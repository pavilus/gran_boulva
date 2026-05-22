import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/app_interactions.dart';

class CoinStoreScreen extends StatefulWidget {
  const CoinStoreScreen({super.key});

  @override
  State<CoinStoreScreen> createState() => _CoinStoreScreenState();
}

class _CoinStoreScreenState extends State<CoinStoreScreen> {
  final _userService = UserService();
  final _coinService = CoinService();
  int _balance = 0;
  bool _loading = true;
  bool _proceeding = false;
  bool _claimingDaily = false;
  int _selectedPack = 2; // 1200 coins — popular default
  int _selectedPayment = 2; // Kat (card)
  List<CoinPackConfig> _packs = CoinEconomyConfig.fallback.coinPacks;
  DailyCoinClaimStatus? _dailyClaim;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userFuture = _userService.getProfile();
      final economyFuture = _coinService.getEconomyConfig();
      final claimFuture = _coinService.getDailyClaimStatus();
      final user = await userFuture;
      final economy = await economyFuture;
      final claim = await claimFuture;
      if (!mounted) return;
      setState(() {
        _balance = user?.coinBalance ?? 0;
        _packs = economy.coinPacks;
        _dailyClaim = claim;
        if (_selectedPack >= _packs.length) _selectedPack = 0;
      });
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _proceed() async {
    if (_selectedPayment != 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'Sèlman pèman pa kat ki disponib pou kounye a.',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final pack = _packs[_selectedPack];
    setState(() => _proceeding = true);
    try {
      final result = await _coinService
          .createPurchase(coinAmount: pack.coins, usdCents: pack.price)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      final clientSecret = _clientSecretFrom(result);
      if (clientSecret == null || clientSecret.isEmpty) {
        final error = result['error'] ?? result['message'];
        _showSnack(error?.toString() ?? 'Stripe pa retounen client secret.');
        return;
      }
      final uri = Uri(
        path: '/payment',
        queryParameters: {
          'secret': clientSecret,
          'amount': pack.price.toString(),
          'label': '${pack.coins} Boulva Coins',
          'argumentId': '',
        },
      );
      final completed = await context.push<bool>(uri.toString());
      if (completed == true) {
        await _load();
      }
    } catch (e) {
      if (mounted) _showSnack('Erè: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _proceeding = false);
    }
  }

  String? _clientSecretFrom(Map<String, dynamic> result) {
    final direct = result['client_secret'] ?? result['clientSecret'];
    if (direct != null) return direct.toString();
    final pi = result['payment_intent'] ?? result['paymentIntent'];
    if (pi is Map) {
      final n = pi['client_secret'] ?? pi['clientSecret'];
      if (n != null) return n.toString();
    }
    final data = result['data'];
    if (data is Map) {
      final n = data['client_secret'] ?? data['clientSecret'];
      if (n != null) return n.toString();
    }
    return null;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: AppColors.card,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _claimDailyReward() async {
    if (_claimingDaily || _dailyClaim?.canClaim != true) return;
    setState(() => _claimingDaily = true);
    try {
      final result = await _coinService.claimDailyReward();
      if (!mounted) return;
      setState(() {
        _dailyClaim = result;
        _balance += result.amount;
      });
      AppHaptics.tap(AppHaptic.success);
      _showSnack('Ou resevwa ${result.amount} Boulva Coins!');
    } catch (e) {
      if (mounted) _showSnack('Erè: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _claimingDaily = false);
    }
  }

  String _fmtCoins(int coins) {
    if (coins >= 1000) {
      final k = coins / 1000;
      return '${k == k.truncate() ? k.toInt() : k.toStringAsFixed(1)}K';
    }
    return '$coins';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => context.pop()),
        title: const Text(
          'Pèman',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.35),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_user_rounded,
                    color: AppColors.success, size: 12),
                SizedBox(width: 4),
                Text(
                  'Sekirite garanti',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceCard(),
                          const SizedBox(height: 20),
                          _buildDailyClaimCard(),
                          const SizedBox(height: 20),
                          _buildPacksSection(),
                          const SizedBox(height: 20),
                          _buildWhatsCoinsSection(),
                          const SizedBox(height: 20),
                          _buildPaymentMethodSection(),
                          const SizedBox(height: 10),
                          const Center(
                            child: Text(
                              'Pèman ou an sekirize ak chifreman SSL.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: _buildContinueButton(),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        image: const DecorationImage(
          image: AssetImage('assets/images/coinsback.png'),
          fit: BoxFit.cover,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Boulva Coins mwen',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/coin.png',
                  width: 26, height: 26, fit: BoxFit.contain),
              const SizedBox(width: 8),
              Text(
                '$_balance',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Poppins',
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyClaimCard() {
    final claim = _dailyClaim;
    final canClaim = claim?.canClaim ?? false;
    final amount =
        claim?.todayAmount ?? CoinEconomyConfig.fallback.dailyClaimBase;
    final streak =
        canClaim ? (claim?.nextStreakCount ?? 1) : (claim?.streakCount ?? 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: canClaim
              ? AppColors.success.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.calendar_month_rounded,
              color: AppColors.success, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Rekonpans chak jou',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              canClaim
                  ? 'Pran $amount coins. Streak: $streak jou'
                  : 'Ou deja reklame jodi a. Streak: $streak jou',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ]),
        ),
        const SizedBox(width: 10),
        AppPressable(
          onTap: canClaim ? _claimDailyReward : null,
          haptic: AppHaptic.medium,
          pressedScale: 0.94,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: canClaim ? AppColors.success : AppColors.bg1,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: canClaim ? AppColors.success : AppColors.border,
              ),
            ),
            child: _claimingDaily
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    canClaim ? 'Pran' : 'Fèt',
                    style: TextStyle(
                      color: canClaim ? Colors.white : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
          ),
        ),
      ]),
    );
  }

  Widget _buildPacksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chwazi kantite Coins',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        ..._packs.asMap().entries.map((e) {
          final isSelected = _selectedPack == e.key;
          final pack = e.value;
          return AppPressable(
            onTap: () => setState(() => _selectedPack = e.key),
            haptic: AppHaptic.selection,
            pressedScale: 0.985,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.purple.withValues(alpha: 0.15)
                    : AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.purpleLight : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.purpleLight.withValues(alpha: 0.18),
                          blurRadius: 14,
                          spreadRadius: 0,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/coin.png',
                    width: 34,
                    height: 34,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${_fmtCoins(pack.coins)} Coins',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            if (pack.popular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'POPILÈ',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (pack.savings.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            pack.savings,
                            style: const TextStyle(
                              color: AppColors.success,
                              fontSize: 11,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    pack.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.purpleLight
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildWhatsCoinsSection() {
    const features = [
      (
        icon: Icons.favorite_rounded,
        label: 'Sipòte agiman',
        sub: 'Monte nis-ou'
      ),
      (
        icon: Icons.bolt_rounded,
        label: 'Booste agiman',
        sub: 'Ogmante vizibilite'
      ),
      (
        icon: Icons.swap_horiz_rounded,
        label: 'Transfere Coins',
        sub: 'Voye bay zanmi'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kisa mwen ka fè ak Coins?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: features.map((f) {
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.bg1,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.5)),
                    ),
                    child: Icon(f.icon, color: AppColors.purpleLight, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    f.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    f.sub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodSection() {
    const methods = [
      (label: 'Apple Pay', icon: Icons.apple),
      (label: 'G Pay', icon: Icons.g_mobiledata_rounded),
      (label: 'Kat', icon: Icons.credit_card_rounded),
      (label: 'PayPal', icon: Icons.account_balance_wallet_rounded),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Metòd peman',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(methods.length, (i) {
            final isSelected = _selectedPayment == i;
            final m = methods[i];
            return Expanded(
              child: AppPressable(
                onTap: () => setState(() => _selectedPayment = i),
                haptic: AppHaptic.selection,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin:
                      EdgeInsets.only(right: i < methods.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.purple.withValues(alpha: 0.18)
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.purpleLight : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        m.icon,
                        color: isSelected
                            ? AppColors.purpleLight
                            : AppColors.textMuted,
                        size: 22,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        m.label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildContinueButton() {
    return AppPressable(
      onTap: _proceeding ? null : _proceed,
      haptic: AppHaptic.medium,
      pressedScale: 0.985,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: _proceeding ? null : AppColors.primaryGradient,
          color: _proceeding ? AppColors.textDim : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _proceeding
              ? null
              : [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: _proceeding
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Kontinye ak pèman',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 20),
                ],
              ),
      ),
    );
  }
}
