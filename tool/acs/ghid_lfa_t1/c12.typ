#import "tpl.typ": *

= Test simulat (50 de minute, 12 puncte)

Rezolvă-l pe hârtie, cu ceasul pornit, *înainte* să te uiți la rezolvări. Apoi punctează-te singur cu baremul.

#block(stroke: 1pt + albastru, inset: 12pt, radius: 4pt, width: 100%)[
  *P1 (2p) · Închidere.*
  \ (a) (1,25p) Fie $L$ regulat peste $Sigma$. Arătați că $L' = {w in Sigma^* | |w| "e par și" (w in L "sau" w^R in L)}$ e regulat.
  \ (b) (0,75p) Adevărat sau fals: „Dacă $L_1$ și $L_1 L_2$ sunt regulate, atunci $L_2$ e regulat.” Justificați.

  *P2 (2p) · Reprezentare.*
  \ (a) (0,75p) Scrieți o ER pentru cuvintele peste ${a, b}$ în care orice $a$ e urmat imediat de cel puțin doi $b$.
  \ (b) (1,25p) Construiți un AFD pentru $L = {w in {a, b}^* | |w|_a equiv 1 thick (mod 3) "și" w "se termină cu" b}$.

  *P3 (2,5p) · Conversii.*
  \ (a) (1,25p) Construiți un AFN pentru $(a union b)^* a b$ și transformați-l într-un AFD prin construcția cu submulțimi.
  \ (b) (1,25p) Transformați AFD-ul obținut într-o ER prin eliminarea stărilor.

  *P4 (1,5p) · Proprietăți algoritmice.* Dat un AFD $M$, descrieți un algoritm care decide dacă există $w in L(M)$ astfel încât și $w^R in L(M)$.

  *P5 (2p) · Pompare.* Arătați că $L = {a^i b^j c^k | i, j, k >= 0, thick i + j = k}$ nu e regulat.

  *P6 (2p) · Bonus.* Fie $L subset.eq {a}^*$ un limbaj *oarecare* (nu neapărat regulat). Arătați că $L^*$ e regulat.
]

#pagebreak()

== Rezolvări și barem

#problema[P1 (2p)][
  (a) $L'$ regulat; (b) adevărat/fals.
][
  *(a)* Observăm că $L' = (L union L^R) inter (Sigma Sigma)^*$.
  - $L^R$ e regulat: din AFD-ul lui $L$ inversăm săgețile, vechea inițială devine finală, adăugăm o inițială nouă cu $e$ spre vechile finale. *(0,5p)*
  - $L union L^R$ e regulat (închidere la reuniune). *(0,25p)*
  - $(Sigma Sigma)^*$ e regulat (e o ER). Intersecția a două limbaje regulate e regulată (automatul produs). *(0,25p)*
  - Corectitudinea scrierii: $w in L' <==> |w|$ par și ($w in L$ sau $w in L^R$). *(0,25p)*

  *(b)* *Fals.* $L_1 = Sigma^*$, $L_2 = {a^n b^n | n >= 0}$. $L_1$ e regulat. $e in L_2$, deci $L_1 L_2 supset.eq Sigma^* e = Sigma^*$, adică $L_1 L_2 = Sigma^*$, regulat. Dar $L_2$ nu e regulat. *(0,25p răspunsul, 0,5p contraexemplul verificat)*
]

#problema[P2 (2p)][
  (a) ER; (b) AFD.
][
  *(a)* $(b union a b b)^*$. *(0,75p; 0,25p dacă lipsește $e$ sau se acceptă $a b$)*

  *(b)* Produs între „$|w|_a mod 3$” (3 stări) și „ultimul simbol e $b$” ($N$ / $B$). Starea $(r, t)$: $a$ duce în $((r + 1) mod 3, N)$, $b$ în $(r, B)$. Inițială $0 N$, finală $1 B$.
  #aut(
    (N0: (N1: "a", B0: "b"), N1: (N2: "a", B1: "b"), N2: (N0: "a", B2: "b"), B0: (N1: "a", B0: "b"), B1: (N2: "a", B1: "b"), B2: (N0: "a", B2: "b")),
    (N0: (0, 0), N1: (4, 0), N2: (8, 0), B0: (0, -3), B1: (4, -3), B2: (8, -3)),
    final: ("B1",),
    etichete: (N0: "0N", N1: "1N", N2: "2N", B0: "0B", B1: "1B", B2: "2B"),
    st: ("N2-N0": (curve: -1.3), "B2-N0": (curve: 0.01, label: (pos: .15)), "N1-B1": (label: (dist: .3)), "B0-B0": (anchor: bottom), "B1-B1": (anchor: bottom), "B2-B2": (anchor: bottom), "B0-N1": (label: (pos: .3)), "B1-N2": (label: (pos: .3))),
  )
  *(0,5p stările și semnificația lor, 0,5p tranzițiile complete, 0,25p inițială și finale)*
]

