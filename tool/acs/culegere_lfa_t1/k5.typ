#import "tpl.typ": *

= Proprietăți algoritmice (P4)

La P4 (1,5 p) se cere un *algoritm* care decide ceva despre limbajul unui automat. Nu se cere cod: se cer *pașii*, de ce sunt *corecți* și de ce *se termină*.

#teorema(t: [Cele trei unelte de bază (pentru un AFD $M$ cu $n$ stări)])[
  + *Vid:* $L(M) = emptyset$ $<==>$ nicio stare finală nu e accesibilă din $s$. Parcurgere (BFS/DFS) din $s$: $O(|K| dot |Sigma|)$.
  + *Finit:* păstrezi doar stările *utile* (accesibile din $s$ și din care se poate ajunge într-o finală). $L(M)$ e infinit $<==>$ printre stările utile există un *ciclu*. Echivalent: $L(M)$ e infinit $<==>$ $M$ acceptă un cuvânt $w$ cu $n <= |w| < 2n$ (un număr finit de cuvinte de încercat).
  + *Operații:* orice combinație de reuniune, intersecție, complement, diferență se face pe automate (produs, inversarea finalelor), apoi pui una dintre întrebările de mai sus.
]

#metoda[
  Întrebarea se *reduce* la „e vid?” sau „e finit?” pentru un limbaj construit din cele date:
  #tabel(
    columns: (1fr, 1fr),
    [*Întrebarea*], [*Se reduce la*],
    [$L(M) = Sigma^*$?], [$overline(L(M)) = emptyset$?],
    [$L(M_1) subset.eq L(M_2)$?], [$L(M_1) inter overline(L(M_2)) = emptyset$?],
    [$L(M_1) = L(M_2)$?], [$L(M_1) triangle.stroked.t L(M_2) = emptyset$? (sau: compari AFD-urile minimale)],
    [$M$ acceptă un cuvânt cu proprietatea $P$ (regulată)?], [$L(M) inter L_P != emptyset$?],
    [toate cuvintele lui $L(M)$ au proprietatea $P$?], [$L(M) inter overline(L_P) = emptyset$?],
  )
]

#petest[Un răspuns complet are: (1) *construcția* (ce automat construiești, din ce); (2) *testul* (vid / finit, cu parcurgere); (3) *corectitudinea* (de ce răspunsul testului e răspunsul la întrebare: o echivalență scrisă explicit); (4) *terminarea* (automatul e finit, parcurgerea vizitează fiecare stare o dată). Nu răspunde „încercăm toate cuvintele”: dacă răspunsul e „nu”, căutarea nu se oprește.]

== Exerciții

#problema[Acceptă măcar un cuvânt?][
  Cum decidem dacă un AFD $M$ acceptă cel puțin un cuvânt?
][
  *Algoritm.* Parcurgem graful lui $M$ în lățime din $s$, marcând stările vizitate. Răspundem „da” dacă vizităm o stare finală, „nu” dacă parcurgerea se oprește fără să întâlnească vreuna.

  *Corectitudine.* $w in L(M)$ $<==>$ drumul etichetat $w$ din $s$ se termină într-o finală. Deci $L(M) != emptyset$ $<==>$ există un drum de la $s$ la o finală, adică o finală e accesibilă.

  *Terminare.* Fiecare stare e pusă în coadă cel mult o dată: cel mult $|K|$ pași, fiecare cu $|Sigma|$ tranziții.

  *De ce nu „încercăm toate cuvintele”:* dacă $L(M) = emptyset$, nu ne oprim niciodată. (Corect ar fi doar „încercăm cuvintele de lungime $< n$”: dacă există un cuvânt acceptat, există unul mai scurt de $n$, pentru că un drum fără stări repetate are cel mult $n - 1$ tranziții.)
]

