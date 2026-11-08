// =============================================================================
// BASH, PARSED: words with their quoting, and the command tree
//   Enough of bash for USO: pipes, && ||, ; and newlines, redirections (> >>
//   < 2> 2>&1 &> >&2 << <<<), quotes, $VAR ${...} $(...) `...` $((...)),
//   if / for / while / until / case / { } / ( ) / functions, comments.
// =============================================================================

import 'vfs.dart' show ShError;

/// A piece of a word: literal text, or something expanded when it runs.
enum PartKind { lit, varRef, param, cmd, arith }

class WPart {
  final PartKind kind;
  final String text;
  final int quote; // 0 unquoted, 1 '...', 2 "..."
  const WPart(this.kind, this.text, this.quote);
  @override
  String toString() => '${kind.name}${quote == 0 ? '' : quote == 1 ? "'" : '"'}($text)';
}

class Word {
  final List<WPart> parts;
  const Word(this.parts);

  /// The word as plain text, if it is only unquoted literal text.
  String? get plain => parts.length == 1 && parts[0].kind == PartKind.lit && parts[0].quote == 0 ? parts[0].text : null;

  bool get quoted => parts.any((p) => p.quote != 0);

  /// The literal text, quotes removed (for heredoc delimiters, case patterns of plain words...).
  String get literal => parts.map((p) => p.text).join();

  @override
  String toString() => parts.join('+');
}

class Tok {
  final String? op; // an operator, or '\n'
  final Word? word;
  const Tok.op(this.op) : word = null;
  const Tok.word(this.word) : op = null;
  bool isOp(String o) => op == o;
  bool isWord(String w) => word != null && word!.plain == w;
  @override
  String toString() => op != null ? (op == '\n' ? 'NL' : 'OP($op)') : 'W($word)';
}

class Redir {
  final int fd; // 0, 1, 2; -1: both 1 and 2 (&>)
  final String op; // '>', '>>', '<', '>&' (dup), '<<' (heredoc), '<<<'
  final Word? target;
  final int dupTo; // for '>&'
  String? heredoc; // the body of a heredoc
  bool heredocExpands = true;
  Redir(this.fd, this.op, this.target, {this.dupTo = -1});
}

sealed class Node {}

class NSimple extends Node {
  final List<(String, Word)> assigns;
  final List<Word> words;
  final List<Redir> redirs;
  NSimple(this.assigns, this.words, this.redirs);
}

class NPipe extends Node {
  final List<Node> cmds;
  final bool bang;
  NPipe(this.cmds, this.bang);
}

class NAndOr extends Node {
  final Node first;
  final List<(String, Node)> rest;
  NAndOr(this.first, this.rest);
}

class NList extends Node {
  final List<Node> items;
  NList(this.items);
}

class NIf extends Node {
  final List<(Node, Node)> branches;
  final Node? orElse;
  NIf(this.branches, this.orElse);
}

class NFor extends Node {
  final String name;
  final List<Word>? items;
  final Node body;
  NFor(this.name, this.items, this.body);
}

class NWhile extends Node {
  final Node cond;
  final Node body;
  final bool until;
  NWhile(this.cond, this.body, this.until);
}

class NCase extends Node {
  final Word subject;
  final List<(List<Word>, Node)> arms;
  NCase(this.subject, this.arms);
}

class NGroup extends Node {
  final Node body;
  final bool subshell;
  NGroup(this.body, this.subshell);
}

class NFunc extends Node {
  final String name;
  final Node body;
  NFunc(this.name, this.body);
}

class NRedirected extends Node {
  final Node inner;
  final List<Redir> redirs;
  NRedirected(this.inner, this.redirs);
}

/// More input is needed (an open quote, `if` without `fi`...).
class ShIncomplete implements Exception {}

// ---------------------------------------------------------------- lexer
class Lexer {
  final String s;
  int i = 0;
  final List<Tok> out = [];
  final List<Redir> _pendingHeredocs = [];

  Lexer(this.s);

  static List<Tok> lex(String s) => (Lexer(s)..run()).out;

  /// The `$...` form (or backquote) at [at] in [s], and where it ends; null if it's a plain `$`.
  static (WPart, int)? dollarAt(String s, int at) {
    final lx = Lexer(s)..i = at;
    final p = lx._dollar(2);
    return p == null ? null : (p, lx.i);
  }

  bool get _end => i >= s.length;
  String get _c => s[i];

