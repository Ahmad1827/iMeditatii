"""LFA — Limbaje Formale și Automate: automata, regular expressions and grammars, checked as languages.

Topics and several statements from the LFA exams and tests (seria CA/CD, 2021-2022).
Every language is also written here as a Python predicate; the regular
expression (or automaton, or grammar) the app compares against is checked
against that predicate on every word up to a length, so the reference is the
language the statement describes.
"""
import itertools, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, quiz_multi, write_course

C1 = '1. Automate finite deterministe'
C2 = '2. Automate nedeterministe'
C3 = '3. Expresii regulate'
C4 = '4. Gramatici independente de context'
C5 = '5. Clase de limbaje'
C6 = '6. Grile: modelul de test'
CHAPTERS = [C1, C2, C3, C4, C5, C6]
MODEL = 'Model test grilă LFA'
EX = 'Examen LFA'
P = []


def words(alphabet, n):
    for k in range(n + 1):
        for t in itertools.product(alphabet, repeat=k):
            yield ''.join(t)


def py_regex(r):
    return re.compile(r.replace(' ', '').replace('∪', '|').replace('ε', '(?:)').replace('∅', '(?!)'))


def check_regex(id, r, alphabet, pred, n=9):
    c = py_regex(r)
    for w in words(alphabet, n):
        assert bool(c.fullmatch(w)) == bool(pred(w)), f'{id}: the expression {r} is wrong on {w!r}'


def nfa_accepts(a, w):
    def closure(s):
        s, todo = set(s), list(s)
        while todo:
            for t in a['t'].get(str(todo.pop()), {}).get('ε', []):
                if t not in s:
                    s.add(t); todo.append(t)
        return s
    cur = closure({0})
    for ch in w:
        cur = closure({t for s in cur for t in a['t'].get(str(s), {}).get(ch, [])})
    return any(s in a['final'] for s in cur)


def table(n, final, rows):
    """rows: 'state symbol targets...' lines -> the app's automaton json."""
    t = {}
    for line in rows.strip().split('\n'):
        s, sym, *to = line.split()
        t.setdefault(s, {})[sym] = sorted(int(x) for x in to)
    return {'states': n, 'final': sorted(final), 't': t}


def check_auto(id, a, alphabet, pred, n=9):
    for w in words(alphabet, n):
        assert nfa_accepts(a, w) == bool(pred(w)), f'{id}: the automaton is wrong on {w!r}'


def grammar_words(text, n):
    rules, start = {}, None
    for line in text.strip().split('\n'):
        left, right = line.replace(' ', '').split('->')
        start = start or left
        rules.setdefault(left, []).extend(alt.replace('ε', '') for alt in right.split('|'))
    lang = {a: set() for a in rules}
    changed = True
    while changed:
        changed = False
        for a, alts in rules.items():
            for alt in alts:
                acc = {''}
                for ch in alt:
                    part = lang[ch] if ch in lang else {ch}
                    acc = {x + y for x in acc for y in part if len(x) + len(y) <= n}
                if not acc <= lang[a]:
                    lang[a] |= acc; changed = True
    return lang[start]


def check_grammar(id, g, alphabet, pred, n):
    got = grammar_words(g, n)
    for w in words(alphabet, n):
        assert (w in got) == bool(pred(w)), f'{id}: the grammar is wrong on {w!r}'


def auto(id, title, ch, diff, statement, alphabet, pred, regex, ref, mode='dfa', max_states=None, hint='', solution='', source='', lang_auto=None):
    spec = {'mode': mode, 'alphabet': alphabet, 'reference': ref}
    if regex:
        check_regex(id, regex, alphabet, pred)
        spec['regex'] = regex
    else:
        check_auto(id, lang_auto, alphabet, pred)
        spec['automaton'] = lang_auto
    check_auto(id, ref, alphabet, pred)
    if mode == 'dfa':
        for s in range(ref['states']):
            for a in alphabet:
                assert len(ref['t'].get(str(s), {}).get(a, [])) == 1, (id, 'reference not deterministic', s, a)
    if max_states:
        assert ref['states'] <= max_states, id
        spec['maxStates'] = max_states
    P.append(problem(id, title, ch, diff, statement, 'lfa', spec, hint, solution, source))


def regex(id, title, diff, statement, alphabet, pred, ref, max_len=None, hint='', solution='', source='', truth=None):
    check_regex(id, ref, alphabet, pred)
    spec = {'mode': 'regex', 'alphabet': alphabet, 'regex': truth or ref, 'reference': ref}
    if truth:
        check_regex(id, truth, alphabet, pred)
    if max_len:
        assert len(ref.replace(' ', '')) <= max_len, id
        spec['maxLen'] = max_len
    P.append(problem(id, title, C3, diff, statement, 'lfa', spec, hint, solution or f'O expresie care merge: `{ref}`.', source))


def cfg(id, title, diff, statement, alphabet, pred, ref, up_to, chomsky=False, hint='', solution='', source='', starter=''):
    check_grammar(id, ref, alphabet, pred, up_to)
    spec = {'mode': 'cfg', 'alphabet': alphabet, 'grammar': ref, 'upTo': up_to, 'reference': ref}
    if chomsky:
        spec['chomsky'] = True
    if starter:
        spec['starter'] = starter
    P.append(problem(id, title, C4, diff, statement, 'lfa', spec, hint, solution or 'O gramatică care merge:\n' + '\n'.join(f'`{l.strip()}`' for l in ref.strip().split('\n')), source))


# ---------------------------------------------------------------- 1. AFD
auto(1, 'Se termină cu ab', C1, 'ușoară',
     'Construiește un automat finit determinist peste `{a, b}` care acceptă cuvintele ce se termină cu `ab`.',
     'ab', lambda w: w.endswith('ab'), '(a∪b)*ab',
     table(3, [2], '0 a 1\n0 b 0\n1 a 1\n1 b 2\n2 a 1\n2 b 0'),
     hint='Ține minte cât din `ab` ai văzut la sfârșitul a ceea ce ai citit: nimic, `a`, sau `ab`.',
     solution='Trei stări: `q0` (nimic), `q1` (ultimul simbol e `a`), `q2` (ultimele două sunt `ab`, finală). Din orice stare, `a` duce în `q1`; `b` duce din `q1` în `q2` și altfel în `q0`.')

auto(2, 'Număr par de a', C1, 'ușoară',
     'Construiește un AFD peste `{a, b}` care acceptă cuvintele cu un număr par de simboluri `a` (zero e par).',
     'ab', lambda w: w.count('a') % 2 == 0, '(b*ab*a)*b*',
     table(2, [0], '0 a 1\n0 b 0\n1 a 0\n1 b 1'), max_states=2,
     hint='Starea ține minte doar paritatea lui `#a`; `b` nu schimbă nimic.',
     solution='Două stări: `q0` (par, finală) și `q1` (impar). `a` trece de la una la alta, `b` rămâne pe loc.')

auto(3, 'Conține aa', C1, 'ușoară',
     'Construiește un AFD peste `{a, b}` care acceptă cuvintele ce conțin subșirul `aa`.',
     'ab', lambda w: 'aa' in w, '(a∪b)*aa(a∪b)*',
     table(3, [2], '0 a 1\n0 b 0\n1 a 2\n1 b 0\n2 a 2\n2 b 2'),
     hint='Odată găsit `aa`, cuvântul rămâne acceptat orice ar urma: starea finală se întoarce în ea însăși.',
     solution='`q0`: nu am un `a` la coadă; `q1`: tocmai am citit un `a`; `q2`: am văzut `aa` (finală, cu bucle pe `a` și `b`).')

