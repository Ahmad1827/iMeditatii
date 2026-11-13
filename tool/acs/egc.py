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
from common import problem, quiz, write_course, load_grile, add_grile, fold

C1 = '1. Transformări elementare'
C2 = '2. Transformări compuse'
C3 = '3. Fereastră și poartă de vizualizare'
C4 = '4. Rasterizare'
C4B = '5. Decupare, proiecții, iluminare: calcule'
C5 = '6. Teorie: transformări, proiecții, iluminare'
C6 = '7. Grile: transformări 2D și 3D'
C7 = '8. Grile: proiecții, vizualizare, OpenGL'
C8 = '9. Grile: eliminarea părților nevizibile'
C9 = '10. Grile: iluminare, umbre, culoare'
CHAPTERS = [C1, C2, C3, C4, C4B, C5, C6, C7, C8, C9]
EXAM = 'Examen EGC'
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


# ---------------------------------------------------------------- more, from the exams
tr(40, 'Rotație cu 90° în jurul unui colț', C2, 'medie', 'Rotește forma cu 90° în sens orar în jurul punctului `(1, 1)`.', L,
   [('T', -1, -1), ('R', -90), ('T', 1, 1)], 'Sensul orar: unghi negativ. Punctul fix trece prin origine pe durata rotației.', max_ops=3)
tr(41, 'Oglindire față de a doua bisectoare', C2, 'medie', 'Oglindește forma față de dreapta `y = -x`, folosind doar rotații și scalări.', L,
   [('R', 45), ('S', 1, -1), ('R', -45)], 'Dreapta `y = -x` face -45° cu OX: rotește-o peste OX, oglindește, rotește înapoi.',
   '`M = R(-45°) · S(1, -1) · R(45°)`, adică `(x, y) → (-y, -x)`.', max_ops=3, allowed=('R', 'S'))
tr(42, 'Scalare neuniformă față de un punct', C2, 'medie', 'Întinde forma de 2 ori pe orizontală față de punctul `(1, 0)`; pe verticală nu se schimbă.', TRI,
   [('T', -1, 0), ('S', 2, 1), ('T', 1, 0)], 'Punctul fix e `(1, 0)`: adu-l în origine, scalează, du-l înapoi.', max_ops=3)
tr(43, 'Oglindire față de dreapta y = 2', C2, 'medie', 'Oglindește forma față de dreapta orizontală `y = 2`.', FLAG,
   [('T', 0, -2), ('S', 1, -1), ('T', 0, 2)], 'Mută dreapta peste OX, oglindește față de OX, mută înapoi.', max_ops=3, source=EXAM)
tr(44, 'Forfecare verticală față de o dreaptă', C2, 'grea', 'Forfecă forma pe verticală cu factorul 0.5, astfel încât dreapta `x = 1` să rămână pe loc: `y\' = y + 0.5·(x - 1)`.', FLAG,
   [('T', -1, 0), ('F', 0, 0.5), ('T', 1, 0)], 'Forfecarea pe y față de origine lasă pe loc axa OY. Adu dreapta `x = 1` peste OY.', max_ops=3, source=TEST)
tr(45, 'Rotație cu 60° în jurul centrului', C2, 'grea', 'Rotește triunghiul cu 60° în sens trigonometric în jurul punctului `(2, 1)`.', TRI,
   [('T', -2, -1), ('R', 60), ('T', 2, 1)], 'Același tipar ca la orice rotație în jurul unui punct; unghiul nu schimbă rețeta.', max_ops=3)
tr(46, 'Poartă centrată, scalare uniformă', C3, 'grea',
   'Fereastra este `[0, 2] × [0, 2]`, poarta este `[0, 8] × [0, 4]`. Ca desenul să nu se deformeze, se folosește o scalare uniformă (factorul mai mic dintre `sx` și `sy`), iar imaginea se centrează în poartă. Forma dată e fereastra.',
   [[0, 0], [2, 0], [2, 2], [0, 2]], [('S', 2, 2), ('T', 2, 0)],
   '`sx = 4`, `sy = 2`: se ia `s = 2`. Imaginea are lățimea 4 într-o poartă de lățime 8: rămân 4 unități, câte 2 de fiecare parte.',
   '`M = T(2, 0) · S(2, 2)`. Pe verticală imaginea umple poarta; pe orizontală e centrată, cu 2 unități libere în stânga și 2 în dreapta.', max_ops=3, source='Test EGC, transformări 2D (2021)')

