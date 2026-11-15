# Run inside tool/acs/lfa.py (exec), after lfa_more.py, with its helpers in scope.
# Problems for the seminar tests' items that had few: another group's Test LR
# nr. 1, the algorithms that decide questions about regular and context-free
# languages, the pumping lemma's method, and conversions to do by hand
# (subsets, elimination, minimisation). Each says its item (topic). Ids 400-449.

OTHER = 'Test LR · Numărul 1 (altă grupă)'


def _q(id, title, ch, diff, statement, right, wrong, why, hint='', source=''):
    P.append(quiz(id, title, ch, diff, statement, right, wrong, hint=hint, solution=why, source=source))


def _tf(id, title, ch, diff, statement, truth, why, source=''):
    P.append(true_false(id, title, ch, diff, statement, truth, solution=why, source=source))


def topic(t):
    P[-1]['topic'] = t


# ---------------------------------------------------------------- the other group's test
_q(400, '|Δ| la un AFN: cel mai mic și cel mai mare', C2, 'medie',
  'Fie `A = (Σ, Q, q0, F, Δ)` un AFN cu tranziții pe simboluri și pe `e` (`Δ ⊆ Q × (Σ ∪ {e}) × Q`). Care sunt cea mai mică și cea mai mare valoare posibilă a lui `|Δ|`?',
  '`(0, |Q|²(|Σ| + 1))`',
  ['`(0, |Q||Σ|²)`', '`(0, (|Q| + 1)|Σ|²)`', '`(0, |Q|²|Σ|)`', '`(1, |Q|²(|Σ| + 1))`', '`(1, |Q|²|Σ|)`'],
  'Un AFN poate să nu aibă nicio tranziție (acceptă atunci cel mult `e`, dacă `q0 ∈ F`), deci minimul e 0. O tranziție e un triplet (stare, simbol sau `e`, stare): `|Q| · (|Σ| + 1) · |Q|` triplete posibile.\n\n'
  'Bonus (din test): în definiția cursului `Δ ⊆ K × Σ* × K`, cu etichete șiruri. Atunci `Δ` e **finită** (orice automat e un obiect finit), dar **nu e mărginită** pentru `K` și `Σ` date: etichetele pot fi oricât de lungi.',
  source=OTHER)
topic('lr-reprezentare')

_dep = ['întotdeauna adevărată', 'întotdeauna falsă', 'depinde de `L1` și `L2`']
_why2 = 'Cheia: dacă `|L1| > |L2|`, atunci `L2` e **finit** (două limbaje infinite peste `Σ` sunt ambele numărabile, deci au același cardinal).'
for _id, _prop, _right, _why in [
    (401, 'Dacă `L1` este finit, atunci și `L2` este finit.', 0, 'Din `|L1| > |L2|`, `L2` are mai puține cuvinte decât un limbaj finit, deci e finit (de fapt `L2` e finit oricum).'),
    (402, '`L1 ⊆ L2`', 1, 'O submulțime nu poate avea mai multe elemente: `L1 ⊆ L2 ⇒ |L1| ≤ |L2|`.'),
    (403, '`L2 ⊆ L1`', 2, 'Depinde: `L1 = {a, b}`, `L2 = {a}` o face adevărată, `L2 = {c}` falsă.'),
    (404, '`L1 ∩ (L2 ∘ {e}) ∉ LR`', 1, '`L2 ∘ {e} = L2`, iar `L1 ∩ L2` e regulat (LR e închisă la intersecție). Deci „∉ LR” e mereu fals.'),
]:
    P.append(quiz_multi(_id, f'|L1| > |L2|: {_prop}'.replace('`', ''), CP, 'medie',
                        f'Fie `L1, L2 ∈ LR` cu `|L1| > |L2|`. Propoziția următoare este: {_prop}', _dep, [_right],
                        solution=f'{_why2}\n\n{_why}', source=OTHER))
    topic('lr-inchidere')

