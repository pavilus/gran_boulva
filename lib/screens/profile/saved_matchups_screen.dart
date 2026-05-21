import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../models/models.dart';
import '../../services/supabase_service.dart';
import '../../widgets/common/app_back_button.dart';
import '../../widgets/matchup/matchup_card.dart';

class SavedMatchupsScreen extends StatefulWidget {
  const SavedMatchupsScreen({super.key});

  @override
  State<SavedMatchupsScreen> createState() => _SavedMatchupsScreenState();
}

class _SavedMatchupsScreenState extends State<SavedMatchupsScreen> {
  final _matchupService = MatchupService();
  List<MatchupModel> _matchups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _matchupService.getSavedMatchups();
      if (mounted) {
        setState(() {
          _matchups = data;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('getSavedMatchups error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSave(MatchupModel matchup, bool save) async {
    await _matchupService.toggleSave(matchup.id, save);
    if (!save && mounted) {
      setState(() => _matchups.removeWhere((m) => m.id == matchup.id));
    }
  }

  Future<void> _openMatchup(MatchupModel matchup) async {
    await _matchupService.recordMatchupView(matchup.id);
    if (!mounted) return;
    final voted = matchup.myVoteOptionId;
    final query = voted == null ? '' : '?voted=${Uri.encodeComponent(voted)}';
    context.push('/matchup/${matchup.id}$query');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg0,
        surfaceTintColor: Colors.transparent,
        leading: AppBackButton(onTap: () => Navigator.of(context).pop()),
        title: const Text(
          'Sovgad',
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
                child: CircularProgressIndicator(color: AppColors.purple),
              )
            : _matchups.isEmpty
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
                    children: const [
                      Icon(Icons.bookmark_border_rounded,
                          color: AppColors.textMuted, size: 54),
                      SizedBox(height: 14),
                      Text(
                        'Pa gen anyen sovgad ankò',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Lè ou sovgad yon matchup, l ap parèt isit la pou ou jwenn li rapid.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.45,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: _matchups.length,
                    itemBuilder: (context, i) {
                      final matchup = _matchups[i];
                      return MatchupCard(
                        matchup: matchup,
                        onTap: () => _openMatchup(matchup),
                        onSave: (save) => _toggleSave(matchup, save),
                      );
                    },
                  ),
      ),
    );
  }
}
