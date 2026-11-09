"""Admitere ACS: the multiple-choice test (grilă), maths and informatics.

As at the UPB admission exam: a question with six answers, a) to f), one of
them correct. Nothing here is copied from a real paper; the questions are
written in the style of the exam's syllabus (algebra and calculus from the
M1 programme, C++ for informatics).

No answer is written by hand. For maths, `truth` is computed (with sympy) and
must equal exactly one option's value; for a program, the code is compiled
with g++ and run, and its output must be exactly one option. The options are
then shuffled (the same way each run), so the right letter moves around.

Run from the repo root:  python3 -I tool/acs/admitere.py
"""
import os, random, subprocess, sys, tempfile
import sympy as sp
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

A1 = '1. Algebră: ecuații, progresii, combinatorică'
A2 = '2. Algebră: matrice, sisteme, legi de compoziție'
A3 = '3. Analiză: limite și derivate'
A4 = '4. Analiză: integrale'
I1 = '5. Informatică: ce afișează programul'
I2 = '6. Informatică: algoritmi'
CHAPTERS = [A1, A2, A3, A4, I1, I2]
P = []

x, n, m, a = sp.symbols('x n m a', real=True)


def same(u, v):
    if isinstance(u, (sp.Basic, int)) and isinstance(v, (sp.Basic, int)):
        return sp.simplify(sp.nsimplify(u) - sp.nsimplify(v)) == 0
    return u == v


def place(id, options, correct):
    """Shuffle the options the same way every run; the new index of the correct one."""
    order = list(range(len(options)))
    random.Random(f'admitere-{id}').shuffle(order)
    return [options[i] for i in order], order.index(correct)


def grila(id, title, ch, diff, statement, options, vals, truth, hint, solution):
    assert len(options) == 6 == len(vals), (id, len(options), len(vals))
    hits = [i for i, v in enumerate(vals) if same(v, truth)]
    assert len(hits) == 1, f'{id} {title}: {len(hits)} options equal the truth {truth!r}'
    opts, ans = place(id, options, hits[0])
    P.append(problem(id, title, ch, diff, statement, 'grila', {'options': opts, 'answer': ans}, hint, solution))


def run_cpp(code, stdin=''):
    d = tempfile.mkdtemp(prefix='acs_adm_')
    src, exe = os.path.join(d, 'main.cpp'), os.path.join(d, 'a.out')
    with open(src, 'w') as f:
        f.write(code)
    r = subprocess.run(['g++', '-std=c++17', '-O1', '-o', exe, src], capture_output=True, text=True)
    if r.returncode != 0:
        raise SystemExit(f'g++ failed:\n{r.stderr}\n{code}')
    return subprocess.run([exe], input=stdin, capture_output=True, text=True, timeout=10).stdout


def program(id, title, diff, intro, code, options, hint, solution, ch=I1):
    """A 'what does it print' question: the output, from g++, must be exactly one option."""
    out = run_cpp(code).strip()
    hits = [i for i, o in enumerate(options) if o == out]
    assert len(hits) == 1, f'{id} {title}: the program prints {out!r}, options {options}'
    assert len(options) == 6
    opts, ans = place(id, [f'`{o}`' for o in options], hits[0])
    statement = f'{intro.strip()}\n\n```\n{code.strip()}\n```'
    P.append(problem(id, title, ch, diff, statement, 'grila', {'options': opts, 'answer': ans, 'output': out}, hint, solution))


# ============================================================ 1. algebra
t = sp.Symbol('t', positive=True)
sols = sp.solve(t**2 - 3*t + 2, t)
grila(1, 'O ecuație exponențială', A1, 'ușoară', r'''
Suma soluțiilor reale ale ecuației $4^x - 3 \cdot 2^x + 2 = 0$ este:''',
      ['$0$', '$1$', '$2$', '$3$', '$-1$', '$\\frac{3}{2}$'], [0, 1, 2, 3, -1, sp.Rational(3, 2)],
      sum(sp.log(s, 2) for s in sols),
      'Notează $t = 2^x > 0$: ecuația devine de gradul al doilea în $t$.',
      '$t^2 - 3t + 2 = 0$ dă $t = 1$ sau $t = 2$, adică $x = 0$ sau $x = 1$. Suma: $1$.')

grila(2, 'O ecuație cu logaritmi', A1, 'ușoară', r'''
Mulțimea soluțiilor ecuației $\log_2(x + 1) + \log_2(x - 1) = 3$ este:''',
      ['$\\{3\\}$', '$\\{-3, 3\\}$', '$\\{-3\\}$', '$\\{2\\sqrt{2}\\}$', '$\\{9\\}$', '$\\emptyset$'],
      [frozenset({3}), frozenset({-3, 3}), frozenset({-3}), frozenset({2 * sp.sqrt(2)}), frozenset({9}), frozenset()],
      frozenset(s for s in sp.solve((x + 1) * (x - 1) - 8, x) if s > 1),
      'Condițiile de existență: $x + 1 > 0$ și $x - 1 > 0$, deci $x > 1$. Apoi $\\log_2 a + \\log_2 b = \\log_2(ab)$.',
      '$(x + 1)(x - 1) = 2^3$, adică $x^2 = 9$. Doar $x = 3$ respectă $x > 1$.')