  void run() {
    while (!_end) {
      final c = _c;
      if (c == ' ' || c == '\t') {
        i++;
      } else if (c == '\\' && i + 1 < s.length && s[i + 1] == '\n') {
        i += 2;
      } else if (c == '#') {
        while (!_end && _c != '\n') {
          i++;
        }
      } else if (c == '\n') {
        i++;
        out.add(const Tok.op('\n'));
        _readHeredocs();
      } else if (_opStart(c)) {
        _op();
      } else {
        _word();
      }
    }
    if (_pendingHeredocs.isNotEmpty) throw ShIncomplete();
  }

  static bool _opStart(String c) => '|&;<>()'.contains(c);

  void _op() {
    final rest = s.substring(i);
    for (final o in ['&>>', '&>', '>>', '>&', '<<<', '<<-', '<<', '&&', '||', ';;', '|', '&', ';', '<', '>', '(', ')']) {
      if (rest.startsWith(o)) {
        i += o.length;
        if (o == '<<' || o == '<<-') {
          _heredocStart(o == '<<-');
        } else {
          out.add(Tok.op(o));
        }
        return;
      }
    }
  }

  void _heredocStart(bool strip) {
    while (!_end && (_c == ' ' || _c == '\t')) {
      i++;
    }
    final w = _readWord();
    if (w == null) throw ShError('syntax error near unexpected token `newline\'', 2);
    final r = Redir(0, '<<', w)..heredocExpands = !w.quoted;
    if (strip) r.heredoc = '\u0000strip';
    _pendingHeredocs.add(r);
    out.add(Tok.op('<<'));
    out.add(Tok.word(Word([WPart(PartKind.lit, '\u0001heredoc${_heredocs.length}', 1)])));
    _heredocs.add(r);
  }

  final List<Redir> _heredocs = [];
  List<Redir> get heredocs => _heredocs;

  void _readHeredocs() {
    for (final r in _pendingHeredocs) {
      final strip = r.heredoc == '\u0000strip';
      final delim = r.target!.literal;
      final body = StringBuffer();
      var found = false;
      while (!_end) {
        final nl = s.indexOf('\n', i);
        final line = nl < 0 ? s.substring(i) : s.substring(i, nl);
        i = nl < 0 ? s.length : nl + 1;
        final l = strip ? line.replaceFirst(RegExp(r'^\t+'), '') : line;
        if (l == delim) {
          found = true;
          break;
        }
        body.writeln(l);
      }
      if (!found) throw ShIncomplete();
      r.heredoc = body.toString();
    }
    _pendingHeredocs.clear();
  }

  void _word() {
    // a fd number before a redirection: 2> 2>> 2>&1
    if ((_c == '1' || _c == '2' || _c == '0') && i + 1 < s.length && (s[i + 1] == '>' || s[i + 1] == '<')) {
      final fd = _c;
      i++;
      out.add(Tok.op('fd$fd'));
      return;
    }
    final w = _readWord();
    if (w != null) out.add(Tok.word(w));
  }

  Word? _readWord() {
    final parts = <WPart>[];
    final lit = StringBuffer();
    void flush([int q = 0]) {
      if (lit.isNotEmpty) {
        parts.add(WPart(PartKind.lit, lit.toString(), q));
        lit.clear();
      }
    }

    var any = false;
    while (!_end) {
      final c = _c;
      if (c == ' ' || c == '\t' || c == '\n' || _opStart(c)) break;
      any = true;
      if (c == '\\') {
        i++;
        if (_end) break;
        if (_c == '\n') {
          i++;
          continue;
        }
        flush();
        parts.add(WPart(PartKind.lit, _c, 1));
        i++;
      } else if (c == "'") {
        flush();
        final j = s.indexOf("'", i + 1);
        if (j < 0) throw ShIncomplete();
        parts.add(WPart(PartKind.lit, s.substring(i + 1, j), 1));
        i = j + 1;
      } else if (c == '"') {
        flush();
        i++;
        _double(parts);
      } else if (c == '\$' || c == '`') {
        final p = _dollar(0);
        if (p == null) {
          lit.write(c);
          i++;
        } else {
          flush();
          parts.add(p);
        }
      } else {
        lit.write(c);
        i++;
      }
    }
    flush();
    if (!any) return null;
    if (parts.isEmpty) parts.add(const WPart(PartKind.lit, '', 1)); // "" or ''
    return Word(parts);
  }

