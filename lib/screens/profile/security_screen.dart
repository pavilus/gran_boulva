import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/app_back_button.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _newPasswordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _saving = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _newPasswordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final newPass = _newPasswordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.length < 8) {
      _showSnack('Modpas la dwe gen omwen 8 karaktè.', error: true);
      return;
    }
    if (newPass != confirm) {
      _showSnack('Modpas yo pa menm.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      if (mounted) {
        _showSnack('Modpas chanje avèk siksè!');
        _newPasswordCtrl.clear();
        _confirmCtrl.clear();
      }
    } catch (e) {
      if (mounted) _showSnack('Erè: ${e.toString()}', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Poppins')),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(
          onTap: () => Navigator.of(context).pop(),
        ),
        title: const Text('Sekirite ak vi prive',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionLabel('Chanje modpas'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _passwordField(
                controller: _newPasswordCtrl,
                hint: 'Nouvo modpas (min. 8 karaktè)',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
                showDivider: true,
              ),
              _passwordField(
                controller: _confirmCtrl,
                hint: 'Konfime nouvo modpas',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                showDivider: false,
              ),
            ]),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _saving ? null : _changePassword,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Chanje modpas',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins')),
              ),
            ),
          ),
          const SizedBox(height: 28),
          _sectionLabel('Vi prive'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(children: [
              _privacyTile(
                icon: Icons.lock_outline_rounded,
                title: 'Pwofil piblik',
                subtitle: 'Moun ka wè pwofil ou',
                value: true,
                onChanged: (_) {},
                showDivider: true,
              ),
              _privacyTile(
                icon: Icons.visibility_outlined,
                title: 'Montre aktivite',
                subtitle: 'Moun ka wè kote ou vote',
                value: false,
                onChanged: (_) {},
                showDivider: false,
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            fontFamily: 'Poppins'),
      );

  Widget _passwordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required bool showDivider,
  }) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Poppins'),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Poppins'),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              obscure
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
        ]),
      ),
      if (showDivider)
        const Divider(
            height: 1, color: AppColors.borderDim, indent: 14, endIndent: 14),
    ]);
  }

  Widget _privacyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(icon, color: AppColors.purpleLight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins')),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ]),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.purple,
            activeTrackColor: AppColors.purpleDim,
          ),
        ]),
      ),
      if (showDivider)
        const Divider(
            height: 1, color: AppColors.borderDim, indent: 16, endIndent: 16),
    ]);
  }
}
