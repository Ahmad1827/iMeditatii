"""MN — Metode Numerice: Octave functions, run on hidden tests in the page.

Topics from the MN labs, homework and exam (seria CD, 2022). Every expected
value is computed here with numpy, by the same algorithm the statement
describes; the app's Octave must agree on the reference solution.
"""
import os, sys
import numpy as np
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

C1 = '1. Sisteme liniare: metode directe'
C2 = '2. Sisteme liniare: metode iterative'
C3 = '3. Interpolare'
C4 = '4. Ecuații neliniare'
C5 = '5. Integrare și ecuații diferențiale'
C6 = '6. Valori proprii și ortogonalizare'
CHAPTERS = [C1, C2, C3, C4, C5, C6]
L = 'Laborator MN'
PROBLEMS = []


def oct(v):
    """A value as an Octave literal."""
    if isinstance(v, (int, float, np.floating, np.integer)):
        return repr(float(v)) if not float(v).is_integer() else str(int(v))
    a = np.array(v, dtype=float)
    if a.ndim == 1:
        a = a.reshape(-1, 1)
    return '[' + '; '.join(' '.join(repr(float(x)) for x in row) for row in a) + ']'


def task(id, title, ch, diff, statement, fn, sig, nout, tests, ref, hint, solution, forbid=(), source=L):
    starter = f'{sig}\n    % scrie codul aici\n\nend\n'
    spec = {'function': fn, 'signature': sig, 'nout': nout, 'tests': tests, 'forbid': list(forbid), 'starter': starter, 'reference': ref}
    PROBLEMS.append(problem(id, title, ch, diff, statement, 'octave', spec, hint, solution + f'\n\n```matlab\n{ref.strip()}\n```', source))


def T(args, expect=None, check=None, tol=1e-6):
    t = {'args': [a if isinstance(a, str) else oct(a) for a in args]}
    if expect is not None:
        t['expect'] = [e if isinstance(e, str) else oct(e) for e in expect]
    if check:
        t['check'] = check
    t['tol'] = tol
    return t


A3 = [[4, -2, 1], [-2, 4, -2], [1, -2, 4]]
SPD = [[[4, 12, -16], [12, 37, -43], [-16, -43, 98]], [[2, -1, 0], [-1, 2, -1], [0, -1, 2]], [[25, 15, -5], [15, 18, 0], [-5, 0, 11]], [[9]]]
DD = [[[10, -1, 2, 0], [-1, 11, -1, 3], [2, -1, 10, -1], [0, 3, -1, 8]], [[4, 1], [2, 5]], [[5, -1, 1], [2, 8, -1], [-1, 1, 4]]]
DDb = [[6, 25, -11, 15], [1, 2], [10, 11, 3]]

# ------------------------------------------------------------------ 1. direct methods
ups = [np.triu(np.array(m, float)) for m in [[[2, 1, -1], [0, 3, 2], [0, 0, 4]], [[1, 2, 3, 4], [0, 5, 6, 7], [0, 0, 8, 9], [0, 0, 0, 10]], [[7]], [[-1, 2], [0, 0.5]]]]
bs = [[1, 2, 8], [10, 18, 17, 10], [14], [3, 1]]
task(1, 'Substituția înapoi', C1, 'ușoară', '''
Scrie funcția `x = subst_inv(U, b)`, care rezolvă sistemul `U x = b`, unde `U` e **superior triunghiulară** (n × n, cu diagonala nenulă) și `b` e un vector coloană. `x` trebuie să fie tot coloană.

$$x_i = \\frac{1}{u_{ii}}\\left(b_i - \\sum_{j=i+1}^{n} u_{ij} x_j\\right), \\quad i = n, n-1, \\ldots, 1$$

Nu ai voie să folosești `\\` sau `inv`. Încearcă funcția în consola de sub editor.''',
    'subst_inv', 'function x = subst_inv(U, b)', 1,
    [T([U, b], [np.linalg.solve(U, b)]) for U, b in zip(ups, bs)],
    '''function x = subst_inv(U, b)
    n = length(b);
    x = zeros(n, 1);
    for i = n:-1:1
        x(i) = (b(i) - U(i, i+1:n) * x(i+1:n)) / U(i, i);
    end
end''', 'Pornește de la ultima ecuație, care are o singură necunoscută. `U(i, i+1:n) * x(i+1:n)` face suma dintr-o singură operație.',
    'Ultima ecuație dă direct `x(n)`; fiecare ecuație de deasupra are o singură necunoscută nouă. Complexitatea e O(n²).', forbid=['\\', 'inv'])

