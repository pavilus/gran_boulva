import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';

// ignore_for_file: unused_import

class PaymentScreen extends StatefulWidget {
  final String clientSecret;
  final int amountCents;
  final String tierLabel;
  final String argumentId;

  const PaymentScreen({
    super.key,
    required this.clientSecret,
    required this.amountCents,
    required this.tierLabel,
    required this.argumentId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _loading = false;
  bool _cardComplete = false;
  String? _paymentStage;
  bool _showBillingAddress = true;
  bool _saveCard = false;
  String _selectedCountry = 'Etazini';
  String? _selectedState;
  final _coinService = CoinService();
  final _cardController = CardEditController();
  final _nameController = TextEditingController();
  final _address1Controller = TextEditingController();
  final _address2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _billingZipController = TextEditingController();

  static const _countries = [
    'Etazini',
    'Ayiti',
    'Kanada',
    'Meksik',
    'Brezil',
    'Kolobi',
    'Pèrou',
    'Venezwela',
    'Chili',
    'Ekwatè',
    'Bolivya',
    'Pawagwe',
    'Irigwe',
    'Giyàn',
    'Lafrans',
    'Espay',
    'Italya',
    'Almay',
    'Wayòm Ini',
    'Pòtigal',
    'Bèljik',
    'Nèdèlan',
    'Swis',
    'Ostrich',
    'Polòy',
    'Risi',
    'Jamayik',
    'Trinite',
    'Domnik',
    'Repiblik Dominikèn',
    'Kiba',
    'Gwatemala',
    'Ondiris',
    'El Salvadò',
    'Nikaragwa',
    'Kostarika',
    'Panama',
  ];

  static const _usStates = [
    'AL',
    'AK',
    'AZ',
    'AR',
    'CA',
    'CO',
    'CT',
    'DE',
    'FL',
    'GA',
    'HI',
    'ID',
    'IL',
    'IN',
    'IA',
    'KS',
    'KY',
    'LA',
    'ME',
    'MD',
    'MA',
    'MI',
    'MN',
    'MS',
    'MO',
    'MT',
    'NE',
    'NV',
    'NH',
    'NJ',
    'NM',
    'NY',
    'NC',
    'ND',
    'OH',
    'OK',
    'OR',
    'PA',
    'RI',
    'SC',
    'SD',
    'TN',
    'TX',
    'UT',
    'VT',
    'VA',
    'WA',
    'WV',
    'WI',
    'WY',
    'DC',
  ];

  bool get _isCoinPurchase => widget.argumentId.isEmpty;

  String get _priceLabel {
    final dollars = widget.amountCents / 100;
    return '\$${dollars.toStringAsFixed(2)}';
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _cardController.dispose();
    _nameController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _cityController.dispose();
    _billingZipController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() {
      _loading = true;
      _paymentStage = 'Trètman peman...';
    });
    try {
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: widget.clientSecret,
        data: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      if (_isCoinPurchase) {
        if (mounted) setState(() => _paymentStage = 'Konfime coins...');
        try {
          await _coinService
              .confirmCoinPurchase(clientSecret: widget.clientSecret)
              .timeout(const Duration(seconds: 30));
        } on TimeoutException {
          throw TimeoutException(
            'Pèman an pase, men konfimasyon coins yo pran twòp tan. Tcheke balans ou epi rafrechi.',
          );
        }
      }

      if (mounted) {
        setState(() {
          _loading = false;
          _paymentStage = null;
        });
        _showSuccessSheet();
      }
    } on StripeException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _paymentStage = null;
        });
        final msg = e.error.localizedMessage ?? 'Pèman pa pase. Eseye ankò.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded,
                    color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(msg,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'Poppins')),
                ),
              ],
            ),
            backgroundColor: AppColors.card,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _paymentStage = null;
        });
        _showPaymentError(e.message ?? 'Pèman an pran twòp tan. Eseye ankò.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _paymentStage = null;
        });
        _showPaymentError('Yon erè te pase: ${e.toString()}');
      }
    }
  }

  void _showPaymentError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuccessSheet(
        isCoinPurchase: _isCoinPurchase,
        onDone: () {
          Navigator.of(context).pop();
          context.pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(
          onTap: _loading ? null : () => context.pop(),
        ),
        title: const Text(
          'Ajoute kat ou',
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
              color: const Color(0xFF635BFF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.3)),
            ),
            child: const Text(
              'stripe',
              style: TextStyle(
                color: Color(0xFF635BFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSecurityRow(),
            const SizedBox(height: 20),
            _buildCardInfoSection(),
            const SizedBox(height: 16),
            _buildBillingAddressSection(),
            const SizedBox(height: 16),
            _buildSaveCardRow(),
            const SizedBox(height: 24),
            GradButton(
              label: 'Peye $_priceLabel',
              onTap: (_loading || !_cardComplete) ? null : _processPayment,
              loading: _loading,
              icon: Icons.lock_rounded,
            ),
            if (_paymentStage != null) ...[
              const SizedBox(height: 12),
              _PaymentStageRow(label: _paymentStage!, loading: _loading),
            ],
            const SizedBox(height: 16),
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Lè w klike sou "Peye", ou dakò ak tèm sèvis nou yo epi ou rekonèt ke w li règleman sou vi prive nou an.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/accept.png',
            height: 36,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.lock_rounded, color: AppColors.success, size: 12),
              SizedBox(width: 5),
              Text(
                'Pèman an sekirize ak Stripe  •  SSL chifre',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.credit_card_rounded,
                      color: AppColors.purpleLight, size: 18),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Enfòmasyon kat',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(Icons.lock_rounded,
                    color: AppColors.textMuted, size: 13),
                const SizedBox(width: 4),
                const Text(
                  'SSL',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.35)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: CardField(
              controller: _cardController,
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.border,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppColors.purpleLight.withValues(alpha: 0.6),
                      width: 1.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide:
                      const BorderSide(color: Colors.transparent, width: 0),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              onCardChanged: (details) {
                setState(() => _cardComplete = details?.complete ?? false);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NON SOU KAT',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Jean Michel',
                  prefixIcon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.name,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KÒD POSTAL',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 6),
                _buildTextField(
                  hint: '12345',
                  prefixIcon: Icons.location_on_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(Icons.security_rounded,
                    color: AppColors.success, size: 13),
                SizedBox(width: 5),
                Text(
                  'Pèman sekirize pa Stripe',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _buildBillingAddressSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Adrès faktirasyon',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Text(
                  'Menm ak adrès mwen an',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showBillingAddress,
                  onChanged: (v) => setState(() => _showBillingAddress = v),
                  activeThumbColor: AppColors.purpleLight,
                  activeTrackColor:
                      AppColors.purpleLight.withValues(alpha: 0.35),
                  inactiveThumbColor: AppColors.textMuted,
                  inactiveTrackColor:
                      AppColors.textMuted.withValues(alpha: 0.2),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
          if (_showBillingAddress) ...[
            Container(
                height: 1, color: AppColors.border.withValues(alpha: 0.35)),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  _buildCountryField(),
                  const SizedBox(height: 10),
                  _buildTextField(
                      controller: _address1Controller,
                      hint: '123 Main Street',
                      prefixIcon: Icons.home_outlined,
                      label: 'ADRÈS 1',
                      keyboardType: TextInputType.streetAddress),
                  const SizedBox(height: 10),
                  _buildTextField(
                      controller: _address2Controller,
                      hint: 'Apt, suite, unit, elatriye.',
                      prefixIcon: Icons.apartment_rounded,
                      label: 'ADRÈS 2 (opsyonèl)',
                      keyboardType: TextInputType.streetAddress),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildTextField(
                            controller: _cityController,
                            hint: 'Miami',
                            prefixIcon: Icons.location_city_rounded,
                            label: 'VIL',
                            keyboardType: TextInputType.text),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: _selectedCountry == 'Etazini'
                            ? _buildStateDropdown()
                            : _buildTextField(
                                hint: 'FL',
                                label: 'LETA',
                                keyboardType: TextInputType.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                      controller: _billingZipController,
                      hint: '33101',
                      prefixIcon: Icons.markunread_mailbox_outlined,
                      label: 'KÒD POSTAL',
                      keyboardType: TextInputType.number),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSaveCardRow() {
    return GestureDetector(
      onTap: () => setState(() => _saveCard = !_saveCard),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _saveCard
                  ? AppColors.purpleLight.withValues(alpha: 0.5)
                  : AppColors.border.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _saveCard ? AppColors.purpleLight : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _saveCard ? AppColors.purpleLight : AppColors.border,
                  width: 1.5,
                ),
              ),
              child: _saveCard
                  ? const Icon(Icons.check_rounded,
                      color: Colors.white, size: 15)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Sovgade kat sa a pou pwochen acha yo',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const Icon(Icons.lock_outline_rounded,
                color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String hint,
    IconData? prefixIcon,
    String? label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg0,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textMuted, size: 18)
                  : null,
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PEYI',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showCountryPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.public_rounded,
                    color: AppColors.textMuted, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedCountry,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Center(
            child: Text('Chwazi Peyi',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 12),
          ..._countries.map((c) => ListTile(
                title: Text(c,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                trailing: _selectedCountry == c
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.purpleLight)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCountry = c;
                    _selectedState = null;
                  });
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'LETA',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showStatePicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.bg0,
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedState ?? 'FL',
                    style: TextStyle(
                      color: _selectedState != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: AppColors.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStatePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          const Center(
            child: Text('Chwazi Leta',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(height: 12),
          ..._usStates.map((s) => ListTile(
                title: Text(s,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontFamily: 'Poppins')),
                trailing: _selectedState == s
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.purpleLight)
                    : null,
                onTap: () {
                  setState(() => _selectedState = s);
                  Navigator.pop(context);
                },
              )),
        ],
      ),
    );
  }
}

class _PaymentStageRow extends StatelessWidget {
  final String label;
  final bool loading;

  const _PaymentStageRow({required this.label, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          if (loading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.purpleLight),
            )
          else
            const Icon(Icons.info_outline_rounded,
                color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessSheet extends StatefulWidget {
  final VoidCallback onDone;
  final bool isCoinPurchase;
  const _SuccessSheet({required this.onDone, required this.isCoinPurchase});

  @override
  State<_SuccessSheet> createState() => _SuccessSheetState();
}

class _SuccessSheetState extends State<_SuccessSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
      decoration: const BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: FadeTransition(
        opacity: _fade,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(height: 28),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleLight.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.isCoinPurchase
                  ? 'Nou ajoute Coins yo!'
                  : 'Boost aktive! ⚡',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.isCoinPurchase
                  ? 'Boulva Coins yo ap parèt nan balans ou.'
                  : 'Agiman ou ap parèt pi anlè.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontFamily: 'Poppins',
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            GradButton(label: 'Retounen', onTap: widget.onDone),
          ],
        ),
      ),
    );
  }
}
