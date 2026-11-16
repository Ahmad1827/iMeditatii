#import "tpl.typ": *

= Automate nedeterministe și expresii regulate (P2)

== Automate nedeterministe

#defn(t: "AFN, ca în curs")[
  $M = (K, Sigma, Delta, s, F)$ cu $Delta subset.eq K times Sigma^* times K$ *finită*: o tranziție $(p, u, q)$ citește un șir întreg $u$ (poate fi $e$, un simbol sau mai multe). $M$ acceptă $w$ dacă *există* un drum de la $s$ la o stare finală care citește exact $w$. Lipsa unei tranziții înseamnă „drumul ăsta moare”; nu e nevoie de stare capcană.
]

#metoda[Un AFN *ghicește*. Pentru „se termină cu $u$” / „conține $u$” / „al $k$-lea simbol de la final”, starea inițială are buclă pe tot alfabetul, iar automatul ghicește momentul în care începe partea interesantă și o citește pe un lanț de stări. Pentru „$A$ sau $B$” pui o stare inițială nouă cu tranziții $e$ spre automatele lui $A$ și $B$.]

#problema[Al treilea simbol de la final e $a$][
  AFN cu cel mult 4 stări peste ${a, b}$ pentru cuvintele în care al treilea simbol de la sfârșit este $a$.
][
  Automatul stă în $0$ cât vrea, apoi ghicește că $a$-ul citit acum e al treilea de la final și mai citește exact două simboluri.
  #aut(
    ("0": ("0": "a,b", "1": "a"), "1": ("2": "a,b"), "2": ("3": "a,b"), "3": (:)),
    ("0": (0, 0), "1": (3, 0), "2": (6, 0), "3": (9, 0)),
    final: ("3",),
    st: ("0-0": (anchor: top)),
  )
  $a b b$: $0 ->^a 1 ->^b 2 ->^b 3$ ✓. $b a b b$: $0 ->^b 0 ->^a 1 -> 2 -> 3$ ✓. $a b$: niciun drum nu se termină în 3 ✗. Orice AFD pentru același limbaj are cel puțin $2^3 = 8$ stări (cap. 3, ex. de determinizare).
]

#problema[Conține $a b a$][
  AFN cu cel mult 4 stări peste ${a, b}$ pentru cuvintele care conțin subcuvântul $a b a$.
][
  Buclă la început (înainte de $a b a$), lanțul $a b a$, buclă la final (după).
  #aut(
    ("0": ("0": "a,b", "1": "a"), "1": ("2": "b"), "2": ("3": "a"), "3": ("3": "a,b")),
    ("0": (0, 0), "1": (3, 0), "2": (6, 0), "3": (9, 0)),
    final: ("3",),
    st: ("0-0": (anchor: top), "3-3": (anchor: top)),
  )
  Compară cu AFD-ul (cap. 1): acolo trebuiau scrise toate tranzițiile de întoarcere; aici nondeterminismul le face inutile.
]

#problema[Conține $a a$ sau $b b$][
  AFN peste ${a, b}$ pentru cuvintele care conțin $a a$ sau $b b$.
][
  Două lanțuri care pleacă din aceeași stare și ajung în aceeași stare finală, cu buclă pe tot.
  #aut(
    (s: (s: "a,b", A: "a", B: "b"), A: (f: "a"), B: (f: "b"), f: (f: "a,b")),
    (s: (0, 0), A: (3, 1.3), B: (3, -1.3), f: (6, 0)),
    final: ("f",),
    st: ("s-s": (anchor: bottom), "f-f": (anchor: right)),
  )
]

#problema[Se termină cu $a b$ sau cu $b a$][
  AFN cu cel mult 4 stări peste ${a, b}$.
][
  #aut(
    (s: (s: "a,b", p: "a", r: "b"), p: (f: "b"), r: (f: "a"), f: (:)),
    (s: (0, 0), p: (3, 1.3), r: (3, -1.3), f: (6, 0)),
    final: ("f",),
    st: ("s-s": (anchor: bottom)),
  )
  Atenție: $f$ nu are bucle. După ce am citit ultimele două simboluri, cuvântul trebuie să se termine. Echivalent: cuvintele de lungime cel puțin 2 în care ultimele două simboluri diferă.
]

