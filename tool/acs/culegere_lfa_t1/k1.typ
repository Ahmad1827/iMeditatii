#import "tpl.typ": *

= Automate finite deterministe (P2)

#metoda[
  + *Ce țin minte?* Scrie în cuvinte informația minimă despre prefixul citit care decide dacă îl mai pot completa până la un cuvânt bun. Fiecare valoare a ei e o stare. Dă-i stării un *nume care spune ce ține minte* („par”, „am văzut $a$”, „rest 2”).
  + *Starea inițială* = informația pentru cuvântul vid. *Finale* = stările în care prefixul citit e deja bun.
  + *Tranzițiile*: pentru fiecare stare și *fiecare* simbol, cum se schimbă informația. Un AFD are $delta$ totală: dacă nu se mai poate repara nimic, du tranziția într-o *stare capcană* $d$ (nefinală, cu buclă pe toate simbolurile) și spune pe foaie că ai adăugat-o.
  + *Verifică* pe 3–4 cuvinte: unul scurt acceptat, unul respins, $e$ și un caz-limită (cuvânt care „aproape” e bun).
]

#petest[La P2 se cere de obicei „un AF” sau „un AFD” pentru un limbaj descris în cuvinte. Dacă scrie *AFD*, automatul trebuie să fie complet (cu $d$); dacă scrie doar *AF*, poți da și un AFN, de multe ori mai mic. Desenează clar: săgeată de start, cerc dublu pentru finale, câte o etichetă pe fiecare săgeată.]

== Tipare de bază

#problema[Se termină cu $a b$][
  Construiți un AFD peste ${a, b}$ pentru cuvintele care se termină cu $a b$.
][
  *Ce țin minte:* cât din $a b$ s-a potrivit la finalul textului citit: nimic ($q_0$), „$a$” ($q_1$), „$a b$” ($q_2$, finală).
  #aut(
    (q0: (q0: "b", q1: "a"), q1: (q1: "a", q2: "b"), q2: (q1: "a", q0: "b")),
    (q0: (0, 0), q1: (3, 0), q2: (6, 0)),
    final: ("q2",),
    st: ("q0-q0": (anchor: top), "q1-q1": (anchor: top), "q2-q1": (curve: .6), "q1-q2": (curve: .6), "q2-q0": (curve: -1.6, label: (dist: .25))),
  )
  Tranzițiile „de întoarcere” sunt partea care se greșește:
  - din $q_1$ cu $a$ rămâi în $q_1$: ultimul $a$ poate fi începutul lui $a b$;
  - din $q_2$ cu $a$ mergi în $q_1$ (ultimul simbol e $a$), iar cu $b$ în $q_0$ ($a b b$ nu se termină cu niciun prefix al lui $a b$).
  Verificare: $a a b$: $q_0 -> q_1 -> q_1 -> q_2$ ✓. $a b a$: se oprește în $q_1$, respins ✓. $e$: rămâne în $q_0$, respins ✓.
]

#problema[Numărul de $a$ divizibil cu 3][
  AFD cu cel mult 3 stări pentru $L = {w in {a, b}^* | |w|_a equiv 0 med (mod 3)}$.
][
  *Ce țin minte:* $|w|_a mod 3$. Stările $r_0, r_1, r_2$; $a$ avansează pe cerc, $b$ nu schimbă nimic.
  #aut(
    (r0: (r0: "b", r1: "a"), r1: (r1: "b", r2: "a"), r2: (r2: "b", r0: "a")),
    (r0: (0, 0), r1: (3, 1.6), r2: (6, 0)),
    final: ("r0",),
    st: ("r0-r0": (anchor: bottom), "r1-r1": (anchor: top), "r2-r2": (anchor: bottom)),
  )
  $e$ e acceptat (0 e divizibil cu 3). Același tipar dă orice condiție „$|w|_x equiv r med (mod k)$”: $k$ stări pe un cerc, finală $r_r$.
]

