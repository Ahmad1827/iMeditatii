#import "tpl.typ": *

= Automate finite deterministe (P2)

#defn(t: "Definiție (AFD)")[
  Un AFD e $M = (K, Sigma, delta, s, F)$: $K$ mulțime finită de stări, $Sigma$ alfabet, $s in K$ starea inițială, $F subset.eq K$ stările finale și $delta : K times Sigma -> K$ *funcție totală*: din fiecare stare, pentru fiecare simbol, există *exact o* tranziție.

  O *configurație* e o pereche $(q, w) in K times Sigma^*$: starea curentă și ce a rămas de citit. Un pas: $(q, a w) tack.r_M (delta(q, a), w)$. $M$ *acceptă* $w$ dacă $(s, w) tack.r_M^* (q, e)$ cu $q in F$. $L(M)$ = mulțimea cuvintelor acceptate.
]

Se folosește și funcția extinsă $delta^* : K times Sigma^* -> K$, cu $delta^*(q, e) = q$ și $delta^*(q, w a) = delta(delta^*(q, w), a)$. Atunci $L(M) = {w | delta^*(s, w) in F}$.

#capcana[Un AFD are $delta$ *totală*. Dacă îți lipsesc tranziții, adaugă o *stare capcană* (moartă) $d$, nefinală, în care duc toate tranzițiile lipsă și din care orice simbol te lasă tot în $d$. Pe test, scrie explicit că ai adăugat-o; altfel automatul e doar un AFN. Contează mai ales la complement (cap. 8).]

== Metoda: stările = ce trebuie să ții minte

Întreabă-te: *ce informație despre prefixul citit până acum decide dacă îl pot completa până la un cuvânt bun?* Fiecare valoare posibilă a acelei informații e o stare.

- „număr par de $a$” → paritatea: 2 stări;
- „conține $a b a$” → cât din $a b a$ am potrivit deja: 4 stări;
- „lungime divizibilă cu $k$” → lungimea modulo $k$: $k$ stări;
- „două condiții simultan” → perechi de informații (automatul produs, cap. 8).

#problema[Număr par de $a$][
  AFD pentru $L = {w in {a, b}^* | |w|_a "par"}$.
][
  Ținem minte paritatea lui $|w|_a$: starea $P$ (par, inițială și finală) și $I$ (impar). $a$ schimbă starea, $b$ o lasă neschimbată.
  #aut(
    (P: (P: "b", I: "a"), I: (I: "b", P: "a")),
    (P: (0, 0), I: (3, 0)),
    final: ("P",),
    st: ("P-I": (curve: .5), "I-P": (curve: .5), "P-P": (anchor: top), "I-I": (anchor: top)),
  )
  Verificare: $a b a$: $P -> I -> I -> P$, acceptat. $a b$: se oprește în $I$, respins. $e$: rămâne în $P$, acceptat (zero e par).
]

#problema[Conține $a b a$ (și complementul lui)][
  AFD pentru (a) cuvintele care conțin subsecvența $a b a$; (b) cuvintele care *nu* o conțin.
][
  Starea $q_i$ = cel mai lung sufix al textului citit care e prefix al lui $a b a$ ($q_0$: nimic, $q_1$: „$a$”, $q_2$: „$a b$”, $q_3$: am găsit $a b a$).
  #aut(
    (q0: (q0: "b", q1: "a"), q1: (q1: "a", q2: "b"), q2: (q3: "a", q0: "b"), q3: (q3: "a,b")),
    (q0: (0, 0), q1: (2.6, 0), q2: (5.2, 0), q3: (7.8, 0)),
    final: ("q3",),
    st: ("q2-q0": (curve: 1.2, label: (dist: -.25)), "q0-q0": (anchor: top), "q1-q1": (anchor: top), "q3-q3": (anchor: top)),
  )
  Atenție la tranzițiile „de revenire”: din $q_1$ cu $a$ rămâi în $q_1$ (ultimul $a$ poate începe un nou $a b a$); din $q_2$ cu $b$ pierzi tot ($a b b$ nu se termină cu niciun prefix al lui $a b a$), deci $q_0$.

  (b) Același automat, cu $F' = {q_0, q_1, q_2}$. Merge pentru că automatul e *complet* (deterministic și total): fiecare cuvânt ajunge într-o singură stare, deci complementarea finalelor complementează limbajul.
]

