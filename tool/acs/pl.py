"""PL — Proiectare Logică: expressions, multiplexers and state machines, designed in the page.

Topics from the PL tests and exam (seria CD, 2021–2022). For the "minimal
form" tasks the number of literals allowed is computed here by brute force
(every cover of prime implicants), so it is the true minimum.
"""
import itertools, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

C1 = '1. Porți și expresii'
C2 = '2. Forme minime (Karnaugh)'
C3 = '3. Circuite combinaționale'
C4 = '4. Automate secvențiale'
CHAPTERS = [C1, C2, C3, C4]
T = 'Test PL'
PROBLEMS = []


def cubes(n):
    # a cube: tuple of 0 / 1 / None (dash), per variable
    return itertools.product((0, 1, None), repeat=n)


def covers(c, m, n):
    return all(v is None or ((m >> (n - 1 - i)) & 1) == v for i, v in enumerate(c))


def min_sop_literals(n, ones, dc=()):
    ones, dc = set(ones), set(dc)
    if not ones:
        return 0
    imps = [c for c in cubes(n) if all(covers(c, m, n) <= (m in ones or m in dc) for m in range(1 << n)) and any(covers(c, m, n) for m in ones)]
    # keep prime implicants
    def contains(a, b):
        return all(x is None or x == y for x, y in zip(a, b))
    primes = [c for c in imps if not any(d != c and contains(d, c) for d in imps)]
    best = None
    for k in range(1, len(primes) + 1):
        for combo in itertools.combinations(primes, k):
            if all(any(covers(c, m, n) for c in combo) for m in ones):
                lit = sum(sum(v is not None for v in c) for c in combo)
                best = lit if best is None else min(best, lit)
        if best is not None and k >= 4 and best <= k:
            break
    return best


def min_pos_literals(n, ones, dc=()):
    zeros = set(range(1 << n)) - set(ones) - set(dc)
    return min_sop_literals(n, zeros, dc)


def expr(id, title, ch, diff, statement, vars, outputs, hint, solution, allowed=None, form=None, max_lit=None, source='', ref=None):
    spec = {'mode': 'expr', 'vars': vars, 'outputs': outputs}
    if allowed: spec['allowed'] = allowed
    if form: spec['form'] = form
    if max_lit is not None: spec['maxLiterals'] = max_lit
    spec['reference'] = ref
    PROBLEMS.append(problem(id, title, ch, diff, statement, 'logic', spec, hint, solution, source))


def minterms(n, f):
    return [m for m in range(1 << n) if f(*[(m >> (n - 1 - i)) & 1 for i in range(n)])]

# ------------------------------------------------------------------ 1
expr(1, 'XOR doar din porți NAND', C1, 'medie', '''
Scrie funcția `f(a, b) = a ⊕ b` folosind **numai porți NAND** (operatorul `↑`, de exemplu `a ↑ b`). Nici măcar negația nu e voie: `a'` se scrie `a ↑ a`.

NAND e o poartă universală: orice circuit se poate face numai din ea. XOR cere 4 porți.''',
    ['a', 'b'], [{'name': 'f', 'ones': [1, 2]}],
    'Notează `t = a ↑ b`. Atunci `a ↑ t` e 1 când a = 1 și b = 0... Combină `a ↑ t` cu `b ↑ t`.',
    'Cu `t = a ↑ b`: `f = (a ↑ (a ↑ b)) ↑ (b ↑ (a ↑ b))`. Cele patru porți NAND sunt circuitul clasic pentru XOR.',
    allowed=['nand'], ref={'f': '(a↑(a↑b))↑(b↑(a↑b))'})

expr(2, 'Funcția majoritate', C1, 'ușoară', '''
`m(a, b, c)` e 1 când **cel puțin două** dintre intrări sunt 1 (o votare). Scrie-o ca sumă de produse, în forma minimă.''',
    ['a', 'b', 'c'], [{'name': 'm', 'ones': minterms(3, lambda a, b, c: a + b + c >= 2)}],
    'Câte o pereche de intrări egale cu 1 ajunge.', '`m = ab + bc + ac`: trei termeni de câte doi literali.',
    form='sop', max_lit=min_sop_literals(3, minterms(3, lambda a, b, c: a + b + c >= 2)), ref={'m': 'ab + bc + ac'})

