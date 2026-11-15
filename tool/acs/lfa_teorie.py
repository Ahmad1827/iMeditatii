"""LFA: the theory pages (assets/data/acs/teorie/lfa.json).

Sixteen lessons in the order of the course (Ștefania Ghiță, seria CD; the
14 lectures, the seminars, the revision sheets), each with definitions,
theorems and their proofs, worked examples, notes for the exam, questions to
check oneself, exam problems solved, and visualisations that run the
algorithms (automata reading a word, the subset construction, state
elimination after Stanford's CS103 guide, Thompson's construction,
minimisation, the product, the pumping lemmas as a game, derivations and
trees, the Chomsky normal form, CYK, pushdown automata, Turing machines).

Every automaton given to a visualisation is checked against the language the
text says it accepts, and every problem linked for practice must exist.
Run from the repo root after tool/acs/lfa.py:  python3 -I tool/acs/lfa_teorie.py
"""
import itertools, json, os, re, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PROBLEMS = json.load(open(os.path.join(ROOT, 'assets', 'data', 'acs', 'lfa.json'), encoding='utf-8'))['problems']
BY_ID = {p['id']: p for p in PROBLEMS}


# ---------------------------------------------------------------- blocks
def p(text):
    return {'t': 'p', 'text': text.strip()}


def d(title, text):
    return {'t': 'def', 'title': title, 'text': text.strip()}


def thm(title, text, proof='', label='Teoremă'):
    b = {'t': 'thm', 'label': label, 'title': title, 'text': text.strip()}
    if proof:
        b['proof'] = proof.strip()
    return b


def ex(title, text, solution='', open_=False):
    b = {'t': 'ex', 'title': title, 'text': text.strip()}
    if solution:
        b['solution'] = solution.strip()
    if open_:
        b['open'] = True
    return b


def note(text, tone='info', title=''):
    return {'t': 'note', 'tone': tone, 'title': title, 'text': text.strip()}


def steps(title, *items):
    return {'t': 'steps', 'title': title, 'items': [i.strip() for i in items]}


def tab(head, rows, title=''):
    return {'t': 'table', 'title': title, 'head': head, 'rows': rows}


def quiz(q, options, answer, why=''):
    assert 0 <= answer < len(options)
    return {'t': 'quiz', 'q': q.strip(), 'options': options, 'answer': answer, 'why': why.strip()}


def exam(source, text, solution, title=''):
    return {'t': 'exam', 'source': source, 'title': title, 'text': text.strip(), 'solution': solution.strip()}


def viz(kind, title, text='', **spec):
    return {'t': 'viz', 'kind': kind, 'title': title, 'text': text.strip(), **spec}


def sec(id, title, *blocks):
    return {'id': id, 'title': title, 'blocks': list(blocks)}


LESSONS = []


def lesson(id, title, summary, curs, minutes, sections, practice=()):
    for pid in practice:
        assert str(pid) in BY_ID, f'{id}: problem {pid} does not exist'
    LESSONS.append({'id': id, 'title': title, 'summary': summary, 'curs': curs, 'minutes': minutes,
                    'practice': [str(x) for x in practice], 'sections': sections})


def ids(chapter_prefix, kind=None, mode=None, limit=14):
    out = []
    for q in PROBLEMS:
        if not q['chapter'].startswith(chapter_prefix):
            continue
        if kind and q['kind'] != kind:
            continue
        if mode and q['spec'].get('mode') != mode:
            continue
        out.append(q['id'])
    return out[:limit]


# ---------------------------------------------------------------- automata, checked
def words(alphabet, n):
    for k in range(n + 1):
        for t in itertools.product(alphabet, repeat=k):
            yield ''.join(t)


def A(n, finals, rows):
    t = {}
    for line in rows.strip().split('\n'):
        s, sym, *to = line.split()
        t.setdefault(s, {})[sym] = sorted(int(x) for x in to)
    return {'states': n, 'final': sorted(finals), 't': t}


def accepts(a, w):
    def close(s):
        s, todo = set(s), list(s)
        while todo:
            for x in a['t'].get(str(todo.pop()), {}).get('ε', []):
                if x not in s:
                    s.add(x); todo.append(x)
        return s
    cur = close({0})
    for c in w:
        cur = close({x for s in cur for x in a['t'].get(str(s), {}).get(c, [])})
    return any(s in a['final'] for s in cur)


