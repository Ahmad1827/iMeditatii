# Run inside tool/acs/lfa.py (exec), after lfa_topics.py.
# Written problems, as the seminar tests ask them ("Arătați că…", "Cum putem
# verifica…", a proof with the pumping lemma): the student writes the
# argument, then grades it by the barem (each item with its points, adding up
# to the item's points in the test), or has Claude grade it. Ids 450-499.

REC = 'Recapitulare LFA: seminarele 1–4'
WT = 'Seminar LFA · model de problemă scrisă'


def written(id, title, ch, diff, statement, model, barem, topic_, total, source=WT, hint=''):
    pts = sum(p for _, p in barem)
    assert abs(pts - total) < 1e-9, (id, pts, total)
    spec = {'model': model.strip(), 'barem': [{'text': t, 'points': p} for t, p in barem]}
    P.append(problem(id, title, ch, diff, statement + f'\n\n**Problemă scrisă** ({str(total).replace(".", ",").removesuffix(",0")}p): scrie argumentarea, apoi compar-o cu baremul.', 'scris', spec, hint, model.strip(), source))
    P[-1]['topic'] = topic_


# ---------------------------------------------------------------- P1 · closure (2p)
written(450, 'Fără subsecvențe din F: arătați că e regulat', CP, 'medie',
        'Știind că `Σ` este un alfabet și `F ⊆ Σ*` este un limbaj finit, arătați că limbajul `L = {w ∈ Σ* | w nu are subsecvențe în F}` este regulat. (Hint: folosiți proprietăți de închidere.)',
        '''`F` e finit, deci regulat (orice limbaj finit e o reuniune finită de limbaje cu un singur cuvânt, fiecare descris de o ER).

Cuvintele care **au** o subsecvență din `F` sunt `Σ* F Σ*`: concatenare de limbaje regulate (`Σ*` e regulat), deci regulat.

`L` este complementul lor: `L = Σ* \\ (Σ* F Σ*)`. Limbajele regulate sunt închise la complement (într-un AFD complet inversezi stările finale cu cele nefinale), deci `L` e regulat.''',
        [('`F` finit ⇒ `F` regulat (cu justificare)', 0.5), ('cuvintele care conțin o subsecvență din `F` sunt `Σ*FΣ*`, regulat prin concatenare', 0.75),
         ('`L` e complementul lui `Σ*FΣ*`', 0.25), ('închiderea la complement, justificată (AFD complet, inversezi finalele)', 0.5)],
        'lr-inchidere', 2, source=REC)

written(451, 'Suf(L) e regulat', CP, 'medie',
        'Demonstrați că `Suf(L) = {w ∈ Σ* | ∃w′ ∈ L cu w sufix pentru w′}` este regulat atunci când `L` este regulat. (Hint: folosiți-vă de AF-uri.)',
        '''Fie `M = (K, Σ, δ, s, F)` un AFD pentru `L`. Fie `A` = mulțimea stărilor **accesibile** din `s` (există `x` cu `δ*(s, x) = q`).

Construiesc AFN-ul `M′ = (K ∪ {s′}, Σ, Δ, s′, F)`: o stare inițială nouă `s′`, cu tranziții pe `e` spre fiecare `q ∈ A`, plus toate tranzițiile lui `M`.

Corectitudine: `w ∈ L(M′)` ⇔ există `q ∈ A` cu `δ*(q, w) ∈ F` ⇔ există `x` cu `δ*(s, xw) ∈ F` ⇔ `xw ∈ L` pentru un `x` ⇔ `w` e sufix al unui cuvânt din `L`. Deci `Suf(L) = L(M′)`, regulat.''',
        [('pornești de la un AF pentru `L`', 0.25), ('stare inițială nouă cu tranziții pe `e` spre stările accesibile (sau: toate stările devin inițiale)', 0.75),
         ('de ce doar stările accesibile (altfel apar cuvinte în plus)', 0.25), ('demonstrația celor două incluziuni (`w ∈ L(M′)` ⇔ `w` e sufix)', 0.75)],
        'lr-inchidere', 2, source=REC)

