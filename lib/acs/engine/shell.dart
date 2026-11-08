// =============================================================================
// THE USO SHELL: bash, run on a file system in memory
//   [Shell.run] takes what the student typed (or a script) and gives back
//   what went on the screen. Expansions, pipes, redirections, scripts with
//   arguments, functions; the commands themselves are in shell_cmds.dart.
// =============================================================================

import 'dart:math' as math;

import 'shell_cmds.dart';
import 'shell_parse.dart';
import 'vfs.dart';

/// Where a command writes.
abstract class Sink {
  void write(String s);
  bool get tty => false;
}

class BufSink extends Sink {
  final StringBuffer b = StringBuffer();
  @override
  void write(String s) => b.write(s);
  @override
  String toString() => b.toString();
}

class NullSink extends Sink {
  @override
  void write(String s) {}
}

/// The screen: what is written, in order, stdout and stderr apart.
class ScreenSink extends Sink {
  final List<(String, bool)> chunks;
  final bool err;
  final bool _tty;
  ScreenSink(this.chunks, this.err, {bool tty = true}) : _tty = tty;
  @override
  void write(String s) {
    if (s.isEmpty) return;
    if (chunks.isNotEmpty && chunks.last.$2 == err) {
      chunks[chunks.length - 1] = (chunks.last.$1 + s, err);
    } else {
      chunks.add((s, err));
    }
  }

  @override
  bool get tty => _tty;
}

/// What a command reads.
class ShIn {
  final String data;
  int pos = 0;
  ShIn(this.data);
  static final ShIn empty = ShIn('');

  String? readLine() {
    if (pos >= data.length) return null;
    final nl = data.indexOf('\n', pos);
    final line = nl < 0 ? data.substring(pos) : data.substring(pos, nl);
    pos = nl < 0 ? data.length : nl + 1;
    return line;
  }

  String readAll() {
    final r = data.substring(math.min(pos, data.length));
    pos = data.length;
    return r;
  }
}

class _Break implements Exception {
  final int n;
  _Break(this.n);
}

class _Continue implements Exception {
  final int n;
  _Continue(this.n);
}

class ShReturn implements Exception {
  final int status;
  ShReturn(this.status);
}

class ShExit implements Exception {
  final int status;
  ShExit(this.status);
}

/// The state a command runs in. A subshell (a pipe, `$(...)`, `( )`) gets a copy.
class ShCtx {
  final Map<String, String> vars;
  final Set<String> exported;
  List<String> args; // $1...
  String name; // $0
  String cwd;
  final Map<String, Node> funcs;
  List<Map<String, String?>> locals = [];
  ShCtx(this.vars, this.exported, this.args, this.name, this.cwd, this.funcs);

  ShCtx copy() => ShCtx(Map.of(vars), Set.of(exported), List.of(args), name, cwd, Map.of(funcs))..locals = [for (final l in locals) Map.of(l)];
}

class Shell {
  final Vfs fs;
  late ShCtx ctx;
  int status = 0;
  int _steps = 0;
  static const int maxSteps = 200000;
  final List<String> history = [];
  int _depth = 0;

  /// Commands that leave the shell to the page: `nano file` opens the editor.
  void Function(String path)? onEdit;
  void Function()? onClear;

  Shell(this.fs, {String? cwd}) {
    ctx = ShCtx(
      {'HOME': Vfs.home, 'USER': Vfs.user, 'LOGNAME': Vfs.user, 'SHELL': '/bin/bash', 'PATH': '/usr/local/bin:/usr/bin:/bin', 'IFS': ' \t\n', 'PS1': '\\u@\\h:\\w\\\$ '},
      {'HOME', 'USER', 'PATH', 'SHELL', 'LOGNAME'},
      [],
      'bash',
      cwd ?? Vfs.home,
      {},
    );
    ctx.vars['PWD'] = ctx.cwd;
  }

  String get cwd => ctx.cwd;

  /// The prompt's directory: ~/proiect.
  String get shortCwd {
    final c = ctx.cwd;
    if (c == Vfs.home) return '~';
    if (c.startsWith('${Vfs.home}/')) return '~${c.substring(Vfs.home.length)}';
    return c;
  }

  /// Runs what was typed; what went on the screen, in order (text, isError).
  List<(String, bool)> run(String src, {String stdin = '', bool tty = true}) {
    final chunks = <(String, bool)>[];
    final out = ScreenSink(chunks, false, tty: tty), err = ScreenSink(chunks, true, tty: tty);
    if (src.trim().isNotEmpty) history.add(src.trimRight());
    _steps = 0;
    try {
      final node = Parser.parse(src);
      status = exec(node, ctx, ShIn(stdin), out, err);
    } on ShIncomplete {
      err.write('bash: syntax error: unexpected end of file\n');
      status = 2;
    } on ShError catch (e) {
      err.write('bash: ${e.message}\n');
      status = e.status;
    } on ShExit catch (e) {
      status = e.status;
    } on ShReturn catch (e) {
      status = e.status;
    } on _Break {
      status = 0;
    } on _Continue {
      status = 0;
    } on StackOverflowError {
      err.write('bash: maximum recursion depth exceeded\n');
      status = 1;
    }
    return chunks;
  }

  /// Is [src] a whole command, or does it need another line?
  static bool complete(String src) {
    try {
      Parser.parse(src);
      return true;
    } on ShIncomplete {
      return false;
    } catch (_) {
      return true;
    }
  }

