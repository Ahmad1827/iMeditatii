#import "tpl.typ": *

= Proprietăți de închidere (P1)

#teorema(t: "Ce trebuie să știi pe de rost")[
  Limbajele regulate sunt închise la: *reuniune, concatenare, stea* (din definiția ER), *complement, intersecție, diferență, diferență simetrică* (automatul produs / inversarea finalelor), *oglindire* $L^R$, *prefixe* $"Pref"(L)$, *sufixe* $"Suf"(L)$, *subcuvinte* $"Sub"(L)$, *morfisme* $h(L)$ și *morfisme inverse* $h^(-1)(L)$, *cât* $X backslash L = {w | exists x in X, x w in L}$ (pentru $X$ oarecare).
]

#tabel(
  columns: (auto, 1fr),
  [*Operația*], [*Construcția pe care o scrii*],
  [$overline(L) = Sigma^* without L$], [AFD *complet* pentru $L$, apoi $F' = K without F$.],
  [$L_1 inter L_2$], [Produsul: $K = K_1 times K_2$, $delta((p, q), a) = (delta_1(p, a), delta_2(q, a))$, $s = (s_1, s_2)$, $F = F_1 times F_2$.],
  [$L_1 union L_2$, $L_1 without L_2$, $L_1 triangle.stroked.t L_2$], [Același produs, cu finalele: măcar una finală / $(p in F_1, q in.not F_2)$ / exact una finală. Sau prin identități: $L_1 without L_2 = L_1 inter overline(L_2)$.],
  [$L^R$], [Inversezi toate săgețile; o stare inițială nouă cu $e$ spre fostele finale; fosta inițială devine singura finală.],
  [$"Pref"(L)$], [În AFD-ul lui $L$ (fără stări inaccesibile) faci finale toate stările din care *se poate ajunge* la o stare finală.],
  [$"Suf"(L)$], [În AFN-ul lui $L$, o stare inițială nouă cu $e$ spre toate stările *accesibile din $s$*.],
  [$h(L)$], [În ER-ul lui $L$ înlocuiești fiecare simbol $a$ cu ER-ul lui $h(a)$.],
  [$h^(-1)(L)$], [AFD nou cu aceleași stări: $delta'(q, a) = delta^*(q, h(a))$.],
)

#petest[
  Un răspuns la P1 („arătați că $L'$ e regulat”) are trei părți, fiecare punctată:
  + *scrii $L'$ prin operații* aplicate unor limbaje despre care știi că sunt regulate (de exemplu $L' = L inter overline(Sigma^* a Sigma^*)$);
  + *justifici* fiecare limbaj de bază (o ER sau un automat) și *numești* fiecare proprietate de închidere folosită;
  + dacă se cere „folosiți automate”, *dai construcția*: stări, tranziții, inițială, finale, și spui de ce acceptă exact $L'$.
]

== Demonstrații cu construcție

#problema[Număr par de $a$ și fără $b b$][
  Arătați, folosind proprietăți de închidere, că $L = {w in {a, b}^* | |w|_a "par și" w "nu conține" b b}$ e regulat. Construiți apoi automatul.
][
  $L = L_1 inter L_2$ cu $L_1 = {w | |w|_a "par"} = L((b^* a b^* a)^* b^*)$ și $L_2 = overline(Sigma^* b b Sigma^*)$.
  - $L_1$ e regulat: are ER-ul de mai sus.
  - $Sigma^* b b Sigma^* = L((a union b)^* b b (a union b)^*)$ e regulat, deci complementul lui, $L_2$, e regulat (închidere la complement).
  - $L = L_1 inter L_2$ e regulat (închidere la intersecție). $qed$

  *Automatul produs.* $M_1$: paritatea lui $a$ ($P$, $I$). $M_2$: $s$ (ultimul nu e $b$), $B$ (ultimul e $b$), $d$ (am văzut $b b$). Produsul are $2 dot 3 = 6$ stări; cele două cu $d$ sunt echivalente (ambele capcane), deci rămân 5. Finale: $(P, s)$, $(P, B)$.
  #aut(
    (Ps: (Is: "a", PB: "b"), PB: (Is: "a", d: "b"), Is: (Ps: "a", IB: "b"), IB: (Ps: "a", d: "b"), d: (d: "a,b")),
    (Ps: (0, 0), PB: (0, -3), Is: (4, 0), IB: (4, -3), d: (2, -5.2)),
    final: ("Ps", "PB"),
    etichete: (Ps: "P,s", PB: "P,B", Is: "I,s", IB: "I,B", d: "d"),
    st: ("Ps-Is": (curve: .4), "Is-Ps": (curve: .4), "d-d": (anchor: bottom), "PB-Is": (label: (pos: .3)), "IB-Ps": (label: (pos: .3))),
  )
]

