// =============================================================================
// A SMALL OCTAVE, FOR MN (and the checks of the maths courses)
//   Real matrices (column-major, as Octave keeps them), strings, function
//   handles. [1 2; 3 4], a:s:b, A(i, :), A(end, 1), x(end+1) = ..., ' and .',
//   + - * / \ .* ./ .^ ^, comparisons, & | && || ~; if / elseif / else,
//   for, while, break, continue, return; function files with several
//   outputs; anonymous functions @(x) ...; the usual built-ins.
//   Statements without ; print their value, as Octave does.
// =============================================================================

import 'dart:math' as math;

class OctError implements Exception {
  final String message;
  final int line;
  OctError(this.message, [this.line = 0]);
  @override
  String toString() => line > 0 ? 'error (linia $line): $message' : 'error: $message';
}

// ---------------------------------------------------------------- values
sealed class OVal {}

class Mat extends OVal {
  final int r, c;
  final List<double> d; // column-major
  final bool logical;
  Mat(this.r, this.c, this.d, {this.logical = false});

  factory Mat.scalar(num v, {bool logical = false}) => Mat(1, 1, [v.toDouble()], logical: logical);
  factory Mat.zeros(int r, int c) => Mat(r, c, List.filled(r * c, 0.0));
  factory Mat.rows(List<List<num>> rows) {
    final r = rows.length, c = r == 0 ? 0 : rows[0].length;
    final m = Mat.zeros(r, c);
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        m.set(i, j, rows[i][j].toDouble());
      }
    }
    return m;
  }

  static final Mat empty = Mat(0, 0, const []);

  int get n => r * c;
  bool get isScalar => r == 1 && c == 1;
  bool get isEmpty => n == 0;
  bool get isVector => r == 1 || c == 1;
  double at(int i, int j) => d[j * r + i];
  void set(int i, int j, double v) => d[j * r + i] = v;
  double get scalar {
    if (!isScalar) throw OctError('se aștepta un număr, dar e o matrice $r×$c');
    return d[0];
  }

  Mat copy({bool? logical}) => Mat(r, c, List.of(d), logical: logical ?? this.logical);
  Mat get t {
    final m = Mat.zeros(c, r);
    for (var i = 0; i < r; i++) {
      for (var j = 0; j < c; j++) {
        m.set(j, i, at(i, j));
      }
    }
    return m;
  }

  List<List<double>> toRows() => [for (var i = 0; i < r; i++) [for (var j = 0; j < c; j++) at(i, j)]];
}

class OStr extends OVal {
  final String s;
  OStr(this.s);
}

class OFunc extends OVal {
  final List<String> params;
  final OExpr? body; // anonymous
  final String? name; // a named function or built-in
  final Map<String, OVal> captured;
  OFunc(this.params, this.body, this.name, this.captured);
}

// ---------------------------------------------------------------- lexer
class OTok {
  final String k; // num str id op kw nl eof
  final String v;
  final int line;
  final bool spaceBefore;
  const OTok(this.k, this.v, this.line, this.spaceBefore);
  @override
  String toString() => '$k:$v';
}

const _kw = {'if', 'elseif', 'else', 'end', 'endif', 'for', 'endfor', 'while', 'endwhile', 'function', 'endfunction', 'return', 'break', 'continue', 'do', 'until', 'switch', 'case', 'otherwise', 'endswitch'};

List<OTok> _lex(String s) {
  final out = <OTok>[];
  var i = 0, line = 1, depth = 0; // depth of [ ] (inside: spaces separate)
  final brackets = <String>[];
  bool operandEnd() {
    if (out.isEmpty) return false;
    final t = out.last;
    if (t.k == 'num' || t.k == 'str' || t.k == 'id') return true;
    if (t.k == 'kw' && t.v == 'end' && brackets.isNotEmpty && brackets.last == '(') return true;
    return t.k == 'op' && (t.v == ')' || t.v == ']' || t.v == '}' || t.v == "'" || t.v == ".'");
  }

  while (i < s.length) {
    final c = s[i];
    final inMatrix = brackets.isNotEmpty && (brackets.last == '[' || brackets.last == '{');
    if (c == ' ' || c == '\t' || c == '\r') {
      var j = i;
      while (j < s.length && (s[j] == ' ' || s[j] == '\t' || s[j] == '\r')) {
        j++;
      }
      if (inMatrix && operandEnd() && j < s.length) {
        final n = s[j];
        final next2 = j + 1 < s.length ? s[j + 1] : '';
        final startsOperand = RegExp(r'[A-Za-z0-9_.(\[@~!"' "'" r']').hasMatch(n) && !(n == '.' && RegExp(r'[*/\\^' "'" r']').hasMatch(next2));
        final signed = (n == '+' || n == '-') && next2 != ' ' && next2 != '\t';
        final notEq = n == '~' && next2 == '=';
        if ((startsOperand && !notEq) || signed) out.add(OTok('op', ',', line, true));
      }
      i = j;
      continue;
    }
    if (c == '.' && s.startsWith('...', i)) {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      i++;
      line++;
      continue;
    }
    if (c == '%' || c == '#') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      continue;
    }
    final sp = i > 0 && (s[i - 1] == ' ' || s[i - 1] == '\t');
    if (c == '\n') {
      out.add(OTok(inMatrix ? 'op' : 'nl', inMatrix ? ';' : '\n', line, sp));
      line++;
      i++;
      continue;
    }
    if (c == "'" && operandEnd() && !(inMatrix && sp)) {
      out.add(OTok('op', "'", line, sp));
      i++;
      continue;
    }
    if (c == "'" || c == '"') {
      final b = StringBuffer();
      var j = i + 1;
      while (true) {
        if (j >= s.length || s[j] == '\n') throw OctError('șir neterminat', line);
        if (s[j] == c) {
          if (j + 1 < s.length && s[j + 1] == c) {
            b.write(c);
            j += 2;
            continue;
          }
          break;
        }
        if (c == '"' && s[j] == '\\' && j + 1 < s.length) {
          final e = s[j + 1];
          b.write(switch (e) { 'n' => '\n', 't' => '\t', '\\' => '\\', '"' => '"', _ => '\\$e' });
          j += 2;
          continue;
        }
        b.write(s[j]);
        j++;
      }
      out.add(OTok('str', b.toString(), line, sp));
      i = j + 1;
      continue;
    }
    final num = RegExp(r"(\d+(?:\.(?![*/\\^'])\d*)?|\.\d+)([eE][+-]?\d+)?[ij]?").matchAsPrefix(s, i);
    if (num != null && !(c == '.' && i + 1 < s.length && !RegExp(r'\d').hasMatch(s[i + 1]))) {
      final t = num[0]!;
      if (t.endsWith('i') || t.endsWith('j')) throw OctError('numerele complexe nu sunt acceptate aici', line);
      out.add(OTok('num', t, line, sp));
      i = num.end;
      continue;
    }
    final id = RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, i);
    if (id != null) {
      final w = id[0]!;
      out.add(OTok(_kw.contains(w) ? 'kw' : 'id', w, line, sp));
      i = id.end;
      continue;
    }
    String? op;
    for (final o in ['.^', ".'", '.*', './', '.\\', '==', '~=', '!=', '<=', '>=', '&&', '||', '++', '--', '+=', '-=', '*=', '/=']) {
      if (s.startsWith(o, i)) {
        op = o;
        break;
      }
    }
    if (op == '++' || op == '--') op = null; // read as two signs
    if (op != null && (op.endsWith('=') && op.length == 2 && '+-*/'.contains(op[0]))) {
      // x += 1: only right after a name
      if (!(out.isNotEmpty && out.last.k == 'id')) op = null;
    }
    op ??= '+-*/\\^<>=&|~!()[]{},;:@'.contains(c) ? c : null;
    if (op == null) throw OctError("caracter neașteptat: '$c'", line);
    if (op == '(' || op == '[' || op == '{') brackets.add(op);
    if ((op == ')' || op == ']' || op == '}') && brackets.isNotEmpty) brackets.removeLast();
    depth = brackets.length;
    out.add(OTok('op', op == '!=' ? '~=' : op, line, sp));
    i += op.length;
  }
  out.add(OTok('eof', '', line, false));
  if (depth < 0) throw OctError('paranteze nepotrivite');
  return out;
}

// ---------------------------------------------------------------- tree
sealed class OExpr {
  int line = 0;
}

class ENum extends OExpr {
  final double v;
  ENum(this.v);
}

class EStr extends OExpr {
  final String v;
  EStr(this.v);
}

class EId extends OExpr {
  final String name;
  EId(this.name);
}

class EColonAll extends OExpr {}

class EEnd extends OExpr {}

class EBin extends OExpr {
  final String op;
  final OExpr l, r;
  EBin(this.op, this.l, this.r);
}

class EUn extends OExpr {
  final String op;
  final OExpr e;
  EUn(this.op, this.e);
}

class EPost extends OExpr {
  final String op; // ' .'
  final OExpr e;
  EPost(this.op, this.e);
}

class ERange extends OExpr {
  final OExpr a;
  final OExpr? step;
  final OExpr b;
  ERange(this.a, this.step, this.b);
}

class ECall extends OExpr {
  final OExpr target;
  final List<OExpr> args;
  ECall(this.target, this.args);
}

class EMatrix extends OExpr {
  final List<List<OExpr>> rows;
  EMatrix(this.rows);
}

class EAnon extends OExpr {
  final List<String> params;
  final OExpr body;
  EAnon(this.params, this.body);
}

class EHandle extends OExpr {
  final String name;
  EHandle(this.name);
}

sealed class OStmt {
  int line = 0;
}

class SExpr extends OStmt {
  final OExpr e;
  final bool show;
  SExpr(this.e, this.show);
}

class SAssign extends OStmt {
  final List<OExpr> targets; // EId or ECall(EId, idx)
  final OExpr value;
  final bool show;
  final String op; // = += -= *= /=
  SAssign(this.targets, this.value, this.show, [this.op = '=']);
}

class SIf extends OStmt {
  final List<(OExpr, List<OStmt>)> branches;
  final List<OStmt>? orElse;
  SIf(this.branches, this.orElse);
}

class SFor extends OStmt {
  final String v;
  final OExpr range;
  final List<OStmt> body;
  SFor(this.v, this.range, this.body);
}

class SWhile extends OStmt {
  final OExpr cond;
  final List<OStmt> body;
  final bool doUntil;
  SWhile(this.cond, this.body, {this.doUntil = false});
}

class SSwitch extends OStmt {
  final OExpr subject;
  final List<(List<OExpr>, List<OStmt>)> cases;
  final List<OStmt>? otherwise;
  SSwitch(this.subject, this.cases, this.otherwise);
}

class SCtl extends OStmt {
  final String kind; // break continue return
  SCtl(this.kind);
}

class OFunction {
  final String name;
  final List<String> params, outs;
  final List<OStmt> body;
  final int line;
  OFunction(this.name, this.params, this.outs, this.body, this.line);
}

