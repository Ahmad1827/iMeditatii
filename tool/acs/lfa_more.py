# Run inside tool/acs/lfa.py (exec), with its helpers and P in scope.
# More LFA problems: the seminars' revision sheet (lfa-problems-1.pdf, all ten),
# the exam subjects of 2022-2025 and the tests (Mitra) not yet in the app,
# pushdown automata and Turing machines (checked by running them), and
# true/false questions.  Ids from 100.
from common import true_false

REC = 'Recapitulare LFA: seminarele 1–4'
PS = 'Examen LFA · set de probleme rezolvate'
T1 = 'Test LFA · grilă'
T2 = 'Test LFA · rezolvări (G. Mitra)'
T3 = 'Test LFA · variante de rezolvare (G. Mitra)'
MT1 = 'Test 1 LFA · 1 noiembrie 2023'
MT2 = 'Test 2 LFA · 9 decembrie 2023'
REC17 = 'Test de recuperare LFA · 2017-2018'
E22a, E22b, E22c, E22d = 'Examen LFA · 9 iunie 2022', 'Examen LFA · 15 iunie 2022', 'Examen LFA · 6 septembrie 2022', 'Examen LFA · 8 septembrie 2022'
E25a, E25b = 'Examen LFA (18 ianuarie 2025)', 'Examen LFA (1 februarie 2025)'
E25c = 'Examen LFA · 2025 (seria CD)'


def regex_in(id, title, ch, diff, statement, alphabet, pred, ref, hint='', solution='', source='', n=9):
    check_regex(id, ref, alphabet, pred, n)
    spec = {'mode': 'regex', 'alphabet': alphabet, 'regex': ref, 'reference': ref}
    P.append(problem(id, title, ch, diff, statement, 'lfa', spec, hint, solution or f'O expresie care merge: `{ref}`.', source))


def nfa_in(id, title, ch, diff, statement, alphabet, pred, regex_, ref, hint='', solution='', source='', max_states=None):
    auto(id, title, ch, diff, statement, alphabet, pred, regex_, ref, mode='nfa', max_states=max_states, hint=hint, solution=solution, source=source)


def dfa_in(id, title, ch, diff, statement, alphabet, pred, regex_, hint='', solution='', source='', max_states=None):
    afd(id, title, diff, statement, alphabet, pred, regex_, hint, solution, source=source, max_states=max_states, ch=ch)


def tree_count(text, w, cap=2):
    """How many derivation trees w has (up to cap); the grammars here have no unit cycles."""
    rules, start = {}, None
    for line in text.strip().split('\n'):
        left, right = line.replace(' ', '').split('->')
        start = start or left
        rules.setdefault(left, []).extend(alt.replace('ε', '') for alt in right.split('|'))
    from functools import lru_cache

    @lru_cache(None)
    def count(a, i, j, depth=0):
        if depth > 40:
            return 0
        tot = 0
        for alt in rules[a]:
            tot += cover(alt, 0, i, j, depth)
            if tot >= cap:
                return cap
        return tot

    @lru_cache(None)
    def cover(alt, k, i, j, depth):
        if k == len(alt):
            return 1 if i == j else 0
        s = alt[k]
        if s not in rules:
            return cover(alt, k + 1, i + 1, j, depth) if i < j and w[i] == s else 0
        tot = 0
        for m in range(i, j + 1):
            c = count(s, i, m, depth + 1)
            if c:
                tot += c * cover(alt, k + 1, m, j, depth)
            if tot >= cap:
                return cap
        return min(tot, cap)

    return count(start, 0, len(w))


def cfg_in(id, title, ch, diff, statement, alphabet, pred, ref, up_to, hint='', solution='', source='', unambiguous=False, chomsky=False):
    check_grammar(id, ref, alphabet, pred, up_to)
    spec = {'mode': 'cfg', 'alphabet': alphabet, 'grammar': ref, 'upTo': up_to, 'reference': ref}
    if unambiguous:
        for w in words(alphabet, up_to):
            if pred(w):
                assert tree_count(ref, w) == 1, f'{id}: the reference is ambiguous on {w!r}'
        spec['unambiguous'] = True
    if chomsky:
        spec['chomsky'] = True
    P.append(problem(id, title, ch, diff, statement, 'lfa', spec, hint,
                     solution or 'O gramatică care merge:\n' + '\n'.join(f'`{l.strip()}`' for l in ref.strip().split('\n')), source))


# ---------------------------------------------------------------- machines, as the app runs them
def pda_parse(text):
    states, start, finals, moves = [], None, set(), []
    for raw in text.strip().split('\n'):
        line = raw.split('//')[0].strip()
        if not line:
            continue
        m = re.match(r'^(start|final)\s+(.*)$', line)
        if m:
            names = [x for x in re.split(r'[\s,]+', m[2]) if x]
            if m[1] == 'final':
                finals |= set(names)
            else:
                start = names[0]
            continue
        left, right = line.split('->')
        f, r, po = [x.strip() for x in left.split(',')]
        t, pu = [x.strip() for x in right.split(',')]
        e = lambda x: '' if x in ('', 'ε', 'e') else x
        moves.append((f, e(r), e(po), t, e(pu)))
        for x in (f, t):
            if x not in states:
                states.append(x)
    return states, start or states[0], finals, moves


def pda_accepts(pda, w, cap=None):
    states, start, finals, moves = pda
    cap = cap or 2 * len(w) + 8
    seen, todo = set(), [(start, 0, '')]
    while todo:
        c = todo.pop()
        if c in seen:
            continue
        seen.add(c)
        st, i, stk = c
        if st in finals and i == len(w) and stk == '':
            return True
        for f, r, po, t, pu in moves:
            if f == st and w.startswith(r, i) and stk.startswith(po):
                n = pu + stk[len(po):]
                if len(n) <= cap:
                    todo.append((t, i + len(r), n))
    return False


ACC, REJ = {'h', 'y', 'acc', 'accept', 'H', 'Y'}, {'n', 'rej', 'reject', 'N'}


def tm_parse(text):
    moves, start = {}, None
    for raw in text.strip().split('\n'):
        line = raw.split('//')[0].strip()
        if not line:
            continue
        if line.startswith('start'):
            start = line.split()[1]
            continue
        left, right = line.split('->')
        q, a = [x.strip() for x in left.split(',')]
        parts = [x.strip() for x in right.split(',')]
        if len(parts) == 3:
            p, b, d = parts
        elif parts[1] in ('L', 'R'):
            p, b, d = parts[0], a, parts[1]
        else:
            p, b, d = parts[0], parts[1], 'S'
        assert (q, a) not in moves, ('two moves for', q, a)
        moves[(q, a)] = (p, b, d)
        start = start or q
    return start, moves


def tm_run(tm, w, limit=3000):
    start, moves = tm
    tape = {i: c for i, c in enumerate(w)}
    q, h = start, 0
    for _ in range(limit + 1):
        if q in ACC:
            cells = [i for i, c in tape.items() if c != '#']
            out = ''.join(tape.get(i, '#') for i in range(min(cells), max(cells) + 1)) if cells else ''
            return True, out
        if q in REJ:
            return False, None
        m = moves.get((q, tape.get(h, '#')))
        if m is None:
            return False, None
        p, b, d = m
        tape[h] = b
        h += {'L': -1, 'R': 1, 'S': 0}[d]
        q = p
    return False, None


def pda_problem(id, title, diff, statement, alphabet, pred, ref, up_to=8, hint='', solution='', source='', max_states=None):
    a = pda_parse(ref)
    for w in words(alphabet, up_to):
        assert pda_accepts(a, w) == bool(pred(w)), f'{id}: the pushdown automaton is wrong on {w!r}'
    spec = {'mode': 'pda', 'alphabet': alphabet, 'reference': ref.strip(), 'upTo': up_to}
    if max_states:
        assert len(a[0]) <= max_states
        spec['maxStates'] = max_states
    P.append(problem(id, title, CA, diff, statement, 'lfa', spec, hint, solution or 'Un automat care merge:\n```\n' + ref.strip() + '\n```', source))


def tm_problem(id, title, diff, statement, alphabet, pred, ref, up_to=7, hint='', solution='', source='', fun=None):
    m = tm_parse(ref)
    for w in words(alphabet, up_to):
        ok, out = tm_run(m, w)
        if fun is None:
            assert ok == bool(pred(w)), f'{id}: the Turing machine is wrong on {w!r}'
        else:
            assert ok and out == fun(w), f'{id}: the Turing machine computes {out!r} on {w!r}, not {fun(w)!r}'
    spec = {'mode': 'tmf' if fun else 'tm', 'alphabet': alphabet, 'reference': ref.strip(), 'upTo': up_to}
    P.append(problem(id, title, CT, diff, statement, 'lfa', spec, hint, solution or 'O mașină care merge:\n```\n' + ref.strip() + '\n```', source))


def tf(id, title, ch, diff, statement, truth, why, source=''):
    P.append(true_false(id, title, ch, diff, statement, truth, solution=why, source=source))


def q(id, title, ch, diff, statement, right, wrong, why, hint='', source=''):
    P.append(quiz(id, title, ch, diff, statement, right, wrong, hint=hint, solution=why, source=source))


# =============================================================================
# The revision sheet of seminars 1-4 (lfa-problems-1.pdf): all ten problems
# =============================================================================
q(100, 'Câte tupluri are relația Δ', C2, 'medie',
  'Câte tupluri poate conține relația de tranziție `Δ` a unui automat finit nedeterminist `M = (K, Σ, Δ, s, F)`?\n\n(În curs `Δ ⊆ K × Σ* × K`: o tranziție poate citi un șir, nu doar un simbol.)',
  'un număr finit oricât de mare: nu există o margine superioară',
  ['cel mult |K|² · (|Σ| + 1)', 'exact |K| · |Σ|', 'o infinitate'],
  '`Δ` e o mulțime **finită** de tupluri `(q, u, p)`, dar etichetele `u ∈ Σ*` pot fi oricât de lungi, deci pentru `K` și `Σ` fixate nu există o margine: oricâte tranziții, dar un număr finit. Doar dacă etichetele sunt simboluri sau `e` (ca la Sipser), `|Δ| ≤ |K| · (|Σ| + 1) · |K|`.',
  hint='Ce poate fi la mijlocul unui tuplu `(q, u, p)`? Este `Δ` voie să fie infinită?', source=REC)

nfa_in(101, 'Automat pentru a*(ab ∪ ba ∪ e) ∪ b*', C2, 'ușoară',
       'Construiește un automat finit care acceptă `L(a*(ab ∪ ba ∪ e) ∪ b*)` peste `{a, b}` (`e` este cuvântul vid, scris în aplicație `ε`).',
       'ab', lambda w: re.fullmatch('a*(ab|ba|)|b*', w), 'a*(ab∪ba∪ε)∪b*',
       table(6, [1, 3, 4], '0 ε 1 4\n1 a 1 2\n1 b 5\n2 b 3\n5 a 3\n4 b 4'),
       hint='Reuniunea: din starea inițială, câte o ε-tranziție spre automatul fiecărei părți.',
       solution='`q0` —ε→ `q1` și —ε→ `q4`. `q1` are buclă pe `a` și e finală (`a*` urmat de `e`); din `q1`, `a` duce în `q2`, apoi `b` în `q3`, iar `b` duce în `q5`, apoi `a` în `q3` (finală). `q4` are buclă pe `b` și e finală.', source=REC)

dfa_in(102, 'Automat pentru ((a ∪ b)*(e ∪ c)*)*', C2, 'ușoară',
       'Construiește un automat finit cu **cât mai puține stări** care acceptă `L(((a ∪ b)*(e ∪ c)*)*)` peste `{a, b, c}`.',
       'abc', lambda w: True, '((a∪b)*(ε∪c)*)*',
       hint='Ce cuvinte de un singur simbol sunt în paranteza de sub stea? Atunci ce dă steaua?',
       solution='`(a ∪ b)*` conține `a` și `b`, `(e ∪ c)*` conține `c`, deci sub stea sunt toate simbolurile: limbajul e `Σ*`. Ajunge o stare, inițială și finală, cu buclă pe `a`, `b`, `c`.', source=REC, max_states=1)

