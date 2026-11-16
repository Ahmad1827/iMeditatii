"""Checks the answers in the LFA test 1 exercise book (culegere) against their statements.

Every automaton or regular expression the book gives as an answer is written here once
more and compared, on all words up to a length, with the language the statement
describes. Run: python3 check.py (no packages needed). Helpers: checklib.py.
"""
from checklib import *  # noqa: F401,F403

# ---------------------------------------------------------------- cap. 1 · AFD
same('1.1 se termină cu ab', AB, dfa({'q0': {'a': 'q1', 'b': 'q0'}, 'q1': {'a': 'q1', 'b': 'q2'}, 'q2': {'a': 'q1', 'b': 'q0'}}, 'q0', {'q2'}),
     lambda w: w.endswith('ab'))
same('1.2 #a mod 3', AB, dfa({'r0': {'a': 'r1', 'b': 'r0'}, 'r1': {'a': 'r2', 'b': 'r1'}, 'r2': {'a': 'r0', 'b': 'r2'}}, 'r0', {'r0'}),
     lambda w: w.count('a') % 3 == 0)
aa = {'q0': {'a': 'q1', 'b': 'q0'}, 'q1': {'a': 'q2', 'b': 'q0'}, 'q2': {'a': 'q2', 'b': 'q2'}}
same('1.3a conține aa', AB, dfa(aa, 'q0', {'q2'}), lambda w: 'aa' in w)
same('1.3b nu conține aa', AB, dfa(aa, 'q0', {'q0', 'q1'}), lambda w: 'aa' not in w)
same('1.4 primul = ultimul', AB, dfa({
    's': {'a': 'A1', 'b': 'B1'}, 'A1': {'a': 'A1', 'b': 'A2'}, 'A2': {'a': 'A1', 'b': 'A2'},
    'B1': {'a': 'B2', 'b': 'B1'}, 'B2': {'a': 'B2', 'b': 'B1'}}, 's', {'A1', 'B1'}),
    lambda w: len(w) > 0 and w[0] == w[-1])
same('1.5 divizibil cu 5', B01, dfa({i: {c: (2 * i + int(c)) % 5 for c in '01'} for i in range(5)}, 0, {0}),
     lambda w: int(w or '0', 2) % 5 == 0, 11)
same('1.6 #a par, #b mod 3', AB, dfa({(i, j): {'a': ((i + 1) % 2, j), 'b': (i, (j + 1) % 3)} for i in range(2) for j in range(3)}, (0, 0), {(0, 0)}),
     lambda w: w.count('a') % 2 == 0 and w.count('b') % 3 == 0)
same('1.7 se termină cu abb', AB, dfa({'q0': {'a': 'q1', 'b': 'q0'}, 'q1': {'a': 'q1', 'b': 'q2'}, 'q2': {'a': 'q1', 'b': 'q3'}, 'q3': {'a': 'q1', 'b': 'q0'}}, 'q0', {'q3'}),
     lambda w: w.endswith('abb'))
same('1.8 fără bb', AB, dfa({'s': {'a': 's', 'b': 'B'}, 'B': {'a': 's', 'b': 'd'}, 'd': {'a': 'd', 'b': 'd'}}, 's', {'s', 'B'}),
     lambda w: 'bb' not in w)
same('1.9 orice a urmat de b', AB, dfa({'q0': {'a': 'q1', 'b': 'q0'}, 'q1': {'a': 'd', 'b': 'q0'}, 'd': {'a': 'd', 'b': 'd'}}, 'q0', {'q0'}),
     lambda w: all(i + 1 < len(w) and w[i + 1] == 'b' for i, c in enumerate(w) if c == 'a'))
same('1.10 #a par, #b impar', AB, dfa({(i, j): {'a': (1 - i, j), 'b': (i, 1 - j)} for i in range(2) for j in range(2)}, (0, 0), {(0, 1)}),
     lambda w: w.count('a') % 2 == 0 and w.count('b') % 2 == 1)
same('1.11 lungime ≡ 1 mod 3', AB, dfa({i: {c: (i + 1) % 3 for c in 'ab'} for i in range(3)}, 0, {1}),
     lambda w: len(w) % 3 == 1)
t112 = {(i, j): {'a': (min(i + 1, 2), j), 'b': (i, j + 1) if j == 0 else 'd'} for i in range(3) for j in range(2)}
t112['d'] = {'a': 'd', 'b': 'd'}
same('1.12 ≥2 a, ≤1 b', AB, dfa(t112, (0, 0), {(2, 0), (2, 1)}), lambda w: w.count('a') >= 2 and w.count('b') <= 1)
count('1.12 minimal', len(minimize(t112, (0, 0), {(2, 0), (2, 1)})), 7)
t113 = {S: {c: S | {c} for c in '012'} for S in map(frozenset, itertools.chain.from_iterable(itertools.combinations('012', k) for k in range(4)))}
same('1.13 fiecare simbol apare', T012, dfa(t113, frozenset(), {frozenset('012')}), lambda w: set(w) == set('012'), 7)
count('1.13 minimal', len(minimize(t113, frozenset(), {frozenset('012')})), 8)
same('1.14 lungime pară, fără 1', T012, dfa({'P': {'0': 'I', '2': 'I', '1': 'd'}, 'I': {'0': 'P', '2': 'P', '1': 'd'}, 'd': {'0': 'd', '1': 'd', '2': 'd'}}, 'P', {'P'}),
     lambda w: len(w) % 2 == 0 and '1' not in w, 7)