#problema[$a^* b^* c^*$ cu tranziții $e$][
  AF cu tranziții $e$, cu cel mult 3 stări, peste ${a, b, c}$, pentru $L(a^* b^* c^*)$.
][
  O stare pentru fiecare „zonă”, legate prin $e$: trecerea la zona următoare nu consumă nimic.
  #aut(
    ("0": ("0": "a", "1": "e"), "1": ("1": "b", "2": "e"), "2": ("2": "c")),
    ("0": (0, 0), "1": (3, 0), "2": (6, 0)),
    final: ("2",),
    st: ("0-0": (anchor: top), "1-1": (anchor: top), "2-2": (anchor: top)),
  )
  Doar $2$ e finală, dar $e$ e acceptat: $0 ->^e 1 ->^e 2$. Dacă faci toate stările finale, poți renunța la tranziții $e$? Nu direct: din $0$ trebuie să poți citi și $b$, și $c$. Un AFD are 4 stări: zonele $a$, $b$, $c$ (toate finale) și capcana, pentru $b a$, $c a$, $c b$.
]

#problema[Lungimea multiplu de 2 sau de 3][
  AF cu tranziții $e$, cu cel mult 6 stări, peste ${a}$, pentru $L = {a^n | 2 | n or 3 | n}$.
][
  O stare inițială $s$ care ghicește prin $e$ ce condiție va fi adevărată: un ciclu de lungime 2 și unul de lungime 3.
  #aut(
    (s: (p0: "e", r0: "e"), p0: (p1: "a"), p1: (p0: "a"), r0: (r1: "a"), r1: (r2: "a"), r2: (r0: "a")),
    (s: (0, 0), p0: (3, 1.4), p1: (6, 1.4), r0: (3, -1.4), r1: (6, -1.4), r2: (4.5, -3.4)),
    final: ("p0", "r0"),
    etichete: (p0: $p_0$, p1: $p_1$, r0: $r_0$, r1: $r_1$, r2: $r_2$),
    st: ("p0-p1": (curve: .5), "p1-p0": (curve: .5)),
  )
  Un AFD ar avea nevoie de $n mod 6$: 6 stări pe un singur ciclu, cu finalele $0, 2, 3, 4$.
]

#problema[Tranziții pe șiruri][
  AFN pentru $(a b)^* (b a)^*$, folosind etichete pe șiruri (definiția din curs). Apoi transformați-l într-unul cu tranziții doar pe simboluri.
][
  Cu etichete pe șiruri: o buclă $a b$ pe $p$, o tranziție $e$ spre $r$, o buclă $b a$ pe $r$; $r$ finală.
  #aut(
    (p: (p: "ab", r: "e"), r: (r: "ba")),
    (p: (0, 0), r: (3.5, 0)),
    final: ("r",),
    st: ("p-p": (anchor: top), "r-r": (anchor: top)),
  )
  O tranziție $(p, u_1 u_2 dots u_k, q)$ cu $k >= 2$ se sparge introducând $k - 1$ stări noi: $p ->^(u_1) x_1 ->^(u_2) dots ->^(u_k) q$. Aici: $p ->^a x ->^b p$ și $r ->^b y ->^a r$. Construcția asta e primul pas al determinizării (cap. 3).
]

== Expresii regulate: limbaj → ER

#metoda[
  + Descompune cuvântul în *bucăți care se repetă* și scrie fiecare bucată ca ER. „Ce se poate repeta oricât” devine o stea.
  + Pentru „exact $k$”, „cel mult $k$”: scrii explicit aparițiile, cu ce e permis între ele ($a^* b a^* b a^*$).
  + Pentru „nu conține $u$” e de obicei mai ușor să faci întâi AFD-ul, apoi ER-ul (din automat, prin eliminare) sau să găsești „blocurile permise”.
  + *Verifică în ambele sensuri*: (1) orice cuvânt generat e în limbaj; (2) orice cuvânt din limbaj se poate genera (ia un cuvânt „urât” și descompune-l). Verifică $e$ separat.
]

