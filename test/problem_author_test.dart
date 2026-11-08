import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/problem_author.dart';

void main() {
  test("the site's own problems are Ahmad's; those from a paper or contest are added by him", () {
    expect(problemCredit({'category': '1. Structuri secvențiale'}, fromSiteFiles: true, grade: '9'), ('Creată de', 'Ahmad'));
    expect(problemCredit({'sursa': 'BAC 2024, sesiunea iunie'}, fromSiteFiles: true, grade: '12'), ('Adăugată de', 'Ahmad'));
    expect(problemCredit({'category': '1. AcadNet 2026'}, fromSiteFiles: true, grade: 'AcadNet'), ('Adăugată de', 'Ahmad'));
    expect(problemCredit({'category': '11. Olimpiadă'}, fromSiteFiles: true, grade: '9'), ('Adăugată de', 'Ahmad'));
    expect(problemCredit({'sursa': 'BAC 2021 · Test de antrenament 1 · Subiectul III.2'}, fromSiteFiles: true, grade: '12'), ('Adăugată de', 'Ahmad'));
    // the site's own practice problems in the style of Subiectul III are his
    expect(
      problemCredit({'sursa': 'Exercițiu de antrenament (nu e dintr-o variantă BAC)', 'category': '1. Subiectul III.1 · Subprograme'},
          fromSiteFiles: true, grade: '12'),
      ('Creată de', 'Ahmad'),
    );
  });

  test('a problem sent in by a visitor names them, or nobody', () {
    expect(problemCredit({'autor': 'Maria'}, fromSiteFiles: false, grade: '9'), ('Trimisă de', 'Maria'));
    expect(problemCredit({}, fromSiteFiles: false, grade: '9'), isNull);
  });
}
