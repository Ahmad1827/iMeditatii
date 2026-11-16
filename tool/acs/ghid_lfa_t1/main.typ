#import "tpl.typ": *
#show: ghid

// ------------------------------------------------------------------ copertă
#v(3cm)
#text(13pt, fill: gri)[Limbaje Formale și Automate · seminar]
#v(4pt)
#text(30pt, weight: "bold", fill: albastru)[Testul 1 · Limbaje regulate]
#v(2pt)
#text(15pt)[Tot ce trebuie să știi: teorie, metode, probleme rezolvate pas cu pas și un test simulat cu barem]
#v(1cm)
#line(length: 100%, stroke: 1pt + albastru)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
  [
    *Ce găsești aici*
    - definițiile și teoremele de care ai nevoie, în notația cursului (Lewis & Papadimitriou);
    - câte o metodă clară pentru fiecare item al testului;
    - peste 50 de probleme rezolvate, cu automatele desenate;
    - fișa de recapitulare a seminarului, rezolvată integral;
    - un test simulat de 12 puncte, cu barem;
    - o foaie de memorat pentru ultima seară.
  ],
  [
    *Cum îl folosești*
    + Citește capitolul 0: ce se cere la fiecare item.
    + Pentru fiecare capitol: citește chenarele colorate, apoi *acoperă rezolvările* și încearcă singur problemele.
    + Rezolvă fișa (cap. 11) și testul simulat (cap. 12) pe hârtie, cu ceasul pornit: 50 de minute.
    + În ultima seară: doar foaia de memorat (cap. 13).
  ],
)
#v(1fr)
#text(9pt, fill: gri)[Ghid scris pentru iMeditații · https://ahmad1827.github.io · structura testului după anunțul seminarului (P1 închidere 2p, P2 ER/AF 2p, P3 conversii 2,5p, P4 proprietăți algoritmice 1,5p, P5 lema de pompare 2p, P6 bonus 2p). Notații: Lewis & Papadimitriou, _Elements of the Theory of Computation_, cap. 1–2.]

#pagebreak()
#outline(title: [Cuprins], depth: 2, indent: 1.2em)

#include "c0.typ"
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