nfa_in(103, 'Automat pentru ((ab)* ∪ (bc)*)ab', C2, 'medie',
       'Construiește un automat finit care acceptă `L(((ab)* ∪ (bc)*)ab)` peste `{a, b, c}`.',
       'abc', lambda w: re.fullmatch('((ab)*|(bc)*)ab', w), '((ab)*∪(bc)*)ab',
       table(8, [7], '0 ε 1 2\n1 a 3\n3 b 1\n2 b 4\n4 c 2\n1 ε 5\n2 ε 5\n5 a 6\n6 b 7'),
       hint='Două cicluri (`ab` și `bc`), fiecare cu o ε-tranziție spre drumul final `a`, `b`.',
       solution='`q0` —ε→ `q1` (ciclul `q1 —a→ q3 —b→ q1`) și —ε→ `q2` (ciclul `q2 —b→ q4 —c→ q2`). Din `q1` și din `q2`, ε spre `q5`, apoi `q5 —a→ q6 —b→ q7` (finală).', source=REC)

dfa_in(104, 'Fiecare dintre 0, 1, 2 apare', C1, 'medie',
       'Construiește un AFD peste `{0, 1, 2}` pentru `L = {w | |w|₀ ≥ 1 ∧ |w|₁ ≥ 1 ∧ |w|₂ ≥ 1}` (fiecare simbol apare măcar o dată).',
       '012', lambda w: '0' in w and '1' in w and '2' in w, None,
       hint='Starea ține minte mulțimea simbolurilor văzute până acum: o submulțime a lui `{0, 1, 2}`.',
       solution='8 stări, câte una pentru fiecare submulțime de simboluri văzute; `∅` e inițială, `{0, 1, 2}` e singura finală (și are buclă pe toate). Din mulțimea `S`, simbolul `x` duce în `S ∪ {x}`. E și produsul a trei automate „`x` a apărut”.',
       source=REC, max_states=8)

dfa_in(105, 'Lungime pară și niciun 1', C1, 'ușoară',
       'Construiește un AFD peste `{0, 1, 2}` pentru `L = {w | |w| este par ∧ |w|₁ = 0}`.',
       '012', lambda w: len(w) % 2 == 0 and '1' not in w, '((0∪2)(0∪2))*',
       hint='Paritatea lungimii, plus o groapă pentru primul `1`.',
       solution='`q0` (lungime pară, finală) și `q1` (impară), cu `0` și `2` trecând de la una la alta; `1` duce din amândouă în groapa `q2`.', source=REC, max_states=3)

dfa_in(106, 'Fără subcuvinte interzise', CP, 'medie',
       'Fie `Σ` un alfabet și `F ⊆ Σ*` un limbaj finit. Limbajul `L = {w ∈ Σ* | w nu are subsecvențe în F}` este regulat (folosind proprietățile de închidere).\n\nAplică ideea pentru `Σ = {a, b}` și `F = {aa, bab}`: construiește un AFD pentru `L`.',
       'ab', lambda w: 'aa' not in w and 'bab' not in w, None,
       hint='`L = Σ* \\ (Σ* F Σ*)`. Pentru automat, ține minte cel mai lung sfârșit al cuvântului care e începutul unui cuvânt interzis.',
       solution='În general: `F` e finit, deci regulat; `Σ*FΣ*` e o concatenare de limbaje regulate, deci regulat; `L` e complementul lui, deci regulat. Merge la fel pentru orice `F` regulat.\n\nAutomatul ține minte ce sfârșit al cuvântului citit poate începe `aa` sau `bab`: nimic, `a`, `b`, `ba`; plus groapa. 5 stări.',
       source=REC)

_m1 = table(2, [0], '0 a 1\n0 b 0\n1 a 0\n1 b 1')   # #a par
_m2 = table(2, [1], '0 a 0\n0 b 1\n1 a 0\n1 b 1')   # se termină cu b
_xor = table(4, [0, 3], '0 a 2\n0 b 1\n1 a 2\n1 b 1\n2 a 0\n2 b 3\n3 a 0\n3 b 3')
auto(107, 'Diferența simetrică a două AFD', CP, 'medie',
     'Se dau AFD-urile peste `{a, b}`:\n- `M1`: `q0` (finală) și `q1`; `a` trece de la una la alta, `b` rămâne pe loc (numărul de `a` e par);\n- `M2`: `p0` și `p1` (finală); `a` duce în `p0`, `b` în `p1` (cuvântul se termină cu `b`).\n\nConstruiește un automat `M` cu `L(M) = L(M1) △ L(M2)`, unde `A △ B = (A ∪ B) \\ (A ∩ B)`.',
     'ab', lambda w: (w.count('a') % 2 == 0) != w.endswith('b'), None, _xor, max_states=4, lang_auto=_xor,
     hint='Ca la intersecție: automatul produs, cu stări perechi `(qi, pj)`. Ce perechi sunt finale acum?',
     solution='Starea `(qi, pj)` (numerotată `2i + j`) urmărește ambele automate: `a` schimbă `i` și duce `j` în 0, `b` lasă `i` și duce `j` în 1. Finale sunt perechile în care **exact unul** dintre automate e într-o stare finală: `(q0, p0)` (număr par de `a`, nu se termină cu `b`) și `(q1, p1)` (impar, se termină cu `b`), adică `q0` și `q3` în tabelă. Față de intersecție (amândouă finale) și reuniune (măcar una), se schimbă doar mulțimea stărilor finale.',
     source=REC)

# 108: |F| = |K|, every state is final: six statements
tf(108, 'Toate stările finale: AFD și e', C1, 'ușoară',
   'Adevărat sau fals?\n\nFie `M` un **AFD** cu `|F| = |K|` (toate stările sunt finale). Atunci `e ∈ L(M)`.', True,
   'Starea inițială e finală, iar `(s, e) ⊢* (s, e)` în zero pași, deci `e` e acceptat. La un AFD (complet) se acceptă de fapt orice cuvânt: `L(M) = Σ*`.', REC)
tf(109, 'Toate stările finale: AFD și prefixele', C1, 'ușoară',
   'Adevărat sau fals?\n\nFie `M` un **AFD** cu `|F| = |K|`. Dacă `w` e acceptat de `M`, atunci orice prefix al lui `w` este în `L(M)`.', True,
   'Un AFD e complet: orice cuvânt duce într-o stare, care e finală. Deci `L(M) = Σ*` și conține orice prefix.', REC)
tf(110, 'Toate stările finale: AFN și e', C2, 'ușoară',
   'Adevărat sau fals?\n\nFie `M` un **AFN** cu `|F| = |K|`. Atunci `e ∈ L(M)`.', True,
   'Starea inițială e finală, iar configurația `(s, e)` e de acceptare din pornire.', REC)
tf(111, 'Toate stările finale: AFN și prefixele', C2, 'medie',
   'Adevărat sau fals?\n\nFie `M` un **AFN** (ca în curs, `Δ ⊆ K × Σ* × K`) cu `|F| = |K|`. Dacă `w` e acceptat de `M`, atunci orice prefix al lui `w` este în `L(M)`.', False,
   'O tranziție poate citi un șir întreg: cu `Δ = {(s, ab, f)}`, `ab` e acceptat, dar prefixul `a` nu, pentru că nicio tranziție nu citește doar `a`. (Dacă tranzițiile citesc câte un simbol sau `e`, afirmația devine adevărată: prefixul se oprește pe drum, într-o stare finală.)', REC)
tf(112, 'Limbaje închise la prefixe și AFN-uri cu toate stările finale', C2, 'grea',
   'Adevărat sau fals?\n\nOrice limbaj regulat care conține toate prefixele șirurilor sale admite un **AFN** acceptor `M` cu `|F| = |K|`.', False,
   'Capcana e limbajul vid: `∅` conține (vid) toate prefixele șirurilor sale, dar orice automat cu toate stările finale acceptă măcar `e`. Pentru `L ≠ ∅` închis la prefixe afirmația e adevărată: în AFD-ul minim, o stare nefinală atinsă are doar continuări în afara lui `L` (altfel cuvântul ar fi prefix al unui cuvânt din `L`), deci e groapa; o scoatem și rămân doar stări finale.', REC)
tf(113, 'Limbaje închise la prefixe și AFD-uri cu toate stările finale', C1, 'medie',
   'Adevărat sau fals?\n\nOrice limbaj regulat care conține toate prefixele șirurilor sale admite un **AFD** acceptor `M` cu `|F| = |K|`.', False,
   'Un AFD complet cu toate stările finale acceptă `Σ*`. Limbajul `L(a*)` peste `{a, b}` e închis la prefixe, dar nu e `Σ*`.', REC)

q(114, 'Când e L(M) finit', CP, 'medie',
  'Cum putem verifica dacă limbajul unui AFD `M` este **finit**?',
  'pe niciun drum de la starea inițială la o stare finală nu există un ciclu',
  ['M nu are niciun ciclu', 'M are cel mult |K| stări finale', 'nicio stare finală nu are buclă'],
  'Un cuvânt mai lung decât `|K|` repetă o stare, deci parcurge un ciclu; ciclul se poate repeta oricât (asta e lema de pompare). Deci `L(M)` e infinit exact când un ciclu e accesibil din start și din el se ajunge într-o stare finală. Algoritm: scoatem stările inaccesibile și pe cele din care nu se ajunge la o stare finală, apoi căutăm un ciclu (DFS). Echivalent: `L(M)` e infinit ⇔ conține un cuvânt cu `|K| ≤ |w| < 2|K|`. Pentru „un unic cel mai lung șir nevid”: `L(M)` trebuie să fie finit și nevid, apoi pe graful fără cicluri al stărilor utile calculăm lungimea maximă a unui drum și numărăm drumurile de lungime maximă (la un AFD, drumuri diferite = cuvinte diferite); trebuie să fie exact unul, nevid.',
  hint='`M` poate avea cicluri care nu ajută niciun cuvânt acceptat: în groapă, de exemplu.', source=REC)

nfa_in(115, 'Sufixele lui ab*a', CP, 'medie',
       'Dacă `L` e regulat, atunci `Suf(L) = {w ∈ Σ* | ∃w′ ∈ L cu w sufix pentru w′}` este regulat.\n\nAplică demonstrația: pentru `L = L(ab*a)` peste `{a, b}`, construiește un automat pentru `Suf(L)`.',
       'ab', lambda w: w == '' or re.fullmatch('b*a|ab*a', w), 'ε∪b*a∪ab*a',
       table(5, [4], '0 ε 1 2 4\n1 a 2\n2 b 2\n2 a 4'),
       hint='Din AFN-ul lui `L`, un sufix începe dintr-o stare la care se poate ajunge din start: adaugă o stare inițială nouă cu ε-tranziții spre toate acestea.',
       solution='Demonstrația: fie `M` un AF pentru `L`. Păstrăm stările accesibile din `s`; adăugăm `s′` nouă, inițială, cu `(s′, e, q)` pentru fiecare `q` accesibilă. Un drum din `s′` citește exact un sufix al unui cuvânt care trece prin `q`. Aici: `q1 —a→ q2` (buclă `b`) `—a→ q4` finală; `q0` nou, cu ε spre `q1`, `q2`, `q4`. `Suf(L) = e ∪ b*a ∪ ab*a`.',
       source=REC)

q(116, 'O singură stare finală la AFD?', CP, 'medie',
  'Poate orice limbaj regulat să fie recunoscut de un automat finit **determinist** cu o singură stare acceptoare?',
  'nu: {e, a} peste {a} nu poate; dar orice limbaj regulat are un AFN cu o singură stare finală',
  ['da, se unesc toate stările finale într-una', 'da, cu ε-tranziții spre o stare finală nouă', 'nu, niciun limbaj infinit nu poate'],
  'Fie `L = {e, a}` peste `{a}`. Un AFD cu o stare finală `f` care acceptă `e` are `s = f`; acceptă și `a`, deci `δ(s, a) = f = s`, și atunci acceptă și `aa ∉ L`. La AFN (cu tranziții pe `e`) adăugăm o stare finală nouă `f` și `(q, e, f)` din fiecare stare finală veche, care devine nefinală. ε-tranzițiile nu sunt voie la un AFD, iar „unirea” stărilor finale schimbă limbajul.',
  hint='Încearcă un limbaj cu `e` și încă un cuvânt.', source=REC)