#problema[Fără subcuvinte dintr-o mulțime finită][
  Fie $F subset.eq Sigma^*$ un limbaj finit. (a) Arătați că $L = {w in Sigma^* | w "nu are subsecvențe în" F}$ e regulat. (b) Construiți un AFD pentru $Sigma = {a, b}$, $F = {a a, b a b}$. (c) Rămâne adevărat dacă $F$ e un limbaj regulat oarecare?
][
  (a) Un cuvânt are o subsecvență din $F$ dacă se scrie $x u y$ cu $u in F$. Deci
  $ L = Sigma^* without (Sigma^* F Sigma^*). $
  $F$ e finit, deci regulat (ER: reuniunea cuvintelor lui). $Sigma^*$ e regulat. Concatenarea a trei limbaje regulate e regulată, iar complementul unui limbaj regulat e regulat. $qed$

  (c) Da: argumentul folosește doar faptul că $F$ e regulat, nu că e finit.

  (b) Starea = cel mai lung sufix al textului citit care e prefix al unui cuvânt interzis: $epsilon$, $a$, $b$, $b a$; plus capcana $d$ (am găsit $a a$ sau $b a b$).
  #tabel(
    columns: (auto, auto, auto),
    [*Stare*], [*cu $a$*], [*cu $b$*],
    [$-> epsilon$], [$a$], [$b$],
    [$a$], [$d$ (s-a format $a a$)], [$b$ („$a b$” se termină cu $b$)],
    [$b$], [$b a$], [$b$],
    [$b a$], [$d$ („$b a a$” conține $a a$)], [$d$ ($b a b$)],
    [$d$], [$d$], [$d$],
  )
  #aut(
    (E: (A: "a", B: "b"), A: (d: "a", B: "b"), B: (BA: "a", B: "b"), BA: (d: "a,b"), d: (d: "a,b")),
    (E: (0, 0), A: (3, 1.5), B: (3, -1.5), BA: (6, -1.5), d: (7, 1.5)),
    final: ("E", "A", "B", "BA"),
    etichete: (E: $epsilon$, A: "a", B: "b", BA: "ba", d: "d"),
    st: ("B-B": (anchor: bottom), "d-d": (anchor: right)),
  )
  Toate stările în afară de $d$ sunt finale. Verificare: $a b a$ ✓ ($epsilon -> a -> b -> b a$); $b a b$ ✗; $a b b a$ ✓.
]

