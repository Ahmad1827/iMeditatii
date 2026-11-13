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
from common import problem, quiz, write_course, load_grile, add_grile, fold

C1 = '1. Curse și întrețeseri'
C2 = '2. Excludere mutuală'
C3 = '3. Semafoare și bariere'
C4 = '4. Blocaje'
C5 = '5. Paralel și distribuit: teorie'
C6 = '6. Calcule: ceasuri, mesaje, performanță'
C7 = '7. Grile: fire, Java, pthreads'
C8 = '8. Grile: algoritmi paraleli și complexitate'
C9 = '9. Grile: MPI și algoritmi distribuiți'
CHAPTERS = [C1, C2, C3, C4, C5, C6, C7, C8, C9]
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

# ---------------------------------------------------------------- 6. computations
def num(id, label, value, tol=0.01, hint='un număr'):
    v = round(float(value), 4)
    return {'id': id, 'label': label, 'answer': repr(int(v) if v == int(v) else v), 'number': True, 'tol': tol, 'hint': hint}


def txt(id, label, answer, hint=''):
    return {'id': id, 'label': label, 'answer': answer, 'hint': hint}


def calc(id, title, diff, statement, fields, hint, solution, source=''):
    P.append(problem(id, title, C6, diff, statement, 'calc', {'fields': fields}, hint, solution, source))


def clocks(procs):
    """procs: {name: [events]}, an event ('a', label) local, ('s', label, msg) send, ('r', label, msg) receive.
    Returns the Lamport and vector clock of every label, run in an order where every receive follows its send."""
    names = list(procs)
    lam = {p: 0 for p in names}
    vec = {p: [0] * len(names) for p in names}
    pos = {p: 0 for p in names}
    sent = {}
    out_l, out_v = {}, {}
    while any(pos[p] < len(procs[p]) for p in names):
        moved = False
        for p in names:
            if pos[p] >= len(procs[p]):
                continue
            ev = procs[p][pos[p]]
            i = names.index(p)
            if ev[0] == 'r' and ev[2] not in sent:
                continue
            if ev[0] == 'r':
                ml, mv = sent[ev[2]]
                lam[p] = max(lam[p], ml) + 1
                vec[p] = [max(a, b) for a, b in zip(vec[p], mv)]
            else:
                lam[p] += 1
            vec[p][i] += 1
            if ev[0] == 's':
                sent[ev[2]] = (lam[p], list(vec[p]))
            out_l[ev[1]] = lam[p]
            out_v[ev[1]] = list(vec[p])
            pos[p] += 1
            moved = True
        assert moved, 'a receive waits for a message never sent'
    return out_l, out_v


def scenario_text(procs):
    lines = []
    for p, evs in procs.items():
        parts = []
        for ev in evs:
            if ev[0] == 'a':
                parts.append(f'{ev[1]} (local)')
            elif ev[0] == 's':
                parts.append(f'{ev[1]} (trimite m{ev[2]})')
            else:
                parts.append(f'{ev[1]} (primește m{ev[2]})')
        lines.append(f'• `{p}`: ' + ', '.join(parts))
    return '\n'.join(lines)


S1 = {'P1': [('a', 'a'), ('s', 'b', 1), ('a', 'c'), ('r', 'd', 2)],
      'P2': [('r', 'e', 1), ('s', 'f', 3), ('a', 'g')],
      'P3': [('a', 'h'), ('r', 'i', 3), ('s', 'j', 2)]}
_l, _v = clocks(S1)
calc(60, 'Ceasuri Lamport pe un scenariu', 'medie',
     'Trei procese, cu evenimentele în ordinea în care apar în fiecare proces (un mesaj e primit după ce a fost trimis):\n\n' + scenario_text(S1) +
     '\n\nToate ceasurile pornesc de la 0. Calculează ceasul Lamport al fiecărui eveniment cerut.',
     [num(k, f'L({k})', _l[k]) for k in ('b', 'e', 'f', 'i', 'j', 'd')],
     'Eveniment local sau trimitere: `L = L + 1`. Recepție: `L = max(L, marca mesajului) + 1`. Mesajul poartă ceasul trimiterii.',
     'Pe rând: ' + ', '.join(f'`L({k}) = {_l[k]}`' for k in 'abcdefghij') + '. De exemplu `d` primește `m2`, trimis la `j` cu marca ' + str(_l['j']) + f', deci `L(d) = max({_l["c"]}, {_l["j"]}) + 1 = {_l["d"]}`.',
     'Curs APD: ceasuri logice')
