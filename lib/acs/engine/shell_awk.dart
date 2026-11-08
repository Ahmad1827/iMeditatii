// =============================================================================
// AWK, for the USO shell
//   Patterns (BEGIN, END, expressions, /regex/), fields ($1, $NF), NR, NF, FS,
//   OFS, associative arrays, if / while / for / for-in, print and printf,
//   length substr index split sub gsub toupper tolower int sprintf match.
// =============================================================================

import 'dart:math' as math;

import 'shell.dart';
import 'shell_cmds.dart';
import 'vfs.dart';

class _Tk {
  final String t; // kind: num str re name func op nl eof
  final String v;
  const _Tk(this.t, this.v);
  @override
  String toString() => '$t:$v';
}

const _funcs = {'length', 'substr', 'index', 'split', 'sub', 'gsub', 'toupper', 'tolower', 'int', 'sqrt', 'exp', 'log', 'sin', 'cos', 'atan2', 'sprintf', 'match', 'rand', 'srand', 'system'};
const _keywords = {'BEGIN', 'END', 'if', 'else', 'while', 'for', 'do', 'in', 'print', 'printf', 'next', 'exit', 'break', 'continue', 'delete', 'getline', 'return', 'function'};

List<_Tk> _lex(String s) {
  final out = <_Tk>[];
  var i = 0;
  bool regexAllowed() {
    if (out.isEmpty) return true;
    final l = out.last;
    if (l.t == 'num' || l.t == 'str' || l.t == 'name' || l.t == 're') return false;
    if (l.t == 'op' && (l.v == ')' || l.v == ']' || l.v == r'$' || l.v == '++' || l.v == '--')) return false;
    if (l.t == 'kw' && (l.v == 'getline')) return false;
    return true;
  }

  while (i < s.length) {
    final c = s[i];
    if (c == ' ' || c == '\t' || c == '\r') {
      i++;
      continue;
    }
    if (c == '\\' && i + 1 < s.length && s[i + 1] == '\n') {
      i += 2;
      continue;
    }
    if (c == '#') {
      while (i < s.length && s[i] != '\n') {
        i++;
      }
      continue;
    }
    if (c == '\n' || c == ';') {
      out.add(_Tk('nl', c));
      i++;
      continue;
    }
    if (c == '"') {
      final b = StringBuffer();
      i++;
      while (i < s.length && s[i] != '"') {
        if (s[i] == '\\' && i + 1 < s.length) {
          final n = s[i + 1];
          b.write(switch (n) { 'n' => '\n', 't' => '\t', '"' => '"', '\\' => '\\', '/' => '/', _ => '\\$n' });
          i += 2;
          continue;
        }
        b.write(s[i++]);
      }
      if (i >= s.length) throw ShError('syntax error: unterminated string', 2);
      i++;
      out.add(_Tk('str', b.toString()));
      continue;
    }
    if (c == '/' && regexAllowed()) {
      final b = StringBuffer();
      i++;
      while (i < s.length && s[i] != '/') {
        if (s[i] == '\\' && i + 1 < s.length) {
          b.write(s[i]);
          b.write(s[i + 1]);
          i += 2;
          continue;
        }
        if (s[i] == '\n') throw ShError('syntax error: newline in regex', 2);
        b.write(s[i++]);
      }
      i++;
      out.add(_Tk('re', b.toString()));
      continue;
    }
    final num = RegExp(r'(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?').matchAsPrefix(s, i);
    if (num != null) {
      out.add(_Tk('num', num[0]!));
      i = num.end;
      continue;
    }
    final name = RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, i);
    if (name != null) {
      final w = name[0]!;
      i = name.end;
      out.add(_Tk(_keywords.contains(w) ? 'kw' : _funcs.contains(w) ? 'func' : 'name', w));
      continue;
    }
    String? op;
    for (final o in ['+=', '-=', '*=', '/=', '%=', '^=', '==', '!=', '<=', '>=', '&&', '||', '++', '--', '!~', '>>', '**']) {
      if (s.startsWith(o, i)) {
        op = o;
        break;
      }
    }
    op ??= '{}()[],<>=!~+-*/%^?:\$|'.contains(c) ? c : null;
    if (op == null) throw ShError("syntax error at source line 1: unexpected character '$c'", 2);
    if (op == '**') op = '^';
    out.add(_Tk('op', op));
    i += op.length;
  }
  out.add(const _Tk('eof', ''));
  return out;
}

// ---------------------------------------------------------------- tree
sealed class _E {}

class _Num extends _E {
  final double v;
  _Num(this.v);
}

class _Str extends _E {
  final String v;
  _Str(this.v);
}

class _Re extends _E {
  final String src;
  _Re(this.src);
}

class _Var extends _E {
  final String name;
  _Var(this.name);
}

