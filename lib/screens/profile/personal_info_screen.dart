import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final user = await _userService.getProfile();
      if (!mounted) return;
      setState(() {
        _nameCtrl.text = user?.fullName ?? '';
        _usernameCtrl.text = user?.username ?? '';
        _bioCtrl.text = user?.bio ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final username = _usernameCtrl.text.trim();
    if (name.isEmpty || username.isEmpty) {
      _showSnack('Non ak non itilizatè obligatwa.', error: true);
      return;
    }
    if (_bioCtrl.text.trim().length > 120) {
      _showSnack('About dwe gen 120 karaktè oswa mwens.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await _userService.updateProfile(
        fullName: name,
        username: username,
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
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
        title: const Text('Enfòmasyon pèsonèl',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins')),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _saving ? null : _save,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                  : const Text('Sove',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildField(
                  label: 'Non konplè',
                  controller: _nameCtrl,
                  hint: 'Ou non konplè',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Non itilizatè',
                  controller: _usernameCtrl,
                  hint: '@yourusername',
                  icon: Icons.alternate_email_rounded,
                  prefix: '@',
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'About',
                  controller: _bioCtrl,
                  hint: 'Di yon bagay sou ou...',
                  icon: Icons.edit_note_rounded,
                  maxLines: 2,
                  maxLength: 120,
                ),
                const SizedBox(height: 12),
                _buildField(
                  label: 'Lokasyon',
                  controller: _locationCtrl,
                  hint: 'Kote ou ye?',
                  icon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 24),
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
                            fontFamily: 'Poppins'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    int? maxLength,
    String? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins')),
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
                  inputFormatters: maxLength == null
                      ? null
                      : [LengthLimitingTextInputFormatter(maxLength)],
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
                      fontFamily: 'Poppins',
                    ),
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