written(452, 'Diferența simetrică a două limbaje regulate', CP, 'ușoară',
        'Fie `M1`, `M2` două AFD-uri. Arătați cum se construiește un automat finit `M` cu `L(M) = L(M1) △ L(M2)`, știind că `A △ B = (A ∪ B) \\ (A ∩ B)`. (Hint: similar cu automatul pentru intersecție.)',
        '''Fie `Mi = (Ki, Σ, δi, si, Fi)` complete. Automatul produs: `M = (K1 × K2, Σ, δ, (s1, s2), F)` cu `δ((p, q), a) = (δ1(p, a), δ2(q, a))`.

După citirea lui `w`, `M` e în `(δ1*(s1, w), δ2*(s2, w))`: rulează ambele automate deodată.

Pentru `△`, `w` trebuie acceptat de exact unul: `F = {(p, q) | p ∈ F1 xor q ∈ F2} = (F1 × (K2 \\ F2)) ∪ ((K1 \\ F1) × F2)`.

Automatele trebuie să fie complete (altfel o ramură se blochează și pierdem cuvinte acceptate de celălalt).''',
        [('automatul produs: stări perechi, tranziții pe componente', 0.75), ('starea inițială `(s1, s2)`', 0.25),
         ('finalele: exact una dintre componente finală', 0.75), ('atenția la completitudine (sau starea capcană)', 0.25)],
        'lr-inchidere', 2, source=REC)

written(453, 'Regulat prin închidere: #a par și fără bb', CP, 'ușoară',
        'Arătați, folosind proprietăți de închidere, că `L = {w ∈ {a, b}* | #a(w) este par și w nu conține bb}` este regulat.',
        '''`L = L1 ∩ L2`, cu `L1 = {w | #a(w) par}` și `L2 = {w | w nu conține bb}`.

`L1 = L((b*ab*a)*b*)` (sau un AFD cu 2 stări care ține paritatea lui `#a`): regulat.

`L2 = Σ* \\ (Σ* bb Σ*)`: `Σ* bb Σ*` e regulat (concatenare), iar complementul unui limbaj regulat e regulat.

Limbajele regulate sunt închise la intersecție (automatul produs), deci `L` e regulat.''',
        [('descompunerea `L = L1 ∩ L2`', 0.5), ('`L1` regulat, cu o ER sau un AF', 0.5), ('`L2` regulat (complementul lui `Σ*bbΣ*`, sau un AF)', 0.5), ('închiderea la intersecție, numită', 0.5)],
        'lr-inchidere', 2)

written(454, 'Lᴿ e regulat', CP, 'medie',
        'Fie `L` un limbaj regulat. Arătați că `Lᴿ = {wᴿ | w ∈ L}` este regulat.',
        '''Fie `M = (K, Σ, δ, s, F)` un AFD pentru `L`. Construiesc AFN-ul `Mᴿ`: inversez toate tranzițiile (`(p, a, q)` devine `(q, a, p)`), adaug o stare inițială nouă `s′` cu tranziții pe `e` spre fiecare stare din `F`, iar singura stare finală devine `s`.

Un calcul al lui `M` pe `w = a1…an` de la `s` la o finală `f` este, citit invers, un calcul al lui `Mᴿ` pe `an…a1` de la `f` la `s`, și reciproc. Deci `L(Mᴿ) = Lᴿ`.

(Alternativ, prin inducție pe structura unei ER: `(r1 r2)ᴿ = r2ᴿ r1ᴿ`, `(r1 ∪ r2)ᴿ = r1ᴿ ∪ r2ᴿ`, `(r*)ᴿ = (rᴿ)*`.)''',
        [('inversezi tranzițiile', 0.75), ('inițială nouă cu `e` spre vechile finale; finală vechea inițială', 0.5), ('justificarea: drumurile se corespund, citite invers', 0.75)],
        'lr-inchidere', 2)

