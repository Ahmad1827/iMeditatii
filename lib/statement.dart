// =============================================================================
// A PROBLEM'S STATEMENT, IN SECTIONS
//   Like at the olympiad or on pbinfo: where the problem comes from as a
//   caption, then the story (what the words mean), then Cerința, and the
//   worked example beside the example's input and output.
//   A problem says which is which itself ('context', 'cerinta'); an older one,
//   or one a teacher wrote, has only 'description', sorted here by paragraph.
//
//   The text has a little markup, the same in every field:
//     `int f(int n)`     code              **cel mult**   bold
//     $\frac{a}{b}$      a formula         $$ ... $$      a formula on its own line
//     • item             a bullet          a) item        a lettered part
//     ``` ... ```        a box in monospace (a matrix, a file's contents)
// =============================================================================

class StatementParts {
  final String source; // "Olimpiada ..., clasa a IX-a.", '' when it has none
  final List<String> context; // the story and the definitions, before the task
  final List<String> body; // the task, paragraph by paragraph
  final List<String> examples; // paragraphs explaining an example ("Exemplu: ...")
  const StatementParts({this.source = '', this.context = const [], this.body = const [], this.examples = const []});

  static List<String> paragraphs(String text) => [
        for (final p in text.replaceAll('\r', '').split(RegExp(r'\n\s*\n')))
          if (p.trim().isNotEmpty) p.trim(),
      ];

  /// [problem]'s statement: its own sections when it has them ('cerinta',
  /// with 'context' and 'explicatie' around it), else [parse] of 'description'.
  static StatementParts of(Map problem, {String? file}) {
    final task = problem['cerinta']?.toString().trim() ?? '';
    if (task.isEmpty) return parse(problem['description']?.toString() ?? '', file: file);
    return StatementParts(
      context: paragraphs(problem['context']?.toString() ?? ''),
      body: paragraphs(task),
    );
  }

  /// Splits [description] into paragraphs and sorts them. With [file] (a
  /// problem with files), the sentence saying so is dropped from the source:
  /// the page says it in a box of its own.
  static StatementParts parse(String description, {String? file}) {
    final paragraphs = StatementParts.paragraphs(description);
    var source = '';
    if (paragraphs.isNotEmpty && paragraphs.first.startsWith('Olimpiada')) {
      source = paragraphs.removeAt(0);
      if (file != null) {
        source = source.replaceAll(RegExp(r'\s*Ca la olimpiadă, datele se citesc din fișierul \S+\.in, iar rezultatul se scrie în fișierul \S+\.out\.'), '').trim();
      }
    }
    final body = <String>[], examples = <String>[];
    for (final p in paragraphs) {
      (RegExp(r'^Exemplu\b').hasMatch(p) ? examples : body).add(p);
    }
    return StatementParts(source: source, body: body, examples: examples);
  }

  /// A line shown in a monospace box rather than as prose: a C++ function
  /// header ("int impare(int n)") or a row of numbers (a matrix, an output).
  static bool isCodeLine(String line) {
    final l = line.trim();
    if (l.isEmpty) return false;
    if (RegExp(r'^(?:unsigned\s+)?(?:int|void|bool|long long|long|double|float|char)\s+&?\w+\s*\(.*\)$').hasMatch(l)) return true;
    return RegExp(r'^[-+]?\d[\d\s.,+-]*$').hasMatch(l);
  }

  /// [text]'s lines in runs: prose, or code ([isCodeLine]), as (isCode, text).
  static List<(bool, String)> runs(String text) {
    final out = <(bool, String)>[];
    for (final line in text.split('\n')) {
      final code = isCodeLine(line);
      if (out.isNotEmpty && out.last.$1 == code) {
        out[out.length - 1] = (code, '${out.last.$2}\n$line');
      } else {
        out.add((code, line));
      }
    }
    return out;
  }
}

// ---------------------------------------------------------------- markup
enum BlockKind { prose, bullets, parts, math, code }

/// A piece of a paragraph: prose (lines joined by '\n'), bullets or lettered
/// parts (one item each), a formula on its own line, or a monospace box.
class StatementBlock {
  final BlockKind kind;
  final List<String> items; // prose/math/code: one; bullets: each; parts: each, after its label
  final List<String> labels; // parts: "a)", "b)", ...
  const StatementBlock(this.kind, this.items, {this.labels = const []});

  String get text => items.join('\n');

  @override
  bool operator ==(Object other) => other is StatementBlock && other.kind == kind && other.text == text && other.labels.join() == labels.join();
  @override
  int get hashCode => Object.hash(kind, text);
  @override
  String toString() => '$kind${labels.isEmpty ? '' : labels}($text)';
}

enum SpanKind { text, bold, code, tex }

class StatementSpan {
  final SpanKind kind;
  final String text;
  const StatementSpan(this.kind, this.text);

  @override
  bool operator ==(Object other) => other is StatementSpan && other.kind == kind && other.text == text;
  @override
  int get hashCode => Object.hash(kind, text);
  @override
  String toString() => '$kind($text)';
}

class Markup {
  static final _bullet = RegExp(r'^\s*[•\-]\s+');
  static final _part = RegExp(r'^\s*(\(?[a-z1-9]\))\s+');

