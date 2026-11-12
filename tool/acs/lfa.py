"""LFA — Limbaje Formale și Automate: automata, regular expressions and grammars, checked as languages.

Topics and several statements from the LFA exams and tests (seria CA/CD, 2021-2022).
Every language is also written here as a Python predicate; the regular
expression (or automaton, or grammar) the app compares against is checked
against that predicate on every word up to a length, so the reference is the
language the statement describes.
"""
import itertools, os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, write_course

C1 = '1. Automate finite deterministe'
C2 = '2. Automate nedeterministe'
C3 = '3. Expresii regulate'
C4 = '4. Gramatici independente de context'
C5 = '5. Clase de limbaje'
CHAPTERS = [C1, C2, C3, C4, C5]
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

write_course('lfa', CHAPTERS, P)
