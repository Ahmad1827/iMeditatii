# Lessons 7-11 (exec'd by lfa_teorie.py): algorithmic properties, the pumping lemma,
# minimisation, context-free grammars, trees / ambiguity / CNF / CYK.

# =============================================================================
# 7. Algorithmic properties
# =============================================================================
lesson('algoritmice-lr', 'Proprietăți algoritmice ale limbajelor regulate',
       'Ce întrebări despre automate au algoritm: apartenența, limbajul vid, limbajul infinit, egalitatea și incluziunea a două limbaje, „acceptă tot”. Cum le compui ca să răspunzi la întrebările de examen de tipul „cum se poate determina dacă …”.',
       'Curs 4', 25, [
    sec('lista', 'Întrebările decidabile',
        p('Pentru limbaje regulate date prin automate (sau expresii, care se transformă în automate), **toate** întrebările naturale au algoritm. Iată cele de bază, din care se construiesc celelalte:'),
        tab(['întrebarea', 'algoritmul'], [
            ['`w ∈ L(M)`?', 'rulează AFD-ul pe `w`: `|w|` pași'],
            ['`L(M) = ∅`?', 'o parcurgere (BFS/DFS) din `s`: e vid ⇔ nicio stare finală nu e accesibilă'],
            ['`L(M)` e infinit?', 'păstrează doar stările accesibile din `s` **și** din care se ajunge la o stare finală; e infinit ⇔ printre ele există un ciclu. Echivalent: există `w ∈ L` cu `n ≤ |w| < 2n` (`n = |K|`)'],
            ['`L(M) = Σ*`?', 'complementează (AFD complet, inversezi finalele) și testează vid'],
            ['`L(M1) ⊆ L(M2)`?', '`L(M1) ∩ ∁L(M2) = ∅`: produs + test de vid'],
            ['`L(M1) = L(M2)`?', '`L(M1) △ L(M2) = ∅`, sau incluziune în ambele sensuri, sau compari AFD-urile minime'],
        ]),
        note('Toate „rețetele” de examen au aceeași formă: **construiești un automat** pentru un limbaj care e vid exact când răspunsul e da (cu proprietățile de închidere), apoi aplici **testul de vid**. Scrie explicit fiecare construcție și de ce e regulat ce construiești.', 'exam'),
        ),
    sec('examen', 'Probleme de examen',
        exam('Examen 2022 și 18 ianuarie 2025', 'Fie două AFD `M1`, `M2` peste același alfabet. Folosind proprietățile algoritmice, scrieți cum se poate determina dacă există un șir care nu este în niciunul dintre limbajele acceptate de automate.',
             '`∃w ∉ L(M1) ∪ L(M2)` ⇔ `Σ* \\ (L(M1) ∪ L(M2)) ≠ ∅`. Construim `M` = produsul lui `M1` cu `M2` pentru reuniune, apoi `∁M` (inversăm stările finale; produsul e complet). Testăm dacă `L(∁M)` e vid printr-o parcurgere: dacă o stare finală a lui `∁M` e accesibilă, șirul există (și drumul găsit îl dă). Mai direct: căutăm o pereche accesibilă `(p, q)` cu `p ∉ F1` și `q ∉ F2`.'),
        exam('Examen 1 februarie 2025', 'Fie `M1`, `M2` două AFD peste `Σ`. Cum se poate determina dacă `prefix(L(M1)) ⊆ L(M2)`, unde `prefix(L) = {x ∈ Σ* | ∃y ∈ Σ*, xy ∈ L}`?',
             '1. `M1′` pentru `prefix(L(M1))`: aceleași stări și tranziții, dar finală devine orice stare din care se poate ajunge într-o stare finală a lui `M1` (o parcurgere inversă din `F1`). 2. `∁M2` pentru complementul lui `L(M2)`: inversăm finalele. 3. Produsul `M3` pentru `L(M1′) ∩ L(∁M2)`. 4. Test de vid pe `M3`: dacă e vid, `prefix(L(M1)) ⊆ L(M2)`; altfel nu, iar un drum până la o stare finală dă un contraexemplu.'),
        exam('Recapitulare seminarele 1–4, problema 7', 'Cum putem verifica: (a) `L(M)` este finit; (b) `M` acceptă un unic cel mai lung șir nevid?',
             '(a) Eliminăm stările inaccesibile din `s` și pe cele din care nu se ajunge în `F`; `L(M)` e finit ⇔ graful rămas nu are cicluri (DFS cu detecția muchiilor înapoi). (b) Cerem întâi ca `L(M)` să fie finit și nevid. Pe graful fără cicluri al stărilor utile calculăm, prin programare dinamică pe ordinea topologică, lungimea maximă a unui drum din `s` la o stare finală și **numărul** de drumuri de lungime maximă (la un AFD, drumuri diferite înseamnă cuvinte diferite). Răspunsul e da dacă lungimea maximă e cel puțin 1 și există exact un astfel de drum.'),
        quiz('Fie `M1, M2 ∈ AFD`. (1) Există un algoritm pentru a decide dacă `L(M1) ⊂ L(M2)`. (2) Nu există un algoritm pentru a decide dacă `L(M2) = (L(M1)L(M2))*`.', ['Adevărat, Fals', 'Fals, Fals', 'Fals, Adevărat', 'Adevărat, Adevărat'], 0,
             'Pentru limbaje regulate totul e decidabil: `(L(M1)L(M2))*` e regulat (se construiește automatul), iar egalitatea a două limbaje regulate se decide. Grilă de examen, 2021.'),
        ),
], practice=['114', '128'])

