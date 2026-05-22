import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/app_interactions.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/verification_badge.dart';

const _matchupPageBg = AppColors.bg0;
const _matchupDeepPurple = Color(0xFF4F158F);
const _matchupHotPink = Color(0xFFD90C82);
const _lockedVoteGradient = LinearGradient(
  colors: [_matchupDeepPurple, _matchupHotPink],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

String? _optionImageSource(MatchupOptionModel option) {
  if (option.imageUrl != null && option.imageUrl!.isNotEmpty) {
    return option.imageUrl;
  }

  final normalized = option.optionName.toLowerCase();
  if (normalized.contains('t-vice') || normalized.contains('tvice')) {
    return 'assets/images/tvice.png';
  }
  if (normalized.contains('rutshelle')) {
    return 'assets/images/rutshelle.png';
  }
  return null;
}

Widget _optionImageWidget(
  String source, {
  Alignment alignment = Alignment.center,
}) {
  if (source.startsWith('assets/')) {
    return Image.asset(source, fit: BoxFit.cover, alignment: alignment);
  }
  return CachedNetworkImage(
    imageUrl: source,
    fit: BoxFit.cover,
    alignment: alignment,
    errorWidget: (_, __, ___) => const SizedBox.shrink(),
  );
}

class MatchupDetailScreen extends StatefulWidget {
  final String matchupId;
  final String? initialVoteOptionId;
  const MatchupDetailScreen({
    super.key,
    required this.matchupId,
    this.initialVoteOptionId,
  });

  @override
  State<MatchupDetailScreen> createState() => _MatchupDetailScreenState();
}

class _MatchupDetailScreenState extends State<MatchupDetailScreen> {
  final _matchupService = MatchupService();
  final _argumentService = ArgumentService();
  final _coinService = CoinService();
  String? _myInternalUserId;

  MatchupModel? _matchup;
  List<ArgumentModel> _arguments = [];
  bool _loading = true;
  bool _isLocked = true;
  String? _myVoteOptionId;
  String? _selectedOptionId;
  bool _hasChangedVote = false;
  String _argumentSort = 'popular';
  bool _submitting = false;
  bool _argumentsLoading = false;
  String? _argumentsError;
  int _coinBalance = 0;
  bool _isSaved = false;

  final _scrollController = ScrollController();

  static const _sortTabs = [
    ('popular', 'Top Agimantasyon'),
    ('boosted', 'Boosted'),
    ('recent', 'Resan'),
    ('following', 'Swiv mwen'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialVoteOptionId != null) {
      _myVoteOptionId = widget.initialVoteOptionId;
      _isLocked = false;
    }
    _init();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    if (_myInternalUserId == null) {
      final profile = await UserService().getProfile();
      if (mounted && profile != null) {
        setState(() => _myInternalUserId = profile.id);
      }
    }
    try {
      final matchup = await _matchupService.getMatchupDetail(widget.matchupId);
      if (!mounted) return;
      setState(() {
        _matchup = matchup;
        _isSaved = matchup?.isSaved ?? false;
        _loading = false;
      });
      if (!_isLocked) {
        await _loadArguments();
      }
      _loadCoinBalance();
    } catch (e) {
      debugPrint('_init matchup error: $e');
      if (mounted) setState(() => _loading = false);
      return;
    }

    // Load user-specific state independently so permission errors don't block the matchup.
    try {
      final vote = await _matchupService.getUserVote(widget.matchupId);
      if (!mounted) return;
      final voteOptionId =
          vote?['option_id'] as String? ?? widget.initialVoteOptionId;
      setState(() {
        _myVoteOptionId = voteOptionId;
        _isLocked = voteOptionId == null;
        _hasChangedVote = vote?['vote_changed'] as bool? ?? false;
      });

      if (!_isLocked) await _loadArguments();
    } catch (e) {
      debugPrint('_init user state error: $e');
      if (widget.initialVoteOptionId != null) {
        await _loadArguments();
      }
    }
  }

  Future<void> _shareMatchup() async {
    final matchup = _matchup;
    if (matchup == null) return;
    final text =
        'Vwa ou konte sou Gran Boulva: ${matchup.titleHt}\nhttps://granboulva.com/matchup/${matchup.id}';
    try {
      // Provide a non-zero origin so iOS share sheet anchors correctly
      final box = context.findRenderObject() as RenderBox?;
      final origin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      await Share.share(text, sharePositionOrigin: origin);
    } catch (_) {
      await Share.share(text);
    }
  }

  Future<void> _toggleSavedMatchup() async {
    final matchup = _matchup;
    if (matchup == null) return;
    final next = !_isSaved;
    setState(() => _isSaved = next);
    try {
      await _matchupService.toggleSave(matchup.id, next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next ? 'Matchup la sovgade.' : 'Matchup la retire nan Sovgad.',
            style: const TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isSaved = !next);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sovgad echwe: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _loadArguments() async {
    if (mounted) {
      setState(() {
        _argumentsLoading = true;
        _argumentsError = null;
      });
    }
    try {
      final res = await _argumentService.getArguments(
        widget.matchupId,
        sort: _argumentSort,
        fetchAll: true,
      );
      if (res['error'] != null) {
        debugPrint('_loadArguments service error: ${res['error']}');
      }
      final list = (res['arguments'] as List? ?? [])
          .map((j) => ArgumentModel.fromJson(j))
          .toList();
      if (_argumentSort == 'popular') {
        list.sort((a, b) => b.finalRankingScore.compareTo(a.finalRankingScore));
      } else if (_argumentSort == 'boosted') {
        list
          ..removeWhere((arg) => !arg.isBoosted)
          ..sort((a, b) => b.finalRankingScore.compareTo(a.finalRankingScore));
      }
      if (mounted) {
        setState(() {
          _arguments = list;
          _argumentsLoading = false;
          _argumentsError = res['error'] as String?;
        });
      }
    } catch (e) {
      debugPrint('_loadArguments parse error: $e');
      if (mounted) {
        setState(() {
          _argumentsLoading = false;
          _argumentsError = e.toString();
        });
      }
    }
  }

  Future<void> _loadCoinBalance() async {
    try {
      final balance = await _coinService.getBalance();
      if (mounted) setState(() => _coinBalance = balance);
    } catch (_) {}
  }

  Future<void> _submitVoteAndArgument(
      String optionId, String argumentBody) async {
    if (optionId.isEmpty || argumentBody.trim().isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _matchupService.submitVoteAndArgument(
        matchupId: widget.matchupId,
        optionId: optionId,
        argumentBody: argumentBody.trim(),
      );
      if (!mounted) return;
      setState(() {
        _myVoteOptionId = optionId;
        _isLocked = false;
        _submitting = false;
      });
      await _loadCoinBalance();
      await _init();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erè: ${e.toString()}',
                style: const TextStyle(fontFamily: 'Poppins')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeVote() async {
    if (_matchup == null) return;
    final newOptionId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ChangeVoteSheet(
        matchup: _matchup!,
        currentOptionId: _myVoteOptionId,
      ),
    );
    if (newOptionId == null || newOptionId == _myVoteOptionId) return;
    setState(() => _submitting = true);
    try {
      await _matchupService.changeVote(
        matchupId: widget.matchupId,
        newOptionId: newOptionId,
      );
      if (!mounted) return;
      setState(() {
        _myVoteOptionId = newOptionId;
        _hasChangedVote = true;
        _submitting = false;
      });
      await _loadCoinBalance();
      await _init();
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erè: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _openVoteSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _VoteBottomSheet(
        matchup: _matchup!,
        onSubmit: (optionId, body) {
          Navigator.pop(context);
          _submitVoteAndArgument(optionId, body);
        },
        submitting: _submitting,
      ),
    );
  }

  void _openArgumentSheet() {
    if (_myVoteOptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vote anvan ou ekri agimanw lan.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ArgumentBottomSheet(
        onSubmit: (body) {
          Navigator.pop(context);
          _submitVoteAndArgument(_myVoteOptionId!, body);
        },
        submitting: _submitting,
      ),
    );
  }

  void _openReplySheet(ArgumentModel arg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) =>
          _ReplyBottomSheet(argument: arg, service: _argumentService),
    );
  }

  void _openReadRepliesSheet(ArgumentModel arg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _RepliesViewSheet(
        argument: arg,
        service: _argumentService,
        currentUserId: _myInternalUserId,
      ),
    );
  }

  void _openSupportSheet(ArgumentModel arg) {
    if (arg.userId == _myInternalUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ou pa ka sipòte pwòp agiman ou.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _SupportBottomSheet(
        argument: arg,
        coinService: _coinService,
        currentUserId: _myInternalUserId,
        onSupported: () async {
          Navigator.pop(context);
          await _loadArguments();
          await _loadCoinBalance();
        },
      ),
    );
  }

  ArgumentModel? get _myArgument {
    final uid = _myInternalUserId;
    if (uid == null) return null;
    return _arguments.where((a) => a.userId == uid).firstOrNull;
  }

  String _fmtNum(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return '$v';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _matchupPageBg,
        body: Center(child: CircularProgressIndicator(color: AppColors.purple)),
      );
    }
    if (_matchup == null) {
      return Scaffold(
        backgroundColor: _matchupPageBg,
        appBar: AppBar(
          backgroundColor: _matchupPageBg,
          leading: AppBackButton.matchupStyle(
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: const Center(
          child: Text('Nou pa jwenn Matchup.',
              style:
                  TextStyle(color: AppColors.textMuted, fontFamily: 'Poppins')),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _matchupPageBg,
      appBar: _buildAppBar(),
      body: _isLocked ? _buildLockedBody() : _buildUnlockedBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 56,
      backgroundColor: _matchupPageBg,
      surfaceTintColor: Colors.transparent,
      leading: AppBackButton.matchupStyle(
        onTap: () => Navigator.of(context).maybePop(),
      ),
      title: Image.asset(
        'assets/images/logo.png',
        width: 40,
        height: 40,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
      actions: [
        GestureDetector(
          onTap: () => context.push('/coins'),
          child: Container(
            height: 42,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.bg1,
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/coin.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 7),
                Text(
                  _fmtNum(_coinBalance),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final m = _matchup!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(m.category?.nameHt ?? 'Kategori',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ),
          const SizedBox(width: 18),
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          const Text('Popilè',
              style: TextStyle(
                  color: Color(0xFFC8B8FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins')),
          const Spacer(),
          Text(
            m.publishedAt != null
                ? timeago.format(m.publishedAt!, locale: 'en_short')
                : '',
            style: const TextStyle(
                color: Color(0xFFC8B8FF), fontSize: 14, fontFamily: 'Poppins'),
          ),
        ]),
        const SizedBox(height: 22),
        if (!_isLocked) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _HeaderCircleAction(
                icon: Icons.share_outlined,
                onTap: _shareMatchup,
              ),
              const SizedBox(width: 8),
              _HeaderCircleAction(
                icon: _isSaved
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                onTap: _toggleSavedMatchup,
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Text(m.titleHt,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                fontFamily: 'Poppins',
                height: 1.24)),
        if (_isLocked) ...[
          const SizedBox(height: 14),
          Text(
              m.descriptionHt?.isNotEmpty == true
                  ? m.descriptionHt!
                  : 'Vote pou moun ou sipòte epi agimante pozisyon ou.',
              style: const TextStyle(
                  color: Color(0xFFC8B8FF),
                  fontSize: 17,
                  height: 1.35,
                  fontFamily: 'Poppins')),
        ],
        if (!_isLocked) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 5),
              Text(_fmtNum(m.argumentCount),
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
              const SizedBox(width: 18),
              const Icon(Icons.people_outline_rounded,
                  color: AppColors.textMuted, size: 16),
              const SizedBox(width: 5),
              Text(_fmtNum(m.totalVotes),
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
            ],
          ),
        ],
      ]),
    );
  }

  Widget _buildPreVoteOptions() {
    final m = _matchup!;
    final optA = m.optionA;
    final optB = m.optionB;
    if (optA == null || optB == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(children: [
            Expanded(
              child: _PreVoteOptionCard(
                option: optA,
                accent: AppColors.purple,
                alignEnd: true,
                selected: _selectedOptionId == optA.id,
                onTap: () => setState(() => _selectedOptionId = optA.id),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: _PreVoteOptionCard(
                option: optB,
                accent: AppColors.pink,
                alignEnd: false,
                selected: _selectedOptionId == optB.id,
                onTap: () => setState(() => _selectedOptionId = optB.id),
              ),
            ),
          ]),
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _matchupPageBg,
              shape: BoxShape.circle,
              border:
                  Border.all(color: AppColors.purple.withValues(alpha: 0.9)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.35),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Text('VS',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCards({bool large = false}) {
    final m = _matchup!;
    final optA = m.optionA;
    final optB = m.optionB;
    if (optA == null || optB == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(children: [
        Expanded(
            child: _OptionCard(
          option: optA,
          accentColor: _matchupDeepPurple,
          gradient: const LinearGradient(
            colors: [_matchupDeepPurple, _matchupDeepPurple],
          ),
          imageAlignment: Alignment.topLeft,
          percent: m.optionAPercent,
          selected: _selectedOptionId == optA.id,
          voted: _myVoteOptionId == optA.id,
          large: large,
          onTap: _isLocked
              ? () => setState(() => _selectedOptionId = optA.id)
              : null,
        )),
        const SizedBox(width: 10),
        Expanded(
            child: _OptionCard(
          option: optB,
          accentColor: _matchupHotPink,
          gradient: const LinearGradient(
            colors: [_matchupHotPink, _matchupHotPink],
          ),
          imageAlignment: Alignment.topRight,
          percent: m.optionBPercent,
          selected: _selectedOptionId == optB.id,
          voted: _myVoteOptionId == optB.id,
          large: large,
          onTap: _isLocked
              ? () => setState(() => _selectedOptionId = optB.id)
              : null,
        )),
      ]),
    );
  }

  Widget _buildProgressBar() {
    final m = _matchup!;
    final pctA = m.optionAPercent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pctA.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            color: _matchupDeepPurple,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            fontFamily: 'Poppins')),
                    Text(m.optionA?.optionName ?? '',
                        style: const TextStyle(
                            color: _matchupDeepPurple,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${_fmtNum(m.totalVotes)} total vwa',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Poppins')),
            ),
            Expanded(
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${m.optionBPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        color: _matchupHotPink,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1,
                        fontFamily: 'Poppins')),
                Text(m.optionB?.optionName ?? '',
                    style: const TextStyle(
                        color: _matchupHotPink,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins'),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ]),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Row(children: [
            Expanded(
              flex: pctA.round().clamp(5, 95),
              child: Container(height: 7, color: _matchupDeepPurple),
            ),
            Expanded(
              flex: (100 - pctA).round().clamp(5, 95),
              child: Container(height: 7, color: _matchupHotPink),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── LOCKED STATE ────────────────────────────────────────────────────────────

  Widget _buildLockedBody() {
    return Column(children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildHeader(),
            _buildPreVoteOptions(),
            const SizedBox(height: 26),
            _buildLockedBackgroundPanel(),
          ]),
        ),
      ),
    ]);
  }

  Widget _buildLockedBackgroundPanel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = width * 1.04;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/bottomback.png',
                  fit: BoxFit.fill,
                ),
              ),
              Positioned(
                left: width * 0.21,
                right: width * 0.21,
                top: height * 0.33,
                child: GradButton(
                  label: 'Vote kounye a',
                  icon: Icons.how_to_vote_rounded,
                  onTap: _openVoteSheet,
                  loading: _submitting,
                  height: 41,
                  gradient: _lockedVoteGradient,
                ),
              ),
              Positioned(
                left: width * 0.21,
                right: width * 0.21,
                top: height * 0.54,
                child: AppPressable(
                  onTap: _openArgumentSheet,
                  haptic: AppHaptic.medium,
                  pressedScale: 0.985,
                  child: Container(
                    height: 41,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Ekri agiman w',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  // ── UNLOCKED STATE ──────────────────────────────────────────────────────────

  Widget _buildUnlockedBody() {
    final m = _matchup!;
    final votedOption =
        m.options.where((o) => o.id == _myVoteOptionId).firstOrNull;

    return Column(children: [
      Expanded(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildOptionCards(large: true),
                    _buildProgressBar(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (votedOption != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width - 32,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.bolt_rounded,
                                        color: Colors.white, size: 14),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Ou deja vote pou ${votedOption.optionName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!_hasChangedVote)
                            GestureDetector(
                              onTap: _changeVote,
                              child: const Text('Chanje vòt ou',
                                  style: TextStyle(
                                      color: AppColors.purpleLight,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins',
                                      decoration: TextDecoration.underline,
                                      decorationColor: AppColors.purpleLight)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_myArgument != null) ...[
                      _buildMyArgumentSection(_myArgument!),
                      const SizedBox(height: 16),
                    ],
                    _buildArgumentsHeader(),
                    const SizedBox(height: 12),
                    _buildSortTabs(),
                    const SizedBox(height: 4),
                  ]),
            ),
            _argumentsLoading
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.purple,
                        ),
                      ),
                    ),
                  )
                : _arguments.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 40),
                          child: Center(
                            child: Text(
                                _argumentsError == null
                                    ? 'Pa gen agiman pou kounye a.'
                                    : 'Nou pa ka chaje agiman yo pou kounye a.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                    fontFamily: 'Poppins')),
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _ArgumentCard(
                              argument: _arguments[i],
                              service: _argumentService,
                              currentUserId: _myInternalUserId,
                              onBoost: () =>
                                  context.push('/boost/${_arguments[i].id}'),
                              onSupport: () => _openSupportSheet(_arguments[i]),
                              onReply: () => _openReplySheet(_arguments[i]),
                              onReadReplies: () =>
                                  _openReadRepliesSheet(_arguments[i]),
                              onReaction: (type) =>
                                  _onReaction(_arguments[i], type),
                            ),
                            childCount: _arguments.length,
                          ),
                        ),
                      ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildMyArgumentSection(ArgumentModel arg) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: AppColors.purpleLight.withValues(alpha: 0.45)),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 6),
                  Text(
                    'Agiman mwen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.edit_outlined, color: Colors.white70, size: 14),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    arg.body,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontFamily: 'Poppins',
                      height: 1.45,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ReactionBtn(
                        icon: '👍',
                        count: _fmtNum(arg.likeCount),
                        active: arg.myReaction == 'like',
                        onTap: () => _onReaction(arg, 'like'),
                      ),
                      const SizedBox(width: 12),
                      _ReactionBtn(
                        icon: '👎',
                        count: _fmtNum(arg.dislikeCount),
                        active: arg.myReaction == 'dislike',
                        onTap: () => _onReaction(arg, 'dislike'),
                      ),
                      if (arg.supportCoins > 0) ...[
                        const SizedBox(width: 12),
                        Image.asset('assets/images/coin.png',
                            width: 14, height: 14),
                        const SizedBox(width: 4),
                        Text(
                          _fmtNum(arg.supportCoins),
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                      const Spacer(),
                      GestureDetector(
                        onTap: () => context.push('/boost/${arg.id}'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.purple.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bolt_rounded,
                                  color: Colors.white, size: 15),
                              SizedBox(width: 5),
                              Text(
                                'Booste',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArgumentsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        const Expanded(
          child: Text('Agiman yo',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Poppins')),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(children: [
            Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 15),
            SizedBox(width: 5),
            Text('Filtre',
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins')),
          ]),
        ),
      ]),
    );
  }

  Widget _buildSortTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _sortTabs.map((t) {
            final (key, label) = t;
            final selected = _argumentSort == key;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (_argumentSort == key) return;
                  setState(() => _argumentSort = key);
                  _loadArguments();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: selected
                      ? const EdgeInsets.all(1.5)
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: selected ? AppColors.primaryGradient : null,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    padding: selected
                        ? const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7)
                        : EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: selected ? _matchupPageBg : null,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(label,
                        style: TextStyle(
                            color:
                                selected ? Colors.white : AppColors.textMuted,
                            fontSize: 12,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w500,
                            fontFamily: 'Poppins')),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _onReaction(ArgumentModel arg, String type) async {
    try {
      if (arg.myReaction == type) {
        await _argumentService.removeReaction(arg.id);
      } else if (type == 'like') {
        await _argumentService.likeArgument(arg.id, ownerUserId: arg.userId);
      } else {
        await _argumentService.dislikeArgument(arg.id);
      }
      await _loadArguments();
    } catch (_) {}
  }
}

// ── Option Card ────────────────────────────────────────────────────────────────

class _PreVoteOptionCard extends StatelessWidget {
  final MatchupOptionModel option;
  final Color accent;
  final bool alignEnd;
  final bool selected;
  final VoidCallback onTap;

  const _PreVoteOptionCard({
    required this.option,
    required this.accent,
    required this.alignEnd,
    required this.selected,
    required this.onTap,
  });

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment =
        alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.right : TextAlign.left;
    final fallbackLetter = option.optionName.trim().isNotEmpty
        ? option.optionName.trim()[0].toUpperCase()
        : '?';
    final imageSource = _optionImageSource(option);

    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 164,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Colors.white : accent,
            width: selected ? 2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: selected ? 0.45 : 0.22),
              blurRadius: selected ? 22 : 14,
              spreadRadius: selected ? 1 : 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.45),
                      AppColors.bg1,
                    ],
                    begin:
                        alignEnd ? Alignment.centerLeft : Alignment.centerRight,
                    end:
                        alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                  ),
                ),
              ),
            ),
            if (imageSource != null)
              Positioned.fill(
                child: _optionImageWidget(
                  imageSource,
                  alignment: alignEnd ? Alignment.topRight : Alignment.topLeft,
                ),
              )
            else
              Positioned(
                left: alignEnd ? null : -8,
                right: alignEnd ? -8 : null,
                bottom: -14,
                child: Container(
                  width: 116,
                  height: 116,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.24),
                  ),
                  child: Text(fallbackLetter,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 58,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Poppins')),
                ),
              ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _matchupPageBg.withValues(alpha: 0.06),
                      _matchupPageBg.withValues(alpha: 0.84),
                    ],
                    begin:
                        alignEnd ? Alignment.centerRight : Alignment.centerLeft,
                    end:
                        alignEnd ? Alignment.centerLeft : Alignment.centerRight,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: crossAxisAlignment,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(option.optionName,
                      textAlign: textAlign,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('${_fmt(option.voteCount)} vòt',
                      textAlign: textAlign,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.2,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _HeaderCircleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      pressedScale: 0.9,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.bg1,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 18),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final MatchupOptionModel option;
  final Color accentColor;
  final LinearGradient gradient;
  final double percent;
  final Alignment imageAlignment;
  final bool selected;
  final bool voted;
  final bool large;
  final VoidCallback? onTap;

  const _OptionCard({
    required this.option,
    required this.accentColor,
    required this.gradient,
    required this.imageAlignment,
    required this.percent,
    required this.selected,
    required this.voted,
    required this.large,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = voted
        ? accentColor
        : selected
            ? accentColor
            : AppColors.border;
    final imageSource = _optionImageSource(option);

    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: large ? 128 : 104,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: selected || voted ? 2 : 1,
          ),
          boxShadow: selected || voted
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(fit: StackFit.expand, children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: gradient),
              ),
            ),
            if (imageSource != null)
              _optionImageWidget(imageSource, alignment: imageAlignment),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: large ? 0.18 : 0.08),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              top: 10,
              child: Text(option.optionName,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: large ? 15 : 13,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                      height: 1.12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text('${percent.toStringAsFixed(0)}%',
                        style: TextStyle(
                            color: large ? Colors.white : Colors.white70,
                            fontSize: large ? 22.8 : 12,
                            fontWeight: large ? FontWeight.w900 : FontWeight.w500,
                            fontFamily: 'Poppins',
                            height: 1)),
                    if (voted) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 15,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ── Argument Card ──────────────────────────────────────────────────────────────

class _ArgumentCard extends StatefulWidget {
  final ArgumentModel argument;
  final ArgumentService service;
  final VoidCallback onBoost;
  final VoidCallback onSupport;
  final VoidCallback onReply;
  final VoidCallback onReadReplies;
  final ValueChanged<String> onReaction;
  final String? currentUserId;

  const _ArgumentCard({
    required this.argument,
    required this.service,
    required this.onBoost,
    required this.onSupport,
    required this.onReply,
    required this.onReadReplies,
    required this.onReaction,
    this.currentUserId,
  });

  @override
  State<_ArgumentCard> createState() => _ArgumentCardState();
}

class _ArgumentCardState extends State<_ArgumentCard> {
  bool _isFollowing = false;
  bool _followLoading = false;

  String _fmt(int v) => v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

  @override
  void initState() {
    super.initState();
    _loadFollowStatus();
  }

  Future<void> _loadFollowStatus() async {
    if (widget.argument.userId == widget.currentUserId) return;
    try {
      final following = await UserService().isFollowing(widget.argument.userId);
      if (mounted) setState(() => _isFollowing = following);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_followLoading) return;
    setState(() => _followLoading = true);
    try {
      if (_isFollowing) {
        await UserService().unfollow(widget.argument.userId);
      } else {
        await UserService().follow(widget.argument.userId);
      }
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  void _openUserProfile() {
    if (widget.argument.username.isEmpty) return;
    context.push('/user/${widget.argument.username}');
  }

  Future<void> _reportArgument() async {
    try {
      await widget.service.report(
        type: 'argument',
        id: widget.argument.id,
        reason: 'reported_from_argument_menu',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rapò a voye. Mèsi dèske w ede kenbe kominote a pwòp.',
              style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapò a echwe: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final arg = widget.argument;
    final isOwnCard = arg.userId == widget.currentUserId;
    final borderColor = arg.optionLabel == 'A'
        ? AppColors.purple.withValues(alpha: 0.5)
        : arg.optionLabel == 'B'
            ? AppColors.pink.withValues(alpha: 0.5)
            : AppColors.borderDim.withValues(alpha: 0.8);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          GestureDetector(
            onTap: _openUserProfile,
            child: UserAvatar(
              radius: 18,
              avatarUrl: arg.userAvatar,
              gender: arg.userGender,
              backgroundColor: AppColors.purpleDim,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                GestureDetector(
                  onTap: _openUserProfile,
                  child: Text('@${arg.username}',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ),
                if (arg.userVerificationStatus == 'approved') ...[
                  const SizedBox(width: 4),
                  VerificationBadge(
                    type: arg.userVerificationType,
                    status: arg.userVerificationStatus,
                    badgeStyle: arg.userVerificationBadgeStyle,
                    size: 13,
                  ),
                ],
              ]),
              Text(timeago.format(arg.createdAt, locale: 'en_short'),
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontFamily: 'Poppins')),
            ]),
          ),
          if (!isOwnCard)
            GestureDetector(
              onTap: _followLoading ? null : _toggleFollow,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _isFollowing
                      ? AppColors.purpleDim
                      : AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isFollowing
                        ? AppColors.purpleLight.withValues(alpha: 0.5)
                        : AppColors.purple.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _isFollowing ? 'Swiv ✓' : 'Swiv',
                  style: TextStyle(
                      color: _isFollowing
                          ? AppColors.purpleLight
                          : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins'),
                ),
              ),
            ),
          if (arg.isBoosted) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('+120 wè',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins')),
            ),
          ],
          if (!isOwnCard) ...[
            const SizedBox(width: 4),
            AppPressable(
              onTap: _reportArgument,
              haptic: AppHaptic.warning,
              pressedScale: 0.88,
              child: Image.asset(
                'assets/images/report.png',
                width: 18,
                height: 18,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        // Body
        Text(arg.body,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontFamily: 'Poppins',
                height: 1.45),
            maxLines: 4,
            overflow: TextOverflow.ellipsis),
        if (arg.supportCoins > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.pink.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.pink.withValues(alpha: 0.28)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Image.asset('assets/images/coin.png', width: 16, height: 16),
              const SizedBox(width: 6),
              Text('${_fmt(arg.supportCoins)} coins sipò',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
              if (arg.supportCount > 0) ...[
                const SizedBox(width: 6),
                Text('• ${_fmt(arg.supportCount)} moun',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontFamily: 'Poppins')),
              ],
            ]),
          ),
        ],
        const SizedBox(height: 10),
        // Footer actions
        Row(children: [
          _ReactionBtn(
            icon: '👍',
            count: _fmt(arg.likeCount),
            active: arg.myReaction == 'like',
            onTap: () => widget.onReaction('like'),
          ),
          const SizedBox(width: 12),
          _ReactionBtn(
            icon: '👎',
            count: _fmt(arg.dislikeCount),
            active: arg.myReaction == 'dislike',
            onTap: () => widget.onReaction('dislike'),
          ),
          const SizedBox(width: 12),
          AppPressable(
            onTap: widget.onReply,
            haptic: AppHaptic.selection,
            child: const Text('Reponn',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins')),
          ),
          if (arg.replyCount > 0) ...[
            const SizedBox(width: 10),
            AppPressable(
              onTap: widget.onReadReplies,
              haptic: AppHaptic.selection,
              child: Text('Li ${_fmt(arg.replyCount)} repons ▾',
                  style: const TextStyle(
                      color: AppColors.purpleLight,
                      fontSize: 12,
                      fontFamily: 'Poppins')),
            ),
          ],
          const Spacer(),
          if (!isOwnCard)
            AppPressable(
              onTap: widget.onSupport,
              haptic: AppHaptic.medium,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.pink.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: AppColors.pink.withValues(alpha: 0.3)),
                ),
                child: const Text('Sipòte',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
              ),
            ),
          if (isOwnCard) ...[
            const SizedBox(width: 8),
            AppPressable(
              onTap: widget.onBoost,
              haptic: AppHaptic.medium,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purpleDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Booste',
                    style: TextStyle(
                        color: AppColors.purpleLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
              ),
            ),
          ],
        ]),
      ]),
    );
  }
}

