// =============================================================================
// DATA STRUCTURES, BUILT BY HAND (SD)
//   The student does what the algorithm does, one move at a time, and each
//   move is checked against it:
//     bst      — click where each key goes in a binary search tree
//     heap     — build-heap, insert or extract-max as swaps of two cells
//     hash     — click the slot each key lands in (linear, quadratic, double)
//     graph    — click the nodes in the order BFS / DFS / Dijkstra / a
//                topological sort visits them, or the edges Prim / Kruskal pick
//   Pure Dart; the page draws it (ws_ds.dart).
// =============================================================================

import 'dart:math' as math;

/// What can be clicked.
class DsTarget {
  final String kind; // slot, cell, node, edge
  final int a, b; // slot: parent key (or -1 for the root), side 0 left / 1 right; cell/node: index; edge: endpoints
  const DsTarget(this.kind, this.a, [this.b = 0]);
  @override
  bool operator ==(Object other) => other is DsTarget && other.kind == kind && other.a == a && other.b == b;
  @override
  int get hashCode => Object.hash(kind, a, b);
}

class DsFeedback {
  final bool ok;
  final String message;
  const DsFeedback(this.ok, this.message);
}

abstract class DsTask {
  int mistakes = 0;
  final int maxMistakes;
  final List<String> log = [];
  DsTask(this.maxMistakes);

  bool get done;
  bool get failed => mistakes > maxMistakes;
  String get prompt;

  /// The student's move.
  DsFeedback play(DsTarget t);

  /// The right move now (for the solution / hints); null when done.
  DsTarget? expected();

  static DsTask fromSpec(Map spec) {
    final max = (spec['maxMistakes'] as num?)?.toInt() ?? 2;
    switch (spec['mode']) {
      case 'bst':
        return BstTask([for (final k in spec['keys'] as List) (k as num).toInt()], max, initial: [for (final k in spec['initial'] as List? ?? const []) (k as num).toInt()]);
      case 'heap':
        return HeapTask(spec['op'] as String, [for (final k in spec['array'] as List? ?? const []) (k as num).toInt()],
            [for (final k in spec['keys'] as List? ?? const []) (k as num).toInt()], (spec['extract'] as num?)?.toInt() ?? 0, spec['min'] == true, max);
      case 'hash':
        return HashTask((spec['m'] as num).toInt(), [for (final k in spec['keys'] as List) (k as num).toInt()], spec['probe'] as String? ?? 'linear',
            (spec['h2'] as num?)?.toInt() ?? 7, max);
      case 'graph':
        return GraphTask.fromSpec(spec, max);
    }
    throw ArgumentError('mod necunoscut: ${spec['mode']}');
  }
}

// ---------------------------------------------------------------- BST
class BstNode {
  final int key;
  BstNode? left, right;
  BstNode(this.key);
}

class BstTask extends DsTask {
  final List<int> keys;
  BstNode? root;
  int next = 0;

  BstTask(this.keys, int max, {List<int> initial = const []}) : super(max) {
    for (final k in initial) {
      _insert(k);
    }
  }

  void _insert(int k) {
    if (root == null) {
      root = BstNode(k);
      return;
    }
    var n = root!;
    while (true) {
      if (k < n.key) {
        if (n.left == null) {
          n.left = BstNode(k);
          return;
        }
        n = n.left!;
      } else {
        if (n.right == null) {
          n.right = BstNode(k);
          return;
        }
        n = n.right!;
      }
    }
  }

  @override
  bool get done => next >= keys.length;

  @override
  String get prompt => done ? 'Arborele e gata.' : 'Inserează ${keys[next]}: apasă locul liber unde ajunge.';

  /// Every empty child place (where a new key could hang).
  List<DsTarget> slots() {
    if (root == null) return const [DsTarget('slot', -1)];
    final out = <DsTarget>[];
    void walk(BstNode n) {
      if (n.left == null) {
        out.add(DsTarget('slot', n.key, 0));
      } else {
        walk(n.left!);
      }
      if (n.right == null) {
        out.add(DsTarget('slot', n.key, 1));
      } else {
        walk(n.right!);
      }
    }

    walk(root!);
    return out;
  }