auto(4, 'Nu conține aa', C1, 'medie',
     'Construiește un AFD peste `{a, b}` care acceptă cuvintele ce **nu** conțin subșirul `aa`.',
     'ab', lambda w: 'aa' not in w, '(b∪ab)*(a∪ε)',
     table(3, [0, 1], '0 a 1\n0 b 0\n1 a 2\n1 b 0\n2 a 2\n2 b 2'),
     hint='Ia automatul pentru „conține `aa`” și schimbă între ele stările finale cu cele nefinale. Merge pentru că e determinist și complet.',
     solution='Complementul unui limbaj regulat: același AFD ca la „conține `aa`”, cu finalele inversate: `q0` și `q1` finale, `q2` (groapa) nefinală.')

auto(5, 'Numărul de a, multiplu de 3', C1, 'medie',
     'Construiește un AFD cu cel mult 3 stări peste `{a, b}` care acceptă cuvintele în care numărul de `a` este multiplu de 3.',
     'ab', lambda w: w.count('a') % 3 == 0, '(b*ab*ab*a)*b*',
     table(3, [0], '0 a 1\n0 b 0\n1 a 2\n1 b 1\n2 a 0\n2 b 2'), max_states=3,
     hint='Câte o stare pentru fiecare rest al lui `#a` la împărțirea la 3.',
     solution='`qi` înseamnă „`#a` dă restul `i` la 3”. `a` duce din `qi` în `q(i+1)%3`, `b` rămâne pe loc; finală e `q0`.')

auto(6, 'Începe și se termină cu același simbol', C1, 'medie',
     'Construiește un AFD peste `{a, b}` care acceptă cuvintele nevide ce încep și se termină cu același simbol (`a`, `b`, `abba`, dar nu `ab`).',
     'ab', lambda w: len(w) > 0 and w[0] == w[-1], 'a(a∪b)*a∪b(a∪b)*b∪a∪b',
     table(5, [1, 3], '0 a 1\n0 b 3\n1 a 1\n1 b 2\n2 a 1\n2 b 2\n3 a 4\n3 b 3\n4 a 4\n4 b 3'),
     hint='Primul simbol hotărăște în ce „jumătate” a automatului rămâi; acolo ții minte doar ultimul simbol citit.',
     solution='Din `q0`, `a` duce în ramura lui `a` (`q1`: ultimul e `a`, finală; `q2`: ultimul e `b`), iar `b` în ramura lui `b` (`q3`: ultimul e `b`, finală; `q4`: ultimul e `a`).')

auto(7, 'Numere binare divizibile cu 3', C1, 'grea',
     'Un cuvânt peste `{0, 1}` este citit ca număr în baza 2 (cuvântul vid are valoarea 0). Construiește un AFD cu cel mult 3 stări care acceptă numerele divizibile cu 3.',
     '01', lambda w: (int(w, 2) if w else 0) % 3 == 0, '(0∪1(01*0)*1)*',
     table(3, [0], '0 0 0\n0 1 1\n1 0 2\n1 1 0\n2 0 1\n2 1 2'), max_states=3,
     hint='Dacă valoarea de până acum e `v`, după încă un bit `c` ea devine `2v + c`. Ține minte doar `v mod 3`.',
     solution='Starea `qr` = restul la 3. Din `qr`, bitul `c` duce în `q(2r+c)%3`: `q0`: 0→q0, 1→q1; `q1`: 0→q2, 1→q0; `q2`: 0→q1, 1→q2.')

_prod = table(6, [0], '\n'.join(f'{i * 3 + j} a {((i + 1) % 2) * 3 + j}\n{i * 3 + j} b {i * 3 + (j + 1) % 3}' for i in range(2) for j in range(3)))
auto(8, 'Două numărători deodată', C1, 'grea',
     'Construiește un AFD peste `{a, b}` care acceptă cuvintele `w` cu `#a(w) % 2 = 0` și `#b(w) % 3 = 0`.\n\nLa examen automatul a fost dat cu stările `q_ij`, `δ(q_ij, a) = q_((i+1)%m)j`, `δ(q_ij, b) = q_i((j+1)%n)` și s-a cerut limbajul; aici îl construiești pentru `m = 2`, `n = 3`.',
     'ab', lambda w: w.count('a') % 2 == 0 and w.count('b') % 3 == 0, None, _prod, max_states=6, lang_auto=_prod,
     hint='Automatul produs: o stare ține minte perechea (`#a % 2`, `#b % 3`). Sunt 2 · 3 = 6 perechi.',
     solution='Numerotează perechea `(i, j)` ca `q(3i+j)`. `a` schimbă `i` (adică sare cu 3 stări), `b` îl mărește pe `j` modulo 3. Finală e doar `q0` = (0, 0).',
     source='Examen LFA · grilă, februarie 2022')

auto(9, 'Din nedeterminist în determinist', C1, 'medie',
     'Fie automatul nedeterminist `N = ({0, 1}, {a, b}, Δ, 0, {1})` cu `Δ = {(0, a, 0), (0, b, 0), (0, b, 1), (1, a, 1), (1, a, 0)}`.\n\nConstruiește un automat **determinist** `A` cu `L(A) = L(N)`.',
     'ab', lambda w: 'b' in w, 'a*b(a∪b)*',
     table(2, [1], '0 a 0\n0 b 1\n1 a 1\n1 b 1'),
     hint='Construcția submulțimilor: pornește din `{0}` și vezi unde duc `a` și `b`. Stările noului automat sunt mulțimi de stări ale lui `N`.',
     solution='`{0}` cu `a` rămâne `{0}`, cu `b` ajunge în `{0, 1}`. `{0, 1}` cu `a` și cu `b` rămâne `{0, 1}`. Deci două stări: `q0 = {0}`, `q1 = {0, 1}` (finală): `L = a*b(a∪b)*`, cuvintele care conțin un `b`.',
     source=EX)

# ---------------------------------------------------------------- 2. AFN
auto(10, 'Al treilea simbol de la sfârșit', C2, 'medie',
     'Construiește un automat **nedeterminist** cu cel mult 4 stări peste `{a, b}` care acceptă cuvintele în care al treilea simbol de la sfârșit este `a`.',
     'ab', lambda w: len(w) >= 3 and w[-3] == 'a', '(a∪b)*a(a∪b)(a∪b)',
     table(4, [3], '0 a 0 1\n0 b 0\n1 a 2\n1 b 2\n2 a 3\n2 b 3'), mode='nfa', max_states=4,
     hint='Automatul „ghicește” care `a` este al treilea de la sfârșit: din `q0`, pe `a`, poate rămâne în `q0` sau poate pleca spre final.',
     solution='`q0` are buclă pe `a` și `b` și, pe `a`, merge și în `q1`. Apoi `q1 → q2 → q3` pe orice simbol; `q3` e finală și nu mai are tranziții. Un AFD pentru același limbaj are nevoie de 8 stări.')

auto(11, 'Conține aba', C2, 'ușoară',
     'Construiește un automat nedeterminist cu cel mult 4 stări peste `{a, b}` care acceptă cuvintele ce conțin subșirul `aba`.',
     'ab', lambda w: 'aba' in w, '(a∪b)*aba(a∪b)*',
     table(4, [3], '0 a 0 1\n0 b 0\n1 b 2\n2 a 3\n3 a 3\n3 b 3'), mode='nfa', max_states=4,
     hint='Buclă pe orice în prima și în ultima stare; între ele, drumul `a`, `b`, `a`.',
     solution='`q0` (buclă pe `a`, `b`) —`a`→ `q1` —`b`→ `q2` —`a`→ `q3` (finală, buclă pe `a`, `b`).')