class _ReactionBtn extends StatelessWidget {
  final String icon;
  final String count;
  final bool active;
  final VoidCallback onTap;
  const _ReactionBtn(
      {required this.icon,
      required this.count,
      required this.active,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: active ? AppHaptic.selection : AppHaptic.light,
      pressedScale: 0.9,
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 15)),
        const SizedBox(width: 3),
        Text(count,
            style: TextStyle(
                color: active ? AppColors.purpleLight : AppColors.textMuted,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Poppins')),
      ]),
    );
  }
}

class _SupportBottomSheet extends StatefulWidget {
  final ArgumentModel argument;
  final CoinService coinService;
  final VoidCallback onSupported;
  final String? currentUserId;

  const _SupportBottomSheet({
    required this.argument,
    required this.coinService,
    required this.onSupported,
    this.currentUserId,
  });

  @override
  State<_SupportBottomSheet> createState() => _SupportBottomSheetState();
}

class _SupportBottomSheetState extends State<_SupportBottomSheet> {
  int _selected = 25;
  bool _loading = false;
  int _balance = 0;
  List<int> _amounts = CoinEconomyConfig.fallback.supportAmounts;

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balanceFuture = widget.coinService.getBalance();
    final economyFuture = widget.coinService.getEconomyConfig();
    final balance = await balanceFuture;
    final economy = await economyFuture;
    if (mounted) {
      setState(() {
        _balance = balance;
        _amounts = economy.supportAmounts;
        if (!_amounts.contains(_selected)) {
          _selected = _amounts.length > 1 ? _amounts[1] : _amounts.first;
        }
      });
    }
  }

  Future<void> _support() async {
    if (widget.argument.userId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Ou pa ka sipòte pwòp agiman ou.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    if (_balance < _selected) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Balans coins ou pa sifi.',
            style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.warning,
      ));
      return;
    }
    setState(() => _loading = true);
    try {
      await widget.coinService.supportArgument(
        argumentId: widget.argument.id,
        amount: _selected,
        ownerUserId: widget.argument.userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ou sipòte agiman an ak $_selected coins.',
            style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.card,
      ));
      widget.onSupported();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erè: ${e.toString()}',
              style: const TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Sipòte agiman sa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Coins yo ogmante vizibilite ak enfliyans. Yo pa transfere bay kreyatè a.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/images/coin.png', width: 18, height: 18),
            const SizedBox(width: 6),
            Text('Balans: $_balance',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
          ]),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _amounts.map((amount) {
              final selected = amount == _selected;
              return AppPressable(
                onTap: () => setState(() => _selected = amount),
                haptic: AppHaptic.selection,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 74,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.pink : AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? AppColors.pink : AppColors.border,
                    ),
                  ),
                  child: Text(
                    '$amount',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          GradButton(
            label: 'Sipòte ak $_selected coins',
            onTap: _loading ? null : _support,
            loading: _loading,
            iconAsset: 'assets/images/fire.png',
          ),
          const SizedBox(height: 10),
          AppPressable(
            onTap: () => Navigator.pop(context),
            haptic: AppHaptic.selection,
            child: const Text('Anile',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontFamily: 'Poppins')),
          ),
        ]),
      ),
    );
  }
}

