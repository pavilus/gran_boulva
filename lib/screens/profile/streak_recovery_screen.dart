import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';

class StreakRecoveryScreen extends StatefulWidget {
  const StreakRecoveryScreen({super.key});

  @override
  State<StreakRecoveryScreen> createState() => _StreakRecoveryScreenState();
}

class _StreakRecoveryScreenState extends State<StreakRecoveryScreen> {
  final _streakService = StreakService();

  StreakStatus? _status;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  bool _recovering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final status = await _streakService.getStreakStatus();
      final history = await _fetchHistory();
      if (!mounted) return;
      setState(() {
        _status = status;
        _history = history;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchHistory() async {
    try {
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) return [];
      final userId = await _resolveUserId(uid);
      if (userId == null) return [];
      final rows = await Supabase.instance.client
          .from('streak_recoveries')
          .select('streak_length_at_recovery, coins_spent, recovered_at, recovered_date')
          .eq('user_id', userId)
          .order('recovered_at', ascending: false)
          .limit(5);
      return List<Map<String, dynamic>>.from(rows as List);
    } catch (_) {
      return [];
    }
  }

  Future<String?> _resolveUserId(String authId) async {
    try {
      final row = await Supabase.instance.client
          .from('users')
          .select('id')
          .eq('auth_user_id', authId)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _confirmAndRecover() async {
    final status = _status;
    if (status == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfime Retablisman',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        content: Text(
          'Ou pral depanse ${status.recoveryCost} monè pou retabli streak ou. Kontinye?',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Anile',
              style: TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Konfime',
              style: TextStyle(
                color: AppColors.purple,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _recovering = true);
    final result = await _streakService.recoverStreak();
    if (!mounted) return;
    setState(() => _recovering = false);

    if (result['ok'] == true) {
      final newStreak = (result['new_streak'] as num?)?.toInt() ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔥 Streak retabli! Ou gen $newStreak jou.',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _load();
    } else {
      final err = result['error'] as String? ?? 'Yon erè te fèt';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err, style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Streak mwen',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.purple,
              backgroundColor: AppColors.card,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  _buildFlameCard(),
                  const SizedBox(height: 16),
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                ],
              ),
            ),
    );
  }

  // ── Flame card ──────────────────────────────────────────────────────────────
  Widget _buildFlameCard() {
    final streak = _status?.currentStreak ?? 0;
    final longest = _status?.longestStreak ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a0038), Color(0xFF2e0060)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🔥', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 12),
          Text(
            '$streak jou',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Streak aktyèl ou',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '🏆 Pi long streak: $longest jou',
              style: const TextStyle(
                color: Color(0xFFFBBF24),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Status card ─────────────────────────────────────────────────────────────
  Widget _buildStatusCard() {
    final status = _status;
    if (status == null) return const SizedBox.shrink();

    if (status.alreadyRecovered) {
      return _infoCard(
        color: AppColors.success,
        icon: '✅',
        text: 'Ou deja retabli streak ou jodi a.',
      );
    }

    if (status.isRecoveryEligible) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1200),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFBBF24).withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Text('⚠️', style: TextStyle(fontSize: 20)),
                SizedBox(width: 8),
                Text(
                  'Ou te rate yè!',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Retabli streak ou pou ${status.recoveryCost} monè',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _recovering ? null : _confirmAndRecover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFBBF24),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _recovering
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Retabli  •  ${status.recoveryCost} monè',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      );
    }

    // Not eligible
    if (status.currentStreak < 3) {
      return _infoCard(
        color: AppColors.textMuted,
        icon: '💡',
        text: 'Kontinye patisipe chak jou pou bati streak ou. (Bezwen omwen 3 jou)',
      );
    }

    return _infoCard(
      color: AppColors.success,
      icon: '🎯',
      text: 'Streak ou bon! Kontinye vote ak patisipe chak jou.',
    );
  }

  Widget _infoCard({required Color color, required String icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color == AppColors.textMuted
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── History section ─────────────────────────────────────────────────────────
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Istorik retablisman',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Pa gen istorik retablisman ankò.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: _history.indexed.map((entry) {
                final i = entry.$1;
                final row = entry.$2;
                final streak = row['streak_length_at_recovery'] as int? ?? 0;
                final coins = row['coins_spent'] as int? ?? 0;
                final dateStr = row['recovered_date'] as String? ?? '';
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.purple.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('🔥', style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Streak $streak jou retabli',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                                Text(
                                  dateStr,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '-$coins monè',
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < _history.length - 1)
                      const Divider(
                        height: 1,
                        color: AppColors.borderDim,
                        indent: 68,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Continue button ─────────────────────────────────────────────────────────
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => context.pop(),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Kontinye',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
