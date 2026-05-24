import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';

class BattleIncomingScreen extends StatefulWidget {
  final String battleId;
  const BattleIncomingScreen({super.key, required this.battleId});

  @override
  State<BattleIncomingScreen> createState() => _BattleIncomingScreenState();
}

class _BattleIncomingScreenState extends State<BattleIncomingScreen> {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel? _battle;
  UserModel?         _challenger;
  bool               _loading    = true;
  bool               _accepting  = false;
  bool               _declining  = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final battle = await _battleService.getBattle(widget.battleId);
      UserModel? challenger;
      if (battle != null) {
        challenger = await _userService.getProfileById(battle.challengerId);
      }
      if (!mounted) return;
      setState(() {
        _battle     = battle;
        _challenger = challenger;
        _loading    = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(String action) async {
    if (action == 'accept') {
      setState(() => _accepting = true);
    } else {
      setState(() => _declining = true);
    }
    try {
      await _battleService.respondToBattle(
        battleId: widget.battleId,
        action:   action,
      );
      if (!mounted) return;
      if (action == 'accept') {
        context.go('/battle/${widget.battleId}');
      } else {
        context.go('/home');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
          _declining = false;
        });
      }
    }
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
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _battle == null
              ? _NotFound(onBack: () => context.go('/home'))
              : _battle!.status != 'pending'
                  ? _AlreadyHandled(
                      status: _battle!.status,
                      onContinue: () => context.go('/battle/${widget.battleId}'),
                    )
                  : _IncomingBody(
                      battle:     _battle!,
                      challenger: _challenger,
                      accepting:  _accepting,
                      declining:  _declining,
                      onAccept:   () => _respond('accept'),
                      onDecline:  () => _respond('decline'),
                    ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _IncomingBody extends StatelessWidget {
  final DebateBattleModel battle;
  final UserModel?        challenger;
  final bool              accepting;
  final bool              declining;
  final VoidCallback      onAccept;
  final VoidCallback      onDecline;

  const _IncomingBody({
    required this.battle,
    this.challenger,
    required this.accepting,
    required this.declining,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final tierRequired = battle.mode == 'full_debate' ? 2 : 1;
    final tierLabel    = tierRequired == 2
        ? 'Kreyatè Verifye (Tier 2)'
        : 'Kreyatè Monte (Tier 1)';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Header ─────────────────────────────────────────
            const Text(
              '⚔️',
              style: TextStyle(fontSize: 64),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ou gen yon Defi!',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${challenger?.fullName ?? challenger?.username ?? 'Yon moun'} defye ou nan yon batay debat.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // ── Challenger ─────────────────────────────────────
            UserAvatar(
              avatarUrl: challenger?.avatarUrl,
              radius: 40,
              gender: challenger?.gender,
            ),
            const SizedBox(height: 10),
            Text(
              challenger?.fullName ?? challenger?.username ?? '...',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            if (challenger?.username != null)
              Text(
                '@${challenger!.username}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),

            const SizedBox(height: 28),

            // ── Battle details card ─────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(
                    label: 'Mod',
                    value: battle.modeLabel,
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Sijè',
                    value: battle.topic,
                  ),
                  if (battle.entryFeeCoins > 0) ...[
                    const SizedBox(height: 12),
                    _DetailRow(
                      label: 'Mise',
                      value: '${battle.entryFeeCoins} 🪙 chak bò · Prim: ${battle.entryFeeCoins * 2} 🪙',
                    ),
                  ],
                  const SizedBox(height: 12),
                  _DetailRow(
                    label: 'Nivo requi',
                    value: tierLabel,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 36),

            // ── Accept button ───────────────────────────────────
            GradButton(
              label: 'Aksepte Defi ✅',
              loading: accepting,
              onTap: accepting || declining ? null : onAccept,
            ),
            const SizedBox(height: 12),

            // ── Decline button ──────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: accepting || declining ? null : onDecline,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: declining
                        ? AppColors.error
                        : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: declining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.error,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Refize',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }
}

class _NotFound extends StatelessWidget {
  final VoidCallback onBack;
  const _NotFound({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Batay la pa jwenn.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: onBack,
            child: const Text('Retounen',
                style: TextStyle(color: AppColors.purple, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

class _AlreadyHandled extends StatelessWidget {
  final String status;
  final VoidCallback onContinue;
  const _AlreadyHandled({required this.status, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              status == 'cancelled' ? '❌' : '⚔️',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 16),
            Text(
              status == 'cancelled'
                  ? 'Batay sa a anile deja.'
                  : 'Batay sa a $status deja.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (status != 'cancelled')
              ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Text('Kontinye',
                    style: TextStyle(fontFamily: 'Poppins')),
              ),
          ],
        ),
      ),
    );
  }
}
