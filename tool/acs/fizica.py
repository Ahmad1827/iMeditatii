"""Fizică (Mecanică): experiments simulated with the student's numbers.

Topics from the Mecanică seminars and exam (seria CD, 2022). The expected
values are computed here from the formulas; the app's engine
(lib/acs/engine/physics.dart) computes its own and the test checks they agree.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

C1 = '1. Cinematică'
C2 = '2. Dinamică și frecare'
C3 = '3. Impuls și ciocniri'
C4 = '4. Oscilații'
CHAPTERS = [C1, C2, C3, C4]
g = 9.81
PROBLEMS = []


def sim(id, title, ch, diff, statement, kind, params, fields, expect, hint, solution, source='', tol=0.01):
    spec = {'sim': kind, 'params': params, 'fields': fields, 'expect': expect, 'tol': tol}
    PROBLEMS.append(problem(id, title, ch, diff, statement, 'sim', spec, hint, solution, source))


def f(name, label, unit=None):
    d = {'name': name, 'label': label}
    if unit: d['unit'] = unit
    return d


# ------------------------------------------------------------------ 1
a, h0, d, ht = 45, 2.0, 6.0, 3.05
v0 = math.sqrt(g * d * d / (2 * math.cos(math.radians(a)) ** 2 * (h0 + d * math.tan(math.radians(a)) - ht)))
sim(1, 'Aruncarea la coș', C1, 'medie', f'''
Un jucător aruncă mingea de la înălțimea $h_0 = {h0}\\,\\text{{m}}$, sub un unghi de ${a}^\\circ$ față de orizontală. Coșul e la distanța orizontală $d = {d}\\,\\text{{m}}$ și la înălțimea $3{{,}}05\\,\\text{{m}}$. Cu ce viteză $v_0$ trebuie aruncată mingea ca să intre în coș, și în cât timp ajunge acolo? ($g = 9{{,}}81\\,\\text{{m/s}}^2$, fără frecare cu aerul.)

„Lansează” aruncă mingea cu viteza ta.''', 'projectile', {'angle': a, 'h0': h0, 'd': d, 'ht': ht},
    [f('v0', 'v₀', 'm/s'), f('t', 't (până la coș)', 's')], {'v0': v0, 't': d / (v0 * math.cos(math.radians(a)))},
    'Scrie $x(t)$ și $y(t)$, elimină timpul: $y = h_0 + x\\tan\\alpha - \\frac{g x^2}{2 v_0^2 \\cos^2\\alpha}$, și pune condiția $y(d) = 3{,}05$.',
    f'$v_0 = \\sqrt{{\\frac{{g d^2}}{{2\\cos^2\\alpha\\,(h_0 + d\\tan\\alpha - h)}}}} \\approx {v0:.2f}\\,\\text{{m/s}}$, iar $t = d/(v_0\\cos\\alpha) \\approx {d / (v0 * math.cos(math.radians(a))):.2f}\\,\\text{{s}}$.')

h1, d1 = 1.25, 2.0
t1 = math.sqrt(2 * h1 / g)
sim(2, 'De pe masă', C1, 'ușoară', f'''
O bilă e lansată orizontal de pe marginea unei mese înalte de $h = {h1}\\,\\text{{m}}$ și trebuie să cadă într-un pahar aflat pe podea la $d = {d1}\\,\\text{{m}}$ de masă. Cât durează căderea și ce viteză orizontală trebuie să aibă bila?''',
    'projectile', {'angle': 0, 'h0': h1, 'd': d1, 'ht': 0, 'hoop': 0.08}, [f('t', 't', 's'), f('v0', 'v₀', 'm/s')], {'t': t1, 'v0': d1 / t1},
    'Pe verticală e o cădere liberă: $h = g t^2 / 2$.', f'$t = \\sqrt{{2h/g}} \\approx {t1:.3f}\\,\\text{{s}}$, $v_0 = d/t \\approx {d1 / t1:.2f}\\,\\text{{m/s}}$.')

v2 = 20.0
sim(3, 'Bătaia maximă', C1, 'ușoară', f'''
Un proiectil e lansat de la nivelul solului cu viteza $v_0 = {v2:.0f}\\,\\text{{m/s}}$. Sub ce unghi ajunge cel mai departe, și cât e atunci bătaia? Încearcă mai multe unghiuri cu „lansează”.''',
    'range', {'v0': v2}, [f('alpha', 'α', '°'), f('R', 'bătaia', 'm')], {'alpha': 45, 'R': v2 * v2 / g},
    'Bătaia e $R = \\frac{v_0^2 \\sin 2\\alpha}{g}$.', f'Maximul lui $\\sin 2\\alpha$ e la $\\alpha = 45^\\circ$: $R = v_0^2/g \\approx {v2 * v2 / g:.1f}\\,\\text{{m}}$.')

# ------------------------------------------------------------------ 2
th, mu, L = 30, 0.2, 4.0
acc = g * (math.sin(math.radians(th)) - mu * math.cos(math.radians(th)))
sim(4, 'Planul înclinat cu frecare', C2, 'medie', f'''
Un corp pornește din repaus din vârful unui plan înclinat cu ${th}^\\circ$, lung de $L = {L:.0f}\\,\\text{{m}}$, cu coeficientul de frecare $\\mu = {mu}$. Află accelerația și timpul în care ajunge jos.''',
    'incline', {'angle': th, 'mu': mu, 'L': L}, [f('a', 'a', 'm/s²'), f('t', 't', 's')], {'a': acc, 't': math.sqrt(2 * L / acc)},
    'Pe direcția planului: $m a = m g \\sin\\theta - \\mu m g \\cos\\theta$.', f'$a = g(\\sin\\theta - \\mu\\cos\\theta) \\approx {acc:.3f}\\,\\text{{m/s}}^2$, $t = \\sqrt{{2L/a}} \\approx {math.sqrt(2 * L / acc):.3f}\\,\\text{{s}}$.',
    source='Seminar Mecanică · dinamica punctului material')

th2 = 25
sim(5, 'Frecarea care ține corpul pe loc', C2, 'ușoară', f'''
Care e **cel mai mic** coeficient de frecare statică pentru care un corp lăsat liber pe un plan înclinat cu ${th2}^\\circ$ rămâne pe loc? „Lansează” lasă corpul pe plan cu frecarea ta.''',
    'friction', {'angle': th2, 'L': 3}, [f('mu', 'μ minim')], {'mu': math.tan(math.radians(th2))},
    'La limită, frecarea maximă $\\mu N$ echilibrează componenta greutății de-a lungul planului.', f'$\\mu m g\\cos\\theta = m g\\sin\\theta$, deci $\\mu = \\tan\\theta \\approx {math.tan(math.radians(th2)):.3f}$.')

m1, m2 = 3.0, 2.0
sim(6, 'Mașina Atwood', C2, 'medie', f'''
Două corpuri, $m_1 = {m1:.0f}\\,\\text{{kg}}$ și $m_2 = {m2:.0f}\\,\\text{{kg}}$, atârnă de capetele unui fir trecut peste un scripete ideal. Află accelerația sistemului și tensiunea din fir.''',
    'atwood', {'m1': m1, 'm2': m2}, [f('a', 'a', 'm/s²'), f('T', 'T', 'N')], {'a': (m1 - m2) * g / (m1 + m2), 'T': 2 * m1 * m2 * g / (m1 + m2)},
    'Scrie legea a doua pentru fiecare corp: $m_1 a = m_1 g - T$, $m_2 a = T - m_2 g$.', f'$a = \\frac{{m_1 - m_2}}{{m_1 + m_2}} g \\approx {(m1 - m2) * g / (m1 + m2):.3f}\\,\\text{{m/s}}^2$, $T = \\frac{{2 m_1 m_2}}{{m_1 + m_2}} g \\approx {2 * m1 * m2 * g / (m1 + m2):.2f}\\,\\text{{N}}$.')

# ------------------------------------------------------------------ 3
p = {'m1': 2, 'v1': 3, 'm2': 1, 'v2': -1, 'elastic': 0}
vv = (2 * 3 + 1 * -1) / 3
sim(7, 'Ciocnirea plastică', C3, 'ușoară', '''
O căruță de 2 kg cu viteza 3 m/s se ciocnește de o căruță de 1 kg care vine din sens opus cu 1 m/s; după ciocnire rămân lipite. Află viteza comună (pozitiv: sensul primei căruțe) și energia transformată în căldură.''',
    'collision', p, [f('v', 'v (după)', 'm/s'), f('Q', 'energia pierdută', 'J')], {'v': vv, 'Q': 0.5 * 2 * 9 + 0.5 * 1 * 1 - 0.5 * 3 * vv * vv},
    'Impulsul se conservă; energia cinetică nu.', f'$v = \\frac{{2 \\cdot 3 + 1 \\cdot (-1)}}{{3}} = \\frac{{5}}{{3}}\\,\\text{{m/s}}$; $Q = 9{{,}}5 - \\frac{{3}}{{2}}\\left(\\frac{{5}}{{3}}\\right)^2 \\approx {0.5 * 2 * 9 + 0.5 - 1.5 * vv * vv:.3f}\\,\\text{{J}}$.')

p2 = {'m1': 1, 'v1': 4, 'm2': 3, 'v2': 0, 'elastic': 1}
sim(8, 'Ciocnirea elastică', C3, 'medie', '''
O bilă de 1 kg cu viteza 4 m/s lovește frontal și **perfect elastic** o bilă de 3 kg aflată în repaus. Află vitezele după ciocnire (pozitiv: sensul inițial al primei bile).''',
    'collision', p2, [f('v1p', "v₁'", 'm/s'), f('v2p', "v₂'", 'm/s')], {'v1p': -2.0, 'v2p': 2.0},
    'Se conservă și impulsul, și energia cinetică: $v_1\' = \\frac{(m_1 - m_2)v_1 + 2m_2v_2}{m_1 + m_2}$.', "$v_1' = \\frac{(1-3)\\cdot 4}{4} = -2\\,\\text{m/s}$ (se întoarce), $v_2' = \\frac{2\\cdot 1\\cdot 4}{4} = 2\\,\\text{m/s}$.",
    source='Examen Mecanică · seria CD · 2022')

# ------------------------------------------------------------------ 4
m, k, A = 0.5, 50.0, 0.1
sim(9, 'Oscilatorul cu resort', C4, 'ușoară', f'''
Un corp de $m = {m}\\,\\text{{kg}}$ prins de un resort cu $k = {k:.0f}\\,\\text{{N/m}}$ oscilează cu amplitudinea $A = {A}\\,\\text{{m}}$. Află perioada și viteza maximă. Corpul punctat oscilează cu perioada ta.''',
    'spring', {'m': m, 'k': k, 'A': A}, [f('T', 'T', 's'), f('vmax', 'v max', 'm/s')], {'T': 2 * math.pi * math.sqrt(m / k), 'vmax': math.sqrt(k / m) * A},
    '$\\omega = \\sqrt{k/m}$, $T = 2\\pi/\\omega$, $v_{max} = \\omega A$.', f'$\\omega = 10\\,\\text{{rad/s}}$, $T = \\pi/5 \\approx {2 * math.pi * math.sqrt(m / k):.4f}\\,\\text{{s}}$, $v_{{max}} = 1\\,\\text{{m/s}}$.')

Lp = 1.0
sim(10, 'Pendulul simplu', C4, 'ușoară', f'''
Care e perioada micilor oscilații ale unui pendul cu lungimea $\\ell = {Lp:.0f}\\,\\text{{m}}$? Pendulul punctat se leagănă cu perioada ta: dacă e corectă, cele două merg împreună.''',
    'pendulum', {'L': Lp}, [f('T', 'T', 's')], {'T': 2 * math.pi * math.sqrt(Lp / g)},
    'Pentru unghiuri mici, $\\sin\\theta \\approx \\theta$ și mișcarea e armonică.', f'$T = 2\\pi\\sqrt{{\\ell/g}} \\approx {2 * math.pi * math.sqrt(Lp / g):.3f}\\,\\text{{s}}$.')

# ------------------------------------------------------------------ more (2026-11)
a11, h11, d11, ht11 = 30, 1.0, 10.0, 2.0
v11 = math.sqrt(g * d11 * d11 / (2 * math.cos(math.radians(a11)) ** 2 * (h11 + d11 * math.tan(math.radians(a11)) - ht11)))
sim(11, 'Peste gard', C1, 'medie', f'''
Mingea pleacă de la $h_0 = {h11:.0f}\\,\\text{{m}}$, sub ${a11}^\\circ$ față de orizontală, și trebuie să treacă exact peste marginea unui gard înalt de ${ht11:.0f}\\,\\text{{m}}$, aflat la ${d11:.0f}\\,\\text{{m}}$. Cu ce viteză trebuie aruncată și când ajunge deasupra gardului?''',
    'projectile', {'angle': a11, 'h0': h11, 'd': d11, 'ht': ht11}, [f('v0', 'v₀', 'm/s'), f('t', 't (până la gard)', 's')],
    {'v0': v11, 't': d11 / (v11 * math.cos(math.radians(a11)))},
    'Aceeași ecuație a traiectoriei ca la coș: $y(d) = h_0 + d\\tan\\alpha - \\frac{g d^2}{2v_0^2\\cos^2\\alpha}$, cu $y(d)$ = înălțimea gardului.',
    f'$v_0 \\approx {v11:.2f}\\,\\text{{m/s}}$, $t \\approx {d11 / (v11 * math.cos(math.radians(a11))):.2f}\\,\\text{{s}}$.')

th12, L12 = 20, 5.0
acc12 = g * math.sin(math.radians(th12))
sim(12, 'Planul fără frecare', C2, 'ușoară', f'''
Un corp alunecă din repaus, **fără frecare**, pe un plan înclinat cu ${th12}^\\circ$, lung de ${L12:.0f}\\,\\text{{m}}$. Află accelerația și viteza cu care ajunge jos. Ar fi aceeași viteza dacă ar cădea liber de la aceeași înălțime?''',
    'incline', {'angle': th12, 'mu': 0, 'L': L12}, [f('a', 'a', 'm/s²'), f('v', 'v (jos)', 'm/s')], {'a': acc12, 'v': math.sqrt(2 * acc12 * L12)},
    'Fără frecare, $a = g\\sin\\theta$; apoi $v^2 = 2aL$.',
    f'$a = g\\sin\\theta \\approx {acc12:.3f}\\,\\text{{m/s}}^2$, $v = \\sqrt{{2aL}} \\approx {math.sqrt(2 * acc12 * L12):.2f}\\,\\text{{m/s}}$. Da: $2aL = 2gL\\sin\\theta = 2gh$, viteza depinde doar de înălțime (conservarea energiei).')

sim(13, 'Atwood cu mase apropiate', C2, 'ușoară', '''
Mașina Atwood a fost inventată ca să **încetinească** căderea, ca s-o poți măsura. Cu $m_1 = 1{,}1\\,\\text{kg}$ și $m_2 = 1\\,\\text{kg}$, află accelerația și tensiunea din fir. De câte ori e accelerația mai mică decât $g$?''',
    'atwood', {'m1': 1.1, 'm2': 1.0}, [f('a', 'a', 'm/s²'), f('T', 'T', 'N')], {'a': 0.1 * g / 2.1, 'T': 2 * 1.1 * g / 2.1},
    '$a = \\frac{m_1 - m_2}{m_1 + m_2}g$.', f'$a = \\frac{{0{{,}}1}}{{2{{,}}1}} g \\approx {0.1 * g / 2.1:.3f}\\,\\text{{m/s}}^2$, de 21 de ori mai mică decât $g$; $T \\approx {2 * 1.1 * g / 2.1:.2f}\\,\\text{{N}}$, aproape greutatea fiecărui corp.')

p14 = {'m1': 2, 'v1': 3, 'm2': 2, 'v2': -3, 'elastic': 1}
sim(14, 'Ciocnire elastică, mase egale', C3, 'ușoară', '''
Două bile de câte 2 kg se apropie una de alta, fiecare cu 3 m/s, și se ciocnesc frontal, **perfect elastic**. Ce viteze au după ciocnire (pozitiv: sensul inițial al primei bile)?''',
    'collision', p14, [f('v1p', "v₁'", 'm/s'), f('v2p', "v₂'", 'm/s')], {'v1p': -3.0, 'v2p': 3.0},
    'La mase egale, într-o ciocnire elastică frontală bilele își **schimbă** vitezele.', "$v_1' = v_2 = -3\\,\\text{m/s}$, $v_2' = v_1 = 3\\,\\text{m/s}$: fiecare se întoarce cu viteza cu care a venit.")

m15, k15, A15 = 2.0, 200.0, 0.05
sim(15, 'Un resort mai tare', C4, 'medie', f'''
Un corp de ${m15:.0f}\\,\\text{{kg}}$ pe un resort cu $k = {k15:.0f}\\,\\text{{N/m}}$ oscilează cu amplitudinea ${A15 * 100:.0f}\\,\\text{{cm}}$. Află perioada și viteza maximă. Cum se schimbă perioada dacă dublezi masa?''',
    'spring', {'m': m15, 'k': k15, 'A': A15}, [f('T', 'T', 's'), f('vmax', 'v max', 'm/s')], {'T': 2 * math.pi * math.sqrt(m15 / k15), 'vmax': math.sqrt(k15 / m15) * A15},
    '$\\omega = \\sqrt{k/m}$.', f'$\\omega = 10\\,\\text{{rad/s}}$, $T = \\pi/5 \\approx {2 * math.pi * math.sqrt(m15 / k15):.4f}\\,\\text{{s}}$, $v_{{max}} = \\omega A = 0{{,}}5\\,\\text{{m/s}}$. Cu masa dublă, $T$ crește de $\\sqrt{{2}}$ ori.')

write_course('fizica', CHAPTERS, PROBLEMS)