written(455, '|L1| > |L2|: justificați fiecare propoziție', CP, 'grea',
        'Fie `L1, L2 ∈ LR` cu `|L1| > |L2|`. Argumentați sumar, pentru fiecare propoziție, dacă valoarea ei de adevăr depinde de `L1` și `L2`: (a) dacă `L1` e finit, atunci și `L2` e finit; (b) `L1 ⊆ L2`; (c) `L2 ⊆ L1`; (d) `L1 ∩ (L2 ∘ {e}) ∉ LR`.',
        '''Observația de bază: două limbaje infinite peste `Σ` au același cardinal (`Σ*` e numărabilă), deci din `|L1| > |L2|` rezultă că `L2` e **finit**.

(a) Mereu adevărată: `L2` e finit oricum (și cu atât mai mult dacă `L1` e finit, `|L2| < |L1|`).

(b) Mereu falsă: `L1 ⊆ L2 ⇒ |L1| ≤ |L2|`, contradicție.

(c) Depinde: `L1 = {a, b}`, `L2 = {a}` o face adevărată; `L2 = {c}` falsă.

(d) Mereu falsă: `L2 ∘ {e} = L2`, iar `L1 ∩ L2` e regulat (închidere la intersecție).''',
        [('observația că `L2` e finit (cardinal)', 0.5), ('(a) mereu adevărată, justificat', 0.25), ('(b) mereu falsă, justificat', 0.25),
         ('(c) depinde, cu două exemple', 0.5), ('(d) mereu falsă: `L2∘{e} = L2` și închiderea la intersecție', 0.5)],
        'lr-inchidere', 2, source='Test LR · Numărul 1 (altă grupă)')

# ---------------------------------------------------------------- P4 · algorithmic properties (1.5p)
written(460, 'Cum verificăm că L(M) e finit', CP, 'medie',
        'Cum putem verifica dacă, pentru un AFD `M`, `L(M)` este finit? Descrieți algoritmul și argumentați de ce e corect și de ce se termină.',
        '''Elimin stările inutile: păstrez doar stările **accesibile** din `s` (BFS de la `s`) și **coaccesibile** (din ele se ajunge într-o stare finală; BFS invers de la `F`).

`L(M)` e infinit ⇔ în graful rămas există un **ciclu**. Dacă e un ciclu pe un drum `s ⇝ q ⇝ q ⇝ f`, bucla se poate repeta de oricâte ori, deci infinit de multe cuvinte. Reciproc, dacă nu există ciclu, drumurile de la `s` la stări finale au lungime < `|K|`, deci limbajul e finit.

Se termină: BFS-urile și detectarea unui ciclu (DFS) lucrează pe un graf finit. (Alternativ: `L(M)` infinit ⇔ `M` acceptă un cuvânt cu `|K| ≤ |w| < 2|K|`, mulțime finită de cuvinte de testat.)''',
        [('elimini stările neaccesibile sau din care nu se ajunge la o finală', 0.5), ('infinit ⇔ ciclu în graful rămas', 0.5), ('justificarea (pompare / drumuri fără ciclu au lungime mărginită) și terminarea', 0.5)],
        'lr-algoritmice', 1.5, source=REC)

written(461, 'Un unic cel mai lung șir nevid', CP, 'grea',
        'Cum putem verifica dacă un AFD `M` acceptă un **unic** cel mai lung șir nevid?',
        '''Întâi `L(M)` trebuie să fie finit (altfel nu există un cel mai lung șir): verificare ca la limbaj finit (stări utile, fără ciclu).

Pe graful util, aciclic, calculez prin programare dinamică, pentru fiecare stare `q`, lungimea maximă `ℓ(q)` a unui drum de la `q` la o stare finală și **numărul** de drumuri care o ating (`c(q)`), mergând în ordine topologică inversă: `ℓ(q) = max(0 dacă q ∈ F, 1 + ℓ(δ(q, a)))`, iar `c(q)` adună contoarele succesorilor care ating maximul.

Răspunsul e da dacă `ℓ(s) ≥ 1` și `c(s) = 1`: un AFD dă un cuvânt diferit pentru fiecare drum, deci numărul de drumuri maxime e numărul de cuvinte maxime.''',
        [('condiția de limbaj finit, verificată', 0.5), ('lungimea maximă și numărul de drumuri maxime, pe graful aciclic', 0.5), ('un drum ↔ un cuvânt (AFD) și condiția `ℓ ≥ 1`, `c = 1`', 0.5)],
        'lr-algoritmice', 1.5, source=REC)

