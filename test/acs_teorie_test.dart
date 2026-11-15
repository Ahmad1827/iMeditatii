// The LFA theory pages: every lesson's file reads, every visualisation's
// automaton, grammar or machine parses and behaves as its text says, and
// every lesson draws, in both looks, on a phone and on a wide screen, with
// each visualisation walked to its last step, nothing overflowing or
// throwing.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:iMeditatii/acs/acs_data.dart';
import 'package:iMeditatii/acs/acs_kit.dart';
import 'package:iMeditatii/acs/engine/lfa.dart';
import 'package:iMeditatii/acs/engine/lfa_cfg.dart';
import 'package:iMeditatii/acs/engine/lfa_machines.dart';
import 'package:iMeditatii/acs/teorie/teorie_data.dart';
import 'package:iMeditatii/acs/teorie/teorie_screen.dart';
import 'package:iMeditatii/theme_manager.dart';

TeorieCourse teorie() => TeorieCourse.parse('lfa', File('assets/data/acs/teorie/lfa.json').readAsStringSync());
AcsCourseData problems() => AcsCourseData.parse('lfa', File('assets/data/acs/lfa.json').readAsStringSync());

bool ink(AcsStyle s) => s == AcsStyle.notebook; // the takeaway's label is in capitals in the notebook

Iterable<Map<String, dynamic>> vizBlocks(TeorieCourse t) sync* {
  for (final l in t.lessons) {
    for (final s in l.sections) {
      for (final b in s.blocks) {
        if (b['t'] == 'viz') yield b;
      }
    }
  }
}

