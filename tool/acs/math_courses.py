"""AM, MS and ALGAED: answers written as maths, checked by their properties.

Each problem gives the fields the student fills (a formula, a number, a
matrix, points), the checks (Octave conditions over those values, see
lib/acs/engine/math_task.dart), an optional graph, and a reference answer
that test/acs_courses_test.dart enters to prove the checks accept it (and a
wrong one that they refuse). ALGAED's row-operation problems carry a
reference sequence of operations, made here by Gauss-Jordan in fractions.
"""
import os, sys
from fractions import Fraction as F
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

XS = '[-1.7 -0.9 -0.35 0.2 0.6 1.1 1.6]'


def expr(name, label, vars=('x',), hint=''):
    return {'name': name, 'label': label, 'type': 'expr', 'vars': list(vars), 'hint': hint}


def num(name, label, hint=''):
    return {'name': name, 'label': label, 'type': 'number', 'hint': hint}


def mat(name, label, r, c, hint=''):
    return {'name': name, 'label': label, 'type': 'matrix', 'rows': r, 'cols': c, 'hint': hint}


def pts(name, label, kinds=True):
    return {'name': name, 'label': label, 'type': 'points', 'kinds': kinds}


def ck(expr, msg):
    return {'expr': expr, 'msg': msg}


def math_problem(probs, id, title, ch, diff, statement, fields, checks, reference, wrong, hint, solution, plot=None, heat=None, source='', constants=None):
    spec = {'fields': fields, 'checks': checks, 'reference': reference, 'wrong': wrong}
    if plot: spec['plot'] = plot
    if heat: spec['heat'] = heat
    if constants: spec['constants'] = constants
    probs.append(problem(id, title, ch, diff, statement, 'math', spec, hint, solution, source))


def same_fn(field, ref, xs=XS, tol='1e-7'):
    return f'close({field}({xs}), ({ref})({xs}), {tol})'


# ============================================================================ AM
AM1 = '1. Formula lui Taylor'
AM2 = '2. Derivate și primitive'
AM3 = '3. Funcții de mai multe variabile'
AM4 = '4. Serii și integrale'
AM = []
E = 'Examen AM · seria CD · februarie 2022'

math_problem(AM, 1, 'Polinomul Taylor al lui eˣ sin x', AM1, 'medie', '''
Scrie polinomul Taylor de **grad 3** al funcției $f(x) = e^x \\sin x$ în jurul lui $x_0 = 0$.

Graficul arată funcția (gri) și polinomul tău (colorat): lângă 0 trebuie să se suprapună.''',
    [expr('P', 'T₃(x) =')],
    [ck(same_fn('P', '@(x) x + x.^2 + x.^3/3'), 'e polinomul Taylor de grad 3 în 0'),
     ck('abs(P(0)) < 1e-12', 'T₃(0) = f(0) = 0')],
    {'P': 'x + x^2 + x^3/3'}, {'P': 'x + x^2'},
    'Înmulțește dezvoltările: $e^x = 1 + x + x^2/2 + \\ldots$, $\\sin x = x - x^3/6 + \\ldots$, și păstrează termenii până la $x^3$.',
    '$(1 + x + \\frac{x^2}{2})(x - \\frac{x^3}{6}) = x + x^2 + \\frac{x^3}{2} - \\frac{x^3}{6} + \\ldots = x + x^2 + \\frac{x^3}{3}$.',
    plot={'field': 'P', 'range': [-2.5, 2.5], 'ref': '@(x) exp(x).*sin(x)', 'refLabel': 'f(x) = eˣ sin x', 'label': 'T₃(x)'})

math_problem(AM, 2, 'Taylor pentru ln(1 + x)', AM1, 'ușoară', '''
Scrie polinomul Taylor de **grad 4** al lui $f(x) = \\ln(1 + x)$ în $x_0 = 0$. Uită-te pe grafic cum se depărtează de funcție după $x = 1$ (raza de convergență a seriei e 1).''',
    [expr('P', 'T₄(x) =')],
    [ck(same_fn('P', '@(x) x - x.^2/2 + x.^3/3 - x.^4/4'), 'e polinomul Taylor de grad 4 în 0')],
    {'P': 'x - x^2/2 + x^3/3 - x^4/4'}, {'P': 'x - x^2/2 + x^3/3'},
    '$f^{(n)}(0) = (-1)^{n-1}(n-1)!$, deci coeficientul lui $x^n$ e $(-1)^{n-1}/n$.',
    '$T_4(x) = x - \\frac{x^2}{2} + \\frac{x^3}{3} - \\frac{x^4}{4}$.',
    plot={'field': 'P', 'range': [-0.95, 2.5], 'ref': '@(x) log(1 + x)', 'refLabel': 'ln(1 + x)', 'label': 'T₄(x)', 'yrange': [-3, 2]})

math_problem(AM, 3, 'Aproximarea lui cos x', AM1, 'ușoară', '''
Scrie polinomul Taylor de **grad 6** al lui $\\cos x$ în 0. Cât de departe de 0 rămâne bun?''',
    [expr('P', 'T₆(x) =')],
    [ck(same_fn('P', '@(x) 1 - x.^2/2 + x.^4/24 - x.^6/720'), 'e polinomul Taylor de grad 6 în 0')],
    {'P': '1 - x^2/2 + x^4/24 - x^6/720'}, {'P': '1 - x^2/2 + x^4/24'},
    'Doar puterile pare apar: $\\cos x = \\sum (-1)^k x^{2k}/(2k)!$.', '$T_6(x) = 1 - \\frac{x^2}{2} + \\frac{x^4}{24} - \\frac{x^6}{720}$.',
    plot={'field': 'P', 'range': [-6, 6], 'ref': '@(x) cos(x)', 'refLabel': 'cos x', 'label': 'T₆(x)', 'yrange': [-2, 2]})

math_problem(AM, 4, 'Derivata unui produs', AM2, 'ușoară', '''
Calculează derivata funcției $f(x) = x^2 \\ln x$, $x > 0$.''',
    [expr('d', "f'(x) =")],
    [ck("close(d([0.3 0.7 1 1.5 2.4 3.1]), deriv(@(x) x.^2.*log(x), [0.3 0.7 1 1.5 2.4 3.1]), 1e-6)", "e derivata lui x² ln x")],
    {'d': '2x ln x + x'}, {'d': '2x ln x'},
    "$(uv)' = u'v + uv'$.", "$f'(x) = 2x \\ln x + x^2 \\cdot \\frac{1}{x} = 2x\\ln x + x$.",
    plot={'field': 'd', 'range': [0.05, 3], 'ref': '@(x) 2*x.*log(x) + x', 'refLabel': "f'(x)", 'label': 'derivata ta'})

math_problem(AM, 5, 'O primitivă prin părți', AM2, 'medie', '''
Găsește o primitivă $F$ a funcției $f(x) = x e^x$. Orice primitivă e bună (constanta nu contează): se verifică $F' = f$.''',
    [expr('F', 'F(x) =')],
    [ck('close(deriv(F, [-2 -1 0 0.5 1 2]), [-2 -1 0 0.5 1 2] .* exp([-2 -1 0 0.5 1 2]), 1e-6)', "F'(x) = x eˣ")],
    {'F': 'x e^x - e^x + 7'}, {'F': 'x e^x'},
    "Integrare prin părți: $\\int u\\,dv = uv - \\int v\\,du$ cu $u = x$, $dv = e^x dx$.",
    "$\\int x e^x dx = x e^x - \\int e^x dx = (x - 1)e^x + C$.",
    plot={'field': 'F', 'range': [-3, 2], 'ref': '@(x) (x - 1).*exp(x)', 'refLabel': '(x − 1)eˣ', 'label': 'F(x) (poate fi deplasată în sus sau jos)'})

