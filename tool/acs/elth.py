"""ELTH — Electrotehnică: circuits solved on the drawn schematic.

Topics from the ELTH finals (seria CD, 2022): Ohm and Kirchhoff, Thevenin,
maximum power, the Wheatstone bridge, sinusoidal steady state, resonance.
The numbers in the solutions (and the design targets) come from the small
nodal solver below; the app solves the same circuits with its own
(lib/acs/engine/circuit.dart) and the test checks they agree.
"""
import cmath, math, os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

C1 = '1. Circuite de curent continuu'
C2 = '2. Teoreme și proiectare'
C3 = '3. Regim sinusoidal'
CHAPTERS = [C1, C2, C3]
E = 'Examen ELTH · seria CD · 2022'
PROBLEMS = []


def R(n, a, b, v): return {'t': 'R', 'n': n, 'a': a, 'b': b, 'v': v}
def V(n, a, b, v, ph=0): return {'t': 'V', 'n': n, 'a': a, 'b': b, 'v': v, 'ph': ph}
def J(n, a, b, v): return {'t': 'I', 'n': n, 'a': a, 'b': b, 'v': v}
def Cc(n, a, b, v): return {'t': 'C', 'n': n, 'a': a, 'b': b, 'v': v}
def Ll(n, a, b, v): return {'t': 'L', 'n': n, 'a': a, 'b': b, 'v': v}
def W(a, b): return {'t': 'W', 'a': a, 'b': b}
def G(a): return {'t': 'G', 'a': a}


def solve(elems, omega=0.0):
    """Independent MNA: currents a->b and voltages V(a)-V(b) of every named element."""
    parent = {}
    def f(p):
        p = tuple(p)
        parent.setdefault(p, p)
        while parent[p] != p:
            p = parent[p]
        return p
    for e in elems:
        f(e['a']); f(e.get('b', e['a']))
        if e['t'] == 'W':
            parent[f(e['a'])] = f(e['b'])
    gnd = next((f(e['a']) for e in elems if e['t'] == 'G'), None)
    roots = sorted({f(p) for p in parent})
    gnd = gnd or roots[0]
    idx = {r: i for i, r in enumerate(r for r in roots if r != gnd)}
    n = len(idx)
    vs = [e for e in elems if e['t'] == 'V' or (e['t'] == 'L' and omega == 0)]
    A = np.zeros((n + len(vs), n + len(vs)), complex)
    b = np.zeros(n + len(vs), complex)
    node = lambda p: idx.get(f(p))
    def y(e):
        return {'R': 1 / e['v'], 'C': 1j * omega * e['v'], 'L': 1 / (1j * omega * e['v']) if omega else 0}.get(e['t'], 0)
    for e in elems:
        i, j = node(e['a']), node(e.get('b', e['a']))
        if e['t'] in 'RCL' and not (e['t'] == 'C' and omega == 0) and not (e['t'] == 'L' and omega == 0):
            g = y(e)
            for p, q, s in [(i, i, 1), (j, j, 1), (i, j, -1), (j, i, -1)]:
                if p is not None and q is not None:
                    A[p, q] += s * g
        if e['t'] == 'I':
            cur = cmath.rect(e['v'], math.radians(e.get('ph', 0)))
            if i is not None: b[i] -= cur
            if j is not None: b[j] += cur
    for k, e in enumerate(vs):
        i, j, r = node(e['a']), node(e['b']), n + k
        if i is not None: A[i, r] += 1; A[r, i] += 1
        if j is not None: A[j, r] -= 1; A[r, j] -= 1
        b[r] = cmath.rect(e['v'], math.radians(e.get('ph', 0))) if e['t'] == 'V' else 0
    x = np.linalg.solve(A, b)
    pot = lambda p: 0 if node(p) is None else x[node(p)]
    cur, volt = {}, {}
    for e in elems:
        if e['t'] in 'GW':
            continue
        u = pot(e['a']) - pot(e['b'])
        volt[e['n']] = u
        if e in vs:
            cur[e['n']] = x[n + vs.index(e)]
        elif e['t'] == 'I':
            cur[e['n']] = cmath.rect(e['v'], math.radians(e.get('ph', 0)))
        elif e['t'] == 'C' and omega == 0:
            cur[e['n']] = 0
        else:
            cur[e['n']] = u * y(e)
    return cur, volt


