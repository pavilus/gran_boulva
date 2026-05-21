import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../config/auth_redirects.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';

class CreateAccountScreen extends StatefulWidget {
  final String? referralCode;

  const CreateAccountScreen({super.key, this.referralCode});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _referralCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _agreedToTerms = false;
  String _language = 'ht';
  String? _gender;
  DateTime? _birthDate;

  // Username availability state
  bool? _usernameAvailable; // null = unchecked, true = available, false = taken
  bool _checkingUsername = false;
  String _lastCheckedUsername = '';
  List<String> _usernameSuggestions = [];
  int _usernameCheckToken = 0;

  @override
  void initState() {
    super.initState();
    if (widget.referralCode != null) {
      _referralCtrl.text = widget.referralCode!;
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _birthDateCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _formatBirthDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initialDate =
        _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.purple,
              surface: AppColors.bg1,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthDateCtrl.text = _formatBirthDate(picked);
    });
  }

  Future<bool?> _checkUsernameAvailability(
    String username, {
    bool force = false,
  }) async {
    final trimmed = _normalizeUsername(username);
    if (trimmed.length < 3) return null;
    if (!force && trimmed == _lastCheckedUsername) return _usernameAvailable;

    final token = ++_usernameCheckToken;

    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
      _usernameSuggestions = [];
    });

    try {
      final result = await Supabase.instance.client
          .rpc('is_username_available', params: {'p_username': trimmed});
      final available = result == true;
      final suggestions =
          available ? <String>[] : await _usernameSuggestionsFor(trimmed);

      if (mounted &&
          token == _usernameCheckToken &&
          _normalizeUsername(_usernameCtrl.text) == trimmed) {
        setState(() {
          _usernameAvailable = available;
          _lastCheckedUsername = trimmed;
          _usernameSuggestions = suggestions;
        });
      }
      return available;
    } catch (_) {
      if (mounted && token == _usernameCheckToken) {
        setState(() {
          _usernameAvailable = null;
          _usernameSuggestions = [];
        });
      }
      return null;
    } finally {
      if (mounted && token == _usernameCheckToken) {
        setState(() => _checkingUsername = false);
      }
    }
  }

  Future<List<String>> _usernameSuggestionsFor(String username) async {
    final base = username.replaceAll(RegExp(r'[^a-z0-9_]'), '');
    final seeds = <String>[
      '${base}_ht',
      '${base}_509',
      '${base}_${DateTime.now().year % 100}',
      '${base}_${_firstNameCtrl.text.trim().toLowerCase()}',
      '${base}_${_lastNameCtrl.text.trim().toLowerCase()}',
    ];
    final candidates = <String>[
      for (final seed in seeds)
        seed.replaceAll(RegExp(r'[^a-z0-9_]'), '').replaceAll('__', '_'),
      for (var i = 1; i <= 60; i++) '${base}_$i',
    ].where((candidate) {
      return candidate.length >= 3 && candidate != username;
    }).toSet();

    final suggestions = <String>[];
    for (final candidate in candidates) {
      try {
        final result = await Supabase.instance.client
            .rpc('is_username_available', params: {'p_username': candidate});
        if (result == true) suggestions.add(candidate);
        if (suggestions.length == 2) break;
      } catch (_) {
        break;
      }
    }
    return suggestions;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      _showError(_language == 'ht'
          ? 'Ou dwe aksepte Tèm ak Kondisyon yo pou kontinye.'
          : 'You must agree to the Terms of Service to continue.');
      return;
    }

    final username = _normalizeUsername(_usernameCtrl.text);
    final usernameVerified =
        _lastCheckedUsername == username && _usernameAvailable == true
            ? true
            : await _checkUsernameAvailability(username, force: true);
    if (usernameVerified != true) {
      _showError(usernameVerified == false
          ? _copy.usernameTaken
          : _copy.usernameCheckFailed);
      return;
    }

    setState(() => _loading = true);

    try {
      final email = _emailCtrl.text.trim();
      final password = _passwordCtrl.text;
      final fullName =
          '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
      final referralCode = _referralCtrl.text.trim();
      final country = _countryCtrl.text.trim();
      final phone = _phoneCtrl.text.trim();

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: AuthRedirects.authCallback,
        data: {
          'full_name': fullName,
          'username': username,
          'language': _language,
          'gender': _gender,
          'date_of_birth': _birthDateCtrl.text.trim(),
          if (country.isNotEmpty) 'country': country,
          if (phone.isNotEmpty) 'phone_number': phone,
          if (referralCode.isNotEmpty) 'referral_code': referralCode,
        },
      );

      final userId = response.user?.id;
      if (userId == null) {
        // Supabase returns null user when email confirmation is on and address already exists.
        if (mounted) {
          _showError(_copy.emailMayAlreadyExist);
          setState(() => _loading = false);
        }
        return;
      }

      if (mounted) {
        _showVerificationNotice();
        await Future<void>.delayed(const Duration(milliseconds: 900));
        if (mounted) context.go('/login');
      }
    } on AuthException catch (e) {
      if (mounted) _showError(_mapAuthError(e.message));
    } catch (e) {
      if (mounted) _showError(_mapUnexpectedSignupError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('username_taken') ||
        lower.contains('username') ||
        lower.contains('duplicate key')) {
      return _copy.usernameTaken;
    }
    if (lower.contains('already registered') ||
        lower.contains('already been registered')) {
      return _copy.emailAlreadyUsed;
    }
    if (lower.contains('database error')) {
      return _copy.profileCreateFailed;
    }
    if (lower.contains('password')) {
      return _copy.weakPassword;
    }
    if (lower.contains('invalid email')) {
      return _copy.emailInvalid;
    }
    return _copy.createFailed;
  }

  String _mapUnexpectedSignupError(Object error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('username_taken') ||
        lower.contains('username') ||
        lower.contains('duplicate') ||
        lower.contains('unique')) {
      return _copy.usernameTaken;
    }
    if (lower.contains('email')) return _copy.emailAlreadyUsed;
    if (lower.contains('network') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return _copy.networkError;
    }
    if (lower.contains('row-level security') || lower.contains('permission')) {
      return _copy.profileCreateFailed;
    }
    return _copy.createFailed;
  }

  _CreateAccountCopy get _copy => _language == 'en'
      ? _CreateAccountCopy.english
      : _CreateAccountCopy.kreyol;

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

  void _showVerificationNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Nou voye yon lyen verifikasyon. Tcheke imèl ou ak spam.',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                  // Back button
                  AppBackButton(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/login'),
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 28),

                  _LanguageToggle(
                    value: _language,
                    onChanged: (value) => setState(() => _language = value),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      _copy.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _copy.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // First name + Last name
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(_copy.firstName, required: true),
                            const SizedBox(height: 8),
                            _AuthInputField(
                              hint: _copy.firstNameHint,
                              controller: _firstNameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return _copy.required;
                                }
                                if (v.trim().length < 2) return _copy.tooShort;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(_copy.lastName, required: true),
                            const SizedBox(height: 8),
                            _AuthInputField(
                              hint: _copy.lastNameHint,
                              controller: _lastNameCtrl,
                              prefixIcon: Icons.person_outline_rounded,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return _copy.required;
                                }
                                if (v.trim().length < 2) return _copy.tooShort;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Username
                  _label(_copy.username, required: true),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.usernameHint,
                    controller: _usernameCtrl,
                    prefixIcon: Icons.alternate_email_rounded,
                    suffixWidget: _usernameSuffix(),
                    onChanged: (v) {
                      if (v.trim().length >= 3) {
                        _checkUsernameAvailability(v);
                      } else {
                        setState(() {
                          _usernameAvailable = null;
                          _lastCheckedUsername = '';
                          _usernameSuggestions = [];
                        });
                      }
                    },
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _copy.usernameRequired;
                      }
                      if (v.trim().length < 3) return _copy.usernameTooShort;
                      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(v.trim())) {
                        return _copy.usernameRule;
                      }
                      if (_usernameAvailable == false) {
                        return _copy.usernameTaken;
                      }
                      return null;
                    },
                  ),
                  _usernameAvailabilityHint(),
                  const SizedBox(height: 20),

                  _label(_copy.gender, required: true),
                  const SizedBox(height: 8),
                  _GenderSelectField(
                    value: _gender,
                    hint: _copy.genderHint,
                    options: _copy.genderOptions,
                    validator: (v) =>
                        v == null || v.isEmpty ? _copy.genderRequired : null,
                    onChanged: (value) => setState(() => _gender = value),
                  ),
                  const SizedBox(height: 20),

                  _label(_copy.birthDate, required: true),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.birthDateHint,
                    controller: _birthDateCtrl,
                    prefixIcon: Icons.calendar_month_outlined,
                    readOnly: true,
                    onTap: _pickBirthDate,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _copy.birthDateRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(_copy.country),
                            const SizedBox(height: 8),
                            _AuthInputField(
                              hint: _copy.countryHint,
                              controller: _countryCtrl,
                              prefixIcon: Icons.public_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _label(_copy.phone),
                            const SizedBox(height: 8),
                            _AuthInputField(
                              hint: _copy.phoneHint,
                              controller: _phoneCtrl,
                              keyboardType: TextInputType.phone,
                              prefixIcon: Icons.phone_outlined,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9+() -]'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Email
                  _label(_copy.email, required: true),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.emailHint,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _copy.emailRequired;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                        return _copy.emailInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password
                  _label(_copy.password, required: true),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.passwordHint,
                    controller: _passwordCtrl,
                    obscure: _obscurePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixWidget: IconButton(
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
                      if (v == null || v.isEmpty) return _copy.passwordRequired;
                      if (v.length < 8) {
                        return _copy.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm password
                  _label(_copy.confirmPassword, required: true),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.confirmPasswordHint,
                    controller: _confirmPasswordCtrl,
                    obscure: _obscureConfirm,
                    prefixIcon: Icons.lock_outline_rounded,
                    suffixWidget: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return _copy.confirmPasswordRequired;
                      }
                      if (v != _passwordCtrl.text) {
                        return _copy.passwordMismatch;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Referral code (optional)
                  _label(_copy.referral),
                  const SizedBox(height: 8),
                  _AuthInputField(
                    hint: _copy.referralHint,
                    controller: _referralCtrl,
                    prefixIcon: Icons.card_giftcard_rounded,
                  ),
                  const SizedBox(height: 24),

                  // Terms agreement checkbox
                  GestureDetector(
                    onTap: () =>
                        setState(() => _agreedToTerms = !_agreedToTerms),
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _agreedToTerms,
                            onChanged: (v) =>
                                setState(() => _agreedToTerms = v ?? false),
                            activeColor: AppColors.purple,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4)),
                            side: const BorderSide(
                                color: AppColors.border, width: 1.5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: _language == 'ht'
                                      ? 'Mwen aksepte '
                                      : 'I agree to the ',
                                ),
                                TextSpan(
                                  text: _language == 'ht'
                                      ? 'Tèm ak Kondisyon'
                                      : 'Terms of Service',
                                  style: const TextStyle(
                                      color: AppColors.purpleLight,
                                      fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrl(
                                        Uri.parse(
                                            'https://www.granboulva.com/terms'),
                                        mode: LaunchMode.externalApplication),
                                ),
                                TextSpan(
                                    text: _language == 'ht' ? ' ak ' : ' and '),
                                TextSpan(
                                  text: _language == 'ht'
                                      ? 'Politik sou Vi Prive'
                                      : 'Privacy Policy',
                                  style: const TextStyle(
                                      color: AppColors.purpleLight,
                                      fontWeight: FontWeight.w600),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => launchUrl(
                                        Uri.parse(
                                            'https://www.granboulva.com/privacy'),
                                        mode: LaunchMode.externalApplication),
                                ),
                                TextSpan(
                                    text: _language == 'ht'
                                        ? ' Gran Boulva.'
                                        : ' of Gran Boulva.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit
                  GradButton(
                    label: _copy.submit,
                    onTap: _loading ? null : _submit,
                    loading: _loading,
                  ),
                  const SizedBox(height: 28),

                  // Login link
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/login'),
                      child: RichText(
                        text: TextSpan(
                          text: _copy.loginPrefix,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: _copy.loginAction,
                              style: const TextStyle(
                                color: AppColors.purpleLight,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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

  Widget _label(String text, {bool required = false}) {
    if (!required) {
      return Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      );
    }
    return RichText(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget? _usernameSuffix() {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textMuted,
          ),
        ),
      );
    }
    if (_usernameAvailable == true) {
      return const Icon(Icons.check_circle_rounded,
          color: AppColors.success, size: 22);
    }
    if (_usernameAvailable == false) {
      return const Icon(Icons.cancel_rounded, color: AppColors.error, size: 22);
    }
    return null;
  }

  Widget _usernameAvailabilityHint() {
    if (_checkingUsername || _usernameCtrl.text.trim().length < 3) {
      return const SizedBox.shrink();
    }
    if (_usernameAvailable == true) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          _copy.usernameAvailable,
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    if (_usernameAvailable != false) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _copy.suggestionsLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _usernameSuggestions.take(2).map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _usernameCtrl.text = suggestion;
                  _usernameCtrl.selection = TextSelection.collapsed(
                    offset: suggestion.length,
                  );
                  _checkUsernameAvailability(suggestion, force: true);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.purpleLight.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    '@$suggestion',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Shared input widget ──────────────────────────────────────────────────────

class _LanguageToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _LanguageToggle({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _LanguageOption(
            label: 'Kreyòl',
            selected: value == 'ht',
            onTap: () => onChanged('ht'),
          ),
          const SizedBox(width: 4),
          _LanguageOption(
            label: 'English',
            selected: value == 'en',
            onTap: () => onChanged('en'),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderSelectField extends StatelessWidget {
  final String? value;
  final String hint;
  final Map<String, String> options;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;

  const _GenderSelectField({
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      validator: validator,
      onChanged: onChanged,
      dropdownColor: AppColors.card,
      iconEnabledColor: AppColors.textMuted,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          color: AppColors.textDim,
        ),
        filled: true,
        fillColor: AppColors.card,
        prefixIcon:
            const Icon(Icons.wc_outlined, color: AppColors.textDim, size: 20),
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
      items: options.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
    );
  }
}

class _CreateAccountCopy {
  final String title;
  final String subtitle;
  final String firstName;
  final String firstNameHint;
  final String lastName;
  final String lastNameHint;
  final String username;
  final String usernameHint;
  final String email;
  final String emailHint;
  final String password;
  final String passwordHint;
  final String confirmPassword;
  final String confirmPasswordHint;
  final String referral;
  final String referralHint;
  final String submit;
  final String loginPrefix;
  final String loginAction;
  final String required;
  final String tooShort;
  final String usernameRequired;
  final String usernameTooShort;
  final String usernameRule;
  final String usernameTaken;
  final String usernameAvailable;
  final String usernameCheckFailed;
  final String suggestionsLabel;
  final String gender;
  final String genderHint;
  final String genderRequired;
  final Map<String, String> genderOptions;
  final String birthDate;
  final String birthDateHint;
  final String birthDateRequired;
  final String country;
  final String countryHint;
  final String phone;
  final String phoneHint;
  final String emailRequired;
  final String emailInvalid;
  final String emailAlreadyUsed;
  final String emailMayAlreadyExist;
  final String passwordRequired;
  final String passwordTooShort;
  final String weakPassword;
  final String confirmPasswordRequired;
  final String passwordMismatch;
  final String genericError;
  final String createFailed;
  final String profileCreateFailed;
  final String networkError;

  const _CreateAccountCopy({
    required this.title,
    required this.subtitle,
    required this.firstName,
    required this.firstNameHint,
    required this.lastName,
    required this.lastNameHint,
    required this.username,
    required this.usernameHint,
    required this.email,
    required this.emailHint,
    required this.password,
    required this.passwordHint,
    required this.confirmPassword,
    required this.confirmPasswordHint,
    required this.referral,
    required this.referralHint,
    required this.submit,
    required this.loginPrefix,
    required this.loginAction,
    required this.required,
    required this.tooShort,
    required this.usernameRequired,
    required this.usernameTooShort,
    required this.usernameRule,
    required this.usernameTaken,
    required this.usernameAvailable,
    required this.usernameCheckFailed,
    required this.suggestionsLabel,
    required this.gender,
    required this.genderHint,
    required this.genderRequired,
    required this.genderOptions,
    required this.birthDate,
    required this.birthDateHint,
    required this.birthDateRequired,
    required this.country,
    required this.countryHint,
    required this.phone,
    required this.phoneHint,
    required this.emailRequired,
    required this.emailInvalid,
    required this.emailAlreadyUsed,
    required this.emailMayAlreadyExist,
    required this.passwordRequired,
    required this.passwordTooShort,
    required this.weakPassword,
    required this.confirmPasswordRequired,
    required this.passwordMismatch,
    required this.genericError,
    required this.createFailed,
    required this.profileCreateFailed,
    required this.networkError,
  });

  static const kreyol = _CreateAccountCopy(
    title: 'Kreye kont ou',
    subtitle: 'Ranpli enfòmasyon yo pou kòmanse',
    firstName: 'Prenon',
    firstNameHint: 'Ex: Jean',
    lastName: 'Siyati',
    lastNameHint: 'Ex: Pierre',
    username: 'Non itilizatè',
    usernameHint: 'Ex: jean_pierre',
    email: 'Imèl',
    emailHint: 'imèl@egzanp.com',
    password: 'Modpas',
    passwordHint: 'Omwen 8 karaktè',
    confirmPassword: 'Konfime modpas',
    confirmPasswordHint: 'Remete modpas la',
    referral: 'Kòd referans (opsyonèl)',
    referralHint: 'Kòd zanmi ou siw gen youn',
    submit: 'Kreye kont',
    loginPrefix: 'Deja gen kont? ',
    loginAction: 'Konekte',
    required: 'Obligatwa',
    tooShort: 'Twò kout',
    usernameRequired: 'Non itilizatè obligatwa',
    usernameTooShort: 'Omwen 3 karaktè',
    usernameRule: 'Sèlman lèt, chif, ak underscore',
    usernameTaken: 'Non sa deja itilize. Chwazi yon lòt.',
    usernameAvailable: 'Non sa disponib.',
    usernameCheckFailed:
        'Nou pa ka verifye non itilizatè a kounye a. Eseye ankò.',
    suggestionsLabel: 'Non sa deja itilize. Eseye youn nan sa yo:',
    gender: 'Sèks',
    genderHint: 'Chwazi sèks ou',
    genderRequired: 'Sèks obligatwa',
    genderOptions: {
      'female': 'Fi',
      'male': 'Gason',
      'non_binary': 'Non-binè',
      'prefer_not_to_say': 'Mwen pito pa di',
    },
    birthDate: 'Dat nesans',
    birthDateHint: 'AAAA-MM-JJ',
    birthDateRequired: 'Dat nesans obligatwa',
    country: 'Peyi',
    countryHint: 'Ex: Ayiti',
    phone: 'Telefòn',
    phoneHint: '+509...',
    emailRequired: 'Imèl obligatwa',
    emailInvalid: 'Imèl pa valid.',
    emailAlreadyUsed: 'Imèl sa a deja itilize. Eseye konekte.',
    emailMayAlreadyExist:
        'Si imèl sa a deja gen yon kont, konekte oswa itilize "Mwen bliye modpas mwen". Si li nouvo, eseye ankò nan kèk minit.',
    passwordRequired: 'Modpas obligatwa',
    passwordTooShort: 'Modpas dwe gen 8 karaktè pou pi piti',
    weakPassword: 'Modpas la twò fèb. Itilize pou pi piti 8 karaktè.',
    confirmPasswordRequired: 'Konfime modpas la',
    passwordMismatch: 'Modpas yo pa menm',
    genericError: 'Yon erè te fèt. Tanpri eseye ankò.',
    createFailed: 'Kreye kont echwe. Verifye enfòmasyon yo epi eseye ankò.',
    profileCreateFailed:
        'Kont lan pa t ka finalize. Eseye ankò; si sa kontinye, kontakte sipò.',
    networkError: 'Koneksyon an pa mache. Tcheke entènèt ou epi eseye ankò.',
  );

  static const english = _CreateAccountCopy(
    title: 'Create your account',
    subtitle: 'Fill in your information to get started',
    firstName: 'First name',
    firstNameHint: 'Ex: Jean',
    lastName: 'Last name',
    lastNameHint: 'Ex: Pierre',
    username: 'Username',
    usernameHint: 'Ex: jean_pierre',
    email: 'Email',
    emailHint: 'email@example.com',
    password: 'Password',
    passwordHint: 'At least 8 characters',
    confirmPassword: 'Confirm password',
    confirmPasswordHint: 'Enter the password again',
    referral: 'Referral code (optional)',
    referralHint: 'Your friend’s code if you have one',
    submit: 'Create account',
    loginPrefix: 'Already have an account? ',
    loginAction: 'Log in',
    required: 'Required',
    tooShort: 'Too short',
    usernameRequired: 'Username is required',
    usernameTooShort: 'At least 3 characters',
    usernameRule: 'Only letters, numbers, and underscore',
    usernameTaken: 'This username is already taken. Choose another.',
    usernameAvailable: 'This username is available.',
    usernameCheckFailed:
        'We could not verify this username right now. Please try again.',
    suggestionsLabel: 'This username is taken. Try one of these:',
    gender: 'Sex',
    genderHint: 'Select your sex',
    genderRequired: 'Sex is required',
    genderOptions: {
      'female': 'Female',
      'male': 'Male',
      'non_binary': 'Non-binary',
      'prefer_not_to_say': 'Prefer not to say',
    },
    birthDate: 'Date of birth',
    birthDateHint: 'YYYY-MM-DD',
    birthDateRequired: 'Date of birth is required',
    country: 'Country',
    countryHint: 'Ex: Haiti',
    phone: 'Phone',
    phoneHint: '+509...',
    emailRequired: 'Email is required',
    emailInvalid: 'Email is not valid.',
    emailAlreadyUsed: 'This email is already in use. Try logging in.',
    emailMayAlreadyExist:
        'If this email already has an account, log in or use "Forgot password". If it is new, try again in a few minutes.',
    passwordRequired: 'Password is required',
    passwordTooShort: 'Password must be at least 8 characters',
    weakPassword: 'Password is too weak. Use at least 8 characters.',
    confirmPasswordRequired: 'Confirm your password',
    passwordMismatch: 'Passwords do not match',
    genericError: 'Something went wrong. Please try again.',
    createFailed:
        'Account creation failed. Check your information and try again.',
    profileCreateFailed:
        'Your account could not be finalized. Try again; if it continues, contact support.',
    networkError: 'Connection failed. Check your internet and try again.',
  );
}

class _AuthInputField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final Widget? suffixWidget;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;

  const _AuthInputField({
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    required this.prefixIcon,
    this.suffixWidget,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      inputFormatters: inputFormatters,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      validator: validator,
      onChanged: onChanged,
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
        suffixIcon: suffixWidget,
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
