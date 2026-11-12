// =============================================================================
// ANSWERS TYPED IN LABELLED FIELDS (RL, EG)
//   A task is a list of fields, each with its answer: a number (with a
//   tolerance), or text compared without spaces and capitals. Several
//   accepted spellings are separated by '|'.
// =============================================================================

class AnswerField {
  final String id;
  final String label;
  final String answer;
  final bool number;
  final double tol;
  final String hint; // the format expected: "a.b.c.d", "/n"
  const AnswerField(this.id, this.label, this.answer, this.number, this.tol, this.hint);

  factory AnswerField.fromJson(Map j) => AnswerField(
        '${j['id']}',
        j['label'] as String,
        '${j['answer']}',
        j['number'] == true,
        (j['tol'] as num?)?.toDouble() ?? 0.005,
        j['hint'] as String? ?? '',
      );

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s'), '');

  static double? parseNumber(String s) {
    final t = s.trim().replaceAll(',', '.').replaceAll('%', '').replaceAll(RegExp(r'\s'), '');
    final frac = RegExp(r'^(-?\d+(?:\.\d+)?)/(\d+(?:\.\d+)?)$').firstMatch(t);
    if (frac != null) {
      final d = double.parse(frac[2]!);
      return d == 0 ? null : double.parse(frac[1]!) / d;
    }
    return double.tryParse(t);
  }

  bool accepts(String typed) {
    if (number) {
      final v = parseNumber(typed), want = double.parse(answer);
      return v != null && (v - want).abs() <= tol + 1e-9;
    }
    final t = _norm(typed);
    return t.isNotEmpty && answer.split('|').any((a) => _norm(a) == t);
  }
}

class FieldsTask {
  final List<AnswerField> fields;
  const FieldsTask(this.fields);

  factory FieldsTask.fromSpec(Map<String, dynamic> spec) => FieldsTask([for (final f in spec['fields'] as List) AnswerField.fromJson(f as Map)]);

  /// id -> right or wrong, for what was typed (an empty field is wrong).
  Map<String, bool> check(Map<String, String> typed) => {for (final f in fields) f.id: f.accepts(typed[f.id] ?? '')};

  /// The answers themselves, as the reference would type them.
  Map<String, String> get reference => {for (final f in fields) f.id: f.answer.split('|').first};
}

// ---------------------------------------------------------------- IPv4
/// "192.168.1.70" -> the 32-bit value, or null.
int? parseIp(String s) {
  final parts = s.trim().split('.');
  if (parts.length != 4) return null;
  var v = 0;
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null || n < 0 || n > 255 || p.isEmpty) return null;
    v = v * 256 + n;
  }
  return v;
}

String ipText(int v) => [for (var s = 24; s >= 0; s -= 8) (v >> s) & 255].join('.');

int maskOf(int prefix) => prefix == 0 ? 0 : (0xFFFFFFFF << (32 - prefix)) & 0xFFFFFFFF;

/// The 32 bits of [v], most significant first.
List<int> bitsOf(int v) => [for (var i = 31; i >= 0; i--) (v >> i) & 1];
