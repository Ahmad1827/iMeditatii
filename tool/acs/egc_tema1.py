"""EGC: exercises on the Tema 1 (Card Games, Hearthstone) — exec'd by egc.py, before write_course.

Built on the student's own Tema 1 (~/an3/egc/gfx-framework/src/lab_m1/Tema1, copied in
tool/acs/ghid_egc_t1/src): the transforms of DrawRect, DrawCard and DrawArrow, the meshes of
shapes.cpp, ArrangeZone, the smoothing and the shake of Update, the mouse conversion, the
rules of the game. Every number comes from tool/acs/egc_tema1_model.py. The guide
web/materiale/egc-tema-1.pdf explains the same code.
"""
import egc_tema1_model as tm

CT = '11. Tema 1: Card Games (Hearthstone)'
CHAPTERS.append(CT)
TEMA = 'Tema 1 EGC (Hearthstone)'
_L = tm.layout()
_cw, _ch, _cg = _L['cardW'], _L['cardH'], _L['cardGap']
INTRO = 'În Tema 1 (Hearthstone, fereastra 1280 × 720): `cardW = 64,512`, `cardH = 92,16`, `cardGap = 12,9024`. '


def tc(id, title, diff, statement, fields, hint, solution):
    calc(id, title, diff, statement, fields, hint, solution, source=TEMA, ch=CT)


def tq(id, title, diff, st, right, wrong, hint, sol):
    P.append(quiz(id, title, CT, diff, st, right, wrong, hint, sol, TEMA))


# ------------------------------------------------------------------ transforms, built in the app
SQ = [[0, 0], [1, 0], [1, 1], [0, 1]]
ARROW = [[0, -0.15], [0.75, -0.15], [0.75, -0.5], [1, 0], [0.75, 0.5], [0.75, 0.15], [0, 0.15]]
DIAMOND = [[0, 0.5], [0.5, 0], [0, -0.5], [-0.5, 0]]
CARD = [[2, 1], [4, 1], [4, 4], [2, 4]]
tr(400, 'DrawRect: pătratul unitate devine o carte', CT, 'ușoară',
   'Mesh-ul `square` din temă e pătratul `[0, 1]²` (colțul stânga-jos în origine). Construiește transformarea lui `DrawRect(2, 1, 2, 3)`: un dreptunghi cu colțul stânga-jos în `(2, 1)`, lat 2 și înalt 3.',
   SQ, [('S', 2, 3), ('T', 2, 1)],
   'În cod: `modelMatrix = parent · Translate(x, y) · Scale(width, height)`. Care se aplică întâi?',
   '`M = T(2, 1) · S(2, 3)`: întâi scalarea (pătratul devine 2 × 3, colțul rămâne în origine), apoi translația. Invers, colțul ar ajunge în `(4, 3)`.', max_ops=2, source=TEMA)
tr(401, 'Shake: cartea rotită în jurul centrului', CT, 'medie',
   'Cartea ocupă dreptunghiul `[2, 4] × [1, 4]`. Rotește-o cu 90° (sens trigonometric) în jurul centrului ei, ca matricea `rotation` din `DrawCard`.',
   CARD, [('T', -3, -2.5), ('R', 90), ('T', 3, 2.5)],
   'Centrul e `(x + w/2, y + h/2)`. În cod: `Translate(c) · Rotate(angle) · Translate(-c)`.',
   '`M = T(3, 2,5) · R(90°) · T(-3, -2,5)`: centrul ajunge în origine, se rotește, revine. Centrul rămâne pe loc.', max_ops=3, source=TEMA)
tr(402, 'Hover: cartea mărită pe loc', CT, 'medie',
   'Mărește cartea `[2, 4] × [1, 4]` de 1,5 ori, astfel încât centrul ei să rămână pe loc (efectul de hover / selectare).',
   CARD, [('T', -3, -2.5), ('S', 1.5, 1.5), ('T', 3, 2.5)],
   'O scalare față de origine mută și centrul. Adu centrul în origine întâi.',
   '`M = T(3, 2,5) · S(1,5, 1,5) · T(-3, -2,5)`. În temă același efect e obținut altfel: `DrawCard` mută colțul cu `(w - cardW) / 2` la stânga și în jos.', max_ops=3, source=TEMA)
