import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();

  List<NotificationModel> _all = [];
  bool _loading = true;
  String _filter = 'all';

  static const _filters = [
    (key: 'all', label: 'Tout', icon: '⭐'),
    (key: 'unread', label: 'Poko li', icon: '🔔'),
    (key: 'debate', label: 'Deba', icon: '💬'),
    (key: 'rewards', label: 'Rekonpans', icon: '🏅'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final notifications = await _notificationService.getNotifications();
      if (!mounted) return;
      setState(() {
        _all = notifications;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  List<NotificationModel> get _filtered {
    return switch (_filter) {
      'unread' => _all.where((n) => !n.isRead).toList(),
      'debate' => _all.where((n) => _isDebateType(n.type)).toList(),
      'rewards' => _all.where((n) => _isRewardType(n.type)).toList(),
      _ => _all,
    };
  }

  bool _isDebateType(String type) {
    return {
      'reply',
      'like',
      'argument_like',
      'argument_reply',
      'matchup',
      'new_matchup',
      'prediction_result',
    }.contains(type);
  }

  bool _isRewardType(String type) {
    return {
      'badge',
      'badge_earned',
      'badge_level_up',
      'boost_result',
      'free_boost_earned',
      'coin',
      'coins',
      'argument_support',
      'support',
      'invite_accepted',
    }.contains(type);
  }

  Future<void> _markAllRead() async {
    await _notificationService.markAllRead();
    if (!mounted) return;
    setState(() {
      _all = _all.map((n) => n.copyWith(isRead: true)).toList();
    });
  }

  Future<void> _markOneRead(NotificationModel notification) async {
    if (notification.isRead) return;
    await _notificationService.markRead(notification.id);
    if (!mounted) return;
    setState(() {
      _all = _all
          .map((n) => n.id == notification.id ? n.copyWith(isRead: true) : n)
          .toList();
    });
  }

  Future<void> _onTap(NotificationModel notification) async {
    await _markOneRead(notification);

    final table = notification.relatedTable;
    final id = notification.relatedId;
    if (table == null || id == null || !mounted) return;

    if (table == 'matchups') {
      context.push('/matchup/$id');
    } else if (table == 'predictions') {
      context.push('/prediction/$id');
    } else if (table == 'arguments') {
      context.push('/matchup/$id');
    } else if (table == 'users') {
      context.push('/user/$id');
    } else if (table == 'badges' || table == 'user_badges') {
      context.push('/badges');
    } else if (table == 'coin_transactions' || table == 'coin_purchases') {
      context.push('/coins');
    }
  }

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  ({IconData icon, Color color, String label}) _typeInfo(String type) {
    switch (type) {
      case 'reply':
      case 'argument_reply':
        return (
          icon: Icons.mode_comment_outlined,
          color: AppColors.purpleLight,
          label: 'Repons'
        );
      case 'like':
      case 'argument_like':
        return (
          icon: Icons.favorite_border_rounded,
          color: AppColors.pink,
          label: 'Reyaksyon'
        );
      case 'argument_support':
      case 'support':
        return (
          icon: Icons.volunteer_activism_outlined,
          color: AppColors.success,
          label: 'Sipò'
        );
      case 'badge':
      case 'badge_earned':
      case 'badge_level_up':
        return (
          icon: Icons.workspace_premium_rounded,
          color: AppColors.warning,
          label: 'Badj'
        );
      case 'boost_result':
      case 'free_boost_earned':
        return (
          icon: Icons.rocket_launch_outlined,
          color: AppColors.orange,
          label: 'Boost'
        );
      case 'prediction_result':
        return (
          icon: Icons.query_stats_rounded,
          color: AppColors.purple,
          label: 'Prediksyon'
        );
      case 'new_matchup':
      case 'matchup':
        return (
          icon: Icons.sports_mma_rounded,
          color: AppColors.blue,
          label: 'Matchup'
        );
      case 'new_follower':
        return (
          icon: Icons.person_add_alt_1_rounded,
          color: AppColors.blue,
          label: 'Abònen'
        );
      case 'coin':
      case 'coins':
        return (
          icon: Icons.monetization_on_outlined,
          color: AppColors.success,
          label: 'Coins'
        );
      case 'invite_accepted':
        return (
          icon: Icons.celebration_outlined,
          color: AppColors.success,
          label: 'Envitasyon'
        );
      default:
        return (
          icon: Icons.notifications_outlined,
          color: AppColors.textMuted,
          label: 'Notifikasyon'
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(onTap: _goBack),
        title: const Text(
          'Notifikasyon',
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
      body: Column(
        children: [
          _buildHeader(),
          _buildFilters(),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.purple),
                  )
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.purple,
                        backgroundColor: AppColors.card,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_active_outlined,
                  color: Colors.white, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _unreadCount == 0
                        ? 'Tout bagay ajou'
                        : '$_unreadCount notifikasyon poko li',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Swiv repons, badj, coins, boost ak nouvo aktivite yo.',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontFamily: 'Poppins',
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _unreadCount == 0 ? null : _markAllRead,
              child: Text(
                'Li tout',
                style: TextStyle(
                  color: _unreadCount == 0
                      ? AppColors.textMuted
                      : AppColors.purpleLight,
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final active = filter.key == _filter;
          final count = filter.key == 'unread' ? _unreadCount : null;
          final label = count != null && count > 0
              ? '${filter.label} ($count)'
              : filter.label;
          if (active) {
            return GestureDetector(
              onTap: () => setState(() => _filter = filter.key),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E0826),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(filter.icon, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return GestureDetector(
            onTap: () => setState(() => _filter = filter.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF11112A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF2A2A4A)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF9999BB),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    final message = switch (_filter) {
      'unread' => 'Ou pa gen notifikasyon ou poko li.',
      'debate' => 'Pa gen nouvo aktivite deba.',
      'rewards' => 'Pa gen nouvo rekonpans.',
      _ => 'Pa gen notifikasyon.',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 24),
      children: [
        Icon(Icons.notifications_none_rounded,
            color: AppColors.textMuted.withValues(alpha: 0.75), size: 58),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Poppins',
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(NotificationModel notification) {
    final info = _typeInfo(notification.type);
    final unread = !notification.isRead;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: unread ? AppColors.secondary : AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: unread
                  ? info.color.withValues(alpha: 0.45)
                  : AppColors.border.withValues(alpha: 0.6),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(info.icon, color: info.color, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _TypeChip(label: info.label, color: info.color),
                        const Spacer(),
                        Text(
                          timeago.format(notification.createdAt, locale: 'fr'),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.pink,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      notification.title,
                      style: TextStyle(
                        color: unread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.25,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (notification.body != null &&
                        notification.body!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body!,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          height: 1.25,
                          fontFamily: 'Poppins',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}
