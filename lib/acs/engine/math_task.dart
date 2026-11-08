// =============================================================================
// MATHS ANSWERS, CHECKED BY WHAT THEY ARE (AM, MS, ALGAED)
//   An answer is a formula (in x, or x and y, or s, t, n...), a number, a
//   matrix or a list of points. It is not compared as text: the checks are
//   properties written in Octave, over the student's values — an
//   antiderivative must differentiate back to f, a solution of a
//   differential equation must satisfy it, P must diagonalise A. So any
//   correct form is accepted ("x^2/2 + 3", "(x*x + 6)/2", ...).
//
//   A formula is written as on paper: 2x, x^2, sin x... is turned into an
//   Octave function (implicit ·, ^ → .^, ln → log, e and pi).
// =============================================================================

import 'octave.dart';

class MathError implements Exception {
  final String message;
  MathError(this.message);
  @override
  String toString() => message;
}

/// Functions a formula may use, with their Octave names.
const Map<String, String> mathFunctions = {
  'sin': 'sin', 'cos': 'cos', 'tan': 'tan', 'tg': 'tan', 'ctg': '1./tan', 'cot': '1./tan', 'exp': 'exp', 'ln': 'log', 'log': 'log', 'sqrt': 'sqrt', 'abs': 'abs',
  'arcsin': 'asin', 'arccos': 'acos', 'arctan': 'atan', 'arctg': 'atan', 'asin': 'asin', 'acos': 'acos', 'atan': 'atan', 'sinh': 'sinh', 'cosh': 'cosh', 'tanh': 'tanh',
  'sh': 'sinh', 'ch': 'cosh', 'th': 'tanh', 'sign': 'sign', 'floor': 'floor',
};

/// A formula as written by the student, into an Octave expression (element-wise).
String toOctave(String src, List<String> vars, {Map<String, String> constants = const {}}) {
  final s = src.replaceAll('·', '*').replaceAll('×', '*').replaceAll('−', '-').replaceAll('π', 'pi').replaceAll('√', 'sqrt').replaceAll(',', '.').trim();
  if (s.isEmpty) throw MathError('scrie o expresie');
  final toks = <(String, String)>[]; // kind, text: num id op
  var i = 0;
  while (i < s.length) {
    final c = s[i];
    if (c == ' ' || c == '\t') {
      i++;
      continue;
    }
    final num = RegExp(r'\d+\.?\d*(?:[eE][+-]?\d+)?|\.\d+').matchAsPrefix(s, i);
    if (num != null) {
      toks.add(('num', num[0]!));
      i = num.end;
      continue;
    }
    final id = RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, i);
    if (id != null) {
      var w = id[0]!;
      // split run-together names: "xy" -> x y, "xsin" -> x sin, "2pi" handled by numbers
      final out = <String>[];
      while (w.isNotEmpty) {
        String? hit;
        for (final cand in [...mathFunctions.keys, 'pi', ...vars, ...constants.keys, 'e']..sort((a, b) => b.length.compareTo(a.length))) {
          if (w.startsWith(cand)) {
            hit = cand;
            break;
          }
        }
        if (hit == null) throw MathError('nu știu ce e „$w” (variabile: ${vars.join(', ')})');
        out.add(hit);
        w = w.substring(hit.length);
      }
      for (final o in out) {
        toks.add(('id', o));
      }
      i = id.end;
      continue;
    }
    if ('+-*/^()'.contains(c)) {
      toks.add(('op', c));
      i++;
      continue;
    }
    if (c == '[' || c == ']' || c == '{' || c == '}') {
      toks.add(('op', c == '[' || c == '{' ? '(' : ')'));
      i++;
      continue;
    }
    throw MathError('caracter neașteptat: „$c”');
  }
  bool endsOperand((String, String) t) => t.$1 == 'num' || (t.$1 == 'id' && !mathFunctions.containsKey(t.$2)) || (t.$1 == 'op' && t.$2 == ')');
  bool startsOperand((String, String) t) => t.$1 == 'num' || t.$1 == 'id' || (t.$1 == 'op' && t.$2 == '(');
  final b = StringBuffer();
  var depth = 0;
  for (var k = 0; k < toks.length; k++) {
    final t = toks[k];
    if (k > 0 && endsOperand(toks[k - 1]) && startsOperand(t)) b.write('.*');
    switch (t.$1) {
      case 'num':
        b.write(t.$2);
      case 'id':
        final f = mathFunctions[t.$2];
        if (f != null) {
          // sin x (without parentheses): the function takes the next factor
          final next = k + 1 < toks.length ? toks[k + 1] : null;
          if (next == null) throw MathError('după ${t.$2} lipsește argumentul');
          if (next.$1 == 'op' && next.$2 == '(') {
            b.write(f);
          } else {
            // wrap the next simple factor: sin x, sin 2x, ln x^2 (as ln(x^2))
            var j = k + 1;
            final arg = StringBuffer();
            var prevOperand = false;
            while (j < toks.length) {
              final u = toks[j];
              if (u.$1 == 'num' || (u.$1 == 'id' && !mathFunctions.containsKey(u.$2))) {
                if (prevOperand) arg.write('.*');
                arg.write(u.$1 == 'id' ? _id(u.$2, vars, constants) : u.$2);
                prevOperand = true;
                j++;
                if (j < toks.length && toks[j].$1 == 'op' && toks[j].$2 == '^' && j + 1 < toks.length && toks[j + 1].$1 == 'num') {
                  arg.write('.^${toks[j + 1].$2}');
                  j += 2;
                }
                continue;
              }
              break;
            }
            if (arg.isEmpty) throw MathError('după ${t.$2} lipsește argumentul (scrie ${t.$2}(...))');
            b.write('$f(${arg.toString()})');
            k = j - 1;
          }
        } else {
          b.write(_id(t.$2, vars, constants));
        }
      default:
        if (t.$2 == '(') depth++;
        if (t.$2 == ')') depth--;
        if (depth < 0) throw MathError('paranteze nepotrivite');
        b.write(switch (t.$2) { '*' => '.*', '/' => './', '^' => '.^', _ => t.$2 });
    }
  }
  if (depth != 0) throw MathError('paranteze nepotrivite');
  return b.toString();
}

