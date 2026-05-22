import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/common/grad_button.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/common/verification_badge.dart';

// ignore_for_file: unused_import

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Tab 0 – AI Drafts
  List<AiDraftModel> _drafts = [];
  bool _draftsLoading = true;
  bool _scanRunning = false;

  // Tab 1 – Matchups
  List<MatchupModel> _matchups = [];
  bool _matchupsLoading = true;

  // Tab 2 – Prediksyon
  List<PredictionModel> _predictions = [];
  bool _predictionsLoading = true;

  // Tab 3 – Rapò
  List<Map<String, dynamic>> _reports = [];
  bool _reportsLoading = true;

  // Tab 4 – Itilizatè
  List<UserModel> _users = [];
  bool _usersLoading = true;

  // Tab 5 – Kategori
  List<CategoryModel> _categories = [];
  bool _categoriesLoading = true;

  // Tab 6 – Verifikasyon
  List<VerificationRequestModel> _verificationRequests = [];
  bool _verificationLoading = true;

  final _tabs = const [
    'Drafts',
    'Matchups',
    'Prediksyon',
    'Rapò',
    'Itilizatè',
    'Kategori',
    'Verifikasyon',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(_onTabChanged);
    _checkAdmin();
    _loadDrafts();
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _checkAdmin() async {
    final user = await UserService().getProfile();
    if (mounted && (user == null || !user.isAdmin)) {
      context.go('/home');
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    switch (_tabController.index) {
      case 0:
        _loadDrafts();
        break;
      case 1:
        _loadMatchups();
        break;
      case 2:
        _loadPredictions();
        break;
      case 3:
        _loadReports();
        break;
      case 4:
        _loadUsers();
        break;
      case 5:
        _loadCategories();
        break;
      case 6:
        _loadVerificationRequests();
        break;
    }
  }

  Future<void> _loadDrafts() async {
    if (!_draftsLoading) setState(() => _draftsLoading = true);
    try {
      final data = await AdminService().getPendingDrafts();
      if (mounted) {
        setState(() {
          _drafts = data;
          _draftsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _draftsLoading = false);
    }
  }

  Future<void> _loadMatchups() async {
    setState(() => _matchupsLoading = true);
    try {
      final data = await AdminService().getAllMatchups();
      if (mounted) {
        setState(() {
          _matchups = data;
          _matchupsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _matchupsLoading = false);
    }
  }

  Future<void> _loadPredictions() async {
    setState(() => _predictionsLoading = true);
    try {
      final data = await AdminService().getAllPredictions();
      if (mounted) {
        setState(() {
          _predictions = data;
          _predictionsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _predictionsLoading = false);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _reportsLoading = true);
    try {
      final data = await AdminService().getPendingReports();
      if (mounted) {
        setState(() {
          _reports = data;
          _reportsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _reportsLoading = false);
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _usersLoading = true);
    try {
      final data = await AdminService().getUsers();
      if (mounted) {
        setState(() {
          _users = data;
          _usersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _usersLoading = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final data = await AdminService().getCategories();
      if (mounted) {
        setState(() {
          _categories = data;
          _categoriesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  Future<void> _loadVerificationRequests() async {
    setState(() => _verificationLoading = true);
    try {
      final data = await AdminService().getVerificationRequests();
      if (mounted) {
        setState(() {
          _verificationRequests = data;
          _verificationLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _verificationLoading = false);
    }
  }

  Future<void> _approveDraft(String id) async {
    try {
      await AdminService().approveDraft(id);
      _loadDrafts();
      _showSnack('Draft apwouve ✓', AppColors.success);
    } catch (_) {
      _showSnack('Erè: pa kapab apwouve', AppColors.error);
    }
  }

  Future<void> _rejectDraft(String id) async {
    try {
      await AdminService().rejectDraft(id);
      _loadDrafts();
      _showSnack('Draft rejte', AppColors.warning);
    } catch (_) {
      _showSnack('Erè: pa kapab rejte', AppColors.error);
    }
  }

  Future<void> _runScan() async {
    setState(() => _scanRunning = true);
    try {
      await AdminService().runTrendScan();
      _showSnack('Scout Scout kouri! ⚡', AppColors.success);
      await Future.delayed(const Duration(seconds: 3));
      _loadDrafts();
    } catch (_) {
      _showSnack('Erè pandan scout a', AppColors.error);
    } finally {
      if (mounted) setState(() => _scanRunning = false);
    }
  }

  Future<void> _toggleMatchupStatus(MatchupModel m) async {
    try {
      if (m.status == 'published') {
        await AdminService().unpublishMatchup(m.id);
      } else {
        await AdminService().publishMatchup(m.id);
      }
      _loadMatchups();
    } catch (_) {
      _showSnack('Erè pandan chanjman statut', AppColors.error);
    }
  }

  Future<void> _resolveReport(String reportId) async {
    try {
      await supabase
          .from('reports')
          .update({'status': 'resolved'}).eq('id', reportId);
      _loadReports();
      _showSnack('Rapò rezoud ✓', AppColors.success);
    } catch (_) {
      _showSnack('Erè pandan rezoud', AppColors.error);
    }
  }

  Future<void> _approveVerification(VerificationRequestModel request) async {
    try {
      await AdminService().approveVerificationRequest(request);
      await _loadVerificationRequests();
      _showSnack('Verifikasyon apwouve ✓', AppColors.success);
    } catch (_) {
      _showSnack('Pa kapab apwouve demann nan', AppColors.error);
    }
  }

  Future<void> _rejectVerification(VerificationRequestModel request) async {
    final reason = await _askText(
      title: 'Rejte verifikasyon',
      hint: 'Rezon pou itilizatè a',
    );
    if (reason == null) return;
    try {
      await AdminService().rejectVerificationRequest(request, reason: reason);
      await _loadVerificationRequests();
      _showSnack('Demann verifikasyon rejte', AppColors.warning);
    } catch (_) {
      _showSnack('Pa kapab rejte demann nan', AppColors.error);
    }
  }

  Future<void> _revokeVerification(VerificationRequestModel request) async {
    final user = request.user;
    if (user == null) {
      _showSnack('Pa gen itilizatè pou demann sa', AppColors.error);
      return;
    }
    final reason = await _askText(
      title: 'Retire verifikasyon',
      hint: 'Rezon pou retire badj la',
    );
    if (reason == null) return;
    try {
      await AdminService().revokeVerification(user, reason: reason);
      await _loadVerificationRequests();
      await _loadUsers();
      _showSnack('Verifikasyon retire', AppColors.warning);
    } catch (_) {
      _showSnack('Pa kapab retire verifikasyon an', AppColors.error);
    }
  }

  Future<void> _openVerificationDocument(
      VerificationDocumentModel document) async {
    try {
      final url = await AdminService()
          .createVerificationDocumentUrl(document.documentUrl);
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) _showSnack('Pa kapab ouvri dokiman an', AppColors.error);
    } catch (_) {
      _showSnack('Pa kapab ouvri dokiman an', AppColors.error);
    }
  }

  Future<String?> _askText(
      {required String title, required String hint}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(title,
            style: const TextStyle(
                color: AppColors.textPrimary, fontFamily: 'Poppins')),
        content: TextField(
          controller: controller,
          maxLines: 3,
          autofocus: true,
          style: const TextStyle(
              color: AppColors.textPrimary, fontFamily: 'Poppins'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Anile'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Kontinye'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(color: Colors.white, fontFamily: 'Poppins')),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 7,
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        appBar: AppBar(
          backgroundColor: AppColors.bg0,
          elevation: 0,
          leading: AppBackButton(
            onTap: () => context.pop(),
          ),
          title: const Text(
            'Admin Dashboard',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins'),
          ),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.purpleLight,
            indicatorWeight: 3,
            labelColor: AppColors.purpleLight,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins'),
            unselectedLabelStyle:
                const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildDraftsTab(),
            _buildMatchupsTab(),
            _buildPredictionsTab(),
            _buildReportsTab(),
            _buildUsersTab(),
            _buildCategoriesTab(),
            _buildVerificationsTab(),
          ],
        ),
      ),
    );
  }

  // ─── TAB 0: AI Drafts ────────────────────────────────────────────────────

  Widget _buildDraftsTab() {
    return Stack(
      children: [
        _draftsLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purpleLight))
            : _drafts.isEmpty
                ? _emptyState('Paka gen drafts annatant', '🤖')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _drafts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _DraftCard(
                      draft: _drafts[i],
                      onApprove: () => _approveDraft(_drafts[i].id),
                      onReject: () => _rejectDraft(_drafts[i].id),
                    ),
                  ),
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: _scanRunning ? null : _runScan,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x664B1BE1),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child: _scanRunning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🤖', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 6),
                        Text('Kouri Scout',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                fontFamily: 'Poppins')),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB 1: Matchups ─────────────────────────────────────────────────────

  Widget _buildMatchupsTab() {
    return Stack(
      children: [
        _matchupsLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purpleLight))
            : _matchups.isEmpty
                ? _emptyState('Pa gen matchups', '⚔️')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _matchups.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final m = _matchups[i];
                      final isPublished = m.status == 'published';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _StatusBadge(
                                      label: isPublished ? 'Pibliye' : 'Draft',
                                      color: isPublished
                                          ? AppColors.success
                                          : AppColors.textMuted),
                                  const SizedBox(height: 6),
                                  Text(m.titleHt,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins'),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                  if (m.optionA != null && m.optionB != null)
                                    Text(
                                        '${m.optionA!.optionName} vs ${m.optionB!.optionName}',
                                        style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                            fontFamily: 'Poppins'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _toggleMatchupStatus(m),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isPublished
                                      ? AppColors.warning
                                          .withValues(alpha: 0.15)
                                      : AppColors.success
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: isPublished
                                          ? AppColors.warning
                                              .withValues(alpha: 0.4)
                                          : AppColors.success
                                              .withValues(alpha: 0.4),
                                      width: 1),
                                ),
                                child: Text(
                                  isPublished ? 'Depiblie' : 'Pibliye',
                                  style: TextStyle(
                                      color: isPublished
                                          ? AppColors.warning
                                          : AppColors.success,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Poppins'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: () => _showCreateMatchupDialog(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x664B1BE1),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateMatchupDialog() async {
    final cats = await AdminService().getCategories();
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (_) =>
            _CreateMatchupDialog(categories: cats, onCreate: _loadMatchups));
  }

  // ─── TAB 2: Prediksyon ───────────────────────────────────────────────────

  Widget _buildPredictionsTab() {
    return Stack(
      children: [
        _predictionsLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purpleLight))
            : _predictions.isEmpty
                ? _emptyState('Pa gen prediksyon', '🔮')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _predictions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = _predictions[i];
                      final deadline =
                          '${p.deadlineAt.day}/${p.deadlineAt.month}/${p.deadlineAt.year}';
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _StatusBadge(
                                    label: p.isActive ? 'Aktif' : 'Fèmen',
                                    color: p.isActive
                                        ? AppColors.success
                                        : AppColors.textMuted),
                                const SizedBox(width: 8),
                                Text('Deadline: $deadline',
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                        fontFamily: 'Poppins')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(p.titleHt,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('${p.optionA} vs ${p.optionB}',
                                style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 11,
                                    fontFamily: 'Poppins')),
                          ],
                        ),
                      );
                    },
                  ),
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: () => _showCreatePredictionDialog(),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x664B1BE1),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  void _showCreatePredictionDialog() async {
    final cats = await AdminService().getCategories();
    if (!mounted) return;
    showDialog(
        context: context,
        builder: (_) => _CreatePredictionDialog(
            categories: cats, onCreate: _loadPredictions));
  }

  // ─── TAB 3: Rapò ─────────────────────────────────────────────────────────

  Widget _buildReportsTab() {
    if (_reportsLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purpleLight));
    }
    if (_reports.isEmpty) return _emptyState('Pa gen rapò annatant', '✅');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final r = _reports[i];
        final type = r['reported_type'] as String? ?? 'unknown';
        final reason = r['reason'] as String? ?? '';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3), width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(
                        label: type.toUpperCase(), color: AppColors.error),
                    const SizedBox(height: 6),
                    Text(reason.isNotEmpty ? reason : 'Pa gen rezon',
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontFamily: 'Poppins'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _resolveReport(r['id'] as String),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withValues(alpha: 0.4),
                        width: 1),
                  ),
                  child: const Text('Rezoud',
                      style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Poppins')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 4: Itilizatè ────────────────────────────────────────────────────

  Widget _buildUsersTab() {
    if (_usersLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purpleLight));
    }
    if (_users.isEmpty) return _emptyState('Pa gen itilizatè', '👤');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = _users[i];
        final isAdmin = u.role == 'admin' || u.role == 'moderator';
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.border.withValues(alpha: 0.5), width: 1),
          ),
          child: Row(
            children: [
              UserAvatar.fromUser(
                u,
                radius: 20,
                backgroundColor: AppColors.purpleDim,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('@${u.username}',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins')),
                        const SizedBox(width: 5),
                        VerificationBadge.user(u, size: 14),
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: AppColors.pink.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6)),
                            child: Text(u.role.toUpperCase(),
                                style: const TextStyle(
                                    color: AppColors.pink,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'Poppins')),
                          ),
                        ],
                      ],
                    ),
                    Text(u.email,
                        style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 12)),
                  Text('${u.participationCount}',
                      style: const TextStyle(
                          color: AppColors.purpleLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── TAB 6: Verifikasyon ────────────────────────────────────────────────

  Widget _buildVerificationsTab() {
    if (_verificationLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.purpleLight));
    }
    if (_verificationRequests.isEmpty) {
      return _emptyState('Pa gen demann verifikasyon', '✓');
    }

    return RefreshIndicator(
      onRefresh: _loadVerificationRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _verificationRequests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final request = _verificationRequests[i];
          final user = request.user;
          final canReview =
              request.status == 'pending' || request.status == 'under_review';
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.55), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    UserAvatar.fromUser(
                      user,
                      radius: 20,
                      backgroundColor: AppColors.purpleDim,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  user == null
                                      ? 'Itilizatè'
                                      : '@${user.username}',
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              VerificationBadge(
                                type: request.verificationType,
                                status: 'approved',
                                size: 16,
                              ),
                            ],
                          ),
                          Text(
                            request.typeLabel,
                            style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                                fontFamily: 'Poppins'),
                          ),
                        ],
                      ),
                    ),
                    _statusPill(request.status),
                  ],
                ),
                const SizedBox(height: 12),
                if (request.displayName?.isNotEmpty == true)
                  _adminMeta('Non piblik', request.displayName!),
                if (request.legalName?.isNotEmpty == true)
                  _adminMeta('Non legal', request.legalName!),
                if (request.organizationName?.isNotEmpty == true)
                  _adminMeta('Òganizasyon', request.organizationName!),
                if (request.website?.isNotEmpty == true)
                  _adminMeta('Sit', request.website!),
                if (request.organizationEmail?.isNotEmpty == true)
                  _adminMeta('Imèl', request.organizationEmail!),
                if (request.socialLinks?.isNotEmpty == true)
                  _adminMeta('Lyen', request.socialLinks!),
                if (request.proofNotes?.isNotEmpty == true)
                  _adminMeta('Prèv', request.proofNotes!),
                if (request.documents.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var d = 0; d < request.documents.length; d++)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _openVerificationDocument(request.documents[d]),
                          icon: const Icon(Icons.lock_open_rounded, size: 16),
                          label: Text('Dokiman ${d + 1}'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purpleLight,
                            side: BorderSide(
                              color:
                                  AppColors.purpleLight.withValues(alpha: 0.5),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                ],
                if (request.rejectionReason?.isNotEmpty == true)
                  _adminMeta('Rezon rejè', request.rejectionReason!),
                if (canReview) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _rejectVerification(request),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Rejte'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _approveVerification(request),
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Apwouve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (request.status == 'approved' && request.user != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _revokeVerification(request),
                      icon:
                          const Icon(Icons.remove_moderator_outlined, size: 18),
                      label: const Text('Retire badj verifikasyon'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _adminMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              height: 1.35,
              fontFamily: 'Poppins'),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = switch (status) {
      'approved' => AppColors.success,
      'rejected' => AppColors.error,
      'under_review' => AppColors.warning,
      _ => AppColors.textMuted,
    };
    final label = switch (status) {
      'approved' => 'Apwouve',
      'rejected' => 'Rejte',
      'under_review' => 'Revizyon',
      _ => 'Annatant',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            fontFamily: 'Poppins'),
      ),
    );
  }

  // ─── TAB 5: Kategori ─────────────────────────────────────────────────────

  Widget _buildCategoriesTab() {
    return Stack(
      children: [
        _categoriesLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.purpleLight))
            : _categories.isEmpty
                ? _emptyState('Pa gen kategori', '📂')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _categories[i];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.border.withValues(alpha: 0.5),
                              width: 1),
                        ),
                        child: Row(
                          children: [
                            Text(c.icon ?? '📂',
                                style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.nameHt,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          fontFamily: 'Poppins')),
                                  Text(c.nameEn,
                                      style: const TextStyle(
                                          color: AppColors.textMuted,
                                          fontSize: 12,
                                          fontFamily: 'Poppins')),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        Positioned(
          bottom: 24,
          right: 20,
          child: GestureDetector(
            onTap: () => showDialog(
                context: context,
                builder: (_) => _AddCategoryDialog(onCreate: _loadCategories)),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x664B1BE1),
                      blurRadius: 16,
                      offset: Offset(0, 6))
                ],
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  Widget _emptyState(String msg, String emoji) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(msg,
              style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontFamily: 'Poppins')),
        ],
      ),
    );
  }
}