expr(3, 'Majoritatea cu porți NAND', C1, 'medie', '''
Aceeași funcție majoritate `m = ab + bc + ac`, dar construită **doar din porți NAND** (`↑`).

O sumă de produse se transformă ușor: `xy + zw = (x ↑ y) ↑ (z ↑ w)` (De Morgan, de două ori).''',
    ['a', 'b', 'c'], [{'name': 'm', 'ones': minterms(3, lambda a, b, c: a + b + c >= 2)}],
    'Cu NAND-uri de două intrări, scrie întâi `m = ((ab)\'(bc)\'(ac)\')\'` (De Morgan) și construiește pe rând produsul celor trei negații.',
    "Cu `p = a↑b`, `q = b↑c`, `r = a↑c` (fiecare e un produs negat), `m = (p·q·r)'`. Produsul `p·q` se face din NAND-uri ca `(p↑q)↑(p↑q)`, deci `m = ((p↑q)↑(p↑q))↑r`, adică `(((a↑b)↑(b↑c))↑((a↑b)↑(b↑c)))↑(a↑c)`. Orice formă cu tabelul corect e acceptată.",
    allowed=['nand'], ref={'m': '(((a↑b)↑(b↑c))↑((a↑b)↑(b↑c)))↑(a↑c)'})

gray_ref = {'g2': 'b2', 'g1': 'b2⊕b1', 'g0': 'b1⊕b0'}
expr(4, 'Din binar în cod Gray', C1, 'ușoară', '''
Codul Gray al unui număr pe 3 biți `b2 b1 b0` are proprietatea că două numere consecutive diferă printr-un singur bit. Scrie cele trei ieșiri `g2`, `g1`, `g0`, folosind **doar porți XOR** (`⊕`).

```
zecimal   0    1    2    3    4    5    6    7
binar    000  001  010  011  100  101  110  111
Gray     000  001  011  010  110  111  101  100
```''',
    ['b2', 'b1', 'b0'],
    [{'name': 'g2', 'ones': [4, 5, 6, 7]}, {'name': 'g1', 'ones': minterms(3, lambda x, y, z: x ^ y)}, {'name': 'g0', 'ones': minterms(3, lambda x, y, z: y ^ z)}],
    'Fiecare bit Gray e XOR între bitul binar de pe aceeași poziție și cel din stânga lui.',
    '`g2 = b2`, `g1 = b2 ⊕ b1`, `g0 = b1 ⊕ b0`.', allowed=['xor'], ref=gray_ref)

# ------------------------------------------------------------------ 2. minimal forms
o5 = [0, 2, 5, 7, 8, 10, 13, 15]
expr(5, 'Karnaugh cu patru variabile', C2, 'ușoară', f'''
Scrie forma **minimă disjunctivă** (sumă de produse, cu cât mai puțini literali) a funcției

$$f(a, b, c, d) = \\sum m({', '.join(map(str, o5))}).$$

Harta Karnaugh de lângă câmp se umple pe măsură ce scrii.''',
    ['a', 'b', 'c', 'd'], [{'name': 'f', 'ones': o5}],
    'Grupează unitățile în dreptunghiuri de 2, 4 sau 8 celule; marginile hărții se ating (colțurile sunt vecine).',
    "Două grupuri de câte 4: colțurile și centrul. `f = b'd' + bd` (adică `b ⊙ d`).", form='sop', max_lit=min_sop_literals(4, o5), ref={'f': "b'd' + bd"})