q(117, 'δ(q, a) = δ(p, a) ⇔ q = p', C1, 'grea',
  'Cum arată un AFD `M` pentru care `δ(q, a) = δ(p, a) ⇔ q = p`, pentru orice `a ∈ Σ` și `p, q ∈ K`?',
  'fiecare simbol permută stările: în fiecare stare intră exact o tranziție pe fiecare simbol, deci automatul oglindit e tot determinist',
  ['are o singură stare', 'nu are cicluri', 'are exact o stare finală'],
  'Pentru un `a` fixat, `q ↦ δ(q, a)` e o funcție injectivă pe mulțimea finită `K`, deci o bijecție (o permutare a stărilor). În fiecare stare intră exact o săgeată etichetată `a`: dacă întoarcem săgețile, obținem tot un automat determinist și complet (un automat „reversibil”); fiecare stare e pe un ciclu pentru fiecare simbol. La AFN, `(q, a, x), (p, a, x) ∈ Δ ⇔ q = p` spune doar că în fiecare stare intră cel mult o tranziție pe fiecare simbol: automatul întors e determinist, dar poate fi incomplet.',
  hint='O funcție injectivă de la o mulțime finită în ea însăși e și surjectivă.', source=REC)

# =============================================================================
# Exams 2022-2025 and the tests: what the app can check
# =============================================================================
cfg_in(120, 'aⁿ b^(n mod 3) cⁿ', C4, 'medie',
       'Fie `L = {aⁿ b^f(n) cⁿ | f(n) = n mod 3, n ≥ 0}`. Arată că `L` este LIC: scrie o gramatică pentru el.',
       'abc', lambda w: w == 'a' * w.count('a') + 'b' * (w.count('a') % 3) + 'c' * w.count('a'),
       'S -> aaaSccc | ε | abc | aabbcc', 12,
       hint='Scrie `n = 3k + r`: `aⁿ b^r cⁿ = a³ᵏ (aʳ bʳ cʳ) c³ᵏ`, cu `r ∈ {0, 1, 2}`.',
       solution='`S -> aaaSccc | ε | abc | aabbcc`: `S` pune câte trei `a` și trei `c` deodată, iar la mijloc restul `r`: nimic, `abc` sau `aabbcc`.', source=E22b)

q(121, 'L1 LIC, L2 nu, disjuncte: reuniunea', C5, 'grea',
  'Fie `L1` un limbaj independent de context și `L2` un limbaj care nu este independent de context, cu `L1 ∩ L2 = ∅`. Cum este `L1 ∪ L2`?',
  'nu se poate afirma nimic: poate fi LIC sau nu',
  ['întotdeauna LIC', 'niciodată LIC', 'întotdeauna regulat'],
  'Cu `L1 = ∅`, `L1 ∪ L2 = L2`, care nu e LIC. Cu `L2 = {aⁿbⁿcⁿ}` și `L1 = Σ* \\ L2` (complementul lui `aⁿbⁿcⁿ` e LIC: reuniunea condițiilor „nu e de forma a*b*c*”, „#a ≠ #b”, „#b ≠ #c”), `L1 ∪ L2 = Σ*`, regulat.',
  source=E22b)

q(122, 'aⁿbⁿw cu |w| = n', C5, 'medie',
  'Fie `L = {aⁿbⁿw | n ≥ 0, w ∈ {c, d}*, |w| = n}`. Cum este `L` în cel mai strict sens?',
  'nu este independent de context', ['regulat', 'independent de context, dar nu regulat', 'finit'],
  'Prin proprietăți de închidere: dacă `L` ar fi LIC, atunci și `L ∩ a*b*c*` ar fi LIC (intersecția cu un regulat). Dar `L ∩ a*b*c* = {aⁿbⁿcⁿ}`, care nu e LIC.',
  hint='Intersectează cu un limbaj regulat bine ales.', source=E22b)

q(123, 'Concatenare de două cuvinte din L, cu doi de a', C5, 'medie',
  'Fie `Σ` un alfabet, `a ∈ Σ`, și `L` un limbaj regulat peste `Σ`. Cum este `L′ = {w ∈ Σ* | ∃w1, w2 ∈ L, w = w1w2 și w are cel puțin 2 a}`?',
  'regulat', ['independent de context, dar nu neapărat regulat', 'poate să nu fie LIC', 'finit'],
  '`L′ = L·L ∩ Σ*aΣ*aΣ*`: concatenarea a două limbaje regulate e regulată, „are cel puțin doi `a`” e regulat, iar intersecția a două limbaje regulate e regulată.', source=E22b)

q(124, 'aᵏbᵏ cu k ≤ 8', C5, 'ușoară',
  'Cum este limbajul `{aᵏbᵏ | k ∈ N*, k ≤ 8}` peste `{a, b}`?',
  'finit, deci regulat', ['independent de context, dar nu regulat', 'nu este independent de context', 'regulat, dar infinit'],
  'Are exact 8 cuvinte. Orice limbaj finit e regulat: o expresie `ab ∪ aabb ∪ … ∪ a⁸b⁸`.', source=E22d)

regex_in(125, 'Ce generează S → SS | Sa | b', C3, 'medie',
         'Gramatica `G` peste `{a, b}`: `S -> SS | Sa | b`. Ce șiruri generează? Scrie o expresie regulată pentru `L(G)`.',
         'ab', lambda w: w.startswith('b'), 'b(a∪b)*',
         hint='Primul simbol al oricărui cuvânt generat: `S ⇒ SS ⇒ …`, cel mai din stânga `S` ajunge la `b`.',
         solution='Cuvintele care încep cu `b`: `b(a ∪ b)*`. Orice derivare începe cu `b` (cel mai din stânga `S` devine în final `b`), și orice `bu` se obține: `S ⇒ Sx ⇒ …` adaugă la dreapta `a` (cu `Sa`) sau `b` (cu `SS`, `S ⇒ b`).', source=E22d)

cfg_in(126, 'Răsturnatul lui L(S → SS | Sa | b)', C4, 'medie',
       'Fie `G: S -> SS | Sa | b` și `L′ = {w | wᴿ ∈ L(G)}`. Modifică gramatica `G` ca să obții `G′` care generează `L′`. (Cum transformi în general o GIC pentru `L` într-una pentru răsturnatul lui `L`?)',
       'ab', lambda w: w.endswith('b'), 'S -> SS | aS | b', 9,
       hint='Răstoarnă partea dreaptă a fiecărei reguli.',
       solution='`S -> SS | aS | b`. În general: `G′ = (V, Σ, R′, S)` cu `R′ = {A → αᴿ | A → α ∈ R}`; prin inducție pe lungimea derivării, `A ⇒* w` în `G` ⇔ `A ⇒* wᴿ` în `G′`. Aici `L′` = cuvintele care se termină cu `b`.', source=E22d)

q(127, '#a = #b și #c = #d', C5, 'medie',
  'Fie `L` limbajul șirurilor peste `{a, b, c, d}` cu `#a = #b` și `#c = #d` (de exemplu `ccbddcaadb ∈ L`). Cum este `L`?',
  'nu este independent de context', ['regulat', 'independent de context, dar nu regulat', 'finit'],
  '`L ∩ a*c*b*d* = {aⁿcᵐbⁿdᵐ}`, care nu e LIC (lema de pompare: pe `aᵖcᵖbᵖdᵖ`, `vxy` are cel mult `p` simboluri, deci atinge cel mult două blocuri vecine și strică o egalitate). Dacă `L` ar fi LIC, intersecția cu un regulat ar fi LIC.',
  source=E22d)

q(128, 'Un șir în niciunul dintre două AFD', CP, 'medie',
  'Fie `M1`, `M2` două AFD peste același alfabet. Cum determinăm dacă există un șir care **nu** este în niciunul dintre `L(M1)`, `L(M2)`?',
  'construim un AFD pentru complementul lui L(M1) ∪ L(M2) și verificăm dacă limbajul lui e nevid',
  ['verificăm dacă L(M1) ∩ L(M2) = ∅', 'verificăm dacă L(M1) = L(M2)', 'nu se poate decide'],
  '`∃w ∉ L(M1) ∪ L(M2)` ⇔ `Σ* \\ (L(M1) ∪ L(M2)) ≠ ∅`. Construim produsul (reuniunea), inversăm stările finale (complementul; AFD-ul e complet) și căutăm, prin parcurgere din starea inițială, o stare finală accesibilă. Echivalent: în produs există o pereche `(p, q)` accesibilă cu `p ∉ F1` și `q ∉ F2`.',
  source=E25a)

q(129, 'prefix(L) pentru L Turing acceptat', C5, 'grea',
  'Dacă `L` este un limbaj Turing acceptat, este `prefix(L)` (mulțimea prefixelor cuvintelor din `L`) Turing acceptat?',
  'da', ['nu', 'doar dacă L e decidabil', 'doar dacă L e finit'],
  'O mașină pentru `prefix(L)` primește `x` și încearcă, în paralel (dovetailing), toate continuările `y`: la pasul `k`, rulează câte `k` pași din mașina lui `L` pe primele `k` cuvinte `xy`. Dacă vreun `xy ∈ L`, rularea lui se oprește după un număr finit de pași și acceptăm. Dacă nu, mașina nu se oprește, ceea ce e voie la un limbaj Turing acceptat.',
  source=E22d)

regex_in(130, '#ab = 0 sau lungime pară', C3, 'medie',
         'Fie `L = {w ∈ {a, b}* | #ab(w) = 0 ∨ |w| e par}` (`#ab(w)` = de câte ori apare `ab` în `w`). Scrie o expresie regulată pentru `L`.',
         'ab', lambda w: 'ab' not in w or len(w) % 2 == 0, 'b*a*∪((a∪b)(a∪b))*',
         hint='Un cuvânt fără `ab` are toți `b`-ii înaintea tuturor `a`-ilor.',
         solution='`b*a* ∪ (ΣΣ)*`: fără niciun `ab`, cuvântul e `bⁱaʲ`; altfel trebuie să aibă lungime pară. O gramatică: `S -> A | B`, `A -> bA | Aa | ε`, `B -> aaB | abB | baB | bbB | ε`.', source=E25b)

cfg_in(131, '#ab = 0 sau lungime pară: gramatica', C4, 'ușoară',
       'Fie `L = {w ∈ {a, b}* | #ab(w) = 0 ∨ |w| e par}`. Scrie o gramatică care generează `L`.',
       'ab', lambda w: 'ab' not in w or len(w) % 2 == 0, 'S -> A | B\nA -> bA | Aa | ε\nB -> aaB | abB | baB | bbB | ε', 8,
       hint='Reuniune: `S -> A | B`, cu `A` pentru `b*a*` și `B` pentru lungime pară.', source=E25b)

_G132 = grammar_words('S -> A | B | C | D\nA -> 01B | 0 | ε\nB -> 00A | 0 | ε\nC -> 10D | 1 | ε\nD -> 11C | 1 | ε', 9)
regex_in(132, 'Ce generează X1, X2, Y1, Y2', C3, 'grea',
         'Fie gramatica peste `{0, 1}`:\n```\nS  -> X1 | X2 | Y1 | Y2\nX1 -> 01X2 | 0 | e\nX2 -> 00X1 | 0 | e\nY1 -> 10Y2 | 1 | e\nY2 -> 11Y1 | 1 | e\n```\nCe limbaj generează? Scrie o expresie regulată pentru el.',
         '01', lambda w: w in _G132, '(0100)*(ε∪0∪01∪010)∪(0001)*(ε∪0∪00∪000)∪(1011)*(ε∪1∪10∪101)∪(1110)*(ε∪1∪11∪111)',
         hint='Scrie ce generează `X1`: `01 00 01 00 …`, oprit oricând cu `0` sau nimic. Restul e la fel.',
         solution='`X1 = 01X2 ∪ 0 ∪ e` și `X2 = 00X1 ∪ 0 ∪ e`; înlocuind, `X1 = (0100)X1 ∪ 010 ∪ 01 ∪ 0 ∪ e`, deci (lema lui Arden) `X1 = (0100)*(e ∪ 0 ∪ 01 ∪ 010)`; analog `X2 = (0001)*(e ∪ 0 ∪ 00 ∪ 000)`, `Y1 = (1011)*(e ∪ 1 ∪ 10 ∪ 101)`, `Y2 = (1110)*(e ∪ 1 ∪ 11 ∪ 111)`. Pe pozițiile impare cuvântul repetă primul simbol, iar pe cele pare alternează.',
         source=E25b)


