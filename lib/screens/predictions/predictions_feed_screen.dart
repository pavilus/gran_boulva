import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';

class PredictionsFeedScreen extends StatefulWidget {
  const PredictionsFeedScreen({super.key});

  @override
  State<PredictionsFeedScreen> createState() => _PredictionsFeedScreenState();
}

class _PredictionsFeedScreenState extends State<PredictionsFeedScreen> {
  List<PredictionModel> _all = [];
  bool _loading = true;
  int _tabIndex = 0; // 0=Aktif 1=Fèmen 2=Tout

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await PredictionService().getPredictions();
      if (mounted) setState(() { _all = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<PredictionModel> get _filtered {
    switch (_tabIndex) {
      case 0:
        return _all.where((p) => p.isActive).toList();
      case 1:
        return _all.where((p) => p.isClosed).toList();
      default:
        return _all;
    }
  }

  String _formatDeadline(PredictionModel p) {
    if (p.isClosed) return 'Fèmen';
    if (p.deadlineAt == null) return 'Aktif';
    final d = p.timeLeft;
    if (d.isNegative) return 'Ekspire';
    if (d.inDays > 0) return '${d.inDays}j rete';
    if (d.inHours > 0) return '${d.inHours}h rete';
    return '${d.inMinutes}m rete';
  }

  String _fmtVotes(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: AppBackButton(onTap: () => context.pop()),
        title: ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.primaryGradient.createShader(bounds),
          child: const Text(
            'Prediksyon',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                fontFamily: 'Poppins'),
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Filter tabs
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5), width: 1),
              ),
              child: Row(
                children: [
                  _tabItem('Aktif', 0),
                  _tabItem('Fèmen', 1),
                  _tabItem('Tout', 2),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.purple))
                : _filtered.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.purple,
                        backgroundColor: AppColors.card,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String label, int index) {
    final active = _tabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textMuted,
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔮', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text(
            'Pa gen prediksyon nan kategori sa.',
            style: TextStyle(
                color: AppColors.textMuted, fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(PredictionModel p) {
    final deadline = _formatDeadline(p);
    final isActive = p.isActive;
    final participated = p.hasParticipated;

    return GestureDetector(
      onTap: () => context.push('/prediction/${p.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: participated
                ? AppColors.purple.withValues(alpha: 0.5)
                : AppColors.border.withValues(alpha: 0.5),
            width: participated ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: category chip + status + deadline
            Row(
              children: [
                if (p.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          AppColors.purple.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.category!.nameHt,
                      style: const TextStyle(
                          color: AppColors.purpleLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                const Spacer(),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textDim.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? '🟢 Aktif' : '🔴 Fèmen',
                    style: TextStyle(
                        color:
                            isActive ? AppColors.success : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Title
            Text(
              p.titleHt,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            // Option A vs Option B chips
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.optionAGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.optionA,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'VS',
                    style: TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Poppins'),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.optionBGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      p.optionB,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Bottom row: deadline countdown + votes + participation
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: TextStyle(
                      color: isActive
                          ? AppColors.warning
                          : AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
                const SizedBox(width: 12),
                const Text('👥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  '${_fmtVotes(p.totalVotes)} vòt',
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins'),
                ),
                const Spacer(),
                if (participated)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '✓ Patisipe',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins'),
                    ),
                  )
                else
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textDim, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