auto(12, 'a-uri, apoi b-uri, apoi c-uri', C2, 'ușoară',
     'Construiește un automat cu ε-tranziții, cu cel mult 3 stări, peste `{a, b, c}`, care acceptă `L(a*b*c*)`.',
     'abc', lambda w: re.fullmatch('a*b*c*', w), 'a*b*c*',
     table(3, [2], '0 a 0\n0 ε 1\n1 b 1\n1 ε 2\n2 c 2'), mode='nfa', max_states=3,
     hint='Câte o stare pentru fiecare literă, cu buclă pe ea; treci la următoarea fără să citești nimic (ε).',
     solution='`q0` cu buclă pe `a`, ε spre `q1`; `q1` cu buclă pe `b`, ε spre `q2`; `q2` cu buclă pe `c`, finală.')

auto(13, 'Se termină cu ab sau cu ba', C2, 'medie',
     'Construiește un automat nedeterminist cu cel mult 4 stări peste `{a, b}` care acceptă cuvintele ce se termină cu `ab` sau cu `ba`.',
     'ab', lambda w: w.endswith('ab') or w.endswith('ba'), '(a∪b)*(ab∪ba)',
     table(4, [3], '0 a 0 1\n0 b 0 2\n1 b 3\n2 a 3'), mode='nfa', max_states=4,
     hint='Două drumuri din `q0` spre aceeași stare finală.',
     solution='`q0` cu buclă pe `a`, `b`; pe `a` și în `q1`, pe `b` și în `q2`; `q1 —b→ q3`, `q2 —a→ q3`; `q3` finală, fără tranziții.')

auto(14, 'Lungime multiplu de 2 sau de 3', C2, 'grea',
     'Construiește un automat cu ε-tranziții, cu cel mult 6 stări, peste `{a}`, care acceptă cuvintele a căror lungime este multiplu de 2 sau multiplu de 3.',
     'a', lambda w: len(w) % 2 == 0 or len(w) % 3 == 0, '(aa)*∪(aaa)*',
     table(6, [1, 3], '0 ε 1 3\n1 a 2\n2 a 1\n3 a 4\n4 a 5\n5 a 3'), mode='nfa', max_states=6,
     hint='Din starea inițială, două ε-tranziții: una spre un ciclu de lungime 2, alta spre un ciclu de lungime 3.',
     solution='`q0` —ε→ `q1` și —ε→ `q3`. Ciclul `q1 → q2 → q1` (finală `q1`) numără modulo 2; ciclul `q3 → q4 → q5 → q3` (finală `q3`) numără modulo 3. Determinist ar fi nevoie de 6 stări într-un singur ciclu.')

# ---------------------------------------------------------------- 3. ER
regex(15, 'Fiecare a e urmat de b, la sfârșit c', 'medie',
      'Scrie o expresie regulată pentru limbajul `{x ∈ {a, b, c}* | fiecare simbol a din x este urmat de un simbol b, și x se termină cu c}`.',
      'abc', lambda w: w.endswith('c') and all(i + 1 < len(w) and w[i + 1] == 'b' for i, ch in enumerate(w) if ch == 'a'),
      '(b∪c∪ab)*c', hint='Un `a` nu apare niciodată singur: tratează `ab` ca pe un singur „simbol”.',
      solution='Bucățile din care e făcut cuvântul sunt `b`, `c` și `ab`; ultima trebuie să fie `c`: `(b∪c∪ab)*c`.', source='Examen LFA · 9 iunie 2022')

regex(16, 'Aceeași expresie, mai scurtă', 'ușoară',
      'Descrie limbajul generat de expresia `(0*∪1∪1*)*` printr-o expresie echivalentă de cel mult 6 caractere.',
      '01', lambda w: True, '(0∪1)*', max_len=6, truth='(0*∪1∪1*)*',
      hint='Ce cuvinte de un singur simbol sunt în paranteză? Steaua de afară face restul.',
      solution='Paranteza conține `0` și `1`, deci steaua ei dă toate cuvintele: `(0∪1)*`.', source='Examen LFA · 6 septembrie 2022')

regex(17, 'Exact doi de b', 'ușoară',
      'Scrie o expresie regulată pentru cuvintele peste `{a, b}` care conțin exact două simboluri `b`.',
      'ab', lambda w: w.count('b') == 2, 'a*ba*ba*', hint='Între cei doi `b`, înainte și după ei, pot fi oricâți `a`.')

regex(18, 'Lungime multiplu de 3', 'ușoară',
      'Scrie o expresie regulată pentru cuvintele peste `{a, b}` a căror lungime este multiplu de 3.',
      'ab', lambda w: len(w) % 3 == 0, '((a∪b)(a∪b)(a∪b))*', hint='Un grup de trei simboluri oarecare, repetat.')

regex(19, 'Fără două simboluri egale alăturate', 'medie',
      'Scrie o expresie regulată pentru cuvintele peste `{a, b}` în care nu apar două simboluri egale unul lângă altul (nici `aa`, nici `bb`).',
      'ab', lambda w: 'aa' not in w and 'bb' not in w, '(ε∪b)(ab)*(ε∪a)',
      hint='Cuvântul alternează. Mijlocul e `(ab)*`; ce poate sta înainte și ce poate sta după?')

regex(20, 'Cel puțin un a și cel puțin un b', 'medie',
      'Scrie o expresie regulată pentru cuvintele peste `{a, b}` care conțin cel puțin un `a` și cel puțin un `b`.',
      'ab', lambda w: 'a' in w and 'b' in w, '(a∪b)*(ab∪ba)(a∪b)*',
      hint='Dacă apar ambele simboluri, undeva în cuvânt ele stau alăturate: `ab` sau `ba`.')

regex(21, 'Numere pare în baza 2', 'medie',
      'Scrie o expresie regulată pentru scrierile în baza 2, fără zerouri la început, ale numerelor pare (`0`, `10`, `100`, `110`...). Cuvântul vid nu este un număr.',
      '01', lambda w: w == '0' or (len(w) > 1 and w[0] == '1' and w[-1] == '0'), '0∪1(0∪1)*0',
      hint='Un număr par se termină cu `0`. Singurul număr care începe cu `0` este chiar `0`.')

regex(22, 'Numărul de a dă restul 3 la 4', 'grea',
      'Scrie o expresie regulată pentru `L = {w ∈ {a, b}* | #a(w) % 4 = 3}`. (La examen s-a cerut clasa limbajului: este regulat.)',
      'ab', lambda w: w.count('a') % 4 == 3, '(b*ab*ab*ab*a)*b*ab*ab*ab*',
      hint='Întâi oricâte grupe de câte patru `a` (cu `b` printre ei), apoi încă exact trei `a`.', source='Examen LFA · grilă, februarie 2022')

regex(23, 'Din automat în expresie', 'medie',
      'Fie `N = ({0, 1}, {a, b}, Δ, 0, {1})` cu `Δ = {(0, a, 0), (0, b, 0), (0, b, 1), (1, a, 1), (1, a, 0)}`. Scrie o expresie regulată `E` cu `L(E) = L(N)`. Bonus: găsește una compactă.',
      'ab', lambda w: 'b' in w, 'a*b(a∪b)*',
      hint='Starea 1 se atinge numai citind un `b`. După aceea, din `{0, 1}` nu se mai pierde niciodată starea 1?',
      solution='`N` acceptă exact cuvintele care conțin un `b`: `a*b(a∪b)*`.', source=EX)