  @override
  DsTarget? expected() {
    if (done) return null;
    final k = keys[next];
    if (root == null) return const DsTarget('slot', -1);
    var n = root!;
    while (true) {
      if (k < n.key) {
        if (n.left == null) return DsTarget('slot', n.key, 0);
        n = n.left!;
      } else {
        if (n.right == null) return DsTarget('slot', n.key, 1);
        n = n.right!;
      }
    }
  }

  List<String> _path(int k) {
    final out = <String>[];
    var n = root;
    while (n != null) {
      out.add(k < n.key ? '$k < ${n.key}, la stânga' : '$k ≥ ${n.key}, la dreapta');
      n = k < n.key ? n.left : n.right;
    }
    return out;
  }

  @override
  DsFeedback play(DsTarget t) {
    if (done) return const DsFeedback(true, '');
    final want = expected()!;
    final k = keys[next];
    if (t == want) {
      _insert(k);
      next++;
      log.add('$k');
      return DsFeedback(true, root!.key == k ? '$k e rădăcina.' : '${_path(k).take(_path(k).length - 1).join('; ')}.');
    }
    mistakes++;
    return DsFeedback(false, 'Nu acolo. Pornește din rădăcină: ${_path(k).join('; ')}.');
  }
}

// ---------------------------------------------------------------- heap
class HeapTask extends DsTask {
  final String op; // build, insert, extract
  final bool minHeap;
  List<int> a;
  final List<_HeapEvent> _events = [];
  int _pos = 0;
  String _phase = '';
  final List<int> extracted = [];

  HeapTask(this.op, List<int> array, List<int> keys, int extract, this.minHeap, int max)
      : a = List.of(array),
        super(max) {
    final sim = List.of(array);
    bool better(int x, int y) => minHeap ? x < y : x > y;
    void siftDown(int i, int n) {
      while (true) {
        final l = 2 * i + 1, r = 2 * i + 2;
        var best = i;
        if (l < n && better(sim[l], sim[best])) best = l;
        if (r < n && better(sim[r], sim[best])) best = r;
        if (best == i) return;
        _events.add(_HeapEvent.swap(i, best));
        final t = sim[i];
        sim[i] = sim[best];
        sim[best] = t;
        i = best;
      }
    }

    if (op == 'build') {
      _events.add(_HeapEvent.note('Construiește ${minHeap ? 'min' : 'max'}-heap-ul: sift-down pe rând de la i = ${sim.length ~/ 2 - 1} la 0.'));
      for (var i = sim.length ~/ 2 - 1; i >= 0; i--) {
        siftDown(i, sim.length);
      }
    }
    if (op == 'insert' || keys.isNotEmpty) {
      for (final k in keys) {
        sim.add(k);
        _events.add(_HeapEvent.append(k, 'Inserează $k: a fost pus la final (poziția ${sim.length - 1}); urcă-l cât trebuie.'));
        var i = sim.length - 1;
        while (i > 0 && better(sim[i], sim[(i - 1) ~/ 2])) {
          final p = (i - 1) ~/ 2;
          _events.add(_HeapEvent.swap(i, p));
          final t = sim[i];
          sim[i] = sim[p];
          sim[p] = t;
          i = p;
        }
      }
    }
    for (var e = 0; e < extract; e++) {
      final top = sim[0];
      final last = sim.removeLast();
      if (sim.isNotEmpty) sim[0] = last;
      _events.add(_HeapEvent.extract(top, 'Scoate ${minHeap ? 'minimul' : 'maximul'} ($top): ultimul element ($last) a trecut în rădăcină; coboară-l.'));
      siftDown(0, sim.length);
    }
    _advance();
  }

  void _advance() {
    while (_pos < _events.length && _events[_pos].kind != 's') {
      final e = _events[_pos++];
      if (e.kind == 'a') a.add(e.value);
      if (e.kind == 'x') {
        extracted.add(a[0]);
        final last = a.removeLast();
        if (a.isNotEmpty) a[0] = last;
      }
      _phase = e.note;
    }
  }

  @override
  bool get done => _pos >= _events.length;

  @override
  String get prompt => done ? 'Gata: ${minHeap ? 'min' : 'max'}-heap-ul e corect.' : '$_phase\nApasă două celule ca să le interschimbi.';