dfa_in(405, '3 | #0, 2 | #1, se termină cu 0', C1, 'medie',
       'Fie `Σ = {0, 1}`. Scrie un AF pentru `L = {w ∈ Σ* | 3 | #0(w) ∧ 2 | #1(w) ∧ ∃x ∈ Σ*: w = x0}` (numărul de `0` divizibil cu 3, numărul de `1` par, iar `w` se termină cu `0`).', '01',
       lambda w: w.count('0') % 3 == 0 and w.count('1') % 2 == 0 and w.endswith('0'), None,
       hint='Produsul a două numărătoare (`#0 mod 3`, `#1 mod 2`): 6 stări. Starea finală (0, 0) trebuie împărțită după ultimul simbol citit.',
       solution='Stările (`#0 mod 3`, `#1 mod 2`) dau 6 stări; în (0, 0) se poate ajunge și cu `0`, și cu `1`, iar acceptăm doar după `0`. Deci (0, 0) se dublează: „(0, 0) după 0” e finală, „(0, 0) altfel” (inclusiv starea inițială) nu: 7 stări.',
       source=OTHER, max_states=7)
topic('lr-reprezentare')

regex_in(406, 'Doar perechile 00, 12, 22', C3, 'medie',
         'Fie `Σ = {0, 1, 2}`. Scrie o ER pentru `L = {w ∈ Σ* | #01(w) = #02(w) = #11(w) = #10(w) = #21(w) = #20(w) = 0}` (la test: altă formă de reprezentare decât la exercițiul anterior).', '012',
         lambda w: not any(p in w for p in ('01', '02', '11', '10', '21', '20')), '0*∪12*∪2*',
         hint='Ce poate urma după fiecare simbol? Rămân doar perechile `00`, `12`, `22`.',
         solution='După `0` vine doar `0`, după `1` doar `2`, după `2` doar `2`. Un cuvânt e deci `0…0`, sau `1` urmat de `2`-uri, sau doar `2`-uri: `0* ∪ 12* ∪ 2*` (sau `0* ∪ (1 ∪ e)2*`).',
         source=OTHER)
topic('lr-reprezentare')

regex_in(407, 'Câtul X \\ L, pe un exemplu', C3, 'grea',
         'Pentru `X, L ∈ LR`, `W = {w ∈ Σ* | ∃x ∈ X astfel încât xw ∈ L}`. Fie `Σ = {a, b}`, `X = L(b*a)` și `L = L((a ∪ b)*aab)`. Scrie o ER pentru `W`.', 'ab',
         lambda w: ('a' + w).endswith('aab'), '(a∪b)*aab∪ab',
         hint='Orice `x ∈ X` se termină cu `a`, iar `b`-urile de dinainte nu contează. Când se termină `aw` cu `aab`?',
         solution='`xw` se termină cu `aab` exact când `aw` se termină cu `aab`: fie `w` însuși se termină cu `aab`, fie `w = ab` (`a·ab = aab`). Deci `W = L((a ∪ b)*aab ∪ ab)`.',
         source=OTHER)
topic('lr-inchidere')

_q(408, 'De ce W = {w | ∃x ∈ X: xw ∈ L} e regulat', CP, 'grea',
  'Fie `X, L ∈ LR` și `W = {w ∈ Σ* | ∃x ∈ X astfel încât xw ∈ L}`. Care construcție dă un AF pentru `W`?',
  'AFD-ul `M` al lui `L`, cu o stare inițială nouă legată prin `e` de toate stările în care `M` ajunge citind un cuvânt din `X`',
  ['produsul AFD-urilor lui `X` și `L`, cu finale perechile (finală, finală)', 'automatul lui `X` legat prin `e`, din stările finale, de starea inițială a lui `L`',
   '`W` nu e neapărat regulat: depinde de `X`'],
  'Un `w` e bun dacă `M`, pornit dintr-o stare `q` în care ajunge după un `x ∈ X`, termină într-o stare finală. Mulțimea `S` a acestor stări e calculabilă: `q ∈ S` ⇔ `X ∩ L(M cu finala {q})` e nevid (produs + test de vid). Apoi o stare inițială nouă cu `e` spre fiecare `q ∈ S`. Produsul dă `X ∩ L`, legarea dă `XL`.',
  source=OTHER)
topic('lr-inchidere')

