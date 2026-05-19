import '../models/models.dart';

bool matchupMatchesQuery(MatchupModel matchup, String query) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) return true;

  final searchableText = [
    matchup.titleHt,
    matchup.titleEn,
    matchup.descriptionHt,
    matchup.category?.nameHt,
    matchup.category?.nameEn,
    ...matchup.options.map((option) => option.optionName),
  ].whereType<String>().join(' ').toLowerCase();

  return searchableText.contains(normalizedQuery);
}