#defn(t: "Identități care scurtează ER-urile")[
  $emptyset^* = e$ #h(1em) $e^* = e$ #h(1em) $alpha emptyset = emptyset alpha = emptyset$ #h(1em) $alpha e = alpha$ #h(1em) $alpha union emptyset = alpha$ #h(1em) $(alpha^*)^* = alpha^*$ #h(1em) $alpha^* alpha^* = alpha^*$ \
  $(alpha union beta)^* = (alpha^* beta^*)^* = (alpha^* union beta^*)^*$ #h(1em) $alpha^+ = alpha alpha^* = alpha^* alpha$ #h(1em) $(alpha beta)^* alpha = alpha (beta alpha)^*$ #h(1em) $(e union alpha)^* = alpha^*$
]

#problema[Exact doi $b$][
  ER pentru cuvintele peste ${a, b}$ cu exact două simboluri $b$.
][
  $ a^* b a^* b a^* $
  Cei doi $b$ sunt scriși explicit, iar înainte, între și după ei pot fi oricâți $a$. Variante: „cel puțin doi $b$”: $(a union b)^* b (a union b)^* b (a union b)^*$; „cel mult doi”: $a^* (e union b) a^* (e union b) a^*$.
]

#problema[Lungimea multiplu de 3][
  ER pentru cuvintele peste ${a, b}$ a căror lungime e multiplu de 3.
][
  Bucata care se repetă: trei simboluri oarecare. $ ((a union b)(a union b)(a union b))^* $
  Pentru lungime $equiv 1 med (mod 3)$: $(a union b)((a union b)^3)^*$.
]

#problema[Fără simboluri egale alăturate][
  ER pentru cuvintele peste ${a, b}$ în care nu apar nici $a a$, nici $b b$.
][
  Asemenea cuvinte alternează: $a b a b dots$ sau $b a b a dots$. Miezul e $(a b)^*$; în față poate fi un $b$ în plus, la final un $a$ în plus:
  $ (e union b)(a b)^* (e union a) $
  Verificare: $b a b$ = $b dot (a b) dot e$ ✓; $a b a$ = $e dot (a b) dot a$ ✓; $b a$ = $b dot e dot a$ ✓; $e$ ✓.
]

#problema[Cel puțin un $a$ și cel puțin un $b$][
  ER pentru cuvintele peste ${a, b}$ care conțin cel puțin un $a$ și cel puțin un $b$.
][
  Varianta „după primul simbol”: dacă începe cu $a$, după blocul de $a$ de la început trebuie să vină un $b$, și invers.
  $ a^+ b (a union b)^* union b^+ a (a union b)^* $
  Varianta directă (mai lungă, la fel de corectă): $(a union b)^* a (a union b)^* b (a union b)^* union (a union b)^* b (a union b)^* a (a union b)^*$.
]

#problema[Numere pare în binar][
  ER pentru scrierile în baza 2, fără zerouri la început, ale numerelor pare: $0, 10, 100, 110, dots$ Cuvântul vid nu e un număr.
][
  Un număr par se termină cu $0$. Fără zerouri la început: ori e chiar $0$, ori începe cu $1$.
  $ 0 union 1(0 union 1)^* 0 $
  Capcane: $(0 union 1)^* 0$ acceptă și $010$ (zero la început); $1(0 union 1)^* 0$ uită numărul $0$.
]

#problema[$|w|_a mod 4 = 3$][
  ER pentru $L = {w in {a, b}^* | |w|_a mod 4 = 3}$.
][
  Trei $a$ obligatorii, apoi grupuri de câte patru $a$, cu oricâți $b$ peste tot:
  $ b^* a b^* a b^* a b^* (a b^* a b^* a b^* a b^*)^* $
  La examen s-a cerut doar clasa: e regulat (AFD cu 4 stări pe un ciclu, finală $r_3$).
]