lows = [np.tril(np.array(m, float)) for m in [[[2, 0, 0], [1, 3, 0], [-1, 2, 4]], [[1, 0], [0.5, 2]], [[3, 0, 0, 0], [1, 1, 0, 0], [2, -1, 5, 0], [0, 4, 1, 2]]]]
lbs = [[2, 5, 11], [1, 3], [3, 2, 9, 7]]
task(2, 'Substituția înainte', C1, 'ușoară', '''
Scrie `x = subst_dir(L, b)`, care rezolvă `L x = b` pentru `L` **inferior triunghiulară**: de data asta pornești de la prima ecuație.''',
    'subst_dir', 'function x = subst_dir(L, b)', 1,
    [T([Lm, b], [np.linalg.solve(Lm, b)]) for Lm, b in zip(lows, lbs)],
    '''function x = subst_dir(L, b)
    n = length(b);
    x = zeros(n, 1);
    for i = 1:n
        x(i) = (b(i) - L(i, 1:i-1) * x(1:i-1)) / L(i, i);
    end
end''', 'Pentru i = 1, `1:i-1` e un interval gol, iar produsul cu un vector gol dă 0.',
    'Simetric cu substituția înapoi: `x(i)` depinde doar de `x(1)`, ..., `x(i-1)`.', forbid=['\\', 'inv'])

gA = [[[2, 1, -1], [-3, -1, 2], [-2, 1, 2]], [[0, 2, 1], [1, 1, 1], [2, 1, 0]], [[1e-12, 1], [1, 1]], [[4, -2, 1, 3], [3, 6, -4, 2], [2, 1, 8, -5], [1, 3, -2, 7]]]
gb = [[8, -11, -3], [3, 6, 1], [1, 2], [5, 8, 12, 9]]
task(3, 'Eliminarea Gauss cu pivotare parțială', C1, 'medie', '''
Scrie `x = gauss_pp(A, b)`, care rezolvă `A x = b` (A pătratică, nesingulară) prin **eliminare gaussiană cu pivotare parțială**: la pasul `k` alegi ca pivot elementul cu cea mai mare valoare absolută din coloana `k`, de pe liniile `k..n`, și schimbi liniile; apoi elimini sub pivot și rezolvi sistemul triunghiular rămas.

Unul dintre teste are un pivot `0`, altul un pivot de `1e-12`: fără pivotare dau rezultate greșite. Nu ai voie la `\\`, `inv` sau `lu`.''',
    'gauss_pp', 'function x = gauss_pp(A, b)', 1,
    [T([A, b], [np.linalg.solve(A, b)], tol=1e-8) for A, b in zip(gA, gb)],
    '''function x = gauss_pp(A, b)
    n = length(b);
    for k = 1:n-1
        [~, p] = max(abs(A(k:n, k)));
        p = p + k - 1;
        A([k p], :) = A([p k], :);
        b([k p]) = b([p k]);
        for i = k+1:n
            m = A(i, k) / A(k, k);
            A(i, k:n) = A(i, k:n) - m * A(k, k:n);
            b(i) = b(i) - m * b(k);
        end
    end
    x = zeros(n, 1);
    for i = n:-1:1
        x(i) = (b(i) - A(i, i+1:n) * x(i+1:n)) / A(i, i);
    end
end''', '`[~, p] = max(abs(A(k:n, k)))` dă poziția pivotului în subvector; adună `k - 1` ca să ai linia din A. `A([k p], :) = A([p k], :)` schimbă două linii.',
    'Pivotarea parțială ține multiplicatorii sub 1 în modul, deci erorile de rotunjire nu cresc. Fără ea, un pivot mic (1e-12) amplifică erorile cu 1e12.', forbid=['\\', 'inv', 'lu'],
    source='Tema MN · eliminare gaussiană')