def q(elems, quantity, omega=0.0):
    cur, volt = solve(elems, omega)
    kind, name = quantity.split('.')
    i, u = cur[name], volt[name]
    return {'I': i.real, 'U': u.real, 'absI': abs(i), 'absU': abs(u), 'phI': math.degrees(cmath.phase(i)), 'phU': math.degrees(cmath.phase(u)),
            'P': (u * i.conjugate()).real}[kind]


def fmt(v, d=3):
    return f'{v:.{d}g}'.replace('.', ',')


def circuit(id, title, ch, diff, statement, elems, grid, ask=None, design=None, omega=0.0, hint='', solution='', source=''):
    spec = {'elems': elems, 'grid': grid, 'omega': omega}
    if ask:
        spec['ask'] = ask
        spec['expect'] = {a['q']: q(elems, a['q'], omega) for a in ask}
    if design:
        spec['design'] = design
    PROBLEMS.append(problem(id, title, ch, diff, statement, 'circuit', spec, hint, solution, source))


# ------------------------------------------------------------------ 1. DC
c1 = [V('E', [0, 0], [0, 3], 12), W([0, 0], [2, 0]), R('R1', [2, 0], [4, 0], 4), W([4, 0], [5, 0]), R('R2', [5, 0], [5, 3], 2), W([5, 3], [0, 3]), G([0, 3])]
circuit(1, 'Divizorul de tensiune', C1, 'ușoară', '''
Sursa $E = 12\\,\\text{V}$ alimentează rezistențele $R_1 = 4\\,\\Omega$ și $R_2 = 2\\,\\Omega$ legate în serie. Calculează curentul prin $R_1$ și tensiunea la bornele lui $R_2$, în sensurile săgeților de pe schemă.''',
    c1, [6, 4], ask=[{'q': 'I.R1', 'label': 'I (prin R1)', 'unit': 'A'}, {'q': 'U.R2', 'label': 'U (pe R2)', 'unit': 'V'}],
    hint='În serie curentul e același: $I = E / (R_1 + R_2)$.', solution='$I = 12/6 = 2\\,\\text{A}$, $U_2 = R_2 I = 4\\,\\text{V}$ — divizorul dă $E \\cdot R_2/(R_1 + R_2)$.')

c2 = [V('E', [0, 0], [0, 4], 10), W([0, 0], [1, 0]), R('R1', [1, 0], [3, 0], 2), W([3, 0], [4, 0]), W([4, 0], [6, 0]), R('R2', [4, 0], [4, 4], 6), R('R3', [6, 0], [6, 4], 3),
      W([6, 4], [4, 4]), W([4, 4], [0, 4]), G([0, 4])]
circuit(2, 'Serie și paralel', C1, 'ușoară', '''
$E = 10\\,\\text{V}$, $R_1 = 2\\,\\Omega$, $R_2 = 6\\,\\Omega$, $R_3 = 3\\,\\Omega$. Calculează curentul prin $R_1$ și curentul prin $R_3$.''',
    c2, [7, 5], ask=[{'q': 'I.R1', 'label': 'I1', 'unit': 'A'}, {'q': 'I.R3', 'label': 'I3', 'unit': 'A'}],
    hint='$R_2 \\parallel R_3 = \\frac{R_2 R_3}{R_2 + R_3}$, apoi divizorul de curent.',
    solution=f"$R_e = 2 + 2 = 4\\,\\Omega$, $I_1 = 2{{,}}5\\,\\text{{A}}$; tensiunea pe grupul paralel e 5 V, deci $I_3 = 5/3 \\approx {fmt(q(c2, 'I.R3'))}\\,\\text{{A}}$.")

c3 = [V('E1', [0, 0], [0, 4], 12), W([0, 0], [1, 0]), R('R1', [1, 0], [3, 0], 2), W([3, 0], [4, 0]), R('R3', [4, 0], [4, 4], 6), W([4, 0], [5, 0]), R('R2', [5, 0], [7, 0], 4), W([7, 0], [8, 0]),
      V('E2', [8, 0], [8, 4], 6), W([8, 4], [4, 4]), W([4, 4], [0, 4]), G([0, 4])]