#problema[Conține / nu conține $a a$][
  (a) AFD pentru cuvintele peste ${a, b}$ care conțin subcuvântul $a a$. (b) AFD pentru cele care *nu* îl conțin.
][
  (a) *Ce țin minte:* câți $a$ consecutivi am la final (0 sau 1) sau dacă am găsit deja $a a$.
  #aut(
    (q0: (q0: "b", q1: "a"), q1: (q2: "a", q0: "b"), q2: (q2: "a,b")),
    (q0: (0, 0), q1: (3, 0), q2: (6, 0)),
    final: ("q2",),
    st: ("q0-q0": (anchor: top), "q2-q2": (anchor: top), "q0-q1": (curve: .5), "q1-q0": (curve: .5)),
  )
  (b) Același automat, cu finalele inversate: $F' = {q_0, q_1}$. Merge *doar* pentru că automatul de la (a) e complet. $q_2$ devine starea capcană a lui (b).

  #capcana[Complementul prin inversarea finalelor se face numai pe un *AFD complet*. Pe un AFN sau pe un AFD fără stare capcană iese alt limbaj.]
]

#problema[Începe și se termină cu același simbol][
  AFD pentru cuvintele *nevide* peste ${a, b}$ care încep și se termină cu același simbol ($a$, $b$, $a b b a$ da; $a b$, $e$ nu).
][
  După primul simbol, automatul se desparte în două „lumi” care nu se mai întâlnesc: în lumea $a$ țin minte dacă ultimul simbol e $a$ ($A_1$, finală) sau $b$ ($A_2$); simetric în lumea $b$.
  #aut(
    (s: (A1: "a", B1: "b"), A1: (A1: "a", A2: "b"), A2: (A2: "b", A1: "a"), B1: (B1: "b", B2: "a"), B2: (B2: "a", B1: "b")),
    (s: (0, 0), A1: (3, 1.4), A2: (6, 1.4), B1: (3, -1.4), B2: (6, -1.4)),
    final: ("A1", "B1"),
    st: ("A1-A1": (anchor: top), "A2-A2": (anchor: top), "B1-B1": (anchor: bottom), "B2-B2": (anchor: bottom), "A1-A2": (curve: .5), "A2-A1": (curve: .5), "B1-B2": (curve: .5), "B2-B1": (curve: .5)),
  )
  $s$ nu e finală, deci $e$ e respins. $a$: $s -> A_1$ ✓. $a b$: $A_2$ ✗. $b a a b$: $B_1 -> B_2 -> B_2 -> B_1$ ✓.
]

#problema[Numere binare divizibile cu 5][
  AFD cu cel mult 5 stări care acceptă scrierile în baza 2 (bitul cel mai semnificativ primul) ale numerelor divizibile cu 5. Cuvântul vid are valoarea 0.
][
  Dacă am citit numărul $x$ și urmează bitul $c$, noul număr e $2x + c$. Ajunge să țin minte $x mod 5$: stările $r_0, dots, r_4$, cu
  $ delta(r_i, c) = r_((2 i + c) mod 5). $
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu 0*], [*cu 1*],
    [$-> r_0$ (finală)], [$r_0$], [$r_1$],
    [$r_1$], [$r_2$], [$r_3$],
    [$r_2$], [$r_4$], [$r_0$],
    [$r_3$], [$r_1$], [$r_2$],
    [$r_4$], [$r_3$], [$r_4$],
  )
  #aut(
    (r0: (r0: "0", r1: "1"), r1: (r2: "0", r3: "1"), r2: (r4: "0", r0: "1"), r3: (r1: "0", r2: "1"), r4: (r3: "0", r4: "1")),
    (r0: (0, 0), r1: (3, 1.8), r2: (6, 0), r3: (3, -1.8), r4: (9, 0)),
    final: ("r0",),
    st: ("r0-r0": (anchor: bottom), "r4-r4": (anchor: right), "r1-r3": (curve: .5), "r3-r1": (curve: .5), "r2-r4": (curve: .5), "r4-r3": (curve: .4)),
  )
  Verificare: $1010 = 10$: $r_0 ->^1 r_1 ->^0 r_2 ->^1 r_0 ->^0 r_0$ ✓. $111 = 7$: $r_1 -> r_3 -> r_2$, respins ✓. Cu $F = {r_k}$ acceptă numerele cu restul $k$.
]

== Mai multe condiții deodată: automatul produs

#metoda[Când limbajul cere *două condiții simultan* („și”), starea e o *pereche* (informația pentru condiția 1, informația pentru condiția 2). Fiecare simbol actualizează ambele componente. Finale: perechile în care ambele condiții sunt îndeplinite (pentru „sau”: măcar una). Numărul de stări e produsul; desenează-le într-un caroiaj.]