#problema[Cinci ER scurte][
  Peste ${a, b}$: (a) lungime pară; (b) cel mult un $a$; (c) fără $a a$; (d) $|w|_a$ multiplu de 3; (e) fără subcuvântul $a b$.
][
  (a) $((a union b)(a union b))^*$. \
  (b) $b^* (e union a) b^*$. \
  (c) $(b union a b)^* (e union a)$: orice $a$ e urmat de $b$, cu excepția unui eventual $a$ final. \
  (d) $b^* (a b^* a b^* a b^*)^*$. \
  (e) $b^* a^*$: după primul $a$ nu mai poate apărea niciun $b$.
]

#problema[$|w|_(a b) = 0$ sau lungime pară][
  Fie $L = {w in {a, b}^* | |w|_(a b) = 0 or |w| "par"}$. Scrieți o ER pentru $L$ și justificați.
][
  Reuniunea a două limbaje: (1) fără $a b$: $b^* a^*$; (2) lungime pară: $((a union b)(a union b))^*$.
  $ b^* a^* union ((a union b)(a union b))^* $
  Justificarea cerută la examen (februarie 2025): ER-ul unei reuniuni e reuniunea ER-urilor; pentru (1), dacă $w$ ar avea un $b$ după un $a$, atunci ar avea și un $a$ urmat imediat de $b$ (ultimul $a$ dinaintea acelui $b$).
]

#problema[Fiecare $a$ urmat de un $b$, și se termină cu $c$][
  ER pentru $L = {x in {a, b, c}^* | "fiecare" a "din" x "e urmat imediat de un" b, "iar" x "se termină cu" c}$.
][
  Blocurile permise: $b$, $c$ și $a b$ (un $a$ trebuie lipit de $b$-ul care îl urmează). La final, obligatoriu $c$:
  $ (b union c union a b)^* c $
  $a b c c$ ✓; $a c$ ✗ ($a$ urmat de $c$); $a b$ ✗ (nu se termină cu $c$). Exercițiul a fost la examenul din 9 iunie 2022 și la testul de recuperare 2017–2018.
]

#problema[Număr impar de $1$ între oricare două zerouri][
  ER pentru limbajul de la ex. 15 (cap. 1): cuvintele peste ${0, 1}$ în care între oricare două zerouri consecutive e un număr impar de $1$.
][
  Dacă nu există niciun $0$: $1^*$. Altfel: $1$-uri la început, primul $0$, apoi grupuri „bloc impar de $1$ + $0$”, apoi $1$-uri la final:
  $ 1^* union 1^* 0 (1 (1 1)^* 0)^* 1^* $
  $1(11)^*$ = un număr impar de $1$. Verificare: $010$ = $0 dot (1 0) dot e$ ✓; $0110$ ✗ (nu se poate: $11$ nu e de forma $1(11)^*$).
]

#problema[$x y$: $x$ fără $01$, $y$ fără $110$][
  ER pentru $L = {x y | x in {0, 1}^* "nu conține" 01, y in {0, 1}^* "nu conține" 110}$.
][
  $x$ fără $01$: după primul $0$ nu mai vine niciun $1$, deci $x in 1^* 0^*$.

  $y$ fără $110$: după ce apar doi $1$ consecutivi, nu mai poate veni niciun $0$. Înainte de asta, orice $1$ e urmat de $0$: blocurile $0$ și $1 0$. Deci $y in (0 union 1 0)^* 1^*$.
  $ E = 1^* 0^* (0 union 1 0)^* 1^* $
  Soluția publicată după examen (2025) scrie $y$ ca $0^* (1 0 0^*)^* 1^*$, care e același limbaj. Simplificare: $0^* (0 union 10)^* = (0 union 10)^*$, deci $E = 1^* (0 union 1 0)^* 1^*$. Nu e $Sigma^*$: $0110 in.not L$ (orice împărțire lasă $01$ în $x$ sau $110$ în $y$).
]