  /// Runs a command's text in [c], output in strings (for tests and `$(...)`).
  (String, String, int) capture(String src, {ShCtx? c, String stdin = ''}) {
    final o = BufSink(), e = BufSink();
    var st = 0;
    try {
      st = exec(Parser.parse(src), c ?? ctx, ShIn(stdin), o, e);
    } on ShError catch (x) {
      e.write('bash: ${x.message}\n');
      st = x.status;
    } on ShExit catch (x) {
      st = x.status;
    } on ShIncomplete {
      e.write('bash: syntax error: unexpected end of file\n');
      st = 2;
    }
    return (o.toString(), e.toString(), st);
  }

  void _step() {
    if (++_steps > maxSteps) throw ShError('execuția a durat prea mult (o buclă infinită?)', 124);
  }

  // ---------------------------------------------------------------- execution
  int exec(Node n, ShCtx c, ShIn inp, Sink out, Sink err) {
    switch (n) {
      case NSimple():
        return _simple(n, c, inp, out, err);
      case NList():
        var st = 0;
        for (final item in n.items) {
          st = exec(item, c, inp, out, err);
          status = st;
        }
        return st;
      case NAndOr():
        var st = exec(n.first, c, inp, out, err);
        for (final (op, cmd) in n.rest) {
          status = st;
          if (op == '&&' && st == 0 || op == '||' && st != 0) st = exec(cmd, c, inp, out, err);
        }
        return st;
      case NPipe():
        var data = inp;
        var st = 0;
        for (var i = 0; i < n.cmds.length; i++) {
          final last = i == n.cmds.length - 1;
          final o = last ? out : BufSink();
          final cc = n.cmds.length > 1 ? c.copy() : c;
          try {
            st = exec(n.cmds[i], cc, data, o, err);
          } on ShExit catch (e) {
            if (n.cmds.length == 1) rethrow;
            st = e.status;
          }
          if (!last) data = ShIn(o.toString());
        }
        return n.bang ? (st == 0 ? 1 : 0) : st;
      case NIf():
        for (final (cond, body) in n.branches) {
          if (exec(cond, c, inp, out, err) == 0) return exec(body, c, inp, out, err);
        }
        return n.orElse == null ? 0 : exec(n.orElse!, c, inp, out, err);
      case NFor():
        final items = n.items == null ? List.of(c.args) : expandWords(n.items!, c, err);
        var st = 0;
        for (final it in items) {
          _step();
          _setVar(c, n.name, it);
          try {
            st = exec(n.body, c, inp, out, err);
          } on _Break catch (b) {
            if (b.n > 1) throw _Break(b.n - 1);
            break;
          } on _Continue catch (b) {
            if (b.n > 1) throw _Continue(b.n - 1);
          }
        }
        return st;
      case NWhile():
        var st = 0;
        while (true) {
          _step();
          final cst = exec(n.cond, c, inp, out, err);
          if ((cst == 0) == n.until) break;
          try {
            st = exec(n.body, c, inp, out, err);
          } on _Break catch (b) {
            if (b.n > 1) throw _Break(b.n - 1);
            break;
          } on _Continue catch (b) {
            if (b.n > 1) throw _Continue(b.n - 1);
          }
        }
        return st;
      case NCase():
        final subject = expandOne(n.subject, c, err);
        for (final (pats, body) in n.arms) {
          for (final p in pats) {
            if (globRegex(expandPattern(p, c, err)).hasMatch(subject)) return exec(body, c, inp, out, err);
          }
        }
        return 0;
      case NGroup():
        if (!n.subshell) return exec(n.body, c, inp, out, err);
        final cc = c.copy();
        try {
          return exec(n.body, cc, inp, out, err);
        } on ShExit catch (e) {
          return e.status;
        }
      case NFunc():
        c.funcs[n.name] = n.body;
        return 0;
      case NRedirected():
        return _withRedirs(n.redirs, c, inp, out, err, (i, o, e) => exec(n.inner, c, i, o, e));
    }
  }

  int _simple(NSimple n, ShCtx c, ShIn inp, Sink out, Sink err) {
    _step();
    final words = expandWords(n.words, c, err);
    if (words.isEmpty) {
      for (final (name, w) in n.assigns) {
        _setVar(c, name, expandOne(w, c, err));
      }
      if (n.redirs.isEmpty) return status == 0 ? 0 : status; // a=$(false) keeps its status
      return _withRedirs(n.redirs, c, inp, out, err, (i, o, e) => 0);
    }
    final env = <String, String>{for (final (name, w) in n.assigns) name: expandOne(w, c, err)};
    return _withRedirs(n.redirs, c, inp, out, err, (i, o, e) {
      final saved = <String, String?>{};
      for (final kv in env.entries) {
        saved[kv.key] = c.vars[kv.key];
        c.vars[kv.key] = kv.value;
      }
      try {
        return runCommand(words, c, i, o, e);
      } finally {
        for (final kv in saved.entries) {
          if (kv.value == null) {
            c.vars.remove(kv.key);
          } else {
            c.vars[kv.key] = kv.value!;
          }
        }
      }
    });
  }