class _Field extends _E {
  final _E index;
  _Field(this.index);
}

class _Index extends _E {
  final String name;
  final List<_E> keys;
  _Index(this.name, this.keys);
}

class _Bin extends _E {
  final String op;
  final _E l, r;
  _Bin(this.op, this.l, this.r);
}

class _Un extends _E {
  final String op;
  final _E e;
  _Un(this.op, this.e);
}

class _Assign extends _E {
  final String op;
  final _E target, value;
  _Assign(this.op, this.target, this.value);
}

class _IncDec extends _E {
  final String op;
  final bool prefix;
  final _E target;
  _IncDec(this.op, this.prefix, this.target);
}

class _Cond extends _E {
  final _E c, a, b;
  _Cond(this.c, this.a, this.b);
}

class _Call extends _E {
  final String name;
  final List<_E> args;
  _Call(this.name, this.args);
}

class _In extends _E {
  final List<_E> keys;
  final String arr;
  _In(this.keys, this.arr);
}

class _Group extends _E {
  final _E e;
  _Group(this.e);
}

sealed class _S {}

class _Block extends _S {
  final List<_S> body;
  _Block(this.body);
}

class _Expr extends _S {
  final _E e;
  _Expr(this.e);
}

class _Print extends _S {
  final List<_E> args;
  final bool f;
  final String? redir;
  final _E? target;
  _Print(this.args, this.f, this.redir, this.target);
}

class _If extends _S {
  final _E c;
  final _S a;
  final _S? b;
  _If(this.c, this.a, this.b);
}

class _While extends _S {
  final _E c;
  final _S body;
  final bool doWhile;
  _While(this.c, this.body, this.doWhile);
}

class _For extends _S {
  final _S? init;
  final _E? c;
  final _S? step;
  final _S body;
  _For(this.init, this.c, this.step, this.body);
}

class _ForIn extends _S {
  final String v, arr;
  final _S body;
  _ForIn(this.v, this.arr, this.body);
}

class _Simple extends _S {
  final String kind; // next exit break continue
  final _E? arg;
  _Simple(this.kind, this.arg);
}

class _Delete extends _S {
  final String arr;
  final List<_E>? keys;
  _Delete(this.arr, this.keys);
}

class _Rule {
  final String kind; // BEGIN END main
  final _E? pattern;
  final _E? pattern2;
  final _S? action;
  bool inRange = false;
  _Rule(this.kind, this.pattern, this.pattern2, this.action);
}

class _P {
  final List<_Tk> t;
  int p = 0;
  _P(this.t);

  _Tk get _c => t[p];
  bool _is(String kind, [String? v]) => _c.t == kind && (v == null || _c.v == v);
  bool _op(String v) => _is('op', v);
  _Tk _next() => t[p++];

  void _expectOp(String v) {
    if (!_op(v)) throw ShError("syntax error: expected '$v' near '${_c.v}'", 2);
    p++;
  }

  void _nls() {
    while (_is('nl')) {
      p++;
    }
  }

  void _nlOnly() {
    while (_is('nl', '\n')) {
      p++;
    }
  }

  List<_Rule> program() {
    final rules = <_Rule>[];
    _nls();
    while (!_is('eof')) {
      if (_is('kw', 'BEGIN') || _is('kw', 'END')) {
        final k = _next().v;
        _nlOnly();
        rules.add(_Rule(k, null, null, _block()));
      } else if (_is('kw', 'function')) {
        throw ShError('awk: funcțiile proprii nu sunt acceptate aici', 2);
      } else {
        _E? pat;
        _E? pat2;
        if (!_op('{')) {
          pat = expr();
          if (_op(',')) {
            p++;
            _nlOnly();
            pat2 = expr();
          }
        }
        rules.add(_Rule('main', pat, pat2, _op('{') ? _block() : null));
      }
      _nls();
    }
    return rules;
  }

  _Block _block() {
    _expectOp('{');
    final body = <_S>[];
    _nls();
    while (!_op('}')) {
      if (_is('eof')) throw ShError("syntax error: missing '}'", 2);
      body.add(stmt());
      _nls();
    }
    p++;
    return _Block(body);
  }

  _S _simpleOrBlock() {
    _nlOnly();
    if (_op('{')) return _block();
    final s = stmt();
    if (_is('nl', ';')) p++;
    return s;
  }

