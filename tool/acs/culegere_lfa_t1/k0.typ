#import "tpl.typ": *

= Cum folosești culegerea

#tabel(
  columns: (auto, 1fr, auto, auto, auto),
  [*Item*], [*Ce se cere*], [*Puncte*], [*Timp*], [*Capitol*],
  [P1], [Proprietăți de închidere: „arătați că $L'$ e regulat”, construcții pe automate, adevărat/fals cu contraexemplu], [2], [8 min], [4],
  [P2], [Reprezentare: AFD / AFN / ER pentru un limbaj descris în cuvinte, sau invers], [2], [8 min], [1, 2],
  [P3], [Conversii: ER → AFN, AFN → AFD, AF → ER, minimizare], [2,5], [12 min], [3],
  [P4], [Proprietăți algoritmice: un algoritm care decide ceva despre $L(M)$], [1,5], [6 min], [5],
  [P5], [Lema de pompare: un limbaj nu e regulat; clasificări], [2], [8 min], [6],
  [P6], [Bonus: definiții exacte, cazuri-limită, Myhill–Nerode], [2], [8 min], [7],
)

Testul are 50 de minute și nota maximă 12; 10 puncte dau tot punctajul de seminar pentru limbaje regulate (1,25 p), iar ce trece de 10 se păstrează ca bonus până la final. E closed book.

== Ce găsești aici

Culegerea are *doar exerciții*, fiecare cu rezolvarea completă: de ce se face așa, automatele desenate, tabelele algoritmilor, verificarea pe cuvinte și, unde e cazul, capcanele și baremul. Teoria e strânsă în chenarele albastre de la începutul fiecărui capitol (exact cât trebuie ca să rezolvi). Pentru teoria pe larg, vezi *ghidul de pregătire pentru Testul 1*, de pe aceeași pagină a site-ului.

Exercițiile vin din:
- fișa de recapitulare a seminarului (seminarele 1–4) și modelele de probleme scrise ale seminarului;
- testele de seminar din anii trecuți (Testul 1 din noiembrie 2023, Testul LR nr. 1 al altei grupe, testul de recuperare 2017–2018);
- examenele 2022–2025, partea de limbaje regulate (inclusiv rezolvările publicate, corectate unde era cazul);
- grilele de pe Moodle (testele și examenele), cu răspunsul explicat;
- exerciții noi, pe tiparele de mai sus, ca să acopere fiecare tip de întrebare.

Fiecare automat și fiecare ER dată ca răspuns a fost verificată automat: comparată cu enunțul pe toate cuvintele scurte (până la lungimea 9–12), iar fiecare demonstrație cu lema de pompare a fost verificată pentru toate împărțirile posibile, pentru valori mici ale lui $p$.

== Cum lucrezi

+ *Acoperă rezolvarea.* Citește enunțul, încearcă singur 3–5 minute, pe hârtie, abia apoi citește rezolvarea. Un exercițiu citit fără să fi încercat nu se reține.
+ *Scrie ca la test*: automatul desenat complet, tabelul algoritmului, justificarea în propoziții. La P1, P4 și P5 se punctează argumentul, nu doar răspunsul.
+ *Marchează* exercițiile greșite și reia-le după două zile.
+ În ultimele zile: cele două teste simulate din capitolul 8, cronometrate.

#petest[
  *Notații* (ale cursului, Lewis & Papadimitriou): $e$ = cuvântul vid; $|w|_a$ (sau $\#_a (w)$) = numărul de $a$ din $w$; $|w|_u$ = numărul de apariții ale lui $u$ (și suprapuse); $overline(L) = Sigma^* without L$; $L^R$ = oglinditul; AFD $(K, Sigma, delta, s, F)$ cu $delta$ totală; AFN $(K, Sigma, Delta, s, F)$ cu $Delta subset.eq K times Sigma^* times K$ finită. În desene: săgeata fără sursă arată starea inițială, cercul dublu o stare finală, $d$ e starea capcană.
]