# ---------------------------------------------------------------- algorithms for regular languages
ALG = 'Seminar LFA · proprietăți algoritmice'
for _id, _t, _st, _right, _wrong, _why in [
    (410, 'L(M) = ∅?', 'Cum decizi dacă un AFD `M` acceptă măcar un cuvânt?',
     'cauți (BFS/DFS) un drum de la starea inițială la o stare finală',
     ['încerci pe rând toate cuvintele din `Σ*`', 'aplici lema de pompare', 'nu se poate decide'],
     'Graful stărilor e finit, deci căutarea se termină. Încercarea tuturor cuvintelor nu se oprește dacă limbajul e vid.'),
    (411, 'L(M) infinit?', 'Fie `M` un AFD cu `n` stări. `L(M)` este infinit dacă și numai dacă:',
     '`M` acceptă un cuvânt `w` cu `n ≤ |w| < 2n`',
     ['`M` are cel puțin o buclă', '`M` acceptă un cuvânt de lungime `n − 1`', '`M` are mai multe stări finale decât nefinale'],
     'Un cuvânt de lungime ≥ n trece de două ori printr-o stare (pompare), deci se poate repeta bucla. Iar dacă există unul acceptat de lungime ≥ n, există și unul între n și 2n − 1 (scoți bucle). Echivalent: un ciclu pe un drum de la start la o finală (o buclă oarecare nu ajunge: poate fi într-o groapă).'),
    (412, 'L(M1) = L(M2)?', 'Cum decizi dacă două AFD-uri `M1`, `M2` acceptă același limbaj?',
     'construiești automatul produs pentru `(L1 \\ L2) ∪ (L2 \\ L1)` și verifici că e vid',
     ['compari numărul de stări', 'testezi toate cuvintele de lungime cel mult 100', 'nu se poate decide'],
     'Diferența simetrică e regulată (produs, finale = perechi cu exact o componentă finală) și e vidă exact când limbajele coincid. Altă cale: minimizezi ambele și compari (AFD-ul minimal e unic, până la redenumire).'),
    (413, 'L(M) = Σ*?', 'Cum decizi dacă un AFD complet `M` acceptă toate cuvintele?',
     'schimbi stările finale cu cele nefinale și verifici că limbajul obținut e vid',
     ['verifici că toate stările sunt finale', 'verifici că starea inițială e finală', 'nu se poate decide pentru AF'],
     'Complementul unui AFD complet se obține inversând finalele; `L = Σ*` ⇔ `∁L = ∅`. „Toate stările finale” e suficient, dar nu necesar (stările inaccesibile pot fi nefinale).'),
    (414, 'L1 ⊆ L2?', 'Cum decizi dacă `L(M1) ⊆ L(M2)` pentru două AFD-uri?',
     'verifici că `L1 ∩ ∁L2` e vid (produs + test de vid)',
     ['verifici că `M1` are mai puține stări decât `M2`', 'verifici că `L1 ∪ L2 = L2` pe cuvinte scurte', 'nu se poate decide'],
     '`L1 ⊆ L2` ⇔ niciun cuvânt din `L1` nu e în afara lui `L2` ⇔ `L1 ∩ ∁L2 = ∅`. Toate operațiile se fac pe automate.'),
    (415, 'w ∈ L(M) pentru un AFD', 'Cât durează să decizi dacă `w ∈ L(M)` pentru un AFD `M` dat?',
     '`O(|w|)`: un pas pentru fiecare simbol',
     ['`O(2^|w|)`', '`O(|w|³)`, ca CYK', 'depinde de numărul de stări exponențial'],
     'Un AFD citește fiecare simbol o dată, fără alegeri. Pentru un AFN se ține mulțimea stărilor posibile: `O(|w| · |K|²)`.'),
    (416, 'Două ER, același limbaj?', 'Este decidabil dacă două expresii regulate descriu același limbaj?',
     'da: ER → AFN → AFD, apoi AFD-urile minimale (sau diferența simetrică) se compară',
     ['nu, e nedecidabil ca la gramatici', 'da, comparând expresiile simbol cu simbol', 'doar dacă expresiile nu au stea'],
     'Toate conversiile sunt algoritmi. Spre deosebire de LIC, unde echivalența e nedecidabilă.'),
    (417, 'Un cuvânt de lungime pară în L(M)?', 'Cum decizi dacă un AFD `M` acceptă măcar un cuvânt de lungime pară?',
     'produsul lui `M` cu AFD-ul cu 2 stări pentru lungime pară, apoi test de vid',
     ['verifici dacă `M` are un număr par de stări', 'încerci cuvintele de lungime 0, 2, 4, … până găsești unul', 'nu se poate decide'],
     '`L(M) ∩ ((a ∪ b)(a ∪ b))*` e regulat; întrebarea devine „e vid?”. Încercarea la nesfârșit nu se oprește dacă răspunsul e nu.'),
    (418, 'Câte cuvinte are L(M)?', 'Fie `M` un AFD cu `L(M)` finit. Se poate calcula `|L(M)|`?',
     'da: numeri drumurile de la start la stările finale (graful util nu are cicluri)',
     ['nu, nu se poate calcula', 'doar prin lema de pompare', 'e mereu numărul de stări finale'],
     'Limbaj finit ⇒ după ce scoți stările care nu duc la o finală, nu rămâne niciun ciclu; drumurile se numără prin programare dinamică pe un graf aciclic.'),
]:
    _q(_id, _t, CP, 'medie', _st, _right, _wrong, _why, source=ALG)
    topic('lr-algoritmice')