math_problem(AM, 6, 'Primitiva cu arctangentă', AM2, 'medie', '''
Găsește o primitivă a funcției $f(x) = \\dfrac{1}{x^2 + 4}$.''',
    [expr('F', 'F(x) =')],
    [ck('close(deriv(F, [-3 -1 0 0.5 2 4]), 1 ./ ([-3 -1 0 0.5 2 4].^2 + 4), 1e-6)', "F'(x) = 1/(x² + 4)")],
    {'F': '1/2 arctg(x/2)'}, {'F': 'arctg(x/2)'},
    '$\\int \\frac{dx}{x^2 + a^2} = \\frac{1}{a}\\arctan\\frac{x}{a} + C$.', '$F(x) = \\frac{1}{2}\\arctan\\frac{x}{2} + C$.',
    plot={'field': 'F', 'range': [-6, 6], 'ref': '@(x) atan(x/2)/2', 'refLabel': '½ arctg(x/2)', 'label': 'F(x)'})

math_problem(AM, 7, 'Derivatele parțiale', AM3, 'ușoară', '''
Pentru $f(x, y) = x^2 y + \\sin(xy)$ calculează derivatele parțiale $\\dfrac{\\partial f}{\\partial x}$ și $\\dfrac{\\partial f}{\\partial y}$.''',
    [expr('fx', '∂f/∂x =', ('x', 'y')), expr('fy', '∂f/∂y =', ('x', 'y'))],
    [ck('close(fx([0.3 -1 2 0.7], [1 0.5 -0.4 2]), dx(@(x, y) x.^2.*y + sin(x.*y), [0.3 -1 2 0.7], [1 0.5 -0.4 2]), 1e-5)', '∂f/∂x e corectă'),
     ck('close(fy([0.3 -1 2 0.7], [1 0.5 -0.4 2]), dy(@(x, y) x.^2.*y + sin(x.*y), [0.3 -1 2 0.7], [1 0.5 -0.4 2]), 1e-5)', '∂f/∂y e corectă')],
    {'fx': '2xy + y cos(xy)', 'fy': 'x^2 + x cos(xy)'}, {'fx': '2xy', 'fy': 'x^2'},
    'Derivând după x, y e o constantă (și invers).', '$f_x = 2xy + y\\cos(xy)$, $f_y = x^2 + x\\cos(xy)$.')

math_problem(AM, 8, 'Punctele critice ale lui x³ + y³ − 3xy', AM3, 'medie', '''
Găsește **toate** punctele critice ale funcției $f(x, y) = x^3 + y^3 - 3xy$ și spune pentru fiecare dacă e minim local, maxim local sau punct șa.

Harta de culori arată funcția; pune-ți punctele pe ea.''',
    [pts('P', 'Punctele critice:')],
    [ck('same_points(P, P_tip, [0 0 0; 1 1 1])', 'punctele critice sunt exact acestea'),
     ck('same_points(P, P_tip, [0 0 0; 1 1 1], 1)', 'tipul fiecărui punct e corect')],
    {'P': [['0', '0', 'șa'], ['1', '1', 'min']]}, {'P': [['1', '1', 'min']]},
    '$f_x = 3x^2 - 3y = 0$ și $f_y = 3y^2 - 3x = 0$ dau $y = x^2$ și $x = y^2$. Apoi hessiana: $f_{xx} = 6x$, $f_{yy} = 6y$, $f_{xy} = -3$.',
    'Din $y = x^2$, $x = x^4$: $x = 0$ sau $x = 1$, deci $(0, 0)$ și $(1, 1)$. În $(0,0)$: $\\det H = 0 \\cdot 0 - 9 < 0$, punct șa. În $(1,1)$: $\\det H = 36 - 9 > 0$ și $f_{xx} = 6 > 0$, minim local ($f = -1$).',
    heat={'field': 'P', 'fn': '@(x, y) x.^3 + y.^3 - 3*x.*y', 'xr': [-1.5, 2], 'yr': [-1.5, 2], 'label': 'f(x, y) = x³ + y³ − 3xy'}, source=E)

math_problem(AM, 9, 'Un singur extrem', AM3, 'ușoară', '''
Găsește punctele critice ale funcției $f(x, y) = x^2 + xy + y^2 - 3x$ și natura lor.''',
    [pts('P', 'Punctele critice:')],
    [ck('same_points(P, P_tip, [2 -1 1])', 'punctele critice sunt exact acestea'), ck('same_points(P, P_tip, [2 -1 1], 1)', 'tipul e corect')],
    {'P': [['2', '-1', 'min']]}, {'P': [['2', '-1', 'max']]},
    'Un sistem liniar: $2x + y - 3 = 0$, $x + 2y = 0$.', '$(2, -1)$; hessiana $\\begin{pmatrix}2 & 1\\\\1 & 2\\end{pmatrix}$ e pozitiv definită, deci minim ($f = -3$).',
    heat={'field': 'P', 'fn': '@(x, y) x.^2 + x.*y + y.^2 - 3*x', 'xr': [-1, 4], 'yr': [-3, 2], 'label': 'f(x, y)'})

math_problem(AM, 10, 'Extreme cu legături', AM3, 'grea', '''
Găsește punctele de extrem ale funcției $f(x, y) = xy$ pe cercul $x^2 + y^2 = 2$ (metoda multiplicatorilor lui Lagrange) și spune care sunt de maxim și care de minim.''',
    [pts('P', 'Punctele de extrem:')],
    [ck('same_points(P, P_tip, [1 1 -1; -1 -1 -1; 1 -1 1; -1 1 1])', 'punctele de extrem sunt exact acestea'),
     ck('same_points(P, P_tip, [1 1 -1; -1 -1 -1; 1 -1 1; -1 1 1], 1)', 'tipul fiecăruia e corect'),
     ck('all(abs(P(:, 1).^2 + P(:, 2).^2 - 2) < 1e-9)', 'toate sunt pe cerc')],
    {'P': [['1', '1', 'max'], ['-1', '-1', 'max'], ['1', '-1', 'min'], ['-1', '1', 'min']]}, {'P': [['1', '1', 'max'], ['-1', '-1', 'max']]},
    '$L = xy - \\lambda(x^2 + y^2 - 2)$: $y = 2\\lambda x$, $x = 2\\lambda y$. Rezultă $x^2 = y^2$.',
    'Din $x^2 = y^2$ și $x^2 + y^2 = 2$: $x, y = \\pm 1$. $f = 1$ în $(1,1)$, $(-1,-1)$ (maxime) și $f = -1$ în $(1,-1)$, $(-1,1)$ (minime).',
    heat={'field': 'P', 'fn': '@(x, y) x.*y - 3*(abs(sqrt(x.^2 + y.^2) - sqrt(2)) < 0.04)', 'xr': [-2, 2], 'yr': [-2, 2], 'label': 'f(x, y) = xy, cu cercul x² + y² = 2'}, source=E)

math_problem(AM, 11, 'Suma unei serii de puteri', AM4, 'medie', '''
Găsește suma seriei $\\displaystyle S(x) = \\sum_{n=1}^{\\infty} \\frac{x^n}{n}$ pentru $|x| < 1$, ca formulă închisă.''',
    [expr('S', 'S(x) =')],
    [ck('close(S([-0.9 -0.5 0 0.3 0.6 0.85]), -log(1 - [-0.9 -0.5 0 0.3 0.6 0.85]), 1e-7)', 'e suma seriei pe (−1, 1)')],
    {'S': '-ln(1 - x)'}, {'S': '1/(1 - x)'},
    "Derivează termen cu termen: $S'(x) = \\sum x^{n-1} = \\frac{1}{1-x}$, apoi integrează, cu $S(0) = 0$.",
    '$S(x) = -\\ln(1 - x)$.',
    plot={'field': 'S', 'range': [-0.99, 0.95], 'ref': '@(x) -log(1 - x)', 'refLabel': '−ln(1 − x)', 'label': 'S(x)'})