class OProgram {
  final List<OStmt> script;
  final Map<String, OFunction> functions;
  OProgram(this.script, this.functions);
}

class _P {
  final List<OTok> t;
  int p = 0;
  int _indexDepth = 0; // inside A(...): `end` is a value
  _P(this.t);

  OTok get _c => t[p];
  bool _op(String v) => _c.k == 'op' && _c.v == v;
  bool _kw(String v) => _c.k == 'kw' && _c.v == v;
  OTok _next() => t[p++];
  void _expect(String v) {
    if (!_op(v)) throw OctError("se aștepta '$v' în loc de '${_c.v.isEmpty ? 'sfârșit' : _c.v}'", _c.line);
    p++;
  }

  bool _isEnd(Set<String> enders) => _c.k == 'eof' || (_c.k == 'kw' && enders.contains(_c.v));

  void _skipSeps() {
    while (_c.k == 'nl' || _op(';') || _op(',')) {
      p++;
    }
  }

  OProgram program() {
    final script = <OStmt>[];
    final funcs = <String, OFunction>{};
    _skipSeps();
    while (_c.k != 'eof') {
      if (_kw('function')) {
        final f = _function();
        funcs[f.name] = f;
      } else {
        script.add(_stmt());
      }
      _skipSeps();
    }
    return OProgram(script, funcs);
  }

  OFunction _function() {
    final line = _next().line;
    var outs = <String>[];
    // function [a, b] = name(x) | function a = name(x) | function name(x)
    if (_op('[')) {
      p++;
      while (!_op(']')) {
        if (_c.k == 'id') outs.add(_next().v);
        if (_op(',')) p++;
        if (_c.k == 'eof') throw OctError('lipsește ]', line);
      }
      p++;
      _expect('=');
    } else if (t[p + 1].k == 'op' && t[p + 1].v == '=') {
      outs = [_next().v];
      p++;
    }
    if (_c.k != 'id') throw OctError('lipsește numele funcției', line);
    final name = _next().v;
    final params = <String>[];
    if (_op('(')) {
      p++;
      while (!_op(')')) {
        if (_c.k == 'id') {
          params.add(_next().v);
        } else if (_op('~')) {
          params.add('~');
          p++;
        }
        if (_op(',')) p++;
        if (_c.k == 'eof') throw OctError('lipsește )', line);
      }
      p++;
    }
    final body = _block({'end', 'endfunction', 'function'});
    if (_kw('end') || _kw('endfunction')) p++;
    return OFunction(name, params, outs, body, line);
  }

  List<OStmt> _block(Set<String> enders) {
    final out = <OStmt>[];
    _skipSeps();
    while (!_isEnd(enders)) {
      out.add(_stmt());
      _skipSeps();
    }
    return out;
  }

  bool _endStmt() {
    // a statement ends at ; , newline or eof; true if it is shown (no ;)
    if (_op(';')) {
      p++;
      return false;
    }
    if (_op(',') || _c.k == 'nl') {
      p++;
      return true;
    }
    if (_c.k == 'eof' || _c.k == 'kw') return true;
    throw OctError("după instrucțiune urmează '${_c.v}' (lipsește un operator sau ; ?)", _c.line);
  }

  OStmt _stmt() {
    final line = _c.line;
    final s = _stmt0();
    s.line = line;
    return s;
  }

  OStmt _stmt0() {
    if (_c.k == 'kw') {
      switch (_c.v) {
        case 'if':
          p++;
          final branches = <(OExpr, List<OStmt>)>[];
          List<OStmt>? orElse;
          final c = _expr();
          branches.add((c, _block({'elseif', 'else', 'end', 'endif'})));
          while (true) {
            if (_kw('elseif')) {
              p++;
              final c2 = _expr();
              branches.add((c2, _block({'elseif', 'else', 'end', 'endif'})));
            } else if (_kw('else')) {
              p++;
              orElse = _block({'end', 'endif'});
            } else if (_kw('end') || _kw('endif')) {
              p++;
              break;
            } else {
              throw OctError('lipsește end pentru if', _c.line);
            }
          }
          return SIf(branches, orElse);
        case 'for':
          p++;
          final paren = _op('(');
          if (paren) p++;
          if (_c.k != 'id') throw OctError('for are nevoie de o variabilă', _c.line);
          final v = _next().v;
          _expect('=');
          final r = _expr();
          if (paren) _expect(')');
          final body = _block({'end', 'endfor'});
          if (!(_kw('end') || _kw('endfor'))) throw OctError('lipsește end pentru for', _c.line);
          p++;
          return SFor(v, r, body);
        case 'while':
          p++;
          final c = _expr();
          final body = _block({'end', 'endwhile'});
          if (!(_kw('end') || _kw('endwhile'))) throw OctError('lipsește end pentru while', _c.line);
          p++;
          return SWhile(c, body);
        case 'do':
          p++;
          final body = _block({'until'});
          if (!_kw('until')) throw OctError('lipsește until', _c.line);
          p++;
          return SWhile(_expr(), body, doUntil: true);
        case 'switch':
          p++;
          final subject = _expr();
          _skipSeps();
          final cases = <(List<OExpr>, List<OStmt>)>[];
          List<OStmt>? otherwise;
          while (true) {
            if (_kw('case')) {
              p++;
              final vals = <OExpr>[];
              if (_op('{')) {
                p++;
                while (!_op('}')) {
                  vals.add(_expr());
                  if (_op(',')) p++;
                }
                p++;
              } else {
                vals.add(_expr());
              }
              cases.add((vals, _block({'case', 'otherwise', 'end', 'endswitch'})));
            } else if (_kw('otherwise')) {
              p++;
              otherwise = _block({'end', 'endswitch'});
            } else if (_kw('end') || _kw('endswitch')) {
              p++;
              break;
            } else {
              throw OctError('lipsește end pentru switch', _c.line);
            }
          }
          return SSwitch(subject, cases, otherwise);
        case 'break':
        case 'continue':
        case 'return':
          final k = _next().v;
          _endStmt();
          return SCtl(k);
        default:
          throw OctError("'${_c.v}' nu are ce căuta aici", _c.line);
      }
    }
    // [a, b] = f(...)
    if (_op('[')) {
      final save = p;
      try {
        p++;
        final targets = <OExpr>[];
        while (!_op(']')) {
          if (_op('~')) {
            p++;
            targets.add(EId('~'));
          } else {
            targets.add(_postfix());
          }
          if (_op(',')) p++;
          if (_c.k == 'eof') throw OctError('');
        }
        p++;
        if (_op('=') ) {
          p++;
          final v = _expr();
          return SAssign(targets, v, _endStmt());
        }
      } catch (_) {
        // not an assignment
      }
      p = save;
    }
    final e = _expr();
    for (final op in const ['=', '+=', '-=', '*=', '/=']) {
      if (_op(op)) {
        if (e is! EId && !(e is ECall && e.target is EId)) throw OctError('în stânga lui = trebuie o variabilă', _c.line);
        p++;
        final v = _expr();
        return SAssign([e], v, _endStmt(), op);
      }
    }
    return SExpr(e, _endStmt());
  }

  OExpr _expr() => _oror();

  OExpr _oror() {
    var l = _andand();
    while (_op('||')) {
      p++;
      l = EBin('||', l, _andand());
    }
    return l;
  }

  OExpr _andand() {
    var l = _or();
    while (_op('&&')) {
      p++;
      l = EBin('&&', l, _or());
    }
    return l;
  }

  OExpr _or() {
    var l = _and();
    while (_op('|')) {
      p++;
      l = EBin('|', l, _and());
    }
    return l;
  }

  OExpr _and() {
    var l = _cmp();
    while (_op('&')) {
      p++;
      l = EBin('&', l, _cmp());
    }
    return l;
  }

  OExpr _cmp() {
    var l = _range();
    while (_c.k == 'op' && const {'==', '~=', '<', '<=', '>', '>='}.contains(_c.v)) {
      final op = _next().v;
      l = EBin(op, l, _range());
    }
    return l;
  }

  OExpr _range() {
    if (_indexDepth > 0 && _op(':') && (t[p + 1].k == 'op' && (t[p + 1].v == ',' || t[p + 1].v == ')'))) {
      p++;
      return EColonAll();
    }
    final a = _add();
    if (_op(':') && !(t[p + 1].k == 'op' && t[p + 1].v == '=')) {
      p++;
      final b = _add();
      if (_op(':')) {
        p++;
        final c = _add();
        return ERange(a, b, c);
      }
      return ERange(a, null, b);
    }
    return a;
  }

  OExpr _add() {
    var l = _mul();
    while (_op('+') || _op('-')) {
      final op = _next().v;
      l = EBin(op, l, _mul());
    }
    return l;
  }

  OExpr _mul() {
    var l = _unary();
    while (_c.k == 'op' && const {'*', '/', '\\', '.*', './', '.\\'}.contains(_c.v)) {
      final op = _next().v;
      l = EBin(op, l, _unary());
    }
    return l;
  }

  OExpr _unary() {
    if (_op('-') || _op('+') || _op('~') || _op('!')) {
      final op = _next().v;
      return EUn(op == '!' ? '~' : op, _unary());
    }
    return _power();
  }

  OExpr _power() {
    var b = _postfix();
    while (_op('^') || _op('.^')) {
      final op = _next().v;
      // the exponent may carry a sign: 2^-1
      OExpr e;
      if (_op('-') || _op('+')) {
        final s = _next().v;
        e = EUn(s, _postfix());
      } else {
        e = _postfix();
      }
      b = EBin(op, b, e);
    }
    return b;
  }

  OExpr _postfix() {
    var e = _primary();
    while (true) {
      if (_op('(')) {
        p++;
        _indexDepth++;
        final args = <OExpr>[];
        while (!_op(')')) {
          args.add(_expr());
          if (_op(',')) {
            p++;
          } else if (!_op(')')) {
            throw OctError("se aștepta ',' sau ')'", _c.line);
          }
        }
        p++;
        _indexDepth--;
        e = ECall(e, args)..line = _c.line;
      } else if (_op("'") || _op(".'")) {
        e = EPost(_next().v, e);
      } else {
        return e;
      }
    }
  }

  OExpr _primary() {
    final k = _next();
    switch (k.k) {
      case 'num':
        return ENum(double.parse(k.v))..line = k.line;
      case 'str':
        return EStr(k.v)..line = k.line;
      case 'id':
        return EId(k.v)..line = k.line;
      case 'kw':
        if (k.v == 'end' && _indexDepth > 0) return EEnd();
        throw OctError("'${k.v}' nu are ce căuta aici", k.line);
      case 'op':
        if (k.v == '(') {
          final saved = _indexDepth;
          _indexDepth = 0;
          final e = _expr();
          _indexDepth = saved;
          _expect(')');
          return e;
        }
        if (k.v == '[') return _matrix(k.line, ']');
        if (k.v == '{') return _matrix(k.line, '}');
        if (k.v == '@') {
          if (_op('(')) {
            p++;
            final params = <String>[];
            while (!_op(')')) {
              if (_c.k != 'id') throw OctError('parametru greșit în @(...)', _c.line);
              params.add(_next().v);
              if (_op(',')) p++;
            }
            p++;
            final saved = _indexDepth;
            _indexDepth = 0;
            final body = _expr();
            _indexDepth = saved;
            return EAnon(params, body);
          }
          if (_c.k == 'id') return EHandle(_next().v);
        }
    }
    throw OctError("nu înțeleg '${k.v.isEmpty ? 'sfârșitul' : k.v}'", k.line);
  }