def _xy(w):
    return any('01' not in w[:i] and '110' not in w[i:] for i in range(len(w) + 1))

regex_in(133, 'x fără 01, apoi y fără 110', C3, 'grea',
         'Scrie o expresie regulată pentru `L = {xy | x ∈ {0, 1}* nu conține 01, y ∈ {0, 1}* nu conține 110}`.',
         '01', _xy, '1*0*(0∪10)*1*',
         hint='Fără `01`: `1*0*`. Fără `110`: după doi `1` consecutivi nu mai poate veni `0`, deci `(0 ∪ 10)*1*`.',
         solution='`Ex = 1*0*`, `Ey = (0 ∪ 10)*1*` (varianta din rezolvare: `0*(100*)*1*`), `E = ExEy = 1*0*(0 ∪ 10)*1*`.', source=E25c)

cfg_in(134, 'O gramatică neambiguă pentru (01)ⁿ(10)ᵐ', C4, 'grea',
       'Gramatica `S -> 01A | 01S`, `A -> B10`, `B -> S | e` este ambiguă (`0101011010` are două derivări stânga) și generează `L = {(01)ⁿ(10)ᵐ | n ≥ m > 0}`.\n\nScrie o gramatică **neambiguă** pentru `L`. (Se verifică și că fiecare cuvânt are un singur arbore de derivare.)',
       '01', lambda w: any(w == '01' * n + '10' * m for n in range(1, 8) for m in range(1, n + 1)),
       'S -> 01S | T\nT -> 01T10 | 0110', 10, unambiguous=True,
       hint='Separă cele două roluri: întâi `01`-urile în plus (`n − m` bucăți), apoi perechile potrivite `01 … 10`, cel puțin una.',
       solution='`S -> 01S | T` pune `01`-urile în plus, `T -> 01T10 | 0110` pune `m ≥ 1` perechi potrivite. Fiecare cuvânt are o singură împărțire `(01)ⁿ⁻ᵐ · (01)ᵐ(10)ᵐ`, deci un singur arbore. Gramatica dată e ambiguă pentru că `S -> 01S` și `B -> S` pot pune același `01` în două locuri.', source=E25c)

def _blocks01(w):
    # S -> AS | e, A -> A1 | 0A1 | 01: blocks 0^k 1^(k+j), k >= 1
    i = 0
    while i < len(w):
        k = 0
        while i < len(w) and w[i] == '0':
            k += 1; i += 1
        o = 0
        while i < len(w) and w[i] == '1':
            o += 1; i += 1
        if k == 0 or o < k:
            return False
    return True



cfg_in(135, 'O gramatică neambiguă (set de probleme)', C4, 'grea',
       'Scrie o gramatică **neambiguă** care generează același limbaj ca `S -> AS | e`, `A -> A1 | 0A1 | 01`.',
       '01', lambda w: _blocks01(w), 'S -> ε | CS\nC -> 0D1E\nD -> 0D1 | ε\nE -> 1E | ε',
       10, unambiguous=True,
       hint='Ce face `A`? `0A1` și `01` dau `0ᵏ1ᵏ`, iar `A1` adaugă `1`-uri: `A = 0ᵏ1ᵏ1ʲ`, cu `k ≥ 1`. `S` = blocuri de felul ăsta.',
       solution='`A` generează `0ᵏ1ᵏ⁺ʲ` (`k ≥ 1`, `j ≥ 0`), iar `S` o concatenare de astfel de blocuri. Ambiguitatea vine din `A -> A1` combinat cu `0A1`: `0011` = `0(01)1` sau... Scriem blocul o singură dată: `C -> 0D1E`, `D -> 0D1 | ε` (perechile), `E -> 1E | ε` (`1`-urile în plus, doar la sfârșit), `S -> ε | CS`. Un bloc începe la fiecare `0` care urmează după un `1`, deci împărțirea în blocuri e unică. (Rezolvarea din set, `S -> S1 | 0S1 | 01 | ε`, generează și `1`, care nu e în limbaj: atenție.)', source=PS)



cfg_in(136, 'Forma normală Chomsky pentru a*b(a ∪ b)*', C4, 'medie',
       'Fie `N = ({0, 1}, {a, b}, {(0, a, 0), (0, b, 0), (0, b, 1), (1, a, 1), (1, a, 0)}, 0, {1})`. Scrie o gramatică `G` în **Forma Normală Chomsky** cu `L(G) = L(N)`.',
       'ab', lambda w: 'b' in w, 'S -> ZS | US | UA | b\nA -> ZA | UA | a | b\nZ -> a\nU -> b', 8, chomsky=True,
       hint='`L(N) = a*b(a ∪ b)*`. Gramatica regulată `S -> aS | bA | b`, `A -> aA | bA | a | b`, apoi terminalele din regulile lungi primesc neterminale.',
       solution='`S -> ZS | US | UA | b`, `A -> ZA | UA | a | b`, `Z -> a`, `U -> b`. (`S` citește `a`-urile de la început și primul `b`; `A` restul, nevid.)', source=PS)

q(137, 'L1·L2 regulat ⇒ L1, L2 regulate?', C5, 'medie',
  'Implicația „pentru orice `L1, L2`: `L1 · L2` regulat ⇒ `L1` regulat și `L2` regulat” este:',
  'falsă: L1 = {0ⁿ1ᵐ | n > m ≥ 0}, L2 = L(1*) dau L1L2 = L(0⁺1*)',
  ['adevărată, pentru că LR sunt închise la concatenare', 'adevărată doar dacă L1 și L2 sunt finite', 'falsă: L1 = {0ⁿ1ⁿ}, L2 = {1ⁿ0ⁿ}'],
  '`L1 = {0ⁿ1ᵐ | n > m ≥ 0}` nu e regulat, dar `L1 · 1* = 0⁺1*` (orice număr de `1`-uri se poate pune după `0ⁿ1ᵐ`). Închiderea la concatenare spune altceva: dacă `L1`, `L2` sunt regulate, atunci și `L1L2`.',
  source=PS)

q(138, 'L* regulat ⇒ L regulat?', C5, 'medie',
  'Implicația „pentru orice `L`: `L*` regulat ⇒ `L` regulat” este:',
  'falsă: L = {a^p | p prim} are L* = {ε} ∪ {aⁿ | n ≥ 2}',
  ['adevărată', 'falsă, dar doar pentru alfabete cu cel puțin două simboluri', 'adevărată pentru limbaje infinite'],
  '`L = {aᵖ | p prim}` nu e regulat (lema de pompare), dar orice `n ≥ 2` e o sumă de 2 și 3, deci `L* = {e} ∪ {aⁿ | n ≥ 2} = L(e ∪ aaa*)`, regulat.',
  source=PS)

# --------------------------------------------------------------- test 1 (grile) and the others
q(140, 'Superlimbaje care nu sunt LIC', C5, 'medie',
  'Valorile de adevăr: (i) Pentru orice `L ∈ LR` există un `L′` care nu este LIC a.î. `L ⊆ L′`. (ii) Pentru orice `L ∈ LIC` există un `L′` care nu este LR a.î. `L ⊆ L′`.',
  'Fals, Fals', ['Adevărat, Adevărat', 'Fals, Adevărat', 'Adevărat, Fals'],
  'Pentru `L = Σ*` singurul `L′ ⊇ L` e `Σ*`, care e regulat (deci și LIC). Ambele afirmații cad pe același contraexemplu.', source=T1)
q(141, 'uvwvᴿ cu |u| = |w| = 2', C5, 'grea',
  'Fie `L = {uvwvᴿ | u, v, w ∈ {a, b}*, |u| = |w| = 2}`. Cum este `L` în cel mai strict sens?',
  'LIC', ['finit', 'nu este LIC', 'LR'],
  'O gramatică: `S -> XXT`, `T -> aTa | bTb | XX`, `X -> a | b`: `T` construiește `v ... vᴿ` în jurul lui `w`. Nu e regulat: `v` se oglindește în jurul unui centru fix, ca la palindroame (de exemplu, intersectat cu `aa(ab)*aa(ba)*` și pompat, egalitatea se strică).', source=T1)
q(142, 'aⁿbᵏcⁿ⁺ᵖ cu p ≥ −n', C5, 'medie',
  'Ce tip de limbaj este `L = {aⁿbᵏcⁿ⁺ᵖ | n, k ≥ 0, p ∈ [−n, ∞)}`?',
  'LR', ['LIC', 'finit', 'nu este LIC'],
  '`p ≥ −n` înseamnă doar `n + p ≥ 0`: exponentul lui `c` e orice număr natural, independent de `n`. Deci `L = a*b*c*`.', source=T1)
q(143, 'aⁿb³ᵏcᵏd²ⁿ⁺ᵖfʳgᵖ⁺ʳ', C5, 'grea',
  'Ce tip de limbaj este `L = {aⁿb³ᵏcᵏd²ⁿ⁺ᵖfʳgᵖ⁺ʳ | n, k, p, r ≥ 0}`?',
  'LIC', ['LR', 'finit', 'nu este LIC'],
  'Desparte exponenții: `aⁿ (b³ᵏcᵏ) d²ⁿ · dᵖ (fʳgʳ) gᵖ`. Fiecare parte are perechi imbricate (ca `aⁿXd²ⁿ` cu `X` tot o pereche), deci e LIC, iar concatenarea a două LIC e LIC. Nu e regulat: intersectat cu `a*d*` dă `aⁿd²ⁿ`.', source=T1)
q(144, 'S → ab | ba | SS | S | a | b | e', C4, 'ușoară',
  'Ce limbaj generează gramatica `S -> ab | ba | SS | S | a | b | e`?',
  'L((a ∪ b)*)', ['L(((ab ∪ ba ∪ aa ∪ bb)(a ∪ b ∪ e))*)', 'L((aba ∪ bab)*)', 'L((aba ∪ aab ∪ baa ∪ bab)*)'],
  '`S -> a | b` și `S -> SS` dau orice cuvânt nevid, iar `S -> e` cuvântul vid.', source=T1)
q(145, 'O gramatică cu A, B, C', C4, 'medie',
  'Ce limbaj generează `S -> SS | A | B`, `A -> aAa | a | C`, `B -> BB | B | b`, `C -> a | e`?',
  'L((a* ∪ bb*)*)', ['L(((aa)*(a ∪ e) ∪ (bb)*)*)', '∅', 'L(a*(a ∪ e)a*b*b*)'],
  '`A` dă `a²ᵏ(a ∪ e)`, adică `a*`; `B` dă `b⁺`; `S` concatenări de astfel de bucăți, deci `(a ∪ b)*` = `L((a* ∪ bb*)*)`. Varianta cu `(bb)*` nu conține `b`.', source=T1)
q(146, 'Intersecții LIC ∩ LR', C5, 'medie',
  'Fie `M1 = {L | L ∈ LIC}`, `M2 = {L | L ∈ LR}` și `M3 = {L1 ∩ L2 | L1 ∈ M1, L2 ∈ M2}`. Care afirmație e adevărată?',
  'M3 = M1', ['M3 = M2', 'M3 = ∅', 'M3 = M1 \\ M2'],
  'Intersecția unui LIC cu un LR e LIC, deci `M3 ⊆ M1`; și orice LIC `L = L ∩ Σ*`, cu `Σ*` regulat, deci `M1 ⊆ M3`.', source=T1)
q(147, 'Același simbol la început, mijloc și sfârșit', C5, 'medie',
  'Fie `L = {w ∈ {a, b}* | |w| = 2k + 1, k ≥ 0, w are același simbol la început, la mijloc și la sfârșit}`. Cum este `L` în cel mai strict sens?',
  'LIC', ['finit', 'LR', 'nu este LIC'],
  'O gramatică: `S -> aAa | bBb | a | b`, `A -> XAX | a`, `B -> XBX | b`, `X -> a | b`: mijlocul se găsește punând simbolurile câte două, unul în stânga, unul în dreapta. Nu e regulat: un automat finit nu poate găsi mijlocul (`aⁿbaⁿ` vs `aⁿbaⁿ⁺²` se deosebesc prin ce urmează).', source=T1)