t115 = {'q0': {'a': 'q1', 'b': 'q0', 'c': 'q0'}, 'q1': {'a': 'q1', 'b': 'q2', 'c': 'q0'}, 'q2': {'a': 'q3', 'b': 'q0', 'c': 'q0'}, 'q3': {'a': 'q1', 'b': 'q2', 'c': 'q0'}}
same('1.15 nu se termină cu aba', ABC, dfa(t115, 'q0', {'q0', 'q1', 'q2'}), lambda w: not w.endswith('aba'), 7)
# 1.16: 3 | #0, 2 | #1, se termină cu 0: produsul are 12 stări, minimul 7
t116 = {(i, j, l): {'0': ((i + 1) % 3, j, 1), '1': (i, (j + 1) % 2, 0)} for i in range(3) for j in range(2) for l in range(2)}
want116 = lambda w: w.count('0') % 3 == 0 and w.count('1') % 2 == 0 and w.endswith('0')
same('1.16 produs', B01, dfa(t116, (0, 0, 0), {(0, 0, 1)}), want116, 11)
count('1.16 minimal', len(minimize(t116, (0, 0, 0), {(0, 0, 1)})), 7)
t116m = {(i, j): {'0': ((i + 1) % 3, j) if (i, j) != (2, 0) else 'F', '1': (i, (j + 1) % 2) if (i, j) != (0, 1) else 'S'} for i in range(3) for j in range(2) if (i, j) != (0, 0)}
t116m['S'] = {'0': (1, 0), '1': (0, 1)}
t116m['F'] = {'0': (1, 0), '1': (0, 1)}
same('1.16 minim', B01, dfa(t116m, 'S', {'F'}), want116, 11)
t117 = {'N': {'1': 'N', '0': 'Z0'}, 'Z0': {'1': 'Z1', '0': 'd'}, 'Z1': {'1': 'Z0', '0': 'Z0'}, 'd': {'0': 'd', '1': 'd'}}


def odd_between(w):
    z = [i for i, c in enumerate(w) if c == '0']
    return all((z[k + 1] - z[k] - 1) % 2 == 1 for k in range(len(z) - 1))


same('1.17 1-uri impare între zerouri', B01, dfa(t117, 'N', {'N', 'Z0', 'Z1'}), odd_between, 11)
# 1.18: automatul de la examen q_ij, m = 2, n = 3: același ca 1.6
# 1.19: citire: automatul dat → limbaj
t119 = {'A': {'a': 'B', 'b': 'A'}, 'B': {'a': 'B', 'b': 'C'}, 'C': {'a': 'B', 'b': 'D'}, 'D': {'a': 'D', 'b': 'D'}}
same('1.19 citire', AB, dfa(t119, 'A', {'A', 'B', 'C'}), lambda w: 'abb' not in w)

# ---------------------------------------------------------------- cap. 2 · AFN și ER
same('2.1 al treilea de la final e a', AB, nfa([(0, 'a', 0), (0, 'b', 0), (0, 'a', 1), (1, 'a', 2), (1, 'b', 2), (2, 'a', 3), (2, 'b', 3)], 0, {3}),
     lambda w: len(w) >= 3 and w[-3] == 'a')
same('2.2 conține aba (AFN)', AB, nfa([(0, 'a', 0), (0, 'b', 0), (0, 'a', 1), (1, 'b', 2), (2, 'a', 3), (3, 'a', 3), (3, 'b', 3)], 0, {3}),
     lambda w: 'aba' in w)
same('2.3 aa sau bb', AB, nfa([('s', 'a', 's'), ('s', 'b', 's'), ('s', 'a', 'A'), ('A', 'a', 'f'), ('s', 'b', 'B'), ('B', 'b', 'f'), ('f', 'a', 'f'), ('f', 'b', 'f')], 's', {'f'}),
     lambda w: 'aa' in w or 'bb' in w)
same('2.4 se termină cu ab sau ba', AB, nfa([('s', 'a', 's'), ('s', 'b', 's'), ('s', 'a', 'p'), ('p', 'b', 'f'), ('s', 'b', 'r'), ('r', 'a', 'f')], 's', {'f'}),
     lambda w: w.endswith('ab') or w.endswith('ba'))
