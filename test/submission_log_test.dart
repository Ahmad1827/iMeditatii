import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/submission_log.dart';

Map<String, dynamic> entry(String at, {bool submit = true, int score = 100}) =>
    {'at': at, 'submit': submit, 'ok': score == 100, 'verdict': '', 'score': score, 'passed': 5, 'total': 5};

void main() {
  test('a submission is still there, with its date, on the next visit', () async {
    SharedPreferences.setMockInitialValues({});
    await saveSent('Informatică_9_12', [entry('2026-11-12T14:05:00.000', score: 60)]);
    final back = await loadSent('Informatică_9_12');
    expect(back, hasLength(1));
    expect(back.first['score'], 60);
    expect(sentWhen(back.first['at'], now: DateTime(2026, 11, 20)), '12.11, 14:05');
    expect(await loadSent('Informatică_9_13'), isEmpty);
  });

  test('runs on the examples are not kept, and only the newest submissions are', () {
    final all = [
      entry('2026-11-12T15:00:00.000', submit: false),
      for (var i = 0; i < sentKept + 5; i++) entry(DateTime(2026, 11, 12, 14).subtract(Duration(minutes: i)).toIso8601String()),
    ];
    final kept = decodeSent(encodeSent(all));
    expect(kept, hasLength(sentKept));
    expect(kept.every((s) => s['submit'] == true), isTrue);
    expect(kept.first['at'], DateTime(2026, 11, 12, 14).toIso8601String());
  });

  test('a damaged list reads as empty', () {
    expect(decodeSent(null), isEmpty);
    expect(decodeSent('nu e json'), isEmpty);
    expect(decodeSent('[{"score": 100}, 7]'), isEmpty);
  });

  test('the date reads as today, yesterday, then the day, with the year when it differs', () {
    final now = DateTime(2026, 1, 1, 10);
    expect(sentWhen('2026-01-01T09:07:00.000', now: now), 'azi, 09:07');
    expect(sentWhen('2025-12-31T23:59:00.000', now: now), 'ieri, 23:59');
    expect(sentWhen('2025-11-02T08:00:00.000', now: now), '02.11.2025, 08:00');
    expect(sentWhen(null, now: now), '–');
  });

  test('the saved list never counts as a solved problem', () async {
    SharedPreferences.setMockInitialValues({});
    await saveSent('Informatică_9_12', [entry('2026-11-12T14:05:00.000')]);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => prefs.get(k) == true), isEmpty);
  });
}
