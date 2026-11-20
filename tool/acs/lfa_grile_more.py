"""LFA: more multiple-choice questions, by subject — exec'd by lfa.py after lfa_written.py.

Two sources:
- the Moodle attempt reviews of the OneDrive_2026-11-12 LFA folder (Grila 1, Grila 2, Test grila 1/2,
  Grila examen, Test grila examen; driveCA/Teste/Grile/LFA_Teste_Grile.pdf, Grile-TURBO, Examen/Grile)
  whose formulas MathJax had scattered: their text was rebuilt from the PDF by the position of each
  span on the page (PyMuPDF), then each question was written again by hand, deduplicated, its key
  checked (the regular expressions and grammars by brute force) and explained. Keys that were wrong
  or questions with no correct option were left out (e.g. S → 2S1S0S | 2S1S | 2S | e, whose
  language is none of the four options);
- new questions in the same style (source 'Grilă nouă …'), on what Grila 1 asks (LR and LIC).

Three chapters, one per seminar test: 11 (LR), 12 (LIC), 13 (MT and decidability).
"""

CGR = '11. Grile: limbaje regulate'
CGC = '12. Grile: LIC, gramatici, APD'
CGT = '13. Grile: Turing și decidabilitate'
CHAPTERS += [CGR, CGC, CGT]
GRILE_TESTS = {CGR: 1, CGC: 2, CGT: 3}

G1 = 'Grila 1 LFA (Moodle)'
TG1 = 'Test grilă 1 LFA (Moodle)'
G2 = 'Grila 2 LFA (Moodle)'
TG2 = 'Test grilă 2 LFA (Moodle)'
GE = 'Grilă de examen LFA (Moodle)'
TGE = 'Test grilă examen LFA (Moodle)'
NOU = 'Grilă nouă, în stilul testului'
AF = ['Adevărat, Adevărat', 'Adevărat, Fals', 'Fals, Adevărat', 'Fals, Fals']

_gid = [600]


def _title(q):
    t = tex_plain(q)
    if t.startswith('Alegeți valoarea'):
        first = t.split('\n')[1].lstrip('1) ').strip()
        return 'Adevărat/fals: ' + (first[:44].rsplit(' ', 1)[0] + '…' if len(first) > 46 else first.rstrip('.'))
    return title_of(t)


def _fix(t):
    """L\\' written in raw strings becomes L'; words inside a formula are taken out of it
    (a formula can't break across lines in the app), and the empty formulas this leaves dropped."""
    t = t.replace("\\'", "'")
    if '\\text{' not in t:
        return t
    t = re.sub(r'\\[ ,;!]\s*(?=\\text)', ' ', t)
    t = re.sub(r'\\text\{([^}]*)\}', lambda m_: '$ ' + m_[1].strip() + ' $', t)
    res = []
    for i, x in enumerate(t.split('$')):
        is_math = i % 2 == 1
        if is_math and not x.strip():
            continue
        if res and not is_math and not res[-1][0]:
            res[-1] = (False, res[-1][1] + x)
        else:
            res.append((is_math, x))
    t = ''.join(f'${x}$' if m_ else x for m_, x in res)
    return re.sub(r' {2,}', ' ', t)


def _add(p, topic=None):
    for k in ('statement', 'solution', 'title'):
        p[k] = _fix(p[k])
    p['spec']['options'] = [_fix(o) for o in p['spec']['options']]
    if topic:
        p['topic'] = topic
    P.append(p)
    _gid[0] += 1


def g(ch, diff, q, right, wrong, expl, src=NOU, topic=None):
    """One correct answer; its place among the options is fixed by the id."""
    q, right, wrong = _fix(q), _fix(right), [_fix(w) for w in wrong]
    _add(quiz(_gid[0], _title(q), ch, diff, wrap_tex(q), wrap_tex(right), [wrap_tex(w) for w in wrong], solution=_fix(expl), source=src), topic)


def gm(ch, diff, q, options, answers, expl, src=NOU, topic=None):
    """Options in the order given; one or more correct (answers: indices)."""
    q, options = _fix(q), [_fix(o) for o in options]
    _add(quiz_multi(_gid[0], _title(q), ch, diff, wrap_tex(q), [wrap_tex(o) for o in options], answers, solution=_fix(expl), source=src), topic)


def af(ch, diff, s1, s2, t1, t2, expl, src=NOU, topic=None):
    """Two statements, judged together: the four options in the usual order."""
    q = f'Alegeți valoarea de adevăr a afirmațiilor:\n1) {s1}\n2) {s2}'
    right = AF.index(f'{"Adevărat" if t1 else "Fals"}, {"Adevărat" if t2 else "Fals"}')
    gm(ch, diff, q, AF, [right], expl, src, topic)


# =====================================================================================
# 11. Limbaje regulate
# =====================================================================================
R = CGR

# --- automate finite: definiții
gm(R, 'medie', r'Fie un AFD $M = (K, \Sigma, \delta, s, F)$ și $|\delta|$ numărul de tranziții. Care afirmații sunt mereu adevărate?',
   [r'$|K| \cdot |\Sigma| = |\delta|$', r'$F \subseteq K$', r'$|F| = 0 \Rightarrow |\delta| = 0$', r'$|F| \neq 0$'], [0, 1],
   r'La un AFD, $\delta : K \times \Sigma \to K$ e o **funcție totală**: exact o tranziție pentru fiecare pereche (stare, simbol), deci $|K| \cdot |\Sigma|$ tranziții. $F \subseteq K$ prin definiție. Un AFD poate avea $F = \emptyset$ (acceptă $\emptyset$), dar tot are toate tranzițiile.',
   G1, 'lr-reprezentare')
gm(CGC, 'medie', r'Fie un automat cu stivă $M = (K, \Sigma, \Gamma, \Delta, s, F)$. Care afirmații sunt mereu adevărate?',
   [r'$|F| \geq |K| \Rightarrow s \in F$', r'$F \subseteq K$', r'$|\Gamma| > 0$', r'$|F| \neq 0 \Rightarrow |\Delta| > 0$'], [0, 1],
   r'Dacă $|F| \geq |K|$, cum $F \subseteq K$, rezultă $F = K$, deci și $s \in F$. $\Gamma$ poate fi vid (automatul nu folosește stiva), iar un automat cu $s \in F$ și fără tranziții acceptă $\{e\}$.',
   G1, 'lic-apd')
g(CGC, 'medie', r'Fie un automat cu stivă $M = (K, \Sigma, \Gamma, \Delta, s, F)$ cu $L(M) \notin LR$. Ce este mereu adevărat?',
  r'$|\Gamma| > 0$', [r'$|\Sigma| = |\Gamma|$', r'$|K| \cdot |\Sigma| = |\Delta|$', r'$F = K$'],
  r'Un APD cu $\Gamma = \emptyset$ nu poate pune nimic pe stivă: e un AFN, deci ar accepta un limbaj regulat. Cum $L(M)$ nu e regulat, stiva e folosită, deci $|\Gamma| > 0$.', G1, 'lic-apd')
g(R, 'ușoară', 'Configurația unui AFD conține:', 'starea curentă și șirul de intrare care a mai rămas de parcurs',
  ['starea curentă și întregul șir de intrare', 'starea următoare și întregul șir de intrare', 'starea curentă și șirul de intrare deja parcurs'],
  r'O configurație e o pereche $(q, w) \in K \times \Sigma^*$: starea curentă și ce a rămas de citit. Ce s-a citit nu mai influențează calculul.', TG1, 'lr-reprezentare')
g(R, 'ușoară', 'Care este numărul minim de stări finale ale unui AFD?', '0', ['1', r'$|\Sigma|$', 'o infinitate'],
  r'$F = \emptyset$ e permis: automatul acceptă limbajul vid.', TGE, 'lr-reprezentare')
g(R, 'ușoară', 'Care este numărul minim de stări finale ale unui AFN?', '0', ['1', r'$|\Sigma|$', 'o infinitate'],
  r'Ca la AFD, $F = \emptyset$ e permis ($L(M) = \emptyset$).', TGE, 'lr-reprezentare')
g(R, 'medie', r'Care este numărul minim de tranziții ale unui AFN pentru $L = \{w \in \{0,1\}^* \mid w \text{ începe cu } 0\}$?', '3', ['1', '2', '4'],
  r'Două stări: $s \xrightarrow{0} f$, iar în $f$ (finală) câte o buclă pe $0$ și pe $1$: 3 tranziții. Cu 2 nu se poate: trebuie citit primul $0$ și apoi orice simbol, de oricâte ori.', G1, 'lr-reprezentare')
g(R, 'ușoară', r'Care este numărul minim de stări ale unui AFN pentru $L = \{w \in \{0,1\}^* \mid w \text{ începe cu } 1\}$?', '2', ['1', '3', '4'],
  r'Cu o singură stare: dacă nu e finală, limbajul e vid; dacă e finală, acceptă și $e$, care nu începe cu 1. Două stări ajung: $s \xrightarrow{1} f$, $f$ finală, cu bucle pe 0 și 1.', G1, 'lr-reprezentare')
g(R, 'medie', r'Fie $L$ un limbaj regulat, $M_1 = (K_1, \Sigma, \delta_1, s_1, F_1)$ un AFD pentru $L$ și $M_2 = (K_2, \Sigma, \Delta_2, s_2, F_2)$ un AFN pentru $L$ ($\Sigma \neq \emptyset$). Care afirmație este adevărată?',
  r'numărul de tranziții din $M_1$ este $\geq |K_1|$', [r'$0 < |\Delta_2| < \infty$', r'$|\Delta_2| = |\Sigma| \cdot |K_2|$', r'$|K_2| \leq |K_1|$ dacă $L$ e infinit'],
  r'$M_1$ are exact $|K_1| \cdot |\Sigma| \geq |K_1|$ tranziții. AFN-ul poate avea 0 tranziții (pentru $\emptyset$ sau $\{e\}$), nu e obligat să aibă tranziții pentru toate perechile și nu e obligat să fie mai mic decât un AFD oarecare pentru același limbaj.', TG1, 'lr-reprezentare')
g(R, 'grea', r'Fie $L_1$ acceptat de AFN-ul $M_1 = (K, \Sigma, \Delta_1, s_1, F_1)$ și $L_2$ de AFN-ul $M_2 = (K, \Sigma, \Delta_2, s_2, F_2)$ (aceleași stări, același alfabet, $|\Sigma| > 1$), cu $L_1 \subseteq L_2$. Ce este adevărat?',
  r'nu există o relație între $\Delta_1$ și $\Delta_2$', [r'$\Delta_1 \subseteq \Delta_2$', r'$F_1 = F_2$', r'nu există $L_1, L_2$ care să satisfacă cerințele'],
  r'Incluziunea limbajelor nu spune nimic despre tranziții: două automate pentru același limbaj pot avea tranziții complet diferite (alte nume pentru stări, alte drumuri).', TG1, 'lr-reprezentare')
g(R, 'medie', r'Fie $m, n \geq 1$ și AFD-ul cu stările $q_{ij}$ ($0 \leq i < m$, $0 \leq j < n$), $\delta(q_{ij}, a) = q_{(i+1) \bmod m,\, j}$, $\delta(q_{ij}, b) = q_{i,\, (j+1) \bmod n}$, $s = q_{00}$, $F = \{q_{00}\}$. Ce limbaj acceptă?',
  r'$\{w \in \{a,b\}^* \mid \#_a(w) \bmod m = 0 \wedge \#_b(w) \bmod n = 0\}$',
  [r'$\{w \mid \#_a(w) \bmod m \neq 0 \wedge \#_b(w) \bmod n = 0\}$', r'$\{w \mid \#_a(w) \bmod m = 0 \wedge \#_b(w) \bmod n \neq 0\}$', r'$\{w \mid \#_a(w) \bmod m \neq 0 \wedge \#_b(w) \bmod n \neq 0\}$'],
  r'Indicele $i$ numără $a$-urile modulo $m$, $j$ numără $b$-urile modulo $n$ (e automatul produs al celor două contoare). Starea $q_{00}$ înseamnă ambele resturi 0.', GE, 'lr-reprezentare')
g(R, 'medie', r'Fie $M = (K, \{0,1\}, \Delta, s, F)$ un AFN cu $L(M) = \{0,1\}^*$. Ce este întotdeauna adevărat?', 'nicio variantă',
  [r'$F = K$', r'$|\Delta| = 2$', r'$F = \emptyset$'],
  r'Se poate ca $F = K$ (o stare cu două bucle), dar și un automat cu stări în plus, nefinale, nefolosite. $|\Delta|$ poate fi oricât de mare. $F = \emptyset$ ar da limbajul vid.', GE, 'lr-reprezentare')

# --- câte automate / expresii
g(R, 'ușoară', r'Câte automate finite deterministe se pot scrie pentru $L = \emptyset$?', 'o infinitate', ['niciunul', '1', '3'],
  'Orice AFD fără stări finale acceptă $\\emptyset$, și se pot adăuga oricâte stări: o infinitate de automate, toate echivalente.', G1, 'lr-bonus')
