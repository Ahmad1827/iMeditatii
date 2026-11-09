"""SD — Structuri de Date: C programs on tests, and structures built by hand.

The C problems (SD seria CD exams, 2019–2022) are in data/sd_c.json. The "ds"
problems are done move by move in the page; for each, "expect" is what the
algorithm does, computed here independently, and the app's engine must agree
(test/acs_courses_test.dart).
"""
import heapq, json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course
from cprob import C_START, statement, check

CHAPTERS = ['1. Liste înlănțuite', '2. Stive și cozi', '3. Arbori binari', '4. Heap și tabele de dispersie', '5. Grafuri']
E = 'Examen SD · seria CD'
PROBLEMS = []

HERE = os.path.dirname(os.path.abspath(__file__))
for k, p in enumerate(json.load(open(os.path.join(HERE, 'data', 'sd_c.json'))), start=1):
    tests = check(p['title'], p['code'], [dict(t) for t in p['tests']])
    st = statement(p['description'], p['input'], p['output'], p['constraints'], (tests[0]['input'], tests[0]['output']))
    sol = (p['solution'] + '\n\n' if p['solution'] else '') + '```c\n' + p['code'].strip() + '\n```'
    PROBLEMS.append(problem(k, p['title'], p['chapter'], p['difficulty'], st, 'c',
                            {'tests': tests, 'starter': C_START, 'reference': p['code']}, p['hint'], sol, p['source']))

nid = [len(PROBLEMS)]


def ds(title, chapter, diff, statement_text, spec, hint='', solution='', source=''):
    nid[0] += 1
    PROBLEMS.append(problem(nid[0], title, chapter, diff, statement_text, 'ds', spec, hint, solution, source))


# ------------------------------------------------------------------ independent references
def bst_shape(keys):
    root = None
    tree = {}
    for k in keys:
        if root is None:
            root = k
            tree[k] = [None, None]
            continue
        n = root
        while True:
            side = 0 if k < n else 1
            if tree[n][side] is None:
                tree[n][side] = k
                tree[k] = [None, None]
                break
            n = tree[n][side]
    return root, tree


def preorder(root, tree):
    out = []
    def go(n):
        if n is None:
            return
        out.append(n)
        go(tree[n][0])
        go(tree[n][1])
    go(root)
    return out