#problema[$|w|_a$ par și $|w|_b$ divizibil cu 3][
  Construiți un AFD pentru $L = {w in {a, b}^* | |w|_a mod 2 = 0 and |w|_b mod 3 = 0}$.
][
  Stările $q_(i j)$ cu $i = |w|_a mod 2$, $j = |w|_b mod 3$: $delta(q_(i j), a) = q_((i + 1) mod 2, j)$ și $delta(q_(i j), b) = q_(i, (j + 1) mod 3)$. Inițială și finală: $q_(00)$.
  #aut(
    (q00: (q10: "a", q01: "b"), q01: (q11: "a", q02: "b"), q02: (q12: "a", q00: "b"), q10: (q00: "a", q11: "b"), q11: (q01: "a", q12: "b"), q12: (q02: "a", q10: "b")),
    (q00: (0, 0), q01: (3.5, 0), q02: (7, 0), q10: (0, -3), q11: (3.5, -3), q12: (7, -3)),
    final: ("q00",),
    etichete: (q00: $q_(00)$, q01: $q_(01)$, q02: $q_(02)$, q10: $q_(10)$, q11: $q_(11)$, q12: $q_(12)$),
    st: ("q00-q10": (curve: .4), "q10-q00": (curve: .4), "q01-q11": (curve: .4), "q11-q01": (curve: .4), "q02-q12": (curve: .4), "q12-q02": (curve: .4), "q02-q00": (curve: -1.3, label: (dist: .25)), "q12-q10": (curve: 1.3, label: (dist: -.25))),
  )
  Asta e exact automatul de la examenul din februarie 2022, unde s-a dat $delta(q_(i j), a) = q_((i+1) % m, j)$, $delta(q_(i j), b) = q_(i, (j+1) % n)$ și s-a cerut limbajul: răspunsul era „$|w|_a$ divizibil cu $m$ și $|w|_b$ divizibil cu $n$” (cu finala $q_(00)$).
]

#problema[Număr par de $a$ și număr impar de $b$][
  AFD pentru cuvintele peste ${a, b}$ cu $|w|_a$ par și $|w|_b$ impar.
][
  Perechea de parități (prima pentru $a$, a doua pentru $b$): $P P$ (inițială), $I P$, $P I$, $I I$. Finală: $P I$.
  #aut(
    (PP: (IP: "a", PI: "b"), IP: (PP: "a", II: "b"), PI: (II: "a", PP: "b"), II: (PI: "a", IP: "b")),
    (PP: (0, 0), IP: (4, 0), PI: (0, -3), II: (4, -3)),
    final: ("PI",),
    etichete: (PP: "PP", IP: "IP", PI: "PI", II: "II"),
    st: ("PP-IP": (curve: .5), "IP-PP": (curve: .5), "PI-II": (curve: .5), "II-PI": (curve: .5), "PP-PI": (curve: .5), "PI-PP": (curve: .5), "IP-II": (curve: .5), "II-IP": (curve: .5)),
  )
  Același caroiaj servește patru limbaje: schimbi doar finala ($P P$, $I P$, $P I$ sau $I I$). Cu $F = {P P, I I}$ ai „lungime pară”, cu $F = {I P, P I}$ „lungime impară”.
]

#problema[Cel puțin doi $a$ și cel mult un $b$][
  AFD pentru $L = {w in {a, b}^* | |w|_a >= 2 and |w|_b <= 1}$.
][
  Pentru $a$ țin minte $min(|w|_a, 2)$: 0, 1 sau „2 sau mai mulți”. Pentru $b$: 0, 1, iar al doilea $b$ strică definitiv cuvântul (capcana $d$). Stările $(i, j)$, $i in {0, 1, 2}$, $j in {0, 1}$, plus $d$. Finale: $(2, 0)$ și $(2, 1)$.
  #aut(
    (s00: (s10: "a", s01: "b"), s10: (s20: "a", s11: "b"), s20: (s20: "a", s21: "b"), s01: (s11: "a", d: "b"), s11: (s21: "a", d: "b"), s21: (s21: "a", d: "b"), d: (d: "a,b")),
    (s00: (0, 0), s10: (3, 0), s20: (6, 0), s01: (0, -2.6), s11: (3, -2.6), s21: (6, -2.6), d: (3, -5)),
    final: ("s20", "s21"),
    etichete: (s00: "0,0", s10: "1,0", s20: "2,0", s01: "0,1", s11: "1,1", s21: "2,1", d: "d"),
    st: ("s20-s20": (anchor: top), "s21-s21": (anchor: right), "d-d": (anchor: bottom), "s01-d": (curve: .3), "s21-d": (curve: -.3)),
  )
  7 stări, și nu se poate cu mai puține: algoritmul de minimizare (cap. 3) nu unește nicio pereche. Verificare: $a b a$: $(0,0) -> (1,0) -> (1,1) -> (2,1)$ ✓; $b a b a$: $(0,1) -> (1,1) -> d$ ✗.
]