#problema[Sufixele unui limbaj regulat][
  (a) Arătați că, dacă $L$ e regulat, atunci $"Suf"(L) = {w | exists w' in L, w "sufix al lui" w'}$ e regulat. (b) Aplicați construcția pentru $L = L(a b^* a)$.
][
  (a) Fie $M = (K, Sigma, delta, s, F)$ un AFD pentru $L$, fără stări inaccesibile. Construim AFN-ul $M'$: stările lui $M$ plus o stare inițială nouă $s'$, cu $(s', e, q)$ pentru *fiecare* $q in K$; finalele rămân $F$.

  *De ce merge.* Dacă $w in "Suf"(L)$, există $u$ cu $u w in L$; fie $q = delta^*(s, u)$. Atunci $delta^*(q, w) in F$ și $M'$ acceptă $w$ pe drumul $s' ->^e q ->^w F$. Invers, dacă $M'$ acceptă $w$ printr-un $q$, $q$ e accesibil: există $u$ cu $delta^*(s, u) = q$, deci $u w in L$ și $w in "Suf"(L)$. $qed$

  #capcana[Fără condiția „accesibile” construcția e greșită: dintr-o stare la care nu se ajunge ar putea pleca drumuri spre finale care nu corespund niciunui cuvânt din $L$.]

  (b) AFN-ul lui $a b^* a$: $0 ->^a 1$, $1 ->^b 1$, $1 ->^a 2$, finala $2$ (fără capcană; o capcană nu ajută, oricum nu duce la finale). Adăugăm $s'$:
  #aut(
    (s: ("0": "e", "1": "e", "2": "e"), "0": ("1": "a"), "1": ("1": "b", "2": "a"), "2": (:)),
    (s: (0, 0), "0": (3, 1.8), "1": (5, 0), "2": (3, -1.8)),
    final: ("2",),
    etichete: (s: $s'$),
    st: ("1-1": (anchor: right)),
  )
  $"Suf"(L) = L(e union b^* a union a b^* a)$: prin $2$ obții $e$, prin $1$ obții $b^* a$, prin $0$ chiar $L$.
]

#problema[Diferența simetrică, pe un exemplu concret][
  $M_1$: $q_0$ (inițială, finală), $q_1$; $a$ trece de la una la alta, $b$ rămâne pe loc (număr par de $a$). $M_2$: $p_0$ (inițială), $p_1$ (finală); $a$ duce în $p_0$, $b$ în $p_1$ (se termină cu $b$). (a) Arătați cum se construiește $M$ cu $L(M) = L(M_1) triangle.stroked.t L(M_2)$, unde $A triangle.stroked.t B = (A union B) without (A inter B)$. (b) Construiți-l.
][
  (a) Automatul produs $M = (K_1 times K_2, Sigma, delta, (s_1, s_2), F)$ cu $delta((p, q), x) = (delta_1(p, x), delta_2(q, x))$ și
  $ F = {(p, q) | p in F_1 "xor" q in F_2}. $
  După citirea lui $w$, $M$ e în $(delta_1^*(s_1, w), delta_2^*(s_2, w))$: prima componentă spune dacă $w in L(M_1)$, a doua dacă $w in L(M_2)$. $w$ e acceptat exact când e în unul singur. Ambele automate trebuie să fie *complete* (altfel produsul „pierde” cuvinte care sunt într-un singur limbaj).

  (b) $F = {(q_0, p_0), (q_1, p_1)}$ (exact o componentă e finală).
  #aut(
    (A: (C: "a", B: "b"), B: (C: "a", B: "b"), C: (A: "a", D: "b"), D: (A: "a", D: "b")),
    (A: (0, 0), B: (4, 0), C: (0, -3), D: (4, -3)),
    final: ("A", "D"),
    etichete: (A: $q_0 p_0$, B: $q_0 p_1$, C: $q_1 p_0$, D: $q_1 p_1$),
    st: ("A-C": (curve: .4), "C-A": (curve: .4), "B-B": (anchor: right), "D-D": (anchor: right), "D-A": (label: (pos: .3)), "B-C": (label: (pos: .3))),
  )
  Verificare: $e$: $(q_0, p_0)$, finală ✓ (par de $a$, nu se termină cu $b$). $b$: $(q_0, p_1)$, în ambele limbaje, deci respins ✓. $a b$: $(q_1, p_1)$, doar în $L(M_2)$ ✓.
]

#problema[Oglinditul][
  Fie $L$ regulat. Arătați că $L^R = {w^R | w in L}$ e regulat. Aplicați pe AFD-ul lui $a b^*$.
][
  *Varianta cu automate.* Fie $M = (K, Sigma, Delta, s, F)$ un AFN pentru $L$ (cu tranziții pe simboluri sau $e$). $M^R$: aceleași stări plus $s'$ nouă; $(q, a, p) in Delta^R <==> (p, a, q) in Delta$; $(s', e, f)$ pentru fiecare $f in F$; singura finală e $s$. Un drum $s ->^w f$ în $M$ e exact un drum $f ->^(w^R) s$ în $M^R$. $qed$

  *Varianta cu ER* (prin inducție): $emptyset^R = emptyset$, $a^R = a$, $(alpha union beta)^R = alpha^R union beta^R$, $(alpha beta)^R = beta^R alpha^R$, $(alpha^*)^R = (alpha^R)^*$.

  Exemplu: $a b^*$ are $0 ->^a 1$, buclă $b$ pe $1$, finală $1$. Inversat: buclă $b$ pe $1$, $1 ->^a 0$, inițială $1$ (unica fostă finală, deci nu trebuie $s'$), finală $0$: $b^* a$ ✓.
]

