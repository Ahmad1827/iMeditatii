// =============================================================================
// LFA: REGULAR EXPRESSIONS, AUTOMATA AND GRAMMARS, COMPARED AS LANGUAGES
//   A regular expression or an automaton (deterministic or not, with ε moves)
//   becomes a complete DFA; two DFAs are compared state pair by state pair,
//   and the first pair that disagrees gives the shortest word one accepts and
//   the other does not. A grammar is compared on every word up to a length.
// =============================================================================

/// The empty word, as the course writes it.
const String lfaEps = 'ε';

class LfaError implements Exception {
  final String message;
  const LfaError(this.message);
  @override
  String toString() => message;
}

/// A complete deterministic automaton over [alphabet]; state 0 is the start.
class Dfa {
  final List<String> alphabet;
  final List<List<int>> next; // next[state][symbol index]
  final List<bool> accepting;
  const Dfa(this.alphabet, this.next, this.accepting);

  int get states => next.length;

  bool accepts(String word) {
    var s = 0;
    for (final ch in word.split('')) {
      final k = alphabet.indexOf(ch);
      if (k < 0) return false;
      s = next[s][k];
    }
    return accepting[s];
  }

  /// The shortest word on which this and [other] disagree, or null if they
  /// accept the same language. Both must have the same alphabet.
  String? difference(Dfa other) {
    final seen = <int>{0};
    final queue = <(int, int, String)>[(0, 0, '')];
    for (var i = 0; i < queue.length; i++) {
      final (a, b, w) = queue[i];
      if (accepting[a] != other.accepting[b]) return w;
      for (var k = 0; k < alphabet.length; k++) {
        final na = next[a][k], nb = other.next[b][k];
        if (seen.add(na * other.states + nb)) queue.add((na, nb, w + alphabet[k]));
      }
    }
    return null;
  }

  /// How many states the smallest DFA of this language has (the sink counted).
  int get minimalStates {
    // only what can be reached, then split the classes until they are stable
    final reach = <int>[0];
    final at = <int, int>{0: 0};
    for (var i = 0; i < reach.length; i++) {
      for (final t in next[reach[i]]) {
        if (!at.containsKey(t)) {
          at[t] = reach.length;
          reach.add(t);
        }
      }
    }
    var cls = [for (final s in reach) accepting[s] ? 1 : 0];
    while (true) {
      final keys = <String, int>{};
      final fresh = [
        for (var i = 0; i < reach.length; i++)
          keys.putIfAbsent('${cls[i]}|${[for (final t in next[reach[i]]) cls[at[t]!]].join(',')}', () => keys.length),
      ];
      if (keys.length == cls.toSet().length) return keys.length;
      cls = fresh;
    }
  }
}

/// An automaton as the student writes it: for each state and symbol the
/// states it may go to (several, or none), ε moves under [lfaEps].
class Nfa {
  final int states;
  final Set<int> accepting;
  final Map<int, Map<String, Set<int>>> moves;
  const Nfa(this.states, this.accepting, this.moves);

  Set<int> targets(int s, String symbol) => moves[s]?[symbol] ?? const {};

  /// Exactly one move for every state and symbol of [alphabet], and no ε move.
  bool isDeterministic(List<String> alphabet) {
    for (var s = 0; s < states; s++) {
      if (targets(s, lfaEps).isNotEmpty) return false;
      for (final a in alphabet) {
        if (targets(s, a).length != 1) return false;
      }
    }
    return true;
  }

  Set<int> closure(Set<int> from) {
    final out = {...from};
    final todo = [...from];
    while (todo.isNotEmpty) {
      for (final t in targets(todo.removeLast(), lfaEps)) {
        if (out.add(t)) todo.add(t);
      }
    }
    return out;
  }

  Set<int> step(Set<int> from, String symbol) => closure({for (final s in from) ...targets(s, symbol)});

  /// The sets of states the automaton is in while reading [word], the start included.
  List<Set<int>> run(String word) {
    var cur = closure({0});
    final out = [cur];
    for (final ch in word.split('')) {
      cur = step(cur, ch);
      out.add(cur);
    }
    return out;
  }

  bool accepts(String word) => run(word).last.any(accepting.contains);

