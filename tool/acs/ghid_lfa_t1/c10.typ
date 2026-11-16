#import "tpl.typ": *

= Lema de pompare (P5)

#teorema(t: "Lema de pompare pentru limbaje regulate")[
  Dacă $L$ e regulat, atunci există un întreg $n >= 1$ astfel încât orice $w in L$ cu $|w| >= n$ se poate scrie $w = x y z$ cu:
  $ (1) thick y != e, quad (2) thick |x y| <= n, quad (3) thick x y^i z in L "pentru orice" i >= 0. $
]

*De unde vine:* $n$ = numărul de stări ale unui AFD pentru $L$. Citind primele $n$ simboluri din $w$, automatul trece prin $n + 1$ stări, deci (principiul cutiei) o stare se repetă. Bucata citită între cele două apariții e $y$: o buclă, pe care o poți parcurge de oricâte ori ($i >= 0$), inclusiv deloc.

== Cum o folosești: un joc cu un adversar

Ca să arăți că $L$ *nu* e regulat, arăți că lema e falsă pentru $L$. Gândește-te la un joc:

#tabel(
  columns: (auto, 1fr, auto),
  [*Pas*], [*Cine alege*], [*Tu trebuie să…*],
  [1], [adversarul alege $n >= 1$], [lucrezi cu $n$ oarecare],
  [2], [*tu* alegi $w in L$ cu $|w| >= n$], [alegi un $w$ inteligent, care depinde de $n$],
  [3], [adversarul alege $x, y, z$ cu $y != e$, $|x y| <= n$], [tratezi *toate* descompunerile posibile],
  [4], [*tu* alegi $i >= 0$], [arăți că $x y^i z in.not L$],
)

#petest[
  *Șablonul de scris (învață-l pe de rost):*

  Presupunem prin absurd că $L$ e regulat. Fie $n >= 1$ constanta din lema de pompare. Alegem $w = dots in L$; avem $|w| >= n$. Fie $w = x y z$ *o descompunere oarecare* cu $y != e$ și $|x y| <= n$. Cum $|x y| <= n$ și primele $n$ simboluri ale lui $w$ sunt $dots$, rezultă $y = dots$ cu $1 <= k <= n$. Pentru $i = dots$, $x y^i z = dots in.not L$, fiindcă $dots$. Contradicție cu lema, deci $L$ nu e regulat. $square$
]

#idee[*Truc:* alege $w$ astfel încât primele $n$ simboluri să fie *toate la fel* (de obicei $a^n dots$). Atunci $|x y| <= n$ te obligă: $y = a^k$ cu $1 <= k <= n$, un singur caz de tratat.]

#problema[$L = {a^m b^m | m >= 0}$][
  Arătați că $L$ nu e regulat.
][
  Presupunem prin absurd că $L$ e regulat; fie $n$ constanta din lemă. Alegem $w = a^n b^n in L$, $|w| = 2 n >= n$. Fie $w = x y z$ cu $y != e$, $|x y| <= n$. Primele $n$ simboluri sunt $a$, deci $x = a^j$, $y = a^k$, $k >= 1$, $j + k <= n$. Pentru $i = 2$: $x y^2 z = a^(n + k) b^n$. Cum $k >= 1$, $n + k != n$, deci $x y^2 z in.not L$. Contradicție.
]

#problema[$L = {w w | w in {a, b}^*}$][
  Arătați că $L$ nu e regulat.
][
  Presupunem că $L$ e regulat, cu constanta $n$. Alegem $w = a^n b a^n b in L$ (e $u u$ cu $u = a^n b$). Orice descompunere cu $|x y| <= n$, $y != e$ are $y = a^k$, $1 <= k <= n$. Luăm $i = 0$: $x z = a^(n - k) b a^n b$.

  Dacă $a^(n - k) b a^n b = u u$, atunci, fiindcă cuvântul conține exact doi $b$, fiecare $u$ conține exact un $b$; ultimul simbol fiind $b$, $u$ se termină cu $b$, deci $u = a^m b$ și $u u = a^m b a^m b$. Comparând: $m = n - k$ și $m = n$, deci $k = 0$, contradicție.
]

#capcana[La $w w$, alegerea $w = a^n a^n = a^(2 n)$ e *greșită*: pompând $y = a^k$ cu $k$ par, rămâi în $L$, iar adversarul poate alege $k = 2$. Alege un $w$ pentru care *orice* descompunere permisă iese din limbaj.]