def doolittle(A):
    A = np.array(A, float)
    n = len(A)
    Lm, U = np.eye(n), np.zeros((n, n))
    for i in range(n):
        for j in range(i, n):
            U[i, j] = A[i, j] - Lm[i, :i] @ U[:i, j]
        for j in range(i + 1, n):
            Lm[j, i] = (A[j, i] - Lm[j, :i] @ U[:i, i]) / U[i, i]
    return Lm, U


dA = [[[2, -1, -2], [-4, 6, 3], [-4, -2, 8]], [[1, 2], [3, 4]], [[4, 3, 2, 1], [3, 4, 3, 2], [2, 3, 4, 3], [1, 2, 3, 4]]]
task(4, 'Factorizarea LU (Doolittle)', C1, 'medie', '''
Scrie `[L, U] = doolittle(A)`, care descompune `A = L U` cu `L` **inferior triunghiulară cu 1 pe diagonală** și `U` superior triunghiulară (fără pivotare; testele au toți pivoții nenuli):

$$u_{ij} = a_{ij} - \\sum_{k<i} l_{ik} u_{kj} \\; (j \\ge i), \\qquad l_{ji} = \\frac{1}{u_{ii}}\\left(a_{ji} - \\sum_{k<i} l_{jk} u_{ki}\\right) \\; (j > i)$$

Fără `lu`.''',
    'doolittle', 'function [L, U] = doolittle(A)', 2,
    [T([A], list(doolittle(A)), check=['norm(o1*o2 - a1) < 1e-9', 'isequal(o2, triu(o2))', 'all(diag(o1) == 1)']) for A in dA],
    '''function [L, U] = doolittle(A)
    n = rows(A);
    L = eye(n);
    U = zeros(n);
    for i = 1:n
        for j = i:n
            U(i, j) = A(i, j) - L(i, 1:i-1) * U(1:i-1, j);
        end
        for j = i+1:n
            L(j, i) = (A(j, i) - L(j, 1:i-1) * U(1:i-1, i)) / U(i, i);
        end
    end
end''', 'Calculează alternativ: linia `i` din U, apoi coloana `i` din L.',
    'O dată ce ai L și U, orice sistem `A x = b` cere doar două substituții (înainte, apoi înapoi): O(n²) în loc de O(n³).', forbid=['lu', '\\', 'inv'])

task(5, 'Factorizarea Cholesky', C1, 'medie', '''
Pentru o matrice **simetrică și pozitiv definită**, scrie `L = cholesky(A)` cu `L` inferior triunghiulară, cu diagonala pozitivă, astfel încât `A = L L'`:

$$l_{jj} = \\sqrt{a_{jj} - \\sum_{k<j} l_{jk}^2}, \\qquad l_{ij} = \\frac{1}{l_{jj}}\\left(a_{ij} - \\sum_{k<j} l_{ik} l_{jk}\\right) \\; (i > j)$$

Fără `chol`.''',
    'cholesky', 'function L = cholesky(A)', 1,
    [T([A], [np.linalg.cholesky(np.array(A, float))], check=["norm(o1*o1' - a1) < 1e-9", 'isequal(o1, tril(o1))']) for A in SPD],
    '''function L = cholesky(A)
    n = rows(A);
    L = zeros(n);
    for j = 1:n
        L(j, j) = sqrt(A(j, j) - L(j, 1:j-1) * L(j, 1:j-1)');
        for i = j+1:n
            L(i, j) = (A(i, j) - L(i, 1:j-1) * L(j, 1:j-1)') / L(j, j);
        end
    end
end''', 'Mergi pe coloane: întâi elementul de pe diagonală, apoi cele de sub el.',
    'Cholesky face jumătate din operațiile lui LU și nu are nevoie de pivotare pentru matrice pozitiv definite.', forbid=['chol', '\\', 'inv'])