  void _double(List<WPart> parts) {
    final lit = StringBuffer();
    var hadAny = false;
    void flush() {
      if (lit.isNotEmpty) {
        parts.add(WPart(PartKind.lit, lit.toString(), 2));
        lit.clear();
        hadAny = true;
      }
    }

    while (true) {
      if (_end) throw ShIncomplete();
      final c = _c;
      if (c == '"') {
        i++;
        break;
      }
      if (c == '\\' && i + 1 < s.length && '\$`"\\\n'.contains(s[i + 1])) {
        if (s[i + 1] != '\n') lit.write(s[i + 1]);
        i += 2;
      } else if (c == '\$' || c == '`') {
        final p = _dollar(2);
        if (p == null) {
          lit.write(c);
          i++;
        } else {
          flush();
          parts.add(p);
          hadAny = true;
        }
      } else {
        lit.write(c);
        i++;
      }
    }
    flush();
    if (!hadAny) parts.add(const WPart(PartKind.lit, '', 2));
  }

  /// `$...` or a backquote at [i]; null if the `$` is just a dollar sign.
  WPart? _dollar(int q) {
    if (_c == '`') {
      final j = s.indexOf('`', i + 1);
      if (j < 0) throw ShIncomplete();
      final raw = s.substring(i + 1, j).replaceAll('\\`', '`');
      i = j + 1;
      return WPart(PartKind.cmd, raw, q);
    }
    if (i + 1 >= s.length) return null;
    final n = s[i + 1];
    if (n == '(') {
      if (i + 2 < s.length && s[i + 2] == '(') {
        final end = _match(i + 3, '((', '))');
        final raw = s.substring(i + 3, end);
        i = end + 2;
        return WPart(PartKind.arith, raw, q);
      }
      final end = _matchParen(i + 2);
      final raw = s.substring(i + 2, end);
      i = end + 1;
      return WPart(PartKind.cmd, raw, q);
    }
    if (n == '{') {
      final j = _matchBrace(i + 2);
      final raw = s.substring(i + 2, j);
      i = j + 1;
      return WPart(PartKind.param, raw, q);
    }
    final m = RegExp(r'[A-Za-z_][A-Za-z0-9_]*|[0-9?#@*$!-]').matchAsPrefix(s, i + 1);
    if (m == null) return null;
    i = m.end;
    return WPart(PartKind.varRef, m.group(0)!, q);
  }

  int _match(int from, String open, String close) {
    var depth = 0;
    for (var j = from; j < s.length; j++) {
      if (s[j] == '(') depth++;
      if (s[j] == ')') {
        if (depth == 0 && s.startsWith(close, j)) return j;
        depth--;
      }
    }
    throw ShIncomplete();
  }

  int _matchParen(int from) {
    var depth = 0;
    var j = from;
    while (j < s.length) {
      final c = s[j];
      if (c == "'") {
        final k = s.indexOf("'", j + 1);
        if (k < 0) throw ShIncomplete();
        j = k + 1;
        continue;
      }
      if (c == '"') {
        j++;
        while (j < s.length && s[j] != '"') {
          if (s[j] == '\\') j++;
          j++;
        }
        j++;
        continue;
      }
      if (c == '\\') {
        j += 2;
        continue;
      }
      if (c == '(') depth++;
      if (c == ')') {
        if (depth == 0) return j;
        depth--;
      }
      j++;
    }
    throw ShIncomplete();
  }

  int _matchBrace(int from) {
    var depth = 0;
    for (var j = from; j < s.length; j++) {
      if (s[j] == '{') depth++;
      if (s[j] == '}') {
        if (depth == 0) return j;
        depth--;
      }
    }
    throw ShIncomplete();
  }
}

// ---------------------------------------------------------------- parser
class Parser {
  final List<Tok> t;
  final List<Redir> heredocs;
  int p = 0;
  Parser(this.t, this.heredocs);

  static Node parse(String src) {
    final lx = Lexer(src)..run();
    final ps = Parser(lx.out, lx.heredocs);
    final n = ps._list(const {});
    if (!ps._end) throw ShError('syntax error near unexpected token `${ps._show(ps.t[ps.p])}\'', 2);
    return n;
  }

  bool get _end => p >= t.length;

  String _show(Tok k) => k.op != null ? (k.op == '\n' ? 'newline' : k.op!) : k.word!.literal;

  static const _reserved = {'then', 'else', 'elif', 'fi', 'do', 'done', 'esac', '}', 'in'};

  void _skipNl() {
    while (!_end && t[p].isOp('\n')) {
      p++;
    }
  }

  bool _atWord(String w) => !_end && t[p].isWord(w);

  void _expectWord(String w) {
    _skipNl();
    if (_end) throw ShIncomplete();
    if (!t[p].isWord(w)) throw ShError('syntax error near unexpected token `${_show(t[p])}\'', 2);
    p++;
  }

