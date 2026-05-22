import '../models/models.dart';
import 'search_utils.dart';

/// Returns true when [matchup] matches every word in [query].
///
/// Searched fields:
///   - title (HT + EN)
///   - description
///   - category name (HT + EN)
///   - option names (the answer text for both options)
bool matchupMatchesQuery(MatchupModel matchup, String query) {
  if (query.trim().isEmpty) return true;

  final haystack = [
    matchup.titleHt,
    matchup.titleEn,
    matchup.descriptionHt,
    matchup.category?.nameHt,
    matchup.category?.nameEn,
    ...matchup.options.map((o) => o.optionName),
  ].whereType<String>().join(' ');

  return matchesQuery(haystack, query);
}