q(148, 'Expresii echivalente cu a*b*', C3, 'medie',
  'Fie `E = a*b*`. Care dintre următoarele este o expresie regulată validă și echivalentă cu `E`?',
  '(a ∪ ∅)*(b∅* ∪ a∅)*', ['(a ∪ b)*∅*b*', '((a ∪ b)*∅)a*b*∅*', '(a ∪ b)* ∩ a*b*'],
  '`∅* = e` și `x∅ = ∅`: `(a ∪ ∅)* = a*`, `b∅* ∪ a∅ = b`, deci `a*b*`. `(a ∪ b)*∅*b* = (a ∪ b)*`; `(…)∅(…) = ∅`; `∩` nu e un operator al expresiilor regulate.', source=T1)
q(149, 'APD cu un singur simbol de stivă', CA, 'medie',
  'Fie `L` un limbaj acceptat de un APD cu `|Γ| = 1`. Atunci `L` poate fi acceptat și de:',
  'un APD (doar atât se poate spune)', ['un AFN', 'un AFD', 'un APD fără cicluri'],
  'Cu un singur simbol, stiva e un contor; tot poate recunoaște `aⁿbⁿ`, care nu e regulat, deci nu un AF în general.', source=T1)
q(150, 'Expresia lungă cu L1…L5', C5, 'grea',
  'Fie `L1, L2 ∈ LIC`, `L3, L4 ∈ LR` și `L5` un limbaj finit. Ce este `(((L1 \\ L2) ∩ (Σ* \\ L1))Σ*)* ∩ (((L3L4) ∪ L2) \\ L5)*`?',
  'un limbaj finit', ['nu se poate specifica', 'LR, dar nu neapărat finit', 'LIC, dar nu neapărat regulat'],
  '`L1 \\ L2 ⊆ L1`, deci `(L1 \\ L2) ∩ (Σ* \\ L1) = ∅`; `∅Σ* = ∅`; `∅* = {e}`. Iar `{e} ∩ X*` = `{e}`, pentru că orice stea conține `e`. Rezultatul e `{e}`.', source=T1)

q(151, 'Trei expresii pentru Σ*', C3, 'ușoară',
  'Care dintre expresiile `(a*b*)*`, `(a* ∪ b*)*`, `(a ∪ b)*` sunt echivalente?',
  'toate trei', ['prima cu a doua', 'prima cu a treia', 'a doua cu a treia'],
  'Fiecare are sub stea și `a`, și `b`, deci descrie `Σ*` pentru `Σ = {a, b}`.', source=T2)
q(152, 'Un limbaj finit, generat de o gramatică', C5, 'medie',
  'Limbajul generat de `S -> aAb | aAbA`, `A -> BB | a`, `B -> bb | b | e` poate fi acceptat, în cel mai strict sens, de:',
  'un automat finit', ['un automat push-down determinist', 'un automat push-down nedeterminist', 'niciuna dintre variante'],
  'Nicio regulă nu se apelează recursiv: `A` și `B` generează un număr finit de cuvinte, deci și `S`. Un limbaj finit e regulat.', source=T2)
q(153, 'Răsturnatul unui LIC', C5, 'ușoară',
  'Fie `L` un limbaj independent de context. `Rasturnat(L) = {wᴿ | w ∈ L}` este:',
  'independent de context', ['regulat', 'dependent de context', 'nu se poate afirma nimic'],
  'Răsturnăm partea dreaptă a fiecărei reguli: `R′ = {(X, γᴿ) | (X, γ) ∈ R}`. Nu adăugăm și nu scoatem restricții.', source=T2)
q(154, 'Prime și pare', C5, 'medie',
  'Fie `L1 = {aᵖ | p prim}`, `L2 = {a²ᵏ | k ∈ N}`. `(L1 ∩ L2)* \\ L2` este:',
  'mulțimea vidă', ['L1*', 'complementul lui L2', 'L1* ∩ L2*'],
  '2 e singurul număr prim par: `L1 ∩ L2 = {aa}`, `(L1 ∩ L2)* = {a²ᵏ} = L2`, iar `L2 \\ L2 = ∅`.', source=T2)
q(155, 'Stivă de dimensiune mărginită', CA, 'medie',
  'Un automat push-down nedeterminist cu stiva finită, de dimensiune constantă, acceptă (în cel mai strict sens):',
  'limbaje regulate', ['orice limbaj', 'limbaje independente de context', 'nu se poate spune'],
  'Dacă stiva are cel mult `l` simboluri, conținutul ei e una dintre finit de multe posibilități; le punem în stare: `K′ = K × Γ^≤l`, un automat finit.', source=T2)
q(156, 'L1L4 = L2 ⇒ L4 regulat?', C5, 'grea',
  'Fie `L1, L2, L3` regulate și `L4` oarecare. (i) `L1L4 = L2 ⇒ L4` regulat; (ii) `L1L2 = L3L4 ⇒ L4` regulat; (iii) `L1L4L2 = L3 ⇒ L4` regulat.',
  'toate afirmațiile sunt false', ['i) și ii) sunt adevărate, iii) e falsă', 'toate afirmațiile sunt adevărate', 'iii) e adevărată, i) și ii) sunt false'],
  '`L1 = L2 = L3 = a*` și `L4 = {a^(n²)}` (cu `e`): toate concatenările dau `a*`, dar `L4` nu e regulat.', source=T2)
q(157, 'S → A, A → S', C4, 'medie',
  'Ce e adevărat despre gramatica `S -> A`, `A -> S`?',
  'generează un limbaj regulat', ['nu este o gramatică validă', 'automatul push-down echivalent are minim două stări', 'are un terminal și un neterminal'],
  'E o gramatică validă pentru `∅` (nicio derivare nu se termină), iar `∅` e regulat. Un APD cu o stare și fără tranziții acceptă `∅`.', source=T2)
q(158, 'Par de a, impar de b mai mare', C5, 'medie',
  'Fie `L = {w ∈ {a, b}* | w are număr par de a și număr impar de b, mai mare decât numărul de a}`. Atunci:',
  'L nu este limbaj regulat', ['se poate scrie un AFN care acceptă L', 'șirul vid aparține lui L', 'orice prefix al unui cuvânt din L conține cel puțin un b'],
  'Comparația `#b > #a` cere numărare nemărginită (o stivă). `e ∉ L` (0 `b` nu e impar), iar `aabbb ∈ L` are prefixul `aa`.', source=T2)
q(159, 'AFD care acceptă tot ce are |w| ≤ k', C1, 'medie',
  'Un AFD peste un alfabet cu `|Σ| = 2` are `k > 2` stări și acceptă orice șir cu `|w| ≤ k`. Ce se poate spune despre `|L(M)|`?',
  '|L(M)| > 2ᵏ⁺²', ['|L(M)| ≤ 2ᵏ', '|L(M)| = 2ᵏ⁺¹ − 1', '|L(M)| = 2ᵏ⁺¹'],
  'Un cuvânt de lungime `k` trece prin `k + 1` stări, deci repetă una: e un ciclu pe un drum de acceptare, iar limbajul e infinit. Doar varianta care nu fixează o margine poate fi adevărată.', source=T2)
q(160, 'Câte stări finale pentru 3 șiruri', C1, 'ușoară',
  'Fie `M` un AFD care acceptă minim 3 șiruri. Numărul minim de stări finale ale automatului este:',
  '1', ['2', '3', 'niciuna dintre celelalte variante'],
  'O singură stare, inițială și finală, cu buclă pe fiecare simbol, acceptă `Σ*`.', source=T2)
q(161, 'Gramatică pe un alfabet unar', C5, 'grea',
  'Fie `G` o GIC cu `|Σ| = 1`. (i) `L(G)` e regulat; (ii) `L(G)` e independent de context; (iii) `L(G)` e finit.',
  'i) și ii) corecte', ['toate corecte', 'doar ii) corectă', 'doar i) și iii) corecte'],
  'Pe un alfabet unar contează doar lungimea, iar lema de pompare dă lungimi care formează o reuniune finită de progresii aritmetice: limbajul e regulat (teorema lui Parikh). `a*` arată că nu e neapărat finit.', source=T2)
q(162, 'L1 ∪ (Σ* \\ L3)', C5, 'medie',
  'Fie `L1, L2` regulate și `L3 ⊆ L1 ∩ L2` (oarecare). Ce se poate spune despre `L1 ∪ (Σ* \\ L3)`?',
  'trebuie să fie regulat', ['nu poate fi independent de context', 'poate să nu fie independent de context', 'este independent de context, dar nu regulat'],
  '`L3 ⊆ L1` ⇒ `Σ* \\ L1 ⊆ Σ* \\ L3` ⇒ `Σ* = L1 ∪ (Σ* \\ L1) ⊆ L1 ∪ (Σ* \\ L3)`. Deci reuniunea e `Σ*`.', source=T2)
q(163, 'Nimic acceptat, totul acceptat', C1, 'medie',
  'Fie `M1` un AFD care nu acceptă niciun șir și `M2` un AFD care acceptă orice șir din `Σ*`. Ce e întotdeauna adevărat?',
  'atât M1 cât și M2 pot avea stări finale', ['M1 nu are stări finale și M2 are cel puțin o stare finală', 'M1 poate avea stări finale și M2 nu are cicluri', 'M1 nu poate avea stări finale și M2 are cel puțin un ciclu'],
  '`M1` poate avea stări finale la care nu se ajunge din start. `M2` acceptă `e`, deci starea inițială e finală, și cuvinte oricât de lungi, deci are cicluri.', source=T2)
q(164, 'L ∩ LL pentru un LIC neregulat', C5, 'grea',
  'Fie `L` un limbaj independent de context care nu e regulat. Ce se poate spune despre `L ∩ LL`?',
  'poate să nu fie independent de context', ['nu poate fi regulat', 'este întotdeauna independent de context', 'are o infinitate de cuvinte'],
  'Exemplul din rezolvare: pentru `L = {wwᴿ}`, `L ∩ LL` conține palindroamele pare care sunt și concatenări de două palindroame pare, ca `wwᴿwwᴿ`; un astfel de limbaj nu e LIC, deci (a). Cu `L = {a, aa} ∪ {aⁿbⁿ | n > 0}`, `L ∩ LL = {aa}`: regulat și finit, deci (b) și (d) cad, iar (c) cade pe primul exemplu.', source=T2)
q(165, 'AFN cu un singur șir: tranziții', C2, 'ușoară',
  'Fie `M` un AFN care acceptă un singur șir. Numărul minim de tranziții pe care le poate avea automatul este:',
  'niciuna dintre celelalte variante (0)', ['1', '2', '4'],
  'O stare, inițială și finală, fără tranziții: acceptă doar `e`. Zero tranziții.', source=T2)

tf(170, 'L1L2 = L2L1 ⇒ L1 = L2', C5, 'ușoară', 'Adevărat sau fals?\n\nDacă `L1L2 = L2L1`, atunci `L1 = L2`.', False,
   '`L1 = ∅`, `L2 = Σ*`: ambele concatenări dau `∅`, dar limbajele diferă.', T3)
tf(171, 'L1L2 = L2L1 ⇒ (L1 ∪ L2)* ⊆ (L1 ∩ L2)*', C5, 'medie', 'Adevărat sau fals?\n\nDacă `L1L2 = L2L1`, atunci `(L1 ∪ L2)* ⊆ (L1 ∩ L2)*`.', False,
   'Cu `L1 = ∅`, `L2 = Σ*`: `(L1 ∪ L2)* = Σ*`, iar `(L1 ∩ L2)* = ∅* = {e}`.', T3)
q(172, 'Câte stele se pot scoate', C3, 'grea',
  'Fie expresia `(a*b*c* ∪ b ∪ c ∪ ab*)*a*` peste `{a, b, c}`. Care este numărul maxim de steluțe ce pot fi eliminate astfel încât limbajul să rămână același?',
  '3', ['1', '2', '4'],
  'Limbajul e `Σ*`. Ultimele două stele trebuie păstrate (fără ele lipsesc `cb`, respectiv cuvintele care nu se termină cu `a`). Sub steaua mare trebuie să apară `a`, `b`, `c`: `(abc ∪ b ∪ c ∪ ab*)*a*` mai acceptă `a` prin `ab*`, deci se pot scoate cele trei stele din `a*b*c*`.', source=T3)
tf(173, 'AFD-ul echivalent are mai multe stări', C2, 'ușoară', 'Adevărat sau fals?\n\nFie `M` un AFN și `M′` un AFD echivalent. `M′` are cel puțin la fel de multe stări ca `M`.', False,
   'Adăugăm în `M` oricâte stări inutile (inaccesibile): `M′` nu trebuie să le aibă.', T3)