  @override
  DsTarget? expected() => done ? null : DsTarget('swap', math.min(_events[_pos].i, _events[_pos].j), math.max(_events[_pos].i, _events[_pos].j));

  /// A swap is played as DsTarget('swap', i, j).
  @override
  DsFeedback play(DsTarget t) {
    if (done) return const DsFeedback(true, '');
    final e = _events[_pos];
    final want = {e.i, e.j};
    if (t.kind == 'swap' && {t.a, t.b}.length == 2 && want.containsAll({t.a, t.b})) {
      final x = a[e.i];
      a[e.i] = a[e.j];
      a[e.j] = x;
      _pos++;
      log.add('${a[e.j]}↔${a[e.i]}');
      _advance();
      return DsFeedback(true, 'Corect: ${a[e.i]} și ${a[e.j]} și-au schimbat locurile.');
    }
    mistakes++;
    final parent = math.min(e.i, e.j);
    return DsFeedback(
        false,
        'Nu. Uită-te la nodul de pe poziția $parent (${a[parent]}) și la copiii lui (pozițiile ${2 * parent + 1} și ${2 * parent + 2}): '
        'în ${minHeap ? 'min' : 'max'}-heap părintele trebuie să fie ${minHeap ? 'mai mic' : 'mai mare'}; se schimbă cu copilul ${minHeap ? 'cel mai mic' : 'cel mai mare'}.');
  }
}

class _HeapEvent {
  final String kind; // s swap, a append, x extract, n note
  final int i, j, value;
  final String note;
  _HeapEvent.swap(this.i, this.j) : kind = 's', value = 0, note = '';
  _HeapEvent.append(this.value, this.note) : kind = 'a', i = 0, j = 0;
  _HeapEvent.extract(this.value, this.note) : kind = 'x', i = 0, j = 0;
  _HeapEvent.note(this.note) : kind = 'n', i = 0, j = 0, value = 0;
}

// ---------------------------------------------------------------- hash table
class HashTask extends DsTask {
  final int m;
  final List<int> keys;
  final String probe; // linear, quadratic, double
  final int h2mod;
  late final List<int?> table = List.filled(m, null);
  int next = 0;

  HashTask(this.m, this.keys, this.probe, this.h2mod, int max) : super(max);

  int h1(int k) => k % m;
  int h2(int k) => h2mod - k % h2mod;

  int probeAt(int k, int i) => switch (probe) {
        'quadratic' => (h1(k) + i * i) % m,
        'double' => (h1(k) + i * h2(k)) % m,
        _ => (h1(k) + i) % m,
      };

  int slotFor(int k) {
    for (var i = 0; i < m; i++) {
      final s = probeAt(k, i);
      if (table[s] == null) return s;
    }
    return -1;
  }

  @override
  bool get done => next >= keys.length;

  @override
  String get prompt => done ? 'Toate cheile sunt în tabelă.' : 'Inserează cheia ${keys[next]}: apasă celula în care ajunge.';

  @override
  DsTarget? expected() => done ? null : DsTarget('cell', slotFor(keys[next]));

  String _explain(int k) {
    final steps = <String>[];
    for (var i = 0; i < m; i++) {
      final s = probeAt(k, i);
      final formula = switch (probe) {
        'quadratic' => i == 0 ? 'h($k) = $k mod $m = $s' : '($k mod $m + $i²) mod $m = $s',
        'double' => i == 0 ? 'h₁($k) = $k mod $m = $s' : '(h₁ + $i·h₂) mod $m = $s, cu h₂($k) = $h2mod − $k mod $h2mod = ${h2(k)}',
        _ => i == 0 ? 'h($k) = $k mod $m = $s' : 'următoarea celulă: $s',
      };
      if (table[s] == null) {
        steps.add('$formula, liberă');
        break;
      }
      steps.add('$formula, ocupată de ${table[s]}');
    }
    return steps.join('; ');
  }

  @override
  DsFeedback play(DsTarget t) {
    if (done) return const DsFeedback(true, '');
    final k = keys[next];
    final want = slotFor(k);
    if (t.kind == 'cell' && t.a == want) {
      final msg = _explain(k);
      table[want] = k;
      next++;
      log.add('$k→$want');
      return DsFeedback(true, msg);
    }
    mistakes++;
    return DsFeedback(false, 'Nu. ${_explain(k)}.');
  }
}