# ------------------------------------------------------------------ 2. iterative methods
def jacobi(A, b, x0, tol, maxit, seidel=False):
    A, b, x = np.array(A, float), np.array(b, float), np.array(x0, float)
    n = len(b)
    for k in range(1, maxit + 1):
        xn = x.copy()
        for i in range(n):
            src = xn if seidel else x
            s = sum(A[i, j] * src[j] for j in range(n) if j != i)
            xn[i] = (b[i] - s) / A[i, i]
        if np.max(np.abs(xn - x)) < tol:
            return xn, k
        x = xn
    return x, maxit


for idx, (name, seidel) in enumerate([('jacobi', False), ('gauss_seidel', True)]):
    tests = []
    for A, b in zip(DD, DDb):
        x0 = [0] * len(b)
        for tol in [1e-8]:
            x, k = jacobi(A, b, x0, tol, 500, seidel)
            tests.append(T([A, b, x0, '1e-8', '500'], [x, k], tol=1e-6))
    title = 'Metoda Jacobi' if not seidel else 'Metoda Gauss-Seidel'
    body = ('Fiecare componentă nouă se calculează **doar din iterația veche** `x`:' if not seidel else
            'Spre deosebire de Jacobi, folosești **imediat** componentele deja calculate în iterația curentă:')
    formula = ('x^{(k+1)}_i = \\frac{1}{a_{ii}}\\left(b_i - \\sum_{j \\ne i} a_{ij} x^{(k)}_j\\right)' if not seidel else
               'x^{(k+1)}_i = \\frac{1}{a_{ii}}\\left(b_i - \\sum_{j<i} a_{ij} x^{(k+1)}_j - \\sum_{j>i} a_{ij} x^{(k)}_j\\right)')
    ref = f'''function [x, k] = {name}(A, b, x0, tol, maxit)
    n = length(b);
    x = x0;
    for k = 1:maxit
        xn = x;
        for i = 1:n
            s = 0;
            for j = 1:n
                if j ~= i
                    s = s + A(i, j) * {'xn(j)' if seidel else 'x(j)'};
                end
            end
            xn(i) = (b(i) - s) / A(i, i);
        end
        if norm(xn - x, Inf) < tol
            x = xn;
            return;
        end
        x = xn;
    end
end'''
    task(6 + idx, title, C2, 'medie', f'''
Scrie `[x, k] = {name}(A, b, x0, tol, maxit)`, care rezolvă `A x = b` iterativ, pornind din `x0`. {body}

$${formula}$$

**Oprirea**: după fiecare iterație `k` (numărate de la 1), dacă `norm(x_nou - x_vechi, Inf) < tol`, întorci `x_nou` și `k`. Dacă ajungi la `maxit` iterații fără să te oprești, întorci ultima iterație și `k = maxit`. Testele verifică și `k`, deci respectă exact regula.''',
        name, f'function [x, k] = {name}(A, b, x0, tol, maxit)', 2, tests, ref,
        'Ține două vectori: iterația veche și cea nouă. `norm(v, Inf)` e cel mai mare element în modul.',
        ('Matricele din teste sunt diagonal dominante, deci metoda converge.' if not seidel else
         'Gauss-Seidel folosește informația nouă mai devreme, deci de obicei are nevoie de mai puține iterații decât Jacobi (compară `k` pe aceleași teste).'),
        forbid=['\\', 'inv'], source='Tema MN · metode iterative')

# ------------------------------------------------------------------ 3. interpolation
def lagrange(xs, ys, x):
    xs, ys = np.array(xs, float), np.array(ys, float)
    out = []
    for t in np.atleast_1d(x):
        s = 0.0
        for i in range(len(xs)):
            li = 1.0
            for j in range(len(xs)):
                if j != i:
                    li *= (t - xs[j]) / (xs[i] - xs[j])
            s += ys[i] * li
        out.append(s)
    return out