# ---------------------------------------------------------------- 4. GIC
cfg(24, 'a^n b^n', 'ușoară',
    'Scrie o gramatică independentă de context pentru `{aⁿbⁿ | n ≥ 0}`.',
    'ab', lambda w: re.fullmatch('a*b*', w) and w.count('a') == w.count('b'), 'S -> aSb | ε', 10,
    hint='Fiecare `a` din stânga își are perechea `b` în dreapta: adaugă-le deodată, de o parte și de alta.')

cfg(25, 'a^n b^n în forma normală Chomsky', 'medie',
    'Scrie o gramatică în **Forma Normală Chomsky** pentru `{aⁿbⁿ | n ≥ 1}`. (Reguli doar de forma `A -> BC` sau `A -> a`.)',
    'ab', lambda w: len(w) > 0 and re.fullmatch('a*b*', w) and w.count('a') == w.count('b'),
    'S -> AT | AB\nT -> SB\nA -> a\nB -> b', 10, chomsky=True,
    hint='Pornește de la `S -> aSb | ab`, înlocuiește terminalele cu neterminale (`A -> a`, `B -> b`) și rupe regula de trei simboluri în două.',
    source=EX)

cfg(26, 'Palindroame', 'ușoară',
    'Scrie o gramatică pentru palindroamele peste `{a, b}` (cuvintele egale cu oglinditul lor, cuvântul vid inclus).',
    'ab', lambda w: w == w[::-1], 'S -> aSa | bSb | a | b | ε', 9,
    hint='Un palindrom are același simbol la cele două capete, iar între ele tot un palindrom.')

cfg(27, 'La fel de mulți a și b', 'medie',
    'Scrie o gramatică pentru cuvintele peste `{a, b}` cu același număr de `a` și de `b`, în orice ordine.',
    'ab', lambda w: w.count('a') == w.count('b'), 'S -> aSbS | bSaS | ε', 10,
    hint='Dacă un cuvânt începe cu `a`, undeva mai încolo e un `b` care îl „închide”; între ele și după ele rămân cuvinte de același fel.')

cfg(28, 'i + j ≤ 2k', 'grea',
    'Fie `L = {0ⁱ1ʲ2ᵏ | i, j, k ∈ N, i + j ≤ 2k}`. Scrie o gramatică care generează `L`.',
    '012', lambda w: re.fullmatch('0*1*2*', w) and w.count('0') + w.count('1') <= 2 * w.count('2'),
    'S -> 00S2 | 0S2 | 01T2 | T\nT -> 11T2 | 1T2 | T2 | ε', 7,
    hint='Fiecare `2` de la dreapta „plătește” cel mult două simboluri din stânga: `00`, `0`, `01`, `11`, `1` sau niciunul.',
    solution='`S` consumă zerourile, `T` unu-urile:\n`S -> 00S2 | 0S2 | 01T2 | T`\n`T -> 11T2 | 1T2 | T2 | ε`\nPentru `000022`: `S ⇒ 00S2 ⇒ 0000S22 ⇒ 0000T22 ⇒ 000022`.',
    source='Examen LFA · 6 septembrie 2022')

cfg(29, 'De două ori mai mulți 0 decât 1', 'grea',
    'Fie limbajul cuvintelor peste `{0, 1}` care conțin de două ori mai multe simboluri `0` decât `1`. Construiește o gramatică independentă de context pentru el.',
    '01', lambda w: w.count('0') == 2 * w.count('1'), 'S -> SS | 0S0S1 | 0S1S0 | 1S0S0 | ε', 9,
    hint='Un `1` merge împreună cu doi de `0`; cei trei pot veni în ordinea `001`, `010` sau `100`, cu alte cuvinte din limbaj printre ei.',
    source='Examen LFA · 15 iunie 2022')

cfg(30, 'a^n b^m cu n diferit de m', 'medie',
    'Scrie o gramatică pentru `{aⁿbᵐ | n, m ≥ 0, n ≠ m}`. (La examen s-a cerut un automat push-down pentru el.)',
    'ab', lambda w: re.fullmatch('a*b*', w) and w.count('a') != w.count('b'), 'S -> aSb | A | B\nA -> aA | a\nB -> bB | b', 10,
    hint='Potrivește perechi `a ... b`, apoi lasă în mijloc doar `a`-uri în plus sau doar `b`-uri în plus, cel puțin unul.', source=EX)

cfg(31, 'i = j sau j = k', 'grea',
    'Scrie o gramatică pentru `{aⁱbʲcᵏ | i = j sau j = k}`.',
    'abc', lambda w: re.fullmatch('a*b*c*', w) and (w.count('a') == w.count('b') or w.count('b') == w.count('c')),
    'S -> XC | AY\nX -> aXb | ε\nC -> cC | ε\nA -> aA | ε\nY -> bYc | ε', 7,
    hint='Reuniunea a două limbaje: (`aⁿbⁿ` urmat de oricâți `c`) și (oricâți `a` urmați de `bⁿcⁿ`).',
    solution='`S -> XC | AY`, `X -> aXb | ε`, `C -> cC | ε`, `A -> aA | ε`, `Y -> bYc | ε`. Gramatica e ambiguă: `aⁿbⁿcⁿ` se obține pe ambele ramuri, iar limbajul este inerent ambiguu.')

cfg(32, 'Paranteze bine închise', 'ușoară',
    'Notăm paranteza deschisă cu `a` și cea închisă cu `b`. Scrie o gramatică pentru șirurile de paranteze bine închise (`ab`, `aabb`, `abab`, cuvântul vid...).',
    'ab', lambda w: w.count('a') == w.count('b') and all(w[:i].count('a') >= w[:i].count('b') for i in range(len(w) + 1)),
    'S -> aSbS | ε', 10, hint='Prima paranteză se închide undeva: `a S b`, apoi urmează alt șir bine închis.')

# ---------------------------------------------------------------- 5. clase
LR, LIC, NLIC, FIN = 'regulat', 'independent de context, dar nu regulat', 'nu este independent de context', 'finit'


def clasa(id, title, diff, lang, right, why, source='', extra=''):
    opts = [LR, LIC, NLIC, FIN]
    P.append(quiz(id, title, C5, diff, f'Fie {lang}. Cum este `L` în cel mai strict sens?{extra}', right, [o for o in opts if o != right],
                  hint='Întreabă-te câtă memorie trebuie ca să recunoști cuvintele: un număr fix de stări, o stivă, sau mai mult.', solution=why, source=source))


clasa(33, '0^n 1^n 0^n', 'ușoară', '`L = {0ⁿ1ⁿ0ⁿ | n ≥ 0}`', NLIC,
      'Trei blocuri de aceeași lungime nu se pot potrivi cu o singură stivă; cu lema de pompare pentru LIC, pe `0ᵖ1ᵖ0ᵖ`, pomparea strică egalitatea a cel puțin două blocuri.', 'Examen LFA · grilă, februarie 2022')
clasa(34, 'Restul numărului de a', 'ușoară', '`L = {w ∈ {a, b}* | #a(w) % 4 = 3}`', LR,
      'Un AFD cu 4 stări ține minte `#a mod 4`.', 'Examen LFA · grilă, februarie 2022')
clasa(35, 'k = |m - n|', 'medie', '`L = {aⁿbᵐcᵏ | k = |m - n|}`', LIC,
      'Pentru `m ≥ n`: `aⁿbⁿ bᵏcᵏ`; pentru `n > m`: `aᵏ aᵐbᵐ cᵏ`. Ambele sunt LIC, deci și reuniunea. Nu e regulat: intersecția cu `a*b*` (adică `k = 0`) este `{aⁿbⁿ}`.', 'Examen LFA · 9 iunie 2022')