# =============================================================================
# 8. Pumping lemma
# =============================================================================
lesson('pompare-lr', 'Limbaje care nu sunt regulate: lema de pompare',
       'De ce un automat finit nu poate număra oricât: principiul cutiei, enunțul lemei, cum se folosește ca un joc cu un adversar, exemplele clasice, metoda proprietăților de închidere, și greșelile care costă puncte la examen.',
       'Curs 5', 40, [
    sec('intuitie', 'Intuiția',
        p('Un AFD cu `p` stări care citește un cuvânt de lungime cel puțin `p` trece prin `p + 1` configurații, deci **repetă o stare** (principiul cutiei). Bucata citită între cele două vizite e un ciclu: o poți repeta de oricâte ori, sau sări peste ea, și automatul ajunge în aceeași stare la sfârșit. Deci cuvintele lungi dintr-un limbaj regulat au o bucată „pompabilă” aproape de început.'),
        ),
    sec('enunt', 'Enunțul',
        thm('Lema de pompare pentru limbaje regulate', 'Dacă `L` e regulat, atunci există `p ≥ 1` astfel încât orice `w ∈ L` cu `|w| ≥ p` se poate scrie `w = xyz` cu:\n- `|xy| ≤ p`;\n- `|y| ≥ 1`;\n- `xyⁱz ∈ L` pentru **orice** `i ≥ 0`.',
            'Fie `M` un AFD cu `p` stări pentru `L` și `w = a1…an ∈ L`, `n ≥ p`. Fie `q0, q1, …, qp` stările după `0, 1, …, p` simboluri. Sunt `p + 1` stări, deci `qj = qk` pentru niște `j < k ≤ p`. Luăm `x = a1…aj`, `y = aj+1…ak`, `z` restul. `|xy| = k ≤ p`, `|y| = k − j ≥ 1`, iar `y` duce din `qj` înapoi în `qj`, deci `xyⁱz` ajunge în aceeași stare finală ca `w`, pentru orice `i`.', label='Lemă'),
        note('Lema e o condiție **necesară**, nu suficientă: există limbaje neregulate care respectă lema. Deci o poți folosi doar ca să demonstrezi că un limbaj **nu** e regulat, niciodată că **este**.', 'warn'),
        ),
    sec('joc', 'Lema ca joc',
        p('Ca să arăți că `L` nu e regulat, negi lema. Negația ei se joacă împotriva unui adversar care încearcă să salveze regularitatea:'),
        steps('Jocul',
              'Adversarul alege `p` (nu știi cât e: lucrezi cu un `p` oarecare).',
              '**Tu** alegi un cuvânt `w ∈ L` cu `|w| ≥ p`, care depinde de `p`.',
              'Adversarul alege **orice** împărțire `w = xyz` cu `|xy| ≤ p`, `|y| ≥ 1`. Tu trebuie să tratezi **toate** împărțirile posibile.',
              '**Tu** alegi un `i ≥ 0` cu `xyⁱz ∉ L`. Dacă reușești pentru orice împărțire, `L` nu e regulat.'),
        viz('pump', 'Joacă jocul', 'Pentru `aⁿbⁿ`, cuvântul `aᵖbᵖ` câștigă: orice `y` e făcut doar din `a` (pentru că `|xy| ≤ p`), deci pomparea strică egalitatea. Încearcă și un cuvânt prost (de exemplu `ab` pentru `p = 1`, sau un cuvânt al cărui `y` poate cădea pe ambele simboluri) și vezi împărțirile care scapă. Ultimul limbaj e regulat: acolo nu vei putea câștiga niciodată.',
            lang='anbn', langs=['anbn', 'eqab', 'pal', 'asq', 'aprime', 'anbmlt', 'astar'], p=3, mode='reg'),
        ),
    sec('exemple', 'Exemplele clasice',
        ex('aⁿbⁿ', 'Arătați că `L = {aⁿbⁿ | n ≥ 0}` nu e regulat.',
           'Presupunem că e regulat și fie `p` constanta. Alegem `w = aᵖbᵖ ∈ L`. Pentru orice `w = xyz` cu `|xy| ≤ p`, `|y| ≥ 1`: `xy` e format doar din `a`, deci `y = aᵏ`, `k ≥ 1`. Atunci `xy⁰z = aᵖ⁻ᵏbᵖ ∉ L`. Contradicție.'),
        ex('Pătratele perfecte', '`L = {a^(n²) | n ≥ 0}` nu e regulat.',
           '`w = a^(p²)`, `y = aᵏ` cu `1 ≤ k ≤ p`. `xy²z` are lungimea `p² + k`, iar `p² < p² + k ≤ p² + p < (p + 1)²`: nu e pătrat perfect.'),
        ex('Palindroamele', '`L = {w ∈ {a, b}* | w = wᴿ}` nu e regulat.',
           '`w = aᵖbaᵖ`. `y` cade în primul bloc de `a`: `xy⁰z = aᵖ⁻ᵏbaᵖ` nu e palindrom.'),
        ex('Set de probleme (examen)', '`L = {w1w2 ∈ {0, 1}⁺ | #1(w1) = 2·#0(w1) și #1(w2) = 2·#0(w2)}` nu e regulat.',
           '`w = 0ᵖ1²ᵖ011` (cu `w1 = 0ᵖ1²ᵖ`, `w2 = 011`). `y = 0ᵏ`, `i = 0`: `0ᵖ⁻ᵏ1²ᵖ011` are cel mult `p − k + 1` zerouri și `2p + 2` unu; o împărțire în `w1w2` cu raportul 2 în ambele părți ar cere `#1 = 2·#0` pe tot cuvântul, adică `2p + 2 = 2(p − k + 1)`, imposibil pentru `k ≥ 1`.'),
        ),
    sec('inchidere', 'Metoda proprietăților de închidere',
        p('Adesea e mai simplu: presupui că `L` e regulat, îl combini cu limbaje regulate prin operații care păstrează regularitatea și obții un limbaj despre care **știi** că nu e regulat. Contradicție.'),
        ex('La fel de mulți a și b', '`L = {w | #a(w) = #b(w)}`.', '`L ∩ a*b* = {aⁿbⁿ}`. Dacă `L` ar fi regulat, intersecția cu `a*b*` ar fi regulată, dar `aⁿbⁿ` nu e.'),
        ex('k = |m − n|', '`L = {aⁿbᵐcᵏ | k = |m − n|}` (examen 9 iunie 2022).', '`L ∩ a*b*` (adică `k = 0`) `= {aⁿbⁿ}`. Deci nu e regulat; e însă LIC (lecția 10).'),
        note('Greșeli frecvente: (1) alegi tu împărțirea `xyz` – nu, o alege adversarul, tu le tratezi pe toate; (2) alegi `p` concret (`p = 3`) – nu, `p` e oarecare; (3) uiți `|xy| ≤ p`, care e exact ce îți spune unde poate fi `y`; (4) dovedești „regulat” cu lema. (5) Un limbaj **finit** e mereu regulat: lema e respectată trivial, pentru că `p` poate fi ales mai mare decât cel mai lung cuvânt.', 'warn'),
        quiz('Fie `L` limbaj infinit astfel încât pentru fiecare `w ∈ L` există un AFD care îl acceptă doar pe `w`. Atunci:', ['`L` e regulat', '`L` e LIC', 'nu se poate spune nimic', '`L` e finit'], 2,
             'Orice cuvânt are un AFD care îl acceptă doar pe el, deci condiția e adevărată pentru orice limbaj. Model de test grilă.'),
        ),
], practice=['33', '34', '35', '36', '37', '42', '122', '124', '127', '147'])