lx = [([0, 1, 2], [1, 3, 7], [0.5, 1.5, 3]), ([-1, 0, 1, 2], [2, 1, 0, 5], [0, 0.25, -0.5]), ([1, 2, 4, 5, 7], [0, 1, 3, 2, 8], [3, 6])]
task(8, 'Interpolarea Lagrange', C3, 'medie', '''
Scrie `y = lagrange(xs, ys, x)`: valorile polinomului de interpolare Lagrange prin punctele `(xs(i), ys(i))`, calculate în fiecare punct al vectorului **linie** `x`. `y` are aceeași formă ca `x`.

$$P(t) = \\sum_{i=1}^{n} y_i \\prod_{j \\ne i} \\frac{t - x_j}{x_i - x_j}$$''',
    'lagrange', 'function y = lagrange(xs, ys, x)', 1,
    [T([np.array(a).reshape(1, -1), np.array(b).reshape(1, -1), np.array(c).reshape(1, -1)], [np.array(lagrange(a, b, c)).reshape(1, -1)]) for a, b, c in lx],
    '''function y = lagrange(xs, ys, x)
    n = length(xs);
    y = zeros(size(x));
    for i = 1:n
        L = ones(size(x));
        for j = 1:n
            if j ~= i
                L = L .* (x - xs(j)) / (xs(i) - xs(j));
            end
        end
        y = y + ys(i) * L;
    end
end''', 'Calculează polinoamele de bază `L_i` direct pe tot vectorul `x`, cu operații element cu element (`.*`).',
    'Fiecare `L_i` e 1 în `xs(i)` și 0 în celelalte noduri, deci suma trece prin toate punctele.')


def divdiff(xs, ys):
    xs = np.array(xs, float)
    c = np.array(ys, float)
    n = len(xs)
    for j in range(1, n):
        for i in range(n - 1, j - 1, -1):
            c[i] = (c[i] - c[i - 1]) / (xs[i] - xs[i - j])
    return c


task(9, 'Diferențele divizate ale lui Newton', C3, 'medie', '''
Scrie `c = dif_div(xs, ys)`, care întoarce (ca vector **linie**) coeficienții formei Newton a polinomului de interpolare:

$$P(t) = c_1 + c_2 (t - x_1) + c_3 (t - x_1)(t - x_2) + \\ldots$$

adică `c(k) = f[x_1, ..., x_k]`, diferențele divizate de pe diagonala tabelului.''',
    'dif_div', 'function c = dif_div(xs, ys)', 1,
    [T([np.array(a).reshape(1, -1), np.array(b).reshape(1, -1)], [divdiff(a, b).reshape(1, -1)]) for a, b, _ in lx],
    '''function c = dif_div(xs, ys)
    n = length(xs);
    c = ys;
    for j = 2:n
        for i = n:-1:j
            c(i) = (c(i) - c(i-1)) / (xs(i) - xs(i-j+1));
        end
    end
end''', 'Poți calcula tabelul pe loc, într-un singur vector: la pasul `j` actualizezi de la coadă spre `j`, ca să nu strici valorile de care mai ai nevoie.',
    'Avantajul formei Newton: un punct nou adaugă doar un termen, fără să recalculezi tot.')

# ------------------------------------------------------------------ 4. nonlinear equations
def newton(f, df, x0, tol, maxit):
    x = x0
    for k in range(1, maxit + 1):
        xn = x - f(x) / df(x)
        if abs(xn - x) < tol:
            return xn, k
        x = xn
    return x, maxit


nt = [('@(x) x.^3 - 2*x - 5', '@(x) 3*x.^2 - 2', lambda x: x ** 3 - 2 * x - 5, lambda x: 3 * x ** 2 - 2, 2),
      ('@(x) cos(x) - x', '@(x) -sin(x) - 1', lambda x: np.cos(x) - x, lambda x: -np.sin(x) - 1, 1),
      ('@(x) x.^2 - 2', '@(x) 2*x', lambda x: x * x - 2, lambda x: 2 * x, 1),
      ('@(x) exp(x) - 3', '@(x) exp(x)', lambda x: np.exp(x) - 3, lambda x: np.exp(x), 0)]