q(174, 'S → Aa | Bb | e, A → Aa | B, B → Ba | S', C4, 'medie',
  'Ce limbaj generează gramatica `S -> Aa | Bb | e`, `A -> Aa | B`, `B -> Ba | S`?',
  '(a ∪ b)*', ['a*b*', '(ab)*', '∅'],
  '`A ⇒ B ⇒ S`, deci `S` poate deveni `Sa` și `Sb`: `S ⇒* Sa | Sb | e` generează orice cuvânt. Și nu generează nimic în afara lui `Σ*`.', source=T3)
q(175, 'L(A), L(B), L(S)', C4, 'grea',
  'Fie `S -> aBbB | BaAc`, `A -> aAa | e`, `B -> BABc | e`. Care este cel mai simplu tip de automat care acceptă `L(G)`?',
  'un automat finit', ['un automat push-down determinist', 'un automat push-down nedeterminist', 'o mașină Turing'],
  '`L(A) = (aa)*`, `L(B) = ((aa)*c)*`, `L(S) = a((aa)*c)*b((aa)*c)* ∪ ((aa)*c)*a(aa)*c`: regulat.', source=T3)
q(176, 'APD care schimbă stiva cu exact 1', CA, 'grea',
  'Fie `C` mulțimea APD-urilor nedeterministe la care după fiecare tranziție dimensiunea stivei crește sau scade cu exact 1. Care afirmație e adevărată?',
  'orice limbaj independent de context e acceptat de un automat din C', ['pentru orice automat din C există unul echivalent determinist', 'există APD-uri care nu au echivalent în C', 'C acceptă doar limbaje regulate'],
  'O tranziție care scoate/pune mai multe simboluri se sparge în mai multe tranziții pe `e` care scot/pun câte unul; una care nu schimbă stiva pune și scoate un simbol auxiliar. Deci `C` acceptă toate LIC. APD-urile deterministe nu acceptă toate LIC (`wwᴿ`).', source=T3)
q(177, 'Câte tranziții are un AFD', C1, 'ușoară',
  'Care este numărul minim de tranziții pe care le poate avea un AFD `(K, Σ, δ, s, F)`? Dar maxim?',
  'minim = maxim = |K| · |Σ|', ['minim 0, maxim |K| · |Σ|', 'minim |K|, maxim |K|²', 'minim 1, maxim |K|² · |Σ|'],
  '`δ : K × Σ → K` e o funcție totală: exact o tranziție pentru fiecare pereche (stare, simbol).', source=T3)

regex_in(180, 'Blocuri de 1 de lungime impară între zerouri', C3, 'grea',
         'Fie `Σ = {0, 1}`. Scrie o expresie regulată pentru `L = {w | ∀w1, w3 ∈ Σ*, w2 ∈ {1}*: w = w1 0 w2 0 w3 → |w2| e impar}` (între oricare două zerouri consecutive e un număr impar de `1`).',
         '01', lambda w: all((j - i - 1) % 2 == 1 for i in range(len(w)) for j in range(i + 1, len(w)) if w[i] == w[j] == '0' and set(w[i + 1:j]) <= {'1'}),
         '1*(ε∪0(1(11)*0)*1*)',
         hint='Între doi `0` consecutivi stă `1(11)*`; înainte de primul `0` și după ultimul, oricâți `1`.', source=MT1)
dfa_in(181, 'Nu se termină cu aba', C1, 'medie',
       'Fie `Σ = {a, b, c}`. Scrie un AFD pentru `L = Σ* \\ (Σ* ∘ {aba})`.', 'abc', lambda w: not w.endswith('aba'), None,
       hint='Construiește AFD-ul pentru „se termină cu `aba`” (stările: cât din `aba` e la coadă), apoi inversează stările finale.',
       solution='4 stări (`ε`, `a`, `ab`, `aba` la coadă); finale toate în afară de `aba`. Atenție la `c`: duce mereu în starea `ε`.', source=MT1)
q(182, 'Liste de limbaje regulate', CP, 'medie',
  'Fie `L1, L2` două limbaje regulate. Care listă conține doar limbaje regulate?',
  'L1 ∪ L2, (L1 \\ L2) ∪ (L2 \\ L1), L1 ∩ L2 ∘ ∅', ['L1 ∘ L2, L1 ∪ {0, 1}*, L1 × L2', 'L1*, 2^(L1∘L2), L2 ∘ L1', 'L2 × L1, L1 \\ L2, L2 \\ L1'],
  '`×` dă perechi de cuvinte, iar `2^X` o mulțime de limbaje: nu sunt limbaje. Reuniunea, diferența simetrică și `X ∘ ∅ = ∅` sunt regulate.', source=MT1)
q(183, 'Expresie mai lungă, limbaj mai mare?', C3, 'ușoară',
  'Fie `E1, E2` expresii regulate cu lungimile `l1 > l2`. Ce relație e între `|L(E1)|` și `|L(E2)|`?',
  'nu avem suficiente informații', ['|L1| = |L2|', '|L1| < |L2|', '|L1| > |L2|'],
  '`(a ∪ b)*` e scurtă și infinită, `aaaaaaa` e lungă și are un cuvânt; `∅∅∅∅∅` e lungă și vidă.', source=MT1)
q(184, 'AFD ⊆ AFN', C2, 'ușoară',
  'Sunt adevărate: (1) ∀M1 ∈ AFD, ∃M2 ∈ AFN, L(M2) = L(M1); (2) ∀M2 ∈ AFN, ∃M1 ∈ AFN, L(M1) = L(M2)?',
  'Da, Da', ['Nu, Nu', 'Da, Nu', 'Nu, Da'],
  'Orice AFD e un AFN; și orice AFN e echivalent cu el însuși.', source=MT1)
q(185, 'Cum e |Δ|', C2, 'ușoară',
  'Fie `M = (K, Σ, Δ, s, F)` un automat finit nedeterminist. Cum e `|Δ|`?',
  'finit și nemărginit superior', ['nu poate fi 0', 'poate fi infinit', 'finit și mărginit superior'],
  '`Δ` e finită prin definiție, dar `Δ ⊆ K × Σ* × K`, iar etichetele pot fi oricât de lungi: nicio margine. Și poate fi vidă.', source=MT1)

def _blocks2(w):
    m = re.fullmatch(r'((?:0+1+)+)(2+)', w)
    if not m:
        return False
    blocks = re.findall(r'(0+)(1+)', m[1])
    return all(len(a) == len(b) for a, b in blocks) and len(blocks) == len(m[2])


cfg_in(186, 'Σ1* minus cuvintele cu #a ≠ #b', C4, 'medie',
       'Fie `Σ0 = {a, b}`, `Σ1 = {a, b, c}`. Scrie o gramatică pentru `L = Σ1* \\ {w ∈ Σ0* | #a(w) ≠ #b(w)}`.',
       'abc', lambda w: 'c' in w or w.count('a') == w.count('b'), 'S -> T | XcX\nT -> aTbT | bTaT | ε\nX -> aX | bX | cX | ε', 7,
       hint='Ce rămâne în `L`: cuvintele care conțin un `c`, plus cuvintele peste `{a, b}` cu `#a = #b`.', source=MT2)
cfg_in(187, '0ⁿ¹1ⁿ¹ … 0ⁿᵏ1ⁿᵏ 2ᵏ', C4, 'grea',
       'Fie `Σ = {0, 1, 2}`. Scrie o gramatică pentru `L = {0ⁿ¹1ⁿ¹ ⋯ 0ⁿᵏ1ⁿᵏ 2ᵏ | nᵢ > 0, k > 0}`.',
       '012', lambda w: _blocks2(w), 'S -> XS2 | X2\nX -> 0X1 | 01', 10,
       hint='Câte un bloc `X = 0ⁿ1ⁿ` pentru fiecare `2` de la sfârșit: `S -> X S 2 | X 2`.', source=MT2)


q(188, 'Un APD dat ca tuplu', CA, 'medie',
  'Fie `M = ({s, p}, {a, b}, {a, b}, Δ, s, {s})` cu `Δ = {((s, a, e), (s, a)), ((s, b, e), (p, b)), ((p, a, a), (p, e)), ((p, b, b), (s, e))}`. Ce se poate spune despre `L(M)`?',
  'este regulat, dar nu finit', ['este vid', 'este finit, dar nu vid', 'este independent de context, dar nu regulat'],
  'Un `a` citit în `s` rămâne pe stivă și nu mai poate fi scos (din `p` se scoate `a` doar dacă e în vârf, dar acolo e `b`-ul abia pus). Singurele drumuri de acceptare: `b` (pune `b`, trece în `p`), `b` (scoate `b`, înapoi în `s`). Deci `L(M) = (bb)*`.', source=MT2)
q(189, 'S → SS | aS | bS', C4, 'ușoară',
  'Fie gramatica `S -> SS | aS | bS`. Este limbajul regulat? Dar gramatica?',
  'Da, Nu', ['Nu, Nu', 'Da, Da', 'Nu, Da'],
  'Nicio regulă nu se termină fără `S`: `L(G) = ∅`, regulat. Gramatica nu e regulată (`S -> SS`).', source=MT2)
q(190, 'Complementul unui LIC e regulat', C5, 'ușoară',
  'Fie `L0` un LIC și `L1 = Σ* \\ L0` regulat. Care afirmație e adevărată?',
  'L0 este regulat', ['L0 nu poate fi finit', 'L1 nu poate fi regulat', 'L1 nu poate fi finit'],
  '`L0 = Σ* \\ L1`, complementul unui limbaj regulat.', source=MT2)

q(191, 'Limbaje regulate peste {a}', C5, 'ușoară',
  'Mulțimea limbajelor regulate peste alfabetul `Σ = {a}` este:',
  'infinit numărabilă', ['finită', 'nenumărabilă', 'cu exact 2^|Σ| elemente'],
  'Fiecare `{aⁿ}` e regulat, deci sunt infinit de multe; fiecare are o expresie regulată (un șir finit), deci sunt numărabile.', source=REC17)
q(192, 'aⁿbⁿ⁺ᵏcᵏ', C5, 'ușoară',
  'Cum este `L = {aⁿbⁿ⁺ᵏcᵏ | k, n ∈ N}`?',
  'independent de context, dar nu regulat', ['regulat', 'nu este independent de context', 'finit'],
  '`aⁿbⁿ · bᵏcᵏ`, concatenarea a două LIC. Intersectat cu `a*b*` dă `aⁿbⁿ`, deci nu e regulat.', source=REC17)
cfg_in(193, 'Palindroame în raport cu b', C4, 'medie',
       'Fie `Σ = {a, b, c}`. Scrie o gramatică pentru `L = {w | ∀i ≤ |w|: w(i) = b ↔ w(|w| + 1 − i) = b}` (pozițiile lui `b` sunt simetrice; `abc ∈ L`).',
       'abc', lambda w: all((w[i] == 'b') == (w[len(w) - 1 - i] == 'b') for i in range(len(w))),
       'S -> bSb | XSX | a | b | c | ε\nX -> a | c', 7,
       hint='La capete: fie `b … b`, fie două simboluri care nu sunt `b` (oricare, nu neapărat egale).', source=REC17)
q(194, 'Câte limbaje cu două reguli', C4, 'grea',
  'Fie `J = {(V, Σ, R, S) ∈ GIC | |R| = 2}`. Care este cardinalul mulțimii `M = {|L(G)| | G ∈ J}`?',
  '4: |L(G)| poate fi 0, 1, 2 sau infinit', ['3', '2', 'infinit'],
  '`S -> aS | bS` dă `∅` (0 cuvinte), `S -> a | S` dă `{a}` (1), `S -> a | b` dă 2, `S -> aS | e` dă infinit. Un limbaj finit cu 3 sau mai multe cuvinte nu se poate: fără recursie, fiecare regulă contribuie cu cel mult un cuvânt, iar cu recursie (care se poate termina) limbajul e infinit. Deci `M = {0, 1, 2, ∞}`.', source=REC17)
cfg_in(195, 'Începe și se termină cu același simbol', C4, 'ușoară',
       'Construiește o gramatică pentru `L = {w ∈ {0, 1}* | w ≠ e, w începe și se termină cu același simbol}`.',
       '01', lambda w: len(w) > 0 and w[0] == w[-1], 'S -> 0X0 | 1X1 | 0 | 1\nX -> 0X | 1X | ε', 8, source=REC17)