  OExpr _matrix(int line, String close) {
    final saved = _indexDepth;
    _indexDepth = 0;
    final rows = <List<OExpr>>[[]];
    while (!_op(close)) {
      if (_c.k == 'eof') throw OctError("lipsește '$close'", line);
      if (_op(';') || _c.k == 'nl') {
        p++;
        if (rows.last.isNotEmpty) rows.add([]);
        continue;
      }
      if (_op(',')) {
        p++;
        continue;
      }
      rows.last.add(_expr());
    }
    p++;
    _indexDepth = saved;
    if (rows.last.isEmpty) rows.removeLast();
    return EMatrix(rows)..line = line;
  }
}

// ---------------------------------------------------------------- interpreter
class _Break implements Exception {}

class _Continue implements Exception {}

class _Return implements Exception {}

class Octave {
  final Map<String, OFunction> functions = {};
  final Map<String, OVal> globals = {};
  final StringBuffer out = StringBuffer();
  int steps = 0;
  int maxSteps = 5000000;
  int _depth = 0;
  final Set<String> called = {}; // built-ins used (to forbid inv, \, ...)
  final Set<String> usedOps = {};
  final math.Random _rand = math.Random(7);

  /// Loads function definitions (and runs the file's script part, if any).
  void load(String src) {
    final prog = _P(_lex(src)).program();
    functions.addAll(prog.functions);
    if (prog.script.isNotEmpty) _run(prog.script, globals);
  }

  /// Runs a command, as at the >> prompt; what it prints.
  String eval(String src) {
    final before = out.length;
    final prog = _P(_lex(src)).program();
    functions.addAll(prog.functions);
    _run(prog.script, globals);
    return out.toString().substring(before);
  }

  /// Calls a function with values; its first [nout] outputs.
  List<OVal> call(String name, List<OVal> args, int nout) {
    final f = functions[name];
    if (f == null) {
      if (_builtins.containsKey(name)) return _builtin(name, args, nout);
      throw OctError("funcția '$name' nu există");
    }
    return _callUser(f, args, nout);
  }

  OVal evalExpr(String src, [Map<String, OVal>? env]) {
    final prog = _P(_lex(src)).program();
    if (prog.script.length != 1 || prog.script.first is! SExpr) throw OctError('se aștepta o expresie: $src');
    return _eval((prog.script.first as SExpr).e, env ?? globals);
  }

  void _step(int line) {
    if (++steps > maxSteps) throw OctError('programul rulează de prea mult timp (o buclă infinită?)', line);
  }

  void _run(List<OStmt> body, Map<String, OVal> env) {
    for (final s in body) {
      try {
        _exec(s, env);
      } on OctError catch (e) {
        if (e.line == 0) throw OctError(e.message, s.line);
        rethrow;
      }
    }
  }

  void _exec(OStmt s, Map<String, OVal> env) {
    _step(s.line);
    switch (s) {
      case SExpr(:final e, :final show):
        if (e is EId && env[e.name] == null && !functions.containsKey(e.name) && !_builtins.containsKey(e.name)) {
          throw OctError("'${e.name}' nu e definit");
        }
        // a call with no outputs (disp, printf, a void function)
        if (e is EId && env[e.name] != null) {
          if (show) out.write(display(e.name, env[e.name]!));
          return;
        }
        final vals = e is ECall || e is EId ? _multi(e, env, 0) : [_eval(e, env)];
        if (vals.isNotEmpty) {
          final v = vals.first;
          env['ans'] = v;
          if (show) out.write(display('ans', v));
        }
      case SAssign(:final targets, :final value, :final show, :final op):
        if (targets.length == 1) {
          var v = _eval(value, env);
          if (op != '=') v = _binary(op[0], _eval(targets[0], env), v);
          _assign(targets[0], v, env);
          if (show) {
            final name = _targetName(targets[0]);
            out.write(display(name, env[name]!));
          }
        } else {
          final vals = _multi(value, env, targets.length);
          if (vals.length < targets.length) throw OctError('funcția întoarce mai puține valori decât ${targets.length}');
          for (var k = 0; k < targets.length; k++) {
            if (targets[k] is EId && (targets[k] as EId).name == '~') continue;
            _assign(targets[k], vals[k], env);
            if (show) {
              final name = _targetName(targets[k]);
              out.write(display(name, env[name]!));
            }
          }
        }
      case SIf(:final branches, :final orElse):
        for (final (c, body) in branches) {
          if (truthy(_eval(c, env))) {
            _run(body, env);
            return;
          }
        }
        if (orElse != null) _run(orElse, env);
      case SFor(:final v, :final range, :final body):
        final r = _eval(range, env);
        final cols = r is Mat ? r.c : 1;
        for (var j = 0; j < cols; j++) {
          _step(s.line);
          if (r is Mat) {
            env[v] = r.r == 1 ? Mat.scalar(r.d[j]) : Mat(r.r, 1, r.d.sublist(j * r.r, (j + 1) * r.r));
          } else {
            env[v] = r;
          }
          try {
            _run(body, env);
          } on _Break {
            break;
          } on _Continue {
            continue;
          }
        }
      case SWhile(:final cond, :final body, :final doUntil):
        if (doUntil) {
          do {
            _step(s.line);
            try {
              _run(body, env);
            } on _Break {
              break;
            } on _Continue {
              // to the condition
            }
          } while (!truthy(_eval(cond, env)));
        } else {
          while (truthy(_eval(cond, env))) {
            _step(s.line);
            try {
              _run(body, env);
            } on _Break {
              break;
            } on _Continue {
              continue;
            }
          }
        }
      case SSwitch(:final subject, :final cases, :final otherwise):
        final v = _eval(subject, env);
        for (final (vals, body) in cases) {
          for (final x in vals) {
            final w = _eval(x, env);
            final hit = (v is OStr && w is OStr) ? v.s == w.s : (v is Mat && w is Mat && v.isScalar && w.isScalar && v.d[0] == w.d[0]);
            if (hit) {
              _run(body, env);
              return;
            }
          }
        }
        if (otherwise != null) _run(otherwise, env);
      case SCtl(:final kind):
        if (kind == 'break') throw _Break();
        if (kind == 'continue') throw _Continue();
        throw _Return();
    }
  }

  String _targetName(OExpr t) => t is EId ? t.name : ((t as ECall).target as EId).name;

  void _assign(OExpr target, OVal v, Map<String, OVal> env) {
    if (target is EId) {
      env[target.name] = v is Mat ? v.copy(logical: v.logical) : v;
      return;
    }
    final call = target as ECall;
    final name = (call.target as EId).name;
    final cur = env[name];
    Mat m;
    if (cur == null) {
      m = Mat.empty;
    } else if (cur is Mat) {
      m = cur;
    } else if (cur is OStr && v is OStr) {
      m = _strMat(cur);
    } else {
      throw OctError('nu se poate indexa în $name');
    }
    final value = v is OStr ? _strMat(v) : v;
    if (value is! Mat) throw OctError('se poate pune doar un număr sau o matrice în $name(...)');
    env[name] = _indexAssign(m, call.args, value, env);
  }

  Mat _strMat(OStr s) => Mat(1, s.s.length, [for (final c in s.s.codeUnits) c.toDouble()]);

  Mat _indexAssign(Mat m, List<OExpr> args, Mat v, Map<String, OVal> env) {
    if (args.length == 1) {
      final idx = _indices(args[0], m.n, env, m);
      var mm = m;
      final maxI = idx.isEmpty ? 0 : idx.reduce(math.max);
      if (maxI >= m.n) {
        // grow: a row vector grows to the right, an empty one becomes a row
        if (m.n == 0 || m.r == 1) {
          mm = Mat(1, maxI + 1, [...m.d, ...List.filled(maxI + 1 - m.n, 0.0)]);
        } else if (m.c == 1) {
          mm = Mat(maxI + 1, 1, [...m.d, ...List.filled(maxI + 1 - m.n, 0.0)]);
        } else {
          throw OctError('A(I) = X: indexul ${maxI + 1} e în afara matricei ${m.r}×${m.c}');
        }
      } else {
        mm = m.copy();
      }
      if (v.n == 1) {
        for (final i in idx) {
          mm.d[i] = v.d[0];
        }
      } else {
        if (v.n != idx.length) throw OctError('A(I) = X: X trebuie să aibă ${idx.length} elemente, are ${v.n}');
        for (var k = 0; k < idx.length; k++) {
          mm.d[idx[k]] = v.d[k];
        }
      }
      return mm;
    }
    if (args.length != 2) throw OctError('se acceptă cel mult doi indici');
    final ri = _indices(args[0], m.r, env, m, dim: 0);
    final ci = _indices(args[1], m.c, env, m, dim: 1);
    final nr = math.max(m.r, ri.isEmpty ? 0 : ri.reduce(math.max) + 1);
    final nc = math.max(m.c, ci.isEmpty ? 0 : ci.reduce(math.max) + 1);
    final mm = Mat.zeros(nr, nc);
    for (var i = 0; i < m.r; i++) {
      for (var j = 0; j < m.c; j++) {
        mm.set(i, j, m.at(i, j));
      }
    }
    if (v.n == 1) {
      for (final j in ci) {
        for (final i in ri) {
          mm.set(i, j, v.d[0]);
        }
      }
    } else {
      if (v.n != ri.length * ci.length) throw OctError('=: nu se potrivesc dimensiunile (${ri.length}×${ci.length} ≠ ${v.r}×${v.c})');
      var k = 0;
      for (var jj = 0; jj < ci.length; jj++) {
        for (var ii = 0; ii < ri.length; ii++) {
          // v in column-major order, shaped as the index block
          final vi = v.r == ri.length ? ii : k % v.r;
          final vj = v.r == ri.length ? jj : k ~/ v.r;
          mm.set(ri[ii], ci[jj], v.at(vi, vj));
          k++;
        }
      }
    }
    return mm;
  }

  /// Zero-based indices from an index expression (`:` is all of [size]).
  OVal _indexValue(OExpr e, int size, Map<String, OVal> env) {
    final saved = _endValue;
    _endValue = size;
    try {
      return _eval(e, env);
    } finally {
      _endValue = saved;
    }
  }