  _S stmt() {
    if (_op('{')) return _block();
    if (_is('kw', 'if')) {
      p++;
      _expectOp('(');
      final c = expr();
      _expectOp(')');
      final a = _simpleOrBlock();
      final save = p;
      _nls();
      if (_is('kw', 'else')) {
        p++;
        return _If(c, a, _simpleOrBlock());
      }
      p = save;
      return _If(c, a, null);
    }
    if (_is('kw', 'while')) {
      p++;
      _expectOp('(');
      final c = expr();
      _expectOp(')');
      return _While(c, _simpleOrBlock(), false);
    }
    if (_is('kw', 'do')) {
      p++;
      final body = _simpleOrBlock();
      _nls();
      if (!_is('kw', 'while')) throw ShError("syntax error: expected 'while'", 2);
      p++;
      _expectOp('(');
      final c = expr();
      _expectOp(')');
      return _While(c, body, true);
    }
    if (_is('kw', 'for')) {
      p++;
      _expectOp('(');
      if (_is('name') && t[p + 1].t == 'kw' && t[p + 1].v == 'in' && t[p + 2].t == 'name' && t[p + 3].t == 'op' && t[p + 3].v == ')') {
        final v = _next().v;
        p++;
        final arr = _next().v;
        p++;
        return _ForIn(v, arr, _simpleOrBlock());
      }
      final init = _is('nl', ';') ? null : _Expr(expr());
      if (!_is('nl', ';')) throw ShError("syntax error in for", 2);
      p++;
      final c = _is('nl', ';') ? null : expr();
      if (!_is('nl', ';')) throw ShError("syntax error in for", 2);
      p++;
      final step = _op(')') ? null : _Expr(expr());
      _expectOp(')');
      return _For(init, c, step, _simpleOrBlock());
    }
    if (_is('kw', 'print') || _is('kw', 'printf')) {
      final f = _next().v == 'printf';
      final args = <_E>[];
      final paren = _op('(');
      if (!_is('nl') && !_op('}') && !_op('>') && !_op('|') && !_op('>>')) {
        args.add(expr(noGt: true));
        while (_op(',')) {
          p++;
          _nlOnly();
          args.add(expr(noGt: true));
        }
      }
      // print (a, b) was read as a group; unwrap
      if (paren && args.length == 1 && args[0] is _Group) {
        final g = (args[0] as _Group).e;
        args[0] = g;
      }
      String? redir;
      _E? target;
      if (_op('>') || _op('>>') || _op('|')) {
        redir = _next().v;
        target = _primaryPostfix();
      }
      return _Print(args, f, redir, target);
    }
    if (_is('kw', 'next') || _is('kw', 'break') || _is('kw', 'continue')) return _Simple(_next().v, null);
    if (_is('kw', 'exit')) {
      p++;
      final arg = _is('nl') || _op('}') ? null : expr();
      return _Simple('exit', arg);
    }
    if (_is('kw', 'delete')) {
      p++;
      final name = _next().v;
      if (_op('[')) {
        p++;
        final keys = [expr()];
        while (_op(',')) {
          p++;
          keys.add(expr());
        }
        _expectOp(']');
        return _Delete(name, keys);
      }
      return _Delete(name, null);
    }
    return _Expr(expr());
  }

  bool _noGt = false;

  _E expr({bool noGt = false}) {
    final saved = _noGt;
    _noGt = noGt;
    try {
      return _ternary();
    } finally {
      _noGt = saved;
    }
  }

  _E _ternary() {
    final c = _or();
    if (_op('?')) {
      p++;
      _nlOnly();
      final a = _ternary();
      _nlOnly();
      _expectOp(':');
      _nlOnly();
      return _Cond(c, a, _ternary());
    }
    if (_c.t == 'op' && const {'=', '+=', '-=', '*=', '/=', '%=', '^='}.contains(_c.v) && (c is _Var || c is _Field || c is _Index)) {
      final op = _next().v;
      _nlOnly();
      return _Assign(op, c, _ternary());
    }
    return c;
  }

  _E _or() {
    var l = _and();
    while (_op('||')) {
      p++;
      _nlOnly();
      l = _Bin('||', l, _and());
    }
    return l;
  }

  _E _and() {
    var l = _in();
    while (_op('&&')) {
      p++;
      _nlOnly();
      l = _Bin('&&', l, _in());
    }
    return l;
  }

  _E _in() {
    var l = _match();
    while (_is('kw', 'in')) {
      p++;
      final arr = _next().v;
      l = _In(l is _Group && l.e is _Bin && (l.e as _Bin).op == ',' ? _flatten(l.e) : [l], arr);
    }
    return l;
  }

  List<_E> _flatten(_E e) => e is _Bin && e.op == ',' ? [..._flatten(e.l), e.r] : [e];

  _E _match() {
    var l = _rel();
    while (_op('~') || _op('!~')) {
      final op = _next().v;
      l = _Bin(op, l, _rel());
    }
    return l;
  }

  _E _rel() {
    final l = _concat();
    if (_c.t == 'op' && const {'<', '<=', '==', '!=', '>=', '>'}.contains(_c.v)) {
      if (_noGt && (_c.v == '>')) return l;
      final op = _next().v;
      return _Bin(op, l, _concat());
    }
    return l;
  }

