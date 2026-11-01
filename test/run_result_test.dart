// What a run that went wrong is called, on the problem page and in the IDE.
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/judge0.dart';

void main() {
  test('too long is called too long, by both runners\' wording', () {
    const r = RunResult(status: 'Time Limit Exceeded', seconds: 10);
    expect(r.timedOut, isTrue);
    expect(r.problem, 'Timp depășit');
    expect(r.timeNote, contains('după 10 secunde'));
  });

  test('the note leaves out a time nobody measured', () {
    expect(const RunResult(status: 'Time Limit Exceeded').timeNote, startsWith('Programul a rulat prea mult și a fost oprit.'));
    expect(const RunResult(status: 'Time Limit Exceeded', seconds: 2.5).timeNote, contains('după 2.5 secunde'));
  });

  test('the other ways a run goes wrong', () {
    expect(const RunResult(status: 'Compilation Error').problem, 'Eroare de compilare');
    expect(const RunResult(status: 'Runtime Error (NZEC)').problem, 'Eroare la rulare');
    expect(const RunResult(status: 'Runtime Error (SIGSEGV)').problem, 'Eroare la rulare');
    expect(const RunResult(failed: true, error: 'x').problem, 'Nu s-a putut rula');
  });

  test('a program that ran to the end has no problem, right answer or not', () {
    const r = RunResult(status: 'Accepted');
    expect(r.problem, isNull);
    expect(r.timedOut, isFalse);
    expect(r.timeNote, isEmpty);
  });
}