q(196, 'Răsturnatul unui limbaj decidabil', C5, 'ușoară',
  'Fie `L` un limbaj Turing decidabil. Este `Lᴿ = {wᴿ | w ∈ L}` Turing decidabil?',
  'da', ['nu', 'doar dacă L e regulat', 'e doar Turing acceptat'],
  'Mașina pentru `Lᴿ` întoarce cuvântul de pe bandă, apoi rulează mașina care decide `L`, care se oprește mereu.', source=REC17)
q(197, 'Mașini care acceptă cel puțin 65536 de șiruri', C5, 'grea',
  'Fie `L = {ρ(M) | M e o mașină Turing care acceptă cel puțin 65536 de șiruri}`. Cum este `L`?',
  'Turing acceptat, dar nu decidabil', ['Turing decidabil', 'nu este Turing acceptat', 'regulat'],
  'Acceptat: rulăm `M` în paralel (dovetailing) pe toate cuvintele și acceptăm când am văzut 65536 acceptate. Nedecidabil: e o proprietate netrivială a limbajului lui `M` (teorema lui Rice).', source=REC17)
q(198, 'Nedecidabil și NP-complet', C5, 'medie',
  'Este posibil ca un limbaj nedecidabil să fie NP-complet?',
  'nu: orice limbaj din NP e decidabil', ['da', 'doar dacă P = NP', 'nu se știe'],
  'Un limbaj NP-complet e în NP, deci decidabil (mașina nedeterministă polinomială se poate simula determinist, în timp exponențial).', source=REC17)