String _id(String name, List<String> vars, Map<String, String> constants) {
  if (vars.contains(name)) return name;
  if (constants.containsKey(name)) return '(${constants[name]})';
  if (name == 'pi') return 'pi';
  if (name == 'e') return 'e';
  throw MathError('nu știu ce e „$name”');
}

/// Helpers the checks can call (numeric derivatives, the gradient...).
const String mathPrelude = r'''
function d = deriv(f, x)
    h = 1e-5;
    d = (f(x + h) - f(x - h)) / (2 * h);
end
function d = deriv2(f, x)
    h = 1e-4;
    d = (f(x + h) - 2 * f(x) + f(x - h)) / (h * h);
end
function d = dx(f, x, y)
    h = 1e-6;
    d = (f(x + h, y) - f(x - h, y)) / (2 * h);
end
function d = dy(f, x, y)
    h = 1e-6;
    d = (f(x, y + h) - f(x, y - h)) / (2 * h);
end
function r = same_points(P, T, E, kinds)
    % the points P (with types T) are exactly the rows of E = [x y type]
    r = false;
    if rows(P) ~= rows(E)
        return;
    end
    used = zeros(rows(E), 1);
    for i = 1:rows(P)
        hit = 0;
        for j = 1:rows(E)
            if ~used(j) && abs(P(i, 1) - E(j, 1)) < 1e-6 && abs(P(i, 2) - E(j, 2)) < 1e-6
                if nargin < 4 || T(i) == E(j, 3)
                    hit = j;
                end
            end
        end
        if hit == 0
            return;
        end
        used(hit) = 1;
    end
    r = true;
end
function r = close(a, b, tol)
    if nargin < 3
        tol = 1e-6;
    end
    r = all(abs(a(:) - b(:)) <= tol * max(1, abs(b(:))));
end
''';

class MathField {
  final String name, label, type; // expr number matrix points
  final List<String> vars;
  final int rows, cols;
  final bool kinds; // points: each with min / max / șa
  final String hint;
  MathField(this.name, this.label, this.type, this.vars, this.rows, this.cols, this.kinds, this.hint);

  factory MathField.fromJson(Map j) => MathField(
        j['name'] as String,
        j['label'] as String? ?? j['name'] as String,
        j['type'] as String? ?? 'expr',
        [for (final v in j['vars'] as List? ?? const ['x']) '$v'],
        (j['rows'] as num?)?.toInt() ?? 1,
        (j['cols'] as num?)?.toInt() ?? 1,
        j['kinds'] == true,
        j['hint'] as String? ?? '',
      );
}

/// What the student entered for one field.
class MathAnswer {
  final String text; // expr / number
  final List<List<String>> cells; // matrix
  final List<(String, String, String)> points; // x, y, kind
  const MathAnswer({this.text = '', this.cells = const [], this.points = const []});
}

class MathCheck {
  final String label;
  final bool ok;
  final String detail;
  const MathCheck(this.label, this.ok, [this.detail = '']);
}