math_problem(AM, 12, 'O integrală definită', AM4, 'ușoară', '''
Calculează exact $\\displaystyle \\int_0^1 x^2 e^x \\, dx$ (poți scrie rezultatul cu `e`).''',
    [num('I', 'I =')], [ck('abs(I - (e - 2)) < 1e-9', 'valoarea integralei e corectă')],
    {'I': 'e - 2'}, {'I': 'e'},
    'De două ori prin părți: $\\int x^2 e^x = (x^2 - 2x + 2)e^x$.', '$[(x^2 - 2x + 2)e^x]_0^1 = e - 2$.')

math_problem(AM, 13, 'Integrală dublă pe un triunghi', AM4, 'medie', '''
Calculează $\\displaystyle \\iint_D xy \\, dx\\, dy$, unde $D$ e triunghiul $x \\ge 0$, $y \\ge 0$, $x + y \\le 1$.''',
    [num('I', 'I =')], [ck('abs(I - 1/24) < 1e-12', 'valoarea integralei e corectă')],
    {'I': '1/24'}, {'I': '1/12'},
    'Integrează întâi după $y$ de la 0 la $1 - x$, apoi după $x$ de la 0 la 1.',
    '$\\int_0^1 x \\frac{(1-x)^2}{2} dx = \\frac{1}{2}\\left(\\frac{1}{2} - \\frac{2}{3} + \\frac{1}{4}\\right) = \\frac{1}{24}$.', source=E)

# ============================================================================ MS
MS1 = '1. Transformata Laplace'
MS2 = '2. Transformata Z'
MS3 = '3. Serii Fourier'
MS4 = '4. Probabilități și reziduuri'
MS = []
ME = 'Examen MS · seria CD · iunie 2022'
SS = '[3 3.5 4.2 5 6.5 8]'

math_problem(MS, 1, 'Laplace pentru t e²ᵗ', MS1, 'ușoară', '''
Calculează transformata Laplace $F(s) = \\mathcal{L}\\{t e^{2t}\\}(s)$, pentru $s > 2$.''',
    [expr('F', 'F(s) =', ('s',))], [ck(f'close(F({SS}), 1 ./ ({SS} - 2).^2, 1e-9)', 'e transformata lui t e²ᵗ')],
    {'F': '1/(s - 2)^2'}, {'F': '1/(s - 2)'},
    '$\\mathcal{L}\\{t\\} = 1/s^2$, iar înmulțirea cu $e^{at}$ deplasează: $s \\to s - a$.', '$F(s) = \\frac{1}{(s-2)^2}$.',
    plot={'field': 'F', 'range': [2.3, 8], 'ref': '@(s) 1 ./ (s - 2).^2', 'refLabel': 'F(s)', 'label': 'F(s) a ta', 'yrange': [0, 6]})

math_problem(MS, 2, 'Laplace pentru e⁻ᵗ cos 2t', MS1, 'ușoară', '''
Calculează $\\mathcal{L}\\{e^{-t}\\cos 2t\\}(s)$.''',
    [expr('F', 'F(s) =', ('s',))], [ck(f'close(F({SS}), ({SS} + 1) ./ (({SS} + 1).^2 + 4), 1e-9)', 'e transformata lui e⁻ᵗ cos 2t')],
    {'F': '(s + 1)/((s + 1)^2 + 4)'}, {'F': 's/(s^2 + 4)'},
    '$\\mathcal{L}\\{\\cos \\omega t\\} = \\frac{s}{s^2 + \\omega^2}$; apoi $s \\to s + 1$.', '$F(s) = \\frac{s + 1}{(s+1)^2 + 4}$.')

TT = '[0 0.3 0.8 1.5 2.5 4]'
math_problem(MS, 3, 'Original din fracții simple', MS1, 'medie', '''
Găsește originalul $f(t)$ al lui $F(s) = \\dfrac{s + 3}{s^2 + 3s + 2}$.''',
    [expr('f', 'f(t) =', ('t',))], [ck(f'close(f({TT}), 2*exp(-{TT}) - exp(-2*{TT}), 1e-9)', 'e originalul lui F')],
    {'f': '2e^(-t) - e^(-2t)'}, {'f': 'e^(-t) - e^(-2t)'},
    '$s^2 + 3s + 2 = (s+1)(s+2)$; descompune în fracții simple.', '$F = \\frac{2}{s+1} - \\frac{1}{s+2}$, deci $f(t) = 2e^{-t} - e^{-2t}$.',
    plot={'field': 'f', 'range': [0, 5], 'ref': '@(t) 2*exp(-t) - exp(-2*t)', 'refLabel': 'originalul', 'label': 'f(t)'})

math_problem(MS, 4, 'O ecuație diferențială rezolvată cu Laplace', MS1, 'medie', '''
Rezolvă cu transformata Laplace problema $y' + 2y = e^{-t}$, $y(0) = 0$.

Se verifică direct că funcția ta satisface ecuația și condiția inițială.''',
    [expr('y', 'y(t) =', ('t',))],
    [ck(f"close(deriv(y, {TT}) + 2*y({TT}), exp(-{TT}), 1e-5)", "y' + 2y = e⁻ᵗ"), ck('abs(y(0)) < 1e-9', 'y(0) = 0')],
    {'y': 'e^(-t) - e^(-2t)'}, {'y': 'e^(-t)'},
    '$sY + 2Y = \\frac{1}{s+1}$, deci $Y = \\frac{1}{(s+1)(s+2)}$.', '$Y = \\frac{1}{s+1} - \\frac{1}{s+2}$, $y(t) = e^{-t} - e^{-2t}$.',
    plot={'field': 'y', 'range': [0, 5], 'ref': '@(t) exp(-t) - exp(-2*t)', 'refLabel': 'soluția', 'label': 'y(t)'}, source=ME)

ZZ = '[1.5 2 2.7 3.5 5]'
math_problem(MS, 5, 'Transformata Z a unui șir geometric', MS2, 'ușoară', '''
Calculează transformata Z a șirului $x_n = \\left(\\frac{1}{2}\\right)^n$, $n \\ge 0$: $X(z) = \\sum_{n\\ge 0} x_n z^{-n}$, pentru $|z| > \\frac{1}{2}$.''',
    [expr('X', 'X(z) =', ('z',))], [ck(f'close(X({ZZ}), {ZZ} ./ ({ZZ} - 0.5), 1e-9)', 'e transformata Z a lui (1/2)ⁿ')],
    {'X': 'z/(z - 1/2)'}, {'X': '1/(z - 1/2)'},
    'E o serie geometrică de rație $\\frac{1}{2z}$.', '$X(z) = \\frac{1}{1 - \\frac{1}{2z}} = \\frac{z}{z - 1/2}$.')

math_problem(MS, 6, 'Transformata Z a lui n', MS2, 'medie', '''
Calculează $\\mathcal{Z}\\{n\\}(z)$, $|z| > 1$.''',
    [expr('X', 'X(z) =', ('z',))], [ck(f'close(X({ZZ}), {ZZ} ./ ({ZZ} - 1).^2, 1e-9)', 'e transformata Z a lui n')],
    {'X': 'z/(z - 1)^2'}, {'X': 'z/(z - 1)'},
    'Derivează $\\sum z^{-n} = \\frac{z}{z-1}$ după $z$ și înmulțește cu $-z$.', '$\\mathcal{Z}\\{n\\} = \\frac{z}{(z-1)^2}$.', source=ME)