# ---------------------------------------------------------------- the pumping lemma's method
PUMP = 'Seminar LFA · lema de pompare'
_q(420, 'Cine ce alege în lema de pompare', CP, 'ușoară', 'Când demonstrezi cu lema de pompare că `L` NU e regulat, ce alegi TU?',
  'cuvântul `w ∈ L` cu `|w| ≥ p` și, pentru fiecare împărțire, un `i`', ['`p` și împărțirea `w = xyz`', 'doar `i`', '`p`, `w` și împărțirea'],
  'Lema: ∃p ∀w ∃xyz ∀i. Ca s-o negi: ∀p ∃w ∀xyz ∃i. Adversarul alege `p` și împărțirea; tu alegi `w` (în funcție de `p`) și `i` (în funcție de împărțire).', source=PUMP)
topic('lr-pompare')
_q(421, 'aⁿbⁿ: de ce y are doar a', CP, 'ușoară', 'Pentru `L = {aⁿbⁿ | n ≥ 0}` alegi `w = aᵖbᵖ`. De ce, în orice împărțire `w = xyz`, `y` conține doar `a`?',
  'pentru că `|xy| ≤ p`, deci `xy` stă în primele `p` simboluri, care sunt toate `a`', ['pentru că `|y| ≥ 1`', 'pentru că tu alegi `y`', 'pentru că `w ∈ L`'],
  'Condiția `|xy| ≤ p` e cea care fixează `y` în prima zonă. Apoi `xy²z = aᵖ⁺ᵏbᵖ ∉ L` (cu `k = |y| ≥ 1`).', source=PUMP)
topic('lr-pompare')
_q(422, 'Limbajul satisface lema: deci?', CP, 'medie', 'Un limbaj `L` satisface condiția din lema de pompare pentru limbaje regulate. Ce se poate spune?',
  'nimic sigur: și unele limbaje neregulate o satisfac', ['`L` e regulat', '`L` nu e regulat', '`L` e finit'],
  'Lema e o condiție necesară, nu suficientă. Exemplu: `{aⁱbʲcʲ | i ≥ 1} ∪ {bʲcᵏ}` satisface lema, dar nu e regulat. Lema se folosește doar ca să arăți că un limbaj NU e regulat.', source=PUMP)
topic('lr-pompare')
_q(423, 'a^(n²): cum închizi demonstrația', CP, 'grea', 'Pentru `L = {a^(n²) | n ≥ 0}`, `w = a^(p²)` și `i = 2`. Ce argument arată că `xy²z ∉ L`?',
  '`p² < p² + |y| ≤ p² + p < (p + 1)²`, deci lungimea nu e pătrat perfect',
  ['`|xy²z| = 2p²`, care nu e pătrat perfect', '`xy²z` are mai mulți `a` decât `b`', '`|y| ≥ 1`, deci `xy²z` e mai lung'],
  '`1 ≤ |y| ≤ |xy| ≤ p`, deci noua lungime e strict între două pătrate consecutive.', source=PUMP)
topic('lr-pompare')
_tf(424, 'Limbajele finite și lema de pompare', CP, 'medie',
   'Orice limbaj finit satisface lema de pompare pentru limbaje regulate (cu `p` mai mare decât cel mai lung cuvânt).', True,
   'Dacă `p` depășește lungimea oricărui cuvânt, nu există `w ∈ L` cu `|w| ≥ p`, deci condiția e adevărată în gol. Firesc: limbajele finite sunt regulate.', source=PUMP)