clasa(36, 'vwv cu |v| = 2', 'medie', '`L = {vwv | v, w ∈ {a, b}*, |v| = 2}`', LR,
      '`v` are doar 4 valori posibile: `L` este reuniunea a patru limbaje `v(a∪b)*v`, toate regulate.', 'Test LFA')
clasa(37, 'Suma exponenților, multiplu de 5', 'medie', '`L = {aⁱbʲcᵏdᵐ | i + j + k + m este multiplu de 5}`', LR,
      'E intersecția dintre `L(a*b*c*d*)` și „lungimea e multiplu de 5”, amândouă regulate.', 'Examen LFA · 15 iunie 2022')
P.append(quiz(38, 'Diferența dintre un LIC și un regulat', C5, 'medie',
              'Dacă `R` este un limbaj regulat și `L` este un limbaj independent de context, cum este `L \\ R`?',
              'independent de context', ['regulat', 'nu este independent de context', 'nu se poate afirma nimic'],
              hint='`L \\ R = L ∩ complement(R)`. Ce știi despre complementul unui limbaj regulat?',
              solution='Complementul lui `R` este regulat, iar intersecția unui LIC cu un limbaj regulat este LIC (automatul push-down rulat în paralel cu AFD-ul).', source='Examen LFA · 9 iunie și 6 septembrie 2022'))
P.append(quiz(39, 'Reuniunea a două limbaje neregulate', C5, 'medie',
              'Fie `L1 = {0ⁱ1ʲ | i, j ≥ 0, i ≠ j}` și `L2 = {0ⁱ1ʲ | i, j ≥ 0, i = j}`. Care afirmație este corectă?',
              'L1 și L2 sunt LIC, dar nu regulate, iar L1 ∪ L2 este regulat',
              ['L1, L2 și L1 ∪ L2 sunt LIC, dar nu regulate', 'L1, L2 și L1 ∪ L2 sunt regulate', 'L1, L2 și L1 ∪ L2 sunt finite'],
              hint='Scrie reuniunea fără condiția dintre `i` și `j`.', solution='`L1 ∪ L2 = L(0*1*)`, regulat, deși niciunul dintre cele două nu este.', source='Test LFA'))
P.append(quiz(40, 'Câte limbaje independente de context sunt', C5, 'ușoară',
              'Cum este mulțimea limbajelor independente de context (peste un alfabet dat)?',
              'infinit numărabilă', ['finită', 'nenumărabilă', 'nu se poate specifica'],
              hint='Fiecare LIC e descris de o gramatică, adică de un text finit.', solution='Gramaticile sunt șiruri finite, deci sunt numărabile; sunt și infinit de multe limbaje (`{aⁿ}` pentru fiecare `n`).', source='Test LFA'))
P.append(quiz(41, 'O submulțime a unui LIC', C5, 'ușoară',
              'Fie `L` un limbaj independent de context și `S ⊆ L`. Este `S` independent de context?',
              'nu neapărat', ['da, întotdeauna', 'da, și este chiar regulat', 'nu, niciodată'],
              hint='`Σ*` este regulat, deci și LIC. Ce submulțimi are?', solution='Orice limbaj este submulțime a lui `Σ*`, care e LIC; de exemplu `{aⁿbⁿcⁿ} ⊆ {a, b, c}*` nu este LIC.', source='Examen LFA · 6 septembrie 2022'))
P.append(quiz(42, 'Câte stări are cel mai mic AFD', C5, 'medie',
              'Câte stări are cel mai mic automat finit determinist (complet) care acceptă cuvintele peste `{a, b}` în care al treilea simbol de la sfârșit este `a`?',
              '8', ['3', '4', '6'], hint='Automatul trebuie să țină minte ultimele trei simboluri citite.',
              solution='Două cuvinte de lungime 3 diferite se pot deosebi prin ce urmează, deci sunt necesare `2³ = 8` stări; nedeterminist ajung 4.'))
P.append(quiz(43, 'Intersecții', C5, 'medie',
              'Care afirmație este adevărată?',
              'intersecția unui LIC cu un limbaj regulat este LIC', ['intersecția a două LIC este întotdeauna LIC', 'complementul unui LIC este întotdeauna LIC', 'intersecția unui LIC cu un limbaj regulat este întotdeauna regulată'],
              hint='`{aⁿbⁿcᵐ} ∩ {aᵐbⁿcⁿ}` = ?', solution='LIC nu sunt închise la intersecție și la complement (`{aⁿbⁿcⁿ}` e intersecția a două LIC), dar sunt închise la intersecția cu un limbaj regulat.'))
P.append(quiz(44, 'M nu acceptă w', C5, 'grea',
              'Fie `L = {ρ(M)ρ(w) | M nu acceptă w}`. Este `L` Turing acceptat?',
              'nu', ['da, și este chiar decidabil', 'da, dar nu este decidabil', 'depinde de M'],
              hint='Complementul lui `L` (față de codificările valide) este limbajul universal, care e acceptat, dar nu decidabil.',
              solution='Dacă și `L`, și complementul lui ar fi Turing acceptate, problema acceptării ar fi decidabilă. Cum `{ρ(M)ρ(w) | M acceptă w}` e acceptat și nedecidabil, `L` nu este Turing acceptat.', source='Examen LFA · 6 septembrie 2022'))
P.append(quiz(45, 'Extratereștrii', C5, 'medie',
              'Fie `L` limbajul care conține doar șirul `s`, unde `s = 1` dacă există extratereștri și `s = 0` dacă nu există. Este `L` decidabil?',
              'da', ['nu', 'doar dacă aflăm răspunsul', 'este Turing acceptat, dar nu decidabil'],
              hint='`L` este fie `{0}`, fie `{1}`. Sunt aceste două limbaje decidabile?',
              solution='`L` este un limbaj finit, oricare ar fi el dintre `{0}` și `{1}`, iar limbajele finite sunt decidabile. Există o mașină care îl decide, chiar dacă nu știm care dintre cele două.', source='Examen LFA · 9 iunie 2022'))

# ---------------------------------------------------------------- more: seminars and exams
def dfa_of(alphabet, pred, depth=7, suffix=7):
    """The minimal DFA of a regular language given by a predicate (Myhill-Nerode on words up to a length)."""
    tails = list(words(alphabet, suffix))
    sig = lambda w: tuple(bool(pred(w + t)) for t in tails)
    states, rows, todo = {sig(''): 0}, {}, ['']
    reps = ['']
    while todo:
        w = todo.pop(0)
        i = states[sig(w)]
        for a in alphabet:
            k = sig(w + a)
            if k not in states:
                assert len(w) < depth, 'the language needs more states than the depth allows'
                states[k] = len(states); reps.append(w + a); todo.append(w + a)
            rows.setdefault(i, {})[a] = states[k]
    final = [states[sig(r)] for r in reps if pred(r)]
    text = '\n'.join(f'{i} {a} {j}' for i in sorted(rows) for a, j in rows[i].items())
    return table(len(states), sorted(set(final)), text)


def afd(id, title, diff, statement, alphabet, pred, regex_, hint, solution, source='', max_states=None, ch=C1):
    ref = dfa_of(alphabet, pred)
    auto(id, title, ch, diff, statement, alphabet, pred, regex_, ref, max_states=max_states or None, hint=hint, solution=solution, source=source, lang_auto=None if regex_ else ref)


afd(50, 'Conține aba, determinist', 'medie', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele ce conțin subcuvântul `aba`.', 'ab',
    lambda w: 'aba' in w, '(a∪b)*aba(a∪b)*', 'Ține minte cel mai lung sufix care e și început de `aba`: nimic, `a`, `ab`; plus starea „găsit”.',
    'Patru stări: `q0` (nimic), `q1` (`a`), `q2` (`ab`), `q3` (găsit, finală, cu bucle). Atenție la `q2` cu `b`: `abb` nu mai păstrează nimic, deci înapoi în `q0`; `q1` cu `a` rămâne în `q1`.')
