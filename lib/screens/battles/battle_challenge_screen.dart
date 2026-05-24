import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_interactions.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';

class BattleChallengeScreen extends StatefulWidget {
  final String opponentId;

  const BattleChallengeScreen({super.key, required this.opponentId});

  @override
  State<BattleChallengeScreen> createState() => _BattleChallengeScreenState();
}

class _BattleChallengeScreenState extends State<BattleChallengeScreen> {
  final _battleService   = BattleService();
  final _userService     = UserService();
  final _matchupService  = MatchupService();
  final _topicCtrl       = TextEditingController();

  UserModel?          _me;
  UserModel?          _opponent;
  List<MatchupModel>  _hotMatchups  = [];
  MatchupModel?       _selectedMatchup;
  bool                _loading      = true;
  bool                _submitting   = false;

  String _mode         = 'rapid_fire';  // 'rapid_fire' | 'full_debate'
  int    _entryFee     = 0;             // coins

  static const _feeOptions = [0, 50, 100, 250, 500, 1000];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _userService.getProfile(),
        _userService.getProfileById(widget.opponentId),
        _matchupService.getHomeFeed(popular: true),
      ]);
      if (!mounted) return;
      final matchups = (results[2] as List<MatchupModel>).take(5).toList();
      setState(() {
        _me          = results[0] as UserModel?;
        _opponent    = results[1] as UserModel?;
        _hotMatchups = matchups;
        _loading     = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    // Prefer the selected matchup title; fall back to free-text field.
    final topic = _selectedMatchup?.titleHt ?? _topicCtrl.text.trim();
    if (topic.isEmpty) {
      _snack('Chwazi yon matchup oswa tape sijè batay la anvan.');
      return;
    }
    if (_entryFee > 0 && (_me?.coinBalance ?? 0) < _entryFee) {
      _snack('Ou pa gen ase pyès. Recharge anvan.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await _battleService.createBattle(
        opponentId:    widget.opponentId,
        mode:          _mode,
        topic:         topic,
        entryFeeCoins: _entryFee,
      );
      if (!mounted) return;
      final battleId = result['battle_id'] as String?;
      if (battleId != null) {
        context.go('/battle/$battleId');
      }
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
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
      appBar: const AppBar2(title: 'Defi Batay', showBack: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Opponent card ─────────────────────────────────
                    _OpponentCard(opponent: _opponent),
                    const SizedBox(height: 24),

                    // ── Mode selector ─────────────────────────────────
                    const _SectionLabel('Chwa Mod'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _ModeCard(
                            emoji: '⚡',
                            title: 'Rapid Fire',
                            subtitle: '5 minit · lib',
                            selected: _mode == 'rapid_fire',
                            onTap: () => setState(() => _mode = 'rapid_fire'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ModeCard(
                            emoji: '🎙️',
                            title: 'Full Debate',
                            subtitle: '10 minit · wòn',
                            selected: _mode == 'full_debate',
                            onTap: () => setState(() => _mode = 'full_debate'),
                            requiresTier2: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Hot matchup picker ────────────────────────────
                    const _SectionLabel('Chwazi Sijè'),
                    const SizedBox(height: 10),
                    if (_hotMatchups.isNotEmpty) ...[
                      ...List.generate(_hotMatchups.length, (i) {
                        final m = _hotMatchups[i];
                        final selected = _selectedMatchup?.id == m.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppPressable(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedMatchup =
                                    selected ? null : m;
                                if (!selected) _topicCtrl.clear();
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.purpleDim
                                    : AppColors.inputBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.purpleLight
                                      : AppColors.border,
                                  width: selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${i + 1}',
                                    style: TextStyle(
                                      color: selected
                                          ? AppColors.purpleLight
                                          : AppColors.textMuted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.titleHt,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                  if (selected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.purpleLight, size: 18),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // Custom topic override (clears selection)
                      const _SectionLabel('Oswa tape sijè ou menm'),
                      const SizedBox(height: 8),
                    ],
                    _TopicField(
                      controller: _topicCtrl,
                      enabled: _selectedMatchup == null,
                      onChanged: (_) {
                        if (_selectedMatchup != null) {
                          setState(() => _selectedMatchup = null);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Entry fee ─────────────────────────────────────
                    const _SectionLabel('Mise (pyès chak bò)'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feeOptions.map((fee) {
                        final selected = _entryFee == fee;
                        return AppPressable(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _entryFee = fee);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.purple
                                  : AppColors.inputBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppColors.purpleLight
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              fee == 0 ? 'Gratis' : '$fee 🪙',
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontFamily: 'Poppins',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (_entryFee > 0) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Balans ou: ${_me?.coinBalance ?? 0} 🪙 · Prim total: ${_entryFee * 2} 🪙',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],

                    const SizedBox(height: 36),
                    GradButton(
                      label: 'Voye Defi ⚔️',
                      loading: _submitting,
                      onTap: _submit,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OpponentCard extends StatelessWidget {
  final UserModel? opponent;
  const _OpponentCard({this.opponent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: opponent?.avatarUrl,
            radius: 28,
            gender: opponent?.gender,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'W ap defye',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  opponent?.fullName ?? opponent?.username ?? '...',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (opponent?.username != null)
                  Text(
                    '@${opponent!.username}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ),
          const Text('⚔️', style: TextStyle(fontSize: 28)),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final bool requiresTier2;

  const _ModeCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.requiresTier2 = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.purpleDim : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.purpleLight : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
            if (requiresTier2) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Tier 2+',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopicField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _TopicField({
    required this.controller,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      maxLines: 2,
      maxLength: 120,
      style: TextStyle(
        color: enabled ? AppColors.textPrimary : AppColors.textMuted,
        fontFamily: 'Poppins',
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: enabled
            ? 'Ekri sijè ou vle pale... (egz: "Edikasyon piblik pi bon pase prive")'
            : 'Yon matchup deja chwazi — deseleksyone l pou tape manyèlman',
        hintStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Poppins',
          fontSize: 13,
        ),
        filled: true,
        fillColor: enabled ? AppColors.inputBg : AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.border.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.purpleLight, width: 2),
        ),
        counterStyle: const TextStyle(
          color: AppColors.textMuted,
          fontFamily: 'Poppins',
          fontSize: 11,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.3,
      ),
    );
  }
}