calc(61, 'Ceasuri vectoriale pe același scenariu', 'grea',
     'Același scenariu ca la problema anterioară:\n\n' + scenario_text(S1) +
     '\n\nCalculează ceasurile vectoriale `[P1, P2, P3]`. Scrie vectorii ca `[x,y,z]`, fără spații.',
     [txt(k, f'V({k})', '[' + ','.join(map(str, _v[k])) + ']', '[x,y,z]') for k in ('b', 'f', 'i', 'd')] +
     [txt('cc', 'evenimentele c și h sunt: concurente / c→h / h→c', 'concurente')],
     'Fiecare proces crește componenta lui la orice eveniment; la recepție ia maximul pe componente cu vectorul din mesaj, apoi crește componenta proprie.',
     'Vectorii: ' + ', '.join(f'`V({k}) = {_v[k]}`' for k in 'abcdefghij') + f'. `c = {_v["c"]}` și `h = {_v["h"]}` nu se compară pe toate componentele, deci sunt concurente.',
     'Curs APD: ceasuri logice')
S2 = {'P1': [('s', 'a', 1), ('a', 'b'), ('r', 'c', 2)],
      'P2': [('a', 'd'), ('r', 'e', 1), ('s', 'f', 2)]}
_l2, _v2 = clocks(S2)
calc(62, 'Un schimb de mesaje: Lamport și vectorial', 'ușoară',
     'Două procese:\n\n' + scenario_text(S2) + '\n\nCalculează ceasurile pentru evenimentele `e` și `c`.',
     [num('le', 'L(e)', _l2['e']), num('lc', 'L(c)', _l2['c']), txt('ve', 'V(e), ca [x,y]', '[' + ','.join(map(str, _v2['e'])) + ']', '[x,y]'),
      txt('vc', 'V(c), ca [x,y]', '[' + ','.join(map(str, _v2['c'])) + ']', '[x,y]')],
     'La recepție, maximul dintre ceasul propriu și cel din mesaj, plus unu.',
     f'`a` are 1, `d` are 1; `e = max(1, 1) + 1 = {_l2["e"]}`; `f = {_l2["f"]}`; `b = {_l2["b"]}`, `c = max({_l2["b"]}, {_l2["f"]}) + 1 = {_l2["c"]}`. Vectorial: `V(e) = {_v2["e"]}`, `V(c) = {_v2["c"]}`.')


def lcr_steps(ring, i):
    n, uid, j, k = len(ring), ring[i], i, 0
    while True:
        k += 1
        j = (j + 1) % n
        if ring[j] >= uid:
            return k


def lcr(ring):
    """Chang-Roberts on a unidirectional ring, all start: messages until the leader knows (then N to announce)."""
    n = len(ring)
    msgs = 0
    for i, uid in enumerate(ring):
        j = i
        while True:
            msgs += 1
            j = (j + 1) % n
            if ring[j] > uid or ring[j] == uid:
                break
    return msgs


_r = [3, 7, 2, 8, 5, 1]
calc(63, 'LeLann-Chang-Roberts pe un inel', 'grea',
     f'Un inel unidirecțional (fiecare proces trimite doar vecinului din dreapta) are procesele, în ordinea mesajelor, cu identificatorii `{", ".join(map(str, _r))}` (după ultimul vine primul). Toate pornesc alegerea în același timp. '
     'Un proces trimite mai departe un identificator doar dacă e mai mare decât al lui; liderul e cel care își primește propriul identificator.',
     [num('l', 'identificatorul liderului', max(_r)), num('m', 'câte mesaje de alegere se trimit (fără anunțarea liderului)', lcr(_r)),
      num('t', 'câte mesaje în total, cu anunțul liderului (încă un tur)', lcr(_r) + len(_r))],
     'Urmărește fiecare identificator: merge din vecin în vecin până dă de unul mai mare (acolo e oprit) sau ajunge înapoi la el (liderul).',
     'Fiecare identificator merge până dă de unul mai mare: ' + ', '.join(f'{u} face {lcr_steps(_r, i)} {"pas" if lcr_steps(_r, i) == 1 else "pași"}' for i, u in enumerate(_r)) +
     f'. Doar {max(_r)} face turul întreg. Total `{lcr(_r)}` mesaje, plus `{len(_r)}` pentru anunțul liderului.',
     'Curs APD: alegerea liderului')
_ts, _tw = 30, 6
calc(64, 'Timpul unui mesaj (modelul Foster)', 'ușoară',
     f'În modelul Foster, timpul de trimitere a unui mesaj de `L` cuvinte este `T = ts + tw · L`. Timpul de pornire (serializare) este `ts = {_ts}` unități, un cuvânt se trimite în `tw = {_tw}` unități. Cât durează un mesaj de 8 cuvinte? Dar trei mesaje de câte 8 cuvinte, trimise unul după altul, față de un singur mesaj de 24 de cuvinte?',
     [num('t8', 'un mesaj de 8 cuvinte', _ts + _tw * 8), num('t3', 'trei mesaje de câte 8', 3 * (_ts + _tw * 8)), num('t24', 'un mesaj de 24', _ts + _tw * 24)],
     'Costul de pornire se plătește la fiecare mesaj.',
     f'`{_ts} + {_tw}·8 = {_ts + _tw * 8}`; de trei ori: `{3 * (_ts + _tw * 8)}`; un mesaj de 24: `{_ts} + {_tw}·24 = {_ts + _tw * 24}`. Mesajele mari, puține, sunt mai ieftine: se economisesc `2·ts = {2 * _ts}`.',
     'Întrebări APD (examen)')