o6, d6 = [1, 3, 7, 11, 15], [0, 2, 5]
expr(6, 'Cu termeni indiferenți', C2, 'medie', f'''
Forma minimă disjunctivă a funcției

$$f(a, b, c, d) = \\sum m({', '.join(map(str, o6))}) + d({', '.join(map(str, d6))}),$$

unde mintermii din `d(...)` sunt **indiferenți**: îi poți folosi ca 1 sau ca 0, cum te ajută (pe hartă apar cu `–`).''',
    ['a', 'b', 'c', 'd'], [{'name': 'f', 'ones': o6, 'dc': d6}],
    'Un termen indiferent merită inclus doar dacă face un grup mai mare.',
    "`f = cd + a'b'` — `a'b'` folosește indiferenții 0 și 2 ca să acopere 1 și 3 cu un grup de 4.", form='sop', max_lit=min_sop_literals(4, o6, d6), ref={'f': "cd + a'b'"})

z7 = [0, 1, 4, 5, 13, 15]
o7 = [m for m in range(16) if m not in z7]
expr(7, 'Forma minimă conjunctivă', C2, 'medie', f'''
Scrie forma **minimă conjunctivă** (produs de sume) a funcției care e 0 exact pe maxtermii

$$f(a, b, c, d) = \\prod M({', '.join(map(str, z7))}).$$

Exemplu de formă: `(a + c)(b' + d')`.''',
    ['a', 'b', 'c', 'd'], [{'name': 'f', 'ones': o7}],
    'Grupează zerourile pe hartă; fiecare grup dă o sumă, cu variabilele luate negat acolo unde în grup sunt 1.',
    "Zerourile 0, 1, 4, 5 dau `(a + c)`, iar 13, 15 dau `(a' + b' + d')`. `f = (a + c)(a' + b' + d')`.", form='pos', max_lit=min_pos_literals(4, o7), ref={'f': "(a + c)(a' + b' + d')"})

seg_a = [0, 2, 3, 5, 6, 7, 8, 9]
expr(8, 'Segmentul a al afișajului', C2, 'medie', '''
Un afișaj cu 7 segmente arată cifrele 0–9 primite în BCD pe 4 biți, `a b c d` (a e bitul cel mai semnificativ). Segmentul de sus (**a**) e aprins pentru cifrele 0, 2, 3, 5, 6, 7, 8, 9. Codurile 10–15 nu apar niciodată, deci sunt indiferente.

Scrie forma minimă disjunctivă a segmentului.''',
    ['a', 'b', 'c', 'd'], [{'name': 's', 'ones': seg_a, 'dc': list(range(10, 16))}],
    'Cu indiferenții 10–15, `a` singur acoperă 8 și 9.',
    "`s = a + c + bd + b'd'`: 6 literali.", form='sop', max_lit=min_sop_literals(4, seg_a, range(10, 16)), ref={'s': "a + c + bd + b'd'"},
    source='Examen PL · decodificator BCD — 7 segmente')

# ------------------------------------------------------------------ 3. combinational circuits
gt = minterms(4, lambda a1, a0, b1, b0: (2 * a1 + a0) > (2 * b1 + b0))
expr(9, 'Comparator pe doi biți', C3, 'medie', '''
`A = a1 a0` și `B = b1 b0` sunt numere pe 2 biți. Scrie forma minimă disjunctivă a ieșirii `g`, care e 1 când **A > B**.''',
    ['a1', 'a0', 'b1', 'b0'], [{'name': 'g', 'ones': gt}],
    'A > B dacă bitul de sus al lui A e mai mare, sau dacă biții de sus sunt egali și cel de jos al lui A e mai mare.',
    "`g = a1b1' + a0b1'b0' + a1a0b0'`.", form='sop', max_lit=min_sop_literals(4, gt), ref={'g': "a1b1' + a0b1'b0' + a1a0b0'"})