a1, r = sp.symbols('a1 r')
s_ = sp.solve([a1 - 2, a1 + 4 * r - 14], [a1, r])
grila(3, 'Suma unei progresii aritmetice', A1, 'ușoară', r'''
Într-o progresie aritmetică $(a_n)_{n \ge 1}$ avem $a_1 = 2$ și $a_5 = 14$. Suma primilor 10 termeni este:''',
      ['$155$', '$145$', '$165$', '$150$', '$140$', '$290$'], [155, 145, 165, 150, 140, 290],
      sum(s_[a1] + k * s_[r] for k in range(10)),
      '$a_5 = a_1 + 4r$, apoi $S_n = \\frac{(a_1 + a_n)\\,n}{2}$.',
      '$r = 3$, $a_{10} = 2 + 9 \\cdot 3 = 29$, $S_{10} = \\frac{(2 + 29) \\cdot 10}{2} = 155$.')

grila(4, 'Combinări și aranjamente', A1, 'ușoară', r'''
Valoarea expresiei $C_6^2 + A_5^2$ este:''',
      ['$35$', '$30$', '$25$', '$45$', '$50$', '$36$'], [35, 30, 25, 45, 50, 36],
      sp.binomial(6, 2) + sp.ff(5, 2),
      '$C_n^k = \\frac{n!}{k!(n-k)!}$, $A_n^k = \\frac{n!}{(n-k)!}$.',
      '$C_6^2 = 15$, $A_5^2 = 5 \\cdot 4 = 20$; suma: $35$.')

grila(5, 'Un polinom divizibil cu X − 2', A1, 'medie', r'''
Polinomul $f = X^3 - 2X^2 + aX + 4$ este divizibil cu $X - 2$ pentru $a$ egal cu:''',
      ['$-2$', '$2$', '$-4$', '$4$', '$0$', '$-1$'], [-2, 2, -4, 4, 0, -1],
      sp.solve((x**3 - 2 * x**2 + a * x + 4).subs(x, 2), a)[0],
      'Teorema lui Bézout: $X - 2$ divide $f$ dacă și numai dacă $f(2) = 0$.',
      '$f(2) = 8 - 8 + 2a + 4 = 0$, deci $a = -2$.')

x1, x2 = sp.solve(x**2 - 5 * x + 3, x)
grila(6, 'Relațiile lui Viète', A1, 'ușoară', r'''
Dacă $x_1, x_2$ sunt soluțiile ecuației $x^2 - 5x + 3 = 0$, atunci $x_1^2 + x_2^2$ este:''',
      ['$19$', '$25$', '$31$', '$22$', '$16$', '$28$'], [19, 25, 31, 22, 16, 28],
      sp.expand(x1**2 + x2**2),
      '$x_1^2 + x_2^2 = (x_1 + x_2)^2 - 2x_1x_2$.',
      '$S = 5$, $P = 3$: $25 - 6 = 19$.')

grila(7, 'Numere întregi într-o inecuație', A1, 'ușoară', r'''
Numărul de numere întregi $x$ care verifică $|2x - 3| \le 5$ este:''',
      ['$6$', '$5$', '$7$', '$4$', '$8$', '$10$'], [6, 5, 7, 4, 8, 10],
      sum(1 for k in range(-20, 21) if abs(2 * k - 3) <= 5),
      '$|u| \\le 5$ înseamnă $-5 \\le u \\le 5$.',
      '$-5 \\le 2x - 3 \\le 5$ dă $-1 \\le x \\le 4$: numerele $-1, 0, 1, 2, 3, 4$, adică $6$.')

grila(8, 'Minimul unei funcții de gradul al doilea', A1, 'ușoară', r'''
Valoarea minimă a funcției $f : \mathbb{R} \to \mathbb{R}$, $f(x) = x^2 - 4x + 3$ este:''',
      ['$-1$', '$3$', '$0$', '$2$', '$-2$', '$1$'], [-1, 3, 0, 2, -2, 1],
      sp.minimum(x**2 - 4 * x + 3, x),
      'Vârful parabolei: $x_V = -\\frac{b}{2a}$, $y_V = -\\frac{\\Delta}{4a}$.',
      '$x_V = 2$, $f(2) = 4 - 8 + 3 = -1$.')

k = sp.Symbol('k', integer=True)
grila(9, 'Termeni raționali într-o dezvoltare', A1, 'grea', r'''
Numărul termenilor raționali din dezvoltarea $\left(\sqrt{2} + \sqrt[3]{3}\right)^{12}$ este:''',
      ['$3$', '$2$', '$4$', '$5$', '$6$', '$13$'], [3, 2, 4, 5, 6, 13],
      sum(1 for j in range(13) if (12 - j) % 2 == 0 and j % 3 == 0),
      '$T_{k+1} = C_{12}^k\\, 2^{\\frac{12-k}{2}}\\, 3^{\\frac{k}{3}}$: e rațional când ambii exponenți sunt întregi.',
      '$12 - k$ par și $k$ multiplu de 3: $k \\in \\{0, 6, 12\\}$, deci 3 termeni.')

grila(10, 'Modulul unei puteri complexe', A1, 'medie', r'''
Modulul numărului complex $z = (1 + i)^{10}$ este:''',
      ['$32$', '$1024$', '$10$', '$16$', '$64$', '$\\sqrt{2}$'], [32, 1024, 10, 16, 64, sp.sqrt(2)],
      sp.Abs((1 + sp.I)**10),
      '$|z^n| = |z|^n$.',
      '$|1 + i| = \\sqrt{2}$, deci $|z| = (\\sqrt{2})^{10} = 2^5 = 32$.')