tr(403, 'Săgeata spre cursor', CT, 'medie',
   'Mesh-ul `arrow` merge pe axa x de la `(0, 0)` (coada) la `(1, 0)` (vârful). Cartea selectată are centrul în `(1, 1)`, cursorul e în `(1, 5)`. Așază săgeata cu coada în centrul cărții și vârful în cursor, păstrându-i grosimea.',
   ARROW, [('S', 4, 1), ('R', 90), ('T', 1, 1)],
   'Ca în `DrawArrow`: `Translate(start) · Rotate(atan2(dy, dx)) · Scale(lungime, grosime)`.',
   '`d = (0, 4)`: lungimea 4, unghiul `atan2(4, 0) = 90°`. `M = T(1, 1) · R(90°) · S(4, 1)`.', max_ops=3, source=TEMA)
tr(404, 'Săgeata spre stânga', CT, 'medie',
   'Aceeași săgeată (de la `(0, 0)` la `(1, 0)`), din centrul cărții `(2, 1)` spre cursorul `(-1, 1)`, aflat în stânga cărții. Păstrează-i grosimea.',
   ARROW, [('S', 3, 1), ('R', 180), ('T', 2, 1)],
   'Lungimea e `√(dx² + dy²)`, unghiul `atan2(dy, dx)`; pentru `dx < 0` și `dy = 0`, `atan2` dă 180°.',
   '`d = (-3, 0)`: `l = 3`, `θ = atan2(0, -3) = 180°` (cu `atan(dy/dx)` ai fi obținut 0°, adică săgeata spre dreapta). `M = T(2, 1) · R(180°) · S(3, 1)`.', max_ops=3, source=TEMA)
tr(405, 'Simbolul de pe carte', CT, 'ușoară',
   'Rombul (`diamond`) e centrat în origine, cu diagonalele de 1. Pune-l cu centrul în `(3, 2)` și diagonalele de 2 (ca `Translate(x + w/2, y + h·0,25) · Scale(size, size)` din `DrawCard`).',
   DIAMOND, [('S', 2, 2), ('T', 3, 2)],
   'O formă centrată în origine se scalează pe loc; apoi se mută după centru.', '`M = T(3, 2) · S(2, 2)`.', max_ops=2, source=TEMA)

# ------------------------------------------------------------------ numbers from the code
_x3 = tm.arrange_x(3, _L)
tc(410, 'ArrangeZone: 3 cărți pe tablă', 'medie', INTRO + 'Pe tabla ta sunt 3 cărți. Ce `targetX` primesc, de la stânga la dreapta?',
   [num('a', 'prima carte', _x3[0], tol=0.05), num('b', 'a doua', _x3[1], tol=0.05), num('c', 'a treia', _x3[2], tol=0.05)],
   '`totalWidth = n·cardW + (n - 1)·cardGap`, `startX = (screenW - totalWidth) / 2`, `x_k = startX + k·(cardW + cardGap)`.',
   f'`totalWidth = 3 · 64,512 + 2 · 12,9024 = 219,341`; `startX = (1280 - 219,341) / 2 = {n(_x3[0], 2)}`; pasul `77,414`: `{n(_x3[0], 2)}`, `{n(_x3[1], 2)}`, `{n(_x3[2], 2)}`. Cartea din mijloc stă exact la `heroX`.')
