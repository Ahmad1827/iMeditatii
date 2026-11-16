#import "tpl.typ": *

= Conversii (P3)

Itemul P3 (2,5 p, cel mai mare) cere aplicarea *mecanică* a unui algoritm. Se notează pașii, nu doar rezultatul: scrie tabelele, numerotează stările, spune ce algoritm aplici.

#metoda[
  *ER → AFN* (construcțiile din curs): pentru $alpha union beta$, stare inițială nouă cu $e$ spre ambele; pentru $alpha beta$, $e$ din finalele lui $alpha$ în inițiala lui $beta$; pentru $alpha^*$, stare inițială nouă *finală*, cu $e$ spre inițiala veche și $e$ din finalele vechi înapoi în inițiala veche.

  *AFN → AFD* (submulțimi): $E(q)$ = stările în care ajungi din $q$ doar pe tranziții $e$. Starea inițială a AFD-ului: $E(s)$. Din mulțimea $S$ cu simbolul $a$: $union.big_(q in S) {E(p) | (q, a, p) in Delta}$. Generezi doar mulțimile accesibile (tabel, rând cu rând). Finale: mulțimile care conțin o finală a AFN-ului. $emptyset$ e starea capcană.

  *AF → ER* (eliminarea stărilor): adaugi o stare inițială nouă (cu $e$ spre cea veche) și o finală nouă (cu $e$ din cele vechi). Elimini pe rând stările vechi: pentru fiecare pereche intrare $p ->^alpha q$, ieșire $q ->^gamma r$, cu bucla $beta$ pe $q$, adaugi $p stretch(->)^(alpha beta^* gamma) r$ (reunit cu ce exista deja între $p$ și $r$). La final rămâne o singură etichetă.

  *Minimizare*: scoți stările inaccesibile; $P_0 = {F, K without F}$; spargi grupurile după „în ce grup duce fiecare simbol”; repeți până nu se mai schimbă nimic.
]

== ER → automat

#problema[Lanțul complet pentru $(a b union b a)^*$][
  Construiți un AFD complet pentru $L((a b union b a)^*)$ cu cel mult 4 stări: ER → AFN (construcția din curs) → AFD (submulțimi) → minimizare.
][
  *Pasul 1: AFN.* $a b$: $p_1 ->^a p_2 ->^e p_3 ->^b p_4$. $b a$: $p_5 ->^b p_6 ->^e p_7 ->^a p_8$. Reuniunea: $p_0 ->^e p_1$, $p_0 ->^e p_5$. Steaua: stare nouă $s'$, finală, $s' ->^e p_0$; din finalele $p_4, p_8$, $e$ înapoi în $p_0$. Finale: $s', p_4, p_8$.
  #aut(
    (s: (p0: "e"), p0: (p1: "e", p5: "e"), p1: (p2: "a"), p2: (p3: "e"), p3: (p4: "b"), p4: (p0: "e"), p5: (p6: "b"), p6: (p7: "e"), p7: (p8: "a"), p8: (p0: "e")),
    (s: (0, 0), p0: (2.6, 0), p1: (4.6, 1.8), p2: (6.6, 1.8), p3: (8.6, 1.8), p4: (10.6, 1.8), p5: (4.6, -1.8), p6: (6.6, -1.8), p7: (8.6, -1.8), p8: (10.6, -1.8)),
    final: ("s", "p4", "p8"),
    etichete: (s: $s'$, p0: $p_0$, p1: $p_1$, p2: $p_2$, p3: $p_3$, p4: $p_4$, p5: $p_5$, p6: $p_6$, p7: $p_7$, p8: $p_8$),
    st: ("p4-p0": (curve: -1.2, label: (dist: .25)), "p8-p0": (curve: 1.2, label: (dist: -.25))),
    lungime: 0.82cm,
  )
  *Pasul 2: submulțimi.* $E(s') = {s', p_0, p_1, p_5}$.
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare AFD*], [*Mulțimea*], [*cu $a$*], [*cu $b$*],
    [$-> A$ (finală)], [${s', p_0, p_1, p_5}$], [$E(p_2) = {p_2, p_3} = B$], [$E(p_6) = {p_6, p_7} = C$],
    [$B$], [${p_2, p_3}$], [$emptyset$], [$E(p_4) = {p_4, p_0, p_1, p_5} = D$],
    [$C$], [${p_6, p_7}$], [$E(p_8) = {p_8, p_0, p_1, p_5} = G$], [$emptyset$],
    [$D$ (finală)], [${p_0, p_1, p_4, p_5}$], [$B$], [$C$],
    [$G$ (finală)], [${p_0, p_1, p_5, p_8}$], [$B$], [$C$],
    [$emptyset$], [—], [$emptyset$], [$emptyset$],
  )
  *Pasul 3: minimizare.* $P_0 = {{A, D, G}, {B, C, emptyset}}$. Finalele $A, D, G$ merg toate cu $a$ în $B$ și cu $b$ în $C$: rămân împreună. În grupul nefinal: $B ->^b D$ (finală), $C ->^b emptyset$ (nefinală): se despart; $C ->^a G$ (finală), $emptyset ->^a emptyset$: se despart. $P_1 = {{A, D, G}, {B}, {C}, {emptyset}}$, stabilă.
  #aut(
    (S: (B: "a", C: "b"), B: (S: "b", d: "a"), C: (S: "a", d: "b"), d: (d: "a,b")),
    (S: (0, 0), B: (3.5, 1.4), C: (3.5, -1.4), d: (7, 0)),
    final: ("S",),
    etichete: (S: "ADG", B: "B", C: "C", d: $emptyset$),
    st: ("S-B": (curve: .4), "B-S": (curve: .4), "S-C": (curve: .4), "C-S": (curve: .4), "d-d": (anchor: right)),
  )
  Verificare: $a b b a$: $S -> B -> S -> C -> S$ ✓. $a a$: $B -> emptyset$ ✗.
]