// ── Vote Bottom Sheet ──────────────────────────────────────────────────────────

class _VoteBottomSheet extends StatefulWidget {
  final MatchupModel matchup;
  final void Function(String optionId, String body) onSubmit;
  final bool submitting;
  const _VoteBottomSheet(
      {required this.matchup,
      required this.onSubmit,
      required this.submitting});

  @override
  State<_VoteBottomSheet> createState() => _VoteBottomSheetState();
}

class _VoteBottomSheetState extends State<_VoteBottomSheet> {
  String? _selectedId;
  final _bodyCtrl = TextEditingController();

  @override
  void dispose() {
    _bodyCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedId != null && _bodyCtrl.text.trim().length >= 10;

  Color get _selectedSideColor {
    final optB = widget.matchup.optionB;
    return _selectedId == optB?.id ? _matchupHotPink : _matchupDeepPurple;
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.matchup;
    final optA = m.optionA;
    final optB = m.optionB;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                const Text('Vote pou on bò!',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 4),
                Text(m.titleHt,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 16),
                if (optA != null && optB != null)
                  Row(children: [
                    Expanded(
                        child: _SheetOptionBtn(
                      option: optA,
                      selectedColor: _matchupDeepPurple,
                      selected: _selectedId == optA.id,
                      onTap: () => setState(() => _selectedId = optA.id),
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _SheetOptionBtn(
                      option: optB,
                      selectedColor: _matchupHotPink,
                      selected: _selectedId == optB.id,
                      onTap: () => setState(() => _selectedId = optB.id),
                    )),
                  ]),
                const SizedBox(height: 16),
                const Text('Agiman ou',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins')),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedId == null
                          ? AppColors.border
                          : _selectedSideColor,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _bodyCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLines: 4,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontFamily: 'Poppins'),
                    decoration: const InputDecoration(
                      hintText:
                          'Eksplike poukisa ou panse konsa... (10 karaktè pou pi piti)',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                          fontFamily: 'Poppins'),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _VoteSubmitButton(
                  active: _canSubmit,
                  loading: widget.submitting,
                  activeColor: _selectedSideColor,
                  onTap: _canSubmit
                      ? () => widget.onSubmit(_selectedId!, _bodyCtrl.text)
                      : null,
                ),
              ]),
        ),
      ),
    );
  }
}