  /// Commands until one of [stops] (reserved words) or the end.
  Node _list(Set<String> stops) {
    final items = <Node>[];
    while (true) {
      _skipNl();
      if (_end) break;
      final k = t[p];
      if (k.word != null && stops.contains(k.word!.plain)) break;
      if (k.isOp(')') || k.isOp(';;')) break;
      items.add(_andOr());
      if (_end) break;
      final n = t[p];
      if (n.isOp(';') || n.isOp('\n') || n.isOp('&')) {
        p++;
        continue;
      }
      if (n.word != null && stops.contains(n.word!.plain)) break;
      if (n.isOp(')') || n.isOp(';;')) break;
      throw ShError('syntax error near unexpected token `${_show(n)}\'', 2);
    }
    return items.length == 1 ? items[0] : NList(items);
  }

  Node _andOr() {
    final first = _pipeline();
    final rest = <(String, Node)>[];
    while (!_end && (t[p].isOp('&&') || t[p].isOp('||'))) {
      final op = t[p].op!;
      p++;
      _skipNl();
      if (_end) throw ShIncomplete();
      rest.add((op, _pipeline()));
    }
    return rest.isEmpty ? first : NAndOr(first, rest);
  }

  Node _pipeline() {
    var bang = false;
    if (_atWord('!')) {
      bang = true;
      p++;
    }
    final cmds = [_command()];
    while (!_end && t[p].isOp('|')) {
      p++;
      _skipNl();
      if (_end) throw ShIncomplete();
      cmds.add(_command());
    }
    return cmds.length == 1 && !bang ? cmds[0] : NPipe(cmds, bang);
  }

  Node _command() {
    if (_end) throw ShIncomplete();
    final k = t[p];
    Node? compound;
    if (k.isOp('(')) {
      p++;
      final body = _list(const {});
      if (_end) throw ShIncomplete();
      if (!t[p].isOp(')')) throw ShError('syntax error near unexpected token `${_show(t[p])}\'', 2);
      p++;
      compound = NGroup(body, true);
    } else if (k.word != null) {
      switch (k.word!.plain) {
        case '{':
          p++;
          final body = _list(const {'}'});
          _expectWord('}');
          compound = NGroup(body, false);
        case 'if':
          compound = _if();
        case 'for':
          compound = _for();
        case 'while':
        case 'until':
          final until = k.word!.plain == 'until';
          p++;
          final cond = _list(const {'do'});
          _expectWord('do');
          final body = _list(const {'done'});
          _expectWord('done');
          compound = NWhile(cond, body, until);
        case 'case':
          compound = _case();
        case 'function':
          p++;
          if (_end || t[p].word == null) throw ShIncomplete();
          final name = t[p].word!.literal;
          p++;
          if (!_end && t[p].isOp('(')) {
            p++;
            if (_end || !t[p].isOp(')')) throw ShError('syntax error near `(\'', 2);
            p++;
          }
          _skipNl();
          compound = NFunc(name, _command());
        default:
          if (k.word!.plain != null && _reserved.contains(k.word!.plain)) {
            throw ShError('syntax error near unexpected token `${k.word!.plain}\'', 2);
          }
          // name() { ... }
          if (p + 2 < t.length && k.word!.plain != null && t[p + 1].isOp('(') && t[p + 2].isOp(')')) {
            final name = k.word!.plain!;
            p += 3;
            _skipNl();
            compound = NFunc(name, _command());
          }
      }
    }
    if (compound != null) {
      final redirs = <Redir>[];
      while (!_end && _redirStart(t[p])) {
        redirs.add(_redir());
      }
      return redirs.isEmpty ? compound : NRedirected(compound, redirs);
    }
    return _simple();
  }

  bool _redirStart(Tok k) =>
      k.op != null && (k.op!.startsWith('fd') || const {'>', '>>', '<', '>&', '&>', '&>>', '<<', '<<<'}.contains(k.op));

  Redir _redir() {
    var fd = -2;
    var op = t[p].op!;
    if (op.startsWith('fd')) {
      fd = int.parse(op.substring(2));
      p++;
      if (_end || t[p].op == null) throw ShError('syntax error near redirection', 2);
      op = t[p].op!;
    }
    p++;
    if (_end || t[p].word == null) {
      if (_end) throw ShIncomplete();
      throw ShError('syntax error near unexpected token `${_show(t[p])}\'', 2);
    }
    final w = t[p].word!;
    p++;
    switch (op) {
      case '>&':
        final to = int.tryParse(w.literal);
        if (to == null) return Redir(fd == -2 ? -1 : fd, '>', w); // >&file is &>file
        return Redir(fd == -2 ? 1 : fd, '>&', null, dupTo: to);
      case '&>':
        return Redir(-1, '>', w);
      case '&>>':
        return Redir(-1, '>>', w);
      case '<<':
        final idx = int.parse(w.literal.substring('\u0001heredoc'.length));
        return heredocs[idx];
      case '<<<':
        return Redir(0, '<<<', w);
      case '<':
        return Redir(fd == -2 ? 0 : fd, '<', w);
      default:
        return Redir(fd == -2 ? 1 : fd, op, w);
    }
  }