task(10, 'Metoda lui Newton', C4, 'medie', '''
Scrie `[r, k] = newton(f, df, x0, tol, maxit)`: rădăcina lui `f` prin metoda tangentei, pornind din `x0`. `f` și `df` (derivata) sunt funcții, de exemplu `@(x) x.^2 - 2`; le apelezi ca `f(x)`.

$$x_{k+1} = x_k - \\frac{f(x_k)}{f^{\\prime}(x_k)}$$

**Oprirea**: după iterația `k` (de la 1), dacă `abs(x_nou - x_vechi) < tol` întorci `x_nou` și `k`; după `maxit` iterații întorci ce ai.''',
    'newton', 'function [r, k] = newton(f, df, x0, tol, maxit)', 2,
    [T([fs, dfs, x0, '1e-12', '100'], list(newton(f, df, float(x0), 1e-12, 100)), tol=1e-9) for fs, dfs, f, df, x0 in nt],
    '''function [r, k] = newton(f, df, x0, tol, maxit)
    x = x0;
    for k = 1:maxit
        r = x - f(x) / df(x);
        if abs(r - x) < tol
            return;
        end
        x = r;
    end
end''', 'O funcție primită ca argument se apelează ca oricare alta: `f(x)`.',
    'Aproape de rădăcină, Newton converge pătratic: numărul de cifre corecte se dublează la fiecare pas (vezi cât de mic e `k`).', source='Laborator MN · ecuații neliniare')


def bisect(f, a, b, tol):
    while (b - a) / 2 > tol:
        c = (a + b) / 2
        if f(a) * f(c) <= 0:
            b = c
        else:
            a = c
    return (a + b) / 2


bt = [('@(x) x.^3 - x - 2', lambda x: x ** 3 - x - 2, 1, 2), ('@(x) cos(x) - x', lambda x: np.cos(x) - x, 0, 1), ('@(x) x.^2 - 5', lambda x: x * x - 5, 0, 5)]
task(11, 'Metoda bisecției', C4, 'ușoară', '''
Scrie `r = bisectie(f, a, b, tol)`, unde `f(a)` și `f(b)` au semne opuse. Cât timp `(b - a) / 2 > tol`: iei mijlocul `c`; dacă `f(a) * f(c) <= 0` rădăcina e în `[a, c]` (deci `b = c`), altfel în `[c, b]` (`a = c`). La sfârșit întorci mijlocul intervalului rămas.''',
    'bisectie', 'function r = bisectie(f, a, b, tol)', 1,
    [T([fs, a, b, '1e-10'], [bisect(f, float(a), float(b), 1e-10)], tol=1e-12) for fs, f, a, b in bt],
    '''function r = bisectie(f, a, b, tol)
    while (b - a) / 2 > tol
        c = (a + b) / 2;
        if f(a) * f(c) <= 0
            b = c;
        else
            a = c;
        end
    end
    r = (a + b) / 2;
end''', 'Un `while` cu condiția din enunț; nu uita că la sfârșit întorci mijlocul, nu `a` sau `b`.',
    'Fiecare pas înjumătățește intervalul: pentru o precizie `tol` trebuie aproximativ log₂((b − a) / tol) pași.')

# ------------------------------------------------------------------ 5. integration and ODEs
def trapez(f, a, b, n):
    h = (b - a) / n
    x = a + h * np.arange(n + 1)
    y = f(x)
    return h * (y[0] / 2 + y[1:-1].sum() + y[-1] / 2)


def simpson(f, a, b, n):
    h = (b - a) / n
    x = a + h * np.arange(n + 1)
    y = f(x)
    return h / 3 * (y[0] + 4 * y[1:-1:2].sum() + 2 * y[2:-1:2].sum() + y[-1])