// ---------------------------------------------------------------- graphs
class GNode {
  final String name;
  final double x, y; // 0..1
  GNode(this.name, this.x, this.y);
}

class GEdge {
  final int u, v;
  final int w;
  GEdge(this.u, this.v, this.w);
}

class GraphTask extends DsTask {
  final String algo; // bfs dfs dijkstra topo prim kruskal
  final List<GNode> nodes;
  final List<GEdge> edges;
  final bool directed;
  final int start;
  final List<int> order = []; // nodes visited / finalized
  final List<int> picked = []; // edges chosen (indexes)
  late final List<int> dist = List.filled(nodes.length, _inf);
  static const int _inf = 1 << 40;
  late List<int> _fixed; // the deterministic order for bfs / dfs

  GraphTask(this.algo, this.nodes, this.edges, this.directed, this.start, int max) : super(max) {
    if (algo == 'bfs' || algo == 'dfs') _fixed = _traverse();
    if (algo == 'dijkstra') dist[start] = 0;
  }

  factory GraphTask.fromSpec(Map spec, int max) {
    final nodes = [for (final n in spec['nodes'] as List) GNode('${(n as Map)['name']}', (n['x'] as num).toDouble(), (n['y'] as num).toDouble())];
    int idx(dynamic name) => nodes.indexWhere((n) => n.name == '$name');
    final edges = [for (final e in spec['edges'] as List) GEdge(idx((e as List)[0]), idx(e[1]), e.length > 2 ? (e[2] as num).toInt() : 1)];
    return GraphTask(spec['algo'] as String, nodes, edges, spec['directed'] == true, spec['start'] == null ? 0 : idx(spec['start']), max);
  }

  bool get weighted => algo == 'dijkstra' || algo == 'prim' || algo == 'kruskal';
  bool get edgeMode => algo == 'prim' || algo == 'kruskal';

  List<(int, int)> neighbors(int u) {
    final out = <(int, int)>[];
    for (final (i, e) in edges.indexed) {
      if (e.u == u) out.add((e.v, i));
      if (!directed && e.v == u) out.add((e.u, i));
    }
    out.sort((p, q) => nodes[p.$1].name.compareTo(nodes[q.$1].name));
    return out;
  }

  List<int> _traverse() {
    final seen = <int>{};
    final out = <int>[];
    if (algo == 'bfs') {
      final q = [start];
      seen.add(start);
      while (q.isNotEmpty) {
        final u = q.removeAt(0);
        out.add(u);
        for (final (v, _) in neighbors(u)) {
          if (seen.add(v)) q.add(v);
        }
      }
    } else {
      void go(int u) {
        seen.add(u);
        out.add(u);
        for (final (v, _) in neighbors(u)) {
          if (!seen.contains(v)) go(v);
        }
      }

      go(start);
    }
    return out;
  }

  /// The moves that are right now (ties all count).
  Set<DsTarget> allowed() {
    switch (algo) {
      case 'bfs':
      case 'dfs':
        return order.length < _fixed.length ? {DsTarget('node', _fixed[order.length])} : {};
      case 'dijkstra':
        final open = [for (var i = 0; i < nodes.length; i++) if (!order.contains(i) && dist[i] < _inf) i];
        if (open.isEmpty) return {};
        final best = open.map((i) => dist[i]).reduce(math.min);
        return {for (final i in open) if (dist[i] == best) DsTarget('node', i)};
      case 'topo':
        final left = [for (var i = 0; i < nodes.length; i++) if (!order.contains(i)) i];
        return {
          for (final i in left)
            if (!edges.any((e) => e.v == i && !order.contains(e.u))) DsTarget('node', i),
        };
      case 'prim':
        final inTree = order.isEmpty ? {start} : order.toSet();
        if (inTree.length == nodes.length) return {};
        final cross = [
          for (final (i, e) in edges.indexed)
            if (inTree.contains(e.u) != inTree.contains(e.v)) i,
        ];
        if (cross.isEmpty) return {};
        final best = cross.map((i) => edges[i].w).reduce(math.min);
        return {for (final i in cross) if (edges[i].w == best) DsTarget('edge', i)};
      case 'kruskal':
        if (picked.length == nodes.length - 1) return {};
        final parent = List.generate(nodes.length, (i) => i);
        int find(int x) => parent[x] == x ? x : parent[x] = find(parent[x]);
        for (final i in picked) {
          parent[find(edges[i].u)] = find(edges[i].v);
        }
        final ok = [
          for (final (i, e) in edges.indexed)
            if (!picked.contains(i) && find(e.u) != find(e.v)) i,
        ];
        if (ok.isEmpty) return {};
        final best = ok.map((i) => edges[i].w).reduce(math.min);
        return {for (final i in ok) if (edges[i].w == best) DsTarget('edge', i)};
    }
    return {};
  }