_x6 = tm.arrange_x(6, _L)
tc(411, 'ArrangeZone: a șasea carte din mână', 'medie', INTRO + 'Ai 6 cărți în mână. La ce `targetX` stă prima și la ce `targetX` stă ultima?',
   [num('a', 'prima', _x6[0], tol=0.05), num('b', 'ultima', _x6[5], tol=0.05)],
   'Grupul e centrat: prima începe la `(1280 - totalWidth) / 2`.',
   f'`totalWidth = 6 · 64,512 + 5 · 12,9024 = {n(6 * _cw + 5 * _cg, 2)}`, `startX = {n(_x6[0], 2)}`, ultima: `startX + 5 · 77,414 = {n(_x6[5], 2)}`.')
tc(412, 'Layout-ul din Init', 'ușoară', 'În `Init` (fereastra 1280 × 720): `handH = heroZoneH = 0,16·screenH`, `halfH = 0,18·screenH`, `cardH = 0,8·handH`, `cardW = 0,7·cardH`, `cardGap = 0,2·cardW`. Calculează-le.',
   [num('h', 'handH', _L['handH']), num('f', 'halfH', _L['halfH']), num('ch', 'cardH', _L['cardH']), num('cw', 'cardW', _L['cardW'], tol=0.01)],
   'Totul e proporțional cu înălțimea ecranului.', '`handH = 115,2`, `halfH = 129,6`, `cardH = 92,16`, `cardW = 64,512` (și `cardGap = 12,9024`). Benzile: `4 · 115,2 + 2 · 129,6 = 720`.')
tc(413, 'Jumătatea ta de tablă', 'ușoară', INTRO + 'Între ce valori trebuie să fie y-ul cursorului la eliberare, ca plasarea să fie validă? (`handH = heroZoneH = 115,2`)',
   [num('a', 'y minim', _L['handH'] + _L['heroZoneH']), num('b', 'y maxim', _L['screenH'] / 2)],
   'Condiția din `OnMouseBtnRelease`: `handH + heroZoneH <= my && my <= screenH / 2`.', '`[230,4, 360]`: între zona eroului tău și linia de mijloc.')
tc(414, 'Mouse-ul în scenă', 'ușoară', 'Fereastra are 1280 × 720. Framework-ul raportează mouse-ul în `(100, 700)` (origine sus-stânga). Unde e în scenă?',
   [num('x', 'x', 100), num('y', 'y', 20)], '`y = screenH - mouseY · screenH / res.y`.', '`(100, 720 - 700) = (100, 20)`: jos, în banda mâinii tale.')
tc(415, 'Mouse-ul, fereastra mărită', 'medie', 'Fereastra a fost mărită la 1920 × 1080 (scena rămâne 1280 × 720). Mouse-ul e la `(960, 270)`. Unde e în scenă?',
   [num('x', 'x', 640), num('y', 'y', 540)], 'Se împarte la rezoluția curentă: `x = mouseX · screenW / res.x`.',
   '`x = 960 · 1280 / 1920 = 640`, `y = 720 - 270 · 720 / 1080 = 540`: pe eroul inamic.')
_hw = _cw * 1.15
tc(416, 'Hover: unde se desenează cartea', 'medie', INTRO + 'O carte din mână are `card.x = 500` și a ajuns la mărimea de hover (×1,15). Ce lățime și ce x folosește `DrawCard`?',
   [num('w', 'w', _hw, tol=0.01), num('x', 'x', 500 - (_hw - _cw) / 2, tol=0.01)],
   '`x = card.x - (w - cardW) / 2`.', f'`w = 1,15 · 64,512 = {n(_hw, 3)}`, `x = 500 - {n((_hw - _cw) / 2, 3)} = {n(500 - (_hw - _cw) / 2, 3)}`: cartea crește egal în toate părțile.')
tc(417, 'Interpolarea spre țintă', 'medie', 'O carte e la `x = 0`, ținta e `100`. `Update` face `x += (target - x) · min(1, 8·dt)`. Unde e după 2 cadre la 60 FPS? Dar după 2 cadre la 30 FPS?',
   [num('a', '60 FPS', tm.smooth(0, 100, 1 / 60, 2), tol=0.05), num('b', '30 FPS', tm.smooth(0, 100, 1 / 30, 2), tol=0.05)],
   'Distanța rămasă se înmulțește la fiecare cadru cu `1 - step`.',
   '60 FPS: `step = 0,1333`, `100 · (1 - 0,8667²) = 24,89`. 30 FPS: `step = 0,2667`, `100 · (1 - 0,7333²) = 46,22`.')