written(462, 'Cum verificăm L(M1) ⊆ L(M2)', CP, 'medie',
        'Fie `M1`, `M2` două AFD-uri. Cum putem verifica dacă `L(M1) ⊆ L(M2)`? Argumentați.',
        '''`L1 ⊆ L2` ⇔ niciun cuvânt din `L1` nu e în afara lui `L2` ⇔ `L1 ∩ ∁L2 = ∅`.

`∁L2`: completez `M2` (stare capcană) și inversez finalele. Intersecția: automatul produs al lui `M1` și al complementului, cu finale perechile (finală în `M1`, nefinală în `M2`).

Vidul: caut (BFS) un drum de la starea inițială `(s1, s2)` la o stare finală a produsului. Dacă nu există, `L1 ⊆ L2`; dacă există, drumul dă chiar un contraexemplu. Totul pe grafuri finite, deci se termină.''',
        [('reformularea `L1 ∩ ∁L2 = ∅`', 0.5), ('construcția (complement + produs)', 0.5), ('testul de vid prin căutare, cu terminarea', 0.5)],
        'lr-algoritmice', 1.5)

written(463, 'Cum verificăm L(M) = Σ*', CP, 'ușoară',
        'Cum putem verifica dacă un AFD `M` acceptă toate cuvintele peste `Σ`?',
        '''Completez `M` (stare capcană pentru tranzițiile lipsă). `L(M) = Σ*` ⇔ `∁L(M) = ∅`.

Complementul: același automat cu finalele inversate. Vidul: nu există drum de la `s` la o stare (acum) finală, adică la o stare nefinală a lui `M`.

Deci: `L(M) = Σ*` ⇔ **toate stările accesibile** din `s` sunt finale. Se verifică printr-un BFS de la `s`.''',
        [('completarea automatului', 0.25), ('reducerea la complement vid', 0.5), ('concluzia: toate stările accesibile sunt finale, verificat prin BFS', 0.75)],
        'lr-algoritmice', 1.5)

written(464, 'Acceptă M un cuvânt care conține aba?', CP, 'medie',
        'Cum putem verifica dacă un AFD `M` peste `{a, b}` acceptă măcar un cuvânt care conține subcuvântul `aba`?',
        '''Întrebarea e `L(M) ∩ L((a ∪ b)*aba(a ∪ b)*) ≠ ∅`.

Al doilea limbaj are un AFD cu 4 stări (cât din `aba` am potrivit). Automatul produs al celor două, cu finale perechile (finală, „găsit”), recunoaște intersecția.

Caut un drum de la starea inițială a produsului la o stare finală (BFS); există ⇔ răspunsul e da, iar drumul dă un astfel de cuvânt. Se termină: graf finit.''',
        [('reformularea ca intersecție nevidă', 0.5), ('AF pentru „conține aba” și produsul', 0.5), ('testul de vid și terminarea', 0.5)],
        'lr-algoritmice', 1.5)

# ---------------------------------------------------------------- P5 · pumping lemma (2p)
_PUMP_BAREM = lambda w, split, i: [
    ('presupui că `L` e regulat și iei `p` din lemă', 0.25),
    (f'alegi un cuvânt bun: {w}, cu `|w| ≥ p`', 0.5),
    (f'tratezi **orice** împărțire `w = xyz` cu `|xy| ≤ p`, `|y| ≥ 1`: {split}', 0.5),
    (f'găsești {i} și arăți că `xyⁱz ∉ L`', 0.5),
    ('concluzia: contradicție, `L` nu e regulat', 0.25)]

written(470, 'aⁿbⁿ nu e regulat', CP, 'ușoară',
        'Demonstrați, folosind lema de pompare, că `L = {aⁿbⁿ | n ≥ 0}` nu este regulat.',
        '''Presupun că `L` e regulat; fie `p` constanta din lema de pompare.

Aleg `w = aᵖbᵖ ∈ L`, `|w| = 2p ≥ p`.

Fie orice împărțire `w = xyz` cu `|xy| ≤ p` și `|y| ≥ 1`. Cum primele `p` simboluri sunt `a`, `y = aᵏ` cu `1 ≤ k ≤ p`.

Pentru `i = 2`: `xy²z = aᵖ⁺ᵏbᵖ`, cu mai mulți `a` decât `b`, deci `∉ L`. Contradicție cu lema: `L` nu e regulat.''',
        _PUMP_BAREM('`w = aᵖbᵖ`', '`y = aᵏ`, `k ≥ 1`', '`i = 2` (sau `i = 0`)'), 'lr-pompare', 2)

