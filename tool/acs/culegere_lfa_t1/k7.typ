#import "tpl.typ": *

= Întrebări bonus (P6)

Bonusul verifică dacă știi *definițiile exacte* și cazurile-limită. Aproape fiecare întrebare se rezolvă cu una dintre ideile de mai jos.

#metoda[
  - *AFD:* $delta$ e *totală*, deci are exact $|K| dot |Sigma|$ tranziții, iar orice cuvânt ajunge într-o singură stare. *AFN:* $Delta$ e *finită*, dar (la curs) etichetele sunt șiruri, deci $|Delta|$ nu e mărginit; poate fi și $0$.
  - Cazurile-limită: $emptyset$, ${e}$, $Sigma^*$, alfabetul vid ($Sigma^* = {e}$), stări inaccesibile (pot fi oricâte, finale sau nu).
  - Numărare: $Sigma^*$ e numărabil; mulțimea limbajelor e nenumărabilă; mulțimea limbajelor regulate e numărabilă (fiecare are o ER, un șir finit).
  - *Myhill–Nerode:* $x equiv_L y$ dacă $forall z : x z in L <==> y z in L$. Numărul claselor = numărul de stări ale AFD-ului minim; $L$ e regulat ⇔ sunt finit de multe clase.
]

== Definiții și cazuri-limită

#problema[Toate stările sunt finale ($|F| = |K|$)][
  Pentru un AFD și pentru un AFN (ca în curs, $Delta subset.eq K times Sigma^* times K$), stabiliți și justificați: (1) $e in L(M)$; (2) dacă $w in L(M)$, orice prefix al lui $w$ e în $L(M)$; (3) orice limbaj regulat care conține toate prefixele cuvintelor sale admite un astfel de automat.
][
  #tabel(
    columns: (auto, 1fr, 1fr),
    [], [*AFD*], [*AFN*],
    [(1)], [*Adevărat*: $s in F$, iar $(s, e)$ e configurație de acceptare.], [*Adevărat*, același motiv.],
    [(2)], [*Adevărat*: AFD-ul e complet, orice cuvânt ajunge într-o stare (finală), deci $L(M) = Sigma^*$.], [*Fals*: $Delta = {(s, a b, f)}$ acceptă $a b$, dar nu și $a$ (nicio tranziție nu citește doar $a$). Cu tranziții pe simboluri ar fi adevărat.],
    [(3)], [*Fals*: un astfel de AFD acceptă $Sigma^*$, iar $L(a^*)$ peste ${a, b}$ e închis la prefixe, dar nu e $Sigma^*$.], [*Fals* din cauza lui $emptyset$ (închis la prefixe „în gol”, dar orice automat cu toate stările finale acceptă $e$). Pentru $L != emptyset$ e adevărat: în AFD-ul minim scoți capcana și rămân doar stări finale.],
  )
]

#problema[O singură stare finală][
  Poate orice limbaj regulat să fie recunoscut de un AFD cu o singură stare finală? Dar de un AFN?
][
  *AFD: nu.* Fie $L = {e, a}$ peste ${a}$. Presupunem un AFD cu o singură finală $f$. $e in L$ ⇒ $s = f$. $a in L$ ⇒ $delta(s, a) = f = s$. Atunci $delta^*(s, a a) = s = f$, deci $a a in L$: contradicție. (Verificat și exhaustiv pe toate AFD-urile cu cel mult 4 stări.)

  *AFN: da* (pentru $L != emptyset$; pentru $emptyset$ ajunge o finală inaccesibilă): adaugi o stare finală nouă $f$, tranziții $(q, e, f)$ din toate fostele finale, care devin nefinale.

  #capcana[„Unim toate stările finale într-una” schimbă limbajul (stările au viitoruri diferite), iar tranzițiile $e$ nu sunt voie la AFD.]
]

#problema[Tranziții injective][
  Cum arată un AFD în care $delta(q, a) = delta(p, a) <==> q = p$, pentru orice $a in Sigma$ și $p, q in K$?
][
  Pentru $a$ fixat, $q |-> delta(q, a)$ e injectivă pe mulțimea finită $K$, deci bijectivă: fiecare simbol *permută* stările. În fiecare stare intră exact o săgeată etichetată $a$; întorcând săgețile obții tot un AFD complet (automat „reversibil”). Fiecare stare e pe un ciclu pentru fiecare simbol (o permutare se descompune în cicluri). Exemplu: automatul pentru $|w|_a mod 3$.
]