afd(51, 'Fără bb', 'ușoară', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele în care nu apar doi `b` consecutivi.', 'ab',
    lambda w: 'bb' not in w, '(a∪ba)*(b∪ε)', 'O stare pentru „ultimul a fost `b`”, una pentru „altfel” și o groapă.',
    '`q0` (finală): ultimul nu e `b`; `q1` (finală): ultimul e `b`; `q2`: am văzut `bb` (groapa, nefinală).')
afd(52, 'Orice a e urmat de b', 'medie', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele în care fiecare `a` este urmat imediat de un `b`.', 'ab',
    lambda w: all(i + 1 < len(w) and w[i + 1] == 'b' for i, c in enumerate(w) if c == 'a'), '(b∪ab)*',
    'După un `a` ești „în datorie”: doar `b` te scoate de acolo.', '`q0` (finală), `q1`: tocmai am citit `a` (nefinală), `q2`: groapa (`aa`). Limbajul e `(b ∪ ab)*`.')
afd(53, 'Număr par de a și impar de b', 'medie', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele cu număr par de `a` și număr impar de `b`.', 'ab',
    lambda w: w.count('a') % 2 == 0 and w.count('b') % 2 == 1, None, 'Patru stări: perechea de parități (`#a % 2`, `#b % 2`).',
    'Stările sunt (par, par), (par, impar), (impar, par), (impar, impar); `a` schimbă prima paritate, `b` pe a doua. Finală: (par, impar).', max_states=4)
afd(54, 'Lungimea dă restul 1 la 3', 'ușoară', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele cu lungimea `≡ 1 (mod 3)`.', 'ab',
    lambda w: len(w) % 3 == 1, '(a∪b)((a∪b)(a∪b)(a∪b))*', 'Doar lungimea contează: trei stări în cerc, orice simbol trece la următoarea.',
    '`q0 → q1 → q2 → q0` pe orice simbol; finală `q1`.', max_states=3)
afd(55, 'Numere binare divizibile cu 5', 'grea', 'Un cuvânt peste `{0, 1}` e citit ca număr în baza 2 (cuvântul vid are valoarea 0). Construiește un AFD cu cel mult 5 stări care acceptă numerele divizibile cu 5.', '01',
    lambda w: (int(w, 2) if w else 0) % 5 == 0, None, 'Starea e restul la 5; bitul `c` duce din `r` în `(2r + c) mod 5`.',
    'Din `r`: `0` → `2r mod 5`, `1` → `(2r+1) mod 5`. De exemplu din `q3`: `0` → `q1`, `1` → `q2`. Finală `q0`.', source='Seminar LFA', max_states=5)
afd(56, 'Se termină cu abb', 'medie', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele ce se termină cu `abb`.', 'ab',
    lambda w: w.endswith('abb'), '(a∪b)*abb', 'Cel mai lung sufix care e început de `abb`: nimic, `a`, `ab`, `abb`.',
    '`q0`, `q1` (`a`), `q2` (`ab`), `q3` (`abb`, finală). Din orice stare `a` duce în `q1`; `b` avansează `q1 → q2 → q3`, iar din `q0` și `q3` duce în `q0`.')
afd(57, 'Cel puțin două a și cel mult un b', 'grea', 'Construiește un AFD peste `{a, b}` care acceptă cuvintele cu cel puțin doi `a` și cel mult un `b`.', 'ab',
    lambda w: w.count('a') >= 2 and w.count('b') <= 1, None, 'Produsul a două automate mici: unul numără `a` până la 2, altul `b` până la 1 (plus groapa).',
    'Stările sunt perechi (`min(#a, 2)`, `#b` ∈ {0, 1}) plus o groapă pentru `#b ≥ 2`: 7 stări. Finale: (2, 0) și (2, 1).', source='Seminar LFA')

def nfa(id, title, diff, statement, alphabet, pred, regex_, ref_rows, n, final, hint, solution, source='', max_states=None):
    auto(id, title, C2, diff, statement, alphabet, pred, regex_, table(n, final, ref_rows), mode='nfa', max_states=max_states, hint=hint, solution=solution, source=source)


nfa(58, 'Al treilea simbol de la coadă e a', 'medie', 'Construiește un automat nedeterminist cu cel mult 4 stări peste `{a, b}` care acceptă cuvintele în care al treilea simbol de la sfârșit este `a`.', 'ab',
    lambda w: len(w) >= 3 and w[-3] == 'a', '(a∪b)*a(a∪b)(a∪b)', '0 a 0 1\n0 b 0\n1 a 2\n1 b 2\n2 a 3\n2 b 3', 4, [3],
    'Ghicește momentul în care citești acel `a`, apoi numără exact încă două simboluri.',
    'Starea 0 are buclă pe `a` și `b` și, pe `a`, poate „ghici” trecerea în 1; de acolo orice simbol în 2, apoi în 3 (finală). Un AFD pentru același limbaj are nevoie de 8 stări.', max_states=4)
nfa(59, 'Conține aa sau bb', 'ușoară', 'Construiește un automat nedeterminist peste `{a, b}` care acceptă cuvintele ce conțin `aa` sau `bb`.', 'ab',
    lambda w: 'aa' in w or 'bb' in w, '(a∪b)*(aa∪bb)(a∪b)*', '0 a 0 1\n0 b 0 2\n1 a 3\n2 b 3\n3 a 3\n3 b 3', 4, [3],
    'Ramifică: o ramură caută `aa`, alta `bb`; ajung în aceeași stare finală.', 'Patru stări: 0 (buclă, ghicește începutul perechii), 1 (`a` citit), 2 (`b` citit), 3 (finală, buclă).')
nfa(60, 'Se termină cu ab sau ba', 'medie', 'Construiește un automat nedeterminist cu cel mult 4 stări peste `{a, b}` care acceptă cuvintele ce se termină cu `ab` sau `ba`.', 'ab',
    lambda w: w[-2:] in ('ab', 'ba'), '(a∪b)*(ab∪ba)', '0 a 0 1\n0 b 0 2\n1 b 3\n2 a 3', 4, [3],
    'Altfel spus: ultimele două simboluri sunt diferite.', 'Din 0 (buclă) ghicești penultimul simbol: `a` în 1, `b` în 2; de acolo simbolul celălalt duce în 3, finală, fără ieșiri.', max_states=4)


regex(61, 'Lungime pară', 'ușoară', 'Scrie o expresie regulată pentru cuvintele de lungime pară peste `{a, b}`.', 'ab',
      lambda w: len(w) % 2 == 0, '((a∪b)(a∪b))*', hint='Cuvântul se împarte în perechi de simboluri.')
regex(62, 'Cel mult un a', 'ușoară', 'Scrie o expresie regulată pentru cuvintele peste `{a, b}` care conțin cel mult un `a`.', 'ab',
      lambda w: w.count('a') <= 1, 'b*(a∪ε)b*', hint='Oricâți `b`, poate un `a`, oricâți `b`.')
regex(63, 'Fără doi a consecutivi', 'medie', 'Scrie o expresie regulată pentru cuvintele peste `{a, b}` în care nu apar doi `a` consecutivi.', 'ab',
      lambda w: 'aa' not in w, '(b∪ab)*(a∪ε)', hint='Orice `a` e urmat de `b`, cu excepția, poate, ultimului simbol.')