tc(418, 'Interpolarea, un cadru lung', 'ușoară', 'Același `x += (target - x) · min(1, 8·dt)`, de la 0 spre 100, dar un singur cadru a durat 0,2 s. Unde ajunge x?',
   [num('a', 'x', 100)], '`8 · 0,2 = 1,6`; ce face `min`?', '`step = min(1, 1,6) = 1`: sare direct în țintă, fără să o depășească.')
tc(419, 'Shake', 'ușoară', 'După un atac, `shakeTimer = 0,6`. În cadrul în care a scăzut la 0,52, apoi în cel în care e 0,49, ce unghi (în radiani) are cartea?',
   [num('a', 'la 0,52', 0.15), num('b', 'la 0,49', -0.15)], '`(int)(shakeTimer · 20) % 2 == 0` → `0,15`, altfel `-0,15`.', '`(int)10,4 = 10` par → `0,15`; `(int)9,8 = 9` impar → `-0,15`.')
tc(420, 'Timer-ul', 'ușoară', INTRO + 'Bara timer-ului are lățimea maximă `timerW = cardW`. Au mai rămas 12 s din 30. Cât de lată e bara galbenă?',
   [num('w', 'lățimea', _cw * 12 / 30, tol=0.01)], '`width = timerW · turnTimer / turnTime`.', f'`64,512 · 12 / 30 = {n(_cw * 12 / 30, 3)}`.')
tc(421, 'Săgeata', 'medie', 'Cartea selectată are centrul în `(600, 295,2)`, cursorul e în `(700, 495,2)`. Ce lungime și ce unghi (în grade) dă `DrawArrow`?',
   [num('l', 'lungimea', 223.607, tol=0.01), num('a', 'unghiul (grade)', 63.435, tol=0.05)],
   '`length = √(dx² + dy²)`, `angle = atan2(dy, dx)`.', '`d = (100, 200)`, `l = √50000 ≈ 223,61`, `θ = atan2(200, 100) ≈ 63,43°` (1,107 rad).')
tc(422, 'Inima: un vârf', 'medie', '`CreateHeart`: `a = 0,38`, `offsetY = 0,875·a`, pentru `i` din 64: `θ = 2πi/64`, `r = a(1 - cos θ)`, vârful `(-r sin θ, r cos θ + offsetY)`. Ce coordonate are vârful pentru `i = 16`? Dar pentru `i = 32`?',
   [num('x1', 'x (i = 16)', -0.38, tol=0.001), num('y1', 'y (i = 16)', 0.3325, tol=0.001), num('x2', 'x (i = 32)', 0, tol=0.001), num('y2', 'y (i = 32)', -0.4275, tol=0.001)],
   '`i = 16` înseamnă `θ = π/2`, `i = 32` înseamnă `θ = π`.', '`θ = π/2`: `r = 0,38`, `(-0,38, 0,3325)`. `θ = π`: `r = 0,76`, `(0, -0,76 + 0,3325) = (0, -0,4275)`: vârful de jos.')
tc(423, 'De ce 0,875·a', 'grea', 'Înainte de deplasare, y-ul inimii e `a(1 - cos θ)·cos θ`. Care e y-ul maxim și cel minim (în funcție de `a = 1`) și ce deplasare centrează inima?',
   [num('M', 'y maxim (a = 1)', 0.25), num('m', 'y minim (a = 1)', -2), num('o', 'deplasarea (a = 1)', 0.875)],
   'Cu `c = cos θ ∈ [-1, 1]`, `y = c - c²`.', 'Maxim la `c = 1/2`: `1/4`; minim la `c = -1`: `-2`. Mijlocul: `(1/4 - 2)/2 = -0,875`, deci se adună `0,875·a`.')
