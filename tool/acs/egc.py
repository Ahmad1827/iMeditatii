"""EGC — Elemente de Grafică pe Calculator: transformations composed on the drawing, rasters lit by hand.

Topics from the EGC lectures and the course tests (seria CA/CD): 2D
transformations in homogeneous coordinates (column vectors, so a sequence is
a product written right to left), the window-to-viewport transformation,
Bresenham's segment and the midpoint circle, and the theory asked in the
"Transformări 2D și 3D" test and the exam.

The target matrix of each task is the product of its reference list, computed
here; the app accepts any list with the same matrix.
"""
import math, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, write_course

C1 = '1. Transformări elementare'
C2 = '2. Transformări compuse'
C3 = '3. Fereastră și poartă de vizualizare'
C4 = '4. Rasterizare'
C5 = '5. Teorie: transformări, proiecții, iluminare'
CHAPTERS = [C1, C2, C3, C4, C5]
TEST = 'Test EGC · Transformări 2D și 3D'
P = []


def mat(op):
    k, a, b = op[0], op[1], (op[2] if len(op) > 2 else 0)
    if k == 'T':
        return [1, 0, a, 0, 1, b, 0, 0, 1]
    if k == 'S':
        return [a, 0, 0, 0, b, 0, 0, 0, 1]
    if k == 'F':
        return [1, a, 0, b, 1, 0, 0, 0, 1]
    r = math.radians(a)
    return [math.cos(r), -math.sin(r), 0, math.sin(r), math.cos(r), 0, 0, 0, 1]


def mul(x, y):
    return [sum(x[i * 3 + k] * y[k * 3 + j] for k in range(3)) for i in range(3) for j in range(3)]


def compose(ops):
    m = [1, 0, 0, 0, 1, 0, 0, 0, 1]
    for op in ops:
        m = mul(mat(op), m)
    return [round(v, 9) + 0.0 for v in m]


L = [[0, 0], [2, 0], [2, 1], [1, 1], [1, 3], [0, 3]]            # an L: not symmetric, so a mirror shows
FLAG = [[1, 1], [3, 1], [3, 2], [2, 2], [2, 4], [1, 4]]
TRI = [[1, 0], [4, 0], [1, 2]]


def tr(id, title, ch, diff, statement, shape, ref, hint, solution='', max_ops=None, allowed=None, source='', start=None):
    spec = {'shape': shape, 'target': compose(ref), 'reference': [{'op': o[0], 'a': o[1], 'b': (o[2] if len(o) > 2 else 0)} for o in ref]}
    if max_ops:
        assert len(ref) <= max_ops
        spec['maxOps'] = max_ops
    if allowed:
        assert all(o[0] in allowed for o in ref)
        spec['allowed'] = list(allowed)
    names = {'T': 'T', 'R': 'R', 'S': 'S', 'F': 'F'}
    prod = ' · '.join((f'R({o[1]}°)' if o[0] == 'R' else f'{names[o[0]]}({o[1]}, {o[2]})') for o in reversed(ref))
    P.append(problem(id, title, ch, diff, statement, 'transform', spec, hint, solution or f'O rezolvare: `M = {prod}` (se aplică de la dreapta la stânga).', source))


tr(1, 'O translație', C1, 'ușoară', 'Mută forma cu 3 unități la dreapta și 2 în sus.', L, [('T', 3, 2)],
   'O singură translație `T(tx, ty)`.', max_ops=1)
tr(2, 'Scalare față de origine', C1, 'ușoară', 'Dublează forma față de origine, pe ambele axe.', TRI, [('S', 2, 2)],
   '`S(sx, sy)` înmulțește coordonatele: punctele se și depărtează de origine.', max_ops=1)
tr(3, 'Rotație față de origine', C1, 'ușoară', 'Rotește forma cu 90° în sens trigonometric în jurul originii.', L, [('R', 90)],
   'Sensul trigonometric (invers acelor de ceas) e cel pozitiv.', max_ops=1)
