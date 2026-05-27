import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/media_player_widget.dart';
import '../../widgets/media_recorder_widget.dart';

class PredictionDetailScreen extends StatefulWidget {
  final String predictionId;
  const PredictionDetailScreen({super.key, required this.predictionId});

  @override
  State<PredictionDetailScreen> createState() => _PredictionDetailScreenState();
}

class _PredictionDetailScreenState extends State<PredictionDetailScreen> {
  PredictionModel? _prediction;
  Map<String, dynamic>? _myVote;
  List<Map<String, dynamic>> _communityVotes = [];
  bool _loading = true;
  bool _submitting = false;
  String? _selectedOption; // 'A' or 'B'
  final _argController = TextEditingController();

  // Media
  File? _mediaFile;
  String? _mediaType;
  int? _mediaDuration;

  // Computed percentages from community votes
  int _votesA = 0;
  int _votesB = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _argController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    PredictionModel? pred;
    try {
      pred = await PredictionService().getPredictionDetail(widget.predictionId);
    } catch (e) {
      debugPrint('getPredictionDetail error: $e');
    }

    Map<String, dynamic>? myVote;
    try {
      myVote = await PredictionService().getUserPredictionVote(widget.predictionId);
    } catch (e) {
      debugPrint('getUserPredictionVote error: $e');
    }

    List<Map<String, dynamic>> communityVotes = [];
    if (myVote != null && pred != null) {
      try {
        communityVotes = await PredictionService().getPredictionVotes(widget.predictionId);
      } catch (e) {
        debugPrint('getPredictionVotes error: $e');
      }
    }

