import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';

class BattleLobbyScreen extends StatefulWidget {
  final String battleId;
  const BattleLobbyScreen({super.key, required this.battleId});

  @override
  State<BattleLobbyScreen> createState() => _BattleLobbyScreenState();
}

class _BattleLobbyScreenState extends State<BattleLobbyScreen> {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel? _battle;
  UserModel?         _challenger;
  UserModel?         _opponent;
  UserModel?         _me;
  bool               _loading    = true;
  bool               _starting   = false;

  // Countdown before start (lobby display only)
  int   _countdown = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _battleService.unsubscribeFromBattle(widget.battleId);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final battle = await _battleService.getBattle(widget.battleId);
      if (battle == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final results = await Future.wait<UserModel?>([
        _userService.getProfileById(battle.challengerId),
        _userService.getProfileById(battle.opponentId),
        _userService.getProfile(),
      ]);
      if (!mounted) return;
      setState(() {
        _battle     = battle;
        _challenger = results[0];
        _opponent   = results[1];
        _me         = results[2];
        _loading    = false;
      });
      _subscribeToUpdates();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribeToUpdates() {
    _battleService.subscribeToBattle(
      widget.battleId,
      onBattleUpdate: (battle) {
        if (!mounted) return;
        setState(() => _battle = battle);
        // Auto-navigate when status changes to 'live'
        if (battle.status == 'live') {
          _countdownTimer?.cancel();
          context.go('/battle/${widget.battleId}');
        }
      },
    );
  }

  bool get _isParticipant {
    final myId = _me?.id;
    if (myId == null || _battle == null) return false;
    return _battle!.isParticipant(myId);
  }

  Future<void> _startBattle() async {
    setState(() => _starting = true);
    try {
      await _battleService.startRecording(widget.battleId);
      // Navigation handled by Realtime subscription (status → 'live')
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdown = 10;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        _startBattle();
      }
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    if (_battle == null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            const Text('Batay la pa jwenn.',
                style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins')),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Akèy', style: TextStyle(color: AppColors.purple, fontFamily: 'Poppins')),
            ),
          ]),
        ),
      );
    }

    final battle = _battle!;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // ── Top bar ───────────────────────────────────────
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.purpleDim,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      battle.modeLabel,
                      style: const TextStyle(
                        color: AppColors.purpleLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),

              const Spacer(),

              // ── Lobby label ───────────────────────────────────
              const Text(
                'LOBBY',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tann pou batay la kòmanse…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // ── VS layout ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _DebaterColumn(
                    user:    _challenger,
                    label:   'Chalan',
                    isMe:    _me?.id == _challenger?.id,
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  _DebaterColumn(
                    user:    _opponent,
                    label:   'Adversè',
                    isMe:    _me?.id == _opponent?.id,
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Topic ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Sijè',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${battle.topic}"',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              if (battle.entryFeeCoins > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '🏆 Prim: ${battle.prizePoolCoins} 🪙',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],

              const Spacer(),

              // ── Start button (participants only) ──────────────
              if (_isParticipant) ...[
                if (_countdownTimer?.isActive == true) ...[
                  Text(
                    'Kòmanse nan $_countdown...',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        _countdownTimer?.cancel();
                        setState(() => _countdown = 10);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Anile',
                          style: TextStyle(
                              color: AppColors.textMuted, fontFamily: 'Poppins')),
                    ),
                  ),
                ] else ...[
                  GradButton(
                    label: 'Kòmanse Batay ⚡',
                    loading: _starting,
                    onTap: _starting ? null : _startCountdown,
                  ),
                ],
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    '👁️ Ou nan piblik. Batay la pral kòmanse byento.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebaterColumn extends StatelessWidget {
  final UserModel? user;
  final String     label;
  final bool       isMe;

  const _DebaterColumn({this.user, required this.label, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isMe ? AppColors.primaryGradient : null,
                color: isMe ? null : AppColors.border,
              ),
              child: UserAvatar(
                avatarUrl: user?.avatarUrl,
                radius: 40,
                gender:  user?.gender,
              ),
            ),
            if (isMe)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👤',
                      style: TextStyle(fontSize: 10)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 0.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          user?.username ?? '...',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}
