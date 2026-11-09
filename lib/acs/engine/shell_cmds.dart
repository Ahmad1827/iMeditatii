// =============================================================================
// THE USO SHELL'S COMMANDS
//   The builtins (cd, echo, read, test...) and the usual tools (ls, cat, grep,
//   sed, sort, uniq, cut, tr, find, chmod...), as GNU coreutils print them in
//   the C locale. awk is in shell_awk.dart.
// =============================================================================

import 'dart:math' as math;

import 'shell.dart';
import 'shell_awk.dart';
import 'vfs.dart';

typedef ShCmd = int Function(Shell sh, ShCtx c, List<String> args, ShIn inp, Sink out, Sink err);

/// Short options: `-la`, `-n 5`, `-n5`; [withValue] are the letters that take one.
class Opts {
  final Set<String> flags = {};
  final Map<String, List<String>> values = {};
  final List<String> rest = [];

  Opts(List<String> args, {String withValue = '', Map<String, String> long = const {}, bool numberFlag = false}) {
    var i = 0;
    var done = false;
    while (i < args.length) {
      final a = args[i];
      if (done || a == '-' || !a.startsWith('-') || a.length == 1) {
        rest.add(a);
        i++;
        continue;
      }
      if (a == '--') {
        done = true;
        i++;
        continue;
      }
      if (a.startsWith('--')) {
        final eq = a.indexOf('=');
        final name = eq < 0 ? a.substring(2) : a.substring(2, eq);
        final short = long[name];
        if (short == null) throw ShError("unrecognized option '$a'");
        if (withValue.contains(short)) {
          final v = eq >= 0 ? a.substring(eq + 1) : (i + 1 < args.length ? args[++i] : throw ShError("option '$a' requires an argument"));
          values.putIfAbsent(short, () => []).add(v);
        } else {
          flags.add(short);
        }
        i++;
        continue;
      }
      if (numberFlag && RegExp(r'^-\d+$').hasMatch(a)) {
        values.putIfAbsent('n', () => []).add(a.substring(1));
        i++;
        continue;
      }
      for (var k = 1; k < a.length; k++) {
        final ch = a[k];
        if (withValue.contains(ch)) {
          final v = k + 1 < a.length ? a.substring(k + 1) : (i + 1 < args.length ? args[++i] : throw ShError('option requires an argument -- \'$ch\''));
          values.putIfAbsent(ch, () => []).add(v);
          break;
        }
        flags.add(ch);
      }
      i++;
    }
  }

  bool has(String f) => flags.contains(f);
  String? value(String f) => values[f]?.last;
}

List<String> textLines(String s) {
  if (s.isEmpty) return [];
  final l = s.split('\n');
  if (s.endsWith('\n')) l.removeLast();
  return l;
}

String joinLines(Iterable<String> l) {
  final b = StringBuffer();
  for (final x in l) {
    b.write(x);
    b.write('\n');
  }
  return b.toString();
}

/// A POSIX regular expression (basic, or extended with [ere]) for Dart.
RegExp posixRegex(String pat, {bool ere = false, bool icase = false, bool fixed = false, bool word = false, bool line = false}) {
  var src = fixed ? RegExp.escape(pat) : posixToJs(pat, ere: ere);
  if (word) src = r'(?<![A-Za-z0-9_])(?:' + src + r')(?![A-Za-z0-9_])';
  if (line) src = '^(?:$src)\$';
  try {
    return RegExp(src, caseSensitive: !icase);
  } on FormatException {
    throw ShError('Invalid regular expression');
  }
}

String posixToJs(String p, {bool ere = false}) {
  final b = StringBuffer();
  var i = 0;
  var atStart = true;
  while (i < p.length) {
    final c = p[i];
    if (c == '[') {
      var j = i + 1;
      if (j < p.length && p[j] == '^') j++;
      if (j < p.length && p[j] == ']') j++;
      while (j < p.length && p[j] != ']') {
        if (p[j] == '[' && j + 1 < p.length && p[j + 1] == ':') {
          final e = p.indexOf(':]', j + 2);
          j = e < 0 ? j + 1 : e + 2;
        } else {
          j++;
        }
      }
      if (j >= p.length) throw ShError('Unmatched [, [^, [:, [., or [=');
      var cls = p.substring(i + 1, j);
      final neg = cls.startsWith('^');
      if (neg) cls = cls.substring(1);
      cls = cls
          .replaceAll('\\', '\\\\')
          .replaceAll('[:digit:]', '0-9')
          .replaceAll('[:alpha:]', 'a-zA-Z')
          .replaceAll('[:upper:]', 'A-Z')
          .replaceAll('[:lower:]', 'a-z')
          .replaceAll('[:alnum:]', 'a-zA-Z0-9')
          .replaceAll('[:space:]', ' \\t\\n\\r\\f\\v')
          .replaceAll('[:blank:]', ' \\t')
          .replaceAll('[:punct:]', '!-\\/:-@\\[-`{-~')
          .replaceAll('[:xdigit:]', '0-9A-Fa-f');
      if (cls.startsWith(']')) cls = '\\]${cls.substring(1)}';
      cls = cls.replaceAll('[', '\\[');
      b.write('[${neg ? '^' : ''}$cls]');
      i = j + 1;
      atStart = false;
      continue;
    }
    if (c == '\\' && i + 1 < p.length) {
      final n = p[i + 1];
      i += 2;
      if (!ere && '(){}|+?'.contains(n)) {
        b.write(n);
        atStart = n == '(' || n == '|';
        continue;
      }
      if (n == '<' || n == '>') {
        b.write(r'\b');
      } else if ('wWsSbB'.contains(n) || RegExp(r'[1-9]').hasMatch(n)) {
        b.write('\\$n');
      } else if (n == 'n') {
        b.write(r'\n');
      } else if (n == 't') {
        b.write(r'\t');
      } else {
        b.write(RegExp.escape(n));
      }
      atStart = false;
      continue;
    }
    if (!ere && '(){}|+?'.contains(c)) {
      b.write('\\$c');
    } else if (c == '*' && atStart) {
      b.write(r'\*');
    } else if (c == '^' && !atStart && !ere) {
      b.write(r'\^');
    } else if (c == r'$' && !ere && i != p.length - 1 && !(i + 2 < p.length && p[i + 1] == '\\' && p[i + 2] == ')')) {
      b.write(r'\$');
    } else if (c == '/' ) {
      b.write('/');
    } else {
      b.write(c);
    }
    atStart = c == '^' || (ere && (c == '(' || c == '|'));
    i++;
  }
  return b.toString();
}

/// `\n`, `\t`, `\\`... in echo -e and printf.
String unescape(String s, {bool printf = false}) {
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (c != '\\' || i + 1 >= s.length) {
      b.write(c);
      continue;
    }
    final n = s[++i];
    switch (n) {
      case 'n':
        b.write('\n');
      case 't':
        b.write('\t');
      case '\\':
        b.write('\\');
      case 'r':
        b.write('\r');
      case 'a':
        b.write('\x07');
      case 'e':
        b.write('\x1b');
      case '0':
        var k = i + 1, v = 0, d = 0;
        while (k < s.length && d < 3 && '01234567'.contains(s[k])) {
          v = v * 8 + int.parse(s[k]);
          k++;
          d++;
        }
        b.write(String.fromCharCode(v));
        i = k - 1;
      default:
        b.write('\\$n');
    }
  }
  return b.toString();
}

/// printf's format, applied again while arguments remain.
String formatPrintf(String fmt, List<String> args) {
  final out = StringBuffer();
  var ai = 0;
  final spec = RegExp(r'%([-+ 0#]*)(\d+|\*)?(?:\.(\d+|\*))?([sdifgeExXoc%b])');
  do {
    var last = 0;
    var used = false;
    for (final m in spec.allMatches(fmt)) {
      out.write(unescape(fmt.substring(last, m.start), printf: true));
      last = m.end;
      final conv = m[4]!;
      if (conv == '%') {
        out.write('%');
        continue;
      }
      used = true;
      var width = m[2];
      if (width == '*') width = ai < args.length ? args[ai++] : '0';
      var prec = m[3];
      if (prec == '*') prec = ai < args.length ? args[ai++] : '0';
      final arg = ai < args.length ? args[ai++] : null;
      out.write(formatOne(m[1]!, width == null ? null : int.tryParse(width), prec == null ? null : int.tryParse(prec), conv, arg));
    }
    out.write(unescape(fmt.substring(last), printf: true));
    if (!used) break;
  } while (ai < args.length);
  return out.toString();
}

String formatOne(String flags, int? width, int? prec, String conv, String? arg) {
  String body;
  num numArg() {
    final a = (arg ?? '').trim();
    if (a.isEmpty) return 0;
    if (a.startsWith("'") || a.startsWith('"')) return a.length > 1 ? a.codeUnitAt(1) : 0;
    return num.tryParse(a) ?? (int.tryParse(a.replaceFirst(RegExp(r'^0x'), ''), radix: 16) ?? 0);
  }

  switch (conv) {
    case 's':
    case 'b':
      body = conv == 'b' ? unescape(arg ?? '') : (arg ?? '');
      if (prec != null && body.length > prec) body = body.substring(0, prec);
    case 'c':
      body = (arg ?? '').isEmpty ? '' : arg![0];
    case 'd':
    case 'i':
      final v = numArg().truncate();
      body = '${v.abs()}';
      if (prec != null) body = body.padLeft(prec, '0');
      body = (v < 0 ? '-' : flags.contains('+') ? '+' : flags.contains(' ') ? ' ' : '') + body;
    case 'x':
    case 'X':
    case 'o':
      final v = numArg().truncate();
      body = v.toRadixString(conv == 'o' ? 8 : 16);
      if (conv == 'X') body = body.toUpperCase();
    case 'f':
      final v = numArg().toDouble();
      body = v.toStringAsFixed(prec ?? 6);
      if (flags.contains('+') && v >= 0) body = '+$body';
    case 'e':
    case 'E':
      final v = numArg().toDouble();
      body = v.toStringAsExponential(prec ?? 6).replaceFirstMapped(RegExp(r'e([+-])(\d)$'), (m) => 'e${m[1]}0${m[2]}');
      if (conv == 'E') body = body.toUpperCase();
    case 'g':
      final v = numArg().toDouble();
      body = formatG(v, prec ?? 6);
    default:
      body = arg ?? '';
  }
  if (width != null && body.length < width) {
    if (flags.contains('-')) {
      body = body.padRight(width);
    } else if (flags.contains('0') && 'difxXoeEg'.contains(conv)) {
      final neg = body.startsWith('-') || body.startsWith('+');
      body = neg ? body[0] + body.substring(1).padLeft(width - 1, '0') : body.padLeft(width, '0');
    } else {
      body = body.padLeft(width);
    }
  }
  return body;
}

/// %g as C prints it.
String formatG(double v, int prec) {
  if (v == 0) return '0';
  if (v.isNaN) return 'nan';
  if (v.isInfinite) return v > 0 ? 'inf' : '-inf';
  final p = prec == 0 ? 1 : prec;
  final exp = (math.log(v.abs()) / math.ln10).floor();
  String strip(String s) => s.contains('.') ? s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '') : s;
  if (exp < -4 || exp >= p) {
    var s = v.toStringAsExponential(p - 1);
    final e = s.indexOf('e');
    var mant = strip(s.substring(0, e));
    var ex = s.substring(e + 1);
    final sign = ex.startsWith('-') ? '-' : '+';
    ex = ex.replaceFirst(RegExp(r'^[+-]'), '').padLeft(2, '0');
    s = '${mant}e$sign$ex';
    return s;
  }
  return strip(v.toStringAsFixed(math.max(0, p - 1 - exp)));
}