# =============================================================================
# Pushdown automata (checked by running them on every word up to a length)
# =============================================================================
pda_problem(200, 'aⁿbⁿ', 'ușoară', 'Construiește un automat cu stivă pentru `{aⁿbⁿ | n ≥ 0}`.\n\nAcceptarea e ca în curs: tot cuvântul citit, o stare finală, stiva goală.',
            'ab', lambda w: w == 'a' * (len(w) // 2) + 'b' * (len(w) // 2),
            'start p\nfinal q\np, a, ε -> p, A\np, ε, ε -> q, ε\nq, b, A -> q, ε',
            hint='Fiecare `a` pune un `A` pe stivă; la primul `b` treci în altă stare, unde fiecare `b` scoate un `A`.',
            solution='Două stări: `p` (citește `a` și pune `A`), `q` (finală; citește `b` și scoate `A`), și `((p, e, e), (q, e))` ca să treacă dintr-una în alta. Stiva goală la sfârșit înseamnă exact atâția `b` câți `a`.')
pda_problem(201, 'wcwᴿ', 'ușoară', 'Construiește un automat cu stivă peste `{a, b, c}` pentru `{wcwᴿ | w ∈ {a, b}*}`.',
            'abc', lambda w: w.count('c') == 1 and w.split('c')[0] == w.split('c')[1][::-1],
            'start p\nfinal q\np, a, ε -> p, a\np, b, ε -> p, b\np, c, ε -> q, ε\nq, a, a -> q, ε\nq, b, b -> q, ε', up_to=7,
            hint='Exemplul din curs: pune pe stivă ce citești până la `c`, apoi scoate câte un simbol egal cu cel citit.')
pda_problem(202, 'wwᴿ (palindroame pare)', 'medie', 'Construiește un automat cu stivă pentru `{wwᴿ | w ∈ {a, b}*}`.',
            'ab', lambda w: len(w) % 2 == 0 and w == w[::-1],
            'start p\nfinal q\np, a, ε -> p, a\np, b, ε -> p, b\np, ε, ε -> q, ε\nq, a, a -> q, ε\nq, b, b -> q, ε',
            hint='Ca la `wcwᴿ`, doar că mijlocul nu e marcat: automatul îl „ghicește” cu o tranziție pe `e`.',
            solution='Nedeterminismul alege momentul în care se trece de la „pun” la „scot”; dacă alegerea e bună pentru un palindrom, drumul se termină cu stiva goală. Nu există un APD **determinist** pentru limbajul acesta.')
pda_problem(203, 'La fel de mulți a și b', 'medie', 'Construiește un automat cu stivă pentru cuvintele peste `{a, b}` cu `#a(w) = #b(w)`.',
            'ab', lambda w: w.count('a') == w.count('b'),
            'start q\nfinal q\nq, a, ε -> q, A\nq, b, A -> q, ε\nq, b, ε -> q, B\nq, a, B -> q, ε',
            hint='Stiva ține diferența: câți `a` (sau câți `b`) sunt în plus până acum. Un simbol opus vârfului îl anulează.',
            solution='O stare, finală. `a` pune `A` sau scoate un `B`; `b` pune `B` sau scoate un `A`. Nedeterminismul poate și pune un `A` peste un `B`, dar atunci stiva nu se mai golește corect pe drumul acela; un drum bun există mereu.')
pda_problem(204, 'aⁿbᵐ cu n ≠ m', 'medie', 'Definește un APD care acceptă `{aⁿbᵐ | n, m ≥ 0, n ≠ m}`.',
            'ab', lambda w: re.fullmatch('a*b*', w) and w.count('a') != w.count('b'),
            'start i\nfinal f\ni, ε, ε -> p, Z\np, a, ε -> p, A\np, ε, ε -> q, ε\nq, b, A -> q, ε\nq, ε, A -> r, ε\nr, ε, A -> r, ε\nr, ε, Z -> f, ε\nq, b, Z -> s, Z\ns, b, Z -> s, Z\ns, ε, Z -> f, ε',
            hint='Potrivește `a`-uri cu `b`-uri; apoi, fie mai rămân `A` pe stivă (mai mulți `a`), fie mai vin `b` (mai mulți `b`). Ca să știi că stiva s-a golit, pune la început un semn de fund, `Z`.',
            solution='`i` pune fundul `Z`; `p` pune `A` pentru fiecare `a`; `q` scoate câte un `A` la fiecare `b`. Mai mulți `a`: din `q` scoate încă un `A` și trece în `r`, care golește stiva până la `Z` și intră în `f`. Mai mulți `b`: un `b` citit când vârful e `Z` trece în `s`, care citește restul de `b`, apoi scoate `Z` și intră în `f`. Fără `Z`, automatul n-ar putea vedea că s-au terminat `A`-urile și ar accepta `ab`.', source=PS)
_G205 = grammar_words('S -> aAA\nA -> aS | bS | a', 8)
pda_problem(205, 'APD pentru S → aAA, A → aS | bS | a', 'medie',
            'Fie gramatica `S -> aAA`, `A -> aS | bS | a`. Construiește un APD care acceptă `L(G)`.',
            'ab', lambda w: w in _G205,
            'start p\nfinal q\np, ε, ε -> q, S\nq, ε, S -> q, aAA\nq, ε, A -> q, aS\nq, ε, A -> q, bS\nq, ε, A -> q, a\nq, a, a -> q, ε\nq, b, b -> q, ε',
            hint='Construcția din curs (GIC → APD): două stări; pune `S`, apoi în `q` înlocuiește un neterminal din vârf cu partea dreaptă a unei reguli, sau scoate un terminal egal cu cel citit.',
            solution='`M = ({p, q}, Σ, V, Δ, p, {q})` cu `((p, e, e), (q, S))`, `((q, e, A), (q, α))` pentru fiecare regulă `A → α`, și `((q, a, a), (q, e))` pentru fiecare terminal. Automatul simulează o derivare stânga: pe stivă e restul formei propoziționale.', source=E22c)
pda_problem(206, '#a(w1) = #b(w2)', 'grea',
            'Definește un APD care acceptă `{w1w2 ∈ {a, b}* | #a(w1) = #b(w2)}`.',
            'ab', lambda w: any(w[:i].count('a') == w[i:].count('b') for i in range(len(w) + 1)),
            'start q\nfinal q\nq, a, ε -> q, ε\nq, b, ε -> q, ε',
            hint='Încearcă pe câteva cuvinte: există mereu o împărțire potrivită? Mută tăietura câte o poziție și urmărește `#a(w1) − #b(w2)`.',
            solution='Limbajul e `Σ*`. Fie `f(i) = #a(w[..i]) − #b(w[i..])`. `f(0) = −#b(w) ≤ 0`, `f(|w|) = #a(w) ≥ 0`, iar mutând tăietura cu o poziție `f` crește cu exact 1 (un `a` trece în `w1` sau un `b` iese din `w2`). Deci `f` ajunge la 0. Un APD cu o stare finală care citește orice ajunge.', source=PS)
pda_problem(207, 'Paranteze bine închise', 'ușoară', 'Notăm `(` cu `a` și `)` cu `b`. Construiește un automat cu stivă pentru șirurile de paranteze bine închise.',
            'ab', lambda w: w.count('a') == w.count('b') and all(w[:i].count('a') >= w[:i].count('b') for i in range(len(w) + 1)),
            'start q\nfinal q\nq, a, ε -> q, X\nq, b, X -> q, ε', hint='O stare: `a` pune, `b` scoate. Ce se întâmplă cu un `b` când stiva e goală?')
pda_problem(208, 'aⁿb²ⁿ', 'ușoară', 'Construiește un automat cu stivă pentru `{aⁿb²ⁿ | n ≥ 0}`.',
            'ab', lambda w: w == 'a' * (len(w) // 3) + 'b' * (2 * len(w) // 3) and len(w) % 3 == 0,
            'start p\nfinal q\np, a, ε -> p, AA\np, ε, ε -> q, ε\nq, b, A -> q, ε', hint='Fiecare `a` pune **doi** `A`.')
pda_problem(209, 'aⁱbʲcᵏ cu i = j sau j = k', 'grea', 'Construiește un automat cu stivă pentru `{aⁱbʲcᵏ | i = j sau j = k}`.',
            'abc', lambda w: re.fullmatch('a*b*c*', w) and (w.count('a') == w.count('b') or w.count('b') == w.count('c')),
            'start s\nfinal f u\ns, ε, ε -> p, ε\np, a, ε -> p, A\np, ε, ε -> q, ε\nq, b, A -> q, ε\nq, ε, ε -> f, ε\nf, c, ε -> f, ε\ns, ε, ε -> r, ε\nr, a, ε -> r, ε\nr, ε, ε -> t, ε\nt, b, ε -> t, B\nt, ε, ε -> u, ε\nu, c, B -> u, ε',
            up_to=7, hint='Ghicește de la început care egalitate verifici: două „ramuri”, una care compară `a` cu `b`, alta `b` cu `c`.')
pda_problem(210, 'Blocuri 0ⁿ1ⁿ, apoi atâția de 2 câte blocuri', 'grea',
            'Construiește un automat cu stivă pentru `L = {0ⁿ¹1ⁿ¹ ⋯ 0ⁿᵏ1ⁿᵏ 2ᵏ | nᵢ > 0, k > 0}`.',
            '012', _blocks2,
            'start p\nfinal r\np, 0, ε -> p, A\np, 1, A -> q, ε\nq, 1, A -> q, ε\nq, ε, ε -> m, B\nm, 0, ε -> p, A\nm, 2, B -> r, ε\nr, 2, B -> r, ε',
            up_to=8, hint='În interiorul unui bloc, stiva compară `0`-urile cu `1`-urile. După fiecare bloc lasă pe stivă un semn `B`; `2`-urile scot semnele.',
            solution='`p` pune `A` pentru fiecare `0`; primul `1` trece în `q`, unde fiecare `1` scoate un `A`. Când blocul e închis (vârful nu mai e `A`… nedeterminist: oricând), `q —e/B→ m` lasă un `B`. Din `m` începe alt bloc (`0`) sau încep `2`-urile, care scot câte un `B`. Un `B` pus prea devreme lasă `A`-uri dedesubt, iar drumul acela nu se mai golește.', source=MT2)
pda_problem(211, 'Palindroame', 'medie', 'Construiește un automat cu stivă pentru palindroamele peste `{a, b}` (și cele de lungime impară).',
            'ab', lambda w: w == w[::-1],
            'start p\nfinal q\np, a, ε -> p, a\np, b, ε -> p, b\np, ε, ε -> q, ε\np, a, ε -> q, ε\np, b, ε -> q, ε\nq, a, a -> q, ε\nq, b, b -> q, ε',
            hint='Ca la `wwᴿ`, dar mijlocul poate fi și un simbol citit fără să fie pus pe stivă.')

# =============================================================================
# Turing machines (acceptors and machines that compute; run on every input up to a length)
# =============================================================================
TM_NOTE = '\n\nConvenția aplicației: banda e plină de blancuri `#` de o parte și de alta a intrării, capul pornește pe primul simbol al intrării (pe `#` dacă intrarea e vidă). Starea `h` (sau `y`) acceptă și oprește; `n` respinge; o tranziție lipsă respinge.'
tm_problem(220, 'aⁿbⁿ cu n ≥ 1', 'medie', 'Scrie o mașină Turing care acceptă limbajul `{aⁿbⁿ | n ≥ 1}`.' + TM_NOTE,
           'ab', lambda w: len(w) >= 2 and w == 'a' * (len(w) // 2) + 'b' * (len(w) // 2),
           'q0, a -> q1, A, R\nq0, B -> q3, B, R\nq1, a -> q1, a, R\nq1, B -> q1, B, R\nq1, b -> q2, B, L\nq2, a -> q2, a, L\nq2, B -> q2, B, L\nq2, A -> q0, A, R\nq3, B -> q3, B, R\nq3, # -> h, #, S',
           hint='Marchează primul `a` nemarcat (`A`), mergi la dreapta la primul `b` nemarcat și marchează-l (`B`), întoarce-te. Când nu mai sunt `a`-uri, verifică să nu mai fie nici `b`-uri.',
           solution='Mașina din set: `q0` marchează un `a` cu `A`; `q1` caută la dreapta primul `b` și îl face `B`; `q2` se întoarce la ultimul `A`; când în `q0` găsește `B`, toate `a`-urile sunt marcate, iar `q3` verifică că urmează doar `B`-uri până la blanc.', source=PS)
tm_problem(221, 'Adună 1 în baza 2', 'ușoară', 'Scrie o mașină Turing care primește un număr în baza 2 (nevid) și lasă pe bandă numărul plus 1.' + TM_NOTE,
           '01', None, 'q0, 0 -> q0, 0, R\nq0, 1 -> q0, 1, R\nq0, # -> q1, #, L\nq1, 1 -> q1, 0, L\nq1, 0 -> h, 1, S\nq1, # -> h, 1, S',
           up_to=6, fun=lambda w: format(int(w, 2) + 1, 'b').zfill(len(w)) if w else '1',
           hint='Mergi la ultima cifră; de acolo, spre stânga, fiecare `1` devine `0` (transportul) până la primul `0` (sau blanc), care devine `1`.')
P[-1]['statement'] += '\n\n(Numărul își păstrează lungimea, cu zerourile de la început, dacă nu crește: `0011` devine `0100`, `11` devine `100`. Pentru intrarea vidă se lasă `1`.)'
tm_problem(223, 'Număr par de a', 'ușoară', 'Scrie o mașină Turing care acceptă cuvintele peste `{a, b}` cu un număr par de `a`.' + TM_NOTE,
           'ab', lambda w: w.count('a') % 2 == 0,
           'p, a -> i, a, R\np, b -> p, b, R\np, # -> h, #, S\ni, a -> p, a, R\ni, b -> i, b, R\ni, # -> n, #, S',
           hint='Un automat finit e o mașină Turing care doar merge la dreapta: două stări pentru paritate, iar la blanc decide.')
tm_problem(224, 'Palindroame', 'grea', 'Scrie o mașină Turing care acceptă palindroamele peste `{a, b}`.' + TM_NOTE,
           'ab', lambda w: w == w[::-1],
           'q0, a -> qa, #, R\nq0, b -> qb, #, R\nq0, # -> h, #, S\nqa, a -> qa, a, R\nqa, b -> qa, b, R\nqa, # -> ra, #, L\nqb, a -> qb, a, R\nqb, b -> qb, b, R\nqb, # -> rb, #, L\nra, a -> back, #, L\nra, # -> h, #, S\nrb, b -> back, #, L\nrb, # -> h, #, S\nback, a -> back, a, L\nback, b -> back, b, L\nback, # -> q0, #, R',
           up_to=7, hint='Șterge primul simbol ținându-l minte în stare, mergi la ultimul, compară și șterge-l, întoarce-te. Repetă.')
tm_problem(225, 'aⁿbⁿcⁿ', 'grea', 'Scrie o mașină Turing care acceptă `{aⁿbⁿcⁿ | n ≥ 0}` (un limbaj care nu e independent de context, dar e decidabil).' + TM_NOTE,
           'abc', lambda w: w == 'a' * (len(w) // 3) + 'b' * (len(w) // 3) + 'c' * (len(w) // 3) and len(w) % 3 == 0,
           'q0, a -> q1, X, R\nq0, Y -> q4, Y, R\nq0, # -> h, #, S\nq1, a -> q1, a, R\nq1, Y -> q1, Y, R\nq1, b -> q2, Y, R\nq2, b -> q2, b, R\nq2, Z -> q2, Z, R\nq2, c -> q3, Z, L\nq3, a -> q3, a, L\nq3, b -> q3, b, L\nq3, Y -> q3, Y, L\nq3, Z -> q3, Z, L\nq3, X -> q0, X, R\nq4, Y -> q4, Y, R\nq4, Z -> q4, Z, R\nq4, # -> h, #, S',
           up_to=7, hint='Ca la `aⁿbⁿ`, dar o trecere marchează câte un `a` (`X`), un `b` (`Y`) și un `c` (`Z`).')
tm_problem(226, 'Dublează aⁿ', 'grea', 'Intrarea e `aⁿ`. Scrie o mașină Turing care lasă pe bandă `a²ⁿ`.' + TM_NOTE,
           'a', None,
           'q0, a -> q1, A, R\nq0, B -> q3, a, R\nq0, # -> h, #, S\nq1, a -> q1, a, R\nq1, B -> q1, B, R\nq1, # -> q2, B, L\nq2, a -> q2, a, L\nq2, B -> q2, B, L\nq2, A -> q0, a, R\nq3, B -> q3, a, R\nq3, # -> h, #, S',
           up_to=6, fun=lambda w: 'a' * (2 * len(w)),
           hint='Pentru fiecare `a` (marcat temporar), scrie un `B` la capătul din dreapta. La sfârșit, toate `B`-urile devin `a`.')
tm_problem(227, 'Inversează biții', 'ușoară', 'Scrie o mașină Turing care înlocuiește fiecare `0` cu `1` și fiecare `1` cu `0`.' + TM_NOTE,
           '01', None, 'q, 0 -> q, 1, R\nq, 1 -> q, 0, R\nq, # -> h, #, S', up_to=6, fun=lambda w: w.translate(str.maketrans('01', '10')),
           hint='O singură stare care merge la dreapta.')
tm_problem(228, 'Ca în curs: scrie sau mută', 'medie',
           'În curs, o tranziție a mașinii Turing face **fie** o scriere, **fie** o mutare: `δ(q, a) = (p, b)` sau `δ(q, a) = (p, L)`. În aplicație le scrii `q, a -> p, b` și `q, a -> p, L`.\n\nScrie, în acest stil, o mașină care acceptă cuvintele peste `{a, b}` care se termină cu `b`.' + TM_NOTE,
           'ab', lambda w: w.endswith('b'),
           'q0, a -> q0, R\nq0, b -> q0, R\nq0, # -> q1, L\nq1, b -> h, b\nq1, a -> n, a\nq1, # -> n, #',
           hint='Mergi la dreapta până la blanc, apoi un pas la stânga și uită-te la simbol.')

# =============================================================================
# The Moodle multiple-choice questions (exam and tests, 2021-2023) whose formulas came
# through as TeX: tool/acs/data/lfa_grile.json, answers as marked by Moodle
# =============================================================================
from common import load_grile, quiz_multi, title_of

TEX_PLAIN = [(r'\mathcal {L}', 'L'), (r'\mathcal{L}', 'L'), (r'\rho', 'ρ'), (r'\mid', '|'), (r'\{', '{'), (r'\}', '}'), (r'\notin', '∉'), (r'\in', '∈'),
             (r'\cup', '∪'), (r'\cap', '∩'), (r'\Sigma', 'Σ'), (r'\emptyset', '∅'), (r'\phi', '∅'), (r'\geq', '≥'), (r'\leq', '≤'), (r'\neq', '≠'),
             (r'\rightarrow', '→'), (r'\Rightarrow', '⇒'), (r'\wedge', '∧'), (r'\vee', '∨'), (r'\setminus', '\\'), (r'\backslash', '\\'), (r'\subseteq', '⊆'),
             (r'\subset', '⊂'), (r'\forall', '∀'), (r'\exists', '∃'), (r'\cdot', '·'), (r'\overline', ''), (r'\Delta', 'Δ'), (r'\delta', 'δ'), (r'\Gamma', 'Γ'),
             (r'\infty', '∞'), (r'\#', '#'), (r'\%', '%'), (r'\textit', ''), (r'\sum', 'Σ'), (r'\limits', ''), (r'\,', ' ')]


TEX_PLAIN.sort(key=lambda p: -len(p[0]))


def tex_plain(t):
    def one(m):
        x = m.group(1)
        for a, b in TEX_PLAIN:
            x = x.replace(a, b)
        x = re.sub(r'\^\{([^{}]*)\}', r'^\1', x)
        x = re.sub(r'_\{([^{}]*)\}', r'\1', x)
        x = re.sub(r'\\[a-zA-Z]+', '', x)
        x = x.replace('^*', '*').replace('^R', 'ᴿ').replace('^n', 'ⁿ').replace('^m', 'ᵐ').replace('^i', 'ⁱ').replace('^j', 'ʲ').replace('^k', 'ᵏ').replace('^p', 'ᵖ').replace('^2', '²')
        x = re.sub(r'_(\w)', r'\1', x).replace('{', '{').replace(' (', '(')
        return re.sub(r'\s+', ' ', x).strip()
    return re.sub(r'\$([^$]*)\$', one, t)


def wrap_tex(t, longest=30):
    """A long inline formula can't break across lines: cut it into several at the top level,
    before \\mid, =, \\in, \\Rightarrow or after a comma, never inside a group or inside a
    set nested in another one (\\{ and \\} are symbols, not groups, so a cut inside the outer
    set is still valid TeX)."""
    def cut(m):
        x = m.group(1)
        if len(x) <= longest:
            return m.group(0)
        parts, depth, sets, cur, i = [], 0, 0, '', 0
        while i < len(x):
            c = x[i]
            if c == '\\' and i + 1 < len(x):
                tok = re.match(r'\\([a-zA-Z]+|.)', x[i:])[0]
                if tok == '\\{': sets += 1
                if tok == '\\}': sets -= 1
                if depth == 0 and sets <= 1 and tok in ('\\mid', '\\Rightarrow', '\\subseteq') and len(cur) >= 10:
                    parts.append(cur); cur = ''
                cur += tok; i += len(tok); continue
            if c == '{': depth += 1
            if c == '}': depth -= 1
            cur += c; i += 1
            if depth == 0 and sets <= 1 and c in ',=' and len(cur) >= 14 and i < len(x) and x[i] == ' ':
                parts.append(cur); cur = ''
        parts.append(cur)
        return ' '.join(f'${p_.strip()}$' for p_ in parts if p_.strip())
    return re.sub(r'\$([^$]*)\$', cut, t)


_gid = 300
for it in load_grile('lfa_grile'):
    it['q'] = re.sub(r' ([1-9])\. (?=\$)', r'\n\1) ', wrap_tex(it['q']))
    it['options'] = [wrap_tex(o) for o in it['options']]
    q = it['q']
    title = title_of(tex_plain(q.split('\n')[0] if q.startswith(('Alegeti valo', 'Stabiliti valo')) else q))
    if title.startswith('Alegeti valo') or title.startswith('Stabiliti valo'):
        title = 'Adevărat/fals: ' + tex_plain(q.split('\n')[1].lstrip('- '))[:40].rstrip() + '…'
    right = it['right']
    sol = 'Răspunsul corect (după grila de pe Moodle): ' + '; '.join(f'„{it["options"][r]}”' for r in right) + '.'
    P.append(quiz_multi(_gid, title, CG, 'medie', q, it['options'], right, solution=sol, source=it['source']))
    _gid += 1