def checked(a, alphabet, pred, n=8):
    for w in words(alphabet, n):
        assert accepts(a, w) == bool(pred(w)), f'automaton wrong on {w!r}'
    return a


def py(r):
    return re.compile(r.replace(' ', '').replace('∪', '|').replace('ε', '(?:)').replace('∅', '(?!)'))


def by_regex(r):
    c = py(r)
    return lambda w: c.fullmatch(w) is not None


# =============================================================================
# The automata the lessons draw (checked once, used where needed)
# =============================================================================
EVEN_A = checked(A(2, [0], '0 a 1\n0 b 0\n1 a 0\n1 b 1'), 'ab', lambda w: w.count('a') % 2 == 0)
ENDS_AB = checked(A(3, [2], '0 a 1\n0 b 0\n1 a 1\n1 b 2\n2 a 1\n2 b 0'), 'ab', lambda w: w.endswith('ab'))
DIV3 = checked(A(3, [0], '0 0 0\n0 1 1\n1 0 2\n1 1 0\n2 0 1\n2 1 2'), '01', lambda w: (int(w, 2) if w else 0) % 3 == 0)
HAS_AA = checked(A(3, [2], '0 a 1\n0 b 0\n1 a 2\n1 b 0\n2 a 2\n2 b 2'), 'ab', lambda w: 'aa' in w)
THIRD = checked(A(4, [3], '0 a 0 1\n0 b 0\n1 a 2\n1 b 2\n2 a 3\n2 b 3'), 'ab', lambda w: len(w) >= 3 and w[-3] == 'a')
EXAM_N = checked(A(2, [1], '0 a 0\n0 b 0 1\n1 a 1 0'), 'ab', lambda w: 'b' in w)
EPS_N = checked(A(4, [3], '0 a 0\n0 ε 1\n1 b 1\n1 ε 2\n2 c 2\n2 ε 3'), 'abc', by_regex('a*b*c*'))
ENDS_ABB_N = checked(A(4, [3], '0 a 0 1\n0 b 0\n1 b 2\n2 b 3'), 'ab', lambda w: w.endswith('abb'))
# a DFA with needless states, for minimisation: ends in a, written with 6 states
MIN6 = checked(A(6, [1, 3, 5], '0 a 1\n0 b 2\n1 a 3\n1 b 4\n2 a 5\n2 b 0\n3 a 1\n3 b 2\n4 a 3\n4 b 0\n5 a 5\n5 b 4'), 'ab', lambda w: w.endswith('a'))
# for minimisation: the pair (#a mod 2, #b mod 2), final when #b is even, and a state nothing reaches
MIN_U = checked(A(5, [0, 1], '0 a 1\n0 b 2\n1 a 0\n1 b 3\n2 a 3\n2 b 0\n3 a 2\n3 b 1\n4 a 0\n4 b 4'), 'ab', lambda w: w.count('b') % 2 == 0)
# the Stanford guide: a^m + a^n ≡ a^p with m + n ≡ p (mod 2); '+' written p and '≡' written e (the symbols are drawn only)
PARITY = A(6, [2], '0 a 3\n3 a 0\n0 + 1\n3 + 4\n1 a 4\n4 a 1\n1 = 2\n4 = 5\n2 a 5\n5 a 2')
PARITY_POS = [[0, 0], [2, 0], [4, 0], [0, 1.6], [2, 1.6], [4, 1.6]]


for part in ('lfa_teorie_1.py', 'lfa_teorie_2.py', 'lfa_teorie_3.py'):
    exec(open(os.path.join(HERE, part), encoding='utf-8').read())

