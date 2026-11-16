#import "tpl.typ": *

= Fișa de recapitulare a seminarului, rezolvată (și întrebări bonus)

Fișa „Recapitulare LFA: Seminare 1–4” e cea mai apropiată sursă de stilul testului. Mai jos e rezolvată integral; unde o problemă e deja rezolvată în detaliu în alt capitol, găsești rezumatul și trimiterea.

#problema[Ex. 1 · Câte tupluri poate conține $Delta$?][
  Câte tupluri poate conține relația $Delta$ a unui AFN?
][
  În definiția din curs, $Delta subset.eq K times Sigma^* times K$ e o submulțime *finită*. $Sigma^*$ e infinit, deci $Delta$ poate avea *oricâte* tupluri, dar întotdeauna un număr *finit*; nu există o margine superioară care să depindă doar de $|K|$ și $|Sigma|$ (de exemplu, $(q, a^m, q)$ pentru $m = 1, dots, 1000$).

  În varianta cu tranziții doar pe simboluri și $e$, $Delta subset.eq K times (Sigma union {e}) times K$, deci $0 <= |Delta| <= |K|^2 (|Sigma| + 1)$.
]

#problema[Ex. 2 · Automate pentru trei ER][
  Construiți automate finite care acceptă: (a) $a^* (a b union b a union e) union b^*$; (b) $((a union b)^* (e union c)^*)^*$; (c) $((a b)^* union (b c)^*) a b$.
][
  *(a)* Două ramuri din starea inițială. Pe ramura de sus: bucla $a$ pe $A$, apoi $a b$, $b a$ sau nimic.
  #aut(
    (s: (A: "e", B: "e"), A: (A: "a", x: "a", y: "b"), x: (F: "b"), y: (F: "a"), F: (:), B: (B: "b")),
    (s: (0, 0), A: (2.6, 1.4), x: (5.2, 2.5), y: (5.2, 0.3), F: (7.8, 1.4), B: (2.6, -1.4)),
    final: ("A", "F", "B"),
    st: ("A-A": (anchor: top), "B-B": (anchor: right)),
  )
  *(b)* Limbajul interior $L_0 = L((a union b)^* (e union c)^*)$ conține $a$, $b$ și $c$ și e inclus în ${a, b, c}^*$. Deci $L_0^* = {a, b, c}^*$: orice cuvânt e o concatenare de simboluri, fiecare simbol fiind în $L_0$. Automatul: o singură stare, inițială și finală, cu buclă pe $a, b, c$.
  #aut(
    (q: (q: "a,b,c")),
    (q: (0, 0)),
    final: ("q",),
    st: ("q-q": (anchor: top)),
  )
  *(c)* O ramură pentru $(a b)^*$, una pentru $(b c)^*$, apoi coada comună $a b$.
  #aut(
    (s: (p: "e", r: "e"), p: (p1: "a", t: "e"), p1: (p: "b"), r: (r1: "b", t: "e"), r1: (r: "c"), t: (u: "a"), u: (f: "b"), f: (:)),
    (s: (0, 0), p: (2.4, 1.3), p1: (2.4, 3.3), r: (2.4, -1.3), r1: (2.4, -3.3), t: (4.8, 0), u: (7, 0), f: (9.2, 0)),
    final: ("f",),
    st: ("p-p1": (curve: .5), "p1-p": (curve: .5), "r-r1": (curve: .5), "r1-r": (curve: .5)),
  )
]