#problema[Limbaj finit (fișa seminarului)][
  Cum putem verifica dacă, pentru un AFD $M$, $L(M)$ este finit? Descrieți algoritmul și argumentați de ce e corect și de ce se termină.
][
  *Algoritm.*
  + $A$ = stările accesibile din $s$ (BFS din $s$).
  + $C$ = stările din care se ajunge într-o finală (BFS din $F$ pe graful cu săgețile întoarse).
  + $U = A inter C$, stările *utile*. Căutăm un ciclu (DFS cu culori) în subgraful indus de $U$.
  + $L(M)$ e infinit dacă există un ciclu, finit altfel.

  *Corectitudine.* ($arrow.l.double$) Dacă $q in U$ e pe un ciclu etichetat $v != e$: $s ->^x q$ (accesibilă), $q ->^v q$, $q ->^z f in F$ (co-accesibilă). Atunci $x v^i z in L(M)$ pentru orice $i$: o infinitate de cuvinte distincte, pentru că $|v| >= 1$.

  ($arrow.r.double$) Dacă $L(M)$ e infinit, are un cuvânt $w$ cu $|w| >= n$. Drumul lui trece prin $|w| + 1 > n$ stări, deci o stare se repetă: drumul conține un ciclu. Toate stările drumului sunt accesibile (sunt pe un drum din $s$) și co-accesibile (drumul continuă până la o finală), deci ciclul e în $U$.

  *Terminare.* Trei parcurgeri pe un graf finit.

  #capcana[„$M$ nu are cicluri” e greșit ca test: aproape orice AFD are cicluri, măcar bucla din capcană. Contează doar ciclurile pe drumuri de la $s$ la o finală.]
]

#problema[Algoritmul pe un exemplu][
  AFD peste ${a, b}$, inițială $0$, finală $3$: $0 ->^a 1$, $0 ->^b 2$, $1 ->^(a, b) 3$, $2 ->^a 3$, $2 ->^b 4$, $3 ->^(a, b) d$, $4 ->^(a, b) 4$, $d ->^(a, b) d$. E $L(M)$ finit? Câte cuvinte are? Are un unic cel mai lung cuvânt?
][
  #aut(
    ("0": ("1": "a", "2": "b"), "1": ("3": "a,b"), "2": ("3": "a", "4": "b"), "3": (d: "a,b"), "4": ("4": "a,b"), d: (d: "a,b")),
    ("0": (0, 0), "1": (3, 1.4), "2": (3, -1.4), "3": (6, 0), "4": (6, -2.6), d: (9, 0)),
    final: ("3",),
    st: ("4-4": (anchor: right), "d-d": (anchor: right)),
  )
  - Accesibile: $A = {0, 1, 2, 3, 4, d}$ (toate).
  - Co-accesibile (din care ajungi în $3$): $C = {3, 1, 2, 0}$. Din $4$ și $d$ nu se mai iese.
  - Utile: $U = {0, 1, 2, 3}$. În $U$ nu e niciun ciclu (buclele sunt pe $4$ și $d$, care nu sunt utile). $L(M)$ e *finit*.
  - Numărarea: graful util e aciclic; drumurile $0 -> 3$: $0 ->^a 1 ->^(a, b) 3$ (două) și $0 ->^b 2 ->^a 3$ (unul). $L(M) = {a a, a b, b a}$, 3 cuvinte.
  - Cel mai lung: lungimea maximă e 2, dar sunt *trei* cuvinte de lungime 2: nu e unic.
]

#problema[Infinit ⇔ un cuvânt de lungime între $n$ și $2n - 1$][
  Fie $M$ un AFD cu $n$ stări. Arătați că $L(M)$ e infinit dacă și numai dacă $M$ acceptă un cuvânt $w$ cu $n <= |w| < 2n$. De ce dă asta un algoritm?
][
  ($arrow.l.double$) Un cuvânt acceptat cu $|w| >= n$ repetă o stare, deci se poate pompa (lema de pompare): $L(M)$ e infinit.

  ($arrow.r.double$) $L(M)$ infinit ⇒ are cuvinte cu $|w| >= n$. Luăm unul *cel mai scurt* cu $|w| >= n$. Dacă $|w| >= 2n$: primele $n$ simboluri trec prin $n + 1$ stări, deci există un ciclu $y$ cu $1 <= |y| <= n$ în primele $n$ simboluri. Scoțându-l ($w = x y z -> x z$) obținem tot un cuvânt acceptat, cu $|x z| >= 2n - n = n$, dar mai scurt decât $w$: contradicție. Deci $n <= |w| < 2n$.

  *Algoritm:* încercăm toate cuvintele de lungime $n, n+1, dots, 2n - 1$ (un număr finit, $|Sigma|^n + dots + |Sigma|^(2n-1)$). Corect, dar exponențial; testul cu ciclul e liniar.
]

