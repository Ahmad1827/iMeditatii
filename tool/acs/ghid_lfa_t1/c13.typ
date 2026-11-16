#import "tpl.typ": *

= Foaia de memorat

#set text(size: 9.6pt)
#set par(spacing: 0.6em)

#grid(columns: (1fr, 1fr), gutter: 14pt,
[
  #v(4pt) #text(weight: "bold", fill: albastru)[Definiții] #v(-2pt)
  - AFD $(K, Sigma, delta, s, F)$, $delta : K times Sigma -> K$ *totală*.
  - AFN $(K, Sigma, Delta, s, F)$, $Delta subset.eq K times Sigma^* times K$ *finită*.
  - Acceptare AFN: *există* un calcul care citește tot și se oprește într-o finală.
  - $E(q)$: stările accesibile din $q$ doar pe $e$, inclusiv $q$.
  - ER: $emptyset$, $a$, $alpha union beta$, $alpha beta$, $alpha^*$; $e = emptyset^*$. Fără $inter$, fără complement.

  #v(4pt) #text(weight: "bold", fill: albastru)[Identități ER] #v(-2pt)
  $emptyset^* = e$, #h(3pt) $alpha emptyset = emptyset$, #h(3pt) $(alpha^*)^* = alpha^*$, #h(3pt) $(alpha union beta)^* = (alpha^* beta^*)^*$, #h(3pt) $alpha (beta alpha)^* = (alpha beta)^* alpha$.

  #v(4pt) #text(weight: "bold", fill: albastru)[Conversii] #v(-2pt)
  - *ER → AFN:* $union$: inițială nouă, $e$ spre ambele. Concatenare: $e$ din finalele lui $M_1$ în $s_2$. $*$: inițială nouă *finală*, $e$ spre $s_1$, $e$ din finale înapoi în $s_1$.
  - *AFN → AFD:* $s' = E(s)$, $delta'(Q, a) = E({p | q in Q, (q, a, p) in Delta})$, finale = submulțimile care *conțin* o finală. Doar submulțimile accesibile; $emptyset$ = capcană.
  - *AF → ER:* $s' ->^e s$, finale $->^e f'$. Elimini $q$: $p -> r$ devine $delta union alpha beta^* gamma$. Toate perechile, și $p = r$!
  - *Arden:* $X = alpha X union beta$, $e in.not L(alpha)$ ⟹ $X = alpha^* beta$.
  - *Minimizare:* scoți inaccesibilele; $P_0 = {F, K without F}$; spargi după grupul în care ajunge fiecare simbol; până e stabil.

  #v(4pt) #text(weight: "bold", fill: albastru)[Myhill–Nerode] #v(-2pt)
  $L$ regulat ⟺ $approx_L$ are un număr finit de clase = numărul de stări ale AFD-ului minim. $k$ cuvinte deosebite două câte două ⟹ $>= k$ stări; infinit de multe ⟹ neregulat.
],
[
  #v(4pt) #text(weight: "bold", fill: albastru)[Închidere (P1)] #v(-2pt)
  Regulatele sunt închise la: $union, inter, without$, complement, $triangle.stroked.t$, concatenare, $*$, $R$, Pref, Suf, Sub, morfism, morfism invers.
  - Complement: AFD *complet*, $F' = K without F$.
  - Produs: $(p, q) ->^a (delta_1(p, a), delta_2(q, a))$; $inter$: $F_1 times F_2$; $without$: $F_1 times overline(F_2)$; $triangle.stroked.t$: xor.
  - $L^R$: săgeți inversate, $s$ devine finala, inițială nouă cu $e$ spre vechile finale.
  - Pref: finale = stările din care se ajunge la $F$. Suf: inițială nouă cu $e$ spre toate stările accesibile.
  *Nu sunt închise:* submulțimi, reuniuni infinite. $L_1 union L_2$, $L_1 L_2$ sau $L^*$ regulat *nu* implică $L_1, L_2, L$ regulate.

  #v(4pt) #text(weight: "bold", fill: albastru)[Algoritmi (P4)] #v(-2pt)
  - Vid: se ajunge din $s$ la o finală? (BFS)
  - $Sigma^*$: complement vid.
  - Finit: stările utile (accesibile + co-accesibile) nu au cicluri.
  - $subset.eq$: $L_1 inter overline(L_2) = emptyset$. $=$: $triangle.stroked.t$ vid sau AFD-uri minime izomorfe.
  - Șablon: reducere → algoritm → corectitudine → terminare.

  #v(4pt) #text(weight: "bold", fill: albastru)[Pompare (P5)] #v(-2pt)
  $L$ regulat ⟹ $exists n >= 1$, $forall w in L$ cu $|w| >= n$, $exists x y z = w$: $y != e$, $|x y| <= n$, $forall i >= 0 : x y^i z in L$.

  Șablon: prin absurd; fie $n$; *alegi* $w$ (de obicei $a^n dots$); *orice* descompunere ⟹ $y = a^k$, $1 <= k <= n$; *alegi* $i$ ($0$ sau $2$); $x y^i z in.not L$; contradicție.

  Clasice: $a^n b^n$ ($i = 2$), $w w$ ($a^n b a^n b$, $i = 0$), prime ($i = p - k$), pătrate ($n^2 < n^2 + k < (n+1)^2$), $i > j$ ($a^(n+1) b^n$, $i = 0$), $m != l$ (prin complement $inter a^* b^*$).

  #v(4pt) #text(weight: "bold", fill: albastru)[Capcane frecvente] #v(-2pt)
  - AFD cu tranziții lipsă = nu e AFD (adaugă capcana).
  - Complement pe AFN = greșit.
  - $emptyset != {e}$; $emptyset^* = {e}$.
  - Ai uitat $e$-închiderea stării inițiale.
  - La pompare: tu nu alegi $n$ și nici descompunerea.
],
)