grila(11, 'Mulțimea valorilor unei funcții', A1, 'medie', r'''
Pentru câte valori naturale ale lui $m$ ecuația $x^2 - 2mx + m + 6 = 0$ **nu** are soluții reale?''',
      ['$3$', '$2$', '$4$', '$5$', '$1$', '$0$'], [3, 2, 4, 5, 1, 0],
      sum(1 for j in range(0, 50) if (2 * j)**2 - 4 * (j + 6) < 0),
      'Fără soluții reale: $\\Delta < 0$.',
      '$\\Delta = 4m^2 - 4(m + 6) = 4(m^2 - m - 6) = 4(m - 3)(m + 2) < 0$ pentru $m \\in (-2, 3)$: naturalele $0, 1, 2$.')

# ============================================================ 2. matrices
M = sp.Matrix([[1, 2, 3], [2, 3, 1], [3, 1, 2]])
grila(12, 'Un determinant de ordinul 3', A2, 'ușoară', r'''
Determinantul matricei $A = \begin{pmatrix} 1 & 2 & 3 \\ 2 & 3 & 1 \\ 3 & 1 & 2 \end{pmatrix}$ este:''',
      ['$-18$', '$18$', '$0$', '$-6$', '$6$', '$-12$'], [-18, 18, 0, -6, 6, -12], M.det(),
      'Regula lui Sarrus, sau adună toate coloanele la prima (toate liniile au suma 6).',
      'Adunând coloanele la prima: $6 \\cdot \\begin{vmatrix} 1 & 2 & 3 \\\\ 1 & 3 & 1 \\\\ 1 & 1 & 2 \\end{vmatrix} = 6 \\cdot (-3) = -18$.')

B = sp.Matrix([[1, 1], [0, 1]])
grila(13, 'Puterea unei matrice', A2, 'ușoară', r'''
Fie $A = \begin{pmatrix} 1 & 1 \\ 0 & 1 \end{pmatrix}$. Suma elementelor matricei $A^{10}$ este:''',
      ['$12$', '$11$', '$4$', '$1024$', '$20$', '$13$'], [12, 11, 4, 1024, 20, 13], sum(B**10),
      'Calculează $A^2$, $A^3$ și ghicește forma lui $A^n$ (apoi inducție).',
      '$A^n = \\begin{pmatrix} 1 & n \\\\ 0 & 1 \\end{pmatrix}$, deci $A^{10}$ are suma $1 + 10 + 0 + 1 = 12$.')

S = sp.Matrix([[1, 1, 1], [1, m, 1], [1, 1, m]])
bad = frozenset(sp.solve(S.det(), m))
grila(14, 'Când are un sistem soluție unică', A2, 'medie', r'''
Sistemul $\begin{cases} x + y + z = 1 \\ x + my + z = 2 \\ x + y + mz = 3 \end{cases}$ are soluție unică dacă și numai dacă:''',
      ['$m \\in \\mathbb{R} \\setminus \\{1\\}$', '$m \\in \\mathbb{R} \\setminus \\{-1\\}$', '$m \\in \\mathbb{R} \\setminus \\{-1, 1\\}$', '$m = 1$', '$m \\in \\mathbb{R}$', '$m \\in \\mathbb{R} \\setminus \\{0\\}$'],
      [('R minus', frozenset({1})), ('R minus', frozenset({-1})), ('R minus', frozenset({-1, 1})), ('only', frozenset({1})), ('R minus', frozenset()), ('R minus', frozenset({0}))],
      ('R minus', bad),
      'Soluție unică (sistem Cramer) când determinantul sistemului e nenul.',
      '$\\det = (m - 1)^2$, nenul pentru $m \\ne 1$.')

y = sp.Symbol('y', real=True)
e = sp.Symbol('e', real=True)
law = x * y - 2 * x - 2 * y + 6
neutral = sp.solve(sp.Eq(law.subs(y, e), x), e)
grila(15, 'Elementul neutru al unei legi', A2, 'medie', r'''
Pe $(2, \infty)$ se definește legea $x \circ y = xy - 2x - 2y + 6$. Elementul neutru al legii este:''',
      ['$3$', '$2$', '$1$', '$6$', '$4$', '$\\frac{5}{2}$'], [3, 2, 1, 6, 4, sp.Rational(5, 2)],
      neutral[0],
      'Scrie legea ca $x \\circ y = (x - 2)(y - 2) + 2$.',
      '$x \\circ e = x$ înseamnă $(x - 2)(e - 2) = x - 2$ pentru orice $x > 2$, deci $e - 2 = 1$, $e = 3$.')

C = sp.Matrix([[2, 1], [5, 3]])
grila(16, 'Inversa unei matrice', A2, 'ușoară', r'''
Fie $A = \begin{pmatrix} 2 & 1 \\ 5 & 3 \end{pmatrix}$. Suma elementelor matricei $A^{-1}$ este:''',
      ['$-1$', '$1$', '$11$', '$0$', '$-11$', '$\\frac{1}{11}$'], [-1, 1, 11, 0, -11, sp.Rational(1, 11)], sum(C.inv()),
      'Pentru $2 \\times 2$: $A^{-1} = \\frac{1}{\\det A}\\begin{pmatrix} d & -b \\\\ -c & a \\end{pmatrix}$.',
      '$\\det A = 1$, $A^{-1} = \\begin{pmatrix} 3 & -1 \\\\ -5 & 2 \\end{pmatrix}$, suma $-1$.')