#problema[Perechi interzise][
  Fie $Sigma = {0, 1, 2}$. Scrieți o ER pentru $L = {w | |w|_(01) = |w|_(02) = |w|_(11) = |w|_(10) = |w|_(21) = |w|_(20) = 0}$.
][
  Sunt 9 perechi de simboluri alăturate posibile; 6 sunt interzise, rămân $00$, $12$, $22$. Deci: după $0$ vine doar $0$; după $1$ vine doar $2$; după $2$ vine doar $2$.
  - dacă începe cu $0$: $0^+$;
  - dacă începe cu $1$: $1 2^*$ (al doilea $1$ e imposibil);
  - dacă începe cu $2$: $2^+$.
  $ 0^* union (e union 1) 2^* $
  Exercițiul e din Testul LR nr. 1 al altei grupe, unde se cerea „altă formă de reprezentare decât la exercițiul anterior” (acolo un AF): AFD-ul are stările „început”, „în zona de 0”, „după 1 / în zona de 2” și capcana.
]

#problema[Grilă: $|w|_(00) <= 1$][
  Care ER generează $L = {w in {0, 1}^* | |w|_(00) <= 1}$ (aparițiile lui $00$ se numără și suprapuse: $|000|_(00) = 2$)?
  + $(e union 1 union 01)^* (e union 00 union 0)(e union 1 union 10)^*$
  + $(e union 0)(e union 1 union 10)^* (e union 1 union 10)^* (e union 0)$
  + $((e union 0) 1 1^*)^* (e union 0 union 00)(1 1^* (e union 0))^*$
][
  *Prima și a treia.* Ideea comună: în stânga și în dreapta zonei centrale, fiecare $0$ e lipit de un $1$ (deci nu pot apărea doi $0$ alăturați), iar zona centrală e singurul loc unde poate fi $00$.
  - (1): în stânga, blocuri $1$ și $01$ (orice $0$ urmat de $1$); în dreapta, $1$ și $10$ (orice $0$ precedat de $1$). Centrul $e$, $0$ sau $00$ poate crea cel mult un $00$. ✓
  - (2) e *greșită*: $001$ are un singur $00$, dar nu se poate genera: după $(e union 0)$, blocurile $1$ și $10$ nu pot începe cu $0$, iar $(e union 0)$ de la final e ultimul simbol.
  - (3): $(e union 0) 1 1^*$ = un $0$ opțional urmat de $1$-uri; simetric în dreapta. ✓

  Într-o variantă a grilei, a doua expresie era $(0 union e)(e union 1 union 10)^* (e union 00)(e union 1 union 10)^*$, care e greșită în sens opus: generează $000 = 0 dot e dot 00$, cu $|000|_(00) = 2$.
]

== Gramatică → ER (apare la examen, dar e bun și pentru test)

#problema[$S -> a S | S b | a b$][
  Scrieți o ER pentru limbajul generat de $G$: $S -> a S | S b | a b$.
][
  Orice derivare pune $a$-uri în stânga (cu $a S$) și $b$-uri în dreapta (cu $S b$) și se termină cu $a b$ în mijloc: $a^i (a b) b^j$, $i, j >= 0$.
  $ a^* a b b^* = a^+ b^+ $
  Gramatica e ambiguă ($a a b b$: $S => a S => a S b => a a b b$ și $S => S b => a S b => a a b b$), dar limbajul e regulat.
]

#problema[$S -> S S | S a | b$][
  Ce șiruri generează $S -> S S | S a | b$ peste ${a, b}$? Scrieți o ER.
][
  Orice cuvânt generat începe cu $b$: regula $S -> b$ e singura care pune un simbol pe prima poziție (celelalte încep tot cu $S$). Invers, orice cuvânt $b w$ se poate genera: citește $w$ simbol cu simbol, folosind $S => S a$ pentru $a$ și $S => S S => S b$ pentru $b$.
  $ b (a union b)^* $
]