  /// Runs `name args...`: a function, a builtin, a command, or a script.
  int runCommand(List<String> words, ShCtx c, ShIn inp, Sink out, Sink err) {
    final name = words[0];
    final args = words.sublist(1);
    final f = c.funcs[name];
    if (f != null) {
      final savedArgs = c.args;
      c.args = args;
      c.locals.add({});
      _depth++;
      if (_depth > 200) {
        _depth = 0;
        throw ShError('maximum function nesting level exceeded');
      }
      try {
        return exec(f, c, inp, out, err);
      } on ShReturn catch (r) {
        return r.status;
      } finally {
        _depth--;
        final l = c.locals.removeLast();
        for (final kv in l.entries) {
          if (kv.value == null) {
            c.vars.remove(kv.key);
          } else {
            c.vars[kv.key] = kv.value!;
          }
        }
        c.args = savedArgs;
      }
    }
    switch (name) {
      case 'break':
      case 'continue':
        final k = args.isEmpty ? 1 : int.tryParse(args[0]) ?? 1;
        if (name == 'break') throw _Break(k);
        throw _Continue(k);
      case 'return':
        throw ShReturn(args.isEmpty ? status : int.tryParse(args[0]) ?? 2);
      case 'exit':
        throw ShExit(args.isEmpty ? status : (int.tryParse(args[0]) ?? 2) & 255);
      case 'local':
        for (final a in args) {
          final eq = a.indexOf('=');
          final k = eq < 0 ? a : a.substring(0, eq);
          if (c.locals.isNotEmpty && !c.locals.last.containsKey(k)) c.locals.last[k] = c.vars[k];
          if (eq >= 0) c.vars[k] = a.substring(eq + 1);
        }
        return 0;
      case 'source':
      case '.':
        if (args.isEmpty) throw ShError('$name: filename argument required', 2);
        final text = fs.read(args[0], c.cwd);
        final savedArgs = c.args;
        if (args.length > 1) c.args = args.sublist(1);
        try {
          return exec(Parser.parse(text), c, inp, out, err);
        } on ShReturn catch (r) {
          return r.status;
        } finally {
          c.args = savedArgs;
        }
      case 'bash':
      case 'sh':
        if (args.isEmpty) {
          err.write('$name: (un shell nou nu e disponibil aici; rulează comenzile direct)\n');
          return 1;
        }
        if (args[0] == '-c') return _script(args.length > 1 ? args[1] : '', args.length > 2 ? args[2] : name, args.length > 3 ? args.sublist(3) : [], c, inp, out, err);
        final String text;
        try {
          text = fs.read(args[0], c.cwd);
        } on ShError catch (e) {
          err.write('$name: ${e.message}\n');
          return 127;
        }
        return _script(text, args[0], args.sublist(1), c, inp, out, err);
    }
    try {
      final b = ShellCommands.builtin(name);
      if (b != null) return b(this, c, args, inp, out, err);
      if (name.contains('/')) return _execFile(name, args, c, inp, out, err);
      if (const {'nano', 'vim', 'vi', 'edit', 'gedit', 'code', 'mcedit'}.contains(name)) {
        if (args.isEmpty) {
          err.write('$name: dă numele fișierului: $name fisier.txt\n');
          return 1;
        }
        if (onEdit == null) {
          err.write('$name: editorul nu e disponibil aici\n');
          return 1;
        }
        onEdit!(Vfs.absolute(args.last, c.cwd));
        return 0;
      }
      // a script in a PATH directory (~/bin)
      for (final dir in (c.vars['PATH'] ?? '').split(':')) {
        if (dir.isEmpty) continue;
        final n = fs.lookup('$dir/$name', '/');
        if (n != null && n.isFile && fs.lookup(dir, '/')?.owner == Vfs.user) return _execFile('$dir/$name', args, c, inp, out, err);
      }
      err.write('$name: command not found\n');
      return 127;
    } on ShError catch (e) {
      err.write('$name: ${e.message}\n');
      return e.status;
    }
  }

  int _execFile(String path, List<String> args, ShCtx c, ShIn inp, Sink out, Sink err) {
    final n = fs.lookup(path, c.cwd);
    if (n == null) throw ShError('No such file or directory', 127);
    if (n.isDir) throw ShError('Is a directory', 126);
    if (!Vfs.may(n, 'x')) throw ShError('Permission denied', 126);
    if (!Vfs.may(n, 'r')) throw ShError('Permission denied', 126);
    return _script(n.data, path, args, c, inp, out, err);
  }

  int _script(String text, String name, List<String> args, ShCtx c, ShIn inp, Sink out, Sink err) {
    final cc = c.copy()
      ..args = args
      ..name = name
      ..locals = [];
    // a script sees only what was exported
    cc.vars.removeWhere((k, _) => !c.exported.contains(k) && !const {'IFS', 'PWD', 'PS1'}.contains(k));
    cc.funcs.clear();
    _depth++;
    if (_depth > 50) {
      _depth = 0;
      throw ShError('too many nested scripts');
    }
    try {
      final node = Parser.parse(text);
      return exec(node, cc, inp, out, err);
    } on ShExit catch (e) {
      return e.status;
    } on ShReturn catch (e) {
      return e.status;
    } on ShIncomplete {
      err.write('$name: syntax error: unexpected end of file\n');
      return 2;
    } on ShError catch (e) {
      err.write('$name: ${e.message}\n');
      return e.status;
    } finally {
      _depth--;
    }
  }