  bool _startsOperand() {
    final k = _c;
    if (k.t == 'num' || k.t == 'str' || k.t == 're' || k.t == 'name' || k.t == 'func') return true;
    if (k.t == 'op' && (k.v == r'$' || k.v == '(' || k.v == '!' || k.v == '-' || k.v == '+' || k.v == '++' || k.v == '--')) return true;
    return false;
  }

  _E _concat() {
    var l = _add();
    while (_startsOperand() && !(_is('op', '-') || _is('op', '+')) && !_is('kw', 'in')) {
      l = _Bin('concat', l, _add());
    }
    return l;
  }

  _E _add() {
    var l = _mul();
    while (_op('+') || _op('-')) {
      final op = _next().v;
      l = _Bin(op, l, _mul());
    }
    return l;
  }

  _E _mul() {
    var l = _unary();
    while (_op('*') || _op('/') || _op('%')) {
      final op = _next().v;
      l = _Bin(op, l, _unary());
    }
    return l;
  }

  _E _unary() {
    if (_op('!')) {
      p++;
      return _Un('!', _unary());
    }
    if (_op('-')) {
      p++;
      return _Un('-', _unary());
    }
    if (_op('+')) {
      p++;
      return _Un('+', _unary());
    }
    return _pow();
  }

  _E _pow() {
    final b = _incdec();
    if (_op('^')) {
      p++;
      return _Bin('^', b, _unaryPow());
    }
    return b;
  }

  _E _unaryPow() {
    if (_op('-')) {
      p++;
      return _Un('-', _unaryPow());
    }
    return _pow();
  }

  _E _incdec() {
    if (_op('++') || _op('--')) {
      final op = _next().v;
      return _IncDec(op, true, _primaryPostfix());
    }
    final e = _primaryPostfix();
    if ((_op('++') || _op('--')) && (e is _Var || e is _Field || e is _Index)) {
      return _IncDec(_next().v, false, e);
    }
    return e;
  }

  _E _primaryPostfix() {
    final k = _next();
    switch (k.t) {
      case 'num':
        return _Num(double.parse(k.v));
      case 'str':
        return _Str(k.v);
      case 're':
        return _Re(k.v);
      case 'func':
        final args = <_E>[];
        if (_op('(')) {
          p++;
          if (!_op(')')) {
            args.add(expr());
            while (_op(',')) {
              p++;
              _nlOnly();
              args.add(expr());
            }
          }
          _expectOp(')');
        } else if (k.v != 'length') {
          throw ShError("syntax error: '${k.v}' needs (", 2);
        }
        return _Call(k.v, args);
      case 'name':
        if (_op('[')) {
          p++;
          final keys = [expr()];
          while (_op(',')) {
            p++;
            keys.add(expr());
          }
          _expectOp(']');
          return _Index(k.v, keys);
        }
        return _Var(k.v);
      case 'op':
        if (k.v == r'$') {
          if (_op('++') || _op('--')) return _Field(_incdec());
          if (_op('-')) {
            p++;
            return _Field(_Un('-', _primaryPostfix()));
          }
          return _Field(_primaryPostfix());
        }
        if (k.v == '(') {
          var e = expr();
          while (_op(',')) {
            p++;
            e = _Bin(',', e, expr());
          }
          _expectOp(')');
          return _Group(e);
        }
        if (k.v == '-') return _Un('-', _primaryPostfix());
        if (k.v == '!') return _Un('!', _primaryPostfix());
    }
    throw ShError("syntax error at source line 1 near '${k.v}'", 2);
  }
}

class _Next implements Exception {}

class _AwkExit implements Exception {
  final int status;
  _AwkExit(this.status);
}

class _ABreak implements Exception {}

class _AContinue implements Exception {}

class Awk {
  final Shell sh;
  final ShCtx ctx;
  final Sink out;
  final Map<String, Object> vars = {};
  final Map<String, Map<String, Object>> arrays = {};
  List<String> fields = [''];
  bool _dirty = false; // a field was set: $0 must be rebuilt
  final Map<String, StringBuffer> files = {};
  int _steps = 0;
  final _rand = math.Random(0);

  Awk(this.sh, this.ctx, this.out);