class ShellCommands {
  static ShCmd? builtin(String name) => _all[name];

  static List<String> get names => (_all.keys.toList()..addAll(['bash', 'sh', 'source', 'exit', 'break', 'continue', 'return', 'local', 'nano']))..sort();

  static final Map<String, ShCmd> _all = {
    'cd': _cd,
    'pwd': (sh, c, a, i, o, e) {
      o.write('${c.cwd}\n');
      return 0;
    },
    'echo': _echo,
    'printf': (sh, c, a, i, o, e) {
      if (a.isEmpty) throw ShError('usage: printf format [arguments]', 2);
      var args = a;
      String? toVar;
      if (args.length >= 2 && args[0] == '-v') {
        toVar = args[1];
        args = args.sublist(2);
      }
      final s = formatPrintf(args[0], args.sublist(1));
      if (toVar != null) {
        c.vars[toVar] = s;
      } else {
        o.write(s);
      }
      return 0;
    },
    'export': (sh, c, a, i, o, e) {
      for (final x in a.where((x) => x != '-n' && x != '-p')) {
        final eq = x.indexOf('=');
        final k = eq < 0 ? x : x.substring(0, eq);
        if (eq >= 0) c.vars[k] = x.substring(eq + 1);
        c.exported.add(k);
      }
      if (a.isEmpty) {
        for (final k in c.exported.toList()..sort()) {
          o.write('declare -x $k="${c.vars[k] ?? ''}"\n');
        }
      }
      return 0;
    },
    'unset': (sh, c, a, i, o, e) {
      for (final x in a.where((x) => !x.startsWith('-'))) {
        c.vars.remove(x);
        c.funcs.remove(x);
        c.exported.remove(x);
      }
      return 0;
    },
    'read': _read,
    'test': (sh, c, a, i, o, e) => _test(sh, c, a),
    '[': (sh, c, a, i, o, e) {
      if (a.isEmpty || a.last != ']') throw ShError("missing `]'", 2);
      return _test(sh, c, a.sublist(0, a.length - 1));
    },
    '[[': (sh, c, a, i, o, e) {
      if (a.isEmpty || a.last != ']]') throw ShError("missing `]]'", 2);
      return _dtest(sh, c, a.sublist(0, a.length - 1));
    },
    'true': (sh, c, a, i, o, e) => 0,
    ':': (sh, c, a, i, o, e) => 0,
    'false': (sh, c, a, i, o, e) => 1,
    'shift': (sh, c, a, i, o, e) {
      final n = a.isEmpty ? 1 : int.tryParse(a[0]) ?? 1;
      if (n > c.args.length) return 1;
      c.args = c.args.sublist(n);
      return 0;
    },
    'set': (sh, c, a, i, o, e) {
      final k = a.indexOf('--');
      if (k >= 0) {
        c.args = a.sublist(k + 1);
      } else if (a.isEmpty) {
        for (final k in c.vars.keys.toList()..sort()) {
          o.write('$k=${c.vars[k]}\n');
        }
      } else if (!a[0].startsWith('-') && !a[0].startsWith('+')) {
        c.args = a;
      }
      return 0;
    },
    'history': (sh, c, a, i, o, e) {
      for (final (k, h) in sh.history.indexed) {
        o.write('${'${k + 1}'.padLeft(5)}  $h\n');
      }
      return 0;
    },
    'clear': (sh, c, a, i, o, e) {
      sh.onClear?.call();
      return 0;
    },
    'help': _help,
    'man': (sh, c, a, i, o, e) {
      if (a.isEmpty) {
        e.write('What manual page do you want?\n');
        return 1;
      }
      o.write('${a[0]}: paginile de manual nu sunt instalate aici. Caută „man ${a[0]}” pe net sau încearcă `help`.\n');
      return 0;
    },
    'type': (sh, c, a, i, o, e) {
      var st = 0;
      for (final x in a) {
        if (c.funcs.containsKey(x)) {
          o.write('$x is a function\n');
        } else if (_all.containsKey(x) || const {'cd', 'echo', 'exit', 'source'}.contains(x)) {
          o.write(const {'cd', 'echo', 'pwd', 'read', 'test', '[', 'export', 'unset', 'shift', 'set', 'history', 'type', 'printf', 'true', 'false', 'umask', 'let'}.contains(x)
              ? '$x is a shell builtin\n'
              : '$x is /usr/bin/$x\n');
        } else {
          e.write('bash: type: $x: not found\n');
          st = 1;
        }
      }
      return st;
    },
    'which': (sh, c, a, i, o, e) {
      var st = 0;
      for (final x in a) {
        if (_all.containsKey(x)) {
          o.write('/usr/bin/$x\n');
        } else {
          st = 1;
        }
      }
      return st;
    },
    'umask': (sh, c, a, i, o, e) {
      if (a.isEmpty) {
        o.write('${sh.fs.umask.toRadixString(8).padLeft(4, '0')}\n');
        return 0;
      }
      final v = int.tryParse(a[0], radix: 8);
      if (v == null) throw ShError('${a[0]}: octal number out of range');
      sh.fs.umask = v & 511;
      return 0;
    },
    'let': (sh, c, a, i, o, e) {
      var v = 0;
      for (final x in a) {
        v = sh.arith(x, c);
      }
      return v == 0 ? 1 : 0;
    },
    'expr': _expr,
    'seq': _seq,
    'sleep': (sh, c, a, i, o, e) => 0,
    'date': (sh, c, a, i, o, e) {
      final f = a.where((x) => x.startsWith('+')).firstOrNull;
      if (f == null) {
        o.write('Sun Nov  8 10:00:00 EET 2026\n');
      } else {
        o.write('${f.substring(1).replaceAll('%Y', '2026').replaceAll('%m', '11').replaceAll('%d', '08').replaceAll('%H', '10').replaceAll('%M', '00').replaceAll('%S', '00').replaceAll('%F', '2026-11-08').replaceAll('%T', '10:00:00').replaceAll('%s', '1794124800')}\n');
      }
      return 0;
    },
    'whoami': (sh, c, a, i, o, e) {
      o.write('student\n');
      return 0;
    },
    'id': (sh, c, a, i, o, e) {
      if (a.contains('-u')) {
        o.write('1000\n');
      } else if (a.contains('-un') || a.contains('-nu')) {
        o.write('student\n');
      } else {
        o.write('uid=1000(student) gid=1000(student) groups=1000(student),27(sudo)\n');
      }
      return 0;
    },
    'groups': (sh, c, a, i, o, e) {
      o.write('student sudo\n');
      return 0;
    },
    'hostname': (sh, c, a, i, o, e) {
      o.write('acs\n');
      return 0;
    },
    'uname': (sh, c, a, i, o, e) {
      o.write(a.contains('-a') ? 'Linux acs 6.8.0-acs #1 SMP x86_64 GNU/Linux\n' : a.contains('-r') ? '6.8.0-acs\n' : 'Linux\n');
      return 0;
    },
    'sudo': (sh, c, a, i, o, e) {
      e.write('student is not in the sudoers file here. This incident will be reported.\n');
      return 1;
    },
    'ls': _ls,
    'cat': _cat,
    'tac': (sh, c, a, i, o, e) {
      final (text, st) = _readInputs(sh, c, a, i, e, 'tac');
      o.write(joinLines(textLines(text).reversed));
      return st;
    },
    'rev': (sh, c, a, i, o, e) {
      final (text, st) = _readInputs(sh, c, a, i, e, 'rev');
      o.write(joinLines(textLines(text).map((l) => String.fromCharCodes(l.runes.toList().reversed))));
      return st;
    },
    'nl': (sh, c, a, i, o, e) {
      final (text, st) = _readInputs(sh, c, a.where((x) => !x.startsWith('-')).toList(), i, e, 'nl');
      var n = 0;
      o.write(joinLines(textLines(text).map((l) => l.trim().isEmpty ? '       $l' : '${'${++n}'.padLeft(6)}\t$l')));
      return st;
    },
    'touch': _touch,
    'mkdir': _mkdir,
    'rmdir': (sh, c, a, i, o, e) {
      var st = 0;
      for (final p in Opts(a, long: {'parents': 'p'}).rest) {
        final n = sh.fs.lookup(p, c.cwd, follow: false);
        if (n == null) {
          e.write("rmdir: failed to remove '$p': No such file or directory\n");
          st = 1;
        } else if (!n.isDir) {
          e.write("rmdir: failed to remove '$p': Not a directory\n");
          st = 1;
        } else if (n.kids.isNotEmpty) {
          e.write("rmdir: failed to remove '$p': Directory not empty\n");
          st = 1;
        } else {
          sh.fs.remove(p, c.cwd);
        }
      }
      return st;
    },
    'rm': _rm,
    'cp': _cp,
    'mv': _mv,
    'ln': _ln,
    'chmod': _chmod,
    'chown': (sh, c, a, i, o, e) {
      e.write('chown: changing ownership: Operation not permitted\n');
      return 1;
    },
    'stat': _stat,
    'file': (sh, c, a, i, o, e) {
      for (final p in a) {
        final n = sh.fs.lookup(p, c.cwd, follow: false);
        o.write('$p: ${n == null ? 'cannot open' : n.isDir ? 'directory' : n.isLink ? 'symbolic link to ${n.data}' : n.data.isEmpty ? 'empty' : n.data.startsWith('#!') ? 'Bourne-Again shell script, ASCII text executable' : 'ASCII text'}\n');
      }
      return 0;
    },
    'find': _find,
    'grep': _grep,
    'egrep': (sh, c, a, i, o, e) => _grep(sh, c, ['-E', ...a], i, o, e),
    'fgrep': (sh, c, a, i, o, e) => _grep(sh, c, ['-F', ...a], i, o, e),
    'wc': _wc,
    'head': (sh, c, a, i, o, e) => _headTail(sh, c, a, i, o, e, true),
    'tail': (sh, c, a, i, o, e) => _headTail(sh, c, a, i, o, e, false),
    'sort': _sort,
    'uniq': _uniq,
    'cut': _cut,
    'tr': _tr,
    'sed': _sed,
    'awk': (sh, c, a, i, o, e) => Awk.main(sh, c, a, i, o, e),
    'tee': (sh, c, a, i, o, e) {
      final opts = Opts(a, long: {'append': 'a'});
      final text = i.readAll();
      for (final f in opts.rest) {
        sh.fs.write(f, c.cwd, text, append: opts.has('a'));
      }
      o.write(text);
      return 0;
    },
    'basename': (sh, c, a, i, o, e) {
      if (a.isEmpty) throw ShError('missing operand');
      var b = a[0].replaceFirst(RegExp(r'/+$'), '');
      b = b.substring(b.lastIndexOf('/') + 1);
      if (a.length > 1 && b.endsWith(a[1]) && b != a[1]) b = b.substring(0, b.length - a[1].length);
      o.write('${b.isEmpty ? '/' : b}\n');
      return 0;
    },
    'dirname': (sh, c, a, i, o, e) {
      if (a.isEmpty) throw ShError('missing operand');
      final s = a[0].replaceFirst(RegExp(r'/+$'), '');
      final k = s.lastIndexOf('/');
      o.write('${k < 0 ? '.' : k == 0 ? '/' : s.substring(0, k)}\n');
      return 0;
    },
    'realpath': (sh, c, a, i, o, e) {
      for (final p in a.where((x) => !x.startsWith('-'))) {
        o.write('${sh.fs.realpath(p, c.cwd)}\n');
      }
      return 0;
    },
    'readlink': (sh, c, a, i, o, e) {
      final opts = Opts(a);
      for (final p in opts.rest) {
        if (opts.has('f')) {
          o.write('${sh.fs.realpath(p, c.cwd)}\n');
          continue;
        }
        final n = sh.fs.lookup(p, c.cwd, follow: false);
        if (n == null || !n.isLink) return 1;
        o.write('${n.data}\n');
      }
      return 0;
    },
    'paste': (sh, c, a, i, o, e) {
      final opts = Opts(a, withValue: 'd');
      final d = opts.value('d') ?? '\t';
      if (opts.has('s')) {
        final (text, st) = _readInputs(sh, c, opts.rest, i, e, 'paste');
        if (st == 0) o.write('${textLines(text).join(d)}\n');
        return st;
      }
      final cols = [for (final f in opts.rest) textLines(f == '-' ? i.readAll() : sh.fs.read(f, c.cwd))];
      final n = cols.fold<int>(0, (m, l) => math.max(m, l.length));
      for (var r = 0; r < n; r++) {
        o.write('${[for (final col in cols) r < col.length ? col[r] : ''].join(d)}\n');
      }
      return 0;
    },
    'xargs': (sh, c, a, i, o, e) {
      final opts = Opts(a, withValue: 'nI');
      final cmd = opts.rest.isEmpty ? ['echo'] : opts.rest;
      final items = i.readAll().split(RegExp(r'\s+')).where((x) => x.isNotEmpty).toList();
      final repl = opts.value('I');
      if (repl != null) {
        var st = 0;
        for (final it in textLines(items.join('\n'))) {
          st = sh.runCommand([for (final w in cmd) w.replaceAll(repl, it)], c, ShIn.empty, o, e);
        }
        return st;
      }
      final per = int.tryParse(opts.value('n') ?? '') ?? (items.isEmpty ? 1 : items.length);
      var st = 0;
      if (items.isEmpty) return sh.runCommand(cmd, c, ShIn.empty, o, e);
      for (var k = 0; k < items.length; k += per) {
        st = sh.runCommand([...cmd, ...items.sublist(k, math.min(items.length, k + per))], c, ShIn.empty, o, e);
      }
      return st;
    },
    'du': (sh, c, a, i, o, e) {
      final opts = Opts(a);
      final paths = opts.rest.isEmpty ? ['.'] : opts.rest;
      for (final p in paths) {
        final n = sh.fs.lookup(p, c.cwd);
        if (n == null) throw ShError("cannot access '$p': No such file or directory");
        var total = 0;
        for (final (_, x, _) in sh.fs.walk(p, n)) {
          total += x.isDir ? 4 : ((x.size + 4095) ~/ 4096) * 4;
        }
        o.write('${opts.has('h') ? '${total}K' : total}\t$p\n');
      }
      return 0;
    },
    'diff': _diff,
    'cmp': (sh, c, a, i, o, e) {
      if (a.length < 2) throw ShError('missing operand');
      final x = sh.fs.read(a[0], c.cwd), y = sh.fs.read(a[1], c.cwd);
      if (x == y) return 0;
      var k = 0;
      while (k < x.length && k < y.length && x[k] == y[k]) {
        k++;
      }
      final line = '\n'.allMatches(x.substring(0, k)).length + 1;
      o.write('${a[0]} ${a[1]} differ: byte ${k + 1}, line $line\n');
      return 1;
    },
    'yes': (sh, c, a, i, o, e) {
      o.write(List.filled(1000, a.isEmpty ? 'y' : a.join(' ')).join('\n'));
      o.write('\n');
      return 0;
    },
    'ps': (sh, c, a, i, o, e) {
      o.write('    PID TTY          TIME CMD\n   4242 pts/0    00:00:00 bash\n   4300 pts/0    00:00:00 ps\n');
      return 0;
    },
    'kill': (sh, c, a, i, o, e) {
      e.write('kill: aici nu rulează alte procese\n');
      return 1;
    },
    'ping': (sh, c, a, i, o, e) {
      e.write('ping: rețeaua nu e disponibilă în acest shell\n');
      return 2;
    },
  };

  // ------------------------------------------------------------ builtins
  static int _cd(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final args = a.where((x) => x != '-P' && x != '-L').toList();
    var target = args.isEmpty ? (c.vars['HOME'] ?? Vfs.home) : args[0];
    if (target == '-') {
      target = c.vars['OLDPWD'] ?? c.cwd;
      o.write('$target\n');
    }
    final abs = Vfs.absolute(target, c.cwd);
    final n = sh.fs.lookup(abs, '/');
    if (n == null) throw ShError('$target: No such file or directory');
    if (!n.isDir) throw ShError('$target: Not a directory');
    if (!Vfs.may(n, 'x')) throw ShError('$target: Permission denied');
    c.vars['OLDPWD'] = c.cwd;
    c.cwd = abs;
    c.vars['PWD'] = abs;
    return 0;
  }

  static int _echo(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    var newline = true, esc = false;
    var k = 0;
    while (k < a.length && RegExp(r'^-[neE]+$').hasMatch(a[k])) {
      if (a[k].contains('n')) newline = false;
      if (a[k].contains('e')) esc = true;
      if (a[k].contains('E')) esc = false;
      k++;
    }
    var s = a.sublist(k).join(' ');
    if (esc) {
      final ci = s.indexOf('\\c');
      if (ci >= 0) {
        s = s.substring(0, ci);
        newline = false;
      }
      s = unescape(s);
    }
    o.write(newline ? '$s\n' : s);
    return 0;
  }

  static int _read(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'pdna');
    final raw = opts.has('r');
    var names = opts.rest;
    final line0 = i.readLine();
    if (line0 == null) {
      for (final n in names) {
        c.vars[n] = '';
      }
      return 1;
    }
    var line = line0;
    if (!raw) {
      while (line.endsWith('\\')) {
        final next = i.readLine();
        line = line.substring(0, line.length - 1) + (next ?? '');
        if (next == null) break;
      }
      line = line.replaceAllMapped(RegExp(r'\\(.)'), (m) => m[1]!);
    }
    if (opts.value('a') != null) {
      final parts = line.trim().split(RegExp(r'\s+'));
      c.vars[opts.value('a')!] = parts.join(' ');
      return 0;
    }
    if (names.isEmpty) names = ['REPLY'];
    final ifs = c.vars['IFS'] ?? ' \t\n';
    final ws = ifs.replaceAll(RegExp(r'[^ \t\n]'), '');
    if (names.length == 1) {
      c.vars[names[0]] = ifs.isEmpty ? line : _trimChars(line, ws);
      return 0;
    }
    var rest = _trimChars(line, ws);
    for (var k = 0; k < names.length; k++) {
      if (k == names.length - 1) {
        c.vars[names[k]] = _trimChars(rest, ws);
        break;
      }
      final m = RegExp('[${RegExp.escape(ifs)}]').firstMatch(rest);
      if (m == null) {
        c.vars[names[k]] = rest;
        rest = '';
      } else {
        c.vars[names[k]] = rest.substring(0, m.start);
        rest = rest.substring(m.end);
        if (ws.isNotEmpty) rest = rest.replaceFirst(RegExp('^[${RegExp.escape(ws)}]+'), '');
      }
    }
    return 0;
  }