it = [('@(x) x.^2', lambda x: x ** 2, 0, 1), ('@(x) sin(x)', np.sin, 0, np.pi), ('@(x) exp(-x.^2)', lambda x: np.exp(-x ** 2), 0, 2), ('@(x) 1 ./ (1 + x.^2)', lambda x: 1 / (1 + x ** 2), 0, 1)]
task(12, 'Formula trapezelor', C5, 'ușoară', '''
Scrie `I = trapez(f, a, b, n)`: aproximarea integralei lui `f` pe `[a, b]` cu formula **trapezelor compusă**, pe `n` subintervale egale de lungime `h = (b - a) / n`:

$$I \\approx h\\left(\\frac{f(x_0)}{2} + f(x_1) + \\ldots + f(x_{n-1}) + \\frac{f(x_n)}{2}\\right)$$

`f` acceptă vectori (scrisă cu `.^`, `./`).''',
    'trapez', 'function I = trapez(f, a, b, n)', 1,
    [T([fs, oct(a), oct(b), str(n)], [trapez(f, a, b, n)], tol=1e-10) for (fs, f, a, b) in it for n in [10]] + [T([it[0][0], '0', '1', '1'], [trapez(it[0][1], 0, 1, 1)])],
    '''function I = trapez(f, a, b, n)
    h = (b - a) / n;
    x = a + (0:n) * h;
    y = f(x);
    I = h * (y(1) / 2 + sum(y(2:n)) + y(n+1) / 2);
end''', '`x = a + (0:n) * h` dă toate nodurile deodată.',
    'Eroarea scade ca h²: dublând n, eroarea scade de aproximativ 4 ori.')

task(13, 'Formula lui Simpson', C5, 'medie', '''
Scrie `I = simpson(f, a, b, n)` cu formula lui **Simpson compusă**, `n` par:

$$I \\approx \\frac{h}{3}\\left(f(x_0) + 4f(x_1) + 2f(x_2) + 4f(x_3) + \\ldots + 4f(x_{n-1}) + f(x_n)\\right)$$''',
    'simpson', 'function I = simpson(f, a, b, n)', 1,
    [T([fs, oct(a), oct(b), '10'], [simpson(f, a, b, 10)], tol=1e-10) for (fs, f, a, b) in it] + [T(['@(x) x.^3', '0', '2', '2'], [4.0])],
    '''function I = simpson(f, a, b, n)
    h = (b - a) / n;
    x = a + (0:n) * h;
    y = f(x);
    I = h / 3 * (y(1) + 4 * sum(y(2:2:n)) + 2 * sum(y(3:2:n-1)) + y(n+1));
end''', 'În Octave indicii pornesc de la 1: nodurile impare ale formulei (x₁, x₃, ...) sunt `y(2:2:n)`.',
    'Simpson e exactă pentru polinoame de grad cel mult 3 (testul cu x³ dă exact 4), iar eroarea scade ca h⁴.')


def euler(f, t0, y0, h, n):
    ys, t, y = [y0], t0, y0
    for _ in range(n):
        y = y + h * f(t, y)
        t = t + h
        ys.append(y)
    return ys


et = [('@(t, y) y', lambda t, y: y, 0, 1, 0.1, 10), ('@(t, y) -2 * t * y', lambda t, y: -2 * t * y, 0, 1, 0.05, 20), ('@(t, y) t - y', lambda t, y: t - y, 0, 2, 0.5, 4)]
task(14, 'Metoda lui Euler', C5, 'ușoară', '''
Scrie `y = euler(f, t0, y0, h, n)` pentru problema Cauchy `y' = f(t, y)`, `y(t0) = y0`: faci `n` pași de lungime `h` și întorci **vectorul linie** cu cele `n + 1` valori `y_0, y_1, ..., y_n`.

$$y_{k+1} = y_k + h\\, f(t_k, y_k), \\qquad t_{k+1} = t_k + h$$''',
    'euler', 'function y = euler(f, t0, y0, h, n)', 1,
    [T([fs, str(t0), str(y0), str(h), str(n)], [np.array(euler(f, t0, y0, h, n)).reshape(1, -1)], tol=1e-10) for fs, f, t0, y0, h, n in et],
    '''function y = euler(f, t0, y0, h, n)
    y = zeros(1, n + 1);
    y(1) = y0;
    t = t0;
    for k = 1:n
        y(k+1) = y(k) + h * f(t, y(k));
        t = t + h;
    end
end''', 'Indicele `k` din vector e cu 1 mai mare decât cel din formulă.',
    'Primul test aproximează e¹ ≈ 2.71828 cu 2.59374: Euler are eroare O(h).')