NN = '[1 2 3 4 5 6 7 10]'
math_problem(MS, 7, 'Seria Fourier a lui f(x) = x', MS3, 'medie', '''
Funcția $f(x) = x$ pe $(-\\pi, \\pi)$, prelungită prin periodicitate, e impară, deci seria ei Fourier are doar sinusuri:

$$f(x) \\sim \\sum_{n \\ge 1} b_n \\sin nx.$$

Scrie coeficientul $b_n$ ca formulă în $n$. Graficul arată suma primilor 15 termeni cu coeficienții tăi (fenomenul Gibbs se vede la capete).''',
    [expr('b', 'bₙ =', ('n',))], [ck(f'close(b({NN}), 2*(-1).^({NN}+1) ./ {NN}, 1e-9)', 'coeficienții bₙ sunt corecți')],
    {'b': '2(-1)^(n+1)/n'}, {'b': '2/n'},
    '$b_n = \\frac{1}{\\pi}\\int_{-\\pi}^{\\pi} x \\sin nx\\, dx$; integrează prin părți.', '$b_n = \\frac{2(-1)^{n+1}}{n}$.',
    plot={'field': 'b', 'fourier': 'sin', 'N': 15, 'range': [-3.6, 3.6], 'ref': '@(x) x - 2*pi*round(x/(2*pi))', 'refLabel': 'f(x) = x (periodică)', 'label': 'suma Fourier, 15 termeni'})

math_problem(MS, 8, 'Seria Fourier a lui |x|', MS3, 'grea', '''
Funcția $f(x) = |x|$ pe $(-\\pi, \\pi)$ e pară, deci are doar cosinusuri:

$$f(x) \\sim \\frac{a_0}{2} + \\sum_{n \\ge 1} a_n \\cos nx.$$

Scrie $a_0$ și $a_n$.''',
    [num('a0', 'a₀ ='), expr('a', 'aₙ =', ('n',))],
    [ck('abs(a0 - pi) < 1e-9', 'a₀ e corect'), ck(f'close(a({NN}), 2*((-1).^{NN} - 1) ./ (pi*{NN}.^2), 1e-9)', 'aₙ e corect')],
    {'a0': 'pi', 'a': '2((-1)^n - 1)/(pi n^2)'}, {'a0': 'pi', 'a': '-4/(pi n^2)'},
    '$a_0 = \\frac{2}{\\pi}\\int_0^\\pi x\\,dx$, $a_n = \\frac{2}{\\pi}\\int_0^\\pi x \\cos nx\\,dx$.',
    '$a_0 = \\pi$, $a_n = \\frac{2((-1)^n - 1)}{\\pi n^2}$: zero pentru $n$ par, $-\\frac{4}{\\pi n^2}$ pentru $n$ impar.',
    plot={'field': 'a', 'a0': 'a0', 'fourier': 'cos', 'N': 15, 'range': [-3.6, 3.6], 'ref': '@(x) abs(x - 2*pi*round(x/(2*pi)))', 'refLabel': '|x| (periodică)', 'label': 'suma Fourier, 15 termeni'})

math_problem(MS, 9, 'Repartiția binomială', MS4, 'ușoară', '''
Un test grilă are 5 întrebări; la fiecare, un student care ghicește răspunde corect cu probabilitatea 0,3, independent. Care e probabilitatea să răspundă corect la **cel puțin 2** întrebări?''',
    [num('p', 'P(X ≥ 2) =')], [ck('abs(p - (1 - 0.7^5 - 5*0.3*0.7^4)) < 1e-6', 'probabilitatea e corectă')],
    {'p': '1 - 0.7^5 - 5*0.3*0.7^4'}, {'p': '0.3^2'},
    '$X \\sim \\text{Bin}(5;\\,0{,}3)$; complementul e $X \\in \\{0, 1\\}$.', '$1 - 0{,}7^5 - 5 \\cdot 0{,}3 \\cdot 0{,}7^4 = 0{,}47178$.')

math_problem(MS, 10, 'O densitate de probabilitate', MS4, 'medie', '''
$X$ are densitatea $f(x) = c\\,x(1 - x)$ pe $[0, 1]$ (și 0 în rest). Află constanta $c$, media $E[X]$ și dispersia $D^2[X]$.''',
    [num('c', 'c ='), num('m', 'E[X] ='), num('v', 'D²[X] =')],
    [ck('abs(c - 6) < 1e-9', 'c e corect'), ck('abs(m - 1/2) < 1e-9', 'media e corectă'), ck('abs(v - 1/20) < 1e-9', 'dispersia e corectă')],
    {'c': '6', 'm': '1/2', 'v': '1/20'}, {'c': '6', 'm': '1/2', 'v': '1/4'},
    '$\\int_0^1 f = 1$ dă $c$. $D^2[X] = E[X^2] - E[X]^2$.', '$c \\int_0^1 (x - x^2) = c/6 = 1$, $c = 6$; $E[X] = 1/2$ (simetrie); $E[X^2] = 6(1/4 - 1/5) = 3/10$, $D^2 = 3/10 - 1/4 = 1/20$.')

math_problem(MS, 11, 'O integrală reală prin reziduuri', MS4, 'grea', '''
Calculează $\\displaystyle \\int_{-\\infty}^{\\infty} \\frac{dx}{(x^2 + 1)^2}$ cu teorema reziduurilor.''',
    [num('I', 'I =')], [ck('abs(I - pi/2) < 1e-9', 'valoarea e corectă')],
    {'I': 'pi/2'}, {'I': 'pi'},
    'Singurul pol din semiplanul superior e $z = i$, de ordin 2. $I = 2\\pi i \\, \\text{Rez}(f, i)$.',
    '$\\text{Rez}\\left(\\frac{1}{(z+i)^2(z-i)^2}, i\\right) = \\frac{d}{dz}(z+i)^{-2}\\Big|_{z=i} = \\frac{-2}{(2i)^3} = \\frac{1}{4i}$, deci $I = 2\\pi i \\cdot \\frac{1}{4i} = \\frac{\\pi}{2}$.', source=ME)

# ============================================================================ ALGAED
AL1 = '1. Sisteme și matrice'
AL2 = '2. Valori și vectori proprii'
AL3 = '3. Spații euclidiene'
AL4 = '4. Ecuații diferențiale'
ALG = []
AE = 'Examen ALGAED · seria CD · 10 februarie 2022'


def fmt(q):
    return str(q.numerator) if q.denominator == 1 else f'({q.numerator}/{q.denominator})'


def gauss_jordan_ops(m, split):
    """The operations of Gauss-Jordan, as the student would type them, and the result."""
    m = [[F(x) for x in r] for r in m]
    ops = []
    rows = len(m)
    r = 0
    for c in range(split):
        if r >= rows:
            break
        p = next((i for i in range(r, rows) if m[i][c] != 0), None)
        if p is None:
            continue
        if p != r:
            m[p], m[r] = m[r], m[p]
            ops.append(f'L{r + 1} <-> L{p + 1}')
        piv = m[r][c]
        if piv != 1:
            m[r] = [x / piv for x in m[r]]
            ops.append(f'L{r + 1} = {fmt(1 / piv)} L{r + 1}')
        for i in range(rows):
            if i != r and m[i][c] != 0:
                f = m[i][c]
                m[i] = [a - f * b for a, b in zip(m[i], m[r])]
                ops.append(f'L{i + 1} = L{i + 1} {"-" if f > 0 else "+"} {fmt(abs(f))} L{r + 1}')
        r += 1
    return ops, m


