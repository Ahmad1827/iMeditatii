#import "tpl.typ": *

= Proprietăți de închidere (P1)

#teorema(t: "Teoremă (închidere)")[
  Dacă $L, L_1, L_2$ sunt regulate peste $Sigma$, atunci sunt regulate și:
  $ L_1 union L_2, quad L_1 L_2, quad L^*, quad overline(L), quad L_1 inter L_2, quad L_1 without L_2, quad L_1 triangle.stroked.t L_2, $
  $ L^R, quad "Pref"(L), quad "Suf"(L), quad "Sub"(L), quad h(L), quad h^(-1)(L) $
  ($h$ = un morfism: înlocuiește fiecare simbol cu un șir.)
]

Pe test nu e suficient să spui „e închisă la …”: când se cere „arătați că”, dai *construcția*, sau scrii limbajul nou ca o combinație de operații deja cunoscute.

== Construcțiile, una câte una

#tabel(
  columns: (auto, 1fr),
  [*Operația*], [*Construcția*],
  [$union$, concatenare, $*$], [cu ER: $alpha union beta$, $alpha beta$, $alpha^*$ (sau automatele din cap. 5)],
  [$overline(L)$], [AFD *complet* pentru $L$ (cu stare capcană, dacă e nevoie), apoi $F' = K without F$],
  [$L_1 inter L_2$], [automatul produs: $K = K_1 times K_2$, $s = (s_1, s_2)$, $delta((p, q), a) = (delta_1(p, a), delta_2(q, a))$, $F = F_1 times F_2$. Sau: $L_1 inter L_2 = overline(overline(L_1) union overline(L_2))$],
  [$L_1 without L_2$], [$L_1 inter overline(L_2)$; în produs: $F = F_1 times (K_2 without F_2)$],
  [$L_1 triangle.stroked.t L_2$], [$(L_1 without L_2) union (L_2 without L_1)$; în produs: $F = {(p, q) | p in F_1 "xor" q in F_2}$],
  [$L^R$], [inversezi toate săgețile; vechea inițială devine singura finală; o inițială nouă $s'$ cu $s' ->^e f$ pentru fiecare $f in F$. Cu ER: oglindești recursiv ($(alpha beta)^R = beta^R alpha^R$)],
  [$"Pref"(L)$], [în AFD, faci finale toate stările din care *se poate ajunge* într-o stare finală],
  [$"Suf"(L)$], [AFN: stare inițială nouă $s'$, cu $s' ->^e q$ pentru fiecare stare $q$ *accesibilă* din $s$; aceleași finale],
  [$"Sub"(L)$], [$"Sub"(L) = "Suf"("Pref"(L))$],
  [$h(L)$], [în ER, înlocuiești fiecare simbol $a$ cu $h(a)$],
)

#problema[Automatul produs pentru $triangle.stroked.t$ (fișa seminarului, ex. 5)][
  Se dau AFD-urile $M_1, M_2$. Construiți un automat $M$ cu $L(M) = L(M_1) triangle.stroked.t L(M_2)$.
][
  Fie $M_i = (K_i, Sigma, delta_i, s_i, F_i)$, ambele *complete*. Definim $M = (K_1 times K_2, Sigma, delta, (s_1, s_2), F)$ cu
  $ delta((p, q), a) = (delta_1(p, a), delta_2(q, a)), quad F = (F_1 times (K_2 without F_2)) union ((K_1 without F_1) times F_2) $
  *Corectitudine.* Prin inducție pe $|w|$: $delta^*((s_1, s_2), w) = (delta_1^*(s_1, w), delta_2^*(s_2, w))$, deci $M$ simulează ambele automate în paralel. $w in L(M)$ $<==>$ exact una dintre componente e finală $<==>$ $w$ e acceptat de exact unul dintre $M_1, M_2$ $<==>$ $w in L(M_1) triangle.stroked.t L(M_2)$.

  *De ce complete:* dacă $delta_1(p, a)$ ar lipsi, perechea s-ar bloca, deși $M_2$ ar mai putea accepta.
]

#problema[Exemplu concret de produs][
  Construiți AFD-ul pentru $L = {w in {a, b}^* | |w|_a "par și" w "se termină cu" b}$.
][
  $M_1$: paritatea lui $a$ (stările $P$, $I$). $M_2$: ultimul simbol ($N$ = nu se termină cu $b$, inițială; $B$ = se termină cu $b$, finală). Produsul are 4 stări; finală doar $(P, B)$.
  #aut(
    (PN: (IN: "a", PB: "b"), PB: (IN: "a", PB: "b"), IN: (PN: "a", IB: "b"), IB: (PN: "a", IB: "b")),
    (PN: (0, 0), PB: (4, 0), IN: (0, -3), IB: (4, -3)),
    final: ("PB",),
    etichete: (PN: "PN", PB: "PB", IN: "IN", IB: "IB"),
    st: ("PN-IN": (curve: .45), "IN-PN": (curve: .45), "PB-PB": (anchor: top), "IB-IB": (anchor: bottom)),
  )
  $a$ schimbă paritatea și face ultimul simbol „nu $b$”; $b$ păstrează paritatea și face ultimul simbol $b$.
]

