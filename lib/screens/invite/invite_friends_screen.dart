import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';

class InviteFriendsScreen extends StatefulWidget {
  const InviteFriendsScreen({super.key});

  @override
  State<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends State<InviteFriendsScreen> {
  UserModel? _profile;
  bool _loading = true;
  List<Map<String, dynamic>> _referrals = [];
  bool _referralsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadProfile(), _loadReferrals()]);
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await UserService().getProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadReferrals() async {
    try {
      final user = await UserService().getProfile();
      if (user == null) {
        if (mounted) setState(() => _referralsLoading = false);
        return;
      }
      final data = await supabase
          .from('referrals')
          .select(
              '*, invited_user:users!referrals_invited_user_id_fkey(username, full_name, created_at)')
          .eq('inviter_user_id', user.id)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _referrals = List<Map<String, dynamic>>.from(data);
          _referralsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _referralsLoading = false);
    }
  }

  String get _referralCode => _profile?.referralCode ?? 'LOADING';

  String get _shareText =>
      'Vin jwenn mwen sou Gran Boulva! Debat, vote ak agimante sou sijè ki konte.\n'
      'Sèvi ak kòd envitasyon m: $_referralCode\n'
      'https://granboulva.app/invite/$_referralCode';

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 18),
            SizedBox(width: 8),
            Text('Kòd kopye!',
                style: TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'Poppins')),
          ],
        ),
        backgroundColor: AppColors.card,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareInvite() =>
      Share.share(_shareText, subject: 'Rejwenn mwen sou Gran Boulva!');
  void _shareWhatsApp() =>
      Share.share(_shareText, subject: 'Gran Boulva Envitasyon');
  void _shareSms() => Share.share(_shareText);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        elevation: 0,
        leading: AppBackButton(
          onTap: () => context.pop(),
        ),
        title: const Text(
          'Envite Zanmi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: AppColors.border.withValues(alpha: 0.4)),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purpleLight))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildReferralCodeCard(),
                  const SizedBox(height: 20),
                  GradButton(
                    label: 'Pataje lyen envitasyon',
                    onTap: _shareInvite,
                    icon: Icons.share_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildShareViaRow(),
                  const SizedBox(height: 28),
                  _buildReferralsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A0E99), Color(0xFF8B1BE8), Color(0xFFCC1499)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x73401A9E),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        children: [
          Text('🎉', style: TextStyle(fontSize: 52)),
          SizedBox(height: 12),
          Text(
            'Jwenn 1 jou boost gratis!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Envite yon zanmi. Lè yo kreye yon kont, ou resevwa 1 jou boost gratis pou agimantasyon ou.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xE0FFFFFF),
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kòd ou:',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontFamily: 'Poppins'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  _referralCode,
                  style: const TextStyle(
                    color: AppColors.purpleLight,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Courier',
                    letterSpacing: 4,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _copyCode,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.purpleLight.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      color: AppColors.purpleLight, size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.border.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          const Text(
            'Pataje kòd sa a avèk zanmi ou yo. Chak zanmi ki kreye yon kont ap ban ou 1 jou boost!',
            style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins',
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildShareViaRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Envite via:',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _ShareButton(
                    label: 'WhatsApp',
                    emoji: '💬',
                    onTap: _shareWhatsApp,
                    color: const Color(0xFF25D366))),
            const SizedBox(width: 10),
            Expanded(
                child: _ShareButton(
                    label: 'SMS',
                    emoji: '📱',
                    onTap: _shareSms,
                    color: const Color(0xFF007AFF))),
            const SizedBox(width: 10),
            Expanded(
                child: _ShareButton(
                    label: 'Lòt',
                    emoji: '⋯',
                    onTap: _shareInvite,
                    color: AppColors.purpleDim)),
          ],
        ),
      ],
    );
  }

  Widget _buildReferralsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Envitasyon ou yo',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            if (_referrals.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_referrals.length}',
                  style: const TextStyle(
                    color: AppColors.purpleLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (_referralsLoading)
          const Center(
              child: CircularProgressIndicator(color: AppColors.purpleLight))
        else if (_referrals.isEmpty)
          _buildEmptyReferrals()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _referrals.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _buildReferralItem(_referrals[i]),
          ),
      ],
    );
  }

  Widget _buildEmptyReferrals() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.4), width: 1),
      ),
      child: const Column(
        children: [
          Text('🌟', style: TextStyle(fontSize: 40)),
          SizedBox(height: 12),
          Text(
            'Ou poko envite pèsonn',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Pataje kòd ou a epi ou ap jwenn\nboost gratis pou chak zanmi ki rejwenn!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralItem(Map<String, dynamic> referral) {
    final invitedUser = referral['invited_user'] as Map<String, dynamic>?;
    final username = invitedUser?['username'] as String? ?? 'En atant...';
    final status = referral['status'] as String? ?? 'pending';
    final createdAt = referral['created_at'] != null
        ? DateTime.tryParse(referral['created_at'] as String)
        : null;
    final isAccepted = status == 'accepted' || status == 'completed';

    String dateStr = '';
    if (createdAt != null) {
      final diff = DateTime.now().difference(createdAt);
      if (diff.inDays > 0) {
        dateStr = 'Il y a ${diff.inDays}j';
      } else if (diff.inHours > 0) {
        dateStr = 'Il y a ${diff.inHours}h';
      } else {
        dateStr = 'Kounye a';
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: isAccepted ? AppColors.primaryGradient : null,
              color: isAccepted ? null : AppColors.bg1,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                if (dateStr.isNotEmpty)
                  Text(
                    dateStr,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins'),
                  ),
              ],
            ),
          ),
          _StatusChip(isAccepted: isAccepted),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool isAccepted;
  const _StatusChip({required this.isAccepted});

  @override
  Widget build(BuildContext context) {
    final color = isAccepted ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        isAccepted ? 'Aksepte' : 'En atant',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final String label;
  final String emoji;
  final VoidCallback onTap;
  final Color color;

  const _ShareButton({
    required this.label,
    required this.emoji,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
