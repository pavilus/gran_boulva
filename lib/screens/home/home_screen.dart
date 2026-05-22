import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/matchup_search.dart';
import '../../utils/search_utils.dart';
import '../../widgets/common/category_tabs.dart';
import '../../widgets/common/user_avatar.dart';
import '../../widgets/matchup/matchup_card.dart';

class _StaticTopVwa {
  final String username;
  final int votes;
  final int rank;
  final String file;
  const _StaticTopVwa(
      {required this.username,
      required this.votes,
      required this.rank,
      required this.file});
}

const _kTopVwa = [
  _StaticTopVwa(username: 'Sarah.j', votes: 2100, rank: 1, file: 'user1.png'),
  _StaticTopVwa(username: 'Ti_Mack', votes: 1700, rank: 2, file: 'user2.png'),
  _StaticTopVwa(username: 'QueenVee', votes: 1300, rank: 3, file: 'user3.png'),
  _StaticTopVwa(
      username: 'Dr. Haitian', votes: 990, rank: 4, file: 'user4.png'),
  _StaticTopVwa(username: 'JayB', votes: 870, rank: 5, file: 'user5.png'),
  _StaticTopVwa(username: 'Mika', votes: 740, rank: 6, file: 'user6.png'),
];

String _fmtVotes(int v) =>
    v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}K' : '$v';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _matchupService = MatchupService();
  final _userService = UserService();
  final _notificationService = NotificationService();
  final _searchController = TextEditingController();

  List<CategoryModel> _categories = [];
  List<MatchupModel> _allMatchups = [];
  List<MatchupModel> _matchups = [];
  List<TopVoiceModel> _topVoices = [];
  List<TopVoiceModel> _topPredictors = [];
  List<PredictionModel> _predictions = [];
  String _searchQuery = '';
  String _activeCategoryLabel = 'Popilè';
  String _activePredCategoryLabel = 'Tout';
  String? _predCategoryId; // null = all categories in predictions tab
  bool _loading = true;
  bool _predictionsLoading = true;
  int _homeTab = 0; // 0 = Matchups, 1 = Prediksyon
  UserModel? _userProfile;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _init();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
      _matchups = _filterMatchups(_allMatchups, query);
      // _filteredPredictions is a getter — setState alone triggers rebuild
    });
  }

  List<PredictionModel> get _filteredPredictions {
    var list = _predictions;
    if (_predCategoryId != null) {
      list = list.where((p) => p.categoryId == _predCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list = list.where((p) {
        final haystack = [
          p.titleHt,
          p.titleEn,
          p.descriptionHt,
          p.optionA,
          p.optionB,
          p.category?.nameHt,
        ].whereType<String>().join(' ');
        return matchesQuery(haystack, _searchQuery);
      }).toList();
    }
    return list;
  }

  List<MatchupModel> _filterMatchups(
      List<MatchupModel> matchups, String query) {
    return matchups.where((m) => matchupMatchesQuery(m, query)).toList();
  }

  Future<void> _init() async {
    setState(() { _loading = true; _predictionsLoading = true; });
    try {
      final results = await Future.wait([
        _matchupService.getCategories(),
        _matchupService.getHomeFeed(popular: true), // default tab is Popilè
        _userService.getTopVoices(limit: 8),
        PredictionService().getPredictions(),
        PredictionService().getTopPredictors(limit: 8),
      ]);
      if (!mounted) return;
      setState(() {
        _categories      = results[0] as List<CategoryModel>;
        _allMatchups     = results[1] as List<MatchupModel>;
        _topVoices       = results[2] as List<TopVoiceModel>;
        _predictions     = results[3] as List<PredictionModel>;
        _topPredictors   = results[4] as List<TopVoiceModel>;
        _matchups = _filterMatchups(_allMatchups, _searchQuery);
        _loading = false;
        _predictionsLoading = false;
      });
    } catch (e) {
      debugPrint('HomeScreen _init error: $e');
      if (mounted) setState(() { _loading = false; _predictionsLoading = false; });
    }

    // Load user profile and notifications independently so a permissions error
    // on the users table doesn't block the matchup feed from showing.
    try {
      final profile = await _userService.getProfile();
      if (mounted) setState(() => _userProfile = profile);
    } catch (e) {
      debugPrint('HomeScreen getProfile error: $e');
    }
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotifications = count);
    } catch (_) {}
  }

  Future<void> _onCategoryTap(String? categoryId, {bool popular = false}) async {
    setState(() => _loading = true);
    try {
      final matchups = await _matchupService.getHomeFeed(
          categoryId: categoryId, popular: popular);
      if (!mounted) return;
      setState(() {
        _allMatchups = matchups;
        _matchups = _filterMatchups(_allMatchups, _searchQuery);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCategoryLabelTap(String label) {
    if (_homeTab == 0) {
      // ── Matchups tab: fetch from API ───────────────────────────────────────
      setState(() => _activeCategoryLabel = label);
      if (label == 'Popilè') {
        _onCategoryTap(null, popular: true);
        return;
      }
      if (label == 'Tout') {
        _onCategoryTap(null);
        return;
      }
      final match = _categories
          .where((c) => c.nameHt.toLowerCase() == label.toLowerCase())
          .firstOrNull;
      _onCategoryTap(match?.id);
    } else {
      // ── Predictions tab: filter locally ───────────────────────────────────
      final match = label == 'Tout' || label == 'Popilè'
          ? null
          : _categories
              .where((c) => c.nameHt.toLowerCase() == label.toLowerCase())
              .firstOrNull;
      setState(() {
        _activePredCategoryLabel = label;
        _predCategoryId = match?.id;
      });
    }
  }

  Future<void> _toggleSave(MatchupModel matchup, bool save) async {
    await _matchupService.toggleSave(matchup.id, save);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.purple,
          backgroundColor: AppColors.card,
          onRefresh: _init,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: _buildHeroBanner()),
              SliverToBoxAdapter(
                child: _homeTab == 0
                    ? _buildTopVoicesSection()
                    : _buildTopPredictorsSection(),
              ),
              SliverToBoxAdapter(child: _buildHomeTabBar()),
              if (_homeTab == 0)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: _loading
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                  color: AppColors.purple),
                            ),
                          ),
                        )
                      : _matchups.isEmpty
                          ? SliverToBoxAdapter(child: _buildEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) {
                                  final matchup = _matchups[i];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: MatchupCard(
                                      matchup: matchup,
                                      onTap: () async {
                                        await _matchupService
                                            .recordMatchupView(matchup.id);
                                        if (!context.mounted) return;
                                        final voted = matchup.myVoteOptionId;
                                        final query = voted == null
                                            ? ''
                                            : '?voted=${Uri.encodeComponent(voted)}';
                                        context
                                            .push('/matchup/${matchup.id}$query');
                                      },
                                      onSave: (save) =>
                                          _toggleSave(matchup, save),
                                    ),
                                  );
                                },
                                childCount: _matchups.length,
                              ),
                            ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: _predictionsLoading
                      ? const SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                  color: AppColors.purple),
                            ),
                          ),
                        )
                      : _filteredPredictions.isEmpty
                          ? SliverToBoxAdapter(
                              child: _buildPredictionsEmptyState())
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildPredictionCard(
                                      _filteredPredictions[i]),
                                ),
                                childCount: _filteredPredictions.length,
                              ),
                            ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final firstName = (_userProfile?.fullName ?? '').split(' ').first;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Bonjou'
        : hour < 18
            ? 'Bonswa'
            : 'Hi';
    final displayName = firstName.isNotEmpty ? firstName : 'Ou';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          // Left: avatar + greeting → opens menu
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => context.go('/menu'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAvatarWidget(),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$greeting, $displayName!',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const Text(
                          'Vwa ou konte!',
                          style: TextStyle(
                            color: AppColors.pink,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Center: logo (truly centered between both sides)
          const _LogoWidget(),
          // Right: notification bell + coin counter
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => context.go('/notifications'),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Image.asset(
                          'assets/images/notification_unifilled.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                        if (_unreadNotifications > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                  minWidth: 16, minHeight: 16),
                              child: Text(
                                _unreadNotifications > 9
                                    ? '9+'
                                    : '$_unreadNotifications',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Poppins',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarWidget() {
    final user = _userProfile;
    return Container(
      width: 42,
      height: 42,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF6F2BFF), Color(0xFFFF2DAA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: UserAvatar.fromUser(user, radius: 19),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.inputBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Image.asset('assets/images/search.png',
                width: 20, height: 20, fit: BoxFit.contain),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                decoration: InputDecoration(
                  hintText: _homeTab == 0
                      ? 'Chèche matchups, kategori,...'
                      : 'Chèche prediksyon...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                onPressed: _searchController.clear,
                icon: const Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 18),
                tooltip: 'Clear search',
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Image.asset('assets/images/filter.png',
                    width: 22, height: 22, fit: BoxFit.contain),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: CategoryTabs(
        activeCategory:
            _homeTab == 0 ? _activeCategoryLabel : _activePredCategoryLabel,
        onSelect: _onCategoryLabelTap,
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTopVoicesSection() {
    final voices = _topVoices;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/Cardback.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Image.asset('assets/images/trophy.png',
                                    width: 20, height: 20, fit: BoxFit.contain),
                                const SizedBox(width: 6),
                                const Text(
                                  'Tòp Vwa',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/top-voices'),
                              child: const Text(
                                'Wè tout',
                                style: TextStyle(
                                  color: AppColors.purpleLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: voices.isNotEmpty
                                ? voices.length
                                : _kTopVwa.length,
                            itemBuilder: (context, i) {
                              final voice =
                                  voices.isNotEmpty ? voices[i] : null;
                              final fallback = _kTopVwa[i % _kTopVwa.length];
                              final username =
                                  voice?.username ?? fallback.username;
                              final avatar = voice?.avatarUrl;
                              final score =
                                  voice?.influenceScore ?? fallback.votes;
                              return GestureDetector(
                                onTap: () => context.push('/user/$username'),
                                child: Container(
                                  width: 72,
                                  margin: const EdgeInsets.only(right: 12),
                                  child: Column(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.bottomCenter,
                                        children: [
                                          Container(
                                            width: 62,
                                            height: 62,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Color(0xFFA855F7),
                                                  Color(0xFFEC4899)
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(2.5),
                                              child: CircleAvatar(
                                                radius: 27,
                                                backgroundColor:
                                                    AppColors.secondary,
                                                backgroundImage: voice == null
                                                    ? AssetImage(
                                                            'assets/images/${fallback.file}')
                                                        as ImageProvider
                                                    : (avatar != null &&
                                                            avatar.isNotEmpty
                                                        ? CachedNetworkImageProvider(
                                                            avatar)
                                                        : UserAvatar
                                                            .defaultImageProvider(
                                                                null)),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.secondary,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: AppColors.border,
                                                    width: 1),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Image.asset(
                                                    'assets/images/fire.png',
                                                    width: 10,
                                                    height: 10,
                                                    fit: BoxFit.contain,
                                                  ),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    _fmtVotes(score),
                                                    style: const TextStyle(
                                                      color: AppColors.textSecondary,
                                                      fontSize: 8,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: 'Poppins',
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '@$username',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                          fontFamily: 'Poppins',
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPredictorsSection() {
    final predictors = _topPredictors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            color: Colors.transparent,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/images/Cardback.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('🔮',
                                    style: TextStyle(fontSize: 18)),
                                SizedBox(width: 6),
                                Text(
                                  'Tòp Pwofèt',
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () => context.push('/predictions'),
                              child: const Text(
                                'Wè tout',
                                style: TextStyle(
                                  color: AppColors.purpleLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (predictors.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'Pa gen prediksyon aktif kounye a.',
                              style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  fontFamily: 'Poppins'),
                            ),
                          )
                        else
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: predictors.length,
                              itemBuilder: (context, i) {
                                final p = predictors[i];
                                return GestureDetector(
                                  onTap: () =>
                                      context.push('/user/${p.username}'),
                                  child: Container(
                                    width: 72,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      children: [
                                        Stack(
                                          clipBehavior: Clip.none,
                                          alignment: Alignment.bottomCenter,
                                          children: [
                                            Container(
                                              width: 62,
                                              height: 62,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Color(0xFFA855F7),
                                                    Color(0xFFEC4899)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(2.5),
                                                child: CircleAvatar(
                                                  radius: 27,
                                                  backgroundColor:
                                                      AppColors.secondary,
                                                  backgroundImage: p.avatarUrl !=
                                                              null &&
                                                          p.avatarUrl!.isNotEmpty
                                                      ? CachedNetworkImageProvider(
                                                              p.avatarUrl!)
                                                          as ImageProvider
                                                      : UserAvatar
                                                          .defaultImageProvider(
                                                              null),
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: -6,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: AppColors.secondary,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                      color: AppColors.border,
                                                      width: 1),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Text('🔮',
                                                        style: TextStyle(
                                                            fontSize: 8)),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      _fmtVotes(
                                                          p.influenceScore),
                                                      style: const TextStyle(
                                                        color: AppColors
                                                            .textSecondary,
                                                        fontSize: 8,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontFamily: 'Poppins',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '@${p.username}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 10,
                                            fontFamily: 'Poppins',
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
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
            _homeTabItem('⚔️  Matchups', 0),
            _homeTabItem('🔮  Prediksyon', 1),
          ],
        ),
      ),
    );
  }

  Widget _homeTabItem(String label, int index) {
    final active = _homeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _homeTab = index),
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

  String _formatPredDeadline(PredictionModel p) {
    if (p.isClosed) return 'Fèmen';
    if (p.deadlineAt == null) return 'Aktif';
    final d = p.timeLeft;
    if (d.isNegative) return 'Ekspire';
    if (d.inDays > 0) return '${d.inDays}j rete';
    if (d.inHours > 0) return '${d.inHours}h rete';
    return '${d.inMinutes}m rete';
  }

  Widget _buildPredictionCard(PredictionModel p) {
    final deadline = _formatPredDeadline(p);
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
            // Top row: category chip + status badge
            Row(
              children: [
                if (p.category != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.15),
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.textDim.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? '🟢 Aktif' : '🔴 Fèmen',
                    style: TextStyle(
                        color: isActive
                            ? AppColors.success
                            : AppColors.textMuted,
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
            // Option A vs B
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
                  child: Text('VS',
                      style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Poppins')),
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
            // Bottom row: deadline + votes + participation badge
            Row(
              children: [
                const Text('⏰', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                Text(
                  deadline,
                  style: TextStyle(
                      color:
                          isActive ? AppColors.warning : AppColors.textMuted,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

  Widget _buildPredictionsEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🔮', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Pa gen prediksyon aktif kounye a.',
              style: TextStyle(
                  color: AppColors.textMuted, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          children: [
            Text('🔍', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text(
              'Pa gen matchups pou ou nan moman an',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoWidget extends StatelessWidget {
  const _LogoWidget();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo.png',
      width: 36,
      height: 36,
      fit: BoxFit.contain,
    );
  }
}
