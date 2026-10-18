// =============================================================================
// A PROBLEM'S STATEMENT, IN SECTIONS
//   The text stays as written; only where it's shown changes. Like at the
//   olympiad or on pbinfo: where the problem comes from as a caption, then
//   Cerința, and the worked example ("Exemplu: ...") beside the example's
//   input and output instead of in the middle of the statement.
// =============================================================================

class StatementParts {
  final String source; // "Olimpiada ..., clasa a IX-a.", '' when it has none
  final List<String> body; // the task, paragraph by paragraph
  final List<String> examples; // paragraphs explaining an example ("Exemplu: ...")
  const StatementParts({this.source = '', this.body = const [], this.examples = const []});

  /// Splits [description] into paragraphs and sorts them. With [file] (a
  /// problem with files), the sentence saying so is dropped from the source:
  /// the page says it in a box of its own.
  static StatementParts parse(String description, {String? file}) {
    final paragraphs = [
      for (final p in description.replaceAll('\r', '').split(RegExp(r'\n\s*\n')))
        if (p.trim().isNotEmpty) p.trim(),
    ];
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