    if (mounted) {
      final vA = communityVotes.where((v) => v['selected_option'] == 'A').length;
      final vB = communityVotes.where((v) => v['selected_option'] == 'B').length;
      setState(() {
        _prediction = pred;
        _myVote = myVote;
        _communityVotes = communityVotes;
        _votesA = vA;
        _votesB = vB;
        _loading = false;
      });
    }
  }

  double get _percentA {
    final total = _votesA + _votesB;
    if (total == 0) return 50;
    return (_votesA / total) * 100;
  }

  double get _percentB => 100 - _percentA;

  Future<void> _submit() async {
    if (_selectedOption == null || _prediction == null) return;
    setState(() => _submitting = true);
    try {
      await PredictionService().submitPrediction(
        predictionId: widget.predictionId,
        selectedOption: _selectedOption!,
        argumentBody: _argController.text.trim().isEmpty
            ? null
            : _argController.text.trim(),
        mediaFile: _mediaFile,
        mediaType: _mediaType,
        mediaDuration: _mediaDuration,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erè: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _share() {
    final p = _prediction;
    if (p == null) return;
    final text = '🔮 ${p.titleHt}\n'
        '${p.optionA}  vs  ${p.optionB}\n'
        '👉 granboulva.com/prediction/${p.id}';
    Share.share(text);
  }

  String _formatDeadline(PredictionModel p) {
    if (p.isClosed) return 'Fèmen';
    if (p.deadlineAt == null) return 'Aktif';
    final d = p.timeLeft;
    if (d.isNegative) return 'Ekspire';
    if (d.inDays > 0) return '${d.inDays} jou rete';
    if (d.inHours > 0) return '${d.inHours} èd tan rete';
    return '${d.inMinutes} minit rete';
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
        title: const Text(
          'Prediksyon',
          style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins'),
        ),
        centerTitle: true,
        actions: [
          if (_prediction != null)
            IconButton(
              onPressed: _share,
              icon: const Icon(Icons.ios_share_rounded,
                  color: AppColors.textSecondary, size: 20),
              tooltip: 'Pataje',
            ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.purple))
          : _prediction == null
              ? const Center(
                  child: Text('Prediksyon pa disponib.',
                      style: TextStyle(
                          color: AppColors.textMuted, fontFamily: 'Poppins')))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _prediction!;
    final participated = _myVote != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        // Category + status + deadline
        Row(
          children: [
            if (p.category != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  p.category!.nameHt,
                  style: const TextStyle(
                      color: AppColors.purpleLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.isActive
                    ? AppColors.success.withValues(alpha: 0.15)
                    : AppColors.textDim.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Text(
                p.isActive ? '🟢 Aktif' : '🔴 Fèmen',
                style: TextStyle(
                    color: p.isActive ? AppColors.success : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Deadline
        Row(
          children: [
            const Text('⏰', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              _formatDeadline(p),
              style: TextStyle(
                  color: p.isActive ? AppColors.warning : AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins'),
            ),
            const SizedBox(width: 12),
            const Text('👥', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              '${p.totalVotes} vòt',
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontFamily: 'Poppins'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Title
        Text(
          p.titleHt,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins'),
        ),
        if (p.descriptionHt != null && p.descriptionHt!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            p.descriptionHt!,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Poppins'),
          ),
        ],
        const SizedBox(height: 24),

        if (!participated && p.isActive)
          _buildVotingSection(p)
        else
          _buildResultsSection(p),
      ],
    );
  }

  Widget _buildVotingSection(PredictionModel p) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Chwazi opsyon ou:',
          style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 12),
        // Option A
        _optionCard(
          label: p.optionA,
          option: 'A',
          gradient: AppColors.optionAGradient,
          selected: _selectedOption == 'A',
        ),
        const SizedBox(height: 10),
        // Option B
        _optionCard(
          label: p.optionB,
          option: 'B',
          gradient: AppColors.optionBGradient,
          selected: _selectedOption == 'B',
        ),
        const SizedBox(height: 20),
        // Argument text field
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.6), width: 1),
          ),
          child: TextField(
            controller: _argController,
            maxLines: 4,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontFamily: 'Poppins'),
            decoration: const InputDecoration(
              hintText: 'Esplike rezon ou (opsyonèl)...',
              hintStyle: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 14,
                  fontFamily: 'Poppins'),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        MediaRecorderWidget(
          onMediaReady: (file, type, dur) => setState(() {
            _mediaFile = file;
            _mediaType = type;
            _mediaDuration = dur;
          }),
          onClear: () => setState(() {
            _mediaFile = null;
            _mediaType = null;
            _mediaDuration = null;
          }),
        ),
        const SizedBox(height: 20),
        GradButton(
          label: 'Soumèt Prediksyon',
          loading: _submitting,
          onTap: _selectedOption != null ? _submit : null,
        ),
      ],
    );
  }

  Widget _optionCard({
    required String label,
    required String option,
    required LinearGradient gradient,
    required bool selected,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = option),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : AppColors.border.withValues(alpha: 0.5),
            width: selected ? 0 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: (option == 'A' ? AppColors.purple : AppColors.pink)
                        .withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (option == 'A' ? AppColors.purple : AppColors.pink)
                        .withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                      color: selected ? Colors.white : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins'),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(PredictionModel p) {
    final myPick = _myVote?['selected_option'] as String?;
    final winner = p.winningOption;
    final isClosed = p.isClosed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Winner banner if closed
        if (isClosed && winner != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: winner == 'A'
                  ? AppColors.optionAGradient
                  : AppColors.optionBGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Text('🏆', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Gayan!',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontFamily: 'Poppins')),
                      Text(
                        winner == 'A' ? p.optionA : p.optionB,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                ),
                if (myPick == winner)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('✓ Ou te genyen!',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins')),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Percentage bars
        _buildPercentBar(
          label: p.optionA,
          option: 'A',
          percent: _percentA,
          votes: _votesA,
          myPick: myPick,
          winner: winner,
        ),
        const SizedBox(height: 10),
        _buildPercentBar(
          label: p.optionB,
          option: 'B',
          percent: _percentB,
          votes: _votesB,
          myPick: myPick,
          winner: winner,
        ),
        const SizedBox(height: 24),

        // Community votes label
        if (_communityVotes.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Opinyon kominote a',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins'),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_communityVotes.length}',
                  style: const TextStyle(
                      color: AppColors.purpleLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._communityVotes.take(10).map((v) => _buildVoteRow(v, p)),
        ],
      ],
    );
  }

  Widget _buildPercentBar({
    required String label,
    required String option,
    required double percent,
    required int votes,
    required String? myPick,
    required String? winner,
  }) {
    final isA = option == 'A';
    final color = isA ? AppColors.purpleLight : AppColors.pink;
    final isMyPick = myPick == option;
    final isWinner = winner == option;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMyPick
              ? color.withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.4),
          width: isMyPick ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                      color: isMyPick ? color : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: isMyPick ? FontWeight.w700 : FontWeight.w400,
                      fontFamily: 'Poppins'),
                ),
              ),
              if (isMyPick)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Ou ✓',
                      style: TextStyle(
                          color: AppColors.purpleLight,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ),
              if (isWinner && winner != null)
                const Text('🏆', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 8,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$votes vòt',
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontFamily: 'Poppins'),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteRow(Map<String, dynamic> v, PredictionModel p) {
    final pick = v['selected_option'] as String? ?? '';
    final isA = pick == 'A';
    final color = isA ? AppColors.purpleLight : AppColors.pink;
    final label = isA ? p.optionA : p.optionB;
    final createdAt =
        DateTime.tryParse(v['created_at'] as String? ?? '') ?? DateTime.now();
    final argBody = v['argument_body'] as String?;
    final mediaUrl = v['media_url'] as String?;
    final mediaType = v['media_type'] as String?;
    final mediaDuration = v['media_duration'] as int?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: AppColors.border.withValues(alpha: 0.4), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Option badge + label + time ──────────────────────────────
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      pick,
                      style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeago.format(createdAt, locale: 'fr'),
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Poppins'),
                ),
              ],
            ),
            // ── Text argument ────────────────────────────────────────────
            if (argBody != null && argBody.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                argBody,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontFamily: 'Poppins',
                    height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            // ── Media ────────────────────────────────────────────────────
            if (mediaUrl != null && mediaType != null) ...[
              const SizedBox(height: 8),
              MediaPlayerWidget(
                url: mediaUrl,
                type: mediaType,
                duration: mediaDuration,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
