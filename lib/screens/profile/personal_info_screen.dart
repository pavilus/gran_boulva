import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _userService = UserService();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _birthDateCtrl = TextEditingController();

  String? _gender;
  DateTime? _birthDate;
  bool _loading = true;
  bool _saving = false;
  bool _isVerified = false;

  static const _genderOptions = {
    'female': 'Fi',
    'male': 'Gason',
    'non_binary': 'Non-binè',
    'prefer_not_to_say': 'Mwen pito pa di',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _countryCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  Future<void> _load() async {
    try {
      final user = await _userService.getProfile();
      if (!mounted) return;
      setState(() {
        _isVerified = user?.isVerified ?? false;

        // split full_name into first / last
        final parts = (user?.fullName ?? '').trim().split(' ');
        _firstNameCtrl.text = parts.isNotEmpty ? parts.first : '';
        _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';

        _usernameCtrl.text = user?.username ?? '';
        _bioCtrl.text = user?.bio ?? '';
        _countryCtrl.text = user?.country ?? '';
        _phoneCtrl.text = user?.phoneNumber ?? '';
        _gender = user?.gender;

        if (user?.dateOfBirth != null) {
          _birthDate = user!.dateOfBirth;
          _birthDateCtrl.text = _formatDate(user.dateOfBirth!);
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 18, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.purple,
            surface: AppColors.bg1,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthDateCtrl.text = _formatDate(picked);
    });
  }

  Future<void> _save() async {
    final firstName = _firstNameCtrl.text.trim();
    final lastName = _lastNameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();

    if (firstName.isEmpty || username.isEmpty) {
      _showSnack('Prenon ak non itilizatè obligatwa.', error: true);
      return;
    }
    if (_bioCtrl.text.trim().length > 120) {
      _showSnack('Yon bagay sou mwen dwe gen 120 karaktè oswa mwens.',
          error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final fullName = lastName.isEmpty ? firstName : '$firstName $lastName';
      await _userService.updateProfile(
        fullName: fullName,
        username: username,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        gender: _gender,
        dateOfBirth: _birthDate,
        country:
            _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
        phoneNumber:
            _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      );
      if (mounted) {
        _showSnack('Pwofil mete ajou avèk siksè!');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Erè: ${e.toString()}', error: true);
        setState(() => _saving = false);
      }
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

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        title: const Text(
          'Enfòmasyon pèsonèl',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          if (!_isVerified)
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text(
                        'Sovgade',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _isVerified
              ? _buildLockedView()
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── First name + Last name ─────────────────────
                    Row(children: [
                      Expanded(
                          child: _buildField(
                        label: 'Prenon',
                        controller: _firstNameCtrl,
                        hint: 'Ex: Jean',
                        icon: Icons.person_outline_rounded,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildField(
                        label: 'Siyati',
                        controller: _lastNameCtrl,
                        hint: 'Ex: Pierre',
                        icon: Icons.person_outline_rounded,
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // ── Username ───────────────────────────────────
                    _buildField(
                      label: 'Non itilizatè',
                      controller: _usernameCtrl,
                      hint: 'Ex: jean_pierre',
                      icon: Icons.alternate_email_rounded,
                      prefix: '@',
                    ),
                    const SizedBox(height: 12),

                    // ── Gender ─────────────────────────────────────
                    _buildLabel('Sèks'),
                    const SizedBox(height: 6),
                    _buildGenderDropdown(),
                    const SizedBox(height: 12),

                    // ── Date of birth ──────────────────────────────
                    _buildField(
                      label: 'Dat nesans',
                      controller: _birthDateCtrl,
                      hint: 'AAAA-MM-JJ',
                      icon: Icons.calendar_month_outlined,
                      readOnly: true,
                      onTap: _pickBirthDate,
                    ),
                    const SizedBox(height: 12),

                    // ── Country + Phone ────────────────────────────
                    Row(children: [
                      Expanded(
                          child: _buildField(
                        label: 'Peyi',
                        controller: _countryCtrl,
                        hint: 'Ex: Ayiti',
                        icon: Icons.public_rounded,
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildField(
                        label: 'Telefòn',
                        controller: _phoneCtrl,
                        hint: '+509...',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9+() -]')),
                        ],
                      )),
                    ]),
                    const SizedBox(height: 12),

                    // ── Bio ────────────────────────────────────────
                    _buildField(
                      label: 'Yon bagay sou mwen',
                      controller: _bioCtrl,
                      hint: 'Di yon bagay sou ou...',
                      icon: Icons.edit_note_rounded,
                      maxLines: 2,
                      maxLength: 120,
                    ),
                    const SizedBox(height: 24),

                    // ── Info banner ────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.purpleDim,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppColors.purpleLight, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Chanjman yo ap parèt sou pwofil ou imedyatman.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
    );
  }

  // ── Locked view (verified users) ──────────────────────────────
  Widget _buildLockedView() {
    final name = [_firstNameCtrl.text, _lastNameCtrl.text]
        .where((s) => s.isNotEmpty)
        .join(' ');
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF14B8A6).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified_rounded,
                color: Color(0xFF14B8A6), size: 36),
          ),
          const SizedBox(height: 20),
          const Text(
            'Pwofil ou verifye ✅',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Bonjou $name,\nPwofil verifye yo pa ka modifye dirèkteman. Kontakte ekip sipò nou pou fè nenpòt chanjman.',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => context.push('/help'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Text(
                'Kontakte Sipò',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Gender dropdown ────────────────────────────────────────────
  Widget _buildGenderDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender,
          hint: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'Chwazi sèks ou',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          isExpanded: true,
          dropdownColor: AppColors.card,
          iconEnabledColor: AppColors.textMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
          items: _genderOptions.entries.map((e) {
            return DropdownMenuItem(value: e.key, child: Text(e.value));
          }).toList(),
          onChanged: (v) => setState(() => _gender = v),
        ),
      ),
    );
  }

  // ── Label ──────────────────────────────────────────────────────
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    );
  }

  // ── Field ──────────────────────────────────────────────────────
  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? prefix,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(
                    left: 14, top: maxLines > 1 ? 14 : 0, right: 4),
                child: SizedBox(
                  height: maxLines > 1 ? null : 50,
                  child: Center(
                    child: Icon(icon, color: AppColors.textMuted, size: 18),
                  ),
                ),
              ),
              if (prefix != null)
                Padding(
                  padding: const EdgeInsets.only(top: 15),
                  child: Text(prefix,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontFamily: 'Poppins')),
                ),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  maxLength: maxLength,
                  readOnly: readOnly,
                  onTap: onTap,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters ??
                      (maxLength != null
                          ? [LengthLimitingTextInputFormatter(maxLength)]
                          : null),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                        fontFamily: 'Poppins'),
                    border: InputBorder.none,
                    counterStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