same('2.5 a*b*c*', ABC, nfa([(0, 'a', 0), (0, '', 1), (1, 'b', 1), (1, '', 2), (2, 'c', 2)], 0, {2}), regex('a*b*c*'), 7)
same('2.5 a*b*c* direct', ABC, lambda w: re.fullmatch('a*b*c*', w), regex('a*b*c*'), 7)
same('2.6 lungime multiplu de 2 sau 3', 'a', nfa([('s', '', 'p0'), ('p0', 'a', 'p1'), ('p1', 'a', 'p0'), ('s', '', 'r0'), ('r0', 'a', 'r1'), ('r1', 'a', 'r2'), ('r2', 'a', 'r0')], 's', {'p0', 'r0'}),
     lambda w: len(w) % 2 == 0 or len(w) % 3 == 0, 20)
same('2.7 etichete pe șiruri', AB, nfa([('p', 'ab', 'p'), ('p', '', 'r'), ('r', 'ba', 'r')], 'p', {'r'}), regex('(ab)*(ba)*'))
# ER
same('2.8 exact doi b', AB, regex('a*ba*ba*'), lambda w: w.count('b') == 2)
same('2.9 lungime multiplu de 3', AB, regex('((a∪b)(a∪b)(a∪b))*'), lambda w: len(w) % 3 == 0)
same('2.10 fără litere egale alăturate', AB, regex('(e∪b)(ab)*(e∪a)'), lambda w: 'aa' not in w and 'bb' not in w)
same('2.11 cel puțin un a și un b', AB, regex('a+b(a∪b)*∪b+a(a∪b)*'), lambda w: 'a' in w and 'b' in w)
same('2.11 varianta lungă', AB, regex('(a∪b)*a(a∪b)*b(a∪b)*∪(a∪b)*b(a∪b)*a(a∪b)*'), lambda w: 'a' in w and 'b' in w)
same('2.12 numere pare în binar', B01, regex('0∪1(0∪1)*0'), lambda w: w != '' and (w == '0' or w[0] == '1') and w[-1] == '0', 11)
same('2.13 #a mod 4 = 3', AB, regex('b*ab*ab*ab*(ab*ab*ab*ab*)*'), lambda w: w.count('a') % 4 == 3, 11)
same('2.13 alt răspuns', AB, regex('(b*ab*ab*ab*ab*)*b*ab*ab*ab*'), lambda w: w.count('a') % 4 == 3, 11)
same('2.14a lungime pară', AB, regex('((a∪b)(a∪b))*'), lambda w: len(w) % 2 == 0)
same('2.14b cel mult un a', AB, regex('b*(e∪a)b*'), lambda w: w.count('a') <= 1)
same('2.14c fără aa', AB, regex('(b∪ab)*(e∪a)'), lambda w: 'aa' not in w)
same('2.14d #a multiplu de 3', AB, regex('b*(ab*ab*ab*)*'), lambda w: w.count('a') % 3 == 0)
same('2.14e fără ab', AB, regex('b*a*'), lambda w: 'ab' not in w)
same('2.15 #ab = 0 sau lungime pară', AB, regex('b*a*∪((a∪b)(a∪b))*'), lambda w: 'ab' not in w or len(w) % 2 == 0)
same('2.16 orice a urmat de b, se termină cu c', ABC, regex('(b∪c∪ab)*c'),
     lambda w: w.endswith('c') and all(i + 1 < len(w) and w[i + 1] == 'b' for i, c in enumerate(w) if c == 'a'), 7)
same('2.17 1-uri impare între zerouri', B01, regex('1*∪1*0(1(11)*0)*1*'), odd_between, 11)
same('2.17 forma 2', B01, regex('1*(0(1(11)*0)*1*∪e)'), odd_between, 11)


def xy(w):
    return any('01' not in w[:i] and '110' not in w[i:] for i in range(len(w) + 1))


same('2.18 xy', B01, regex('1*0*(0∪10)*1*'), xy, 11)
same('2.18 forma examenului', B01, regex('1*0*0*(100*)*1*'), xy, 11)
same('2.18 y fără 110', B01, regex('(0∪10)*1*'), lambda w: '110' not in w, 11)
forb = ['01', '02', '11', '10', '21', '20']
same('2.19 perechi interzise', T012, regex('0*∪(e∪1)2*'), lambda w: all(f not in w for f in forb), 7)
# 2.20 #00 ≤ 1: grila cu trei variante (prima și a treia)
le1 = lambda w: cnt(w, '00') <= 1
same('2.20 v1', B01, regex('(e∪1∪01)*(e∪00∪0)(e∪1∪10)*'), le1, 11)
same('2.20 v3', B01, regex('((e∪0)11*)*(e∪0∪00)(11*(e∪0))*'), le1, 11)
v2 = regex('(e∪0)(e∪1∪10)*(e∪1∪10)*(e∪0)')
count('2.20 v2 greșită', all(v2(w) == le1(w) for w in words(B01, 9)), False)
count('2.20 v2 contraexemplu', (v2('001'), le1('001')), (False, True))
o2 = regex('(0∪e)(e∪1∪10)*(e∪00)(e∪1∪10)*')
count('2.20 grila 342 v2 contraexemplu', (o2('000'), le1('000')), (True, False))
same('2.20 grila 342 v3', B01, regex('(e∪0)(e∪1∪10)*(e∪1∪01)*(e∪0)'), le1, 11)
# gramatici → ER
same('2.21 S → aS | Sb | ab', AB, regex('a+b+'), regex('a*abb*'))
same('2.22 S → SS | Sa | b', AB, regex('b(a∪b)*'), lambda w: w.startswith('b'))