tc(424, 'Sabia: vârfurile lamei', 'grea', '`CreateSword`: `r(θ) = 0,3 + 0,1·sin(3θ) / (1,05 + cos(2θ))`. Cât e r la `θ = π/2` și la `θ = 3π/2`?',
   [num('a', 'r(π/2)', -1.7, tol=0.001), num('b', 'r(3π/2)', 2.3, tol=0.001)],
   'Numitorul `1,05 + cos(2θ)` e aproape zero acolo.', '`cos π = -1`: numitorul `0,05`. `sin(3π/2) = -1`: `0,3 - 2 = -1,7`; `sin(9π/2) = 1`: `0,3 + 2 = 2,3`. De aici vârfurile lungi ale lamei.')
tc(425, 'Câte triunghiuri', 'medie', 'Cercul are 48 de segmente, inima și sabia 64, rombul 2 triunghiuri. Câte triunghiuri desenează `DrawCard` pentru simbolul și statisticile unei cărți Tank cu cost 4, ATK 3, HP 2 (fără chenar și fundal)?',
   [num('t', 'triunghiuri', 2 + 4 * 48 + 3 * 64 + 2 * 64)], 'Fiecare punct de mana e un cerc, de ATK o sabie, de HP o inimă.', '`2 + 4·48 + 3·64 + 2·64 = 514`.')
tc(426, 'Indicii evantaiului', 'ușoară', 'Câți indici au mesh-urile `circle` (48 de segmente) și `star` (10 puncte)? Ce indici are ultimul triunghi al cercului?',
   [num('c', 'indici cerc', 144), num('s', 'indici stea', 30), txt('u', 'ultimul triunghi (trei numere, separate prin virgulă)', '0,48,1')],
   'Triunghiul `i`: `0, i + 1, (i + 1) % n + 1`.', '`3 · 48 = 144`, `3 · 10 = 30`. Pentru `i = 47`: `0, 48, 48 % 48 + 1 = 1`: închide cercul.')
tc(427, 'Cristalele de mana', 'ușoară', 'Ești în runda ta 4 (`maxMana = 4`) și ai pus o carte Silence (cost 2). Câte cristale sunt albastre, albe și negre?',
   [num('a', 'albastre', 2), num('b', 'albe', 2), num('c', 'negre', 6)], 'Albastru dacă `i < mana`, alb dacă `i < maxMana`, altfel negru.', '`mana = 2`: 0–1 albastre, 2–3 albe, 4–9 negre.')
tc(428, 'Un atac cu Lifesteal', 'medie', 'Cartea ta Lifesteal 4/3 (ATK 4, HP 3) atacă o carte 2/5. Eroul tău are 25 HP. Ce HP au după atac cele două cărți și eroul tău?',
   [num('a', 'cartea ta', 1), num('b', 'cartea inamică', 1), num('h', 'eroul tău', 29)],
   'Damage simultan; Lifesteal: `owner.hp += attacker.atk`.', 'A ta `3 - 2 = 1`, a lui `5 - 4 = 1`, eroul `25 + 4 = 29`.')
tc(429, 'Ambele mor', 'ușoară', 'Cartea ta 1/1 atacă o carte 4/1. Câte cărți ajung în zona `DEAD`?',
   [num('d', 'cărți moarte', 2)], 'Ambele primesc damage, apoi `RemoveDead` pe ambele liste.', 'A ta `1 - 4 < 0`, a lui `1 - 1 = 0`: amândouă.')
tc(430, 'Prima tură', 'ușoară', 'La începutul primei tale ture (după `Init` și `StartTurn`), câte cărți ai în mână, câte în pachet și câtă mana?',
   [num('h', 'în mână', 6), num('d', 'în pachet', 24), num('m', 'mana', 1)],
   '`FillDeck(30)`, 5 × `TakeFromDeck`, mana pusă pe 0, apoi `StartTurn` (+1 mana, +1 carte).', '5 + 1 = 6 în mână, 30 - 6 = 24 în pachet, `maxMana` și `mana` 1.')