# =============================================================================
# 9. Minimisation
# =============================================================================
lesson('minimizare', 'Minimizarea automatelor finite deterministe',
       'Stări care nu se pot deosebi prin niciun cuvânt, algoritmul de marcare a perechilor (rundă cu rundă), unirea claselor, unicitatea AFD-ului minim și teorema Myhill–Nerode, care dă și o a doua metodă de a arăta că un limbaj nu e regulat.',
       'Curs 5', 30, [
    sec('echivalenta', 'Stări echivalente',
        d('Echivalență', 'Două stări `p`, `q` ale unui AFD sunt **echivalente** (`p ≡ q`) dacă pentru orice cuvânt `w`, `δ*(p, w) ∈ F ⇔ δ*(q, w) ∈ F`. Dacă un cuvânt le deosebește, ele sunt **distinse**, iar cel mai scurt astfel de cuvânt e **martorul**.'),
        p('Stările echivalente se pot uni fără să schimbe limbajul. Stările **inaccesibile** din starea inițială se pot șterge. Ce rămâne e AFD-ul minim.'),
        ),
    sec('algoritm', 'Algoritmul de marcare',
        steps('Pașii',
              'Șterge stările inaccesibile; completează automatul cu o groapă, dacă lipsesc tranziții.',
              'Desenează tabelul tuturor perechilor `{p, q}` de stări.',
              '**Runda 0:** marchează perechile cu o stare finală și una nefinală (le deosebește cuvântul `e`).',
              '**Runda k:** marchează `{p, q}` dacă există un simbol `a` cu `{δ(p, a), δ(q, a)}` deja marcată (martorul e `a` urmat de martorul acelei perechi).',
              'Repetă până când o rundă nu mai marchează nimic. Perechile rămase nemarcate sunt stări echivalente: unește-le în clase.'),
        viz('minimize', 'Minimizare, rundă cu rundă',
            'Un AFD cu 6 stări pentru „se termină cu `a`”. Căsuța arată runda în care s-a marcat perechea și simbolul care a deosebit-o. La final, perechile `≡` se unesc.',
            alphabet='ab', a=MIN6, pos=[[0, 0.8], [1.6, 0], [1.6, 1.6], [3.2, 0], [3.2, 1.6], [4.8, 0.8]]),
        viz('minimize', 'Cu o stare inaccesibilă', '`#b` par, scris cu stări care țin minte și paritatea lui `#a` (inutil), plus o stare `q4` la care nu se ajunge.',
            alphabet='ab', a=MIN_U, pos=[[0, 0], [1.8, 0], [0, 1.6], [1.8, 1.6], [3.4, 0.8]]),
        ),
    sec('myhill', 'Teorema Myhill–Nerode',
        d('Relația lui L', 'Pentru un limbaj `L`, cuvintele `x`, `y` sunt **indistinctibile** (`x ≡_L y`) dacă pentru orice `z`, `xz ∈ L ⇔ yz ∈ L`.'),
        thm('Myhill–Nerode', '`L` e regulat ⇔ `≡_L` are un număr finit de clase. Numărul claselor este numărul de stări al AFD-ului minim (complet), care e **unic** până la redenumirea stărilor.',
            '(⇒) Cuvintele care duc în aceeași stare a unui AFD sunt indistinctibile, deci clasele sunt cel mult câte stări. (⇐) Clasele însele formează un AFD: `δ([x], a) = [xa]` e bine definită (dacă `x ≡_L y`, atunci `xa ≡_L ya`), starea inițială `[e]`, finale clasele cuvintelor din `L`. Orice AFD pentru `L` are cel puțin atâtea stări câte clase, deci acesta e minim; iar algoritmul de marcare calculează exact aceste clase.'),
        ex('Al treilea simbol de la sfârșit', 'De ce orice AFD pentru „al treilea simbol de la sfârșit e `a`” are cel puțin 8 stări?',
           'Cele 8 cuvinte de lungime 3 sunt distincte două câte două: dacă `x` și `y` diferă pe poziția `i` (din 3), atunci `z = b^(i−1)` le deosebește (pune poziția `i` pe locul trei de la coadă). 8 clase ⇒ cel puțin 8 stări. Un AFN are nevoie doar de 4.'),
        ex('aⁿbⁿ, prin Myhill–Nerode', 'Arătați că `{aⁿbⁿ}` nu e regulat.',
           'Cuvintele `aⁱ` și `aʲ` (`i ≠ j`) sunt distinse de `z = bⁱ`: `aⁱbⁱ ∈ L`, `aʲbⁱ ∉ L`. Deci `≡_L` are o infinitate de clase.'),
        ),
], practice=['5', '7', '42', '55'])

