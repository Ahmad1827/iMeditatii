#import "tpl.typ": *

= Minimizarea AFD și teorema Myhill–Nerode (P3, P6)

== Stări echivalente

#defn[
  Într-un AFD $M$, două stări $p, q$ sunt *echivalente* ($p equiv q$) dacă pentru orice $z in Sigma^*$: $delta^*(p, z) in F <==> delta^*(q, z) in F$. Adică niciun sufix nu le poate deosebi.

  $p equiv_n q$: la fel, dar doar pentru sufixe $z$ cu $|z| <= n$.
]

#teorema(t: "Algoritmul de minimizare (rafinarea partițiilor)")[
  + Șterge stările *inaccesibile* din $s$.
  + Partiția inițială (pentru $equiv_0$): ${F, K without F}$. Sufixul $e$ deosebește finalele de nefinale.
  + Rafinare: două stări rămân în același grup doar dacă, pentru *fiecare* simbol $a$, $delta(p, a)$ și $delta(q, a)$ cad în *același grup* al partiției curente. Altfel spargi grupul.
  + Repeți până partiția nu se mai schimbă (cel mult $|K|$ pași). Fiecare grup devine o stare a AFD-ului minim; tranzițiile se iau de la oricare reprezentant.
]

#petest[Pentru fiecare grup scrie un tabel „stare → grupul în care ajunge cu $a$, cu $b$”. Stările cu aceeași „semnătură” rămân împreună. Notează partițiile $P_0, P_1, dots$ cu toate grupurile; corectorul vrea să vadă fiecare pas.]

#problema[Minimizare pas cu pas][
  Minimizați AFD-ul ($s = 0$, $F = {4}$):
  #aut(
    ("0": ("1": "a", "3": "b"), "1": ("1": "a", "2": "b"), "2": ("1": "a", "4": "b"), "3": ("1": "a", "3": "b"), "4": ("1": "a", "3": "b")),
    ("0": (0, 0), "1": (3, 1.5), "2": (6, 1.5), "3": (3, -1.5), "4": (6, -1.5)),
    final: ("4",),
    st: ("1-1": (anchor: top), "3-3": (anchor: bottom), "4-3": (curve: .4), "2-1": (curve: .5), "1-2": (curve: .5), "4-1": (curve: -.3, label: (pos: .3))),
  )
][
  Toate stările sunt accesibile.

  $P_0 = {{0, 1, 2, 3}, {4}}$. Notăm $A = {0, 1, 2, 3}$, $B = {4}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare din $A$*], [*cu $a$ → grup*], [*cu $b$ → grup*],
    [0], [1 ∈ A], [3 ∈ A],
    [1], [1 ∈ A], [2 ∈ A],
    [2], [1 ∈ A], [*4 ∈ B*],
    [3], [1 ∈ A], [3 ∈ A],
  )
  2 are altă semnătură: $P_1 = {{0, 1, 3}, {2}, {4}}$.
  #tabel(
    columns: (auto, auto, auto),
    [*Stare din ${0, 1, 3}$*], [*cu $a$*], [*cu $b$*],
    [0], [1 ∈ {0,1,3}], [3 ∈ {0,1,3}],
    [1], [1 ∈ {0,1,3}], [*2 ∈ {2}*],
    [3], [1 ∈ {0,1,3}], [3 ∈ {0,1,3}],
  )
  $P_2 = {{0, 3}, {1}, {2}, {4}}$. Verificăm ${0, 3}$: amândouă merg cu $a$ în $1$ și cu $b$ în $3 in {0, 3}$. Partiția e stabilă.

  *AFD-ul minim* are 4 stări: $[0 3], [1], [2], [4]$.
  #aut(
    (A: (B: "a", A: "b"), B: (B: "a", C: "b"), C: (B: "a", D: "b"), D: (B: "a", A: "b")),
    (A: (0, 0), B: (3.4, 0), C: (6.8, 0), D: (3.4, -2.8)),
    final: ("D",),
    etichete: (A: "03", B: "1", C: "2", D: "4"),
    st: ("A-A": (anchor: top), "B-B": (anchor: top), "C-B": (curve: .5), "B-C": (curve: .5)),
  )
  Limbajul: $(a union b)^* a b b$ (cuvintele care se termină în $a b b$).
]

== Metoda tabelului (alternativă)

Faci un tabel triunghiular cu toate perechile $\{p, q\}$. Marchezi întâi perechile cu o stare finală și una nefinală. Apoi, repetat: marchezi $\{p, q\}$ dacă există $a$ cu $\{delta(p, a), delta(q, a)\}$ deja marcată. Perechile rămase nemarcate sunt stări echivalente. Dă același rezultat; folosește metoda din seminar.

== Myhill–Nerode

#defn[
  Pentru un limbaj $L$, $x approx_L y$ dacă pentru orice $z in Sigma^*$: $x z in L <==> y z in L$. Un sufix $z$ cu $x z in L$, $y z in.not L$ (sau invers) *deosebește* $x$ de $y$.
]

#teorema(t: "Teorema Myhill–Nerode")[
  $L$ e regulat $<==>$ $approx_L$ are un număr *finit* de clase de echivalență. În plus, numărul de clase e exact numărul de stări ale AFD-ului minim pentru $L$, iar AFD-ul minim e unic (până la redenumirea stărilor).
]

Două folosiri importante:

*1. Margine inferioară pentru numărul de stări.* Dacă găsești $k$ cuvinte deosebite două câte două (o mulțime de „martori”), orice AFD pentru $L$ are cel puțin $k$ stări: două cuvinte deosebite nu pot ajunge în aceeași stare.

*2. Demonstrație de neregularitate.* Dacă găsești o infinitate de cuvinte deosebite două câte două, $L$ nu e regulat.

#problema[Neregularitate cu Myhill–Nerode][
  Arătați că $L = {a^n b^n | n >= 0}$ nu e regulat.
][
  Fie $i != j$. Sufixul $z = b^i$ deosebește $a^i$ de $a^j$: $a^i b^i in L$, $a^j b^i in.not L$. Deci cuvintele $a^0, a^1, a^2, dots$ sunt în clase diferite: $approx_L$ are o infinitate de clase, deci $L$ nu e regulat.
]

#problema[Margine inferioară][
  Arătați că orice AFD pentru $L_k = {w in {a, b}^* | |w| equiv 0 thick (mod k)}$ are cel puțin $k$ stări.
][
  Cuvintele $e, a, a^2, dots, a^(k-1)$ sunt deosebite două câte două: pentru $0 <= i < j < k$, sufixul $z = a^(k - j)$ dă $|a^j z| = k$ (în $L_k$) și $|a^i z| = k - j + i$, care nu e multiplu de $k$, fiindcă $0 < k - j + i < k$. Deci sunt cel puțin $k$ clase. Automatul cu $k$ stări în ciclu (lungimea modulo $k$) arată că $k$ e și suficient.
]

#problema[AFD-ul de la cap. 3 e minim?][
  AFD-ul cu 4 stări pentru „al doilea simbol de la final e $a$” e minim?
][
  Da. Cuvintele $b b, b a, a b, a a$ (ultimele două simboluri) sunt deosebite două câte două: $a b$ și $a a$ sunt în $L$, $b b$ și $b a$ nu, deci $e$ deosebește orice pereche cu o finală și o nefinală. $b b$ și $b a$: sufixul $a$ dă $b b a in.not L$, $b a a in L$. $a b$ și $a a$: sufixul $a$ dă $a b a in.not L$, $a a a in L$. Deci 4 clase, deci minim 4 stări.
]
