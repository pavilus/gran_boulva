import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final _badgeService = BadgeService();
  List<BadgeProgressModel> _badges = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final badges = await _badgeService.getUserBadges();
    if (!mounted) return;
    setState(() {
      _badges = badges;
      _loading = false;
    });
  }

  Color _colorFromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? AppColors.purpleLight : Color(value);
  }

  int get _totalLevel => _badges.fold(0, (sum, badge) => sum + badge.level);

  int get _earnedCount => _badges.where((badge) => badge.level > 0).length;

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
          'Badj mwen',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.purple,
              backgroundColor: AppColors.card,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  _buildSummary(),
                  const SizedBox(height: 16),
                  for (final badge in _badges) ...[
                    _BadgeProgressCard(
                      badge: badge,
                      color: _colorFromHex(badge.badge.colorHex),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Badj debloke',
              value: '$_earnedCount/${_badges.length}',
              icon: Icons.workspace_premium_rounded,
              color: AppColors.warning,
            ),
          ),
          Container(width: 1, height: 48, color: AppColors.border),
          Expanded(
            child: _SummaryStat(
              label: 'Nivo total',
              value: '$_totalLevel',
              icon: Icons.trending_up_rounded,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeProgressCard extends StatelessWidget {
  final BadgeProgressModel badge;
  final Color color;

  const _BadgeProgressCard({
    required this.badge,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final nextText = badge.isMaxed
        ? 'Nivo maksimòm'
        : '${badge.currentXp}/${badge.nextRequiredXp} XP';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              // Inner container border property has been removed from here
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                  16), // Clips the image to match the container corners
              child: Image.asset(
                badge.badge.iconAsset,
                fit: BoxFit
                    .cover, // Forces the image to completely fill the 68x68 dimensions
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(Icons.workspace_premium_rounded, color: color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        badge.badge.nameHt,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Nivo ${badge.level}',
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.badge.descriptionHt,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: badge.progressRatio,
                    minHeight: 7,
                    backgroundColor: AppColors.secondary,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  nextText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontFamily: 'Poppins',
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