// ─── Draft Card ───────────────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  final AiDraftModel draft;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _DraftCard(
      {required this.draft, required this.onApprove, required this.onReject});

  Color get _riskColor {
    switch (draft.riskLevel) {
      case 'low':
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      case 'high':
        return AppColors.error;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(
                  label: draft.type.toUpperCase(),
                  color: AppColors.purpleLight),
              const SizedBox(width: 8),
              if (draft.riskLevel != null)
                _StatusBadge(
                    label: (draft.riskLevel ?? '').toUpperCase(),
                    color: _riskColor),
              const Spacer(),
              if (draft.trendScore != null)
                Text('trend: ${draft.trendScore!.toStringAsFixed(1)}',
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'Poppins')),
            ],
          ),
          const SizedBox(height: 10),
          Text(draft.titleHt,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.purpleLight.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('A: ${draft.optionA}',
                      style: const TextStyle(
                          color: AppColors.purpleLight,
                          fontSize: 12,
                          fontFamily: 'Poppins'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: AppColors.pink.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('B: ${draft.optionB}',
                      style: const TextStyle(
                          color: AppColors.pink,
                          fontSize: 12,
                          fontFamily: 'Poppins'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onReject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: const Center(
                        child: Text('✗ Rejte',
                            style: TextStyle(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Poppins'))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onApprove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                          width: 1),
                    ),
                    child: const Center(
                        child: Text('✓ Aprouve',
                            style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                fontFamily: 'Poppins'))),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins')),
    );
  }
}

// ─── Create Matchup Dialog ────────────────────────────────────────────────────

class _CreateMatchupDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final VoidCallback onCreate;
  const _CreateMatchupDialog(
      {required this.categories, required this.onCreate});

  @override
  State<_CreateMatchupDialog> createState() => _CreateMatchupDialogState();
}

class _CreateMatchupDialogState extends State<_CreateMatchupDialog> {
  CategoryModel? _selectedCat;
  final _titleHt = TextEditingController();
  final _titleEn = TextEditingController();
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _desc = TextEditingController();
  bool _publish = false;
  bool _creating = false;

  @override
  void dispose() {
    _titleHt.dispose();
    _titleEn.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_selectedCat == null ||
        _titleHt.text.isEmpty ||
        _optionA.text.isEmpty ||
        _optionB.text.isEmpty) {
      return;
    }
    setState(() => _creating = true);
    try {
      await AdminService().createMatchup(
        categoryId: _selectedCat!.id,
        titleHt: _titleHt.text.trim(),
        titleEn: _titleEn.text.trim().isEmpty ? null : _titleEn.text.trim(),
        optionA: _optionA.text.trim(),
        optionB: _optionB.text.trim(),
        descriptionHt: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        publish: _publish,
      );
      widget.onCreate();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvo Matchup',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 16),
            _label('Kategori'),
            DropdownButtonFormField<CategoryModel>(
              initialValue: _selectedCat,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: 14),
              decoration: _inputDec('Chwazi kategori'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text('${c.icon ?? ''} ${c.nameHt}')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCat = v),
            ),
            const SizedBox(height: 12),
            _label('Tit (Kreyòl)'),
            _field(_titleHt, 'Ekri tit la...'),
            const SizedBox(height: 12),
            _label('Tit (Angle) – opsyonèl'),
            _field(_titleEn, 'English title...'),
            const SizedBox(height: 12),
            _label('Opsyon A'),
            _field(_optionA, 'Eks: Lionel Messi'),
            const SizedBox(height: 12),
            _label('Opsyon B'),
            _field(_optionB, 'Eks: Cristiano Ronaldo'),
            const SizedBox(height: 12),
            _label('Deskripsyon – opsyonèl'),
            _field(_desc, 'Deskripsyon...', maxLines: 3),
            const SizedBox(height: 14),
            Row(
              children: [
                Switch(
                    value: _publish,
                    onChanged: (v) => setState(() => _publish = v),
                    activeThumbColor: AppColors.purpleLight),
                const SizedBox(width: 8),
                const Text('Pibliye kounye a?',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontFamily: 'Poppins')),
              ],
            ),
            const SizedBox(height: 16),
            GradButton(
                label: _publish ? 'Kreye & Pibliye' : 'Kreye Draft',
                onTap: _create,
                loading: _creating),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins')),
      );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
        decoration: _inputDec(hint),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 13),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.purpleLight, width: 2)),
      );
}

