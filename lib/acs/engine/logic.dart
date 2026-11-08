// =============================================================================
// LOGIC FOR PL: boolean expressions, multiplexers, state machines
//   An expression is checked by its truth table against the target (minterms
//   and don't-cares), and by how it is written: which gates it uses, how many
//   literals, sum-of-products or product-of-sums. A multiplexer is checked by
//   the function it makes; a Mealy machine by equivalence with the target one
//   (a walk over the pairs of states), so any state names and any minimal
//   machine are accepted.
// =============================================================================

class LogicError implements Exception {
  final String message;
  LogicError(this.message);
  @override
  String toString() => message;
}

sealed class BExpr {}

class BVar extends BExpr {
  final String name;
  BVar(this.name);
}

class BConst extends BExpr {
  final bool v;
  BConst(this.v);
}

class BNot extends BExpr {
  final BExpr e;
  BNot(this.e);
}

class BBin extends BExpr {
  final String op; // and or xor nand nor xnor
  final BExpr l, r;
  BBin(this.op, this.l, this.r);
}

/// Parses: a b c (or names given), ' ! ~ ¬ (not), · * & or side by side (and),
/// + | ∨ (or), ^ ⊕ (xor), ⊙ (xnor), ↑ (nand), ↓ (nor), 0 1, parentheses.
class BoolParser {
  final String s;
  final List<String> vars;
  int i = 0;
  BoolParser(this.s, this.vars);

  static BExpr parse(String s, List<String> vars) {
    final p = BoolParser(s, [...vars]..sort((a, b) => b.length.compareTo(a.length)));
    if (s.trim().isEmpty) throw LogicError('scrie o expresie');
    final e = p._or();
    p._ws();
    if (p.i < s.length) throw LogicError('nu înțeleg „${s.substring(p.i)}”');
    return e;
  }

  void _ws() {
    while (i < s.length && (s[i] == ' ' || s[i] == '\t')) {
      i++;
    }
  }

  bool _eat(String chars) {
    _ws();
    if (i < s.length && chars.contains(s[i])) {
      i++;
      return true;
    }
    return false;
  }

  BExpr _or() {
    var l = _xor();
    while (true) {
      if (_eat('+|∨')) {
        l = BBin('or', l, _xor());
      } else if (_eat('↓')) {
        l = BBin('nor', l, _xor());
      } else {
        return l;
      }
    }
  }

  BExpr _xor() {
    var l = _and();
    while (true) {
      if (_eat('^⊕')) {
        l = BBin('xor', l, _and());
      } else if (_eat('⊙')) {
        l = BBin('xnor', l, _and());
      } else {
        return l;
      }
    }
  }

  bool _startsFactor() {
    _ws();
    if (i >= s.length) return false;
    final c = s[i];
    return c == '(' || c == '!' || c == '~' || c == '¬' || c == '0' || c == '1' || RegExp(r'[A-Za-z]').hasMatch(c);
  }

  BExpr _and() {
    var l = _unary();
    while (true) {
      if (_eat('·*&∧')) {
        l = BBin('and', l, _unary());
      } else if (_eat('↑')) {
        l = BBin('nand', l, _unary());
      } else if (_startsFactor()) {
        l = BBin('and', l, _unary());
      } else {
        return l;
      }
    }
  }

  BExpr _unary() {
    if (_eat('!~¬')) return BNot(_unary());
    var e = _primary();
    while (_eat("'’")) {
      e = BNot(e);
    }
    return e;
  }

  BExpr _primary() {
    _ws();
    if (i >= s.length) throw LogicError('expresia se termină prea devreme');
    final c = s[i];
    if (c == '(') {
      i++;
      final e = _or();
      if (!_eat(')')) throw LogicError('lipsește „)”');
      return e;
    }
    if (c == '0' || c == '1') {
      i++;
      return BConst(c == '1');
    }
    for (final v in vars) {
      if (s.startsWith(v, i)) {
        i += v.length;
        return BVar(v);
      }
    }
    throw LogicError('„$c” nu e o variabilă (variabilele sunt ${vars.join(', ')})');
  }
}

class Bool {
  static bool eval(BExpr e, Map<String, bool> a) => switch (e) {
        BVar(:final name) => a[name] ?? false,
        BConst(:final v) => v,
        BNot(:final e) => !eval(e, a),
        BBin(:final op, :final l, :final r) => switch (op) {
            'and' => eval(l, a) && eval(r, a),
            'or' => eval(l, a) || eval(r, a),
            'xor' => eval(l, a) != eval(r, a),
            'xnor' => eval(l, a) == eval(r, a),
            'nand' => !(eval(l, a) && eval(r, a)),
            _ => !(eval(l, a) || eval(r, a)),
          },
      };