g(R, 'ușoară', r'Fie $\Sigma$ un alfabet. Câte automate finite nedeterministe se pot scrie pentru $L = \Sigma^*$?', 'o infinitate', ['niciunul', '1', '4'],
  'Pentru orice limbaj regulat există o infinitate de automate (se adaugă stări inaccesibile sau redundante).', G1, 'lr-bonus')
af(R, 'ușoară', 'Pentru orice limbaj regulat se poate scrie o infinitate de automate finite deterministe.',
   'Pentru orice automat finit nedeterminist există o infinitate de expresii regulate echivalente.', True, True,
   r'1: se adaugă stări în plus. 2: dacă $E$ e echivalentă cu automatul, la fel sunt $E \cup \emptyset$, $(E \cup \emptyset) \cup \emptyset$, ... .', G1, 'lr-bonus')
g(R, 'medie', r'Câte stări are AFD-ul minim pentru $L = \{w \in \{a,b\}^* \mid w \text{ se termină în } ab\}$?', 'trei', ['una', 'două', 'patru'],
  r'Stările țin minte cât din sufixul $ab$ am văzut: nimic, „$a$”, „$ab$” (finală). Sunt 3 clase Myhill–Nerode: $e$, $a$, $ab$.', NOU, 'lr-conversii')
g(R, 'medie', r'Câte stări are AFD-ul minim (complet) pentru $L = \{w \in \{a,b\}^* \mid |w| = 2\}$?', 'patru', ['două', 'trei', 'cinci'],
  r'Lungimea citită: 0, 1, 2 (finală) și „peste 2” (stare capcană). Toate patru sunt distinguibile.', NOU, 'lr-conversii')
g(R, 'medie', r'Câte stări are AFD-ul minim pentru $L = \{w \in \{a,b\}^* \mid \#_a(w) \bmod 3 = 0\}$?', 'trei', ['una', 'două', 'șase'],
  r'Restul împărțirii numărului de $a$-uri la 3: 0 (finală), 1, 2. $b$ nu schimbă starea.', NOU, 'lr-conversii')
g(R, 'medie', r'Un AFN are $n$ stări. Câte stări are, cel mult, AFD-ul obținut prin construcția submulțimilor?', r'$2^n$', [r'$n$', r'$n^2$', r'$n!$'],
  'Fiecare stare a AFD-ului e o submulțime de stări ale AFN-ului (inclusiv $\\emptyset$, starea capcană): cel mult $2^n$. Există limbaje la care toate sunt necesare.', NOU, 'lr-conversii')
af(R, 'ușoară', 'Există limbaje regulate acceptate de automate finite nedeterministe, dar neacceptate de niciun automat finit determinist.',
   'Orice limbaj regulat finit este și independent de context.', False, True,
   'AFN și AFD acceptă exact aceeași clasă (construcția submulțimilor). Orice limbaj regulat (deci și orice limbaj finit) e independent de context.', G1, 'lr-conversii')
af(R, 'medie', 'Un AFN care acceptă șirul vid trebuie să aibă starea inițială finală.', 'Dacă $L$ este regulat, atunci orice limbaj inclus în $L$ este regulat.', False, False,
   r'1: poate ajunge într-o stare finală prin tranziții pe $e$. 2: $\{a^nb^n\} \subseteq \{a,b\}^*$, iar $\{a,b\}^*$ e regulat.', TGE, 'lr-inchidere')
af(R, 'medie', 'Orice expresie regulată este echivalentă cu o expresie regulată fără paranteze.',
   'Orice limbaj regulat poate fi acceptat de un automat finit nedeterminist fără tranziții pe șirul vid.', False, True,
   r'1: fără paranteze, steaua se aplică doar unui simbol, deci $(ab)^*$ nu se poate scrie. 2: tranzițiile pe $e$ se elimină (închiderea pe $e$), iar un AFD e deja un AFN fără ele.', GE, 'lr-conversii')

# --- expresii regulate
g(R, 'medie', r'Fie $E = \emptyset^* a b^* b b^*$. Care afirmație este adevărată?', r'$L(E) = L(a(b\emptyset \cup b^*)b)$',
  [r'$L(E) = \emptyset$', r'orice $w \in L(E)$ se termină cu un număr impar de $b$', r'$L(ab^*) \subseteq L(E)$'],
  r'$\emptyset^* = \{e\}$, deci $L(E) = ab^*bb^* = \{ab^n \mid n \geq 1\}$. $b\emptyset = \emptyset$, deci $a(b\emptyset \cup b^*)b = ab^*b$: același limbaj. $a \in L(ab^*)$, dar $a \notin L(E)$.', G1, 'lr-reprezentare')
g(R, 'medie', r'Fie $r = a(ab^*a \cup b^*)^*$. Alegeți varianta corectă:', r'$a$ apare în orice șir generat de $r$',
  [r'$b$ apare în orice șir generat de $r$', r'$e \in L(r)$', 'niciuna dintre variante'],
  r'Orice șir din $L(r)$ începe cu $a$. Șirul $a$ (steaua de 0 ori) nu conține $b$, iar $e$ nu e în limbaj.', TG1, 'lr-reprezentare')
g(R, 'medie', r'Fie $r = a(aa^*a \cup b^*)^*$. Alegeți varianta corectă:', r'$a \in L(r)$',
  [r'$aa \in L(r)$', r'$b$ apare în orice șir generat de $r$', 'niciuna dintre variante'],
  r'Steaua de 0 ori dă $a$. După primul $a$ urmează blocuri $aa^*a$ (cel puțin două $a$-uri) sau $b^*$, deci un singur $a$ în plus nu se poate: $aa \notin L(r)$.', TG1, 'lr-reprezentare')
g(R, 'ușoară', r'Care este ER pentru $L(a(a \cup b)^*) \cap L(b(a \cup b)^*)$?', r'$\emptyset$', [r'$(a \cup b)^*$', r'$(a \cup b)(a \cup b)^*$', r'$a \cup b$'],
  'Un șir nu poate începe și cu $a$, și cu $b$.', TG1, 'lr-inchidere')
gm(R, 'grea', r'Care dintre expresiile următoare generează $L = \{w \in \{0,1\}^* \mid \#_{00}(w) \leq 1\}$ (cel mult o apariție a lui $00$)?' + '\n' +
   r'1) $((e \cup 0)11^*)^*(e \cup 0 \cup 00)(11^*(e \cup 0))^*$' + '\n' + r'2) $(e \cup 0)(e \cup 1 \cup 10)^*(e \cup 1 \cup 01)^*(e \cup 0)$' + '\n' + r'3) $((e \cup 0)11^*)^*(e \cup 00)(11^*(e \cup 0))^*$',
   ['toate trei', 'prima și a doua', 'prima și a treia', 'a doua și a treia'], [1],
   r'A treia nu poate genera $0$ (mijlocul e $e$ sau $00$, iar un $0$ singur trebuie urmat de $1$): îi lipsesc $0$, $010$, ... . Prima și a doua sunt corecte (verificat pe toate șirurile de lungime $\leq 10$). În a doua, $00$ poate apărea doar la granița dintre cele două stele ($...10 \cdot 01...$) sau la capete.', TG1, 'lr-reprezentare')
gm(R, 'grea', r'Care dintre expresiile următoare generează $L = \{w \in \{0,1\}^* \mid \#_{00}(w) \leq 1\}$?' + '\n' +
   r'1) $(0 \cup e)(e \cup 1 \cup 10)^*(e \cup 00)(e \cup 1 \cup 10)^*$' + '\n' + r'2) $(e \cup 1 \cup 01)^*(e \cup 00)(e \cup 1 \cup 10)^*$' + '\n' + r'3) $((e \cup 0)11^*)^*(e \cup 00)(11^*(e \cup 0))^*$',
   ['niciuna', 'prima', 'a doua și a treia', 'toate trei'], [0],
   r'1 generează $000$ (cu $0$, apoi $00$): două apariții. 2 și 3 nu generează $0$. Nicio expresie nu e corectă.', TG1, 'lr-reprezentare')
g(R, 'medie', r'Fie $\Sigma = \{a, b\}$ și $L$ limbajul palindroamelor peste $\Sigma$. Expresia regulată pentru $L$ este:', 'nu există nicio expresie regulată pentru $L$',
  [r'$((a^*b^*)^*a \cup (b^*a^*)b)^*$', r'$(bab \cup aba)^* \cup a \cup b$', r'$a^*b^*a^* \cup b^*a^*b^*$'],
  r'Palindroamele peste $\{a,b\}$ nu sunt regulate: $L \cap a^*ba^* = \{a^nba^n\}$ nu e regulat (pompare).', TG1, 'lr-pompare')
g(R, 'ușoară', r'Care expresie generează limbajul vid?', r'$a^*\emptyset$', [r'$\emptyset^*$', r'$\emptyset^* a^*$', r'$(\emptyset \cup a)^*$'],
  r'Concatenarea cu $\emptyset$ dă $\emptyset$. Atenție: $\emptyset^* = \{e\}$.', NOU, 'lr-reprezentare')
af(R, 'ușoară', r'Mulțimea limbajelor regulate peste $\Sigma = \{a\}$ este finită.', r'$\emptyset^* = \emptyset$', False, False,
   r'1: $\{a^n\}$ pentru fiecare $n$ e regulat (finit): o infinitate. 2: $\emptyset^* = \{e\}$.', G1, 'lr-bonus')
af(R, 'ușoară', 'Orice expresie regulată ce conține operația Kleene star generează un limbaj infinit.', 'Un AFD poate avea 0 stări finale.', False, True,
   r'1: $\emptyset^* = \{e\}$, finit. 2: da, acceptă $\emptyset$.', TG1, 'lr-reprezentare')
af(R, 'medie', r'Dacă $L \subseteq \Sigma^*$ e regulat, atunci $L\' = \{0^i \mid \exists w \in L,\ i = |w|\}$ e regulat.', r'Limbajul $L(\emptyset^* a^*)$ este vid.', True, False,
   r'1: $L\'$ e imaginea lui $L$ prin morfismul care trimite fiecare simbol în $0$; LR sunt închise la morfisme (în automat, fiecare tranziție se reetichetează cu $0$). 2: $\emptyset^* a^* = a^*$.', GE, 'lr-inchidere')
af(R, 'medie', r'Pentru $E = a^*\emptyset^* aa^*b$, $|L(E)| = 0$.', r'$L = \{1^n 0^m \mid n, m \geq 0,\ n \neq m\}$ este regulat.', False, False,
   r'1: $\emptyset^* = \{e\}$, deci $L(E) = a^*aa^*b \ni ab$. 2: complementul lui $\{1^n0^n\}$ în $1^*0^*$; dacă ar fi regulat, ar fi și $\{1^n0^n\}$.', TGE, 'lr-pompare')
g(R, 'grea', r'Fie $J = \{L \subseteq \{a,b\}^* \mid |L^*| < \infty\}$. Cât este $\sum_{L \in J} |L^*|$?', '2', ['0', '1', r'$\infty$'],
  r'$L^*$ e finit doar dacă $L$ nu conține niciun șir nevid: $L = \emptyset$ sau $L = \{e\}$. În ambele cazuri $L^* = \{e\}$, de cardinal 1. Suma: $1 + 1 = 2$.', GE, 'lr-bonus')

# --- clase de limbaje: regulat sau nu
g(R, 'medie', r'Fie $L = \{a^{2^n} \mid n \geq 0\}$. Cum este $L$ în cel mai strict sens?', 'nicio variantă',
  ['limbaj finit', 'limbaj regulat', 'limbaj independent de context'],
  r'$L$ e infinit; nu e regulat și nici independent de context (pompare: lungimile $2^n$ au goluri tot mai mari). Pe un alfabet cu o literă, LIC = LR.', G1, 'lr-pompare')
g(R, 'medie', r'Fie $L = \{a^{n^2} \mid n \geq 0\}$. Cum este $L$ în cel mai strict sens?', 'nicio variantă',
  ['limbaj finit', 'limbaj regulat', 'limbaj independent de context'],
  r'Diferența dintre pătrate consecutive, $2n + 1$, crește: pomparea dă lungimi care nu sunt pătrate. Pe alfabet unar LIC = LR, deci nu e nici LIC.', G1, 'lr-pompare')
g(R, 'medie', r'Fie $L = \{a^p \mid p \text{ prim}\}$. Cum este $L$ în cel mai strict sens?', 'nicio variantă',
  ['limbaj finit', 'limbaj regulat', 'limbaj independent de context'],
  r'Pompând $a^p$ cu $y = a^k$ de $p + 1$ ori se obține lungimea $p(1 + k)$, care nu e primă. Nu e regulat, iar pe alfabet unar nici LIC.', G1, 'lr-pompare')