  static String _trimChars(String s, String chars) {
    if (chars.isEmpty) return s;
    final cls = '[${RegExp.escape(chars)}]';
    return s.replaceFirst(RegExp('^$cls+'), '').replaceFirst(RegExp('$cls+\$'), '');
  }

  static int _test(Shell sh, ShCtx c, List<String> a) {
    try {
      return _TestEval(sh, c, a).run() ? 0 : 1;
    } on ShError catch (x) {
      throw ShError('test: ${x.message}', 2);
    }
  }

  static int _dtest(Shell sh, ShCtx c, List<String> a) {
    // [[ ]]: && || ! ( ) and == with patterns, =~ with a regex
    var k = 0;
    late bool Function() orE;
    bool primary() {
      if (k < a.length && a[k] == '!') {
        k++;
        return !primary();
      }
      if (k < a.length && a[k] == '(') {
        k++;
        final v = orE();
        if (k < a.length && a[k] == ')') k++;
        return v;
      }
      final start = k;
      while (k < a.length && a[k] != '&&' && a[k] != '||' && a[k] != ')') {
        k++;
      }
      final part = a.sublist(start, k);
      if (part.length == 3 && (part[1] == '==' || part[1] == '=' || part[1] == '!=')) {
        final m = Shell.globRegex(part[2]).hasMatch(part[0]);
        return part[1] == '!=' ? !m : m;
      }
      if (part.length == 3 && part[1] == '=~') return posixRegex(part[2], ere: true).hasMatch(part[0]);
      if (part.length == 3 && (part[1] == '<' || part[1] == '>')) {
        final cmp = part[0].compareTo(part[2]);
        return part[1] == '<' ? cmp < 0 : cmp > 0;
      }
      return _TestEval(sh, c, part).run();
    }

    bool andExpr() {
      var v = primary();
      while (k < a.length && a[k] == '&&') {
        k++;
        final r = primary();
        v = v && r;
      }
      return v;
    }

    bool orExpr0() {
      var v = andExpr();
      while (k < a.length && a[k] == '||') {
        k++;
        final r = andExpr();
        v = v || r;
      }
      return v;
    }

    orE = orExpr0;
    return orExpr0() ? 0 : 1;
  }

  static int _expr(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    if (a.isEmpty) throw ShError('missing operand', 2);
    if (a[0] == 'length' && a.length == 2) {
      o.write('${a[1].length}\n');
      return a[1].isEmpty ? 1 : 0;
    }
    if (a.length == 1) {
      o.write('${a[0]}\n');
      return a[0] == '0' || a[0].isEmpty ? 1 : 0;
    }
    // left to right, * / % before + -
    num toNum(String s) => int.tryParse(s) ?? (throw ShError('non-integer argument', 2));
    final vals = <String>[...a];
    String evalOps(List<String> v, Set<String> ops) {
      final out = <String>[];
      for (var k = 0; k < v.length; k++) {
        if (ops.contains(v[k]) && out.isNotEmpty && k + 1 < v.length) {
          final l = out.removeLast(), r = v[++k];
          final res = switch (v[k - 1]) {
            '*' => toNum(l) * toNum(r),
            '/' => toNum(r) == 0 ? throw ShError('division by zero', 2) : toNum(l) ~/ toNum(r),
            '%' => toNum(r) == 0 ? throw ShError('division by zero', 2) : toNum(l).remainder(toNum(r)),
            '+' => toNum(l) + toNum(r),
            '-' => toNum(l) - toNum(r),
            '=' || '==' => l == r ? 1 : 0,
            '!=' => l != r ? 1 : 0,
            '<' => (int.tryParse(l) != null && int.tryParse(r) != null ? toNum(l) < toNum(r) : l.compareTo(r) < 0) ? 1 : 0,
            '<=' => (int.tryParse(l) != null && int.tryParse(r) != null ? toNum(l) <= toNum(r) : l.compareTo(r) <= 0) ? 1 : 0,
            '>' => (int.tryParse(l) != null && int.tryParse(r) != null ? toNum(l) > toNum(r) : l.compareTo(r) > 0) ? 1 : 0,
            '>=' => (int.tryParse(l) != null && int.tryParse(r) != null ? toNum(l) >= toNum(r) : l.compareTo(r) >= 0) ? 1 : 0,
            _ => 0,
          };
          out.add('$res');
        } else {
          out.add(v[k]);
        }
      }
      return out.join('\u0000');
    }

    var v = evalOps(vals, {'*', '/', '%'}).split('\u0000');
    v = evalOps(v, {'+', '-'}).split('\u0000');
    v = evalOps(v, {'=', '==', '!=', '<', '<=', '>', '>='}).split('\u0000');
    if (v.length != 1) throw ShError('syntax error', 2);
    o.write('${v[0]}\n');
    return v[0] == '0' || v[0].isEmpty ? 1 : 0;
  }