circuit(3, 'Teoremele lui Kirchhoff', C1, 'medie', f'''
Două surse, $E_1 = 12\\,\\text{{V}}$ și $E_2 = 6\\,\\text{{V}}$, alimentează împreună rezistența $R_3 = 6\\,\\Omega$ prin $R_1 = 2\\,\\Omega$ și $R_2 = 4\\,\\Omega$. Calculează curenții prin $R_1$, $R_2$ și $R_3$, în sensurile săgeților (un curent negativ înseamnă sens opus).''',
    c3, [9, 5], ask=[{'q': 'I.R1', 'label': 'I1', 'unit': 'A'}, {'q': 'I.R2', 'label': 'I2', 'unit': 'A'}, {'q': 'I.R3', 'label': 'I3', 'unit': 'A'}],
    hint='Un singur nod independent (sus, la R3): scrie potențialul lui cu metoda potențialelor nodurilor.',
    solution=f"Cu $V$ potențialul nodului din mijloc: $\\frac{{12 - V}}{{2}} + \\frac{{6 - V}}{{4}} = \\frac{{V}}{{6}}$, deci $V = {fmt(q(c3, 'U.R3'), 4)}\\,\\text{{V}}$; $I_1 = {fmt(q(c3, 'I.R1'))}$, $I_2 = {fmt(q(c3, 'I.R2'))}$, $I_3 = {fmt(q(c3, 'I.R3'))}\\,\\text{{A}}$.",
    source=E)

c4 = [J('J', [0, 4], [0, 0], 2), W([0, 0], [2, 0]), R('R1', [2, 0], [2, 4], 5), W([2, 0], [3, 0]), R('R2', [3, 0], [5, 0], 3), W([5, 0], [6, 0]), V('E', [6, 0], [6, 4], 4),
      W([6, 4], [2, 4]), W([2, 4], [0, 4]), G([0, 4])]
circuit(4, 'Cu o sursă de curent', C1, 'medie', '''
Sursa de curent $J = 2\\,\\text{A}$ și sursa de tensiune $E = 4\\,\\text{V}$ lucrează în același circuit, cu $R_1 = 5\\,\\Omega$ și $R_2 = 3\\,\\Omega$. Calculează curentul prin $R_1$ și tensiunea pe $R_2$.''',
    c4, [7, 5], ask=[{'q': 'I.R1', 'label': 'I1', 'unit': 'A'}, {'q': 'U.R2', 'label': 'U2', 'unit': 'V'}],
    hint='Nodul de sus din stânga primește J; scrie Kirchhoff I acolo.',
    solution=f"Potențialul nodului: $2 = \\frac{{V}}{{5}} + \\frac{{V - 4}}{{3}}$, $V = {fmt(q(c4, 'I.R1') * 5, 4)}\\,\\text{{V}}$; $I_1 = {fmt(q(c4, 'I.R1'))}\\,\\text{{A}}$, $U_2 = {fmt(q(c4, 'U.R2'))}\\,\\text{{V}}$.")

# ------------------------------------------------------------------ 2. theorems and design
def mp(rl):
    c = [V('E', [0, 0], [0, 4], 24), W([0, 0], [1, 0]), R('R1', [1, 0], [3, 0], 6), W([3, 0], [4, 0]), R('R2', [4, 0], [4, 4], 3), W([4, 0], [6, 0]), R('RL', [6, 0], [6, 4], rl),
         W([6, 4], [4, 4]), W([4, 4], [0, 4]), G([0, 4])]
    return c