# ------------------------------------------------------------------ 6. eigenvalues and orthogonalization
pw = [[[2, 1], [1, 3]], [[4, 1, 0], [1, 3, 1], [0, 1, 2]], A3, [[6, 2, 1], [2, 3, 1], [1, 1, 1]]]
task(15, 'Metoda puterii', C6, 'medie', '''
Scrie `[lambda, v] = putere(A, x0, tol, maxit)`, care găsește valoarea proprie de **modul maxim** a lui `A` și un vector propriu, prin metoda puterii: repeți `y = A x`, `x = y / norm(y)`, iar estimarea valorii proprii e `x' A x` (câtul Rayleigh). Te oprești când estimarea se schimbă cu mai puțin de `tol` sau după `maxit` pași.

Testele verifică valoarea proprie și că `A v ≈ λ v` (orice normare a lui `v` e acceptată).''',
    'putere', 'function [lambda, v] = putere(A, x0, tol, maxit)', 2,
    [T([A, np.ones(len(A)), '1e-12', '1000'], [max(np.linalg.eigvalsh(np.array(A, float)), key=abs)], check=['norm(a1*o2 - o1*o2) < 1e-5 * norm(o2)', 'norm(o2) > 0'], tol=1e-7) for A in pw],
    '''function [lambda, v] = putere(A, x0, tol, maxit)
    v = x0 / norm(x0);
    lambda = v' * A * v;
    for k = 1:maxit
        y = A * v;
        v = y / norm(y);
        nou = v' * A * v;
        if abs(nou - lambda) < tol
            lambda = nou;
            return;
        end
        lambda = nou;
    end
end''', 'Normează vectorul la fiecare pas, altfel crește (sau scade) exponențial.',
    'Viteza depinde de raportul |λ₂ / λ₁|: cu cât e mai aproape de 1, cu atât converge mai încet.', forbid=['eig'], source='Laborator MN · valori proprii')

gs = [[[1, 1, 0], [1, 0, 1], [0, 1, 1]], [[3, 1], [4, 2]], [[1, 2, 0], [0, 1, 1], [1, 0, 1], [1, 1, 1]]]
task(16, 'Gram-Schmidt: factorizarea QR', C6, 'grea', '''
Scrie `[Q, R] = gram_schmidt(A)` pentru o matrice `A` (m × n, m ≥ n) cu coloanele liniar independente: `Q` (m × n) are coloanele **ortonormate**, `R` (n × n) e superior triunghiulară cu diagonala pozitivă, iar `A = Q R`.

Coloana `j` din Q se obține din coloana `j` din A scăzând proiecțiile pe coloanele deja găsite și normând rezultatul.''',
    'gram_schmidt', 'function [Q, R] = gram_schmidt(A)', 2,
    [T([A], None, check=["norm(o1*o2 - a1) < 1e-9", "norm(o1'*o1 - eye(columns(a1))) < 1e-9", 'isequal(o2, triu(o2))', 'all(diag(o2) > 0)', 'isequal(size(o1), size(a1))']) for A in gs],
    '''function [Q, R] = gram_schmidt(A)
    [m, n] = size(A);
    Q = zeros(m, n);
    R = zeros(n);
    for j = 1:n
        v = A(:, j);
        for i = 1:j-1
            R(i, j) = Q(:, i)' * A(:, j);
            v = v - R(i, j) * Q(:, i);
        end
        R(j, j) = norm(v);
        Q(:, j) = v / R(j, j);
    end
end''', '`R(i, j) = Q(:, i)\' * A(:, j)` e proiecția; după ce le-ai scăzut pe toate, `norm(v)` e `R(j, j)`.',
    'Așa se rezolvă și problemele de cele mai mici pătrate: `A x ≈ b` devine `R x = Q\' b`.', forbid=['qr'])

write_course('mn', CHAPTERS, PROBLEMS)