#problema[Acceptă toate cuvintele?][
  Cum putem verifica dacă un AFD $M$ acceptă toate cuvintele peste $Sigma$?
][
  $L(M) = Sigma^*$ $<==>$ $overline(L(M)) = emptyset$.
  + Completăm $M$ (dacă îi lipsesc tranziții, adăugăm capcana).
  + Inversăm finalele: obținem $overline(M)$, care acceptă $overline(L(M))$.
  + Testăm dacă $L(overline(M)) = emptyset$: BFS din $s$; dacă nu atingem nicio stare *nefinală a lui $M$*, răspunsul e „da”.
  Echivalent, direct: $L(M) = Sigma^*$ $<==>$ toate stările *accesibile* din $s$ sunt finale.

  #capcana["Toate stările sunt finale" e suficient, dar nu necesar: o stare nefinală inaccesibilă nu contează. Și invers: la un AFN, „toate stările finale” nu dă $Sigma^*$ (un AFN poate să nu aibă tranziții pe unele simboluri).]
]

#problema[Incluziune][
  Fie $M_1$, $M_2$ două AFD. Cum verificăm dacă $L(M_1) subset.eq L(M_2)$? Argumentați.
][
  $L(M_1) subset.eq L(M_2)$ $<==>$ niciun cuvânt din $L(M_1)$ nu e în afara lui $L(M_2)$ $<==>$ $L(M_1) inter overline(L(M_2)) = emptyset$.
  + $overline(M_2)$: $M_2$ completat, cu finalele inversate.
  + Produsul $P = M_1 times overline(M_2)$, cu finalele $F_1 times (K_2 without F_2)$.
  + BFS în $P$ din $(s_1, s_2)$. Dacă se atinge o pereche $(p, q)$ cu $p in F_1$ și $q in.not F_2$, *nu* e inclus (drumul dă chiar un contraexemplu $w$); altfel e inclus.
  Termină: $P$ are $|K_1| dot |K_2|$ stări.
]

#problema[Același limbaj?][
  Cum decidem dacă două AFD $M_1$, $M_2$ acceptă același limbaj? Dar două ER?
][
  *Metoda 1:* $L_1 = L_2$ $<==>$ $L_1 triangle.stroked.t L_2 = emptyset$. Produsul cu finalele „exact una dintre componente e finală”, apoi test de vid.

  *Metoda 2:* minimizezi ambele automate (fără stări inaccesibile) și verifici că sunt izomorfe: AFD-ul minim al unui limbaj e unic, până la redenumirea stărilor.

  *Pentru două ER:* ER → AFN → AFD (toate sunt algoritmi), apoi metoda 1 sau 2. Deci echivalența ER-urilor e decidabilă. (Contrast: echivalența a două gramatici independente de context e *nedecidabilă*, la testul 2.)
]

#problema[Conține $a b a$?][
  Cum putem verifica dacă un AFD $M$ peste ${a, b}$ acceptă măcar un cuvânt care conține subcuvântul $a b a$?
][
  Fie $L_(a b a) = Sigma^* a b a Sigma^*$, regulat (ER). Întrebarea e $L(M) inter L_(a b a) != emptyset$.
  + AFD-ul $N$ pentru $L_(a b a)$ (4 stări, cap. 1).
  + Produsul $M times N$, cu finalele $F_M times {q_3}$.
  + BFS din $(s, q_0)$: „da” dacă se atinge o finală a produsului.
  Același tipar pentru orice „acceptă un cuvânt care…” cu o proprietate regulată: lungime pară (produs cu automatul cu 2 stări), începe cu $a$, are număr par de $b$ etc.
]