#problema[Câte tranziții?][
  (a) Care e numărul minim și maxim de tranziții ale unui AFD $(K, Sigma, delta, s, F)$? (b) Pentru un AFN cu $Delta subset.eq Q times (Sigma union {e}) times Q$? (c) Pentru un AFN ca în curs? (d) Numărul minim de tranziții ale unui AFD pentru un $L != emptyset$? (e) Al unui AFN care acceptă un singur cuvânt?
][
  (a) Minim = maxim = $|K| dot |Sigma|$: $delta$ e funcție totală.

  (b) Minim $0$, maxim $|Q| dot (|Sigma| + 1) dot |Q| = |Q|^2 (|Sigma| + 1)$ (toate tripletele posibile).

  (c) $Delta$ e finită, dar nemărginită superior (etichetele pot fi oricât de lungi) și poate fi vidă: „finit și nemărginit superior”.

  (d) $1$: cu $|Sigma| = 1$, o stare inițială și finală cu o buclă (acceptă $a^*$). Un AFD are mereu $|K| dot |Sigma| >= 1$ tranziții. În general numărul de tranziții e $>= |K|$.

  (e) $0$: o stare, inițială și finală, fără tranziții, acceptă exact ${e}$.
]

#problema[Câte stări?][
  (a) Numărul minim de stări ale unui AFN pentru ${e}$? (b) Poate un AFN cu 2 stări să accepte ${e}$? Unul cu 3 stări să accepte $emptyset$? (c) Numărul minim de stări finale ale unui AFD care acceptă cel puțin 3 cuvinte? (d) Fie $M$ un AFD cu $L(M) = {w}$ și $Y = {f | (s, w) tack.r^* (f, e)}$. Ce e sigur?
][
  (a) $1$ (inițială, finală, fără tranziții).

  (b) Da și da: stările în plus pot fi inaccesibile; un automat fără stări finale accesibile acceptă $emptyset$.

  (c) $1$: o stare cu buclă pe tot acceptă $Sigma^*$.

  (d) $|Y| = 1$ (determinism: citind $w$ din $s$ ajungi într-o singură stare). Nu e sigur că $|F| = 1$ (pot fi finale inaccesibile) și nici că $|w| > 0$ ($w$ poate fi $e$).
]

#problema[Câte automate?][
  Câte AFD se pot construi pentru: (a) $L = emptyset$ cu $|Sigma| = 4$; (b) $L = {a}$; (c) $L = Sigma^*$; (d) $L(0^*)$ peste ${0, 1}$?
][
  *O infinitate*, în toate cazurile: oricărui AFD îi poți adăuga oricâte stări inaccesibile (sau stări echivalente). Doar AFD-ul *minim* e unic (până la redenumirea stărilor).
]

#problema[Câte AFD cu două stări?][
  Fie $Sigma$ un alfabet. Câte automate finite deterministe cu două stări pot exista? (a) $2^(2|Sigma|)$ (b) $4^(|Sigma|)$ (c) $2^(2|Sigma| + 2)$ (d) o infinitate
][
  Fixăm numele stărilor, $K = {q_0, q_1}$, cu $q_0$ inițială (orice AFD cu 2 stări arată așa după redenumire):
  - $delta : K times Sigma -> K$: $2^(2 |Sigma|)$ funcții (pentru fiecare dintre cele $2|Sigma|$ perechi, 2 alegeri);
  - $F subset.eq K$: $4$ variante.
  Total: $4 dot 2^(2|Sigma|) = 2^(2|Sigma| + 2)$, varianta *(c)*. (Dacă și starea inițială se alege liber, se dublează; dacă numele stărilor sunt libere, sunt o infinitate. Pe test, spune în ce sens numeri: punctajul vine din raționament.)
]