#problema[Ex. 3 · Automate pentru două limbaje peste ${0, 1, 2}$][
  (a) $L = {w in {0, 1, 2}^* | |w|_0 >= 1 and |w|_1 >= 1 and |w|_2 >= 1}$; (b) $L = {w in {0, 1, 2}^* | |w| "par" and |w|_1 = 0}$.
][
  *(a)* Ținem minte *mulțimea* simbolurilor văzute până acum: 8 stări $S subset.eq {0, 1, 2}$, inițială $emptyset$, finală ${0, 1, 2}$, cu $delta(S, c) = S union {c}$. (E produsul a trei automate de câte 2 stări, „am văzut $c$ / încă nu”.)
  #tabel(
    columns: (auto, auto, auto, auto),
    [*Stare*], [*0*], [*1*], [*2*],
    [$emptyset$ (inițială)], [${0}$], [${1}$], [${2}$],
    [${0}$], [${0}$], [${0,1}$], [${0,2}$],
    [${1}$], [${0,1}$], [${1}$], [${1,2}$],
    [${2}$], [${0,2}$], [${1,2}$], [${2}$],
    [${0,1}$], [${0,1}$], [${0,1}$], [${0,1,2}$],
    [${0,2}$], [${0,2}$], [${0,1,2}$], [${0,2}$],
    [${1,2}$], [${0,1,2}$], [${1,2}$], [${1,2}$],
    [${0,1,2}$ (finală)], [${0,1,2}$], [${0,1,2}$], [${0,1,2}$],
  )
  E minim: două mulțimi diferite $S != T$ se deosebesc prin sufixul format din simbolurile care lipsesc din $S$, dar nu și din $T$ (sau invers).

  *(b)* Paritatea lungimii, plus o capcană pentru orice $1$:
  #aut(
    (P: (I: "0,2", d: "1"), I: (P: "0,2", d: "1"), d: (d: "0,1,2")),
    (P: (0, 0), I: (3.4, 0), d: (1.7, -2.6)),
    final: ("P",),
    st: ("P-I": (curve: .5), "I-P": (curve: .5), "d-d": (anchor: bottom)),
  )
]

#problema[Ex. 4, 5, 8 · Închidere][
  (4) Fără subsecvențe din $F$ finit; (5) automat pentru $L(M_1) triangle.stroked.t L(M_2)$; (8) $"Suf"(L)$ e regulat.
][
  Toate trei sunt rezolvate complet în cap. 8. Pe scurt: (4) $L = overline(Sigma^* F Sigma^*)$; (5) automatul produs cu $F = {(p, q) | p in F_1 "xor" q in F_2}$; (8) AFN cu o inițială nouă și tranziții $e$ spre toate stările accesibile.
]

#problema[Ex. 6 · Automat cu $|F| = |K|$][
  Fie $M$ un automat finit cu $|F| = |K|$. Adevărat sau fals, pentru AFD și pentru AFN: (i) $e in L(M)$; (ii) dacă $w in L(M)$, orice prefix al lui $w$ e în $L(M)$; (iii) orice limbaj regulat care conține toate prefixele cuvintelor sale are un astfel de automat acceptor.
][
  $F subset.eq K$ și $|F| = |K|$, deci $F = K$: *toate stările sunt finale*.

  *(i)* Adevărat pentru ambele: calculul de lungime 0 se oprește în $s in F$.

  *(ii)* AFD: adevărat, chiar mai mult: $delta$ e totală, deci orice cuvânt ajunge într-o stare, care e finală; $L(M) = Sigma^*$.
  AFN cu tranziții pe simboluri sau $e$: adevărat. Calculul acceptor pentru $w$, oprit după ce a citit prefixul $u$, e un calcul care se oprește într-o stare (finală).
  AFN ca în curs, cu etichete pe șiruri: *fals*. Contraexemplu: $Delta = {(s, a b, s)}$, $F = K = {s}$: $L(M) = (a b)^*$, iar $a$, prefix al lui $a b$, nu e acceptat. Pe test, menționează definiția pe care o folosești.

  *(iii)* AFD: fals. Un AFD cu $F = K$ acceptă $Sigma^*$, dar $a^*$ peste ${a, b}$ e regulat, închis la prefixe și diferit de $Sigma^*$.
  AFN: adevărat pentru $L != emptyset$. Luăm un AFD pentru $L$, ștergem stările din care nu se ajunge într-o finală (inclusiv capcana; rezultatul e un AFN, pentru că $delta$ devine parțială) și facem toate stările rămase finale. Dacă $w$ e acceptat de noul automat, calculul lui se termină într-o stare $q$ din care se ajunge într-o finală: $exists z : w z in L$, deci $w in "Pref"(L) = L$. Invers, un cuvânt din $L$ are un calcul care trece doar prin stări utile. Pentru $L = emptyset$ (închis la prefixe, trivial) e fals, fiindcă $e$ e mereu acceptat.
]

#problema[Ex. 7 · Finit / unic cel mai lung cuvânt][
  Cum verificăm, pentru un AFD $M$, că $L(M)$ e finit, respectiv că $M$ acceptă un unic cel mai lung cuvânt nevid?
][
  Rezolvat în cap. 9: finit $<==>$ nu există cicluri prin stări utile; unicitatea: programare dinamică pe DAG-ul stărilor utile, numărând drumurile de lungime maximă.
]