#problema[Prefixele][
  Fie $L$ regulat. Arătați că $"Pref"(L) = {x | exists y, x y in L}$ e regulat. Pentru $L = a b^* a$, scrieți o ER pentru $"Pref"(L)$.
][
  În AFD-ul $M$ al lui $L$ declarăm finale *toate stările din care se poate ajunge într-o stare finală* (se calculează cu o parcurgere pe graful inversat, pornind din $F$). $x in "Pref"(L)$ $<==>$ din $delta^*(s, x)$ există un drum $y$ spre $F$ $<==>$ $delta^*(s, x)$ e finală în $M'$. $qed$

  Pentru $a b^* a$ (stări $0, 1, 2$ și capcana $d$), din $0, 1, 2$ se ajunge la $2$, din $d$ nu. Finale: $0, 1, 2$. $"Pref"(L) = e union a b^* union a b^* a$.
]

#problema[Fără $a$ (examen, ianuarie 2025)][
  Fie $L$ un limbaj regulat peste ${a, b, c}$. Folosiți proprietățile de închidere ca să arătați că $L' = {w | w in L and |w|_a = 0}$ e regulat.
][
  $L' = L inter {b, c}^* = L inter L((b union c)^*)$. $(b union c)^*$ e o ER, deci limbajul ei e regulat; intersecția a două limbaje regulate e regulată. $qed$

  Variantă: $L' = L without (Sigma^* a Sigma^*)$, diferență de limbaje regulate. Construcția concretă: în AFD-ul lui $L$ ștergi toate tranzițiile pe $a$ (sau le trimiți în capcană).
]

#problema[Câtul la stânga $W = X backslash L$][
  Pentru $X, L in "LR"$, fie $W = {w in Sigma^* | exists x in X : x w in L}$. (a) Dați o construcție de automat pentru $W$. (b) Pentru $Sigma = {a, b}$, $X = L(b^* a)$, $L = L((a union b)^* a a b)$, scrieți o ER pentru $W$.
][
  (a) Fie $M = (K, Sigma, delta, s, F)$ un AFD pentru $L$. Fie $S = {q in K | exists x in X : delta^*(s, x) = q}$, stările în care ajunge $M$ după un cuvânt din $X$. $S$ se calculează: pentru fiecare $q$, $q in S$ $<==>$ $X inter L(M_q) != emptyset$, unde $M_q$ e $M$ cu finala ${q}$ (produs + test de vid). Automatul lui $W$: $M$ cu o stare inițială nouă și tranziții $e$ spre fiecare $q in S$. Atunci $w in W$ $<==>$ din vreun $q in S$, $w$ duce la o finală. $qed$

  (b) $x = b^k a$. Căutăm $w$ cu $b^k a w$ terminat în $a a b$:
  - dacă $w$ se termină cu $a a b$, merge;
  - dacă $w = a b$: $b^k a a b$ ✓;
  - $w = b$: ar trebui ca $x$ să se termine cu $a a$, dar $x = b^k a$ se termină cu $b a$ sau e $a$: nu;
  - $w = e$: $x$ nu se termină cu $a a b$; alte $w$ mai scurte de 3 nu merg.
  $ W = a b union (a union b)^* a a b $
]

#problema[Morfisme][
  Fie $h : {a, b}^* -> {a, b}^*$ morfismul cu $h(a) = e$, $h(b) = b$ (șterge toate $a$-urile). Ce este $h(L)$ pentru $L = L((a b)^* a a)$? Dar pentru $L = {a^n b^n | n >= 0}$?
][
  Pentru ER se înlocuiește fiecare simbol: $h((a b)^* a a) = (e b)^* e e = b^*$. Al doilea: $h({a^n b^n}) = {b^n | n >= 0} = b^*$, care e regulat deși $L$ nu e. Morfismele păstrează regularitatea, dar pot și „crea” regularitate: din „$h(L)$ e regulat” nu rezultă nimic despre $L$.
]