g(R, 'grea', r'Fie $L = \{a^{n^3} \mid n \in \mathbb{N}\}$. Alegeți varianta corectă:', r'$L \notin LR \wedge L^* \in LR$',
  [r'$L \in LR \wedge L^* \in LR$', r'$L \notin LR \wedge L^* \notin LR$', r'$L \in LR \wedge L^* \notin LR$'],
  r'$L$ nu e regulat (golurile cresc). Dar $a = a^{1^3} \in L$, deci $L^* = a^*$, regulat.', TGE, 'lr-pompare')
g(R, 'grea', r'Pentru orice limbaj $L \subseteq 0^*$, $L^*$ este:', 'un limbaj regulat',
  ['un limbaj independent de context, dar nu regulat', 'nici independent de context, nici regulat', 'nu se poate preciza'],
  r'Lungimile din $L^*$ sunt sumele de lungimi din $L$. Dacă $d$ e cmmdc-ul lungimilor, de la un prag încolo toți multiplii lui $d$ se pot obține (teorema lui Frobenius), deci $L^*$ = o mulțime finită $\cup$ $(0^d)^*$ de la prag: regulat.', TG1, 'lr-bonus')
g(R, 'medie', r'Fie $\Sigma = \{a\}$ și $L = \{w \in \Sigma^* \mid w \text{ este palindrom}\}$. Cum este $L$?', 'regulat, dar nu finit',
  ['finit', 'independent de context, dar nu regulat', 'nu este independent de context'],
  r'Peste o singură literă orice cuvânt e palindrom: $L = a^*$.', TG1, 'lr-pompare')
g(R, 'medie', r'Fie $\Sigma = \{a, b\}$ și $L = \{w \in \Sigma^* \mid w \text{ este palindrom}\}$. Cum este $L$?', 'independent de context, dar nu regulat',
  ['finit', 'regulat, dar nu finit', 'nu este independent de context'],
  r'GIC: $S \to aSa \mid bSb \mid a \mid b \mid e$. Nu e regulat: $L \cap a^*ba^* = \{a^nba^n\}$.', TG1, 'lr-pompare')
g(R, 'medie', r'Fie $\Sigma$ un alfabet și $L = \{xw \mid x, w \in \Sigma^*,\ |x| = |w|\}$. Cum este $L$ în cel mai strict sens?', 'regulat',
  ['independent de context', 'Turing decidabil', 'Turing acceptat'],
  r'Orice șir de lungime pară se taie în două jumătăți egale: $L = ((\Sigma)(\Sigma))^*$, șirurile de lungime pară. Nu se cere nicio legătură între $x$ și $w$.', GE, 'lr-pompare')
g(R, 'ușoară', r'Fie $L = \{w \in \{a,b\}^* \mid w \text{ începe cu } b \text{ și se termină cu } a\}$. Cum este $L$ în cel mai strict sens?', 'regulat',
  ['finit', 'independent de context', 'nu este independent de context'], r'$L = L(b(a \cup b)^*a)$.', GE, 'lr-reprezentare')
g(R, 'ușoară', r'Fie $L = \{a^ib^jc^kd^m \mid i + j + k + m = 11\}$. Cum este $L$ în cel mai strict sens (dintre variante)?', 'regulat',
  ['independent de context', 'Turing decidabil', 'Turing acceptat'], 'Limbajul e finit (toate cuvintele au lungimea 11), deci regulat.', GE, 'lr-pompare')
g(R, 'medie', r'Fie $\Sigma = \{0,1\}$ și $L = \{w \mid \forall u, v, x \in \Sigma^*,\ w = uvx \Rightarrow |\#_0(v) - \#_1(v)| \leq 1\}$. Alegeți varianta adevărată:', 'L este regulat, dar nu finit',
  ['L este finit', 'L este independent de context, dar nu regulat', 'L nu este independent de context'],
  r'Orice subșir (factor) de lungime 2 trebuie să aibă un 0 și un 1, deci simbolurile alternează: $L = \{e\} \cup (01)^*(0 \cup e) \cup (10)^*(1 \cup e)$; infinit, regulat.', TG1, 'lr-pompare')
g(R, 'medie', r'Fie $\Sigma = \{0,1\}$ și $L = \{w \mid \forall u, v, x \in \Sigma^*,\ w = uvx \Rightarrow |\#_0(u) - \#_1(u)| < 1\}$. Alegeți varianta adevărată:', 'L este finit',
  ['L este regulat, dar nu finit', 'L este independent de context, dar nu regulat', 'L nu este independent de context'],
  r'Orice prefix $u$ trebuie să aibă la fel de multe 0 ca 1. Dar prefixul de lungime 1 are diferența 1. Rămâne doar $L = \{e\}$.', TG1, 'lr-pompare')
g(R, 'medie', r'Fie $\Sigma = \{0,1\}$ și $L = \{w \mid \forall u, v, x \in \Sigma^*,\ w = uvx \Rightarrow |\#_0(x) - \#_1(x)| > 1\}$. Alegeți varianta adevărată:', 'L este finit',
  ['L este regulat, dar nu finit', 'L este independent de context, dar nu regulat', 'L nu este independent de context'],
  r'Sufixul $x = e$ are diferența 0, care nu e $> 1$: niciun $w$ nu satisface condiția, $L = \emptyset$, finit.', TG1, 'lr-pompare')
g(R, 'medie', r'Fie $n \geq 0$, $L_n = \{a^jb^k \mid j < n,\ 0 < k < j\}$ și $L = \bigcup_{i \geq 1} L_i$. Alegeți varianta corectă:', 'L nu este regulat',
  [r'L este finit, pentru că fiecare $L_i$ e finit', 'L este regulat, dar nu finit', 'nu se poate preciza'],
  r'$L = \{a^jb^k \mid 0 < k < j\}$: o reuniune infinită de limbaje finite nu e neapărat regulată. Pompând $a^{p+1}b^p$ în zona de $a$-uri în jos se obține $k \geq j$.', TG1, 'lr-pompare')
g(R, 'ușoară', 'Mulțimea tuturor cuvintelor care se găsesc pe toate paginile de pe internet formează:', 'un limbaj regulat',
  ['un limbaj independent de context, dar nu regulat', 'un limbaj care nu e independent de context', 'nu se poate preciza'],
  'E o mulțime finită de cuvinte, iar orice limbaj finit e regulat.', TG1, 'lr-pompare')
af(R, 'medie', r'$L = \{0^n1^m \mid n, m \geq 0,\ n \neq m\}$ este regulat.', r'$L = \{0^n0^m \mid n, m \geq 0,\ n \neq m\}$ este regulat.', False, True,
   r'1: altfel $\overline{L} \cap 0^*1^* = \{0^n1^n\}$ ar fi regulat. 2: $0^n0^m = 0^{n+m}$, iar orice lungime $\geq 1$ se scrie ca $n + m$ cu $n \neq m$ (de ex. $n = k$, $m = 0$): $L = 0^+$.', TGE, 'lr-pompare')

# --- închidere
g(R, 'ușoară', r'Fie $\Sigma$ un alfabet și $L$ un limbaj peste $\Sigma$. Valoarea de adevăr a afirmației $L_1 = L \cup \Sigma^* \Rightarrow L_1 \in LR$ este:', 'adevărat pentru orice $L$',
  [r'adevărat doar dacă $L = \emptyset$', 'adevărat doar dacă $L$ e finit', 'fals'], r'$L \subseteq \Sigma^*$, deci $L \cup \Sigma^* = \Sigma^*$, regulat, indiferent cât de complicat e $L$.', G1, 'lr-inchidere')
g(R, 'ușoară', r'Fie $L \in LR$. Cum este $L^R$ (răsturnatul)?', r'$\forall L \in LR \Rightarrow L^R \in LR$',
  [r'$\exists L \in LR \Rightarrow L^R \notin LR$', r'$\forall L \in LR \Rightarrow L^R \in LIC \wedge L^R \notin LR$', r'$L^R$ este întotdeauna finit'],
  'Se inversează săgețile automatului, starea inițială devine finală, iar finalele devin inițiale (printr-o stare nouă cu tranziții pe $e$).', G1, 'lr-inchidere')
g(R, 'medie', r'Fie $L = L_1 \cup L_2$ cu $L_1 \cap L_2 = \emptyset$, $L_1$ regulat și $L_2$ neregulat. Atunci $L$:', 'nu este regulat',
  ['este regulat', 'poate fi regulat', 'nu se poate preciza'],
  r'Fiind disjuncte, $L_2 = L \setminus L_1 = L \cap \overline{L_1}$. Dacă $L$ ar fi regulat, și $L_2$ ar fi (închidere la complement și intersecție).', TG1, 'lr-inchidere')
g(R, 'medie', r'Fie $L_1 \cap L_2 \in LR$ și $L_1 \cup L_2 \in LR$. Ce este întotdeauna adevărat?', 'nicio variantă',
  [r'$L_1, L_2 \in LR$', r'$L_1 \in LR \vee L_2 \in LR$', 'cel puțin un limbaj este finit'],
  r'$L_2 = \overline{L_1}$ cu $L_1$ neregulat: $L_1 \cap L_2 = \emptyset$, $L_1 \cup L_2 = \Sigma^*$, ambele regulate, dar niciunul dintre $L_1, L_2$ nu e regulat (și niciunul nu e finit).', GE, 'lr-inchidere')
g(R, 'medie', r'Fie $L$ regulat, $PREFIX(L)$ mulțimea prefixelor cuvintelor din $L$ și $SUFIX(L)$ mulțimea sufixelor. Alegeți afirmația FALSĂ:', r'$L = PREFIX(L) \cdot SUFIX(L)$',
  [r'$SUFIX(L)$ este regulat', r'$PREFIX(L)$ este regulat', r'$L \cap PREFIX(L)$ este regulat'],
  r'Pentru $L = \{ab\}$: $e \in PREFIX(L)$ și $e \in SUFIX(L)$, deci $e \in PREFIX \cdot SUFIX$, dar $e \notin L$. Prefixele: aceleași stări, devin finale toate stările din care se poate ajunge într-o finală; sufixele: analog.', GE, 'lr-inchidere')
g(R, 'medie', r'Fie $L_1$ și $L_2$ regulate și $L_3 = \{xy \mid x \in L_1,\ y \in L_2,\ |x| = |y|\}$. Cum este întotdeauna $L_3$ (cel mai strict)?', 'LIC',
  ['LR', 'nu este LIC', 'nu se poate afirma nimic'],
  r'Un APD pune un simbol pe stivă pentru fiecare simbol citit din $x$ (simulând AFD-ul lui $L_1$), ghicește mijlocul, apoi scoate unul pentru fiecare simbol din $y$ (simulând AFD-ul lui $L_2$). Nu e mereu regulat: $L_1 = a^*$, $L_2 = b^*$ dau $\{a^nb^n\}$.', G1, 'lr-inchidere')
g(R, 'grea', r'Fie $L\' = \{ww \mid w \in L\}$, unde $L$ e regulat. Atunci:', 'limbajele regulate sunt închise la concatenare (dar $L\'$ poate să nu fie regulat)',
  [r'$L\' = LL$', r'$L\'$ este regulat', 'limbajele regulate sunt închise la produsul cartezian'],
  r'$L\' \neq LL$: $LL$ conține și $w_1w_2$ cu $w_1 \neq w_2$. Pentru $L = a^*b$, $L\' = \{a^nba^nb\}$ nu e regulat. Concatenarea a două LR e LR, dar $L\'$ cere aceeași jumătate de două ori.', TG1, 'lr-inchidere')
g(R, 'ușoară', r'Fie $\Sigma = \{a,b\}$ și $K = \{L \subseteq \Sigma^* \mid abba \in L\}$. În raport cu care operație $K$ NU este închisă?', 'complementare',
  ['reuniune', 'intersecție', 'Kleene star'], r'Dacă $abba \in L$, atunci $abba \notin \overline{L}$. Reuniunea, intersecția și steaua păstrează $abba$.', TGE, 'lr-inchidere')
g(R, 'ușoară', r'Fie $L_1, L_2$ limbaje finite și $L_3 = L_1 \cup L_2L_1$. Ce se poate afirma întotdeauna despre $L_3$?', 'este regulat',
  ['nu este finit', 'nu este regulat', 'nu se poate afirma nimic'], 'Reuniunea și concatenarea limbajelor finite dau un limbaj finit, deci regulat.', TGE, 'lr-inchidere')
g(R, 'medie', r'Fie $L_1 = L(1^*0^*)$ și $L_2$ un limbaj cu $L_1 \subseteq L_2$. Ce este întotdeauna adevărat?', 'nu se poate spune nimic',
  [r'$L_2 \in LR$', r'$L_2 \in LIC$', r'$L_2 = L_1$'],
  r'Un limbaj care include un limbaj regulat poate fi orice: $L_1 \cup \{a^{n^2}\}$, $\Sigma^*$, $L_1$ însuși.', TG1, 'lr-inchidere')