written(471, '#a = #b nu e regulat', CP, 'medie',
        'Arătați că `L = {w ∈ {a, b}* | #a(w) = #b(w)}` nu este regulat. Puteți folosi lema de pompare sau proprietăți de închidere.',
        '''**Cu închiderea:** dacă `L` ar fi regulat, atunci `L ∩ L(a*b*) = {aⁿbⁿ | n ≥ 0}` ar fi regulat (intersecție de regulate). Dar `{aⁿbⁿ}` nu e regulat (lema de pompare, cu `w = aᵖbᵖ`). Contradicție.

**Direct cu lema:** `w = aᵖbᵖ`; orice `y` cu `|xy| ≤ p` e `aᵏ`, `k ≥ 1`; `xy⁰z = aᵖ⁻ᵏbᵖ` are `#a ≠ #b`.''',
        [('alegerea metodei, enunțată corect', 0.25), ('intersecția cu `a*b*` (sau alegerea `w = aᵖbᵖ`)', 0.5),
         ('justificarea că rezultatul nu e regulat (sau tratarea tuturor împărțirilor)', 0.75), ('folosirea corectă a închiderii la intersecție / a lui `i`', 0.25), ('concluzia', 0.25)],
        'lr-pompare', 2)

written(472, 'ww nu e regulat', CP, 'medie',
        'Demonstrați că `L = {ww | w ∈ {a, b}*}` nu este regulat.',
        '''Presupun `L` regulat, cu constanta `p`.

Aleg `w = aᵖb aᵖb ∈ L` (`= uu` cu `u = aᵖb`). (Atenție: `aᵖaᵖ` nu merge, se poate pompa.)

Orice `xyz` cu `|xy| ≤ p`, `|y| ≥ 1`: `y = aᵏ`, `k ≥ 1`, în primul bloc.

`xy²z = aᵖ⁺ᵏb aᵖb`: are lungimea `2p + 2 + k`; dacă e impară nu e de forma `uu`; dacă e pară, jumătatea întâi se termină înainte de primul `b` sau îl conține fără să fie egală cu a doua (care conține un singur `b`, la sfârșit). În ambele cazuri `∉ L`. Contradicție.''',
        _PUMP_BAREM('`w = aᵖbaᵖb` (nu `a²ᵖ`)', '`y = aᵏ` în primul bloc', '`i = 2` (sau `0`)'), 'lr-pompare', 2)

written(473, 'aᵖ cu p prim nu e regulat', CP, 'grea',
        'Demonstrați că `L = {aⁿ | n este prim}` nu este regulat.',
        '''Presupun `L` regulat, cu constanta `p`. Aleg un prim `q ≥ p + 2` și `w = a^q`.

Orice împărțire: `y = aᵏ`, `1 ≤ k ≤ p`; fie `m = q − k = |xz| ≥ 2`.

Aleg `i = m`: `|xyᵐz| = m + mk = m(1 + k)`, produs de doi factori ≥ 2, deci nu e prim: `xyᵐz ∉ L`. Contradicție.''',
        _PUMP_BAREM('`w = a^q` cu `q` prim, `q ≥ p + 2`', '`y = aᵏ`, `1 ≤ k ≤ p`', '`i = q − k`, lungimea `(q − k)(1 + k)`'), 'lr-pompare', 2)

written(474, 'aⁱbʲ cu i > j nu e regulat', CP, 'medie',
        'Demonstrați că `L = {aⁱbʲ | i > j ≥ 0}` nu este regulat.',
        '''Presupun `L` regulat, cu constanta `p`. Aleg `w = aᵖ⁺¹bᵖ ∈ L`.

Orice împărțire cu `|xy| ≤ p`: `y = aᵏ`, `k ≥ 1`.

Pompez **în jos**, `i = 0`: `xz = aᵖ⁺¹⁻ᵏbᵖ`, cu `p + 1 − k ≤ p`, deci `#a ≤ #b`: `∉ L`. (Pomparea în sus nu ajută: păstrează `i > j`.) Contradicție.''',
        _PUMP_BAREM('`w = aᵖ⁺¹bᵖ`', '`y = aᵏ`', '`i = 0` (pomparea în jos), cu motivul'), 'lr-pompare', 2)