  List<int> _indices(OExpr e, int size, Map<String, OVal> env, Mat of, {int dim = -1, OVal? value}) {
    if (e is EColonAll) return List.generate(size, (i) => i);
    final saved = _endValue;
    _endValue = size;
    try {
      final v = value ?? _eval(e, env);
      if (v is! Mat) throw OctError('indicele trebuie să fie un număr');
      if (v.logical) return [for (var i = 0; i < v.n; i++) if (v.d[i] != 0) i];
      return [
        for (final x in v.d)
          () {
            if (x != x.roundToDouble()) throw OctError('indicele ${_fmtNum(x)} nu e întreg');
            if (x < 1) throw OctError('indicele ${_fmtNum(x)} e în afara limitelor (indicii încep de la 1)');
            return x.toInt() - 1;
          }(),
      ];
    } finally {
      _endValue = saved;
    }
  }

  int? _endValue;

  static bool truthy(OVal v) {
    if (v is Mat) return v.n > 0 && v.d.every((x) => x != 0 && !x.isNaN);
    if (v is OStr) return v.s.isNotEmpty;
    return true;
  }

  /// The values an expression gives (several for f(...) with several outputs).
  List<OVal> _multi(OExpr e, Map<String, OVal> env, int nout) {
    if (e is ECall && e.target is EId) {
      final name = (e.target as EId).name;
      final v = env[name];
      if (v == null) {
        final args = [for (final a in e.args) _eval(a, env)];
        return _callName(name, args, nout);
      }
      if (v is OFunc) return _callFunc(v, [for (final a in e.args) _eval(a, env)], nout);
    }
    if (e is EId && env[e.name] == null && (functions.containsKey(e.name) || _builtins.containsKey(e.name))) {
      return _callName(e.name, const [], nout);
    }
    return [_eval(e, env)];
  }

  List<OVal> _callName(String name, List<OVal> args, int nout) {
    final f = functions[name];
    if (f != null) return _callUser(f, args, nout);
    if (_builtins.containsKey(name)) {
      called.add(name);
      return _builtin(name, args, nout);
    }
    throw OctError("'$name' nu e definit");
  }

  List<OVal> _callFunc(OFunc f, List<OVal> args, int nout) {
    if (f.name != null) return _callName(f.name!, args, nout);
    if (args.length > f.params.length) throw OctError('@(${f.params.join(', ')}): prea multe argumente');
    final env = Map.of(f.captured);
    for (var k = 0; k < args.length; k++) {
      env[f.params[k]] = args[k];
    }
    return [_eval(f.body!, env)];
  }

  List<OVal> _callUser(OFunction f, List<OVal> args, int nout) {
    if (args.length > f.params.length) throw OctError("'${f.name}': prea multe argumente (primește ${f.params.length})");
    if (nout > math.max(1, f.outs.length)) throw OctError("'${f.name}': întoarce doar ${f.outs.length} valori");
    if (++_depth > 256) {
      _depth = 0;
      throw OctError('recursivitate prea adâncă (256 de apeluri)');
    }
    final env = <String, OVal>{};
    for (var k = 0; k < args.length; k++) {
      env[f.params[k]] = args[k];
    }
    env['nargin'] = Mat.scalar(args.length);
    env['nargout'] = Mat.scalar(nout);
    try {
      _run(f.body, env);
    } on _Return {
      // done
    } finally {
      _depth--;
    }
    final outs = <OVal>[];
    for (var k = 0; k < math.max(nout, f.outs.isEmpty ? 0 : 1) && k < f.outs.length; k++) {
      final v = env[f.outs[k]];
      if (v == null) throw OctError("'${f.name}': valoarea de ieșire '${f.outs[k]}' nu a primit nicio valoare");
      outs.add(v);
    }
    return outs;
  }

  OVal _eval(OExpr e, Map<String, OVal> env) {
    switch (e) {
      case ENum(:final v):
        return Mat.scalar(v);
      case EStr(:final v):
        return OStr(v);
      case EEnd():
        if (_endValue == null) throw OctError("'end' se folosește doar într-un indice");
        return Mat.scalar(_endValue!);
      case EColonAll():
        throw OctError("':' singur se folosește doar într-un indice");
      case EId(:final name):
        final v = env[name];
        if (v != null) return v;
        final r = _multi(e, env, 1);
        if (r.isEmpty) throw OctError("'$name' nu întoarce nicio valoare");
        return r.first;
      case EAnon(:final params, :final body):
        return OFunc(params, body, null, Map.of(env));
      case EHandle(:final name):
        if (!functions.containsKey(name) && !_builtins.containsKey(name)) throw OctError("@$name: funcția nu există");
        return OFunc(const [], null, name, const {});
      case EMatrix(:final rows):
        return _concat(rows, env);
      case ERange(:final a, :final step, :final b):
        final x = _num(_eval(a, env)), y = _num(_eval(b, env));
        final s = step == null ? 1.0 : _num(_eval(step, env));
        if (s == 0 || (s > 0 && x > y) || (s < 0 && x < y)) return Mat(1, 0, const []);
        final n = ((y - x) / s + 1e-10).floor() + 1;
        if (n > 10000000) throw OctError('interval prea mare');
        return Mat(1, n, [for (var k = 0; k < n; k++) x + k * s]);
      case EPost(:final e):
        final v = _eval(e, env);
        if (v is OStr) return v;
        return (v as Mat).t;
      case EUn(:final op, :final e):
        final v = _mat(_eval(e, env));
        if (op == '-') return Mat(v.r, v.c, [for (final x in v.d) -x]);
        if (op == '+') return v;
        return Mat(v.r, v.c, [for (final x in v.d) x == 0 ? 1.0 : 0.0], logical: true);
      case EBin(:final op, :final l, :final r):
        if (op == '&&' || op == '||') {
          final a = truthy(_eval(l, env));
          if (op == '&&' && !a) return Mat.scalar(0, logical: true);
          if (op == '||' && a) return Mat.scalar(1, logical: true);
          return Mat.scalar(truthy(_eval(r, env)) ? 1 : 0, logical: true);
        }
        usedOps.add(op);
        return _binary(op, _eval(l, env), _eval(r, env));
      case ECall(:final target, :final args):
        if (target is EId) {
          final v = env[target.name];
          if (v is Mat || v is OStr) return _index(v!, args, env);
          final r = _multi(e, env, 1);
          if (r.isEmpty) throw OctError("'${target.name}' nu întoarce nicio valoare");
          return r.first;
        }
        final v = _eval(target, env);
        if (v is OFunc) {
          final r = _callFunc(v, [for (final a in args) _eval(a, env)], 1);
          return r.first;
        }
        return _index(v, args, env);
    }
  }

  OVal _index(OVal v, List<OExpr> args, Map<String, OVal> env) {
    if (v is OStr) {
      final m = _strMat(v);
      final r = _index(m, args, env) as Mat;
      return OStr(String.fromCharCodes(r.d.map((x) => x.toInt())));
    }
    final m = v as Mat;
    if (args.isEmpty) return m;
    if (args.length == 1) {
      final a0 = args[0];
      final iv = a0 is EColonAll ? null : _indexValue(a0, m.n, env);
      final idx = _indices(a0, m.n, env, m, value: iv);
      for (final i in idx) {
        if (i >= m.n) throw OctError('indicele ${i + 1} e în afara limitelor (are ${m.n} elemente)');
      }
      final vals = [for (final i in idx) m.d[i]];
      if (a0 is EColonAll) return Mat(m.n, 1, vals);
      // the shape follows the index, or the vector being indexed
      if (m.isVector && iv is Mat && iv.isVector) return m.r == 1 ? Mat(1, vals.length, vals) : Mat(vals.length, 1, vals);
      if (iv is Mat && !iv.logical) return Mat(iv.r, iv.c, vals);
      return Mat(vals.length, 1, vals);
    }
    if (args.length != 2) throw OctError('se acceptă cel mult doi indici');
    final ri = _indices(args[0], m.r, env, m, dim: 0);
    final ci = _indices(args[1], m.c, env, m, dim: 1);
    for (final i in ri) {
      if (i >= m.r) throw OctError('indicele de linie ${i + 1} e în afara limitelor (are ${m.r} linii)');
    }
    for (final j in ci) {
      if (j >= m.c) throw OctError('indicele de coloană ${j + 1} e în afara limitelor (are ${m.c} coloane)');
    }
    final out = Mat.zeros(ri.length, ci.length);
    for (var jj = 0; jj < ci.length; jj++) {
      for (var ii = 0; ii < ri.length; ii++) {
        out.set(ii, jj, m.at(ri[ii], ci[jj]));
      }
    }
    return out;
  }

  OVal _concat(List<List<OExpr>> rows, Map<String, OVal> env) {
    final built = <Mat>[];
    var anyStr = false;
    for (final row in rows) {
      final parts = [
        for (final x in row)
          () {
            final v = _eval(x, env);
            if (v is OStr) {
              anyStr = true;
              return _strMat(v);
            }
            if (v is! Mat) throw OctError('o funcție nu poate intra într-o matrice');
            return v;
          }(),
      ].where((m) => m.n > 0).toList();
      if (parts.isEmpty) continue;
      final r = parts.first.r;
      for (final p in parts) {
        if (p.r != r) throw OctError('concatenare orizontală: dimensiuni diferite (${p.r} linii față de $r)');
      }
      final c = parts.fold<int>(0, (s, p) => s + p.c);
      final m = Mat.zeros(r, c);
      var off = 0;
      for (final p in parts) {
        for (var j = 0; j < p.c; j++) {
          for (var i = 0; i < r; i++) {
            m.set(i, off + j, p.at(i, j));
          }
        }
        off += p.c;
      }
      built.add(m);
    }
    if (built.isEmpty) return anyStr ? OStr('') : Mat.empty;
    final c = built.first.c;
    for (final b in built) {
      if (b.c != c) throw OctError('concatenare verticală: dimensiuni diferite (${b.c} coloane față de $c)');
    }
    final r = built.fold<int>(0, (s, b) => s + b.r);
    final m = Mat.zeros(r, c);
    var off = 0;
    for (final b in built) {
      for (var i = 0; i < b.r; i++) {
        for (var j = 0; j < c; j++) {
          m.set(off + i, j, b.at(i, j));
        }
      }
      off += b.r;
    }
    if (anyStr && r == 1) return OStr(String.fromCharCodes(m.d.map((x) => x.toInt())));
    return m;
  }

  Mat _mat(OVal v) {
    if (v is Mat) return v;
    if (v is OStr) return _strMat(v);
    throw OctError('o funcție nu e un număr');
  }

  double _num(OVal v) => _mat(v).scalar;

