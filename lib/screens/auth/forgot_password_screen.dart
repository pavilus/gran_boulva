import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();

  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailCtrl.text.trim(),
      );
      if (mounted) setState(() => _sent = true);
    } on AuthException catch (e) {
      if (mounted) _showError(_mapAuthError(e.message));
    } catch (_) {
      if (mounted) _showError('Yon erè te fèt. Tanpri eseye ankò.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Twòp demann. Tanpri tann yon ti moman.';
    }
    if (lower.contains('invalid email') ||
        lower.contains('unable to validate')) {
      return 'Imèl pa valid.';
    }
    return 'Imèl sa pa egziste. Eseye ankò.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.bg0,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Back button
                AppBackButton(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/login'),
                  margin: EdgeInsets.zero,
                ),
                const SizedBox(height: 40),

                // Lock icon
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border, width: 1.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x406F2BFF),
                        blurRadius: 24,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    color: AppColors.purpleLight,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 28),

                // Title
                const Text(
                  'Bliye modpas?',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Antre imèl ou epi n ap voye yon lyen pou ou reyinisyalize modpas ou.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: AppColors.textMuted,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 40),

                // Success state
                if (_sent) ...[
                  _SuccessBanner(email: _emailCtrl.text.trim()),
                  const SizedBox(height: 32),
                  GradButton(
                    label: 'Retounen konekte',
                    onTap: () => context.go('/login'),
                  ),
                ] else ...[
                  // Email form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Imèl',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Imèl obligatwa';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(v.trim())) {
                              return 'Imèl pa valid';
                            }
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: 'imèl@egzanp.com',
                            hintStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 15,
                              color: AppColors.textDim,
                            ),
                            filled: true,
                            fillColor: AppColors.card,
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                              color: AppColors.textDim,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 1),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.border, width: 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.purpleLight, width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.error, width: 1),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.error, width: 1.5),
                            ),
                            errorStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 32),
                        GradButton(
                          label: 'Voye lyen pou resèt',
                          onTap: _loading ? null : _sendReset,
                          loading: _loading,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Tounen nan koneksyon',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessBanner extends StatelessWidget {
  final String email;

  const _SuccessBanner({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
              SizedBox(width: 10),
              Text(
                'Imèl voye!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Nou te voye yon lyen pou reyinisyalize modpas ou nan $email. Tcheke bwat imèl ou, gade menm nan spam.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