#problema[Gramatica de la examenul din februarie 2025][
  Ce limbaj generează $S -> X_1 | X_2 | Y_1 | Y_2$, $X_1 -> 01 X_2 | 0 | e$, $X_2 -> 00 X_1 | 0 | e$, $Y_1 -> 10 Y_2 | 1 | e$, $Y_2 -> 11 Y_1 | 1 | e$?
][
  $X_1$ și $X_2$ se apelează alternativ: $X_1 => 01 X_2 => 01 00 X_1 => dots$ Deci $X_1$ generează $(0100)^*$ urmat de un final: oprirea în $X_1$ ($e$ sau $0$) sau în $X_2$ după $01$ ($01$ sau $010$):
  $ X_1: (0100)^* (e union 0 union 01 union 010) $
  La fel: $X_2: (0001)^* (e union 0 union 00 union 000)$; $Y_1$ și $Y_2$ sunt la fel cu $0 <-> 1$:
  $ L = (0100)^* (e union 0 union 01 union 010) union (0001)^* (e union 0 union 00 union 000) union (1011)^* (e union 1 union 10 union 101) union (1110)^* (e union 1 union 11 union 111) $
  În cuvinte: prefixele șirurilor periodice $0100 0100 dots$, $0001 0001 dots$, $1011 dots$, $1110 dots$ Gramatica e regulată (fiecare regulă are cel mult un neterminal, la final), deci limbajul e regulat.
]

== ER → limbaj și ER echivalente

#metoda[Pentru „ce limbaj generează $alpha$?” sau „sunt echivalente?”: caută *invarianți* (ce au în comun toate cuvintele generate: paritatea lui $a$, primul simbol…) și *cuvinte-test* mici. Pentru „nu sunt echivalente” ajunge un cuvânt generat de una și nu de cealaltă; pentru „sunt echivalente” trebuie un argument în ambele sensuri.]

#problema[Ce limbaje sunt?][
  Descrieți în cuvinte: (a) $(a b^* a union b^*)^*$; (b) $a(a^* a union b^*)^*$; (c) $(0^* union 1 union 1^*)^*$ (printr-o ER de cel mult 6 caractere); (d) $(a^* b^*)^*$, $(a^* union b^*)^*$, $(a union b)^*$; (e) $0 e^* union 1 emptyset^*$.
][
  (a) *Cuvintele cu număr par de $a$.* Fiecare bloc are 0 sau 2 $a$, deci totalul e par. Invers, un cuvânt cu număr par de $a$ se taie în $b$-uri și perechi $a b^dots a$. Deci $a a in L$, $a in.not L$, iar $e$ și $a a$ nu conțin $b$.

  (b) *$a (a union b)^*$*, cuvintele care încep cu $a$. Sub stea apar $a$ (din $a^* a$) și $b$ (din $b^*$), deci steaua generează tot $(a union b)^*$. La fel $a(a a^* union b^*)^*$. Deci $a a in L$, $e in.not L$, $b in.not L$.

  (c) Sub stea apar $0$ și $1$, deci $(0 union 1)^*$, care are 6 caractere.

  (d) Toate trei sunt $(a union b)^*$: sub fiecare stea se pot genera separat $a$ și $b$.

  (e) $e^* = e$ și $emptyset^* = e$, deci $0 e^* union 1 emptyset^* = 0 union 1$.
]

#problema[ER echivalente cu $a^* b^*$ (grilă din teste)][
  Care sunt ER valide și echivalente cu $E = a^* b^*$? (a) $(a union b)^* emptyset^* b^*$; (b) $(a union emptyset)^* (b emptyset^* union a emptyset)^*$; (c) $((a union b)^* emptyset) a^* b^* emptyset^*$; (d) $(a union b)^* inter a^* b^*$.
][
  - (a) $emptyset^* = e$, deci $(a union b)^* b^* = (a union b)^*$: generează și $b a$. ✗
  - (b) $(a union emptyset)^* = a^*$; $b emptyset^* = b$; $a emptyset = emptyset$; deci $a^* (b union emptyset)^* = a^* b^*$. ✓
  - (c) conține concatenarea cu $emptyset$, deci e $emptyset$. ✗
  - (d) $inter$ nu e un operator al ER-urilor: expresia nu e validă (chiar dacă limbajul descris ar fi bun). ✗
]

#problema[ER pentru o reuniune][
  Care e ER pentru $L(a(a union b)^*) union L(b(a union b)^*)$?
][
  Cuvintele care încep cu $a$ sau cu $b$ = toate cuvintele nevide:
  $ (a union b)(a union b)^* = (a union b)^+ $
  Nu $(a union b)^*$: $e$ nu e în niciunul dintre limbaje.
]