  static int main(Shell sh, ShCtx c, List<String> a, ShIn inp, Sink out, Sink err) {
    String? fs;
    final assigns = <String>[];
    String? prog;
    final files = <String>[];
    for (var k = 0; k < a.length; k++) {
      final x = a[k];
      if (prog == null && x == '-F' && k + 1 < a.length) {
        fs = a[++k];
      } else if (prog == null && x.startsWith('-F')) {
        fs = x.substring(2);
      } else if (prog == null && x == '-v' && k + 1 < a.length) {
        assigns.add(a[++k]);
      } else if (prog == null && x == '-f' && k + 1 < a.length) {
        prog = sh.fs.read(a[++k], c.cwd);
      } else if (prog == null) {
        prog = x;
      } else {
        files.add(x);
      }
    }
    if (prog == null) throw ShError('usage: awk [-F fs][-v var=value][prog | -f progfile][file ...]', 2);
    final aw = Awk(sh, c, out);
    aw.vars['FS'] = fs == null ? ' ' : (fs == 't' || fs == r'\t' ? '\t' : fs);
    aw.vars['OFS'] = ' ';
    aw.vars['ORS'] = '\n';
    aw.vars['NR'] = 0.0;
    aw.vars['NF'] = 0.0;
    aw.vars['FNR'] = 0.0;
    aw.vars['SUBSEP'] = '\x1c';
    aw.vars['RSTART'] = 0.0;
    aw.vars['RLENGTH'] = -1.0;
    for (final s in assigns) {
      final eq = s.indexOf('=');
      if (eq > 0) aw.vars[s.substring(0, eq)] = unescape(s.substring(eq + 1));
    }
    final rules = _P(_lex(prog)).program();
    var status = 0;
    try {
      try {
        for (final r in rules.where((r) => r.kind == 'BEGIN')) {
          aw._run(r.action!);
        }
        final hasMain = rules.any((r) => r.kind != 'BEGIN');
        if (hasMain) {
          final inputs = <(String, String)>[];
          if (files.isEmpty) {
            inputs.add(('', inp.readAll()));
          } else {
            for (final f in files) {
              final eq = f.indexOf('=');
              if (eq > 0 && RegExp(r'^[A-Za-z_]\w*$').hasMatch(f.substring(0, eq))) {
                inputs.add(('\u0000assign', f));
                continue;
              }
              try {
                inputs.add((f, f == '-' ? inp.readAll() : sh.fs.read(f, c.cwd)));
              } on ShError catch (x) {
                err.write("awk: cannot open \"$f\" (${x.message.split(': ').last})\n");
                status = 2;
              }
            }
          }
          outer:
          for (final (name, text) in inputs) {
            if (name == '\u0000assign') {
              final eq = text.indexOf('=');
              aw.vars[text.substring(0, eq)] = text.substring(eq + 1);
              continue;
            }
            aw.vars['FILENAME'] = name;
            aw.vars['FNR'] = 0.0;
            for (final line in textLines(text)) {
              aw.vars['NR'] = aw._num(aw.vars['NR']!) + 1;
              aw.vars['FNR'] = aw._num(aw.vars['FNR']!) + 1;
              aw._setRecord(line);
              try {
                for (final r in rules.where((r) => r.kind == 'main')) {
                  if (aw._matches(r)) {
                    if (r.action == null) {
                      aw._print([aw._record()], null, null);
                    } else {
                      aw._run(r.action!);
                    }
                  }
                }
              } on _Next {
                continue;
              } on _AwkExit catch (e) {
                status = e.status;
                break outer;
              }
            }
          }
        }
      } on _AwkExit catch (e) {
        status = e.status;
      }
      for (final r in rules.where((r) => r.kind == 'END')) {
        aw._run(r.action!);
      }
    } on _AwkExit catch (e) {
      status = e.status;
    } on _Next {
      // next in BEGIN/END: ignore
    }
    for (final f in aw.files.entries) {
      sh.fs.write(f.key, c.cwd, f.value.toString());
    }
    return status;
  }

  bool _matches(_Rule r) {
    if (r.pattern == null) return true;
    if (r.pattern2 != null) {
      if (r.inRange) {
        if (_truthy(_eval(r.pattern2!))) r.inRange = false;
        return true;
      }
      if (_truthy(_eval(r.pattern!))) {
        r.inRange = !_truthy(_eval(r.pattern2!));
        return true;
      }
      return false;
    }
    return _truthy(_eval(r.pattern!));
  }

  void _step() {
    if (++_steps > 2000000) throw ShError('awk: execuția a durat prea mult (o buclă infinită?)', 124);
  }

  // ------------------------------------------------------------ records and fields
  void _setRecord(String line) {
    fields = [line, ..._split(line, _str(vars['FS']!))];
    vars['NF'] = (fields.length - 1).toDouble();
    _dirty = false;
  }

  List<String> _split(String s, String fs) {
    if (fs == ' ') return s.trim().isEmpty ? [] : s.trim().split(RegExp(r'[ \t\n]+'));
    if (s.isEmpty) return [];
    if (fs.length == 1 && fs != '\\') return s.split(fs);
    return s.split(posixRegex(fs, ere: true));
  }

  String _record() {
    if (_dirty) {
      fields[0] = fields.sublist(1).join(_str(vars['OFS']!));
      _dirty = false;
    }
    return fields[0];
  }