class _SheetOptionBtn extends StatelessWidget {
  final MatchupOptionModel option;
  final Color selectedColor;
  final bool selected;
  final VoidCallback onTap;
  const _SheetOptionBtn(
      {required this.option,
      required this.selectedColor,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 54,
        decoration: BoxDecoration(
          color: selected ? selectedColor : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? selectedColor : AppColors.border, width: 1.5),
        ),
        child: Center(
          child: Text(option.optionName,
              style: TextStyle(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}

class _VoteSubmitButton extends StatelessWidget {
  final bool active;
  final bool loading;
  final Color activeColor;
  final VoidCallback? onTap;

  const _VoteSubmitButton({
    required this.active,
    required this.loading,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: active && !loading ? onTap : null,
      haptic: AppHaptic.medium,
      pressedScale: 0.985,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: activeColor, width: 1.5),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.32),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: loading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.how_to_vote_rounded,
                      color: active ? Colors.white : activeColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Soumèt vòt ak agimanw',
                    style: TextStyle(
                      color: active ? Colors.white : activeColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Argument-only Bottom Sheet ─────────────────────────────────────────────────

class _ArgumentBottomSheet extends StatefulWidget {
  final void Function(String body) onSubmit;
  final bool submitting;
  const _ArgumentBottomSheet(
      {required this.onSubmit, required this.submitting});

  @override
  State<_ArgumentBottomSheet> createState() => _ArgumentBottomSheetState();
}

class _ArgumentBottomSheetState extends State<_ArgumentBottomSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Ekri agimanw...',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 5,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                  decoration: const InputDecoration(
                    hintText: 'Eksplike poukisa ou panse konsa...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GradButton(
                label: 'Soumèt agimanw',
                icon: Icons.send_rounded,
                onTap: _ctrl.text.trim().length >= 10
                    ? () => widget.onSubmit(_ctrl.text)
                    : null,
                loading: widget.submitting,
              ),
            ]),
      ),
    );
  }
}

