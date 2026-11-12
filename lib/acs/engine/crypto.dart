// =============================================================================
// ISC: DECODING STEPS, CHAINED
//   Each step takes the bytes the one before it left: undo an encoding (hex,
//   base64, binary, URL), a classical cipher (Caesar, Vigenère, Atbash), an
//   XOR with a key, or a reversal. A task gives the scrambled text and is
//   solved when the chain ends in the flag.
// =============================================================================

import 'dart:convert';

class CryptoError implements Exception {
  final String message;
  const CryptoError(this.message);
  @override
  String toString() => message;
}

class CryptoOp {
  final String kind; // hex, b64, bin, url, rot, vig, atbash, xor, rev
  final String arg; // the shift or the key
  const CryptoOp(this.kind, [this.arg = '']);

  static const names = {
    'hex': 'din hex',
    'b64': 'din base64',
    'bin': 'din binar',
    'url': 'din URL (%xx)',
    'rot': 'Cezar: înapoi cu',
    'vig': 'Vigenère, cheia',
    'atbash': 'Atbash',
    'xor': 'XOR cu cheia',
    'rev': 'inversează',
  };

  /// What the argument is, for the steps that have one.
  static const argHints = {'rot': 'deplasare', 'vig': 'cheie', 'xor': 'cheie'};

  bool get needsArg => argHints.containsKey(kind);

  static int _shift(int c, int by) {
    if (c >= 65 && c <= 90) return (c - 65 + by) % 26 + 65;
    if (c >= 97 && c <= 122) return (c - 97 + by) % 26 + 97;
    return c;
  }

  List<int> apply(List<int> input) {
    final text = String.fromCharCodes(input);
    switch (kind) {
      case 'hex':
        final t = text.replaceAll(RegExp(r'\s|0x|:'), '');
        if (t.isEmpty || t.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(t)) throw const CryptoError('nu e un șir hex (perechi de cifre 0-9, a-f)');
        return [for (var i = 0; i < t.length; i += 2) int.parse(t.substring(i, i + 2), radix: 16)];
      case 'b64':
        try {
          return base64.decode(base64.normalize(text.replaceAll(RegExp(r'\s'), '')));
        } on FormatException {
          throw const CryptoError('nu e base64 valid');
        }
      case 'bin':
        final t = text.replaceAll(RegExp(r'\s'), '');
        if (t.isEmpty || t.length % 8 != 0 || !RegExp(r'^[01]+$').hasMatch(t)) throw const CryptoError('nu sunt grupuri de câte 8 biți');
        return [for (var i = 0; i < t.length; i += 8) int.parse(t.substring(i, i + 8), radix: 2)];
      case 'url':
        try {
          return utf8.encode(Uri.decodeComponent(text));
        } catch (_) {
          throw const CryptoError('nu e un text codificat cu %xx');
        }
      case 'rot':
        final n = int.tryParse(arg.trim());
        if (n == null) throw const CryptoError('scrie deplasarea (un număr)');
        return [for (final c in input) _shift(c, (26 - n % 26) % 26)];
      case 'vig':
        final key = arg.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        if (key.isEmpty) throw const CryptoError('scrie cheia (litere)');
        var k = 0;
        return [
          for (final c in input)
            if ((c >= 65 && c <= 90) || (c >= 97 && c <= 122)) _shift(c, 26 - (key.codeUnitAt(k++ % key.length) - 97)) else c,
        ];
      case 'atbash':
        return [
          for (final c in input)
            if (c >= 65 && c <= 90) 155 - c else if (c >= 97 && c <= 122) 219 - c else c,
        ];
      case 'xor':
        if (arg.isEmpty) throw const CryptoError('scrie cheia');
        final key = arg.codeUnits;
        return [for (var i = 0; i < input.length; i++) input[i] ^ (key[i % key.length] & 255)];
      default:
        return input.reversed.toList();
    }
  }

  Map<String, dynamic> toJson() => {'op': kind, 'arg': arg};
  factory CryptoOp.fromJson(Map j) => CryptoOp('${j['op']}', '${j['arg'] ?? ''}');
}

/// Bytes as a person reads them: the text when it is all printable, else hex.
String showBytes(List<int> b) {
  if (b.every((c) => (c >= 32 && c < 127) || c == 10)) return String.fromCharCodes(b);
  return b.map((c) => c.toRadixString(16).padLeft(2, '0')).join(' ');
}

bool printable(List<int> b) => b.every((c) => (c >= 32 && c < 127) || c == 10);

/// The output after each step; the run stops at the first step that fails.
class CryptoRun {
  final List<List<int>> outputs; // one per step that worked
  final String? error; // of step outputs.length
  const CryptoRun(this.outputs, this.error);

  static CryptoRun of(String cipher, List<CryptoOp> ops) {
    List<int> cur = utf8.encode(cipher);
    final outs = <List<int>>[];
    for (final op in ops) {
      try {
        cur = op.apply(cur);
      } on CryptoError catch (e) {
        return CryptoRun(outs, e.message);
      }
      outs.add(cur);
    }
    return CryptoRun(outs, null);
  }
}

class CryptoTask {
  final String cipher, flag;
  final List<CryptoOp> reference;
  const CryptoTask(this.cipher, this.flag, this.reference);

  factory CryptoTask.fromSpec(Map<String, dynamic> spec) =>
      CryptoTask(spec['cipher'] as String, spec['flag'] as String, [for (final o in spec['reference'] as List) CryptoOp.fromJson(o as Map)]);

  bool solvedBy(List<CryptoOp> ops) {
    final r = CryptoRun.of(cipher, ops);
    return r.error == null && r.outputs.isNotEmpty && showBytes(r.outputs.last) == flag;
  }
}