  String _getField(int i) {
    if (i < 0) throw ShError('awk: trying to access out of range field $i', 2);
    if (i == 0) return _record();
    return i < fields.length ? fields[i] : '';
  }

  void _setField(int i, String v) {
    if (i == 0) {
      _setRecord(v);
      return;
    }
    while (fields.length <= i) {
      fields.add('');
    }
    fields[i] = v;
    vars['NF'] = (fields.length - 1).toDouble();
    _dirty = true;
  }

  // ------------------------------------------------------------ values
  static final _numRe = RegExp(r'^\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?\s*$');

  double _num(Object v) {
    if (v is double) return v;
    final s = v as String;
    final m = RegExp(r'^\s*[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?').firstMatch(s);
    return m == null ? 0 : double.parse(m[0]!.trim());
  }

  String _str(Object v) {
    if (v is String) return v;
    final d = v as double;
    if (d == d.truncateToDouble() && d.abs() < 1e16) return '${d.toInt()}';
    return formatG(d, 6);
  }

  bool _truthy(Object v) => v is double ? v != 0 : (v as String).isNotEmpty;

  bool _looksNumeric(Object v) => v is double || _numRe.hasMatch(v as String);

  Object _get(String name) {
    if (name == 'NF') {
      _record();
      return (fields.length - 1).toDouble();
    }
    return vars[name] ?? '';
  }

  void _set(_E target, Object v) {
    switch (target) {
      case _Var(:final name):
        if (name == 'NF') {
          final n = _num(v).toInt();
          _record();
          if (n < fields.length - 1) {
            fields = fields.sublist(0, n + 1);
          } else {
            while (fields.length <= n) {
              fields.add('');
            }
          }
          vars['NF'] = n.toDouble();
          _dirty = true;
          return;
        }
        vars[name] = v;
      case _Field(:final index):
        _setField(_num(_eval(index)).toInt(), _str(v));
      case _Index(:final name, :final keys):
        arrays.putIfAbsent(name, () => {})[_key(keys)] = v;
      default:
        throw ShError('awk: assignment to a non-variable', 2);
    }
  }

  String _key(List<_E> keys) => keys.map((k) => _str(_eval(k))).join(_str(vars['SUBSEP']!));

  RegExp _re(_E e) => e is _Re ? posixRegex(e.src, ere: true) : posixRegex(_str(_eval(e)), ere: true);

  // ------------------------------------------------------------ evaluation
  Object _eval(_E e) {
    switch (e) {
      case _Num(:final v):
        return v;
      case _Str(:final v):
        return v;
      case _Re():
        return _re(e).hasMatch(_record()) ? 1.0 : 0.0;
      case _Var(:final name):
        return _get(name);
      case _Group(:final e):
        return _eval(e);
      case _Field(:final index):
        return _getField(_num(_eval(index)).toInt());
      case _Index(:final name, :final keys):
        return arrays.putIfAbsent(name, () => {}).putIfAbsent(_key(keys), () => '');
      case _In(:final keys, :final arr):
        return (arrays[arr]?.containsKey(_key(keys)) ?? false) ? 1.0 : 0.0;
      case _Cond(:final c, :final a, :final b):
        return _truthy(_eval(c)) ? _eval(a) : _eval(b);
      case _Un(:final op, :final e):
        final v = _eval(e);
        return switch (op) { '!' => _truthy(v) ? 0.0 : 1.0, '-' => -_num(v), _ => _num(v) };
      case _Assign(:final op, :final target, :final value):
        var v = _eval(value);
        if (op != '=') {
          final cur = _num(_eval(target)), r = _num(v);
          v = switch (op) {
            '+=' => cur + r,
            '-=' => cur - r,
            '*=' => cur * r,
            '/=' => r == 0 ? throw ShError('awk: division by zero in /=', 2) : cur / r,
            '%=' => r == 0 ? throw ShError('awk: division by zero in %=', 2) : cur.remainder(r),
            _ => math.pow(cur, r).toDouble(),
          };
        }
        _set(target, v);
        return v;
      case _IncDec(:final op, :final prefix, :final target):
        final cur = _num(_eval(target));
        final nv = op == '++' ? cur + 1 : cur - 1;
        _set(target, nv);
        return prefix ? nv : cur;
      case _Bin(:final op, :final l, :final r):
        switch (op) {
          case '&&':
            return _truthy(_eval(l)) && _truthy(_eval(r)) ? 1.0 : 0.0;
          case '||':
            return _truthy(_eval(l)) || _truthy(_eval(r)) ? 1.0 : 0.0;
          case '~':
          case '!~':
            final m = _re(r).hasMatch(_str(_eval(l)));
            return (op == '~') == m ? 1.0 : 0.0;
          case 'concat':
            return _str(_eval(l)) + _str(_eval(r));
          case ',':
            return '${_str(_eval(l))}${_str(vars['SUBSEP']!)}${_str(_eval(r))}';
        }
        final a = _eval(l), b = _eval(r);
        switch (op) {
          case '+':
            return _num(a) + _num(b);
          case '-':
            return _num(a) - _num(b);
          case '*':
            return _num(a) * _num(b);
          case '/':
            if (_num(b) == 0) throw ShError('awk: division by zero', 2);
            return _num(a) / _num(b);
          case '%':
            if (_num(b) == 0) throw ShError('awk: division by zero in %', 2);
            return _num(a).remainder(_num(b));
          case '^':
            return math.pow(_num(a), _num(b)).toDouble();
        }
        // comparisons: numbers if both look numeric, else strings
        final numeric = _looksNumeric(a) && _looksNumeric(b) && !(l is _Str || r is _Str);
        final cmp = numeric ? _num(a).compareTo(_num(b)) : _str(a).compareTo(_str(b));
        return switch (op) {
              '<' => cmp < 0,
              '<=' => cmp <= 0,
              '>' => cmp > 0,
              '>=' => cmp >= 0,
              '==' => cmp == 0,
              _ => cmp != 0,
            }
            ? 1.0
            : 0.0;
      case _Call(:final name, :final args):
        return _call(name, args);
    }
  }

