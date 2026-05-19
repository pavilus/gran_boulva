import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/matchup_search.dart';
import '../../widgets/common/category_tabs.dart';
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
  String _searchQuery = '';
  String _activeCategoryLabel = 'Popilè';
  bool _loading = true;
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
    });
  }

  List<MatchupModel> _filterMatchups(
      List<MatchupModel> matchups, String query) {
    return matchups.where((m) => matchupMatchesQuery(m, query)).toList();
  }

  Future<void> _init() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _matchupService.getCategories(),
        _matchupService.getHomeFeed(),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _allMatchups = results[1] as List<MatchupModel>;
        _matchups = _filterMatchups(_allMatchups, _searchQuery);
        _loading = false;
      });
    } catch (e) {
      debugPrint('HomeScreen _init error: $e');
      if (mounted) setState(() => _loading = false);
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

  Future<void> _onCategoryTap(String? categoryId) async {
    setState(() => _loading = true);
    try {
      final matchups =
          await _matchupService.getHomeFeed(categoryId: categoryId);
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
              SliverToBoxAdapter(child: _buildTopVoicesSection()),
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
                                return MatchupCard(
                                  matchup: matchup,
                                  onTap: () {
                                    final voted = matchup.myVoteOptionId;
                                    final query = voted == null
                                        ? ''
                                        : '?voted=${Uri.encodeComponent(voted)}';
                                    context
                                        .push('/matchup/${matchup.id}$query');
                                  },
                                  onSave: (save) => _toggleSave(matchup, save),
                                );
                              },
                              childCount: _matchups.length,
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
                            fontSize: 13,
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
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_outlined,
                              color: Colors.white, size: 20),
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
          child: user?.avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: user!.avatarUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _avatarFallback(user.username),
                )
              : _avatarFallback(user?.username ?? ''),
        ),
      ),
    );
  }

  Widget _avatarFallback(String username) => Container(
        color: AppColors.purpleDim,
        alignment: Alignment.center,
        child: Text(
          username.isNotEmpty ? username[0].toUpperCase() : '?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      );

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
            const Icon(Icons.search_rounded,
                color: AppColors.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                decoration: const InputDecoration(
                  hintText: 'Chèche matchups, kategori,...',
                  hintStyle: TextStyle(
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
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune,
                    color: AppColors.textMuted, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  void _onCategoryLabelTap(String label) {
    setState(() => _activeCategoryLabel = label);
    if (label == 'Popilè' || label == 'Tout') {
      _onCategoryTap(null);
      return;
    }
    final match = _categories
        .where((c) => c.nameHt.toLowerCase() == label.toLowerCase())
        .firstOrNull;
    _onCategoryTap(match?.id);
  }

  Widget _buildCategoryChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: CategoryTabs(
        activeCategory: _activeCategoryLabel,
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
                                Icon(Icons.emoji_events_rounded,
                                    color: AppColors.warning, size: 20),
                                SizedBox(width: 6),
                                Text(
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
                              onTap: () {},
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
                            itemCount: _kTopVwa.length,
                            itemBuilder: (context, i) {
                              final v = _kTopVwa[i];
                              return GestureDetector(
                                onTap: () => context.go('/user/${v.username}'),
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
                                                backgroundImage: AssetImage(
                                                    'assets/images/${v.file}'),
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
                                              child: Text(
                                                '🔥 ${_fmtVotes(v.votes)}',
                                                style: const TextStyle(
                                                  color:
                                                      AppColors.textSecondary,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: 'Poppins',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '@${v.username}',
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
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            'Matchups pou ou',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
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
