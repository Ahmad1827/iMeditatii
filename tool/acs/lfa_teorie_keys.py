# The short layer of the LFA theory: what each lesson teaches (goals) and
# the takeaway of each section (key), shown first so a student sees what
# matters before the details. Exec'd by lfa_teorie.py after the lessons.

GOALS = {
    'limbaje': [
        'Folosești corect alfabet, cuvânt, limbaj, cuvântul vid e și limbajul vid ∅.',
        'Faci operațiile pe cuvinte (concatenare, putere, oglindire) și pe limbaje (∪, ∩, concatenare, stea Kleene).',
        'Știi de ce există limbaje pe care niciun program nu le poate recunoaște (numărare).',
    ],
    'expresii-regulate': [
        'Scrii o expresie regulată pentru un limbaj descris în cuvinte.',
        'Simplifici expresii cu identitățile de bază și lema lui Arden.',
        'Recunoști tiparele: „conține”, „se termină cu”, „număr par de”, „fără subcuvântul”.',
    ],
    'afd': [
        'Citești și scrii un AFD ca 5-uplu M = (K, Σ, δ, s, F).',
        'Urmărești un calcul prin configurații (q, w) ⊢ (p, w′).',
        'Construiești un AFD pornind de la „ce trebuie să țin minte?”.',
    ],
    'afn': [
        'Știi ce aduce în plus un AFN: mai multe alegeri, tranziții pe e, tranziții lipsă.',
        'Calculezi ε-închiderea E(q).',
        'Transformi orice AFN în AFD prin construcția submulțimilor și știi de ce poate exploda (2ⁿ stări).',
    ],
    'inchidere-lr': [
        'Știi pe de rost ce operații păstrează limbajele regulate (toate cele uzuale).',
        'Construiești automatul produs pentru ∩, ∪, \\, △.',
        'Demonstrezi că un limbaj e regulat compunând limbaje regulate cunoscute.',
    ],
    'af-er': [
        'Știi teorema lui Kleene: AF și ER descriu exact aceleași limbaje.',
        'ER → AFN prin construcția lui Thompson.',
        'AF → ER prin eliminarea stărilor (formula R_in (R_loop)* R_out).',
    ],
    'algoritmice-lr': [
        'Știi ce întrebări despre limbaje regulate sunt decidabile: apartenență, vid, finit, echivalență, incluziune.',
        'Pentru fiecare, spui algoritmul și de ce se oprește mereu.',
    ],
    'pompare-lr': [
        'Enunți corect lema de pompare (cu ordinea cuantificatorilor).',
        'Demonstrezi că un limbaj nu e regulat: alegi cuvântul, tratezi toate împărțirile, găsești i.',
        'Folosești proprietățile de închidere ca scurtătură.',
    ],
    'minimizare': [
        'Știi când două stări sunt echivalente (nu se pot deosebi prin niciun cuvânt).',
        'Minimizezi un AFD prin algoritmul de marcare a perechilor.',
        'Folosești Myhill–Nerode: numărul de clase = numărul de stări ale AFD-ului minimal.',
    ],
    'gic': [
        'Scrii o GIC G = (V, Σ, R, S) pentru un limbaj dat.',
        'Faci derivări (stânga, dreapta) și desenezi arborele.',
        'Demonstrezi că o gramatică generează exact limbajul cerut (ambele incluziuni).',
        'Știi unde stau gramaticile regulate în ierarhia Chomsky.',
    ],
    'arbori-fnc': [
        'Arăți că o gramatică e ambiguă găsind două arbori pentru același cuvânt.',
        'Aduci o gramatică în forma normală Chomsky, pas cu pas.',
        'Rulezi CYK ca să decizi dacă un cuvânt e generat.',
    ],
    'apd': [
        'Citești și scrii un automat cu stivă (tranziții (p, a, β) → (q, γ)).',
        'Construiești APD pentru limbajele clasice (aⁿbⁿ, wcwᴿ, #a = #b).',
        'Transformi o GIC în APD prin construcția din curs.',
    ],
    'proprietati-lic': [
        'Știi la ce operații sunt închise LIC (∪, ·, *) și la ce nu (∩, complement).',
        'Folosești lema de pompare pentru LIC (uvxyz).',
        'Știi ce e decidabil pentru LIC și ce nu.',
    ],
    'turing': [
        'Citești și scrii o mașină Turing în notația cursului.',
        'Urmărești un calcul pe bandă, configurație cu configurație.',
        'Construiești MT care acceptă un limbaj sau calculează o funcție.',
    ],
    'calculabilitate': [
        'Deosebești limbajele Turing decidabile (TD) de cele Turing acceptate (TA).',
        'Știi de ce problema opririi e nedecidabilă și ce spune teorema lui Rice.',
        'Răspunzi metodic la „ce fel de limbaj este …?”.',
    ],
    'recapitulare': [
        'Ai toate proprietățile de închidere și decidabilitate într-un singur loc.',
        'Știi schema fiecărui tip de demonstrație cerut la examen.',
        'Eviți capcanele clasice din grile.',
    ],
}