topic('lr-pompare')

# ---------------------------------------------------------------- conversions by hand
CONV = 'Seminar LFA · conversii'
dfa_in(425, 'Submulțimi: AFN pentru „se termină cu ab”', C2, 'medie',
       'Fie AFN-ul `N = ({0, 1, 2}, {a, b}, Δ, 0, {2})` cu `Δ = {(0, a, 0), (0, b, 0), (0, a, 1), (1, b, 2)}`. Aplică construcția submulțimilor și scrie AFD-ul obținut (cel mult 3 stări accesibile).', 'ab',
       lambda w: w.endswith('ab'), '(a∪b)*ab',
       hint='Pornești din `{0}`. Calculează pentru fiecare mulțime nouă unde duc `a` și `b`.',
       solution='`{0}` --a--> `{0, 1}`, `{0}` --b--> `{0}`; `{0, 1}` --a--> `{0, 1}`, `{0, 1}` --b--> `{0, 2}`; `{0, 2}` --a--> `{0, 1}`, `{0, 2}` --b--> `{0}`. Finală: `{0, 2}`. Trei stări.',
       source=CONV, max_states=3)
topic('lr-conversii')
dfa_in(426, 'Submulțimi cu e-tranziții: a*b*', C2, 'medie',
       'Fie AFN-ul `N = ({0, 1}, {a, b}, Δ, 0, {1})` cu `Δ = {(0, a, 0), (0, e, 1), (1, b, 1)}`. Aplică construcția submulțimilor (cu ε-închideri) și scrie un AFD echivalent (cel mult 3 stări).', 'ab',
       lambda w: 'ba' not in w, 'a*b*',
       hint='Starea inițială a AFD-ului e `E(0) = {0, 1}`.',
       solution='`E(0) = {0, 1}` (inițială, finală) --a--> `{0, 1}`, --b--> `{1}`; `{1}` (finală) --b--> `{1}`, --a--> `∅` (groapa). Trei stări: `L = L(a*b*)`.',
       source=CONV, max_states=3)
topic('lr-conversii')
regex_in(427, 'Eliminarea stărilor: din AFD în ER', C3, 'medie',
         'AFD-ul `M` peste `{a, b}`: `q0` (inițială) --a--> `q1`, `q0` --b--> `q0`, `q1` --a--> `q1`, `q1` --b--> `q2`, `q2` --a--> `q1`, `q2` --b--> `q0`, finală `q2`. Elimină stările și scrie o ER pentru `L(M)`.', 'ab',
         lambda w: w.endswith('ab'), '(a∪b)*ab',
         hint='Adaugă `qs` și `qf`. Ce ține minte fiecare stare din ce s-a citit?',
         solution='`q1` = „ultimul e `a`”, `q2` = „ultimele două sunt `ab`”. Eliminând pe rând (de exemplu `q1`, apoi `q0`, apoi `q2`) se ajunge la o expresie echivalentă cu `(a ∪ b)*ab`.',
         source=CONV)
topic('lr-conversii')
dfa_in(428, 'Minimizare: 6 stări pentru „se termină cu a”', C1, 'medie',
       'AFD-ul `M` peste `{a, b}` cu stările `0`–`5`, inițială `0`, finale `{1, 3, 5}` și `δ`: `0 a→1, 0 b→2, 1 a→3, 1 b→4, 2 a→5, 2 b→0, 3 a→1, 3 b→2, 4 a→3, 4 b→0, 5 a→5, 5 b→4`. Minimizează-l: scrie AFD-ul minimal echivalent (cel mult 2 stări).', 'ab',
       lambda w: w.endswith('a'), '(a∪b)*a',
       hint='Marchează perechile (finală, nefinală), apoi propagă. Câte clase rămân?',
       solution='Toate finalele duc cu `a` într-o finală și cu `b` într-o nefinală; toate nefinalele la fel. Algoritmul de marcare nu mai marchează nimic după primul pas: două clase, `{1, 3, 5}` și `{0, 2, 4}`. `L = L((a ∪ b)*a)`.',
       source=CONV, max_states=2)
