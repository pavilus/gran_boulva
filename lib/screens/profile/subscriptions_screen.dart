import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/user_avatar.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final _userService = UserService();
  UserModel? _me;
  bool _loading = true;
  int _tab = 0;
  List<_SubscriptionUser> _following = [];
  List<_SubscriptionUser> _followers = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final me = await _userService.getProfile();
      if (me == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final followingRows = await supabase
          .from('follows')
          .select('created_at, user:users!follows_following_id_fkey(*)')
          .eq('follower_id', me.id)
          .order('created_at', ascending: false);

      final followerRows = await supabase
          .from('follows')
          .select('created_at, user:users!follows_follower_id_fkey(*)')
          .eq('following_id', me.id)
          .order('created_at', ascending: false);

      final following = (followingRows as List)
          .map((row) => _SubscriptionUser.fromJson(row))
          .where((item) => item.user != null)
          .map((item) => item.requireUser(isFollowing: true))
          .toList();

      final followers = <_SubscriptionUser>[];
      for (final row in followerRows as List) {
        final item = _SubscriptionUser.fromJson(row);
        final user = item.user;
        if (user == null) continue;
        final isFollowing = await _userService.isFollowing(user.id);
        followers.add(item.requireUser(isFollowing: isFollowing));
      }

      if (!mounted) return;
      setState(() {
        _me = me;
        _following = following;
        _followers = followers;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow(_SubscriptionUser item) async {
    final user = item.user;
    if (user == null || user.id == _me?.id || item.busy) return;

    setState(() => item.busy = true);
    try {
      if (item.isFollowing) {
        await _userService.unfollow(user.id);
      } else {
        await _userService.follow(user.id);
      }
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Erè. Eseye ankò.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => item.busy = false);
    }
  }

  void _openProfile(UserModel user) {
    context.push('/user/${user.username}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(onTap: () => context.pop()),
        title: const Text(
          'Abònman',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Rafrechi',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : RefreshIndicator(
              color: AppColors.purple,
              backgroundColor: AppColors.card,
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 14),
                  _buildTabs(),
                  const SizedBox(height: 14),
                  ..._currentList.map(_buildUserTile),
                  if (_currentList.isEmpty) _buildEmptyState(),
                ],
              ),
            ),
    );
  }

  List<_SubscriptionUser> get _currentList =>
      _tab == 0 ? _following : _followers;

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _summaryStat(
              label: 'M ap swiv',
              value: '${_following.length}',
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white24),
          Expanded(
            child: _summaryStat(
              label: 'Abònen mwen',
              value: '${_followers.length}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryStat({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _tabButton(0, 'M ap swiv'),
          _tabButton(1, 'Abònen mwen'),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    final active = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(_SubscriptionUser item) {
    final user = item.user!;
    final isOwnUser = user.id == _me?.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        onTap: () => _openProfile(user),
        leading: UserAvatar.fromUser(user, radius: 24),
        title: Text(
          user.fullName.isNotEmpty ? user.fullName : '@${user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins',
          ),
        ),
        subtitle: Text(
          '@${user.username} • ${timeago.format(item.createdAt, locale: 'en_short')}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontFamily: 'Poppins',
          ),
        ),
        trailing: isOwnUser
            ? null
            : GestureDetector(
                onTap: item.busy ? null : () => _toggleFollow(item),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: item.isFollowing
                        ? AppColors.cardLight
                        : AppColors.purple.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: item.isFollowing
                          ? AppColors.border
                          : AppColors.purple.withValues(alpha: 0.45),
                    ),
                  ),
                  child: item.busy
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.purpleLight,
                          ),
                        )
                      : Text(
                          item.isFollowing ? 'Swivan' : 'Swiv',
                          style: TextStyle(
                            color: item.isFollowing
                                ? AppColors.textSecondary
                                : AppColors.purpleLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Poppins',
                          ),
                        ),
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final title = _tab == 0 ? 'Ou poko swiv pèsonn' : 'Ou poko gen abònen';
    final body = _tab == 0
        ? 'Ale sou deba yo epi swiv vwa ki enterese w.'
        : 'Lè moun kòmanse swiv ou, y ap parèt isit la.';
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.people_outline_rounded,
              color: AppColors.textMuted, size: 42),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionUser {
  final UserModel? user;
  final DateTime createdAt;
  bool isFollowing;
  bool busy;

  _SubscriptionUser({
    required this.user,
    required this.createdAt,
    this.isFollowing = false,
    this.busy = false,
  });

  factory _SubscriptionUser.fromJson(Object row) {
    final data = Map<String, dynamic>.from(row as Map);
    final userData = data['user'];
    return _SubscriptionUser(
      user: userData is Map
          ? UserModel.fromJson(Map<String, dynamic>.from(userData))
          : null,
      createdAt: DateTime.tryParse('${data['created_at']}') ?? DateTime.now(),
    );
  }

  _SubscriptionUser requireUser({required bool isFollowing}) {
    return _SubscriptionUser(
      user: user!,
      createdAt: createdAt,
      isFollowing: isFollowing,
      busy: busy,
    );
  }
}
