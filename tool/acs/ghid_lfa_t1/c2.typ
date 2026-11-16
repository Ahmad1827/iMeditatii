#import "tpl.typ": *

= Expresii regulate (P2)

#defn(t: "Definiție (recursivă)")[
  Expresiile regulate (ER) peste $Sigma$ și limbajele pe care le descriu:
  - $emptyset$ e ER, cu $L(emptyset) = emptyset$;
  - fiecare $a in Sigma$ e ER, cu $L(a) = {a}$;
  - dacă $alpha, beta$ sunt ER, atunci sunt ER și $(alpha union beta)$, $(alpha beta)$, $alpha^*$, cu $L(alpha union beta) = L(alpha) union L(beta)$, $L(alpha beta) = L(alpha) L(beta)$, $L(alpha^*) = L(alpha)^*$;
  - nimic altceva nu e ER.

  Prescurtări: $e$ înseamnă $emptyset^*$ (descrie ${e}$), $alpha^+ = alpha alpha^*$, $Sigma$ înseamnă $(a union b union dots)$. Un limbaj e *regulat* dacă e descris de o ER.
]

*Precedența:* $*$ leagă cel mai tare, apoi concatenarea, apoi $union$. Deci $a b^* union c$ înseamnă $(a (b^*)) union c$.

#capcana[$inter$, complementul și $without$ *nu* sunt operatori ai ER. Limbajul obținut e tot regulat (cap. 8), dar $a^* inter b^*$ nu e o expresie regulată validă. La fel, $alpha^2$ sau $alpha^n$ cu $n$ variabil nu sunt ER; $alpha^2$ e doar prescurtarea lui $alpha alpha$.]

== Identități utile

#tabel(
  columns: (1fr, 1fr),
  [*Identitate*], [*De ce*],
  [$alpha union alpha = alpha$, #h(4pt) $alpha union emptyset = alpha$], [reuniune de mulțimi],
  [$alpha emptyset = emptyset alpha = emptyset$], [nu ai ce lipi],
  [$alpha e = e alpha = alpha$], [$e$ e neutru],
  [$emptyset^* = e$, #h(4pt) $(alpha^*)^* = alpha^*$, #h(4pt) $(e union alpha)^* = alpha^*$], [steaua include deja $e$],
  [$alpha^* alpha = alpha alpha^* = alpha^+$], [cel puțin o repetare],
  [$(alpha union beta)^* = (alpha^* beta^*)^* = (alpha^* union beta^*)^*$], [orice amestec],
  [$alpha (beta alpha)^* = (alpha beta)^* alpha$], [„alunecare”: $alpha beta alpha beta alpha$],
  [$alpha (beta union gamma) = alpha beta union alpha gamma$], [distributivitate],
)

#capcana[$(alpha union beta)^* != alpha^* union beta^*$: $a b in L((a union b)^*)$, dar $a b in.not L(a^* union b^*)$. Și $(alpha beta)^* != alpha^* beta^*$: $a b a b$ e în primul, nu în al doilea.]

== Metoda: din cuvinte în ER

+ Scrie 4–5 cuvinte din limbaj, *inclusiv cele mai scurte* ($e$? un singur simbol?).
+ Găsește „structura”: ce bucăți se repetă (devin $(dots)^*$), ce e obligatoriu (concatenare), ce variante sunt (reuniune).
+ Verifică ER-ul pe cuvintele de la pasul 1 și pe 2 cuvinte care *nu* sunt în limbaj.

Peste tot mai jos $Sigma = {a, b}$.

#problema[Traduceri limbaj → ER][
  Scrieți câte o ER pentru:
  (a) cuvintele care conțin $a b a$; (b) cuvintele cu număr par de $a$; (c) cuvintele care nu conțin $b b$; (d) cuvintele care încep cu $a b$ și se termină cu $b$; (e) cuvintele în care orice $a$ e urmat imediat de un $b$; (f) cuvintele cu cel mult doi de $a$; (g) cuvintele în care al treilea simbol de la final e $a$; (h) cuvintele care nu conțin $a b$; (i) cuvintele de lungime multiplu de 3.
][
  #tabel(
    columns: (auto, auto, 1fr),
    [], [*ER*], [*Explicație / verificare*],
    [(a)], [$(a union b)^* a b a (a union b)^*$], [orice, apoi $a b a$, apoi orice],
    [(b)], [$b^* (a b^* a b^*)^*$], [$a$-urile vin în perechi; între ele, oricâți $b$],
    [(c)], [$(a union b a)^* (e union b)$], [orice $b$ e urmat de $a$, cu excepția, poate, ultimului],
    [(d)], [$a b union a b (a union b)^* b$], [*atenție:* $a b$ însuși e în limbaj (începe cu $a b$ și se termină cu $b$)],
    [(e)], [$(b union a b)^*$], [blocuri: un $b$ singur sau $a b$; $e$ e în limbaj],
    [(f)], [$b^* (e union a) b^* (e union a) b^*$], [0, 1 sau 2 de $a$, cu $b$-uri oriunde],
    [(g)], [$(a union b)^* a (a union b)(a union b)$], [ultimele trei: $a$, apoi oricare două],
    [(h)], [$b^* a^*$], [după primul $a$ nu mai poate veni $b$],
    [(i)], [$((a union b)(a union b)(a union b))^*$], [blocuri de câte 3],
  )
]