def build_heap(a):
    a = list(a)
    n = len(a)
    for i in range(n // 2 - 1, -1, -1):
        j = i
        while True:
            l, r, b = 2 * j + 1, 2 * j + 2, j
            if l < n and a[l] > a[b]: b = l
            if r < n and a[r] > a[b]: b = r
            if b == j: break
            a[j], a[b] = a[b], a[j]
            j = b
    return a


def heap_insert(a, keys):
    a = list(a)
    for k in keys:
        a.append(k)
        i = len(a) - 1
        while i > 0 and a[i] > a[(i - 1) // 2]:
            p = (i - 1) // 2
            a[i], a[p] = a[p], a[i]
            i = p
    return a


def heap_extract(a, times):
    a = list(a)
    out = []
    for _ in range(times):
        out.append(a[0])
        last = a.pop()
        if a:
            a[0] = last
            n, j = len(a), 0
            while True:
                l, r, b = 2 * j + 1, 2 * j + 2, j
                if l < n and a[l] > a[b]: b = l
                if r < n and a[r] > a[b]: b = r
                if b == j: break
                a[j], a[b] = a[b], a[j]
                j = b
    return a, out


def hash_fill(m, keys, probe, h2mod=7):
    t = [None] * m
    for k in keys:
        for i in range(m):
            if probe == 'linear': s = (k + i) % m
            elif probe == 'quadratic': s = (k % m + i * i) % m
            else: s = (k % m + i * (h2mod - k % h2mod)) % m
            if t[s] is None:
                t[s] = k
                break
    return t


def adj(nodes, edges, directed):
    g = {n: [] for n in nodes}
    for e in edges:
        u, v = e[0], e[1]
        w = e[2] if len(e) > 2 else 1
        g[u].append((v, w))
        if not directed:
            g[v].append((u, w))
    for n in g:
        g[n].sort()
    return g


def bfs(g, s):
    seen, q, out = {s}, [s], []
    while q:
        u = q.pop(0)
        out.append(u)
        for v, _ in g[u]:
            if v not in seen:
                seen.add(v)
                q.append(v)
    return out


def dfs(g, s):
    seen, out = set(), []
    def go(u):
        seen.add(u)
        out.append(u)
        for v, _ in g[u]:
            if v not in seen:
                go(v)
    go(s)
    return out


def dijkstra(g, s):
    d = {s: 0}
    pq = [(0, s)]
    done = []
    while pq:
        du, u = heapq.heappop(pq)
        if u in done or du > d[u]:
            continue
        done.append(u)
        for v, w in g[u]:
            if v not in d or du + w < d[v]:
                d[v] = du + w
                heapq.heappush(pq, (d[v], v))
    return d


def mst_cost(nodes, edges):
    parent = {n: n for n in nodes}
    def f(x):
        while parent[x] != x:
            x = parent[x]
        return x
    cost = 0
    for u, v, w in sorted(edges, key=lambda e: e[2]):
        if f(u) != f(v):
            parent[f(u)] = f(v)
            cost += w
    return cost


def place(names, coords):
    return [{'name': n, 'x': x, 'y': y} for n, (x, y) in zip(names, coords)]

# ------------------------------------------------------------------ 3. trees
keys = [50, 30, 70, 20, 40, 60, 80, 35, 65, 45]
root, tree = bst_shape(keys)
ds('Construiește un arbore binar de căutare', '3. Arbori binari', 'ușoară', f'''
Inserează, în ordine, cheile

`{', '.join(map(str, keys))}`

într-un arbore binar de căutare inițial gol: la fiecare pas apasă **locul liber** (`+`) unde ajunge cheia. Cheile mai mici merg în stânga, cele mai mari sau egale în dreapta.

Ai voie la cel mult 2 greșeli.''', {'mode': 'bst', 'keys': keys, 'maxMistakes': 2, 'expect': {'preorder': preorder(root, tree)}},
    hint='Fiecare cheie nouă pornește din rădăcină și coboară: la stânga dacă e mai mică decât nodul, la dreapta altfel, până la un loc gol.',
    solution=f'Parcurs în preordine, arborele final este `{" ".join(map(str, preorder(root, tree)))}`. Rădăcina e prima cheie, {keys[0]}.')

keys2 = [10, 20, 30, 40, 50, 25]
root2, tree2 = bst_shape(keys2)
ds('Un arbore care s-a făcut listă', '3. Arbori binari', 'ușoară', f'''
Inserează cheile `{', '.join(map(str, keys2))}` într-un arbore binar de căutare gol.

Privește forma arborelui: ce se întâmplă cu căutarea când cheile vin **sortate**? (La examen: „Câte comparații face căutarea lui 50?”)''',
    {'mode': 'bst', 'keys': keys2, 'maxMistakes': 1, 'expect': {'preorder': preorder(root2, tree2)}},
    hint='Fiecare cheie e mai mare decât toate de dinainte, deci merge mereu în dreapta.',
    solution='Cheile sortate fac din arbore un lanț spre dreapta: înălțimea e n − 1, iar căutarea lui 50 trece prin 10, 20, 30, 40, 50 — 5 comparații, ca într-o listă. De aceea există arborii echilibrați (AVL, roșu-negru).',
    source=f'{E} · test grilă · căutarea într-un BST neechilibrat')

# ------------------------------------------------------------------ 4. heaps and hashing
arr = [4, 10, 3, 5, 1, 8, 9, 2, 7]
ds('Build-heap', '4. Heap și tabele de dispersie', 'medie', f'''
Transformă vectorul `{arr}` într-un **max-heap** cu algoritmul build-heap: sift-down pentru fiecare nod intern, de la ultimul (`i = n/2 − 1`) spre rădăcină.

Fiecare pas e o interschimbare: apasă cele două noduri (în arbore sau în vector) care își schimbă locurile. Copiii nodului `i` sunt `2i + 1` și `2i + 2`.''',
    {'mode': 'heap', 'op': 'build', 'array': arr, 'maxMistakes': 2, 'expect': {'array': build_heap(arr)}},
    hint='La sift-down, nodul se compară cu ambii copii și se schimbă cu cel mai mare dintre ei, dacă acela e mai mare decât el; apoi continuă de pe noua poziție.',
    solution=f'Heap-ul final: `{build_heap(arr)}`. Build-heap face O(n) operații în total, mai puțin decât n inserări (O(n log n)).')

h0 = build_heap([90, 70, 80, 30, 60, 50])
ds('Inserare într-un max-heap', '4. Heap și tabele de dispersie', 'ușoară', f'''
Max-heap-ul `{h0}` primește, pe rând, cheile **85** și **95**. Fiecare cheie se pune la final și urcă (sift-up) cât timp e mai mare decât părintele ei.

Apasă perechile de noduri care se schimbă.''',
    {'mode': 'heap', 'op': 'insert', 'array': h0, 'keys': [85, 95], 'maxMistakes': 1, 'expect': {'array': heap_insert(h0, [85, 95])}},
    hint='Părintele poziției `i` este `(i − 1) / 2`.',
    solution=f'După inserări: `{heap_insert(h0, [85, 95])}`. 95 urcă până în rădăcină.')

h1 = build_heap([100, 80, 90, 40, 70, 60, 50, 10, 30])
after, out = heap_extract(h1, 2)
ds('Extragerea maximului', '4. Heap și tabele de dispersie', 'medie', f'''
Din max-heap-ul `{h1}` se scoate de **două ori** maximul. La fiecare extragere, ultimul element trece în rădăcină (asta se face automat), apoi coboară prin sift-down: tu faci interschimbările.''',
    {'mode': 'heap', 'op': 'extract', 'array': h1, 'extract': 2, 'maxMistakes': 2, 'expect': {'array': after, 'extracted': out}},
    hint='Coborând, elementul se schimbă cu copilul cel mai mare, cât timp acesta e mai mare decât el.',
    solution=f'Se scot {out[0]} și {out[1]}; heap-ul rămas: `{after}`.',
    source=f'{E} · operații pe un max-heap')

hk = [22, 1, 13, 11, 24, 33, 18, 42, 31]
ds('Dispersie cu adresare deschisă', '4. Heap și tabele de dispersie', 'ușoară', f'''
O tabelă de dispersie are **11** celule, numerotate 0–10, funcția `h(k) = k mod 11` și rezolvă coliziunile prin **sondare liniară** (dacă celula e ocupată, încearcă următoarea, circular).

Inserează, în ordine, cheile `{', '.join(map(str, hk))}`: apasă celula în care ajunge fiecare.''',
    {'mode': 'hash', 'm': 11, 'keys': hk, 'probe': 'linear', 'maxMistakes': 2, 'expect': {'table': hash_fill(11, hk, 'linear')}},
    hint='Calculează `k mod 11`; dacă acolo e deja o cheie, mergi la dreapta (după 10 vine 0).',
    solution='Tabela finală: ' + ', '.join(f'{i}: {v}' if v is not None else f'{i}: —' for i, v in enumerate(hash_fill(11, hk, 'linear'))) + '. Cheile se adună în grupuri lipite (clustering primar): de aceea există sondarea pătratică și dubla dispersie.',
    source=f'{E} · test grilă · coliziune în tabela de dispersie')

dk = [14, 17, 25, 37, 34, 16, 26]
ds('Dublă dispersie', '4. Heap și tabele de dispersie', 'medie', f'''
Tabela are **11** celule și folosește **dublă dispersie**: la încercarea `i` (de la 0) cheia `k` merge în

$$(h_1(k) + i \\cdot h_2(k)) \\bmod 11, \\quad h_1(k) = k \\bmod 11, \\quad h_2(k) = 7 - (k \\bmod 7).$$

Inserează cheile `{', '.join(map(str, dk))}`.''',
    {'mode': 'hash', 'm': 11, 'keys': dk, 'probe': 'double', 'h2': 7, 'maxMistakes': 2, 'expect': {'table': hash_fill(11, dk, 'double', 7)}},
    hint='h₂ nu e niciodată 0 (e între 1 și 7), deci fiecare încercare sare în altă celulă.',
    solution='Tabela finală: ' + ', '.join(f'{i}: {v}' if v is not None else f'{i}: —' for i, v in enumerate(hash_fill(11, dk, 'double', 7))) + '.')

# ------------------------------------------------------------------ 5. graphs
gn = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H']
gc = [(0.1, 0.5), (0.35, 0.15), (0.35, 0.85), (0.6, 0.15), (0.6, 0.5), (0.6, 0.85), (0.88, 0.3), (0.88, 0.75)]
ge = [['A', 'B'], ['A', 'C'], ['B', 'D'], ['B', 'E'], ['C', 'E'], ['C', 'F'], ['D', 'G'], ['E', 'G'], ['E', 'H'], ['F', 'H']]
g = adj(gn, ge, False)
ds('Parcurgerea în lățime', '5. Grafuri', 'ușoară', '''
Parcurge graful **în lățime** (BFS) pornind din `A`. Când un nod are mai mulți vecini nevizitați, îi ia în **ordine alfabetică**.

Apasă nodurile în ordinea în care sunt vizitate (scoase din coadă).''',
    {'mode': 'graph', 'algo': 'bfs', 'nodes': place(gn, gc), 'edges': ge, 'start': 'A', 'maxMistakes': 2, 'expect': {'order': bfs(g, 'A')}},
    hint='BFS folosește o coadă: vizitezi nodul din față și pui la final vecinii lui încă nevăzuți.',
    solution=f'Ordinea BFS: `{" ".join(bfs(g, "A"))}` — întâi nodurile la distanța 1 de A, apoi cele la distanța 2, apoi 3.')

ds('Parcurgerea în adâncime', '5. Grafuri', 'ușoară', '''
Același graf, parcurs **în adâncime** (DFS, recursiv) din `A`, vecinii în ordine alfabetică.''',
    {'mode': 'graph', 'algo': 'dfs', 'nodes': place(gn, gc), 'edges': ge, 'start': 'A', 'maxMistakes': 2, 'expect': {'order': dfs(g, 'A')}},
    hint='DFS merge mereu la primul vecin nevizitat al nodului curent; când nu mai are, se întoarce la nodul de dinainte.',
    solution=f'Ordinea DFS: `{" ".join(dfs(g, "A"))}`.')

dn = ['S', 'A', 'B', 'C', 'D', 'T']
dc = [(0.05, 0.5), (0.35, 0.12), (0.35, 0.88), (0.65, 0.12), (0.65, 0.88), (0.95, 0.5)]
de = [['S', 'A', 4], ['S', 'B', 1], ['B', 'A', 2], ['A', 'C', 5], ['B', 'D', 8], ['B', 'C', 9], ['C', 'D', 1], ['C', 'T', 3], ['D', 'T', 6]]
dd = dijkstra(adj(dn, de, True), 'S')
ds('Dijkstra pas cu pas', '5. Grafuri', 'medie', '''
Rulează algoritmul lui **Dijkstra** din `S` pe graful orientat cu costuri. La fiecare pas, apasă nodul care se **fixează**: cel nefixat cu distanța provizorie cea mai mică. Sub fiecare nod vezi distanța lui provizorie, care se actualizează după fiecare pas.''',
    {'mode': 'graph', 'algo': 'dijkstra', 'directed': True, 'nodes': place(dn, dc), 'edges': de, 'start': 'S', 'maxMistakes': 2, 'expect': {'dist': dd}},
    hint='La început doar S are distanța 0. Când fixezi un nod u, pentru fiecare muchie u→v încerci dist[u] + cost < dist[v].',
    solution='Distanțele finale: ' + ', '.join(f'{k} = {v}' for k, v in sorted(dd.items())) + '. Drumul minim până la T: S → B → A → C → T.',
    source=f'{E} · drum minim într-un graf')

tn = ['curs', 'lab1', 'lab2', 'tema1', 'tema2', 'test', 'examen']
tc = [(0.05, 0.5), (0.3, 0.15), (0.3, 0.85), (0.55, 0.15), (0.55, 0.85), (0.78, 0.5), (0.97, 0.5)]
te = [['curs', 'lab1'], ['curs', 'lab2'], ['lab1', 'tema1'], ['lab2', 'tema2'], ['lab1', 'tema2'], ['tema1', 'test'], ['tema2', 'test'], ['test', 'examen'], ['lab2', 'test']]
ds('Sortarea topologică', '5. Grafuri', 'medie', '''
O muchie `x → y` înseamnă „x trebuie făcut înainte de y”. Găsește o ordine în care pot fi făcute toate (o **sortare topologică**): apasă pe rând nodurile. Orice ordine corectă e acceptată.''',
    {'mode': 'graph', 'algo': 'topo', 'directed': True, 'nodes': place(tn, tc), 'edges': te, 'maxMistakes': 2},
    hint='Poți lua oricând un nod în care nu mai intră nicio muchie de la noduri neluate încă (algoritmul lui Kahn).',
    solution='De exemplu `curs lab1 lab2 tema1 tema2 test examen`. Nu e singura: `lab1` și `lab2` pot fi luate în orice ordine după `curs`.',
    source=f'{E} · test grilă · sortarea topologică')

kn = ['A', 'B', 'C', 'D', 'E', 'F', 'G']
kc = [(0.08, 0.3), (0.38, 0.08), (0.4, 0.55), (0.12, 0.88), (0.68, 0.32), (0.66, 0.9), (0.95, 0.6)]
ke = [['A', 'B', 7], ['A', 'D', 5], ['B', 'C', 8], ['B', 'D', 9], ['B', 'E', 7], ['C', 'E', 5], ['D', 'E', 15], ['D', 'F', 6], ['E', 'F', 8], ['E', 'G', 9], ['F', 'G', 11]]
cost = mst_cost(kn, [tuple(e) for e in ke])
ds('Kruskal', '5. Grafuri', 'medie', '''
Construiește un **arbore parțial de cost minim** cu algoritmul lui **Kruskal**: apasă muchiile în ordinea în care le alege algoritmul (cea mai ieftină care nu închide un ciclu). La costuri egale, oricare e bună.''',
    {'mode': 'graph', 'algo': 'kruskal', 'nodes': place(kn, kc), 'edges': ke, 'maxMistakes': 2, 'expect': {'cost': cost}},
    hint='Sortează muchiile după cost. O muchie închide un ciclu dacă ambele capete sunt deja legate prin muchii alese.',
    solution=f'Costul minim este {cost}. Muchiile alese: AD (5), CE (5), DF (6), AB (7), BE (7), EG (9).')

ds('Prim', '5. Grafuri', 'medie', '''
Același graf, dar cu algoritmul lui **Prim**, pornind din `A`: arborele crește dintr-un singur nod, iar la fiecare pas intră cea mai ieftină muchie care iese din el.''',
    {'mode': 'graph', 'algo': 'prim', 'nodes': place(kn, kc), 'edges': ke, 'start': 'A', 'maxMistakes': 2, 'expect': {'cost': cost}},
    hint='Uită-te doar la muchiile cu un capăt în arbore și celălalt în afară.',
    solution=f'Ordinea lui Prim: AD (5), DF (6), AB (7), BE (7), EC (5), EG (9); costul e tot {cost}. Prim și Kruskal aleg aceleași muchii aici, în altă ordine.')

# ------------------------------------------------------------------ more (2026-11)
keys3 = [8, 3, 10, 1, 6, 14, 4, 7, 13]
root3, tree3 = bst_shape(keys3)
ds('Arborele din manual', '3. Arbori binari', 'ușoară', f'''
Inserează, în ordine, cheile `{', '.join(map(str, keys3))}` într-un arbore binar de căutare gol.

După ce îl construiești, gândește-te: ce dă parcurgerea lui în **inordine**?''',
    {'mode': 'bst', 'keys': keys3, 'maxMistakes': 2, 'expect': {'preorder': preorder(root3, tree3)}},
    hint='Fiecare cheie coboară din rădăcină: la stânga dacă e mai mică, la dreapta altfel.',
    solution=f'Preordinea: `{" ".join(map(str, preorder(root3, tree3)))}`. Inordinea (stânga, nod, dreapta) a unui arbore binar de căutare dă mereu cheile **sortate**: `{" ".join(map(str, sorted(keys3)))}`.')

arr2 = [9, 4, 7, 1, 8, 2, 6, 3]
minh = [-v for v in build_heap([-v for v in arr2])]
ds('Build-heap pentru un min-heap', '4. Heap și tabele de dispersie', 'medie', f'''
Transformă vectorul `{arr2}` într-un **min-heap** (în rădăcină, cel mai mic element), cu build-heap: sift-down de la ultimul nod intern spre rădăcină. Apasă perechile care se schimbă.''',
    {'mode': 'heap', 'op': 'build', 'array': arr2, 'min': True, 'maxMistakes': 2, 'expect': {'array': minh}},
    hint='Într-un min-heap, nodul se schimbă cu copilul **cel mai mic**, dacă acela e mai mic decât el.',
    solution=f'Min-heap-ul final: `{minh}`. E același algoritm ca la max-heap, cu comparațiile inversate.')

qk = [27, 38, 49, 16, 12, 5]
qt = hash_fill(11, qk, 'quadratic')
assert sum(v is not None for v in qt) == len(qk), 'quadratic probing left a key out'
ds('Sondare pătratică', '4. Heap și tabele de dispersie', 'medie', f'''
Tabela are **11** celule și sondare **pătratică**: la încercarea `i` (de la 0), cheia `k` merge în $(k \\bmod 11 + i^2) \\bmod 11$.

Inserează cheile `{', '.join(map(str, qk))}`. Multe dintre ele au același rest la 11: urmărește cum se împrăștie.''',
    {'mode': 'hash', 'm': 11, 'keys': qk, 'probe': 'quadratic', 'maxMistakes': 2, 'expect': {'table': qt}},
    hint='Încercările pentru o cheie cu restul 5: 5, 6, 9, 3 (14 mod 11), 10 (21 mod 11)...',
    solution='Tabela finală: ' + ', '.join(f'{i}: {v}' if v is not None else f'{i}: —' for i, v in enumerate(qt)) + '. Spre deosebire de sondarea liniară, cheile nu se mai lipesc într-un singur bloc (fără clustering primar).')

bn = ['1', '2', '3', '4', '5', '6', '7']
bc = [(0.08, 0.5), (0.35, 0.15), (0.35, 0.85), (0.62, 0.15), (0.62, 0.5), (0.62, 0.85), (0.92, 0.5)]
be = [['1', '2'], ['1', '3'], ['2', '4'], ['2', '5'], ['3', '5'], ['3', '6'], ['5', '7'], ['6', '7'], ['4', '7'], ['7', '1']]
gb = adj(bn, be, True)
ds('BFS pe un graf orientat', '5. Grafuri', 'ușoară', '''
Parcurge graful **orientat** în lățime din nodul `1`: un nod are ca vecini doar nodurile spre care pleacă săgeți din el. Vecinii se iau în ordine crescătoare.''',
    {'mode': 'graph', 'algo': 'bfs', 'directed': True, 'nodes': place(bn, bc), 'edges': be, 'start': '1', 'maxMistakes': 2, 'expect': {'order': bfs(gb, '1')}},
    hint='Muchia `7 → 1` nu face din 1 un vecin nou: 1 e deja vizitat.',
    solution=f'Ordinea BFS: `{" ".join(bfs(gb, "1"))}`.')

un = ['A', 'B', 'C', 'D', 'E', 'F']
uc = [(0.06, 0.5), (0.35, 0.12), (0.35, 0.88), (0.65, 0.12), (0.65, 0.88), (0.94, 0.5)]
ue = [['A', 'B', 2], ['A', 'C', 6], ['B', 'C', 3], ['B', 'D', 7], ['C', 'E', 2], ['D', 'E', 1], ['D', 'F', 3], ['E', 'F', 6]]
ud = dijkstra(adj(un, ue, False), 'A')
ds('Dijkstra pe un graf neorientat', '5. Grafuri', 'medie', '''
Dijkstra din `A`, pe un graf **neorientat** (o muchie se poate parcurge în ambele sensuri). Apasă nodurile în ordinea în care se fixează.''',
    {'mode': 'graph', 'algo': 'dijkstra', 'nodes': place(un, uc), 'edges': ue, 'start': 'A', 'maxMistakes': 2, 'expect': {'dist': ud}},
    hint='Drumul cel mai scurt spre un nod nu e mereu cel cu cele mai puține muchii.',
    solution='Distanțele finale: ' + ', '.join(f'{k} = {v}' for k, v in sorted(ud.items())) + '. De exemplu, până la D nu se merge direct pe B–D (2 + 7 = 9), ci pe A–B–C–E–D (2 + 3 + 2 + 1 = 8).')


def cwrite(chapter, title, diff, desc, inp, out, constraints, ref, tests, hint, sol):
    nid[0] += 1
    t = check(title, ref, [{'input': x} for x in tests])
    st = statement(desc, inp, out, constraints, (t[0]['input'], t[0]['output']))
    PROBLEMS.append(problem(nid[0], title, chapter, diff, st, 'c', {'tests': t, 'starter': C_START, 'reference': ref}, hint, sol + '\n\n```c\n' + ref.strip() + '\n```'))


cwrite('1. Liste înlănțuite', 'Inversarea unei liste', 'medie', '''
Citește `n` numere și pune-le, în ordine, într-o **listă simplu înlănțuită** (fiecare nod nou la final). Inversează lista **pe loc**, schimbând legăturile (fără vector auxiliar și fără noduri noi), apoi afișeaz-o.''',
    'Pe prima linie `n`; pe a doua `n` numere întregi.', 'Lista inversată, pe o linie, numerele separate prin spațiu.', ['1 ≤ n ≤ 100 000'],
    """#include <stdio.h>
#include <stdlib.h>

typedef struct Nod {
    int val;
    struct Nod *next;
} Nod;

int main(void) {
    int n;
    scanf("%d", &n);
    Nod *cap = NULL, *coada = NULL;
    for (int i = 0; i < n; i++) {
        Nod *x = malloc(sizeof *x);
        scanf("%d", &x->val);
        x->next = NULL;
        if (coada) coada->next = x; else cap = x;
        coada = x;
    }
    Nod *prev = NULL;
    while (cap) {
        Nod *urm = cap->next;
        cap->next = prev;
        prev = cap;
        cap = urm;
    }
    for (Nod *p = prev; p; ) {
        Nod *urm = p->next;
        printf("%d%c", p->val, urm ? ' ' : '\\n');
        free(p);
        p = urm;
    }
    return 0;
}
""", ['5\n1 2 3 4 5\n', '1\n42\n', '2\n-1 1\n', '6\n3 3 1 2 2 1\n'],
    'Trei pointeri: nodul de dinainte (`prev`), cel curent și următorul, salvat înainte să schimbi `next`.',
    'La fiecare pas legătura nodului curent se întoarce spre `prev`; la final `prev` e noul cap. O(n) timp, O(1) memorie în plus.')

cwrite('2. Stive și cozi', 'Paranteze echilibrate', 'ușoară', '''
Pentru fiecare linie citită, spune dacă parantezele `()`, `[]` și `{}` din ea sunt **corect închise** (orice altceva se ignoră). Afișează `DA` sau `NU`. Folosește o stivă.''',
    'Mai multe linii, fiecare cu cel mult 10 000 de caractere, până la sfârșitul intrării.', 'Pentru fiecare linie, `DA` sau `NU`.', [],
    """#include <stdio.h>
#include <string.h>

int main(void) {
    static char s[10005], st[10005];
    while (fgets(s, sizeof s, stdin)) {
        int k = 0, ok = 1;
        for (int i = 0; s[i] && ok; i++) {
            char c = s[i];
            if (c == '(' || c == '[' || c == '{') st[k++] = c;
            else if (c == ')' || c == ']' || c == '}') {
                char want = c == ')' ? '(' : c == ']' ? '[' : '{';
                if (k == 0 || st[k - 1] != want) ok = 0;
                else k--;
            }
        }
        printf("%s\\n", ok && k == 0 ? "DA" : "NU");
    }
    return 0;
}
""", ['{[()()]}\n([)]\n', 'v[i] = (a + b) * c;\n', '((\n', ')(\n', 'if (x) { f(a[0]); }\n}\n'],
    'Deschiderea intră în stivă; o închidere trebuie să găsească în vârf deschiderea ei. La final stiva trebuie să fie goală.',
    'Trei moduri de a greși: o închidere cu stiva goală, o închidere care nu se potrivește cu vârful, deschideri rămase la final.')

write_course('sd', CHAPTERS, PROBLEMS)
