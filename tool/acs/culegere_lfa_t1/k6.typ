#import "tpl.typ": *

= Lema de pompare și clasificarea limbajelor (P5)

#teorema(t: "Lema de pompare pentru limbaje regulate")[
  Dacă $L$ e regulat, există $p >= 1$ astfel încât orice $w in L$ cu $|w| >= p$ se scrie $w = x y z$ cu
  + $|x y| <= p$, #h(2em) 2. $|y| >= 1$, #h(2em) 3. $x y^i z in L$ pentru orice $i >= 0$.
]

#metoda[
  *Șablonul* (scrie-l exact așa, e ce se punctează):
  + Presupunem prin reducere la absurd că $L$ e regulat. Fie $p$ constanta din lemă.
  + *Alegem* $w = dots$ (în funcție de $p$). Verificăm: $w in L$ și $|w| >= p$.
  + Fie *orice* împărțire $w = x y z$ cu $|x y| <= p$, $|y| >= 1$. Din $|x y| <= p$ rezultă *unde* e $y$ (de obicei: doar în primul bloc), deci $y = a^k$ cu $1 <= k <= p$.
  + *Alegem* $i$ (de obicei 0 sau 2) și arătăm $x y^i z in.not L$.
  + Contradicție cu lema, deci $L$ nu e regulat. $qed$

  *Cine ce alege:* lema spune $exists p forall w exists x y z forall i$. Ca s-o negi: $forall p exists w forall x y z exists i$. *Tu* alegi $w$ și $i$; $p$ și împărțirea sunt ale adversarului, deci trebuie să le acoperi pe toate.
]

#capcana[
  - Nu alegi $p$ (de exemplu „fie $p = 3$”) și nu alegi împărțirea („fie $y = a$”).
  - $w$ trebuie să fie în $L$ și să depindă de $p$: $w = a^5 b^5$ e greșit.
  - Lema nu demonstrează că un limbaj *e* regulat: e o condiție necesară, nu suficientă (exercițiul cu #sym.hash 333 de mai jos).
]

#petest[Alegerea lui $w$ e jumătate din problemă. Alege-l astfel încât primele $p$ simboluri să fie *toate la fel* ($a^p dots$): atunci $|x y| <= p$ forțează $y = a^k$ și nu mai ai cazuri de discutat.]

== Demonstrații

#problema[$L = {a^n b^n | n >= 0}$ (modelul, cu barem)][
  Demonstrați, folosind lema de pompare, că $L$ nu e regulat.
][
  Presupunem că $L$ e regulat; fie $p$ constanta din lemă. Alegem $w = a^p b^p in L$, $|w| = 2p >= p$. Fie $w = x y z$ cu $|x y| <= p$, $|y| >= 1$. Cum primele $p$ simboluri ale lui $w$ sunt $a$, $x y$ conține doar $a$: $x = a^j$, $y = a^k$, $z = a^(p - j - k) b^p$, cu $k >= 1$. Pentru $i = 2$: $x y^2 z = a^(p + k) b^p in.not L$, pentru că $p + k != p$. Contradicție, deci $L$ nu e regulat. $qed$
  #barem[0,5 p presupunerea și alegerea lui $w$ (cu $w in L$, $|w| >= p$); 0,5 p forma lui $y$ dedusă din $|x y| <= p$ (pentru *orice* împărțire); 0,5 p alegerea lui $i$ și calculul; 0,5 p concluzia.]
]

#problema[$|w|_a = |w|_b$][
  Arătați că $L = {w in {a, b}^* | |w|_a = |w|_b}$ nu e regulat. Puteți folosi lema de pompare sau proprietăți de închidere.
][
  *Cu închiderea (mai scurt).* Dacă $L$ ar fi regulat, atunci $L inter L(a^* b^*) = {a^n b^n}$ ar fi regulat (intersecție de limbaje regulate). Dar ${a^n b^n}$ nu e regulat (ex. 1). Contradicție. $qed$

  *Cu pomparea.* $w = a^p b^p in L$; $y = a^k$, $k >= 1$; $x y^2 z = a^(p + k) b^p$ are mai mulți $a$ decât $b$, deci $in.not L$.

  #capcana[Cu $w = (a b)^p$ nu merge: adversarul ia $y = a b$, iar $(a b)^i$ păstrează egalitatea.]
]