def triangular_ops(m):
    m = [[F(x) for x in r] for r in m]
    ops = []
    n = len(m)
    for c in range(n):
        p = next((i for i in range(c, n) if m[i][c] != 0), None)
        if p is None:
            continue
        if p != c:
            m[p], m[c] = m[c], m[p]
            ops.append(f'L{c + 1} <-> L{p + 1}')
        for i in range(c + 1, n):
            if m[i][c] != 0:
                f = m[i][c] / m[c][c]
                m[i] = [a - f * b for a, b in zip(m[i], m[c])]
                ops.append(f'L{i + 1} = L{i + 1} {"-" if f > 0 else "+"} {fmt(abs(f))} L{c + 1}')
    return ops


def det(m):
    m = [[F(x) for x in r] for r in m]
    n, d = len(m), F(1)
    for c in range(n):
        p = next((i for i in range(c, n) if m[i][c] != 0), None)
        if p is None:
            return F(0)
        if p != c:
            m[p], m[c] = m[c], m[p]
            d = -d
        d *= m[c][c]
        for i in range(c + 1, n):
            f = m[i][c] / m[c][c]
            m[i] = [a - f * b for a, b in zip(m[i], m[c])]
    return d


def rowops(id, title, ch, diff, statement, matrix, goal, split=None, answers=(), hint='', solution='', source=''):
    n = len(matrix)
    if goal == 'inverse':
        aug = [list(r) + [1 if i == j else 0 for j in range(n)] for i, r in enumerate(matrix)]
        ops, _ = gauss_jordan_ops(aug, n)
    elif goal == 'triangular':
        ops = triangular_ops(matrix)
    else:
        ops, _ = gauss_jordan_ops(matrix, split or len(matrix[0]))
    spec = {'matrix': [[str(x) for x in r] for r in matrix], 'goal': goal, 'answers': list(answers), 'reference': ops}
    if split:
        spec['split'] = split
    ALG.append(problem(id, title, ch, diff, statement, 'rowops', spec, hint, solution, source))


S1 = [[1, 1, 1, 6], [2, -1, 1, 3], [1, 2, -1, 2]]
rowops(1, 'Un sistem prin Gauss-Jordan', AL1, 'ușoară', '''
Rezolvă sistemul

$$\\begin{cases} x + y + z = 6 \\\\ 2x - y + z = 3 \\\\ x + 2y - z = 2 \\end{cases}$$

aducând matricea extinsă la **forma eșalon redusă** prin operații pe linii, apoi citește soluția.''',
    S1, 'rref', split=3, answers=[{'label': 'x =', 'value': '1'}, {'label': 'y =', 'value': '2'}, {'label': 'z =', 'value': '3'}],
    hint='Fă întâi 0 sub pivotul din colțul stânga sus: `L2 = L2 - 2L1`, `L3 = L3 - L1`. Apoi treci la coloana 2.',
    solution='La final matricea e $[I_3 \\mid (1, 2, 3)^T]$: $x = 1$, $y = 2$, $z = 3$.')

A2 = [[2, 1, 1], [1, 3, 2], [1, 0, 0]]
rowops(2, 'Inversa unei matrice', AL1, 'medie', '''
Calculează inversa matricei

$$A = \\begin{pmatrix} 2 & 1 & 1 \\\\ 1 & 3 & 2 \\\\ 1 & 0 & 0 \\end{pmatrix}$$

prin metoda Gauss-Jordan: lângă $A$ e scrisă matricea unitate; fă operații pe linii până ajunge $I_3$ în stânga. Ce rămâne în dreapta e $A^{-1}$.''',
    A2, 'inverse', hint='Linia 3 are deja un singur element nenul: începe cu `L1 <-> L3`.',
    solution='$A^{-1} = \\begin{pmatrix} 0 & 0 & 1 \\\\ -2 & 1 & 3 \\\\ 3 & -1 & -5 \\end{pmatrix}$. Verificare: $A \\cdot A^{-1} = I_3$.')

R3 = [[1, 2, -1, 3], [2, 4, 1, 0], [3, 6, 0, 3]]
rowops(3, 'Rangul unei matrice', AL1, 'ușoară', '''
Adu matricea

$$A = \\begin{pmatrix} 1 & 2 & -1 & 3 \\\\ 2 & 4 & 1 & 0 \\\\ 3 & 6 & 0 & 3 \\end{pmatrix}$$

la o **formă eșalon** și citește rangul (numărul de linii nenule).''',
    R3, 'echelon', answers=[{'label': 'rang(A) =', 'value': '2'}],
    hint='Observă că $L_3 = L_1 + L_2$: după eliminare, o linie devine 0.', solution='Rangul e 2: $L_3 = L_1 + L_2$, iar $L_1$ și $L_2$ nu sunt proporționale.', source=AE)

D4 = [[2, 1, 0, 3], [4, 3, 1, 7], [-2, 0, 2, 1], [6, 2, 1, 9]]
dval = det(D4)
rowops(4, 'Determinant prin eliminare', AL1, 'medie', '''
Calculează determinantul matricei

$$\\begin{pmatrix} 2 & 1 & 0 & 3 \\\\ 4 & 3 & 1 & 7 \\\\ -2 & 0 & 2 & 1 \\\\ 6 & 2 & 1 & 9 \\end{pmatrix}$$

adusă la formă **superior triunghiulară**. Ține minte: `Li = Li + k·Lj` nu schimbă determinantul, o schimbare de linii îi schimbă semnul, iar înmulțirea unei linii cu $k$ îl înmulțește cu $k$ (pagina îți arată factorul).''',
    D4, 'triangular', answers=[{'label': 'det =', 'value': str(dval)}],
    hint='Folosește doar `Li = Li - k Lj` cu pivotul de pe diagonală: atunci determinantul e produsul diagonalei.', solution=f'Determinantul este {dval}.')

S5 = [[1, 2, -1, 3], [2, 4, 1, 9], [1, 2, 2, 6]]
rowops(5, 'Un sistem cu o infinitate de soluții', AL1, 'medie', '''
Adu la forma eșalon redusă matricea extinsă a sistemului

$$\\begin{cases} x + 2y - z = 3 \\\\ 2x + 4y + z = 9 \\\\ x + 2y + 2z = 6 \\end{cases}$$

și spune câte necunoscute secundare (parametri) are soluția.''',
    S5, 'rref', split=3, answers=[{'label': 'rang(A) =', 'value': '2'}, {'label': 'necunoscute secundare:', 'value': '1'}],
    hint='Coloana lui y nu va avea pivot.', solution='Forma redusă dă $x + 2y = 4$, $z = 1$: $y$ e secundară, soluția e $(4 - 2t, t, 1)$.')

math_problem(ALG, 6, 'Diagonalizarea unei matrice 2 × 2', AL2, 'ușoară', '''
Diagonalizează $A = \\begin{pmatrix} 4 & 1 \\\\ 2 & 3 \\end{pmatrix}$: găsește o matrice inversabilă $P$ (vectorii proprii pe coloane) și o matrice diagonală $D$ (valorile proprii) cu $AP = PD$. Orice ordine și orice normare a vectorilor sunt bune.''',
    [mat('P', 'P =', 2, 2), mat('D', 'D =', 2, 2)],
    [ck('norm([4 1; 2 3]*P - P*D) < 1e-9', 'A P = P D'), ck('abs(det(P)) > 1e-9', 'P e inversabilă'), ck('norm(D - diag(diag(D))) < 1e-12', 'D e diagonală')],
    {'P': [['1', '1'], ['-2', '1']], 'D': [['2', '0'], ['0', '5']]}, {'P': [['1', '0'], ['0', '1']], 'D': [['4', '0'], ['0', '3']]},
    'Polinomul caracteristic: $\\lambda^2 - 7\\lambda + 10$.', '$\\lambda = 2$: $v = (1, -2)$; $\\lambda = 5$: $v = (1, 1)$.')

