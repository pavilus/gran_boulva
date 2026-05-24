import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';

class BattleResultScreen extends StatefulWidget {
  final String battleId;
  const BattleResultScreen({super.key, required this.battleId});

  @override
  State<BattleResultScreen> createState() => _BattleResultScreenState();
}

class _BattleResultScreenState extends State<BattleResultScreen>
    with SingleTickerProviderStateMixin {
  final _battleService = BattleService();
  final _userService   = UserService();

  DebateBattleModel? _battle;
  UserModel?         _challenger;
  UserModel?         _opponent;
  UserModel?         _me;
  BattleVoteCounts   _votes = const BattleVoteCounts(challengerVotes: 0, opponentVotes: 0);
  bool               _loading    = true;
  bool               _tallying   = false;

  late final AnimationController _anim;
  late final Animation<double>    _fadeIn;

  @override
  void initState() {
    super.initState();
    _anim   = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _load();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final battle = await _battleService.getBattle(widget.battleId);
      if (battle == null || !mounted) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final userResults = await Future.wait<UserModel?>([
        _userService.getProfileById(battle.challengerId),
        _userService.getProfileById(battle.opponentId),
        _userService.getProfile(),
      ]);
      final votes = await _battleService.getAudienceVoteCounts(widget.battleId);
      if (!mounted) return;
      setState(() {
        _battle     = battle;
        _challenger = userResults[0];
        _opponent   = userResults[1];
        _me         = userResults[2];
        _votes      = votes;
        _loading    = false;
      });
      _anim.forward();

      // If still in 'voting', tally after 30s window (failsafe for client-triggered flow)
      if (battle.status == 'voting') {
        await Future.delayed(const Duration(seconds: 30));
        if (mounted && _battle?.status == 'voting') _tally();
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _tally() async {
    setState(() => _tallying = true);
    try {
      await _battleService.tallyBattle(widget.battleId);
      final updated = await _battleService.getBattle(widget.battleId);
      if (mounted && updated != null) {
        setState(() => _battle = updated);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _tallying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : FadeTransition(
              opacity: _fadeIn,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    children: [
                      // ── Winner reveal ─────────────────────────────
                      _WinnerReveal(
                        battle:     _battle!,
                        challenger: _challenger,
                        opponent:   _opponent,
                        me:         _me,
                      ),
                      const SizedBox(height: 28),

                      // ── Vote breakdown ────────────────────────────
                      _VoteBreakdown(
                        votes:      _votes,
                        challenger: _challenger,
                        opponent:   _opponent,
                      ),
                      const SizedBox(height: 20),

                      // ── Prize info ────────────────────────────────
                      if (_battle!.prizePoolCoins > 0)
                        _PrizeCard(battle: _battle!),

                      const SizedBox(height: 32),

                      // ── Tally CTA (if still voting) ───────────────
                      if (_battle!.status == 'voting') ...[
                        GradButton(
                          label: 'Konte Vòt Yo',
                          loading: _tallying,
                          onTap: _tally,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Replay button ─────────────────────────────
                      if (_battle!.isReplayAvailable) ...[
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                context.go('/battle/${widget.battleId}/replay'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.purple),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.play_circle_outline,
                                color: AppColors.purpleLight),
                            label: const Text(
                              'Gade Replay',
                              style: TextStyle(
                                  color: AppColors.purpleLight,
                                  fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ── Back home ─────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: () => context.go('/home'),
                          child: const Text(
                            'Retounen Akèy',
                            style: TextStyle(
                                color: AppColors.textMuted,
                                fontFamily: 'Poppins'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _WinnerReveal extends StatelessWidget {
  final DebateBattleModel battle;
  final UserModel?        challenger;
  final UserModel?        opponent;
  final UserModel?        me;

  const _WinnerReveal({
    required this.battle,
    this.challenger,
    this.opponent,
    this.me,
  });

  @override
  Widget build(BuildContext context) {
    final winnerId    = battle.winnerId;
    final winnerUser  = winnerId == battle.challengerId ? challenger : opponent;
    final isMeWinner  = me?.id == winnerId;
    final hasResult   = winnerId != null && battle.status == 'completed';

    if (!hasResult) {
      return const Column(
        children: [
          Text('🏟️', style: TextStyle(fontSize: 56)),
          SizedBox(height: 12),
          Text(
            'Vòt piblik yo fini…',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 18,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text('🏆', style: TextStyle(fontSize: 72)),
        const SizedBox(height: 8),
        Text(
          isMeWinner ? 'Ou Genyen! 🎉' : 'Rezilta Batay',
          style: TextStyle(
            color: isMeWinner ? AppColors.warning : AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 20),
        UserAvatar(
          avatarUrl: winnerUser?.avatarUrl,
          radius:    44,
          gender:  winnerUser?.gender,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            winnerUser?.username ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          winnerUser?.fullName ?? '',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _VoteBreakdown extends StatelessWidget {
  final BattleVoteCounts votes;
  final UserModel?       challenger;
  final UserModel?       opponent;

  const _VoteBreakdown(
      {required this.votes, this.challenger, this.opponent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'Vòt piblik — ${votes.total} total',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            name:  challenger?.username ?? 'Chalan',
            votes: votes.challengerVotes,
            pct:   votes.challengerPct,
            color: AppColors.blue,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            name:  opponent?.username ?? 'Adversè',
            votes: votes.opponentVotes,
            pct:   votes.opponentPct,
            color: AppColors.pink,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String name;
  final int    votes;
  final double pct;
  final Color  color;

  const _BreakdownRow({
    required this.name,
    required this.votes,
    required this.pct,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct.clamp(0.0, 1.0),
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${(pct * 100).round()}%',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final DebateBattleModel battle;
  const _PrizeCard({required this.battle});

  @override
  Widget build(BuildContext context) {
    final winnerCoins = (battle.prizePoolCoins * 0.9).floor();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text(
            '💰 Prim Distribiye',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$winnerCoins 🪙 → Gayan',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          Text(
            '${battle.prizePoolCoins - winnerCoins} 🪙 → Platfòm (10%)',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