#problema[$a^* (a b union b a union e) union b^*$][
  Construiți un automat finit pentru $L(a^* (a b union b a union e) union b^*)$ peste ${a, b}$.
][
  Gândit direct, cu câte o ramură pentru fiecare termen al reuniunii:
  #aut(
    (s: (A: "e", B: "e"), A: (A: "a", x: "a", y: "b", f: "e"), x: (f: "b"), y: (f: "a"), B: (B: "b"), f: (:)),
    (s: (0, 0), A: (2.8, 1.2), x: (5.6, 2.6), y: (5.6, 0.2), f: (8.4, 1.2), B: (2.8, -1.5)),
    final: ("f", "B"),
    st: ("A-A": (anchor: top), "B-B": (anchor: right), "A-f": (curve: -.6, label: (pos: .25))),
  )
  $A$ citește $a^*$, apoi alege: $a b$ (prin $x$), $b a$ (prin $y$) sau nimic ($A ->^e f$). Ramura $B$ citește $b^*$ (inclusiv $e$). Nu e nevoie de construcția formală dacă enunțul nu o cere.
]

#problema[$((a b)^* union (b c)^*) a b$][
  Construiți un automat finit pentru $L(((a b)^* union (b c)^*) a b)$ peste ${a, b, c}$.
][
  #aut(
    (s: (P: "e", R: "e"), P: (p1: "a", T: "e"), p1: (P: "b"), R: (r1: "b", T: "e"), r1: (R: "c"), T: (t1: "a"), t1: (f: "b"), f: (:)),
    (s: (0, 0), P: (2.6, 1.5), p1: (2.6, 3.6), R: (2.6, -1.5), r1: (2.6, -3.6), T: (5.2, 0), t1: (7.6, 0), f: (10, 0)),
    final: ("f",),
    st: ("P-p1": (curve: .5), "p1-P": (curve: .5), "R-r1": (curve: .5), "r1-R": (curve: .5)),
  )
  Atenție: nu lega ciclul lui $(a b)^*$ și pe al lui $(b c)^*$ de aceeași stare, altfel automatul acceptă și $a b b c a b$, care amestecă cele două ramuri.
]

#problema[Cât mai puține stări][
  Construiți un automat finit cu *cât mai puține stări* pentru $L(((a union b)^* (e union c)^*)^*)$ peste ${a, b, c}$.
][
  Sub steaua exterioară se pot genera separat $a$, $b$ și $c$, deci limbajul e $(a union b union c)^* = Sigma^*$. Automatul: *o singură stare*, inițială și finală, cu buclă pe $a, b, c$. Nu poate avea 0 stări (orice automat are o stare inițială).
  #aut((q: (q: "a,b,c")), (q: (0, 0)), final: ("q",), st: ("q-q": (anchor: top)))
]

== Determinizare