  /// Row k of the truth table: the first variable is the most significant bit.
  static Map<String, bool> row(List<String> vars, int k) => {for (var j = 0; j < vars.length; j++) vars[j]: (k >> (vars.length - 1 - j)) & 1 == 1};

  static List<bool> table(BExpr e, List<String> vars) => [for (var k = 0; k < 1 << vars.length; k++) eval(e, row(vars, k))];

  static int literals(BExpr e) => switch (e) {
        BVar() => 1,
        BConst() => 0,
        BNot(:final e) => literals(e),
        BBin(:final l, :final r) => literals(l) + literals(r),
      };

  /// The gates used: not and or xor xnor nand nor.
  static Set<String> ops(BExpr e) => switch (e) {
        BVar() || BConst() => {},
        BNot(:final e) => {'not', ...ops(e)},
        BBin(:final op, :final l, :final r) => {op, ...ops(l), ...ops(r)},
      };

  static bool _literal(BExpr e) => e is BVar || (e is BNot && e.e is BVar);

  static List<BExpr> _flat(BExpr e, String op) => e is BBin && e.op == op ? [..._flat(e.l, op), ..._flat(e.r, op)] : [e];

  /// A sum of products of literals (a single product or literal counts too).
  static bool isSop(BExpr e) => _flat(e, 'or').every((t) => _flat(t, 'and').every(_literal));

  static bool isPos(BExpr e) => _flat(e, 'and').every((t) => _flat(t, 'or').every(_literal));
}

/// One output to write: its target as minterms (and don't-cares).
class LogicTarget {
  final String name;
  final Set<int> ones;
  final Set<int> dc;
  LogicTarget(this.name, this.ones, this.dc);

  factory LogicTarget.fromJson(Map j) => LogicTarget(j['name'] as String? ?? 'f', {for (final m in j['ones'] as List) (m as num).toInt()}, {for (final m in j['dc'] as List? ?? const []) (m as num).toInt()});
}

class LogicCheck {
  final String label;
  final bool ok;
  final String detail;
  const LogicCheck(this.label, this.ok, [this.detail = '']);
}

class ExprTask {
  final List<String> vars;
  final List<LogicTarget> outputs;
  final Set<String>? allowed; // the gates that may be used
  final int? maxLiterals;
  final String? form; // sop, pos
  ExprTask(this.vars, this.outputs, this.allowed, this.maxLiterals, this.form);

  factory ExprTask.fromSpec(Map s) => ExprTask(
        [for (final v in s['vars'] as List) '$v'],
        [for (final o in s['outputs'] as List) LogicTarget.fromJson(o as Map)],
        s['allowed'] == null ? null : {for (final o in s['allowed'] as List) '$o'},
        (s['maxLiterals'] as num?)?.toInt(),
        s['form'] as String?,
      );

  static const opNames = {'not': 'NOT', 'and': 'AND', 'or': 'OR', 'xor': 'XOR', 'xnor': 'XNOR', 'nand': 'NAND', 'nor': 'NOR'};

  List<LogicCheck> check(String name, String text) {
    final t = outputs.firstWhere((o) => o.name == name);
    final BExpr e;
    try {
      e = BoolParser.parse(text, vars);
    } on LogicError catch (x) {
      return [LogicCheck('$name: expresia se citește', false, x.message)];
    }
    final out = <LogicCheck>[];
    final tab = Bool.table(e, vars);
    final wrong = [for (var k = 0; k < tab.length; k++) if (!t.dc.contains(k) && tab[k] != t.ones.contains(k)) k];
    out.add(LogicCheck('$name: tabelul de adevăr e cel cerut', wrong.isEmpty,
        wrong.isEmpty ? '' : 'diferă pe ${wrong.length} ${wrong.length == 1 ? 'rând' : 'rânduri'}: ${wrong.take(6).map((k) => '${_bits(k)} (m$k)').join(', ')}${wrong.length > 6 ? '…' : ''}'));
    if (allowed != null) {
      final extra = Bool.ops(e).difference(allowed!);
      out.add(LogicCheck('$name: folosește doar ${allowed!.map((o) => opNames[o]).join(', ')}', extra.isEmpty, extra.isEmpty ? '' : 'folosește și ${extra.map((o) => opNames[o]).join(', ')}'));
    }
    if (form == 'sop') out.add(LogicCheck('$name: e o sumă de produse', Bool.isSop(e), 'nu e de forma termen + termen + ..., cu termeni produse de literali'));
    if (form == 'pos') out.add(LogicCheck('$name: e un produs de sume', Bool.isPos(e), 'nu e de forma (sumă)(sumă)..., cu sume de literali'));
    if (maxLiterals != null) {
      final n = Bool.literals(e);
      out.add(LogicCheck('$name: are cel mult $maxLiterals literali (forma minimă)', n <= maxLiterals!, 'are $n literali'));
    }
    return out;
  }