line(47, 'Segment orizontal aproape', 'ușoară', (0, 1), (8, 3), 10, 5, 'Panta 1/4: y crește de două ori în opt pași.')
line(48, 'Segment abrupt care coboară', 'grea', (2, 9), (5, 0), 7, 10, 'Panta e mai mare decât 1 în modul: câte un pixel pe fiecare linie, x crește rar.')
line(49, 'Pantă exact 1/2', 'medie', (0, 0), (8, 4), 10, 6, 'La mijlocul dintre doi pixeli algoritmul alege mereu la fel: urmărește semnul variabilei de test când e 0.')
line(50, 'Segment spre stânga-jos', 'grea', (9, 6), (1, 1), 11, 8, 'Și x, și y scad. Panta e sub 1: câte un pixel pe coloană.')
_c3 = midpoint_circle(6, 6, 5)
P.append(problem(51, 'Cerc de rază 5', C4, 'grea',
                 'Aprinde pixelii aleși de algoritmul punctului de mijloc pentru cercul cu centrul în `(6, 6)` și raza 5. Pixelii de pe axe sunt deja aprinși.',
                 'raster', {'w': 13, 'h': 13, 'pixels': _c3, 'given': [[6, 11], [6, 1], [11, 6], [1, 6]], 'circle': [6, 6, 5]},
                 'Pornește din `(0, 5)` cu `d = 1 - r = -4`; dacă `d < 0`: `d += 2x + 3`, altfel `d += 2(x - y) + 5` și y scade.',
                 'Primul octant, față de centru: `(0, 5)`, `(1, 5)`, `(2, 5)`, `(3, 4)`; apoi simetricele în celelalte șapte octante.', EXAM))


def num(id, label, value, tol=0.01, hint='un număr'):
    v = round(float(value), 4)
    return {'id': id, 'label': label, 'answer': repr(int(v) if v == int(v) else v), 'number': True, 'tol': tol, 'hint': hint}


def txt(id, label, answer, hint=''):
    return {'id': id, 'label': label, 'answer': answer, 'hint': hint}


def calc(id, title, diff, statement, fields, hint, solution, source=EXAM, ch=C4B):
    P.append(problem(id, title, ch, diff, statement, 'calc', {'fields': fields}, hint, solution, source))


def n(v, k=3):
    v = round(float(v), k)
    return str(int(v)) if v == int(v) else f'{v}'.rstrip('0').replace('.', ',')


# Cohen-Sutherland: bits TBRL (sus, jos, dreapta, stânga)
def outcode(x, y, w):
    xmin, ymin, xmax, ymax = w
    return (8 if y > ymax else 0) | (4 if y < ymin else 0) | (2 if x > xmax else 0) | (1 if x < xmin else 0)


def cs_case(id, title, diff, a, b, w, extra_fields=(), extra_sol=''):
    ca, cb = outcode(*a, w), outcode(*b, w)
    verdict = 'acceptat' if (ca | cb) == 0 else ('respins' if (ca & cb) else 'decupat')
    calc(id, title, diff,
         f'Fereastra de decupare este `[{w[0]}, {w[2]}] × [{w[1]}, {w[3]}]`. Codurile Cohen-Sutherland au 4 biți, în ordinea **sus, jos, dreapta, stânga** (de exemplu `1001` = deasupra și la stânga). '
         f'Segmentul are capetele `A({a[0]}, {a[1]})` și `B({b[0]}, {b[1]})`.',
         [txt('ca', 'codul lui A (4 biți)', f'{ca:04b}', 'ex.: 0000'), txt('cb', 'codul lui B (4 biți)', f'{cb:04b}', 'ex.: 1010'),
          txt('v', 'segmentul este: acceptat / respins / decupat', verdict, 'un cuvânt'), *extra_fields],
         'Un bit e 1 când punctul e de acea parte a ferestrei. Ambele coduri 0000: acceptat trivial. `codA AND codB ≠ 0`: ambele sunt de aceeași parte, respins trivial. Altfel trebuie decupat.',
         f'`A` → `{ca:04b}`, `B` → `{cb:04b}`; `OR = {ca | cb:04b}`, `AND = {ca & cb:04b}`: segmentul e **{verdict}**.' + extra_sol)