g(R, 'medie', r'Fie $\Sigma = \{a,b\}$, $L_1 = L((a^*b^*)^*)$, $L_2 = L((a \cup b)^*)$ și $L_3 = \Sigma^* \setminus (L_1 \cap (\Sigma^* \setminus L_2))$. Alegeți afirmația adevărată:', r'$L_3 \neq \emptyset$',
  [r'$L_3 \neq L_2$', r'$L_3 \neq \Sigma^*$', r'$L_3 \neq L_1$'],
  r'$L_1 = L_2 = \Sigma^*$, deci $\Sigma^* \setminus L_2 = \emptyset$, intersecția e vidă și $L_3 = \Sigma^*$. Singura afirmație adevărată: $L_3 \neq \emptyset$.', TG1, 'lr-inchidere')
g(R, 'medie', r'Fie $M_1 = \{L \mid L \in LR \wedge a \in L\}$ și $M_2 = \{L \mid L \in LR \wedge b \in L\}$. Cu ce este egal $M_1 \cap M_2$?', 'nicio variantă',
  [r'$\{L \mid L \in LR \wedge ab \in L\}$', r'$\emptyset$', r'$\{L \mid L \in LR\}$'],
  r'$M_1 \cap M_2$ = limbajele regulate care conțin și $a$, și $b$. Nu e vidă ($\{a, b\}$), nu sunt toate LR ($\emptyset$ lipsește), iar condiția nu e despre $ab$.', TG1, 'lr-inchidere')
g(R, 'ușoară', r'Fie $M_1 = \{L \mid L \in LR\}$ și $M_2 = \{L \mid L \in LIC\}$. Cu ce este egal $M_1 \setminus M_2$?', r'$\emptyset$',
  [r'$M_1$', r'$M_2$', 'nicio variantă'], r'Orice limbaj regulat e independent de context: $LR \subseteq LIC$, deci diferența e vidă.', TG1, 'lr-bonus')
g(R, 'ușoară', r'Fie $M_1 = \{L \mid L \in LR\}$ și $M_2 = \{L \mid L \in LIC\}$. Cu ce este egal $M_2 \setminus M_1$?', 'nicio variantă',
  [r'$\emptyset$', r'$M_1$', r'$M_2$'], r'$M_2 \setminus M_1$ = LIC care nu sunt regulate (de ex. $\{a^nb^n\}$): nevidă, diferită de $M_1$ și de $M_2$.', TG1, 'lr-bonus')

# --- numărabilitate, algoritmi
g(R, 'medie', r'Fie $\Sigma = \{0, ..., 9, a, ..., f\}$. Este mulțimea limbajelor peste $\Sigma$ numărabilă? Dar mulțimea limbajelor regulate peste $\Sigma$?', 'nu, da',
  ['da, da', 'da, nu', 'nu, nu'],
  r'Limbajele sunt submulțimile lui $\Sigma^*$ (o mulțime numărabilă infinită): $2^{\Sigma^*}$ e nenumărabilă. Limbajele regulate au fiecare o expresie regulată, un șir finit: sunt numărabile.', TG1, 'lr-bonus')
g(R, 'ușoară', r'Mulțimea limbajelor care NU sunt regulate peste $\Sigma = \{a, b\}$ este:', 'nenumărabilă',
  ['finită', 'infinit numărabilă', 'nu se poate afirma nimic'],
  'Toate limbajele formează o mulțime nenumărabilă, iar cele regulate una numărabilă; diferența rămâne nenumărabilă.', TGE, 'lr-bonus')
g(R, 'ușoară', r'Fie $\Sigma$ un alfabet și $Y = \{L \subseteq \Sigma^* \mid \forall w \in L,\ \exists M \in AFD,\ L(M) = \{w\}\}$. Alegeți afirmația corectă:', r'$LR \subseteq Y$',
  [r'$Y \subseteq LR$', r'$Y \subseteq LIC$', r'$\forall L \in Y$, $L$ este Turing decidabil'],
  r'Pentru orice cuvânt $w$ există un AFD pentru $\{w\}$, deci condiția e adevărată pentru orice $L$: $Y$ = toate limbajele. Atunci $LR \subseteq Y$, dar $Y$ conține și limbaje nedecidabile.', TGE, 'lr-bonus')
af(R, 'medie', r'Dacă $\overline{L}$ este un limbaj infinit, atunci $L$ este finit.', 'Orice limbaj regulat infinit conține un limbaj regulat.', False, True,
   r'1: $L = $ șirurile de lungime pară: și el, și complementul sunt infinite. 2: conține $\emptyset$ (și pe el însuși).', TGE, 'lr-bonus')
af(R, 'medie', r'Fie $M_1, M_2$ AFD. Există un algoritm care decide dacă $L(M_1) \subseteq L(M_2)$.', r'Nu există un algoritm care decide dacă $L(M_2) = (L(M_1)L(M_2))^*$.', True, False,
   r'1: $L(M_1) \subseteq L(M_2) \iff L(M_1) \cap \overline{L(M_2)} = \emptyset$, iar vidarea e decidabilă. 2: ambele părți sunt regulate (construibile efectiv), iar egalitatea a două LR e decidabilă (prin AFD minim sau diferență simetrică vidă).', TGE, 'lr-algoritmice')

# --- noi, pe itemii testului
g(R, 'medie', 'Care limbaj este regulat?', r'$\{a^nb^m \mid n + m \text{ par}\}$',
  [r'$\{a^nb^m \mid n = m\}$', r'$\{a^nb^m \mid n \leq m\}$', r'$\{a^nb^m \mid n = 2m\}$'],
  r'Paritatea lui $n + m$ se ține minte cu 2 stări (plus faza $a$/$b$). Celelalte cer o comparație nemărginită între $n$ și $m$.', NOU, 'lr-pompare')
g(R, 'medie', r'În lema de pompare pentru limbaje regulate, pentru un cuvânt $w \in L$ cu $|w| \geq p$, descompunerea $w = xyz$ trebuie să respecte:', r'$|xy| \leq p$ și $|y| \geq 1$',
  [r'$|y| \leq p$ și $|x| \geq 1$', r'$|xz| \leq p$ și $|y| \geq 1$', r'$|xy| \geq p$ și $|z| \geq 1$'],
  r'$y$ nevid, în primele $p$ simboluri; atunci $xy^iz \in L$ pentru orice $i \geq 0$.', NOU, 'lr-pompare')
g(R, 'medie', r'Pentru a arăta cu lema de pompare că $L$ NU e regulat, cine alege fiecare element?', r'adversarul alege $p$ și descompunerea $xyz$; noi alegem $w$ și $i$',
  [r'noi alegem $p$, $w$ și descompunerea; adversarul alege $i$', r'adversarul alege $w$; noi alegem $p$ și $i$', r'noi alegem tot, inclusiv descompunerea'],
  r'Lema spune „există $p$, pentru orice $w$ ... există o descompunere, pentru orice $i$”. Negația: pentru orice $p$ găsim un $w$ astfel încât pentru orice descompunere validă găsim un $i$ cu $xy^iz \notin L$.', NOU, 'lr-pompare')
g(R, 'ușoară', 'Dacă un limbaj satisface lema de pompare pentru limbaje regulate, atunci:', 'nu se poate spune sigur că e regulat',
  ['e sigur regulat', 'e sigur neregulat', 'e sigur finit'],
  r'Lema e o condiție necesară, nu suficientă: există limbaje neregulate care o satisfac (de ex. $\{a^ib^jc^j \mid i \geq 1\} \cup b^*c^*$).', NOU, 'lr-pompare')
g(R, 'ușoară', 'Limbajele regulate NU sunt închise în raport cu:', 'submulțimile (orice submulțime a unui LR)',
  ['complementul', 'intersecția', 'răsturnarea'], r'$\{a^nb^n\} \subseteq a^*b^*$. Celelalte trei operații păstrează regularitatea.', NOU, 'lr-inchidere')
g(R, 'medie', r'Dacă $L_1$ e regulat și $L_2$ nu e regulat, $L_1 \cap L_2$ este:', 'nu se poate preciza',
  ['întotdeauna regulat', 'întotdeauna neregulat', 'întotdeauna vid'],
  r'Cu $L_1 = \emptyset$: $\emptyset$, regulat. Cu $L_1 = \Sigma^*$: $L_2$, neregulat.', NOU, 'lr-inchidere')
g(R, 'medie', r'Dacă $L_1$ și $L_2$ nu sunt regulate, $L_1 \cup L_2$ este:', 'nu se poate preciza',
  ['întotdeauna neregulat', 'întotdeauna regulat', 'întotdeauna independent de context'],
  r'$L$ și $\overline{L}$ cu $L$ neregulat: reuniunea e $\Sigma^*$. Dar $\{a^nb^n\} \cup \{a^nb^{2n}\}$ nu e regulat.', NOU, 'lr-inchidere')
g(R, 'ușoară', 'Care problemă este decidabilă pentru un AFD $M$ dat?', r'dacă $L(M)$ este infinit',
  ['niciuna dintre variante', r'dacă $L(M)$ e independent de context, dar nu regulat', r'dacă $L(M)$ conține un cuvânt nedecidabil'],
  r'$L(M)$ e infinit dacă și numai dacă există un ciclu accesibil din $s$ din care se poate ajunge într-o stare finală (sau: acceptă un cuvânt cu lungimea între $n$ și $2n - 1$).', NOU, 'lr-algoritmice')
g(R, 'medie', r'Ce face, la eliminarea stărilor (AF → ER), eliminarea unei stări $q$ cu bucla $S$, o săgeată intrare $p \xrightarrow{A} q$ și o ieșire $q \xrightarrow{B} r$?', r'adaugă (prin reuniune) eticheta $AS^*B$ pe săgeata $p \to r$',
  [r'adaugă $A \cup S \cup B$ pe $p \to r$', r'adaugă $ASB$ pe $p \to r$', r'adaugă $(ASB)^*$ pe $p \to r$'],
  r'Un drum $p \to q \to r$ citește $A$, apoi oricâte bucle $S$, apoi $B$: $AS^*B$. Se reunește cu eticheta deja existentă pe $p \to r$.', NOU, 'lr-conversii')
g(R, 'medie', r'Câte stări are AFN-ul obținut prin construcția Thompson pentru $a^*$?', '4', ['1', '2', '3'],
  r'Steaua adaugă o stare inițială și una finală noi în jurul automatului pentru $a$ (2 stări): $2 + 2 = 4$.', NOU, 'lr-conversii')
af(R, 'ușoară', r'$L(\emptyset^*) = \{e\}$.', r'$L(a\emptyset) = \{a\}$.', True, False, r'$\emptyset^*$ conține concatenarea a zero cuvinte, $e$. Concatenarea cu $\emptyset$ dă $\emptyset$.', NOU, 'lr-reprezentare')
af(R, 'medie', 'Orice limbaj finit este regulat.', 'Orice limbaj infinit este neregulat.', True, False, r'1: o reuniune finită de cuvinte e o ER. 2: $a^*$ e infinit și regulat.', NOU, 'lr-reprezentare')
af(R, 'medie', 'Două AFD minime pentru același limbaj au același număr de stări.', 'Un AFN cu $n$ stări are întotdeauna un AFD echivalent cu cel mult $n$ stări.', True, False,
   r'1: AFD-ul minim e unic, până la redenumirea stărilor. 2: uneori sunt necesare $2^n$ stări (de ex. „al $n$-lea simbol de la sfârșit e $1$”).', NOU, 'lr-conversii')
af(R, 'medie', r'Dacă $L$ e regulat, atunci $L^*$ e regulat.', r'Dacă $L^*$ e regulat, atunci $L$ e regulat.', True, False,
   r'2: $L = \{a^p \mid p \text{ prim}\}$ nu e regulat, dar $L^* = \{e\} \cup \{a^k \mid k \geq 2\}$ e regulat.', NOU, 'lr-inchidere')
af(R, 'medie', r'Dacă $L_1L_2$ e regulat, atunci $L_1$ și $L_2$ sunt regulate.', r'Dacă $L_1$ și $L_2$ sunt regulate, atunci $L_1 \setminus L_2$ e regulat.', False, True,
   r'1: $L_1$ neregulat oarecare, $L_2 = \emptyset$: $L_1L_2 = \emptyset$. 2: $L_1 \cap \overline{L_2}$.', NOU, 'lr-inchidere')
g(R, 'medie', r'Câte cuvinte de lungime 3 conține $L((a \cup b)^*a(a \cup b))$ (al doilea simbol de la sfârșit e $a$)?', '4', ['2', '3', '8'],
  r'Primul simbol e oricare (2 variante), al doilea e $a$, ultimul oricare (2): $2 \cdot 1 \cdot 2 = 4$.', NOU, 'lr-reprezentare')
g(R, 'grea', r'Câte stări are AFD-ul minim pentru „al doilea simbol de la sfârșit este $a$” peste $\{a, b\}$?', '4', ['2', '3', '8'],
  r'Automatul ține minte ultimele două simboluri: $aa, ab, ba, bb$, toate distinguibile (cu continuarea $e$ sau un simbol). În general, pentru al $n$-lea de la sfârșit: $2^n$ stări.', NOU, 'lr-conversii')

