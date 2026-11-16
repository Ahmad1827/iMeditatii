#import "tpl.typ": *

= Din ER în automat (P3)

#teorema[Pentru orice ER $alpha$ există un AFN $M$ cu $L(M) = L(alpha)$. Demonstrația e constructivă, prin inducție pe structura lui $alpha$.]

== Construcțiile de bază

Cazurile de bază: pentru $emptyset$, o singură stare, nefinală. Pentru $a in Sigma$, două stări $i ->^a f$, cu $f$ finală.

Fie $M_1 = (K_1, Sigma, Delta_1, s_1, F_1)$ și $M_2 = (K_2, Sigma, Delta_2, s_2, F_2)$, cu stări disjuncte.

#tabel(
  columns: (auto, 1fr),
  [*Operația*], [*Construcția (ca în curs)*],
  [$alpha union beta$], [stare inițială nouă $s$, cu $(s, e, s_1)$ și $(s, e, s_2)$; $F = F_1 union F_2$],
  [$alpha beta$], [inițiala e $s_1$; tranziții $(f, e, s_2)$ pentru fiecare $f in F_1$; $F = F_2$],
  [$alpha^*$], [stare inițială nouă $s'$, *finală* (ca să accepte $e$), cu $(s', e, s_1)$; tranziții $(f, e, s_1)$ pentru fiecare $f in F_1$; $F = F_1 union {s'}$],
)

#capcana[La stea, starea nouă $s'$ e necesară. Dacă ai face pur și simplu $s_1$ finală și ai adăuga $(f, e, s_1)$, ai putea accepta cuvinte în plus, când în $M_1$ există tranziții care se întorc în $s_1$. Exemplu: pentru $(a^* b)^*$, AFN-ul lui $a^* b$ are o buclă $a$ pe $s_1$; dacă $s_1$ ar deveni finală, $a$ ar fi acceptat, deși $a in.not L((a^* b)^*)$.]

#idee[Seminarul poate folosi varianta Thompson: fiecare automat are *o singură* stare inițială $i$ și *o singură* stare finală $f$, iar la stea se adaugă $i ->^e$ (vechiul $i$), (vechiul $f$) $->^e$ (vechiul $i$), (vechiul $f$) $->^e f$ și $i ->^e f$. Ambele variante sunt corecte; folosește-o pe cea din seminar și fii consecvent.]

#problema[Construcția formală pentru $(a b union a)^*$][
  Construiți, pas cu pas, AFN-ul pentru $(a b union a)^*$.
][
  + $a$: $p_1 ->^a p_2$. $b$: $p_3 ->^b p_4$. Al doilea $a$: $p_5 ->^a p_6$.
  + $a b$: legăm finala lui $a$ de inițiala lui $b$: $p_2 ->^e p_3$; inițială $p_1$, finală $p_4$.
  + $a b union a$: stare nouă $p_0$, cu $p_0 ->^e p_1$ și $p_0 ->^e p_5$; finale $p_4, p_6$.
  + $(a b union a)^*$: stare nouă $s$, finală, cu $s ->^e p_0$; din finalele $p_4, p_6$, tranziții $e$ înapoi în $p_0$. Finale: $s, p_4, p_6$.
  #aut(
    (s: (p0: "e"), p0: (p1: "e", p5: "e"), p1: (p2: "a"), p2: (p3: "e"), p3: (p4: "b"), p4: (p0: "e"), p5: (p6: "a"), p6: (p0: "e")),
    (s: (0, 0), p0: (3, 0), p1: (1.5, 2), p2: (2, 4), p3: (4.4, 4), p4: (5, 2), p5: (1.8, -2), p6: (4.2, -2)),
    final: ("s", "p4", "p6"),
  )
  Verificare: $a a b a$ = $(a)(a b)(a)$: $s -> p_0 -> p_5 ->^a p_6 -> p_0 -> p_1 ->^a p_2 -> p_3 ->^b p_4 -> p_0 -> p_5 ->^a p_6$, finală. $b$ nu e acceptat: din $s$ nu se poate citi $b$ fără un $a$ înainte.
]

#petest[Dacă enunțul cere explicit „folosind algoritmul”, fă construcția formală, cu toate tranzițiile $e$, și scrie pașii. Dacă cere doar „un automat care acceptă”, desenează un AFN mic, gândit direct; e mai rapid și mai greu de greșit. Poți elimina tranzițiile $e$ inutile, dar doar dacă e evident că nu schimbi limbajul.]

#problema[AFN-uri gândite direct][
  Desenați câte un AFN pentru: (a) $a^* b union (b a)^*$; (b) $(a union b)^* a b b$; (c) $(a b)^* (b a)^*$.
][
  (a) Două ramuri, alese nedeterminist din start:
  #aut(
    (s: (A: "e", C: "e"), A: (A: "a", B: "b"), B: (:), C: (D: "b"), D: (C: "a")),
    (s: (0, 0), A: (2.5, 1.2), B: (5, 1.2), C: (2.5, -1.2), D: (5, -1.2)),
    final: ("B", "C"),
    st: ("A-A": (anchor: top), "C-D": (curve: .4), "D-C": (curve: .4)),
  )
  (b) Ghicim începutul sufixului $a b b$:
  #aut(
    (q0: (q0: "a,b", q1: "a"), q1: (q2: "b"), q2: (q3: "b"), q3: (:)),
    (q0: (0, 0), q1: (2.6, 0), q2: (5.2, 0), q3: (7.8, 0)),
    final: ("q3",),
    st: ("q0-q0": (anchor: top)),
  )
  (c) Folosind etichete pe șiruri, cum permite definiția din curs: o buclă $a b$ pe $p$, o tranziție $e$ spre $r$, o buclă $b a$ pe $r$; $r$ finală.
  #aut(
    (p: (p: "ab", r: "e"), r: (r: "ba")),
    (p: (0, 0), r: (3, 0)),
    final: ("r",),
    st: ("p-p": (anchor: top), "r-r": (anchor: top)),
  )
  Dacă trebuie tranziții doar pe simboluri, spargi fiecare buclă: $p ->^a x ->^b p$ și $r ->^b y ->^a r$.
]