  int _withRedirs(List<Redir> redirs, ShCtx c, ShIn inp, Sink out, Sink err, int Function(ShIn, Sink, Sink) body) {
    if (redirs.isEmpty) return body(inp, out, err);
    var i = inp;
    Sink o = out, e = err;
    final files = <(String, BufSink, bool)>[]; // path, buffer, append
    try {
      for (final r in redirs) {
        switch (r.op) {
          case '<':
            final path = expandOne(r.target!, c, err);
            i = ShIn(path == '/dev/null' ? '' : fs.read(path, c.cwd));
          case '<<':
            final body = r.heredoc ?? '';
            i = ShIn(r.heredocExpands ? expandHeredoc(body, c, err) : body);
          case '<<<':
            i = ShIn('${expandOne(r.target!, c, err)}\n');
          case '>&':
            final to = r.dupTo == 2 ? e : r.dupTo == 1 ? o : null;
            if (to == null) throw ShError('${r.dupTo}: Bad file descriptor');
            if (r.fd == 1) o = to;
            if (r.fd == 2) e = to;
          case '>':
          case '>>':
            final path = expandOne(r.target!, c, err);
            Sink s;
            if (path == '/dev/null') {
              s = NullSink();
            } else {
              final buf = BufSink();
              final abs = Vfs.absolute(path, c.cwd);
              final existing = fs.lookup(abs, '/');
              if (existing != null && existing.isDir) throw ShError('$path: Is a directory');
              if (r.op == '>') fs.write(abs, '/', ''); // truncated as it opens
              if (r.op == '>>' && existing == null) fs.write(abs, '/', '');
              files.add((abs, buf, true));
              s = buf;
            }
            if (r.fd == 1 || r.fd == -1) o = s;
            if (r.fd == 2 || r.fd == -1) e = s;
        }
      }
    } on ShError catch (x) {
      err.write('bash: ${x.message}\n');
      return 1;
    }
    try {
      return body(i, o, e);
    } finally {
      for (final (path, buf, _) in files) {
        try {
          fs.write(path, '/', buf.toString(), append: true);
        } on ShError catch (x) {
          err.write('bash: ${x.message}\n');
        }
      }
    }
  }

  // ---------------------------------------------------------------- variables
  void _setVar(ShCtx c, String name, String value) {
    c.vars[name] = value;
  }

  String? getVar(ShCtx c, String name) {
    switch (name) {
      case '?':
        return '$status';
      case '#':
        return '${c.args.length}';
      case '@':
      case '*':
        return c.args.join(' ');
      case '\$':
        return '4242';
      case '0':
        return c.name;
      case '!':
        return '';
      case 'RANDOM':
        return '${math.Random().nextInt(32768)}';
      case 'PWD':
        return c.cwd;
    }
    final k = int.tryParse(name);
    if (k != null) return k >= 1 && k <= c.args.length ? c.args[k - 1] : '';
    return c.vars[name];
  }

  // ---------------------------------------------------------------- expansion
  /// The words, expanded: braces, ~, variables, $(...), splitting, globs.
  List<String> expandWords(List<Word> words, ShCtx c, Sink err) {
    final out = <String>[];
    for (final w in words) {
      for (final b in braceExpand(w)) {
        out.addAll(_expandWord(b, c, err));
      }
    }
    return out;
  }

  /// One word, expanded without splitting or globs (an assignment's value, a redirection's file).
  String expandOne(Word w, ShCtx c, Sink err) {
    final b = StringBuffer();
    for (final (i, p) in w.parts.indexed) {
      if (p.kind == PartKind.lit) {
        b.write(i == 0 && p.quote == 0 ? _tilde(p.text, c) : p.text);
      } else {
        b.write(_expandPart(p, c, err));
      }
    }
    return b.toString();
  }

  /// A case pattern: quoted parts match literally.
  String expandPattern(Word w, ShCtx c, Sink err) {
    final b = StringBuffer();
    for (final p in w.parts) {
      final s = p.kind == PartKind.lit ? p.text : _expandPart(p, c, err);
      b.write(p.quote == 0 ? s : s.replaceAllMapped(RegExp(r'[*?\[\]\\]'), (m) => '\\${m[0]}'));
    }
    return b.toString();
  }

  String _tilde(String s, ShCtx c) {
    if (s == '~') return c.vars['HOME'] ?? Vfs.home;
    if (s.startsWith('~/')) return '${c.vars['HOME'] ?? Vfs.home}${s.substring(1)}';
    return s;
  }