calc(65, 'Accelerare, eficiență, cost', 'ușoară',
     'Cel mai rapid algoritm secvențial rezolvă o problemă în `G = 960` ms. Varianta paralelă rulează pe `P = 16` procesoare în `T = 80` ms.',
     [num('s', 'accelerarea S = G / T', 12), num('e', 'eficiența E = G / (T · P)', 0.75), num('c', 'costul C = T · P (ms)', 1280)],
     'Costul paralel e timpul înmulțit cu numărul de procesoare; un algoritm e optim ca și cost dacă `C` e de ordinul lui `G`.',
     '`S = 960 / 80 = 12`, `E = 12 / 16 = 0,75`, `C = 80 · 16 = 1280` ms (față de 960: 25% din timpul procesoarelor se pierde).', 'Întrebări APD (examen)')
calc(66, 'Replicare cu cvorum', 'medie',
     'Un obiect e replicat pe `n = 5` noduri. O scriere trebuie confirmată de `w = 3` noduri, o citire întreabă `r = 3` noduri.',
     [txt('ok', 'orice citire vede ultima scriere (r + w > n): da / nu', 'da'), num('fw', 'câte noduri pot cădea fără ca scrierile să se blocheze', 5 - 3),
      num('fr', 'câte noduri pot cădea fără ca citirile să se blocheze', 5 - 3)],
     'O citire și o scriere se intersectează dacă `r + w > n`. Operația merge cât timp sunt măcar `w` (sau `r`) noduri în viață.',
     '`3 + 3 = 6 > 5`: cvorumurile se intersectează mereu. Pot lipsi `5 - 3 = 2` noduri.', 'Întrebări APD (examen)')
calc(67, 'Sume prefix paralele: câți pași', 'medie',
     'Pe un sistem cu `n = 16` procesoare se calculează sumele prefix ale unui vector de 16 elemente cu algoritmul în care, la pasul `j`, procesul `k` adună valoarea procesului `k - 2^(j-1)` (dacă există).',
     [num('p', 'câți pași sunt necesari', 4), num('w1', 'câte procese lucrează la primul pas', 15), num('w4', 'câte procese lucrează la ultimul pas', 8)],
     'La pasul `j` lucrează procesele cu `k - 2^(j-1) ≥ 1`. Distanța se dublează la fiecare pas.',
     '`log₂ 16 = 4` pași; la pasul 1 lucrează procesele 2..16 (15), la pasul 4 procesele 9..16 (8). Pe un sistem MIMD fiecare pas cere bariere: citirea valorilor vechi trebuie să se termine înainte de a le suprascrie.', 'Întrebări APD (examen)')
calc(68, 'Crossover în două puncte', 'ușoară',
     'Un algoritm genetic face crossover în două puncte, după poziția a 4-a și a 9-a, între cromozomii\n\n`C1 = 1101 00100 110100`\n\n`C2 = 1010 11000 011110`\n\nDescendenții primesc segmentul din mijloc schimbat. Scrie-i fără spații.',
     [txt('d1', 'descendentul care păstrează capetele lui C1', '1101110001101 00'.replace(' ', '')[:0] + '1101' + '11000' + '110100', '15 biți'),
      txt('d2', 'descendentul care păstrează capetele lui C2', '1010' + '00100' + '011110', '15 biți')],
     'Capetele rămân, mijlocul (pozițiile 5-9) se schimbă între cromozomi.',
     'D1 = `1101 11000 110100`, D2 = `1010 00100 011110`.', 'Întrebări APD (examen)')


# ---------------------------------------------------------------- 7-9. grile
def g(id, ch, title, diff, st, right, wrong, sol, hint='', source='Întrebări APD (examen)'):
    P.append(quiz(id, title, ch, diff, st, right, wrong, hint, sol, source))


g(130, C7, 'Split binary semaphore', 'medie', 'Ce înseamnă un „split binary semaphore”?',
  'un grup de semafoare a căror sumă a valorilor este cel mult 1', ['un semafor binar folosit de exact două fire', 'un semafor general împărțit în două semafoare binare cu aceeași valoare', 'un mutex care poate fi eliberat de alt fir decât cel care l-a luat'],
  'În orice moment cel mult unul dintre semafoarele grupului e 1: fiecare cale de execuție ia unul (P) și eliberează, la final, unul (V), nu neapărat același.')
g(131, C7, 'Mutex față de semafor binar', 'medie', 'Care este una dintre diferențele dintre un mutex și un semafor binar?',
  'mutexul are un proprietar: doar firul care l-a luat îl poate elibera', ['semaforul binar poate lua doar valorile 0 și 1, mutexul orice valoare', 'mutexul nu poate bloca un fir', 'semaforul binar nu poate fi folosit pentru excludere mutuală'],
  'Eliberarea unui mutex de alt fir e o eroare; un semafor poate fi incrementat de oricine, de aceea e bun și pentru semnalizare.')