R = sp.Matrix([[1, 2, 3], [2, 4, 6], [1, 0, 1]])
grila(17, 'Rangul unei matrice', A2, 'ușoară', r'''
Rangul matricei $\begin{pmatrix} 1 & 2 & 3 \\ 2 & 4 & 6 \\ 1 & 0 & 1 \end{pmatrix}$ este:''',
      ['$2$', '$1$', '$3$', '$0$', '$4$', '$6$'], [2, 1, 3, 0, 4, 6], R.rank(),
      'A doua linie e de două ori prima. Caută un minor de ordin 2 nenul.',
      'Determinantul e $0$ (liniile 1 și 2 proporționale), iar $\\begin{vmatrix} 1 & 2 \\\\ 1 & 0 \\end{vmatrix} = -2 \\ne 0$: rangul e $2$.')

X = sp.Matrix(2, 2, sp.symbols('p q r s'))
grila(18, 'Câte matrice comută cu A', A2, 'grea', r'''
Fie $A = \begin{pmatrix} 1 & 1 \\ 0 & 1 \end{pmatrix}$. Câte matrice $X \in \mathcal{M}_2(\mathbb{Z}_2)$ (cu elemente din $\{0, 1\}$, operații modulo 2) verifică $AX = XA$?''',
      ['$4$', '$2$', '$8$', '$16$', '$1$', '$6$'], [4, 2, 8, 16, 1, 6],
      sum(1 for v in range(16)
          if ((B * sp.Matrix(2, 2, [(v >> i) & 1 for i in range(4)]) - sp.Matrix(2, 2, [(v >> i) & 1 for i in range(4)]) * B).applyfunc(lambda z: z % 2)) == sp.zeros(2)),
      'Scrie $X = \\begin{pmatrix} p & q \\\\ r & s \\end{pmatrix}$ și egalează $AX$ cu $XA$.',
      '$AX = XA$ dă $r = 0$ și $p = s$; $q$ e oarecare: $X = \\begin{pmatrix} p & q \\\\ 0 & p \\end{pmatrix}$, $2 \\cdot 2 = 4$ matrice.')

# ============================================================ 3. limits, derivatives
grila(19, 'Limita unui raport de polinoame', A3, 'ușoară', r'''
$\displaystyle\lim_{n \to \infty} \frac{n^2 + 3n}{2n^2 + 1}$ este:''',
      ['$\\frac{1}{2}$', '$0$', '$\\infty$', '$2$', '$3$', '$1$'], [sp.Rational(1, 2), 0, sp.oo, 2, 3, 1],
      sp.limit((n**2 + 3 * n) / (2 * n**2 + 1), n, sp.oo),
      'Același grad sus și jos: raportul coeficienților dominanți.', 'Împărțind la $n^2$: $\\frac{1 + 3/n}{2 + 1/n^2} \\to \\frac{1}{2}$.')

grila(20, 'O limită remarcabilă', A3, 'ușoară', r'''
$\displaystyle\lim_{x \to 0} \frac{e^{2x} - 1}{x}$ este:''',
      ['$2$', '$1$', '$0$', '$e^2$', '$\\frac{1}{2}$', '$\\infty$'], [2, 1, 0, sp.E**2, sp.Rational(1, 2), sp.oo],
      sp.limit((sp.exp(2 * x) - 1) / x, x, 0),
      '$\\lim_{u \\to 0} \\frac{e^u - 1}{u} = 1$.', '$\\frac{e^{2x} - 1}{2x} \\cdot 2 \\to 1 \\cdot 2 = 2$.')

grila(21, 'Limita care dă un e', A3, 'medie', r'''
$\displaystyle\lim_{n \to \infty} \left(1 + \frac{2}{n}\right)^n$ este:''',
      ['$e^2$', '$e$', '$1$', '$2$', '$\\infty$', '$\\sqrt{e}$'], [sp.E**2, sp.E, 1, 2, sp.oo, sp.sqrt(sp.E)],
      sp.limit((1 + 2 / n)**n, n, sp.oo),
      '$\\left(1 + \\frac{1}{u}\\right)^u \\to e$ când $u \\to \\infty$.', '$\\left[\\left(1 + \\frac{2}{n}\\right)^{n/2}\\right]^2 \\to e^2$.')

grila(22, 'Derivata într-un punct', A3, 'ușoară', r'''
Pentru $f : (0, \infty) \to \mathbb{R}$, $f(x) = x \ln x$, valoarea $f'(e)$ este:''',
      ['$2$', '$1$', '$e$', '$0$', '$e + 1$', '$\\frac{1}{e}$'], [2, 1, sp.E, 0, sp.E + 1, 1 / sp.E],
      sp.diff(x * sp.log(x), x).subs(x, sp.E),
      "$(uv)' = u'v + uv'$.", "$f'(x) = \\ln x + 1$, deci $f'(e) = 2$.")

grila(23, 'Maximul local', A3, 'ușoară', r'''
Valoarea maximă locală a funcției $f(x) = x^3 - 3x$ este:''',
      ['$2$', '$-2$', '$0$', '$1$', '$-1$', '$3$'], [2, -2, 0, 1, -1, 3],
      max((x**3 - 3 * x).subs(x, c) for c in sp.solve(sp.diff(x**3 - 3 * x, x), x) if sp.diff(x**3 - 3 * x, x, 2).subs(x, c) < 0),
      "Punctele critice: $f'(x) = 0$; maxim acolo unde $f'' < 0$.",
      "$f'(x) = 3x^2 - 3 = 0$ dă $x = \\pm 1$; $f''(-1) = -6 < 0$: maxim local $f(-1) = -1 + 3 = 2$.")