def gen(rules, start, alpha, n):
    """All terminal words of length ≤ n generated by a grammar whose bodies are strings
    (uppercase = variables). Used to read off the language of a small grammar."""
    out, seen, todo = set(), set(), [start]
    while todo:
        f = todo.pop()
        if f in seen:
            continue
        seen.add(f)
        if sum(c.islower() or c.isdigit() for c in f) > n or len(f) > 2 * n + 4:
            continue
        i = next((k for k, c in enumerate(f) if c.isupper()), None)
        if i is None:
            out.add(f)
            continue
        for body in rules[f[i]]:
            todo.append(f[:i] + body + f[i + 1:])
    return out


g = {'S': ['X', 'Y', 'Z', 'W'], 'X': ['01Y', '0', ''], 'Y': ['00X', '0', ''], 'Z': ['10W', '1', ''], 'W': ['11Z', '1', '']}
L223 = gen(g, 'S', B01, 10)
same('2.23 gramatica de la examen', B01, regex('(0100)*(e∪0∪01∪010)∪(0001)*(e∪0∪00∪000)∪(1011)*(e∪1∪10∪101)∪(1110)*(e∪1∪11∪111)'), lambda w: w in L223, 10)
count('2.21 gram', gen({'S': ['aS', 'Sb', 'ab']}, 'S', AB, 7) == {w for w in words(AB, 7) if regex('a+b+')(w)}, True)
count('2.22 gram', gen({'S': ['SS', 'Sa', 'b']}, 'S', AB, 6) == {w for w in words(AB, 6) if w.startswith('b')}, True)
# ER → limbaj
same('2.24a (ab*a ∪ b*)*', AB, regex('(ab*a∪b*)*'), lambda w: w.count('a') % 2 == 0)
same('2.24b a(a*a ∪ b*)*', AB, regex('a(a*a∪b*)*'), regex('a(a∪b)*'))
same('2.24c (0*∪1∪1*)*', B01, regex('(0*∪1∪1*)*'), regex('(0∪1)*'))
same('2.24d (a*b*)*', AB, regex('(a*b*)*'), regex('(a∪b)*'))
same('2.24e a(aa* ∪ b*)*', AB, regex('a(aa*∪b*)*'), regex('a(a∪b)*'))
same('2.24f 0e* ∪ 1∅*', B01, regex('0e*∪1∅*'), regex('0∪1'))
same('2.25 b var', AB, regex('(a∪∅)*(b∅*∪a∅)*'), regex('a*b*'))
same('2.25 a var', AB, regex('(a∪b)*∅*b*'), regex('(a∪b)*'))
same('2.26 L(a(a∪b)*) ∪ L(b(a∪b)*)', AB, regex('a(a∪b)*∪b(a∪b)*'), regex('(a∪b)(a∪b)*'))

# ---------------------------------------------------------------- cap. 3 · conversii
# 3.1 (ab ∪ ba)*: construcția din curs, apoi submulțimi, apoi minimizare
th = [("s'", '', 'p0'), ('p0', '', 'p1'), ('p1', 'a', 'p2'), ('p2', '', 'p3'), ('p3', 'b', 'p4'), ('p0', '', 'p5'), ('p5', 'b', 'p6'),
      ('p6', '', 'p7'), ('p7', 'a', 'p8'), ('p4', '', 'p0'), ('p8', '', 'p0')]
same('3.1 Thompson', AB, nfa(th, "s'", {"s'", 'p4', 'p8'}), regex('(ab∪ba)*'))
s0, tab = subsets(th, "s'", AB)
count('3.1 submulțimi', len(tab), 6)
count('3.1 A', sorted(s0), sorted({"s'", 'p0', 'p1', 'p5'}))
fin31 = {S for S in tab if S & {"s'", 'p4', 'p8'}}
count('3.1 minim', len(minimize(tab, s0, fin31)), 4)
same('3.1 AFD', AB, dfa({'S': {'a': 'B', 'b': 'C'}, 'B': {'a': 'd', 'b': 'S'}, 'C': {'a': 'S', 'b': 'd'}, 'd': {'a': 'd', 'b': 'd'}}, 'S', {'S'}), regex('(ab∪ba)*'))
same('3.2 a*(ab∪ba∪e) ∪ b*', AB, nfa([('s', '', 'A'), ('A', 'a', 'A'), ('A', 'a', 'x'), ('x', 'b', 'f'), ('A', 'b', 'y'), ('y', 'a', 'f'), ('A', '', 'f'), ('s', '', 'B'), ('B', 'b', 'B')], 's', {'f', 'B'}),
     regex('a*(ab∪ba∪e)∪b*'))
