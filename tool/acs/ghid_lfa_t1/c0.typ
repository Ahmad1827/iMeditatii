#import "tpl.typ": *

= Testul pe scurt

Testul durează *50 de minute* și are 6 itemi. Nota maximă e 12; 10 puncte îți dau tot punctajul de seminar pentru limbaje regulate (1,25 p), iar ce trece de 10 se adună la final ca bonus. Testul e _closed book_: tot ce e în ghidul ăsta trebuie să fie în cap.

#tabel(
  columns: (auto, 1fr, auto, auto, auto),
  [*Item*], [*Ce se cere de obicei*], [*Puncte*], [*Timp*], [*Capitol*],
  [P1], [Proprietăți de închidere: „arătați că $L'$ e regulat dacă $L$ e regulat”, adevărat/fals cu contraexemplu], [2], [8 min], [8],
  [P2], [Reprezentare: ER și automat (AFD/AFN) pentru un limbaj descris în cuvinte, sau invers], [2], [8 min], [2, 3],
  [P3], [Conversii: ER → AFN, AFN → AFD (submulțimi), AF → ER (eliminarea stărilor), minimizare], [2,5], [12 min], [4–7],
  [P4], [Proprietăți algoritmice: un algoritm care decide ceva despre $L(M)$ (vid, finit, incluziune…)], [1,5], [6 min], [9],
  [P5], [Lema de pompare: demonstrați că un limbaj nu e regulat], [2], [8 min], [10],
  [P6], [Bonus: o întrebare nouă, care verifică dacă ai _înțeles_ definițiile], [2], [8 min], [11],
)

== Ce trebuie să știi pentru fiecare item

#grid(columns: (1fr, 1fr), gutter: 12pt,
  petest[*P1 · închidere.* Lista operațiilor sub care limbajele regulate sunt închise, plus *construcția* pentru fiecare (automat produs, inversarea finalelor, inversarea săgeților, tranziții $e$ noi). Trei contraexemple clasice pentru „fals”.],
  petest[*P2 · ER / AF.* Să traduci o descriere în cuvinte într-o ER și într-un AFD. Metoda: „ce trebuie să țin minte despre ce am citit până acum?” = stările.],
  petest[*P3 · conversii.* Patru algoritmi mecanici, scriși ordonat, cu tabel: Thompson / construcțiile din curs, determinizarea cu $e$-închideri, eliminarea stărilor, minimizarea prin partiții.],
  petest[*P4 · algoritmic.* Reduci totul la două întrebări pe graful automatului: _se ajunge la o stare finală?_ (vid) și _există un ciclu pe un drum util?_ (finit).],
  petest[*P5 · pompare.* Șablonul de demonstrație pe 5 rânduri. Alegi bine $w$, acoperi *toate* descompunerile, alegi $i$.],
  petest[*P6 · bonus.* Definițiile exacte (AFD = $delta$ totală!), cazuri limită ($e$, $emptyset$, $Sigma^*$), Myhill–Nerode.],
)

== Plan de studiu (4 zile)

#tabel(
  columns: (auto, 1fr),
  [*Ziua*], [*Ce faci*],
  [1], [Cap. 1–3: notații, ER, AFD. Fă toate problemele din cap. 2 și 3 fără să te uiți la rezolvare.],
  [2], [Cap. 4–7: cele patru conversii. Fiecare algoritm de cel puțin două ori, de mână, pe hârtie.],
  [3], [Cap. 8–10: închidere, algoritmi, pompare. Învață pe de rost șablonul de pompare și lista de închideri.],
  [4], [Cap. 11–12: fișa seminarului și testul simulat, cronometrat. Apoi recitește capcanele (chenarele roșii).],
)

== Notații folosite

Ghidul folosește notațiile cursului (Lewis & Papadimitriou):

- $e$ = șirul vid (în alte surse $epsilon$ sau $lambda$); $|w|$ = lungimea lui $w$; $|w|_a$ = numărul de apariții ale lui $a$ în $w$.
- AFD: $M = (K, Sigma, delta, s, F)$, cu $K$ stările, $Sigma$ alfabetul, $delta : K times Sigma -> K$ funcția de tranziție (*totală*), $s$ starea inițială, $F subset.eq K$ stările finale.
- AFN: $M = (K, Sigma, Delta, s, F)$, cu $Delta$ o relație *finită*, $Delta subset.eq K times Sigma^* times K$.
- $overline(L) = Sigma^* without L$ (complementul), notat uneori și $complement L$; $L^R$ = oglinditul.
- În desene: săgeata fără sursă arată starea inițială, cercul dublu o stare finală, eticheta $e$ o tranziție care nu citește nimic.