#problema[Fiecare simbol apare măcar o dată][
  AFD peste ${0, 1, 2}$ pentru $L = {w | |w|_0 >= 1 and |w|_1 >= 1 and |w|_2 >= 1}$.
][
  *Ce țin minte:* mulțimea simbolurilor văzute până acum, o submulțime a lui ${0, 1, 2}$: 8 stări. Din starea $S$ cu simbolul $c$ treci în $S union {c}$. Inițială: $emptyset$; finală: ${0, 1, 2}$ (care are buclă pe toate simbolurile).
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare*], [*0*], [*1*], [*2*],
    [$-> emptyset$], [${0}$], [${1}$], [${2}$],
    [${0}$], [${0}$], [${0,1}$], [${0,2}$],
    [${1}$], [${0,1}$], [${1}$], [${1,2}$],
    [${2}$], [${0,2}$], [${1,2}$], [${2}$],
    [${0,1}$], [${0,1}$], [${0,1}$], [${0,1,2}$],
    [${0,2}$], [${0,2}$], [${0,1,2}$], [${0,2}$],
    [${1,2}$], [${0,1,2}$], [${1,2}$], [${1,2}$],
    [${0,1,2}$ (finală)], [${0,1,2}$], [${0,1,2}$], [${0,1,2}$],
  )
  Toate cele 8 stări sunt necesare: două mulțimi diferite $S != T$ se deosebesc printr-un sufix care conține exact simbolurile lipsă din una dintre ele. E fișa de recapitulare a seminarului, ex. 3.
]

#problema[Lungime pară și fără $1$][
  AFD peste ${0, 1, 2}$ pentru $L = {w | |w| "par" and |w|_1 = 0}$.
][
  Paritatea lungimii ($P$, $I$) și o capcană $d$ pentru orice $1$.
  #aut(
    (P: (I: "0,2", d: "1"), I: (P: "0,2", d: "1"), d: (d: "0,1,2")),
    (P: (0, 0), I: (4, 0), d: (2, -2.4)),
    final: ("P",),
    st: ("P-I": (curve: .5), "I-P": (curve: .5), "d-d": (anchor: bottom)),
  )
  E intersecția a două limbaje: produsul „lungime pară” × „fără 1” are 4 stări, dar cele două capcane (pară/impară, după un $1$) sunt echivalente și se unesc.
]

== Sufixe și subcuvinte interzise

#metoda[Pentru „se termină cu $u$” / „conține $u$” / „nu conține $u$”, starea e *cel mai lung sufix al textului citit care e și prefix al lui $u$*. Pentru $u$ de lungime $k$ ai $k + 1$ stări. Tranziția din starea „am potrivit $u_1 dots u_i$” cu simbolul $c$: dacă $c = u_(i+1)$ avansezi; altfel cauți cel mai lung sufix al lui $u_1 dots u_i c$ care e prefix al lui $u$ (cum face algoritmul KMP).]

#problema[Se termină cu $a b b$][
  AFD peste ${a, b}$ pentru $(a union b)^* a b b$.
][
  Stările: $q_0$ (nimic), $q_1$ („$a$”), $q_2$ („$a b$”), $q_3$ („$a b b$”, finală).
  #aut(
    (q0: (q0: "b", q1: "a"), q1: (q1: "a", q2: "b"), q2: (q1: "a", q3: "b"), q3: (q1: "a", q0: "b")),
    (q0: (0, 0), q1: (3, 0), q2: (6, 0), q3: (9, 0)),
    final: ("q3",),
    st: ("q0-q0": (anchor: top), "q1-q1": (anchor: top), "q2-q1": (curve: .6), "q1-q2": (curve: .6), "q3-q1": (curve: -1.2, label: (dist: .25)), "q3-q0": (curve: 1.7, label: (dist: -.25))),
  )
  Întoarcerile: $a b a$ se termină cu „$a$” → $q_1$; $a b b a$ → „$a$” → $q_1$; $a b b b$ → nimic → $q_0$. Acest AFD e minim; îl vei regăsi la eliminarea stărilor (cap. 3).
]