  List<String> _expandWord(Word w, ShCtx c, Sink err) {
    // fields being built: each a list of (text, globbable)
    final fields = <List<(String, bool)>>[[]];
    var anyQuoted = false;
    final ifs = c.vars['IFS'] ?? ' \t\n';
    for (final (idx, p) in w.parts.indexed) {
      if (p.quote != 0) anyQuoted = true;
      if (p.kind == PartKind.lit) {
        final t = idx == 0 && p.quote == 0 ? _tilde(p.text, c) : p.text;
        fields.last.add((t, p.quote == 0));
        continue;
      }
      if (p.kind == PartKind.varRef && (p.text == '@' || p.text == '*') && p.quote == 2) {
        if (p.text == '*') {
          fields.last.add((c.args.join(' '), false));
          continue;
        }
        for (final (k, a) in c.args.indexed) {
          if (k > 0) fields.add([]);
          fields.last.add((a, false));
        }
        if (c.args.isEmpty && w.parts.length == 1) return [];
        continue;
      }
      final v = _expandPart(p, c, err);
      if (p.quote != 0) {
        fields.last.add((v, false));
        continue;
      }
      // unquoted: split on IFS whitespace
      final pieces = ifs.isEmpty ? [v] : v.split(RegExp('[${RegExp.escape(ifs)}]+'));
      final leading = v.isNotEmpty && ifs.contains(v[0]);
      final trailing = v.isNotEmpty && ifs.contains(v[v.length - 1]);
      final nonEmpty = pieces.where((s) => s.isNotEmpty).toList();
      if (nonEmpty.isEmpty) {
        if (v.isNotEmpty && fields.last.isNotEmpty) fields.add([]);
        continue;
      }
      if (leading && fields.last.isNotEmpty) fields.add([]);
      for (final (k, s) in nonEmpty.indexed) {
        if (k > 0) fields.add([]);
        fields.last.add((s, true));
      }
      if (trailing) fields.add([]);
    }
    final out = <String>[];
    for (final f in fields) {
      if (f.isEmpty) continue;
      final text = f.map((x) => x.$1).join();
      final globby = f.any((x) => x.$2 && RegExp(r'[*?\[]').hasMatch(x.$1));
      if (globby) {
        final pattern = f.map((x) => x.$2 ? x.$1 : x.$1.replaceAllMapped(RegExp(r'[*?\[\]\\]'), (m) => '\\${m[0]}')).join();
        final matches = glob(pattern, c.cwd);
        if (matches.isNotEmpty) {
          out.addAll(matches);
          continue;
        }
        out.add(text);
        continue;
      }
      out.add(text);
    }
    if (out.isEmpty && anyQuoted && fields.length == 1) return [''];
    if (out.isEmpty && anyQuoted && fields.every((f) => f.isEmpty)) return [''];
    return out;
  }

  String _expandPart(WPart p, ShCtx c, Sink err) {
    switch (p.kind) {
      case PartKind.lit:
        return p.text;
      case PartKind.varRef:
        return getVar(c, p.text) ?? '';
      case PartKind.param:
        return _param(p.text, c, err);
      case PartKind.cmd:
        final cc = c.copy();
        final o = BufSink();
        try {
          status = exec(Parser.parse(p.text), cc, ShIn.empty, o, err);
        } on ShExit catch (e) {
          status = e.status;
        } on ShIncomplete {
          throw ShError('syntax error in command substitution', 2);
        }
        return o.toString().replaceFirst(RegExp(r'\n+$'), '');
      case PartKind.arith:
        return '${arith(expandHeredoc(p.text, c, err), c)}';
    }
  }

  String _param(String raw, ShCtx c, Sink err) {
    if (raw.startsWith('#') && raw.length > 1) {
      final name = raw.substring(1);
      if (name == '@' || name == '*') return '${c.args.length}';
      return '${(getVar(c, name) ?? '').length}';
    }
    final m = RegExp(r'^([A-Za-z_][A-Za-z0-9_]*|[0-9]+|[?#@*$!])').firstMatch(raw);
    if (m == null) throw ShError('\${$raw}: bad substitution');
    final name = m.group(1)!;
    final rest = raw.substring(m.end);
    final v = getVar(c, name);
    String word(String s) => expandHeredoc(s, c, err);
    if (rest.isEmpty) return v ?? '';
    if (rest.startsWith(':-')) return (v == null || v.isEmpty) ? word(rest.substring(2)) : v;
    if (rest.startsWith('-')) return v ?? word(rest.substring(1));
    if (rest.startsWith(':=')) {
      if (v == null || v.isEmpty) {
        final d = word(rest.substring(2));
        c.vars[name] = d;
        return d;
      }
      return v;
    }
    if (rest.startsWith(':+')) return (v == null || v.isEmpty) ? '' : word(rest.substring(2));
    if (rest.startsWith(':?')) {
      if (v == null || v.isEmpty) throw ShError('$name: ${rest.length > 2 ? word(rest.substring(2)) : 'parameter null or not set'}');
      return v;
    }
    final s = v ?? '';
    if (rest.startsWith('%%') || rest.startsWith('%') || rest.startsWith('##') || rest.startsWith('#')) {
      final greedy = rest.startsWith('%%') || rest.startsWith('##');
      final suffix = rest.startsWith('%');
      final re = globRegex(word(rest.substring(greedy ? 2 : 1)), anchored: false);
      if (suffix) {
        final starts = greedy ? List.generate(s.length + 1, (i) => i) : List.generate(s.length + 1, (i) => s.length - i);
        for (final i in starts) {
          if (_fullMatch(re, s.substring(i))) return s.substring(0, i);
        }
      } else {
        final ends = greedy ? List.generate(s.length + 1, (i) => s.length - i) : List.generate(s.length + 1, (i) => i);
        for (final i in ends) {
          if (_fullMatch(re, s.substring(0, i))) return s.substring(i);
        }
      }
      return s;
    }
    if (rest.startsWith('/')) {
      final all = rest.startsWith('//');
      final body = rest.substring(all ? 2 : 1);
      final slash = body.indexOf('/');
      final pat = word(slash < 0 ? body : body.substring(0, slash));
      final rep = slash < 0 ? '' : word(body.substring(slash + 1));
      final re = RegExp(globRegex(pat, anchored: false).pattern);
      return all ? s.replaceAll(re, rep) : s.replaceFirst(re, rep);
    }
    if (rest.startsWith(':')) {
      final parts = rest.substring(1).split(':');
      var off = arith(parts[0], c);
      if (off < 0) off = math.max(0, s.length + off);
      if (off > s.length) return '';
      if (parts.length < 2) return s.substring(off);
      final len = arith(parts[1], c);
      return s.substring(off, len < 0 ? math.max(off, s.length + len) : math.min(s.length, off + len));
    }
    if (rest == '^^') return s.toUpperCase();
    if (rest == ',,') return s.toLowerCase();
    if (rest == '^') return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
    throw ShError('\${$raw}: bad substitution');
  }

