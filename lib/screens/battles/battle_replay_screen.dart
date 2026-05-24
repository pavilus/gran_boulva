import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/user_avatar.dart';

/// HLS replay screen for completed battles.
/// Recording expires 24 hours after the battle ends (AWS S3 lifecycle rule).
class BattleReplayScreen extends StatefulWidget {
  final String battleId;
  const BattleReplayScreen({super.key, required this.battleId});

  @override
  State<BattleReplayScreen> createState() => _BattleReplayScreenState();
}

class _BattleReplayScreenState extends State<BattleReplayScreen> {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel? _battle;
  UserModel?         _challenger;
  UserModel?         _opponent;
  UserModel?         _winner;
  bool               _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final battle = await _battleService.getBattle(widget.battleId);
      if (battle == null || !mounted) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final debaters = await Future.wait<UserModel?>([
        _userService.getProfileById(battle.challengerId),
        _userService.getProfileById(battle.opponentId),
      ]);
      UserModel? winner;
      if (battle.winnerId != null) {
        winner = battle.winnerId == battle.challengerId
            ? debaters[0]
            : debaters[1];
      }
      if (!mounted) return;
      setState(() {
        _battle     = battle;
        _challenger = debaters[0];
        _opponent   = debaters[1];
        _winner     = winner;
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _expiresIn(DateTime expiresAt) {
    final diff = expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Ekspire';
    if (diff.inHours > 0) {
      return 'Ekspire nan ${diff.inHours}h ${diff.inMinutes % 60}min';
    }
    return 'Ekspire nan ${diff.inMinutes}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/battle/${widget.battleId}/result'),
        ),
        title: const Text(
          'Replay',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _battle == null
              ? _NotAvailable(
                  message: 'Batay sa a pa jwenn.',
                  onBack: () => context.go('/home'),
                )
              : !_battle!.isReplayAvailable
                  ? _NotAvailable(
                      message: _battle!.recordingExpiresAt != null &&
                              _battle!.recordingExpiresAt!.isBefore(DateTime.now())
                          ? 'Replay sa a ekspire deja. Li disponib pou 24h sèlman.'
                          : 'Replay pa disponib pou batay sa a.',
                      onBack: () =>
                          context.go('/battle/${widget.battleId}/result'),
                    )
                  : _ReplayBody(
                      battle:     _battle!,
                      challenger: _challenger,
                      opponent:   _opponent,
                      winner:     _winner,
                      expiresIn:  _battle!.recordingExpiresAt != null
                          ? _expiresIn(_battle!.recordingExpiresAt!)
                          : null,
                    ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _ReplayBody extends StatelessWidget {
  final DebateBattleModel battle;
  final UserModel?        challenger;
  final UserModel?        opponent;
  final UserModel?        winner;
  final String?           expiresIn;

  const _ReplayBody({
    required this.battle,
    this.challenger,
    this.opponent,
    this.winner,
    this.expiresIn,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Video player ────────────────────────────────────
        _VideoPlayerWidget(url: battle.recordingUrl!),

        // ── Expiry notice ───────────────────────────────────
        if (expiresIn != null)
          Container(
            width: double.infinity,
            color: AppColors.bg1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '⏳ $expiresIn',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
          ),

        // ── Battle info ─────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode + topic
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
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
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '"${battle.topic}"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(height: 20),

                // Debater row
                Row(
                  children: [
                    _DebaterChip(
                      user:     challenger,
                      label:    'Chalan',
                      isWinner: winner?.id == challenger?.id,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    _DebaterChip(
                      user:     opponent,
                      label:    'Adversè',
                      isWinner: winner?.id == opponent?.id,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Back button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () =>
                        context.go('/battle/${battle.id}/result'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Wè Rezilta',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Video player ──────────────────────────────────────────────────────────────

class _VideoPlayerWidget extends StatefulWidget {
  final String url;
  const _VideoPlayerWidget({required this.url});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _ready = true);
          _ctrl.play();
        }
      });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: _ready
          ? Stack(
              children: [
                VideoPlayer(_ctrl),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: VideoProgressIndicator(_ctrl, allowScrubbing: true),
                ),
              ],
            )
          : const Center(
              child: CircularProgressIndicator(color: AppColors.purpleLight),
            ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _DebaterChip extends StatelessWidget {
  final UserModel? user;
  final String     label;
  final bool       isWinner;

  const _DebaterChip({this.user, required this.label, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            UserAvatar(
              avatarUrl: user?.avatarUrl,
              radius:    28,
              gender:    user?.gender,
            ),
            if (isWinner)
              const Positioned(
                top: -4,
                right: -4,
                child: Text('🏆', style: TextStyle(fontSize: 16)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          user?.username ?? label,
          style: TextStyle(
            color: isWinner ? AppColors.warning : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isWinner ? FontWeight.w700 : FontWeight.w400,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _NotAvailable extends StatelessWidget {
  final String       message;
  final VoidCallback onBack;
  const _NotAvailable({required this.message, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📼', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Retounen',
                style: TextStyle(color: AppColors.purple, fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