#problema[Două automate extreme][
  Fie $M_1$ un AFD care nu acceptă niciun șir și $M_2$ un AFD care acceptă $Sigma^*$. Ce e întotdeauna adevărat? (a) $M_1$ nu are stări finale și $M_2$ are cel puțin una; (b) $M_1$ poate avea stări finale și $M_2$ nu are cicluri; (c) $M_1$ nu poate avea stări finale și $M_2$ are cel puțin un ciclu; (d) atât $M_1$ cât și $M_2$ pot avea stări finale.
][
  *(d).* $M_1$ poate avea finale la care nu se ajunge. $M_2$ are sigur finale ($s in F$) și sigur cicluri (acceptă cuvinte oricât de lungi). (a) și (c) cad din cauza finalelor inaccesibile ale lui $M_1$; (b) pentru că $M_2$ are cicluri.
]

#problema[Un AFD care acceptă tot ce e scurt][
  Un AFD peste un alfabet cu $|Sigma| = 2$ are $k > 2$ stări și acceptă orice șir cu $|w| <= k$. Ce se poate spune despre $|L(M)|$?
][
  $L(M)$ e *infinit*. Un cuvânt de lungime $k$ trece prin $k + 1$ stări, deci repetă una: drumul lui conține un ciclu, pe un drum spre o finală. Pompându-l obții o infinitate de cuvinte acceptate. Din variantele grilei, singura posibilă e cea care nu pune o margine superioară: $|L(M)| > 2^(k + 2)$.
]

#problema[Alfabetul vid și numărări][
  (a) Fie $Sigma = emptyset$ și $Z = 2^(Sigma^*)$. Cât e $|Z|$? (b) Mulțimea limbajelor regulate peste ${a}$ e finită, numărabilă sau nenumărabilă? (c) Fie $J = {L subset.eq {a, b}^* | |L^*| < infinity}$. Cât e $sum_(L in J) |L|$?
][
  (a) $Sigma^* = {e}$ (cuvântul vid există și peste alfabetul vid), deci $Z = {emptyset, {e}}$, $|Z| = 2$.

  (b) *Infinit numărabilă*: fiecare ${a^n}$ e regulat (infinit de multe), iar fiecare limbaj regulat are o ER, un șir finit peste un alfabet finit (numărabil de multe).

  (c) $L^*$ e finit doar dacă $L$ nu conține cuvinte nevide (altfel $w, w w, w w w, dots in L^*$). Deci $J = {emptyset, {e}}$ și suma e $0 + 1 = 1$.
]

#problema[Limbaje care comută][
  (a) Dacă $L_1 L_2 = L_2 L_1$, rezultă $L_1 = L_2$? (b) Rezultă $(L_1 union L_2)^* subset.eq (L_1 inter L_2)^*$? (c) Dați două limbaje diferite peste ${a, b}$ care comută.
][
  (a) *Nu*: $L_1 = emptyset$, $L_2 = Sigma^*$, ambele concatenări dau $emptyset$.

  (b) *Nu*, același exemplu: $(L_1 union L_2)^* = Sigma^*$, iar $(L_1 inter L_2)^* = emptyset^* = {e}$.

  (c) $L_1$ = cuvintele de lungime pară, $L_2$ = cele de lungime impară: ambele produse sunt „lungime impară”. (Contra-variante din grilă: $a^*$ și $b^*$ nu comută, $a^* b^* != b^* a^*$.)
]

#problema[AFN-uri cu același număr de stări][
  Fie $M_1$, $M_2$ AFN cu $K_1 = K_2$, $Sigma_1 = Sigma_2$, $|Sigma_1| > 1$ și $L(M_1) subset.eq L(M_2)$. Ce relație e între $Delta_1$ și $Delta_2$?
][
  *Niciuna.* Același limbaj se poate accepta cu tranziții complet diferite (redenumește stările, adaugă tranziții spre stări moarte etc.). Incluziunea limbajelor nu spune nimic despre incluziunea relațiilor de tranziție, nici despre $F_1$, $F_2$.
]

#problema[Două afirmații despre clase][
  (1) Mulțimea limbajelor generate de expresii regulate coincide cu mulțimea limbajelor regulate acceptate de automate push-down. (2) Pentru orice $L in "LR"$ infinit, orice submulțime a lui $L$ are o expresie regulată.
][
  (1) *Adevărat*: ambele sunt exact clasa limbajelor regulate.

  (2) *Fals*: ${a^n b^n} subset.eq a^* b^*$, iar ${a^n b^n}$ nu are ER. Mai general: $L$ infinit are nenumărabil de multe submulțimi, iar ER-urile sunt numărabile.
]