#problema[Fără $b b$][
  AFD peste ${a, b}$ pentru cuvintele în care nu apar doi $b$ consecutivi.
][
  $s$ = „ultimul simbol nu e $b$” (sau nu am citit nimic), $B$ = „ultimul simbol e $b$”, $d$ = am văzut $b b$.
  #aut(
    (s: (s: "a", B: "b"), B: (s: "a", d: "b"), d: (d: "a,b")),
    (s: (0, 0), B: (3.5, 0), d: (7, 0)),
    final: ("s", "B"),
    st: ("s-s": (anchor: top), "d-d": (anchor: top), "s-B": (curve: .5), "B-s": (curve: .5)),
  )
]

#problema[Fiecare $a$ e urmat imediat de un $b$][
  AFD peste ${a, b}$ pentru cuvintele în care orice $a$ e urmat imediat de un $b$.
][
  $q_0$ = „totul e în regulă”, $q_1$ = „tocmai am citit un $a$ care așteaptă un $b$”. Un $a$ în $q_1$ (adică $a a$) e o greșeală fără reparație.
  #aut(
    (q0: (q0: "b", q1: "a"), q1: (q0: "b", d: "a"), d: (d: "a,b")),
    (q0: (0, 0), q1: (3.5, 0), d: (7, 0)),
    final: ("q0",),
    st: ("q0-q0": (anchor: top), "d-d": (anchor: top), "q0-q1": (curve: .5), "q1-q0": (curve: .5)),
  )
  $q_1$ nu e finală: un cuvânt care se termină cu $a$ are un $a$ neurmat de $b$. ER: $(b union a b)^*$.
]

#problema[Nu se termină cu $a b a$][
  Fie $Sigma = {a, b, c}$. Scrieți un AFD pentru $L = Sigma^* without (Sigma^* compose {a b a})$.
][
  Construim AFD-ul pentru „se termină cu $a b a$” și inversăm finalele. Stările: cât din $a b a$ am potrivit la final.
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare*], [*a*], [*b*], [*c*],
    [$-> q_0$ (nimic)], [$q_1$], [$q_0$], [$q_0$],
    [$q_1$ („$a$”)], [$q_1$], [$q_2$], [$q_0$],
    [$q_2$ („$a b$”)], [$q_3$], [$q_0$], [$q_0$],
    [$q_3$ („$a b a$”)], [$q_1$], [$q_2$], [$q_0$],
  )
  Din $q_3$ cu $b$ mergi în $q_2$: $a b a b$ se termină cu $a b$, care e prefix al lui $a b a$ (suprapunere!). Pentru „se termină cu $a b a$”, $F = {q_3}$; pentru $L$, $F = {q_0, q_1, q_2}$.
  #aut(
    (q0: (q0: "b,c", q1: "a"), q1: (q1: "a", q2: "b", q0: "c"), q2: (q3: "a", q0: "b,c"), q3: (q1: "a", q2: "b", q0: "c")),
    (q0: (0, 0), q1: (3.5, 2), q2: (7, 0), q3: (3.5, -2)),
    final: ("q0", "q1", "q2"),
    st: ("q0-q0": (anchor: bottom), "q1-q1": (anchor: top), "q1-q0": (curve: .5), "q0-q1": (curve: .5), "q3-q2": (curve: .5), "q2-q3": (curve: .5), "q3-q1": (curve: .3), "q2-q0": (label: (pos: .3))),
  )
  #petest[Exercițiul a fost la Testul 1 din noiembrie 2023 (seria lui G. Mitra). Greșeala tipică: automatul fără $c$ (alfabetul are trei simboluri!) sau tranziția $q_3 ->^b q_0$ în loc de $q_2$.]
]

