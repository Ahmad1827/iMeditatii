#import "tpl.typ": *

= Proprietăți algoritmice (P4)

O proprietate e *decidabilă* pentru limbajele regulate dacă există un algoritm care, primind un automat (sau o ER), răspunde corect *da* sau *nu* și se termină mereu. Pentru limbaje regulate, aproape tot e decidabil, pentru că automatul e un graf finit.

#teorema(t: [Ce poți decide, dat fiind un AFD $M$ (sau un AFN sau o ER, transformate întâi)])[
  #tabel(
    columns: (auto, 1fr),
    [*Întrebarea*], [*Algoritmul*],
    [$w in L(M)$?], [simulezi $M$ pe $w$: $|w|$ pași],
    [$e in L(M)$?], [$s in F$? (într-un AFN: $E(s) inter F != emptyset$)],
    [$L(M) = emptyset$?], [parcurgere în graf (BFS/DFS) din $s$: e vid $<==>$ nicio stare finală nu e accesibilă],
    [$L(M) = Sigma^*$?], [AFD complet, complementezi ($F' = K without F$), testezi vidul],
    [$L(M)$ finit?], [păstrezi doar stările *utile* (accesibile din $s$ și din care se ajunge într-o finală); $L$ e infinit $<==>$ graful lor are un *ciclu*],
    [$L(M_1) subset.eq L(M_2)$?], [$L(M_1) inter overline(L(M_2)) = emptyset$? (produs + vid)],
    [$L(M_1) = L(M_2)$?], [ambele incluziuni; sau $L(M_1) triangle.stroked.t L(M_2) = emptyset$; sau minimizezi și compari AFD-urile minime],
  )
]

== De ce funcționează testul de finitudine

Fie $U$ mulțimea stărilor utile.

- Dacă există un ciclu prin stări utile, fie $q$ pe ciclu: $s ->^u q$, $q ->^v q$ (cu $v != e$) și $q ->^z f in F$. Atunci $u v^i z in L$ pentru orice $i$, toate de lungimi diferite: $L$ e infinit.
- Dacă nu există ciclu, orice calcul acceptor trece prin stări utile distincte, deci are cel mult $|K| - 1$ pași: $L$ conține doar cuvinte de lungime $< |K|$, deci e finit.

#idee[Alt criteriu (din lema de pompare): dacă $M$ are $n$ stări, $L(M)$ e infinit $<==>$ $L(M)$ conține un cuvânt $w$ cu $n <= |w| < 2 n$. Algoritmul: testezi toate cuvintele de aceste lungimi. Corect, dar exponențial; pe test, metoda cu ciclul e mai elegantă.]

#petest[
  *Șablon de răspuns la P4:*
  + *Reducere:* transformă întrebarea într-una dintre cele standard (vid / finit / incluziune), folosind construcții de închidere (produs, complement).
  + *Algoritmul:* pașii concreți pe graful automatului.
  + *Corectitudine:* de ce „da” $<==>$ proprietatea (2–3 rânduri).
  + *Terminare:* automatul are un număr finit de stări, toate construcțiile sunt finite.
]

#problema[Infinit de cuvinte de lungime pară][
  Dat fiind un AFD $M$, decideți dacă $L(M)$ conține o infinitate de cuvinte de lungime pară.
][
  *Reducere:* întrebarea e dacă $L' = L(M) inter (Sigma Sigma)^*$ e infinit.
  + Construim AFD-ul pentru $(Sigma Sigma)^*$ (2 stări: lungime pară/impară) și produsul cu $M$; finale: $(f, "par")$, $f in F$.
  + Eliminăm stările inaccesibile și pe cele din care nu se ajunge într-o finală.
  + Răspuns „da” $<==>$ graful rămas are un ciclu (DFS: există o muchie înapoi).
  *Corectitudine:* produsul acceptă exact $L'$ (cap. 8); testul de finitudine e corect (mai sus). *Terminare:* produsul are $2|K|$ stări.
]

#problema[Un unic cel mai lung cuvânt nevid (fișa seminarului, ex. 7)][
  Cum verificăm, pentru un AFD $M$: (a) dacă $L(M)$ e finit; (b) dacă $M$ acceptă un *unic* cel mai lung cuvânt nevid?
][
  (a) Testul cu ciclul de mai sus.

  (b) Dacă $L(M)$ e infinit, nu există un cel mai lung cuvânt: răspuns „nu”. Altfel, graful stărilor utile e *aciclic* (un DAG). Calculăm, în ordine topologică, pentru fiecare stare utilă $q$:
  - $"lung"(q)$ = lungimea maximă a unui drum $s ~> q$;
  - $"nr"(q)$ = numărul de drumuri $s ~> q$ de lungime $"lung"(q)$.
  Fie $ell = max_(f in F "utilă") "lung"(f)$. Răspuns „da” $<==>$ $ell >= 1$ și suma lui $"nr"(f)$ peste finalele $f$ cu $"lung"(f) = ell$ e 1.

  *De ce numărăm drumuri:* $M$ e determinist, deci cuvinte diferite dau drumuri diferite din $s$, iar fiecare drum din $s$ citește un singur cuvânt. Numărul de cuvinte acceptate de lungime $ell$ e exact numărul de drumuri de lungime $ell$ de la $s$ la finale.
]

#problema[Conține un cuvânt cu $a b a$?][
  Dat un AFN $M$, decideți dacă există $w in L(M)$ care conține subsecvența $a b a$.
][
  $L(M) inter Sigma^* a b a Sigma^* != emptyset$? Construim AFD-ul pentru $Sigma^* a b a Sigma^*$ (cap. 3, 4 stări), determinizăm $M$ (sau facem produsul direct cu AFN-ul: produsul unui AFN cu un AFD e un AFN pentru intersecție), apoi testăm vidul prin parcurgere. Răspuns „da” $<==>$ o stare finală a produsului e accesibilă.
]

#problema[Două AFD-uri, același limbaj?][
  Dați două metode de a decide dacă $L(M_1) = L(M_2)$.
][
  *Metoda 1:* construim produsul cu $F = {(p, q) | p in F_1 "xor" q in F_2}$ (acceptă $L_1 triangle.stroked.t L_2$) și testăm vidul. Egale $<==>$ nicio stare din $F$ accesibilă din $(s_1, s_2)$.

  *Metoda 2:* minimizăm ambele AFD-uri (după ce le facem complete) și verificăm dacă sunt izomorfe, adică au aceeași structură până la redenumirea stărilor. Corect fiindcă AFD-ul minim e unic (Myhill–Nerode).
]

#capcana[„Decidabil” nu înseamnă „ușor pentru un om”: e suficient un algoritm care se termină. Nu răspunde niciodată cu „încercăm toate cuvintele” pentru vid sau $Sigma^*$: sunt infinit de multe, deci n-ai un algoritm. Ai nevoie de o *margine* (de exemplu, lungimi $< |K|$) sau de un argument pe graf.]