tr(4, 'Oglindire față de axa OY', C1, 'ușoară', 'Oglindește forma față de axa OY, folosind o singură scalare.', L, [('S', -1, 1)],
   'Oglindirea față de o axă e o scalare cu `-1` pe cealaltă axă.', max_ops=1, allowed=('S',), source=TEST)
tr(5, 'Forfecare pe x', C1, 'ușoară', 'Forfecă forma de-a lungul axei OX cu factorul 1: `x\' = x + y`, `y\' = y`.', L, [('F', 1, 0)],
   '`F(fx, fy)`: `x\' = x + fx·y`, `y\' = y + fy·x`.', max_ops=1)
tr(6, 'Scalare neuniformă', C1, 'ușoară', 'Întinde forma de 3 ori pe orizontală și micșoreaz-o la jumătate pe verticală.', FLAG, [('S', 3, 0.5)],
   'Factorii pot fi diferiți pe cele două axe și pot fi subunitari.', max_ops=1)

tr(7, 'Rotație în jurul unui punct', C2, 'medie', 'Rotește forma cu 90° în sens trigonometric în jurul punctului `(2, 1)`.', FLAG,
   [('T', -2, -1), ('R', 90), ('T', 2, 1)],
   'Adu punctul în origine, rotește, apoi du-l înapoi.', '`M = T(2, 1) · R(90°) · T(-2, -1)`: translația care duce `(2, 1)` în origine se aplică prima.', max_ops=3)
tr(8, 'Scalare față de un punct', C2, 'medie', 'Dublează forma față de colțul ei din `(1, 1)`: acel colț rămâne pe loc.', FLAG,
   [('T', -1, -1), ('S', 2, 2), ('T', 1, 1)],
   'La fel ca rotația în jurul unui punct: translație, scalare față de origine, translația inversă.', max_ops=3)
tr(9, 'Rotație cu 180° în jurul centrului', C2, 'medie', 'Rotește triunghiul cu 180° în jurul punctului `(2.5, 1)`.', TRI,
   [('T', -2.5, -1), ('R', 180), ('T', 2.5, 1)],
   'Rotația cu 180° e aceeași cu `S(-1, -1)`.', max_ops=3)
tr(10, 'Oglindire față de dreapta x = 3', C2, 'medie', 'Oglindește forma față de dreapta verticală `x = 3`.', L,
    [('T', -3, 0), ('S', -1, 1), ('T', 3, 0)],
    'Mută dreapta peste axa OY, oglindește, mută înapoi.', max_ops=3)
tr(11, 'Oglindire față de prima bisectoare', C2, 'medie', 'Oglindește forma față de dreapta `y = x`, folosind doar rotații și scalări.', L,
    [('R', -45), ('S', 1, -1), ('R', 45)],
    'Rotește planul astfel încât dreapta să ajungă peste axa OX, oglindește față de OX, rotește înapoi.',
    '`M = R(45°) · S(1, -1) · R(-45°)`. Rezultatul schimbă între ele coordonatele: `(x, y) → (y, x)`.', max_ops=3, allowed=('R', 'S'))
tr(12, 'Oglindire față de o dreaptă oarecare', C2, 'grea', 'Oglindește forma față de dreapta `y = x + 1`.', L,
    [('T', 0, -1), ('R', -45), ('S', 1, -1), ('R', 45), ('T', 0, 1)],
    'Dreapta trece prin `(0, 1)` și face 45° cu OX. Cinci pași: translație, rotație, oglindire față de OX și inversele lor.',
    '`M = T(0, 1) · R(45°) · S(1, -1) · R(-45°) · T(0, -1)`.', max_ops=5, source=TEST)