tc(431, 'Șansa eroului', 'medie', 'Inamicul atacă fără Tank pe tabla ta, unde ai 3 cărți: `pick = rand() % (targets.size() + 1)`, iar `pick == targets.size()` înseamnă eroul. Ce probabilitate are eroul tău să fie ținta?',
   [num('p', 'probabilitatea', 0.25, tol=0.001)], '4 valori egal probabile.', '`rand() % 4` ∈ {0, 1, 2, 3}; 3 = eroul: `1/4`.')

# ------------------------------------------------------------------ grile on the code
tq(440, 'De ce glm::transpose', 'medie', 'De ce funcțiile din `transform2D.h` întorc `glm::transpose(glm::mat3(...))`?',
   'GLM umple matricea pe coloane, iar matricele sunt scrise rând cu rând', ['ca să inverseze transformarea', 'pentru că OpenGL folosește vectori linie', 'ca rotația să fie în sens orar'],
   'Cum interpretează constructorul `mat3` cele 9 valori?', 'GLM e column-major: primele trei valori sunt prima coloană. Transpusa dă matricea de pe hârtie.')
tq(441, 'Ordinea din DrawRect', 'medie', '`DrawRect` calculează `parent · Translate(x, y) · Scale(w, h)`. Ce se aplică întâi pe vârfurile pătratului?',
   'scalarea', ['translația', 'parent', 'nu contează ordinea'], 'Vectori coloană: de la dreapta la stânga.', 'Întâi `S`, apoi `T`, la urmă `parent` (rotația cărții).')
tq(442, 'Rotația cărții', 'medie', 'Ce matrice rotește o carte în jurul centrului ei `c`?',
   'T(c) · R(α) · T(-c)', ['R(α) · T(c)', 'T(-c) · R(α) · T(c)', 'R(α)'], 'Centrul trebuie adus în origine primul.', '`T(-c)` se aplică primul (e cel mai din dreapta), apoi rotația, apoi `T(c)`.')
tq(443, 'Click stânga', 'medie', 'De ce `IsLeftClick` verifică `button == 1`?',
   'framework-ul trimite o mască de biți, iar butonul stâng (GLFW 0) setează bitul 0', ['GLFW numerotează butoanele de la 1', 'butonul drept are valoarea 0', '1 e codul ASCII al click-ului'],
   'Vezi `pressEvent = mouseButtonAction & mouseButtonStates`.', '`SET_BIT(item, 0)` dă `1 << 0 = 1`; dreptul ar da 2.')
tq(444, 'De unde vine y-ul mouse-ului', 'ușoară', 'De ce `OnMouseMove` calculează `cursorY = screenH - mouseY · screenH / res.y`?',
   'fereastra are originea sus-stânga cu y în jos, scena are originea jos-stânga', ['ca să inverseze axa x', 'pentru proiecția perspectivă', 'pentru că mouse-ul e în coordonate normalizate'],
   'Unde e originea fiecăruia?', 'Conversia întoarce axa y și scalează după rezoluția curentă.')
tq(445, 'Testul de adâncime', 'medie', 'De ce funcționează tema cu `glDisable(GL_DEPTH_TEST)` și cartea trasă apare deasupra?',
   'ordinea de desen decide: ce e desenat mai târziu acoperă, iar cartea trasă e desenată ultima', ['cartea trasă are z mai mare', 'shader-ul sortează după mărime', 'camera ortografică ignoră ordinea'],
   'Toate formele au z = 0.', 'Algoritmul pictorului: în `Update`, cartea cu `isDragged` e desenată după toate celelalte.')