expr(10, 'Sumatorul complet', C3, 'ușoară', '''
Un sumator complet adună trei biți, `a`, `b` și transportul de intrare `t`, și dă bitul sumei `s` și transportul de ieșire `c`. Scrie ambele ieșiri (orice porți).

```
a b t   000  001  010  011  100  101  110  111
c s      00   01   01   10   01   10   10   11
```''',
    ['a', 'b', 't'],
    [{'name': 's', 'ones': minterms(3, lambda a, b, t: (a + b + t) % 2)}, {'name': 'c', 'ones': minterms(3, lambda a, b, t: a + b + t >= 2)}],
    'Suma e 1 când un număr impar de intrări e 1.',
    '`s = a ⊕ b ⊕ t`, `c = ab + t(a ⊕ b)` (sau `ab + bt + at`).', ref={'s': 'a⊕b⊕t', 'c': 'ab + t(a⊕b)'})

mux1 = [1, 2, 6, 7]
PROBLEMS.append(problem(11, 'Funcție pe un MUX 4:1', C3, 'medie', f'''
Realizează funcția

$$f(a, b, c) = \\sum m({', '.join(map(str, mux1))})$$

cu un **multiplexor 4:1**: pe selecție pui două variabile, iar pe fiecare intrare de date `0`, `1`, a treia variabilă sau negata ei.''', 'logic',
    {'mode': 'mux', 'vars': ['a', 'b', 'c'], 'outputs': [{'name': 'f', 'ones': mux1}], 'selects': 2, 'reference': {'sel': ['a', 'b'], 'data': ['c', "c'", '0', '1']}},
    'Cu `a b` pe selecție, intrarea `D(ab)` trebuie să fie f ca funcție de `c` pentru acele valori ale lui a și b.',
    "Selecție `S1 = a`, `S0 = b`: D0 = c (m1), D1 = c' (m2), D2 = 0, D3 = 1 (m6, m7).",
    'Test PL · implementarea funcțiilor cu multiplexoare'))

mux2 = [0, 1, 3, 6, 7, 9, 12, 14, 15]
PROBLEMS.append(problem(12, 'Funcție pe un MUX 8:1', C3, 'medie', f'''
Realizează

$$f(a, b, c, d) = \\sum m({', '.join(map(str, mux2))})$$

cu un **multiplexor 8:1**: trei variabile pe selecție, iar pe intrări `0`, `1`, a patra variabilă sau negata ei.''', 'logic',
    {'mode': 'mux', 'vars': ['a', 'b', 'c', 'd'], 'outputs': [{'name': 'f', 'ones': mux2}], 'selects': 3, 'reference': {'sel': ['a', 'b', 'c'], 'data': ['1', 'd', '0', '1', 'd', '0', "d'", '1']}},
    'Pentru fiecare combinație `abc`, uită-te la cei doi mintermi `abc0` și `abc1`: 00 → 0, 11 → 1, 01 → d, 10 → d\'.',
    "Cu `a b c` pe selecție: D0 = 1, D1 = d, D2 = 0, D3 = 1, D4 = d, D5 = 0, D6 = d', D7 = 1."))

# ------------------------------------------------------------------ 4. state machines
det101 = {'states': ['A', 'B', 'C'], 'start': 'A', 't': {'A': [['A', 0], ['B', 0]], 'B': [['C', 0], ['B', 0]], 'C': [['A', 0], ['B', 1]]}}
PROBLEMS.append(problem(13, 'Detectorul de secvență 101', C4, 'medie', '''
Proiectează un automat **Mealy** cu o intrare `x` și o ieșire `z`: `z = 1` exact la bitul care încheie secvența `101`. Secvențele se pot **suprapune**: pe intrarea `10101` ieșirea e `00101`.

Completează tabelul de tranziții (cu cât mai puține stări: 3 ajung) și încearcă-l pe intrări de test.''', 'logic',
    {'mode': 'fsm', 'target': det101, 'maxStates': 3, 'reference': det101},
    'Stările țin minte cât din `101` ai văzut deja: nimic, `1`, `10`. După ce ai găsit `101`, ultimul `1` poate începe o secvență nouă.',
    'A = nimic, B = „1”, C = „10”. Din C, cu 1: ieșire 1 și mergi în B (ultimul 1 contează); cu 0: înapoi în A. Din B, cu 1: rămâi în B.',
    'Test PL · automate de recunoaștere a secvențelor'))

