#import "tpl.typ": *

= Automate nedeterministe și determinizarea (P2, P3)

#defn(t: "Definiție (AFN, ca în curs)")[
  Un AFN e $M = (K, Sigma, Delta, s, F)$, unde $Delta$ e o submulțime *finită* a lui $K times Sigma^* times K$. Un triplet $(q, u, p) in Delta$ înseamnă: din $q$, citind șirul $u$ (poate fi $e$ sau mai multe simboluri), poți trece în $p$.

  Un pas: $(q, u w) tack.r_M (p, w)$ dacă $(q, u, p) in Delta$. $M$ *acceptă* $w$ dacă *există* un calcul $(s, w) tack.r_M^* (f, e)$ cu $f in F$.
]

Diferențele față de AFD:
- dintr-o stare pot pleca mai multe tranziții cu același simbol, sau niciuna (calculul se blochează);
- există tranziții $e$, care nu citesc nimic;
- un cuvânt e acceptat dacă *măcar un* calcul ajunge într-o stare finală după ce a citit tot cuvântul; e respins dacă *toate* calculele se blochează sau se termină în stări nefinale.

Orice tranziție pe un șir lung se poate sparge în tranziții pe simboluri: $(q, a b c, p)$ devine $(q, a, x_1), (x_1, b, x_2), (x_2, c, p)$, cu $x_1, x_2$ stări noi. De aceea multe surse (și seminarul) lucrează cu $Delta subset.eq K times (Sigma union {e}) times K$; puterea e aceeași.

#teorema[Pentru orice AFN există un AFD echivalent (care acceptă același limbaj). Deci AFN, AFD și ER descriu exact aceeași clasă: limbajele regulate.]

#problema[Un AFN mic și AFD-ul lui][
  AFN pentru $L = (a union b)^* a (a union b)$ (al doilea simbol de la final e $a$).
][
  „Ghicim” momentul în care citim penultimul simbol:
  #aut(
    (q0: (q0: "a,b", q1: "a"), q1: (q2: "a,b"), q2: (:)),
    (q0: (0, 0), q1: (3, 0), q2: (6, 0)),
    final: ("q2",),
    st: ("q0-q0": (anchor: top)),
  )
  Pe $a b$: un calcul rămâne în $q_0$ (respinge), altul trece $q_0 ->^a q_1 ->^b q_2$ (acceptă). Deci $a b in L$. Pe $b a$: singurul calcul care ajunge la $q_1$ o face cu ultimul $a$ și apoi nu mai are ce citi: respins.
]

== $e$-închiderea

#defn(t: "Definiție")[
  $E(q)$ = mulțimea stărilor în care poți ajunge din $q$ *doar* pe tranziții $e$ (inclusiv $q$ însăși): $E(q) = {p in K | (q, e) tack.r_M^* (p, e)}$. Pentru o mulțime $Q$: $E(Q) = union.big_(q in Q) E(q)$.
]

Se calculează ca un parcurs în graf (DFS/BFS) folosind doar muchiile $e$.

== Determinizarea (construcția cu submulțimi)

#teorema(t: "Algoritm")[
  Pentru AFN-ul $M = (K, Sigma, Delta, s, F)$ cu tranziții pe simboluri sau $e$, AFD-ul $M' = (K', Sigma, delta', s', F')$ e:
  - $s' = E(s)$;
  - $delta'(Q, a) = union.big {E(p) | exists q in Q : (q, a, p) in Delta}$: „din oricare stare din $Q$, citește $a$, apoi închide pe $e$”;
  - $F' = {Q | Q inter F != emptyset}$: o submulțime e finală dacă *conține* o stare finală;
  - $K'$ = doar submulțimile *accesibile* din $s'$ (nu toate $2^(|K|)$).
]

#petest[Scrie un tabel cu o linie pentru fiecare submulțime nouă și o coloană pentru fiecare simbol. Adaugă o linie nouă de fiecare dată când apare o submulțime nevăzută. Te oprești când nu mai apar submulțimi noi. Dacă apare $emptyset$, e o stare capcană: o păstrezi (AFD-ul trebuie să fie total) și o marchezi ca nefinală.]