#problema[Ștergerea unui simbol (tip bonus)][
  Pentru $L$ regulat, fie $"Drop"(L) = {x z | exists y in Sigma : x y z in L}$ (cuvintele obținute ștergând exact un simbol). Arătați că $"Drop"(L)$ e regulat.
][
  Fie $M$ un AFD pentru $L$. Construim un AFN cu *două copii* ale lui $M$: copia 1 („încă n-am șters nimic”) și copia 2 („am șters deja simbolul”). Tranzițiile din fiecare copie sunt cele din $M$; în plus, pentru fiecare $delta(p, y) = q$, adăugăm $(p_1, e, q_2)$: automatul „sare” peste un simbol $y$ fără să-l citească. Inițială: $s_1$; finale: stările finale ale copiei a doua ($F_2$). Un drum acceptor citește $x$ în copia 1, sare peste $y$ și citește $z$ în copia 2, deci acceptă exact $x z$ cu $x y z in L$. $qed$
]

== Adevărat sau fals? (contraexemple)

#metoda[Pentru „fals” dai un *contraexemplu concret*, cu limbaje cunoscute. Trusa ta: $emptyset$, ${e}$, $Sigma^*$, $a^*$, ${a^n b^n}$ (neregulat), ${a^p | p "prim"}$ (neregulat), ${a^(n^2)}$ (neregulat) și complementele lor. Pentru „adevărat” dai demonstrația (de obicei o proprietate de închidere sau o incluziune).]

#problema[„$L_1 L_2$ regulat ⇒ $L_1$, $L_2$ regulate”][
  Adevărat sau fals: pentru orice $L_1, L_2$, dacă $L_1 L_2$ e regulat, atunci $L_1$ și $L_2$ sunt regulate?
][
  *Fals.* $L_1 = {0^n 1^m | n > m >= 0}$ nu e regulat (pompare), $L_2 = 1^*$. Atunci $L_1 L_2 = {0^n 1^j | n >= 1, j >= 0} = 0^+ 1^*$: după $0^n 1^m$ se pot pune oricâți $1$, deci orice număr de $1$ apare. Mai simplu: $L_1 = {a^n b^n} union {e}$, $L_2 = Sigma^*$: $L_1 L_2 = Sigma^*$.

  Închiderea la concatenare spune doar implicația inversă: $L_1, L_2$ regulate ⇒ $L_1 L_2$ regulat.
]

#problema[„$L^*$ regulat ⇒ $L$ regulat”][
  Adevărat sau fals?
][
  *Fals.* $L = {a^p | p "prim"}$ nu e regulat. Dar orice $n >= 2$ e o sumă de $2$ și $3$ (care sunt prime), deci $L^* = {e} union {a^n | n >= 2} = L(e union a a a^*)$, regulat. (Alt exemplu: $L = {a^n b^n} union {a, b}$: $L^* = Sigma^*$.)
]

#problema[Regulat + ceva = regulat?][
  Pentru fiecare afirmație, spuneți dacă e întotdeauna adevărată: (1) $L_1$ și $L_1 union L_2$ regulate ⇒ $L_2$ regulat. (2) $L_1 inter L_2$ și $L_1 union L_2$ regulate ⇒ măcar unul e regulat. (3) $L_1$ și $L_1 L_2$ regulate ⇒ $L_2$ regulat. (4) $L_2 subset.eq L(a^* b^*)$ ⇒ $L_2$ regulat.
][
  Toate sunt *false*:
  + $L_1 = Sigma^*$: $L_1 union L_2 = Sigma^*$ pentru orice $L_2$.
  + $L_1 = N$ neregulat, $L_2 = overline(N)$ (tot neregulat, altfel $N$ ar fi regulat): $L_1 inter L_2 = emptyset$, $L_1 union L_2 = Sigma^*$.
  + $L_1 = Sigma^*$, $L_2 = {a^n b^n} union {e}$: $L_1 L_2 = Sigma^*$. (Grila: „nu se poate afirma nimic”.)
  + $L_2 = {a^n b^n} subset.eq a^* b^*$: o submulțime a unui limbaj regulat poate fi oricât de complicată.
]