  static int _seq(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    var sep = '\n';
    var width = false;
    final nums = <String>[];
    for (var k = 0; k < a.length; k++) {
      if (a[k] == '-s' && k + 1 < a.length) {
        sep = unescape(a[++k]);
      } else if (a[k].startsWith('-s') && a[k].length > 2) {
        sep = unescape(a[k].substring(2));
      } else if (a[k] == '-w') {
        width = true;
      } else {
        nums.add(a[k]);
      }
    }
    if (nums.isEmpty) throw ShError('missing operand');
    final v = nums.map((x) => num.tryParse(x) ?? (throw ShError("invalid floating point argument: '$x'"))).toList();
    final first = v.length > 1 ? v[0] : 1, inc = v.length > 2 ? v[1] : 1, last = v.last;
    if (inc == 0) throw ShError("invalid Zero increment value: '0'");
    final out = <String>[];
    final isInt = v.every((x) => x == x.roundToDouble()) && nums.every((x) => !x.contains('.'));
    for (var x = first; inc > 0 ? x <= last + 1e-9 : x >= last - 1e-9; x += inc) {
      out.add(isInt ? '${x.round()}' : formatG(x.toDouble(), 6));
      if (out.length > 100000) break;
    }
    if (width) {
      final w = out.fold<int>(0, (m, s) => math.max(m, s.length));
      for (var k = 0; k < out.length; k++) {
        out[k] = out[k].padLeft(w, '0');
      }
    }
    if (out.isNotEmpty) o.write('${out.join(sep)}\n');
    return 0;
  }

  static int _help(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    o.write('Shell-ul USO: bash, rulat în browser, pe un sistem de fișiere doar al tău.\n'
        'Comenzi: ${names.join(' ')}\n'
        'Ai pipe-uri (|), redirectări (> >> < 2> 2>&1), &&, ||, ;, variabile, \$(...), \$((...)),\n'
        'if, for, while, case, funcții și scripturi (bash script.sh sau ./script.sh după chmod +x).\n'
        'nano fisier deschide editorul. Săgețile sus/jos: istoricul; Tab: completează numele.\n');
    return 0;
  }

  // ------------------------------------------------------------ files
  static (String, int) _readInputs(Shell sh, ShCtx c, List<String> files, ShIn i, Sink e, String cmd) {
    if (files.isEmpty) return (i.readAll(), 0);
    final b = StringBuffer();
    var st = 0;
    for (final f in files) {
      if (f == '-') {
        b.write(i.readAll());
        continue;
      }
      try {
        b.write(sh.fs.read(f, c.cwd));
      } on ShError catch (x) {
        e.write('$cmd: ${x.message}\n');
        st = 1;
      }
    }
    return (b.toString(), st);
  }