  @override
  bool get done => allowed().isEmpty;

  @override
  DsTarget? expected() {
    final a = allowed();
    return a.isEmpty ? null : a.first;
  }

  @override
  String get prompt {
    if (done) {
      return switch (algo) {
        'prim' || 'kruskal' => 'Arborele parțial de cost minim e gata: cost ${picked.fold<int>(0, (s, i) => s + edges[i].w)}.',
        _ => 'Gata: ${order.map((i) => nodes[i].name).join(' ')}.',
      };
    }
    return switch (algo) {
      'bfs' => 'Parcurgere în lățime (BFS) din ${nodes[start].name}, vecinii în ordine alfabetică: apasă următorul nod vizitat.',
      'dfs' => 'Parcurgere în adâncime (DFS) din ${nodes[start].name}, vecinii în ordine alfabetică: apasă următorul nod vizitat.',
      'dijkstra' => 'Dijkstra din ${nodes[start].name}: apasă nodul care se fixează acum (cel cu distanța cea mai mică dintre cele nefixate).',
      'topo' => 'Sortare topologică: apasă un nod în care nu mai intră nicio muchie de la noduri neluate.',
      'prim' => 'Prim din ${nodes[start].name}: apasă muchia care intră acum în arbore.',
      _ => 'Kruskal: apasă muchia care intră acum în arbore.',
    };
  }

  void _relax(int u) {
    for (final (v, i) in neighbors(u)) {
      if (order.contains(v)) continue;
      final d = dist[u] + edges[i].w;
      if (d < dist[v]) dist[v] = d;
    }
  }

  @override
  DsFeedback play(DsTarget t) {
    if (done) return const DsFeedback(true, '');
    final ok = allowed();
    if (ok.contains(t)) {
      if (t.kind == 'node') {
        order.add(t.a);
        log.add(nodes[t.a].name);
        if (algo == 'dijkstra') {
          _relax(t.a);
          return DsFeedback(true, '${nodes[t.a].name} se fixează cu distanța ${dist[t.a]}; vecinii lui se actualizează.');
        }
        return DsFeedback(true, 'Corect: ${nodes[t.a].name}.');
      }
      picked.add(t.a);
      final e = edges[t.a];
      if (algo == 'prim') {
        if (order.isEmpty) order.add(start);
        order.add(order.contains(e.u) ? e.v : e.u);
      }
      log.add('${nodes[e.u].name}${nodes[e.v].name}');
      return DsFeedback(true, 'Corect: muchia ${nodes[e.u].name}–${nodes[e.v].name} (${e.w}).');
    }
    mistakes++;
    return DsFeedback(false, switch (algo) {
      'bfs' => 'Nu. BFS ia nodurile în ordinea în care au intrat în coadă: întâi toți vecinii nodului curent, apoi vecinii lor.',
      'dfs' => 'Nu. DFS merge cât de adânc poate: de la ultimul nod vizitat, la primul vecin nevizitat (alfabetic); doar când nu mai are, se întoarce.',
      'dijkstra' => 'Nu. Se fixează nodul nefixat cu distanța provizorie cea mai mică (vezi etichetele).',
      'topo' => 'Nu. Mai intră în el o muchie de la un nod care n-a fost luat.',
      'prim' => 'Nu. Prim ia cea mai ieftină muchie care leagă arborele de un nod din afara lui.',
      _ => 'Nu. Kruskal ia cea mai ieftină muchie rămasă care nu închide un ciclu.',
    });
  }
}