cs_case(52, 'Cohen-Sutherland: acceptare trivială', 'ușoară', (2, 3), (7, 5), (1, 1, 8, 6))
cs_case(53, 'Cohen-Sutherland: respingere trivială', 'ușoară', (-3, 7), (2, 9), (0, 0, 10, 6))
# a segment crossing the left edge
_w = (0, 0, 10, 8); _a = (-4, 2); _b = (6, 7)
_y = _a[1] + (_b[1] - _a[1]) * (0 - _a[0]) / (_b[0] - _a[0])
cs_case(54, 'Cohen-Sutherland: intersecția cu marginea stângă', 'medie', _a, _b, _w,
        [num('y', 'y-ul punctului în care segmentul intră în fereastră (pe x = 0)', _y)],
        f' Capătul `A` e la stânga: se taie cu dreapta `x = 0`: `y = {_a[1]} + ({_b[1]} - {_a[1]}) · (0 - ({_a[0]})) / ({_b[0]} - ({_a[0]})) = {n(_y)}`. Noul capăt `(0, {n(_y)})` are codul `0000`, deci restul segmentului e acceptat.')
_w = (0, 0, 10, 10); _a = (2, -4); _b = (14, 8)
# bottom edge first (A has bit "jos"), then right edge for B
_xb = _a[0] + (_b[0] - _a[0]) * (0 - _a[1]) / (_b[1] - _a[1])
_yr = _a[1] + (_b[1] - _a[1]) * (10 - _a[0]) / (_b[0] - _a[0])
cs_case(55, 'Cohen-Sutherland: decupat la ambele capete', 'grea', _a, _b, _w,
        [num('x1', 'x-ul punctului de pe marginea de jos (y = 0)', _xb), num('y2', 'y-ul punctului de pe marginea dreaptă (x = 10)', _yr)],
        f' `A` e sub fereastră: tăiat cu `y = 0` dă `x = {n(_xb)}`. `B` e la dreapta: tăiat cu `x = 10` dă `y = {n(_yr)}`. Segmentul vizibil: `({n(_xb)}, 0)` – `(10, {n(_yr)})`.')
cs_case(56, 'Cohen-Sutherland: nici acceptat, nici respins, dar invizibil', 'grea', (-3, 6), (3, 12), (0, 0, 8, 8),
        [], ' Codurile nu au niciun bit comun, deci testul trivial nu îl respinge, deși segmentul trece pe lângă colțul ferestrei: după decupări succesive nu rămâne nimic din el. De aceea algoritmul repetă testele după fiecare tăiere.')


def vec(v):
    return '(' + ', '.join(n(x) for x in v) + ')'


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def norm(v):
    l = math.sqrt(dot(v, v)); return [x / l for x in v]


def sub3(a, b):
    return [x - y for x, y in zip(a, b)]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


# perspective projection on z = d, centre in the origin
for id, pt, d in ((57, (4, 6, 8), 2), (58, (-3, 9, 12), 4)):
    calc(id, f'Proiecție perspectivă: punctul ({pt[0]}, {pt[1]}, {pt[2]})', 'ușoară' if id == 57 else 'medie',
         f'Centrul de proiecție este în origine, iar planul de proiecție este `z = {d}`. Unde se proiectează punctul `P{vec(pt)}`?',
         [num('x', "x'", pt[0] * d / pt[2]), num('y', "y'", pt[1] * d / pt[2])],
         "Asemănarea triunghiurilor: `x' = x · d / z`, `y' = y · d / z`.",
         f"`x' = {pt[0]} · {d} / {pt[2]} = {n(pt[0] * d / pt[2])}`, `y' = {pt[1]} · {d} / {pt[2]} = {n(pt[1] * d / pt[2])}`. Obiectele mai depărtate (z mare) ies mai mici.")