  static int _cat(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'number': 'n'});
    final (text, st) = _readInputs(sh, c, opts.rest, i, e, 'cat');
    if (opts.has('n')) {
      var n = 0;
      final lines = text.split('\n');
      final b = StringBuffer();
      for (var k = 0; k < lines.length; k++) {
        if (k == lines.length - 1 && lines[k].isEmpty) break;
        b.write('${'${++n}'.padLeft(6)}\t${lines[k]}');
        if (k < lines.length - 1) b.write('\n');
      }
      o.write(b.toString());
    } else {
      o.write(text);
    }
    return st;
  }

  static int _touch(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    var st = 0;
    for (final p in Opts(a).rest) {
      final n = sh.fs.lookup(p, c.cwd);
      try {
        if (n != null) {
          n.mtime = sh.fs.tick();
        } else {
          sh.fs.write(p, c.cwd, '');
        }
      } on ShError catch (x) {
        e.write("touch: cannot touch '$p': ${x.message.split(': ').last}\n");
        st = 1;
      }
    }
    return st;
  }

  static int _mkdir(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'm', long: {'parents': 'p'});
    var st = 0;
    if (opts.rest.isEmpty) throw ShError('missing operand');
    for (final p in opts.rest) {
      try {
        final d = sh.fs.mkdir(p, c.cwd, parents: opts.has('p'));
        if (opts.value('m') != null) d.mode = Vfs.applyMode(d.mode, opts.value('m')!, true);
      } on ShError catch (x) {
        e.write('mkdir: ${x.message}\n');
        st = 1;
      }
    }
    return st;
  }

  static int _rm(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'recursive': 'r', 'force': 'f'});
    final rec = opts.has('r') || opts.has('R');
    var st = 0;
    if (opts.rest.isEmpty && !opts.has('f')) throw ShError('missing operand');
    for (final p in opts.rest) {
      final n = sh.fs.lookup(p, c.cwd, follow: false);
      if (n == null) {
        if (!opts.has('f')) {
          e.write("rm: cannot remove '$p': No such file or directory\n");
          st = 1;
        }
        continue;
      }
      final abs = Vfs.absolute(p, c.cwd);
      if (abs == '/' || abs == Vfs.home && false) {
        e.write("rm: it is dangerous to operate recursively on '/'\n");
        st = 1;
        continue;
      }
      if (n.isDir && !rec) {
        e.write("rm: cannot remove '$p': Is a directory\n");
        st = 1;
        continue;
      }
      if (Vfs.absolute(c.cwd, '/').startsWith('$abs/') || c.cwd == abs) {
        // removing the directory we're in: allowed, like bash
      }
      try {
        sh.fs.remove(p, c.cwd);
      } on ShError catch (x) {
        e.write('rm: ${x.message}\n');
        st = 1;
      }
    }
    return st;
  }

  static int _cp(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'recursive': 'r'});
    final rec = opts.has('r') || opts.has('R') || opts.has('a');
    final args = opts.rest;
    if (args.length < 2) throw ShError(args.isEmpty ? 'missing file operand' : "missing destination file operand after '${args[0]}'");
    final dest = args.last;
    final srcs = args.sublist(0, args.length - 1);
    final destNode = sh.fs.lookup(dest, c.cwd);
    final intoDir = destNode != null && destNode.isDir;
    if (srcs.length > 1 && !intoDir) throw ShError("target '$dest' is not a directory");
    var st = 0;
    for (final s in srcs) {
      final n = sh.fs.lookup(s, c.cwd);
      if (n == null) {
        e.write("cp: cannot stat '$s': No such file or directory\n");
        st = 1;
        continue;
      }
      if (n.isDir && !rec) {
        e.write("cp: -r not specified; omitting directory '$s'\n");
        st = 1;
        continue;
      }
      if (!Vfs.may(n, 'r')) {
        e.write("cp: cannot open '$s' for reading: Permission denied\n");
        st = 1;
        continue;
      }
      final name = Vfs.absolute(s, c.cwd).split('/').last;
      final target = intoDir ? '${Vfs.absolute(dest, c.cwd)}/$name' : Vfs.absolute(dest, c.cwd);
      if (n.isDir && Vfs.absolute(target, '/').startsWith('${Vfs.absolute(s, c.cwd)}/')) {
        e.write("cp: cannot copy a directory, '$s', into itself, '$dest'\n");
        st = 1;
        continue;
      }
      final copy = n.clone();
      for (final (_, x, _) in sh.fs.walk('/', copy)) {
        x.owner = Vfs.user;
        if (!opts.has('p') && !opts.has('a')) x.mtime = sh.fs.tick();
      }
      final existing = sh.fs.lookup(target, '/');
      if (existing != null && existing.isFile && copy.isFile) {
        if (!Vfs.may(existing, 'w')) {
          e.write("cp: cannot create regular file '$target': Permission denied\n");
          st = 1;
          continue;
        }
        existing.data = copy.data;
        existing.mtime = sh.fs.tick();
      } else {
        sh.fs.place(target, '/', copy);
      }
    }
    return st;
  }

  static int _mv(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final args = Opts(a).rest;
    if (args.length < 2) throw ShError(args.isEmpty ? 'missing file operand' : "missing destination file operand after '${args[0]}'");
    final dest = args.last;
    final srcs = args.sublist(0, args.length - 1);
    final destNode = sh.fs.lookup(dest, c.cwd);
    final intoDir = destNode != null && destNode.isDir;
    if (srcs.length > 1 && !intoDir) throw ShError("target '$dest' is not a directory");
    var st = 0;
    for (final s in srcs) {
      final n = sh.fs.lookup(s, c.cwd, follow: false);
      if (n == null) {
        e.write("mv: cannot stat '$s': No such file or directory\n");
        st = 1;
        continue;
      }
      final srcAbs = Vfs.absolute(s, c.cwd);
      final name = srcAbs.split('/').last;
      final target = intoDir ? '${Vfs.absolute(dest, c.cwd)}/$name' : Vfs.absolute(dest, c.cwd);
      if (target == srcAbs) continue;
      if (n.isDir && target.startsWith('$srcAbs/')) {
        e.write("mv: cannot move '$s' to a subdirectory of itself, '$dest'\n");
        st = 1;
        continue;
      }
      final existing = sh.fs.lookup(target, '/', follow: false);
      if (existing != null && existing.isDir && !n.isDir) {
        e.write("mv: cannot overwrite directory '$target' with non-directory\n");
        st = 1;
        continue;
      }
      try {
        sh.fs.remove(srcAbs, '/');
        sh.fs.place(target, '/', n);
      } on ShError catch (x) {
        e.write('mv: ${x.message}\n');
        st = 1;
      }
    }
    return st;
  }

  static int _ln(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'symbolic': 's', 'force': 'f'});
    final args = opts.rest;
    if (args.isEmpty) throw ShError('missing file operand');
    final target = args[0];
    var name = args.length > 1 ? args[1] : target.split('/').last;
    final nameNode = sh.fs.lookup(name, c.cwd);
    if (nameNode != null && nameNode.isDir) name = '$name/${target.split('/').last}';
    final existing = sh.fs.lookup(name, c.cwd, follow: false);
    if (existing != null) {
      if (!opts.has('f')) throw ShError("failed to create ${opts.has('s') ? 'symbolic' : 'hard'} link '$name': File exists");
      sh.fs.remove(name, c.cwd);
    }
    if (opts.has('s')) {
      sh.fs.place(name, c.cwd, VNode.link(target, Vfs.user, sh.fs.tick()));
    } else {
      final n = sh.fs.lookup(target, c.cwd);
      if (n == null) throw ShError("failed to access '$target': No such file or directory");
      if (n.isDir) throw ShError("'$target': hard link not allowed for directory");
      sh.fs.place(name, c.cwd, n);
    }
    return 0;
  }

  static int _chmod(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    // a mode like -x or -w is a mode, not an option
    final rec = a.contains('-R');
    final args = a.where((x) => x != '-R' && x != '-v' && x != '-f').toList();
    if (args.length < 2) throw ShError(args.isEmpty ? 'missing operand' : "missing operand after '${args[0]}'");
    final mode = args[0];
    var st = 0;
    for (final p in args.sublist(1)) {
      final n = sh.fs.lookup(p, c.cwd);
      if (n == null) {
        e.write("chmod: cannot access '$p': No such file or directory\n");
        st = 1;
        continue;
      }
      if (n.owner != Vfs.user) {
        e.write("chmod: changing permissions of '$p': Operation not permitted\n");
        st = 1;
        continue;
      }
      final targets = rec ? sh.fs.walk(p, n).map((x) => x.$2).toList() : [n];
      for (final t in targets) {
        if (t.isLink) continue;
        t.mode = Vfs.applyMode(t.mode, mode, t.isDir);
      }
    }
    return st;
  }

  static int _stat(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'c', long: {'format': 'c'});
    var st = 0;
    for (final p in opts.rest) {
      final n = sh.fs.lookup(p, c.cwd, follow: false);
      if (n == null) {
        e.write("stat: cannot statx '$p': No such file or directory\n");
        st = 1;
        continue;
      }
      final f = opts.value('c');
      if (f != null) {
        o.write('${f.replaceAll('%a', (n.mode & 0xfff).toRadixString(8)).replaceAll('%A', Vfs.modeString(n)).replaceAll('%n', p).replaceAll('%s', '${n.size}').replaceAll('%U', n.owner).replaceAll('%G', n.owner).replaceAll('%F', n.isDir ? 'directory' : n.isLink ? 'symbolic link' : n.data.isEmpty ? 'regular empty file' : 'regular file')}\n');
      } else {
        o.write('  File: $p${n.isLink ? ' -> ${n.data}' : ''}\n'
            '  Size: ${n.size}\t\t${n.isDir ? 'directory' : n.isLink ? 'symbolic link' : 'regular file'}\n'
            'Access: (0${(n.mode & 0xfff).toRadixString(8).padLeft(3, '0')}/${Vfs.modeString(n)})  Uid: ( ${n.owner == Vfs.user ? '1000' : '   0'}/ ${n.owner.padLeft(7)})\n');
      }
    }
    return st;
  }

  static int _ls(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'all': 'a', 'almost-all': 'A', 'recursive': 'R', 'human-readable': 'h', 'directory': 'd', 'reverse': 'r'});
    final long = opts.has('l') || opts.has('g') || opts.has('n');
    final all = opts.has('a'), almost = opts.has('A');
    final paths = opts.rest.isEmpty ? ['.'] : opts.rest;
    var st = 0;
    final files = <(String, VNode)>[];
    final dirs = <(String, VNode)>[];
    for (final p in paths) {
      final n = sh.fs.lookup(p, c.cwd, follow: !long || !p.endsWith('/') ? !(sh.fs.lookup(p, c.cwd, follow: false)?.isLink ?? false) || !long : true);
      final real = sh.fs.lookup(p, c.cwd);
      if (n == null && real == null) {
        e.write("ls: cannot access '$p': No such file or directory\n");
        st = 2;
        continue;
      }
      final node = (n ?? real)!;
      if (node.isDir && !opts.has('d')) {
        dirs.add((p, node));
      } else if (real != null && real.isDir && !long && !opts.has('d')) {
        dirs.add((p, real));
      } else {
        files.add((p, node));
      }
    }
    String fmtSize(int s) {
      if (!opts.has('h') || s < 1024) return '$s';
      final units = ['K', 'M', 'G'];
      var v = s / 1024;
      var u = 0;
      while (v >= 1024 && u < 2) {
        v /= 1024;
        u++;
      }
      return v < 10 ? '${(v * 10).ceil() / 10}${units[u]}' : '${v.ceil()}${units[u]}';
    }

    String time(VNode n) {
      final m = n.mtime % 60, h = 9 + (n.mtime ~/ 60) % 14;
      return 'Nov  8 ${'$h'.padLeft(2, '0')}:${'$m'.padLeft(2, '0')}';
    }

    void listing(List<(String, VNode)> entries, {bool total = false}) {
      var sorted = List.of(entries);
      if (opts.has('t')) sorted.sort((x, y) => y.$2.mtime.compareTo(x.$2.mtime));
      if (opts.has('S')) sorted.sort((x, y) => y.$2.size.compareTo(x.$2.size));
      if (opts.has('r')) sorted = sorted.reversed.toList();
      if (long) {
        if (total) {
          var blocks = 0;
          for (final (_, n) in sorted) {
            blocks += n.isDir ? 4 : ((n.size + 4095) ~/ 4096) * 4;
          }
          o.write('total $blocks\n');
        }
        final w = sorted.fold<int>(1, (m, x) => math.max(m, fmtSize(x.$2.size).length));
        final lw = sorted.fold<int>(1, (m, x) => math.max(m, '${x.$2.isDir ? 2 + x.$2.kids.values.where((k) => k.isDir).length : 1}'.length));
        for (final (name, n) in sorted) {
          final links = n.isDir ? 2 + n.kids.values.where((k) => k.isDir).length : 1;
          final owner = opts.has('n') ? (n.owner == Vfs.user ? '1000' : '0') : n.owner;
          o.write('${Vfs.modeString(n)} ${'$links'.padLeft(lw)} $owner${opts.has('g') ? '' : ' $owner'} ${fmtSize(n.size).padLeft(w)} ${time(n)} $name${n.isLink ? ' -> ${n.data}' : ''}\n');
        }
      } else if (o.tty && !opts.has('1')) {
        if (sorted.isNotEmpty) o.write('${sorted.map((x) => x.$1).join('  ')}\n');
      } else {
        for (final (name, _) in sorted) {
          o.write('$name\n');
        }
      }
    }

    files.sort((x, y) => x.$1.compareTo(y.$1));
    dirs.sort((x, y) => x.$1.compareTo(y.$1));
    listing(files);
    final multi = files.isNotEmpty || dirs.length > 1 || opts.has('R');
    var first = files.isEmpty;
    void dir(String label, VNode d) {
      if (!Vfs.may(d, 'r')) {
        e.write("ls: cannot open directory '$label': Permission denied\n");
        st = 2;
        return;
      }
      if (!first) o.write('\n');
      first = false;
      if (multi) o.write('$label:\n');
      final entries = <(String, VNode)>[
        if (all) ('.', d),
        if (all) ('..', d),
        for (final kv in d.kids.entries)
          if (!kv.key.startsWith('.') || all || almost) (kv.key, kv.value),
      ];
      listing(entries, total: true);
      if (opts.has('R')) {
        for (final kv in d.kids.entries) {
          if (kv.value.isDir && (!kv.key.startsWith('.') || all || almost)) dir(label.endsWith('/') ? '$label${kv.key}' : '$label/${kv.key}', kv.value);
        }
      }
    }

    for (final (p, d) in dirs) {
      dir(p, d);
    }
    return st;
  }

  static int _find(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    var k = 0;
    final roots = <String>[];
    while (k < a.length && !a[k].startsWith('-') && a[k] != '!' && a[k] != '(') {
      roots.add(a[k++]);
    }
    if (roots.isEmpty) roots.add('.');
    final expr = a.sublist(k);
    var maxDepth = 1 << 30, minDepth = 0;
    // -maxdepth / -mindepth anywhere
    final cleaned = <String>[];
    for (var j = 0; j < expr.length; j++) {
      if (expr[j] == '-maxdepth' && j + 1 < expr.length) {
        maxDepth = int.tryParse(expr[++j]) ?? maxDepth;
      } else if (expr[j] == '-mindepth' && j + 1 < expr.length) {
        minDepth = int.tryParse(expr[++j]) ?? minDepth;
      } else {
        cleaned.add(expr[j]);
      }
    }
    final pred = _FindExpr(sh, c, cleaned, o, e);
    var st = 0;
    for (final r in roots) {
      final n = sh.fs.lookup(r, c.cwd, follow: false) ?? sh.fs.lookup(r, c.cwd);
      if (n == null) {
        e.write("find: '$r': No such file or directory\n");
        st = 1;
        continue;
      }
      final startNode = n.isLink ? (sh.fs.lookup(r, c.cwd) ?? n) : n;
      final items = <(String, VNode, int)>[];
      void walk(String path, VNode node, int depth) {
        items.add((path, node, depth));
        if (node.isDir && depth < maxDepth) {
          if (!Vfs.may(node, 'r') || !Vfs.may(node, 'x')) {
            e.write("find: '$path': Permission denied\n");
            st = 1;
            return;
          }
          for (final kv in node.kids.entries) {
            walk(path.endsWith('/') ? '$path${kv.key}' : '$path/${kv.key}', kv.value, depth + 1);
          }
        }
      }

      walk(r, startNode, 0);
      for (final (path, node, depth) in items) {
        if (depth < minDepth) continue;
        pred.eval(path, node);
      }
      // -delete runs children first
      for (final p in pred.toDelete.reversed) {
        try {
          sh.fs.remove(p, c.cwd);
        } on ShError catch (x) {
          e.write('find: ${x.message}\n');
        }
      }
      pred.toDelete.clear();
    }
    return st;
  }

  static int _grep(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'emABC', long: {
      'ignore-case': 'i',
      'invert-match': 'v',
      'count': 'c',
      'line-number': 'n',
      'files-with-matches': 'l',
      'recursive': 'r',
      'word-regexp': 'w',
      'line-regexp': 'x',
      'only-matching': 'o',
      'extended-regexp': 'E',
      'fixed-strings': 'F',
      'quiet': 'q',
      'silent': 'q',
      'no-filename': 'h',
      'with-filename': 'H',
      'files-without-match': 'L',
      'max-count': 'm',
    });
    final pats = <String>[...?opts.values['e']];
    final rest = List.of(opts.rest);
    if (pats.isEmpty) {
      if (rest.isEmpty) throw ShError('Usage: grep [OPTION]... PATTERNS [FILE]...', 2);
      pats.add(rest.removeAt(0));
    }
    final res = [
      for (final p in pats.expand((p) => p.split('\n')))
        posixRegex(p, ere: opts.has('E'), icase: opts.has('i'), fixed: opts.has('F'), word: opts.has('w'), line: opts.has('x')),
    ];
    final rec = opts.has('r') || opts.has('R');
    final files = <String>[];
    var st = 1;
    var errs = false;
    if (rest.isEmpty && rec) rest.add('.');
    for (final f in rest) {
      final n = sh.fs.lookup(f, c.cwd);
      if (n != null && n.isDir) {
        if (!rec) {
          e.write('grep: $f: Is a directory\n');
          errs = true;
          continue;
        }
        for (final (p, x, _) in sh.fs.walk(f == '.' && !f.endsWith('/') ? '.' : f, n)) {
          if (x.isFile) files.add(p);
        }
        continue;
      }
      files.add(f);
    }
    final showName = opts.has('H') || (!opts.has('h') && (files.length > 1 || rec));
    final maxCount = int.tryParse(opts.value('m') ?? '');
    Iterable<(String, String)> inputs() sync* {
      if (rest.isEmpty) {
        yield ('(standard input)', i.readAll());
        return;
      }
      for (final f in files) {
        String text;
        try {
          text = f == '-' ? i.readAll() : sh.fs.read(f, c.cwd);
        } on ShError catch (x) {
          e.write('grep: ${x.message}\n');
          errs = true;
          continue;
        }
        yield (f, text);
      }
    }

    for (final (name, text) in inputs()) {
      var count = 0;
      final lines = textLines(text);
      final buf = StringBuffer();
      for (var ln = 0; ln < lines.length; ln++) {
        final line = lines[ln];
        final hit = res.any((r) => r.hasMatch(line));
        if (hit == opts.has('v')) continue;
        count++;
        if (opts.has('q') || opts.has('l') || opts.has('L') || opts.has('c')) {
          if (maxCount != null && count >= maxCount) break;
          continue;
        }
        final pre = '${showName ? '$name:' : ''}${opts.has('n') ? '${ln + 1}:' : ''}';
        if (opts.has('o') && !opts.has('v')) {
          final ms = <Match>[for (final r in res) ...r.allMatches(line)]..sort((x, y) => x.start.compareTo(y.start));
          var last = -1;
          for (final m in ms) {
            if (m.start < last || m.end == m.start) continue;
            buf.write('$pre${m[0]}\n');
            last = m.end;
          }
        } else {
          buf.write('$pre$line\n');
        }
        if (maxCount != null && count >= maxCount) break;
      }
      if (count > 0) st = 0;
      if (opts.has('q')) {
        if (count > 0) return 0;
        continue;
      }
      if (opts.has('l')) {
        if (count > 0) o.write('$name\n');
      } else if (opts.has('L')) {
        if (count == 0) o.write('$name\n');
      } else if (opts.has('c')) {
        o.write('${showName ? '$name:' : ''}$count\n');
      } else {
        o.write(buf.toString());
      }
    }
    return errs && st != 0 ? 2 : st;
  }

  static int _wc(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'lines': 'l', 'words': 'w', 'bytes': 'c', 'chars': 'm'});
    var which = [if (opts.has('l')) 'l', if (opts.has('w')) 'w', if (opts.has('m')) 'm', if (opts.has('c')) 'c'];
    if (which.isEmpty) which = ['l', 'w', 'c'];
    final rows = <(List<int>, String?)>[];
    var st = 0;
    List<int> count(String t) => [
          for (final k in which)
            switch (k) {
              'l' => '\n'.allMatches(t).length,
              'w' => t.split(RegExp(r'\s+')).where((x) => x.isNotEmpty).length,
              'm' => t.runes.length,
              _ => VNode.file(t, 0, '', 0).size,
            },
        ];
    if (opts.rest.isEmpty) {
      rows.add((count(i.readAll()), null));
    } else {
      for (final f in opts.rest) {
        try {
          final n = sh.fs.lookup(f, c.cwd);
          if (n != null && n.isDir) {
            e.write('wc: $f: Is a directory\n');
            rows.add(([for (final _ in which) 0], f));
            st = 1;
            continue;
          }
          rows.add((count(f == '-' ? i.readAll() : sh.fs.read(f, c.cwd)), f));
        } on ShError catch (x) {
          e.write('wc: ${x.message}\n');
          st = 1;
        }
      }
      if (rows.length > 1) rows.add(([for (var k = 0; k < which.length; k++) rows.fold<int>(0, (s, r) => s + r.$1[k])], 'total'));
    }
    final single = which.length == 1 && rows.length == 1;
    var width = 1;
    if (!single) {
      if (opts.rest.isEmpty) {
        width = 7;
      } else {
        for (final r in rows) {
          for (final v in r.$1) {
            width = math.max(width, '$v'.length);
          }
        }
      }
    }
    for (final (vals, name) in rows) {
      o.write('${vals.map((v) => '$v'.padLeft(width)).join(' ')}${name == null ? '' : ' $name'}\n');
    }
    return st;
  }

  static int _headTail(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e, bool head) {
    final opts = Opts(a, withValue: 'nc', long: {'lines': 'n', 'bytes': 'c'}, numberFlag: true);
    final nStr = opts.value('n') ?? '10';
    final cStr = opts.value('c');
    final files = opts.rest;
    var st = 0;
    void one(String text) {
      if (cStr != null) {
        final n = int.tryParse(cStr.replaceFirst('+', '')) ?? 0;
        if (head) {
          o.write(text.substring(0, math.min(n, text.length)));
        } else {
          o.write(cStr.startsWith('+') ? text.substring(math.min(text.length, math.max(0, n - 1))) : text.substring(math.max(0, text.length - n)));
        }
        return;
      }
      final lines = textLines(text);
      final fromStart = nStr.startsWith('+');
      final neg = nStr.startsWith('-');
      final n = int.tryParse(nStr.replaceFirst(RegExp(r'^[+-]'), '')) ?? (throw ShError("invalid number of lines: '$nStr'"));
      List<String> sel;
      if (head) {
        sel = neg ? lines.sublist(0, math.max(0, lines.length - n)) : lines.sublist(0, math.min(n, lines.length));
      } else {
        sel = fromStart ? lines.sublist(math.min(lines.length, math.max(0, n - 1))) : lines.sublist(math.max(0, lines.length - n));
      }
      final keepNoNl = sel.isNotEmpty && !text.endsWith('\n') && (head ? sel.length == lines.length : true);
      final out = joinLines(sel);
      o.write(keepNoNl ? out.substring(0, out.length - 1) : out);
    }

    if (files.isEmpty) {
      one(i.readAll());
      return 0;
    }
    for (final (k, f) in files.indexed) {
      try {
        final text = f == '-' ? i.readAll() : sh.fs.read(f, c.cwd);
        if (files.length > 1) o.write('${k > 0 ? '\n' : ''}==> $f <==\n');
        one(text);
      } on ShError catch (x) {
        e.write('${head ? 'head' : 'tail'}: cannot open \'$f\' for reading: ${x.message.split(': ').last}\n');
        st = 1;
      }
    }
    return st;
  }

  static int _sort(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'tko', long: {'numeric-sort': 'n', 'reverse': 'r', 'unique': 'u', 'ignore-case': 'f', 'field-separator': 't', 'key': 'k', 'human-numeric-sort': 'h', 'output': 'o'});
    final (text, st) = _readInputs(sh, c, opts.rest, i, e, 'sort');
    final lines = textLines(text);
    final sep = opts.value('t');
    final keys = <(int, int, bool, bool)>[]; // start field, end field, numeric, reverse
    for (final k in opts.values['k'] ?? const <String>[]) {
      final m = RegExp(r'^(\d+)(?:\.\d+)?([a-zA-Z]*)(?:,(\d+)(?:\.\d+)?([a-zA-Z]*))?$').firstMatch(k);
      if (m == null) throw ShError('invalid number at field start: invalid count at start of \'$k\'');
      final mods = '${m[2]}${m[4] ?? ''}';
      keys.add((int.parse(m[1]!), m[3] == null ? 1 << 20 : int.parse(m[3]!), mods.contains('n') || mods.contains('h'), mods.contains('r')));
    }
    List<String> fields(String l) {
      if (sep != null) return l.split(sep);
      // blank-separated, each field keeps its leading blanks
      final out = <String>[];
      final m = RegExp(r'\s*\S+').allMatches(l);
      for (final x in m) {
        out.add(x[0]!);
      }
      return out;
    }

    String keyText(String l, int s, int en) {
      final f = fields(l);
      if (s > f.length) return '';
      final end = math.min(en, f.length);
      return f.sublist(s - 1, end).join(sep ?? '');
    }

    num numOf(String s) {
      final m = RegExp(r'^\s*(-?\d+(?:\.\d+)?)([KMGT]?)').firstMatch(s);
      if (m == null) return 0;
      final v = num.parse(m[1]!);
      return switch (m[2]) { 'K' => v * 1e3, 'M' => v * 1e6, 'G' => v * 1e9, 'T' => v * 1e12, _ => v };
    }

    final numeric = opts.has('n') || opts.has('h');
    final fold = opts.has('f');
    int cmpText(String x, String y) => fold ? x.toUpperCase().compareTo(y.toUpperCase()) : x.compareTo(y);
    int cmp(String x, String y) {
      if (keys.isNotEmpty) {
        for (final (s, en, n, r) in keys) {
          final kx = keyText(x, s, en), ky = keyText(y, s, en);
          var d = (n || numeric) ? numOf(kx).compareTo(numOf(ky)) : cmpText(sep == null ? kx.trimLeft() : kx, sep == null ? ky.trimLeft() : ky);
          if (r) d = -d;
          if (d != 0) return d;
        }
        if (opts.has('u')) return 0;
        return x.compareTo(y);
      }
      if (numeric) {
        final d = numOf(x).compareTo(numOf(y));
        if (d != 0 || opts.has('u')) return d;
        return x.compareTo(y);
      }
      final d = cmpText(x, y);
      if (d != 0 || opts.has('u')) return d;
      return x.compareTo(y);
    }

    final idx = List.generate(lines.length, (k) => k);
    idx.sort((p, q) {
      final d = cmp(lines[p], lines[q]);
      return d != 0 ? (opts.has('r') ? -d : d) : p.compareTo(q);
    });
    var sorted = [for (final k in idx) lines[k]];
    if (opts.has('u')) {
      final u = <String>[];
      for (final l in sorted) {
        if (u.isEmpty || cmp(u.last, l) != 0) u.add(l);
      }
      sorted = u;
    }
    final outFile = opts.value('o');
    if (outFile != null) {
      sh.fs.write(outFile, c.cwd, joinLines(sorted));
    } else {
      o.write(joinLines(sorted));
    }
    return st;
  }

  static int _uniq(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'count': 'c', 'repeated': 'd', 'unique': 'u', 'ignore-case': 'i'});
    final files = opts.rest;
    final text = files.isEmpty || files[0] == '-' ? i.readAll() : sh.fs.read(files[0], c.cwd);
    final lines = textLines(text);
    final out = StringBuffer();
    var k = 0;
    while (k < lines.length) {
      var j = k + 1;
      while (j < lines.length && (opts.has('i') ? lines[j].toLowerCase() == lines[k].toLowerCase() : lines[j] == lines[k])) {
        j++;
      }
      final n = j - k;
      final show = opts.has('d') ? n > 1 : opts.has('u') ? n == 1 : true;
      if (show) out.write(opts.has('c') ? '${'$n'.padLeft(7)} ${lines[k]}\n' : '${lines[k]}\n');
      k = j;
    }
    if (files.length > 1) {
      sh.fs.write(files[1], c.cwd, out.toString());
    } else {
      o.write(out.toString());
    }
    return 0;
  }

  static List<bool Function(int)> _ranges(String list) {
    return [
      for (final part in list.split(','))
        () {
          final m = RegExp(r'^(\d*)(-?)(\d*)$').firstMatch(part);
          if (m == null || (m[1]!.isEmpty && m[3]!.isEmpty)) throw ShError("invalid field value '$part'");
          final a = m[1]!.isEmpty ? 1 : int.parse(m[1]!);
          if (m[2]!.isEmpty) return (int x) => x == a;
          final b = m[3]!.isEmpty ? 1 << 30 : int.parse(m[3]!);
          return (int x) => x >= a && x <= b;
        }(),
    ];
  }

  static int _cut(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, withValue: 'dfcb', long: {'delimiter': 'd', 'fields': 'f', 'characters': 'c', 'only-delimited': 's'});
    final (text, st) = _readInputs(sh, c, opts.rest, i, e, 'cut');
    final f = opts.value('f'), ch = opts.value('c') ?? opts.value('b');
    if (f == null && ch == null) throw ShError('you must specify a list of bytes, characters, or fields');
    final d = opts.value('d') ?? '\t';
    if (d.length != 1) throw ShError('the delimiter must be a single character');
    final sel = _ranges(f ?? ch!);
    bool want(int x) => sel.any((s) => s(x));
    final out = StringBuffer();
    for (final l in textLines(text)) {
      if (ch != null) {
        final cs = l.split('');
        out.write('${[for (var k = 0; k < cs.length; k++) if (want(k + 1)) cs[k]].join()}\n');
        continue;
      }
      if (!l.contains(d)) {
        if (!opts.has('s')) out.write('$l\n');
        continue;
      }
      final parts = l.split(d);
      out.write('${[for (var k = 0; k < parts.length; k++) if (want(k + 1)) parts[k]].join(d)}\n');
    }
    o.write(out.toString());
    return st;
  }

  static List<int> _trSet(String s) {
    final t = unescape(s);
    var x = t
        .replaceAll('[:lower:]', 'a-z')
        .replaceAll('[:upper:]', 'A-Z')
        .replaceAll('[:digit:]', '0-9')
        .replaceAll('[:alpha:]', 'a-zA-Z')
        .replaceAll('[:alnum:]', 'a-zA-Z0-9')
        .replaceAll('[:space:]', ' \t\n\r\f\v')
        .replaceAll('[:blank:]', ' \t')
        .replaceAll('[:punct:]', '!"#\$%&\'()*+,-./:;<=>?@[\\]^_`{|}~');
    final out = <int>[];
    final cs = x.runes.toList();
    for (var k = 0; k < cs.length; k++) {
      if (k + 2 < cs.length && cs[k + 1] == 45 /* - */ && cs[k + 2] >= cs[k]) {
        for (var v = cs[k]; v <= cs[k + 2]; v++) {
          out.add(v);
        }
        k += 2;
      } else {
        out.add(cs[k]);
      }
    }
    return out;
  }

  static int _tr(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final opts = Opts(a, long: {'delete': 'd', 'squeeze-repeats': 's', 'complement': 'c'});
    final sets = opts.rest;
    if (sets.isEmpty) throw ShError('missing operand');
    final text = i.readAll();
    final s1 = _trSet(sets[0]).toSet();
    bool inS1(int r) => opts.has('c') || opts.has('C') ? !s1.contains(r) : s1.contains(r);
    final out = StringBuffer();
    if (opts.has('d')) {
      final squeeze = sets.length > 1 && opts.has('s') ? _trSet(sets[1]).toSet() : <int>{};
      int? last;
      for (final r in text.runes) {
        if (inS1(r)) continue;
        if (squeeze.contains(r) && last == r) continue;
        out.writeCharCode(r);
        last = r;
      }
      o.write(out.toString());
      return 0;
    }
    if (sets.length == 1) {
      if (!opts.has('s')) throw ShError("missing operand after '${sets[0]}'");
      int? last;
      for (final r in text.runes) {
        if (inS1(r) && last == r) continue;
        out.writeCharCode(r);
        last = r;
      }
      o.write(out.toString());
      return 0;
    }
    final from = _trSet(sets[0]), to = _trSet(sets[1]);
    if (to.isEmpty) throw ShError('when not truncating set1, string2 must be non-empty');
    final map = <int, int>{};
    for (var k = 0; k < from.length; k++) {
      map[from[k]] = to[math.min(k, to.length - 1)];
    }
    int? last;
    final sq = opts.has('s') ? to.toSet() : <int>{};
    for (final r in text.runes) {
      int v;
      if (opts.has('c') || opts.has('C')) {
        v = s1.contains(r) ? r : to.last;
      } else {
        v = map[r] ?? r;
      }
      if (sq.contains(v) && last == v) continue;
      out.writeCharCode(v);
      last = v;
    }
    o.write(out.toString());
    return 0;
  }

  static int _sed(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final scripts = <String>[];
    var quiet = false, ere = false, inPlace = false;
    final files = <String>[];
    for (var k = 0; k < a.length; k++) {
      final x = a[k];
      if (x == '-n' || x == '--quiet') {
        quiet = true;
      } else if (x == '-E' || x == '-r') {
        ere = true;
      } else if (x == '-i' || x.startsWith('-i')) {
        inPlace = true;
      } else if (x == '-e' && k + 1 < a.length) {
        scripts.add(a[++k]);
      } else if (RegExp(r'^-[nEr]+$').hasMatch(x)) {
        if (x.contains('n')) quiet = true;
        if (x.contains('E') || x.contains('r')) ere = true;
      } else if (scripts.isEmpty && !x.startsWith('-')) {
        scripts.add(x);
      } else {
        files.add(x);
      }
    }
    if (scripts.isEmpty) throw ShError('no script specified', 1);
    final prog = SedProgram.parse(scripts.join('\n'), ere);
    if (inPlace) {
      for (final f in files) {
        sh.fs.write(f, c.cwd, prog.run(sh.fs.read(f, c.cwd), quiet));
      }
      return 0;
    }
    final (text, st) = _readInputs(sh, c, files, i, e, 'sed');
    o.write(prog.run(text, quiet));
    return st;
  }

  static int _diff(Shell sh, ShCtx c, List<String> a, ShIn i, Sink o, Sink e) {
    final files = a.where((x) => !x.startsWith('-')).toList();
    if (files.length < 2) throw ShError('missing operand', 2);
    final x = textLines(files[0] == '-' ? i.readAll() : sh.fs.read(files[0], c.cwd));
    final y = textLines(files[1] == '-' ? i.readAll() : sh.fs.read(files[1], c.cwd));
    // LCS table
    final n = x.length, m = y.length;
    final t = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (var p = n - 1; p >= 0; p--) {
      for (var q = m - 1; q >= 0; q--) {
        t[p][q] = x[p] == y[q] ? t[p + 1][q + 1] + 1 : math.max(t[p + 1][q], t[p][q + 1]);
      }
    }
    var p = 0, q = 0;
    var differ = false;
    String rng(int s, int en) => s == en ? '$s' : '$s,$en';
    while (p < n || q < m) {
      if (p < n && q < m && x[p] == y[q]) {
        p++;
        q++;
        continue;
      }
      final p0 = p, q0 = q;
      while ((p < n || q < m) && !(p < n && q < m && x[p] == y[q])) {
        if (q >= m || (p < n && t[p + 1][q] >= t[p][q + 1])) {
          p++;
        } else {
          q++;
        }
      }
      differ = true;
      final del = p - p0, add = q - q0;
      if (del > 0 && add > 0) {
        o.write('${rng(p0 + 1, p)}c${rng(q0 + 1, q)}\n');
      } else if (del > 0) {
        o.write('${rng(p0 + 1, p)}d$q0\n');
      } else {
        o.write('${p0}a${rng(q0 + 1, q)}\n');
      }
      for (var k = p0; k < p; k++) {
        o.write('< ${x[k]}\n');
      }
      if (del > 0 && add > 0) o.write('---\n');
      for (var k = q0; k < q; k++) {
        o.write('> ${y[k]}\n');
      }
    }
    return differ ? 1 : 0;
  }
}