pmax = q(mp(2.0), 'P.RL')
circuit(5, 'Transferul maxim de putere', C2, 'medie', f'''
Alege rezistența de sarcină $R_L$ astfel încât **puterea pe ea să fie maximă**. Apasă „măsoară” ca să vezi puterea cu valoarea ta, apoi verifică (se acceptă o abatere de 0,2% de la maxim).

$E = 24\\,\\text{{V}}$, $R_1 = 6\\,\\Omega$, $R_2 = 3\\,\\Omega$.''',
    mp(1.0), [7, 5], design={'vars': [{'name': 'RL', 'label': 'R_L', 'unit': 'Ω'}], 'target': {'q': 'P.RL', 'value': pmax, 'tol': 0.002, 'label': 'puterea pe R_L e maximă', 'meter': 'wattmetrul pe R_L', 'unit': 'W'}, 'reference': {'RL': '2'}},
    hint='Puterea e maximă când $R_L$ e egală cu rezistența Thévenin văzută de la bornele ei (cu sursa pasivizată).',
    solution=f'$R_{{Th}} = R_1 \\parallel R_2 = 2\\,\\Omega$, $E_{{Th}} = 24 \\cdot 3/9 = 8\\,\\text{{V}}$; $P_{{max}} = E_{{Th}}^2/(4R_{{Th}}) = {fmt(pmax)}\\,\\text{{W}}$.', source=E)

def div(r2):
    return [V('E', [0, 0], [0, 3], 5), W([0, 0], [2, 0]), R('R1', [2, 0], [4, 0], 1000), W([4, 0], [5, 0]), R('R2', [5, 0], [5, 3], r2), W([5, 3], [0, 3]), G([0, 3])]
circuit(6, 'Un divizor pentru 3,3 V', C2, 'ușoară', '''
Un senzor are nevoie de 3,3 V, iar placa dă 5 V. Cu $R_1 = 1\\,\\text{k}\\Omega$, alege $R_2$ astfel încât tensiunea pe ea să fie **3,3 V** (±1%).''',
    div(1000), [6, 4], design={'vars': [{'name': 'R2', 'label': 'R2', 'unit': 'Ω'}], 'target': {'q': 'U.R2', 'value': 3.3, 'tol': 0.01, 'label': 'tensiunea pe R2 e 3,3 V', 'meter': 'voltmetrul pe R2', 'unit': 'V'}, 'reference': {'R2': '1941'}},
    hint='$U_2 = E \\frac{R_2}{R_1 + R_2}$; rezolvă după $R_2$.', solution='$R_2 = R_1 \\frac{U_2}{E - U_2} = 1000 \\cdot \\frac{3{,}3}{1{,}7} \\approx 1941\\,\\Omega$.')

def bridge(rx):
    return [V('E', [0, 0], [0, 6], 10), W([0, 0], [2, 0]), W([2, 0], [6, 0]), R('R1', [2, 0], [2, 3], 100), R('R2', [6, 0], [6, 3], 200), R('R3', [2, 3], [2, 6], 150), R('Rx', [6, 3], [6, 6], rx),
            R('Rg', [2, 3], [6, 3], 50), W([6, 6], [2, 6]), W([2, 6], [0, 6]), G([0, 6])]
circuit(7, 'Puntea Wheatstone', C2, 'medie', '''
În puntea de pe schemă, $R_g$ e galvanometrul. Alege $R_x$ astfel încât **prin galvanometru să nu treacă curent** (puntea echilibrată, |I| < 0,1 mA).''',
    bridge(100), [7, 7], design={'vars': [{'name': 'Rx', 'label': 'R_x', 'unit': 'Ω'}], 'target': {'q': 'I.Rg', 'value': 0, 'abstol': 1e-4, 'label': 'prin galvanometru nu trece curent', 'meter': 'curentul prin galvanometru', 'unit': 'A'}, 'reference': {'Rx': '300'}},
    hint='La echilibru, cele două noduri din mijloc au același potențial: rapoartele sunt egale.', solution='$\\frac{R_1}{R_3} = \\frac{R_2}{R_x}$, deci $R_x = R_2 R_3 / R_1 = 300\\,\\Omega$.')