# =====================================================================================
# 12. LIC, gramatici, APD
# =====================================================================================
C = CGC
_GRAM = r'Fie $\Sigma = \{a, b, c\}$ și $G$ gramatica cu regulile: $S \to AX \mid YC$, $A \to aA \mid e$, $C \to cC \mid e$, $X \to bXc \mid e$, $Y \to aYb \mid e$. '
g(C, 'medie', _GRAM + r'Mulțimea șirurilor terminale derivabile din $X$, $\{w \in \Sigma^* \mid X \Rightarrow^* w\}$, este:', 'nicio variantă',
  [r'$L(b^*c^*)$', r'$\emptyset$, pentru că $X$ nu este simbol de start', r'șirurile cu număr impar de $b$'],
  r'Din $X$ se obține $\{b^nc^n \mid n \geq 0\}$: nu e $b^*c^*$ (lipsește $bcc$), nu e vidă (derivarea poate porni din orice neterminal) și nu are mereu număr impar de $b$.', G1, 'lic-gramatici')
g(C, 'ușoară', _GRAM + r'Mulțimea șirurilor terminale derivabile din $C$ este:', r'$L(c^*)$',
  [r'$\emptyset$, pentru că $C$ nu este simbol de start', 'șirurile cu număr par de $c$', 'șirurile cu număr impar de $c$'], r'$C \to cC \mid e$ dă $c^n$, $n \geq 0$.', G1, 'lic-gramatici')
gm(C, 'medie', _GRAM + 'Care dintre următoarele șiruri pot fi derivate din $S$ în zero sau mai mulți pași?', [r'$abcabc$', r'$aaAbXc$', r'$aaba$', r'$aabbbc$'], [1],
   r'$S \Rightarrow AX \Rightarrow aAX \Rightarrow aaAX \Rightarrow aaAbXc$ (o formă propozițională poate conține neterminale). $L(G) = a^*\{b^nc^n\} \cup \{a^nb^n\}c^*$, iar $abcabc$, $aaba$, $aabbbc$ nu au această formă.', G1, 'lic-gramatici')
g(C, 'medie', _GRAM + r'Cum este $L(G)$ în cel mai strict sens?', 'independent de context, dar nu regulat',
  ['finit', 'regulat', 'cu un număr impar de elemente'],
  r'$L(G) = \{a^ib^nc^n\} \cup \{a^nb^nc^k\}$. Nu e regulat: $L(G) \cap b^+c^+ = \{b^nc^n \mid n \geq 1\}$.', G1, 'lic-gramatici')
gm(C, 'grea', r'Fie $G$ cu regulile $S \to AX \mid YC$, $A \to aA \mid e$, $B \to bB \mid e$, $C \to cC \mid e$, $X \to bXc \mid bB \mid cC$, $Y \to aYb \mid aA \mid bB$. Ce secvențe pot fi derivate din $S$ în 0 sau mai mulți pași?',
   [r'$aaAbXc$', r'$aabbcc$', r'$aaacccc$', r'$aaba$'], [0, 2],
   r'$S \Rightarrow AX \Rightarrow^* aaAX \Rightarrow aaAbXc$. $aaacccc$: $A \Rightarrow^* aaa$, $X \Rightarrow cC \Rightarrow^* cccc$. $aabbcc$ ar cere din $X$ exact $bbcc$, dar $X$ se oprește doar cu $bB$ sau $cC$, care strică echilibrul ($bbXcc$ dă cel puțin 5 simboluri); din $YC$ ar cere $aabb$ din $Y$, imposibil la fel. $aaba$ nu are forma.', TGE, 'lic-gramatici')
g(C, 'medie', r'Fie $G$ cu regulile $S \to SS \mid aAB \mid BB$, $A \to a \mid A \mid AAB \mid e$, $B \to bB \mid AS \mid SAA$. Ce limbaj generează $G$?', r'$L(G) = \emptyset$',
  [r'$L(G) = \{e\}$', r'$L(G) = L((a \cup b)^*)$', r'$L(G) = \{w \mid \#_a(w) > \#_b(w)\}$'],
  r'$B$ nu poate deriva un șir terminal: fiecare regulă a lui $B$ conține $B$ sau $S$. Fiecare regulă a lui $S$ conține $S$ sau $B$. Deci $S$ e neproductiv: limbajul e vid.', G1, 'lic-gramatici')
g(C, 'medie', r'Fie $G$: $S \to 0S1 \mid SS \mid S_1 \mid S_2$, $S_1 \to 0 \mid 1$, $S_2 \to e$. Ce limbaj generează?', r'$L((0 \cup 1)^*)$',
  [r'$\{0^n1^n \mid n \geq 0\}$', r'$L(0 \cup 1)$', r'$\{(0^{n_i}1^{n_i})^k\}$'],
  r'$S \to SS$ și $S \to 0 \mid 1$ (prin $S_1$) generează orice șir nevid, iar $S \to e$ (prin $S_2$) și pe $e$.', TG1, 'lic-gramatici')
g(C, 'medie', r'Fie $G$ cu $S \to S_1S_2$, $S_1 \to aS_1b \mid e$, $S_2 \to bS_2a \mid e$. Ce este întotdeauna adevărat?', 'cuvintele din $L(G)$ au lungime pară',
  ['cuvintele din $L(G)$ conțin mai multe $a$ decât $b$', 'cuvintele din $L(G)$ se termină în $a$', r'$L(G) = \{a^nb^{2n}a^n \mid n \geq 0\}$'],
  r'$L(G) = \{a^nb^nb^ma^m\}$: lungimea $2n + 2m$. Numărul de $a$ e egal cu cel de $b$; $e \in L(G)$; $n \neq m$ e permis.', GE, 'lic-gramatici')
g(C, 'medie', r'Fie $G$ cu regulile $S \to \# \mid ASA$, $A \to 0 \mid 1$. Alegeți varianta corectă:', r'$L(G) = \{w\#x \mid w, x \in \{0,1\}^*,\ |w| = |x|\}$',
  [r'$L(G) = \{w\#w^R \mid w \in \{0,1\}^*\}$', r'$L(G) = \{w\#w^c\}$, unde $w^c$ e complementul lui $w$', 'nicio variantă'],
  r'Fiecare aplicare a lui $S \to ASA$ pune un simbol oarecare în stânga și unul oarecare în dreapta: lungimile sunt egale, simbolurile independente.', GE, 'lic-gramatici')
g(C, 'grea', r'Fie $G$ cu regulile $S \to 1B1 \mid 0B0 \mid ASA$, $B \to ABA \mid \#$, $A \to 0 \mid 1$. Alegeți varianta corectă ($x^R$ = răsturnatul, $x^c$ = complementul binar):',
  r'$L(G) = \{w\#x \mid w, x \in \{0,1\}^*,\ |w| = |x|,\ x \neq (w^R)^c\}$',
  [r'$L(G) = \{w\#w^R \mid w \in \{0,1\}^*\}$', r'$L(G) = \{w\#w^c \mid w \in \{0,1\}^*\}$', 'nicio variantă'],
  r'Un cuvânt are forma $u\,c\,x\#y\,c\,v$ cu $|u| = |v|$, $|x| = |y|$ și același bit $c$ de două ori. Cu $n = |w|$: există o poziție $i$ cu $w_i = x_{n-1-i}$, adică $x$ nu e complementul răsturnatului lui $w$. Verificat pe toate cuvintele de lungime $\leq 9$.', GE, 'lic-gramatici')
g(C, 'medie', r'Fie $L_1 = \{a^nb^m \mid n = 2m,\ n, m > 0\}$ și $L_2 = \{b^mc^k \mid k = 2m,\ m, k > 0\}$. Cum este $L_3 = L_1L_2$ în cel mai strict sens?', 'LIC',
  ['LR', 'nu este LIC', r'$L_3 = \Sigma^*$'],
  r'LIC sunt închise la concatenare: $S \to S_1S_2$. $L_3 = \{a^{2m}b^{m+p}c^{2p} \mid m, p \geq 1\}$ nu e regulat: în $a^{2m}b^{m+1}c^2$, numărul de $b$-uri e legat de cel de $a$-uri, iar pomparea $a$-urilor strică legătura.', G1, 'lic-bonus')
g(C, 'medie', r'Fie $L_1 = \{w \in \{0,1\}^* \mid \#_1(w) \text{ și } \#_0(w) \text{ pare}\}$ și $L_2 = \{0^n1^n \mid n \geq 0\}$. Cum este $L_1 \cap L_2$?', 'independent de context',
  ['regulat', 'finit', 'nicio variantă'],
  r'$L_1 \cap L_2 = \{0^n1^n \mid n \text{ par}\}$: intersecția unui LIC cu un LR e LIC; nu e regulat.', G1, 'lic-bonus')
g(C, 'medie', r'Fie $L_1 \in LR$, $L_2 \in LIC$, $L_3 \notin LIC$, $L_4 = L_1 \cap \{a^nb^n \mid n \text{ par}\}$ și $L_5 = (L_1 \cap L_2) \cup (L_3 \cap \emptyset) \cup (L_4 \cap \Sigma^*)$. Cum este $L_5$, în general?', 'LIC',
  ['LR', 'nu e LIC', r'$L_5 = \emptyset$'],
  r'$L_3 \cap \emptyset = \emptyset$ și $L_4 \cap \Sigma^* = L_4$. $L_1 \cap L_2$ și $L_4$ sunt LIC (LR ∩ LIC), iar reuniunea a două LIC e LIC.', G1, 'lic-bonus')
g(C, 'medie', r'Fie $G_1 = (V_1, \Sigma, R_1, S_1)$ și $G_2 = (V_2, \Sigma, R_2, S_2)$ două GIC. Ce regulă putem adăuga pentru a obține o gramatică pentru $L(G_1) \cap L(G_2)$?', 'niciuna dintre variante',
  [r'$S \to S_1S_2$', r'$S \to S_1 \mid S_2 \mid SS$', r'$S \to S_1S_2 \mid S_2S_1 \mid SS$'],
  r'LIC nu sunt închise la intersecție ($\{a^nb^nc^m\} \cap \{a^mb^nc^n\} = \{a^nb^nc^n\}$), deci nu există o construcție generală. $S \to S_1 \mid S_2$ ar da reuniunea, $S \to S_1S_2$ concatenarea.', G1, 'lic-bonus')
g(C, 'ușoară', r'Fie $L \in LIC$. Cum este $L^R$?', r'$\forall L \in LIC \Rightarrow L^R \in LIC$',
  [r'$\exists L \in LIC \Rightarrow L^R \notin LIC$', r'$\forall L \in LIC \Rightarrow L^R \in LR$', r'$L^R$ este întotdeauna finit'],
  'Se răstoarnă partea dreaptă a fiecărei reguli.', G1, 'lic-bonus')
af(C, 'medie', r'Se poate scrie o infinitate de expresii regulate pentru $L = \{w \in \{0,1\}^* \mid w = w^R\}$.', 'Se poate scrie o infinitate de gramatici independente de context pentru același $L$.', False, True,
   'Palindroamele peste $\\{0,1\\}$ nu sunt regulate, deci nu au nicio ER. Gramatici: o infinitate (se adaugă neterminale inutile).', G1, 'lic-gramatici')
g(C, 'ușoară', r'Câte automate push-down se pot scrie pentru $L = \{a\}$?', 'o infinitate', ['niciunul', '1', '4'],
  'Ca la orice limbaj acceptat de un model de calcul: se pot adăuga stări sau simboluri de stivă inutile.', G1, 'lic-apd')
g(C, 'medie', r'Fie $\Sigma = \{a, b, c\}$ și $L = \{xcycz \mid x, y, z \in \{a,b\}^*,\ x \text{ palindrom},\ |y| \geq 700\}$. Cum este $L$ în cel mai strict sens?', 'LIC',
  ['LR', 'limbaj finit', 'nu se poate spune'],
  r'$x$ e chiar prefixul dinaintea primului $c$, deci $L$ cere un palindrom la început: nu e regulat (intersectat cu $a^*ba^*c\{a,b\}^{700}c$ dă $a^nba^n\cdots$). APD: verifică palindromul cu stiva, apoi numără 700 de simboluri cu stări.', G1, 'lic-bonus')
g(C, 'medie', r'Fie $\Sigma = \{0, 1, 2\}$ și $L = \{x2y2z \mid x, y, z \in \{0,1\}^*,\ y \text{ palindrom},\ |z| \leq 400\}$. Cum este $L$ în cel mai strict sens?', 'LIC',
  ['LR', 'limbaj finit', 'nu se poate spune'], r'$y$ e exact porțiunea dintre cei doi de $2$: un palindrom nemărginit, deci nu e regulat; e LIC.', G1, 'lic-bonus')
g(C, 'ușoară', r'Fie $L = \{a^nb^na^mb^m \mid m, n \geq 0\}$. $L$ este un:', 'limbaj independent de context',
  ['limbaj regulat', 'limbaj dependent de context (și nu independent)', 'nu se poate preciza'], r'Concatenarea a două copii ale lui $\{a^nb^n\}$: $S \to TT$, $T \to aTb \mid e$.', TG1, 'lic-bonus')