KEYS = {
    ('limbaje', 'de-ce'): [
        'Cursul întreabă: ce limbaje poate recunoaște fiecare tip de mașină?',
        'Trei nivele: regulate (AF), independente de context (APD), Turing (MT).',
    ],
    ('limbaje', 'cuvinte'): [
        'Un cuvânt e un șir finit de simboluri din Σ; e (sau ε) e cuvântul vid, |e| = 0.',
        'Prefix, sufix, subcuvânt: bucăți de la început, de la sfârșit, din mijloc.',
    ],
    ('limbaje', 'limbaje'): [
        'Un limbaj e o mulțime de cuvinte: ∅ (niciun cuvânt) ≠ {e} (doar cuvântul vid).',
        'L* conține mereu e; L⁺ = LL*.',
    ],
    ('limbaje', 'numarare'): [
        'Σ* e numărabilă, dar mulțimea limbajelor peste Σ nu e.',
        'Programele sunt numărabile, deci unele limbaje nu au niciun program.',
    ],
    ('expresii-regulate', 'definitie'): [
        'Bazele: ∅, e, a; operațiile: reuniune, concatenare, stea.',
        'Prioritate: * înaintea concatenării, concatenarea înaintea reuniunii.',
    ],
    ('expresii-regulate', 'identitati'): [
        '(a*)* = a*, (a ∪ b)* = (a*b*)*, ∅* = e.',
        'Arden: X = AX ∪ B are soluția X = A*B (dacă e ∉ A).',
    ],
    ('expresii-regulate', 'tehnici'): [
        'Descompune limbajul în bucăți (început, mijloc, sfârșit) și leagă-le.',
        'Verifică mereu pe cuvinte mici: e, a, b, aa, ab...',
    ],
    ('afd', 'definitie'): [
        'AFD: o singură tranziție pentru fiecare stare și simbol (δ e funcție totală).',
        'Acceptă dacă, după tot cuvântul, ajunge într-o stare finală.',
    ],
    ('afd', 'exemplu'): [
        'Un calcul e un șir de configurații (q, w) ⊢ (p, w′), un simbol pe pas.',
    ],
    ('afd', 'constructie'): [
        'Fiecare stare = ce trebuie ținut minte din ce s-a citit până acum.',
        'Nu uita starea capcană și cazul e.',
    ],
    ('afd', 'verifica'): [
        'Testează-ți automatul pe cuvintele cele mai scurte, inclusiv e.',
    ],
    ('afn', 'definitie'): [
        'AFN: Δ e o relație: zero, una sau mai multe tranziții, chiar pe e sau pe șiruri.',
        'Acceptă dacă măcar o ramură ajunge în stare finală cu tot cuvântul citit.',
    ],
    ('afn', 'inchidere'): [
        'E(q) = stările accesibile din q doar pe tranziții e, inclusiv q.',
    ],
    ('afn', 'submultimi'): [
        'Starea AFD = mulțimea stărilor AFN în care poți fi; pornești din E(s).',
        'O stare-mulțime e finală dacă conține o stare finală.',
        'Poate ieși până la 2ⁿ stări, dar construiești doar ce e accesibil.',
    ],
    ('afn', 'verifica'): [
        'AFN și AFD recunosc aceleași limbaje: nedeterminismul nu adaugă putere.',
    ],
    ('inchidere-lr', 'constructii'): [
        'Reuniune, concatenare, stea: se leagă automatele cu tranziții e.',
    ],
    ('inchidere-lr', 'produs'): [
        'Produsul: stări (p, q), ambele automate citesc simultan.',
        'Doar mulțimea stărilor finale se schimbă între ∩, ∪, \\, △.',
        'Automatele trebuie să fie AFD complete.',
    ],
    ('inchidere-lr', 'altele'): [
        'Și oglindirea, prefixele, sufixele, câtul păstrează regularitatea.',
    ],
    ('inchidere-lr', 'folosire'): [
        'Ca să arăți că L e regulat: scrie-l din limbaje regulate și operații închise.',
        'Atenție: o operație închisă nu dovedește că operanzii erau regulați.',
    ],
    ('af-er', 'kleene'): [
        'Kleene: un limbaj e regulat ⇔ e acceptat de un AF ⇔ e descris de o ER.',
    ],
    ('af-er', 'thompson'): [
        'Fiecare bucată a expresiei devine un mic AFN; se lipesc cu tranziții e.',
        'Steaua: buclă înapoi și un ocol peste, ca să poți citi și e.',
    ],
    ('af-er', 'eliminare'): [
        'Adaugi o stare inițială nouă și o finală nouă, apoi elimini pe rând celelalte stări.',
        'Pentru fiecare pereche (intrare, ieșire): R_in (R_loop)* R_out, reunit cu ce exista.',
        'Ordinea contează doar pentru lungimea expresiei, nu pentru limbaj.',
    ],
    ('af-er', 'verifica'): [
        'Expresia de la final descrie exact limbajul automatului, oricare ar fi ordinea.',
    ],
    ('algoritmice-lr', 'lista'): [
        'Pentru limbaje regulate, aproape orice întrebare e decidabilă.',
        'Vid: există drum spre o stare finală? Finit: există ciclu pe un astfel de drum?',
        'Echivalență: (L₁ \\ L₂) ∪ (L₂ \\ L₁) = ∅, sau compari AFD-urile minimale.',
    ],
    ('algoritmice-lr', 'examen'): [
        'La examen: numești algoritmul, construcția pe care o folosește și de ce se termină.',
    ],
    ('pompare-lr', 'intuitie'): [
        'Un AFD cu p stări care citește un cuvânt de lungime ≥ p trece de două ori prin aceeași stare.',
        'Bucla dintre cele două treceri se poate repeta oricât.',
    ],
    ('pompare-lr', 'enunt'): [
        'Dacă L e regulat: ∃p, ∀w ∈ L cu |w| ≥ p, ∃w = xyz cu |xy| ≤ p, |y| ≥ 1, ∀i ≥ 0: xyⁱz ∈ L.',
        'Lema e o condiție necesară: o folosești doar ca să arăți că L NU e regulat.',
    ],
    ('pompare-lr', 'joc'): [
        'Adversarul alege p și împărțirea; tu alegi w și i.',
        'Câștigi dacă pentru orice împărțire găsești un i care scoate cuvântul din L.',
    ],
    ('pompare-lr', 'exemple'): [
        'Alege w așa încât |xy| ≤ p să forțeze y în prima zonă (de obicei y = aᵏ).',
        'Clasice: aⁿbⁿ, palindroame, #a = #b, aⁿ², a^prim.',
    ],
    ('pompare-lr', 'inchidere'): [
        'Scurtătură: dacă L ∩ R (R regulat) nu e regulat, nici L nu e.',
    ],
    ('minimizare', 'echivalenta'): [
        'p ≡ q dacă pentru orice w: din p și din q, w e acceptat în ambele sau în niciuna.',
    ],
    ('minimizare', 'algoritm'): [
        'Elimini stările inaccesibile, marchezi perechile (finală, nefinală).',
        'Marchezi (p, q) dacă un simbol le duce într-o pereche marcată; repeți până nu se mai schimbă.',
        'Perechile nemarcate se unesc.',
    ],
    ('minimizare', 'myhill'): [
        'L e regulat ⇔ relația ≡_L are un număr finit de clase.',
        'Numărul de clase = numărul de stări ale AFD-ului minimal (complet).',
    ],
    ('gic', 'definitie'): [
        'Reguli A → α: un neterminal înlocuit cu orice șir, oriunde apare.',
        'L(G) = cuvintele doar din terminale derivate din S.',
    ],
    ('gic', 'tehnici'): [
        'Potrivire: S → aSb leagă simboluri pereche; reuniune: S → S₁ | S₂; concatenare: S → S₁S₂.',
    ],
    ('gic', 'corectitudine'): [
        'Două direcții: tot ce generează G e în L (inducție pe derivare) și tot din L se generează (inducție pe lungime).',
    ],
    ('gic', 'chomsky'): [
        'Gramatică regulată: A → wB sau A → w; generează exact limbajele regulate.',
        'Ierarhia: regulate ⊂ LIC ⊂ decidabile ⊂ Turing acceptate.',
    ],
    ('arbori-fnc', 'arbori'): [
        'Un arbore = toate derivările care diferă doar prin ordinea pașilor.',
        'Un arbore ↔ o singură derivare stânga.',
    ],
    ('arbori-fnc', 'ambiguitate'): [
        'Ambiguă: un cuvânt are doi arbori diferiți (sau două derivări stânga).',
        'Ca s-o demonstrezi: un singur cuvânt cu două derivări ajunge.',
    ],
    ('arbori-fnc', 'fnc'): [
        'FNC: doar A → BC și A → a (plus S → e dacă e ∈ L).',
        'Ordinea pașilor: start nou, elimini e-reguli, reguli unitare, apoi spargi corpurile lungi.',
    ],
    ('arbori-fnc', 'cyk'): [
        'Tabelul: căsuța (i, j) = neterminalii care generează bucata w_i..w_j.',
        'w ∈ L ⇔ S e în căsuța care acoperă tot cuvântul. Complexitate O(n³).',
    ],
    ('apd', 'definitie'): [
        'Tranziție (p, a, β) → (q, γ): citește a, scoate β din vârf, pune γ.',
        'În curs: acceptă cu tot cuvântul citit, stare finală ȘI stivă goală.',
    ],
    ('apd', 'exemple'): [
        'Stiva numără sau ține minte prima jumătate; a doua jumătate o golește.',
    ],
    ('apd', 'gic-apd'): [
        'GIC → APD: pui S pe stivă, înlocuiești neterminalul din vârf cu un corp, potrivești terminalii cu intrarea.',
    ],
    ('apd', 'determinism'): [
        'APD nedeterministe sunt mai puternice decât cele deterministe (ex.: wwᴿ).',
    ],
    ('proprietati-lic', 'inchidere'): [
        'LIC: închise la ∪, ·, *, intersecție cu un regulat.',
        'NU sunt închise la ∩ și complement.',
    ],
    ('proprietati-lic', 'pompare'): [
        'w = uvxyz cu |vxy| ≤ p, |vy| ≥ 1, uvⁱxyⁱz ∈ L pentru orice i.',
        'Clasic ne-LIC: aⁿbⁿcⁿ, ww.',
    ],
    ('proprietati-lic', 'algoritmice'): [
        'Decidabile: apartenența (CYK), vidul, finitudinea.',
        'Nedecidabile: echivalența, ambiguitatea, L = Σ*.',
    ],
    ('proprietati-lic', 'verifica'): [
        'Testează-te pe ce e închis și ce e decidabil: sunt întrebări sigure la grile.',
    ],
    ('turing', 'definitie'): [
        'M = (K, Σ, δ, s, H): la fiecare pas citește simbolul de sub cap, apoi fie scrie, fie mută capul.',
        'Acceptoare: se oprește în y (acceptă) sau n (respinge), ori nu se oprește deloc.',
    ],
    ('turing', 'exemple'): [
        'Tehnica clasică: marchezi simbolurile deja potrivite și te întorci.',
    ],
    ('turing', 'compunere'): [
        'MT se compun ca blocuri (mașini mici legate prin săgeți).',
        'Benzi multiple și nedeterminismul nu adaugă putere.',
    ],
    ('calculabilitate', 'clase'): [
        'TD: o MT care se oprește pe orice intrare, în y sau n. TA: o MT care se oprește exact pe cuvintele din L.',
        'L e TD ⇔ L și complementul lui sunt TA.',
    ],
    ('calculabilitate', 'oprire'): [
        'Problema opririi e TA, dar nu TD; complementul ei nu e nici măcar TA.',
        'Rice: orice proprietate netrivială a limbajului unei MT e nedecidabilă.',
    ],
    ('calculabilitate', 'examen'): [
        'Folosește rezolvările ca șablon: întâi clasificarea, apoi argumentul.',
    ],
    ('calculabilitate', 'metoda'): [
        'Întreabă în ordine: e regulat? e LIC? e TD? e TA? și justifică fiecare răspuns.',
    ],
    ('recapitulare', 'tabele'): [
        'Închidere și decidabilitate pentru fiecare clasă, într-un singur tabel.',
    ],
    ('recapitulare', 'demonstratii'): [
        'Schema fiecărui tip de demonstrație cerut la examen.',
    ],
    ('recapitulare', 'capcane'): [
        'Capcanele care pică des la grile.',
    ],
}