regex(64, 'Exact doi de 1', 'ușoară', 'Scrie o expresie regulată pentru cuvintele peste `{0, 1}` care conțin exact doi de `1`.', '01',
      lambda w: w.count('1') == 2, '0*10*10*', hint='Zerouri oriunde între ei.')
regex(65, 'Expresie: numărul de a, multiplu de 3', 'grea', 'Scrie o expresie regulată pentru cuvintele peste `{a, b}` în care numărul de `a` este multiplu de 3.', 'ab',
      lambda w: w.count('a') % 3 == 0, 'b*(ab*ab*ab*)*', hint='Grupează `a`-urile câte trei, cu `b`-uri oriunde între ele.')
regex(66, 'Din gramatica de la examen', 'medie', 'Gramatica `G: S → aS | Sb | ab`. Scrie o expresie regulată pentru limbajul generat de `G`.', 'ab',
      lambda w: re.fullmatch('a+b+', w) is not None, 'aa*bb*', hint='Derivă câteva cuvinte: `ab`, `aab`, `abb`, `aabbb`...',
      solution='`S` adaugă `a`-uri la stânga și `b`-uri la dreapta lui `ab`: `L(G) = { aⁱbʲ | i, j ≥ 1 }`, adică `aa*bb*`. Gramatica e ambiguă: `aabb` are două derivări stânga (`S ⇒ aS ⇒ aSb ⇒ aabb` și `S ⇒ Sb ⇒ aSb ⇒ aabb`).',
      source='Examen LFA (18 ianuarie 2025)')
regex(67, 'Fără ab', 'ușoară', 'Scrie o expresie regulată pentru cuvintele peste `{a, b}` care nu conțin subcuvântul `ab` (`#ab(w) = 0`).', 'ab',
      lambda w: 'ab' not in w, 'b*a*', hint='După primul `a` nu mai poate veni niciun `b`.', source='După examenul LFA (1 februarie 2025)')


def _gx():
    return """S -> X|Y|Z|W
X -> 01Y|0|ε
Y -> 00X|0|ε
Z -> 10W|1|ε
W -> 11Z|1|ε"""


_lx = grammar_words(_gx(), 12)
regex(68, 'Ce limbaj generează gramatica', 'grea',
      'Gramatica de la examen, cu neterminalii redenumiți (`X1 = X`, `X2 = Y`, `Y1 = Z`, `Y2 = W`):\n\n`S → X | Y | Z | W`\n\n`X → 01Y | 0 | ε`\n\n`Y → 00X | 0 | ε`\n\n`Z → 10W | 1 | ε`\n\n`W → 11Z | 1 | ε`\n\nScrie o expresie regulată pentru limbajul generat.', '01',
      lambda w: w in _lx, '(0100)*(ε∪0∪01∪010)∪00(0100)*(ε∪0∪01∪010)∪(1011)*(ε∪1∪10∪101)∪11(1011)*(ε∪1∪10∪101)',
      hint='Rezolvă întâi `X`: înlocuiește `Y` în regula lui `X` și obții `X = 0100 X | 010 | 01 | 0 | ε`.',
      solution='`X = (0100)*(ε ∪ 0 ∪ 01 ∪ 010)`, `Y = 00X ∪ 0 ∪ ε`, iar `Z` și `W` la fel, cu `0` și `1` schimbate între ele (`Z = (1011)*(ε ∪ 1 ∪ 10 ∪ 101)`). `L(G)` e reuniunea celor patru.',
      source='Examen LFA (1 februarie 2025)')

cfg(69, 'aⁿb²ⁿ', 'ușoară', 'Scrie o gramatică independentă de context pentru `{ aⁿb²ⁿ | n ≥ 0 }`.', 'ab',
    lambda w: re.fullmatch('a*b*', w) is not None and w.count('b') == 2 * w.count('a'), 'S -> aSbb|ε', 8,
    hint='Fiecare `a` pus la stânga aduce doi `b` la dreapta.')
cfg(71, 'Tot atâția a cât b', 'medie', 'Scrie o gramatică pentru cuvintele peste `{a, b}` cu același număr de `a` și `b`, în orice ordine.', 'ab',
    lambda w: w.count('a') == w.count('b'), 'S -> aSbS|bSaS|ε', 8,
    hint='Uită-te la primul simbol și la locul unde „se închide” prima dată diferența dintre `#a` și `#b`.')
cfg(72, 'Mai mulți a decât b, în ordine', 'medie', 'Scrie o gramatică pentru `{ aⁱbʲ | i > j ≥ 0 }`.', 'ab',
    lambda w: re.fullmatch('a*b*', w) is not None and w.count('a') > w.count('b'), 'S -> aSb|aS|a', 8,
    hint='Pune perechile `a…b`, apoi cel puțin un `a` în plus.')
cfg(73, 'Paranteze unghiulare oglindite', 'grea',
    'Pentru `x ∈ {<, >}*`, `mirror(x)` e imaginea în oglindă a lui `x`: întors și cu fiecare paranteză schimbată (`mirror(<<>) = <>>`). Scrie o gramatică pentru `L = { x | x = mirror(x) }`.', '<>',
    lambda w: w == ''.join({'<': '>', '>': '<'}[c] for c in reversed(w)), 'S -> <S>|>S<|ε', 8,
    hint='Simbolul de pe poziția `i` trebuie să fie „opusul” celui de pe poziția `n + 1 - i`. Un simbol de mijloc ar trebui să fie propriul opus: imposibil.',
    solution='`S → <S> | >S< | ε`. Toate cuvintele din `L` au lungime pară; `mirror(x) ≠ reverse(x)` pentru orice `x` nevid, pentru că primul simbol al lui `mirror(x)` e opusul ultimului simbol al lui `x`, iar al lui `reverse(x)` e chiar acela.',
    source='Examen LFA (18 ianuarie 2025)')
cfg(74, 'aⁱbʲcᵏ cu i = j sau j = k', 'grea', 'Scrie o gramatică pentru `{ aⁱbʲcᵏ | i = j sau j = k }`.', 'abc',
    lambda w: (m := re.fullmatch('(a*)(b*)(c*)', w)) is not None and (len(m[1]) == len(m[2]) or len(m[2]) == len(m[3])),
    'S -> XC|AY\nX -> aXb|ε\nC -> cC|ε\nA -> aA|ε\nY -> bYc|ε', 7,
    hint='Reuniunea a două limbaje independente de context e independentă de context: o ramură pentru `i = j`, una pentru `j = k`.',
    solution='`S → XC | AY`, `X → aXb | ε`, `C → cC | ε`, `A → aA | ε`, `Y → bYc | ε`. Limbajul e inerent ambiguu: `aⁿbⁿcⁿ` are mereu două arbori.')


# ---------------------------------------------------------------- 6. the model test, solved
def m(id, title, diff, st, options, right, sol):
    P.append(quiz_multi(id, title, C6, diff, st, options, [right], solution=sol, source=MODEL))


m(80, 'Mulțimea expresiilor regulate', 'medie', 'Fie `X` mulțimea expresiilor regulate peste un alfabet nevid (văzute ca șiruri de simboluri). Care afirmație este adevărată?',
  ['`X ∈ LIC`', '`X` e închisă în raport cu operația reverse', 'niciuna dintre celelalte variante', '`|X| ≠ |N|`'], 0,
  'Sintaxa expresiilor regulate (cu paranteze echilibrate) e independentă de context, nu regulată. Reverse strică parantezele: `(a)` devine `)a(`. `X` e numărabilă infinită, deci `|X| = |N|`.')