g(C, 'ușoară', r'Fie $\Sigma = \{a, b\}$ și $L = \{ww \mid w \in \Sigma^*\}$. Cum este $L$?', 'nu este independent de context',
  ['finit', 'regulat, dar nu finit', 'independent de context, dar nu regulat'],
  r'Pompare pentru LIC pe $a^pb^pa^pb^p$: porțiunea pompată ($|vxy| \leq p$) nu poate modifica simetric ambele jumătăți. (Spre deosebire de $ww^R$, care e LIC.)', TG1, 'lic-bonus')
g(C, 'ușoară', r'Fie $L = \{w \in \{0,1\}^* \mid w = uu\}$. Alegeți varianta corectă:', 'nu se poate construi un APD pentru $L$',
  ['se poate construi un APD determinist pentru $L$', '$L$ este finit', 'nicio variantă'], r'$\{uu\}$ nu e LIC, iar APD-urile acceptă exact LIC.', TG2, 'lic-apd')
g(C, 'medie', r'Fie $L = \{w \in \{a,b\}^* \mid w = w^R \wedge \#_a(w) = \#_b(w)\}$ (palindroamele cu tot atâtea $a$ cât $b$). Alegeți varianta corectă:', 'L nu poate fi generat de o GIC și nu poate fi acceptat de un APD',
  ['L poate fi generat de o GIC și acceptat de un APD', 'L poate fi generat de o GIC, dar nu are APD', 'L are APD, dar nu poate fi generat de o GIC'],
  r'Pompare pe $a^pb^{2p}a^p$: orice pompare strică fie palindromul, fie egalitatea numerelor. GIC și APD descriu aceeași clasă, deci variantele „doar unul” sunt mereu false.', TG2, 'lic-bonus')
g(C, 'medie', r'Fie $M$ un APD care, indiferent de intrare, nu are niciodată mai mult de 176 de simboluri pe stivă. Alegeți varianta corectă:', r'$L(M)$ este regulat',
  [r'$L(M)$ este independent de context, dar nu regulat', r'$L(M)$ nu este independent de context', 'niciuna dintre variante'],
  r'Conținutul stivei e unul dintre finit de multe șiruri de lungime $\leq 176$: poate fi inclus în stare. Rezultă un automat finit.', TG2, 'lic-apd')
g(C, 'medie', 'Fie $L$ acceptat de un automat cu un număr finit de stări și un contor care poate fi incrementat, decrementat și testat la 0. Cum este $L$ în cel mai strict sens?', 'independent de context',
  ['Turing decidabil', 'nu este independent de context', 'nu se poate afirma nimic'],
  'Contorul e o stivă cu un singur simbol (plus un marcaj de fund pentru testul la 0): un APD.', G2, 'lic-apd')
af(C, 'medie', 'Orice LIC poate fi acceptat de un APD cu o singură stare finală, care acceptă cu stiva vidă.', 'Intersecția a două limbaje independente de context nu este niciodată independentă de context.', True, False,
   r'1: convenția din curs (stare finală și stivă vidă), cu toate finalele legate de o finală nouă. 2: $L \cap L = L$ e LIC.', G2, 'lic-apd')
g(C, 'medie', r'Fie $x$ și $y$ șiruri și $mix(x, y)$ mulțimea șirurilor $z$ cu $|z| = |x| + |y|$ în care $x$ și $y$ apar ca subsecvențe disjuncte (amestecul lor). $mix(L_1, L_2) = \{z \mid \exists x \in L_1, y \in L_2,\ z \in mix(x, y)\}$. Dacă $L_1$ e regulat și $L_2$ e independent de context, cum este $mix(L_1, L_2)$?', 'independent de context',
  ['nu este independent de context', 'nu este definit corect', 'nu se poate afirma nimic'],
  'APD-ul pentru $L_2$ și AFD-ul pentru $L_1$ rulează în paralel; la fiecare simbol, se ghicește (nedeterminist) cui îi aparține. Stiva e folosită doar de APD.', G2, 'lic-bonus')
g(C, 'medie', r'Fie $k > 0$ și $G_k$ gramaticile cu reguli $u \to v$, $u \in (V - \Sigma)^*$, $|u| \leq k$, $v \in V^*$. Ce clasă de limbaje corespunde lui $G_1$?', 'limbaje independente de context',
  ['limbaje dependente de context', 'limbaje Turing acceptate', 'nu se poate afirma nimic'],
  'Cu $|u| \\leq 1$, partea stângă e un singur neterminal: exact forma regulilor unei GIC.', G2, 'lic-gramatici')
g(C, 'ușoară', r'Mulțimea limbajelor independente de context peste $\Sigma = \{i\}$ este:', 'infinit numărabilă',
  ['finită', 'nenumărabilă', 'nu se poate afirma nimic'], r'Fiecare LIC are o gramatică (un șir finit): numărabile. Sunt infinit de multe ($\{i^n\}$ pentru orice $n$).', TGE, 'lic-bonus')
g(C, 'medie', r'Fie $Y = \{L(M) \mid M = (K, \Sigma, \Gamma, \Delta, s, F) \in APD,\ |\Gamma| = 1\}$. Alegeți afirmația corectă:', r'$\exists L \in LIC,\ L \notin Y$',
  [r'$\forall L \in Y,\ L \in LR$', 'mulțimea $Y$ e finită', r'$\exists L \in LR,\ L \notin Y$'],
  r'Cu un singur simbol, stiva e un contor fără test de fund: nu poate recunoaște, de exemplu, palindroamele. Dar $\{a^nb^n\} \in Y$ (deci nu doar LR), iar orice LR e în $Y$ (APD-ul nu folosește stiva).', TGE, 'lic-apd')
af(C, 'medie', r'Dacă $L \subseteq L(0^*)$, atunci $L \in LIC$.', r'Dacă $L \in LIC$ și $R \in LR$, atunci $\overline{L \cup R} \notin LIC$.', False, False,
   r'1: $\{0^{n^2}\}$ nu e LIC. 2: $L = R = \Sigma^*$: complementul e $\emptyset$, LIC.', TGE, 'lic-bonus')
af(C, 'medie', r'Dacă $L \in LIC$ și $R \in LR$, atunci $\overline{L \cup R} \notin LIC$.', r'Dacă $L \in LIC$ și $R \in LR$, atunci $R \setminus L \in LIC$.', False, False,
   r'1: ca mai sus. 2: $R \setminus L = R \cap \overline{L}$, iar complementul unui LIC poate să nu fie LIC (de ex. $R = \Sigma^*$).', TGE, 'lic-bonus')

# --- noi
g(C, 'ușoară', 'Limbajele independente de context NU sunt închise în raport cu:', 'intersecția',
  ['reuniunea', 'concatenarea', 'steaua Kleene'], r'$\{a^nb^nc^m\} \cap \{a^mb^nc^n\} = \{a^nb^nc^n\}$, care nu e LIC.', NOU, 'lic-bonus')
g(C, 'ușoară', 'Limbajele independente de context NU sunt închise în raport cu:', 'complementul',
  ['reuniunea', 'intersecția cu un limbaj regulat', 'răsturnarea'],
  r'Dacă ar fi, din $L_1 \cap L_2 = \overline{\overline{L_1} \cup \overline{L_2}}$ ar fi închise și la intersecție.', NOU, 'lic-bonus')
g(C, 'medie', 'O gramatică independentă de context este ambiguă dacă:', 'există un cuvânt cu doi arbori de derivare diferiți',
  ['există un cuvânt cu două derivări diferite', 'generează un limbaj care nu e regulat', 'are două reguli cu aceeași parte stângă'],
  r'Derivări diferite pot avea același arbore (stânga vs. dreapta). Ambiguitatea înseamnă doi arbori, echivalent două derivări **stângi** diferite.', NOU, 'lic-gramatici')
g(C, 'medie', r'Gramatica $S \to SS \mid a$ este:', 'ambiguă',
  ['neambiguă', 'neambiguă, dar limbajul ei e inerent ambiguu', 'nu e independentă de context'],
  r'$aaa$ are doi arbori: $(aa)a$ și $a(aa)$. Limbajul $a^+$ are însă o gramatică neambiguă: $S \to aS \mid a$.', NOU, 'lic-gramatici')
g(C, 'medie', 'În forma normală Chomsky, regulile au forma:', r'$A \to BC$ sau $A \to a$ (și eventual $S \to e$)',
  [r'$A \to aB$ sau $A \to a$', r'$A \to aBC$ sau $A \to e$', r'$A \to w$ cu $|w| \leq 2$, oricare ar fi $w$'],
  r'Două neterminale sau un terminal; $S \to e$ doar dacă $e \in L$, cu $S$ care nu apare în dreapta.', NOU, 'lic-gramatici')
g(C, 'grea', r'Un cuvânt de lungime $n \geq 1$ se derivă într-o gramatică în forma normală Chomsky în exact câți pași?', r'$2n - 1$',
  [r'$n$', r'$2n$', r'$n^2$'], r'$n - 1$ aplicări ale regulilor $A \to BC$ (fiecare crește numărul de simboluri cu 1) și $n$ aplicări ale regulilor $A \to a$.', NOU, 'lic-gramatici')
g(C, 'medie', 'Care problemă este decidabilă pentru o GIC $G$?', r'dacă $L(G) = \emptyset$',
  [r'dacă $L(G) = \Sigma^*$', 'dacă $G$ este ambiguă', r'dacă $L(G)$ e regulat'],
  'Vidarea se decide marcând neterminalele productive. Universalitatea, ambiguitatea și regularitatea sunt nedecidabile pentru GIC.', NOU, 'lic-algoritmice')
g(C, 'medie', r'Algoritmul CYK decide dacă $w \in L(G)$, pentru $G$ în FNC, în timp:', r'$O(n^3)$ (pentru $|w| = n$)',
  [r'$O(n)$', r'$O(2^n)$', 'nu se termină întotdeauna'], 'Tabelul are $O(n^2)$ celule, fiecare calculată din $O(n)$ împărțiri ale subșirului.', NOU, 'lic-algoritmice')
g(C, 'medie', 'În cursul de LFA, un automat push-down acceptă un cuvânt dacă:', 'după citirea întregului cuvânt ajunge într-o stare finală cu stiva vidă',
  ['ajunge într-o stare finală, indiferent de stivă', 'stiva se golește, indiferent de stare', 'citește cel puțin un simbol și stiva nu e vidă'],
  'Convenția Lewis–Papadimitriou: ambele condiții. Celelalte variante (doar stare finală, doar stivă vidă) dau aceeași clasă de limbaje, dar alte automate.', NOU, 'lic-apd')
g(C, 'grea', 'Care limbaj este independent de context, dar nu poate fi acceptat de un APD determinist?', r'$\{ww^R \mid w \in \{a,b\}^*\}$',
  [r'$\{a^nb^n \mid n \geq 0\}$', r'$\{wcw^R \mid w \in \{a,b\}^*\}$', r'$L(a^*b^*)$'],
  r'Fără marcajul $c$ la mijloc, automatul trebuie să ghicească mijlocul: e nevoie de nedeterminism. $\{wcw^R\}$ și $\{a^nb^n\}$ au APD determinist.', NOU, 'lic-apd')
g(C, 'medie', r'Lema de pompare pentru LIC descompune $w = uvxyz$ cu:', r'$|vxy| \leq p$ și $|vy| \geq 1$',
  [r'$|uv| \leq p$ și $|y| \geq 1$', r'$|vxy| \geq p$ și $|x| \geq 1$', r'$|v| = |y|$'],
  r'Și $uv^ixy^iz \in L$ pentru orice $i \geq 0$. $v$ și $y$ sunt pompate **simultan**, de același număr de ori.', NOU, 'lic-bonus')
af(C, 'ușoară', 'Orice limbaj regulat este independent de context.', 'Orice limbaj independent de context este regulat.', True, False, r'$LR \subsetneq LIC$: $\{a^nb^n\}$ e LIC, nu LR.', NOU, 'lic-bonus')
af(C, 'medie', 'Intersecția unui limbaj independent de context cu un limbaj regulat este independentă de context.', 'Reuniunea a două limbaje independente de context este independentă de context.', True, True,
   r'1: produsul dintre APD și AFD (stiva e a APD-ului). 2: $S \to S_1 \mid S_2$.', NOU, 'lic-bonus')
g(C, 'medie', r'Care gramatică generează $\{a^nb^n \mid n \geq 1\}$?', r'$S \to aSb \mid ab$',
  [r'$S \to aSb \mid e$', r'$S \to aS \mid Sb \mid ab$', r'$S \to aSbS \mid e$'],
  r'$S \to aSb \mid e$ generează și $e$. $S \to aS \mid Sb \mid ab$ dă $a^+b^+$ cu numere oarecare. $S \to aSbS \mid e$ dă cuvintele bine parantezate.', NOU, 'lic-gramatici')