math_problem(ALG, 7, 'Valori proprii multiple', AL2, 'medie', '''
Diagonalizează matricea simetrică $A = \\begin{pmatrix} 2 & 1 & 1 \\\\ 1 & 2 & 1 \\\\ 1 & 1 & 2 \\end{pmatrix}$: $AP = PD$, $P$ inversabilă, $D$ diagonală. Valoarea proprie 1 e dublă, deci îi trebuie doi vectori proprii independenți.''',
    [mat('P', 'P =', 3, 3), mat('D', 'D =', 3, 3)],
    [ck('norm([2 1 1; 1 2 1; 1 1 2]*P - P*D) < 1e-9', 'A P = P D'), ck('abs(det(P)) > 1e-9', 'P e inversabilă'), ck('norm(D - diag(diag(D))) < 1e-12', 'D e diagonală')],
    {'P': [['1', '1', '1'], ['-1', '0', '1'], ['0', '-1', '1']], 'D': [['1', '0', '0'], ['0', '1', '0'], ['0', '0', '4']]},
    {'P': [['1', '1', '1'], ['-1', '-1', '1'], ['0', '0', '1']], 'D': [['1', '0', '0'], ['0', '1', '0'], ['0', '0', '4']]},
    '$A = J + I$, unde $J$ e matricea cu toți 1: valorile proprii ale lui $J$ sunt 3, 0, 0.', 'Valorile proprii 4 (vector $(1,1,1)$) și 1, dublă (orice vector cu suma componentelor 0, de ex. $(1,-1,0)$ și $(1,0,-1)$).', source=AE)

math_problem(ALG, 8, 'O bază ortonormată (Gram-Schmidt)', AL3, 'medie', '''
Găsește o bază **ortonormată** a subspațiului din $\\mathbb{R}^3$ generat de $v_1 = (1, 1, 0)$ și $v_2 = (1, 0, 1)$: două coloane $q_1, q_2$, de normă 1, perpendiculare, care generează același plan. Poți scrie radicali: `1/sqrt(2)`.''',
    [mat('Q', 'Q = [q₁ q₂] =', 3, 2)],
    [ck("norm(Q'*Q - eye(2)) < 1e-9", 'coloanele sunt ortonormate'), ck('rank([[1 1; 1 0; 0 1], Q]) == 2', 'generează același plan')],
    {'Q': [['1/sqrt(2)', '1/sqrt(6)'], ['1/sqrt(2)', '-1/sqrt(6)'], ['0', '2/sqrt(6)']]}, {'Q': [['1', '0'], ['0', '1'], ['0', '0']]},
    '$q_1 = v_1 / \\|v_1\\|$; apoi $w = v_2 - \\langle v_2, q_1\\rangle q_1$ și $q_2 = w / \\|w\\|$.',
    '$q_1 = \\frac{1}{\\sqrt 2}(1, 1, 0)$, $w = (1, 0, 1) - \\frac{1}{2}(1, 1, 0) = (\\frac12, -\\frac12, 1)$, $q_2 = \\frac{1}{\\sqrt 6}(1, -1, 2)$.')

XX = '[-1 -0.5 0 0.4 0.8 1.2]'
math_problem(ALG, 9, 'Ecuație liniară de ordinul 2', AL4, 'medie', '''
Rezolvă problema Cauchy

$$y'' - 3y' + 2y = 0, \\qquad y(0) = 1, \\quad y'(0) = 0.$$

Se verifică direct că funcția ta satisface ecuația și condițiile inițiale (orice formă e acceptată).''',
    [expr('y', 'y(x) =')],
    [ck(f'close(deriv2(y, {XX}) - 3*deriv(y, {XX}) + 2*y({XX}), zeros(1, 6), 2e-3)', "y'' − 3y' + 2y = 0"), ck('abs(y(0) - 1) < 1e-9', 'y(0) = 1'), ck('abs(deriv(y, 0)) < 1e-6', "y'(0) = 0")],
    {'y': '2e^x - e^(2x)'}, {'y': 'e^x'},
    'Ecuația caracteristică $r^2 - 3r + 2 = 0$ are rădăcinile 1 și 2: $y = C_1 e^x + C_2 e^{2x}$.',
    '$C_1 + C_2 = 1$, $C_1 + 2C_2 = 0$ dau $C_1 = 2$, $C_2 = -1$: $y = 2e^x - e^{2x}$.',
    plot={'field': 'y', 'range': [-2, 1], 'ref': '@(x) 2*exp(x) - exp(2*x)', 'refLabel': 'soluția', 'label': 'y(x)'}, source=AE)

math_problem(ALG, 10, 'Ecuație liniară de ordinul 1', AL4, 'ușoară', '''
Rezolvă $y' + y = x$, $y(0) = 1$.''',
    [expr('y', 'y(x) =')],
    [ck(f'close(deriv(y, {XX}) + y({XX}), {XX}, 1e-5)', "y' + y = x"), ck('abs(y(0) - 1) < 1e-9', 'y(0) = 1')],
    {'y': 'x - 1 + 2e^(-x)'}, {'y': 'x - 1'},
    'Factor integrant $e^x$: $(y e^x)\' = x e^x$.', '$y e^x = (x - 1)e^x + C$; din $y(0) = 1$, $C = 2$: $y = x - 1 + 2e^{-x}$.',
    plot={'field': 'y', 'range': [-1.5, 4], 'ref': '@(x) x - 1 + 2*exp(-x)', 'refLabel': 'soluția', 'label': 'y(x)'})

math_problem(ALG, 11, 'Variabile separabile', AL4, 'ușoară', '''
Rezolvă $y' = 2xy$, $y(0) = 1$.''',
    [expr('y', 'y(x) =')],
    [ck(f'close(deriv(y, {XX}), 2*{XX}.*y({XX}), 1e-5)', "y' = 2xy"), ck('abs(y(0) - 1) < 1e-9', 'y(0) = 1')],
    {'y': 'e^(x^2)'}, {'y': 'e^(2x)'},
    '$\\frac{dy}{y} = 2x\\,dx$.', '$\\ln|y| = x^2 + C$, deci $y = e^{x^2}$.',
    plot={'field': 'y', 'range': [-1.5, 1.5], 'ref': '@(x) exp(x.^2)', 'refLabel': 'soluția', 'label': 'y(x)'})

# ============================================================ more (2026-11)
# ---- AM
math_problem(AM, 14, 'Taylor pentru √(1 + x)', AM1, 'ușoară', '''
Scrie polinomul Taylor de **grad 2** al funcției $f(x) = \\sqrt{1 + x}$ în $x_0 = 0$. Folosește-l apoi în gând ca să aproximezi $\\sqrt{1{,}1}$.''',
    [expr('P', 'T₂(x) =')],
    [ck(same_fn('P', '@(x) 1 + x/2 - x.^2/8'), 'e polinomul Taylor de grad 2 în 0')],
    {'P': '1 + x/2 - x^2/8'}, {'P': '1 + x/2'},
    "$f'(x) = \\frac{1}{2}(1+x)^{-1/2}$, $f''(x) = -\\frac{1}{4}(1+x)^{-3/2}$; coeficientul lui $x^2$ e $\\frac{f''(0)}{2}$.",
    '$T_2(x) = 1 + \\frac{x}{2} - \\frac{x^2}{8}$; $\\sqrt{1{,}1} \\approx 1 + 0{,}05 - 0{,}00125 = 1{,}04875$ (valoarea exactă: 1,04881).',
    plot={'field': 'P', 'range': [-0.99, 3], 'ref': '@(x) sqrt(1 + x)', 'refLabel': '√(1 + x)', 'label': 'T₂(x)', 'yrange': [-0.5, 2.5]})