#problema[Începe cu $a b$ și se termină cu $b$][
  AFD pentru $L = {w in {a, b}^* | w "începe cu" a b "și se termină cu" b}$.
][
  #aut(
    (q0: (q1: "a", d: "b"), q1: (q2: "b", d: "a"), q2: (q2: "b", q3: "a"), q3: (q3: "a", q2: "b"), d: (d: "a,b")),
    (q0: (0, 0), q1: (2.6, 0), q2: (5.2, 0), q3: (7.8, 0), d: (2.6, -2.3)),
    final: ("q2",),
    st: ("q2-q3": (curve: .5), "q3-q2": (curve: .5), "q2-q2": (anchor: top), "q3-q3": (anchor: top), "d-d": (anchor: bottom)),
  )
  $d$ e starea capcană. $q_2$ = „am văzut $a b$ și ultimul simbol e $b$”, $q_3$ = „am văzut $a b$ și ultimul simbol e $a$”. $a b$ e acceptat ($q_0 -> q_1 -> q_2$).
]

#problema[Numere în binar divizibile cu 3][
  AFD peste ${0, 1}$ care acceptă scrierile binare (cel mai semnificativ bit primul) ale numerelor divizibile cu 3.
][
  Dacă am citit numărul $x$ și vine bitul $c$, noul număr e $2 x + c$. Ținem minte doar $x mod 3$: stările $r_0, r_1, r_2$, cu $delta(r_i, c) = r_((2 i + c) mod 3)$.
  #aut(
    (r0: (r0: "0", r1: "1"), r1: (r0: "1", r2: "0"), r2: (r1: "0", r2: "1")),
    (r0: (0, 0), r1: (3, 0), r2: (6, 0)),
    final: ("r0",),
    st: ("r0-r1": (curve: .5), "r1-r0": (curve: .5), "r1-r2": (curve: .5), "r2-r1": (curve: .5), "r0-r0": (anchor: top), "r2-r2": (anchor: top)),
  )
  Verificare: $110 = 6$: $r_0 ->^1 r_1 ->^1 r_0 ->^0 r_0$, acceptat. $111 = 7$: $r_0 -> r_1 -> r_0 -> r_1$, respins. Acest automat revine în cap. 6 (îl transformăm în ER).
]

#problema[Paritatea lui $a$ și a lui $b$ simultan][
  AFD pentru cuvintele peste ${a, b}$ cu număr par de $a$ *și* număr par de $b$.
][
  Ținem minte perechea de parități: 4 stări, $(P, P)$ inițială și finală. $a$ schimbă prima componentă, $b$ pe a doua.
  #aut(
    (PP: (IP: "a", PI: "b"), IP: (PP: "a", II: "b"), PI: (II: "a", PP: "b"), II: (PI: "a", IP: "b")),
    (PP: (0, 0), IP: (4, 0), PI: (0, -3), II: (4, -3)),
    final: ("PP",),
    etichete: (PP: "PP", IP: "IP", PI: "PI", II: "II"),
    st: ("PP-IP": (curve: .5), "IP-PP": (curve: .5), "PI-II": (curve: .5), "II-PI": (curve: .5), "PP-PI": (curve: .5), "PI-PP": (curve: .5), "IP-II": (curve: .5), "II-IP": (curve: .5)),
  )
  E exemplul tipic de *automat produs*: produsul automatului pentru „$|w|_a$ par” cu cel pentru „$|w|_b$ par”. Cu $F = {I I}$ obții „ambele impare”; cu $F = {P P, I I}$ obții „lungime pară”.
]

#problema[Al doilea simbol de la final e $a$][
  AFD pentru $L = (a union b)^* a (a union b)$.
][
  Ținem minte *ultimele două simboluri* citite (la început presupunem că am citit „$b b$”: nu ajută cu nimic). Stările sunt $b b$, $b a$, $a b$, $a a$; finale sunt cele în care penultimul simbol e $a$: $a b$ și $a a$. Din starea $x y$ cu simbolul $c$ ajungi în $y c$.
  #aut(
    (bb: (bb: "b", ba: "a"), ba: (aa: "a", ab: "b"), aa: (aa: "a", ab: "b"), ab: (ba: "a", bb: "b")),
    (bb: (0, 0), ba: (3.5, 0), aa: (7, 0), ab: (3.5, -2.8)),
    final: ("aa", "ab"),
    etichete: (bb: "bb", ba: "ba", aa: "aa", ab: "ab"),
    st: ("ba-ab": (curve: .45), "ab-ba": (curve: .45), "bb-bb": (anchor: top), "aa-aa": (anchor: top)),
  )
  Un AFN pentru același limbaj are doar 3 stări (cap. 4). Pentru „al $k$-lea simbol de la final e $a$”, AFN-ul are $k + 1$ stări, iar orice AFD are cel puțin $2^k$: memorează ultimele $k$ simboluri și nu se poate mai puțin (cap. 7).
]