g(132, C7, 'Bărbierul somnoros', 'medie', 'De câte semafoare e nevoie, minim, pentru problema bărbierului (bărbierul fără clienți, venirea unui client, frizeria plină)?',
  '3', ['1', '2', '4'], 'Unul pentru clienții care așteaptă, unul pentru bărbierul liber și un mutex pentru numărul de scaune ocupate.')
g(133, C7, 'Producători și consumatori', 'medie', 'M producători, N consumatori și un buffer de dimensiune k: de câte semafoare e nevoie dacă nu se folosește alt mecanism de sincronizare?',
  '4', ['2', '3', 'M + N'], 'Locuri libere, locuri ocupate și câte un mutex pentru producători (indicele de scriere) și pentru consumatori (indicele de citire).')
g(134, C7, 'Cititori și scriitori', 'ușoară', 'Care este dezavantajul soluției cu prioritate pentru cititori la problema cititorilor și scriitorilor?',
  'un flux continuu de cititori poate bloca la nesfârșit scriitorii', ['un singur cititor poate citi la un moment dat', 'scriitorii pot scrie în timp ce se citește', 'cititorii pot ajunge în deadlock între ei'],
  'Cât timp mai e măcar un cititor înăuntru, alți cititori pot intra: scriitorii suferă de înfometare (starvation).')
g(135, C7, 'Cititori și scriitori: ce e fals', 'ușoară', 'Care dintre afirmații este falsă pentru problema cititorilor și scriitorilor?',
  'un singur cititor poate citi la un moment dat', ['mai mulți cititori pot citi simultan', 'un scriitor are acces exclusiv', 'când scrie cineva, nu poate citi nimeni'], 'Tocmai citirile simultane sunt rostul problemei.')
g(136, C7, 'Lock re-entrant', 'medie', 'Ce înseamnă că un lock este re-entrant?',
  'un fir care deține deja lock-ul îl poate lua din nou fără să se blocheze', ['lock-ul se eliberează singur la sfârșitul metodei', 'mai multe fire îl pot deține simultan', 'lock-ul poate fi luat din nou după ce a fost eliberat'],
  'În Java, `synchronized` și `ReentrantLock` sunt re-entrante: un contor numără de câte ori l-a luat firul.')
g(137, C7, 'Semaphore(-2) în Java', 'grea', 'În Java, `Semaphore s = new Semaphore(-2)`. De câte apeluri `s.release()` e nevoie pentru ca un fir care face `s.acquire()` să treacă?',
  '3', ['2', '1', 'niciunul: constructorul aruncă excepție'], 'Un `acquire()` trece doar când există cel puțin un permis: de la -2 trebuie ajuns la 1.')
g(138, C7, 'static synchronized', 'medie', 'O metodă `public static synchronized void f()` din clasa `A`: pe ce se face sincronizarea?',
  'pe obiectul clasei, `A.class`', ['pe `this`', 'pe fiecare instanță separat', 'pe metoda `f`'], 'O metodă statică nu are `this`; monitorul e obiectul `Class` al clasei.')
g(139, C7, 'run() față de start()', 'ușoară', 'Ce se întâmplă când apelăm metoda `run()` a unui obiect `Thread` în Java, în loc de `start()`?',
  'conținutul metodei se execută pe firul curent, fără să se creeze un fir nou', ['se creează un fir nou, la fel ca la `start()`', 'se aruncă `IllegalThreadStateException`', 'firul pornește abia după ce se termină firul curent'], '`start()` creează firul, care apoi apelează `run()`.')
g(140, C7, 'IllegalMonitorStateException', 'medie', 'De ce poate apărea `IllegalMonitorStateException` când apelăm `wait()` pe un obiect?',
  'firul curent nu deține monitorul obiectului', ['obiectul a fost deja notificat', 'firul a fost întrerupt', 'obiectul nu implementează `Runnable`'], '`wait`, `notify` și `notifyAll` se apelează doar dintr-un bloc `synchronized` pe același obiect.')
g(141, C7, 'Ce nu se poate folosi pentru sincronizare', 'ușoară', 'Ce nu se poate folosi în Java ca obiect de sincronizare (`synchronized (x)`)?',
  'o variabilă de tip primitiv (`int`, `double`...)', ['un `String`', 'un obiect oarecare `new Object()`', 'obiectul `this`'], 'Monitorul aparține obiectelor; valorile primitive nu au monitor.')
g(142, C7, 'Runnable', 'ușoară', 'Care este avantajul creării unui fir în Java prin implementarea interfeței `Runnable`, față de extinderea clasei `Thread`?',
  'clasa noastră poate extinde în continuare o altă clasă', ['firul pornește mai repede', 'nu mai e nevoie de `start()`', 'firul are automat prioritate mai mare'], 'Java nu are moștenire multiplă de clase, dar o clasă poate implementa oricâte interfețe.')