# back-face culling
for id, tri, eye in ((59, ((0, 0, 0), (4, 0, 0), (0, 3, 0)), (1, 1, 5)), (60, ((1, 0, 2), (1, 4, 2), (5, 0, 2)), (2, 1, 9))):
    nrm = cross(sub3(tri[1], tri[0]), sub3(tri[2], tri[0]))
    v = sub3(eye, tri[0])
    d_ = dot(nrm, v)
    calc(id, 'Față auto-obturată?' if id == 59 else 'Față auto-obturată, vârfuri în altă ordine', 'medie',
         f'Un triunghi are vârfurile, în ordinea dată (sens trigonometric privit din afara obiectului), `A{vec(tri[0])}`, `B{vec(tri[1])}`, `C{vec(tri[2])}`. Observatorul este în `O{vec(eye)}`. '
         'Normala exterioară este `N = AB × AC`.',
         [num('nx', 'Nx', nrm[0]), num('ny', 'Ny', nrm[1]), num('nz', 'Nz', nrm[2]), num('d', 'N · (O - A)', d_),
          txt('v', 'fața este: vizibilă / ascunsă', 'vizibilă|vizibila' if d_ > 0 else 'ascunsă|ascunsa', 'un cuvânt')],
         'O față e vizibilă dacă observatorul e de partea normalei exterioare: produsul scalar dintre normală și vectorul spre observator e pozitiv.',
         f'`AB = {vec(sub3(tri[1], tri[0]))}`, `AC = {vec(sub3(tri[2], tri[0]))}`, `N = {vec(nrm)}`; `O - A = {vec(v)}`, `N · (O - A) = {n(d_)}` ⇒ fața e **{"vizibilă" if d_ > 0 else "ascunsă"}**.')

# Lambert
_N = [0, 0, 1]; _P = [0, 0, 0]; _Ls = [3, 0, 4]; _Ip, _kd = 200, 0.6
_L = norm(sub3(_Ls, _P))
calc(61, 'Reflexia difuză (legea lui Lambert)', 'medie',
     f'Un punct `P(0, 0, 0)` al unei suprafețe are normala `N = (0, 0, 1)`. O sursă punctiformă se află în `(3, 0, 4)` și are intensitatea `Ip = {_Ip}`; coeficientul de reflexie difuză este `kd = {_kd}`.',
     [num('c', 'cos θ (θ: unghiul dintre N și direcția spre sursă)', dot(_N, _L)), num('i', 'intensitatea difuză Id', _Ip * _kd * dot(_N, _L), tol=0.05)],
     '`Id = Ip · kd · cos θ`, cu `cos θ = N · L` pentru vectori unitari. Nu depinde de poziția observatorului.',
     f'`L = (3, 0, 4) / 5 = (0,6, 0, 0,8)`, `cos θ = N · L = 0,8`, `Id = {_Ip} · {_kd} · 0,8 = {n(_Ip * _kd * 0.8)}`.')
# Phong specular
_L = norm([1, 0, 1]); _V = norm([-1, 0, 1]); _Nn = [0, 0, 1]
_R = [2 * dot(_Nn, _L) * a - b for a, b in zip(_Nn, _L)]
_ks, _nexp, _Ip2 = 0.5, 4, 100
calc(62, 'Reflexia speculară (modelul Phong)', 'grea',
     f'Normala într-un punct este `N = (0, 0, 1)`. Direcția spre sursă este `L = (1, 0, 1)/√2`, iar direcția spre observator este `V = (-1, 0, 1)/√2`. Sursa are `Ip = {_Ip2}`, `ks = {_ks}`, exponentul de strălucire `n = {_nexp}`.',
     [num('rx', 'Rx (vectorul reflectat R = 2(N·L)N - L)', _R[0]), num('rz', 'Rz', _R[2]), num('rv', 'R · V', dot(_R, _V)),
      num('i', 'intensitatea speculară Is', _Ip2 * _ks * max(0, dot(_R, _V)) ** _nexp, tol=0.05)],
     '`Is = Ip · ks · (R · V)ⁿ`; `R` e simetricul lui `L` față de normală.',
     f'`N · L = 1/√2 ≈ 0,707`, `R = 2 · 0,707 · (0, 0, 1) - (0,707, 0, 0,707) = ({n(_R[0])}, 0, {n(_R[2])})`. `R · V = {n(dot(_R, _V))}`: observatorul e exact pe direcția reflectată, deci `Is = {_Ip2} · {_ks} · 1 = {n(_Ip2 * _ks)}`, maximul posibil.')