// ─── Create Prediction Dialog ─────────────────────────────────────────────────

class _CreatePredictionDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final VoidCallback onCreate;
  const _CreatePredictionDialog(
      {required this.categories, required this.onCreate});

  @override
  State<_CreatePredictionDialog> createState() =>
      _CreatePredictionDialogState();
}

class _CreatePredictionDialogState extends State<_CreatePredictionDialog> {
  CategoryModel? _selectedCat;
  final _titleHt = TextEditingController();
  final _optionA = TextEditingController();
  final _optionB = TextEditingController();
  final _desc = TextEditingController();
  DateTime? _deadline;
  bool _creating = false;

  @override
  void dispose() {
    _titleHt.dispose();
    _optionA.dispose();
    _optionB.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.purpleLight, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _create() async {
    if (_selectedCat == null ||
        _titleHt.text.isEmpty ||
        _optionA.text.isEmpty ||
        _optionB.text.isEmpty ||
        _deadline == null) {
      return;
    }
    setState(() => _creating = true);
    try {
      await AdminService().createPrediction(
        categoryId: _selectedCat!.id,
        titleHt: _titleHt.text.trim(),
        optionA: _optionA.text.trim(),
        optionB: _optionB.text.trim(),
        descriptionHt: _desc.text.trim().isEmpty ? null : _desc.text.trim(),
        deadline: _deadline!,
      );
      widget.onCreate();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadlineStr = _deadline != null
        ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
        : 'Chwazi dat...';
    return Dialog(
      backgroundColor: AppColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvo Prediksyon',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 16),
            _label('Kategori'),
            DropdownButtonFormField<CategoryModel>(
              initialValue: _selectedCat,
              dropdownColor: AppColors.card,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'Poppins',
                  fontSize: 14),
              decoration: _inputDec('Chwazi kategori'),
              items: widget.categories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text('${c.icon ?? ''} ${c.nameHt}')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCat = v),
            ),
            const SizedBox(height: 12),
            _label('Tit (Kreyòl)'),
            _field(_titleHt, 'Ekri tit la...'),
            const SizedBox(height: 12),
            _label('Opsyon A'),
            _field(_optionA, 'Opsyon A...'),
            const SizedBox(height: 12),
            _label('Opsyon B'),
            _field(_optionB, 'Opsyon B...'),
            const SizedBox(height: 12),
            _label('Deskripsyon – opsyonèl'),
            _field(_desc, 'Deskripsyon...', maxLines: 3),
            const SizedBox(height: 12),
            _label('Deadline'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _deadline != null
                          ? AppColors.purpleLight
                          : AppColors.border,
                      width: _deadline != null ? 2 : 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: AppColors.purpleLight, size: 16),
                    const SizedBox(width: 10),
                    Text(deadlineStr,
                        style: TextStyle(
                            color: _deadline != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontFamily: 'Poppins',
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            GradButton(
                label: 'Kreye Prediksyon', onTap: _create, loading: _creating),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontFamily: 'Poppins')),
      );

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) =>
      TextFormField(
        controller: c,
        maxLines: maxLines,
        style: const TextStyle(
            color: AppColors.textPrimary, fontFamily: 'Poppins', fontSize: 14),
        decoration: _inputDec(hint),
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 13),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.purpleLight, width: 2)),
      );
}