m(81, 'Care sunt regulate', 'grea', 'Fie `L1 = { 0ⁿ1ⁿ | 1 ≤ n ≤ 1000 }`, `L2 = { aⁿ | n prim sau n impar }`, `L3 = { w ∈ {0,1}* | int(w) ≥ int(wᴿ) }`, unde `int` e valoarea în baza 2. Care sunt regulate?',
  ['L1 și L2', 'L1, L2 și L3', 'L1 și L3', 'L2 și L3'], 0,
  '`L1` e finit, deci regulat. `L2` = numerele impare plus 2 (singurul prim par): regulat. `L3 ∩ 0*10* = { 0ᵃ10ᵇ | b ≥ a }` nu e regulat, deci nici `L3`.')
m(82, 'Pushdown și o expresie echivalentă', 'ușoară', 'Valorile de adevăr: (1) Se poate scrie cel puțin un automat pushdown pentru orice limbaj regulat. (2) Nu se poate scrie o altă expresie regulată echivalentă cu `a(a∪b)*b`.',
  ['adevărat, fals', 'adevărat, adevărat', 'fals, adevărat', 'fals, fals'], 0,
  '(1) Un AFD e un automat pushdown care nu folosește stiva. (2) De exemplu `a(a*b*)*b` sau `a(a∪b)*b ∪ ∅` sunt echivalente.')
m(83, 'Complementul nu e regulat', 'ușoară', 'Fie `L ⊆ Σ*` astfel încât `Σ* \\ L` nu este regulat. Atunci `L`:',
  ['nu este niciodată regulat', 'poate fi regulat, dar nu întotdeauna', 'conține șiruri de lungime infinită', 'este întotdeauna regulat'], 0,
  'Dacă `L` ar fi regulat, complementul lui ar fi regulat (închidere la complement).')
m(84, 'Reuniunea regulată', 'medie', 'Fie `L1, L2 ⊆ Σ*` cu `L1` și `L1 ∪ L2` regulate. Atunci:',
  ['niciuna dintre celelalte variante', '`L2` poate să nu fie regulat', '`L2` este întotdeauna regulat', '`L2 = (L1 ∪ L2) \\ L1`'], 1,
  'Cu `L1 = Σ*`, `L1 ∪ L2 = Σ*` pentru orice `L2`, chiar neregulat. Egalitatea din (d) e falsă când `L1 ∩ L2 ≠ ∅`.')
m(85, 'O gramatică amestecată', 'medie', 'Gramatica `S → 0S | A`, `A → A1 | B`, `B → ε | 1` (în original `S1`, `S2`). Ce este adevărat?',
  ['gramatica nu e regulată, dar generează un limbaj regulat', 'limbajul generat nu e regulat', 'gramatica e regulată și generează un limbaj regulat', 'gramatica are 2 neterminali'], 0,
  '`S → 0S` e liniară la dreapta, `A → A1` liniară la stânga: amestecul nu e o gramatică regulată. Limbajul e `0*1*`, regulat. Are 3 neterminali.')
m(86, 'AFD cu un singur cuvânt', 'medie', 'Fie `M` un AFD cu `L(M) = {w}` și `Y = { f | (s, w) ⊢* (f, ε) }`. Ce este întotdeauna adevărat?',
  ['`|F| = 1`', '`M` are mai multe stări inițiale', '`|w| > 0`', '`|Y| = 1`'], 3,
  'Determinismul: citind `w` din `s` ajungi într-o singură stare. `F` poate avea și stări finale inaccesibile, iar `w` poate fi `ε`.')
m(87, 'L = L·L? Infinitate de tranziții?', 'medie', 'Valorile de adevăr: (1) Pentru orice limbaj regulat `L`, `L = L·L`, pentru că limbajele regulate sunt închise la concatenare. (2) Un automat finit nedeterminist poate avea o infinitate de tranziții.',
  ['fals, fals', 'fals, adevărat', 'adevărat, adevărat', 'adevărat, fals'], 0,
  '(1) `L = {a}`: `L·L = {aa} ≠ L`; închiderea spune doar că `L·L` e regulat. (2) Relația de tranziție e o submulțime a unei mulțimi finite.')
m(88, 'Un cuvânt în (ab*a ∪ b*)*', 'ușoară', 'Fie `r = (ab*a ∪ b*)*`. Ce este adevărat despre `L(r)`?',
  ['`a ∈ L(r)`', 'niciuna dintre celelalte variante', 'fiecare șir din `L(r)` conține cel puțin un `b`', '`aa ∈ L(r)`'], 3,
  '`aa = a b⁰ a`. Orice cuvânt are un număr par de `a`, deci `a ∉ L(r)`; `ε` și `aa` nu au niciun `b`.')
m(89, 'Limbajele peste alfabetul vid', 'medie', 'Fie `Σ = ∅` și `Z = 2^(Σ*)`, mulțimea tuturor limbajelor peste `Σ`. Ce este adevărat?',
  ['`Z` este nenumărabilă', '`Z` este infinit numărabilă', '`|Z| = 2`', '`|Z| = 0`'], 2,
  '`Σ* = {ε}` (cuvântul vid există și peste alfabetul vid), deci `Z = {∅, {ε}}`.')
m(90, 'Limbajele care conțin abba', 'medie', 'Fie `Σ = {a, b, c}` și `L_abba = { L ⊆ Σ* | abba ∈ L }`. În raport cu ce operație e închisă `L_abba`?',
  ['diferență', 'intersecție', 'produs cartezian', 'concatenare'], 1,
  'Dacă ambele conțin `abba`, și intersecția îl conține. Diferența îl scoate; `{abba}·{abba} = {abbaabba}` nu îl mai conține.')
m(91, 'Derivări', 'medie', 'Fie gramatica `U → XUX | S`, `S → aTb | bTS`, `T → XTX | X | ε`, `X → a | b`. Ce este adevărat?',
  ['`T ⇒ aba`', '`X ⇒* aba`', '`S ⇒* ε`', '`T ⇒* XX`'], 3,
  '`T ⇒ XTX ⇒ XX` (cu `T → ε`). `T` nu ajunge la `aba` într-un pas, `X` dă doar un simbol, iar `S` produce mereu cel puțin `ab`.')
m(92, 'aⁱbʲcᵏ cu i < j < k', 'medie', 'Fie `L = { aⁱbʲcᵏ | 0 < i < j < k }`. Ce este adevărat?',
  ['nu se poate afirma nimic despre `L`', '`L` este regulat', '`L` nu este independent de context', '`L` este independent de context, dar nu regulat'], 2,
  'Trebuie comparate două perechi de exponenți deodată: lema de pompare pentru limbaje independente de context îl scoate, ca pe `aⁿbⁿcⁿ`.')
m(93, 'Fiecare cuvânt, acceptat de un AFD', 'medie', 'Fie `L` un limbaj infinit astfel încât pentru fiecare cuvânt din `L` există un AFD care îl acceptă. Ce este adevărat?',
  ['`L` este strict independent de context', 'nu se poate afirma nimic despre clasa lui `L`', '`L` este regulat', '`L` este strict dependent de context'], 1,
  'Orice cuvânt e acceptat de un AFD (limbajul `{w}` e finit): condiția e adevărată pentru orice limbaj, deci nu spune nimic.')
m(94, 'Limbajul vid', 'ușoară', 'Care expresie regulată generează limbajul vid?', ['`1*`', '`1*∅`', '`∅*(∅ ∪ 0*)`', '`∅*`'], 1,
  'Concatenarea cu `∅` dă `∅`. Atenție: `∅* = {ε}`, nu vid; `∅*(∅ ∪ 0*) = 0*`.')

write_course('lfa', CHAPTERS, P)
