import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../widgets/common/grad_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (mounted) context.go('/home');
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
    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials')) {
      return 'Imèl oswa modpas ou pa kòrèk.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Tanpri konfime imèl ou anvan ou konekte.';
    }
    if (lower.contains('too many requests')) {
      return 'Twòp eseye. Tanpri tann yon ti moman.';
    }
    return 'Koneksyon echwe. Tanpri eseye ankò.';
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 56),

                  // Logo
                  const _SplashLogo(),
                  const SizedBox(height: 20),

                  // App name
                  const Text(
                    'GRAN BOULVA',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Konekte pou kontinye',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Email field
                  _InputField(
                    hint: 'Imèl ou',
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Imèl obligatwa';
                      }
                      if (!v.contains('@')) return 'Imèl pa valid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  _InputField(
                    hint: 'Modpas ou',
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Modpas obligatwa';
                      if (v.length < 6) return 'Modpas twò kout';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: const Text(
                        'Bliye modpas?',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.pink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Sign in button
                  GradButton(
                    label: 'Konekte',
                    onTap: _loading ? null : _signIn,
                    loading: _loading,
                  ),
                  const SizedBox(height: 32),

                  // Divider
                  const Row(
                    children: [
                      Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'oswa',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: AppColors.border)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Create account link
                  GestureDetector(
                    onTap: () => context.push('/create-account'),
                    child: RichText(
                      text: const TextSpan(
                        text: 'Pa gen kont? ',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        children: [
                          TextSpan(
                            text: 'Kreye yon kont',
                            style: TextStyle(
                              color: AppColors.purpleLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Shared sub-widgets ───────────────────────────────────────────────────────

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 112,
      height: 112,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return const SizedBox(
          width: 112,
          height: 112,
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _InputField({
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          color: AppColors.textDim,
        ),
        filled: true,
        fillColor: AppColors.card,
        prefixIcon: Icon(prefixIcon, color: AppColors.textDim, size: 20),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: AppColors.purpleLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: AppColors.error,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