written(475, 'Palindroamele nu sunt regulate', CP, 'ușoară',
        'Demonstrați că `L = {w ∈ {a, b}* | w = wᴿ}` nu este regulat.',
        '''Presupun `L` regulat, cu constanta `p`. Aleg `w = aᵖbaᵖ ∈ L`.

Orice împărțire cu `|xy| ≤ p`: `y = aᵏ`, `k ≥ 1`, în primul bloc.

`i = 2`: `xy²z = aᵖ⁺ᵏbaᵖ`, iar oglinditul lui e `aᵖbaᵖ⁺ᵏ ≠`, deci nu e palindrom: `∉ L`. Contradicție.''',
        _PUMP_BAREM('`w = aᵖbaᵖ`', '`y = aᵏ` în primul bloc', '`i = 2`'), 'lr-pompare', 2)

# ---------------------------------------------------------------- P6 · bonus (2p)
written(480, 'Un AFD cu o singură stare acceptoare?', CP, 'grea',
        'Poate orice limbaj regulat să fie recunoscut de un AFD cu o singură stare acceptoare? Demonstrați.',
        '''**Nu.** Contraexemplu: `L = {e, a}` peste `Σ = {a}`.

Presupun un AFD `M` cu o singură finală `f`. `e ∈ L` ⇒ `s = f`. `a ∈ L` ⇒ `δ(s, a) = f = s`. Atunci `δ(s, aa) = s = f`, deci `aa ∈ L(M)`, dar `aa ∉ L`. Contradicție.

(Pentru AFN răspunsul e **da**: o finală nouă, cu tranziții pe `e` din toate vechile finale.)''',
        [('răspunsul corect (nu, pentru AFD)', 0.25), ('un contraexemplu bun', 0.5), ('demonstrația că niciun AFD cu o singură finală nu-l recunoaște', 1),
         ('observația pentru AFN (sau de ce nu se poate „uni” finalele la AFD)', 0.25)],
        'lr-bonus', 2, source=REC)

written(481, '|F| = |K|: ce rezultă', CP, 'grea',
        'Fie `M` un automat finit cu `|F| = |K|` (toate stările sunt finale). Stabiliți și justificați valorile de adevăr, pentru AFD și pentru AFN: (1) `e ∈ L(M)`; (2) dacă `w` e acceptat, orice prefix al lui `w` e în `L(M)`; (3) orice limbaj regulat care conține toate prefixele cuvintelor sale admite un astfel de automat.',
        '''(1) Adevărat pentru ambele: starea inițială e finală.

(2) AFD: adevărat. Calculul pe `w` trece prin stări pentru fiecare prefix, toate finale. (Dacă `M` nu e complet și se blochează, `w` nu e acceptat.) AFN: adevărat dacă tranzițiile sunt pe simboluri sau `e`: drumul acceptor pentru `w` trece prin prefixele lui; cu tranziții pe șiruri (`(q, ab, p)`), un prefix „din mijlocul” etichetei poate să nu fie acceptat (de ex. `Δ = {(s, ab, s)}`: `ab` acceptat, `a` nu).

(3) Adevărat, cu un AFD **parțial** sau un AFN: iei AFD-ul minimal, scoți starea capcană (din care nu se mai ajunge la finală); pentru un limbaj închis la prefixe toate stările rămase sunt finale (dintr-o stare utilă nefinală s-ar ajunge la un cuvânt acceptat al cărui prefix nu e acceptat). Pentru un AFD complet, fals (de ex. `L = {e, a}` peste `{a}`: capcana trebuie să fie nefinală).''',
        [('(1) adevărat, justificat', 0.25), ('(2) AFD: adevărat, cu drumul prin prefixe', 0.5), ('(2) AFN: cazul etichetelor pe șiruri', 0.5), ('(3) cu capcana scoasă / AFN, justificat', 0.5), ('(3) cazul AFD complet', 0.25)],
        'lr-bonus', 2, source=REC)

written(482, 'Myhill–Nerode: aⁿbⁿ are infinit de multe clase', CP, 'grea',
        'Folosind teorema Myhill–Nerode, arătați că `L = {aⁿbⁿ | n ≥ 0}` nu este regulat.',
        '''Pentru `i ≠ j`, cuvintele `aⁱ` și `aʲ` sunt în clase diferite ale lui `≡_L`: sufixul `z = bⁱ` dă `aⁱbⁱ ∈ L`, dar `aʲbⁱ ∉ L`.

Deci `a, a², a³, …` sunt în clase două câte două diferite: `≡_L` are o infinitate de clase. Myhill–Nerode: `L` e regulat ⇔ `≡_L` are un număr finit de clase. Deci `L` nu e regulat.''',
        [('enunțul relației `≡_L` / al teoremei', 0.5), ('familia infinită `aⁱ`', 0.5), ('sufixul care le deosebește, verificat', 0.75), ('concluzia', 0.25)],
        'lr-bonus', 2)