g(143, C7, 'Oprirea unui ExecutorService', 'ușoară', 'Ce metodă oprește un `ExecutorService` încercând să întrerupă toate task-urile active?',
  '`shutdownNow()`', ['`shutdown()`', '`close()`', '`awaitTermination()`'], '`shutdown()` doar nu mai acceptă task-uri noi și le lasă pe cele pornite să se termine.')
g(144, C7, 'a++ din două fire', 'medie', 'Două fire au variabila partajată `int a = 0`. Fiecare face o dată `a++`, fără sincronizare. Ce valori poate avea `a` la final?',
  '1 sau 2', ['doar 2', 'doar 1', '0, 1 sau 2'], '`a++` înseamnă citire, adunare, scriere: dacă ambele fire citesc 0 înainte de vreo scriere, una dintre incrementări se pierde.')
g(145, C7, 'Condiție de cursă', 'ușoară', 'Care dintre operații creează o condiție de cursă dacă e apelată simultan de mai multe fire, pe aceeași variabilă partajată?',
  'înmulțirea variabilei cu 3', ['citirea variabilei', 'calculul unei valori într-o variabilă locală', 'apelul unei funcții pure cu argumente locale'], '`x = x * 3` citește și scrie: două fire pot citi aceeași valoare veche.')
g(146, C7, 'Starvation', 'ușoară', 'Ce înseamnă „starvation” (înfometare) la programarea cu fire?',
  'un fir așteaptă la nesfârșit să primească resursa de care are nevoie, deși altele avansează', ['toate firele se blochează reciproc', 'un fir consumă toată memoria', 'un fir se termină înaintea celorlalte'], 'La deadlock nu avansează nimeni; la starvation sistemul merge, dar un fir e mereu ocolit.')
g(147, C7, 'Algoritmul lui Dekker', 'ușoară', 'Pentru câte procese funcționează algoritmul lui Dekker de excludere mutuală?',
  'exact 2', ['oricâte', 'cel mult 3', 'doar pentru 1'], 'A fost prima soluție software corectă pentru două procese; pentru N se folosesc Peterson generalizat, Lamport (brutăria) etc.')
g(148, C7, 'Atomicitate', 'medie', 'Succesiunea a două operații atomice este o operație atomică?',
  'nu: între ele se poate intercala un alt fir', ['da, întotdeauna', 'da, dacă sunt pe aceeași variabilă', 'da, dacă sunt citiri'], 'De aceea `if (x == 0) x = 1;` nu e atomic, deși citirea și scrierea sunt.')
g(149, C7, 'Semaforul nu poate...', 'medie', 'Pentru ce NU poate fi folosit un semafor?',
  'pentru a garanta lipsa deadlock-ului oricum ar fi folosit', ['pentru excludere mutuală', 'pentru a ordona execuția a două fire', 'pentru a limita numărul de fire dintr-o zonă'], 'Semafoarele pot face toate celelalte; folosite greșit, produc chiar ele deadlock.', source='')

g(160, C8, 'Scalabilitate', 'ușoară', 'Ce înseamnă o scalabilitate bună în programarea paralelă?',
  'pe măsură ce crește numărul de fire, timpul de rulare scade', ['programul rulează la fel pe orice procesor', 'memoria folosită nu crește cu datele', 'programul poate rula pe un singur fir'], 'Se măsoară empiric: același program cu 1, 2, 4, 8 fire și timpul fiecărei rulări.')
g(161, C8, 'Paralelism la nivel de bit', 'ușoară', 'Execuția în paralel a operației `a | b` pe două numere întregi este un exemplu de paralelism la nivel de:',
  'bit', ['instrucțiune', 'task', 'date (SIMD)'], 'Toți biții cuvântului se combină deodată în ALU.')
g(162, C8, 'Odd-Even Transposition Sort', 'ușoară', 'Pe ce algoritm secvențial se bazează Odd-Even Transposition Sort?',
  'Bubble sort', ['Merge sort', 'Quick sort', 'Insertion sort'], 'Fazele pare și impare compară perechi de vecini, ca bubble sort, dar toate perechile unei faze în paralel.')
g(163, C8, 'Căutare paralelă', 'medie', 'Ce complexitate are căutarea unei valori într-un vector cu N elemente, pe un sistem cu N/2 procesoare (CRCW)?',
  'O(1)', ['O(log N)', 'O(N)', 'O(N / P)'], 'Fiecare procesor verifică două poziții; rezultatul se scrie concurent.')
g(164, C8, 'Difuzarea unei valori', 'medie', 'Care este complexitatea difuzării (broadcast) unei valori pe un sistem SIMD-EREW cu P procesoare?',
  'O(log P)', ['O(1)', 'O(P)', 'O(P log P)'], 'Cu citire exclusivă, valoarea se copiază în dublare: la fiecare pas, numărul celor care o au se dublează.')