// ── Change Vote Sheet ──────────────────────────────────────────────────────────

class _ChangeVoteSheet extends StatefulWidget {
  final MatchupModel matchup;
  final String? currentOptionId;
  const _ChangeVoteSheet({required this.matchup, this.currentOptionId});

  @override
  State<_ChangeVoteSheet> createState() => _ChangeVoteSheetState();
}

class _ChangeVoteSheetState extends State<_ChangeVoteSheet> {
  late String? _selectedId;

  @override
  void initState() {
    super.initState();
    // Default to the OTHER option so the user only needs to confirm
    final optA = widget.matchup.optionA;
    final optB = widget.matchup.optionB;
    if (widget.currentOptionId == optA?.id) {
      _selectedId = optB?.id;
    } else {
      _selectedId = optA?.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.matchup;
    final optA = m.optionA;
    final optB = m.optionB;

    Color selectedColor(String? id) =>
        id == optB?.id ? _matchupHotPink : _matchupDeepPurple;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Chanje vòt ou',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Chwazi opsyon ou vle vote pou',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 20),
            if (optA != null && optB != null)
              Row(children: [
                Expanded(
                  child: _ChangeVoteOption(
                    option: optA,
                    color: _matchupDeepPurple,
                    selected: _selectedId == optA.id,
                    isCurrent: widget.currentOptionId == optA.id,
                    onTap: () => setState(() => _selectedId = optA.id),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ChangeVoteOption(
                    option: optB,
                    color: _matchupHotPink,
                    selected: _selectedId == optB.id,
                    isCurrent: widget.currentOptionId == optB.id,
                    onTap: () => setState(() => _selectedId = optB.id),
                  ),
                ),
              ]),
            const SizedBox(height: 20),
            GestureDetector(
              onTap:
                  _selectedId != null && _selectedId != widget.currentOptionId
                      ? () => Navigator.pop(context, _selectedId)
                      : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: _selectedId != null &&
                          _selectedId != widget.currentOptionId
                      ? selectedColor(_selectedId)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedColor(_selectedId),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Wi, chanje vòt mwen',
                    style: TextStyle(
                      color: _selectedId != null &&
                              _selectedId != widget.currentOptionId
                          ? Colors.white
                          : selectedColor(_selectedId),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Center(
                child: Text('Anile',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeVoteOption extends StatelessWidget {
  final MatchupOptionModel option;
  final Color color;
  final bool selected;
  final bool isCurrent;
  final VoidCallback onTap;

  const _ChangeVoteOption({
    required this.option,
    required this.color,
    required this.selected,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      haptic: AppHaptic.selection,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? color : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              option.optionName,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            if (isCurrent)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  'vòt aktyèl',
                  style: TextStyle(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppColors.textMuted,
                    fontSize: 10,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Reply Bottom Sheet ─────────────────────────────────────────────────────────

class _ReplyBottomSheet extends StatefulWidget {
  final ArgumentModel argument;
  final ArgumentService service;
  const _ReplyBottomSheet({required this.argument, required this.service});

  @override
  State<_ReplyBottomSheet> createState() => _ReplyBottomSheetState();
}

class _ReplyBottomSheetState extends State<_ReplyBottomSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.service.replyToArgument(
        widget.argument.id,
        body,
        ownerUserId: widget.argument.userId,
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              const Text('Reponn agiman sa',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Poppins')),
              const SizedBox(height: 6),
              Text('"${widget.argument.body}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                      fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (_) => setState(() {}),
                  maxLines: 3,
                  autofocus: true,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontFamily: 'Poppins'),
                  decoration: const InputDecoration(
                    hintText: 'Ekri repons ou...',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontFamily: 'Poppins'),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GradButton(
                label: 'Voye repons',
                icon: Icons.reply_rounded,
                onTap: _ctrl.text.trim().isNotEmpty ? _send : null,
                loading: _sending,
              ),
            ]),
      ),
    );
  }
}

// ── Replies View Sheet ─────────────────────────────────────────────────────────

class _RepliesViewSheet extends StatefulWidget {
  final ArgumentModel argument;
  final ArgumentService service;
  final String? currentUserId;
  const _RepliesViewSheet(
      {required this.argument, required this.service, this.currentUserId});

  @override
  State<_RepliesViewSheet> createState() => _RepliesViewSheetState();
}

class _RepliesViewSheetState extends State<_RepliesViewSheet> {
  List<Map<String, dynamic>> _replies = [];
  bool _loading = true;
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final replies = await widget.service.getReplies(widget.argument.id);
      if (mounted) {
        setState(() {
          _replies = replies;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _ctrl.text.trim();
    if (body.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.service.replyToArgument(
        widget.argument.id,
        body,
        ownerUserId: widget.argument.userId,
      );
      _ctrl.clear();
      await _load();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollCtrl) => Column(children: [
        Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: AppColors.border, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Text('${widget.argument.replyCount} repons',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child:
                  const Icon(Icons.close, color: AppColors.textMuted, size: 20),
            ),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '"${widget.argument.body}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins',
                fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.purple))
              : _replies.isEmpty
                  ? const Center(
                      child: Text('Pa gen repons encore.',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontFamily: 'Poppins')))
                  : ListView.separated(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _replies.length,
                      separatorBuilder: (_, __) => Divider(
                          color: AppColors.border.withValues(alpha: 0.4),
                          height: 1),
                      itemBuilder: (_, i) {
                        final r = _replies[i];
                        final user = r['user'] is List
                            ? (r['user'] as List).firstOrNull
                            : r['user'] as Map?;
                        final username =
                            user?['username'] as String? ?? 'Itilizatè';
                        final avatar = user?['avatar_url'] as String?;
                        final gender = user?['gender'] as String?;
                        final verificationType =
                            user?['verification_type'] as String?;
                        final verificationStatus =
                            user?['verification_status'] as String?;
                        final verificationBadgeStyle =
                            user?['verification_badge_style'] as String?;
                        final body = r['body'] as String? ?? '';
                        final createdAt = r['created_at'] != null
                            ? DateTime.tryParse(r['created_at'] as String)
                            : null;
                        void openReplyUser() {
                          if (username.isEmpty || username == 'Itilizatè') {
                            return;
                          }
                          context.push('/user/$username');
                        }

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: openReplyUser,
                                  child: UserAvatar(
                                    radius: 16,
                                    avatarUrl: avatar,
                                    gender: gender,
                                    backgroundColor: AppColors.purpleDim,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(children: [
                                          GestureDetector(
                                            onTap: openReplyUser,
                                            child: Text('@$username',
                                                style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    fontFamily: 'Poppins')),
                                          ),
                                          if (verificationStatus ==
                                              'approved') ...[
                                            const SizedBox(width: 4),
                                            VerificationBadge(
                                              type: verificationType,
                                              status: verificationStatus,
                                              badgeStyle:
                                                  verificationBadgeStyle,
                                              size: 12,
                                            ),
                                          ],
                                          if (createdAt != null) ...[
                                            const SizedBox(width: 6),
                                            Text(
                                                timeago.format(createdAt,
                                                    locale: 'en_short'),
                                                style: const TextStyle(
                                                    color: AppColors.textMuted,
                                                    fontSize: 10,
                                                    fontFamily: 'Poppins')),
                                          ],
                                        ]),
                                        const SizedBox(height: 3),
                                        Text(body,
                                            style: const TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                                fontFamily: 'Poppins',
                                                height: 1.4)),
                                      ]),
                                ),
                              ]),
                        );
                      },
                    ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border)),
                child: TextField(
                  controller: _ctrl,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontFamily: 'Poppins'),
                  decoration: const InputDecoration(
                    hintText: 'Ekri repons ou…',
                    hintStyle: TextStyle(
                        color: AppColors.textMuted, fontFamily: 'Poppins'),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _ctrl.text.trim().isNotEmpty && !_sending ? _send : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: _ctrl.text.trim().isNotEmpty
                      ? AppColors.primaryGradient
                      : null,
                  color: _ctrl.text.trim().isEmpty ? AppColors.card : null,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.send_rounded,
                        color: _ctrl.text.trim().isNotEmpty
                            ? Colors.white
                            : AppColors.textMuted,
                        size: 18),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
