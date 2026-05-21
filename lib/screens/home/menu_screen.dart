import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/verification_badge.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _userService = UserService();
  final _notifService = NotificationService();

  UserModel? _profile;
  bool _loading = true;
  int _unreadNotifs = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _userService.getProfile(),
        _notifService.getUnreadCount(),
      ]);
      if (!mounted) return;
      setState(() {
        _profile = results[0] as UserModel?;
        _unreadNotifs = results[1] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erè: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              color: AppColors.purple,
              backgroundColor: AppColors.card,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildMenuSection(),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.bg0,
      surfaceTintColor: Colors.transparent,
      leading: AppBackButton(onTap: () => context.go('/home')),
      title: Image.asset(
        'assets/images/logo.png',
        width: 36,
        height: 36,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: const [],
    );
  }

  Widget _buildProfileCard() {
    final p = _profile;
    final username = p?.username ?? 'Itilizatè';
    final fullName = p?.fullName ?? '';
    const level = 12;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Avatar with glow ring
        GestureDetector(
          onTap: () => context.go('/profile'),
          child: Stack(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.purple.withValues(alpha: 0.5),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.5),
                child: ClipOval(
                  child: UserAvatar.fromUser(p, radius: 33.5),
                ),
              ),
            ),
            Positioned(
              bottom: 2,
              right: 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.bg0, width: 2),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              'Hello, $fullName! 👋',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(children: [
              Text('@$username',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontFamily: 'Poppins')),
              const SizedBox(width: 4),
              if (p != null) VerificationBadge.user(p, size: 14),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '👑 Nivo $level • Enfliyansè',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  String _fmt(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  Widget _buildStatsRow() {
    final p = _profile;
    final stats = [
      ('🔥', _fmt(p?.participationCount ?? 0), 'Patisipasyon'),
      ('🏆', _fmt(p?.victoryCount ?? 0), 'Viktwa'),
      ('⭐', _fmt(p?.followersCount ?? 0), 'Abònen'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: stats.map((entry) {
          final (emoji, value, label) = entry;
          return Expanded(
            child: Column(children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins')),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontFamily: 'Poppins'),
                  textAlign: TextAlign.center),
            ]),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Menu',
          style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              fontFamily: 'Poppins')),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          _MenuItem(
            emoji: '👤',
            color: AppColors.purpleLight,
            title: 'Pwofil mwen',
            subtitle: 'View and edit your profile',
            onTap: () => context.go('/profile'),
          ),
          _divider(),
          _MenuItem(
            emoji: '📈',
            color: AppColors.pink,
            title: 'Estatistik',
            subtitle: 'Gade pèfòmans ou',
            onTap: () => context.push('/my-statistics'),
          ),
          _divider(),
          _MenuItem(
            emoji: '💰',
            color: AppColors.success,
            title: 'Boulva Coins',
            subtitle: 'Balans, acha ak tranzaksyon',
            onTap: () => context.push('/coins'),
          ),
          _divider(),
          _MenuItem(
            emoji: '🏅',
            color: AppColors.warning,
            title: 'Badj mwen',
            subtitle: 'Dekouvri ak kolekte badj',
            onTap: () => context.push('/badges'),
          ),
          _divider(),
          _MenuItem(
            emoji: '🔔',
            color: AppColors.purpleLight,
            title: 'Notifikasyon',
            subtitle: 'Jere notifikasyon ou yo',
            badge: _unreadNotifs > 0 ? '$_unreadNotifs' : null,
            onTap: () => context.go('/notifications'),
          ),
          _divider(),
          _MenuItem(
            emoji: '👥',
            color: const Color(0xFF3B82F6),
            title: 'Abòneman',
            subtitle: 'Moun w ap swiv ak abònen yo',
            onTap: () => context.push('/subscriptions'),
          ),
          _divider(),
          _MenuItem(
            emoji: '🔖',
            color: AppColors.error,
            title: 'Sovgad',
            subtitle: 'Matchups ak pòs sove yo',
            onTap: () => context.push('/saved'),
          ),
          _divider(),
          _MenuItem(
            emoji: '⚙️',
            color: AppColors.textMuted,
            title: 'Anviwònman',
            subtitle: 'Preferans kont ak sekirite',
            onTap: () => context.push('/settings'),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          _MenuItem(
            emoji: '❓',
            color: const Color(0xFF14B8A6),
            title: 'Èd ak Sipò',
            subtitle: 'FAQ, kontak ak sipò',
            onTap: () => context.push('/help'),
          ),
          _divider(),
          _MenuItem(
            emoji: '🚪',
            color: AppColors.error,
            title: 'Dekonekte',
            subtitle: 'Soti nan kont ou',
            titleColor: AppColors.error,
            onTap: () => _confirmSignOut(),
          ),
        ]),
      ),
    ]);
  }

  Widget _divider() => const Divider(
        height: 1,
        thickness: 1,
        color: AppColors.borderDim,
        indent: 60,
      );

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Dekonekte?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700)),
        content: const Text('Èske ou vle soti nan kont ou?',
            style: TextStyle(
                color: AppColors.textSecondary,
                fontFamily: 'Poppins',
                fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Anile',
                style: TextStyle(
                    color: AppColors.textMuted, fontFamily: 'Poppins')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _signOut();
            },
            child: const Text('Wi, dekonekte',
                style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item ──────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final String emoji;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? titleColor;

  const _MenuItem({
    required this.emoji,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      color: titleColor ?? AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ]),
          ),
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(badge!,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
            ),
          const Icon(Icons.arrow_forward_ios_rounded,
              color: AppColors.textDim, size: 14),
        ]),
      ),
    );
  }
}