#problema[AFN-ul de la examen → AFD și ER][
  Fie $N = ({0, 1}, {a, b}, Delta, 0, {1})$ cu $Delta = {(0, a, 0), (0, b, 0), (0, b, 1), (1, a, 1), (1, a, 0)}$. (a) Construiți un AFD $A$ cu $L(A) = L(N)$. (b) Scrieți o ER pentru $L(N)$ (bonus: una compactă).
][
  #aut(
    ("0": ("0": "a,b", "1": "b"), "1": ("1": "a", "0": "a")),
    ("0": (0, 0), "1": (3.5, 0)),
    final: ("1",),
    st: ("0-0": (anchor: top), "1-1": (anchor: top), "0-1": (curve: .5), "1-0": (curve: .5)),
  )
  (a) Nu sunt tranziții $e$, deci $E(q) = {q}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> {0}$], [${0}$], [${0, 1}$],
    [${0, 1}$ (finală)], [${0} union {0, 1} = {0, 1}$], [${0, 1} union emptyset = {0, 1}$],
  )
  #aut(
    (A: (A: "a", B: "b"), B: (B: "a,b")),
    (A: (0, 0), B: (3.5, 0)),
    final: ("B",),
    etichete: (A: "{0}", B: "{0,1}"),
    st: ("A-A": (anchor: top), "B-B": (anchor: top)),
  )
  (b) Din AFD se citește direct: $a^* b (a union b)^*$, adică *cuvintele care conțin cel puțin un $b$*. Prin eliminarea stărilor pe $N$ (stare inițială nouă $s ->^e 0$, finală nouă $1 ->^e f$):
  - eliminăm $0$ (buclă $a union b$; intrări $s ->^e 0$, $1 ->^a 0$; ieșire $0 ->^b 1$): $s stretch(->)^((a union b)^* b) 1$, iar pe $1$ bucla devine $a union a (a union b)^* b$;
  - eliminăm $1$: $s stretch(->)^((a union b)^* b (a union a(a union b)^* b)^*) f$.
  Ambele ER sunt corecte; a doua e „ce iese din algoritm”, prima e varianta compactă cerută la bonus.
]

#problema[Construcția submulțimilor: se termină cu $a b$][
  Fie AFN-ul $N = ({0, 1, 2}, {a, b}, Delta, 0, {2})$ cu $Delta = {(0, a, 0), (0, b, 0), (0, a, 1), (1, b, 2)}$. Aplicați construcția submulțimilor.
][
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> {0}$], [${0, 1}$], [${0}$],
    [${0, 1}$], [${0, 1}$], [${0, 2}$],
    [${0, 2}$ (finală)], [${0, 1}$], [${0}$],
  )
  Doar 3 dintre cele $2^3 = 8$ submulțimi sunt accesibile. $emptyset$ nu apare, pentru că $0$ are buclă pe tot și e în fiecare mulțime.
  #aut(
    (A: (B: "a", A: "b"), B: (B: "a", C: "b"), C: (B: "a", A: "b")),
    (A: (0, 0), B: (3.5, 0), C: (7, 0)),
    final: ("C",),
    etichete: (A: "{0}", B: "{0,1}", C: "{0,2}"),
    st: ("A-A": (anchor: top), "B-B": (anchor: top), "B-C": (curve: .5), "C-B": (curve: .5), "C-A": (curve: -1.4, label: (dist: .25))),
  )
  E exact AFD-ul pentru „se termină cu $a b$” din cap. 1.
]

#problema[Cu tranziții $e$: $a^* b^*$][
  Fie $N = ({0, 1}, {a, b}, Delta, 0, {1})$ cu $Delta = {(0, a, 0), (0, e, 1), (1, b, 1)}$. Construiți un AFD echivalent.
][
  $E(0) = {0, 1}$, $E(1) = {1}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> {0, 1}$ (finală)], [$E(0) = {0, 1}$], [$E(1) = {1}$],
    [${1}$ (finală)], [$emptyset$], [${1}$],
    [$emptyset$], [$emptyset$], [$emptyset$],
  )
  Starea inițială e $E(0)$, nu ${0}$! Pentru că ${0, 1}$ conține finala $1$, $e$ e acceptat. $emptyset$ e capcana, necesară ca AFD-ul să fie complet ($b a$ trebuie respins). $L = a^* b^*$.
  #aut(
    (A: (A: "a", B: "b"), B: (B: "b", d: "a"), d: (d: "a,b")),
    (A: (0, 0), B: (3.5, 0), d: (7, 0)),
    final: ("A", "B"),
    etichete: (A: "{0,1}", B: "{1}", d: $emptyset$),
    st: ("A-A": (anchor: top), "B-B": (anchor: top), "d-d": (anchor: top)),
  )
]