/// test / [ ]: unary and binary tests, ! -a -o and parentheses.
class _TestEval {
  final Shell sh;
  final ShCtx c;
  final List<String> a;
  int k = 0;
  _TestEval(this.sh, this.c, this.a);

  bool run() {
    if (a.isEmpty) return false;
    final v = _or();
    if (k < a.length) throw ShError('too many arguments');
    return v;
  }

  bool _or() {
    var v = _and();
    while (k < a.length && a[k] == '-o') {
      k++;
      final r = _and();
      v = v || r;
    }
    return v;
  }

  bool _and() {
    var v = _not();
    while (k < a.length && a[k] == '-a') {
      k++;
      final r = _not();
      v = v && r;
    }
    return v;
  }

  bool _not() {
    if (k < a.length && a[k] == '!' && k + 1 < a.length) {
      k++;
      return !_not();
    }
    return _prim();
  }

  static const _bin = {'=', '==', '!=', '-eq', '-ne', '-lt', '-le', '-gt', '-ge', '-nt', '-ot', '<', '>'};

  bool _prim() {
    if (k >= a.length) throw ShError('argument expected');
    if (a[k] == '(') {
      k++;
      final v = _or();
      if (k >= a.length || a[k] != ')') throw ShError("')' expected");
      k++;
      return v;
    }
    if (k + 2 < a.length + 0 && k + 1 < a.length && _bin.contains(a[k + 1]) && k + 2 < a.length) {
      final l = a[k], op = a[k + 1], r = a[k + 2];
      k += 3;
      int n(String s) => int.tryParse(s.trim()) ?? (throw ShError('$s: integer expression expected'));
      return switch (op) {
        '=' || '==' => l == r,
        '!=' => l != r,
        '-eq' => n(l) == n(r),
        '-ne' => n(l) != n(r),
        '-lt' => n(l) < n(r),
        '-le' => n(l) <= n(r),
        '-gt' => n(l) > n(r),
        '-ge' => n(l) >= n(r),
        '<' => l.compareTo(r) < 0,
        '>' => l.compareTo(r) > 0,
        '-nt' => (sh.fs.lookup(l, c.cwd)?.mtime ?? -1) > (sh.fs.lookup(r, c.cwd)?.mtime ?? -1),
        _ => (sh.fs.lookup(l, c.cwd)?.mtime ?? 1 << 30) < (sh.fs.lookup(r, c.cwd)?.mtime ?? 1 << 30),
      };
    }
    final x = a[k];
    if (x.length == 2 && x.startsWith('-') && k + 1 < a.length && 'efdrwxszLhnp'.contains(x[1])) {
      final arg = a[k + 1];
      k += 2;
      if (x == '-z') return arg.isEmpty;
      if (x == '-n') return arg.isNotEmpty;
      final link = sh.fs.lookup(arg, c.cwd, follow: false);
      final n = sh.fs.lookup(arg, c.cwd);
      return switch (x[1]) {
        'e' => n != null,
        'f' => n != null && n.isFile,
        'd' => n != null && n.isDir,
        'r' => n != null && Vfs.may(n, 'r'),
        'w' => n != null && Vfs.may(n, 'w'),
        'x' => n != null && Vfs.may(n, 'x'),
        's' => n != null && n.size > 0 && !(n.isFile && n.data.isEmpty),
        'L' || 'h' => link != null && link.isLink,
        _ => false,
      };
    }
    k++;
    return x.isNotEmpty;
  }
}