  OVal _binary(String op, OVal a0, OVal b0) {
    final a = _mat(a0), b = _mat(b0);
    switch (op) {
      case '*':
        if (a.isScalar || b.isScalar) return _elem(a, b, (x, y) => x * y, '*');
        // an empty sum (U(i, i+1:n) * x(i+1:n) at the last row) is 0, whichever way the empties lie
        if (a.c == 0 && b.n == 0) return Mat.zeros(a.r, b.r == 0 ? b.c : 1);
        if (a.c != b.r) throw OctError('operator *: dimensiuni nepotrivite (${a.r}×${a.c} ori ${b.r}×${b.c})');
        final m = Mat.zeros(a.r, b.c);
        for (var i = 0; i < a.r; i++) {
          for (var j = 0; j < b.c; j++) {
            var s = 0.0;
            for (var k = 0; k < a.c; k++) {
              s += a.at(i, k) * b.at(k, j);
            }
            m.set(i, j, s);
          }
        }
        return m;
      case '/':
        if (b.isScalar) return _elem(a, b, (x, y) => x / y, '/');
        // A / B = (B' \ A')'
        return (_solve(b.t, a.t)).t;
      case '\\':
        if (a.isScalar) return _elem(a, b, (x, y) => y / x, '\\');
        return _solve(a, b);
      case '^':
        if (a.isScalar && b.isScalar) return Mat.scalar(_pow(a.d[0], b.d[0]));
        if (b.isScalar && a.r == a.c && b.d[0] == b.d[0].roundToDouble() && b.d[0] >= 0) {
          var r = identity(a.r);
          for (var k = 0; k < b.d[0].toInt(); k++) {
            r = _binary('*', r, a) as Mat;
          }
          return r;
        }
        throw OctError('operator ^: pentru matrice folosește .^ (element cu element)');
      case '.*':
        return _elem(a, b, (x, y) => x * y, op);
      case './':
        return _elem(a, b, (x, y) => x / y, op);
      case '.\\':
        return _elem(a, b, (x, y) => y / x, op);
      case '.^':
        return _elem(a, b, _pow, op);
      case '+':
        return _elem(a, b, (x, y) => x + y, op);
      case '-':
        return _elem(a, b, (x, y) => x - y, op);
      case '==':
        return _elem(a, b, (x, y) => x == y ? 1 : 0, op, logical: true);
      case '~=':
        return _elem(a, b, (x, y) => x != y ? 1 : 0, op, logical: true);
      case '<':
        return _elem(a, b, (x, y) => x < y ? 1 : 0, op, logical: true);
      case '<=':
        return _elem(a, b, (x, y) => x <= y ? 1 : 0, op, logical: true);
      case '>':
        return _elem(a, b, (x, y) => x > y ? 1 : 0, op, logical: true);
      case '>=':
        return _elem(a, b, (x, y) => x >= y ? 1 : 0, op, logical: true);
      case '&':
        return _elem(a, b, (x, y) => x != 0 && y != 0 ? 1 : 0, op, logical: true);
      case '|':
        return _elem(a, b, (x, y) => x != 0 || y != 0 ? 1 : 0, op, logical: true);
    }
    throw OctError('operator necunoscut $op');
  }

  static double _pow(double x, double y) {
    if (x < 0 && y != y.roundToDouble()) return double.nan;
    return math.pow(x, y).toDouble();
  }

  Mat _elem(Mat a, Mat b, double Function(double, double) f, String op, {bool logical = false}) {
    if (a.isScalar) return Mat(b.r, b.c, [for (final y in b.d) f(a.d[0], y)], logical: logical);
    if (b.isScalar) return Mat(a.r, a.c, [for (final x in a.d) f(x, b.d[0])], logical: logical);
    if (a.r == b.r && a.c == b.c) return Mat(a.r, a.c, [for (var k = 0; k < a.n; k++) f(a.d[k], b.d[k])], logical: logical);
    // broadcasting a row against a column (Octave does it)
    if ((a.r == b.r || a.r == 1 || b.r == 1) && (a.c == b.c || a.c == 1 || b.c == 1)) {
      final r = math.max(a.r, b.r), c = math.max(a.c, b.c);
      final m = Mat.zeros(r, c);
      for (var i = 0; i < r; i++) {
        for (var j = 0; j < c; j++) {
          m.set(i, j, f(a.at(a.r == 1 ? 0 : i, a.c == 1 ? 0 : j), b.at(b.r == 1 ? 0 : i, b.c == 1 ? 0 : j)));
        }
      }
      return Mat(r, c, m.d, logical: logical);
    }
    throw OctError('operator $op: dimensiuni nepotrivite (${a.r}×${a.c} și ${b.r}×${b.c})');
  }

  static Mat identity(int n) {
    final m = Mat.zeros(n, n);
    for (var i = 0; i < n; i++) {
      m.set(i, i, 1);
    }
    return m;
  }

  /// A \ B by Gaussian elimination with partial pivoting.
  static Mat _solve(Mat a, Mat b) {
    if (a.r != b.r) throw OctError('operator \\: dimensiuni nepotrivite (${a.r}×${a.c} și ${b.r}×${b.c})');
    if (a.r != a.c) throw OctError('operator \\: aici se rezolvă doar sisteme pătratice');
    final n = a.r;
    final m = a.copy(), x = b.copy();
    for (var k = 0; k < n; k++) {
      var p = k;
      for (var i = k + 1; i < n; i++) {
        if (m.at(i, k).abs() > m.at(p, k).abs()) p = i;
      }
      if (m.at(p, k).abs() < 1e-14) throw OctError('matricea e singulară');
      if (p != k) {
        for (var j = 0; j < n; j++) {
          final t = m.at(k, j);
          m.set(k, j, m.at(p, j));
          m.set(p, j, t);
        }
        for (var j = 0; j < x.c; j++) {
          final t = x.at(k, j);
          x.set(k, j, x.at(p, j));
          x.set(p, j, t);
        }
      }
      for (var i = k + 1; i < n; i++) {
        final f = m.at(i, k) / m.at(k, k);
        for (var j = k; j < n; j++) {
          m.set(i, j, m.at(i, j) - f * m.at(k, j));
        }
        for (var j = 0; j < x.c; j++) {
          x.set(i, j, x.at(i, j) - f * x.at(k, j));
        }
      }
    }
    for (var j = 0; j < x.c; j++) {
      for (var i = n - 1; i >= 0; i--) {
        var s = x.at(i, j);
        for (var k = i + 1; k < n; k++) {
          s -= m.at(i, k) * x.at(k, j);
        }
        x.set(i, j, s / m.at(i, i));
      }
    }
    return x;
  }

  static double det(Mat a) {
    if (a.r != a.c) throw OctError('det: matricea trebuie să fie pătratică');
    final n = a.r;
    final m = a.copy();
    var d = 1.0;
    for (var k = 0; k < n; k++) {
      var p = k;
      for (var i = k + 1; i < n; i++) {
        if (m.at(i, k).abs() > m.at(p, k).abs()) p = i;
      }
      if (m.at(p, k) == 0) return 0;
      if (p != k) {
        d = -d;
        for (var j = 0; j < n; j++) {
          final t = m.at(k, j);
          m.set(k, j, m.at(p, j));
          m.set(p, j, t);
        }
      }
      d *= m.at(k, k);
      for (var i = k + 1; i < n; i++) {
        final f = m.at(i, k) / m.at(k, k);
        for (var j = k; j < n; j++) {
          m.set(i, j, m.at(i, j) - f * m.at(k, j));
        }
      }
    }
    return d;
  }

  /// Eigenvalues and vectors of a symmetric matrix (Jacobi rotations).
  static (List<double>, Mat) eigSym(Mat a) {
    final n = a.r;
    final m = a.copy();
    final v = identity(n);
    for (var sweep = 0; sweep < 100; sweep++) {
      var off = 0.0;
      for (var i = 0; i < n; i++) {
        for (var j = i + 1; j < n; j++) {
          off += m.at(i, j) * m.at(i, j);
        }
      }
      if (off < 1e-22) break;
      for (var p = 0; p < n; p++) {
        for (var q = p + 1; q < n; q++) {
          if (m.at(p, q).abs() < 1e-300) continue;
          final theta = (m.at(q, q) - m.at(p, p)) / (2 * m.at(p, q));
          final t = (theta >= 0 ? 1 : -1) / (theta.abs() + math.sqrt(theta * theta + 1));
          final c = 1 / math.sqrt(t * t + 1), s = t * c;
          for (var k = 0; k < n; k++) {
            final mkp = m.at(k, p), mkq = m.at(k, q);
            m.set(k, p, c * mkp - s * mkq);
            m.set(k, q, s * mkp + c * mkq);
          }
          for (var k = 0; k < n; k++) {
            final mpk = m.at(p, k), mqk = m.at(q, k);
            m.set(p, k, c * mpk - s * mqk);
            m.set(q, k, s * mpk + c * mqk);
          }
          for (var k = 0; k < n; k++) {
            final vkp = v.at(k, p), vkq = v.at(k, q);
            v.set(k, p, c * vkp - s * vkq);
            v.set(k, q, s * vkp + c * vkq);
          }
        }
      }
    }
    final vals = [for (var i = 0; i < n; i++) m.at(i, i)];
    // ascending, like Octave
    final order = List.generate(n, (i) => i)..sort((x, y) => vals[x].compareTo(vals[y]));
    final vs = Mat.zeros(n, n);
    for (var k = 0; k < n; k++) {
      for (var i = 0; i < n; i++) {
        vs.set(i, k, v.at(i, order[k]));
      }
    }
    return ([for (final k in order) vals[k]], vs);
  }

  /// Real eigenvalues of a general matrix (QR iterations); complex ones are refused.
  static List<double> eigGeneral(Mat a) {
    final n = a.r;
    var m = a.copy();
    for (var it = 0; it < 500; it++) {
      // QR by Gram-Schmidt, with a shift
      final mu = m.at(n - 1, n - 1);
      final shifted = m.copy();
      for (var i = 0; i < n; i++) {
        shifted.set(i, i, shifted.at(i, i) - mu);
      }
      final (q, r) = qr(shifted);
      m = _mulS(r, q);
      for (var i = 0; i < n; i++) {
        m.set(i, i, m.at(i, i) + mu);
      }
      var low = 0.0;
      for (var i = 1; i < n; i++) {
        low += m.at(i, i - 1).abs();
      }
      if (low < 1e-12) break;
    }
    for (var i = 1; i < n; i++) {
      if (m.at(i, i - 1).abs() > 1e-6) throw OctError('eig: valorile proprii complexe nu sunt acceptate aici');
    }
    return [for (var i = 0; i < n; i++) m.at(i, i)]..sort();
  }

  static Mat _mulS(Mat a, Mat b) {
    final m = Mat.zeros(a.r, b.c);
    for (var i = 0; i < a.r; i++) {
      for (var j = 0; j < b.c; j++) {
        var s = 0.0;
        for (var k = 0; k < a.c; k++) {
          s += a.at(i, k) * b.at(k, j);
        }
        m.set(i, j, s);
      }
    }
    return m;
  }

  static (Mat, Mat) qr(Mat a) {
    final n = a.r, c = a.c;
    final q = Mat.zeros(n, c), r = Mat.zeros(c, c);
    for (var j = 0; j < c; j++) {
      final v = [for (var i = 0; i < n; i++) a.at(i, j)];
      for (var k = 0; k < j; k++) {
        var dot = 0.0;
        for (var i = 0; i < n; i++) {
          dot += q.at(i, k) * v[i];
        }
        r.set(k, j, dot);
        for (var i = 0; i < n; i++) {
          v[i] -= dot * q.at(i, k);
        }
      }
      final norm = math.sqrt(v.fold<double>(0, (s, x) => s + x * x));
      r.set(j, j, norm);
      for (var i = 0; i < n; i++) {
        q.set(i, j, norm == 0 ? 0 : v[i] / norm);
      }
    }
    return (q, r);
  }