#problema[Explozia exponențială: al treilea simbol de la final][
  Determinizați AFN-ul de la cap. 2 pentru „al treilea simbol de la final e $a$” ($0 stretch(->)^(a, b) 0$, $0 ->^a 1$, $1 stretch(->)^(a, b) 2$, $2 stretch(->)^(a, b) 3$, finală $3$). Câte stări are AFD-ul minim?
][
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> {0}$], [${0,1}$], [${0}$],
    [${0,1}$], [${0,1,2}$], [${0,2}$],
    [${0,2}$], [${0,1,3}$], [${0,3}$],
    [${0,1,2}$], [${0,1,2,3}$], [${0,2,3}$],
    [${0,3}$ ✓], [${0,1}$], [${0}$],
    [${0,1,3}$ ✓], [${0,1,2}$], [${0,2}$],
    [${0,2,3}$ ✓], [${0,1,3}$], [${0,3}$],
    [${0,1,2,3}$ ✓], [${0,1,2,3}$], [${0,2,3}$],
  )
  8 stări (✓ = finale, cele care conțin $3$). Interpretare: mulțimea spune care dintre ultimele trei simboluri au fost $a$ ($1 in S$: ultimul; $2 in S$: penultimul; $3 in S$: antepenultimul). Toate 8 sunt necesare: două cuvinte care diferă pe una dintre ultimele 3 poziții se deosebesc printr-un sufix potrivit (dacă diferă pe poziția $i$ de la final, adaugi $3 - i$ simboluri). Deci AFD-ul minim are $2^3 = 8$ stări, față de 4 la AFN.
]

#problema[AFN cu etichete pe șiruri][
  Fie AFN-ul cu $K = {p, q}$, $s = p$, $F = {q}$ și $Delta = {(p, a b, q), (q, e, p), (q, a, q)}$. Construiți un AFD echivalent și descrieți limbajul.
][
  *Pasul 0:* spargem $(p, a b, q)$ în $p ->^a x ->^b q$, cu $x$ stare nouă. Acum etichetele sunt simboluri sau $e$, și $E(q) = {q, p}$.
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare AFD*], [*Mulțimea*], [*cu $a$*], [*cu $b$*],
    [$-> P$], [${p}$], [${x} = X$], [$emptyset$],
    [$X$], [${x}$], [$emptyset$], [$E(q) = {p, q} = Q$],
    [$Q$ (finală)], [${p, q}$], [${x} union E(q) = {p, q, x} = R$], [$emptyset$],
    [$R$ (finală)], [${p, q, x}$], [$R$], [$Q$],
  )
  plus capcana $emptyset$. Limbajul: începe cu $a b$, apoi blocuri $a$ (bucla pe $q$) sau $a b$ (încă o trecere prin $p -> x -> q$): $a b (a union a b)^*$.
]

== Automat → ER (eliminarea stărilor)

#problema[Eliminare pe un AFD cu 3 stări][
  AFD-ul $M$ peste ${a, b}$: $q_0$ inițială; $q_0 ->^a q_1$, $q_0 ->^b q_0$, $q_1 ->^a q_1$, $q_1 ->^b q_2$, $q_2 ->^a q_1$, $q_2 ->^b q_0$; finală $q_2$. Eliminați stările și scrieți o ER pentru $L(M)$.
][
  Adăugăm $s ->^e q_0$ și $q_2 ->^e f$. Eliminăm în ordinea $q_2, q_1, q_0$.

  *Eliminăm $q_2$.* Intră: $q_1 ->^b q_2$. Ies: $q_2 ->^a q_1$, $q_2 ->^b q_0$, $q_2 ->^e f$. Fără buclă. Noi: $q_1 stretch(->)^(b a) q_1$ (reunit cu bucla $a$: bucla devine $a union b a$), $q_1 stretch(->)^(b b) q_0$, $q_1 ->^b f$.

  *Eliminăm $q_1$.* Intră: $q_0 ->^a q_1$. Buclă: $a union b a$. Ies: $q_1 stretch(->)^(b b) q_0$, $q_1 ->^b f$. Noi: $q_0 stretch(->)^(a (a union b a)^* b b) q_0$ (reunit cu bucla $b$) și $q_0 stretch(->)^(a (a union b a)^* b) f$.

  *Eliminăm $q_0$.* Buclă: $b union a(a union b a)^* b b$. Rămâne:
  $ (b union a (a union b a)^* b b)^* a (a union b a)^* b $
  Limbajul e „se termină cu $a b$”, adică $(a union b)^* a b$: în $q_2$ se ajunge exact după $a b$. Ambele răspunsuri sunt corecte; pe test îl dai pe cel obținut prin algoritm, iar dacă vezi forma scurtă, o poți adăuga.
]