#problema[P3 (2,5p)][
  (a) AFN și determinizare; (b) eliminarea stărilor.
][
  *(a)* AFN: $q_0$ cu buclă $a, b$; $q_0 ->^a q_1 ->^b q_2$; $F = {q_2}$. *(0,25p)*
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare*], [*a*], [*b*], [*finală?*],
    [$1 = {q_0}$], [${q_0, q_1} = 2$], [${q_0} = 1$], [nu],
    [$2 = {q_0, q_1}$], [${q_0, q_1} = 2$], [${q_0, q_2} = 3$], [nu],
    [$3 = {q_0, q_2}$], [${q_0, q_1} = 2$], [${q_0} = 1$], [*da*],
  )
  #aut(
    ("1": ("1": "b", "2": "a"), "2": ("2": "a", "3": "b"), "3": ("2": "a", "1": "b")),
    ("1": (0, 0), "2": (3.4, 0), "3": (6.8, 0)),
    final: ("3",),
    st: ("1-1": (anchor: top), "2-2": (anchor: top), "2-3": (curve: .5), "3-2": (curve: .5), "3-1": (curve: 1.2)),
  )
  *(0,75p tabelul, 0,25p finalele)*

  *(b)* Pregătire: $s' ->^e 1$, $3 ->^e f'$. *(0,25p)*
  - Eliminăm $2$ (buclă $a$): $(1, 3)$: $a a^* b$; $(3, 3)$: buclă nouă $a a^* b$. *(0,25p)*
  - Eliminăm $1$ (buclă $b$): $(s', 3)$: $b^* a a^* b$; $(3, 3)$: bucla devine $a a^* b union b b^* a a^* b$. *(0,35p)*
  - Eliminăm $3$: $(s', f')$: $b^* a a^* b (a a^* b union b b^* a a^* b)^*$. *(0,25p)*
  Simplificare (opțională): $a a^* b union b b^* a a^* b = (e union b b^*) a a^* b = b^* a^+ b$, deci ER-ul e $(b^* a^+ b)^+$, adică exact cuvintele care se termină în $a b$. *(0,15p pentru verificare)*
]

#problema[P4 (1,5p)][
  Există $w in L(M)$ cu $w^R in L(M)$?
][
  *Reducere:* întrebarea e $L inter L^R != emptyset$, cu $L = L(M)$. *(0,5p)*
  + Construim un AFN pentru $L^R$ (săgeți inversate, inițială nouă cu $e$ spre vechile finale, finală vechea inițială) și îl determinizăm. *(0,25p)*
  + Construim automatul produs pentru $L inter L^R$. *(0,25p)*
  + Parcurgem graful produsului din starea inițială (BFS); răspundem „da” $<==>$ se ajunge la o stare finală. *(0,25p)*
  *Corectitudine și terminare:* construcțiile păstrează limbajul (închidere la oglindire și intersecție); toate automatele sunt finite, deci parcurgerea se termină. *(0,25p)*
]

#problema[P5 (2p)][
  $L = {a^i b^j c^k | i + j = k}$ nu e regulat.
][
  Presupunem prin absurd că $L$ e regulat; fie $n$ constanta din lema de pompare. *(0,25p)*
  Alegem $w = a^n c^n in L$ ($i = n$, $j = 0$, $k = n$), $|w| = 2 n >= n$. *(0,5p)*
  Fie $w = x y z$ o descompunere oarecare cu $|x y| <= n$, $y != e$. Primele $n$ simboluri sunt $a$, deci $y = a^m$, $1 <= m <= n$. *(0,5p)*
  Pentru $i = 2$: $x y^2 z = a^(n + m) c^n$; $(n + m) + 0 != n$, deci $x y^2 z in.not L$. *(0,5p)*
  Contradicție cu lema, deci $L$ nu e regulat. *(0,25p)*
]

#problema[P6 (2p, bonus)][
  $L subset.eq {a}^*$ oarecare $==>$ $L^*$ regulat.
][
  Fie $S = {|w| : w in L}$. Un cuvânt $a^t$ e în $L^*$ $<==>$ $t$ e o sumă de elemente din $S$ (cu repetiții; suma vidă = 0). Fie $T$ mulțimea acestor sume.

  *Cazul 1:* $S subset.eq {0}$. Atunci $L^* = {e}$, regulat. *(0,25p)*

  *Cazul 2:* fie $g$ = cel mai mare divizor comun al elementelor nenule din $S$. Șirul cmmdc-urilor primelor $m$ elemente nenule e descrescător și pozitiv, deci se stabilizează: există $s_1, dots, s_m in S$ cu $gcd(s_1, dots, s_m) = g$. *(0,5p)*

  Prin teorema lui Schur (problema monedelor): orice multiplu de $g$ suficient de mare, adică $>= N$, cu $N$ multiplu de $g$, e o combinație cu coeficienți naturali a lui $s_1, dots, s_m$. Deci $T$ conține toți multiplii lui $g$ care sunt $>= N$. Pe de altă parte, orice element din $T$ e multiplu de $g$. *(0,75p)*

  Deci $L^* = {a^t | t in T, t < N} union a^N (a^g)^*$: o mulțime finită reunită cu un limbaj descris de o ER. Ambele sunt regulate, deci $L^*$ e regulat. *(0,5p)*

  Exemplu: $L = {a^p | p "prim"}$ nu e regulat, dar $L^* = {e} union a^2 a^*$ e regulat.
]