#problema[Trei afirmații cu $L_4$ oarecare][
  Fie $L_1, L_2, L_3$ regulate și $L_4$ oarecare. (i) $L_1 L_4 = L_2 => L_4$ regulat; (ii) $L_1 L_2 = L_3 L_4 => L_4$ regulat; (iii) $L_1 L_4 L_2 = L_3 => L_4$ regulat. Câte sunt adevărate?
][
  *Niciuna.* Un singur contraexemplu le rezolvă pe toate: $L_1 = L_2 = L_3 = a^*$ și $L_4 = {a^(n^2) | n >= 0}$ (conține $a^0 = e$). Atunci $a^* L_4 = a^*$ (orice $a^m = a^m dot e$), $L_4 a^* = a^*$ și $a^* L_4 a^* = a^*$, dar $L_4$ nu e regulat.
]

#problema[O reuniune care e mereu regulată][
  Fie $L_1, L_2$ regulate și $L_3 subset.eq L_1 inter L_2$ oarecare. Ce e $L_1 union (Sigma^* without L_3)$?
][
  *Întotdeauna $Sigma^*$, deci regulat.* $L_3 subset.eq L_1$ ⇒ $overline(L_1) subset.eq overline(L_3)$, deci $Sigma^* = L_1 union overline(L_1) subset.eq L_1 union overline(L_3)$. Chiar dacă $L_3$ nu e regulat, reuniunea e.
]

#problema[Cu numere prime][
  Fie $L_1 = {a^p | p "prim"}$, $L_2 = {a^(2k) | k in NN}$. Ce e $(L_1 inter L_2)^* without L_2$?
][
  2 e singurul prim par: $L_1 inter L_2 = {a a}$, $(a a)^* = L_2$, deci rezultatul e $L_2 without L_2 = emptyset$.
]

#problema[Stea și complement][
  Valorile de adevăr: (1) $overline(L^*) = (overline(L))^*$; (2) $(L^*)^* = L^*$; (3) pentru orice $L$ regulat, $L = L L$.
][
  (1) *Fals*: $e in (overline(L))^*$ mereu, dar $e in.not overline(L^*)$ (pentru că $e in L^*$). Deci cele două diferă pentru orice $L$.

  (2) *Adevărat*: $L^* subset.eq (L^*)^*$; invers, o concatenare de cuvinte din $L^*$ e tot o concatenare de cuvinte din $L$.

  (3) *Fals*: $L = {a}$, $L L = {a a}$. Închiderea la concatenare spune doar că $L L$ e regulat.
]

#problema[Cardinale: $|L_1| > |L_2|$][
  Fie $L_1, L_2 in "LR"$ cu $|L_1| > |L_2|$. Pentru fiecare propoziție, spuneți dacă e întotdeauna adevărată, întotdeauna falsă sau depinde: (a) dacă $L_1$ e finit, $L_2$ e finit; (b) $L_1 subset.eq L_2$; (c) $L_2 subset.eq L_1$; (d) $L_1 inter (L_2 compose {e}) in.not "LR"$.
][
  *Cheia:* $Sigma^*$ e numărabil, deci orice limbaj infinit are cardinalul $aleph_0$. Dacă $|L_1| > |L_2|$, atunci $L_2$ e *finit* (două limbaje infinite au același cardinal).
  - (a) *Întotdeauna adevărată* ($L_2$ e finit oricum).
  - (b) *Întotdeauna falsă*: o submulțime nu are mai multe elemente decât mulțimea.
  - (c) *Depinde*: $L_1 = {a, b}$, $L_2 = {a}$ (adevărată) sau $L_2 = {b b}$ (falsă).
  - (d) *Întotdeauna falsă*: $L_2 compose {e} = L_2$ și $L_1 inter L_2$ e regulat.
]