tq(446, 'Culoarea mesh-urilor', 'ușoară', 'Toate formele din `shapes.cpp` au vârfuri albe. De ce inimile apar roșii?',
   '`RenderMesh2D(mesh, matrice, culoare)` folosește shader-ul Color, care ignoră culoarea vârfurilor', ['culoarea se schimbă în InitFromData', 'roșul vine din fundalul cărții', 'shader-ul înmulțește alb cu roșul fundalului'],
   'Ce face al treilea parametru?', 'Shader-ul primește culoarea ca uniformă și colorează tot mesh-ul.')
tq(447, 'Dreptunghiul plin', 'medie', '`CreateRectangle` cu `fill = true` are indicii `0, 1, 2, 3, 0, 2`. Ce desenează?',
   'două triunghiuri: (0, 1, 2) și (3, 0, 2)', ['un patrulater cu GL_QUADS', 'un contur închis', 'șase puncte'], 'Modul implicit e GL_TRIANGLES.', 'Câte 3 indici fac un triunghi; diagonala comună e 0–2.')
tq(448, 'Evantaiul', 'medie', 'Pentru cerc, triunghiul `i` are indicii `0, i + 1, (i + 1) % segments + 1`. Ce rol are `% segments`?',
   'ultimul triunghi se leagă de primul vârf de pe cerc', ['evită vârfurile duplicate din centru', 'inversează sensul triunghiurilor', 'face cercul să înceapă de sus'],
   'Ce dă pentru i = segments - 1?', '`segments % segments + 1 = 1`: închide cercul; fără el, indicele `segments + 1` nu ar exista.')
tq(449, 'De unde pornește evantaiul inimii', 'grea', 'Evantaiul inimii pornește din vârful `(0, offsetY)`. Ce punct al curbei e acesta?',
   'polul cardioidei (r = 0), adică scobitura de sus', ['vârful de jos al inimii', 'centrul de greutate al inimii', 'un punct din afara inimii'],
   'Pentru ce θ e r = 0?', 'La `θ = 0`, `r = 0`: punctul `(0, offsetY)` e cuspida. O curbă polară cu r ≥ 0 e stelată față de pol, deci evantaiul o acoperă.')
tq(450, 'Animația de translație', 'medie', 'Ce fel de mișcare dă `x += (targetX - x) · min(1, 8·dt)`?',
   'rapidă la început și încetinind lin la sosire, fără să depășească ținta', ['cu viteză constantă', 'care accelerează până la țintă', 'care oscilează în jurul țintei'],
   'Ce fracțiune din distanță se parcurge la fiecare cadru?', 'O fracțiune fixă din distanța rămasă: scădere exponențială (ease-out).')
tq(451, 'Cine mută cărțile', 'medie', 'Ce face `ArrangeZone`?',
   'calculează doar țintele (targetX, targetY) ale cărților din zonă; mișcarea o face Update', ['mută instantaneu cărțile pe pozițiile noi', 'sortează cărțile după cost', 'șterge cărțile moarte'],
   'Ce câmpuri scrie?', 'Scrie țintele; interpolarea din `Update` apropie poziția curentă de ele, de aceea toate reorganizările sunt animate.')
tq(452, 'Ordinea relativă', 'ușoară', 'Cum păstrează `ArrangeZone` ordinea relativă a cărților rămase în mână?',
   'parcurge vectorul în ordine și dă locul k doar cărților din zonă, crescând k', ['sortează după targetX', 'reține un index separat pentru fiecare carte', 'nu o păstrează'],
   'Contorul `k`.', 'Cărțile nu își schimbă locul în vector; `k` le numerotează în aceeași ordine.')
tq(453, 'O carte abia pusă', 'ușoară', 'De ce o carte pusă în runda curentă nu are chenar verde (nu poate ataca)?',
   'CanAttack cere card.round < round (în afară de Charge)', ['hasAttacked e true la plasare', 'nu e încă în zona BOARD', 'mana a ajuns la 0'],
   'Ce reține `PlayCard`?', '`PlayCard` pune `round` = runda proprietarului; abia în runda următoare `card.round < round`.')