  // ---------------------------------------------------------------- built-ins
  static final Map<String, int> _builtins = {
    for (final n in [
      'pi', 'e', 'Inf', 'inf', 'NaN', 'nan', 'eps', 'true', 'false', 'zeros', 'ones', 'eye', 'rand', 'size', 'numel', 'length', 'rows', 'columns', 'isempty',
      'abs', 'sqrt', 'exp', 'log', 'log2', 'log10', 'sin', 'cos', 'tan', 'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'floor', 'ceil', 'round', 'fix', 'sign', 'mod', 'rem',
      'max', 'min', 'sum', 'prod', 'cumsum', 'cumprod', 'mean', 'norm', 'det', 'inv', 'trace', 'diag', 'triu', 'tril', 'transpose', 'any', 'all', 'find', 'linspace',
      'repmat', 'sort', 'disp', 'printf', 'fprintf', 'sprintf', 'num2str', 'error', 'isequal', 'feval', 'dot', 'cross', 'polyval', 'fliplr', 'flipud', 'reshape', 'eig',
      'isrow', 'iscolumn', 'isvector', 'isscalar', 'numel', 'abs', 'factorial', 'nchoosek', 'gamma', 'hypot', 'kron', 'lu', 'chol', 'qr', 'rank', 'mat2str', 'fflush', 'stdout', 'tic', 'toc',
      'floor', 'idivide', 'func2str', 'isnan', 'isinf', 'cat', 'horzcat', 'vertcat', 'numel', 'magic', 'hilb', 'vander', 'trapz', 'diff', 'logical', 'double', 'exist', 'nargin', 'warning',
    ])
      n: 1,
  };

  static bool isBuiltin(String n) => _builtins.containsKey(n);