g(165, C8, 'Lungimea până la capătul listei', 'grea', 'Care este complexitatea calculului, în paralel, al distanței din fiecare nod al unei liste cu N elemente până la sfârșitul ei (list ranking, pointer jumping)?',
  'O(log N)', ['O(1)', 'O(N)', 'O(√N)'], 'La fiecare pas, fiecare nod sare la succesorul succesorului: distanțele se dublează.')
g(166, C8, 'Înmulțirea de matrice', 'medie', 'Care este complexitatea înmulțirii a două matrice N×N în paralel, pe P procesoare, cu algoritmul clasic?',
  'O(N³ / P)', ['O(N² / P)', 'O(N³)', 'O(log N)'], 'Munca totală e `N³` operații, împărțită egal.')
g(167, C8, 'Liniar?', 'ușoară', 'În practică, timpul de execuție scade întotdeauna liniar cu numărul de procesoare?',
  'nu: partea secvențială, comunicarea și sincronizarea limitează accelerarea', ['da, pentru orice program', 'da, dacă procesoarele sunt identice', 'da, dacă se folosește MPI'], 'Legea lui Amdahl: `S ≤ 1 / f`.')
g(168, C8, 'Bariera în SIMD', 'medie', 'Într-un sistem SIMD trebuie să pună programatorul bariere între pașii unui algoritm?',
  'nu: toate procesoarele execută aceeași instrucțiune în același timp', ['da, după fiecare instrucțiune', 'da, dar doar la citiri', 'nu, pentru că SIMD are un singur procesor'], 'Sincronizarea e implicită. Pe MIMD aceleași sume prefix cer două bariere pe pas.')
g(169, C8, 'Selecția de tip turneu', 'ușoară', 'Cum funcționează selecția de tip turneu într-un algoritm genetic?',
  'se aleg soluții două câte două, iar cea mai bună dintre ele e păstrată', ['se păstrează mereu jumătatea cea mai bună a populației', 'probabilitatea de selecție e proporțională cu fitness-ul', 'se aleg soluții la întâmplare, fără a ține cont de fitness'], 'Varianta proporțională cu fitness-ul e selecția prin ruletă.')
g(170, C8, 'Modelul Master-Slave', 'medie', 'În modelul genetic Master-Slave:',
  'fitness-ul se evaluează în paralel, iar selecția și operatorii genetici se aplică pe toată populația', ['fiecare sclav are propria populație și schimbă din când în când indivizi', 'fiecare individ e un proces separat', 'master-ul nu ține populația'], 'Populațiile separate cu migrare sunt modelul insular (de tip „island”).')
g(171, C8, 'Regulile sumelor prefix', 'grea', 'n procese calculează sumele prefix (procesul k ține elementul k, k de la 1). La pasul j (j de la 1), ce condiție trebuie să îndeplinească un proces ca să lucreze?',
  '`k - 2^(j-1) ≥ 1`', ['`k ≥ 2^j`', '`k mod 2^j = 0`', '`k - j ≥ 1`'], 'La pasul j se adună valoarea de la distanța `2^(j-1)`.')

g(180, C9, 'MPI_Comm_size', 'ușoară', 'Ce face `MPI_Comm_size`?',
  'returnează numărul de procese din comunicator', ['returnează rangul procesului curent', 'setează numărul de procese', 'returnează dimensiunea bufferului de trimitere'], '`MPI_Comm_rank` dă rangul.')
g(181, C9, 'MPI_Send se întoarce', 'medie', 'Când se întoarce apelul `MPI_Send`, ce știm sigur?',
  'datele au fost copiate și bufferul poate fi refolosit', ['destinatarul a primit mesajul', 'destinatarul a apelat `MPI_Recv`', 'mesajul a ajuns în rețea'], 'Se poate întoarce înainte de recepție (dacă mesajul a fost pus într-un buffer de sistem) sau abia după, pentru mesaje mari.')
g(182, C9, 'Send fără Recv', 'medie', 'Ce se poate întâmpla dacă un proces MPI face foarte multe `send`-uri, dar destinația nu face `recv`?',
  '`send` poate deveni blocant când se umple bufferul de sistem', ['mesajele se pierd', 'programul se termină cu eroare imediat', 'nimic: `send` nu blochează niciodată'], 'De aceea doi parteneri care fac întâi `send` unul către altul pot ajunge în deadlock pentru mesaje mari.')
g(183, C9, 'Apelul MPI_Send corect', 'ușoară', 'Care este apelul corect pentru a trimite variabila `int x = 3` procesului 1, cu tag 0?',
  '`MPI_Send(&x, 1, MPI_INT, 1, 0, MPI_COMM_WORLD);`', ['`MPI_Send(x, 1, MPI_INT, 1, 0, MPI_COMM_WORLD);`', '`MPI_Send(&x, sizeof(int), MPI_INT, 0, 1, MPI_COMM_WORLD);`', '`MPI_Send(&x, 1, MPI_INT, MPI_COMM_WORLD, 1, 0);`'],
  'Ordinea: buffer, număr de elemente, tip, destinație, tag, comunicator.')
