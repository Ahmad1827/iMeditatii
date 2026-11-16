#import "tpl.typ": *

= Din automat în ER (P3)

#teorema[Pentru orice automat finit $M$ există o ER $alpha$ cu $L(alpha) = L(M)$. Împreună cu cap. 5: *ER, AFN și AFD descriu exact aceeași clasă de limbaje*, limbajele regulate.]

== Metoda 1: eliminarea stărilor

Lucrăm cu un automat generalizat, în care muchiile sunt etichetate cu ER.

#teorema(t: "Algoritm")[
  + *Pregătire.* Adaugă o stare inițială nouă $s'$ cu $s' ->^e s$ și o stare finală nouă $f'$ cu $q ->^e f'$ pentru fiecare $q in F$. Acum $s'$ nu are intrări, $f'$ nu are ieșiri și e singura finală. Dacă între două stări sunt mai multe muchii, le unești: $p ->^(alpha union beta) r$.
  + *Eliminare.* Alegi o stare $q in.not {s', f'}$. Pentru *fiecare* pereche $(p, r)$ cu $p ->^alpha q$ și $q ->^gamma r$ (cu $p, r != q$, dar posibil $p = r$), dacă $q$ are bucla $beta$ și exista deja $p ->^delta r$, pui
  $ p ->^(delta union alpha beta^* gamma) r $
  (fără $delta$ dacă nu exista muchia; fără $beta^*$ dacă $q$ nu are buclă). Apoi ștergi $q$.
  + Repeți până rămân doar $s'$ și $f'$. Eticheta $s' -> f'$ e ER-ul căutat.
]

#petest[
  - Înainte de orice, *șterge starea capcană* și stările din care nu se ajunge la o finală: nu contribuie la limbaj și îți complică formulele.
  - Elimină întâi stările cu puține muchii. Ordinea nu schimbă limbajul, doar forma ER-ului.
  - La fiecare eliminare, scrie lista perechilor $(p, r)$ afectate. Cea mai frecventă greșeală: uiți o pereche, mai ales $p = r$ (care dă o buclă nouă).
]

#problema[Eliminare: numere binare divizibile cu 3][
  Găsiți o ER pentru AFD-ul din problema cu resturile modulo 3 (stările $r_0, r_1, r_2$, $r_0$ inițială și finală).
][
  *Pregătire:* $s' ->^e r_0$, $r_0 ->^e f'$.
  #aut(
    (s: (r0: "e"), r0: (r0: "0", r1: "1", f: "e"), r1: (r0: "1", r2: "0"), r2: (r1: "0", r2: "1"), f: (:)),
    (s: (0, 0), r0: (2.4, 0), r1: (5.4, 0), r2: (8.4, 0), f: (2.4, -2.4)),
    final: ("f",),
    etichete: (s: $s'$, f: $f'$),
    st: ("r0-r1": (curve: .5), "r1-r0": (curve: .5), "r1-r2": (curve: .5), "r2-r1": (curve: .5), "r0-r0": (anchor: top), "r2-r2": (anchor: top)),
  )
  *Eliminăm $r_2$* (buclă $1$). Singura pereche: $(r_1, r_1)$, cu $r_1 ->^0 r_2 ->^0 r_1$: buclă nouă pe $r_1$: $0 1^* 0$.

  *Eliminăm $r_1$* (buclă $0 1^* 0$). Singura pereche: $(r_0, r_0)$, cu $r_0 ->^1 r_1 ->^1 r_0$. Exista deja bucla $0$ pe $r_0$, deci bucla devine $0 union 1 (0 1^* 0)^* 1$.

  *Eliminăm $r_0$.* Perechea $(s', f')$: $e dot (0 union 1 (0 1^* 0)^* 1)^* dot e$.
  $ alpha = (0 union 1 (0 1^* 0)^* 1)^* $
]