grila(24, 'Ecuația tangentei', A3, 'ușoară', r'''
Tangenta la graficul funcției $f(x) = x^2$ în punctul de abscisă $x_0 = 1$ are ecuația:''',
      ['$y = 2x - 1$', '$y = 2x + 1$', '$y = x$', '$y = 2x$', '$y = x + 1$', '$y = -2x + 3$'],
      [(2, -1), (2, 1), (1, 0), (2, 0), (1, 1), (-2, 3)],
      (sp.diff(x**2, x).subs(x, 1), 1 - sp.diff(x**2, x).subs(x, 1)),
      "$y - f(x_0) = f'(x_0)(x - x_0)$.", "$f(1) = 1$, $f'(1) = 2$: $y - 1 = 2(x - 1)$, adică $y = 2x - 1$.")

f = (x**2 + 1) / (x - 1)
mm = sp.limit(f / x, x, sp.oo)
grila(25, 'Asimptota oblică', A3, 'medie', r'''
Asimptota oblică spre $+\infty$ a graficului funcției $f(x) = \dfrac{x^2 + 1}{x - 1}$ este:''',
      ['$y = x + 1$', '$y = x - 1$', '$y = x$', '$y = 2x + 1$', '$y = x + 2$', '$y = 1$'],
      [(1, 1), (1, -1), (1, 0), (2, 1), (1, 2), (0, 1)],
      (mm, sp.limit(f - mm * x, x, sp.oo)),
      '$m = \\lim \\frac{f(x)}{x}$, $n = \\lim (f(x) - mx)$.', '$m = 1$, $n = \\lim \\frac{x^2 + 1 - x^2 + x}{x - 1} = 1$: $y = x + 1$.')

grila(26, 'O limită cu radical', A3, 'medie', r'''
$\displaystyle\lim_{x \to \infty} \left(\sqrt{x^2 + 4x} - x\right)$ este:''',
      ['$2$', '$0$', '$4$', '$\\infty$', '$1$', '$-2$'], [2, 0, 4, sp.oo, 1, -2],
      sp.limit(sp.sqrt(x**2 + 4 * x) - x, x, sp.oo),
      'Amplifică cu conjugatul $\\sqrt{x^2 + 4x} + x$.', '$\\frac{4x}{\\sqrt{x^2 + 4x} + x} = \\frac{4}{\\sqrt{1 + 4/x} + 1} \\to 2$.')

grila(27, 'Monotonia unei funcții', A3, 'medie', r'''
Funcția $f : \mathbb{R} \to \mathbb{R}$, $f(x) = x^3 + ax$ este strict crescătoare pe $\mathbb{R}$ dacă și numai dacă:''',
      ['$a \\ge 0$', '$a > 0$', '$a \\le 0$', '$a < 0$', '$a \\in \\mathbb{R}$', '$a = 0$'],
      ['>=0', '>0', '<=0', '<0', 'R', '=0'],
      # a >= 0: f' = 3x^2 + a >= 0, zero at most at x = 0, so still strictly increasing; a < 0: f'(0) = a < 0
      '>=0',
      "$f'(x) = 3x^2 + a$. Atenție la $a = 0$: $f' $ se anulează doar în $0$.",
      "Pentru $a \\ge 0$, $f'(x) = 3x^2 + a \\ge 0$ și se anulează cel mult în $x = 0$, deci $f$ e strict crescătoare (și $x^3$ e). Pentru $a < 0$, $f'(0) = a < 0$: $f$ scade lângă 0.")

# ============================================================ 4. integrals
grila(28, 'O integrală definită', A4, 'ușoară', r'''
$\displaystyle\int_0^1 (3x^2 + 2x)\,dx$ este:''',
      ['$2$', '$1$', '$5$', '$3$', '$\\frac{5}{6}$', '$0$'], [2, 1, 5, 3, sp.Rational(5, 6), 0],
      sp.integrate(3 * x**2 + 2 * x, (x, 0, 1)),
      'O primitivă: $x^3 + x^2$.', '$(x^3 + x^2)\\big|_0^1 = 2$.')

grila(29, 'Sinus ori cosinus', A4, 'ușoară', r'''
$\displaystyle\int_0^{\pi/2} \sin x \cos x\,dx$ este:''',
      ['$\\frac{1}{2}$', '$1$', '$0$', '$\\frac{\\pi}{4}$', '$2$', '$-\\frac{1}{2}$'], [sp.Rational(1, 2), 1, 0, sp.pi / 4, 2, -sp.Rational(1, 2)],
      sp.integrate(sp.sin(x) * sp.cos(x), (x, 0, sp.pi / 2)),
      'Substituția $u = \\sin x$, sau $\\sin x \\cos x = \\frac{1}{2}\\sin 2x$.', '$\\frac{\\sin^2 x}{2}\\Big|_0^{\\pi/2} = \\frac{1}{2}$.')

grila(30, 'Integrala logaritmului', A4, 'medie', r'''
$\displaystyle\int_1^e \ln x\,dx$ este:''',
      ['$1$', '$e$', '$e - 1$', '$0$', '$\\frac{1}{e}$', '$2$'], [1, sp.E, sp.E - 1, 0, 1 / sp.E, 2],
      sp.integrate(sp.log(x), (x, 1, sp.E)),
      'Prin părți: $u = \\ln x$, $dv = dx$.', '$(x \\ln x - x)\\big|_1^e = (e - e) - (0 - 1) = 1$.')