  static bool _fullMatch(RegExp re, String s) {
    final m = RegExp('^(?:${re.pattern})\$', dotAll: true).firstMatch(s);
    return m != null;
  }

  /// $VAR, ${...}, $(...) and $((...)) in a heredoc's text (or an arithmetic's).
  String expandHeredoc(String text, ShCtx c, Sink err) {
    if (!text.contains('\$') && !text.contains('`')) return text;
    final b = StringBuffer();
    var i = 0;
    while (i < text.length) {
      final ch = text[i];
      if (ch == '\\' && i + 1 < text.length && '\$`\\'.contains(text[i + 1])) {
        b.write(text[i + 1]);
        i += 2;
        continue;
      }
      if (ch == '\$' || ch == '`') {
        try {
          final r = Lexer.dollarAt(text, i);
          if (r != null) {
            b.write(_expandPart(r.$1, c, err));
            i = r.$2;
            continue;
          }
        } on ShIncomplete {
          // an unclosed form stays as text
        }
      }
      b.write(ch);
      i++;
    }
    return b.toString();
  }

  // ---------------------------------------------------------------- braces and globs
  /// a{b,c}d -> abd acd; {1..5} -> 1 2 3 4 5 (only in unquoted text).
  static List<Word> braceExpand(Word w) {
    // join the word into a template; anything but unquoted text is a placeholder
    final ph = <WPart>[];
    final t = StringBuffer();
    for (final p in w.parts) {
      if (p.kind == PartKind.lit && p.quote == 0) {
        t.write(p.text);
      } else {
        t.write('\u0000${ph.length}\u0000');
        ph.add(p);
      }
    }
    final tmpl = t.toString();
    if (!tmpl.contains('{')) return [w];
    final outs = _braces(tmpl);
    if (outs.length == 1 && outs[0] == tmpl) return [w];
    return [
      for (final o in outs)
        Word([
          for (final (i, seg) in o.split('\u0000').indexed)
            if (i.isOdd) ph[int.parse(seg)] else if (seg.isNotEmpty) WPart(PartKind.lit, seg, 0),
        ]),
    ];
  }

  static List<String> _braces(String s) {
    // the first {...} at depth 0 with a comma or ..
    for (var i = 0; i < s.length; i++) {
      if (s[i] != '{') continue;
      var depth = 0;
      for (var j = i; j < s.length; j++) {
        if (s[j] == '{') depth++;
        if (s[j] == '}') {
          depth--;
          if (depth == 0) {
            final inner = s.substring(i + 1, j);
            final pre = s.substring(0, i), post = s.substring(j + 1);
            List<String>? alts;
            final range = RegExp(r'^(-?\d+)\.\.(-?\d+)(?:\.\.(-?\d+))?$').firstMatch(inner);
            final letters = RegExp(r'^([a-zA-Z])\.\.([a-zA-Z])$').firstMatch(inner);
            if (range != null) {
              final a = int.parse(range[1]!), b = int.parse(range[2]!);
              var step = range[3] == null ? 1 : int.parse(range[3]!).abs();
              if (step == 0) step = 1;
              final width = (range[1]!.startsWith('0') && range[1]!.length > 1) || (range[2]!.startsWith('0') && range[2]!.length > 1)
                  ? math.max(range[1]!.length, range[2]!.length)
                  : 0;
              alts = [for (var k = a; a <= b ? k <= b : k >= b; k += a <= b ? step : -step) '$k'.padLeft(width, '0')];
            } else if (letters != null) {
              final a = letters[1]!.codeUnitAt(0), b = letters[2]!.codeUnitAt(0);
              alts = [for (var k = a; a <= b ? k <= b : k >= b; k += a <= b ? 1 : -1) String.fromCharCode(k)];
            } else {
              final parts = <String>[];
              var d = 0, start = 0;
              for (var k = 0; k < inner.length; k++) {
                if (inner[k] == '{') d++;
                if (inner[k] == '}') d--;
                if (inner[k] == ',' && d == 0) {
                  parts.add(inner.substring(start, k));
                  start = k + 1;
                }
              }
              parts.add(inner.substring(start));
              if (parts.length > 1) alts = parts;
            }
            if (alts == null) {
              // not a brace expression: keep it and look further on
              final later = _braces(post);
              return [for (final l in later) '$pre{$inner}$l'];
            }
            return [
              for (final a in alts)
                for (final r in _braces('$a$post')) '$pre$r',
            ];
          }
        }
      }
      break;
    }
    return [s];
  }