# =============================================================================
# 10. Context-free grammars
# =============================================================================
G_ANBN = 'S -> aSb | ε'
G_PAL = 'S -> aSa | bSb | a | b | ε'
G_EX25 = 'S -> aS | Sb | ab'
G_ABSC = 'S -> abSc | A\nA -> cAd | cd'
G_SEPT = 'S -> 0S2 | 00S2 | 01T2 | T\nT -> 1T2 | 11T2 | T2 | ε'
lesson('gic', 'Gramatici independente de context',
       'Cum generează o gramatică un limbaj: definiția, derivări, limbajul generat. Tehnici de construcție pentru limbajele de examen (perechi imbricate, reuniuni, concatenări, inegalități, „de două ori mai mulți”), demonstrarea corectitudinii, gramaticile regulate și ierarhia Chomsky.',
       'Curs 6, 10', 40, [
    sec('definitie', 'Definiția',
        d('GIC', 'O **gramatică independentă de context** este `G = (V, Σ, R, S)`:\n- `V` – alfabetul total (neterminale și terminale), `Σ ⊆ V` – terminalele;\n- `R ⊆ (V \\ Σ) × V*` – regulile `A → α`, finite;\n- `S ∈ V \\ Σ` – simbolul de start.\n\nO **derivare într-un pas**: `uAv ⇒ uαv` dacă `A → α ∈ R`. `⇒*` – zero sau mai mulți pași. `L(G) = {w ∈ Σ* | S ⇒* w}`.'),
        p('„Independent de context” înseamnă că `A` se rescrie la fel oriunde ar apărea, indiferent de ce e în jurul lui. Un limbaj e **independent de context** (LIC) dacă e generat de o GIC.'),
        viz('derive', 'O derivare, pas cu pas, cu arborele ei', 'Fiecare pas rescrie neterminalul cel mai din stânga (derivare stânga). Arborele crește cu el.', grammar=G_ANBN, words=['aabb', 'ab', '']),
        ),
    sec('tehnici', 'Tehnici de construcție (cursul 10)',
        tab(['limbaj', 'gramatica', 'ideea'], [
            ['`a*`', '`A → aA | e`', 'un simbol la fiecare pas'],
            ['`aⁿbⁿ`', '`X → aXb | e`', 'perechile se adaugă din exterior spre interior'],
            ['`aⁿb³ⁿ`', '`Y → aYbbb | e`', 'fiecare `a` aduce trei `b`'],
            ['`aⁿbᵐ`, `n < m`', '`S → AB`, `A → aAb | e`, `B → bB | b`', '`aⁿbⁿ` urmat de cel puțin un `b`'],
            ['`aⁿbᵐ`, `n ≠ m`', '`S → aSb | A | B`, `A → aA | a`, `B → bB | b`', 'potrivește, apoi „în plus” pe o singură parte'],
            ['`L1 ∪ L2`', '`S → S1 | S2`', 'reuniune'],
            ['`L1L2`', '`S → S1S2`', 'concatenare'],
            ['`L*`', '`S → S1S | e`', 'stea'],
            ['palindroame', '`S → aSa | bSb | a | b | e`', 'capetele egale'],
            ['`#a = #b`', '`S → aSbS | bSaS | e`', 'primul simbol își are perechea undeva'],
            ['paranteze', '`S → (S)S | e`', 'prima paranteză se închide undeva'],
        ]),
        ex('Examen 6 septembrie 2022', 'Fie `L = {0ⁱ1ʲ2ᵏ | i + j ≤ 2k}`. Scrieți gramatica și arborii de derivare pentru `000022` și `00122`.',
           'Fiecare `2` din dreapta „plătește” între 0 și 2 simboluri din stânga. `S` produce zerourile, `T` unu-urile: `S → 0S2 | 00S2 | 01T2 | T`, `T → 1T2 | 11T2 | T2 | e`. `000022`: `S ⇒ 00S2 ⇒ 0000S22 ⇒ 0000T22 ⇒ 000022`.'),
        viz('derive', 'Arborii de la examen', '', grammar=G_SEPT, words=['000022', '00122']),
        ex('Examen 15 iunie 2022', 'Construiți o GIC pentru cuvintele peste `{0, 1}` cu de două ori mai mulți `0` decât `1`.',
           'Un `1` vine cu doi `0`, în ordinea `001`, `010` sau `100`, cu alte cuvinte din limbaj intercalate: `S → SS | 0S0S1 | 0S1S0 | 1S0S0 | e`.'),
        ex('Examen 2025', '`S → abSc | A`, `A → cAd | cd`. O derivare stânga pentru `ababccddcc` și limbajul generat.',
           '`S ⇒ abSc ⇒ ababScc ⇒ ababAcc ⇒ ababcAdcc ⇒ ababccddcc`. `L(G) = {(ab)ⁿcᵐdᵐcⁿ | n ≥ 0, m ≥ 1}`.'),
        viz('derive', 'Derivarea de la examenul din 2025', '', grammar=G_ABSC, words=['ababccddcc', 'abcdc']),
        ),
    sec('corectitudine', 'Demonstrarea corectitudinii',
        p('Ca să arăți că `L(G) = L`, demonstrezi două incluziuni:'),
        steps('Cele două direcții',
              '`L(G) ⊆ L`: prin **inducție pe lungimea derivării** arăți că orice formă propozițională derivată din `S` are o proprietate (de exemplu „are forma `aⁿSbⁿ` sau `aⁿbⁿ`”).',
              '`L ⊆ L(G)`: prin **inducție pe lungimea cuvântului** arăți că orice `w ∈ L` se poate deriva: descompui `w` după prima regulă care l-ar produce și aplici ipoteza de inducție pe bucăți mai scurte.'),
        ex('S → aSbS | bSaS | e generează exact #a = #b', 'Schița demonstrației.',
           '(⊆) Fiecare regulă adaugă câte un `a` și un `b`, deci orice cuvânt derivat are `#a = #b`. (⊇) Fie `w ≠ e` cu `#a = #b`, să zicem că începe cu `a`. Fie `f(i) = #a − #b` pe prefixul de lungime `i`: `f(1) = 1`, `f(|w|) = 0`, și `f` se schimbă cu 1 la fiecare pas, deci există un prim `i` cu `f(i) = 0`, iar acolo e un `b`. Atunci `w = a u b v` cu `u` și `v` echilibrate (mai scurte), derivabile din `S` prin ipoteza de inducție: `S ⇒ aSbS ⇒* aubv`.'),
        ),
    sec('chomsky', 'Gramatici regulate și ierarhia Chomsky',
        d('Gramatică regulată', 'Toate regulile au forma `A → wB` sau `A → w`, cu `w ∈ Σ*` (un singur neterminal, la dreapta).'),
        thm('Gramaticile regulate generează exact limbajele regulate', 'Un limbaj e regulat ⇔ e generat de o gramatică regulată.',
            '(⇐) Construim un AFN cu stările = neterminalele plus o stare finală `f`: `(A, w, B) ∈ Δ` pentru `A → wB`, `(A, w, f)` pentru `A → w`. O derivare `S ⇒ w1A1 ⇒ w1w2A2 ⇒ …` e exact un calcul al automatului. (⇒) Pentru un AFN, neterminalele sunt stările: `q → ap` pentru `(q, a, p) ∈ Δ` și `q → e` pentru `q ∈ F`.'),
        viz('hierarchy', 'Ierarhia Chomsky', 'Atinge o clasă: ce o descrie, ce o recunoaște, exemple tipice și la ce e închisă.'),
        quiz('Fie `G`: `S → SS | aS | bS`. Este limbajul regulat? Dar gramatica?', ['Nu, Nu', 'Da, Da', 'Da, Nu', 'Nu, Da'], 2,
             'Nicio regulă nu scapă de `S`: `L(G) = ∅`, regulat. Gramatica nu e regulată (`S → SS` are doi neterminali). Test 2, 2023.'),
        ),
], practice=ids('5.', kind='lfa', limit=20))