div3 = {'states': ['R0', 'R1', 'R2'], 'start': 'R0', 't': {
    'R0': [['R0', 1], ['R1', 0]], 'R1': [['R2', 0], ['R0', 1]], 'R2': [['R1', 0], ['R2', 0]]}}
PROBLEMS.append(problem(14, 'Divizibil cu 3', C4, 'grea', '''
Biții unui număr vin pe intrarea `x`, de la cel mai semnificativ. După fiecare bit, ieșirea `z` (Mealy) spune dacă numărul citit **până atunci** e divizibil cu 3. De exemplu, pentru `110` (6) ieșirea e `011`: 1 nu, 3 da, 6 da.

Automatul trebuie să aibă cel mult 3 stări.''', 'logic',
    {'mode': 'fsm', 'target': div3, 'maxStates': 3, 'reference': div3},
    'Ține minte doar restul împărțirii la 3. Un bit nou `x` transformă numărul `n` în `2n + x`, deci restul `r` devine `(2r + x) mod 3`.',
    'Stările sunt resturile 0, 1, 2. Din restul r, cu bitul x, mergi în (2r + x) mod 3, iar ieșirea e 1 când acesta e 0.'))

# ------------------------------------------------------------------ more (2026-11)
expr(15, 'Implicația doar din porți NOR', C1, 'medie', '''
Implicația `a → b` e 0 doar când `a = 1` și `b = 0`, adică `f = a' + b`. Scrie-o folosind **numai porți NOR** (operatorul `↓`, de exemplu `a ↓ b`). Negația se scrie `a ↓ a`.

Ca NAND, și NOR e o poartă universală.''',
    ['a', 'b'], [{'name': 'f', 'ones': minterms(2, lambda a, b: (not a) or b)}],
    "O sumă negată e un NOR: `a' + b = ((a' ↓ b))'`, iar o negație e un NOR cu ea însăși.",
    "`a' = a ↓ a`; `t = a' ↓ b` e `(a' + b)'`; `f = t ↓ t`. Deci `f = ((a↓a)↓b)↓((a↓a)↓b)`: 3 porți distincte.",
    allowed=['nor'], ref={'f': '((a↓a)↓b)↓((a↓a)↓b)'})

o16 = [1, 3, 4, 6, 9, 11, 12, 14]
expr(16, 'O hartă în tablă de șah', C2, 'ușoară', f'''
Forma minimă disjunctivă a funcției

$$f(a, b, c, d) = \\sum m({', '.join(map(str, o16))}).$$

Uită-te bine la hartă înainte să grupezi: doar două variabile contează.''',
    ['a', 'b', 'c', 'd'], [{'name': 'f', 'ones': o16}],
    'Verifică pentru fiecare variabilă dacă schimbarea ei schimbă valoarea funcției.',
    "Funcția depinde doar de b și d: `f = b'd + bd'` (adică `b ⊕ d`), două grupuri de câte 4 celule, care se închid peste marginile hărții.",
    form='sop', max_lit=min_sop_literals(4, o16), ref={'f': "b'd + bd'"})