  /// The subset construction, over [alphabet].
  Dfa toDfa(List<String> alphabet) {
    String key(Set<int> s) => (s.toList()..sort()).join(',');
    final sets = <Set<int>>[closure({0})];
    final index = <String, int>{key(sets[0]): 0};
    final next = <List<int>>[];
    for (var i = 0; i < sets.length; i++) {
      final row = <int>[];
      for (final a in alphabet) {
        final t = step(sets[i], a);
        row.add(index.putIfAbsent(key(t), () {
          sets.add(t);
          return sets.length - 1;
        }));
      }
      next.add(row);
    }
    return Dfa(alphabet, next, [for (final s in sets) s.any(accepting.contains)]);
  }

  Map<String, dynamic> toJson() => {
        'states': states,
        'final': accepting.toList()..sort(),
        't': {
          for (final e in moves.entries)
            '${e.key}': {for (final m in e.value.entries) if (m.value.isNotEmpty) m.key: (m.value.toList()..sort())},
        },
      };

  factory Nfa.fromJson(Map j) => Nfa(
        (j['states'] as num).toInt(),
        {for (final f in j['final'] as List? ?? const []) (f as num).toInt()},
        {
          for (final e in (j['t'] as Map? ?? const {}).entries)
            int.parse('${e.key}'): {
              for (final m in (e.value as Map).entries) '${m.key}': {for (final t in m.value as List) (t as num).toInt()},
            },
        },
      );
}

// ---------------------------------------------------------------- regex
/// A regular expression in the course's writing: juxtaposition, `∪` or `|`
/// for union, `*`, `+` (one or more), `?`, `ε` for the empty word, `∅` for
/// the empty language, parentheses. Spaces are ignored.
class Regex {
  static const _union = {'|', '∪', 'U'};
  static const _eps = {lfaEps, 'λ', '_'};

  final String _s;
  final List<String> alphabet;
  int _i = 0;
  // Thompson's construction: states numbered as made, moves kept flat
  final List<(int, String, int)> _moves = [];
  int _n = 0;

  Regex._(this._s, this.alphabet);

  /// The automaton of [text], over [alphabet].
  static Nfa parse(String text, List<String> alphabet) {
    final r = Regex._(text.replaceAll(RegExp(r'\s'), ''), alphabet);
    if (r._s.isEmpty) throw const LfaError('Scrie o expresie.');
    final (a, b) = r._alt();
    if (r._i < r._s.length) throw LfaError('Nu înțeleg „${r._s[r._i]}” la poziția ${r._i + 1}.');
    // renumber so that the start is state 0
    int at(int s) => s == a ? 0 : (s == 0 ? a : s);
    final moves = <int, Map<String, Set<int>>>{};
    for (final (f, sym, t) in r._moves) {
      ((moves[at(f)] ??= {})[sym] ??= {}).add(at(t));
    }
    return Nfa(r._n, {at(b)}, moves);
  }

  int _new() => _n++;
  void _add(int f, String sym, int t) => _moves.add((f, sym, t));
  String? get _peek => _i < _s.length ? _s[_i] : null;

  (int, int) _alt() {
    var (a, b) = _cat();
    while (_peek != null && _union.contains(_peek)) {
      _i++;
      final (c, d) = _cat();
      final s = _new(), e = _new();
      _add(s, lfaEps, a);
      _add(s, lfaEps, c);
      _add(b, lfaEps, e);
      _add(d, lfaEps, e);
      (a, b) = (s, e);
    }
    return (a, b);
  }

  (int, int) _cat() {
    (int, int)? acc;
    while (_peek != null && _peek != ')' && !_union.contains(_peek)) {
      final (c, d) = _star();
      if (acc == null) {
        acc = (c, d);
      } else {
        _add(acc.$2, lfaEps, c);
        acc = (acc.$1, d);
      }
    }
    if (acc == null) throw LfaError(_peek == null ? 'Expresia se termină prea devreme.' : 'Lipsește ceva înainte de „$_peek”.');
    return acc;
  }

  (int, int) _star() {
    var (a, b) = _atom();
    while (_peek == '*' || _peek == '+' || _peek == '?') {
      final op = _s[_i++];
      final s = _new(), e = _new();
      _add(s, lfaEps, a);
      _add(b, lfaEps, e);
      if (op != '+') _add(s, lfaEps, e); // may be skipped
      if (op != '?') _add(b, lfaEps, a); // may repeat
      (a, b) = (s, e);
    }
    return (a, b);
  }