_V2 = norm([0, 0, 1])
_rv = dot(_R, _V2)
calc(63, 'Specular, observator deasupra', 'grea',
     f'Aceleași date ca la problema anterioară (`N = (0, 0, 1)`, `L = (1, 0, 1)/√2`, `Ip = {_Ip2}`, `ks = {_ks}`, `n = {_nexp}`), dar observatorul privește din `V = (0, 0, 1)`.',
     [num('rv', 'R · V', _rv), num('i', 'intensitatea speculară Is', _Ip2 * _ks * _rv ** _nexp, tol=0.05)],
     'Vectorul reflectat nu se schimbă (nu depinde de observator); doar unghiul dintre R și V.',
     f'`R = (-0,707, 0, 0,707)`, `R · V = 0,707`, `Is = {_Ip2} · {_ks} · 0,707⁴ = {n(_Ip2 * _ks * _rv ** _nexp)}`: exponentul face lobul îngust, iar la 45° de el lumina speculară scade deja la un sfert.')
# Blinn: H
_H = norm([a + b for a, b in zip(norm([1, 0, 1]), [0, 0, 1])])
calc(64, 'Vectorul median H (Blinn-Phong)', 'medie',
     'Direcția spre sursă este `L = (1, 0, 1)/√2`, direcția spre observator `V = (0, 0, 1)`, normala `N = (0, 0, 1)`. Modelul Blinn-Phong folosește vectorul median `H = (L + V) / |L + V|` în loc de `R`.',
     [num('nh', 'N · H (cosinusul unghiului dintre N și H)', dot([0, 0, 1], _H))],
     '`H` e la jumătatea drumului dintre L și V. Lumina speculară e maximă când `H` coincide cu normala.',
     f'`L + V = (0,707, 0, 1,707)`, `|L + V| ≈ {n(math.sqrt(0.5 + 1.707 ** 2))}`, `N · H = {n(dot([0, 0, 1], _H))}` (unghi de 22,5°, jumătate din unghiul de 45° dintre L și V).')
# fog
calc(65, 'Ceața liniară, calculată', 'ușoară',
     'Ceața liniară începe la distanța 10 și acoperă totul de la distanța 50. Un fragment se află la distanța 30 de observator; culoarea lui este `(200, 100, 0)`, culoarea ceții este `(128, 128, 128)`.',
     [num('f', 'factorul f (1 = fără ceață, 0 = doar ceață)', (50 - 30) / (50 - 10)), num('r', 'componenta R a culorii finale', 0.5 * 200 + 0.5 * 128), num('g', 'componenta G a culorii finale', 0.5 * 100 + 0.5 * 128)],
     '`f = (end - z) / (end - start)`, culoarea finală `= f · Cfragment + (1 - f) · Cceață`.',
     '`f = (50 - 30) / (50 - 10) = 0,5`; `R = 0,5 · 200 + 0,5 · 128 = 164`, `G = 0,5 · 100 + 0,5 · 128 = 114`.', source='Test EGC, cursurile 9–12 (2021)')
# Gouraud interpolation
calc(66, 'Gouraud: culoarea de pe o latură', 'medie',
     'În modelul Gouraud, culorile se calculează doar în vârfuri și apoi se interpolează. O latură merge de la vârful `A` (pe linia de scanare 10, intensitate 40) la `B` (linia 30, intensitate 200). Ce intensitate primește latura pe linia de scanare 15? Dar pe linia 25?',
     [num('i15', 'intensitatea pe linia 15', 40 + (200 - 40) * (15 - 10) / 20), num('i25', 'intensitatea pe linia 25', 40 + (200 - 40) * (25 - 10) / 20)],
     'Interpolare liniară: `I = IA + (IB - IA) · (y - yA) / (yB - yA)`.',
     '`I(15) = 40 + 160 · 5/20 = 80`, `I(25) = 40 + 160 · 15/20 = 160`. Pe linie, între cele două laturi, se interpolează la fel pe x. De aceea un reflex specular din mijlocul poligonului se pierde (îl prinde doar Phong).')
# z-buffer
calc(67, 'Z-buffer pe un pixel', 'medie',
     'Pe același pixel ajung, în ordinea rasterizării, trei fragmente: roșu cu `z = 0,7`, verde cu `z = 0,4`, albastru cu `z = 0,55` (z mai mic = mai aproape). Buffer-ul z pornește cu 1, testul este `GL_LESS`.',
     [txt('c', 'culoarea pixelului la sfârșit', 'verde'), num('z', 'valoarea din buffer-ul z la sfârșit', 0.4), num('w', 'de câte ori se scrie în buffer-ul de culoare', 2)],
     'Fiecare fragment se compară cu valoarea din buffer; dacă e mai aproape, se scrie (și culoarea, și z).',
     'Roșu: `0,7 < 1`, scris. Verde: `0,4 < 0,7`, scris. Albastru: `0,55 < 0,4` e fals, aruncat. Pixelul rămâne verde, cu z = 0,4, după 2 scrieri; ordinea nu contează pentru rezultat, doar pentru numărul de scrieri.')