y1 = minterms(4, lambda d3, d2, d1, d0: d3 or d2)
y0 = minterms(4, lambda d3, d2, d1, d0: d3 or ((not d2) and d1))
vv = minterms(4, lambda d3, d2, d1, d0: d3 or d2 or d1 or d0)
expr(17, 'Codificatorul cu prioritate', C3, 'medie', '''
Un codificator cu prioritate 4:2 are intrările `d3 d2 d1 d0` și dă pe `y1 y0` indicele **celei mai mari** intrări egale cu 1 (`d3` are prioritatea cea mai mare). Ieșirea `v` spune dacă vreo intrare e activă; când `v = 0`, `y1 y0 = 00`.

Scrie cele trei ieșiri ca sume de produse minime.''',
    ['d3', 'd2', 'd1', 'd0'],
    [{'name': 'y1', 'ones': y1}, {'name': 'y0', 'ones': y0}, {'name': 'v', 'ones': vv}],
    'Indicele e 3 dacă `d3 = 1`, oricare ar fi celelalte; e 2 dacă `d3 = 0` și `d2 = 1`, și tot așa.',
    "`y1 = d3 + d2` (indicele 2 sau 3), `y0 = d3 + d2'd1` (indicele 3 sau 1), `v = d3 + d2 + d1 + d0`.",
    form='sop', max_lit=min_sop_literals(4, y1) + min_sop_literals(4, y0) + min_sop_literals(4, vv),
    ref={'y1': 'd3 + d2', 'y0': "d3 + d2'd1", 'v': 'd3 + d2 + d1 + d0'}, source='Test PL · codificatoare')

mux3 = [0, 3, 5, 6]
PROBLEMS.append(problem(18, 'Paritatea pe un MUX 4:1', C3, 'ușoară', f'''
Realizează cu un **multiplexor 4:1** funcția

$$f(a, b, c) = \\sum m({', '.join(map(str, mux3))}),$$

care e 1 când are un număr **par** de intrări egale cu 1. Pe selecție pui două variabile, pe date `0`, `1`, a treia variabilă sau negata ei.''', 'logic',
    {'mode': 'mux', 'vars': ['a', 'b', 'c'], 'outputs': [{'name': 'f', 'ones': mux3}], 'selects': 2, 'reference': {'sel': ['a', 'b'], 'data': ["c'", 'c', 'c', "c'"]}},
    'Pentru `ab = 00`, f e 1 doar dacă c = 0; pentru `ab = 01`, doar dacă c = 1...',
    "Cu `a b` pe selecție: D0 = c', D1 = c, D2 = c, D3 = c'. Nicio intrare nu e o constantă: paritatea depinde mereu de toți biții."))

par = {'states': ['P', 'I'], 'start': 'P', 't': {'P': [['P', 0], ['I', 1]], 'I': [['I', 1], ['P', 0]]}}
PROBLEMS.append(problem(19, 'Paritatea biților primiți', C4, 'ușoară', '''
Proiectează un automat **Mealy** cu o intrare `x` și o ieșire `z`: după fiecare bit, `z = 1` dacă până atunci au venit un număr **impar** de biți de 1. De exemplu, pentru `1101` ieșirea e `1001`.

Ajung 2 stări.''', 'logic',
    {'mode': 'fsm', 'target': par, 'maxStates': 2, 'reference': par},
    'Automatul trebuie să țină minte un singur lucru: paritatea de până acum.',
    'P = par, I = impar. Un 0 nu schimbă starea, un 1 o schimbă; ieșirea e 1 când starea în care ajungi e I.'))

det110 = {'states': ['A', 'B', 'C'], 'start': 'A', 't': {'A': [['A', 0], ['B', 0]], 'B': [['A', 0], ['C', 0]], 'C': [['A', 1], ['C', 0]]}}
PROBLEMS.append(problem(20, 'Detectorul de secvență 110', C4, 'medie', '''
Un automat **Mealy** cu intrarea `x` dă `z = 1` exact la bitul care încheie secvența `110`. De exemplu, pe intrarea `111010110` ieșirea e `000100001`.

Ajung 3 stări.''', 'logic',
    {'mode': 'fsm', 'target': det110, 'maxStates': 3, 'reference': det110},
    'Stările: nimic util, „1”, „11”. Din „11”, încă un 1 te lasă tot în „11” (ultimii doi biți sunt tot 11).',
    'A = nimic, B = „1”, C = „11”. A: 0 → A, 1 → B. B: 0 → A, 1 → C. C: 0 → A cu ieșirea 1, 1 → C.',
    'Test PL · automate de recunoaștere a secvențelor'))

write_course('pl', CHAPTERS, PROBLEMS)