#problema[$L = {w w | w in {a, b}^*}$][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^p b a^p b in L$ (cu jumătatea $a^p b$), $|w| >= p$. $|x y| <= p$ ⇒ $y = a^k$, $k >= 1$, în primul bloc. $x y^2 z = a^(p + k) b a^p b$. Are lungimea $2p + 2 + k$. Dacă $k$ e impar, lungimea e impară, deci nu e de forma $u u$. Dacă $k$ e par, jumătățile au lungimea $p + 1 + k/2$: prima e $a^(p + k/2 + 1)$ (doar $a$, pentru că $p + k/2 + 1 <= p + k$), a doua conține $b$-uri. Diferă, deci $in.not L$. $qed$

  #capcana[Cu $w = a^p a^p$ nu merge: $a^(2p) = (a^p)(a^p)$, dar și $a^(2p + 2) in L$; adversarul ia $|y| = 2$. Îți trebuie un $w$ care „blochează” cu $b$-urile.]
]

#problema[$L = {a^n | n "prim"}$][
  Demonstrați că $L$ nu e regulat.
][
  Fie $q >= p$ un număr prim și $w = a^q in L$. $y = a^k$, $1 <= k <= p$. Alegem $i = q + 1$:
  $ |x y^(q+1) z| = q + q k = q (1 + k). $
  Ambii factori sunt $>= 2$, deci numărul nu e prim: $x y^(q+1) z in.not L$. $qed$

  Remarcă: $i = 2$ nu merge în general ($q + k$ poate fi prim). „Pompezi” de exact $q$ ori în plus ca să faci lungimea multiplu de $q$.
]

#problema[$L = {a^(n^2) | n >= 0}$][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^(p^2)$, $y = a^k$ cu $1 <= k <= p$. Pentru $i = 2$: $|x y^2 z| = p^2 + k$ și
  $ p^2 < p^2 + k <= p^2 + p < p^2 + 2p + 1 = (p + 1)^2. $
  Lungimea e strict între două pătrate consecutive, deci nu e pătrat perfect. $qed$
]

#problema[$L = {a^(2^n) | n >= 0}$][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^(2^p)$ (lungimea $2^p >= p$). $y = a^k$, $1 <= k <= p$. Pentru $i = 2$: $2^p < 2^p + k <= 2^p + p < 2^p + 2^p = 2^(p+1)$ (pentru că $p < 2^p$). Lungimea e strict între două puteri consecutive ale lui 2. $qed$
]

#problema[$L = {a^i b^j | i > j}$: pompare în jos][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^(p + 1) b^p in L$. $y = a^k$, $k >= 1$. Pomparea în sus nu ajută ($a^(p+1+k) b^p in L$). Pompăm *în jos*, $i = 0$: $x z = a^(p + 1 - k) b^p$, cu $p + 1 - k <= p$, deci $i > j$ nu mai are loc: $in.not L$. $qed$
]

#problema[Palindroame][
  Demonstrați că $L = {w in {a, b}^* | w = w^R}$ nu e regulat.
][
  $w = a^p b a^p in L$. $y = a^k$ în primul bloc. $x y^2 z = a^(p + k) b a^p$: $b$-ul nu mai e la mijloc, oglinditul e $a^p b a^(p + k) != a^(p+k) b a^p$. $qed$
]

#problema[$L = {a^i b^j | i <= j}$][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^p b^p in L$ (egalitatea e la limită: orice $a$ în plus strică). $y = a^k$, $i = 2$: $a^(p + k) b^p$, cu $p + k > p$, deci $in.not L$. $qed$

  Morala: pentru $i <= j$ pompezi în sus, pentru $i > j$ pompezi în jos (ex. 7). Alege $w$ *la limita* condiției.
]