#problema[Ex. 9 · O singură stare finală][
  Poate orice limbaj regulat să fie recunoscut de un AFD cu o singură stare acceptoare?
][
  *Nu.* Contraexemplu: $L = {e, a}$ peste $Sigma = {a}$. Presupunem un AFD cu $F = {f}$. Cum $e in L$, $s = f$. Cum $a in L$, $delta(s, a) = f = s$. Atunci $delta^*(s, a a) = s in F$, deci $a a in L$, fals. Contradicție.

  *Pentru AFN, da:* adaugi o stare nouă $f'$, singura finală, cu $(f, e, f')$ pentru fiecare $f in F$, fără tranziții din $f'$.
]

#problema[Ex. 10 · Tranziții injective][
  Cum arată un AFD pentru care $delta(q, a) = delta(p, a) <==> q = p$, pentru orice $a in Sigma$ și $p, q in K$? Dar un AFN cu $(q, a, x), (p, a, x) in Delta <==> q = p$?
][
  *AFD:* pentru fiecare $a$, funcția $q |-> delta(q, a)$ e injectivă pe mulțimea finită $K$, deci e o *bijecție* (o permutare a stărilor). În desen: în fiecare stare intră *exact o* săgeată etichetată cu $a$, pentru fiecare $a$. Consecințe: nu poate exista o stare capcană în care să ajungi din altă stare (ar primi două săgeți cu același simbol: bucla ei și săgeata venită din afară); orice calcul poate fi „derulat înapoi” în mod unic; automatul invers (săgețile întoarse) e tot determinist și complet. Exemplu: automatele pentru paritate sau pentru $|w| mod k$.

  *AFN:* în fiecare stare $x$ intră *cel mult o* săgeată cu eticheta $a$, pentru fiecare $a$. Automatul e „co-determinist”: inversând săgețile, obții un automat fără nedeterminism pe simboluri (poate să-i lipsească tranziții și poate avea mai multe stări inițiale, vechile finale).
]

== Alte întrebări de tip bonus

#problema[Fapte rapide (adevărat / fals, cu justificare)][
  (a) Orice limbaj finit e acceptat de un AFD fără cicluri. (b) Dacă un AFD cu $n$ stări acceptă vreun cuvânt, acceptă unul de lungime $< n$. (c) Câte stări are AFD-ul minim pentru $emptyset$, $Sigma^*$, ${e}$ și ${a^m}$ (un singur cuvânt) peste ${a}$? (d) Dacă $L$ e regulat, ${w | w w in L}$ e regulat.
][
  *(a)* Fals, dacă „AFD” înseamnă $delta$ totală: graful e finit și din fiecare stare pleacă o săgeată, deci orice drum suficient de lung repetă o stare; cel puțin capcana are o buclă. Adevărat dacă vorbim de cicluri prin stări *utile*.

  *(b)* Adevărat: cel mai scurt drum de la $s$ la o finală nu repetă stări, deci are $<= n - 1$ muchii.

  *(c)* $emptyset$: 1 stare (nefinală). $Sigma^*$: 1 stare (finală). ${e}$: 2 stări (inițiala finală + capcana). ${a^m}$: $m + 2$ stări (un lanț de $m + 1$ stări + capcana).

  *(d)* Adevărat. Fie $M$ un AFD pentru $L$. Pentru fiecare $w$, fie $t_w : K -> K$, $t_w (q) = delta^*(q, w)$. Există cel mult $|K|^(|K|)$ astfel de funcții (finit). Construim un AFD cu stările = funcțiile $t : K -> K$, starea inițială $t_e = "id"$, tranziția $t ->^a (q |-> delta(t(q), a))$ și finale $\{t | t(t(s)) in F\}$. După citirea lui $w$ suntem în $t_w$, iar $w w in L <==> delta^*(delta^*(s, w), w) in F <==> t_w (t_w (s)) in F$.
]

#problema[Margini și cazuri limită][
  (a) Este ${a^n b^m | n, m >= 0, n + m <= 100}$ regulat? (b) Este ${a^n b^n | 0 <= n <= 10^6}$ regulat? (c) Dacă $L_1$ e regulat și $L_2$ nu, poate $L_1 inter L_2$ să fie regulat?
][
  (a) Da: e finit. (b) Da: e finit, deși are o structură „de tip $a^n b^n$”. Pompajul nu se aplică: $n$ din lemă poate fi mai mare decât orice cuvânt. (c) Da: $L_1 = emptyset$ dă $emptyset$. Sau $L_1 = a^*$, $L_2 = {a^n b^n}$: $L_1 inter L_2 = {e}$.
]