// ─── Add Category Dialog ──────────────────────────────────────────────────────

class _AddCategoryDialog extends StatefulWidget {
  final VoidCallback onCreate;
  const _AddCategoryDialog({required this.onCreate});

  @override
  State<_AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<_AddCategoryDialog> {
  final _nameHt = TextEditingController();
  final _nameEn = TextEditingController();
  final _icon = TextEditingController();
  bool _creating = false;

  @override
  void dispose() {
    _nameHt.dispose();
    _nameEn.dispose();
    _icon.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_nameHt.text.isEmpty || _nameEn.text.isEmpty) return;
    setState(() => _creating = true);
    try {
      await AdminService().addCategory(_nameHt.text.trim(), _nameEn.text.trim(),
          _icon.text.trim().isEmpty ? '📂' : _icon.text.trim());
      widget.onCreate();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) setState(() => _creating = false);
    }
  }

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: AppColors.textMuted, fontFamily: 'Poppins', fontSize: 13),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                const BorderSide(color: AppColors.purpleLight, width: 2)),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nouvo Kategori',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 16),
            const Text('Non (Kreyòl)',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            TextFormField(
                controller: _nameHt,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'Poppins'),
                decoration: _inputDec('Espò, Politik...')),
            const SizedBox(height: 12),
            const Text('Non (Angle)',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            TextFormField(
                controller: _nameEn,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'Poppins'),
                decoration: _inputDec('Sports, Politics...')),
            const SizedBox(height: 12),
            const Text('Ikòn (emoji)',
                style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontFamily: 'Poppins')),
            const SizedBox(height: 6),
            TextFormField(
                controller: _icon,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontFamily: 'Poppins',
                    fontSize: 22),
                decoration: _inputDec('⚽')),
            const SizedBox(height: 20),
            GradButton(
                label: 'Ajoute Kategori', onTap: _create, loading: _creating),
          ],
        ),
      ),
    );
  }
}