  Node _simple() {
    final assigns = <(String, Word)>[];
    final words = <Word>[];
    final redirs = <Redir>[];
    var dbl = false; // inside [[ ... ]]
    while (!_end) {
      final k = t[p];
      if (dbl && k.op != null && const {'&&', '||', '<', '>', '(', ')'}.contains(k.op)) {
        words.add(Word([WPart(PartKind.lit, k.op!, 1)]));
        p++;
        continue;
      }
      if (_redirStart(k)) {
        redirs.add(_redir());
        continue;
      }
      if (k.word == null) break;
      final w = k.word!;
      if (words.isEmpty) {
        final first = w.parts.first;
        final m = first.kind == PartKind.lit && first.quote == 0 ? RegExp(r'^([A-Za-z_][A-Za-z0-9_]*)=').firstMatch(first.text) : null;
        if (m != null) {
          final restFirst = first.text.substring(m.end);
          assigns.add((m.group(1)!, Word([if (restFirst.isNotEmpty) WPart(PartKind.lit, restFirst, 0), ...w.parts.skip(1)])));
          p++;
          continue;
        }
      }
      if (words.isEmpty && w.plain == '[[') dbl = true;
      if (dbl && w.plain == ']]') dbl = false;
      words.add(w);
      p++;
    }
    if (words.isEmpty && assigns.isEmpty && redirs.isEmpty) {
      if (_end) throw ShIncomplete();
      throw ShError('syntax error near unexpected token `${_show(t[p])}\'', 2);
    }
    return NSimple(assigns, words, redirs);
  }

  Node _if() {
    p++; // if
    final branches = <(Node, Node)>[];
    Node? orElse;
    final cond = _list(const {'then'});
    _expectWord('then');
    final body = _list(const {'elif', 'else', 'fi'});
    branches.add((cond, body));
    while (true) {
      _skipNl();
      if (_end) throw ShIncomplete();
      if (_atWord('elif')) {
        p++;
        final c = _list(const {'then'});
        _expectWord('then');
        branches.add((c, _list(const {'elif', 'else', 'fi'})));
      } else if (_atWord('else')) {
        p++;
        orElse = _list(const {'fi'});
      } else if (_atWord('fi')) {
        p++;
        break;
      } else {
        throw ShError('syntax error near unexpected token `${_show(t[p])}\'', 2);
      }
    }
    return NIf(branches, orElse);
  }

  Node _for() {
    p++; // for
    if (_end) throw ShIncomplete();
    final name = t[p].word?.literal;
    if (name == null || !RegExp(r'^[A-Za-z_][A-Za-z0-9_]*$').hasMatch(name)) throw ShError("`$name': not a valid identifier", 2);
    p++;
    List<Word>? items;
    while (!_end && t[p].isOp('\n')) {
      p++;
    }
    if (_atWord('in')) {
      p++;
      items = [];
      while (!_end && t[p].word != null) {
        items.add(t[p].word!);
        p++;
      }
    }
    if (!_end && (t[p].isOp(';') || t[p].isOp('\n'))) p++;
    _expectWord('do');
    final body = _list(const {'done'});
    _expectWord('done');
    return NFor(name, items, body);
  }

  Node _case() {
    p++; // case
    if (_end) throw ShIncomplete();
    final subject = t[p].word;
    if (subject == null) throw ShError('syntax error in case', 2);
    p++;
    _expectWord('in');
    final arms = <(List<Word>, Node)>[];
    while (true) {
      _skipNl();
      if (_end) throw ShIncomplete();
      if (_atWord('esac')) {
        p++;
        break;
      }
      if (t[p].isOp('(')) p++;
      final pats = <Word>[];
      while (true) {
        if (_end) throw ShIncomplete();
        final w = t[p].word;
        if (w == null) throw ShError('syntax error in case pattern', 2);
        pats.add(w);
        p++;
        if (!_end && t[p].isOp('|')) {
          p++;
          continue;
        }
        break;
      }
      if (_end) throw ShIncomplete();
      if (!t[p].isOp(')')) throw ShError('syntax error near `${_show(t[p])}\'', 2);
      p++;
      final body = _list(const {'esac'});
      arms.add((pats, body));
      _skipNl();
      if (!_end && t[p].isOp(';;')) p++;
    }
    return NCase(subject, arms);
  }
}