  /// A glob as a regular expression (a backslash quotes the next character).
  static RegExp globRegex(String g, {bool anchored = true}) {
    final b = StringBuffer(anchored ? '^' : '');
    for (var i = 0; i < g.length; i++) {
      final c = g[i];
      if (c == '\\' && i + 1 < g.length) {
        b.write(RegExp.escape(g[++i]));
      } else if (c == '*') {
        b.write('.*');
      } else if (c == '?') {
        b.write('.');
      } else if (c == '[') {
        final j = i + 2 <= g.length ? g.indexOf(']', i + 2) : -1;
        if (j < 0) {
          b.write('\\[');
          continue;
        }
        var cls = g.substring(i + 1, j);
        if (cls.startsWith('!')) cls = '^${cls.substring(1)}';
        cls = cls
            .replaceAll('[:digit:]', r'0-9')
            .replaceAll('[:alpha:]', r'a-zA-Z')
            .replaceAll('[:upper:]', r'A-Z')
            .replaceAll('[:lower:]', r'a-z')
            .replaceAll('[:alnum:]', r'a-zA-Z0-9')
            .replaceAll('[:space:]', r'\s');
        b.write('[${cls.replaceAll('\\', '\\\\')}]');
        i = j;
      } else {
        b.write(RegExp.escape(c));
      }
    }
    if (anchored) b.write(r'$');
    return RegExp(b.toString(), dotAll: true);
  }

  /// The paths matching [pattern], sorted; relative patterns give relative paths.
  List<String> glob(String pattern, String cwd) {
    final abs = pattern.startsWith('/');
    final segs = pattern.split('/');
    var cur = <String>[abs ? '/' : ''];
    for (var k = 0; k < segs.length; k++) {
      final seg = segs[k];
      if (seg.isEmpty) continue;
      final next = <String>[];
      final magic = RegExp(r'(?<!\\)[*?\[]').hasMatch(seg);
      for (final base in cur) {
        final dirPath = base.isEmpty ? cwd : (base.startsWith('/') ? base : Vfs.absolute(base, cwd));
        String join(String n) => base.isEmpty ? n : (base.endsWith('/') ? '$base$n' : '$base/$n');
        if (!magic) {
          final lit = seg.replaceAll(RegExp(r'\\(.)'), r'$1');
          final unesc = seg.replaceAllMapped(RegExp(r'\\(.)'), (m) => m[1]!);
          if (fs.lookup(join(unesc), base.isEmpty || !base.startsWith('/') ? cwd : '/') != null) next.add(join(unesc));
          if (lit.isEmpty) continue;
          continue;
        }
        final dir = fs.lookup(dirPath, '/');
        if (dir == null || !dir.isDir || !Vfs.may(dir, 'r')) continue;
        final re = globRegex(seg);
        for (final name in dir.kids.keys) {
          if (name.startsWith('.') && !seg.startsWith('.')) continue;
          if (re.hasMatch(name)) next.add(join(name));
        }
      }
      cur = next;
      if (cur.isEmpty) return [];
    }
    if (pattern.endsWith('/')) cur = [for (final p in cur) if (fs.lookup(p, cwd)?.isDir ?? false) '$p/'];
    cur.sort();
    return cur;
  }

  // ---------------------------------------------------------------- arithmetic
  int arith(String src, ShCtx c) => _Arith(src, this, c).run();
}

/// $(( ... )): integers, C operators, variables by name.
class _Arith {
  final String s;
  final Shell sh;
  final ShCtx c;
  int i = 0;
  _Arith(this.s, this.sh, this.c);

  int run() {
    if (s.trim().isEmpty) return 0;
    final v = _comma();
    _ws();
    if (i < s.length) throw ShError('$s: syntax error in expression (error token is "${s.substring(i)}")');
    return v;
  }

  void _ws() {
    while (i < s.length && (s[i] == ' ' || s[i] == '\t' || s[i] == '\n')) {
      i++;
    }
  }

  bool _eat(String op) {
    _ws();
    if (s.startsWith(op, i)) {
      // don't take '=' from '==', '<' from '<=', etc.
      if ((op == '=' || op == '<' || op == '>' || op == '!') && i + 1 < s.length && s[i + 1] == '=') return false;
      if ((op == '&' && s.startsWith('&&', i)) || (op == '|' && s.startsWith('||', i))) return false;
      if ((op == '<' && s.startsWith('<<', i)) || (op == '>' && s.startsWith('>>', i))) return false;
      if (op == '*' && s.startsWith('**', i)) return false;
      i += op.length;
      return true;
    }
    return false;
  }

  int _comma() {
    var v = _assign();
    while (_eat(',')) {
      v = _assign();
    }
    return v;
  }

  int _assign() {
    _ws();
    final m = RegExp(r'([A-Za-z_][A-Za-z0-9_]*)\s*(\+=|-=|\*=|/=|%=|=)(?!=)').matchAsPrefix(s, i);
    if (m != null) {
      i = m.end;
      final name = m[1]!;
      final rhs = _assign();
      final cur = _var(name);
      final v = switch (m[2]) {
        '+=' => cur + rhs,
        '-=' => cur - rhs,
        '*=' => cur * rhs,
        '/=' => rhs == 0 ? throw ShError('division by 0') : cur ~/ rhs,
        '%=' => rhs == 0 ? throw ShError('division by 0') : cur.remainder(rhs),
        _ => rhs,
      };
      c.vars[name] = '$v';
      return v;
    }
    return _ternary();
  }