#problema[Eliminare: se termină cu $a b b$][
  Aplicați eliminarea stărilor pe AFD-ul pentru $(a union b)^* a b b$ (cap. 1, ex. 11).
][
  Stările $q_0, dots, q_3$, finală $q_3$. Adăugăm $s ->^e q_0$, $q_3 ->^e f$. Eliminăm $q_3$, $q_2$, $q_1$, $q_0$.
  + *$q_3$*: intră $q_2 ->^b q_3$; ies $q_3 ->^a q_1$, $q_3 ->^b q_0$, $q_3 ->^e f$. Noi: $q_2 stretch(->)^(b a) q_1$ (cu cea veche: $q_2 stretch(->)^(a union b a) q_1$), $q_2 stretch(->)^(b b) q_0$, $q_2 ->^b f$.
  + *$q_2$*: intră $q_1 ->^b q_2$; ies spre $q_1$ ($a union b a$), $q_0$ ($b b$), $f$ ($b$). Noi: bucla pe $q_1$ devine $a union b(a union b a) = a union b a union b b a$; $q_1 stretch(->)^(b b b) q_0$; $q_1 stretch(->)^(b b) f$.
  + *$q_1$*: intră $q_0 ->^a q_1$; buclă $beta = a union b a union b b a$. Noi: bucla pe $q_0$ devine $b union a beta^* b b b$; $q_0 stretch(->)^(a beta^* b b) f$.
  + *$q_0$*: $s -> f$:
  $ (b union a (a union b a union b b a)^* b b b)^* a (a union b a union b b a)^* b b $
  Pare complicat, dar e corect (verifică pe $a b b$, $a a b b$, $a b b a b b$). Morala: algoritmul dă ER mari; nu le simplifica pe test decât dacă ești sigur.
]

== Minimizare

#problema[De la 6 stări la 2][
  Minimizați AFD-ul peste ${a, b}$ cu stările $0, dots, 5$, inițială $0$, finale ${1, 3, 5}$ și $delta$: $0 ->^a 1$, $0 ->^b 2$, $1 ->^a 3$, $1 ->^b 4$, $2 ->^a 5$, $2 ->^b 0$, $3 ->^a 1$, $3 ->^b 2$, $4 ->^a 3$, $4 ->^b 0$, $5 ->^a 5$, $5 ->^b 4$.
][
  Toate stările sunt accesibile ($0 -> 1, 2$; $1 -> 3, 4$; $2 -> 5$).

  $P_0 = {N, F}$ cu $N = {0, 2, 4}$ (nefinale) și $F = {1, 3, 5}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$ → grup*], [*cu $b$ → grup*],
    [0], [1 ∈ F], [2 ∈ N],
    [2], [5 ∈ F], [0 ∈ N],
    [4], [3 ∈ F], [0 ∈ N],
    [1], [3 ∈ F], [4 ∈ N],
    [3], [1 ∈ F], [2 ∈ N],
    [5], [5 ∈ F], [4 ∈ N],
  )
  Toate stările din $N$ au aceeași semnătură $(F, N)$, la fel toate din $F$. Partiția e deja stabilă: *AFD-ul minim are 2 stări*.
  #aut(
    (N: (F: "a", N: "b"), F: (F: "a", N: "b")),
    (N: (0, 0), F: (3.5, 0)),
    final: ("F",),
    etichete: (N: "024", F: "135"),
    st: ("N-N": (anchor: top), "F-F": (anchor: top), "N-F": (curve: .5), "F-N": (curve: .5)),
  )
  Limbajul: cuvintele care *se termină cu $a$*. Automatul mare doar „complica” același lucru.
]