#problema[$L = {a^p | p "prim"}$][
  Arătați că $L$ nu e regulat.
][
  Presupunem că $L$ e regulat, cu constanta $n$. Alegem un prim $p >= n + 2$ și $w = a^p$. Orice descompunere are $y = a^k$, $1 <= k <= n$. Luăm $i = p - k$ (e $>= 2$, deci valid):
  $ |x y^(p-k) z| = (p - k) + (p - k) k = (p - k)(k + 1). $
  $p - k >= p - n >= 2$ și $k + 1 >= 2$, deci $(p - k)(k + 1)$ e un produs de doi factori $>= 2$, adică nu e prim. Deci $x y^(p-k) z in.not L$. Contradicție.
]

#problema[$L = {a^(m^2) | m >= 0}$][
  Arătați că $L$ nu e regulat.
][
  Alegem $w = a^(n^2)$, $|w| = n^2 >= n$. $y = a^k$, $1 <= k <= n$. Pentru $i = 2$: $|x y^2 z| = n^2 + k$, iar
  $ n^2 < n^2 + k <= n^2 + n < n^2 + 2 n + 1 = (n + 1)^2. $
  Între două pătrate perfecte consecutive nu e niciun pătrat, deci $x y^2 z in.not L$. Contradicție.
]

#problema[$L = {a^(2^m) | m >= 0}$][
  Arătați că $L$ nu e regulat.
][
  Alegem $m$ cu $2^m > n$ și $w = a^(2^m)$. $y = a^k$, $1 <= k <= n < 2^m$. Pentru $i = 2$: $2^m < 2^m + k < 2^m + 2^m = 2^(m+1)$, deci lungimea nu e putere a lui 2. Contradicție.

  (Atenție: cu $2^m >= n$ în loc de $2^m > n$, cazul $k = n = 2^m$ ar da exact $2^(m+1)$. Detaliile de felul ăsta costă puncte.)
]

#problema[$L = {a^i b^j | i > j}$: pompare „în jos”][
  Arătați că $L$ nu e regulat.
][
  Alegem $w = a^(n+1) b^n in L$. $y = a^k$, $1 <= k <= n$. Pompând în sus ($i >= 2$) rămânem în $L$ (mai mulți $a$), deci luăm $i = 0$: $x z = a^(n + 1 - k) b^n$. Cum $k >= 1$, $n + 1 - k <= n$, deci numărul de $a$ nu mai e strict mai mare: $x z in.not L$. Contradicție.
]

#problema[Palindroame][
  Arătați că $L = {w in {a, b}^* | w = w^R}$ nu e regulat.
][
  Alegem $w = a^n b a^n in L$. $y = a^k$ (din primul bloc), $1 <= k <= n$. Pentru $i = 2$: $a^(n+k) b a^n$; singurul $b$ nu mai e la mijloc, iar oglinditul e $a^n b a^(n+k) != a^(n+k) b a^n$. Deci nu e palindrom. Contradicție.
]

#problema[Când e mai simplu cu închiderea: $L = {a^m b^l | m != l}$][
  Arătați că $L$ nu e regulat.
][
  Pomparea directă e incomodă (orice $w$ ales poate fi pompat astfel încât să rămână $m != l$). Folosim închiderea: dacă $L$ ar fi regulat, atunci și $overline(L) inter a^* b^* = {a^m b^m | m >= 0}$ ar fi regulat (complement și intersecție). Dar acesta nu e regulat (prima problemă din capitol). Contradicție.
]

#problema[Număr dublu de $a$ față de $b$][
  Arătați că $L = {w in {a, b}^* | |w|_a = 2 |w|_b}$ nu e regulat.
][
  Alegem $w = a^(2 n) b^n in L$. Primele $n$ simboluri sunt $a$, deci $y = a^k$, $1 <= k <= n$. Pentru $i = 0$: $x z = a^(2 n - k) b^n$, cu $2 n - k != 2 n$, deci $x z in.not L$. Contradicție.
]

== Capcane și nuanțe

#capcana[
  - Tu *nu* alegi $n$ și nici descompunerea. „Fie $y = a$” e greșit dacă nu arăți că *orice* $y$ permis duce la contradicție.
  - $w$ trebuie să fie *în* $L$ și să aibă $|w| >= n$. Verifică asta explicit.
  - $i$ poate fi $0$ (pompare în jos), și uneori doar $i = 0$ merge.
  - Lema dă o condiție *necesară*, nu și suficientă. Un limbaj care „se pompează” nu e neapărat regulat: $L = {a^i b^j c^k | i = 0 "sau" j = k}$ satisface lema cu $n = 1$, dar nu e regulat, fiindcă $L inter a b^* c^* = {a b^j c^j}$ nu e regulat.
  - Lema nu se folosește pentru a arăta că un limbaj *e* regulat. Pentru asta dai un automat, o ER, sau folosești închiderea.
]