  List<OVal> _builtin(String name, List<OVal> a, int nout) {
    Mat m(int k) => k < a.length ? _mat(a[k]) : throw OctError('$name: lipsește argumentul ${k + 1}');
    double s(int k) => m(k).scalar;
    Mat map1(double Function(double) f) {
      final x = m(0);
      return Mat(x.r, x.c, [for (final v in x.d) f(v)]);
    }

    List<OVal> one(OVal v) => [v];
    List<OVal> sc(num v) => [Mat.scalar(v)];
    (int, int) dims() {
      if (a.isEmpty) return (1, 1);
      if (a.length == 1) {
        final x = m(0);
        if (x.n == 2) return (x.d[0].toInt(), x.d[1].toInt());
        return (x.scalar.toInt(), x.scalar.toInt());
      }
      return (s(0).toInt(), s(1).toInt());
    }

    // reduce along columns (or the vector), like Octave
    Mat reduce(Mat x, double Function(List<double>) f, {int? dim}) {
      final d = dim ?? (x.r == 1 ? 2 : 1);
      if (x.n == 0) return Mat.scalar(f(const []));
      if (d == 2) return Mat(x.r, 1, [for (var i = 0; i < x.r; i++) f([for (var j = 0; j < x.c; j++) x.at(i, j)])]);
      return Mat(1, x.c, [for (var j = 0; j < x.c; j++) f([for (var i = 0; i < x.r; i++) x.at(i, j)])]);
    }

    switch (name) {
      case 'pi':
        return sc(math.pi);
      case 'e':
        return sc(math.e);
      case 'Inf':
      case 'inf':
        return sc(double.infinity);
      case 'NaN':
      case 'nan':
        return sc(double.nan);
      case 'eps':
        return sc(2.220446049250313e-16);
      case 'true':
        return [Mat.scalar(1, logical: true)];
      case 'false':
        return [Mat.scalar(0, logical: true)];
      case 'zeros':
      case 'ones':
        final (r, c) = dims();
        return one(Mat(r, c, List.filled(math.max(0, r) * math.max(0, c), name == 'ones' ? 1.0 : 0.0)));
      case 'eye':
        final (r, c) = dims();
        final x = Mat.zeros(r, c);
        for (var i = 0; i < math.min(r, c); i++) {
          x.set(i, i, 1);
        }
        return one(x);
      case 'rand':
        final (r, c) = dims();
        return one(Mat(r, c, [for (var k = 0; k < r * c; k++) _rand.nextDouble()]));
      case 'magic':
        final n = s(0).toInt();
        if (n != 3) throw OctError('magic: aici doar magic(3)');
        return one(Mat.rows([
          [8, 1, 6],
          [3, 5, 7],
          [4, 9, 2],
        ]));
      case 'hilb':
        final n = s(0).toInt();
        return one(Mat.rows([for (var i = 0; i < n; i++) [for (var j = 0; j < n; j++) 1 / (i + j + 1)]]));
      case 'size':
        final x = a.isNotEmpty && a[0] is OStr ? _strMat(a[0] as OStr) : m(0);
        if (a.length > 1) return sc(s(1) == 1 ? x.r : x.c);
        if (nout >= 2) return [Mat.scalar(x.r), Mat.scalar(x.c)];
        return one(Mat(1, 2, [x.r.toDouble(), x.c.toDouble()]));
      case 'numel':
        return sc(a[0] is OStr ? (a[0] as OStr).s.length : m(0).n);
      case 'length':
        final x = a[0] is OStr ? _strMat(a[0] as OStr) : m(0);
        return sc(x.n == 0 ? 0 : math.max(x.r, x.c));
      case 'rows':
        return sc(m(0).r);
      case 'columns':
        return sc(m(0).c);
      case 'isempty':
        return [Mat.scalar((a[0] is OStr ? (a[0] as OStr).s.isEmpty : m(0).n == 0) ? 1 : 0, logical: true)];
      case 'isrow':
        return [Mat.scalar(m(0).r == 1 ? 1 : 0, logical: true)];
      case 'iscolumn':
        return [Mat.scalar(m(0).c == 1 ? 1 : 0, logical: true)];
      case 'isvector':
        return [Mat.scalar(m(0).isVector && m(0).n >= 1 ? 1 : 0, logical: true)];
      case 'isscalar':
        return [Mat.scalar(m(0).isScalar ? 1 : 0, logical: true)];
      case 'isnan':
        final x = m(0);
        return one(Mat(x.r, x.c, [for (final v in x.d) v.isNaN ? 1 : 0], logical: true));
      case 'isinf':
        final x = m(0);
        return one(Mat(x.r, x.c, [for (final v in x.d) v.isInfinite ? 1 : 0], logical: true));
      case 'logical':
        final x = m(0);
        return one(Mat(x.r, x.c, [for (final v in x.d) v != 0 ? 1 : 0], logical: true));
      case 'double':
        return one(m(0).copy(logical: false));
      case 'abs':
        return one(map1((x) => x.abs()));
      case 'sqrt':
        return one(map1((x) => x < 0 ? double.nan : math.sqrt(x)));
      case 'exp':
        return one(map1(math.exp));
      case 'log':
        return one(map1(math.log));
      case 'log2':
        return one(map1((x) => math.log(x) / math.ln2));
      case 'log10':
        return one(map1((x) => math.log(x) / math.ln10));
      case 'sin':
        return one(map1(math.sin));
      case 'cos':
        return one(map1(math.cos));
      case 'tan':
        return one(map1(math.tan));
      case 'asin':
        return one(map1(math.asin));
      case 'acos':
        return one(map1(math.acos));
      case 'atan':
        return one(map1(math.atan));
      case 'sinh':
        return one(map1((x) => (math.exp(x) - math.exp(-x)) / 2));
      case 'cosh':
        return one(map1((x) => (math.exp(x) + math.exp(-x)) / 2));
      case 'tanh':
        return one(map1((x) => (math.exp(2 * x) - 1) / (math.exp(2 * x) + 1)));
      case 'atan2':
        return one(_elem(m(0), m(1), (y, x) => math.atan2(y, x), 'atan2'));
      case 'hypot':
        return one(_elem(m(0), m(1), (x, y) => math.sqrt(x * x + y * y), 'hypot'));
      case 'floor':
        return one(map1((x) => x.floorToDouble()));
      case 'ceil':
        return one(map1((x) => x.ceilToDouble()));
      case 'round':
        return one(map1((x) => x < 0 ? -(-x).roundToDouble() : x.roundToDouble()));
      case 'fix':
        return one(map1((x) => x.truncateToDouble()));
      case 'sign':
        return one(map1((x) => x > 0 ? 1 : x < 0 ? -1 : 0));
      case 'factorial':
        return one(map1((x) {
          var r = 1.0;
          for (var k = 2; k <= x; k++) {
            r *= k;
          }
          return r;
        }));
      case 'gamma':
        return one(map1((x) {
          var r = 1.0;
          for (var k = 2; k < x; k++) {
            r *= k;
          }
          return r;
        }));
      case 'nchoosek':
        final n = s(0).toInt(), k = s(1).toInt();
        var r = 1.0;
        for (var i = 1; i <= k; i++) {
          r = r * (n - k + i) / i;
        }
        return sc(r.roundToDouble());
      case 'mod':
        return one(_elem(m(0), m(1), (x, y) => y == 0 ? x : x - (x / y).floorToDouble() * y, 'mod'));
      case 'rem':
        return one(_elem(m(0), m(1), (x, y) => y == 0 ? x : x - (x / y).truncateToDouble() * y, 'rem'));
      case 'idivide':
        return one(_elem(m(0), m(1), (x, y) => (x / y).truncateToDouble(), 'idivide'));
      case 'max':
      case 'min':
        final isMax = name == 'max';
        if (a.length >= 2 && !(a[1] is Mat && (a[1] as Mat).isEmpty)) {
          return one(_elem(m(0), m(1), (x, y) => isMax ? math.max(x, y) : math.min(x, y), name));
        }
        final x = m(0);
        if (x.n == 0) return [Mat.empty, Mat.empty];
        final dim = a.length >= 3 ? s(2).toInt() : (x.r == 1 ? 2 : 1);
        final vals = <double>[], idx = <double>[];
        final groups = dim == 2 ? [for (var i = 0; i < x.r; i++) [for (var j = 0; j < x.c; j++) x.at(i, j)]] : [for (var j = 0; j < x.c; j++) [for (var i = 0; i < x.r; i++) x.at(i, j)]];
        for (final g in groups) {
          var bi = 0;
          for (var k = 1; k < g.length; k++) {
            if (isMax ? g[k] > g[bi] : g[k] < g[bi]) bi = k;
          }
          vals.add(g[bi]);
          idx.add(bi + 1.0);
        }
        final shape = dim == 2 ? (x.r, 1) : (1, x.c);
        return [Mat(shape.$1, shape.$2, vals), Mat(shape.$1, shape.$2, idx)];
      case 'sum':
        return one(reduce(m(0), (l) => l.fold(0.0, (s, x) => s + x), dim: a.length > 1 ? s(1).toInt() : null));
      case 'prod':
        return one(reduce(m(0), (l) => l.fold(1.0, (s, x) => s * x), dim: a.length > 1 ? s(1).toInt() : null));
      case 'mean':
        return one(reduce(m(0), (l) => l.isEmpty ? double.nan : l.fold(0.0, (s, x) => s + x) / l.length, dim: a.length > 1 ? s(1).toInt() : null));
      case 'cumsum':
      case 'cumprod':
        final x = m(0);
        final out = x.copy();
        if (x.r == 1 || x.c == 1) {
          for (var k = 1; k < x.n; k++) {
            out.d[k] = name == 'cumsum' ? out.d[k - 1] + x.d[k] : out.d[k - 1] * x.d[k];
          }
        } else {
          for (var j = 0; j < x.c; j++) {
            for (var i = 1; i < x.r; i++) {
              out.set(i, j, name == 'cumsum' ? out.at(i - 1, j) + x.at(i, j) : out.at(i - 1, j) * x.at(i, j));
            }
          }
        }
        return one(out);
      case 'diff':
        final x = m(0);
        if (!x.isVector) throw OctError('diff: doar pentru vectori aici');
        final d = [for (var k = 1; k < x.n; k++) x.d[k] - x.d[k - 1]];
        return one(x.r == 1 ? Mat(1, d.length, d) : Mat(d.length, 1, d));
      case 'trapz':
        final xs = m(0), ys = a.length > 1 ? m(1) : null;
        if (ys == null) {
          var t = 0.0;
          for (var k = 1; k < xs.n; k++) {
            t += (xs.d[k] + xs.d[k - 1]) / 2;
          }
          return sc(t);
        }
        var t = 0.0;
        for (var k = 1; k < xs.n; k++) {
          t += (xs.d[k] - xs.d[k - 1]) * (ys.d[k] + ys.d[k - 1]) / 2;
        }
        return sc(t);
      case 'norm':
        final x = m(0);
        final kind = a.length > 1 ? (a[1] is OStr ? (a[1] as OStr).s : '${_num(a[1])}') : '2';
        if (x.isVector) {
          if (kind == 'Inf' || kind == 'inf' || kind == 'Infinity') return sc(x.d.fold(0.0, (s, v) => math.max(s, v.abs())));
          if (kind == '1' || kind == '1.0') return sc(x.d.fold(0.0, (s, v) => s + v.abs()));
          final p = double.tryParse(kind) ?? 2;
          if (kind == 'fro' || p == 2) return sc(math.sqrt(x.d.fold(0.0, (s, v) => s + v * v)));
          return sc(math.pow(x.d.fold(0.0, (s, v) => s + math.pow(v.abs(), p)), 1 / p).toDouble());
        }
        if (kind == 'fro') return sc(math.sqrt(x.d.fold(0.0, (s, v) => s + v * v)));
        if (kind == '1' || kind == '1.0') return sc([for (var j = 0; j < x.c; j++) [for (var i = 0; i < x.r; i++) x.at(i, j).abs()].fold(0.0, (s, v) => s + v)].reduce(math.max));
        if (kind == 'Inf' || kind == 'inf' || kind == 'Infinity') {
          return sc([for (var i = 0; i < x.r; i++) [for (var j = 0; j < x.c; j++) x.at(i, j).abs()].fold(0.0, (s, v) => s + v)].reduce(math.max));
        }
        final (vals, _) = eigSym(_mulS(x.t, x));
        return sc(math.sqrt(vals.last.abs()));
      case 'det':
        return sc(det(m(0)));
      case 'inv':
        final x = m(0);
        if (x.r != x.c) throw OctError('inv: matricea trebuie să fie pătratică');
        if (det(x).abs() < 1e-14) throw OctError('inv: matricea e singulară');
        return one(_solve(x, identity(x.r)));
      case 'trace':
        final x = m(0);
        var t = 0.0;
        for (var i = 0; i < math.min(x.r, x.c); i++) {
          t += x.at(i, i);
        }
        return sc(t);
      case 'rank':
        final x = m(0).copy();
        var rank = 0;
        final rowsUsed = List.filled(x.r, false);
        for (var j = 0; j < x.c; j++) {
          var p = -1;
          var best = 1e-10;
          for (var i = 0; i < x.r; i++) {
            if (!rowsUsed[i] && x.at(i, j).abs() > best) {
              best = x.at(i, j).abs();
              p = i;
            }
          }
          if (p < 0) continue;
          rowsUsed[p] = true;
          rank++;
          for (var i = 0; i < x.r; i++) {
            if (i == p) continue;
            final f = x.at(i, j) / x.at(p, j);
            for (var k = j; k < x.c; k++) {
              x.set(i, k, x.at(i, k) - f * x.at(p, k));
            }
          }
        }
        return sc(rank);
      case 'diag':
        final x = m(0);
        if (x.isVector) {
          final n = x.n;
          final out = Mat.zeros(n, n);
          for (var i = 0; i < n; i++) {
            out.set(i, i, x.d[i]);
          }
          return one(out);
        }
        final k = math.min(x.r, x.c);
        return one(Mat(k, 1, [for (var i = 0; i < k; i++) x.at(i, i)]));
      case 'triu':
      case 'tril':
        final x = m(0).copy();
        final k = a.length > 1 ? s(1).toInt() : 0;
        for (var i = 0; i < x.r; i++) {
          for (var j = 0; j < x.c; j++) {
            if (name == 'triu' ? j - i < k : j - i > k) x.set(i, j, 0);
          }
        }
        return one(x);
      case 'transpose':
        return one(m(0).t);
      case 'any':
        return [Mat.scalar(m(0).d.any((x) => x != 0) ? 1 : 0, logical: true)];
      case 'all':
        return [Mat.scalar(m(0).d.every((x) => x != 0) ? 1 : 0, logical: true)];
      case 'find':
        final x = m(0);
        final idx = [for (var k = 0; k < x.n; k++) if (x.d[k] != 0) k + 1.0];
        return one(x.r == 1 ? Mat(1, idx.length, idx) : Mat(idx.length, 1, idx));
      case 'linspace':
        final x0 = s(0), x1 = s(1);
        final n = a.length > 2 ? s(2).toInt() : 100;
        return one(Mat(1, n, [for (var k = 0; k < n; k++) n == 1 ? x1 : x0 + (x1 - x0) * k / (n - 1)]));
      case 'repmat':
        final x = m(0);
        final rr = s(1).toInt(), cc = a.length > 2 ? s(2).toInt() : rr;
        final out = Mat.zeros(x.r * rr, x.c * cc);
        for (var i = 0; i < out.r; i++) {
          for (var j = 0; j < out.c; j++) {
            out.set(i, j, x.at(i % x.r, j % x.c));
          }
        }
        return one(out);
      case 'reshape':
        final x = m(0);
        final r = s(1).toInt(), c = a.length > 2 ? s(2).toInt() : x.n ~/ r;
        if (r * c != x.n) throw OctError('reshape: nu se poate din ${x.r}×${x.c} în $r×$c');
        return one(Mat(r, c, List.of(x.d)));
      case 'fliplr':
        final x = m(0);
        final out = Mat.zeros(x.r, x.c);
        for (var i = 0; i < x.r; i++) {
          for (var j = 0; j < x.c; j++) {
            out.set(i, j, x.at(i, x.c - 1 - j));
          }
        }
        return one(out);
      case 'flipud':
        final x = m(0);
        final out = Mat.zeros(x.r, x.c);
        for (var i = 0; i < x.r; i++) {
          for (var j = 0; j < x.c; j++) {
            out.set(i, j, x.at(x.r - 1 - i, j));
          }
        }
        return one(out);
      case 'sort':
        final x = m(0);
        final desc = a.length > 1 && a[1] is OStr && (a[1] as OStr).s == 'descend';
        if (!x.isVector) throw OctError('sort: doar pentru vectori aici');
        final idx = List.generate(x.n, (i) => i)..sort((p, q) => desc ? x.d[q].compareTo(x.d[p]) : x.d[p].compareTo(x.d[q]));
        final vals = [for (final i in idx) x.d[i]];
        final ii = [for (final i in idx) i + 1.0];
        return x.r == 1 ? [Mat(1, x.n, vals), Mat(1, x.n, ii)] : [Mat(x.n, 1, vals), Mat(x.n, 1, ii)];
      case 'dot':
        final x = m(0), y = m(1);
        if (x.n != y.n) throw OctError('dot: vectorii au lungimi diferite');
        var t = 0.0;
        for (var k = 0; k < x.n; k++) {
          t += x.d[k] * y.d[k];
        }
        return sc(t);
      case 'cross':
        final x = m(0), y = m(1);
        if (x.n != 3 || y.n != 3) throw OctError('cross: vectori de 3 elemente');
        final v = [x.d[1] * y.d[2] - x.d[2] * y.d[1], x.d[2] * y.d[0] - x.d[0] * y.d[2], x.d[0] * y.d[1] - x.d[1] * y.d[0]];
        return one(x.r == 1 ? Mat(1, 3, v) : Mat(3, 1, v));
      case 'kron':
        final x = m(0), y = m(1);
        final out = Mat.zeros(x.r * y.r, x.c * y.c);
        for (var i = 0; i < out.r; i++) {
          for (var j = 0; j < out.c; j++) {
            out.set(i, j, x.at(i ~/ y.r, j ~/ y.c) * y.at(i % y.r, j % y.c));
          }
        }
        return one(out);
      case 'polyval':
        final p = m(0), x = m(1);
        return one(Mat(x.r, x.c, [
          for (final v in x.d) p.d.fold(0.0, (acc, c) => acc * v + c),
        ]));
      case 'vander':
        final x = m(0);
        final n = x.n;
        return one(Mat.rows([for (var i = 0; i < n; i++) [for (var j = 0; j < n; j++) math.pow(x.d[i], n - 1 - j)]]));
      case 'eig':
        final x = m(0);
        if (x.r != x.c) throw OctError('eig: matricea trebuie să fie pătratică');
        var sym = true;
        for (var i = 0; i < x.r && sym; i++) {
          for (var j = 0; j < i; j++) {
            if ((x.at(i, j) - x.at(j, i)).abs() > 1e-12) sym = false;
          }
        }
        if (sym) {
          final (vals, vecs) = eigSym(x);
          if (nout >= 2) {
            final d = Mat.zeros(x.r, x.r);
            for (var i = 0; i < x.r; i++) {
              d.set(i, i, vals[i]);
            }
            return [vecs, d];
          }
          return one(Mat(vals.length, 1, vals));
        }
        if (nout >= 2) throw OctError('eig: vectorii proprii doar pentru matrice simetrice aici');
        final vals = eigGeneral(x);
        return one(Mat(vals.length, 1, vals));
      case 'lu':
      case 'chol':
      case 'qr':
        final x = m(0);
        if (name == 'qr') {
          final (q, r) = qr(x);
          return [q, r];
        }
        if (name == 'chol') {
          final n = x.r;
          final l = Mat.zeros(n, n);
          for (var j = 0; j < n; j++) {
            var sum = x.at(j, j);
            for (var k = 0; k < j; k++) {
              sum -= l.at(j, k) * l.at(j, k);
            }
            if (sum <= 0) throw OctError('chol: matricea nu e pozitiv definită');
            l.set(j, j, math.sqrt(sum));
            for (var i = j + 1; i < n; i++) {
              var t = x.at(i, j);
              for (var k = 0; k < j; k++) {
                t -= l.at(i, k) * l.at(j, k);
              }
              l.set(i, j, t / l.at(j, j));
            }
          }
          return one(l.t);
        }
        final n = x.r;
        final u = x.copy(), l = identity(n), pm = identity(n);
        for (var k = 0; k < n; k++) {
          var p = k;
          for (var i = k + 1; i < n; i++) {
            if (u.at(i, k).abs() > u.at(p, k).abs()) p = i;
          }
          if (p != k) {
            for (var j = 0; j < n; j++) {
              for (final mm in [u, pm]) {
                final t = mm.at(k, j);
                mm.set(k, j, mm.at(p, j));
                mm.set(p, j, t);
              }
            }
            for (var j = 0; j < k; j++) {
              final t = l.at(k, j);
              l.set(k, j, l.at(p, j));
              l.set(p, j, t);
            }
          }
          for (var i = k + 1; i < n; i++) {
            final f = u.at(k, k) == 0 ? 0.0 : u.at(i, k) / u.at(k, k);
            l.set(i, k, f);
            for (var j = k; j < n; j++) {
              u.set(i, j, u.at(i, j) - f * u.at(k, j));
            }
          }
        }
        return [l, u, pm];
      case 'disp':
        final v = a.isEmpty ? Mat.empty : a[0];
        out.write(v is OStr ? '${v.s}\n' : _body(v));
        return const [];
      case 'printf':
      case 'fprintf':
        var args = a;
        if (name == 'fprintf' && args.isNotEmpty && args[0] is Mat && (args[0] as Mat).isScalar && args.length > 1 && args[1] is OStr) args = args.sublist(1);
        if (args.isEmpty) return const [];
        out.write(_sprintf(args));
        return const [];
      case 'sprintf':
        return [OStr(_sprintf(a))];
      case 'num2str':
        final v = a[0];
        if (v is OStr) return [v];
        final x = _mat(v);
        if (a.length > 1 && a[1] is Mat) {
          final p = _num(a[1]).toInt();
          return [OStr(x.d.map((d) => _fmtG(d, p)).join('  '))];
        }
        return [OStr(x.d.map((d) => d == d.roundToDouble() && d.abs() < 1e15 ? '${d.toInt()}' : _fmtG(d, 5)).join('  '))];
      case 'mat2str':
        final x = m(0);
        String f(double d) => d == d.roundToDouble() && d.abs() < 1e15 ? '${d.toInt()}' : _fmtG(d, 15);
        if (x.isScalar) return [OStr(f(x.d[0]))];
        return [OStr('[${[for (var i = 0; i < x.r; i++) [for (var j = 0; j < x.c; j++) f(x.at(i, j))].join(' ')].join(';')}]')];
      case 'func2str':
        final f = a[0] as OFunc;
        return [OStr(f.name != null ? f.name! : '@(${f.params.join(', ')}) ...')];
      case 'error':
        final msg = a.isEmpty ? 'eroare' : (a.length > 1 ? _sprintf(a) : (a[0] is OStr ? (a[0] as OStr).s : _body(a[0])));
        throw OctError(msg);
      case 'warning':
        out.write('warning: ${a.isEmpty ? '' : _sprintf(a)}\n');
        return const [];
      case 'isequal':
        final x = m(0), y = m(1);
        var eq = x.r == y.r && x.c == y.c;
        for (var k = 0; eq && k < x.n; k++) {
          eq = x.d[k] == y.d[k];
        }
        return [Mat.scalar(eq ? 1 : 0, logical: true)];
      case 'feval':
        final f = a[0];
        final rest = a.sublist(1);
        if (f is OFunc) return _callFunc(f, rest, math.max(1, nout));
        if (f is OStr) return _callName(f.s, rest, math.max(1, nout));
        throw OctError('feval: primul argument e o funcție');
      case 'fflush':
      case 'tic':
        return const [];
      case 'stdout':
        return sc(1);
      case 'toc':
        return sc(0);
      case 'exist':
        final n = (a[0] as OStr).s;
        return sc(globals.containsKey(n) ? 1 : (functions.containsKey(n) || _builtins.containsKey(n)) ? 2 : 0);
      case 'cat':
      case 'horzcat':
      case 'vertcat':
        throw OctError('$name: folosește [a, b] sau [a; b]');
    }
    throw OctError("'$name' nu e disponibil aici");
  }