#problema[Eliminare cu stare capcană: începe cu $a b$, se termină cu $b$][
  Găsiți o ER pentru AFD-ul cu stările $q_0, q_1, q_2, q_3, d$ din cap. 3.
][
  Ștergem $d$ (capcana). Rămân $q_0 ->^a q_1 ->^b q_2$, bucla $b$ pe $q_2$, $q_2 ->^a q_3$, bucla $a$ pe $q_3$, $q_3 ->^b q_2$; $F = {q_2}$. Pregătire: $s' ->^e q_0$, $q_2 ->^e f'$.

  *Eliminăm $q_3$:* perechea $(q_2, q_2)$: $q_2 ->^a q_3$, buclă $a$, $q_3 ->^b q_2$; bucla lui $q_2$ devine $b union a a^* b$.

  *Eliminăm $q_1$:* $q_0 ->^(a b) q_2$. *Eliminăm $q_0$:* $s' ->^(a b) q_2$. *Eliminăm $q_2$:*
  $ alpha = a b (b union a a^* b)^* $
  Verificare: $a b$ (zero repetări) e inclus; $a b a$ nu (după $a$ trebuie să urmeze $b$).
]

#problema[Eliminare: paritatea lui $a$ și $b$][
  ER pentru cuvintele cu număr par de $a$ și număr par de $b$ (AFD-ul cu stările $P P, I P, P I, I I$ din cap. 3).
][
  Pregătire: $s' ->^e P P$, $P P ->^e f'$.

  *Eliminăm $I I$* (fără buclă). Intră: $I P ->^b I I$, $P I ->^a I I$. Ies: $I I ->^a P I$, $I I ->^b I P$. Perechi:
  - $(I P, I P)$: buclă $b b$; $(I P, P I)$: $b a$; $(P I, P I)$: buclă $a a$; $(P I, I P)$: $a b$.
  *Eliminăm $P I$* (buclă $a a$). Intră: $P P ->^b P I$, $I P ->^(b a) P I$. Ies: $P I ->^b P P$, $P I ->^(a b) I P$. Perechi:
  - $(P P, P P)$: buclă $b (a a)^* b$; $(P P, I P)$: $a union b (a a)^* a b$ (exista deja $P P ->^a I P$);
  - $(I P, P P)$: $a union b a (a a)^* b$; $(I P, I P)$: bucla devine $b b union b a (a a)^* a b$.
  Notăm $X = b (a a)^* b$, $Y = a union b (a a)^* a b$, $Z = a union b a (a a)^* b$, $W = b b union b a (a a)^* a b$.

  *Eliminăm $I P$* (buclă $W$): pe $P P$ apare bucla $X union Y W^* Z$. *Eliminăm $P P$:*
  $ alpha = (X union Y W^* Z)^* = (b (a a)^* b union (a union b (a a)^* a b)(b b union b a (a a)^* a b)^* (a union b a (a a)^* b))^* $
  E corect, dar urât; ER-ul „gândit” din cap. 2 e mai scurt. Pe test, oricare e acceptat, cât timp pașii sunt corecți.
]

== Metoda 2: sistemul de ecuații (lema lui Arden)

Pentru fiecare stare $q$, $X_q$ = limbajul cuvintelor care duc din $q$ într-o stare finală. Scrii câte o ecuație: $X_q = union.big_(q ->^a p) a X_p$, plus $union e$ dacă $q in F$.

#teorema(t: "Lema lui Arden")[Dacă $e in.not L(alpha)$, ecuația $X = alpha X union beta$ are soluția unică $X = alpha^* beta$.]

#problema[Ecuații: număr par de $a$][
  Rezolvați sistemul pentru AFD-ul cu stările $P$ (inițială, finală) și $I$.
][
  $ X_P = b X_P union a X_I union e, quad X_I = b X_I union a X_P $
  Din a doua, cu Arden ($alpha = b$, $beta = a X_P$): $X_I = b^* a X_P$. Înlocuim:
  $ X_P = b X_P union a b^* a X_P union e = (b union a b^* a) X_P union e ==> X_P = (b union a b^* a)^* $
  Răspunsul e $X_P$ (starea inițială): $(b union a b^* a)^*$. Am obținut altă formă a lui $b^* (a b^* a b^*)^*$ din cap. 2.
]

#idee[Ecuațiile sunt rapide pentru automate cu 2–3 stări. Eliminarea stărilor e mai ușor de urmărit pe automate mai mari, iar corectorul îi poate verifica pașii unul câte unul.]