  Object _call(String name, List<_E> a) {
    String s(int i) => i < a.length ? _str(_eval(a[i])) : '';
    double n(int i) => i < a.length ? _num(_eval(a[i])) : 0;
    switch (name) {
      case 'length':
        if (a.isEmpty) return _record().length.toDouble();
        if (a[0] is _Var && arrays.containsKey((a[0] as _Var).name)) return arrays[(a[0] as _Var).name]!.length.toDouble();
        return s(0).length.toDouble();
      case 'substr':
        final str = s(0);
        var m = n(1).round();
        var len = a.length > 2 ? n(2).round() : str.length + 1;
        if (m < 1) {
          len += m - 1;
          m = 1;
        }
        if (len <= 0 || m > str.length) return '';
        return str.substring(m - 1, math.min(str.length, m - 1 + len));
      case 'index':
        return (s(0).indexOf(s(1)) + 1).toDouble();
      case 'split':
        final str = s(0);
        final arr = (a[1] as _Var).name;
        final parts = _split(str, a.length > 2 ? (a[2] is _Re ? (a[2] as _Re).src : s(2)) : _str(vars['FS']!));
        arrays[arr] = {for (var k = 0; k < parts.length; k++) '${k + 1}': parts[k]};
        return parts.length.toDouble();
      case 'sub':
      case 'gsub':
        final re = _re(a[0]);
        final rep = s(1);
        final target = a.length > 2 ? a[2] : _Field(_Num(0));
        final cur = _str(_eval(target));
        var count = 0;
        final b = StringBuffer();
        var last = 0;
        for (final m in re.allMatches(cur)) {
          if (name == 'sub' && count == 1) break;
          b.write(cur.substring(last, m.start));
          for (var k = 0; k < rep.length; k++) {
            if (rep[k] == '\\' && k + 1 < rep.length && (rep[k + 1] == '&' || rep[k + 1] == '\\')) {
              b.write(rep[++k]);
            } else if (rep[k] == '&') {
              b.write(m[0]);
            } else {
              b.write(rep[k]);
            }
          }
          last = m.end;
          count++;
        }
        if (count > 0) {
          b.write(cur.substring(last));
          _set(target, b.toString());
        }
        return count.toDouble();
      case 'match':
        final m = _re(a[1]).firstMatch(s(0));
        vars['RSTART'] = m == null ? 0.0 : (m.start + 1).toDouble();
        vars['RLENGTH'] = m == null ? -1.0 : (m.end - m.start).toDouble();
        return vars['RSTART']!;
      case 'toupper':
        return s(0).toUpperCase();
      case 'tolower':
        return s(0).toLowerCase();
      case 'int':
        return n(0).truncateToDouble();
      case 'sqrt':
        return math.sqrt(n(0));
      case 'exp':
        return math.exp(n(0));
      case 'log':
        return math.log(n(0));
      case 'sin':
        return math.sin(n(0));
      case 'cos':
        return math.cos(n(0));
      case 'atan2':
        return math.atan2(n(0), n(1));
      case 'rand':
        return _rand.nextDouble();
      case 'srand':
        return 0.0;
      case 'sprintf':
        return _sprintf(a);
      case 'system':
        final (o, e, st) = sh.capture(s(0), c: ctx);
        out.write(o);
        out.write(e);
        return st.toDouble();
    }
    throw ShError('awk: calling undefined function $name', 2);
  }