/// find's expression: tests, actions, ! -a -o ( ).
class _FindExpr {
  final Shell sh;
  final ShCtx c;
  final List<String> a;
  final Sink o, e;
  final List<String> toDelete = [];
  late final bool hasAction = a.any((x) => const {'-print', '-exec', '-delete', '-ls', '-printf'}.contains(x));
  _FindExpr(this.sh, this.c, this.a, this.o, this.e);

  late String _path;
  late VNode _node;
  int k = 0;

  void eval(String path, VNode node) {
    _path = path;
    _node = node;
    k = 0;
    final v = a.isEmpty ? true : _or();
    if (v && !hasAction) o.write('$path\n');
  }

  bool _or() {
    var v = _and();
    while (k < a.length && (a[k] == '-o' || a[k] == '-or')) {
      k++;
      if (v) {
        _skipAnd();
      } else {
        v = _and();
      }
    }
    return v;
  }

  void _skipAnd() {
    // skip an operand without running its actions
    final saved = (_path, _node);
    var depth = 0;
    while (k < a.length) {
      final x = a[k];
      if (x == '(') depth++;
      if (x == ')') {
        if (depth == 0) return;
        depth--;
      }
      if ((x == '-o' || x == '-or') && depth == 0) return;
      if (x == '-exec') {
        while (k < a.length && a[k] != ';' && a[k] != '+') {
          k++;
        }
      }
      k++;
    }
    _path = saved.$1;
    _node = saved.$2;
  }

  bool _and() {
    var v = _not();
    while (k < a.length && a[k] != '-o' && a[k] != '-or' && a[k] != ')') {
      if (a[k] == '-a' || a[k] == '-and') k++;
      if (!v) {
        // skip the rest of this and-chain
        var depth = 0;
        while (k < a.length) {
          final x = a[k];
          if (x == '(') depth++;
          if (x == ')') {
            if (depth == 0) break;
            depth--;
          }
          if ((x == '-o' || x == '-or') && depth == 0) break;
          if (x == '-exec') {
            while (k < a.length && a[k] != ';' && a[k] != '+') {
              k++;
            }
          }
          k++;
        }
        return false;
      }
      v = _not();
    }
    return v;
  }

