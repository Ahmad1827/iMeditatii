#import "tpl.typ": *

= Formele: `object2D` și `shapes`

Toate formele sunt mesh-uri create *o dată* în `Init` și puse în `meshes` sub un nume:

#cod("Tema1.cpp", 43, 52)

În desenele de mai jos: pătratul punctat e $[-0.5, 0.5]^2$, punctele roșii sunt vârfurile (cu indicele lor), triunghiurile alternează două nuanțe ca să se vadă unde se termină fiecare.

== Pătratul și dreptunghiul (`object2D.cpp`)

#cod("object2D.cpp", 20, 50)

Patru vârfuri, în ordine *trigonometrică*: stânga-jos (0), dreapta-jos (1), dreapta-sus (2), stânga-sus (3).

- *Plin* (`fill = true`): indicii devin `0, 1, 2, 3, 0, 2`, citiți cu `GL_TRIANGLES` (modul implicit) ca *două triunghiuri*: $(0, 1, 2)$ și $(3, 0, 2)$, care împreună acoperă pătratul pe diagonala 0–2.
- *Contur* (`fill = false`): `SetDrawMode(GL_LINE_LOOP)` cu indicii `0, 1, 2, 3`: linii 0–1–2–3 și înapoi la 0.

Tu folosești doar pătratul *plin, de latură 1, cu colțul în origine*, sub numele `"square"`. Din el iese *orice* dreptunghi prin `DrawRect` (capitolul 3): fundaluri, cărți, chenare, butonul, timer-ul, ecranul final.