tr(13, 'Forfecare față de un punct', C2, 'grea', 'Forfecă forma pe orizontală cu factorul 1, astfel încât linia ei de jos (`y = 1`) să rămână pe loc.', FLAG,
    [('T', 0, -1), ('F', 1, 0), ('T', 0, 1)],
    'Forfecarea față de origine lasă pe loc axa OX. Adu linia `y = 1` peste OX.', max_ops=3, source=TEST)
tr(14, 'Ordinea contează', C2, 'medie', 'Ținta s-a obținut din două transformări: o scalare cu 2 și o translație cu `(2, 0)`. Găsește ordinea bună.', TRI,
    [('S', 2, 2), ('T', 2, 0)],
    'Dacă translatezi întâi, scalarea dublează și deplasarea.', '`M = T(2, 0) · S(2, 2)`: întâi scalarea. În ordinea inversă, forma ar ajunge cu 4 unități mai la dreapta, nu cu 2.', max_ops=2)
tr(15, 'Transformarea inversă', C2, 'medie', 'Forma dată a fost obținută rotind originalul cu 90° în jurul originii și apoi translatându-l cu `(4, 1)`. Adu-o înapoi unde era.',
    [[4, 1], [4, 3], [3, 3], [3, 2], [1, 2], [1, 1]], [('T', -4, -1), ('R', -90)],
    'Inversa unui produs: inversele, în ordine inversă.', '`(T · R)⁻¹ = R⁻¹ · T⁻¹`: întâi `T(-4, -1)`, apoi `R(-90°)`.', max_ops=2)
tr(16, 'Rotație cu 45° în jurul unui colț', C2, 'medie', 'Rotește forma cu 45° în sens orar în jurul colțului ei din `(1, 1)`.', FLAG,
    [('T', -1, -1), ('R', -45), ('T', 1, 1)],
    'Sensul orar înseamnă unghi negativ.', max_ops=3)

tr(17, 'Din fereastră în poartă', C3, 'medie',
    'Fereastra din spațiul utilizator este `[0, 4] × [0, 2]`, iar poarta de vizualizare este `[2, 10] × [1, 5]`. Forma dată e chiar fereastra. Scrie transformarea fereastră-poartă.',
    [[0, 0], [4, 0], [4, 2], [0, 2]], [('S', 2, 2), ('T', 2, 1)],
    '`sx = (xvmax - xvmin) / (xfmax - xfmin)`, la fel pe y. Colțul ferestrei e deja în origine.',
    '`sx = 8 / 4 = 2`, `sy = 4 / 2 = 2`; apoi translația în colțul porții: `M = T(2, 1) · S(2, 2)`.', max_ops=3)
tr(18, 'Fereastră care nu pornește din origine', C3, 'grea',
    'Fereastra este `[1, 4] × [1, 3]`, poarta este `[0, 6] × [0, 2]`. Forma dată e fereastra. Scrie transformarea fereastră-poartă.',
    [[1, 1], [4, 1], [4, 3], [1, 3]], [('T', -1, -1), ('S', 2, 1)],
    'Trei pași în general: colțul ferestrei în origine, scalare, translație în colțul porții. Aici poarta începe chiar în origine.',
    '`sx = 6 / 3 = 2`, `sy = 2 / 2 = 1`: `M = S(2, 1) · T(-1, -1)`. Scalarea e neuniformă, deci imaginea se deformează.', max_ops=3)
tr(19, 'Poartă cu axa y în jos', C3, 'grea',
    'Fereastra este `[0, 4] × [0, 3]`. Pe ecran axa y crește în jos, așa că poarta `[0, 4] × [0, 3]` trebuie să arate forma răsturnată pe verticală: punctul `(0, 0)` ajunge în `(0, 3)`, iar `(0, 3)` în `(0, 0)`.',
    [[0, 0], [4, 0], [4, 1], [1, 1], [1, 3], [0, 3]], [('S', 1, -1), ('T', 0, 3)],
    'O oglindire față de OX, apoi o translație pe verticală cu înălțimea porții.', max_ops=2)

