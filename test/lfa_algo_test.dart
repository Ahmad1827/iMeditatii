// The step-by-step LFA algorithms the theory pages show: each result is
// checked as a language against an independent answer.
import 'package:flutter_test/flutter_test.dart';
import 'package:iMeditatii/acs/engine/lfa.dart';
import 'package:iMeditatii/acs/engine/lfa_algo.dart';
import 'package:iMeditatii/acs/engine/lfa_cfg.dart';
import 'package:iMeditatii/acs/engine/lfa_machines.dart';

Nfa table(int n, List<int> finals, String rows) {
  final m = <int, Map<String, Set<int>>>{};
  for (final l in rows.trim().split('\n')) {
    final p = l.trim().split(RegExp(r'\s+'));
    ((m[int.parse(p[0])] ??= {})[p[1]] ??= {}).addAll(p.skip(2).map(int.parse));
  }
  return Nfa(n, finals.toSet(), m);
}

bool sameLanguage(Nfa a, Nfa b, List<String> sigma) => a.toDfa(sigma).difference(b.toDfa(sigma)) == null;

void main() {
  const ab = ['a', 'b'];
  // contains aa (the guide's exercise)
  final aa = table(3, [2], '0 a 1\n0 b 0\n1 a 2\n1 b 0\n2 a 2\n2 b 2');

  group('expressions', () {
    test('simplified as they are built', () {
      expect(Re.cat([Re.sym('a'), Re.eps, Re.sym('b')]).show(), 'ab');
      expect(Re.cat([Re.sym('a'), Re.empty]).show(), '∅');
      expect(Re.alt([Re.sym('a'), Re.sym('a'), Re.empty]).show(), 'a');
      expect(Re.star(Re.star(Re.sym('a'))).show(), 'a*');
      expect(Re.star(Re.alt([Re.eps, Re.sym('a')])).show(), 'a*');
      expect(Re.cat([Re.alt([Re.sym('a'), Re.sym('b')]), Re.sym('c')]).show(), '(a ∪ b)c');
      expect(Re.star(Re.cat([Re.sym('a'), Re.sym('b')])).show(), '(ab)*');
      expect(Re.cat([Re.sym('a'), Re.star(Re.alt([Re.sym('a'), Re.sym('b')]))]).show(sigma: ab), 'aΣ*');
    });

    test('parse then show gives the same language', () {
      for (final r in ['(a∪b)*abb', 'a*b*', '(ab∪b)*a?', 'a+b', '∅∪ε', '(a(b∪ε))*']) {
        final back = Re.parse(r, ab).show();
        expect(sameLanguage(Regex.parse(r, ab), Regex.parse(back, ab), ab), isTrue, reason: '$r -> $back');
      }
    });
  });

  group('state elimination', () {
    test('order q2, q1, q0 on "contains aa"', () {
      var g = Gnfa.of(aa, ab);
      for (final q in [2, 1, 0]) {
        g = g.eliminate(q);
      }
      final r = g.result.show();
      expect(sameLanguage(Regex.parse(r, ab), aa, ab), isTrue, reason: r);
      expect(g.result.show(sigma: ab), '(b ∪ ab)*aaΣ*');
    });

    test('any order, the cheapest first, and the guide\'s parity automaton', () {
      for (final order in [
        [0, 1, 2],
        [1, 0, 2],
      ]) {
        var g = Gnfa.of(aa, ab);
        for (final q in order) {
          g = g.eliminate(q);
        }
        expect(sameLanguage(Regex.parse(g.result.show(), ab), aa, ab), isTrue);
      }
      // a^m + a^n = a^p with m + n ≡ p (mod 2); the symbols + and = written p and e
      const s = ['a', 'p', 'e'];
      final parity = table(6, [2], '0 a 3\n3 a 0\n0 p 1\n3 p 4\n1 a 4\n4 a 1\n1 e 2\n4 e 5\n2 a 5\n5 a 2');
      var g = Gnfa.of(parity, s);
      while (g.inner.isNotEmpty) {
        g = g.eliminate(g.cheapest);
      }
      final r = g.result.show();
      expect(sameLanguage(Regex.parse(r, s), parity, s), isTrue, reason: r);
      final guide = [3, 5, 4, 1, 2, 0].fold(Gnfa.of(parity, s), (g, q) => g.eliminate(q));
      expect(sameLanguage(Regex.parse(guide.result.show(), s), parity, s), isTrue);
    });
  });

  test('subset construction: the exam automaton has two states', () {
    final n = table(2, [1], '0 a 0\n0 b 0 1\n1 a 1 0');
    final rows = subsetRows(n, ab);
    expect(rows.map((r) => setName(r.set)).toList(), ['{0}', '{0,1}']);
    expect(rows[1].accepting, isTrue);
  });

  test('minimisation merges what cannot be told apart', () {
    // ends in a, with a needless copy of each state
    final d = table(4, [1, 3], '0 a 1\n0 b 2\n1 a 3\n1 b 0\n2 a 1\n2 b 0\n3 a 1\n3 b 2').toDfa(ab);
    final m = minimise(d);
    expect(m.classes.length, 2);
    final (min, _) = minimalOf(d, m);
    expect(sameLanguage(min, Regex.parse('(a∪b)*a', ab), ab), isTrue);
    expect(m.classes.length, d.minimalStates);
  });

  test('product: intersection, union, difference, symmetric difference', () {
    final evenA = table(2, [0], '0 a 1\n0 b 0\n1 a 0\n1 b 1').toDfa(ab);
    final endsB = table(2, [1], '0 a 0\n0 b 1\n1 a 0\n1 b 1').toDfa(ab);
    for (final (op, pred) in [
      (ProductOp.inter, (String w) => w.split('a').length.isOdd && w.endsWith('b')),
      (ProductOp.union, (String w) => w.split('a').length.isOdd || w.endsWith('b')),
      (ProductOp.minus, (String w) => w.split('a').length.isOdd && !w.endsWith('b')),
      (ProductOp.xor, (String w) => w.split('a').length.isOdd != w.endsWith('b')),
    ]) {
      final (p, _) = product(evenA, endsB, op);
      for (final w in allWords(ab, 7)) {
        expect(p.accepts(w), pred(w), reason: '$op $w');
      }
    }
  });

  test('Thompson: the automaton built has the expression\'s language', () {
    for (final r in ['(a∪b)*abb', 'a*b*', '(ab)*', 'ε', '∅', 'a(b∪ε)a*']) {
      final t = thompson(Re.parse(r, ab));
      expect(sameLanguage(t.nfa, Regex.parse(r, ab), ab), isTrue, reason: r);
      expect(t.pos.length, t.nfa.states);
    }
  });

  group('grammars', () {
    test('a derivation tree yields the word; an ambiguous grammar has two', () {
      final g = Cfg.parse('S -> aS | Sb | ab');
      final trees = parseTrees(g, 'aabb');
      expect(trees.length, 2);
      for (final t in trees) {
        expect(t.yield, 'aabb');
        expect(t.leftmost().last, 'aabb');
      }
      expect(parseTrees(g, 'ba'), isEmpty);
      final e = Cfg.parse('S -> AS | ε\nA -> A1 | 0A1 | 01');
      expect(parseTrees(e, '0011').first.yield, '0011');
      expect(parseTrees(e, '').single.yield, '');
    });

    test('Chomsky normal form keeps the language and has the form', () {
      for (final text in ['S -> aSb | ε', 'S -> ASA | aB\nA -> B | S\nB -> b | ε', 'S -> SS | (S) | ε', 'S -> aAA\nA -> aS | bS | a']) {
        final g = Cfg.parse(text);
        final steps = toChomsky(g);
        final last = steps.last.grammar;
        expect(last.isChomsky, isTrue, reason: '$text\n${last.show()}');
        expect(last.words(7), g.words(7), reason: text);
        for (final w in allWords(g.terminals.toList()..sort(), 6)) {
          expect(cyk(last, w).accepted, g.words(6).contains(w), reason: '$text: $w');
        }
      }
    });
  });

  group('machines', () {
    test('a pushdown automaton for aⁿbⁿ', () {
      final p = Pda.parse('start s\nfinal f\ns, a, ε -> s, A\ns, ε, ε -> f, ε\nf, b, A -> f, ε');
      for (final w in allWords(ab, 8)) {
        expect(p.accepts(w), w.length.isEven && w == 'a' * (w.length ~/ 2) + 'b' * (w.length ~/ 2), reason: w);
      }
      final r = p.run('aabb');
      expect(r.accepted, isTrue);
      expect(r.path.last.stack, '');
    });

    test('a Turing machine for aⁿbⁿ (n ≥ 1) and one that adds 1 in base 2', () {
      final m = Tm.parse('''
q0, a -> q1, A, R
q0, B -> q3, B, R
q1, a -> q1, a, R
q1, B -> q1, B, R
q1, b -> q2, B, L
q2, a -> q2, a, L
q2, B -> q2, B, L
q2, A -> q0, A, R
q3, B -> q3, B, R
q3, # -> h, #, S
''');
      bool anbn(String w) {
        final n = w.length ~/ 2;
        return n >= 1 && w == 'a' * n + 'b' * n;
      }

      for (final w in allWords(ab, 8)) {
        expect(m.accepts(w), anbn(w), reason: w);
      }
      final inc = Tm.parse('q0, 0 -> q0, 0, R\nq0, 1 -> q0, 1, R\nq0, # -> q1, #, L\nq1, 1 -> q1, 0, L\nq1, 0 -> h, 1, S\nq1, # -> h, 1, S');
      expect(inc.compute('1011'), '1100');
      expect(inc.compute('111'), '1000');
    });
  });
}
