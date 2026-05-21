import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class RecentActivityScreen extends StatefulWidget {
  const RecentActivityScreen({super.key});

  @override
  State<RecentActivityScreen> createState() => _RecentActivityScreenState();
}

class _RecentActivityScreenState extends State<RecentActivityScreen> {
  List<_ActivityItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await UserService().getProfile();
      if (user == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final rows = await supabase
          .from('user_behavior_events')
          .select('event_type, target_type, target_id, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(40);
      final rawItems = (rows as List)
          .map((row) => _ActivityItem.fromJson(Map<String, dynamic>.from(row)))
          .toList();
      await _hydrateTitles(rawItems);

      if (mounted) {
        setState(() {
          _items = rawItems;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('recent activity error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _hydrateTitles(List<_ActivityItem> items) async {
    final matchupIds = items
        .where((i) => i.targetType == 'matchup')
        .map((i) => i.targetId)
        .toSet()
        .toList();
    final predictionIds = items
        .where((i) => i.targetType == 'prediction')
        .map((i) => i.targetId)
        .toSet()
        .toList();
    final userIds = items
        .where((i) => i.targetType == 'user')
        .map((i) => i.targetId)
        .toSet()
        .toList();

    final titles = <String, String>{};
    if (matchupIds.isNotEmpty) {
      final rows = await supabase
          .from('matchups')
          .select('id, title_ht')
          .inFilter('id', matchupIds);
      for (final row in rows as List) {
        titles[row['id'] as String] = row['title_ht'] as String? ?? 'Matchup';
      }
    }
    if (predictionIds.isNotEmpty) {
      final rows = await supabase
          .from('predictions')
          .select('id, title_ht')
          .inFilter('id', predictionIds);
      for (final row in rows as List) {
        titles[row['id'] as String] =
            row['title_ht'] as String? ?? 'Prediksyon';
      }
    }
    if (userIds.isNotEmpty) {
      final rows = await supabase
          .from('users')
          .select('id, username')
          .inFilter('id', userIds);
      for (final row in rows as List) {
        titles[row['id'] as String] = '@${row['username'] ?? 'itilizatè'}';
      }
    }

    for (final item in items) {
      item.targetTitle = titles[item.targetId];
    }
  }

  void _openItem(_ActivityItem item) {
    if (item.targetType == 'matchup') {
      context.push('/matchup/${item.targetId}');
    } else if (item.targetType == 'prediction') {
      context.push('/prediction/${item.targetId}');
    } else if (item.targetType == 'user' && item.targetTitle != null) {
      context.push('/user/${item.targetTitle!.replaceFirst('@', '')}');
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
          'Aktivite resan mwen',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        backgroundColor: AppColors.card,
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purple))
            : _items.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                    children: const [
                      Icon(Icons.history_rounded,
                          color: AppColors.textMuted, size: 54),
                      SizedBox(height: 14),
                      Text(
                        'Pa gen aktivite ankò',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lè ou vote, swiv, sovgad, reponn oswa sipòte yon pòs, aktivite yo ap parèt isit la.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final item = _items[i];
                      return _ActivityTile(
                        item: item,
                        onTap: () => _openItem(item),
                      );
                    },
                  ),
      ),
    );
  }
}

class _ActivityItem {
  final String eventType;
  final String targetType;
  final String targetId;
  final DateTime createdAt;
  String? targetTitle;

  _ActivityItem({
    required this.eventType,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
  });

  factory _ActivityItem.fromJson(Map<String, dynamic> json) => _ActivityItem(
        eventType: json['event_type'] ?? '',
        targetType: json['target_type'] ?? '',
        targetId: json['target_id'] ?? '',
        createdAt: DateTime.parse(json['created_at']),
      );

  IconData get icon {
    switch (eventType) {
      case 'vote':
      case 'prediction_vote':
        return Icons.how_to_vote_rounded;
      case 'argument_post':
      case 'reply':
        return Icons.chat_bubble_outline_rounded;
      case 'save':
        return Icons.bookmark_rounded;
      case 'follow':
        return Icons.person_add_alt_1_rounded;
      case 'support':
        return Icons.favorite_rounded;
      case 'boost':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.bolt_rounded;
    }
  }

  String? get asset {
    switch (eventType) {
      case 'vote':
      case 'prediction_vote':
        return 'assets/images/fire.png';
      case 'argument_post':
      case 'reply':
        return 'assets/images/comment.png';
      case 'badge':
      case 'badge_earned':
      case 'badge_level_up':
        return 'assets/images/trophy.png';
      default:
        return null;
    }
  }

  Color get color {
    switch (eventType) {
      case 'save':
        return AppColors.error;
      case 'follow':
        return AppColors.blue;
      case 'support':
        return AppColors.pink;
      case 'boost':
        return AppColors.warning;
      default:
        return AppColors.purpleLight;
    }
  }

  String get label {
    final target = targetTitle ?? targetType;
    switch (eventType) {
      case 'vote':
        return 'Ou te vote sou $target';
      case 'prediction_vote':
        return 'Ou te fè yon prediksyon sou $target';
      case 'argument_post':
        return 'Ou te bay opinyon ou sou $target';
      case 'reply':
        return 'Ou te reponn nan $target';
      case 'save':
        return 'Ou te sovgad $target';
      case 'follow':
        return 'Ou te swiv $target';
      case 'support':
        return 'Ou te sipòte yon agiman';
      case 'boost':
        return 'Ou te boost yon agiman';
      case 'matchup_view':
        return 'Ou te gade $target';
      default:
        return 'Aktivite sou $target';
    }
  }
}

class _ActivityTile extends StatelessWidget {
  final _ActivityItem item;
  final VoidCallback onTap;

  const _ActivityTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final canOpen = item.targetType == 'matchup' ||
        item.targetType == 'prediction' ||
        item.targetType == 'user';
    return InkWell(
      onTap: canOpen ? onTap : null,
      borderRadius: BorderRadius.circular(16),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: item.asset == null
                  ? Icon(item.icon, color: item.color, size: 22)
                  : Center(
                      child: Image.asset(
                        item.asset!,
                        width: 24,
                        height: 24,
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
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.35,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    timeago.format(item.createdAt, locale: 'en_short'),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (canOpen)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}