== Raționamente

#problema[Cel puțin două stări (testul de recuperare 2017–2018)][
  Fie $L = L(a^* b^*)$. Demonstrați că orice AFD care acceptă $L$ are cel puțin două stări.
][
  Presupunem un AFD cu o singură stare $s$. Fiind complet, toate tranzițiile sunt bucle pe $s$, deci orice cuvânt ajunge în $s$: dacă $s in F$, $L(M) = Sigma^*$; altfel $L(M) = emptyset$. Dar $L$ nu e niciunul dintre ele ($e in L$, $b a in.not L$). Contradicție. (Myhill–Nerode dă chiar 3: $e$, $b$ și $b a$ sunt în clase diferite.)
]

#problema[Funcția $"len"$ pe ER-uri (Testul 1, noiembrie 2023)][
  Fie $Sigma = {0, 1}$. Definiți recursiv $"len"(E) = max{|w| | w in L(E)}$, lungimea maximă a unui șir din $L(E)$. Puteți folosi $"is"_emptyset (E)$, care e $0$ dacă $L(E) = emptyset$ și $1$ altfel, și operații aritmetice.
][
  Pe structura ER-ului (cu convenția $"len" = 0$ pentru limbajul vid și $infinity$ dacă limbajul are cuvinte oricât de lungi):
  - $"len"(emptyset) = 0$, $"len"(e) = 0$, $"len"(a) = 1$ pentru $a in Sigma$;
  - $"len"(E_1 union E_2) = max("len"(E_1), "len"(E_2))$ (un limbaj vid contribuie cu $0$, deci nu strică maximul);
  - $"len"(E_1 E_2) = "is"_emptyset (E_1) dot "is"_emptyset (E_2) dot ("len"(E_1) + "len"(E_2))$: dacă unul e vid, concatenarea e vidă;
  - $"len"(E^*) = 0$ dacă $"len"(E) = 0$ (atunci $L(E^*) = {e}$), altfel $infinity$ (un cuvânt nevid repetat oricât).
  Cu doar $+, -, dot$: $max(x, y) = x dot [x >= y] + y dot (1 - [x >= y])$, unde comparația e simulată ca în enunț. Capcana e la concatenare: fără factorii $"is"_emptyset$, $"len"(a emptyset)$ ar ieși $1$ în loc de $0$.
]

#problema[La fel de multe $a b$ ca $b a$][
  Arătați că $L = {w in {a, b}^* | |w|_(a b) = |w|_(b a)}$ e regulat.
][
  *Ideea:* parcurgând $w$, aparițiile lui $a b$ și $b a$ sunt exact schimbările de literă, și ele *alternează* (după o trecere $a -> b$ urmează o trecere $b -> a$ și invers). Deci numărul lor diferă cu cel mult 1 și sunt egale exact când prima și ultima literă coincid (numărul de schimbări e par).
  $ L = e union a union b union a (a union b)^* a union b (a union b)^* b $
  Contraintuitiv: o condiție care „pare” să compare două contoare nemărginite e regulată. Aici contoarele sunt legate între ele.
]

#problema[Myhill–Nerode: câte stări?][
  (a) Câte stări are AFD-ul minim pentru $L = {w in {a, b}^* | |w|_a equiv |w|_b med (mod 3)}$? (b) Arătați cu Myhill–Nerode că ${a^n b^n}$ nu e regulat.
][
  (a) *3.* Ajunge să ții minte $(|w|_a - |w|_b) mod 3$: stările $r_0$ (inițială, finală), $r_1$, $r_2$; $a$ adună 1, $b$ scade 1. Sunt necesare toate trei: $e$, $a$, $a a$ sunt în clase diferite. Pentru $i != j$ din ${0, 1, 2}$, sufixul $z = a^((3 - i) mod 3)$ pune $a^i z$ în $L$ (diferența devine $0 mod 3$), dar $a^j z$ nu (diferența e $j - i != 0 mod 3$).

  (b) Cuvintele $a^0, a^1, a^2, dots$ sunt două câte două în clase diferite: pentru $i != j$, sufixul $b^i$ dă $a^i b^i in L$ și $a^j b^i in.not L$. O infinitate de clase, deci $L$ nu e regulat. $qed$
]