g(C, 'medie', r'Ce limbaj generează $S \to aSbS \mid e$?', 'cuvintele „bine parantezate” peste $\\{a, b\\}$ ($a$ = deschide, $b$ = închide)',
  [r'$\{a^nb^n \mid n \geq 0\}$', r'$\{w \mid \#_a(w) = \#_b(w)\}$', r'$L((ab)^*)$'],
  r'Fiecare $a$ se închide cu $b$-ul lui, iar după el urmează alt cuvânt bine parantezat. $abab$, $aabb$, $aababb$ sunt generate; $ba$ (cu tot atâtea $a$ cât $b$) nu.', NOU, 'lic-gramatici')

# =====================================================================================
# 13. Turing și decidabilitate
# =====================================================================================
T = CGT
g(T, 'medie', r'Fie $L = \{\rho(M) \mid \forall w \in \Sigma^*,\ |w| < 100,\ M \text{ execută exact 5 tranziții cu } w \text{ la intrare}\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['Turing acceptat', 'nu e Turing acceptat', 'nu există un astfel de limbaj'],
  r'Sunt finit de multe cuvinte cu $|w| < 100$; pentru fiecare se simulează cel mult 6 pași (ca să vedem dacă se oprește exact după 5). Simularea se termină mereu.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M) \mid \forall w,\ |w| < 40,\ M \text{ execută mai puțin de 5 tranziții cu } w\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['Turing acceptat', 'nu e Turing acceptat', 'nu există un astfel de limbaj'],
  'Pentru fiecare dintre cele finit multe cuvinte, simularea a 5 pași spune dacă mașina s-a oprit înainte. Număr mărginit de pași: decidabil.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M) \mid \forall w,\ |w| < 40,\ M \text{ se termină și execută mai mult de 5 tranziții cu } w\}$. Cum este $L$ în cel mai strict sens?', 'Turing acceptat',
  ['Turing decidabil', 'nu e Turing acceptat', 'nu există un astfel de limbaj'],
  'Trebuie verificat că mașina **se oprește** pe fiecare cuvânt: se simulează pe rând (sunt finit multe) și se acceptă când toate s-au oprit. Dacă una nu se oprește, simularea nu se termină: acceptat, nu decidabil.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1, L_2 \in TA$ cu $L_1 = \Sigma^* \setminus L_2$. Ce se poate spune despre $L_3 = L_1 \cap L_2$ (cel mai strict)?', 'Turing decidabil',
  ['Turing acceptat', 'nu este Turing acceptat', 'nicio variantă'],
  r'$L_1 \cap L_2 = \emptyset$, decidabil. (În plus, $L_1$ și complementul lui sunt TA, deci ambele sunt TD.)', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1, L_2 \in TA$ cu $L_2 = \Sigma^* \setminus L_1$. Ce se poate spune despre $L_3 = L_1L_2$ (cel mai strict)?', 'Turing decidabil',
  ['Turing acceptat', 'nu este Turing acceptat', 'nicio variantă'],
  r'Un limbaj TA cu complement TA e decidabil, deci $L_1, L_2 \in TD$. Concatenarea a două limbaje decidabile e decidabilă (se încearcă toate cele $|w| + 1$ tăieturi).', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1 \notin TA$ și $L_2 \in TA$. Ce se poate afirma întotdeauna despre $L_1 \cap L_2$?', 'nicio variantă',
  ['Turing acceptat', 'Turing decidabil', 'nu este Turing acceptat'],
  r'Cu $L_2 = \emptyset$: $\emptyset$, decidabil. Cu $L_2 = \Sigma^*$: $L_1$, neacceptat.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1 \notin TD$ și $L_2 \in TD$. Cum este întotdeauna $L_1 \cap L_2$?', 'nicio variantă',
  ['Turing acceptat', 'Turing decidabil', 'nu este Turing acceptat'], r'Ca mai sus: $L_2 = \emptyset$ dă TD, $L_2 = \Sigma^*$ dă $L_1$.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1 \in TD$ și $L_2$ un limbaj cu $L_1 \setminus L_2 \in TD$. Cum este $L_2$ în cel mai strict sens?', 'nicio variantă',
  ['Turing decidabil', 'Turing acceptat', 'nu este Turing acceptat'],
  r'Cu $L_1 = \emptyset$, $L_1 \setminus L_2 = \emptyset$ pentru orice $L_2$: $L_2$ poate fi orice.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L_1 \in LIC$ și $L_2 \in TA$. Cum este întotdeauna $L_1 \cup L_2$?', 'Turing acceptat',
  ['Turing decidabil', 'independent de context', 'nu este Turing acceptat'],
  'LIC ⊆ TD ⊆ TA, iar TA e închisă la reuniune (se rulează ambele mașini în paralel).', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L_1 \in TD$ și $L_2 \in TA$. Cum este întotdeauna $L_1 \cup L_2$?', 'Turing acceptat',
  ['Turing decidabil', 'independent de context', 'nu este Turing acceptat'], 'Ambele sunt TA; reuniunea a două TA e TA. Nu neapărat TD ($L_1 = \\emptyset$).', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L_1 \in TD$ și $L_2 \in TA$. Cum este întotdeauna $L_1 \cap L_2$?', 'Turing acceptat',
  ['Turing decidabil', 'independent de context', 'nu este Turing acceptat'], r'Intersecția a două TA e TA. Nu neapărat TD ($L_1 = \Sigma^*$).', G2, 'mt-decidabil')
af(T, 'ușoară', 'Există un număr infinit numărabil de limbaje Turing acceptate.', 'Problema dacă o GIC generează șirul vid este decidabilă.', True, True,
   r'1: fiecare are o mașină (un șir finit); sunt infinit de multe. 2: se marchează neterminalele care derivă $e$.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{w \in \{a,b\}^* \mid w \text{ începe și se termină cu } a \text{ și este palindrom}\}$. Cum este $L$ în cel mai strict sens?', 'independent de context',
  ['Turing decidabil', 'Turing acceptat', 'nu este Turing acceptat'], r'$S \to aTa \mid a$, $T \to aTa \mid bTb \mid a \mid b \mid e$. Nu e regulat.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M) \mid M \text{ are 3 stări și 2 tranziții}\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['Turing acceptat', 'nu e Turing acceptat', 'nu putem accesa codificarea lui $M$, deci limbajul nu e valid'],
  'E o proprietate a **codului** mașinii, nu a limbajului ei: se citește codificarea și se numără. (Rice nu se aplică.)', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M) \mid M \text{ are 3 stări și 2 tranziții}\}$. Câte mașini Turing care decid $L$ se pot construi?', 'o infinitate',
  ['niciuna, limbajul nu e decidabil', '1', '3'], 'Orice limbaj decidabil e decis de o infinitate de mașini (stări inutile).', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(A)\rho(w) \mid A \in APD \text{ cu 3 stări și 2 tranziții, care acceptă } w\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['Turing acceptat', 'nu e Turing acceptat', 'un APD nu se poate codifica pentru o MT'],
  'Apartenența la un LIC e decidabilă (APD → GIC → FNC → CYK), iar condiția despre stări e sintactică.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M_1)\rho(M_2) \mid |L(M_1)| \geq 0 \wedge |L(M_2)| \geq 2\}$. Cum este $L$ în cel mai strict sens?', 'Turing acceptat',
  ['Turing decidabil', 'nu este Turing acceptat', 'nu se poate afirma nimic'],
  r'Prima condiție e mereu adevărată. „$M_2$ acceptă cel puțin 2 cuvinte” se semidecide (simulare în paralel pe toate cuvintele, până găsim 2 acceptate), dar nu se decide (Rice).', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(w)\rho(M_1)\cdots\rho(M_k) \mid k > 2,\ \text{majoritatea } M_i \text{ acceptă } w\}$. Cum este $L$ în cel mai strict sens?', 'Turing acceptat',
  ['Turing decidabil', 'nu e Turing acceptat', 'nu există un astfel de limbaj'],
  'Se simulează toate mașinile în paralel și se acceptă când mai mult de jumătate au acceptat. Nu se poate decide (ar decide acceptarea pentru o mașină).', G2, 'mt-decidabil')
g(T, 'grea', r'Fie $L = \{\rho(M_1)\cdots\rho(M_{23})\rho(w) \mid \text{exact 13 dintre } M_i \text{ acceptă } w\}$. Cum este $L$?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat, dar nu decidabil', 'finit'],
  r'„Exact” cere și ca celelalte 10 să **nu** accepte, o condiție de tip complement: se reduce $\overline{A_{TM}}$ (mașini care nu acceptă) la $L$.', TG2, 'mt-decidabil')
af(T, 'medie', 'O MT nedeterministă acceptă limbaje pe care o MT deterministă nu le poate accepta.', 'O MT cu $k$ benzi decide limbaje pe care o MT cu $k - 1$ benzi nu le poate decide ($k > 1$).', False, False,
   'Toate extensiile (nedeterminism, benzi multiple, mai multe capete) au aceeași putere: o MT deterministă cu o bandă le simulează (doar mai încet).', G2, 'mt-extensii')
af(T, 'medie', 'O MT nedeterministă cu 10 benzi acceptă limbaje pe care o MT deterministă nu le poate accepta.', 'Există un limbaj decis de o MT cu 4 benzi și 4 capete, dar nu de una cu 4 benzi și un cap.', False, False,
   'Aceeași teză: extensiile nu cresc puterea de calcul.', G2, 'mt-extensii')
g(T, 'ușoară', r'Un limbaj decis de o mașină Turing cu $k > 13$ benzi:', 'poate fi decis de o mașină Turing cu $k + 3$ benzi',
  ['nu poate fi acceptat de o MT cu $k + 1$ benzi', 'nu poate fi decis de o MT cu $k - 2$ benzi', 'niciuna dintre variante'],
  'Benzile în plus pot fi ignorate; benzile mai puține pot simula benzile în plus. Singura afirmație adevărată e prima.', TG2, 'mt-extensii')
g(T, 'ușoară', r'Un limbaj decis de o mașină Turing cu $h = 100$ capete de citire:', 'poate fi decis de o mașină Turing cu un singur cap',
  ['nu poate fi decis de o MT cu 2 capete', 'nu poate fi acceptat de o MT cu 3 capete', 'niciuna dintre variante'], 'Capetele multiple se simulează cu unul (cu marcaje pe bandă).', TG2, 'mt-extensii')
g(T, 'grea', r'Fie $L = \{\rho(A_1)\rho(A_2) \mid A_1, A_2 \in APD \wedge L(A_1) = L(A_2)\}$. Cum este $L$ în cel mai strict sens?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat', 'nu se poate afirma nimic'],
  r'Inegalitatea se semidecide (se caută un cuvânt pe care exact unul îl acceptă; apartenența la LIC e decidabilă), deci egalitatea e co-TA. Dacă ar fi și TA, ar fi decidabilă, dar egalitatea LIC e nedecidabilă.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M_1)\rho(M_2) \mid L(M_1) = L(M_2)\}$ ($M_i$ mașini Turing). Cum este $L$?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat', 'nu se poate afirma nimic'], 'Egalitatea limbajelor a două MT nu e nici acceptată, nici co-acceptată.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M)\rho(w) \mid M \text{ nu se oprește cu } w \text{ la intrare}\}$. Cum este $L$?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat, dar nu decidabil', 'finit'],
  'E complementul problemei opririi, care e acceptată, dar nu decidabilă. Dacă și complementul ar fi acceptat, oprirea ar fi decidabilă.', TG2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(G_1)\rho(G_2) \mid G_1, G_2 \in GIC \wedge L(G_1) \supseteq L(G_2)\}$. Cum este $L$?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat, dar nu decidabil', 'finit'],
  r'Neincluziunea se semidecide (un cuvânt din $L(G_2) \setminus L(G_1)$), deci incluziunea e co-TA și nedecidabilă: nu e TA.', TG2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M_1)\rho(M_2) \mid M_1 \in AFN \wedge M_2 \in AFD \wedge L(M_1) \subseteq L(M_2)\}$. Cum este $L$?', 'Turing decidabil',
  ['Turing acceptat, dar nu decidabil', 'nu este Turing acceptat', 'finit'], r'$L(M_1) \cap \overline{L(M_2)} = \emptyset$ se verifică efectiv pe automate.', TG2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M_1)\rho(M_2) \mid M_1, M_2 \in AFD \wedge L(M_1) = L(M_2)\}$. Cum este $L$?', 'Turing decidabil',
  ['Turing acceptat, dar nu decidabil', 'nu este Turing acceptat', 'finit'], 'Se minimizează ambele și se compară (sau diferența simetrică e vidă).', TG2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(G) \mid G \in GIC \wedge L(G) = \emptyset\}$. Cum este $L$?', 'Turing decidabil',
  ['Turing acceptat, dar nu decidabil', 'nu este Turing acceptat', 'finit'], 'Vidarea unei GIC e decidabilă: e vid dacă $S$ nu e productiv.', TG2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(G)\rho(w) \mid G \in GIC \wedge w \in L(G)\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['Turing acceptat', 'nu este Turing acceptat', 'nu se poate afirma nimic'], 'CYK (după aducerea la FNC) decide apartenența.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M)\rho(w) \mid M \text{ acceptă } w\}$. Cum este $L$?', 'Turing acceptat, dar nu Turing decidabil',
  ['Turing decidabil', 'nu este Turing acceptat', 'finit'], 'Mașina universală îl acceptă (simulează $M$ pe $w$). Nu e decidabil (diagonalizare).', TG2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(M_1)\rho(M_2)\rho(w) \mid M_1 \text{ sau } M_2 \text{ acceptă } w\}$. Cum este $L$?', 'Turing acceptat, dar nu Turing decidabil',
  ['Turing decidabil', 'nu este Turing acceptat', 'finit'], 'Se simulează ambele în paralel (pas cu pas, alternând).', TG2, 'mt-decidabil')
