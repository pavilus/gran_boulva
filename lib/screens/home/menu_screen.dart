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

  // ── Tier helpers ───────────────────────────────────────────────
  String _tierLabel(UserModel? p) {
    final s = p?.influenceScore ?? 0;
    if (s >= 70) return 'Elit';
    if (s >= 35) return 'Konfime';
    if (s >= 15) return 'Entèmedyè';
    return 'Debitan';
  }

  String _tierEmoji(UserModel? p) {
    final s = p?.influenceScore ?? 0;
    if (s >= 70) return '⚡';
    if (s >= 35) return '✅';
    if (s >= 15) return '🌱';
    return '👤';
  }

  bool get _isAdmin =>
      _profile?.role == 'admin' || _profile?.role == 'moderator';
  bool get _isVerified => _profile?.verificationStatus == 'verified';

  // ── Build ──────────────────────────────────────────────────────
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
                children: [
                  _buildProfileCard(),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 24),
                  _buildSection('Kont Mwen', _accountItems()),
                  const SizedBox(height: 16),
                  _buildSection('Kominotè', _communityItems()),
                  const SizedBox(height: 16),
                  _buildSection('Finansman', _financeItems()),
                  const SizedBox(height: 16),
                  _buildSection('Preferans', _preferencesItems()),
                  const SizedBox(height: 16),
                  _buildSection('Sipò', _supportItems()),
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
              child: Text(
                '${_tierEmoji(p)} ${_tierLabel(p)} • ${p?.influenceScore ?? 0} pwen',
                style: const TextStyle(
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
      ('assets/images/fire.png',            AppColors.error,   _fmt(p?.participationCount ?? 0), 'Patisipasyon'),
      ('assets/images/trophy.png',          AppColors.warning, _fmt(p?.victoryCount ?? 0),       'Viktwa'),
      ('assets/images/follower.png',         AppColors.purple,  _fmt(p?.followersCount ?? 0),     'Abònen'),
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
          final (img, color, value, label) = entry;
          return Expanded(
            child: Column(children: [
              Image.asset(img,
                  width: 22,
                  height: 22,
                  color: color,
                  colorBlendMode: BlendMode.srcIn),
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

  // ── Section builder ────────────────────────────────────────────
  Widget _buildSection(String title, List<_MenuItemData> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              fontFamily: 'Poppins'),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            final item = items[i];
            return Column(children: [
              _MenuItem(data: item),
              if (i < items.length - 1)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.borderDim,
                  indent: 60,
                ),
            ]);
          }),
        ),
      ),
    ]);
  }

  // ── Section item lists ─────────────────────────────────────────
  List<_MenuItemData> _accountItems() => [
        _MenuItemData(
          imagePath: 'assets/images/profile_filled.png',
          color: AppColors.purpleLight,
          title: 'Pwofil mwen',
          subtitle: 'Gade ak modifye pwofil ou',
          onTap: () => context.go('/profile'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/influencer.png',
          color: const Color(0xFFF59E0B),
          title: 'Espas Kreyatè',
          subtitle: 'Revni, nivo ak estatistik kreyatè',
          onTap: () => context.push('/creator-dashboard'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/level.png',
          color: AppColors.pink,
          title: 'Estatistik',
          subtitle: 'Pèfòmans ak done ou yo',
          onTap: () => context.push('/my-statistics'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/clock.png',
          color: const Color(0xFF3B82F6),
          title: 'Aktivite Resan',
          subtitle: 'Tout aksyon ou fè dènyèman',
          onTap: () => context.push('/recent-activity'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/file.png',
          color: AppColors.error,
          title: 'Sovgad',
          subtitle: 'Matchups ak pòs ou sove yo',
          onTap: () => context.push('/saved'),
        ),
      ];

  List<_MenuItemData> _communityItems() => [
        _MenuItemData(
          imagePath: 'assets/images/predict.png',
          color: AppColors.purple,
          title: 'Prediksyon',
          subtitle: 'Fè pwopozisyon ou, wè si ou gen rezon',
          onTap: () => context.push('/predictions'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/community.png',
          color: const Color(0xFF3B82F6),
          title: 'Abòneman',
          subtitle: 'Moun w ap swiv ak abònen ou yo',
          onTap: () => context.push('/subscriptions'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/top.png',
          color: const Color(0xFFF59E0B),
          title: 'Tòp Vwa',
          subtitle: 'Kreyatè ki pi enfliyans yo',
          onTap: () => context.push('/top-voices'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/follower.png',
          color: AppColors.success,
          title: 'Envite Zanmi',
          subtitle: 'Pataje kòd referans ou',
          onTap: () => context.push('/invite'),
        ),
      ];

  List<_MenuItemData> _financeItems() => [
        _MenuItemData(
          imagePath: 'assets/images/coins.png',
          color: AppColors.success,
          title: 'Boulva Coins',
          subtitle: 'Balans, acha ak tranzaksyon',
          onTap: () => context.push('/coins'),
        ),
        _MenuItemData(
          imagePath: 'assets/images/badjmwen.png',
          color: AppColors.warning,
          title: 'Badj mwen',
          subtitle: 'Dekouvri ak kolekte badj ou yo',
          onTap: () => context.push('/badges'),
        ),
        // TODO: Uncomment when Kosmetik is ready to launch
        // _MenuItemData(
        //   icon: Icons.auto_awesome_rounded,
        //   color: AppColors.pink,
        //   title: 'Boutik Kosmetik',
        //   subtitle: 'Kadè pwofil, efè non ak plis',
        //   onTap: () => context.push('/cosmetics'),
        // ),
      ];

  List<_MenuItemData> _preferencesItems() {
    final items = <_MenuItemData>[
      _MenuItemData(
        imagePath: 'assets/images/notification_filled.png',
        color: AppColors.purpleLight,
        title: 'Notifikasyon',
        subtitle: 'Jere ak vè notifikasyon ou yo',
        badge: _unreadNotifs > 0 ? '$_unreadNotifs' : null,
        onTap: () => context.go('/notifications'),
      ),
      _MenuItemData(
        imagePath: 'assets/images/anviwonman.png',
        color: AppColors.textMuted,
        title: 'Anviwònman',
        subtitle: 'Preferans kont ak sekirite',
        onTap: () => context.push('/settings'),
      ),
    ];

    if (!_isVerified) {
      items.add(_MenuItemData(
        imagePath: 'assets/images/verified.png',
        color: const Color(0xFF14B8A6),
        title: 'Mande Verifikasyon',
        subtitle: 'Aplike pou badge verifikasyon',
        onTap: () => context.push('/verification-request'),
      ));
    }

    if (_isAdmin) {
      items.add(_MenuItemData(
        imagePath: 'assets/images/backend.png',
        color: AppColors.error,
        title: 'Admin',
        subtitle: 'Tableau de bò administrasyon',
        onTap: () => context.push('/admin'),
      ));
    }

    return items;
  }

  List<_MenuItemData> _supportItems() => [
        _MenuItemData(
          imagePath: 'assets/images/help.png',
          color: const Color(0xFF14B8A6),
          title: 'Èd ak Sipò',
          subtitle: 'FAQ, kontak ak asistans',
          onTap: () => context.push('/help'),
        ),
        _MenuItemData(
          icon: Icons.logout_rounded,
          color: AppColors.error,
          title: 'Dekonekte',
          subtitle: 'Soti nan kont ou an sekirite',
          titleColor: AppColors.error,
          onTap: _confirmSignOut,
        ),
      ];

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

// ── Data class ────────────────────────────────────────────────────────────────
class _MenuItemData {
  final String? imagePath;  // custom PNG asset
  final IconData? icon;     // fallback Material icon
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? badge;
  final Color? titleColor;

  const _MenuItemData({
    this.imagePath,
    this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badge,
    this.titleColor,
  });
}

// ── Menu Item widget ──────────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final _MenuItemData data;
  const _MenuItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          // Icon box — custom image or Material icon
          SizedBox(
            width: 38,
            height: 38,
            child: data.imagePath != null
                ? Image.asset(data.imagePath!, fit: BoxFit.contain)
                : Container(
                    decoration: BoxDecoration(
                      color: data.color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(data.icon, color: data.color, size: 22),
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(data.title,
                  style: TextStyle(
                      color: data.titleColor ?? AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 2),
              Text(data.subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ]),
          ),
          if (data.badge != null)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(data.badge!,
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