#problema[Traduceri ER → limbaj][
  Descrieți în cuvinte: (a) $(a union b)^* a (a union b)^*$; (b) $(a a)^*(b b)^* b$; (c) $(a b union b)^*$; (d) $a^* b^* a^*$; (e) $(a b)^* a$; (f) $a^* inter b^*$.
][
  (a) cuvintele care conțin cel puțin un $a$. (b) ${a^(2 m) b^(2 n + 1) | m, n >= 0}$: un număr par de $a$, urmat de un număr impar de $b$. (c) cuvintele în care orice $a$ e urmat imediat de $b$ (același limbaj ca (e) de mai sus). (d) cuvintele de forma „$a$-uri, $b$-uri, $a$-uri”, adică cel mult un bloc de $b$-uri. (e) ${a, a b a, a b a b a, dots}$: cuvintele care alternează, încep și se termină cu $a$ (identitatea de alunecare: $(a b)^* a = a (b a)^*$). (f) Capcană: nu e ER, $inter$ nu e operator al ER (limbajul ar fi ${e}$).
]

#problema[Grilă din testele vechi: ER echivalente cu $a^* b^*$][
  Care sunt ER valide și echivalente cu $E = a^* b^*$? (a) $(a union b)^* emptyset^* b^*$; (b) $(a union emptyset)^* (b emptyset^* union a emptyset)^*$; (c) $((a union b)^* emptyset) a^* b^* emptyset^*$; (d) $(a union b)^* inter a^* b^*$.
][
  Simplificăm cu identitățile. (a) $emptyset^* = e$, deci $(a union b)^* b^* = (a union b)^*$: *nu*. (b) $a union emptyset = a$; $b emptyset^* = b e = b$; $a emptyset = emptyset$; deci $(b union emptyset)^* = b^*$ și totul e $a^* b^*$: *da*. (c) $(dots) emptyset = emptyset$, iar concatenarea cu $emptyset$ dă $emptyset$: *nu*. (d) nu e ER ($inter$). Răspuns: *doar (b)*.
]

#problema[Încă trei, mai grele][
  (a) cuvintele în care orice $a$ e urmat de *cel puțin doi* $b$; (b) cuvintele cu număr par de $a$ *și* număr par de $b$; (c) cuvintele în care nu apar doi $a$ consecutivi și nici doi $b$ consecutivi.
][
  (a) $(b union a b b)^*$. După un $a$ vin obligatoriu $b b$; ceilalți $b$ pot sta oriunde.

  (b) Gândește-te la cuvânt în perechi de simboluri. Perechile $a a$ și $b b$ nu schimbă paritățile; $a b$ sau $b a$ schimbă ambele parități. Între două perechi „mixte” trebuie să fie oricâte perechi „pure”:
  $ ((a a union b b) union (a b union b a)(a a union b b)^*(a b union b a))^* $
  (Se obține și prin eliminarea stărilor din AFD-ul cu 4 stări; vezi cap. 6.)

  (c) Cuvintele alternează: $(e union b)(a b)^*(e union a)$. Verificare: $e, a, b, a b, b a, a b a, b a b$ sunt toate generate.
]

#idee[Pe test, dacă nu vezi direct ER-ul, desenează întâi un AFD (cap. 3) și transformă-l cu eliminarea stărilor (cap. 6). E mai lent, dar sigur.]
