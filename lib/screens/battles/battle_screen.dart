import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import 'battle_incoming_screen.dart';
import 'battle_lobby_screen.dart';
import 'battle_live_screen.dart';
import 'battle_result_screen.dart';

/// Entry-point for /battle/:id
///
/// Loads the battle and routes to the correct sub-screen based on
/// the current status and whether the signed-in user is a participant.
///
///   pending  + opponent  → BattleIncomingScreen
///   pending  + challenger → "Aguayo challenge…" waiting screen
///   accepted / lobby     → BattleLobbyScreen
///   live                 → BattleLiveScreen
///   voting / completed   → BattleResultScreen
///   cancelled            → CancelledScreen (inline)
class BattleScreen extends StatefulWidget {
  final String battleId;
  const BattleScreen({super.key, required this.battleId});

  @override
  State<BattleScreen> createState() => _BattleScreenState();
}

class _BattleScreenState extends State<BattleScreen> {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel? _battle;
  UserModel?         _me;
  bool               _loading = true;
  String?            _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _battleService.unsubscribeFromBattle(widget.battleId);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _battleService.getBattle(widget.battleId),
        _userService.getProfile(),
      ]);
      if (!mounted) return;
      final battle = results[0] as DebateBattleModel?;
      if (battle == null) {
        setState(() { _error = 'Batay sa a pa jwenn.'; _loading = false; });
        return;
      }
      setState(() {
        _battle  = battle;
        _me      = results[1] as UserModel?;
        _loading = false;
      });
      // Subscribe to live updates so status changes auto-navigate
      _battleService.subscribeToBattle(
        widget.battleId,
        onBattleUpdate: (updated) {
          if (!mounted) return;
          setState(() => _battle = updated);
          _maybeNavigate(updated);
        },
      );
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _maybeNavigate(DebateBattleModel battle) {
    final status = battle.status;
    final myId   = _me?.id;
    final isOpponent = myId == battle.opponentId;

    switch (status) {
      case 'pending':
        if (isOpponent) context.go('/battle/${battle.id}/incoming');
        break;
      case 'accepted':
      case 'lobby':
        context.go('/battle/${battle.id}/lobby');
        break;
      case 'live':
        context.go('/battle/${battle.id}/live');
        break;
      case 'voting':
      case 'completed':
        context.go('/battle/${battle.id}/result');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }

    if (_error != null || _battle == null) {
      return Scaffold(
        backgroundColor: AppColors.bg0,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Erè enkoni.',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => context.go('/home'),
              child: const Text('Retounen Akèy',
                  style: TextStyle(
                      color: AppColors.purple, fontFamily: 'Poppins')),
            ),
          ]),
        ),
      );
    }

    final battle     = _battle!;
    final myId       = _me?.id;
    final isOpponent = myId == battle.opponentId;

    switch (battle.status) {
      case 'pending':
        if (isOpponent) {
          return BattleIncomingScreen(battleId: battle.id);
        }
        // Challenger waiting for opponent to respond
        return _WaitingScreen(battle: battle);

      case 'accepted':
      case 'lobby':
        return BattleLobbyScreen(battleId: battle.id);

      case 'live':
        return BattleLiveScreen(battleId: battle.id);

      case 'voting':
      case 'completed':
        return BattleResultScreen(battleId: battle.id);

      case 'cancelled':
        return _CancelledScreen(battle: battle);

      default:
        return BattleLobbyScreen(battleId: battle.id);
    }
  }
}

// ── Inline sub-screens ─────────────────────────────────────────────────────────

class _WaitingScreen extends StatelessWidget {
  final DebateBattleModel battle;
  const _WaitingScreen({required this.battle});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textMuted),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⚔️', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 20),
              const Text(
                'Defi voye!',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Ap tann adversè ou aksepte defi ${battle.modeLabel} a…',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '"${battle.topic}"',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                  color: AppColors.purple, strokeWidth: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _CancelledScreen extends StatelessWidget {
  final DebateBattleModel battle;
  const _CancelledScreen({required this.battle});

  @override
  Widget build(BuildContext context) {
    final reason = switch (battle.cancelledReason) {
      'opponent_declined' => 'Adversè ou te refize defi a.',
      String r => r,
      null => 'Batay la anile.',
    };

    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('❌', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              const Text(
                'Batay Anile',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                reason,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
              if (battle.entryFeeCoins > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${battle.entryFeeCoins} 🪙 ranbouse nan kont ou.',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                ),
                child: const Text(
                  'Retounen Akèy',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
