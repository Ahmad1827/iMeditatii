#import "tpl.typ": *
#show: ghid

// ------------------------------------------------------------------ copertă
#v(3cm)
#text(13pt, fill: gri)[Limbaje Formale și Automate · seminar]
#v(4pt)
#text(30pt, weight: "bold", fill: albastru)[Testul 1 · Limbaje regulate]
#v(2pt)
#text(17pt)[Culegere de exerciții rezolvate]
#v(6pt)
#text(12pt)[Toate tipurile de exerciții de la test, pe itemi, cu rezolvări explicate pas cu pas, automatele desenate și baremul]
#v(1cm)
#line(length: 100%, stroke: 1pt + albastru)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
  [
    *Ce găsești aici*
    - #context nrprob.final().first() de exerciții rezolvate, grupate pe cei șase itemi ai testului;
    - automate desenate pentru fiecare construcție;
    - tabelele algoritmilor (submulțimi, eliminare, minimizare);
    - demonstrațiile cu lema de pompare scrise ca pe foaie;
    - grilele din testele și examenele vechi, explicate;
    - două teste simulate de 50 de minute, cu barem.
  ],
  [
    *Cum o folosești*
    + Citește capitolul 0: structura testului și cum lucrezi.
    + La fiecare exercițiu: *acoperă rezolvarea* și încearcă singur.
    + Reia exercițiile greșite după două zile.
    + La final: testele simulate din capitolul 8, cronometrate.
  ],
)
#v(1fr)
#text(9pt, fill: gri)[Culegere scrisă pentru iMeditații · https://ahmad1827.github.io · structura testului după anunțul seminarului (P1 închidere 2p, P2 ER/AF 2p, P3 conversii 2,5p, P4 proprietăți algoritmice 1,5p, P5 lema de pompare 2p, P6 bonus 2p). Notații: Lewis & Papadimitriou, _Elements of the Theory of Computation_. Răspunsurile (automate, ER, demonstrații prin pompare) sunt verificate automat cu `tool/acs/culegere_lfa_t1/check.py`.]

#pagebreak()
#outline(title: [Cuprins], depth: 2, indent: 1.2em)

#include "k0.typ"
#include "k1.typ"
#include "k2.typ"
#include "k3.typ"
#include "k4.typ"
#include "k5.typ"
#include "k6.typ"
#include "k7.typ"
#include "k8.typ"
