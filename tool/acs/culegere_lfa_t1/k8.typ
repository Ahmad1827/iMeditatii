#import "tpl.typ": *

= Două teste simulate, cu barem

Rezolvă fiecare test pe hârtie, cu ceasul pornit: *50 de minute*, fără notițe. Apoi corectează-te cu baremul. Ghidul de pregătire (pe site, lângă culegere) mai are un test simulat.

== Varianta A

#block(width: 100%, inset: 10pt, stroke: 0.8pt + albastru, radius: 3pt)[
  #set par(justify: false)
  + *(2 p)* (a) Fie $L$ un limbaj regulat peste $Sigma$ și $a in Sigma$. Arătați că $L slash a = {w in Sigma^* | w a in L}$ e regulat, dând construcția pe automat. (b) Ce e $L slash a$ pentru $L = L(a^* b a)$?
  + *(2 p)* Fie $L = {w in {a, b}^* | w "conține un" a "și după ultimul" a "urmează un număr par de" b}$. Scrieți un AFD și o ER pentru $L$.
  + *(2,5 p)* Fie AFN-ul $N = ({0, 1, 2}, {a, b}, Delta, 0, {2})$ cu $Delta = {(0, a, 0), (0, e, 1), (1, b, 2), (2, a, 1), (2, e, 0)}$. Construiți un AFD echivalent prin construcția submulțimilor, minimizați-l și scrieți o ER pentru $L(N)$.
  + *(1,5 p)* Fie $M$ un AFD peste ${a, b}$. Descrieți un algoritm care decide dacă $M$ acceptă o infinitate de cuvinte care încep cu $b$.
  + *(2 p)* Demonstrați că $L = {w in {a, b}^* | |w|_a = 2 |w|_b}$ nu e regulat.
  + *(2 p, bonus)* Arătați că $L = {w in {a, b}^* | |w|_(a b) = |w|_(b a)}$ e regulat.
]

#problema[Varianta A · P1 (2 p)][
  $L slash a = {w | w a in L}$.
][
  (a) Fie $M = (K, Sigma, delta, s, F)$ un AFD (complet) pentru $L$. Construim $M' = (K, Sigma, delta, s, F')$ cu
  $ F' = {q in K | delta(q, a) in F}. $
  $w in L(M')$ $<==>$ $delta^*(s, w) in F'$ $<==>$ $delta(delta^*(s, w), a) in F$ $<==>$ $delta^*(s, w a) in F$ $<==>$ $w a in L$. Deci $L(M') = L slash a$, care e regulat. $qed$

  (b) Cuvintele lui $a^* b a$ se termină cu $a$; tăiem acest $a$: $L slash a = a^* b$.
  #barem[0,5 p construcția ($F'$ corect); 0,5 p demonstrația echivalenței; 0,5 p menționarea faptului că $M$ e AFD complet (sau AFN cu aceeași idee); 0,5 p exemplul.]
]

#problema[Varianta A · P2 (2 p)][
  AFD și ER pentru „are un $a$, iar după ultimul $a$ e un număr par de $b$”.
][
  Stările: $N$ (încă niciun $a$), $E$ (după ultimul $a$, număr par de $b$; finală), $O$ (impar). Un $a$ resetează contorul.
  #aut(
    (N: (N: "b", E: "a"), E: (E: "a", O: "b"), O: (E: "a,b")),
    (N: (0, 0), E: (3.5, 0), O: (7, 0)),
    final: ("E",),
    st: ("N-N": (anchor: top), "E-E": (anchor: top), "E-O": (curve: .5), "O-E": (curve: .5)),
  )
  ER: $(a union b)^* a (b b)^*$. Verificare: $b a b b$ ✓, $a b$ ✗, $b$ ✗, $a b b a$ ✓.
  #barem[1 p AFD complet și corect (−0,25 p pentru fiecare tranziție lipsă sau greșită); 1 p ER corectă.]
]

#problema[Varianta A · P3 (2,5 p)][
  Determinizare, minimizare și ER pentru $N$.
][
  $E(0) = {0, 1}$, $E(1) = {1}$, $E(2) = {2, 0, 1}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> A = {0, 1}$], [din $0$: $E(0) = {0, 1}$; din $1$: nimic ⇒ $A$], [din $1$: $E(2) = {0, 1, 2}$ ⇒ $B$],
    [$B = {0, 1, 2}$ (finală)], [$E(0) union E(1) = {0, 1}$ ⇒ $A$], [$E(2) = {0, 1, 2}$ ⇒ $B$],
  )
  Minimizare: $P_0 = {{A}, {B}}$, deja minim (o stare finală și una nefinală). $L(N)$: se ajunge în $B$ exact după un $b$, deci $L(N) = (a union b)^* b$, cuvintele care se termină cu $b$.
  #aut(
    (A: (A: "a", B: "b"), B: (B: "b", A: "a")),
    (A: (0, 0), B: (3.5, 0)),
    final: ("B",),
    etichete: (A: "{0,1}", B: "{0,1,2}"),
    st: ("A-A": (anchor: top), "B-B": (anchor: top), "A-B": (curve: .5), "B-A": (curve: .5)),
  )
  #barem[0,5 p $e$-închiderile; 1 p tabelul submulțimilor; 0,5 p minimizarea (justificată); 0,5 p ER.]
]