#problema[$L = {a^n b^m c^(n + m)}$][
  Demonstrați că $L$ nu e regulat.
][
  $w = a^p b^p c^(2p)$. $y = a^k$. $x y^2 z = a^(p+k) b^p c^(2p)$: $p + k + p != 2p$. $qed$
]

#problema[Paritate și comparație (grilă din teste)][
  Fie $L = {w in {a, b}^* | |w|_a "par", |w|_b "impar și" |w|_b > |w|_a}$. Arătați că $L$ nu e regulat.
][
  $w = a^(2p) b^(2p + 1)$: $2p$ e par, $2p + 1$ impar și mai mare. $y = a^k$, $1 <= k <= p$. Pentru $i = 2$: $x y^2 z = a^(2p + k) b^(2p + 1)$.
  - dacă $k$ e impar, $|w|_a = 2p + k$ e impar: $in.not L$;
  - dacă $k$ e par, $k >= 2$, deci $|w|_a = 2p + k >= 2p + 2 > 2p + 1 = |w|_b$: $in.not L$.
  În ambele cazuri contradicție. $qed$ (De reținut din grilă: $e in.not L$, pentru că $0$ nu e impar.)
]

#problema[Două jumătăți cu $|w|_1 = 2 |w|_0$ (examen)][
  Demonstrați că $L = {w_1 w_2 in {0, 1}^+ | |w_1|_1 = 2 |w_1|_0 "și" |w_2|_1 = 2 |w_2|_0}$ nu e regulat.
][
  *Observație care simplifică.* Dacă $w = w_1 w_2$ cu ambele condiții, atunci $|w|_1 = 2 |w|_0$. Invers, dacă $|w|_1 = 2|w|_0$, alegi $w_1 = e$, $w_2 = w$. Deci $L = {w != e | |w|_1 = 2 |w|_0}$.

  $w = 0^p 1^(2p) in L$. $y = 0^k$, $k >= 1$. Pentru $i = 0$: $0^(p - k) 1^(2p)$ are $|w|_1 = 2p != 2(p - k)$, deci $in.not L$. $qed$

  (Soluția publicată folosea $w = 0^p 1^(2p) 0 1 1$ și $i = 0$, cu același raționament: după pompare, $|w|_1 = 2p + 2 > 2 |w|_0$, deci nicio împărțire nu mai merge.)
]

#problema[Același număr de alternanțe (examen)][
  $"flip"(w)$ = numărul de apariții ale lui $01$ în $w$ (trecerile de la $0$ la $1$): $"flip"(01) = 1$, $"flip"(10) = 0$, $"flip"(00001) = 1$, $"flip"(01011100010) = 3$. Demonstrați că $L = {w_1 w_2 | |w_1| = |w_2| "și" "flip"(w_1) = "flip"(w_2)}$ nu e regulat.
][
  $w = 0^p 1^p 0^p 1^p in L$: $w_1 = w_2 = 0^p 1^p$, cu $"flip" = 1$. $y = 0^k$, $1 <= k <= p$, în primul bloc. Pompăm mult, cu $i = 2p + 1$:
  $ w' = 0^(p + 2p k) 1^p 0^p 1^p, quad |w'| = 4p + 2p k "(par)". $
  Jumătatea are lungimea $2p + p k$, iar primul bloc are $p + 2 p k >= 2p + p k$ zerouri (pentru că $p k >= p$). Deci prima jumătate e doar din $0$: $"flip" = 0$. A doua jumătate se termină cu $0^p 1^p$, deci conține $01$: $"flip" >= 1$. Așadar $w' in.not L$. $qed$

  #capcana[Cu $i = 2$ nu merge: pentru $k$ par, jumătățile $0^(p+k) 1^(p - k\/2)$ și $1^(k\/2) 0^p 1^p$ au amândouă un singur $01$. Când nu iese din prima, pompează mai mult: $i$ poate depinde de $p$ și de $k$.]
]

