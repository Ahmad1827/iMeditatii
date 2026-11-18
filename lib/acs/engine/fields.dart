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

// ---------------------------------------------------------------- RISC-V (APM)
/// One field of an instruction format: its bits [hi..lo] and what it holds.
class RvField {
  final String name;
  final int hi, lo;
  final int tint; // 0 opcode, 1 rd, 2 funct3, 3 rs1, 4 rs2, 5 funct7, 6 imm
  const RvField(this.name, this.hi, this.lo, this.tint);
  int width() => hi - lo + 1;
  int of(int w) => (w >> lo) & ((1 << width()) - 1);
}

/// The six formats of Fig. 3 (riscv-spec v2.2, p. 12), from bit 31 down.
const Map<String, List<RvField>> rvFormats = {
  'R': [RvField('funct7', 31, 25, 5), RvField('rs2', 24, 20, 4), RvField('rs1', 19, 15, 3), RvField('funct3', 14, 12, 2), RvField('rd', 11, 7, 1), RvField('opcode', 6, 0, 0)],
  'I': [RvField('imm[11:0]', 31, 20, 6), RvField('rs1', 19, 15, 3), RvField('funct3', 14, 12, 2), RvField('rd', 11, 7, 1), RvField('opcode', 6, 0, 0)],
  'S': [RvField('imm[11:5]', 31, 25, 6), RvField('rs2', 24, 20, 4), RvField('rs1', 19, 15, 3), RvField('funct3', 14, 12, 2), RvField('imm[4:0]', 11, 7, 6), RvField('opcode', 6, 0, 0)],
  'B': [
    RvField('[12]', 31, 31, 6), RvField('imm[10:5]', 30, 25, 6), RvField('rs2', 24, 20, 4), RvField('rs1', 19, 15, 3), RvField('funct3', 14, 12, 2),
    RvField('[4:1]', 11, 8, 6), RvField('[11]', 7, 7, 6), RvField('opcode', 6, 0, 0)
  ],
  'U': [RvField('imm[31:12]', 31, 12, 6), RvField('rd', 11, 7, 1), RvField('opcode', 6, 0, 0)],
  'J': [RvField('[20]', 31, 31, 6), RvField('imm[10:1]', 30, 21, 6), RvField('[11]', 20, 20, 6), RvField('imm[19:12]', 19, 12, 6), RvField('rd', 11, 7, 1), RvField('opcode', 6, 0, 0)],
};

/// "0x0020F1B3", "0020f1b3" or 32 binary digits (spaces and '_' allowed) -> the word, or null.
int? parseRvWord(String s) {
  var t = s.trim().toLowerCase().replaceAll(RegExp(r'[\s_]'), '');
  if (t.isEmpty) return null;
  if (t.startsWith('0b')) {
    t = t.substring(2);
    return RegExp(r'^[01]{1,32}$').hasMatch(t) ? int.parse(t, radix: 2) : null;
  }
  if (t.length == 32 && RegExp(r'^[01]+$').hasMatch(t)) return int.parse(t, radix: 2);
  if (t.startsWith('0x')) t = t.substring(2);
  return RegExp(r'^[0-9a-f]{1,8}$').hasMatch(t) ? int.parse(t, radix: 16) : null;
}

String rvHex(int w) => '0x${w.toRadixString(16).toUpperCase().padLeft(8, '0')}';
