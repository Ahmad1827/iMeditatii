#import "tpl.typ": *
#show: ghid

// ------------------------------------------------------------------ copertă
#v(2.6cm)
#text(13pt, fill: gri)[Arhitectura Procesoarelor Moderne · laborator]
#v(4pt)
#block(par(justify: false, text(30pt, weight: "bold", fill: albastru)[Lucrarea 2 · Front-end-ul unui procesor RISC-V]))
#v(2pt)
#par(justify: false)[#text(15pt)[Etapele IF și ID, explicate până la ultimul bit: fiecare modul, fiecare linie de cod, fiecare instrucțiune codificată și fiecare ciclu de ceas din simulare]]
#v(1cm)
#line(length: 100%, stroke: 1pt + albastru)
#v(4pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
  [
    *Ce găsești aici*
    - imaginea de ansamblu: ISA, RV32I, pipeline-ul în 5 etape, ce e „front-end-ul”;
    - Verilog-ul de care ai nevoie, explicat de la zero;
    - fiecare cerință (1a–8), cu codul tău, linie cu linie, și de ce e scris așa;
    - cele 7 instrucțiuni codificate bit cu bit și fișierul `code_stud.mem`;
    - simularea, ciclu cu ciclu, comparată cu Fig. 4;
    - greșelile tipice, întrebările de la prezentare, exerciții rezolvate și o foaie de memorat.
  ],
  [
    *Cum îl folosești*
    + Capitolele 0–2: contextul și Verilog-ul. Dacă le știi, sari peste.
    + Capitolele 3–7: cerințele, în ordinea în care construiești procesorul.
    + Capitolul 8: deschide simularea în Vivado și urmărește tabelul rând cu rând.
    + Înainte de prezentare: capitolele 9–10 (greșeli, întrebări) și foaia de memorat (cap. 12).
  ],
)
#v(1fr)
#text(9pt, fill: gri)[Ghid scris pentru iMeditații · https://ahmad1827.github.io · după enunțul „Lucrarea 2” (RISC-V, IF + ID) și codul folosit la laborator. Toate valorile din tabele (codificări, imediate, forme de undă) sunt calculate de un model al circuitului și verificate pe Fig. 4 din enunț. Bibliografie: Patterson & Hennessy, _Computer Organization and Design, RISC-V Edition_ (2018), cap. 4; Waterman & Asanović, _The RISC-V Instruction Set Manual, Vol. I_ v2.2 (2017), cap. 2 și pp. 104–107.]

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