grila(31, 'Aria dintre două curbe', A4, 'medie', r'''
Aria suprafeței cuprinse între graficele funcțiilor $f(x) = x$ și $g(x) = x^2$ este:''',
      ['$\\frac{1}{6}$', '$\\frac{1}{2}$', '$\\frac{1}{3}$', '$1$', '$\\frac{5}{6}$', '$\\frac{2}{3}$'],
      [sp.Rational(1, 6), sp.Rational(1, 2), sp.Rational(1, 3), 1, sp.Rational(5, 6), sp.Rational(2, 3)],
      sp.integrate(x - x**2, (x, 0, 1)),
      'Curbele se taie în $x = 0$ și $x = 1$; pe $[0, 1]$, $x \\ge x^2$.', '$\\int_0^1 (x - x^2)\\,dx = \\frac{1}{2} - \\frac{1}{3} = \\frac{1}{6}$.')

grila(32, 'Prin părți, cu exponențiala', A4, 'medie', r'''
$\displaystyle\int_0^1 x e^x\,dx$ este:''',
      ['$1$', '$e$', '$e - 1$', '$2e - 1$', '$0$', '$\\frac{e}{2}$'], [1, sp.E, sp.E - 1, 2 * sp.E - 1, 0, sp.E / 2],
      sp.integrate(x * sp.exp(x), (x, 0, 1)),
      'Prin părți: $u = x$, $dv = e^x dx$.', '$(x - 1)e^x\\big|_0^1 = 0 - (-1) = 1$.')

grila(33, 'O sumă Riemann', A4, 'grea', r'''
$\displaystyle\lim_{n \to \infty} \frac{1^2 + 2^2 + \ldots + n^2}{n^3}$ este:''',
      ['$\\frac{1}{3}$', '$\\frac{1}{2}$', '$1$', '$0$', '$\\frac{1}{6}$', '$\\infty$'],
      [sp.Rational(1, 3), sp.Rational(1, 2), 1, 0, sp.Rational(1, 6), sp.oo],
      sp.limit(sp.summation(k**2, (k, 1, n)) / n**3, n, sp.oo),
      'Fie formula $\\sum k^2 = \\frac{n(n+1)(2n+1)}{6}$, fie suma Riemann $\\frac{1}{n}\\sum \\left(\\frac{k}{n}\\right)^2$.',
      '$\\frac{1}{n}\\sum_{k=1}^n \\left(\\frac{k}{n}\\right)^2 \\to \\int_0^1 x^2\\,dx = \\frac{1}{3}$.')

grila(34, 'Integrala unei funcții pare și impare', A4, 'medie', r'''
$\displaystyle\int_{-1}^{1} \left(x^5 \cos x + x^2\right)dx$ este:''',
      ['$\\frac{2}{3}$', '$0$', '$\\frac{1}{3}$', '$2$', '$\\frac{4}{3}$', '$1$'],
      [sp.Rational(2, 3), 0, sp.Rational(1, 3), 2, sp.Rational(4, 3), 1],
      sp.integrate(x**5 * sp.cos(x) + x**2, (x, -1, 1)),
      'Pe un interval simetric, integrala unei funcții impare e $0$.', '$x^5 \\cos x$ e impară (integrala $0$), iar $\\int_{-1}^1 x^2\\,dx = \\frac{2}{3}$.')

# ============================================================ 5. what does it print
HEAD = '#include <iostream>\nusing namespace std;\n\n'

program(35, 'Cifrele unui număr', 'ușoară', 'Ce afișează programul de mai jos?', HEAD + '''int main() {
    int n = 52817, s = 0, p = 1;
    while (n > 0) {
        int c = n % 10;
        if (c % 2 == 0) s = s + c * p;
        else p = p * 10;
        n = n / 10;
    }
    cout << s;
    return 0;
}''', ['1000', '800', '28', '208', '820', '82'],
        'Urmărește pe hârtie $n$, $c$, $s$ și $p$ la fiecare pas: cifrele se iau de la dreapta, iar $p$ crește doar la cifrele impare.',
        'Cifrele, de la dreapta: 7 impară ($p = 10$), 1 impară ($p = 100$), 8 pară ($s = 8 \\cdot 100 = 800$), 2 pară ($s = 800 + 2 \\cdot 100 = 1000$), 5 impară ($p = 1000$). Se afișează 1000.')

program(36, 'Recursivitate: un șir', 'ușoară', 'Ce afișează programul?', HEAD + '''int f(int n) {
    if (n <= 1) return 1;
    return f(n - 1) + f(n - 2);
}

int main() {
    cout << f(6);
    return 0;
}''', ['13', '8', '21', '6', '5', '720'],
        'Calculează de jos în sus: $f(0) = f(1) = 1$, apoi $f(2) = 2$, ...', '$f$: 1, 1, 2, 3, 5, 8, 13: $f(6) = 13$.')

program(37, 'Afișare la intrare și la ieșire', 'medie', 'Ce afișează programul?', HEAD + '''void f(int n) {
    if (n > 0) {
        cout << n;
        f(n - 2);
        cout << n;
    }
}

int main() {
    f(5);
    return 0;
}''', ['531135', '531', '135531', '5311', '53135', '5310135'],
        'Fiecare apel scrie $n$ înainte și după apelul pentru $n - 2$.', 'Scrie 5, 3, 1 coborând, $f(-1)$ nu scrie nimic, apoi 1, 3, 5 la întoarcere: 531135.')

