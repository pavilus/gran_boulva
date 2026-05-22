/// Shared search helpers for matchups and predictions.
///
/// Key features:
/// - Accent-insensitive (è→e, ò→o, é→e, …) — lets users skip Haitian Creole
///   diacritics and still find results.
/// - Word-by-word: ALL words in the query must be present somewhere in the
///   haystack, so "Messi sport" matches a matchup whose title contains "Messi"
///   and whose category is "Sport" regardless of word order.
library;

/// Strips common Haitian Creole / French diacritics and lowercases the text.
String normalizeForSearch(String text) {
  return text
      .toLowerCase()
      .replaceAll('è', 'e')
      .replaceAll('é', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ò', 'o')
      .replaceAll('ó', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('à', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('ù', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('î', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('ç', 'c');
}

/// Returns true when every word in [query] appears somewhere in [haystack].
///
/// Both strings are normalized before comparison.  Empty or blank queries
/// always return true.
bool matchesQuery(String haystack, String query) {
  final trimmed = query.trim();
  if (trimmed.isEmpty) return true;
  final normalizedHaystack = normalizeForSearch(haystack);
  final words = normalizeForSearch(trimmed).split(RegExp(r'\s+'));
  return words.every((w) => w.isEmpty || normalizedHaystack.contains(w));
}
