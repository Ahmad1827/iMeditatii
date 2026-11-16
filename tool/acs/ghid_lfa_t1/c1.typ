#import "tpl.typ": *

= Noțiuni de bază: alfabete, șiruri, limbaje

#defn[
  - Un *alfabet* $Sigma$ e o mulțime *finită și nevidă* de simboluri.
  - Un *șir* (cuvânt) peste $Sigma$ e o secvență finită de simboluri din $Sigma$. Șirul fără niciun simbol e $e$, cu $|e| = 0$.
  - $Sigma^*$ = mulțimea tuturor șirurilor peste $Sigma$ (inclusiv $e$); $Sigma^+ = Sigma^* without {e}$.
  - Un *limbaj* peste $Sigma$ e orice submulțime $L subset.eq Sigma^*$.
]

== Operații cu șiruri

- *Concatenarea:* $u v$; $e$ e element neutru: $e w = w e = w$; $|u v| = |u| + |v|$.
- *Puteri:* $w^0 = e$, $w^(i+1) = w^i w$. Exemplu: $(a b)^3 = a b a b a b$.
- *Oglinditul:* $e^R = e$, $(w a)^R = a w^R$; în plus $(u v)^R = v^R u^R$.
- $u$ e *prefix* al lui $w$ dacă $w = u v$ pentru un $v$; *sufix* dacă $w = v u$; *subșir* (subsecvență, factor) dacă $w = x u y$. Prefixele lui $a b a$: $e, a, a b, a b a$.

#capcana[„Subsecvență” în enunțurile seminarului înseamnă bucată *contiguă* ($a b$ e subsecvență a lui $a a b$, dar $a a$ nu e subsecvență a lui $a b a$, deși $a$-urile apar în ordine). Dacă enunțul vrea simboluri ne-contigue, spune explicit „subșir neconsecutiv” / „subcuvânt împrăștiat”.]

== Operații cu limbaje

Pe lângă $union$, $inter$, $without$ și complement $overline(L) = Sigma^* without L$:

- *Concatenarea:* $L_1 L_2 = {u v | u in L_1, v in L_2}$.
- *Puterea:* $L^0 = {e}$, $L^(i+1) = L^i L$.
- *Steaua Kleene:* $L^* = union.big_(i >= 0) L^i$ (orice concatenare de 0 sau mai multe cuvinte din $L$); $L^+ = L L^*$.
- *Oglinditul:* $L^R = {w^R | w in L}$.

#teorema(t: "Reguli de calcul de reținut")[
  $ emptyset L = L emptyset = emptyset quad {e} L = L quad emptyset^* = {e} quad {e}^* = {e} quad (L^*)^* = L^* quad L^+ = L L^* = L^* L $
  $e in L^*$ întotdeauna. $L^+ = L^*$ dacă și numai dacă $e in L$.
]

#problema[Concatenare și stea][
  Fie $L = {a, a b}$. Calculați $L^2$ și spuneți dacă $a b a a b in L^*$, $b a in L^*$.
][
  $L^2 = {a a, a a b, a b a, a b a b}$. $a b a a b = (a b)(a)(a b) in L^3 subset.eq L^*$. Orice cuvânt din $L^*$ începe cu $a$ (sau e $e$), deci $b a in.not L^*$. Mai mult, $L^*$ = cuvintele în care orice $b$ e precedat imediat de un $a$ și care nu încep cu $b$.
]

#capcana[$emptyset != {e}$. $emptyset$ nu are niciun cuvânt; ${e}$ are un cuvânt (cel vid). $emptyset L = emptyset$, dar ${e} L = L$.]

== De ce există limbaje neregulate (argument de numărare)

$Sigma^*$ e infinit *numărabil* (îl enumeri pe lungimi: întâi $e$, apoi cele de lungime 1, …). Mulțimea tuturor limbajelor, $cal(P)(Sigma^*)$, e *nenumărabilă* (argumentul diagonal al lui Cantor). Orice ER sau automat e un șir finit de simboluri, deci există doar o infinitate *numărabilă* de limbaje regulate. Concluzie: aproape toate limbajele nu sunt regulate. Argumentul nu-ți spune însă *care*; pentru un limbaj anume folosești lema de pompare (cap. 10) sau Myhill–Nerode (cap. 7).

#petest[O grilă clasică: „Cum este mulțimea limbajelor regulate / independente de context?” Răspuns: *infinit numărabilă*. „Cum este mulțimea tuturor limbajelor peste $Sigma$?” *Nenumărabilă*.]

== Ierarhia pe scurt

$ "finite" subset.neq "regulate (LR)" subset.neq "independente de context (LIC)" subset.neq "decidabile" subset.neq "Turing-acceptate" $

Orice limbaj *finit* e regulat (o ER care e reuniunea cuvintelor lui). „În cel mai strict sens” înseamnă clasa cea mai mică din care face parte limbajul.
