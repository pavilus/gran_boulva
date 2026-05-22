import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/verification_badge.dart';

class VerificationRequestScreen extends StatefulWidget {
  const VerificationRequestScreen({super.key});

  @override
  State<VerificationRequestScreen> createState() =>
      _VerificationRequestScreenState();
}

class _VerificationRequestScreenState extends State<VerificationRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _organizationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _organizationEmailCtrl = TextEditingController();
  final _socialLinksCtrl = TextEditingController();
  final _proofNotesCtrl = TextEditingController();
  final _picker = ImagePicker();

  String _type = 'standard';
  bool _submitting = false;
  bool _loading = true;
  List<VerificationRequestModel> _requests = [];
  List<XFile> _selectedDocuments = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _legalNameCtrl.dispose();
    _organizationCtrl.dispose();
    _websiteCtrl.dispose();
    _organizationEmailCtrl.dispose();
    _socialLinksCtrl.dispose();
    _proofNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    try {
      final requests = await VerificationService().getMyRequests();
      if (mounted) {
        setState(() {
          _requests = requests;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final request = await VerificationService().submitRequest(
        verificationType: _type,
        displayName: _clean(_displayNameCtrl.text),
        legalName: _clean(_legalNameCtrl.text),
        organizationName: _clean(_organizationCtrl.text),
        website: _clean(_websiteCtrl.text),
        organizationEmail: _clean(_organizationEmailCtrl.text),
        socialLinks: _clean(_socialLinksCtrl.text),
        proofNotes: _clean(_proofNotesCtrl.text),
      );
      for (final document in _selectedDocuments) {
        await VerificationService().uploadDocument(
          requestId: request.id,
          bytes: await document.readAsBytes(),
          fileName: document.name,
        );
      }
      if (!mounted) return;
      _displayNameCtrl.clear();
      _legalNameCtrl.clear();
      _organizationCtrl.clear();
      _websiteCtrl.clear();
      _organizationEmailCtrl.clear();
      _socialLinksCtrl.clear();
      _proofNotesCtrl.clear();
      setState(() => _selectedDocuments = []);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demann verifikasyon an voye.')),
      );
      await _loadRequests();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pa kapab voye demann nan kounye a.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDocuments() async {
    final images = await _picker.pickMultiImage(imageQuality: 82);
    if (images.isEmpty) return;
    setState(() {
      _selectedDocuments = [
        ..._selectedDocuments,
        ...images,
      ].take(5).toList();
    });
  }

  void _removeDocument(int index) {
    setState(() => _selectedDocuments.removeAt(index));
  }

  String? _clean(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        title: const Text(
          'Verifikasyon',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFormCard(),
          const SizedBox(height: 20),
          _buildHistory(),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mande badj verifye',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ekip la ap revize idantite, prezans piblik, oswa prèv òganizasyon an anvan badj la parèt sou pwofil ou.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                height: 1.45,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _type,
              dropdownColor: AppColors.card,
              decoration: _decoration('Tip verifikasyon'),
              items: const [
                DropdownMenuItem(value: 'standard', child: Text('Verifye')),
                DropdownMenuItem(
                    value: 'public_figure', child: Text('Pèsonalite piblik')),
                DropdownMenuItem(
                    value: 'organization', child: Text('Òganizasyon')),
                DropdownMenuItem(
                    value: 'trusted_creator', child: Text('Kreyatè serye')),
              ],
              onChanged: (value) => setState(() => _type = value ?? _type),
            ),
            const SizedBox(height: 12),
            _field(_displayNameCtrl, 'Non ki dwe parèt sou pwofil la',
                required: true),
            const SizedBox(height: 12),
            _field(_legalNameCtrl, 'Non legal oswa non responsab la',
                required: true),
            if (_type == 'organization') ...[
              const SizedBox(height: 12),
              _field(_organizationCtrl, 'Non òganizasyon an', required: true),
              const SizedBox(height: 12),
              _field(_organizationEmailCtrl, 'Imèl òganizasyon an'),
              const SizedBox(height: 12),
              _field(_websiteCtrl, 'Sit entènèt'),
            ],
            const SizedBox(height: 12),
            _field(
              _socialLinksCtrl,
              'Lyen piblik oswa rezo sosyal',
              required: _type != 'standard',
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _field(
              _proofNotesCtrl,
              'Prèv oswa nòt pou ekip revizyon an',
              required: true,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            _buildDocumentPicker(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.verified_user_outlined),
                label: Text(_submitting ? 'Ap voye...' : 'Voye demann'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purpleLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentPicker() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Dokiman / foto prèv',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _selectedDocuments.length >= 5 || _submitting
                    ? null
                    : _pickDocuments,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Ajoute'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ajoute jiska 5 imaj: ID, screenshot sosyal, dokiman òganizasyon, oswa lòt prèv.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              height: 1.35,
              fontFamily: 'Poppins',
            ),
          ),
          if (_selectedDocuments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _selectedDocuments.length; i++)
                  InputChip(
                    label: Text(
                      _selectedDocuments[i].name,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onDeleted: _submitting ? null : () => _removeDocument(i),
                    backgroundColor: AppColors.card,
                    labelStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontFamily: 'Poppins',
                    ),
                    deleteIconColor: AppColors.textMuted,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistory() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: AppColors.purpleLight),
        ),
      );
    }
    if (_requests.isEmpty) {
      return const Text(
        'Ou poko voye okenn demann verifikasyon.',
        style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Demann mwen yo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 10),
        ..._requests.map(_requestTile),
      ],
    );
  }

  Widget _requestTile(VerificationRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.card.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          VerificationBadge(
            type: request.verificationType,
            status: 'approved',
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.typeLabel,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  '${_statusLabel(request.status)}'
                  '${request.documents.isEmpty ? '' : ' · ${request.documents.length} dokiman'}',
                  style: TextStyle(
                    color: _statusColor(request.status),
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          if (request.rejectionReason?.isNotEmpty == true)
            const Icon(Icons.info_outline_rounded,
                color: AppColors.warning, size: 18),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontFamily: 'Poppins',
      ),
      decoration: _decoration(label),
      validator: required
          ? (value) => value == null || value.trim().isEmpty
              ? 'Chan sa a obligatwa'
              : null
          : null,
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.bg1,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.purpleLight),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Apwouve';
      case 'rejected':
        return 'Rejte';
      case 'under_review':
        return 'An revizyon';
      default:
        return 'Annatant';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'under_review':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }
}
