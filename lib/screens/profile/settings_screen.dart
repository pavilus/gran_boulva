import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Efase kont ou?',
          style: TextStyle(
              color: AppColors.error,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Aksyon sa a pèmanan. Tout done ou, pòs ou, ak èstori ou pral efase epi ou p ap ka rekipere yo.',
          style: TextStyle(
              color: AppColors.textSecondary, fontFamily: 'Poppins', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Anile',
                style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Efase kont mwen',
                style: TextStyle(
                    color: AppColors.error,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await AuthService().deleteAccount();
      if (context.mounted) context.go('/login');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erè: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
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
          'Anviwònman',
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
          const Text(
            'Kont',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                color: AppColors.purpleLight,
                title: 'Enfòmasyon pèsonèl',
                subtitle: 'Non, username, biyo ak foto pwofil',
                onTap: () => context.push('/personal-info'),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                color: AppColors.warning,
                title: 'Sekirite ak vi prive',
                subtitle: 'Modpas ak preferans vi prive',
                onTap: () => context.push('/security'),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.verified_user_outlined,
                color: AppColors.purpleLight,
                title: 'Verifikasyon',
                subtitle: 'Mande yon badj verifye pou pwofil ou',
                onTap: () => context.push('/verification-request'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Preferans',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.notifications_none_rounded,
                asset: 'assets/images/notification_unifilled.png',
                color: const Color(0xFF38BDF8),
                title: 'Notifikasyon',
                subtitle: 'Chwazi ki alèt ou vle resevwa',
                onTap: () => context.push('/notification-settings'),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.help_outline_rounded,
                color: AppColors.success,
                title: 'Èd ak sipò',
                subtitle: 'Kesyon, règ kominote ak asistans',
                onTap: () => context.push('/help'),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Zòn danjere',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 12),
          _SettingsGroup(
            children: [
              _SettingsTile(
                icon: Icons.open_in_new_rounded,
                color: AppColors.error,
                title: 'Mande efasman done ou',
                subtitle: 'Soumèt yon demann efasman sou entènèt',
                onTap: () => launchUrl(
                  Uri.parse('https://granboulva.com/delete-account'),
                  mode: LaunchMode.externalApplication,
                ),
                showDivider: true,
              ),
              _SettingsTile(
                icon: Icons.delete_forever_rounded,
                color: AppColors.error,
                title: 'Efase kont mwen',
                subtitle: 'Siprime tout done ou pou toujou',
                onTap: () => _deleteAccount(context),
                showDivider: false,
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String? asset;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsTile({
    required this.icon,
    this.asset,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.showDivider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: asset == null
                      ? Icon(icon, color: color, size: 22)
                      : Center(
                          child: Image.asset(
                            asset!,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.35,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: AppColors.borderDim,
            indent: 72,
            endIndent: 16,
          ),
      ],
    );
  }
}