g(184, C9, 'Scatter', 'ușoară', 'Ce face `MPI_Scatter`?',
  'împarte un vector în bucăți egale și trimite câte o bucată fiecărui proces din comunicator', ['trimite tot vectorul tuturor proceselor', 'adună bucățile de la toate procesele la unul singur', 'reduce valorile tuturor proceselor la una'], 'Tot vectorul tuturor: `MPI_Bcast`; adunarea bucăților: `MPI_Gather`; reducerea: `MPI_Reduce`.')
g(185, C9, 'Primirea unui Bcast', 'medie', 'Cum primesc celelalte procese un mesaj trimis cu `MPI_Bcast`?',
  'tot prin `MPI_Bcast`, cu aceeași rădăcină', ['prin `MPI_Recv` cu sursa `MPI_ANY_SOURCE`', 'prin `MPI_Recv` de la rădăcină', 'automat, fără niciun apel'], 'Operațiile colective se apelează de toate procesele comunicatorului.')
g(186, C9, 'MPI_Barrier', 'ușoară', 'Ce face `MPI_Barrier`?',
  'oprește fiecare proces până când toate procesele comunicatorului ajung la barieră', ['trimite un mesaj tuturor proceselor', 'termină programul distribuit', 'blochează comunicatorul pentru alte mesaje'], 'Ca bariera de la fire, dar între procese.')
g(187, C9, 'mpirun', 'ușoară', 'Ce face `mpirun`?', 'pornește un program MPI în mai multe procese', ['compilează un program MPI', 'afișează procesele MPI care rulează', 'leagă biblioteca MPI la program'], 'Se compilează cu `mpicc`, se pornește cu `mpirun -np 4 ./prog`.')
g(188, C9, 'Overhead', 'medie', 'În modelul LogP, ce este overhead-ul (o)?',
  'timpul în care procesorul e ocupat cu trimiterea sau primirea unui mesaj', ['întârzierea mesajului prin rețea', 'intervalul minim dintre două trimiteri succesive', 'numărul de procesoare'], 'L e latența rețelei, g (gap) intervalul minim dintre două trimiteri sau recepții ale aceluiași modul, P numărul de procesoare.')
g(189, C9, 'Gap-ul în LogP', 'medie', 'În modelul LogP, ce reprezintă gap-ul (g)?',
  'intervalul minim dintre două trimiteri (sau recepții) succesive ale aceluiași modul', ['timpul cât procesorul e ocupat cu un mesaj', 'latența rețelei', 'diferența dintre ceasurile a două noduri'], '`1/g` e lățimea de bandă disponibilă unui procesor.')
g(190, C9, 'Timpul total al unui algoritm distribuit', 'ușoară', 'Cum se definește timpul total de execuție al unui algoritm distribuit?',
  'de la pornirea primului proces până la terminarea ultimului', ['timpul celui mai lent proces', 'suma timpilor tuturor proceselor', 'media timpilor proceselor'], 'Include și așteptările dintre procese.')
g(191, C9, 'NTP', 'medie', 'Care dintre următoarele soluții de sincronizare a ceasurilor fizice este descentralizată?',
  'Network Time Protocol (NTP)', ['algoritmul Berkeley', 'algoritmul lui Cristian', 'ceasul Lamport'], 'Cristian și Berkeley folosesc un server central (Berkeley face media ceasurilor); NTP e o ierarhie de servere.')
g(192, C9, 'Ceasul Lamport la pornire', 'ușoară', 'Cu ce valoare își inițializează fiecare proces ceasul logic, în soluția lui Lamport?', '0', ['1', 'ora sistemului', 'rangul procesului'], 'Apoi crește la fiecare eveniment.')
g(193, C9, 'Petrecut înainte, între procese', 'medie',
  'P1: `v1 += 7` (ev1), `send(C, v1)` (ev2), `v1 += 8` (ev3). P2: `v2++` (ev4), `receive(C, v2)` (ev5), `v2 += 10` (ev6). Ce se poate garanta pentru orice execuție?',
  'ev1 → ev5', ['ev4 → ev2', 'ev3 → ev6', 'ev3 și ev5 sunt în relația ev3 → ev5'],
  'ev1 → ev2 (același proces), ev2 → ev5 (trimitere și recepție), deci ev1 → ev5. ev3 și ev6 sunt concurente, la fel ev4 și ev2.')
g(194, C9, 'Clock drift', 'ușoară', 'Ce este „clock drift” (deriva unui ceas)?',
  'diferența care se acumulează între ceasul local și un ceas de referință', ['diferența dintre două ceasuri logice', 'timpul în care un mesaj traversează rețeaua', 'eroarea împărțirii timpului între fire'], 'Cristalele oscilează puțin diferit: ceasurile trebuie resincronizate periodic.')