#problema[$"int"(w) >= "int"(w^R)$][
  Fie $L = {w in {0, 1}^* | "int"(w) >= "int"(w^R)}$, unde $"int"$ e valoarea în baza 2. Arătați că $L$ nu e regulat.
][
  Intersectăm cu limbajul regulat $0^* 1 0^*$: pentru $w = 0^a 1 0^b$, $"int"(w) = 2^b$ și $"int"(w^R) = "int"(0^b 1 0^a) = 2^a$. Deci $L inter 0^* 1 0^* = {0^a 1 0^b | b >= a}$.

  Acesta nu e regulat: $w = 0^p 1 0^p$, $y = 0^k$ în primul bloc, $i = 2$: $0^(p+k) 1 0^p$ are $b = p < p + k = a$. Dacă $L$ ar fi regulat, intersecția ar fi regulată: contradicție. $qed$
]

#problema[Neregulat și totuși nu satisface lema (grila #sym.hash 333)][
  Fie $L = {w in {a, b}^* | |w|_a = |w|_b, |w|_(a a a a) = 0, |w|_(b b b b) = 0}$. Este $L$ regulat? Satisface lema de pompare?
][
  *Nu e regulat și nici nu satisface lema.* Arătăm direct că lema nu e satisfăcută; de aici rezultă și că $L$ nu e regulat.

  Pentru orice $p$, fie $w = (a a a b)^p med a med (b b b a)^p med b$. Are $4p + 1$ de $a$ și $4p + 1$ de $b$, iar cel mai lung bloc de litere egale are 3: $w in L$. Primele $p$ simboluri sunt în $(a a a b)^p$. Fie $w = x y z$ cu $|x y| <= p$, $|y| >= 1$:
  - dacă $|y|_a != |y|_b$, atunci $x y^2 z$ nu mai e echilibrat: $in.not L$;
  - dacă $|y|_a = |y|_b$: singurele subcuvinte echilibrate ale lui $a a a b a a a b dots$ sunt $a b$ și $b a$ (orice bucată mai lungă are de 3 ori mai mulți $a$). Pentru $i = 0$ se lipesc două blocuri de $a$: $y = a b$ lasă $dots a a | a a a b dots$, iar $y = b a$ lasă $dots a a a | a a b dots$; în ambele cazuri apare $a a a a$: $in.not L$.
  Deci lema nu e satisfăcută pentru niciun $p$, iar $L$ nu e regulat.

  #capcana[Pe grila de pe Moodle răspunsul marcat corect era „$L in.not "LR"$ și $L$ satisface lema de pompare”. Demonstrația de mai sus (verificată și cu calculatorul pentru $p <= 39$) arată că a doua parte e falsă. Dacă primești întrebarea, discut-o cu asistentul.]
]

== În ce clasă e limbajul? (în sensul cel mai strict)

#metoda[
  + E *finit*? (atunci e regulat și răspunsul „în sensul cel mai strict” e „finit”).
  + Condiția se poate verifica cu *memorie mărginită*? (resturi modulo $k$, un număr *mărginit* de valori, perechi fixe) ⇒ regulat; dă ER-ul sau automatul.
  + Cere *comparații între contoare nemărginite* ($n = m$, $n > m$, $n^2$, prime) ⇒ de obicei nu e regulat; demonstrezi cu pompare sau închidere.
  + Atenție la condițiile care *par* să compare, dar nu restrâng nimic ($p >= -n$, $|v| = 2$, $p <= 100$).
]