g(T, 'medie', r'Fie $\Sigma = \{0,1\}$ și $L = \{\rho(M) \mid \exists w \in \Sigma^*,\ M \text{ acceptă } w\}$. Cum este $L$?', 'Turing acceptat, dar nu Turing decidabil',
  ['Turing decidabil', 'nu este Turing acceptat', 'finit'], r'Simulare „în diagonală”: la pasul $k$, primele $k$ cuvinte câte $k$ pași. Nedecidabil (Rice: $L(M) \neq \emptyset$ e o proprietate netrivială).', TG2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M) \mid \forall w \in \Sigma^*,\ |w| > 10 \Rightarrow M \text{ acceptă } w\}$. Ce se poate spune despre $L$?', 'nu este Turing acceptat',
  ['Turing decidabil', 'Turing acceptat', 'este finit'], 'Condiția privește o infinitate de cuvinte, toate trebuind acceptate: nu se poate confirma într-un timp finit.', TGE, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M)\rho(w) \mid \text{există un șir mai lung decât } w \text{ pe care } M \text{ se oprește}\}$. Cum este $L$?', 'Turing acceptat',
  ['Turing decidabil', 'nu e Turing acceptat', 'nu există un astfel de limbaj'], 'Se caută în paralel pe toate șirurile mai lungi; dacă există unul, simularea îl găsește.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M)\rho(w_1)\rho(w_2) \mid M \text{ acceptă } w_1 \text{ în mai mult de 10 tranziții și acceptă } w_2 \text{ în mai puțin de 10}\}$. Cum este $L$?', 'Turing acceptat',
  ['Turing decidabil', 'nu e Turing acceptat', 'nu există un astfel de limbaj'], '$w_2$ se verifică în 10 pași; pentru $w_1$ trebuie așteptată acceptarea, care poate să nu vină.', G2, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(w)\rho(M) \mid w \in \{a,b\}^*,\ |w| = 10,\ M \text{ acceptă } w\}$. Cum este $L$?', 'Turing acceptat',
  ['Turing decidabil', 'nu e Turing acceptat', 'limbajul nu e valid'], 'Fixarea lungimii lui $w$ nu ajută: tot trebuie simulat $M$ pe $w$.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{\rho(w)\rho(M) \mid w \in \{a,b\}^*,\ |w| = 10,\ M \text{ are 3 stări și 2 tranziții}\}$. Cum este $L$?', 'Turing decidabil',
  ['Turing acceptat', 'nu e Turing acceptat', 'limbajul nu e valid'], 'Ambele condiții sunt sintactice.', G2, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L = \{a^nb^nc^n \mid n \geq 0\}$. Cum este $L$ în cel mai strict sens?', 'Turing decidabil',
  ['independent de context', 'Turing acceptat', 'nu e Turing acceptat'], 'Nu e LIC (pompare), dar o MT îl decide (numără sau tăie câte un simbol din fiecare bloc).', G2, 'mt-decidabil')
af(T, 'ușoară', 'Se poate decide dacă două AFD acceptă același limbaj.', 'Se poate decide dacă două MT acceptă același limbaj.', True, False,
   'Pentru AFD: minimizare și comparare. Pentru MT: nedecidabil (Rice).', G2, 'mt-decidabil')
af(T, 'medie', 'Mulțimea limbajelor Turing decidabile este închisă la intersecție.', 'Mulțimea limbajelor Turing acceptate este închisă la concatenare.', True, True,
   'TD: se rulează ambele. TA: se încearcă în paralel toate tăieturile.', TG2, 'mt-decidabil')
af(T, 'medie', 'Mulțimea limbajelor Turing decidabile este închisă la diferență.', 'Mulțimea limbajelor Turing acceptate este închisă la steaua Kleene.', True, True,
   r'TD: $A \setminus B = A \cap \overline{B}$. TA: nedeterminist se ghicește descompunerea și se verifică fiecare bucată.', TG2, 'mt-decidabil')
af(T, 'medie', 'Mulțimea limbajelor Turing decidabile este închisă la complement.', 'Mulțimea limbajelor Turing acceptate este închisă la complement.', True, False,
   'TD: se inversează răspunsul. TA: complementul problemei opririi nu e TA.', TG2, 'mt-decidabil')
af(T, 'medie', r'Dacă $L \in TD$, atunci întotdeauna $\overline{L} \in TD$.', r'Dacă $L \in TD$ și $L\' \subseteq L$, atunci întotdeauna $L\' \in TD$.', True, False,
   r'2: orice limbaj e submulțime a lui $\Sigma^* \in TD$.', GE, 'mt-decidabil')
af(T, 'medie', r'Dacă $L \in TA$, atunci întotdeauna $\overline{L} \in TA$.', r'Dacă $L \in TA$ și $L\' \subseteq L$, atunci întotdeauna $L\' \in TA$.', False, False,
   r'1: problema opririi. 2: $L = \Sigma^*$ și $L\'$ neacceptat.', GE, 'mt-decidabil')
g(T, 'ușoară', r'Fie $L$ un limbaj Turing decidabil. Alegeți varianta corectă:', r'$L$ și $\overline{L}$ sunt ambele Turing acceptate',
  [r'$L$ e Turing acceptat, dar $\overline{L}$ nu', r'$\overline{L}$ e Turing acceptat, dar $L$ nu', r'nici $L$, nici $\overline{L}$ nu sunt Turing acceptate'],
  r'$\overline{L}$ e și el decidabil, iar orice limbaj decidabil e acceptat.', TG2, 'mt-decidabil')
g(T, 'ușoară', 'Fie $L$ un limbaj regulat. Alegeți varianta corectă:', '$L$ este Turing decidabil',
  ['$L$ nu este Turing decidabil', '$L$ este Turing acceptat, dar nu decidabil', 'niciuna dintre celelalte variante'], 'LR ⊆ LIC ⊆ TD.', TG2, 'mt-decidabil')
g(T, 'ușoară', 'Fie $L$ independent de context și Turing decidabil. Alegeți afirmația adevărată:', '$L$ este Turing acceptat',
  ['$L$ nu este Turing acceptat', '$L$ este finit', 'nu se poate afirma nimic'], 'TD ⊆ TA.', TGE, 'mt-decidabil')
g(T, 'medie', r'Fie $L$ Turing acceptat și $L^R = \{w \mid w^R \in L\}$. Atunci $L^R$:', 'este Turing acceptat',
  ['este Turing decidabil', 'nu este Turing acceptat', 'nu se poate preciza'], 'Mașina răstoarnă întâi intrarea, apoi rulează mașina lui $L$.', TG2, 'mt-decidabil')
g(T, 'medie', 'Fie $L$ Turing acceptat și $PERMUTARI(L)$ limbajul obținut prin permutarea (literelor) cuvintelor din $L$. Cum este $PERMUTARI(L)$ în cel mai strict sens?', 'Turing acceptat',
  ['Turing decidabil', 'nu este Turing acceptat', 'nu se poate afirma nimic'], 'Pentru $w$, se încearcă în paralel toate permutările lui $w$ (finit multe) în mașina lui $L$.', GE, 'mt-decidabil')
g(T, 'grea', r'Fie $A, B$ Turing acceptate, cu $A \cup B = \Sigma^*$. Dacă $(A \cap \overline{B}) \cup (\overline{A} \cap B)$ este decidabil, ce se poate spune întotdeauna despre $A$ și $B$?', 'ambele sunt decidabile',
  ['niciunul nu este decidabil', 'exact unul este decidabil', 'nicio variantă'],
  r'Fie $D$ diferența simetrică. Cum $A \cup B = \Sigma^*$, $x \notin A \iff x \in B \wedge x \in D$, deci $\overline{A}$ e TA ($D$ decidabil, $B$ acceptat). $A$ și $\overline{A}$ TA, deci $A$ decidabil; la fel $B$.', GE, 'mt-decidabil')
g(T, 'medie', r'Fie $L = \{\rho(M)\rho(w_1)\rho(w_2) \mid M \text{ se oprește cu } w_1 \text{ sau cu } w_2\}$. Alegeți afirmația întotdeauna adevărată:', r'$L \notin TD$',
  [r'$L \in TD$', r'$L \notin TA$', 'L e acceptat doar de o MT cu 2 benzi'],
  r'E acceptat (simulare în paralel), dar nu decidabil: cu $w_1 = w_2$ ar decide oprirea.', GE, 'mt-decidabil')
g(T, 'ușoară', r'Fie $M_1$ și $M_2$ mașini Turing cu $L(M_2) \subseteq L(M_1)$. Atunci:', 'pentru orice intrare acceptată de $M_2$, $M_1$ se oprește',
  ['pentru orice intrare pe care $M_1$ nu se oprește, $M_2$ se oprește', 'pentru orice intrare acceptată de $M_1$, $M_2$ se oprește', 'pentru orice intrare pe care $M_2$ nu se oprește, nici $M_1$ nu se oprește'],
  r'Un cuvânt acceptat de $M_2$ e în $L(M_1)$, deci $M_1$ îl acceptă (se oprește în starea de acceptare).', TGE, 'mt-decidabil')
af(T, 'ușoară', r'Dacă $L \in LR$ și $L\'$ e Turing decidabil, atunci $L\'$ e Turing decidabil.', 'O MT nedeterministă poate decide limbaje pe care o MT deterministă nu le poate decide.', True, False,
   '1: concluzia e chiar ipoteza. 2: nedeterminismul nu crește puterea.', TGE, 'mt-extensii')
af(T, 'ușoară', r'Dacă $L$ este Turing acceptat, atunci complementul său este Turing acceptat.', r'Dacă $L \in LR$ și $L\'$ e Turing decidabil, atunci $L\'$ e Turing decidabil.', False, True,
   '1: problema opririi. 2: concluzia e ipoteza.', TGE, 'mt-decidabil')
g(T, 'medie', r'Fie $L_1 \cup L_2 \in TD$ și $L_1 \cap L_2 \in TD$. Alegeți afirmația întotdeauna adevărată:', r'există $L_1 \in TA$ astfel încât cerințele sunt satisfăcute',
  [r'$L_1, L_2 \in TD$', r'$L_1 \in TD \vee L_2 \in TD$', 'nu există două limbaje care să satisfacă cerințele'],
  r'De exemplu $L_1 = L_2 = \emptyset$. Dar nu rezultă că sunt decidabile: $L_1 = K$ (neacceptat), $L_2 = \overline{K}$ dau $\emptyset$ și $\Sigma^*$.', GE, 'mt-decidabil')

# --- noi
g(T, 'ușoară', 'Teorema lui Rice spune că este nedecidabilă orice proprietate:', 'netrivială a limbajului acceptat de o mașină Turing',
  ['a codului (descrierii) unei mașini Turing', 'a unui automat finit', 'a unei gramatici independente de context'],
  r'„Netrivială”: unele MT au proprietatea, altele nu. Proprietățile **codului** (număr de stări) sunt decidabile.', NOU, 'mt-decidabil')
g(T, 'ușoară', 'Un limbaj este decidabil dacă și numai dacă:', 'el și complementul lui sunt Turing acceptate',
  ['el este Turing acceptat', 'complementul lui e independent de context', 'e acceptat de o MT nedeterministă'],
  'Se rulează în paralel cele două mașini; exact una se oprește, iar ea dă răspunsul.', NOU, 'mt-decidabil')
af(T, 'ușoară', 'Orice limbaj independent de context este Turing decidabil.', 'Orice limbaj Turing decidabil este independent de context.', True, False, r'2: $\{a^nb^nc^n\}$.', NOU, 'mt-decidabil')
g(T, 'medie', 'Ierarhia corectă este:', r'$LR \subsetneq LIC \subsetneq TD \subsetneq TA$',
  [r'$LR \subsetneq TD \subsetneq LIC \subsetneq TA$', r'$LIC \subsetneq LR \subsetneq TD \subsetneq TA$', r'$LR \subsetneq LIC \subsetneq TA \subsetneq TD$'],
  r'Exemple de separare: $\{a^nb^n\}$ (LIC, nu LR), $\{a^nb^nc^n\}$ (TD, nu LIC), problema opririi (TA, nu TD).', NOU, 'mt-decidabil')