g(195, C9, 'Bully', 'medie', 'În algoritmul Bully, când devine un proces lider?',
  'când trimite mesaje de alegere proceselor cu identificator mai mare și nu îi răspunde niciunul', ['când primește cele mai multe voturi', 'când primește propriul identificator înapoi pe inel', 'când e primul care pornește alegerea'], 'Apoi anunță celorlalți că e coordonator.')
g(196, C9, 'Hirschberg-Sinclair', 'medie', 'Prin ce diferă ipoteza algoritmului Hirschberg-Sinclair de cea a algoritmilor LeLann și Chang-Roberts?',
  'mesajele pot circula în ambele sensuri pe inel', ['procesele nu au identificatori', 'inelul poate avea noduri căzute', 'există un proces inițiator unic'], 'Bidirecționalitatea permite fazele cu distanțe `2^k` în ambele sensuri, de unde `O(n log n)`.')
g(197, C9, 'Chang-Roberts, cazul cel mai bun', 'grea', 'Câte mesaje de alegere se trimit în algoritmul Chang-Roberts în cazul cel mai favorabil, dacă toate procesele sunt inițiatoare?',
  '2N - 1', ['N', 'N(N + 1) / 2', 'N log N'], 'Cazul cel mai bun: fiecare identificator, în afară de maxim, e oprit după un pas (N - 1 mesaje), iar maximul face turul (N). În cel mai rău caz: `N(N + 1) / 2`.')
g(198, C9, 'Alegerea liderului pe arbore', 'grea', 'Câte mesaje se trimit, în total, în algoritmul arbore de alegere a liderului cu N procese (cu mesajele de wake-up)?',
  '4N - 4', ['2N - 2', 'N', 'N²'], 'Pe fiecare din cele `N - 1` muchii trec două mesaje de wake-up și două ale algoritmului undă de tip arbore.')
g(199, C9, 'Algoritmul fazelor', 'medie', 'Pentru care algoritm undă trebuie cunoscut diametrul rețelei?',
  'algoritmul fazelor (heartbeat)', ['algoritmul inel', 'algoritmul ecou', 'algoritmul arbore'], 'Fiecare proces trimite pe fiecare canal de D ori, D fiind diametrul.')
g(200, C9, 'Dijkstra-Scholten', 'grea', 'În care algoritm de detecție a terminării trebuie confirmate toate mesajele trimise înainte ca un proces să se poată declara terminat?',
  'Dijkstra-Scholten', ['algoritmul lui Huang (cu ponderi)', 'algoritmul cu marcaje pe inel', 'algoritmul fazelor'], 'Fiecare mesaj de calcul primește o confirmare; arborele de procese active se strânge de la frunze spre rădăcină.')
g(201, C9, 'Defect de omisiune', 'medie', 'Care este un exemplu de defect de tip omisiune?',
  'un proces nu mai reușește să trimită un mesaj din cauza încărcării', ['un proces trimite valori greșite', 'un proces se oprește definitiv', 'un mesaj ajunge cu întârziere mare'], 'Oprire definitivă: crash; valori greșite: defect bizantin; întârziere: defect de timp (performanță).')
g(202, C9, 'Disponibil, dar nu fiabil', 'medie', 'Un sistem distribuit cade câte o milisecundă în fiecare oră. Este:',
  'foarte disponibil, dar nefiabil', ['fiabil, dar indisponibil', 'și disponibil, și fiabil', 'nici disponibil, nici fiabil'], 'Disponibilitatea e fracțiunea de timp în care merge; fiabilitatea, cât de lung merge fără întrerupere.')
g(203, C9, 'Efectul domino', 'medie', 'Ce înseamnă efectul domino la recuperarea din eroare prin puncte de control (checkpoint)?',
  'procesele se întorc din punct în punct până la starea inițială și pierd tot progresul', ['o eroare se propagă la toate procesele', 'procesele repornesc în ordinea identificatorilor', 'un proces căzut le oprește pe celelalte'], 'Apare când punctele de control nu sunt coordonate: niciunul nu formează o stare globală consistentă.')
g(204, C9, 'Tip de consistență', 'medie', 'Care dintre următoarele NU este un model de consistență?',
  'consistență distribuită', ['consistență secvențială', 'consistență cauzală', 'consistență eventuală'], 'Cele obișnuite: strictă, liniarizabilă, secvențială, cauzală, FIFO, eventuală.')

import re as _re


def apd_chapter(it):
    t = fold(it['q'] + ' ' + ' '.join(it.get('options', [])))
    if _re.search(r'mpi|mesaj|unda|ecou|lider|lelann|huang|raft|lamport|petrecut|foster|e-commerce|consistent', t):
        return C9
    if _re.search(r'thread|java|pthread|mutex|deadlock|filosof|synchronized|lock', t):
        return C7
    return C8


add_grile(P, load_grile('apd_grile'), 101, apd_chapter)

write_course('apd', CHAPTERS, P)