same('3.3 ((ab)* ∪ (bc)*)ab', ABC, nfa([('s', '', 'P'), ('P', 'a', 'p1'), ('p1', 'b', 'P'), ('s', '', 'R'), ('R', 'b', 'r1'), ('r1', 'c', 'R'), ('P', '', 'T'), ('R', '', 'T'), ('T', 'a', 't1'), ('t1', 'b', 'f')], 's', {'f'}),
     regex('((ab)*∪(bc)*)ab'), 8)
same('3.4 ((a∪b)*(e∪c)*)*', ABC, regex('((a∪b)*(e∪c)*)*'), regex('(a∪b∪c)*'), 7)
same('3.5 N → AFD', AB, dfa({'0': {'a': '0', 'b': '01'}, '01': {'a': '01', 'b': '01'}}, '0', {'01'}),
     nfa([(0, 'a', 0), (0, 'b', 0), (0, 'b', 1), (1, 'a', 1), (1, 'a', 0)], 0, {1}))
same('3.5 ER', AB, regex('a*b(a∪b)*'), nfa([(0, 'a', 0), (0, 'b', 0), (0, 'b', 1), (1, 'a', 1), (1, 'a', 0)], 0, {1}))
same('3.5 eliminare', AB, regex('(a∪b)*b(a∪a(a∪b)*b)*'), regex('a*b(a∪b)*'))
same('3.6 #425', AB, dfa({'0': {'a': '01', 'b': '0'}, '01': {'a': '01', 'b': '02'}, '02': {'a': '01', 'b': '0'}}, '0', {'02'}),
     nfa([(0, 'a', 0), (0, 'b', 0), (0, 'a', 1), (1, 'b', 2)], 0, {2}))
same('3.7 #426', AB, dfa({'01': {'a': '01', 'b': '1'}, '1': {'a': 'z', 'b': '1'}, 'z': {'a': 'z', 'b': 'z'}}, '01', {'01', '1'}), regex('a*b*'))
s0, tab = subsets([(0, 'a', 0), (0, 'b', 0), (0, 'a', 1), (1, 'a', 2), (1, 'b', 2), (2, 'a', 3), (2, 'b', 3)], 0, AB)
count('3.8 al treilea de la final: stări', len(tab), 8)
count('3.8 minim', len(minimize(tab, s0, {S for S in tab if 3 in S})), 8)
dstr = [('p', 'a', 'x'), ('x', 'b', 'q'), ('q', '', 'p'), ('q', 'a', 'q')]
same('3.9 etichete pe șiruri', AB, nfa([('p', 'ab', 'q'), ('q', '', 'p'), ('q', 'a', 'q')], 'p', {'q'}), nfa(dstr, 'p', {'q'}))
same('3.9 AFD', AB, dfa({'P': {'a': 'X', 'b': 'z'}, 'X': {'a': 'z', 'b': 'Q'}, 'Q': {'a': 'R', 'b': 'z'}, 'R': {'a': 'R', 'b': 'Q'}, 'z': {'a': 'z', 'b': 'z'}}, 'P', {'Q', 'R'}),
     nfa(dstr, 'p', {'q'}))
same('3.9 limbaj', AB, regex('ab(a∪ab)*'), nfa(dstr, 'p', {'q'}))
same('3.10 eliminare #427', AB, regex('(b∪a(a∪ba)*bb)*a(a∪ba)*b'), lambda w: w.endswith('ab'))
same('3.11 eliminare abb', AB, regex('(b∪a(a∪ba∪bba)*bbb)*a(a∪ba∪bba)*bb'), lambda w: w.endswith('abb'), 11)
t428 = {0: {'a': 1, 'b': 2}, 1: {'a': 3, 'b': 4}, 2: {'a': 5, 'b': 0}, 3: {'a': 1, 'b': 2}, 4: {'a': 3, 'b': 0}, 5: {'a': 5, 'b': 4}}
count('3.12 #428', minimize(t428, 0, {1, 3, 5}), [[0, 2, 4], [1, 3, 5]])
same('3.12 limbaj', AB, dfa(t428, 0, {1, 3, 5}), lambda w: w.endswith('a'))
U = {'A': {'0': 'B', '1': 'F'}, 'B': {'0': 'G', '1': 'C'}, 'C': {'0': 'A', '1': 'C'}, 'D': {'0': 'C', '1': 'G'}, 'E': {'0': 'H', '1': 'F'},
     'F': {'0': 'C', '1': 'G'}, 'G': {'0': 'G', '1': 'E'}, 'H': {'0': 'G', '1': 'C'}}