#problema[Un unic cel mai lung cuvânt nevid (fișa seminarului)][
  Cum putem verifica dacă un AFD $M$ acceptă un *unic* cel mai lung șir nevid?
][
  + *Finit și nevid.* Dacă $L(M)$ e infinit (ciclu în stările utile), nu există un cel mai lung cuvânt: răspuns „nu”. Dacă $L(M) without {e}$ e vid, nu există cuvânt nevid: „nu”.
  + *Lungimea maximă.* Graful stărilor utile $U$ e aciclic. Calculăm pentru fiecare stare $q in U$ $ell(q)$ = lungimea celui mai lung drum de la $q$ la o finală (programare dinamică în ordine topologică inversă: $ell(q) = max(0 "dacă" q in F, 1 + max_(q -> r) ell(r))$).
  + *Unicitatea.* Numărăm drumurile de lungime maximă $ell(s)$ de la $s$ la o finală (tot prin programare dinamică: $N(q)$ = numărul de drumuri de lungime $ell(q)$ care încep în $q$). Răspunsul e „da” dacă $ell(s) >= 1$ și $N(s) = 1$.
  *De ce numărăm drumuri și nu cuvinte:* la un AFD, drumuri diferite din $s$ citesc cuvinte diferite (determinism), deci numărul drumurilor = numărul cuvintelor.
]

#problema[Un șir care nu e în niciunul (examen, ianuarie 2025)][
  Fie două AFD $M_1$, $M_2$ peste același alfabet. Folosind proprietățile algoritmice, cum se poate determina dacă există un șir care nu este în niciunul dintre limbajele acceptate de automate?
][
  $exists w : w in.not L(M_1) and w in.not L(M_2)$ $<==>$ $overline(L(M_1) union L(M_2)) = overline(L(M_1)) inter overline(L(M_2)) != emptyset$.
  + Completăm ambele automate și construim produsul $M_1 times M_2$.
  + Finalele: perechile $(p, q)$ cu $p in.not F_1$ *și* $q in.not F_2$.
  + BFS din $(s_1, s_2)$: dacă atingem o astfel de pereche, șirul există (și drumul îl dă); altfel nu.
]

#problema[Prefixele lui $L(M_1)$ incluse în $L(M_2)$ (examen, februarie 2025)][
  Fie $M_1$, $M_2$ două AFD peste $Sigma$. Cum se poate determina dacă $"prefix"(L(M_1)) subset.eq L(M_2)$, unde $"prefix"(L) = {x | exists y, x y in L}$?
][
  + $M_1'$ pentru $"prefix"(L(M_1))$: în $M_1$ facem finală orice stare *din care se poate ajunge într-o finală* (parcurgere pe graful inversat din $F_1$). Stările inaccesibile nu contează.
  + $overline(M_2)$: inversăm finalele lui $M_2$ (completat).
  + Produsul $M_1' times overline(M_2)$ și test de vid. Dacă $L = emptyset$, atunci $"prefix"(L(M_1)) inter overline(L(M_2)) = emptyset$, adică incluziunea e adevărată; altfel e falsă.
]

#problema[Patru întrebări rapide][
  Pentru un AFD $M$ dat, cum decizi: (a) dacă $M$ acceptă un cuvânt de lungime pară; (b) dacă toate cuvintele lui $L(M)$ au lungime pară; (c) $|L(M)|$, dacă $L(M)$ e finit; (d) dacă $L(M) = L(M)^R$?
][
  (a) $L(M) inter ((a union b)(a union b))^* != emptyset$: produs cu AFD-ul cu 2 stări pentru „lungime pară”, apoi test de vid.

  (b) $L(M) inter {"lungime impară"} = emptyset$: același produs, cu cealaltă finală.

  (c) Da: graful util e aciclic; $|L(M)|$ = numărul de drumuri de la $s$ la stări finale, prin programare dinamică (un drum = un cuvânt, la AFD).

  (d) $L(M)^R$ e regulat (inversezi săgețile, determinizezi). Apoi testezi egalitatea a două limbaje regulate (diferența simetrică vidă).
]

#problema[Cât costă apartenența?][
  Cât durează să decizi dacă $w in L(M)$ pentru (a) un AFD; (b) un AFN; (c) o ER?
][
  (a) $O(|w|)$: un pas pe simbol, fără alegeri.

  (b) Simulezi mulțimea stărilor posibile (construcția submulțimilor „din mers”): $O(|w| dot |K|^2)$. Nu încerci toate drumurile (exponențial).

  (c) ER → AFN (liniar în lungimea ER-ului), apoi ca la (b).
]