#problema[Familii de limbaje închise la operații][
  (a) $K = {L subset.eq {0, 1}^* | 101 in L}$: la ce operație e închisă: diferență, concatenare, reuniune, complement? (b) Aceeași întrebare pentru $L_(a b b a) = {L subset.eq {a, b, c}^* | a b b a in L}$ și intersecție, diferență, produs cartezian, concatenare. (c) Fie $M_1 = {L in "LR" | 0 in L}$, $M_2 = {L in "LR" | 1 in L}$. Ce e $M_1 inter M_2$?
][
  (a) *Reuniune*: dacă $101$ e într-unul, e și în reuniune. Diferența $L without L$ îl scoate; complementul îl scoate; ${101} dot {101} = {101101}$ nu-l conține.

  (b) *Intersecție* (ambele îl conțin). Diferența îl scoate; produsul cartezian nu dă limbaje; ${a b b a}{a b b a}$ nu-l conține.

  (c) $M_1 inter M_2 = {L in "LR" | 0 in L and 1 in L}$, mulțimea limbajelor regulate care conțin *ambele* cuvinte; nu e niciuna dintre variantele obișnuite din grilă („$emptyset$”, „toate LR”, „cele care conțin $01$”).
]

#problema[Limbajele care sunt egale cu $L L^*$][
  Fie $J = {L subset.eq {a, b, c}^* | L L^* = L^*}$ și $P = {w | forall L in J, w in L}$. Cât e $|P|$?
][
  $L L^* = L^+$, iar $L^+ = L^*$ $<==>$ $e in L^+$ $<==>$ $e in L$. Deci $J$ = limbajele care conțin $e$, iar cuvintele comune tuturor sunt doar $e$ (${e} in J$). $P = {e}$, $|P| = 1$.
]

#problema[Liste de operații][
  Fie $L_1, L_2$ regulate. Care listă conține doar limbaje regulate? (a) $L_1 compose L_2$, $L_1 union {0,1}^*$, $L_1 times L_2$; (b) $L_1^*$, $2^(L_1 compose L_2)$, $L_2 compose L_1$; (c) $L_2 times L_1$, $L_1 without L_2$, $L_2 without L_1$; (d) $L_1 union L_2$, $(L_1 without L_2) union (L_2 without L_1)$, $L_1 inter L_2 compose emptyset$.
][
  *(d).* $times$ dă perechi de cuvinte și $2^X$ o mulțime de limbaje: nu sunt limbaje, deci (a), (b), (c) cad. În (d): reuniunea, diferența simetrică și $X compose emptyset = emptyset$ sunt regulate.
]

#problema[Prefixe, sufixe și o capcană][
  Fie $L$ regulat. Care afirmație e *falsă*? (a) $"Pref"(L)$ e regulat; (b) $"Suf"(L)$ e regulat; (c) $L = "Pref"(L) compose "Suf"(L)$; (d) $L inter "Pref"(L)$ e regulat.
][
  *(c).* Contraexemplu: $L = {a b}$. $"Pref"(L) = {e, a, a b}$, $"Suf"(L) = {e, b, a b}$, iar concatenarea conține $e$, $a$, $b$, $a b a b$, care nu sunt în $L$. (Incluziunea $L subset.eq "Pref"(L) "Suf"(L)$ e adevărată pentru $L != emptyset$: $w = w dot e$.) (d) e regulat ca intersecție; de fapt e chiar $L$.
]

#problema[$L' = {w w | w in L}$][
  Fie $L$ un limbaj oarecare și $L' = {w w | w in L}$. Ce e întotdeauna adevărat? (a) $L'$ nu e regulat; (b) $L' = L L$; (c) niciuna; (d) $L'$ e regulat.
][
  *(c).* $L = {a}$: $L' = {a a}$, regulat (deci (a) cade). $L = a^*$ peste ${a}$: $L' = (a a)^*$, regulat. $L = (a union b)^*$: $L' = {w w}$ nu e regulat (deci (d) cade). (b): $L = {a, b}$: $L L$ conține $a b$, $L'$ nu.
]