#problema[Determinizare cu tranziții $e$][
  Determinizați AFN-ul de mai jos ($s = q_0$, $F = {q_3}$) și descrieți limbajul.
  #aut(
    (q0: (q0: "a,b", q1: "a"), q1: (q2: "b,e"), q2: (q3: "a"), q3: (:)),
    (q0: (0, 0), q1: (2.8, 0), q2: (5.6, 0), q3: (8.4, 0)),
    final: ("q3",),
    st: ("q0-q0": (anchor: top)),
  )
][
  *Pasul 1: $e$-închiderile.* $E(q_0) = {q_0}$, $E(q_1) = {q_1, q_2}$, $E(q_2) = {q_2}$, $E(q_3) = {q_3}$.

  *Pasul 2: tabelul.* Starea inițială: $E(q_0) = {q_0}$.
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare AFD*], [*$a$*], [*$b$*], [*finală?*],
    [$S_0 = {q_0}$], [${q_0} union E(q_1) = {q_0, q_1, q_2} = S_1$], [${q_0} = S_0$], [nu],
    [$S_1 = {q_0, q_1, q_2}$], [${q_0, q_1, q_2} union E(q_3) = {q_0, q_1, q_2, q_3} = S_2$], [${q_0} union E(q_2) = {q_0, q_2} = S_3$], [nu],
    [$S_2 = {q_0, q_1, q_2, q_3}$], [$S_2$ (din $q_3$ nu pleacă nimic)], [$S_3$], [*da* ($q_3 in S_2$)],
    [$S_3 = {q_0, q_2}$], [${q_0, q_1, q_2} union {q_3} = S_2$], [${q_0} = S_0$], [nu],
  )
  Detaliu pentru $delta'(S_1, a)$: din $q_0$ cu $a$ ajungi în $q_0$ și $q_1$; din $q_1$ cu $a$, nimic; din $q_2$ cu $a$ în $q_3$. Închizi pe $e$: $E(q_0) union E(q_1) union E(q_3) = {q_0, q_1, q_2, q_3}$.

  *Pasul 3: desenul.*
  #aut(
    (S0: (S0: "b", S1: "a"), S1: (S2: "a", S3: "b"), S2: (S2: "a", S3: "b"), S3: (S2: "a", S0: "b")),
    (S0: (0, 0), S1: (3.2, 0), S2: (6.4, 0), S3: (3.2, -2.8)),
    final: ("S2",),
    st: ("S0-S0": (anchor: top), "S2-S2": (anchor: top), "S2-S3": (curve: .4), "S3-S2": (curve: .4)),
  )
  *Limbajul:* $L = (a union b)^* a (b union e) a$, adică cuvintele care se termină în $a a$ sau în $a b a$. Interpretarea stărilor: $S_0$ = „nimic util la final”, $S_1$ = „se termină în $a$”, $S_3$ = „se termină în $a b$”, $S_2$ = „se termină în $a a$ sau $a b a$”.
]

#capcana[
  - Nu uita $e$-închiderea *după* fiecare tranziție pe simbol și la starea inițială.
  - O submulțime e finală dacă *conține* o stare finală, nu dacă e formată doar din finale.
  - Nu complementa un AFN inversând stările finale: în AFN-ul de mai sus, cu $F = {q_0, q_1, q_2}$ s-ar accepta și $a a$ (rămânând în $q_0$). Întâi determinizezi, apoi complementezi.
]

#problema[Determinizare cu stare capcană][
  Determinizați AFN-ul cu $K = {1, 2}$, $s = 1$, $F = {2}$, $Delta = {(1, a, 1), (1, a, 2), (2, b, 2)}$.
][
  Nu există tranziții $e$, deci $E(q) = {q}$.
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare*], [*$a$*], [*$b$*], [*finală?*],
    [${1}$], [${1, 2}$], [$emptyset$], [nu],
    [${1, 2}$], [${1, 2}$], [${2}$], [da],
    [${2}$], [$emptyset$], [${2}$], [da],
    [$emptyset$], [$emptyset$], [$emptyset$], [nu],
  )
  $emptyset$ e starea capcană. Limbajul: $a^+ b^*$.
]

#idee[Numărul de stări poate crește exponențial: AFN-ul pentru „al $k$-lea simbol de la final e $a$” are $k + 1$ stări, iar AFD-ul minim are $2^k$. Pe test nu primești astfel de exemple mari; dacă ai mai mult de 6–7 submulțimi, verifică dacă n-ai greșit o $e$-închidere.]