  String _sprintf(List<OVal> a) {
    final fmt = a[0] is OStr ? (a[0] as OStr).s : _body(a[0]);
    final vals = <OVal>[];
    for (final v in a.skip(1)) {
      if (v is Mat) {
        for (final x in v.d) {
          vals.add(Mat.scalar(x));
        }
      } else {
        vals.add(v);
      }
    }
    final spec = RegExp(r'%([-+ 0#]*)(\d+)?(?:\.(\d+))?([dfgeisxc%])');
    final b = StringBuffer();
    var vi = 0;
    var first = true;
    while (first || vi < vals.length) {
      first = false;
      var last = 0;
      var used = false;
      for (final mm in spec.allMatches(fmt)) {
        b.write(_esc(fmt.substring(last, mm.start)));
        last = mm.end;
        final conv = mm[4]!;
        if (conv == '%') {
          b.write('%');
          continue;
        }
        if (vi >= vals.length && used) break;
        used = true;
        final v = vi < vals.length ? vals[vi++] : null;
        final flags = mm[1]!;
        final w = mm[2] == null ? null : int.parse(mm[2]!);
        final p = mm[3] == null ? null : int.parse(mm[3]!);
        String t;
        if (v == null) {
          t = '';
        } else if (conv == 's') {
          t = v is OStr ? v.s : _fmtShort((v as Mat).d[0]);
        } else if (v is OStr) {
          t = v.s;
        } else {
          final x = (v as Mat).d[0];
          t = switch (conv) {
            'd' || 'i' => x == x.roundToDouble() ? '${x.toInt()}' : _fmtG(x, 5),
            'f' => x.isInfinite ? (x > 0 ? 'Inf' : '-Inf') : x.isNaN ? 'NaN' : x.toStringAsFixed(p ?? 6),
            'e' => x.toStringAsExponential(p ?? 6).replaceFirstMapped(RegExp(r'e([+-])(\d)$'), (q) => 'e${q[1]}0${q[2]}'),
            'g' => _fmtG(x, p ?? 6),
            'x' => x.toInt().toRadixString(16),
            'c' => String.fromCharCode(x.toInt()),
            _ => '$x',
          };
          if (flags.contains('+') && x >= 0 && conv != 'c') t = '+$t';
        }
        if (w != null && t.length < w) t = flags.contains('-') ? t.padRight(w) : (flags.contains('0') ? t.padLeft(w, '0') : t.padLeft(w));
        b.write(t);
      }
      if (last < fmt.length && (vi >= vals.length || !used)) {
        b.write(_esc(fmt.substring(last)));
      } else if (last < fmt.length) {
        b.write(_esc(fmt.substring(last)));
      }
      if (!used) break;
    }
    return b.toString();
  }

  static String _esc(String s) => s.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t').replaceAll(r'\\', '\\');

  // ---------------------------------------------------------------- display
  static String _fmtG(double x, int p) {
    if (x.isNaN) return 'NaN';
    if (x.isInfinite) return x > 0 ? 'Inf' : '-Inf';
    if (x == 0) return '0';
    final e = (math.log(x.abs()) / math.ln10).floor();
    if (e < -5 || e >= p) {
      final s = x.toStringAsExponential(math.max(0, p - 1));
      final k = s.indexOf('e');
      var mant = s.substring(0, k);
      if (mant.contains('.')) mant = mant.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
      final ex = int.parse(s.substring(k + 1));
      return '${mant}e${ex < 0 ? '-' : '+'}${ex.abs().toString().padLeft(2, '0')}';
    }
    var s = x.toStringAsFixed(math.max(0, p - 1 - e));
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  static String _fmtNum(double x) => x == x.roundToDouble() && x.abs() < 1e15 ? '${x.toInt()}' : _fmtG(x, 5);

  static String _fmtShort(double x) {
    if (x.isNaN) return 'NaN';
    if (x.isInfinite) return x > 0 ? 'Inf' : '-Inf';
    if (x == x.roundToDouble() && x.abs() < 1e10) return '${x.toInt()}';
    final a = x.abs();
    if (a >= 1e5 || a < 1e-5) return _fmtG(x, 5).replaceFirstMapped(RegExp(r'^(-?\d)(?:\.(\d+))?e'), (m) => '${m[1]}.${(m[2] ?? '').padRight(4, '0')}e');
    return x.toStringAsFixed(4);
  }

  String _body(OVal v) {
    if (v is OStr) return '${v.s}\n';
    if (v is OFunc) return v.name != null ? '@${v.name}\n' : '@(${v.params.join(', ')}) ...\n';
    final m = v as Mat;
    if (m.n == 0) return '[](${m.r}x${m.c})\n';
    if (m.isScalar) return '${_fmtShort(m.d[0])}\n';
    final ints = m.d.every((x) => x == x.roundToDouble() && x.abs() < 1e10 || x.isNaN || x.isInfinite);
    final big = m.d.any((x) => x.isFinite && x.abs() >= 1e5);
    String cell(double x) {
      if (ints) return _fmtNum(x);
      if (x.isNaN) return 'NaN';
      if (x.isInfinite) return x > 0 ? 'Inf' : '-Inf';
      if (x == 0) return '0';
      return big ? _fmtShort(x) : x.toStringAsFixed(4);
    }

    final cells = [for (var i = 0; i < m.r; i++) [for (var j = 0; j < m.c; j++) cell(m.at(i, j))]];
    final w = cells.expand((r) => r).fold<int>(0, (s, t) => math.max(s, t.length));
    final b = StringBuffer();
    for (final row in cells) {
      b.write('${row.map((t) => t.padLeft(w + (ints ? 3 : 3))).join()}\n');
    }
    return b.toString();
  }

  String display(String name, OVal v) {
    if (v is OStr) return '$name = ${v.s}\n';
    if (v is OFunc) return '$name =\n\n${_body(v)}\n';
    final m = v as Mat;
    if (m.isScalar) return '$name = ${_fmtShort(m.d[0])}\n';
    if (m.n == 0) return '$name = [](${m.r}x${m.c})\n';
    return '$name =\n\n${_body(m)}\n';
  }

  /// A value read back from text, for the checks: "[1 2; 3 4]", "3", "@(x) x.^2".
  OVal parseValue(String src) => evalExpr(src);
}
