// =============================================================================
// WHO MADE A PROBLEM
//   The problems in the app's own files are the site's: written by Ahmad, or,
//   when they come from a paper or a contest (BAC, AcadNet, an olympiad), added
//   by him, the problem itself being the paper's. A problem sent in by a visitor
//   is credited only when it says who sent it ('autor').
// =============================================================================

const String siteAuthor = 'Ahmad';

/// ("Creată de", "Ahmad"), ("Adăugată de", "Ahmad"), or null when nobody is known.
(String, String)? problemCredit(Map<String, dynamic> problem, {required bool fromSiteFiles, required String grade}) {
  final sentBy = '${problem['autor'] ?? ''}'.trim();
  if (!fromSiteFiles) return sentBy.isEmpty ? null : ('Trimisă de', sentBy);
  final category = '${problem['category'] ?? ''}'.toLowerCase();
  // a real paper: "BAC 2024 · Sesiunea specială", "AcadNet 2026 · ...", an olympiad;
  // not "Exercițiu de antrenament (nu e dintr-o variantă BAC)", which is the site's own
  final source = '${problem['sursa'] ?? ''}'.trim().toLowerCase();
  final fromPaper = grade == 'AcadNet' ||
      category.contains('olimpiad') ||
      RegExp(r'^(bac|acadnet|oji|oni|olimpiad|simulare|model)\b').hasMatch(source);
  return (fromPaper ? 'Adăugată de' : 'Creată de', siteAuthor);
}