#problema[Douăsprezece limbaje de clasificat][
  În ce clasă e fiecare (finit / regulat infinit / neregulat)?
  + ${w in {a, b}^* | |w|_a mod 4 = 3}$
  + ${v w v | v, w in {a, b}^*, |v| = 2}$
  + ${a^i b^j c^k d^m | i + j + k + m "multiplu de" 5}$
  + ${a^k b^k | 1 <= k <= 8}$
  + ${a^n b^k c^(n + p) | n, k >= 0, p >= -n}$
  + ${a^p b^k a^p | p <= 100 < k}$
  + ${w w | w in {a}^*}$
  + ${w in {1}^* | w = x^n y^n z^n, x, y, z in {1}^*, n >= 0}$
  + ${u a^p | u in {a, b}^*, p "prim", p <= 200}$
  + ${w in {0, 1}^* | |w|_1 "prim"}$
  + ${a^n | n "prim sau" n "impar"}$
  + $L' = {w | exists w_1, w_2 in L, w = w_1 w_2, |w|_a >= 2}$, cu $L$ regulat
][
  + *Regulat* (AFD cu 4 stări pe un ciclu).
  + *Regulat*: $v$ are doar 4 valori, deci $L = union.big_(v in {a a, a b, b a, b b}) v (a union b)^* v$.
  + *Regulat*: $L(a^* b^* c^* d^*) inter {"lungime" equiv 0 med (mod 5)}$.
  + *Finit* (8 cuvinte), deci regulat.
  + *Regulat*: $p >= -n$ înseamnă doar $n + p >= 0$, deci exponentul lui $c$ e orice număr: $L = a^* b^* c^*$.
  + *Regulat, infinit*: $p$ ia doar 101 valori: $L = union.big_(p = 0)^(100) a^p b^(101) b^* a^p$.
  + *Regulat, infinit*: $(a a)^*$ (peste un singur simbol, $w w = a^(2|w|)$).
  + *Regulat*: pentru $n = 1$, $x = 1^m$, $y = z = e$ dă orice $1^m$. Deci $L = 1^*$.
  + *Regulat, infinit*: reuniune finită de $Sigma^* a^p$, câte una pentru fiecare prim $p <= 200$.
  + *Nu e regulat* (și nici independent de context): $L inter 1^* = {1^p | p "prim"}$. În grilă: „nicio variantă”.
  + *Regulat*: numerele impare plus $2$ (singurul prim par): $a(a a)^* union a a$.
  + *Regulat*: $L' = L L inter Sigma^* a Sigma^* a Sigma^*$.
]

#problema[Fapte despre lemă și clase][
  Adevărat sau fals: (1) orice limbaj finit satisface lema de pompare; (2) dacă $L$ satisface lema, $L$ e regulat; (3) dacă $Sigma^* without L$ nu e regulat, nici $L$ nu e regulat; (4) pentru orice $L_1$ neregulat există $R_1, R_2$ regulate cu $R_1 subset.eq L_1 subset.eq R_2$; (5) dacă $L_1$ e regulat, $L_2$ neregulat și $L_1 inter L_2 = emptyset$, atunci $L_1 union L_2$ nu e regulat; (6) dacă pentru fiecare cuvânt din $L$ există un AFD care îl acceptă, $L$ e regulat.
][
  (1) *Adevărat*: cu $p$ mai mare decât cel mai lung cuvânt, nu există $w in L$ cu $|w| >= p$ (condiția e adevărată în gol).

  (2) *Fals*: lema e doar necesară. Exemplu clasic: ${a^i b^j c^j | i >= 1} union {b^j c^k}$ satisface lema, dar nu e regulat.

  (3) *Adevărat*: dacă $L$ ar fi regulat, complementul lui ar fi regulat.

  (4) *Adevărat*: $R_1 = emptyset$, $R_2 = Sigma^*$.

  (5) *Adevărat*: dacă $R = L_1 union L_2$ ar fi regulat, atunci $L_2 = R without L_1$ (pentru că sunt disjuncte) ar fi regulat.

  (6) *Fals*: orice cuvânt e acceptat de un AFD (${w}$ e finit), deci condiția nu spune nimic despre $L$.
]
