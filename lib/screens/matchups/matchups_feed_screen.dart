import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../utils/matchup_search.dart';
import '../../widgets/common/category_tabs.dart';
import '../../widgets/matchup/matchup_card.dart';

class MatchupsFeedScreen extends StatefulWidget {
  const MatchupsFeedScreen({super.key});

  @override
  State<MatchupsFeedScreen> createState() => _MatchupsFeedScreenState();
}

class _MatchupsFeedScreenState extends State<MatchupsFeedScreen> {
  final _matchupService = MatchupService();

  List<MatchupModel> _allMatchups = [];
  List<MatchupModel> _matchups = [];
  List<CategoryModel> _categories = [];
  String _searchQuery = '';
  String _activeCategoryLabel = 'Popilè';
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadCategories();
    _loadMatchups();
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

  Future<void> _loadCategories() async {
    try {
      final cats = await _matchupService.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (_) {}
  }

  Future<void> _loadMatchups() async {
    setState(() => _loading = true);
    try {
      final data = await _matchupService.getMatchupsFeed(
        categoryId: _selectedCategoryId(),
      );
      if (mounted) {
        setState(() {
          _allMatchups = data;
          _matchups = _filterMatchups(_allMatchups, _searchQuery);
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadMatchups error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _selectedCategoryId() {
    if (_activeCategoryLabel == 'Popilè' || _activeCategoryLabel == 'Tout') {
      return null;
    }
    final match = _categories
        .where(
            (c) => c.nameHt.toLowerCase() == _activeCategoryLabel.toLowerCase())
        .firstOrNull;
    return match?.id;
  }

  void _onCategoryLabelTap(String label) {
    setState(() => _activeCategoryLabel = label);
    _loadMatchups();
  }

  Future<void> _toggleSave(MatchupModel m, bool save) =>
      _matchupService.toggleSave(m.id, save);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.purple,
          backgroundColor: AppColors.card,
          onRefresh: _loadMatchups,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildAppBar()),
              SliverToBoxAdapter(child: _buildSearchBar()),
              SliverToBoxAdapter(child: _buildCategoryChips()),
              SliverToBoxAdapter(child: _buildHeaderBand()),
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
                                  onTap: () async {
                                    await MatchupService()
                                        .recordMatchupView(matchup.id);
                                    if (!context.mounted) return;
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Matchups',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  'Debat. Vote. Agimante.',
                  style: TextStyle(
                    color: AppColors.pink,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          const _LogoWidget(),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_outlined,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
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
                  hintText: 'Chèche matchups, kategori, moun...',
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
              const SizedBox.shrink(),
          ],
        ),
      ),
    );
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

  Widget _buildHeaderBand() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tout matchups',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Text(
            '${_matchups.length} disponib',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontFamily: 'Poppins',
            ),
          ),
        ],
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
              'Pa gen matchups pou kounye a',
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