# colour models
calc(68, 'Din RGB în CMY', 'ușoară', 'Culoarea `(R, G, B) = (0,2, 0,7, 1)` (componente între 0 și 1) se tipărește. Care sunt componentele ei în modelul CMY?',
     [num('c', 'C', 0.8), num('m', 'M', 0.3), num('y', 'Y', 0)],
     'Modelul substractiv: `C = 1 - R`, `M = 1 - G`, `Y = 1 - B`.', '`(C, M, Y) = (0,8, 0,3, 0)`: cerneala cyan absoarbe roșul.', source='Test EGC, cursurile 9–12 (2021)')


def hsv(r, g, b):
    import colorsys
    h, s_, v = colorsys.rgb_to_hsv(r, g, b)
    return h * 360, s_, v


_h = hsv(1, 0.5, 0)
calc(69, 'Din RGB în HSV', 'medie', 'Care sunt componentele HSV ale culorii `(R, G, B) = (1, 0,5, 0)`? Nuanța (H) în grade, S și V între 0 și 1.',
     [num('h', 'H (grade)', _h[0], tol=0.5), num('s', 'S', _h[1]), num('v', 'V', _h[2])],
     '`V = max`, `S = (max - min) / max`; nuanța: pe hexagon, roșu la 0°, galben la 60°, verde la 120°.',
     f'`max = 1`, `min = 0`: `V = 1`, `S = 1`. Culoarea e între roșu (0°) și galben (60°), la jumătate: `H = {n(_h[0])}°` (portocaliu).', source='Test EGC, cursurile 9–12 (2021)')
# Bresenham's decision variable
_dx, _dy = 8, 3
_d = [2 * _dy - _dx]
for _ in range(4):
    _d.append(_d[-1] + (2 * _dy - 2 * _dx if _d[-1] >= 0 else 2 * _dy))
calc(70, 'Variabila de test din Bresenham', 'grea',
     'Segmentul merge de la `(0, 0)` la `(8, 3)`. Algoritmul Bresenham folosește variabila de test `d`, cu `d₀ = 2Δy - Δx`; la fiecare pas, dacă `d < 0` se alege pixelul din dreapta (E) și `d += 2Δy`, altfel cel din dreapta-sus (NE) și `d += 2(Δy - Δx)`.',
     [num('d0', 'd₀', _d[0]), num('ie', 'incrementul pentru E', 2 * _dy), num('ine', 'incrementul pentru NE', 2 * (_dy - _dx)), num('d2', 'd după doi pași (d₂)', _d[2])],
     'Toate valorile sunt întregi: de aceea algoritmul e rapid. Urmărește semnul la fiecare pas.',
     f'`Δx = 8`, `Δy = 3`: `d₀ = {_d[0]}` (< 0: E), `d₁ = {_d[1]}` (≥ 0: NE), `d₂ = {_d[2]}`. Incremente: `+{2 * _dy}` pentru E, `{2 * (_dy - _dx)}` pentru NE.')
# window-viewport mapping of a point
_xw = (3 - 1) / (5 - 1) * (400 - 100) + 100
_yw = (2 - 0) / (4 - 0) * (300 - 0) + 0
calc(71, 'Un punct, din fereastră în poartă', 'medie',
     'Fereastra este `[1, 5] × [0, 4]`, poarta de afișare este `[100, 400] × [0, 300]`. În ce punct al porții ajunge punctul `(3, 2)` din fereastră?',
     [num('x', 'x în poartă', _xw), num('y', 'y în poartă', _yw)],
     '`xp = xpmin + (x - xfmin) · sx`, cu `sx = (xpmax - xpmin) / (xfmax - xfmin)`.',
     f'`sx = 300 / 4 = 75`, `sy = 300 / 4 = 75`: `xp = 100 + 2 · 75 = {n(_xw)}`, `yp = 0 + 2 · 75 = {n(_yw)}`. Mijlocul ferestrei ajunge în mijlocul porții.', source='Test EGC, transformări 2D (2021)')