count('3.13 tabel', minimize(U, 'A', {'C'}), [['A', 'E'], ['B', 'H'], ['C'], ['F'], ['G']])
Um = {'AE': {'0': 'BH', '1': 'F'}, 'BH': {'0': 'G', '1': 'C'}, 'C': {'0': 'AE', '1': 'C'}, 'F': {'0': 'C', '1': 'G'}, 'G': {'0': 'G', '1': 'AE'}}
same('3.13 minim', B01, dfa(Um, 'AE', {'C'}), dfa(U, 'A', {'C'}), 11)

# ---------------------------------------------------------------- cap. 4 · închidere
par = {'P': {'a': 'I', 'b': 'P'}, 'I': {'a': 'P', 'b': 'I'}}
nobb = {'s': {'a': 's', 'b': 'B'}, 'B': {'a': 's', 'b': 'd'}, 'd': {'a': 'd', 'b': 'd'}}
prod = {(p, q): {c: (par[p][c], nobb[q][c]) for c in AB} for p in par for q in nobb}
want41 = lambda w: w.count('a') % 2 == 0 and 'bb' not in w
same('4.1 produs', AB, dfa(prod, ('P', 's'), {('P', 's'), ('P', 'B')}), want41)
count('4.1 minim', len(minimize(prod, ('P', 's'), {('P', 's'), ('P', 'B')})), 5)
t42 = {'e': {'a': 'a', 'b': 'b'}, 'a': {'a': 'd', 'b': 'b'}, 'b': {'a': 'ba', 'b': 'b'}, 'ba': {'a': 'd', 'b': 'd'}, 'd': {'a': 'd', 'b': 'd'}}
same('4.2 fără aa, bab', AB, dfa(t42, 'e', {'e', 'a', 'b', 'ba'}), lambda w: 'aa' not in w and 'bab' not in w, 11)
count('4.2 minim', len(minimize(t42, 'e', {'e', 'a', 'b', 'ba'})), 5)
L43 = regex('ab*a')
same('4.3 Suf(ab*a)', AB, nfa([('s', '', '0'), ('s', '', '1'), ('s', '', '2'), ('0', 'a', '1'), ('1', 'b', '1'), ('1', 'a', '2')], 's', {'2'}),
     lambda w: any(L43(u + w) for u in words(AB, 6)), 7)
same('4.3 ER', AB, regex('e∪b*a∪ab*a'), lambda w: any(L43(u + w) for u in words(AB, 6)), 7)
m1 = {'q0': {'a': 'q1', 'b': 'q0'}, 'q1': {'a': 'q0', 'b': 'q1'}}
m2 = {'p0': {'a': 'p0', 'b': 'p1'}, 'p1': {'a': 'p0', 'b': 'p1'}}
pr = {(p, q): {c: (m1[p][c], m2[q][c]) for c in AB} for p in m1 for q in m2}
fsd = {(p, q) for p in m1 for q in m2 if (p == 'q0') != (q == 'p1')}
count('4.4 F', sorted(fsd), [('q0', 'p0'), ('q1', 'p1')])
same('4.4 △', AB, dfa(pr, ('q0', 'p0'), fsd), lambda w: (w.count('a') % 2 == 0) != w.endswith('b'))
same('4.5 oglindit ab*', AB, nfa([('1', 'b', '1'), ('1', 'a', '0')], '1', {'0'}), regex('b*a'))
same('4.6 Pref(ab*a)', AB, regex('e∪ab*∪ab*a'), lambda w: any(L43(w + u) for u in words(AB, 6)), 7)
same('4.7 L ∩ (b∪c)*', ABC, lambda w: 'a' not in w, regex('(b∪c)*'), 6)
Lx, Xx = regex('(a∪b)*aab'), regex('b*a')
same('4.8 W = X \\ L', AB, regex('ab∪(a∪b)*aab'), lambda w: any(Xx(x) and Lx(x + w) for x in words(AB, 5)), 8)
same('4.9 h(L) a ↦ e', AB, regex('b*'), lambda w: 'a' not in w)

# ---------------------------------------------------------------- cap. 5 · algoritmice
t5 = {0: {'a': 1, 'b': 2}, 1: {'a': 3, 'b': 3}, 2: {'a': 3, 'b': 4}, 3: {'a': 'd', 'b': 'd'}, 4: {'a': 4, 'b': 4}, 'd': {'a': 'd', 'b': 'd'}}
count('5.x exemplu finit', {w for w in words(AB, 8) if dfa(t5, 0, {3})(w)}, {'aa', 'ab', 'ba'})