# the seminar's tests (LR, LIC, MT), shown on each part
TESTS = {
    'Partea I · Limbaje regulate': 'Testul 1 (LR)',
    'Partea II · Limbaje independente de context': 'Testul 2 (LIC)',
    'Partea III · Mașini Turing și calculabilitate': 'Testul 3 (MT)',
}

for l in LESSONS:
    if l['id'] in GOALS:
        l['goals'] = GOALS[l['id']]
    for s_ in l['sections']:
        k = KEYS.get((l['id'], s_['id']))
        if k:
            s_['key'] = k
missing = [(l['id'], s_['id']) for l in LESSONS for s_ in l['sections'] if 'key' not in s_]
assert not missing, f'sections with no key: {missing}'
assert all('goals' in l for l in LESSONS), 'a lesson with no goals'

# problems added for the tests' items (tool/acs/lfa_topics.py), practised after their lesson
MORE_PRACTICE = {
    'afn': ['425', '426', '400'],
    'af-er': ['427'],
    'expresii-regulate': ['406'],
    'afd': ['405'],
    'proprietati-lic': [str(i) for i in range(430, 436)] + ['492'],
    # written problems, as the tests ask them
    'inchidere-lr': ['401', '402', '403', '404', '407', '408', '450', '451', '452', '453', '454', '455'],
    'algoritmice-lr': [str(i) for i in range(410, 419)] + ['460', '461', '462', '463', '464'],
    'pompare-lr': [str(i) for i in range(420, 425)] + ['470', '471', '472', '473', '474', '475'],
    'minimizare': ['428', '482'],
    'recapitulare': ['480', '481'],
    'arbori-fnc': ['490', '491'],
}
_ids = {str(p_['id']) for p_ in json.load(open(os.path.join(ROOT, 'assets', 'data', 'acs', 'lfa.json'), encoding='utf-8'))['problems']}
for l in LESSONS:
    for i in MORE_PRACTICE.get(l['id'], []):
        assert i in _ids, i
        if i not in l['practice']:
            l['practice'].append(i)