# ------------------------------------------------------------------ 3. AC
w1 = 1000.0
c8 = [V('U', [0, 0], [0, 3], 10), W([0, 0], [1, 0]), R('R', [1, 0], [3, 0], 100), W([3, 0], [4, 0]), Cc('C', [4, 0], [4, 3], 10e-6), W([4, 3], [0, 3]), G([0, 3])]
circuit(8, 'Circuit RC serie', C3, 'medie', f'''
Tensiunea sinusoidală are valoarea efectivă $U = 10\\,\\text{{V}}$ și faza 0, la $\\omega = 1000\\,\\text{{rad/s}}$; $R = 100\\,\\Omega$, $C = 10\\,\\mu\\text{{F}}$. Calculează valoarea efectivă a curentului și faza lui (în grade).''',
    c8, [5, 4], omega=w1, ask=[{'q': 'absI.R', 'label': '|I|', 'unit': 'A'}, {'q': 'phI.R', 'label': 'faza lui I', 'unit': '°'}],
    hint='$\\underline{Z} = R - j/(\\omega C)$.', solution=f"$X_C = 100\\,\\Omega$, $|Z| = 100\\sqrt2$, $|I| = {fmt(q(c8, 'absI.R', w1))}\\,\\text{{A}}$; curentul e defazat înaintea tensiunii cu 45°.")

w2 = 2 * math.pi * 50
c9 = [V('U', [0, 0], [0, 3], 220), W([0, 0], [1, 0]), R('R', [1, 0], [3, 0], 30), W([3, 0], [4, 0]), Ll('L', [4, 0], [4, 3], 40 / w2), W([4, 3], [0, 3]), G([0, 3])]
circuit(9, 'Bobina reală la rețea', C3, 'medie', f'''
O bobină cu rezistența $R = 30\\,\\Omega$ și reactanța $X_L = 40\\,\\Omega$ (la 50 Hz) e legată la rețeaua de $220\\,\\text{{V}}$. Calculează curentul efectiv și puterea activă consumată.''',
    c9, [5, 4], omega=w2, ask=[{'q': 'absI.R', 'label': '|I|', 'unit': 'A'}, {'q': 'P.R', 'label': 'P', 'unit': 'W'}],
    hint='$|Z| = \\sqrt{R^2 + X_L^2}$; puterea activă se consumă doar pe R.', solution=f"$|Z| = 50\\,\\Omega$, $I = 4{{,}}4\\,\\text{{A}}$, $P = R I^2 = {fmt(q(c9, 'P.R', w2), 4)}\\,\\text{{W}}$.", source=E)

def rlc(c):
    return [V('U', [0, 0], [0, 3], 10), W([0, 0], [1, 0]), R('R', [1, 0], [3, 0], 20), W([3, 0], [4, 0]), Ll('L', [4, 0], [6, 0], 0.1), W([6, 0], [7, 0]), Cc('C', [7, 0], [7, 3], c), W([7, 3], [0, 3]), G([0, 3])]
circuit(10, 'Rezonanța serie', C3, 'medie', '''
Alege capacitatea $C$ astfel încât circuitul RLC serie să fie **la rezonanță** la $\\omega = 1000\\,\\text{rad/s}$ ($R = 20\\,\\Omega$, $L = 0{,}1\\,\\text{H}$, $U = 10\\,\\text{V}$). La rezonanță curentul e maxim: $U/R$. Poți scrie `10e-6` pentru 10 µF.''',
    rlc(5e-6), [8, 4], omega=1000.0, design={'vars': [{'name': 'C', 'label': 'C', 'unit': 'F'}], 'target': {'q': 'absI.R', 'value': 0.5, 'tol': 0.002, 'label': 'curentul e maxim (U/R = 0,5 A)', 'meter': 'ampermetrul', 'unit': 'A'}, 'reference': {'C': '10e-6'}},
    hint='Rezonanță: $\\omega L = \\frac{1}{\\omega C}$.', solution='$C = \\frac{1}{\\omega^2 L} = \\frac{1}{10^6 \\cdot 0{,}1} = 10\\,\\mu\\text{F}$.')

# ------------------------------------------------------------------ more (2026-11)
c11 = [V('E', [0, 0], [0, 4], 12), W([0, 0], [2, 0]), W([2, 0], [4, 0]), W([4, 0], [6, 0]),
       R('R1', [2, 0], [2, 4], 4), R('R2', [4, 0], [4, 4], 6), R('R3', [6, 0], [6, 4], 12),
       W([6, 4], [4, 4]), W([4, 4], [2, 4]), W([2, 4], [0, 4]), G([0, 4])]