  String _sprintf(List<_E> a) {
    if (a.isEmpty) return '';
    final fmt = _str(_eval(a[0]));
    final vals = [for (final x in a.skip(1)) _eval(x)];
    final b = StringBuffer();
    final spec = RegExp(r'%([-+ 0#]*)(\d+|\*)?(?:\.(\d+|\*))?([sdifgeExXoc%])');
    var last = 0, ai = 0;
    for (final m in spec.allMatches(fmt)) {
      b.write(fmt.substring(last, m.start));
      last = m.end;
      if (m[4] == '%') {
        b.write('%');
        continue;
      }
      var w = m[2];
      if (w == '*') w = _str(ai < vals.length ? vals[ai++] : 0.0);
      var pr = m[3];
      if (pr == '*') pr = _str(ai < vals.length ? vals[ai++] : 0.0);
      final v = ai < vals.length ? vals[ai++] : '';
      final conv = m[4]!;
      String arg;
      if (conv == 'c') {
        arg = v is double ? String.fromCharCode(v.toInt()) : (_str(v).isEmpty ? '' : _str(v)[0]);
        b.write(formatOne(m[1]!, w == null ? null : int.tryParse(w), null, 's', arg));
        continue;
      }
      arg = 'sdi'.contains(conv) && conv != 's' ? '${_num(v).truncate()}' : (conv == 's' ? _str(v) : '${_num(v)}');
      b.write(formatOne(m[1]!, w == null ? null : int.tryParse(w), pr == null ? null : int.tryParse(pr), conv, arg));
    }
    b.write(fmt.substring(last));
    return b.toString();
  }

  void _print(List<Object> vals, String? redir, String? target) {
    final text = vals.map(_str).join(_str(vars['OFS']!)) + _str(vars['ORS']!);
    _emit(text, redir, target);
  }

  void _emit(String text, String? redir, String? target) {
    if (redir == null) {
      out.write(text);
      return;
    }
    if (redir == '|') {
      final (o, e, _) = sh.capture(target!, c: ctx, stdin: text);
      out.write(o);
      out.write(e);
      return;
    }
    final buf = files.putIfAbsent(target!, () {
      final b = StringBuffer();
      if (redir == '>>') {
        try {
          b.write(sh.fs.read(target, ctx.cwd));
        } on ShError {
          // a new file
        }
      }
      return b;
    });
    buf.write(text);
  }

  void _run(_S s) {
    _step();
    switch (s) {
      case _Block(:final body):
        for (final x in body) {
          _run(x);
        }
      case _Expr(:final e):
        _eval(e);
      case _Print(:final args, :final f, :final redir, :final target):
        final t = target == null ? null : _str(_eval(target));
        if (f) {
          _emit(_sprintf(args), redir, t);
        } else {
          _print(args.isEmpty ? [_record()] : [for (final x in args) _eval(x)], redir, t);
        }
      case _If(:final c, :final a, :final b):
        if (_truthy(_eval(c))) {
          _run(a);
        } else if (b != null) {
          _run(b);
        }
      case _While(:final c, :final body, :final doWhile):
        if (doWhile) {
          do {
            try {
              _run(body);
            } on _ABreak {
              break;
            } on _AContinue {
              // next round
            }
            _step();
          } while (_truthy(_eval(c)));
        } else {
          while (_truthy(_eval(c))) {
            _step();
            try {
              _run(body);
            } on _ABreak {
              break;
            } on _AContinue {
              continue;
            }
          }
        }
      case _For(:final init, :final c, :final step, :final body):
        if (init != null) _run(init);
        while (c == null || _truthy(_eval(c))) {
          _step();
          try {
            _run(body);
          } on _ABreak {
            break;
          } on _AContinue {
            // to the step
          }
          if (step != null) _run(step);
        }
      case _ForIn(:final v, :final arr, :final body):
        final keys = (arrays[arr] ?? const {}).keys.toList();
        for (final k in keys) {
          vars[v] = k;
          try {
            _run(body);
          } on _ABreak {
            break;
          } on _AContinue {
            continue;
          }
        }
      case _Simple(:final kind, :final arg):
        switch (kind) {
          case 'next':
            throw _Next();
          case 'exit':
            throw _AwkExit(arg == null ? 0 : _num(_eval(arg)).toInt());
          case 'break':
            throw _ABreak();
          default:
            throw _AContinue();
        }
      case _Delete(:final arr, :final keys):
        if (keys == null) {
          arrays.remove(arr);
        } else {
          arrays[arr]?.remove(_key(keys));
        }
    }
  }
}

/// Used by Vfs-free callers that only want the awk language checked.
bool awkParses(String prog) {
  try {
    _P(_lex(prog)).program();
    return true;
  } on ShError {
    return false;
  }
}