math_problem(AM, 15, 'Derivata unui cât', AM2, 'medie', '''
Calculează derivata funcției $f(x) = \\dfrac{e^x}{x^2 + 1}$. Unde se anulează?''',
    [expr('d', "f'(x) =")],
    [ck(f"close(d({XS}), deriv(@(x) exp(x)./(x.^2 + 1), {XS}), 1e-6)", "e derivata lui eˣ/(x² + 1)")],
    {'d': 'e^x (x - 1)^2 / (x^2 + 1)^2'}, {'d': 'e^x / (2x)'},
    "$\\left(\\frac{u}{v}\\right)' = \\frac{u'v - uv'}{v^2}$.",
    "$f'(x) = \\frac{e^x(x^2 + 1) - e^x \\cdot 2x}{(x^2+1)^2} = \\frac{e^x (x - 1)^2}{(x^2 + 1)^2} \\ge 0$: se anulează doar în $x = 1$, iar $f$ e crescătoare pe tot $\\mathbb{R}$ (fără extrem).",
    plot={'field': 'd', 'range': [-3, 3], 'ref': '@(x) exp(x).*(x - 1).^2./(x.^2 + 1).^2', 'refLabel': "f'(x)", 'label': 'derivata ta'})

math_problem(AM, 16, 'Derivata după o direcție', AM3, 'medie', '''
Pentru $f(x, y) = x^2 y + y^3$, calculează gradientul în punctul $(1, 2)$ și derivata lui $f$ în acest punct după direcția vectorului $v = (3, 4)$ (normat).''',
    [num('gx', '∂f/∂x (1, 2) ='), num('gy', '∂f/∂y (1, 2) ='), num('D', 'D_v f (1, 2) =')],
    [ck('abs(gx - 4) < 1e-9 && abs(gy - 13) < 1e-9', 'gradientul în (1, 2) e corect'), ck('abs(D - 64/5) < 1e-9', 'derivata după direcție e corectă')],
    {'gx': '4', 'gy': '13', 'D': '64/5'}, {'gx': '4', 'gy': '13', 'D': '64'},
    'Direcția trebuie normată: $u = v / \\|v\\| = (\\frac35, \\frac45)$. Apoi $D_u f = \\nabla f \\cdot u$.',
    '$\\nabla f = (2xy, x^2 + 3y^2) = (4, 13)$ în $(1, 2)$; $D_u f = 4 \\cdot \\frac35 + 13 \\cdot \\frac45 = \\frac{64}{5}$.')

math_problem(AM, 17, 'Raza de convergență', AM4, 'ușoară', '''
Găsește raza de convergență a seriei de puteri $\\displaystyle\\sum_{n \\ge 1} \\frac{x^n}{n \\cdot 3^n}$ și suma ei în $x = -3$ (unde converge, ca serie alternată).''',
    [num('R', 'R ='), num('S', 'suma în x = −3:')],
    [ck('abs(R - 3) < 1e-9', 'raza de convergență e corectă'), ck('abs(S + log(2)) < 1e-9', 'suma în x = −3 e corectă')],
    {'R': '3', 'S': '-ln 2'}, {'R': '1/3', 'S': 'ln 2'},
    'Criteriul raportului: $\\left|\\frac{a_{n+1}}{a_n}\\right| \\to \\frac{|x|}{3}$. În $x = -3$, seria devine $\\sum \\frac{(-1)^n}{n}$.',
    '$R = 3$. În $x = -3$: $\\sum_{n \\ge 1} \\frac{(-1)^n}{n} = -\\ln 2$ (seria lui $\\ln(1 + t)$ în $t = 1$, cu semn schimbat).')

math_problem(AM, 18, 'O integrală improprie', AM4, 'ușoară', '''
Calculează $\\displaystyle\\int_0^{\\infty} \\frac{dx}{1 + x^2}$ și $\\displaystyle\\int_1^{\\infty} \\frac{dx}{x^2}$.''',
    [num('I', '∫₀^∞ 1/(1 + x²) dx ='), num('J', '∫₁^∞ 1/x² dx =')],
    [ck('abs(I - pi/2) < 1e-9', 'prima integrală e corectă'), ck('abs(J - 1) < 1e-9', 'a doua integrală e corectă')],
    {'I': 'pi/2', 'J': '1'}, {'I': 'pi', 'J': '1'},
    'O integrală improprie e limita integralelor pe $[0, b]$, cu $b \\to \\infty$.',
    '$\\arctan b \\to \\frac{\\pi}{2}$, iar $1 - \\frac{1}{b} \\to 1$.')

# ---- MS
SL = '[0.5 1 1.7 2.3 3 4.5]'  # s for sin 3t: any s > 0
math_problem(MS, 12, 'Laplace pentru sin 3t', MS1, 'ușoară', '''
Calculează transformata Laplace a funcției $f(t) = \\sin 3t$, $t \\ge 0$.''',
    [expr('F', 'F(s) =', ('s',))], [ck(f'close(F({SL}), 3 ./ ({SL}.^2 + 9), 1e-9)', 'e transformata lui sin 3t')],
    {'F': '3/(s^2 + 9)'}, {'F': 's/(s^2 + 9)'},
    '$\\mathcal{L}\\{\\sin \\omega t\\} = \\frac{\\omega}{s^2 + \\omega^2}$.', '$F(s) = \\frac{3}{s^2 + 9}$, pentru $s > 0$.')

math_problem(MS, 13, 'O treaptă întârziată', MS2, 'medie', '''
Calculează transformata Z a șirului $x_n = 1$ pentru $n \\ge 2$ și $x_0 = x_1 = 0$ (treapta unitate întârziată cu 2), pentru $|z| > 1$.''',
    [expr('X', 'X(z) =', ('z',))], [ck(f'close(X({ZZ}), 1 ./ ({ZZ} .* ({ZZ} - 1)), 1e-9)', 'e transformata treptei întârziate')],
    {'X': '1/(z(z - 1))'}, {'X': 'z/(z - 1)'},
    'Întârzierea cu $k$ pași înmulțește transformata cu $z^{-k}$.', '$X(z) = z^{-2} \\cdot \\frac{z}{z - 1} = \\frac{1}{z(z - 1)}$.')

math_problem(MS, 14, 'Seria Fourier a lui x²', MS3, 'medie', '''
Pentru $f(x) = x^2$ pe $[-\\pi, \\pi]$, extinsă periodic, scrie termenul liber $\\frac{a_0}{2}$ și coeficienții $a_n$ ($n \\ge 1$) ai seriei Fourier $\\frac{a_0}{2} + \\sum_{n \\ge 1} a_n \\cos nx$ (funcția e pară, deci $b_n = 0$).''',
    [num('c', 'a₀/2 ='), expr('a', 'aₙ =', ('n',))],
    [ck('abs(c - pi^2/3) < 1e-9', 'termenul liber e corect'), ck(f'close(a({NN}), 4*(-1).^{NN} ./ {NN}.^2, 1e-9)', 'coeficienții aₙ sunt corecți')],
    {'c': 'pi^2/3', 'a': '4(-1)^n/n^2'}, {'c': 'pi^2/3', 'a': '4/n^2'},
    '$a_n = \\frac{2}{\\pi}\\int_0^\\pi x^2 \\cos nx\\,dx$: de două ori prin părți. $\\cos n\\pi = (-1)^n$.',
    '$\\frac{a_0}{2} = \\frac{1}{2\\pi}\\int_{-\\pi}^{\\pi} x^2 dx = \\frac{\\pi^2}{3}$, $a_n = \\frac{4(-1)^n}{n^2}$. În $x = \\pi$ se obține $\\sum \\frac{1}{n^2} = \\frac{\\pi^2}{6}$.')