#problema[Între oricare două zerouri, un număr impar de $1$][
  Fie $Sigma = {0, 1}$. AFD pentru $L = {w | forall w_1, w_3 in Sigma^*, w_2 in {1}^* : w = w_1 0 w_2 0 w_3 => |w_2| "impar"}$.
][
  Traducere: între oricare două zerouri *consecutive* e un număr impar de $1$ (deci nu apare $00$, nici $0110$ etc.). Țin minte: $N$ = încă n-am văzut niciun $0$; $Z_0$ = după ultimul $0$ am un număr par de $1$; $Z_1$ = impar. Un $0$ în $Z_0$ înseamnă un bloc par: capcana.
  #aut(
    (N: (N: "1", Z0: "0"), Z0: (Z1: "1", d: "0"), Z1: (Z0: "0,1"), d: (d: "0,1")),
    (N: (0, 0), Z0: (3.5, 0), Z1: (7, 0), d: (3.5, -2.4)),
    final: ("N", "Z0", "Z1"),
    etichete: (N: "N", Z0: $Z_0$, Z1: $Z_1$, d: "d"),
    st: ("N-N": (anchor: top), "d-d": (anchor: bottom), "Z0-Z1": (curve: .5), "Z1-Z0": (curve: .5)),
  )
  Atenție la $Z_1 ->^0 Z_0$: noul $0$ încheie un bloc impar (bun) și începe un bloc nou, cu zero $1$-uri. Toate stările în afară de $d$ sunt finale: condiția privește doar perechile de zerouri deja văzute. ER-ul e în cap. 2.
]

#problema[Trei condiții: $3 | |w|_0$, $2 | |w|_1$, se termină cu $0$][
  Fie $Sigma = {0, 1}$. Scrieți un AF pentru $L = {w | 3 | |w|_0 and 2 | |w|_1 and exists x in Sigma^* : w = x 0}$.
][
  *Varianta directă (produs).* Starea $(i, j, ell)$: $i = |w|_0 mod 3$, $j = |w|_1 mod 2$, $ell$ = „ultimul simbol e 0”. Sunt $3 dot 2 dot 2 = 12$ stări, finală $(0, 0, "da")$. E corect, dar mare.

  *Observația care micșorează automatul.* Informația $ell$ contează doar când $(i, j) = (0, 0)$: în celelalte stări cuvântul e respins oricum, iar după încă un simbol $ell$ se recalculează. Deci păstrăm $(i, j)$ (6 stări) și dublăm doar $(0, 0)$: $S$ = „$(0, 0)$ și nu se termină cu 0” (inițială) și $F$ = „$(0, 0)$ și se termină cu 0” (finală). 7 stări:
  #tabel(
    columns: (auto, auto, auto),
    [*Stare $(i, j)$*], [*cu 0*], [*cu 1*],
    [$-> S = (0,0)$], [$(1,0)$], [$(0,1)$],
    [$F = (0,0)$, finală], [$(1,0)$], [$(0,1)$],
    [$(1,0)$], [$(2,0)$], [$(1,1)$],
    [$(2,0)$], [$F$], [$(2,1)$],
    [$(0,1)$], [$(1,1)$], [$S$],
    [$(1,1)$], [$(2,1)$], [$(1,0)$],
    [$(2,1)$], [$(0,1)$], [$(2,0)$],
  )
  Singurul loc unde se ajunge în $(0, 0)$ citind un $0$ e $(2, 0) ->^0 F$; citind un $1$, $(0, 1) ->^1 S$. Verificare: $000$: $(1,0) -> (2,0) -> F$ ✓. $11$: $(0,1) -> S$, respins (nu se termină cu 0) ✓. $01100$: $(1,0),(1,1),(1,0),(2,0),F$ ✓.

  Minimizarea automatului de 12 stări dă exact aceste 7 (verificat cu algoritmul din cap. 3).
]

== Invers: dat automatul, ce limbaj acceptă?

#metoda[Dă fiecărei stări un nume care spune *ce s-a citit* ca să ajungi acolo. Caută stările capcană și ciclurile. Apoi formulează limbajul și verifică pe cuvinte mici, acceptate și respinse.]

#problema[Ce acceptă automatul?][
  AFD peste ${a, b}$, inițială $A$, finale $A, B, C$: $A ->^a B$, $A ->^b A$, $B ->^a B$, $B ->^b C$, $C ->^a B$, $C ->^b D$, $D ->^(a, b) D$.
][
  $D$ e capcană (nefinală, cu buclă pe tot). Singura intrare în $D$ e $C ->^b D$. Cine e $C$? Se ajunge în $C$ doar cu $b$ din $B$, iar în $B$ doar cu $a$. Deci $C$ = „ultimele două simboluri sunt $a b$”, iar $C ->^b D$ citește $a b b$.

  *Limbajul:* cuvintele care nu conțin subcuvântul $a b b$. Verificare: $a b a b$ ✓ (nu are $a b b$); $b a b b$ ✗; $b b b$ ✓ ($b b$ fără $a$ înainte e în regulă: $A$ are buclă pe $b$).
]
