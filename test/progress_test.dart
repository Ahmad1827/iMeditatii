import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/progress.dart';

void main() {
  test('only solved problems the account lacks are sent', () {
    expect(
      keysToSync(['Informatică_9_1', 'Informatică_9_2'], ['Informatică_9_1']),
      {'Informatică_9_2'},
    );
  });

  test('maths stays out: a person checks it and can take it back', () {
    expect(keysToSync(['Matematică_9_1', 'matematica_10_3'], const []), isEmpty);
  });

  test('other settings saved as true are not problems', () {
    expect(keysToSync(['is_dark_mode', 'deck_open', 'lectie_citita:cpp_9_vectori'], const []), isEmpty);
  });
}