# =============================================================================
# 11. Trees, ambiguity, CNF, CYK
# =============================================================================
G_AMB = 'S -> AS | S1 | 0S1 | ε\nA -> 0A | 0'
G_ARITH = 'E -> E+E | E*E | (E) | a'
G_CNF1 = 'S -> ASA | aB\nA -> B | S\nB -> b | ε'
G_CNF_EX = 'S -> aAA\nA -> aS | bS | a'
G_CYK = 'S -> AB | BC\nA -> BA | a\nB -> CC | b\nC -> AB | a'
lesson('arbori-fnc', 'Arbori de derivare, ambiguitate, forma normală Chomsky',
       'Arborele unei derivări și derivările stânga, gramatici ambigue și cum se arată ambiguitatea, eliminarea ei, forma normală Chomsky construită pas cu pas și algoritmul CYK, care decide apartenența în timp cubic.',
       'Curs 8', 40, [
    sec('arbori', 'Arbori de derivare',
        d('Arbore de derivare', 'Rădăcina e `S`; fiecare nod interior e un neterminal `A` ai cărui fii, de la stânga la dreapta, sunt simbolurile unei reguli `A → X1…Xk` (sau o frunză `e` pentru `A → e`); frunzele, citite de la stânga la dreapta, formează cuvântul (**frontiera**).'),
        p('Un arbore corespunde mai multor derivări (ordinea în care rescrii neterminalele), dar exact **unei derivări stânga** (rescrii mereu cel mai din stânga neterminal) și unei derivări dreapta.'),
        ),
    sec('ambiguitate', 'Ambiguitate',
        d('Gramatică ambiguă', 'O gramatică e **ambiguă** dacă un cuvânt are **două arbori de derivare diferiți** (echivalent: două derivări stânga diferite). Un limbaj e **inerent ambiguu** dacă orice gramatică a lui e ambiguă (de exemplu `{aⁱbʲcᵏ | i = j sau j = k}`).'),
        viz('derive', 'Examen 18 ianuarie 2025: două derivări stânga pentru aabb', '`S → aS | Sb | ab`. Comută între cei doi arbori.', grammar=G_EX25, words=['aabb', 'aab']),
        viz('derive', 'Set de probleme: gramatica ambiguă', 'Arătați că `S → AS | S1 | 0S1 | e`, `A → 0A | 0` e ambiguă: `S ⇒ AS ⇒ 0S ⇒ 0S1 ⇒ 01` și `S ⇒ 0S1 ⇒ 01`.', grammar=G_AMB, words=['01', '001']),
        viz('derive', 'Ambiguitatea clasică: expresii aritmetice', '`a+a*a` are doi arbori: unul face întâi adunarea, celălalt înmulțirea.', grammar=G_ARITH, words=['a+a*a', 'a+a+a']),
        p('O gramatică ambiguă se poate adesea rescrie neambiguu, separând „rolurile” simbolurilor: pentru expresii, câte un neterminal pe nivel de prioritate (`E → E+T | T`, `T → T*F | F`, `F → (E) | a`); pentru `(01)ⁿ(10)ᵐ, n ≥ m > 0`, întâi `01`-urile în plus, apoi perechile potrivite.'),
        ),
    sec('fnc', 'Forma normală Chomsky',
        d('FNC', 'O gramatică e în **forma normală Chomsky** dacă toate regulile sunt `A → BC` (`B`, `C` neterminale, diferite de start) sau `A → a` (`a` terminal); în plus, e permisă `S → e` dacă `e ∈ L`.'),
        thm('Orice LIC are o gramatică în FNC', 'Pentru orice GIC `G` există o gramatică `G′` în FNC cu `L(G′) = L(G)`.',
            'Se aplică, în ordine, transformări care păstrează limbajul: (1) simbol de start nou; (2) eliminarea regulilor `A → e`: pentru fiecare regulă, adaugi variantele fără neterminalele care pot genera `e`; (3) eliminarea redenumirilor `A → B`: `A` primește direct regulile lui `B`; (4) eliminarea simbolurilor inutile; (5) terminalele din regulile lungi primesc neterminale proprii (`Ta → a`); (6) regulile cu `k ≥ 3` simboluri se taie într-un lanț de reguli cu două.'),
        viz('cnf', 'FNC pas cu pas', 'Exemplul clasic (Sipser). Liniile noi după fiecare pas sunt colorate. Scrie orice gramatică ca s-o transformi.', grammar=G_CNF1),
        exam('Examen LFA · set de probleme', 'Scrieți o gramatică în FNC pentru `{aⁿbⁿ | n ≥ 1}`.', '`S → ZA | ZU`, `A → SU`, `Z → a`, `U → b` (soluția din set scrie `S → ZA`, `A → SU | 1` cu `1` în loc de `b`). Pornești de la `S → aSb | ab`, înlocuiești terminalele și tai regula lungă `S → ZSU` în `S → ZA`, `A → SU`.'),
        ),
    sec('cyk', 'Algoritmul CYK',
        p('Pentru o gramatică în FNC și un cuvânt `w = w1…wn`, CYK completează un tabel triunghiular: căsuța `X[i, j]` conține neterminalele care generează `wi…wj`. Rândul de jos: `A` cu `A → wi`. O căsuță mai sus: pentru fiecare tăietură `wi…wk | wk+1…wj`, adaugi `A` dacă `A → BC` cu `B ∈ X[i, k]` și `C ∈ X[k + 1, j]`. `w ∈ L(G)` ⇔ `S ∈ X[1, n]`. Timpul: `O(n³ · |R|)`.'),
        viz('cyk', 'CYK, căsuță cu căsuță', 'Exemplul din manuale (`baaba`). Căsuțele galbene sunt perechile care se combină pentru căsuța curentă.', grammar=G_CYK, word='baaba'),
        ),
], practice=['25', '134', '135', '136', '144', '145', '174', '189'])