# homogeneous point through a composite transform
_m = compose([('T', -1, -1), ('R', 90), ('T', 1, 1)])
_p = (3, 1)
_q = (_m[0] * _p[0] + _m[1] * _p[1] + _m[2], _m[3] * _p[0] + _m[4] * _p[1] + _m[5])
calc(72, 'Un punct, rotit în jurul altui punct', 'medie',
     'Punctul `P(3, 1)` se rotește cu 90° în sens trigonometric în jurul punctului `C(1, 1)`, adică `M = T(1, 1) · R(90°) · T(-1, -1)`. Unde ajunge?',
     [num('x', "x'", _q[0]), num('y', "y'", _q[1])],
     'Lucrează în trei pași: `P - C`, rotit cu 90° (`(x, y) → (-y, x)`), plus `C`.',
     f'`P - C = (2, 0)`, rotit: `(0, 2)`, plus `C`: `({n(_q[0])}, {n(_q[1])})`.', ch=C2)
# transparency (alpha blending)
calc(73, 'Transparență: amestecul alfa', 'ușoară',
     'Peste un pixel de culoare `(0, 0, 255)` se desenează un fragment `(255, 0, 0)` cu opacitatea `α = 0,25`, cu amestecul obișnuit `C = α · Csursă + (1 - α) · Cdestinație`.',
     [num('r', 'R', 0.25 * 255), num('g', 'G', 0), num('b', 'B', 0.75 * 255)],
     'Fragmentul nou e sursa, ce era deja în pixel e destinația.', '`R = 0,25 · 255 = 63,75`, `G = 0`, `B = 0,75 · 255 = 191,25`. Ordinea de desenare contează: obiectele transparente se desenează după cele opace, din spate în față.', source='Test EGC, cursurile 9–12 (2021)')
# viewing volume: canonical
calc(74, 'Volumul vizual canonic', 'medie',
     'În OpenGL, după proiecție și împărțirea perspectivă, coordonatele vizibile sunt cele din cubul `[-1, 1]³`. Un vârf are coordonatele de decupare `(x, y, z, w) = (2, -3, 1, 4)`.',
     [num('x', 'x după împărțirea perspectivă', 0.5), num('y', 'y', -0.75), num('z', 'z', 0.25), txt('v', 'vârful este în volumul vizual: da / nu', 'da')],
     'Împărțirea perspectivă împarte la `w`. Decuparea se face înainte de ea, comparând fiecare coordonată cu `±w`.',
     '`(2/4, -3/4, 1/4) = (0,5, -0,75, 0,25)`: toate sunt în `[-1, 1]`, deci vârful e vizibil (echivalent: `|x|, |y|, |z| ≤ w`).', source='Test EGC, transformări 3D, proiecții (2021)', ch=C4B)

# ------------------------------------------------- the tests' questions (curs.upb.ro)
import re


def egc_chapter(it):
    t = fold(it['test'])
    q = fold(it['q'] + ' ' + ' '.join(it.get('options', [])))
    if 'nevizibil' in t:
        return C8
    if 'cursuri 9' in t:
        return C9
    if re.search(r'proiecti|vizualizare|viewport|poarta|decupare|volum(ul)? vizual|camer|observator', q):
        return C7
    return C6


TESTS = {'Transformari 2D': 'transformări 2D', 'Transformari 2D si 3D': 'transformări 2D și 3D',
         'Transformari 3D, Proiectii, Transformarea varfurilor in OpenGL': 'transformări 3D, proiecții',
         'Eliminarea partilor nevizibile ale scenelor 3D din imagini': 'părți nevizibile', 'cursuri 9,10,11,12': 'cursurile 9–12'}


def egc_source(it):
    t = it['test'].replace('Test - ', '')
    year = it['source'].rsplit('(', 1)[-1].rstrip(')') if '(' in it['source'] else ''
    return f'Test EGC, {TESTS.get(t, t)}' + (f' ({year})' if year else '')


def egc_difficulty(it):
    return 'grea' if len(it.get('right', [])) > 2 else 'medie'


add_grile(P, load_grile('egc_grile'), 101, egc_chapter, egc_difficulty, egc_source)

write_course('egc', CHAPTERS, P)
