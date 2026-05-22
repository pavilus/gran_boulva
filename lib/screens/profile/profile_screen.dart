import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/verification_badge.dart';
import 'avatar_crop_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _userService = UserService();
  final _badgeService = BadgeService();
  final _notificationService = NotificationService();
  final _picker = ImagePicker();

  UserModel? _user;
  List<BadgeProgressModel> _badges = [];
  int _unreadNotifications = 0;
  int _totalVotes = 0;
  bool _loading = true;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final user = await _userService.getProfile();
      final results = await Future.wait([
        _badgeService.getUserBadges(),
        _notificationService.getUnreadCount(),
        if (user == null) Future<int>.value(0) else _countVotes(user.id),
      ]);
      if (!mounted) return;
      setState(() {
        _user = user;
        _badges = results[0] as List<BadgeProgressModel>;
        _unreadNotifications = results[1] as int;
        _totalVotes = results[2] as int;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _countVotes(String userId) async {
    try {
      final rows =
          await supabase.from('votes').select('id').eq('user_id', userId);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    final uid = _user?.id;
    if (uid == null) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
    );
    if (file == null) return;

    final rawBytes = await file.readAsBytes();
    if (!mounted) return;

    final croppedBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCropScreen(imageBytes: rawBytes),
        fullscreenDialog: true,
      ),
    );
    if (croppedBytes == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await _userService.uploadAvatar(croppedBytes, uid);
      if (url != null) {
        await _userService.updateProfile(avatarUrl: url);
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erè: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Chanje foto pwofil',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: AppColors.purpleLight),
              title: const Text('Chwazi nan galri',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: AppColors.purpleLight),
              title: const Text('Pran yon foto',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontFamily: 'Poppins')),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadAvatar(ImageSource.camera);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  String _victoryRate(UserModel user) {
    if (user.participationCount <= 0) return '0%';
    final rate = ((user.victoryCount / user.participationCount) * 100).round();
    return '${rate.clamp(0, 100)}%';
  }

  String _activeTime(UserModel user) {
    final elapsed = DateTime.now().difference(user.createdAt);
    if (elapsed.inHours < 24) return '${elapsed.inHours.clamp(0, 23)}h';
    if (elapsed.inDays < 30) return '${elapsed.inDays}j';
    final months = (elapsed.inDays / 30).floor();
    if (months < 12) return '${months}mwa';
    final years = (elapsed.inDays / 365).floor();
    return '${years}a';
  }

  String _aboutText(UserModel user) {
    final bio = user.bio?.trim();
    if (bio == null || bio.isEmpty) return 'A pwopo de mwen';
    if (bio.length <= 120) return bio;
    return '${bio.substring(0, 117).trimRight()}...';
  }

  String _formatMemberSince(DateTime dt) {
    const months = [
      'Jan',
      'Fev',
      'Mas',
      'Avr',
      'Me',
      'Jen',
      'Jiy',
      'Out',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${months[dt.month - 1]} ${dt.year}';
  }

  Color _colorFromHex(String hex) {
    final value = int.tryParse('FF${hex.replaceFirst('#', '')}', radix: 16);
    return value == null ? AppColors.purpleLight : Color(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : _user == null
              ? const Center(
                  child: Text(
                    'Pwofil pa disponib',
                    style: TextStyle(
                        color: AppColors.textMuted, fontFamily: 'Poppins'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppColors.purple,
                  backgroundColor: AppColors.card,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: ColoredBox(color: AppColors.bg0),
                      ),
                      ListView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          MediaQuery.of(context).padding.top + 14,
                          16,
                          34,
                        ),
                        children: [
                          _buildTopBar(),
                          const SizedBox(height: 24),
                          _buildHero(),
                          const SizedBox(height: 18),
                          _buildInfluenceStats(),
                          const SizedBox(height: 18),
                          _buildStreakBanner(),
                          const SizedBox(height: 18),
                          _buildBadgesSection(),
                          const SizedBox(height: 18),
                          _buildRecentActivitySection(),
                          const SizedBox(height: 18),
                          _buildStatsMiniSection(),
                          const SizedBox(height: 18),
                          _buildCreatorDashboardBanner(),
                          const SizedBox(height: 18),
                          _buildSettingsList(),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTopBar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 38,
          height: 38,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.close_rounded, color: Colors.white, size: 32),
        ),
        Row(
          children: [
            _IconSquare(
              icon: Icons.settings_outlined,
              onTap: () => context.push('/personal-info'),
            ),
            const Spacer(),
            _NotificationButton(
              count: _unreadNotifications,
              onTap: () => context.push('/notifications'),
            ),
            const SizedBox(width: 8),
            _CoinPill(balance: _user!.coinBalance),
          ],
        ),
      ],
    );
  }

  Widget _buildHero() {
    final user = _user!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _showAvatarOptions,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 99,
                height: 99,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.purpleLight.withValues(alpha: 0.55),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(3),
                child: _uploadingAvatar
                    ? const CircleAvatar(
                        backgroundColor: AppColors.purpleDim,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : CircleAvatar(
                        backgroundColor: AppColors.bg1,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : UserAvatar.defaultImageProvider(user.gender),
                      ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 27,
                  height: 27,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.purpleLight, width: 1),
                  ),
                  child: const Icon(Icons.edit_square,
                      color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 17),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      user.fullName.isEmpty ? user.username : user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 7),
                  VerificationBadge.user(user, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '@${user.username}',
                style: const TextStyle(
                  color: Color(0xFFC7B7F4),
                  fontSize: 14.5,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              Text(
                _aboutText(user),
                style: const TextStyle(
                  color: Color(0xFFD6CFF0),
                  fontSize: 13,
                  height: 1.2,
                  fontFamily: 'Poppins',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),
              const _ProfileMeta(
                icon: Icons.location_on_outlined,
                text: 'Pòtoprens, Ayiti',
              ),
              const SizedBox(height: 4),
              _ProfileMeta(
                icon: Icons.calendar_month_outlined,
                text: 'Manm depi ${_formatMemberSince(user.createdAt)}',
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _FollowMetric(
                    value: _fmt(user.followersCount),
                    label: 'Abònen',
                  ),
                  const SizedBox(width: 10),
                  _FollowMetric(
                    value: _fmt(user.followingCount),
                    label: 'Ap swiv',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfluenceStats() {
    final user = _user!;
    final stats = [
      (
        asset: 'assets/images/community.png',
        value: _fmt(user.influenceScore),
        label: 'Enfliyans'
      ),
      (
        asset: 'assets/images/fire.png',
        value: _fmt(user.participationCount),
        label: 'Patisipasyon'
      ),
      (
        asset: 'assets/images/trophy.png',
        value: _fmt(user.victoryCount),
        label: 'Viktwa'
      ),
      (
        asset: 'assets/images/follower.png',
        value: _fmt(user.followersCount),
        label: 'Abònen'
      ),
    ];

    return Row(
      children: [
        for (int i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDim),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        stats[i].asset,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          stats[i].value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    stats[i].label,
                    style: const TextStyle(
                      color: Color(0xFFC7B7F4),
                      fontSize: 10,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onTap) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onTap,
          child: const Row(
            children: [
              Text(
                'Wè tout',
                style: TextStyle(
                  color: Color(0xFFC453FF),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded,
                  color: Color(0xFFCFC1FF), size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakBanner() {
    return GestureDetector(
      onTap: () => context.push('/streak'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1a0038), Color(0xFF2e0060)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border: Border.all(
              color: AppColors.purpleLight.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Text('🔥', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Streak mwen',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Wè streak ou ak opsyon retablisman',
                    style: TextStyle(
                        color: Color(0xFFBDB3DD), fontSize: 12,
                        fontFamily: 'Poppins'),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.purpleLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = _badges.where((badge) => badge.level > 0).take(5).toList();
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Badj mwen', () => context.push('/badges')),
          const SizedBox(height: 18),
          if (badges.isEmpty)
            const Text(
              'Ou poko genyen badj.',
              style: TextStyle(
                color: Color(0xFFC7B7F4),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            )
          else
            Row(
              children: badges.map((badge) {
                final color = _colorFromHex(badge.badge.colorHex);
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          // Border and BoxShadow properties have been removed
                        ),
                        //padding: const EdgeInsets.all(7),
                        child: Image.asset(
                          badge.badge.iconAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.workspace_premium_rounded,
                            color: color,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        badge.badge.nameEn.isEmpty
                            ? badge.badge.nameEn
                            : badge.badge.nameHt,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nivo ${badge.level}',
                        style: const TextStyle(
                          color: Color(0xFFC7B7F4),
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    const activities = [
      (
        asset: 'assets/images/fire.png',
        color: AppColors.orange,
        text: 'Ou te vote “Ede plis” nan sondaj la',
        ago: '2h ago'
      ),
      (
        asset: 'assets/images/comment.png',
        color: AppColors.pink,
        text: 'Ou te patisipe nan debat “Èske mizik rap...”',
        ago: '4h ago'
      ),
      (
        asset: 'assets/images/trophy.png',
        color: AppColors.warning,
        text: 'Ou genyen badj “Top Votè” Nivo 3',
        ago: '1d ago'
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Aktivite resan mwen',
            () => context.push('/recent-activity'),
          ),
          const SizedBox(height: 12),
          for (final entry in activities.indexed) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      entry.$2.asset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      entry.$2.text,
                      style: const TextStyle(
                        color: Color(0xFFD6CFF0),
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    entry.$2.ago,
                    style: const TextStyle(
                      color: Color(0xFFC7B7F4),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (entry.$1 < activities.length - 1)
              Divider(
                color: const Color(0xFF372469).withValues(alpha: 0.55),
                height: 1,
                indent: 58,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsMiniSection() {
    final user = _user!;
    final miniStats = [
      (
        value: _victoryRate(user),
        label: 'To viktwa',
        asset: 'assets/images/trophy.png'
      ),
      (
        value: _fmt(_totalVotes),
        label: 'Vòt total',
        asset: 'assets/images/vote.png'
      ),
      (
        value: _fmt(user.participationCount),
        label: 'Deba patisipe',
        asset: 'assets/images/comment.png'
      ),
      (
        value: _activeTime(user),
        label: 'Tan aktif',
        asset: 'assets/images/clock.png'
      ),
    ];

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Estatistik mwen',
            () => context.push('/my-statistics'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (int i = 0; i < miniStats.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 48,
                    color: const Color(0xFF372469).withValues(alpha: 0.55),
                  ),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            miniStats[i].asset,
                            width: 27,
                            height: 27,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              miniStats[i].value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Poppins',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        miniStats[i].label,
                        style: const TextStyle(
                          color: Color(0xFFBDB3DD),
                          fontSize: 11,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreatorDashboardBanner() {
    return GestureDetector(
      onTap: () => context.push('/creator-dashboard'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF2A0070), Color(0xFF4F158F)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          border:
              Border.all(color: AppColors.purpleLight.withValues(alpha: 0.35)),
        ),
        child: const Row(
          children: [
            Text('⚡', style: TextStyle(fontSize: 24)),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Panèl Kreyatè',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Wè skò, revni ak nivo kreyatè ou',
                    style: TextStyle(color: Color(0xFFBDB3DD), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.purpleLight, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList() {
    final items = [
      (
        icon: Icons.person_outline_rounded,
        asset: null,
        label: 'Enfòmasyon pèsonèl',
        route: '/personal-info',
        color: AppColors.purpleLight
      ),
      (
        icon: Icons.lock_outline_rounded,
        asset: null,
        label: 'Sekirite ak vi prive',
        route: '/security',
        color: const Color(0xFFBDB3DD)
      ),
      (
        icon: Icons.notifications_none_rounded,
        asset: 'assets/images/notification_unifilled.png',
        label: 'Notifikasyon',
        route: '/notification-settings',
        color: const Color(0xFFBDB3DD)
      ),
      (
        icon: Icons.help_outline_rounded,
        asset: null,
        label: 'Èd ak sipò',
        route: '/help',
        color: const Color(0xFFBDB3DD)
      ),
    ];

    return _SectionCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      child: Column(
        children: items.indexed.map((entry) {
          final item = entry.$2;
          return Column(
            children: [
              InkWell(
                onTap: () async {
                  final result = await context.push(item.route);
                  if (result == true && mounted) _loadProfile();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: item.asset == null
                            ? Icon(item.icon, color: item.color, size: 22)
                            : Center(
                                child: Image.asset(
                                  item.asset!,
                                  width: 22,
                                  height: 22,
                                  fit: BoxFit.contain,
                                ),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Colors.white, size: 24),
                    ],
                  ),
                ),
              ),
              if (entry.$1 < items.length - 1)
                Divider(
                  color: const Color(0xFF372469).withValues(alpha: 0.65),
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Cardback.png',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }
}

class _IconSquare extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconSquare({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.purpleLight),
        ),
        child: Icon(icon, color: Colors.white, size: 23),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _NotificationButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox(
            width: 44,
            height: 44,
            child: Image(
              image: AssetImage('assets/images/notification_unifilled.png'),
              width: 39,
              height: 39,
              fit: BoxFit.contain,
            ),
          ),
          if (count > 0)
            Positioned(
              top: 0,
              right: -5,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: AppColors.pink,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                alignment: Alignment.center,
                child: Text(
                  count > 9 ? '9+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinPill extends StatelessWidget {
  final int balance;

  const _CoinPill({required this.balance});

  @override
  Widget build(BuildContext context) {
    final formatted = balance >= 1000
        ? '${(balance / 1000).toStringAsFixed(balance % 1000 == 0 ? 0 : 1)}K'
        : '$balance';
    return GestureDetector(
      onTap: () => context.push('/coins'),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purpleLight),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/coin.png',
              width: 24,
              height: 24,
            ),
            const SizedBox(width: 5),
            Text(
              formatted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMeta extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ProfileMeta({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFC7B7F4), size: 15),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFFC7B7F4),
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FollowMetric extends StatelessWidget {
  final String value;
  final String label;

  const _FollowMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.borderDim),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFC7B7F4),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
