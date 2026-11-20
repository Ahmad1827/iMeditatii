#import "tpl.typ": *
#show: ghid

// ------------------------------------------------------------------ copertă
#v(2.4cm)
#text(13pt, fill: gri)[Elemente de Grafică pe Calculator · tema 1]
#v(4pt)
#block(par(justify: false, text(30pt, weight: "bold", fill: albastru)[Tema 1 · Card Games: Hearthstone în OpenGL]))
#v(2pt)
#par(justify: false)[#text(15pt)[Tema ta explicată de la cap la coadă: framework-ul, fiecare fișier, fiecare funcție, fiecare matrice și fiecare animație, cu numerele reale pentru o fereastră de 1280 × 720]]
#v(1cm)
#line(length: 100%, stroke: 1pt + albastru)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
  [
    *Ce găsești aici*
    - enunțul pe scurt și baremul, cu locul din cod al fiecărei cerințe;
    - framework-ul (`SimpleScene`, mesh-uri, camera, coordonatele mouse-ului) explicat cât îți trebuie;
    - transformările 2D din `transform2D.h` și de ce se compun în ordinea aceea;
    - fiecare formă din `shapes.cpp` desenată, cu vârfurile și triunghiurile ei (inima și sabia, din formulele polare);
    - fiecare funcție din `Tema1.cpp`, linie cu linie;
    - animațiile, inamicul, o tură urmărită pas cu pas;
    - întrebări de la prezentare cu răspunsuri, exerciții rezolvate și o foaie de memorat.
  ],
  [
    *Cum îl folosești*
    + Capitolele 1–2: ce se cere și cum funcționează framework-ul.
    + Capitolele 3–5: structurile de date, formele, așezarea pe ecran.
    + Capitolele 6–10: desenarea, logica, mouse-ul, animațiile, inamicul. Ține codul deschis lângă.
    + Capitolul 11: o tură completă, cu numere.
    + Înainte de prezentare: capitolele 12–13 (întrebări, puncte slabe) și foaia de memorat (cap. 15).
  ],
)
#v(1fr)
#text(9pt, fill: gri)[Ghid scris pentru iMeditații · https://ahmad1827.github.io · după enunțul temei (ocw.cs.pub.ro/courses/egc/teme/2026/01, CC BY-SA 3.0) și codul temei (`src/lab_m1/Tema1`). Toate valorile numerice (poziții, dimensiuni, vârfuri, pași de animație) sunt calculate de un model în Python al codului (`tool/acs/egc_tema1_model.py`), pentru rezoluția implicită a framework-ului, 1280 × 720.]

#pagebreak()
#outline(title: [Cuprins], depth: 2, indent: 1.2em)

#include "c1.typ"
#include "c2.typ"
#include "c3.typ"
#include "c4.typ"
#include "c5.typ"
#include "c6.typ"
#include "c7.typ"
#include "c8.typ"
#include "c9.typ"
#include "c10.typ"
#include "c11.typ"
#include "c12.typ"
#include "c13.typ"
#include "c14.typ"
#include "c15.typ"