#problema[$"Suf"(L)$ e regulat (fișa seminarului, ex. 8)][
  Arătați că dacă $L$ e regulat, atunci $"Suf"(L) = {w in Sigma^* | exists w' in L "cu" w "sufix al lui" w'}$ e regulat.
][
  Fie $M = (K, Sigma, delta, s, F)$ un AFD pentru $L$. Fie $A subset.eq K$ stările accesibile din $s$. Construim AFN-ul $M' = (K union {s'}, Sigma, Delta, s', F)$, cu $s'$ stare nouă și
  $ Delta = {(q, a, delta(q, a)) | q in K, a in Sigma} union {(s', e, q) | q in A} $

  *$"Suf"(L) subset.eq L(M')$:* fie $w$ sufix al lui $w' = u w in L$. Fie $q = delta^*(s, u)$; $q in A$. Cum $u w in L$, $delta^*(q, w) in F$. Atunci $M'$ face $s' ->^e q$ și apoi citește $w$, ajungând într-o finală.

  *$L(M') subset.eq "Suf"(L)$:* un calcul acceptor începe cu $s' ->^e q$, $q in A$, apoi citește $w$ până într-o finală. $q$ e accesibil, deci $q = delta^*(s, u)$ pentru un $u$. Atunci $delta^*(s, u w) in F$, deci $u w in L$ și $w$ e sufix al unui cuvânt din $L$.

  Deci $"Suf"(L) = L(M')$ e regulat. (Alternativ: $"Suf"(L) = ("Pref"(L^R))^R$.)
]

#problema[Fără subsecvențe dintr-o mulțime finită (fișa seminarului, ex. 4)][
  Fie $F subset.eq Sigma^*$ finit. Arătați că $L = {w in Sigma^* | w "nu are nicio subsecvență din" F}$ e regulat.
][
  Cuvintele care *au* o subsecvență din $F$ sunt exact $Sigma^* F Sigma^*$. Deci $L = overline(Sigma^* F Sigma^*)$.
  - $F$ e finit, deci regulat: $F = {u_1, dots, u_k}$ e descris de ER-ul $u_1 union dots union u_k$ (sau $emptyset$ dacă $F = emptyset$).
  - $Sigma^*$ e regulat ($(a_1 union dots union a_n)^*$).
  - Concatenarea a trei limbaje regulate e regulată, deci $Sigma^* F Sigma^*$ e regulat.
  - Complementul unui limbaj regulat e regulat, deci $L$ e regulat. $square$
]

#problema[Cuvintele minimale][
  Fie $L$ regulat și $"Min"(L) = {w in L | "niciun prefix propriu al lui" w "nu e în" L}$. Arătați că $"Min"(L)$ e regulat.
][
  Fie $M$ un AFD complet pentru $L$. Construim $M'$: aceleași stări, plus o capcană $d$; pentru fiecare $f in F$ și $a in Sigma$, înlocuim $delta(f, a)$ cu $d$. Finalele rămân $F$.

  Un cuvânt $w$ e acceptat de $M'$ $<==>$ calculul lui $M$ pe $w$ se termină într-o finală *fără să fi trecut printr-o finală înainte* (altfel ar fi căzut în $d$) $<==>$ $w in L$ și niciun prefix propriu al lui $w$ nu e în $L$. Deci $L(M') = "Min"(L)$.
]

#problema[Închiderea folosită pentru a arăta neregularitatea][
  Arătați că $L = {w in {a, b}^* | |w|_a = |w|_b}$ nu e regulat, știind că ${a^n b^n | n >= 0}$ nu e regulat.
][
  Presupunem că $L$ e regulat. $a^* b^*$ e regulat. Intersecția a două limbaje regulate e regulată, deci $L inter a^* b^* = {a^n b^n | n >= 0}$ ar fi regulat. Contradicție. Deci $L$ nu e regulat.
]

#capcana[Direcția contează. Închiderea spune „operație pe regulate ⇒ regulat”. *Nu* spune nimic despre limbaje neregulate. Cele mai frecvente afirmații false la P1:
- *„Orice submulțime a unui limbaj regulat e regulată.”* Fals: ${a^n b^n} subset.eq Sigma^*$, iar $Sigma^*$ e regulat.
- *„Reuniunea unei infinități de limbaje regulate e regulată.”* Fals: ${a^n b^n} = union.big_(n >= 0) {a^n b^n}$, fiecare termen finit, deci regulat.
- *„Dacă $L_1 union L_2$ e regulat, atunci $L_1$ și $L_2$ sunt regulate.”* Fals: $L union overline(L) = Sigma^*$ pentru orice $L$.
- *„Dacă $L_1 L_2$ e regulat, atunci $L_1$, $L_2$ sunt regulate.”* Fals: $L_1 = {a^n b^n | n >= 0}$, $L_2 = Sigma^*$: $L_1 L_2 = Sigma^*$ (pentru că $e in L_1$).
- *„Dacă $L^*$ e regulat, atunci $L$ e regulat.”* Fals: $L = {a^p | p "prim"}$ nu e regulat, dar $L^* = {a^n | n != 1}$ e regulat (orice $n >= 2$ e sumă de 2 și 3).
- *„Dacă $L$ nu e regulat, atunci $overline(L)$ nu e regulat.”* Adevărat! (dacă $overline(L)$ ar fi regulat, atunci și $L = overline(overline(L))$.)
]

#petest[
  *Șablon pentru „arătați că $L'$ e regulat”:*
  + Fie $M = (K, Sigma, delta, s, F)$ un AFD (complet) pentru $L$.
  + Definește complet automatul nou: stări, inițială, tranziții, finale.
  + Arată *ambele* incluziuni: tot ce e în $L'$ e acceptat, și tot ce e acceptat e în $L'$.

  Sau, mai scurt: scrie $L'$ ca o expresie din operații cunoscute (de exemplu, $L' = (L union L^R) inter (Sigma Sigma)^*$) și citează închiderea pentru fiecare operație.
]
