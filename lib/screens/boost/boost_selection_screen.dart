import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/app_interactions.dart';
import '../../widgets/common/grad_button.dart';

class BoostSelectionScreen extends StatefulWidget {
  final String argumentId;
  const BoostSelectionScreen({super.key, required this.argumentId});

  @override
  State<BoostSelectionScreen> createState() => _BoostSelectionScreenState();
}

class _BoostSelectionScreenState extends State<BoostSelectionScreen> {
  int _selected = -1;
  bool _loading = false;
  bool _hasFreeBoost = false;
  bool _usingFree = false;
  int _coinBalance = 0;
  List<BoostTierConfig> _tiers = CoinEconomyConfig.fallback.boostTiers;

  @override
  void initState() {
    super.initState();
    _checkFreeBoost();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final coinService = CoinService();
    final balanceFuture = coinService.getBalance();
    final economyFuture = coinService.getEconomyConfig();
    final balance = await balanceFuture;
    final economy = await economyFuture;
    if (mounted) {
      setState(() {
        _coinBalance = balance;
        _tiers = economy.boostTiers;
        if (_selected >= _tiers.length) _selected = -1;
      });
    }
  }

  Future<void> _checkFreeBoost() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    final data = await Supabase.instance.client
        .from('users')
        .select('free_boost_credits')
        .eq('auth_user_id', user.id)
        .maybeSingle();
    if (data != null && mounted) {
      setState(() => _hasFreeBoost = (data['free_boost_credits'] ?? 0) > 0);
    }
  }

  Future<void> _proceed() async {
    if (_selected < 0) return;
    final tier = _tiers[_selected];

    if (_usingFree) {
      setState(() => _loading = true);
      try {
        await BoostService().createBoost(
          argumentId: widget.argumentId,
          tier: tier.tier,
          useFreCredit: true,
        );
        if (mounted) {
          AppHaptics.tap(AppHaptic.success);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Boost gratis aktive!')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erè: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    } else {
      final cost = tier.coins;
      if (_coinBalance < cost) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Balans ou pa sifi. Achte Boulva Coins.',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.card,
          action: SnackBarAction(
            label: 'Achte',
            textColor: AppColors.purpleLight,
            onPressed: () => context.push('/coins'),
          ),
        ));
        return;
      }
      setState(() => _loading = true);
      try {
        await BoostService().createBoost(
          argumentId: widget.argumentId,
          tier: tier.tier,
          useCoins: true,
          coinCost: cost,
        );
        if (!mounted) return;
        AppHaptics.tap(AppHaptic.success);
        // Reload balance from server after confirmed deduction (no optimistic update).
        _loadBalance();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Boost aktive pou $cost coins!',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.card,
          ),
        );
        context.pop();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('Erè: $e', style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
          ));
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          onTap: () => context.pop(),
        ),
        title: const Text('Boost Agiman',
            style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Chwazi dire boost la',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Yon boost sèvi ak Boulva Coins pou ogmante vizibilite. Li pa garanti premye plas.',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 14),
              _CoinBalancePill(balance: _coinBalance),
              const SizedBox(height: 24),
              ..._tiers.asMap().entries.map((e) => _TierCard(
                    index: e.key,
                    tier: e.value,
                    selected: _selected == e.key,
                    onTap: () => setState(() {
                      _selected = e.key;
                      _usingFree = false;
                    }),
                  )),
              if (_hasFreeBoost) ...[
                const SizedBox(height: 12),
                _FreeTierCard(
                  selected: _usingFree,
                  onTap: () => setState(() {
                    _usingFree = !_usingFree;
                    if (_usingFree) _selected = 0;
                  }),
                ),
              ],
              const Spacer(),
              GradButton(
                label: _usingFree
                    ? 'Aktive Boost Gratis'
                    : (_selected >= 0
                        ? 'Boost ${_tiers[_selected].price}'
                        : 'Chwazi yon plan'),
                onTap: _selected >= 0 ? _proceed : null,
                loading: _loading,
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Fè yo wè w.',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoinBalancePill extends StatelessWidget {
  final int balance;
  const _CoinBalancePill({required this.balance});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Image.asset('assets/images/coin.png', width: 18, height: 18),
        const SizedBox(width: 7),
        Text(
          '$balance Boulva Coins',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ]),
    );
  }
}

class _TierCard extends StatelessWidget {
  final int index;
  final BoostTierConfig tier;
  final bool selected;
  final VoidCallback onTap;

  const _TierCard(
      {required this.index,
      required this.tier,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.purple.withAlpha(40) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.purpleLight : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: selected ? AppColors.primaryGradient : null,
                color: selected ? null : AppColors.bg1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.bolt_rounded,
                  color: selected ? Colors.white : AppColors.textMuted,
                  size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tier.label,
                      style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(tier.desc,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
            Text(tier.price,
                style: TextStyle(
                    color:
                        selected ? AppColors.purpleLight : AppColors.textMuted,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}

class _FreeTierCard extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _FreeTierCard({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.pink.withAlpha(30) : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.pink : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.pink.withAlpha(60) : AppColors.bg1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.card_giftcard_rounded,
                  color: selected ? AppColors.pink : AppColors.textMuted,
                  size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Boost Gratis',
                      style: TextStyle(
                          color:
                              selected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          fontSize: 16)),
                  const SizedBox(height: 2),
                  const Text(
                      'Kredit envitasyon ou — 24 èdtan vizibilite gratis',
                      style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
            Text('GRATIS',
                style: TextStyle(
                    color: selected ? AppColors.pink : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }
}