  String _bits(int k) => k.toRadixString(2).padLeft(vars.length, '0');
}

/// A 2^s:1 multiplexer: the select lines (variables, most significant first)
/// and, for each data input, 0, 1, a variable or its negation (v').
class MuxTask {
  final List<String> vars;
  final LogicTarget target;
  final int selects;
  MuxTask(this.vars, this.target, this.selects);

  factory MuxTask.fromSpec(Map s) => MuxTask([for (final v in s['vars'] as List) '$v'], LogicTarget.fromJson((s['outputs'] as List).first as Map), (s['selects'] as num).toInt());

  List<String> inputChoices(List<String> sel) {
    final rest = vars.where((v) => !sel.contains(v)).toList();
    return ['0', '1', for (final v in rest) ...[v, "$v'"]];
  }

  bool _value(String choice, Map<String, bool> a) {
    if (choice == '0') return false;
    if (choice == '1') return true;
    if (choice.endsWith("'")) return !(a[choice.substring(0, choice.length - 1)] ?? false);
    return a[choice] ?? false;
  }

  List<bool> table(List<String> sel, List<String> data) {
    return [
      for (var k = 0; k < 1 << vars.length; k++)
        () {
          final a = Bool.row(vars, k);
          var idx = 0;
          for (final s in sel) {
            idx = idx * 2 + ((a[s] ?? false) ? 1 : 0);
          }
          return _value(data[idx], a);
        }(),
    ];
  }

  List<LogicCheck> check(List<String> sel, List<String> data) {
    if (sel.toSet().length != sel.length) return [const LogicCheck('liniile de selecție sunt variabile diferite', false)];
    final tab = table(sel, data);
    final wrong = [for (var k = 0; k < tab.length; k++) if (!target.dc.contains(k) && tab[k] != target.ones.contains(k)) k];
    return [LogicCheck('multiplexorul realizează funcția', wrong.isEmpty, wrong.isEmpty ? '' : 'diferă pe mintermii ${wrong.join(', ')}')];
  }
}

/// A Mealy machine: for each state and input bit, the next state and the output.
class Mealy {
  final List<String> states;
  final Map<String, List<(String, int)>> t; // state -> [for input 0, for input 1]
  final String start;
  Mealy(this.states, this.t, this.start);

  factory Mealy.fromJson(Map j) => Mealy(
        [for (final s in j['states'] as List) '$s'],
        {
          for (final e in (j['t'] as Map).entries)
            '${e.key}': [for (final x in e.value as List) ('${(x as List)[0]}', (x[1] as num).toInt())],
        },
        j['start'] as String,
      );

  /// The outputs for an input string of 0s and 1s.
  String run(String input) {
    var s = start;
    final out = StringBuffer();
    for (final c in input.split('')) {
      final k = c == '1' ? 1 : 0;
      final (n, o) = t[s]![k];
      out.write(o);
      s = n;
    }
    return out.toString();
  }

  /// The shortest input on which the two machines answer differently; null if equivalent.
  static String? difference(Mealy a, Mealy b) {
    final seen = <String>{};
    final queue = <(String, String, String)>[(a.start, b.start, '')];
    seen.add('${a.start}|${b.start}');
    while (queue.isNotEmpty) {
      final (x, y, path) = queue.removeAt(0);
      for (final k in [0, 1]) {
        final (nx, ox) = a.t[x]![k];
        final (ny, oy) = b.t[y]![k];
        if (ox != oy) return '$path$k';
        if (seen.add('$nx|$ny')) queue.add((nx, ny, '$path$k'));
      }
    }
    return null;
  }
}

class FsmTask {
  final Mealy target;
  final int maxStates;
  FsmTask(this.target, this.maxStates);

  factory FsmTask.fromSpec(Map s) => FsmTask(Mealy.fromJson(s['target'] as Map), (s['maxStates'] as num).toInt());

  List<LogicCheck> check(Mealy m) {
    for (final st in m.states) {
      for (final (n, _) in m.t[st]!) {
        if (!m.states.contains(n)) return [LogicCheck('tranzițiile duc în stări existente', false, 'din $st se ajunge în „$n”, care nu e în tabel')];
      }
    }
    final d = Mealy.difference(target, m);
    return [
      LogicCheck('automatul se comportă cum se cere', d == null,
          d == null ? '' : 'pe intrarea $d ar trebui să dea ${target.run(d)}, dar dă ${m.run(d)}'),
      LogicCheck('are cel mult $maxStates stări', m.states.length <= maxStates, 'are ${m.states.length}'),
    ];
  }
}