# ---------------------------------------------------------------- rasterizare
def bresenham(x0, y0, x1, y1):
    pts = []
    dx, dy = abs(x1 - x0), -abs(y1 - y0)
    sx, sy = (1 if x0 < x1 else -1), (1 if y0 < y1 else -1)
    err = dx + dy
    while True:
        pts.append([x0, y0])
        if (x0, y0) == (x1, y1):
            return pts
        e2 = 2 * err
        if e2 >= dy:
            err += dy; x0 += sx
        if e2 <= dx:
            err += dx; y0 += sy


def midpoint_circle(cx, cy, r):
    pts = set()
    x, y, d = 0, r, 1 - r
    while x <= y:
        for a, b in ((x, y), (y, x), (-x, y), (-y, x), (x, -y), (y, -x), (-x, -y), (-y, -x)):
            pts.add((cx + a, cy + b))
        if d < 0:
            d += 2 * x + 3
        else:
            d += 2 * (x - y) + 5; y -= 1
        x += 1
    return sorted([list(p) for p in pts])


def line(id, title, diff, a, b, w, h, hint, extra=''):
    pts = bresenham(*a, *b)
    assert all(0 <= x < w and 0 <= y < h for x, y in pts)
    st = f'Aprinde pixelii pe care îi alege algoritmul Bresenham pentru segmentul de la `({a[0]}, {a[1]})` la `({b[0]}, {b[1]})`. Capetele sunt deja aprinse.{extra}'
    sol = 'Pixelii, în ordine: ' + ', '.join(f'`({x}, {y})`' for x, y in pts) + '.'
    P.append(problem(id, title, C4, diff, st, 'raster', {'w': w, 'h': h, 'pixels': pts, 'given': [list(a), list(b)], 'line': [*a, *b]}, hint, sol))


line(20, 'Segment cu pantă mică', 'ușoară', (0, 0), (7, 3), 9, 5,
     'Panta e sub 1: pe fiecare coloană se aprinde exact un pixel, cel mai apropiat de dreapta ideală.')
line(21, 'Segment cu pantă mare', 'medie', (1, 0), (4, 8), 6, 9,
     'Panta e peste 1: rolurile lui x și y se schimbă, câte un pixel pe fiecare linie.')
line(22, 'Segment care coboară', 'medie', (0, 5), (9, 1), 10, 7,
     'La fel ca la pantă mică, dar y scade. Tot câte un pixel pe coloană.')
line(23, 'De la dreapta la stânga', 'medie', (8, 1), (1, 4), 10, 6,
     'Sensul de parcurgere nu schimbă ce pixeli sunt cei mai apropiați de dreaptă.')
line(24, 'Diagonală aproape', 'ușoară', (0, 0), (6, 5), 8, 7,
     'Aproape diagonală: y crește la aproape fiecare pas, o singură dată rămâne pe loc.')

_c = midpoint_circle(5, 5, 4)
P.append(problem(25, 'Cerc cu algoritmul punctului de mijloc', C4, 'grea',
                 'Aprinde pixelii pe care algoritmul punctului de mijloc îi alege pentru cercul cu centrul în `(5, 5)` și raza 4. Cei patru pixeli de pe axe sunt deja aprinși.',
                 'raster', {'w': 11, 'h': 11, 'pixels': _c, 'given': [[5, 9], [5, 1], [9, 5], [1, 5]], 'circle': [5, 5, 4]},
                 'Algoritmul calculează un singur octant (de la `(0, r)` până la `x = y`) și aprinde simetricele lui în celelalte șapte.',
                 'În primul octant, față de centru: `(0, 4)`, `(1, 4)`, `(2, 3)`, `(3, 3)` (cu `d` pornind de la `1 - r = -3`). Fiecare se oglindește în celelalte șapte octante.'))