class MathTask {
  final List<MathField> fields;
  final List<(String, String)> checks; // octave condition, what it means
  final Map<String, String> constants;
  MathTask(this.fields, this.checks, this.constants);

  factory MathTask.fromSpec(Map s) => MathTask(
        [for (final f in s['fields'] as List) MathField.fromJson(f as Map)],
        [for (final c in s['checks'] as List) ('${(c as Map)['expr']}', '${c['msg']}')],
        {for (final e in ((s['constants'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
      );

  /// A number written as an expression: 3/4, sqrt(2)/2, 2pi, e^2.
  static double number(String text, [Map<String, String> constants = const {}]) {
    final o = Octave();
    final v = o.evalExpr(toOctave(text, const [], constants: constants));
    if (v is! Mat || !v.isScalar) throw MathError('se aștepta un număr');
    return v.d[0];
  }

  /// The student's values, as Octave values named like the fields.
  Map<String, OVal> values(Map<String, MathAnswer> answers) {
    final env = <String, OVal>{};
    for (final f in fields) {
      final a = answers[f.name] ?? const MathAnswer();
      switch (f.type) {
        case 'expr':
          final code = '@(${f.vars.join(', ')}) ${toOctave(a.text, f.vars, constants: constants)}';
          env[f.name] = Octave().evalExpr(code);
        case 'number':
          env[f.name] = Mat.scalar(number(a.text, constants));
        case 'matrix':
          final m = Mat.zeros(f.rows, f.cols);
          for (var i = 0; i < f.rows; i++) {
            for (var j = 0; j < f.cols; j++) {
              final t = i < a.cells.length && j < a.cells[i].length ? a.cells[i][j] : '';
              if (t.trim().isEmpty) throw MathError('${f.label}: căsuța (${i + 1}, ${j + 1}) e goală');
              m.set(i, j, number(t, constants));
            }
          }
          env[f.name] = m;
        case 'points':
          final pts = a.points.where((p) => p.$1.trim().isNotEmpty || p.$2.trim().isNotEmpty).toList();
          final m = Mat.zeros(pts.length, 2);
          final kinds = Mat.zeros(pts.length, 1);
          for (var k = 0; k < pts.length; k++) {
            m.set(k, 0, number(pts[k].$1, constants));
            m.set(k, 1, number(pts[k].$2, constants));
            kinds.set(k, 0, switch (pts[k].$3) { 'min' => 1, 'max' => -1, 'șa' => 0, _ => 9 });
          }
          env[f.name] = m;
          env['${f.name}_tip'] = kinds;
      }
    }
    return env;
  }

  List<MathCheck> verify(Map<String, MathAnswer> answers) {
    Map<String, OVal> env;
    try {
      env = values(answers);
    } on MathError catch (e) {
      return [MathCheck('răspunsul se poate citi', false, e.message)];
    } on OctError catch (e) {
      return [MathCheck('răspunsul se poate citi', false, e.message)];
    }
    final o = Octave()..load(mathPrelude);
    final out = <MathCheck>[];
    for (final (expr, msg) in checks) {
      try {
        final v = o.evalExpr(expr, env);
        out.add(MathCheck(msg, Octave.truthy(v)));
      } on OctError catch (e) {
        out.add(MathCheck(msg, false, 'nu s-a putut calcula: ${e.message}'));
      }
    }
    return out;
  }

  /// A formula's values at [xs] (for the plots); null where it can't be read.
  static List<double>? sample(String text, List<String> vars, List<double> xs, [Map<String, String> constants = const {}]) {
    try {
      final f = Octave().evalExpr('@(${vars.join(', ')}) ${toOctave(text, vars, constants: constants)}') as OFunc;
      final o = Octave();
      final v = o.call('feval', [f, Mat(1, xs.length, xs)], 1).first as Mat;
      if (v.n == 1) return List.filled(xs.length, v.d[0]);
      return v.d;
    } catch (_) {
      return null;
    }
  }

  /// A function of two variables on a grid (for the heat map), row by row.
  static List<double>? grid(String octaveFn, List<double> xs, List<double> ys) {
    try {
      final o = Octave();
      final f = o.evalExpr(octaveFn) as OFunc;
      final out = <double>[];
      for (final y in ys) {
        final v = o.call('feval', [f, Mat(1, xs.length, xs), Mat.scalar(y)], 1).first as Mat;
        out.addAll(v.n == 1 ? List.filled(xs.length, v.d[0]) : v.d);
      }
      return out;
    } catch (_) {
      return null;
    }
  }
}