topic('lr-conversii')
dfa_in(429, 'Din ER în AFD: (ab ∪ ba)*', C2, 'medie',
       'Construiește un AFD (complet) pentru `L((ab ∪ ba)*)` peste `{a, b}`, cu cel mult 4 stări (pornind, dacă vrei, de la Thompson și construcția submulțimilor).', 'ab',
       lambda w: len(w) % 2 == 0 and all(w[i:i + 2] in ('ab', 'ba') for i in range(0, len(w), 2)), '(ab∪ba)*',
       hint='Starea inițială e și finală; după `a` aștepți `b`, după `b` aștepți `a`.',
       solution='`q0` (inițială, finală) --a--> `q1`, --b--> `q2`; `q1` --b--> `q0`, `q2` --a--> `q0`; restul în groapa `q3`.',
       source=CONV, max_states=4)
topic('lr-conversii')

# ---------------------------------------------------------------- algorithms for context-free languages
ALG2 = 'Seminar LFA · proprietăți algoritmice LIC'
for _id, _t, _st, _right, _wrong, _why in [
    (430, 'w ∈ L(G) pentru o GIC', 'Cum decizi dacă `w ∈ L(G)` pentru o gramatică independentă de context `G`?',
     'aduci `G` în FNC și aplici CYK, în `O(|w|³ · |G|)`', ['simulezi un AFD', 'nu se poate decide', 'încerci toate derivările, oricât de lungi'],
     'În FNC fiecare pas lungește forma sau pune un terminal, deci derivările lui `w` au exact `2|w| − 1` pași: căutarea e finită, iar CYK o face eficient.'),
    (431, 'L(G) = ∅?', 'Cum decizi dacă o GIC generează măcar un cuvânt?',
     'calculezi neterminalii generatori (care derivă un șir de terminale) și verifici dacă `S` e printre ei',
     ['verifici dacă `S` are o regulă', 'încerci toate cuvintele', 'nu se poate decide'],
     'Generatori: întâi cei cu o regulă doar din terminale, apoi cei cu o regulă doar din terminale și generatori; se oprește după cel mult `|V|` runde.'),
    (432, 'L(G) infinit?', 'Cum decizi dacă o GIC (fără simboluri inutile, în FNC) generează un limbaj infinit?',
     'verifici dacă graful „A → B dacă B apare în dreapta unei reguli a lui A” are un ciclu',
     ['verifici dacă există o regulă recursivă `A → …A…`, oricare', 'nu se poate decide', 'numeri regulile'],
     'Un ciclu `A ⇒+ uAv` cu `uv ≠ e` (garantat în FNC) se poate repeta. Simbolurile inutile trebuie scoase întâi: un ciclu printre ele nu contează.'),
    (433, 'Ce NU e decidabil pentru GIC', 'Care întrebare despre gramatici independente de context NU este decidabilă?',
     '`L(G1) = L(G2)`', ['`w ∈ L(G)`', '`L(G) = ∅`', '`L(G)` e finit'],
     'Echivalența, `L(G) = Σ*`, ambiguitatea și `L(G1) ∩ L(G2) = ∅` sunt nedecidabile (reducere din problema corespondenței lui Post). Apartenența, vidul și finitudinea sunt decidabile.'),
    (434, 'E ambiguă gramatica?', 'Este decidabil, în general, dacă o GIC dată este ambiguă?',
     'nu', ['da, cu CYK', 'da, încercând cuvintele de lungime cel mult |V|', 'da, dacă e în FNC'],
     'Ambiguitatea e nedecidabilă. Pentru o gramatică anume o arăți dând un cuvânt cu doi arbori; neambiguitatea se demonstrează de la caz la caz.'),
    (435, 'w ∈ L(M) pentru un APD', 'Fie `M` un automat pushdown. Este decidabil dacă `M` acceptă un cuvânt `w` dat?',
     'da: `M` se transformă într-o GIC, apoi CYK', ['nu, APD-ul poate rula la nesfârșit', 'doar pentru APD deterministe', 'doar dacă stiva e mărginită'],
     'APD și GIC descriu aceleași limbaje, iar construcția APD → GIC e un algoritm. Simularea directă poate cicla (pe `e`-tranziții), de aceea se trece prin gramatică.'),
]:
    _q(_id, _t, C4, 'medie', _st, _right, _wrong, _why, source=ALG2)
    topic('lic-algoritmice')
