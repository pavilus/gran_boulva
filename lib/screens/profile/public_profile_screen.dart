import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/verification_badge.dart';
import '../../widgets/cosmetics/cosmetic_avatar.dart';
import '../../widgets/cosmetics/cosmetic_username.dart';

class PublicProfileScreen extends StatefulWidget {
  final String username;
  const PublicProfileScreen({super.key, required this.username});

  @override
  State<PublicProfileScreen> createState() => _PublicProfileScreenState();
}

class _PublicProfileScreenState extends State<PublicProfileScreen> {
  final _cosmeticsService = CosmeticsService();

  UserModel? _profile;
  EquippedCosmetics _equipped = const EquippedCosmetics.empty();
  bool _isOwnProfile = false;
  bool _loading = true;
  bool _isFollowing = false;
  bool _followLoading = false;
  List<Map<String, dynamic>> _recentArguments = [];


  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final profile = await UserService().getProfileByUsername(widget.username);
      if (profile != null) {
        // Canonicalize URL if we resolved via a username_history redirect.
        if (profile.username.toLowerCase() != widget.username.toLowerCase() && mounted) {
          context.replace('/user/${profile.username}');
          return;
        }
        final currentUser = await UserService().getProfile();
        final isOwnProfile = currentUser?.id == profile.id;
        final results = await Future.wait([
          isOwnProfile
              ? Future<bool>.value(false)
              : UserService().isFollowing(profile.id),
          _loadRecentArguments(profile.id),
          _cosmeticsService
              .getEquippedCosmetics(profile.id)
              .then((e) => e ?? const EquippedCosmetics.empty()),
        ]);
        if (mounted) {
          setState(() {
            _profile = profile;
            _isOwnProfile = isOwnProfile;
            _isFollowing = results[0] as bool;
            _recentArguments = results[1] as List<Map<String, dynamic>>;
            _equipped = results[2] as EquippedCosmetics;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentArguments(String userId) async {
    try {
      final data = await supabase
          .from('arguments')
          .select(
              'id, matchup_id, body, like_count, created_at, matchup:matchups(title_ht)')
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (_) {
      return [];
    }
  }

  Future<void> _toggleFollow() async {
    if (_profile == null || _isOwnProfile || _followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await UserService().unfollow(_profile!.id);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _profile = _profile?.copyWith(
              followersCount: (_profile!.followersCount - 1).clamp(0, 1 << 31),
            );
          });
        }
      } else {
        await UserService().follow(_profile!.id);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _profile = _profile?.copyWith(
              followersCount: _profile!.followersCount + 1,
            );
          });
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erè. Eseye ankò.',
                style: TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.borderDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _menuTile(
              icon: Icons.block_rounded,
              label: 'Bloke @${_profile?.username ?? ''}',
              color: AppColors.warning,
              onTap: () {
                Navigator.pop(context);
                _showSnack('Fonksyon bloke a poko disponib sou aparèy sa a.');
              },
            ),
            const SizedBox(height: 8),
            _menuTile(
              icon: Icons.flag_rounded,
              label: 'Rapòte pwofil sa',
              color: AppColors.error,
              onTap: () async {
                Navigator.pop(context);
                await _reportProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message, {Color backgroundColor = AppColors.card}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _reportProfile() async {
    final profile = _profile;
    if (profile == null) return;
    try {
      await ArgumentService().report(
        type: 'user',
        id: profile.id,
        reason: 'reported_from_public_profile',
      );
      if (mounted) {
        _showSnack('Rapò a voye. Ekip la ap verifye pwofil la.');
      }
    } catch (e) {
      if (mounted) {
        _showSnack('Rapò a echwe: ${e.toString()}',
            backgroundColor: AppColors.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(
          onTap: () => context.pop(),
        ),
        title: Text(
          '@${widget.username}',
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: () => _showMoreMenu(context),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: const Icon(Icons.more_horiz_rounded,
                  color: AppColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('👤', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text(
                        'Itilizatè "@${widget.username}" pa jwenn',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  color: AppColors.purple,
                  backgroundColor: AppColors.card,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      _buildProfileCard(),
                      const SizedBox(height: 14),
                      _buildStatsRow(),
                      const SizedBox(height: 20),
                      _buildRecentArgumentsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildProfileCard() {
    final p = _profile!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar
          CosmeticAvatar(
            avatarUrl: p.avatarUrl,
            gender: p.gender,
            frameKey: _equipped.profileFrameKey,
            size: 80,
            ringWidth: 3,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: CosmeticUsername(
                  name: p.fullName,
                  effectKey: _equipped.usernameEffectKey,
                  badgeKey: _equipped.cosmeticBadgeKey,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins'),
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              VerificationBadge.user(p, size: 18),
            ],
          ),
          const SizedBox(height: 2),
          CosmeticHandle(
            handle: '@${p.username}',
            effectKey: _equipped.usernameEffectKey,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontFamily: 'Poppins'),
          ),
          if (p.bio != null && p.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              p.bio!.length <= 120
                  ? p.bio!
                  : '${p.bio!.substring(0, 117).trimRight()}...',
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontFamily: 'Poppins'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 6),
          // Influence score pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.4), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  '${_fmt(p.participationCount)} Patisipasyon',
                  style: const TextStyle(
                      color: AppColors.purpleLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!_isOwnProfile)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _followLoading ? null : _toggleFollow,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: _isFollowing ? null : AppColors.primaryGradient,
                        color: _isFollowing ? AppColors.cardLight : null,
                        borderRadius: BorderRadius.circular(14),
                        border: _isFollowing
                            ? Border.all(color: AppColors.border, width: 1)
                            : null,
                        boxShadow: _isFollowing
                            ? null
                            : [
                                BoxShadow(
                                  color: AppColors.purple.withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: Center(
                        child: _followLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                _isFollowing ? 'Swivan ✓' : 'Swiv',
                                style: TextStyle(
                                  color: _isFollowing
                                      ? AppColors.textSecondary
                                      : Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                // 1 vs 1 button — hidden until battle feature is fully live
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final p = _profile!;
    final items = [
      {
        'icon': '🔥',
        'value': _fmt(p.participationCount),
        'label': 'Patisipasyon'
      },
      {'icon': '🏆', 'value': _fmt(p.victoryCount), 'label': 'Viktwa'},
      {'icon': '⭐', 'value': _fmt(p.followersCount), 'label': 'Abònen'},
      {'icon': '👥', 'value': _fmt(p.followingCount), 'label': 'Ap swiv'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        children: items.map((s) {
          return Expanded(
            child: Column(
              children: [
                Text(s['icon']!, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 4),
                Text(s['value']!,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 2),
                Text(s['label']!,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'Poppins'),
                    textAlign: TextAlign.center),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecentArgumentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Agimantasyon resan',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 10),
        if (_recentArguments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5), width: 1),
            ),
            child: const Center(
              child: Text(
                'Pa gen agimantasyon piblik yo.',
                style: TextStyle(
                    color: AppColors.textMuted, fontFamily: 'Poppins'),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5), width: 1),
            ),
            child: Column(
              children: _recentArguments.asMap().entries.map((e) {
                final i = e.key;
                final arg = e.value;
                final body = arg['body'] as String? ?? '';
                final likes = arg['like_count'] as int? ?? 0;
                final createdAt =
                    DateTime.tryParse(arg['created_at'] as String? ?? '') ??
                        DateTime.now();
                final matchupTitle = (arg['matchup']
                    as Map<String, dynamic>?)?['title_ht'] as String?;

                return Column(
                  children: [
                    GestureDetector(
                      onTap: () =>
                          context.push('/matchup/${arg['matchup_id']}'),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (matchupTitle != null) ...[
                              Text(
                                matchupTitle,
                                style: const TextStyle(
                                    color: AppColors.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                            ],
                            Text(
                              body,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontFamily: 'Poppins'),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('👍',
                                    style: TextStyle(fontSize: 13)),
                                const SizedBox(width: 4),
                                Text('$likes',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                        fontFamily: 'Poppins')),
                                const Spacer(),
                                Text(
                                  timeago.format(createdAt, locale: 'fr'),
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11,
                                      fontFamily: 'Poppins'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i < _recentArguments.length - 1)
                      const Divider(
                          color: AppColors.borderDim,
                          height: 1,
                          indent: 16,
                          endIndent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