_c2 = midpoint_circle(4, 4, 3)
P.append(problem(26, 'Cerc de rază 3', C4, 'medie',
                 'Aprinde pixelii aleși de algoritmul punctului de mijloc pentru cercul cu centrul în `(4, 4)` și raza 3. Pixelii de pe axe sunt deja aprinși.',
                 'raster', {'w': 9, 'h': 9, 'pixels': _c2, 'given': [[4, 7], [4, 1], [7, 4], [1, 4]], 'circle': [4, 4, 3]},
                 'Pornește din `(0, 3)` cu `d = 1 - r = -2`. Cât timp `d < 0`, y rămâne pe loc.',
                 'Față de centru, primul octant dă `(0, 3)`, `(1, 3)`, `(2, 2)`. Cu simetriile: 16 pixeli.'))

# ---------------------------------------------------------------- teorie
def q(id, title, diff, st, right, wrong, hint, sol, source=''):
    P.append(quiz(id, title, C5, diff, st, right, wrong, hint, sol, source))


q(27, 'Transformările 3D, ca matrice', 'ușoară', 'Cum se reprezintă transformările geometrice 3D, astfel încât și translația să fie o înmulțire de matrice?',
  'prin matrice 4×4 în coordonate omogene', ['prin matrice 3×3 în coordonate omogene', 'prin matrice 3×3 în coordonate carteziene', 'prin înmulțiri de matrice în care ordinea nu contează'],
  'În 2D se folosesc matrice 3×3; în 3D mai apare o coordonată.', 'Coordonata omogenă `w` adaugă o linie și o coloană: translația devine liniară, deci 4×4 în 3D.', TEST)
q(28, 'Raportată la o axă', 'ușoară', 'Care dintre următoarele transformări 2D poate fi raportată la o axă?',
  'oglindirea', ['translația', 'rotația', 'scalarea'], 'Rotația și scalarea se raportează la un punct.', 'Oglindirea se face față de o dreaptă (o axă); rotația și scalarea, față de un punct; translația nu are un reper.', TEST)
q(29, 'Scalare urmată de translație', 'medie',
  'Ce transformare 2D reprezintă matricea cu liniile `(sx, 0, tx)`, `(0, sy, ty)`, `(0, 0, 1)`?',
  'scalare față de origine urmată de o translație', ['scalare în jurul originii', 'forfecare în jurul originii', 'translație urmată de o scalare față de origine'],
  'Calculează `T(tx, ty) · S(sx, sy)` și `S(sx, sy) · T(tx, ty)`.', '`T · S` are ultima coloană `(tx, ty, 1)`; `S · T` ar avea `(sx·tx, sy·ty, 1)`.', TEST)
q(30, 'Ce au în comun rotația, scalarea și translația', 'medie', 'Care afirmație despre rotație, scalare și translație este FALSĂ?',
  'conduc la același rezultat indiferent de ordinea în care se aplică', ['sunt transformări afine', 'păstrează paralelismul dreptelor', 'se compun prin înmulțirea matricelor lor'],
  'Înmulțirea matricelor nu e comutativă.', 'Sunt afine și păstrează paralelismul, dar `T · R ≠ R · T` în general.', TEST)
q(31, 'Rotația în jurul unei drepte oarecare', 'medie', 'Ce este adevărat despre rotația 3D în jurul unei drepte oarecare?',
  'se compune din transformări care aliniază dreapta cu o axă principală, rotația, și inversele alinierilor', ['este o singură rotație elementară în jurul axei OZ', 'nu are nevoie niciodată de translație', 'primul plan în care se aduce dreapta este întotdeauna XOZ'],
  'Același tipar ca la rotația 2D în jurul unui punct.', 'Translație (dreapta prin origine), rotații de aliniere, rotația propriu-zisă, apoi inversele în ordine inversă.', TEST)