  /// [text]'s paragraphs cut into blocks (see the top of the file).
  static List<StatementBlock> blocks(String text) {
    final out = <StatementBlock>[];
    void add(BlockKind kind, String item, {String? label}) {
      final last = out.isEmpty ? null : out.last;
      final joins = last != null && last.kind == kind && kind != BlockKind.math && last.text.isNotEmpty; // an empty one is a gap
      if (!joins) {
        out.add(StatementBlock(kind, [item], labels: [if (label != null) label]));
      } else if (kind == BlockKind.prose || kind == BlockKind.code) {
        out[out.length - 1] = StatementBlock(kind, ['${last.items.first}\n$item']);
      } else {
        out[out.length - 1] = StatementBlock(kind, [...last.items, item], labels: [...last.labels, if (label != null) label]);
      }
    }

    // a formula on its own line, even when written in the middle of a sentence
    final lines = text
        .replaceAll('\r', '')
        .replaceAllMapped(RegExp(r'[ \t]*\$\$([\s\S]+?)\$\$[ \t]*'), (m) => '\n\$\$${m[1]!.replaceAll('\n', ' ')}\$\$\n')
        .split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final t = line.trim();
      if (t.isEmpty) {
        out.add(const StatementBlock(BlockKind.prose, ['']));
        continue;
      }
      if (t.startsWith('```')) {
        final box = <String>[];
        while (++i < lines.length && !lines[i].trim().startsWith('```')) {
          box.add(lines[i]);
        }
        out.add(StatementBlock(BlockKind.code, [box.join('\n')]));
        continue;
      }
      if (t.startsWith(r'$$')) {
        var tex = t.substring(2);
        while (!tex.trimRight().endsWith(r'$$') && i + 1 < lines.length) {
          tex = '$tex\n${lines[++i]}';
        }
        tex = tex.trimRight();
        if (tex.endsWith(r'$$')) tex = tex.substring(0, tex.length - 2);
        out.add(StatementBlock(BlockKind.math, [tex.trim()]));
        continue;
      }
      final b = _bullet.firstMatch(line);
      if (b != null) {
        add(BlockKind.bullets, line.substring(b.end).trim());
        continue;
      }
      final p = _part.firstMatch(line);
      if (p != null) {
        add(BlockKind.parts, line.substring(p.end).trim(), label: p.group(1)!);
        continue;
      }
      if (StatementParts.isCodeLine(line)) {
        add(BlockKind.code, line.trimRight());
        continue;
      }
      final last = out.isEmpty ? null : out.last;
      if (last != null && (last.kind == BlockKind.bullets || last.kind == BlockKind.parts) && line.startsWith('  ')) {
        // an item carried on the next line
        final items = [...last.items];
        items[items.length - 1] = '${items.last} $t';
        out[out.length - 1] = StatementBlock(last.kind, items, labels: last.labels);
        continue;
      }
      add(BlockKind.prose, line.trim());
    }
    // the blank lines only kept blocks apart
    return [for (final b in out) if (!(b.kind == BlockKind.prose && b.text.isEmpty)) b];
  }

  /// [text] cut at `code`, $formulas$ and **bold**. A marker left open is
  /// text; "\$" is a dollar sign.
  static List<StatementSpan> spans(String text) {
    final out = <StatementSpan>[];
    final buf = StringBuffer();
    void flush() {
      if (buf.isNotEmpty) {
        if (out.isNotEmpty && out.last.kind == SpanKind.text) {
          out[out.length - 1] = StatementSpan(SpanKind.text, out.last.text + buf.toString());
        } else {
          out.add(StatementSpan(SpanKind.text, buf.toString()));
        }
        buf.clear();
      }
    }

    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == r'\' && i + 1 < text.length && text[i + 1] == r'$') {
        buf.write(r'$');
        i += 2;
        continue;
      }
      String? close;
      SpanKind? kind;
      var open = 1;
      if (c == '`') {
        close = '`';
        kind = SpanKind.code;
      } else if (c == r'$') {
        close = r'$';
        kind = SpanKind.tex;
      } else if (text.startsWith('**', i)) {
        close = '**';
        kind = SpanKind.bold;
        open = 2;
      }
      if (close != null) {
        var end = text.indexOf(close, i + open);
        while (kind == SpanKind.tex && end > 0 && text[end - 1] == r'\') {
          end = text.indexOf(close, end + 1);
        }
        if (end > i + open - 1 && end != -1) {
          flush();
          out.add(StatementSpan(kind!, text.substring(i + open, end)));
          i = end + close.length;
          continue;
        }
      }
      buf.write(c);
      i++;
    }
    flush();
    return out;
  }

  /// [text] without its markup, for where it's shown as plain text (a
  /// notification, a search result); formulas keep their TeX.
  static String plain(String text) => text
      .replaceAll(RegExp(r'^```.*$', multiLine: true), '')
      .replaceAll(r'$$', '')
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'`([^`]*)`'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'(?<!\\)\$([^$]*)\$'), (m) => m[1]!)
      .replaceAll(r'\$', r'$');
}