  (int, int) _atom() {
    final ch = _s[_i++];
    if (ch == '(') {
      if (_peek == ')') {
        _i++;
        final s = _new(), e = _new();
        _add(s, lfaEps, e);
        return (s, e);
      }
      final r = _alt();
      if (_peek != ')') throw const LfaError('Lipsește o paranteză „)”.');
      _i++;
      return r;
    }
    final s = _new(), e = _new();
    if (_eps.contains(ch)) {
      _add(s, lfaEps, e);
    } else if (ch == '∅' || ch == '@') {
      // no move: nothing is accepted
    } else if (alphabet.contains(ch)) {
      _add(s, ch, e);
    } else if (ch == ')' || ch == '*' || ch == '+' || ch == '?') {
      throw LfaError('„$ch” nu are ce să urmeze la poziția $_i.');
    } else {
      throw LfaError('„$ch” nu e în alfabet ({${alphabet.join(', ')}}).');
    }
    return (s, e);
  }
}

// ---------------------------------------------------------------- grammars
/// A context-free grammar: one rule per line, `S -> aSb | ε`. Capital letters
/// are nonterminals, the first rule's left side is the start symbol.
class Grammar {
  final String start;
  final Map<String, List<String>> rules; // an empty right side is ε

  const Grammar(this.start, this.rules);

  static Grammar parse(String text) {
    final rules = <String, List<String>>{};
    String? start;
    for (final (n, raw) in text.split('\n').indexed) {
      final line = raw.replaceAll(RegExp(r'\s'), '');
      if (line.isEmpty) continue;
      final m = RegExp(r'^([A-Z])(?:->|→|::=)(.*)$').firstMatch(line);
      if (m == null) throw LfaError('Linia ${n + 1}: scrie o regulă ca „S -> aSb | ε”.');
      start ??= m[1]!;
      for (final alt in m[2]!.split('|')) {
        final right = alt.replaceAll(lfaEps, '').replaceAll('λ', '').replaceAll('_', '');
        if (alt.isEmpty) throw LfaError('Linia ${n + 1}: o variantă e goală; pentru cuvântul vid scrie ε.');
        (rules[m[1]!] ??= []).add(right);
      }
    }
    if (start == null) throw const LfaError('Scrie cel puțin o regulă.');
    for (final rs in rules.values) {
      for (final r in rs) {
        for (final ch in r.split('')) {
          if (RegExp(r'[A-Z]').hasMatch(ch) && !rules.containsKey(ch)) throw LfaError('Neterminalul $ch nu are nicio regulă.');
        }
      }
    }
    return Grammar(start, rules);
  }

  /// Every word of at most [max] symbols the grammar generates.
  Set<String> words(int max) {
    final lang = {for (final a in rules.keys) a: <String>{}};
    var changed = true;
    while (changed) {
      changed = false;
      for (final e in rules.entries) {
        for (final right in e.value) {
          var acc = <String>{''};
          for (final ch in right.split('')) {
            final part = lang[ch] ?? {ch};
            acc = {
              for (final x in acc)
                for (final y in part)
                  if (x.length + y.length <= max) x + y,
            };
            if (acc.isEmpty) break;
          }
          final into = lang[e.key]!;
          final before = into.length;
          into.addAll(acc);
          if (into.length != before) changed = true;
        }
      }
    }
    return lang[start]!;
  }

  /// In Chomsky normal form: every rule is A -> BC or A -> a (S -> ε allowed).
  bool get isChomsky {
    for (final e in rules.entries) {
      for (final r in e.value) {
        final ok = (r.length == 1 && !RegExp(r'[A-Z]').hasMatch(r)) ||
            (r.length == 2 && RegExp(r'^[A-Z]{2}$').hasMatch(r)) ||
            (r.isEmpty && e.key == start);
        if (!ok) return false;
      }
    }
    return true;
  }
}

/// Every word over [alphabet] of at most [max] symbols, shortest first.
List<String> allWords(List<String> alphabet, int max) {
  final out = <String>[''];
  var layer = <String>[''];
  for (var n = 1; n <= max; n++) {
    layer = [for (final w in layer) for (final a in alphabet) w + a];
    out.addAll(layer);
  }
  return out;
}

// ---------------------------------------------------------------- the task
/// What a problem asks for and how an answer is judged.
class LfaTask {
  final String mode; // dfa, nfa, regex, cfg
  final List<String> alphabet;
  final String? refRegex;
  final String? refGrammar;
  final Map? refAutomaton; // the language given by an automaton instead
  final int? maxLen; // a regular expression: at most this many characters
  final int upTo; // grammars: words compared up to this length
  final int? maxStates;
  final bool chomsky;
  final Object reference; // an answer that solves it: text, or an automaton's json