circuit(11, 'Trei rezistențe în paralel', C1, 'ușoară', '''
Sursa $E = 12\\,\\text{V}$ alimentează în paralel $R_1 = 4\\,\\Omega$, $R_2 = 6\\,\\Omega$ și $R_3 = 12\\,\\Omega$. Calculează curentul prin $R_1$, curentul prin $R_3$ și puterea disipată pe $R_2$.''',
    c11, [7, 5], ask=[{'q': 'I.R1', 'label': 'I1', 'unit': 'A'}, {'q': 'I.R3', 'label': 'I3', 'unit': 'A'}, {'q': 'P.R2', 'label': 'P2', 'unit': 'W'}],
    hint='În paralel, fiecare rezistență are la borne toată tensiunea sursei.',
    solution=f"$I_1 = 12/4 = 3\\,\\text{{A}}$, $I_3 = 12/12 = 1\\,\\text{{A}}$, $P_2 = U^2/R_2 = 144/6 = {fmt(q(c11, 'P.R2'))}\\,\\text{{W}}$. Rezistența echivalentă: $\\frac{{1}}{{R_e}} = \\frac14 + \\frac16 + \\frac{{1}}{{12}} = \\frac12$, $R_e = 2\\,\\Omega$, curentul total 6 A.")


def lim(r2):
    return [V('E', [0, 0], [0, 3], 12), W([0, 0], [2, 0]), R('R1', [2, 0], [4, 0], 4), W([4, 0], [5, 0]), R('R2', [5, 0], [5, 3], r2), W([5, 3], [0, 3]), G([0, 3])]
circuit(12, 'Rezistența pentru un curent dat', C2, 'ușoară', '''
Sursa $E = 12\\,\\text{V}$ și rezistența interioară $R_1 = 4\\,\\Omega$ alimentează sarcina $R_2$. Alege $R_2$ astfel încât **curentul prin ea să fie 1 A** (±1%).''',
    lim(2), [6, 4], design={'vars': [{'name': 'R2', 'label': 'R2', 'unit': 'Ω'}], 'target': {'q': 'I.R2', 'value': 1.0, 'tol': 0.01, 'label': 'curentul prin R2 e 1 A', 'meter': 'ampermetrul', 'unit': 'A'}, 'reference': {'R2': '8'}},
    hint='În serie: $I = \\frac{E}{R_1 + R_2}$; rezolvă după $R_2$.', solution='$R_1 + R_2 = E / I = 12\\,\\Omega$, deci $R_2 = 8\\,\\Omega$.')

w3 = 1000.0
c13 = [V('U', [0, 0], [0, 4], 10), W([0, 0], [2, 0]), W([2, 0], [4, 0]), R('R', [2, 0], [2, 4], 100), Ll('L', [4, 0], [4, 4], 0.1),
       W([4, 4], [2, 4]), W([2, 4], [0, 4]), G([0, 4])]
circuit(13, 'R și L în paralel', C3, 'medie', f'''
O tensiune sinusoidală cu valoarea efectivă $U = 10\\,\\text{{V}}$, faza 0, $\\omega = 1000\\,\\text{{rad/s}}$, alimentează în paralel $R = 100\\,\\Omega$ și $L = 0{{,}}1\\,\\text{{H}}$. Calculează valoarea efectivă a curentului prin bobină și faza lui, apoi puterea activă pe $R$.''',
    c13, [5, 5], omega=w3, ask=[{'q': 'absI.L', 'label': '|I_L|', 'unit': 'A'}, {'q': 'phI.L', 'label': 'faza lui I_L', 'unit': '°'}, {'q': 'P.R', 'label': 'P', 'unit': 'W'}],
    hint='Fiecare ramură are la borne toată tensiunea; $\\underline{Z}_L = j\\omega L$.',
    solution=f"$X_L = \\omega L = 100\\,\\Omega$, $\\underline{{I}}_L = \\frac{{10}}{{j \\cdot 100}} = -0{{,}}1j$: $|I_L| = {fmt(q(c13, 'absI.L', w3))}\\,\\text{{A}}$, defazat cu 90° în urma tensiunii. $P = U^2/R = {fmt(q(c13, 'P.R', w3))}\\,\\text{{W}}$; bobina ideală nu consumă putere activă.")

write_course('elth', CHAPTERS, PROBLEMS)