# ---------------------------------------------------------------- test 2: P1 grammars (3p), P4 algorithmic (2p)
written(490, 'Arătați că gramatica e ambiguă', C4, 'medie',
        'Fie gramatica `E → E + E | E * E | a`. Arătați că este ambiguă și scrieți o gramatică neambiguă echivalentă, în care `*` are prioritate față de `+`.',
        '''Cuvântul `a + a * a` are două derivări stânga diferite (deci doi arbori):

`E ⇒ E + E ⇒ a + E ⇒ a + E * E ⇒ a + a * E ⇒ a + a * a` (`*` sub `+`)

`E ⇒ E * E ⇒ E + E * E ⇒ a + E * E ⇒ a + a * E ⇒ a + a * a` (`+` sub `*`)

Gramatica neambiguă, pe niveluri de prioritate: `E → E + T | T`, `T → T * F | F`, `F → a`. Fiecare cuvânt are un singur arbore: `+` doar la nivelul `E`, `*` doar la `T`, asociativitate la stânga.''',
        [('un cuvânt cu două derivări stânga / doi arbori', 1), ('cele două derivări scrise complet', 0.75), ('gramatica neambiguă pe niveluri', 1), ('de ce e neambiguă / echivalentă', 0.25)],
        'lic-gramatici', 3)

written(491, 'Derivare stânga, dreapta și arbore', C4, 'ușoară',
        'Fie `S → aSb | SS | e`. Pentru `w = aabbab`, scrieți o derivare stânga, o derivare dreapta și arborele de derivare. Este gramatica ambiguă?',
        '''Stânga: `S ⇒ SS ⇒ aSbS ⇒ aaSbbS ⇒ aabbS ⇒ aabbaSb ⇒ aabbab`.

Dreapta: `S ⇒ SS ⇒ SaSb ⇒ Sab ⇒ aSbab ⇒ aaSbbab ⇒ aabbab`.

Arborele: rădăcina `S` cu fiii `S S`; primul `S → aSb` cu `S → aSb → ab` în interior (`aabb`), al doilea `S → aSb` cu `S → e` (`ab`).

Da, e ambiguă: `S → SS` cu `S → e` dă arbori diferiți pentru `e` (`S ⇒ e` și `S ⇒ SS ⇒ S ⇒ e`) și pentru orice cuvânt (`S ⇒ SS` cu un `S` vid).''',
        [('derivarea stânga, corectă', 0.75), ('derivarea dreapta, corectă', 0.75), ('arborele', 0.75), ('ambiguitatea, cu doi arbori pentru același cuvânt', 0.75)],
        'lic-gramatici', 3)

written(492, 'Cum verificăm că L(G) e vid sau finit', C4, 'medie',
        'Fie `G` o gramatică independentă de context. Descrieți cum putem verifica (a) dacă `L(G) = ∅` și (b) dacă `L(G)` este finit.',
        '''(a) Calculez neterminalii **generatori**: inițial cei cu o regulă `A → w`, `w ∈ Σ*`; apoi adaug `A` dacă are o regulă în care toate simbolurile sunt terminale sau generatori; repet până nu se mai schimbă (cel mult `|V|` runde). `L(G) = ∅` ⇔ `S` nu e generator.

(b) Elimin simbolurile inutile (negeneratori, apoi neaccesibili din `S`) și aduc `G` în FNC. Construiesc graful cu muchie `A → B` dacă `B` apare în dreapta unei reguli a lui `A`. `L(G)` e infinit ⇔ graful are un ciclu: `A ⇒+ uAv` cu `uv ≠ e` (în FNC) se poate repeta; fără ciclu, arborii au înălțime mărginită, deci cuvinte finite ca număr.''',
        [('(a) neterminalii generatori, iterativ', 0.75), ('(a) criteriul `S` generator și terminarea', 0.25), ('(b) eliminarea simbolurilor inutile (și FNC)', 0.5), ('(b) ciclu în graful dependențelor ⇔ infinit, justificat', 0.5)],
        'lic-algoritmice', 2)