program(38, 'Bucle imbricate', 'ușoară', 'Ce afișează programul?', HEAD + '''int main() {
    int n = 10, cnt = 0;
    for (int i = 1; i <= n; i++)
        for (int j = i; j <= n; j++)
            cnt++;
    cout << cnt;
    return 0;
}''', ['55', '100', '45', '50', '10', '110'],
        'Pentru un $i$ fixat, bucla interioară face $n - i + 1$ pași.', '$10 + 9 + \\ldots + 1 = 55$.')

program(39, 'Operații pe biți', 'medie', 'Ce afișează programul?', HEAD + '''int main() {
    int x = 13;
    cout << (x & 6) << ' ' << (x | 2) << ' ' << (x ^ 5) << ' ' << (x >> 1);
    return 0;
}''', ['4 15 8 6', '6 15 8 6', '4 13 8 6', '4 15 18 7', '1 15 8 6', '4 15 8 26'],
        'Scrie în baza 2: $13 = 1101_2$, $6 = 0110_2$, $5 = 0101_2$.', '$1101 \\,\\&\\, 0110 = 0100 = 4$, $1101 \\,|\\, 0010 = 1111 = 15$, $1101 \\oplus 0101 = 1000 = 8$, $13 \\gg 1 = 6$.')

program(40, 'Un vector inversat pe jumătate', 'medie', 'Ce afișează programul?', HEAD + '''int main() {
    int v[] = {1, 2, 3, 4, 5, 6}, n = 6;
    for (int i = 0; i < n / 2; i += 2) {
        int t = v[i];
        v[i] = v[n - 1 - i];
        v[n - 1 - i] = t;
    }
    for (int i = 0; i < n; i++) cout << v[i];
    return 0;
}''', ['624351', '654321', '123456', '623451', '624531', '524361'],
        'Atenție la pasul $i$ += 2: se schimbă doar perechile cu $i = 0$ și $i = 2$.', 'Se schimbă $v[0] \\leftrightarrow v[5]$ și $v[2] \\leftrightarrow v[3]$: 6 2 4 3 5 1.')

program(41, 'Un șir de caractere', 'medie', 'Ce afișează programul?', '#include <iostream>\n#include <cstring>\nusing namespace std;\n\n' + '''int main() {
    char s[] = "admitere";
    int n = strlen(s), k = 0;
    for (int i = 0; i < n; i++)
        if (strchr("aeiou", s[i]) == NULL) s[k++] = s[i];
    s[k] = 0;
    cout << s << ' ' << n - k;
    return 0;
}''', ['dmtr 4', 'dmtr 3', 'aiee 4', 'admtr 3', 'dmtr 8', 'dmitr 3'],
        '`strchr("aeiou", c)` e diferit de NULL exact când c e vocală.', 'Rămân consoanele d, m, t, r (vocalele a, i, e, e sunt scoase, 4 la număr): „dmtr 4”.')

program(42, 'Diagonalele unei matrice', 'medie', 'Ce afișează programul?', HEAD + '''int main() {
    int a[4][4], s = 0;
    for (int i = 0; i < 4; i++)
        for (int j = 0; j < 4; j++)
            a[i][j] = i * 4 + j;
    for (int i = 0; i < 4; i++)
        s += a[i][i] - a[i][3 - i];
    cout << s << ' ' << a[2][1];
    return 0;
}''', ['0 9', '30 9', '0 6', '-30 9', '60 9', '0 10'],
        '$a[i][j] = 4i + j$: scrie matricea (0..15).', 'Diagonala principală: 0 + 5 + 10 + 15 = 30; secundara: 3 + 6 + 9 + 12 = 30; diferența 0. $a[2][1] = 9$.')

program(43, 'Câte apeluri face recursivitatea', 'grea', 'Ce afișează programul?', HEAD + '''int apeluri = 0;

int fib(int n) {
    apeluri++;
    if (n < 2) return n;
    return fib(n - 1) + fib(n - 2);
}

int main() {
    int r = fib(6);
    cout << r << ' ' << apeluri;
    return 0;
}''', ['8 25', '8 13', '13 25', '8 15', '8 24', '13 41'],
        'Numărul de apeluri $A(n) = 1 + A(n - 1) + A(n - 2)$, cu $A(0) = A(1) = 1$.', '$fib(6) = 8$; $A$: 1, 1, 3, 5, 9, 15, 25: 25 de apeluri.')

program(44, 'Împărțiri întregi', 'ușoară', 'Ce afișează programul?', HEAD + '''int main() {
    int a = 17, b = 5;
    double c = a / b;
    cout << a / b * b + a % b << ' ' << c << ' ' << (double)a / b;
    return 0;
}''', ['17 3 3.4', '17 3.4 3.4', '15 3 3.4', '17 3 3', '17 3.4 3', '12 3 3.4'],
        '`a / b` între două `int` e o împărțire întreagă, chiar dacă rezultatul se pune într-un `double`.', '$17 / 5 \\cdot 5 + 17 \\% 5 = 15 + 2 = 17$; `c = 3`; `(double)a / b = 3.4`.')

# ============================================================ 6. algorithms
from itertools import permutations, product, combinations

perms = list(permutations([1, 2, 3, 4]))
grila(45, 'Permutări în ordine lexicografică', I2, 'medie', r'''
Se generează, cu metoda backtracking, în ordine lexicografică, toate permutările mulțimii $\{1, 2, 3, 4\}$. A **zecea** permutare generată este:''',
      ['`2 3 1 4`', '`2 1 4 3`', '`2 3 4 1`', '`2 4 1 3`', '`3 1 2 4`', '`2 4 3 1`'],
      [(2, 3, 1, 4), (2, 1, 4, 3), (2, 3, 4, 1), (2, 4, 1, 3), (3, 1, 2, 4), (2, 4, 3, 1)], perms[9],
      'Primele 6 permutări încep cu 1; numără de acolo.',
      'Primele 6 încep cu 1. Apoi: a 7-a e 2134, a 8-a 2143, a 9-a 2314, a 10-a 2341.')