# ---------------------------------------------------------------- cap. 6 · pompare
def pump_proof(name, L, w_of, i_of, pmax=12):
    """For each p: w = w_of(p) ∈ L, |w| ≥ p, and for every x y z with |xy| ≤ p, |y| ≥ 1,
    the book's i = i_of(p, x, y, z) gives x yⁱ z ∉ L."""
    for p in range(1, pmax + 1):
        w = w_of(p)
        if not (L(w) and len(w) >= p):
            FAILED.append(f'{name}: w ∉ L or too short for p = {p}')
            return
        for i in range(p + 1):
            for j in range(i + 1, p + 1):
                x, y, z = w[:i], w[i:j], w[j:]
                k = i_of(p, x, y, z)
                if L(x + y * k + z):
                    FAILED.append(f'{name}: p = {p}, x = {x!r}, y = {y!r}: i = {k} stays in L')
                    return


def is_prime(n):
    return n > 1 and all(n % d for d in range(2, int(n ** .5) + 1))


anbn = lambda w: (lambda n: w == 'a' * n + 'b' * n)(len(w) // 2) and len(w) % 2 == 0
pump_proof('6.1 aⁿbⁿ', anbn, lambda p: 'a' * p + 'b' * p, lambda p, x, y, z: 2)
pump_proof('6.2 #a = #b', lambda w: w.count('a') == w.count('b'), lambda p: 'a' * p + 'b' * p, lambda p, x, y, z: 2)
ww = lambda w: len(w) % 2 == 0 and w[:len(w) // 2] == w[len(w) // 2:]
pump_proof('6.3 ww', ww, lambda p: 'a' * p + 'b' + 'a' * p + 'b', lambda p, x, y, z: 2)
pump_proof('6.4 prime', lambda w: set(w) <= {'a'} and is_prime(len(w)), lambda p: 'a' * next(q for q in range(p, 10 * p + 10) if is_prime(q)),
           lambda p, x, y, z: len(x + y + z) + 1, 9)
sq = lambda w: set(w) <= {'a'} and int(len(w) ** .5) ** 2 == len(w)
pump_proof('6.5 n²', sq, lambda p: 'a' * p * p, lambda p, x, y, z: 2, 9)
pw = lambda w: set(w) <= {'a'} and len(w) > 0 and len(w) & (len(w) - 1) == 0
pump_proof('6.6 2ⁿ', pw, lambda p: 'a' * 2 ** p, lambda p, x, y, z: 2, 9)
igj = lambda w: re.fullmatch('a*b*', w) and w.count('a') > w.count('b')
pump_proof('6.7 i > j', igj, lambda p: 'a' * (p + 1) + 'b' * p, lambda p, x, y, z: 0)
pump_proof('6.8 palindroame', lambda w: w == w[::-1], lambda p: 'a' * p + 'b' + 'a' * p, lambda p, x, y, z: 2)
ilej = lambda w: re.fullmatch('a*b*', w) and w.count('a') <= w.count('b')
pump_proof('6.9 i ≤ j', ilej, lambda p: 'a' * p + 'b' * p, lambda p, x, y, z: 2)
abc = lambda w: re.fullmatch('a*b*c*', w) and w.count('c') == w.count('a') + w.count('b')
pump_proof('6.10 aⁿbᵐcⁿ⁺ᵐ', abc, lambda p: 'a' * p + 'b' * p + 'c' * (2 * p), lambda p, x, y, z: 2)
L611 = lambda w: w.count('a') % 2 == 0 and w.count('b') % 2 == 1 and w.count('b') > w.count('a')
pump_proof('6.11 #b > #a', L611, lambda p: 'a' * (2 * p) + 'b' * (2 * p + 1), lambda p, x, y, z: 2)
L612 = lambda w: len(w) > 0 and w.count('1') == 2 * w.count('0')
count('6.12 L = {#1 = 2#0}', all(L612(w) == any(
    (lambda u, v: u.count('1') == 2 * u.count('0') and v.count('1') == 2 * v.count('0'))(w[:k], w[k:]) for k in range(len(w) + 1))
    for w in words(B01, 10) if w), True)
pump_proof('6.12 pompare', L612, lambda p: '0' * p + '1' * (2 * p), lambda p, x, y, z: 0)


def flip(w):
    return cnt(w, '01')


count('6.13 flip din enunț', [flip(w) for w in ('01', '10', '00001', '01011100010')], [1, 0, 1, 3])


L613 = lambda w: len(w) % 2 == 0 and flip(w[:len(w) // 2]) == flip(w[len(w) // 2:])
pump_proof('6.13 flip', L613, lambda p: '0' * p + '1' * p + '0' * p + '1' * p, lambda p, x, y, z: 2 * p + 1, 9)
L614 = lambda w: re.fullmatch('0*10*', w) and w.index('1') <= len(w) - 1 - w.index('1')
count('6.14 int(w) ≥ int(wᴿ) pe 0*10*', all(bool(L614(w)) == (int(w, 2) >= int(w[::-1], 2)) for w in words(B01, 10) if re.fullmatch('0*10*', w)), True)
pump_proof('6.14 pompare', L614, lambda p: '0' * p + '1' + '0' * p, lambda p, x, y, z: 2)
L333 = lambda w: w.count('a') == w.count('b') and 'aaaa' not in w and 'bbbb' not in w
pump_proof('6.16 #333', L333, lambda p: 'aaab' * p + 'a' + 'bbba' * p + 'b', lambda p, x, y, z: 0 if y.count('a') == y.count('b') else 2, 10)
# clasificări
same('6.17 x^n y^n z^n peste {1}', '1', lambda w: any(len(w) == n * m for n in range(0, len(w) + 1) for m in range(len(w) + 1)), regex('1*'), 15)

# ---------------------------------------------------------------- cap. 7 · bonus
same('7.x ab = ba', AB, regex('e∪a∪b∪a(a∪b)*a∪b(a∪b)*b'), lambda w: cnt(w, 'ab') == cnt(w, 'ba'), 12)
L3 = lambda w: w.count('a') % 3 == w.count('b') % 3
count('7.x |a| ≡ |b| mod 3: minim', len(minimize({i: {'a': (i + 1) % 3, 'b': (i - 1) % 3} for i in range(3)}, 0, {0})), 3)
same('7.x |a| ≡ |b| mod 3', AB, dfa({i: {'a': (i + 1) % 3, 'b': (i - 1) % 3} for i in range(3)}, 0, {0}), L3)
# 7.x {e, a} nu are AFD cu o singură stare finală: căutare exhaustivă pe AFD-uri mici peste {a}
for n in range(1, 5):
    for t in itertools.product(range(n), repeat=n):
        for f in range(n):
            acc = lambda w: (lambda q: q == f)(__import__('functools').reduce(lambda q, c: t[q], w, 0))
            if all(acc(w) == (w in ('', 'a')) for w in words('a', 8)):
                FAILED.append(f'7.x: AFD cu o finală pentru {{e, a}} găsit: {t}, {f}')

# ---------------------------------------------------------------- cap. 8 · teste simulate
same('A.P1 L/a', AB, regex('a*b'), lambda w: regex('a*ba')(w + 'a'))
tA2 = {'N': {'a': 'E', 'b': 'N'}, 'E': {'a': 'E', 'b': 'O'}, 'O': {'a': 'E', 'b': 'E'}}
wantA2 = lambda w: 'a' in w and (len(w) - 1 - w.rindex('a')) % 2 == 0
same('A.P2 AFD', AB, dfa(tA2, 'N', {'E'}), wantA2)
same('A.P2 ER', AB, regex('(a∪b)*a(bb)*'), wantA2)
dA3 = [(0, 'a', 0), (0, '', 1), (1, 'b', 2), (2, 'a', 1), (2, '', 0)]
same('A.P3', AB, nfa(dA3, 0, {2}), lambda w: w.endswith('b'))
pump_proof('A.P5', lambda w: w.count('a') == 2 * w.count('b'), lambda p: 'a' * (2 * p) + 'b' * p, lambda p, x, y, z: 0)
same('B.P2a', AB, regex('(b∪aa)*'), lambda w: all(len(r) % 2 == 0 for r in re.findall('a+', w)))
tB2 = {(i, j): {'a': ((i + 1) % 2, j), 'b': (i, (j + 1) % 3)} for i in range(2) for j in range(3)}
same('B.P2b', AB, dfa(tB2, (0, 0), {(i, j) for i in range(2) for j in range(3) if i == 0 or j == 0}), lambda w: w.count('a') % 2 == 0 or w.count('b') % 3 == 0)
tB3 = {(i, c): {'a': ((i + 1) % 3, c), 'b': (i, 1 - c)} for i in range(3) for c in range(2)}
count('B.P3 minim', minimize(tB3, (0, 0), {(0, 0), (0, 1)}), [[(0, 0), (0, 1)], [(1, 0), (1, 1)], [(2, 0), (2, 1)]])
same('B.P3 ER', AB, regex('(b∪ab*ab*a)*'), lambda w: w.count('a') % 3 == 0)
LB5 = lambda w: (lambda m: m is not None and (len(m.group(1)) == len(m.group(2)) or len(m.group(2)) == len(m.group(3))))(re.fullmatch('(a*)(b*)(c*)', w))
pump_proof('B.P5', LB5, lambda p: 'a' * p + 'b' * p + 'c' * (p + 1), lambda p, x, y, z: 2)
same('B.P1 a*b ∩ ba*', AB, lambda w: regex('a*b')(w) and regex('ba*')(w), lambda w: w == 'b')

report()