q(32, 'Forfecarea pe OZ', 'medie', 'La forfecarea față de origine pe axa OZ, ce se întâmplă cu coordonatele unui vârf?',
  'x și y se modifică proporțional cu z, iar z rămâne neschimbat', ['z se modifică proporțional cu x și y', 'toate cele trei coordonate se modifică', 'x și y rămân neschimbate, z se dublează'],
  'Axa pe care se face forfecarea e cea care „împinge” celelalte două coordonate.', '`x\' = x + a·z`, `y\' = y + b·z`, `z\' = z`.', TEST)
q(33, 'Proiecția perspectivă', 'ușoară', 'Ce deosebește proiecția perspectivă de cea paralelă?',
  'proiectoarele trec printr-un centru de proiecție, deci obiectele depărtate apar mai mici', ['proiectoarele sunt paralele între ele', 'păstrează raportul lungimilor pe orice direcție', 'nu are nevoie de un plan de proiecție'],
  'Gândește-te la șinele de tren care par să se întâlnească.', 'În proiecția paralelă centrul e la infinit; în cea perspectivă, împărțirea la adâncime micșorează obiectele depărtate.')
q(34, 'Z-buffer', 'medie', 'Ce ține minte algoritmul Z-buffer pentru fiecare pixel?',
  'adâncimea celui mai apropiat fragment desenat până atunci', ['lista tuturor poligoanelor care îl acoperă', 'normala suprafeței vizibile', 'ordinea în care au fost desenate poligoanele'],
  'Un fragment nou se desenează doar dacă e mai aproape.', 'Pe lângă culoare, fiecare pixel are o valoare de adâncime; poligoanele pot fi desenate în orice ordine.')
q(35, 'Eliminarea fețelor spate', 'medie', 'O față a unui obiect convex închis are normala exterioară `N`, iar `V` e vectorul de la față spre observator. Când este fața nevizibilă?',
  'când N · V < 0', ['când N · V > 0', 'când N · V = 1', 'când N și V sunt paralele și de același sens'],
  'Produsul scalar e pozitiv când unghiul dintre vectori e sub 90°.', 'Fața „privește” în direcția opusă observatorului când unghiul dintre `N` și `V` depășește 90°.')
q(36, 'Modelul Phong', 'ușoară', 'Care componentă a modelului de reflexie Phong depinde de poziția observatorului?',
  'componenta speculară', ['componenta ambientală', 'componenta difuză', 'niciuna'],
  'Pata lucioasă se mută când te miști.', 'Difuza depinde de `N · L`, speculara de `(R · V)ⁿ`, iar ambientala e constantă.')
q(37, 'Gouraud și Phong', 'medie', 'Prin ce diferă modelul de shading Phong de Gouraud?',
  'Phong interpolează normalele și calculează iluminarea în fiecare pixel; Gouraud interpolează culorile calculate în vârfuri', ['Gouraud interpolează normalele, Phong culorile', 'Phong folosește o singură culoare pe poligon', 'Gouraud nu poate folosi lumini difuze'],
  'Unde se evaluează modelul de iluminare: în vârfuri sau în fiecare fragment?', 'De aceea petele speculare din mijlocul unui poligon se pierd la Gouraud și apar la Phong.')
q(38, 'Cohen-Sutherland', 'medie', 'La decuparea Cohen-Sutherland, capetele unui segment au codurile `c1` și `c2`. Când este segmentul respins fără niciun calcul de intersecție?',
  'când c1 ȘI c2 (pe biți) este diferit de 0', ['când c1 SAU c2 (pe biți) este 0', 'când c1 = c2 = 0', 'când c1 ȘI c2 (pe biți) este 0'],
  'Un bit comun înseamnă că ambele capete sunt de aceeași parte a ferestrei.', 'Dacă ambele coduri au același bit setat, segmentul e în întregime în afara acelei laturi. `c1 = c2 = 0` înseamnă acceptare trivială.')

write_course('egc', CHAPTERS, P)