tq(454, 'Tank', 'medie', 'Inamicul are pe tablă un Tank. Ce poți ataca?',
   'doar cărțile Tank ale inamicului', ['orice carte, dar nu eroul', 'doar eroul', 'orice, Tank-ul doar reduce damage-ul'],
   'Variabila `ok` din `OnMouseBtnPress`.', 'Cu `ok == 1`, țintele permise sunt doar cele cu `EFFECT_TANK`, iar atacul eroului e blocat.')
tq(455, 'Silence', 'medie', 'Ce schimbă Silence la cartea țintă?',
   'efectul devine EFFECT_NONE, dar tipul (culoarea și simbolul) rămâne', ['cartea e distrusă', 'tipul devine NORMAL', 'atacul ei devine 0'],
   '`effect` și `type` sunt câmpuri separate.', 'Doar `effect` se schimbă: cartea arată la fel, dar nu mai protejează și nu mai fură viață.')
tq(456, 'Cărțile moarte', 'medie', 'De ce `RemoveDead` nu face `erase` din vector?',
   'ca referințele Card& folosite în Attack să rămână valide; cartea e doar marcată DEAD', ['erase nu există pentru vector', 'ca să poată fi înviate', 'pentru că vectorul e const'],
   'Ce s-ar întâmpla cu `attacker` după un `erase`?', 'Cu `erase`, elementele de după s-ar muta și referințele ar indica alte cărți.')
tq(457, 'Parametrul player', 'grea', 'În `StartTurn(Player& player, ...)`, apelată ca `StartTurn(enemy, enemyDeck, enemyCards)`, ce modifică `player.mana = player.maxMana`?',
   'mana inamicului: parametrul îl ascunde pe membrul player', ['mana jucătorului (membrul clasei)', 'ambele', 'nimic, e o copie'],
   'Shadowing.', 'Numele parametrului acoperă membrul; e o referință la `enemy`.')
tq(458, 'Inamicul', 'medie', 'Ce face `EnemyTurn` când n-are nicio carte selectată, are loc pe tablă și o carte pe care și-o permite?',
   'o pune pe tablă (o mișcare), iar atacurile vin după ce nu mai are ce pune', ['atacă imediat cu toate cărțile', 'termină tura', 'selectează un atacator'],
   'Ordinea testelor.', 'Prioritățile: atac cu cartea selectată > plasare > selectarea unui atacator > `EndTurn`. Câte o mișcare pe secundă.')
tq(459, 'Timpul expirat', 'ușoară', 'Ce se întâmplă când `turnTimer` ajunge la 0?',
   'se apelează EndTurn, ca la apăsarea butonului', ['jocul se termină', 'jucătorul pierde viață', 'timer-ul repornește în aceeași tură'],
   '`UpdateTimer`.', 'Cerința din enunț: butonul de terminare „se apasă singur”.')
tq(460, 'Plasare fără mana', 'medie', 'Tragi pe tablă o carte de 3 mana când ai 2. Ce se întâmplă?',
   'o poți prinde, dar la eliberare se întoarce animat în mână', ['nu o poți prinde deloc', 'se pune și mana devine -1', 'se pune, dar nu poate ataca'],
   'Unde e verificată mana?', 'Mana e verificată abia în `OnMouseBtnRelease`; plasarea invalidă cheamă `ArrangeZone(HAND)`.')
tq(461, 'Pachetul desenat', 'ușoară', 'Cum e desenat pachetul de cărți?',
   'cel mult 3 dreptunghiuri decalate, câte rămân în pachet până la 3', ['un singur dreptunghi, mereu', 'câte un dreptunghi pentru fiecare carte', 'un text cu numărul de cărți'],
   '`min(3, deck.size())`.', 'Teancul are 3 straturi; când rămân 2 cărți se văd 2, iar pachetul gol dispare.')
