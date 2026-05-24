import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_interactions.dart';
import '../../widgets/common/user_avatar.dart';

/// Live battle screen — handles both ⚡ Rapid Fire and 🎙️ Full Debate modes.
///
/// Participants see debater video tiles (Agora — placeholder until SDK added).
/// Audience sees the same layout but with vote buttons instead of mute controls.
///
/// Timer authority: battle.roundEndsAt from the DB is the source of truth.
/// Local countdown syncs every second via a periodic Timer.
class BattleLiveScreen extends StatefulWidget {
  final String battleId;
  const BattleLiveScreen({super.key, required this.battleId});

  @override
  State<BattleLiveScreen> createState() => _BattleLiveScreenState();
}

class _BattleLiveScreenState extends State<BattleLiveScreen>
    with WidgetsBindingObserver {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel?      _battle;
  List<BattleRoundLogModel> _rounds = [];
  BattleVoteCounts        _audienceVotes  = const BattleVoteCounts(challengerVotes: 0, opponentVotes: 0);
  BattleExtensionCounts   _extensionVotes = const BattleExtensionCounts(yesVotes: 0, noVotes: 0);

  UserModel?  _me;
  UserModel?  _challenger;
  UserModel?  _opponent;

  bool        _loading             = true;
  bool        _hasVotedAudience    = false;
  bool        _hasVotedExtension   = false;
  bool        _isStopping          = false;

  // Agora RTC
  RtcEngine?  _engine;
  bool        _agoraInitialized   = false;

  // Local countdown (seconds left in current timer)
  int         _secondsLeft         = 0;
  Timer?      _tickTimer;
  Timer?      _votePollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tickTimer?.cancel();
    _votePollTimer?.cancel();
    _battleService.unsubscribeFromBattle(widget.battleId);
    if (_agoraInitialized) {
      _engine?.leaveChannel();
      _engine?.release();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-sync timer on foreground return
      _syncTimer();
    }
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _battleService.getBattle(widget.battleId),
        _userService.getProfile(),
      ]);
      final battle = results[0] as DebateBattleModel?;
      final me     = results[1] as UserModel?;
      if (battle == null || !mounted) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final debaters = await Future.wait<UserModel?>([
        _userService.getProfileById(battle.challengerId),
        _userService.getProfileById(battle.opponentId),
      ]);

      if (!mounted) return;
      setState(() {
        _battle     = battle;
        _me         = me;
        _challenger = debaters[0];
        _opponent   = debaters[1];
        _loading    = false;
      });

      _syncTimer();
      _subscribeToUpdates();
      _startVotePoll();
      if (battle.mode == 'full_debate') _loadRoundLog();
      await _initAgora();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initAgora() async {
    final battle = _battle;
    if (battle?.agoraChannel == null) return;

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: String.fromEnvironment('AGORA_APP_ID'),
    ));
    await _engine!.enableVideo();
    await _engine!.startPreview();

    final token = _isParticipant
        ? (_me?.id == battle!.challengerId
            ? battle.agoraChallengerToken
            : battle.agoraOpponentToken)
        : null; // audience joins without token

    await _engine!.joinChannel(
      token: token ?? '',
      channelId: battle!.agoraChannel!,
      uid: _me?.id == battle.challengerId ? 1 : 2,
      options: const ChannelMediaOptions(),
    );
    if (mounted) setState(() => _agoraInitialized = true);
  }

  /// Returns the right [VideoViewControllerBase] for a debater tile.
  /// Returns null when Agora is not yet initialised (shows avatar placeholder).
  VideoViewControllerBase? _controllerFor(String role) {
    if (!_agoraInitialized || _engine == null || _battle?.agoraChannel == null) {
      return null;
    }
    final battle = _battle!;
    final myRole = _me?.id == battle.challengerId
        ? 'challenger'
        : _me?.id == battle.opponentId
            ? 'opponent'
            : 'audience';

    if (_isParticipant && myRole == role) {
      // This debater's own local camera preview
      return VideoViewController(
        rtcEngine: _engine!,
        canvas: const VideoCanvas(uid: 0),
      );
    }
    // Remote stream (other debater or audience view)
    final uid = role == 'challenger' ? 1 : 2;
    return VideoViewController.remote(
      rtcEngine: _engine!,
      canvas: VideoCanvas(uid: uid),
      connection: RtcConnection(channelId: battle.agoraChannel!),
    );
  }

  Future<void> _loadRoundLog() async {
    final rounds = await _battleService.getRoundLog(widget.battleId);
    if (mounted) setState(() => _rounds = rounds);
  }

  void _subscribeToUpdates() {
    _battleService.subscribeToBattle(
      widget.battleId,
      onBattleUpdate: (battle) {
        if (!mounted) return;
        setState(() => _battle = battle);
        _syncTimer();
        if (battle.mode == 'full_debate') _loadRoundLog();
        if (battle.status == 'voting' || battle.status == 'completed') {
          _tickTimer?.cancel();
          context.go('/battle/${widget.battleId}/result');
        }
      },
    );
  }

  void _syncTimer() {
    _tickTimer?.cancel();
    final endsAt = _battle?.roundEndsAt;
    if (endsAt == null) return;

    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = endsAt.difference(DateTime.now()).inSeconds;
      setState(() => _secondsLeft = remaining.clamp(0, 99999));
      if (remaining <= 0) {
        _tickTimer?.cancel();
        // Server (pg_cron / Edge Function) handles advancing state.
        // If participant, offer manual end button as fallback.
      }
    });
    // Immediate first tick
    setState(() =>
        _secondsLeft = endsAt.difference(DateTime.now()).inSeconds.clamp(0, 99999));
  }

  void _startVotePoll() {
    // Poll vote counts every 3 seconds while battle is live/voting
    _votePollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_battle == null || !mounted) return;
      if (_battle!.audienceVoteOpen) {
        final counts = await _battleService.getAudienceVoteCounts(widget.battleId);
        if (mounted) setState(() => _audienceVotes = counts);
      }
      if (_battle!.extensionVoteOpen) {
        final ext = await _battleService.getExtensionVoteCounts(widget.battleId);
        if (mounted) setState(() => _extensionVotes = ext);
      }
    });
  }

  bool get _isParticipant =>
      _me?.id != null &&
      _battle != null &&
      _battle!.isParticipant(_me!.id);

  Future<void> _castAudienceVote(String voteFor) async {
    if (_hasVotedAudience) return;
    setState(() => _hasVotedAudience = true);
    await _battleService.castAudienceVote(
      battleId: widget.battleId,
      voteFor:  voteFor,
    );
    final counts = await _battleService.getAudienceVoteCounts(widget.battleId);
    if (mounted) setState(() => _audienceVotes = counts);
  }

  Future<void> _castExtensionVote(bool vote) async {
    if (_hasVotedExtension) return;
    setState(() => _hasVotedExtension = true);
    await _battleService.castExtensionVote(
      battleId: widget.battleId,
      vote:     vote,
    );
    final counts = await _battleService.getExtensionVoteCounts(widget.battleId);
    if (mounted) setState(() => _extensionVotes = counts);
  }

  Future<void> _stopBattle() async {
    setState(() => _isStopping = true);
    try {
      await _battleService.stopBattle(widget.battleId);
      // Navigation via Realtime status change
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceFirst('Exception: ', ''),
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isStopping = false);
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    final battle = _battle;
    if (battle == null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(
          child: TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Retounen akèy',
                style: TextStyle(color: AppColors.purple, fontFamily: 'Poppins')),
          ),
        ),
      );
    }

    final isFullDebate = battle.mode == 'full_debate';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────
            _TopBar(
              battle:      battle,
              secondsLeft: _secondsLeft,
              formatTime:  _formatTime,
            ),

            // ── Round indicator (Full Debate only) ────────────
            if (isFullDebate && _rounds.isNotEmpty) ...[
              _RoundIndicator(
                battle: battle,
                rounds: _rounds,
                challenger: _challenger,
                opponent:   _opponent,
              ),
            ],

            // ── Debater video tiles ───────────────────────
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: _VideoTile(
                      user:           _challenger,
                      label:          'Chalan',
                      isHighlighted:  isFullDebate
                          ? _currentSpeaker(battle, _rounds) == 'challenger'
                          : false,
                      agoraController: _controllerFor('challenger'),
                    ),
                  ),
                  Expanded(
                    child: _VideoTile(
                      user:           _opponent,
                      label:          'Adversè',
                      isHighlighted:  isFullDebate
                          ? _currentSpeaker(battle, _rounds) == 'opponent'
                          : false,
                      agoraController: _controllerFor('opponent'),
                    ),
                  ),
                ],
              ),
            ),

            // ── Extension vote bar ────────────────────────────
            if (battle.extensionVoteOpen)
              _ExtensionVoteBar(
                counts:           _extensionVotes,
                hasVoted:         _hasVotedExtension,
                onVoteYes:        () => _castExtensionVote(true),
                onVoteNo:         () => _castExtensionVote(false),
              ),

            // ── Audience winner vote ──────────────────────────
            if (battle.audienceVoteOpen)
              _AudienceVoteBar(
                counts:      _audienceVotes,
                hasVoted:    _hasVotedAudience,
                challenger:  _challenger,
                opponent:    _opponent,
                onVote:      _castAudienceVote,
              ),

            // ── Bottom controls ───────────────────────────────
            _BottomBar(
              isParticipant: _isParticipant,
              isStopping:    _isStopping,
              secondsLeft:   _secondsLeft,
              onStop:        _stopBattle,
            ),
          ],
        ),
      ),
    );
  }

  String? _currentSpeaker(
      DebateBattleModel battle, List<BattleRoundLogModel> rounds) {
    final now = DateTime.now();
    for (final r in rounds) {
      if (now.isAfter(r.startsAt) && now.isBefore(r.endsAt)) {
        return r.speaker;
      }
    }
    return null;
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final DebateBattleModel battle;
  final int               secondsLeft;
  final String Function(int) formatTime;

  const _TopBar({
    required this.battle,
    required this.secondsLeft,
    required this.formatTime,
  });

  Color get _timerColor {
    if (secondsLeft > 60) return AppColors.success;
    if (secondsLeft > 20) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.black,
      child: Row(
        children: [
          // Mode badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purpleDim,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              battle.modeLabel,
              style: const TextStyle(
                color: AppColors.purpleLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          const Spacer(),
          // Central timer
          Text(
            formatTime(secondsLeft),
            style: TextStyle(
              color: _timerColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          // LIVE indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              '● LIVE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundIndicator extends StatelessWidget {
  final DebateBattleModel       battle;
  final List<BattleRoundLogModel> rounds;
  final UserModel?              challenger;
  final UserModel?              opponent;

  const _RoundIndicator({
    required this.battle,
    required this.rounds,
    this.challenger,
    this.opponent,
  });

  static const _roundNames = ['Ouvertura', 'Agiman', 'Repons', 'Klotin', 'Bonus'];

  @override
  Widget build(BuildContext context) {
    final currentRound = battle.currentRound;
    final roundName = currentRound > 0 && currentRound <= _roundNames.length
        ? _roundNames[currentRound - 1]
        : 'Ap prepare…';

    // Current speaker from rounds
    final now = DateTime.now();
    String? currentSpeaker;
    for (final r in rounds) {
      if (now.isAfter(r.startsAt) && now.isBefore(r.endsAt)) {
        currentSpeaker = r.speaker;
        break;
      }
    }
    final speakerName = currentSpeaker == 'challenger'
        ? (challenger?.username ?? 'Chalan')
        : currentSpeaker == 'opponent'
            ? (opponent?.username ?? 'Adversè')
            : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.bg1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Wòn $currentRound — $roundName',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          if (speakerName != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '🎙 $speakerName',
                style: const TextStyle(
                  color: AppColors.purpleLight,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VideoTile extends StatelessWidget {
  final UserModel?              user;
  final String                  label;
  final bool                    isHighlighted;
  final VideoViewControllerBase? agoraController;

  const _VideoTile({
    this.user,
    required this.label,
    this.isHighlighted = false,
    this.agoraController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.purpleLight : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          // ── Live Agora video or avatar placeholder ────────
          if (agoraController != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AgoraVideoView(controller: agoraController!),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    avatarUrl: user?.avatarUrl,
                    radius:    36,
                    gender:    user?.gender,
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.videocam_off,
                      color: AppColors.textMuted, size: 18),
                  const SizedBox(height: 4),
                  const Text(
                    'Vidéyo\npa disponib',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // ── Name label bottom-left ────────────────────────
          Positioned(
            left: 8,
            bottom: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user?.username ?? label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),

          // ── Speaking indicator ────────────────────────────
          if (isHighlighted)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.purple,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExtensionVoteBar extends StatelessWidget {
  final BattleExtensionCounts counts;
  final bool                  hasVoted;
  final VoidCallback          onVoteYes;
  final VoidCallback          onVoteNo;

  const _ExtensionVoteBar({
    required this.counts,
    required this.hasVoted,
    required this.onVoteYes,
    required this.onVoteNo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          const Text(
            '⏳ Kontinye batay la?',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          if (!hasVoted)
            Row(
              children: [
                Expanded(
                  child: AppPressable(
                    onTap: onVoteYes,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success),
                      ),
                      child: const Text('✅ Wi',
                          style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppPressable(
                    onTap: onVoteNo,
                    child: Container(
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: const Text('❌ Non',
                          style: TextStyle(
                              color: AppColors.error,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins')),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            _VoteBar(pct: counts.yesPct, color: AppColors.success, label: 'Wi'),
            const SizedBox(height: 4),
            _VoteBar(pct: 1 - counts.yesPct, color: AppColors.error, label: 'Non'),
          ],
        ],
      ),
    );
  }
}

class _AudienceVoteBar extends StatelessWidget {
  final BattleVoteCounts counts;
  final bool             hasVoted;
  final UserModel?       challenger;
  final UserModel?       opponent;
  final void Function(String) onVote;

  const _AudienceVoteBar({
    required this.counts,
    required this.hasVoted,
    this.challenger,
    this.opponent,
    required this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            '🏆 Ki moun ki genyen?',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 10),
          if (!hasVoted)
            Row(
              children: [
                Expanded(
                  child: AppPressable(
                    onTap: () => onVote('challenger'),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.optionAGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        challenger?.username ?? 'Chalan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppPressable(
                    onTap: () => onVote('opponent'),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: AppColors.optionBGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        opponent?.username ?? 'Adversè',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: _VoteBar(
                    pct:   counts.challengerPct,
                    color: AppColors.blue,
                    label: '${(counts.challengerPct * 100).round()}% '
                        '${challenger?.username ?? "Chalan"}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _VoteBar(
                    pct:   counts.opponentPct,
                    color: AppColors.pink,
                    label: '${(counts.opponentPct * 100).round()}% '
                        '${opponent?.username ?? "Adversè"}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${counts.total} vòt total',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _VoteBar extends StatelessWidget {
  final double pct;
  final Color  color;
  final String label;
  const _VoteBar({required this.pct, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  final bool         isParticipant;
  final bool         isStopping;
  final int          secondsLeft;
  final VoidCallback onStop;

  const _BottomBar({
    required this.isParticipant,
    required this.isStopping,
    required this.secondsLeft,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isParticipant && secondsLeft <= 5) ...[
            // Offer manual stop when timer is at 0
            AppPressable(
              onTap: isStopping ? null : onStop,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isStopping
                      ? AppColors.card
                      : AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error),
                ),
                child: isStopping
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.error,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        '⏹ Fini Batay',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
          ] else ...[
            // Audience view shows reaction hint
            const Text(
              '🔥  Reyaji nan kòmantè avan batay fini…',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