grila(46, 'Șiruri de biți fără doi de 1 alăturați', I2, 'medie', r'''
Câte șiruri de lungime 6, formate din cifrele 0 și 1, **nu** conțin doi de 1 pe poziții alăturate?''',
      ['$21$', '$13$', '$32$', '$34$', '$20$', '$64$'], [21, 13, 32, 34, 20, 64],
      sum(1 for s in product('01', repeat=6) if '11' not in ''.join(s)),
      'Fie $a_n$ numărul lor: un șir bun de lungime $n$ se termină cu 0 (orice șir bun de $n - 1$ înainte) sau cu 01.',
      '$a_n = a_{n-1} + a_{n-2}$, $a_1 = 2$, $a_2 = 3$: 2, 3, 5, 8, 13, 21.')

grila(47, 'Muchiile unei păduri', I2, 'ușoară', r'''
Un graf neorientat fără cicluri are 10 noduri și 3 componente conexe. Câte muchii are?''',
      ['$7$', '$9$', '$10$', '$8$', '$6$', '$13$'], [7, 9, 10, 8, 6, 13], 10 - 3,
      'Fiecare componentă e un arbore: un arbore cu $k$ noduri are $k - 1$ muchii.',
      'Însumând pe componente: $(k_1 - 1) + (k_2 - 1) + (k_3 - 1) = 10 - 3 = 7$.')

tata = [2, 0, 2, 1, 1, 3, 6, 6]  # nodes 1..8
leaves = [i + 1 for i in range(len(tata)) if (i + 1) not in tata]
grila(48, 'Frunzele unui arbore din vectorul de tați', I2, 'medie', r'''
Un arbore cu rădăcină, cu 8 noduri numerotate de la 1 la 8, este dat prin vectorul de tați $t = (2, 0, 2, 1, 1, 3, 6, 6)$ ($t_i$ este tatăl nodului $i$, iar $0$ marchează rădăcina). Câte frunze are arborele?''',
      ['$4$', '$3$', '$5$', '$2$', '$6$', '$1$'], [4, 3, 5, 2, 6, 1], len(leaves),
      'O frunză e un nod care nu apare în vectorul de tați.',
      'În $t$ apar 2, 1, 3, 6 (tați). Frunzele: 4, 5, 7, 8, adică 4.')


def bsearch_steps(nn):
    worst = 0
    for target in range(-1, nn + 1):
        lo, hi, c = 0, nn - 1, 0
        while lo <= hi:
            mid = (lo + hi) // 2
            c += 1
            if mid == target: break
            if mid < target: lo = mid + 1
            else: hi = mid - 1
        worst = max(worst, c)
    return worst


grila(49, 'Căutarea binară', I2, 'ușoară', r'''
Într-un vector **sortat** cu 1000 de elemente se caută o valoare prin căutare binară. Numărul maxim de elemente comparate cu valoarea căutată este:''',
      ['$10$', '$9$', '$11$', '$500$', '$1000$', '$32$'], [10, 9, 11, 500, 1000, 32], bsearch_steps(1000),
      'La fiecare pas intervalul se înjumătățește.', '$2^9 = 512 < 1000 < 1024 = 2^{10}$: cel mult 10 comparații.')

v = [5, 1, 4, 2, 8]
grila(50, 'Interschimbările sortării prin metoda bulelor', I2, 'medie', r'''
Câte interschimbări face sortarea prin metoda bulelor (bubble sort), crescător, pe vectorul $(5, 1, 4, 2, 8)$?''',
      ['$4$', '$3$', '$5$', '$6$', '$2$', '$10$'], [4, 3, 5, 6, 2, 10],
      sum(1 for i, j in combinations(range(len(v)), 2) if v[i] > v[j]),
      'Fiecare interschimbare a doi vecini scoate exact o inversiune.', 'Inversiunile: (5,1), (5,4), (5,2), (4,2): 4 interschimbări.')

grila(51, 'Submulțimi cu suma pară', I2, 'grea', r'''
Se generează toate submulțimile cu **3 elemente** ale mulțimii $\{1, 2, 3, 4, 5, 6\}$. Câte dintre ele au suma elementelor pară?''',
      ['$10$', '$20$', '$9$', '$12$', '$8$', '$11$'], [10, 20, 9, 12, 8, 11],
      sum(1 for c in combinations(range(1, 7), 3) if sum(c) % 2 == 0),
      'Suma a trei numere e pară dacă are 0 sau 2 numere impare.', 'Trei pare: $C_3^3 = 1$; două impare și un par: $C_3^2 \\cdot C_3^1 = 9$. Total 10.')

grila(52, 'Muchiile unui graf complet', I2, 'ușoară', r'''
Câte muchii trebuie **adăugate** unui arbore cu 7 noduri pentru a obține graful complet cu 7 noduri?''',
      ['$15$', '$21$', '$14$', '$6$', '$16$', '$42$'], [15, 21, 14, 6, 16, 42], 7 * 6 // 2 - 6,
      'Graful complet cu $n$ noduri are $\\frac{n(n-1)}{2}$ muchii.', '$K_7$ are 21 de muchii, arborele are 6: lipsesc 15.')

if __name__ == '__main__':
    write_course('admitere', CHAPTERS, P)