#grid(columns: (1fr, 1fr, 1fr, 1fr), gutter: 6pt,
  align(center)[#deseneaza-mesh("square", size: 2.6, vs: none) #text(9pt)[`square` (colț în origine)]],
  align(center)[#deseneaza-mesh("triangle", size: 2.6) #text(9pt)[`triangle`: 1 triunghi]],
  align(center)[#deseneaza-mesh("diamond", size: 2.6) #text(9pt)[`diamond`: 2 triunghiuri]],
  align(center)[#deseneaza-mesh("plus", size: 2.6) #text(9pt)[`plus`: 4 triunghiuri]],
)

== Formele simple

#cod("shapes.cpp", 12, 42)

*Plusul* sunt *două dreptunghiuri* suprapuse: unul orizontal ($[-0.5, 0.5] × [-t, t]$, vârfurile 0–3) și unul vertical ($[-t, t] × [-0.5, 0.5]$, vârfurile 4–7), cu grosimea $2t = 0.3$. Fiecare dreptunghi = 2 triunghiuri: $(0,1,2), (0,2,3)$ și $(4,5,6), (4,6,7)$. Pătratul din mijloc e desenat de două ori, ceea ce nu se vede (aceeași culoare).

*Triunghiul* (`CreateTriangle`): un singur triunghi, baza jos pe $y = -0.5$, vârful în $(0, 0.5)$. *Rombul* (`CreateDiamond`): 4 vârfuri pe axe (sus, dreapta, jos, stânga), două triunghiuri $(0, 3, 2)$ și $(0, 2, 1)$ tăiate pe diagonala verticală 0–2. E simbolul Tank și forma cristalelor de mana.

== Evantaiul (triangle fan): cercul și steaua

#cod("shapes.cpp", 123, 147)

Cercul e aproximat de un *poligon regulat* cu `segments = 48` de laturi. Vârful 0 e centrul, vârfurile $1..n$ sunt pe cerc la unghiurile $2 pi i \/ n$, cu raza 0.5 (diametrul 1). Triunghiurile:

$ (0, i + 1, (i + 1) mod n + 1), quad i = 0, ..., n - 1 $

Pentru $i = n - 1$, al treilea indice e $n mod n + 1 = 1$: ultimul triunghi *închide* cercul, legând ultimul vârf de primul. Fără `% segments`, indicele ar fi $n + 1$, care nu există.

#grid(columns: (1fr, 1fr, 1fr), gutter: 6pt,
  align(center)[#deseneaza-mesh("circle12", size: 3, triunghiuri: false) #text(9pt)[același cod cu 12 segmente]],
  align(center)[#deseneaza-mesh("circle", size: 3, numere: false) #text(9pt)[`circle`: 48 de segmente]],
  align(center)[#deseneaza-mesh("star", size: 3) #text(9pt)[`star`: 10 vârfuri pe contur]],
)

#cod("shapes.cpp", 91, 120)

*Steaua* e tot un evantai din centru, doar că raza *alternează*: vârfurile pare pe conturul exterior ($r = 0.5$, cele 5 colțuri), cele impare pe cel interior ($r = 0.2$, „scobiturile”). Primul unghi e $pi \/ 2$, deci primul colț e sus. 10 vârfuri pe contur → 10 triunghiuri → o stea cu 5 colțuri.

#idee[Evantaiul din centru funcționează pentru orice formă *stelată față de centru* (orice rază dusă din centru taie conturul o singură dată). Cercul, steaua, inima și sabia sunt toate așa, de aceea folosesc același tipar de indici.]

== Săgeata

#cod("shapes.cpp", 149, 176)

Corpul e dreptunghiul $[0, 0.75] × [-0.15, 0.15]$ (vârfurile 0–3, două triunghiuri), iar vârful săgeții e triunghiul $(0.75, -0.5), (1, 0), (0.75, 0.5)$ (vârfurile 4–6). Coada e în origine, vârful în $(1, 0)$: tocmai ca o scalare pe $x$ cu lungimea $ell$ să o facă exact de lungimea dorită (capitolul 3).

#align(center)[#deseneaza-mesh("arrow", size: 4)]

== Inima: cardioida $r(theta) = a(1 - cos theta)$

#cod("shapes.cpp", 178, 205)

Enunțul propune formula polară a *cardioidei* $r(theta) = a(1 - cos theta)$. În forma ei standard, $(r cos theta, r sin theta)$, cardioida are vârful ascuțit (cuspida) în origine, îndreptat spre dreapta, și lobul mare spre stânga. Tu scrii punctul ca

$ (x, y) = (-r sin theta, quad r cos theta + "offsetY") $

adică punctul standard *rotit cu 90°* în sens trigonometric ($(u, v) arrow.r.bar (-v, u)$): cuspida ajunge *sus* (scobitura inimii), iar lobul, care era la $theta = pi$ în $(-2a, 0)$, ajunge *jos*, în $(0, -2a)$: vârful inimii.

*De ce `offsetY = 0.875a`.* Înainte de deplasare, $y = a(1 - cos theta) cos theta$. Cu $c = cos theta in [-1, 1]$, $y(c) = a(c - c^2)$ e maximă la $c = 1\/2$: $y_max = a\/4$, și minimă la $c = -1$: $y_min = -2a$. Mijlocul intervalului e $(a\/4 - 2a)\/2 = -0.875a$. Adunând $0.875a$, inima ajunge *centrată vertical* în origine: $y in [-1.125a, 1.125a]$.

*De ce $a = 0.38$.* Pe orizontală, $|x| = a(1 - cos theta) sin theta$ e maxim la $theta = 2pi\/3$: $a dot 1.5 dot sqrt(3)\/2 approx 1.299a$. Cu $a = 0.38$: lățimea e $2 dot 1.299 dot 0.38 approx #f2(g.heart_extent.at(1) * 2)$ și înălțimea $2.25 dot 0.38 approx #f2(g.heart_extent.at(3) * 2)$: inima încape în pătratul unitate, ca toate celelalte simboluri.

*De ce evantaiul pornește din $(0, "offsetY")$.* E chiar *polul* curbei ($r = 0$), cuspida. O curbă polară cu $r(theta) >= 0$ e stelată față de pol, deci triunghiurile $("pol", P_i, P_(i+1))$ o acoperă exact. 64 de segmente → 64 de triunghiuri, 192 de indici.

#grid(columns: (1fr, 1fr), gutter: 6pt,
  align(center)[#deseneaza-mesh("heart16", size: 4, triunghiuri: false) #text(9pt)[inima cu 16 segmente: evantaiul din cuspidă (vârful 0)]],
  align(center)[#deseneaza-mesh("heart", size: 4, numere: false) #text(9pt)[`heart`, 64 de segmente, cum apare în joc]],
)

== Sabia: $r(theta) = a + b dot sin(n theta) \/ (c + cos(m theta))$

#cod("shapes.cpp", 208, 241)

Parametrii tăi: $a = 0.3$, $b = 0.1$, $c = 1.05$, $n = 3$, $m = 2$. Partea interesantă e numitorul: $c + cos(2 theta)$ ajunge la $1.05 - 1 = 0.05$ pentru $theta = pi\/2$ și $3pi\/2$, deci fracția explodează acolo și dă *vârfurile lungi*:

#tabel(
  columns: 3,
  [*i (din 64)*], [*θ*], [*r(θ)*],
  ..g.sword_r.map(x => (str(x.at(0)), str(x.at(1)), str(x.at(2)))).flatten(),
)

La $theta = pi\/2$, $sin(3 theta) = -1$ și $r = 0.3 - 0.1\/0.05 = -1.7$ (rază *negativă*: punctul iese în direcția opusă, adică tot în jos); la $theta = 3pi\/2$, $sin(3 theta) = 1$ și $r = 0.3 + 2 = 2.3$. Restul conturului rămâne aproape de $r approx 0.3$ (garda și mânerul). Apoi:

$ (x, y) = (0.9 dot r cos theta, quad -0.38 dot r sin theta - 0.385) $

- `scaleX = 0.9`, `scale = 0.38`: turtește forma pe verticală (cele două vârfuri de 1.7 și 2.3 ar fi mult prea lungi);
- semnul minus de la $y$ o oglindește față de $O x$, ca lama să fie *în sus*;
- `offsetY = -0.385` o centrează: rezultatul ocupă $x in [#g.meshes.sword.bbox.at(0), #g.meshes.sword.bbox.at(1)]$, $y in [#g.meshes.sword.bbox.at(2), #g.meshes.sword.bbox.at(3)]$, adică încape în pătratul unitate.

#grid(columns: (1fr, 1fr), gutter: 6pt,
  align(center)[#deseneaza-mesh("sword16", size: 4, triunghiuri: false) #text(9pt)[sabia cu 16 segmente]],
  align(center)[#deseneaza-mesh("sword", size: 4, numere: false) #text(9pt)[`sword`, 64 de segmente]],
)

#prof[„Cum ai făcut inima și sabia?” Din formulele polare din enunț: pentru $i = 0..63$ calculez $theta = 2 pi i \/ 64$, raza $r(theta)$, apoi punctul $(r cos theta, r sin theta)$ (la inimă rotit cu 90°, la sabie turtit și oglindit), plus un vârf central; triunghiurile sunt un evantai din vârful central. Coeficienții (0.38, 0.875a, 0.9, −0.385) sunt aleși ca forma să fie centrată în origine și să încapă în pătratul unitate, ca s-o pot scala cu `Scale(size, size)` la fel ca pe celelalte.]