  bool _not() {
    if (k < a.length && (a[k] == '!' || a[k] == '-not')) {
      k++;
      return !_not();
    }
    return _prim();
  }

  String _arg() {
    if (k >= a.length) throw ShError("missing argument to `${a[k - 1]}'");
    return a[k++];
  }

  bool _prim() {
    final x = a[k++];
    final name = _path == '/' ? '/' : _path.replaceFirst(RegExp(r'/+$'), '').split('/').last;
    switch (x) {
      case '(':
        final v = _or();
        if (k < a.length && a[k] == ')') k++;
        return v;
      case '-name':
        return Shell.globRegex(_arg()).hasMatch(name);
      case '-iname':
        return RegExp(Shell.globRegex(_arg()).pattern, caseSensitive: false).hasMatch(name);
      case '-path':
      case '-wholename':
        return Shell.globRegex(_arg()).hasMatch(_path);
      case '-type':
        final t = _arg();
        return t == 'f' ? _node.isFile : t == 'd' ? _node.isDir : t == 'l' ? _node.isLink : false;
      case '-empty':
        return _node.isDir ? _node.kids.isEmpty : _node.isFile && _node.data.isEmpty;
      case '-perm':
        final p = _arg();
        // octal (644) or symbolic (o=x, u+rw,g+r), as GNU find: symbolic starts from 000
        final body = p.replaceFirst(RegExp(r'^[-/]'), '');
        final int want;
        try {
          want = Vfs.applyMode(0, body, false);
        } on ShError {
          throw ShError("invalid mode '$body'");
        }
        final m = _node.mode & 0xfff;
        if (p.startsWith('-')) return m & want == want;
        if (p.startsWith('/')) return m & want != 0;
        return m == want;
      case '-size':
        final s = _arg();
        final mm = RegExp(r'^([+-]?)(\d+)([ckMG]?)$').firstMatch(s);
        if (mm == null) throw ShError("invalid argument `$s' to `-size'");
        final unit = switch (mm[3]) { 'c' => 1, 'k' => 1024, 'M' => 1 << 20, 'G' => 1 << 30, _ => 512 };
        final size = _node.size;
        final n = int.parse(mm[2]!);
        final blocks = (size + unit - 1) ~/ unit;
        return mm[1] == '+' ? blocks > n : mm[1] == '-' ? blocks < n : blocks == n;
      case '-user':
        return _node.owner == _arg();
      case '-newer':
        final other = sh.fs.lookup(_arg(), c.cwd);
        return other != null && _node.mtime > other.mtime;
      case '-executable':
        return Vfs.may(_node, 'x');
      case '-readable':
        return Vfs.may(_node, 'r');
      case '-writable':
        return Vfs.may(_node, 'w');
      case '-true':
        return true;
      case '-false':
        return false;
      case '-print':
        o.write('$_path\n');
        return true;
      case '-ls':
        o.write('${Vfs.modeString(_node)} ${_node.owner} ${_node.size} $_path\n');
        return true;
      case '-delete':
        toDelete.add(_path);
        return true;
      case '-exec':
        final cmd = <String>[];
        while (k < a.length && a[k] != ';' && a[k] != '+') {
          cmd.add(a[k++]);
        }
        if (k >= a.length) throw ShError("missing argument to `-exec'");
        k++;
        if (cmd.isEmpty) throw ShError("missing argument to `-exec'");
        return sh.runCommand([for (final w in cmd) w.replaceAll('{}', _path)], c, ShIn.empty, o, e) == 0;
      default:
        throw ShError("unknown predicate `$x'");
    }
  }
}

/// sed: addresses (n, \$, /re/, a,b, first~step) and s, d, p, q, y, =, a, i, c.
class SedProgram {
  final List<_SedCmd> _cmds;
  SedProgram._(this._cmds);

  static SedProgram parse(String src, bool ere) {
    final cmds = <_SedCmd>[];
    var i = 0;
    String? readDelim(String d) {
      final b = StringBuffer();
      while (i < src.length && src[i] != d) {
        if (src[i] == '\\' && i + 1 < src.length) {
          if (src[i + 1] == d) {
            b.write(d);
          } else if (src[i + 1] == 'n') {
            b.write('\\n');
          } else {
            b.write(src[i]);
            b.write(src[i + 1]);
          }
          i += 2;
          continue;
        }
        b.write(src[i++]);
      }
      if (i >= src.length) return null;
      i++;
      return b.toString();
    }

    _SedAddr? addr() {
      if (i >= src.length) return null;
      if (src[i] == r'$') {
        i++;
        return _SedAddr.last();
      }
      final m = RegExp(r'(\d+)(?:~(\d+))?').matchAsPrefix(src, i);
      if (m != null) {
        i = m.end;
        return m[2] != null ? _SedAddr.step(int.parse(m[1]!), int.parse(m[2]!)) : _SedAddr.line(int.parse(m[1]!));
      }
      if (src[i] == '/' || src[i] == '\\') {
        final d = src[i] == '\\' ? src[i + 1] : '/';
        i += src[i] == '\\' ? 2 : 1;
        final re = readDelim(d);
        if (re == null) throw ShError('-e expression #1: unterminated address regex');
        var icase = false;
        if (i < src.length && src[i] == 'I') {
          icase = true;
          i++;
        }
        return _SedAddr.re(posixRegex(re, ere: ere, icase: icase));
      }
      return null;
    }

    while (i < src.length) {
      while (i < src.length && (src[i] == ' ' || src[i] == '\n' || src[i] == ';' || src[i] == '\t')) {
        i++;
      }
      if (i >= src.length) break;
      final a1 = addr();
      _SedAddr? a2;
      if (a1 != null && i < src.length && src[i] == ',') {
        i++;
        a2 = addr();
        if (a2 == null) throw ShError('-e expression #1: unexpected `,\'');
      }
      while (i < src.length && src[i] == ' ') {
        i++;
      }
      var neg = false;
      if (i < src.length && src[i] == '!') {
        neg = true;
        i++;
      }
      if (i >= src.length) throw ShError('-e expression #1: missing command');
      final cmd = src[i++];
      final c = _SedCmd(cmd, a1, a2, neg);
      switch (cmd) {
        case 's':
          final d = src[i++];
          final re = readDelim(d);
          final rep = readDelim(d);
          if (re == null || rep == null) throw ShError("-e expression #1: unterminated `s' command");
          var flags = '';
          while (i < src.length && RegExp(r'[gpiI0-9]').hasMatch(src[i])) {
            flags += src[i++];
          }
          c.re = posixRegex(re, ere: ere, icase: flags.contains('i') || flags.contains('I'));
          c.text = rep;
          c.flags = flags;
        case 'y':
          final d = src[i++];
          final from = readDelim(d), to = readDelim(d);
          if (from == null || to == null || from.length != to.length) throw ShError("-e expression #1: strings for `y' command are different lengths");
          c.text = from;
          c.flags = to;
        case 'a':
        case 'i':
        case 'c':
          var t = src.substring(i);
          final nl = t.indexOf('\n');
          if (nl >= 0) t = t.substring(0, nl);
          i += t.length;
          c.text = t.replaceFirst(RegExp(r'^\\?\s*'), '').replaceFirst(RegExp(r'^\\'), '');
        case 'd':
        case 'p':
        case 'q':
        case '=':
        case 'n':
        case 'N':
        case 'P':
        case 'D':
          break;
        case '{':
        case '}':
          throw ShError('-e expression #1: { } nu sunt acceptate aici');
        default:
          throw ShError("-e expression #1: unknown command: `$cmd'");
      }
      cmds.add(c);
    }
    return SedProgram._(cmds);
  }

  String run(String text, bool quiet) {
    final lines = textLines(text);
    final out = StringBuffer();
    for (final c in _cmds) {
      c.active = false;
    }
    for (var n = 0; n < lines.length; n++) {
      var line = lines[n];
      var deleted = false;
      final after = <String>[];
      var quit = false;
      for (final c in _cmds) {
        if (!c.matches(n + 1, line, n == lines.length - 1)) continue;
        switch (c.cmd) {
          case 's':
            line = c.subst(line);
            if (c.flags.contains('p') && c.lastSubst) out.write('$line\n');
          case 'y':
            final b = StringBuffer();
            for (final ch in line.split('')) {
              final k = c.text.indexOf(ch);
              b.write(k < 0 ? ch : c.flags[k]);
            }
            line = b.toString();
          case 'd':
            deleted = true;
          case 'p':
            out.write('$line\n');
          case '=':
            out.write('${n + 1}\n');
          case 'a':
            after.add(c.text);
          case 'i':
            out.write('${c.text}\n');
          case 'c':
            if (c.a2 == null || !c.active) out.write('${c.text}\n');
            deleted = true;
          case 'q':
            quit = true;
        }
        if (deleted || quit) break;
      }
      if (!deleted && !quiet) out.write('$line\n');
      for (final x in after) {
        out.write('$x\n');
      }
      if (quit) break;
    }
    return out.toString();
  }
}

class _SedAddr {
  final int kind; // 0 line, 1 last, 2 regex, 3 step
  final int n, step;
  final RegExp? re;
  _SedAddr.line(this.n) : kind = 0, step = 0, re = null;
  _SedAddr.last() : kind = 1, n = 0, step = 0, re = null;
  _SedAddr.re(this.re) : kind = 2, n = 0, step = 0;
  _SedAddr.step(this.n, this.step) : kind = 3, re = null;

  bool hit(int line, String text, bool last) => switch (kind) {
        0 => line == n,
        1 => last,
        2 => re!.hasMatch(text),
        _ => step == 0 ? line == n : line >= n && (line - n) % step == 0,
      };
}

class _SedCmd {
  final String cmd;
  final _SedAddr? a1, a2;
  final bool neg;
  RegExp? re;
  String text = '';
  String flags = '';
  bool active = false;
  bool lastSubst = false;
  _SedCmd(this.cmd, this.a1, this.a2, this.neg);

  bool matches(int line, String t, bool last) {
    bool m;
    if (a1 == null) {
      m = true;
    } else if (a2 == null) {
      m = a1!.hit(line, t, last);
    } else if (active) {
      m = true;
      if (a2!.kind == 0 ? line >= a2!.n : a2!.hit(line, t, last)) active = false;
    } else if (a1!.hit(line, t, last)) {
      m = true;
      active = !(a2!.kind == 0 && a2!.n <= line);
    } else {
      m = false;
    }
    return neg ? !m : m;
  }

  String subst(String line) {
    final all = flags.contains('g');
    final nth = int.tryParse(flags.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    var count = 0;
    lastSubst = false;
    final b = StringBuffer();
    var last = 0;
    for (final m in re!.allMatches(line)) {
      count++;
      if (!all && count != nth) continue;
      if (all && count < nth) continue;
      b.write(line.substring(last, m.start));
      b.write(_rep(m));
      last = m.end;
      lastSubst = true;
      if (!all) break;
    }
    b.write(line.substring(last));
    return b.toString();
  }

  String _rep(Match m) {
    final b = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final c = text[i];
      if (c == '\\' && i + 1 < text.length) {
        final n = text[++i];
        if (RegExp(r'[0-9]').hasMatch(n)) {
          final g = int.parse(n);
          b.write(g <= m.groupCount ? (m.group(g) ?? '') : '');
        } else if (n == 'n') {
          b.write('\n');
        } else if (n == 't') {
          b.write('\t');
        } else {
          b.write(n);
        }
      } else if (c == '&') {
        b.write(m[0]);
      } else {
        b.write(c);
      }
    }
    return b.toString();
  }
}
