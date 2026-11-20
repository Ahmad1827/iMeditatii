#import "tpl.typ": *

= Transformările 2D

== Coordonate omogene

Un punct 2D $(x, y)$ se scrie ca vectorul coloană $(x, y, 1)^T$. Cu al treilea „1”, *și translația* devine o înmulțire cu matrice (fără el, translația ar fi o adunare, iar scalarea și rotația înmulțiri, și nu s-ar putea compune într-o singură matrice).

#grid(columns: (1fr, 1fr, 1fr), gutter: 8pt,
  [$ T(t_x, t_y) = mat(1, 0, t_x; 0, 1, t_y; 0, 0, 1) $],
  [$ S(s_x, s_y) = mat(s_x, 0, 0; 0, s_y, 0; 0, 0, 1) $],
  [$ R(theta) = mat(cos theta, -sin theta, 0; sin theta, cos theta, 0; 0, 0, 1) $],
)

$R(theta)$ rotește în sens *trigonometric* (invers acelor de ceas) pentru $theta > 0$, în jurul *originii*. $S$ scalează *față de origine*: un punct departe de origine se și deplasează.

== `transform2D.h` și de ce e acolo `glm::transpose`

#cod("transform2D.h", 9, 33)

GLM ține matricele *pe coloane* (column-major, ca OpenGL): constructorul `glm::mat3(a, b, c, d, e, f, g, h, i)` pune `a, b, c` în *prima coloană*, nu pe primul rând. Ai scris matricele „ca pe hârtie”, rând cu rând, deci GLM le-a citit transpuse; `glm::transpose` le întoarce la forma corectă. Rezultatul e exact matricea de pe hârtie: de exemplu, în `Translate`, $t_x$ ajunge în coloana a treia, rândul întâi (în GLM: `m[2][0]`, coloana 2, rândul 0). E același lucru ca în laboratorul 3.

#capcana[Fără `transpose`, `Translate` ar pune $t_x, t_y$ pe *ultimul rând*, iar înmulțirea cu $(x, y, 1)^T$ n-ar mai muta nimic (ar strica doar coordonata omogenă). `RenderMesh2D` citește translația din `mm[2][0]` și `mm[2][1]`, adică din a treia coloană.]

== Compunerea: se citește de la dreapta la stânga

Cu vectori coloană, $M = A dot B dot C$ aplicat unui punct $p$ înseamnă $A(B(C p))$: *întâi* $C$, apoi $B$, la urmă $A$. Ordinea contează, pentru că înmulțirea de matrice nu e comutativă.

=== `DrawRect`: pătratul unitate devine orice dreptunghi

#cod("Tema1.cpp", 562, 568)

Mesh-ul `"square"` e pătratul $[0, 1]^2$ (colțul stânga-jos în origine, din `CreateSquare(..., glm::vec3(0, 0, 0), 1, ...)`). Matricea finală e $"parent" dot T(x, y) dot S(w, h)$:

+ $S(w, h)$: pătratul devine dreptunghiul $[0, w] × [0, h]$ (colțul stânga-jos rămâne în origine, pentru că scalarea e față de origine);
+ $T(x, y)$: îl mută cu colțul stânga-jos în $(x, y)$;
+ `parent` (implicit identitatea): o transformare a „părintelui”, la tine rotația cărții în timpul shake-ului.

Dacă ai fi scris $T dot S$ invers ($S dot T$), translația ar fi fost și ea scalată: colțul ar fi ajuns în $(x w, y h)$.

=== Rotația în jurul centrului cărții

#cod("Tema1.cpp", 420, 422)

$ M_"rot" = T(c_x, c_y) dot R(alpha) dot T(-c_x, -c_y), quad (c_x, c_y) = (x + w/2, y + h/2) $

$R$ rotește doar în jurul originii. Ca să rotești în jurul centrului cărții: muți centrul în origine ($T(-c)$), rotești, îl duci înapoi ($T(c)$). Centrul rămâne fix: $M_"rot" dot c = c$. Aceeași matrice `rotation` e dată ca `parent` *tuturor* bucăților cărții (chenarul, fundalul, simbolul, statisticile), deci cartea se rotește *ca un întreg*, ca un nod părinte într-o ierarhie.

=== Simbolul de pe carte

#cod("Tema1.cpp", 442, 446)

Formele din `shapes.cpp` sunt *centrate în origine* și încap în pătratul $[-0.5, 0.5]^2$. $S("shapeSize")$ le face de mărimea dorită (35% din lățimea cărții), $T(x + w/2, y + h dot 0.25)$ le pune cu centrul pe mijlocul cărții, la un sfert din înălțime, iar `rotation` le rotește odată cu cartea.

#idee[De aceea formele sunt centrate în origine, iar pătratul are colțul în origine: o formă centrată se scalează „pe loc” și se poziționează după centru; dreptunghiul se poziționează după colț, cum sunt date și coordonatele `x, y` ale cărților (colțul stânga-jos).]

=== Săgeata: translație, rotație, scalare

#cod("Tema1.cpp", 534, 544)

Mesh-ul `arrow` merge pe axa $x$ de la $x = 0$ (coada) la $x = 1$ (vârful). Matricea $T(s_x, s_y) dot R(theta) dot S(ell, 0.6 dot "cardW")$:

+ $S(ell, ...)$: săgeata devine lungă exact cât distanța $ell = sqrt(d_x^2 + d_y^2)$ de la carte la cursor (și groasă cât 60% din lățimea unei cărți);
+ $R(theta)$, cu $theta = "atan2"(d_y, d_x)$: o îndreaptă spre cursor;
+ $T(s_x, s_y)$: îi pune coada în centrul cărții selectate.

Vârful, care era în $(1, 0)$, ajunge exact în cursor: $(s_x + ell cos theta, s_y + ell sin theta) = (s_x + d_x, s_y + d_y)$.

#capcana[`atan2(dy, dx)`, nu `atan(dy / dx)`: `atan` dă doar unghiuri în $(-90°, 90°)$ și împarte la zero pentru $d_x = 0$; `atan2` folosește semnele ambelor argumente și dă unghiul corect în toate cele patru cadrane.]