#problema[Metoda tabelului, cu o stare inaccesibilă][
  Minimizați AFD-ul peste ${0, 1}$, inițială $A$, finală $C$:
  #tabel(
    columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto),
    [], [*A*], [*B*], [*C*], [*D*], [*E*], [*F*], [*G*], [*H*],
    [*0*], [B], [G], [A], [C], [H], [C], [G], [G],
    [*1*], [F], [C], [C], [G], [F], [G], [E], [C],
  )
][
  *Pasul 1: inaccesibile.* Din $A$: $B, F$; din $B$: $G, C$; din $G$: $E$; din $E$: $H$. $D$ nu apare nicăieri ca destinație dintr-o stare accesibilă: îl ștergem.

  *Pasul 2: tabelul perechilor.* Marcăm întâi perechile (finală, nefinală): toate perechile cu $C$. Apoi, la fiecare rundă, marcăm ${p, q}$ dacă pentru un simbol $x$ perechea ${delta(p, x), delta(q, x)}$ e deja marcată.
  - Runda 1 (cu $C$ marcat): ${A, B}$ (cu 1: ${F, C}$), ${A, F}$ (cu 0: ${B, C}$), ${A, H}$, ${B, E}$, ${B, F}$, ${B, G}$, ${E, F}$, ${E, H}$, ${F, G}$, ${F, H}$, ${G, H}$.
  - Runda 2: ${A, G}$ (cu 0: ${B, G}$, marcată), ${E, G}$ (cu 0: ${H, G}$, marcată).
  - Runda 3: nimic nou.
  Rămân nemarcate ${A, E}$ și ${B, H}$: sunt echivalente. Verificare: $A$ și $E$ merg cu 1 în $F$, iar cu 0 în $B$ și $H$, care sunt echivalente; $B$ și $H$ merg cu 0 în $G$ și cu 1 în $C$.

  *AFD-ul minim* are 5 stări: $[A E], [B H], C, F, G$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*0*], [*1*],
    [$-> [A E]$], [$[B H]$], [$F$],
    [$[B H]$], [$G$], [$C$],
    [$C$ (finală)], [$[A E]$], [$C$],
    [$F$], [$C$], [$G$],
    [$G$], [$G$], [$[A E]$],
  )
  #petest[Ambele metode (partiții sau tabelul perechilor) sunt acceptate. Cu tabelul, desenează „triunghiul” de perechi și pune în fiecare căsuță numărul rundei în care ai marcat-o; corectorul vede imediat raționamentul.]
]

== Grile de conversie

#problema[Câte stele se pot șterge?][
  Fie $(a^* b^* c^* union b union c union a b^*)^* a^*$ peste ${a, b, c}$. Care e numărul maxim de stele ce pot fi eliminate fără să se schimbe limbajul? (a) 3 (b) 1 (c) 2 (d) 4
][
  *(a) 3.* Limbajul e $Sigma^*$ (sub steaua mare apar $a$, $b$, $c$). Ce trebuie păstrat:
  - steaua mare: fără ea, $c b$ nu se mai generează;
  - $a^*$ de la final: fără el, cuvintele trebuie să se termine cu un $a$ obligatoriu;
  - măcar o sursă pentru $a$ sub steaua mare. Dacă scoatem cele trei stele din $a^* b^* c^*$, rămâne $a b c$, dar $a$ vine din $a b^*$ (cu $b^0$).
  Dintre toate variantele cu 3 stele șterse, doar aceasta păstrează limbajul (de exemplu $(a b c^* union b union c union a b)^* a^*$ nu mai generează $a c$: sub steaua mare niciun bloc nu e doar $a$). Cu 4 stele șterse nu merge niciuna. Expresia: $(a b c union b union c union a b^*)^* a^*$.
]

#problema[Fapte despre conversii (adevărat / fals)][
  (1) Cel mai mic AFD pentru „al treilea simbol de la final e $a$” are 8 stări. (2) Dacă $M'$ e AFD echivalent cu AFN-ul $M$, $M'$ are cel puțin la fel de multe stări ca $M$. (3) Un AFN pentru ${e}$ are nevoie de cel puțin 1 stare. (4) Un AFD pentru „începe cu $a$” peste ${a, b}$ are cel puțin 6 tranziții.
][
  (1) *Adevărat* (ex. 8 de mai sus).

  (2) *Fals*: adaugă în $M$ 100 de stări inaccesibile; $M'$ nu are nevoie de ele.

  (3) *Adevărat*, și ajunge una: starea inițială, finală, fără tranziții. 0 tranziții.

  (4) *Adevărat*: AFD-ul minim are 3 stări (start, „a început cu $a$”, capcana pentru $b$ la început), iar un AFD are exact $|K| dot |Sigma| = 3 dot 2 = 6$ tranziții ($delta$ e totală).
]