#problema[Varianta A · P4 (1,5 p)][
  Decide dacă $M$ acceptă o infinitate de cuvinte care încep cu $b$.
][
  Fie $L_b = b (a union b)^*$ (AFD cu 3 stări). Întrebarea e: $L(M) inter L_b$ e infinit?
  + Construim produsul $P = M times M_b$, cu finale $F_M times F_b$.
  + În $P$ calculăm stările utile (accesibile din start și co-accesibile spre o finală).
  + Căutăm un ciclu în subgraful stărilor utile (DFS). Ciclu ⇒ infinit; altfel finit.
  Corectitudine: $L(P) = L(M) inter L_b$ (produsul), iar un limbaj regulat e infinit exact când automatul lui are un ciclu pe un drum de la start la o finală. Terminare: $P$ e finit.
  #barem[0,5 p reducerea la $L(M) inter L_b$; 0,5 p produsul; 0,5 p testul de finitudine cu justificare.]
]

#problema[Varianta A · P5 (2 p)][
  $L = {w | |w|_a = 2 |w|_b}$ nu e regulat.
][
  Presupunem $L$ regulat, cu constanta $p$. $w = a^(2p) b^p in L$, $|w| = 3p >= p$. Pentru orice $w = x y z$ cu $|x y| <= p$, $|y| >= 1$: $y = a^k$, $1 <= k <= p$. Pentru $i = 0$: $x z = a^(2p - k) b^p$ are $|x z|_a = 2p - k != 2p = 2 |x z|_b$, deci $x z in.not L$. Contradicție. $qed$
  #barem[0,5 p $w$; 0,5 p forma lui $y$; 0,5 p $i$ și calculul; 0,5 p concluzia.]
]

#problema[Varianta A · P6 (2 p, bonus)][
  $|w|_(a b) = |w|_(b a)$ e regulat.
][
  Vezi cap. 7: aparițiile lui $a b$ și $b a$ alternează, deci sunt egale exact când $w$ începe și se termină cu aceeași literă (sau $w = e$). $L = e union a union b union a (a union b)^* a union b (a union b)^* b$, o ER, deci $L$ e regulat.
  #barem[1 p observația (alternanța) cu justificare; 1 p ER-ul sau automatul.]
]

== Varianta B

#block(width: 100%, inset: 10pt, stroke: 0.8pt + albastru, radius: 3pt)[
  #set par(justify: false)
  + *(2 p)* (a) Fie $L$ regulat. Arătați că $L_"sim" = {w | w in L "și" w^R in L}$ e regulat. (b) Calculați $L_"sim"$ pentru $L = L(a^* b)$.
  + *(2 p)* (a) Scrieți o ER pentru cuvintele peste ${a, b}$ în care orice bloc maximal de $a$ are lungime pară. (b) Scrieți un AFD pentru $L = {w in {a, b}^* | |w|_a "par sau" |w|_b equiv 0 med (mod 3)}$.
  + *(2,5 p)* Minimizați AFD-ul cu stările $(i, c)$, $i in {0, 1, 2}$, $c in {0, 1}$, inițială $(0, 0)$, finale $(0, 0)$ și $(0, 1)$, cu $delta((i, c), a) = ((i + 1) mod 3, c)$ și $delta((i, c), b) = (i, 1 - c)$. Apoi scrieți o ER prin eliminarea stărilor.
  + *(1,5 p)* Fie $M_1$, $M_2$ AFD. Cum decideți dacă $L(M_1) inter L(M_2)$ e finit?
  + *(2 p)* Demonstrați că $L = {a^i b^j c^k | i = j "sau" j = k}$ nu e regulat.
  + *(2 p, bonus)* Câte stări are AFD-ul minim pentru $L = {w in {a, b}^* | |w|_a equiv |w|_b med (mod 3)}$? Justificați cu Myhill–Nerode.
]