/// Pumps until [f] finds something (the page loads its files first).
Future<void> settle(WidgetTester t, Finder f) async {
  for (var i = 0; i < 40 && f.evaluate().isEmpty; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    ByteData bytes(String path) => ByteData.view(File(path).readAsBytesSync().buffer);
    await (FontLoader('Iosevka')
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Regular.ttf')))
          ..addFont(Future.value(bytes('assets/fonts/Iosevka-Bold.ttf'))))
        .load();
  });

  test('the lessons, their parts and the problems they link', () {
    final t = teorie();
    final p = problems();
    expect(t.lessons.length, greaterThanOrEqualTo(16));
    expect(t.parts.expand((x) => x.lessons).toSet(), t.lessons.map((l) => l.id).toSet());
    for (final l in t.lessons) {
      expect(l.sections, isNotEmpty, reason: l.id);
      for (final id in l.practice) {
        expect(p.byId(id), isNotNull, reason: '${l.id} links $id');
      }
    }
    expect(acsTeorieCourses, contains('lfa'));
  });

  test('every visualisation reads', () {
    for (final b in vizBlocks(teorie())) {
      final why = '${b['title']}';
      switch (b['kind']) {
        case 'automaton':
        case 'subset':
        case 'elim':
        case 'minimize':
          final a = Nfa.fromJson(b['a'] as Map);
          expect(a.states, lessThanOrEqualTo(12), reason: why);
          if (b['pos'] != null) expect((b['pos'] as List).length, a.states, reason: why);
          if (b['kind'] == 'minimize') expect(a.isDeterministic('${b['alphabet']}'.split('')), isTrue, reason: why);
        case 'thompson':
        case 'regexlab':
          Regex.parse('${b['regex']}', '${b['alphabet']}'.split(''));
        case 'derive':
          final g = Cfg.parse('${b['grammar']}');
          // the first word given is one the grammar derives
          final w = '${(b['words'] as List).first}';
          expect(parseTrees(g, w), isNotEmpty, reason: '$why: $w');
        case 'cnf':
          final steps = toChomsky(Cfg.parse('${b['grammar']}'));
          expect(steps.last.grammar.isChomsky, isTrue, reason: why);
        case 'cyk':
          final g = Cfg.parse('${b['grammar']}');
          expect(g.isChomsky, isTrue, reason: why);
        case 'pda':
          final p = Pda.parse('${b['pda']}');
          expect(p.accepts('${(b['words'] as List).first}'), isTrue, reason: why);
        case 'tm':
          Tm.parse('${b['tm']}');
      }
    }
  });

  test('each lesson says what it teaches, each section its takeaway, each chapter its lesson', () {
    final t = teorie();
    final p = problems();
    for (final l in t.lessons) {
      expect(l.goals, isNotEmpty, reason: l.id);
      for (final s in l.sections) {
        expect(s.key, isNotEmpty, reason: '${l.id}/${s.id}');
      }
    }
    for (final ch in p.chapters) {
      expect(t.forChapter(ch), isNotNull, reason: ch);
    }
    expect(t.parts.where((x) => x.test.isNotEmpty).map((x) => x.test), ['Testul 1 (LR)', 'Testul 2 (LIC)', 'Testul 3 (MT)']);
  });

  test('the theory course is listed for its course page', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    expect(File('assets/data/acs/teorie/lfa.json').existsSync(), isTrue);
    expect(json.decode(File('assets/data/acs/teorie/lfa.json').readAsStringSync())['code'], 'lfa');
  });

  final lessons = teorie().lessons;
  for (final style in AcsStyle.values) {
    for (final width in [390.0, 1300.0]) {
      testWidgets('the list of lessons, ${style.name} at ${width.toInt()} px', (t) async {
        SharedPreferences.setMockInitialValues({'acs-teorie:lfa:limbaje': true});
        ThemeManager.acsStyleNotifier.value = style;
        t.view.physicalSize = Size(width, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(const MaterialApp(home: AcsTeorieScreen(code: 'lfa')));
        await settle(t, find.textContaining('lecții citite'));
        expect(find.textContaining('1 din ${lessons.length} lecții citite'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      for (final l in lessons) {
        testWidgets('lesson ${l.id}, ${style.name} at ${width.toInt()} px', (t) async {
          SharedPreferences.setMockInitialValues({});
          ThemeManager.acsStyleNotifier.value = style;
          t.view.physicalSize = Size(width, 2400);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.reset);
          final ink = AcsInk.of(style, false);
          final p = problems();
          // every block of the lesson, in a scrolling column, as the lesson page lays them out
          await t.pumpWidget(MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: width < 600 ? 16 : 32),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    for (final s in l.sections)
                      for (final b in s.blocks) Padding(padding: const EdgeInsets.only(top: 12), child: TeorieBlock(ink, b, code: 'lfa', problems: p)),
                  ]),
                ),
              ),
            ),
          ));
          await t.pump();
          expect(t.takeException(), isNull);
          // walk every step bar to its end
          for (var round = 0; round < 3; round++) {
            final last = find.text('⇥');
            final n = last.evaluate().length;
            for (var i = 0; i < n; i++) {
              final f = find.text('⇥').at(i);
              await t.ensureVisible(f);
              await t.tap(f, warnIfMissed: false);
              await t.pump();
            }
          }
          expect(t.takeException(), isNull);
          // open every hidden proof and solution
          final reveals = find.textContaining(RegExp(r'^(▸|\[\+\]) '));
          for (var i = reveals.evaluate().length - 1; i >= 0; i--) {
            final f = find.textContaining(RegExp(r'^(▸|\[\+\]) ')).at(i);
            await t.ensureVisible(f);
            await t.tap(f, warnIfMissed: false);
          }
          await t.pump();
          expect(t.takeException(), isNull);
        });
      }

      testWidgets('esențial hides the explanations until asked, complet shows them, ${style.name} at ${width.toInt()} px', (t) async {
        SharedPreferences.setMockInitialValues({});
        ThemeManager.acsStyleNotifier.value = style;
        t.view.physicalSize = Size(width, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(const MaterialApp(home: AcsLessonScreen(code: 'lfa', lesson: 'afn')));
        await settle(t, find.textContaining('Construcția submulțimilor'));
        // the first section's paragraph (a "p" block) is behind "arată tot"
        final prose = teorie().byId('afn')!.sections.first.blocks.firstWhere((b) => b['t'] == 'p')['text'] as String;
        final probe = prose.substring(0, 11); // "Față de AFD"
        expect(find.textContaining(probe), findsNothing);
        expect(find.textContaining(ink(style) ? 'PE SCURT' : 'pe scurt'), findsWidgets);
        final more = find.textContaining(RegExp(r'^arată tot')).first;
        // in the middle of the screen: on a phone the top bar covers the top
        // to the middle of the screen: on a phone the bar covers the top
        Scrollable.ensureVisible(t.element(more), alignment: 0.5);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 200));
        }
        await t.tap(more);
        await t.pump(const Duration(milliseconds: 400));
        expect(find.textContaining(probe), findsOneWidget);
        // complet: everything, and no "arată tot" left
        final complet = find.text('complet').first;
        Scrollable.ensureVisible(t.element(complet), alignment: 0.5);
        for (var i = 0; i < 6; i++) {
          await t.pump(const Duration(milliseconds: 200));
        }
        await t.tap(complet);
        await t.pump(const Duration(milliseconds: 400));
        expect(find.textContaining(RegExp(r'^arată tot')), findsNothing);
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
      });

      testWidgets('a lesson page with its contents and links, ${style.name} at ${width.toInt()} px', (t) async {
        SharedPreferences.setMockInitialValues({});
        ThemeManager.acsStyleNotifier.value = style;
        t.view.physicalSize = Size(width, 2600);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.reset);
        await t.pumpWidget(const MaterialApp(home: AcsLessonScreen(code: 'lfa', lesson: 'af-er')));
        await settle(t, find.textContaining('Echivalența automate'));
        expect(find.textContaining('Echivalența automate'), findsWidgets);
        expect(find.textContaining('xersează'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  }
}