  LfaTask(this.mode, this.alphabet, this.refRegex, this.refGrammar, this.refAutomaton, this.maxLen, this.upTo, this.maxStates, this.chomsky, this.reference);

  factory LfaTask.fromSpec(Map<String, dynamic> spec) => LfaTask(
        spec['mode'] as String,
        (spec['alphabet'] as String).split(''),
        spec['regex'] as String?,
        spec['grammar'] as String?,
        spec['automaton'] as Map?,
        (spec['maxLen'] as num?)?.toInt(),
        (spec['upTo'] as num?)?.toInt() ?? 8,
        (spec['maxStates'] as num?)?.toInt(),
        spec['chomsky'] == true,
        spec['reference'] as Object,
      );

  late final Dfa? _ref = refRegex != null
      ? Regex.parse(refRegex!, alphabet).toDfa(alphabet)
      : (refAutomaton != null ? Nfa.fromJson(refAutomaton!).toDfa(alphabet) : null);

  /// True when the language is regular here, so any word can be asked about.
  bool get exact => _ref != null;
  late final Set<String>? _refWords = refGrammar == null ? null : Grammar.parse(refGrammar!).words(upTo);

  /// Is [word] in the language asked for? (Grammars: only up to [upTo].)
  bool wants(String word) => _ref?.accepts(word) ?? _refWords!.contains(word);

  String _say(String w) => w.isEmpty ? 'cuvântul vid ε' : '„$w”';

  /// (label, ok, detail) for each thing checked.
  List<(String, bool, String)> _language(bool Function(String) mine, Dfa? asDfa) {
    String? bad;
    if (_ref != null && asDfa != null) {
      bad = _ref.difference(asDfa);
    } else {
      for (final w in allWords(alphabet, upTo)) {
        if (mine(w) != wants(w)) {
          bad = w;
          break;
        }
      }
    }
    final scope = _ref != null && asDfa != null ? '' : ' (toate cuvintele de cel mult $upTo simboluri)';
    if (bad == null) return [('descrie exact limbajul cerut$scope', true, '')];
    return [
      (
        'descrie exact limbajul cerut$scope',
        false,
        wants(bad) ? '${_say(bad)} este în limbaj, dar răspunsul tău nu îl acceptă' : '${_say(bad)} nu este în limbaj, dar răspunsul tău îl acceptă',
      ),
    ];
  }

  List<(String, bool, String)> checkAutomaton(Nfa a) {
    final out = <(String, bool, String)>[];
    if (mode == 'dfa') {
      final det = a.isDeterministic(alphabet);
      out.add(('este determinist și complet: o singură tranziție pentru fiecare stare și simbol', det, det ? '' : 'o căsuță e goală, are mai multe stări, sau există o ε-tranziție'));
    }
    if (maxStates != null) {
      out.add(('are cel mult $maxStates stări', a.states <= maxStates!, 'are ${a.states}'));
    }
    return [...out, ..._language(a.accepts, a.toDfa(alphabet))];
  }

  List<(String, bool, String)> checkRegex(String text) {
    final Nfa n;
    try {
      n = Regex.parse(text, alphabet);
    } on LfaError catch (e) {
      return [('expresia se poate citi', false, e.message)];
    }
    final len = text.replaceAll(RegExp(r'\s'), '').length;
    return [
      if (maxLen != null) ('are cel mult $maxLen caractere', len <= maxLen!, 'are $len'),
      ..._language(n.accepts, n.toDfa(alphabet)),
    ];
  }

  List<(String, bool, String)> checkGrammar(String text) {
    final Grammar g;
    try {
      g = Grammar.parse(text);
    } on LfaError catch (e) {
      return [('gramatica se poate citi', false, e.message)];
    }
    final words = g.words(upTo);
    return [
      if (chomsky) ('este în forma normală Chomsky (A -> BC sau A -> a)', g.isChomsky, 'o regulă are altă formă'),
      ..._language(words.contains, null),
    ];
  }

  /// The reference answer, judged the same way.
  List<(String, bool, String)> checkReference() => switch (mode) {
        'regex' => checkRegex(reference as String),
        'cfg' => checkGrammar(reference as String),
        _ => checkAutomaton(Nfa.fromJson(reference as Map)),
      };
}