math_problem(MS, 15, 'Repartiția Poisson', MS4, 'ușoară', '''
Numărul de cereri care ajung la un server într-o secundă urmează o repartiție Poisson cu $\\lambda = 3$. Calculează $P(X = 2)$ și $P(X \\ge 1)$.''',
    [num('p2', 'P(X = 2) ='), num('p1', 'P(X ≥ 1) =')],
    [ck('abs(p2 - 9/2*exp(-3)) < 1e-9', 'P(X = 2) e corectă'), ck('abs(p1 - (1 - exp(-3))) < 1e-9', 'P(X ≥ 1) e corectă')],
    {'p2': '9/2 e^(-3)', 'p1': '1 - e^(-3)'}, {'p2': '9 e^(-3)', 'p1': 'e^(-3)'},
    '$P(X = k) = e^{-\\lambda}\\frac{\\lambda^k}{k!}$. Pentru $P(X \\ge 1)$, treci prin evenimentul contrar.',
    '$P(X = 2) = e^{-3}\\frac{9}{2} \\approx 0{,}224$, $P(X \\ge 1) = 1 - P(X = 0) = 1 - e^{-3} \\approx 0{,}950$.')

# ---- ALGAED
S12 = [[1, 2, 1, 4], [2, 1, -1, 2], [1, -1, 2, 2]]
rowops(12, 'Încă un sistem, prin Gauss-Jordan', AL1, 'ușoară', '''
Rezolvă prin operații pe linii sistemul

$$\\begin{cases} x + 2y + z = 4 \\\\ 2x + y - z = 2 \\\\ x - y + 2z = 2 \\end{cases}$$''',
    S12, 'rref', split=3, answers=[{'label': 'x =', 'value': '1'}, {'label': 'y =', 'value': '1'}, {'label': 'z =', 'value': '1'}],
    hint='Primul pivot e deja 1: `L2 = L2 - 2L1`, `L3 = L3 - L1`.',
    solution='Forma eșalon redusă e $[I_3 \\mid (1, 1, 1)^T]$.')

A13 = [[1, 2, 0], [0, 1, 3], [0, 0, 1]]
rowops(13, 'Inversa unei matrice triunghiulare', AL1, 'ușoară', '''
Calculează inversa matricei superior triunghiulare

$$A = \\begin{pmatrix} 1 & 2 & 0 \\\\ 0 & 1 & 3 \\\\ 0 & 0 & 1 \\end{pmatrix}$$

prin Gauss-Jordan. Matricea e deja în formă eșalon: lucrezi doar **de jos în sus**.''',
    A13, 'inverse', hint='Începe cu `L2 = L2 - 3L3`, apoi `L1 = L1 - 2L2`.',
    solution='$A^{-1} = \\begin{pmatrix} 1 & -2 & 6 \\\\ 0 & 1 & -3 \\\\ 0 & 0 & 1 \\end{pmatrix}$: inversa unei matrice superior triunghiulare e tot superior triunghiulară.')

math_problem(ALG, 14, 'Diagonalizarea unei matrice triunghiulare', AL2, 'medie', '''
Diagonalizează $A = \\begin{pmatrix} 2 & 0 & 0 \\\\ 1 & 3 & 0 \\\\ 0 & 1 & 4 \\end{pmatrix}$: $AP = PD$, cu $P$ inversabilă și $D$ diagonală.''',
    [mat('P', 'P =', 3, 3), mat('D', 'D =', 3, 3)],
    [ck('norm([2 0 0; 1 3 0; 0 1 4]*P - P*D) < 1e-9', 'A P = P D'), ck('abs(det(P)) > 1e-9', 'P e inversabilă'), ck('norm(D - diag(diag(D))) < 1e-12', 'D e diagonală')],
    {'P': [['2', '0', '0'], ['-2', '1', '0'], ['1', '-1', '1']], 'D': [['2', '0', '0'], ['0', '3', '0'], ['0', '0', '4']]},
    {'P': [['1', '0', '0'], ['0', '1', '0'], ['0', '0', '1']], 'D': [['2', '0', '0'], ['0', '3', '0'], ['0', '0', '4']]},
    'Valorile proprii ale unei matrice triunghiulare sunt pe diagonală. Pentru fiecare, rezolvă $(A - \\lambda I)v = 0$.',
    '$\\lambda = 2$: $v = (2, -2, 1)$; $\\lambda = 3$: $v = (0, 1, -1)$; $\\lambda = 4$: $v = (0, 0, 1)$. Trei valori proprii distincte: matricea e diagonalizabilă.')

math_problem(ALG, 15, 'Proiecția pe o dreaptă', AL3, 'ușoară', '''
Găsește proiecția ortogonală $p$ a vectorului $v = (1, 2, 3)$ pe dreapta generată de $u = (1, 1, 1)$. Se verifică: $p$ e pe dreaptă și $v - p \\perp u$.''',
    [mat('p', 'p =', 3, 1)],
    [ck('abs(([1; 2; 3] - p)\' * [1; 1; 1]) < 1e-9', 'v − p e perpendicular pe u'), ck('norm(p - (p\' * [1; 1; 1]) / 3 * [1; 1; 1]) < 1e-9', 'p e pe dreapta lui u')],
    {'p': [['2'], ['2'], ['2']]}, {'p': [['1'], ['1'], ['1']]},
    '$p = \\frac{\\langle v, u \\rangle}{\\langle u, u \\rangle}\\,u$.', '$\\langle v, u\\rangle = 6$, $\\langle u, u\\rangle = 3$: $p = 2u = (2, 2, 2)$.')

math_problem(ALG, 16, 'Oscilatorul armonic', AL4, 'ușoară', '''
Rezolvă $y'' + 4y = 0$, $y(0) = 0$, $y'(0) = 2$.''',
    [expr('y', 'y(x) =')],
    [ck(f'close(deriv2(y, {XX}) + 4*y({XX}), zeros(1, 6), 2e-3)', "y'' + 4y = 0"), ck('abs(y(0)) < 1e-9', 'y(0) = 0'), ck('abs(deriv(y, 0) - 2) < 1e-6', "y'(0) = 2")],
    {'y': 'sin 2x'}, {'y': '2 sin x'},
    'Ecuația caracteristică $r^2 + 4 = 0$ are rădăcinile $\\pm 2i$: $y = C_1 \\cos 2x + C_2 \\sin 2x$.',
    '$y(0) = C_1 = 0$, $y\'(0) = 2C_2 = 2$: $y = \\sin 2x$.',
    plot={'field': 'y', 'range': [-3.2, 3.2], 'ref': '@(x) sin(2*x)', 'refLabel': 'soluția', 'label': 'y(x)'})

write_course('am', [AM1, AM2, AM3, AM4], AM)
write_course('ms', [MS1, MS2, MS3, MS4], MS)
write_course('algaed', [AL1, AL2, AL3, AL4], ALG)
