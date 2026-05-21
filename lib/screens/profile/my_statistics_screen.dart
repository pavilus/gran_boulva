import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class MyStatisticsScreen extends StatefulWidget {
  const MyStatisticsScreen({super.key});

  @override
  State<MyStatisticsScreen> createState() => _MyStatisticsScreenState();
}

class _MyStatisticsScreenState extends State<MyStatisticsScreen> {
  UserModel? _user;
  Map<String, int> _stats = {};
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
      final results = await Future.wait([
        _count('votes', 'user_id', user.id),
        _count('arguments', 'user_id', user.id),
        _count('saved_items', 'user_id', user.id),
        _count('prediction_votes', 'user_id', user.id),
        _count('coin_transactions', 'from_user_id', user.id),
      ]);

      if (mounted) {
        setState(() {
          _user = user;
          _stats = {
            'votes': results[0],
            'arguments': results[1],
            'saved': results[2],
            'predictions': results[3],
            'coinActions': results[4],
          };
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('my statistics error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<int> _count(String table, String column, String value) async {
    try {
      final rows = await supabase.from(table).select('id').eq(column, value);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final victoryRate = user == null || user.participationCount == 0
        ? 0
        : ((user.victoryCount / user.participationCount) * 100).round();

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        title: const Text(
          'Estatistik mwen',
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
            : user == null
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 90, 24, 24),
                    children: const [
                      Text(
                        'Estatistik pa disponib',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _HeroStats(
                        influence: _fmt(user.influenceScore),
                        victoryRate: '$victoryRate%',
                        participation: _fmt(user.participationCount),
                      ),
                      const SizedBox(height: 16),
                      _StatsGrid(
                        items: [
                          _StatItem('Vòt total', _fmt(_stats['votes'] ?? 0),
                              Icons.how_to_vote_rounded, AppColors.purpleLight,
                              asset: 'assets/images/vote.png'),
                          _StatItem('Agiman', _fmt(_stats['arguments'] ?? 0),
                              Icons.chat_bubble_outline_rounded, AppColors.pink,
                              asset: 'assets/images/comment.png'),
                          _StatItem(
                              'Prediksyon',
                              _fmt(_stats['predictions'] ?? 0),
                              Icons.query_stats_rounded,
                              AppColors.blue),
                          _StatItem('Sovgad', _fmt(_stats['saved'] ?? 0),
                              Icons.bookmark_rounded, AppColors.error),
                          _StatItem('Abònen', _fmt(user.followersCount),
                              Icons.people_alt_outlined, AppColors.success),
                          _StatItem(
                              'M ap swiv',
                              _fmt(user.followingCount),
                              Icons.person_add_alt_1_rounded,
                              AppColors.warning),
                          _StatItem(
                              'Sipò resevwa',
                              _fmt(user.totalSupportReceived),
                              Icons.favorite_rounded,
                              AppColors.pinkLight),
                          _StatItem('Boost itilize', _fmt(user.totalBoostsUsed),
                              Icons.rocket_launch_rounded, AppColors.orange),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _MoneyCard(
                        balance: _fmt(user.coinBalance),
                        spent: _fmt(user.totalCoinsSpent),
                        transferred: _fmt(user.totalCoinsTransferred),
                        actions: _fmt(_stats['coinActions'] ?? 0),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  final String influence;
  final String victoryRate;
  final String participation;

  const _HeroStats({
    required this.influence,
    required this.victoryRate,
    required this.participation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          _HeroMetric(label: 'Enfliyans', value: influence),
          _divider(),
          _HeroMetric(label: 'To viktwa', value: victoryRate),
          _divider(),
          _HeroMetric(label: 'Patisipasyon', value: participation),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 54,
        color: Colors.white.withValues(alpha: 0.18),
      );
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFE9D5FF),
              fontSize: 11,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final List<_StatItem> items;

  const _StatsGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: item.asset == null
                    ? Icon(item.icon, color: item.color, size: 21)
                    : Center(
                        child: Image.asset(
                          item.asset!,
                          width: 23,
                          height: 23,
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.value,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoneyCard extends StatelessWidget {
  final String balance;
  final String spent;
  final String transferred;
  final String actions;

  const _MoneyCard({
    required this.balance,
    required this.spent,
    required this.transferred,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Boulva Coins',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _CoinMetric(label: 'Balans', value: balance),
              _CoinMetric(label: 'Depanse', value: spent),
              _CoinMetric(label: 'Transfere', value: transferred),
              _CoinMetric(label: 'Aksyon', value: actions),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoinMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CoinMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? asset;

  const _StatItem(this.label, this.value, this.icon, this.color, {this.asset});
}
