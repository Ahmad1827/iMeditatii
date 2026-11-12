"""APD — Algoritmi Paraleli și Distribuiți: threads stepped by hand, every interleaving explored.

Topics from the APD lectures, labs and exams (seria CA/CC/CD): races and lost
updates, mutual exclusion, semaphores (ordering, hand-off), barriers,
deadlock, Amdahl, logical clocks, wave and election algorithms.

The values a program can end with are not trusted from here: 'values' is what
this file claims, and test/acs_courses_test.dart compares it with what the
app's explorer finds over every interleaving. The same test runs every
reference fix through the explorer, and checks the starter fails.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, write_course

C1 = '1. Curse și întrețeseri'
C2 = '2. Excludere mutuală'
C3 = '3. Semafoare și bariere'
C4 = '4. Blocaje'
C5 = '5. Paralel și distribuit: teorie'
CHAPTERS = [C1, C2, C3, C4, C5]
P = []
SYNC = re.compile(r'^(lock|unlock|P|V|acquire|release|await)\(')


def code(text):
    return '\n'.join(l.rstrip() for l in text.strip('\n').split('\n'))


def show(text):
    return '```\n' + code(text) + '\n```'


def outcomes(id, title, ch, diff, intro, prog, ask, values, hint, solution, source=''):
    st = f'{intro}\n\n{show(prog)}\n\nCare sunt **toate** valorile cu care se poate termina `{ask}`?'
    P.append(problem(id, title, ch, diff, st, 'threads', {'mode': 'outcomes', 'program': code(prog), 'ask': ask, 'values': sorted(values)}, hint, solution, source))


def schedule(id, title, ch, diff, intro, prog, hint, solution, goal=None, deadlock=False, source=''):
    want = 'toate firele rămase să fie blocate (deadlock)' if deadlock else 'programul să se termine cu ' + ', '.join(f'`{k} = {v}`' for k, v in goal.items())
    st = f'{intro}\n\n{show(prog)}\n\nRulează firele pas cu pas, în ordinea pe care o alegi, astfel încât {want}.'
    spec = {'mode': 'schedule', 'program': code(prog)}
    if deadlock:
        spec['goalDeadlock'] = True
    else:
        spec['goal'] = goal
    P.append(problem(id, title, ch, diff, st, 'threads', spec, hint, solution, source))


def fix(id, title, ch, diff, intro, prog, expect, reference, hint, solution='', forbid=(), source=''):
    keep, name = {}, None
    for line in code(prog).split('\n'):
        l = line.strip()
        m = re.match(r'thread\s+(\w+)', l)
        if m:
            name = m.group(1); keep[name] = []
        elif name and l and not SYNC.match(l.replace(' ', '')):
            keep[name].append(l.replace(' ', '').replace(';', ''))
    want = ', '.join(f'`{k} = {v}`' for k, v in expect.items())
    st = f'{intro}\n\n{show(prog)}\n\nSincronizează firele astfel încât, **în orice întrețesere**, programul să se termine (fără blocaj) cu {want}. Instrucțiunile date rămân; adaugi doar sincronizare.'
    if forbid:
        st += ' ' + {'lock': 'Fără lock-uri: folosește semafoare.', 'sem': 'Fără semafoare.'}[forbid[0]]
    spec = {'mode': 'fix', 'program': code(prog), 'expect': expect, 'keep': keep, 'reference': code(reference)}
    if forbid:
        spec['forbid'] = list(forbid)
    P.append(problem(id, title, ch, diff, st, 'threads', spec, hint, solution or 'O rezolvare:\n' + show(reference), source))


# ---------------------------------------------------------------- 1. curse
outcomes(1, 'Două incrementări', C1, 'ușoară',
         'Două fire incrementează aceeași variabilă. `x = x + 1` nu e atomică: firul citește `x`, apoi scrie înapoi valoarea citită plus 1.',
         '''
shared x = 0
thread A:
  x = x + 1
thread B:
  x = x + 1
''', 'x', [1, 2],
         'Ce se întâmplă dacă ambele fire citesc `x` înainte ca vreunul să scrie?',
         '`2` când un fir termină înainte să înceapă celălalt; `1` când amândouă citesc `0` și amândouă scriu `1` (o actualizare se pierde).')

outcomes(2, 'Câte două incrementări', C1, 'medie',
         'Fiecare fir incrementează variabila de două ori.',
         '''
shared x = 0
thread A:
  x = x + 1
  x = x + 1
thread B:
  x = x + 1
  x = x + 1
''', 'x', [2, 3, 4],
         'Poate ieși `1`? Fiecare fir scrie de două ori, iar a doua scriere a lui vine după prima lui.',
         '`4` fără suprapuneri, `3` cu o actualizare pierdută, `2` cu două. `1` nu se poate: ultimul fir care scrie a citit după prima lui scriere, deci cel puțin `1`, și scrie cel puțin `2`.')

outcomes(3, 'Înmulțire și adunare', C1, 'medie',
         'Un fir dublează variabila, celălalt o incrementează.',
         '''
shared x = 1
thread A:
  x = x * 2
thread B:
  x = x + 1
''', 'x', [2, 3, 4],
         'Trei cazuri: A întreg înaintea lui B, B întreg înaintea lui A, sau amândouă citesc `1`.',
         '`A` apoi `B`: `1·2 + 1 = 3`. `B` apoi `A`: `(1+1)·2 = 4`. Amândouă citesc `1`: și `A`, și `B` vor să scrie `2`, deci `2`.')

outcomes(4, 'Trei fire, o variabilă', C1, 'grea',
         'Două fire scriu constante, al treilea adună 10 la ce găsește.',
         '''
shared x = 0
thread A:
  x = 1
thread B:
  x = 2
thread C:
  x = x + 10
''', 'x', [1, 2, 10, 11, 12],
         'Valoarea finală e cea scrisă ultima. Dacă ultimul scrie `C`, contează ce citise: `0`, `1` sau `2`.',
         'Ultimul scrie `A`: `1`. Ultimul scrie `B`: `2`. Ultimul scrie `C`: `10`, `11` sau `12`, după ce a apucat să citească.')

outcomes(5, 'Lock-ul nu alege ordinea', C2, 'ușoară',
         'Cele două actualizări sunt acum protejate de același lock.',
         '''
shared x = 0
lock m
thread A:
  lock(m)
  x = x + 1
  unlock(m)
thread B:
  lock(m)
  x = x * 2
  unlock(m)
''', 'x', [1, 2],
         'Secțiunile critice nu se mai suprapun, dar oricare dintre fire poate intra primul.',
         '`A` apoi `B`: `(0+1)·2 = 2`. `B` apoi `A`: `0·2 + 1 = 1`. Excluderea mutuală elimină actualizările pierdute, nu și nedeterminismul ordinii.')

outcomes(6, 'Semaforul impune ordinea', C3, 'ușoară',
         'Semaforul `s` pornește de la 0.',
         '''
shared x = 0
sem s = 0
thread A:
  P(s)
  x = x * 2
thread B:
  x = x + 3
  V(s)
''', 'x', [6],
         '`A` nu poate trece de `P(s)` până când `B` nu face `V(s)`.',
         '`B` rulează întreg înaintea lui `A`: `(0+3)·2 = 6`. E singura valoare: semaforul inițializat cu 0 e folosit pentru sincronizare condiționată (ordonare).')

outcomes(7, 'După barieră', C3, 'grea',
         'Bariera `b` lasă firele să treacă doar după ce au ajuns amândouă la ea.',
         '''
shared x = 1
barrier b = 2
thread A:
  x = x + 1
  await(b)
  x = x * 2
thread B:
  await(b)
  x = x + 10
''', 'x', [4, 12, 14, 24],
         'Tot ce e înainte de barieră se termină înainte de orice e după ea. După barieră, cele două actualizări sunt din nou în cursă.',
         'La barieră `x = 2`. Apoi: `A`, `B`: `2·2 + 10 = 14`; `B`, `A`: `(2+10)·2 = 24`; amândouă citesc `2`: rămâne ultima scriere, `4` sau `12`.',
         source='Examen APD 2020 · „Ce garanții oferă o barieră?”')

# ---------------------------------------------------------------- planificări
schedule(8, 'Actualizarea pierdută', C1, 'ușoară',
         'Arată că incrementarea neprotejată poate pierde o actualizare.',
         '''
shared x = 0
thread A:
  x = x + 1
thread B:
  x = x + 1
''', 'Ambele fire trebuie să citească înainte ca vreunul să scrie.',
         'O ordine: `A B A B` (A citește 0, B citește 0, A scrie 1, B scrie 1).', goal={'x': 1})

schedule(9, 'Patru incrementări, rezultat 2', C1, 'grea',
         'Fiecare fir incrementează de două ori. Găsește întrețeserea în care se pierd două actualizări.',
         '''
shared x = 0
thread A:
  x = x + 1
  x = x + 1
thread B:
  x = x + 1
  x = x + 1
''', 'Un fir citește `0` și „doarme” cât celălalt face o incrementare întreagă; apoi scrie `1`, celălalt citește `1`...',
         'O ordine: `A B B A B A A B`: A citește 0; B incrementează (x = 1); A scrie 1; B citește 1; A incrementează (x = 2); B scrie 2.', goal={'x': 2})

schedule(10, 'Trei fire, rezultat 1', C1, 'medie',
         'Găsește ordinea în care, la sfârșit, `x = 1`.',
         '''
shared x = 0
thread A:
  x = 5
thread B:
  x = x + 1
thread C:
  x = x * 2
''', 'Ultima scriere trebuie să fie a lui `B`, cu valoarea citită la început, când `x` era `0`.',
         'O ordine: `B A C C B`: B citește 0; A scrie 5; C citește 5 și scrie 10; B scrie 1.', goal={'x': 1})

schedule(11, 'Între cele două jumătăți', C3, 'medie',
         '`B` așteaptă semnalul lui `A`.',
         '''
shared x = 0
sem s = 0
thread A:
  x = x + 1
  V(s)
  x = x + 1
thread B:
  P(s)
  x = x * 10
''', '`B` trebuie să ruleze întreg între `V(s)` și a doua incrementare a lui `A`.',
         'O ordine: `A A A B B B A A`: A face `x = 1` și `V(s)`; B trece de `P(s)` și face `x = 10`; A face `x = 11`.', goal={'x': 11})

schedule(12, 'Deadlock cu două lock-uri', C4, 'ușoară',
         'Cele două fire iau aceleași lock-uri în ordine inversă.',
         '''
shared x = 0
lock m, n
thread A:
  lock(m)
  lock(n)
  x = x + 1
  unlock(n)
  unlock(m)
thread B:
  lock(n)
  lock(m)
  x = x + 1
  unlock(m)
  unlock(n)
''', 'Fiecare fir trebuie să apuce primul lui lock înainte ca celălalt să-l ceară.',
         'Ordinea `A B`: A ține `m` și așteaptă `n`; B ține `n` și așteaptă `m`. Așteptare circulară: deadlock.', deadlock=True)

schedule(13, 'Semnalul care nu mai vine', C4, 'medie',
         'Fiecare fir așteaptă semnalul celuilalt înainte să-l dea pe al lui.',
         '''
shared x = 0
sem a = 0, b = 1
thread A:
  P(b)
  P(a)
  x = x + 1
  V(b)
thread B:
  P(b)
  x = x + 1
  V(a)
  V(b)
''', 'Cine ia primul semaforul `b` hotărăște totul.',
         'Dacă `A` face primul `P(b)`, rămâne blocat la `P(a)` ținând `b`, iar `B` se blochează la `P(b)`: nimeni nu mai face `V(a)`. Ordinea: `A`.', deadlock=True)

# ---------------------------------------------------------------- 2-4. sincronizare
fix(14, 'Contor protejat', C2, 'ușoară',
    'Cele două fire pierd uneori o incrementare.',
    '''
shared x = 0
thread A:
  x = x + 1
thread B:
  x = x + 1
''', {'x': 2}, '''
shared x = 0
lock m
thread A:
  lock(m)
  x = x + 1
  unlock(m)
thread B:
  lock(m)
  x = x + 1
  unlock(m)
''', 'Declară un lock (`lock m`) și pune fiecare incrementare între `lock(m)` și `unlock(m)`.')

fix(15, 'Trei fire, șase incrementări', C2, 'medie',
    'Trei fire incrementează de câte două ori același contor.',
    '''
shared x = 0
thread A:
  x = x + 1
  x = x + 1
thread B:
  x = x + 1
  x = x + 1
thread C:
  x = x + 1
  x = x + 1
''', {'x': 6}, '''
shared x = 0
lock m
thread A:
  lock(m)
  x = x + 1
  x = x + 1
  unlock(m)
thread B:
  lock(m)
  x = x + 1
  x = x + 1
  unlock(m)
thread C:
  lock(m)
  x = x + 1
  x = x + 1
  unlock(m)
''', 'Același lock în toate firele. O secțiune critică poate cuprinde ambele incrementări.')

fix(16, 'Excludere mutuală cu un semafor', C3, 'ușoară',
    'Protejează contorul folosind un semafor în loc de lock.',
    '''
shared x = 0
thread A:
  x = x + 1
thread B:
  x = x + 1
''', {'x': 2}, '''
shared x = 0
sem s = 1
thread A:
  P(s)
  x = x + 1
  V(s)
thread B:
  P(s)
  x = x + 1
  V(s)
''', 'Un semafor inițializat cu 1 (binar) lasă un singur fir între `P` și `V`.', forbid=('lock',))

fix(17, 'A înaintea lui B', C3, 'medie',
    '`A` trebuie să-și termine calculul înainte ca `B` să-l înceapă pe al lui.',
    '''
shared x = 1
thread A:
  x = x + 4
thread B:
  x = x * 3
''', {'x': 15}, '''
shared x = 1
sem s = 0
thread A:
  x = x + 4
  V(s)
thread B:
  P(s)
  x = x * 3
''', 'Un semafor inițializat cu 0: `B` îl așteaptă cu `P`, `A` îl eliberează cu `V` când a terminat.', forbid=('lock',))

fix(18, 'Trei fire în ordinea C, A, B', C3, 'medie',
    'Fiecare fir adaugă o cifră la sfârșitul lui `x`. Cifrele trebuie să apară în ordinea `3`, `1`, `2`.',
    '''
shared x = 0
thread A:
  x = x * 10 + 1
thread B:
  x = x * 10 + 2
thread C:
  x = x * 10 + 3
''', {'x': 312}, '''
shared x = 0
sem a = 0, b = 0
thread A:
  P(a)
  x = x * 10 + 1
  V(b)
thread B:
  P(b)
  x = x * 10 + 2
thread C:
  x = x * 10 + 3
  V(a)
''', 'Predarea ștafetei: câte un semafor pe 0 pentru fiecare fir care trebuie să aștepte; cel dinainte îi dă `V`.', forbid=('lock',))

fix(19, 'Producător și consumator, un singur element', C3, 'medie',
    'Producătorul pune o valoare în `buf`; consumatorul o ia în `got` și golește bufferul. Consumatorul nu are voie să citească înainte să existe ceva.',
    '''
shared buf = 0, got = 0
thread Prod:
  buf = 7
thread Cons:
  got = buf
  buf = 0
''', {'buf': 0, 'got': 7}, '''
shared buf = 0, got = 0
sem plin = 0
thread Prod:
  buf = 7
  V(plin)
thread Cons:
  P(plin)
  got = buf
  buf = 0
''', 'Semaforul `plin`, inițializat cu 0, numără elementele din buffer: producătorul face `V(plin)` după ce a pus, consumatorul face `P(plin)` înainte să ia.',
    forbid=('lock',), source='Examen APD 2020 · pseudocod Producător-Consumator')

fix(20, 'B între cei doi pași ai lui A', C3, 'grea',
    '`B` trebuie să ruleze exact între cele două instrucțiuni ale lui `A`.',
    '''
shared x = 0
thread A:
  x = x + 1
  x = x * 2
thread B:
  x = x + 3
''', {'x': 8}, '''
shared x = 0
sem toB = 0, toA = 0
thread A:
  x = x + 1
  V(toB)
  P(toA)
  x = x * 2
thread B:
  P(toB)
  x = x + 3
  V(toA)
''', 'Două semafoare pe 0: `A` îi dă voie lui `B` și apoi așteaptă să fie anunțat că `B` a terminat.')

fix(21, 'Faza a doua, după barieră', C3, 'medie',
    'Fiecare fir își scrie valoarea (faza 1), apoi calculează suma celor două (faza 2). Suma trebuie calculată abia după ce ambele valori sunt scrise.',
    '''
shared x = 0, y = 0, ra = 0, rb = 0
thread A:
  x = 2
  ra = x + y
thread B:
  y = 3
  rb = x + y
''', {'x': 2, 'y': 3, 'ra': 5, 'rb': 5}, '''
shared x = 0, y = 0, ra = 0, rb = 0
barrier b = 2
thread A:
  x = 2
  await(b)
  ra = x + y
thread B:
  y = 3
  await(b)
  rb = x + y
''', 'O barieră pentru 2 fire (`barrier b = 2`), cu `await(b)` între cele două faze, în ambele fire.')

fix(22, 'Scapă de deadlock', C4, 'medie',
    'Programul se poate bloca: firele iau lock-urile în ordine inversă. Fă-l să se termine mereu, păstrând ambele lock-uri în jurul incrementării.',
    '''
shared x = 0
lock m, n
thread A:
  lock(m)
  lock(n)
  x = x + 1
  unlock(n)
  unlock(m)
thread B:
  lock(n)
  lock(m)
  x = x + 1
  unlock(m)
  unlock(n)
''', {'x': 2}, '''
shared x = 0
lock m, n
thread A:
  lock(m)
  lock(n)
  x = x + 1
  unlock(n)
  unlock(m)
thread B:
  lock(m)
  lock(n)
  x = x + 1
  unlock(n)
  unlock(m)
''', 'Rupe așteptarea circulară: toate firele iau lock-urile în aceeași ordine.')

fix(23, 'Transfer între două conturi', C4, 'grea',
    'Două transferuri în sens opus între conturile `a` și `b`. Suma totală trebuie să rămână 100, iar fiecare cont să ajungă la valoarea corectă.',
    '''
shared a = 60, b = 40
thread T1:
  a = a - 10
  b = b + 10
thread T2:
  b = b - 5
  a = a + 5
''', {'a': 55, 'b': 45}, '''
shared a = 60, b = 40
lock la, lb
thread T1:
  lock(la)
  lock(lb)
  a = a - 10
  b = b + 10
  unlock(lb)
  unlock(la)
thread T2:
  lock(la)
  lock(lb)
  b = b - 5
  a = a + 5
  unlock(lb)
  unlock(la)
''', 'Un lock pe fiecare cont, luate mereu în aceeași ordine (sau un singur lock pentru amândouă).')

# ---------------------------------------------------------------- 5. teorie
def amdahl(par, p):
    return 1 / ((1 - par) + par / p)


def q(id, title, diff, st, right, wrong, hint, sol, source=''):
    P.append(quiz(id, title, C5, diff, st, right, wrong, hint, sol, source))


q(24, 'Amdahl: 90% paralelizabil, 4 procesoare', 'ușoară',
  'Un program a fost paralelizat în proporție de 90%. Ce accelerare (speed-up) prezice legea lui Amdahl pe 4 procesoare?',
  f'{amdahl(.9, 4):.2f}', [f'{amdahl(.9, 2):.2f}', '3.60', '4.00'],
  '`S = 1 / (f + (1 - f) / P)`, cu `f` partea secvențială.', '`S = 1 / (0.1 + 0.9 / 4) = 1 / 0.325 ≈ 3.08`.', 'Examen APD 2020')
q(25, 'Amdahl: 50% paralelizabil, 8 procesoare', 'ușoară',
  'Cum scalează, după legea lui Amdahl, o soluție paralelizabilă în proporție de 50%, pe 8 procesoare?',
  f'{amdahl(.5, 8):.2f}', ['4.00', f'{amdahl(.5, 4):.2f}', '2.00'],
  '`S = 2P / (1 + P)` când jumătate din program e secvențial.', '`S = 1 / (0.5 + 0.5 / 8) = 16 / 9 ≈ 1.78`. Oricâte procesoare ai avea, `S < 2`.', 'Examen APD 2020')
q(26, 'Amdahl: limita', 'medie',
  'Un program are 5% cod care nu poate fi paralelizat. Care este accelerarea maximă, oricâte procesoare am folosi?',
  '20', ['5', '95', 'nelimitată'], 'Când `P → ∞`, termenul `(1 - f) / P` dispare.', '`S → 1 / f = 1 / 0.05 = 20`.')
q(27, 'Taxonomia Flynn', 'ușoară',
  'În ce categorie a taxonomiei Flynn intră un procesor obișnuit cu mai multe nuclee?',
  'MIMD', ['SISD', 'SIMD', 'MISD'], 'Mai multe fluxuri de instrucțiuni, fiecare cu datele lui.',
  'SISD: calculatorul clasic cu un nucleu; SIMD: plăci video, instrucțiuni vectoriale; MISD: sisteme specializate; MIMD: procesoare multi-core, clustere.', 'Examen APD 2020')
q(28, 'Ce garantează o barieră', 'ușoară',
  'Ce garanție oferă o barieră la care așteaptă toate firele?',
  'tot codul dinaintea barierei, din toate firele, se execută înaintea codului de după ea', ['un singur fir execută codul de după barieră', 'firele trec de barieră în ordinea în care au ajuns', 'codul de după barieră se execută secvențial'],
  'Bariera desparte două faze.', 'Niciun fir nu trece până nu au ajuns toate; după aceea toate continuă, în paralel, în orice ordine.', 'Examen APD 2020')
q(29, 'Ceasul Lamport la recepție', 'medie',
  'Un proces are ceasul logic (Lamport) egal cu 4 și primește un mesaj cu marca de timp 9. Ce valoare are ceasul lui după evenimentul de recepție?',
  '10', ['5', '9', '13'], 'La recepție: `ceas = max(ceas, marca mesajului) + 1`.', '`max(4, 9) + 1 = 10`.')
q(30, 'Ceasuri vectoriale', 'medie',
  'Două evenimente au ceasurile vectoriale `[2, 1, 0]` și `[1, 2, 0]`. Ce relație este între ele?',
  'sunt concurente', ['primul îl precede cauzal pe al doilea', 'al doilea îl precede cauzal pe primul', 'sunt același eveniment'],
  '`V1 < V2` doar dacă toate componentele lui `V1` sunt `≤` și cel puțin una e strict mai mică.',
  '`2 > 1` pe prima componentă și `1 < 2` pe a doua: niciunul nu e mai mic decât celălalt, deci evenimentele sunt concurente. Un ceas Lamport (o singură valoare) nu ar putea arăta asta.', 'Examen APD 2020 · „Diferența dintre ceas vectorial și ceas logic”')
q(31, 'Algoritmi undă', 'medie',
  'Care dintre următoarele NU este una dintre cele trei condiții pe care le îndeplinește un algoritm undă?',
  'fiecare proces trimite exact un mesaj', ['terminare: fiecare calcul e finit', 'decizie: fiecare calcul conține cel puțin un eveniment „decide”', 'dependență: fiecare „decide” e precedat cauzal de un eveniment din fiecare proces'],
  'Cele trei condiții: terminare, decizie, dependență.', 'Numărul de mesaje diferă de la un algoritm undă la altul (inel, arbore, ecou, faze); condițiile sunt terminarea, decizia și dependența.', 'Examen APD 2020')
q(32, 'Alegerea liderului pe inel', 'grea',
  'Ce complexitate are, în număr de mesaje, algoritmul Hirschberg-Sinclair de alegere a liderului pe un inel bidirecțional cu `n` procese?',
  'O(n log n)', ['O(n)', 'O(n²)', 'O(log n)'], 'În faza `k` un candidat își trimite identificatorul la distanța `2^k` în ambele sensuri.',
  'Sunt cel mult `log n` faze și în fiecare se trimit `O(n)` mesaje: `O(n log n)`. LeLann și Chang-Roberts au cazul cel mai defavorabil `O(n²)`.', 'Examen APD 2015')
q(33, 'SHA-1 în Chord', 'ușoară',
  'Ce rol are funcția SHA-1 în algoritmul Chord?',
  'distribuie uniform identificatorii nodurilor și ai cheilor pe inel', ['criptează mesajele dintre noduri', 'semnează tabelele de rutare (finger tables)', 'detectează nodurile căzute'],
  'Chord e o tabelă de dispersie distribuită.', 'Hashing consistent: și nodurile, și cheile primesc identificatori pe același inel, iar o cheie e ținută de succesorul ei.', 'Examen APD 2020')
q(34, 'Eficiența', 'ușoară',
  'Un program rulează în 120 s pe un procesor și în 20 s pe 8 procesoare. Care este eficiența paralelizării?',
  '0.75', ['6', '0.60', '1.33'], 'Eficiența este accelerarea împărțită la numărul de procesoare.', '`S = 120 / 20 = 6`, `E = S / P = 6 / 8 = 0.75`.')
q(35, 'Condițiile deadlock-ului', 'medie',
  'Care dintre următoarele nu este o condiție necesară pentru apariția unui deadlock?',
  'preempțiunea resurselor', ['excluderea mutuală', 'reținere și așteptare (hold and wait)', 'așteptarea circulară'],
  'Condițiile Coffman.', 'Deadlock-ul cere excludere mutuală, hold and wait, lipsa preempțiunii și așteptare circulară. Dacă resursele pot fi luate cu forța, blocajul se poate rupe.')

write_course('apd', CHAPTERS, P)