PARTS = [
    {'title': 'Partea I · Limbaje regulate', 'about': 'Automate finite, expresii regulate și tot ce se poate face cu ele; cum arăți că un limbaj nu e regulat.',
     'lessons': ['limbaje', 'expresii-regulate', 'afd', 'afn', 'inchidere-lr', 'af-er', 'algoritmice-lr', 'pompare-lr', 'minimizare']},
    {'title': 'Partea II · Limbaje independente de context', 'about': 'Gramatici și automate cu stivă: un pas de memorie mai sus.',
     'lessons': ['gic', 'arbori-fnc', 'apd', 'proprietati-lic']},
    {'title': 'Partea III · Mașini Turing și calculabilitate', 'about': 'Ce se poate calcula, ce se poate doar căuta, și ce nu se poate deloc.',
     'lessons': ['turing', 'calculabilitate']},
    {'title': 'Recapitulare', 'about': 'Înainte de examen.', 'lessons': ['recapitulare']},
]
exec(open(os.path.join(HERE, 'lfa_teorie_keys.py'), encoding='utf-8').read())
for p_ in PARTS:
    if p_['title'] in TESTS:
        p_['test'] = TESTS[p_['title']]
assert sorted(i for p_ in PARTS for i in p_['lessons']) == sorted(l['id'] for l in LESSONS), 'a lesson is in no part'
order = [i for p_ in PARTS for i in p_['lessons']]
LESSONS.sort(key=lambda l: order.index(l['id']))

KINDS = {'automaton', 'subset', 'elim', 'thompson', 'regexlab', 'minimize', 'product', 'pump', 'derive', 'cnf', 'cyk', 'hierarchy', 'pda', 'tm'}
for l in LESSONS:
    assert len({s_['id'] for s_ in l['sections']}) == len(l['sections']), l['id']
    for s_ in l['sections']:
        for b in s_['blocks']:
            if b['t'] == 'viz':
                assert b['kind'] in KINDS, b['kind']
                if 'a' in b:
                    assert b['a']['states'] <= 12
                if 'pos' in b and 'a' in b:
                    assert len(b['pos']) == b['a']['states'], (l['id'], b['title'])

# the problem list's chapters, each with the lesson to read for it
CHAPTERS = {
    '1. Automate finite deterministe': 'afd',
    '2. Automate nedeterministe': 'afn',
    '3. Expresii regulate': 'expresii-regulate',
    '4. Proprietăți ale limbajelor regulate': 'inchidere-lr',
    '5. Gramatici independente de context': 'gic',
    '6. Automate cu stivă': 'apd',
    '7. Mașini Turing': 'turing',
    '8. Clase de limbaje': 'calculabilitate',
    '9. Grile: modelul de test': 'recapitulare',
    '10. Grile din teste și examene': 'recapitulare',
}
_problem_chapters = {c for c in json.load(open(os.path.join(ROOT, 'assets', 'data', 'acs', 'lfa.json'), encoding='utf-8'))['chapters']}
assert set(CHAPTERS) == _problem_chapters, set(CHAPTERS) ^ _problem_chapters
assert all(v in order for v in CHAPTERS.values())

out = os.path.join(ROOT, 'assets', 'data', 'acs', 'teorie', 'lfa.json')
os.makedirs(os.path.dirname(out), exist_ok=True)
data = {
    'code': 'lfa',
    'title': 'Limbaje Formale și Automate',
    'intro': 'Teoria cursului, lecție cu lecție, în ordinea cursurilor: definițiile cu notațiile din curs, teoremele cu demonstrațiile lor, exemple rezolvate, probleme de examen din anii trecuți cu rezolvarea, întrebări de verificare și algoritmi pe care îi rulezi pas cu pas (automate care citesc un cuvânt, construcția submulțimilor, eliminarea stărilor, minimizarea, lema de pompare ca joc, arbori de derivare, CYK, automate cu stivă, mașini Turing). La sfârșitul fiecărei lecții, problemele pe care se aplică.',
    'parts': PARTS,
    'chapters': CHAPTERS,
    'lessons': LESSONS,
}
text = json.dumps(data, ensure_ascii=False, indent=1).replace('\u2212', '-')
open(out, 'w', encoding='utf-8').write(text + '\n')
n_viz = sum(1 for l in LESSONS for s_ in l['sections'] for b in s_['blocks'] if b['t'] == 'viz')
print(f'lfa teorie: {len(LESSONS)} lecții, {sum(len(l["sections"]) for l in LESSONS)} secțiuni, {n_viz} vizualizări -> {os.path.relpath(out, ROOT)}', file=sys.stderr)