#problema[Varianta B · P1 (2 p)][
  $L_"sim" = L inter L^R$.
][
  (a) $w in L_"sim"$ $<==>$ $w in L$ și $w^R in L$ $<==>$ $w in L$ și $w in L^R$. Deci $L_"sim" = L inter L^R$. $L^R$ e regulat (inversăm săgețile automatului, cu o stare inițială nouă legată prin $e$ de fostele finale), iar intersecția a două limbaje regulate e regulată (produsul). $qed$

  (b) $L = a^* b$, $L^R = b a^*$. Cuvintele comune: se termină cu $b$ și încep cu $b$, cu un singur $b$: doar $b$. $L_"sim" = {b}$.
  #barem[1 p scrierea ca $L inter L^R$; 0,5 p justificarea închiderii (ambele construcții numite); 0,5 p exemplul.]
]

#problema[Varianta B · P2 (2 p)][
  ER pentru blocuri pare de $a$; AFD pentru o reuniune.
][
  (a) Blocurile permise sunt $b$ și $a a$: $(b union a a)^*$. (Un bloc de $a$ de lungime pară se descompune în $a a$-uri.)

  (b) Produsul automatelor „$|w|_a mod 2$” și „$|w|_b mod 3$”, cu stările $q_(i j)$ (ca în cap. 1, ex. 6), dar cu finalele pentru „*sau*”: toate $q_(0 j)$ și toate $q_(i 0)$, adică $q_(00), q_(01), q_(02), q_(10)$. 6 stări.
  #barem[1 p ER; 1 p AFD (0,5 p construcția produsului, 0,5 p finalele pentru „sau”).]
]

#problema[Varianta B · P3 (2,5 p)][
  Minimizare și eliminare.
][
  *Minimizare.* $P_0 = {F, N}$ cu $F = {(0, 0), (0, 1)}$ și $N = {(1, c), (2, c)}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$(0, c)$], [$(1, c) in N$], [$(0, 1 - c) in F$],
    [$(1, c)$], [$(2, c) in N$], [$(1, 1 - c) in N$],
    [$(2, c)$], [$(0, c) in F$], [$(2, 1 - c) in N$],
  )
  În $N$, $(1, c)$ și $(2, c)$ au semnături diferite (cu $a$: $N$ față de $F$): $P_1 = {{(0, 0), (0, 1)}, {(1, 0), (1, 1)}, {(2, 0), (2, 1)}}$. La pasul următor nimic nu se mai sparge (componenta $c$ nu influențează nimic). AFD-ul minim are 3 stări $r_0, r_1, r_2$: $a$ avansează pe ciclu, $b$ e buclă. Limbajul: $|w|_a$ divizibil cu 3.

  *Eliminare.* $s ->^e r_0$, $r_0 ->^e f$. Eliminăm $r_2$: $r_1 ->^(a b^* a) r_0$. Eliminăm $r_1$: bucla pe $r_0$ devine $b union a b^* a b^* a$. Rămâne:
  $ (b union a b^* a b^* a)^* $
  #barem[1,5 p minimizarea, cu partițiile scrise; 1 p eliminarea, pas cu pas.]
]

#problema[Varianta B · P4 (1,5 p)][
  $L(M_1) inter L(M_2)$ finit?
][
  Produsul $P = M_1 times M_2$ cu finalele $F_1 times F_2$ acceptă $L(M_1) inter L(M_2)$. În $P$ păstrăm stările utile și căutăm un ciclu: ciclu ⇔ intersecția e infinită. Corectitudine: un cuvânt acceptat de lungime $>= |K_1| |K_2|$ repetă o stare a produsului (ciclu pompabil); invers, un ciclu util se poate parcurge oricât. Terminare: graf finit.
  #barem[0,5 p produsul; 0,5 p stările utile; 0,5 p ciclul, cu justificare.]
]

#problema[Varianta B · P5 (2 p)][
  ${a^i b^j c^k | i = j or j = k}$ nu e regulat.
][
  $w = a^p b^p c^(p + 1) in L$ ($i = j$). $y = a^k$, $k >= 1$. Pentru $i = 2$: $a^(p + k) b^p c^(p + 1)$: $p + k != p$ și $p != p + 1$, deci nicio condiție nu mai are loc: $in.not L$. $qed$

  De ce $c^(p+1)$ și nu $c^p$: cu $w = a^p b^p c^p$, după pompare rămâne adevărat $j = k$, deci cuvântul rămâne în $L$.
  #barem[0,5 p $w$ ales astfel încât $j != k$; 0,5 p forma lui $y$; 0,5 p ambele condiții false după pompare; 0,5 p concluzia.]
]

#problema[Varianta B · P6 (2 p, bonus)][
  AFD-ul minim pentru $|w|_a equiv |w|_b med (mod 3)$.
][
  *3 stări* (cap. 7): cele trei clase $[e], [a], [a a]$ sunt distincte (sufixul $a^((3 - i) mod 3)$ le separă), iar trei stări ajung: ținem minte $(|w|_a - |w|_b) mod 3$.
  #barem[1 p automatul cu 3 stări; 1 p demonstrația că sunt necesare toate trei (cuvinte separate prin sufixe).]
]