  int _ternary() {
    final cond = _or();
    if (_eat('?')) {
      final a = _assign();
      if (!_eat(':')) throw ShError('$s: expected `:\'');
      final b = _assign();
      return cond != 0 ? a : b;
    }
    return cond;
  }

  int _or() {
    var v = _and();
    while (_eat('||')) {
      final r = _and();
      v = (v != 0 || r != 0) ? 1 : 0;
    }
    return v;
  }

  int _and() {
    var v = _bor();
    while (_eat('&&')) {
      final r = _bor();
      v = (v != 0 && r != 0) ? 1 : 0;
    }
    return v;
  }

  int _bor() {
    var v = _bxor();
    while (_eat('|')) {
      v |= _bxor();
    }
    return v;
  }

  int _bxor() {
    var v = _band();
    while (_eat('^')) {
      v ^= _band();
    }
    return v;
  }

  int _band() {
    var v = _eq();
    while (_eat('&')) {
      v &= _eq();
    }
    return v;
  }

  int _eq() {
    var v = _rel();
    while (true) {
      if (_eat('==')) {
        v = v == _rel() ? 1 : 0;
      } else if (_eat('!=')) {
        v = v != _rel() ? 1 : 0;
      } else {
        return v;
      }
    }
  }

  int _rel() {
    var v = _shift();
    while (true) {
      if (_eat('<=')) {
        v = v <= _shift() ? 1 : 0;
      } else if (_eat('>=')) {
        v = v >= _shift() ? 1 : 0;
      } else if (_eat('<')) {
        v = v < _shift() ? 1 : 0;
      } else if (_eat('>')) {
        v = v > _shift() ? 1 : 0;
      } else {
        return v;
      }
    }
  }

  int _shift() {
    var v = _add();
    while (true) {
      if (_eat('<<')) {
        v <<= _add();
      } else if (_eat('>>')) {
        v >>= _add();
      } else {
        return v;
      }
    }
  }

  int _add() {
    var v = _mul();
    while (true) {
      _ws();
      if (s.startsWith('++', i) || s.startsWith('--', i)) return v;
      if (_eat('+')) {
        v += _mul();
      } else if (_eat('-')) {
        v -= _mul();
      } else {
        return v;
      }
    }
  }

  int _mul() {
    var v = _pow();
    while (true) {
      if (_eat('*')) {
        v *= _pow();
      } else if (_eat('/')) {
        final r = _pow();
        if (r == 0) throw ShError('division by 0 (error token is "${s.trim()}")');
        v = v ~/ r;
      } else if (_eat('%')) {
        final r = _pow();
        if (r == 0) throw ShError('division by 0 (error token is "${s.trim()}")');
        v = v.remainder(r);
      } else {
        return v;
      }
    }
  }

  int _pow() {
    final b = _unary();
    if (_eat('**')) {
      final e = _pow();
      var r = 1;
      for (var k = 0; k < e; k++) {
        r *= b;
      }
      return r;
    }
    return b;
  }

  int _unary() {
    _ws();
    if (s.startsWith('++', i) || s.startsWith('--', i)) {
      final inc = s[i] == '+';
      i += 2;
      _ws();
      final m = RegExp(r'[A-Za-z_][A-Za-z0-9_]*').matchAsPrefix(s, i);
      if (m == null) throw ShError('$s: syntax error');
      i = m.end;
      final v = _var(m[0]!) + (inc ? 1 : -1);
      c.vars[m[0]!] = '$v';
      return v;
    }
    if (_eat('-')) return -_unary();
    if (_eat('+')) return _unary();
    if (_eat('!')) return _unary() == 0 ? 1 : 0;
    if (_eat('~')) return ~_unary();
    return _primary();
  }

  int _primary() {
    _ws();
    if (_eat('(')) {
      final v = _comma();
      if (!_eat(')')) throw ShError('$s: missing `)\'');
      return v;
    }
    final num = RegExp(r'0[xX][0-9a-fA-F]+|[0-9]+#[0-9a-zA-Z]+|[0-9]+').matchAsPrefix(s, i);
    if (num != null) {
      i = num.end;
      final t = num[0]!;
      if (t.startsWith('0x') || t.startsWith('0X')) return int.parse(t.substring(2), radix: 16);
      if (t.contains('#')) {
        final h = t.indexOf('#');
        return int.parse(t.substring(h + 1), radix: int.parse(t.substring(0, h)));
      }
      if (t.length > 1 && t.startsWith('0')) return int.parse(t, radix: 8);
      return int.parse(t);
    }
    final m = RegExp(r'\$?([A-Za-z_][A-Za-z0-9_]*)').matchAsPrefix(s, i);
    if (m != null) {
      i = m.end;
      final name = m[1]!;
      _ws();
      if (s.startsWith('++', i) || s.startsWith('--', i)) {
        final inc = s[i] == '+';
        i += 2;
        final v = _var(name);
        c.vars[name] = '${v + (inc ? 1 : -1)}';
        return v;
      }
      return _var(name);
    }
    throw ShError('$s: syntax error: operand expected (error token is "${s.substring(i)}")');
  }

  int _var(String name) {
    final v = sh.getVar(c, name);
    if (v == null || v.trim().isEmpty) return 0;
    final n = int.tryParse(v.trim());
    if (n != null) return n;
    // a variable holding an expression
    if (RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(v.trim()) && v.trim() != name) return _var(v.trim());
    throw ShError('$v: syntax error: operand expected');
  }
}
