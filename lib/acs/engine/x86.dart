// =============================================================================
// AN x86 (32-BIT) EMULATOR, FOR IOCLA
//   NASM syntax, like the labs: section .data / .bss / .text, db dw dd, resb
//   resw resd, times, equ, labels; registers eax..esp with their 16- and 8-bit
//   parts, the flags CF ZF SF OF, memory [base + index*scale + disp] with
//   byte/word/dword. The usual instructions (mov, add, imul, div, shl, cmp,
//   jcc, push, call, ret, loop, setcc...) and printf / puts / putchar.
//   A function is tested as C calls it (cdecl): arguments on the stack,
//   result in eax, ebx esi edi ebp kept.
// =============================================================================

import 'dart:typed_data';

class AsmError implements Exception {
  final String message;
  final int line; // 1-based, 0 when unknown
  AsmError(this.message, [this.line = 0]);
  @override
  String toString() => line > 0 ? 'linia $line: $message' : message;
}

const int dataBase = 0x0804A000;
const int heapBase = 0x09000000;
const int stackTop = 0xBFFF0000;
const int stackSize = 0x10000;
const int returnSentinel = 0xDEAD0000;

const _regs32 = ['eax', 'ecx', 'edx', 'ebx', 'esp', 'ebp', 'esi', 'edi'];
const _regs16 = {'ax': 'eax', 'cx': 'ecx', 'dx': 'edx', 'bx': 'ebx', 'sp': 'esp', 'bp': 'ebp', 'si': 'esi', 'di': 'edi'};
const _regs8 = {'al': ('eax', 0), 'ah': ('eax', 8), 'cl': ('ecx', 0), 'ch': ('ecx', 8), 'dl': ('edx', 0), 'dh': ('edx', 8), 'bl': ('ebx', 0), 'bh': ('ebx', 8)};

sealed class Opnd {}

class RegOp extends Opnd {
  final String name; // the 32-bit register it lives in
  final int size; // 1, 2, 4
  final int shift; // 8 for ah, bh...
  final String text;
  RegOp(this.name, this.size, this.shift, this.text);
}

class ImmOp extends Opnd {
  final int value;
  ImmOp(this.value);
}

class MemOp extends Opnd {
  final String? base, index;
  final int scale, disp;
  int size; // 0 if not given
  MemOp(this.base, this.index, this.scale, this.disp, this.size);
}

class Instr {
  final String op;
  final List<Opnd> args;
  final int line;
  Instr(this.op, this.args, this.line);
}

class AsmProgram {
  final List<Instr> code = [];
  final Map<String, int> labels = {}; // code labels: instruction index
  final Map<String, int> dataLabels = {}; // data labels: address
  final Map<String, int> equs = {};
  final BytesBuilder data = BytesBuilder();
  int bssSize = 0;
  final Map<int, int> lineOf = {}; // instruction index -> source line

  int get dataSize => data.length;
}

/// Turns NASM source into a program.
class Assembler {
  static AsmProgram assemble(String src) {
    final p = AsmProgram();
    final lines = src.replaceAll('\r', '').split('\n');
    var section = '.text';
    // pass 1: equs and data labels' addresses need data sizes; code labels need indexes
    final pendingData = <(int, String, String, String?)>[]; // line, label, directive, rest
    final textLines = <(int, String?, String)>[]; // line, label, instruction text
    final bssLabels = <(String, int)>[];
    for (var i = 0; i < lines.length; i++) {
      var l = _stripComment(lines[i]).trim();
      if (l.isEmpty) continue;
      final ln = i + 1;
      final lower = l.toLowerCase();
      if (lower.startsWith('section ') || lower.startsWith('segment ')) {
        section = lower.split(RegExp(r'\s+'))[1];
        continue;
      }
      if (lower.startsWith('global ') || lower.startsWith('extern ') || lower.startsWith('bits ') || lower.startsWith('default ') || lower.startsWith('%include')) continue;
      String? label;
      final m = RegExp(r'^([A-Za-z_.$?][\w.$?@]*)\s*:\s*(.*)$').firstMatch(l);
      if (m != null && !_isMnemonic(m[1]!.toLowerCase())) {
        label = m[1]!;
        l = m[2]!.trim();
      }
      // "name db ..." without a colon
      final d = RegExp(r'^([A-Za-z_.$?][\w.$?@]*)\s+(db|dw|dd|dq|resb|resw|resd|resq|equ|times)\b\s*(.*)$', caseSensitive: false).firstMatch(l);
      if (label == null && d != null && !_isMnemonic(d[1]!.toLowerCase())) {
        label = d[1]!;
        l = '${d[2]} ${d[3]}'.trim();
      }
      final first = l.split(RegExp(r'\s+')).first.toLowerCase();
      if (first == 'equ') {
        if (label == null) throw AsmError('equ fără nume', ln);
        p.equs[label] = _evalConst(l.substring(3).trim(), p, ln);
        continue;
      }
      if (section == '.text' && !const {'db', 'dw', 'dd', 'dq', 'resb', 'resw', 'resd', 'times'}.contains(first)) {
        textLines.add((ln, label, l));
        continue;
      }
      if (section == '.bss' || first.startsWith('res')) {
        if (label != null && l.isEmpty) {
          bssLabels.add((label, -1));
          continue;
        }
        final r = RegExp(r'^(resb|resw|resd|resq)\s+(.+)$', caseSensitive: false).firstMatch(l);
        if (r == null) {
          if (l.isEmpty) continue;
          throw AsmError('în .bss se folosesc resb, resw, resd: „$l”', ln);
        }
        final unit = {'resb': 1, 'resw': 2, 'resd': 4, 'resq': 8}[r[1]!.toLowerCase()]!;
        final n = _evalConst(r[2]!, p, ln);
        if (label != null) bssLabels.add((label, p.bssSize));
        for (final (k, (name, off)) in bssLabels.indexed) {
          if (off == -1) bssLabels[k] = (name, p.bssSize);
        }
        p.bssSize += unit * n;
        continue;
      }
      pendingData.add((ln, label ?? '', first, l));
    }
    // data: lay out bytes in order
    for (final (ln, label, _, l) in pendingData) {
      if (label.isNotEmpty) p.dataLabels[label] = dataBase + p.data.length;
      if (l == null || l.isEmpty) continue;
      _emitData(l, p, ln);
    }
    final bssStart = dataBase + ((p.data.length + 15) & ~15);
    for (final (name, off) in bssLabels) {
      p.dataLabels[name] = bssStart + (off < 0 ? p.bssSize : off);
    }
    // code: labels first, then operands (which may name labels)
    var idx = 0;
    for (final (_, label, l) in textLines) {
      if (label != null) {
        if (p.labels.containsKey(label)) throw AsmError('eticheta „$label” e definită de două ori');
        p.labels[label] = idx;
      }
      if (l.isNotEmpty) idx++;
    }
    for (final (ln, _, l) in textLines) {
      if (l.isEmpty) continue;
      p.lineOf[p.code.length] = ln;
      p.code.add(_parseInstr(l, p, ln));
    }
    return p;
  }

  static String _stripComment(String l) {
    var inStr = false;
    String? q;
    for (var i = 0; i < l.length; i++) {
      final c = l[i];
      if (inStr) {
        if (c == q) inStr = false;
      } else if (c == '"' || c == "'" || c == '`') {
        inStr = true;
        q = c;
      } else if (c == ';') {
        return l.substring(0, i);
      }
    }
    return l;
  }

  static const _mnemonics = {
    'mov', 'movzx', 'movsx', 'lea', 'xchg', 'add', 'sub', 'adc', 'sbb', 'inc', 'dec', 'neg', 'not', 'and', 'or', 'xor', 'test', 'cmp',
    'shl', 'sal', 'shr', 'sar', 'rol', 'ror', 'mul', 'imul', 'div', 'idiv', 'cdq', 'cwd', 'cbw', 'cwde', 'push', 'pop', 'pushad', 'popad', 'pusha', 'popa',
    'call', 'ret', 'jmp', 'loop', 'nop', 'leave', 'hlt', 'int',
  };

  static bool _isMnemonic(String w) =>
      _mnemonics.contains(w) || (w.startsWith('j') && _cond(w.substring(1)) != null) || (w.startsWith('set') && _cond(w.substring(3)) != null) || (w.startsWith('cmov') && _cond(w.substring(4)) != null);

  /// The condition a jcc / setcc / cmovcc tests, by its suffix.
  static String? _cond(String s) => const {
        'e': 'e', 'z': 'e', 'ne': 'ne', 'nz': 'ne', 'g': 'g', 'nle': 'g', 'ge': 'ge', 'nl': 'ge', 'l': 'l', 'nge': 'l', 'le': 'le', 'ng': 'le',
        'a': 'a', 'nbe': 'a', 'ae': 'ae', 'nb': 'ae', 'nc': 'ae', 'b': 'b', 'nae': 'b', 'c': 'b', 'be': 'be', 'na': 'be', 's': 's', 'ns': 'ns',
        'o': 'o', 'no': 'no', 'ecxz': 'ecxz',
      }[s];

  static void _emitData(String l, AsmProgram p, int ln) {
    final t = RegExp(r'^times\s+(.+?)\s+(db|dw|dd|dq)\s+(.*)$', caseSensitive: false).firstMatch(l);
    if (t != null) {
      final n = _evalConst(t[1]!, p, ln);
      for (var k = 0; k < n; k++) {
        _emitData('${t[2]} ${t[3]}', p, ln);
      }
      return;
    }
    final m = RegExp(r'^(db|dw|dd|dq)\s+(.*)$', caseSensitive: false).firstMatch(l);
    if (m == null) throw AsmError('directivă de date necunoscută: „$l”', ln);
    final unit = {'db': 1, 'dw': 2, 'dd': 4, 'dq': 8}[m[1]!.toLowerCase()]!;
    for (final item in _splitItems(m[2]!)) {
      final it = item.trim();
      if (it.isEmpty) continue;
      if ((it.startsWith('"') && it.endsWith('"')) || (it.startsWith("'") && it.endsWith("'")) || (it.startsWith('`') && it.endsWith('`'))) {
        var s = it.substring(1, it.length - 1);
        if (it.startsWith('`')) s = s.replaceAll(r'\n', '\n').replaceAll(r'\t', '\t').replaceAll(r'\0', '\x00');
        for (final b in s.codeUnits) {
          _put(p.data, b, unit);
        }
        continue;
      }
      _put(p.data, _evalConst(it, p, ln, allowLabels: true), unit);
    }
  }

  static void _put(BytesBuilder b, int v, int unit) {
    for (var k = 0; k < unit; k++) {
      b.addByte((v >> (8 * k)) & 0xff);
    }
  }

  static List<String> _splitItems(String s) {
    final out = <String>[];
    var cur = StringBuffer();
    String? q;
    for (final c in s.split('')) {
      if (q != null) {
        cur.write(c);
        if (c == q) q = null;
      } else if (c == '"' || c == "'" || c == '`') {
        q = c;
        cur.write(c);
      } else if (c == ',') {
        out.add(cur.toString());
        cur = StringBuffer();
      } else {
        cur.write(c);
      }
    }
    out.add(cur.toString());
    return out;
  }

  /// A constant: numbers (10, 0x1F, 1Fh, 101b, 'a'), equs, labels, + - * / << >> & |.
  static int _evalConst(String s, AsmProgram p, int ln, {bool allowLabels = true}) {
    final e = _ConstExpr(s.trim(), p, ln, allowLabels);
    final v = e.parse();
    return v;
  }

  static Opnd _operand(String s, AsmProgram p, int ln) {
    var t = s.trim();
    var size = 0;
    final sz = RegExp(r'^(byte|word|dword)\s+(?:ptr\s+)?', caseSensitive: false).firstMatch(t);
    if (sz != null) {
      size = {'byte': 1, 'word': 2, 'dword': 4}[sz[1]!.toLowerCase()]!;
      t = t.substring(sz.end).trim();
    }
    final lower = t.toLowerCase();
    if (_regs32.contains(lower)) return RegOp(lower, 4, 0, lower);
    if (_regs16.containsKey(lower)) return RegOp(_regs16[lower]!, 2, 0, lower);
    if (_regs8.containsKey(lower)) return RegOp(_regs8[lower]!.$1, 1, _regs8[lower]!.$2, lower);
    if (t.startsWith('[')) {
      if (!t.endsWith(']')) throw AsmError('lipsește „]” în „$s”', ln);
      return _mem(t.substring(1, t.length - 1), size, p, ln);
    }
    final v = _evalConst(t, p, ln);
    final op = ImmOp(v);
    return op;
  }

  static MemOp _mem(String inner, int size, AsmProgram p, int ln) {
    String? base, index;
    var scale = 1, disp = 0;
    // terms joined by + or -
    final terms = RegExp(r'([+-]?)\s*([^+-]+)').allMatches(inner.replaceAll(' ', ''));
    for (final m in terms) {
      final neg = m[1] == '-';
      final term = m[2]!.toLowerCase();
      final star = term.split('*');
      if (star.length == 2 && (_regs32.contains(star[0]) || _regs32.contains(star[1]))) {
        final r = _regs32.contains(star[0]) ? star[0] : star[1];
        final k = int.tryParse(_regs32.contains(star[0]) ? star[1] : star[0]);
        if (k == null || !const {1, 2, 4, 8}.contains(k)) throw AsmError('scara trebuie să fie 1, 2, 4 sau 8', ln);
        if (neg) throw AsmError('un registru nu se poate scădea într-o adresă', ln);
        if (index != null) throw AsmError('o adresă are un singur registru index', ln);
        index = r;
        scale = k;
      } else if (_regs32.contains(term)) {
        if (neg) throw AsmError('un registru nu se poate scădea într-o adresă', ln);
        if (base == null) {
          base = term;
        } else if (index == null) {
          index = term;
        } else {
          throw AsmError('prea multe registre în adresă', ln);
        }
      } else if (_regs16.containsKey(term) || _regs8.containsKey(term)) {
        throw AsmError('în modul pe 32 de biți adresa folosește registre de 32 de biți (nu „$term”)', ln);
      } else {
        final orig = RegExp(RegExp.escape(term), caseSensitive: false).firstMatch(m[2]!)?.group(0) ?? m[2]!;
        final v = _evalConst(orig, p, ln);
        disp += neg ? -v : v;
      }
    }
    return MemOp(base, index, scale, disp, size);
  }

  static Instr _parseInstr(String l, AsmProgram p, int ln) {
    final sp = l.indexOf(RegExp(r'\s'));
    var op = (sp < 0 ? l : l.substring(0, sp)).toLowerCase();
    final rest = sp < 0 ? '' : l.substring(sp + 1).trim();
    if (op == 'rep' || op == 'lock') throw AsmError('prefixul „$op” nu e acceptat aici', ln);
    if (!_isMnemonic(op)) throw AsmError('instrucțiune necunoscută: „$op”', ln);
    if (op == 'sal') op = 'shl';
    if (op == 'pusha') op = 'pushad';
    if (op == 'popa') op = 'popad';
    final args = <Opnd>[];
    if (rest.isNotEmpty) {
      for (final a in _splitItems(rest)) {
        // jumps and calls take labels
        final t = a.trim();
        if ((op == 'call' || op == 'jmp' || op.startsWith('j') || op == 'loop') && !t.startsWith('[') && !_regs32.contains(t.toLowerCase())) {
          if (p.labels.containsKey(t)) {
            args.add(ImmOp(p.labels[t]!));
            continue;
          }
          if (op == 'call' && _externs.contains(t)) {
            args.add(ImmOp(-1 - _externs.indexOf(t)));
            continue;
          }
          throw AsmError(op == 'call' ? 'funcția „$t” nu există (externe: ${_externs.join(', ')})' : 'eticheta „$t” nu există', ln);
        }
        args.add(_operand(t, p, ln));
      }
    }
    final ins = Instr(op, args, ln);
    _validate(ins, ln);
    return ins;
  }

  static const _externs = ['printf', 'puts', 'putchar', 'strlen', 'exit'];

  static void _validate(Instr i, int ln) {
    final n = i.args.length;
    final a = i.args;
    void need(int k) {
      if (n != k) throw AsmError('„${i.op}” primește $k operand${k == 1 ? '' : 'zi'}, nu $n', ln);
    }

    int sizeOf(Opnd o) => o is RegOp ? o.size : o is MemOp ? o.size : 0;
    switch (i.op) {
      case 'mov':
      case 'add':
      case 'sub':
      case 'adc':
      case 'sbb':
      case 'and':
      case 'or':
      case 'xor':
      case 'cmp':
      case 'test':
      case 'xchg':
        need(2);
        if (a[0] is ImmOp) throw AsmError('primul operand al lui „${i.op}” nu poate fi o constantă', ln);
        if (a[0] is MemOp && a[1] is MemOp) throw AsmError('„${i.op}” nu poate avea doi operanzi din memorie', ln);
        final s0 = sizeOf(a[0]), s1 = sizeOf(a[1]);
        if (s0 != 0 && s1 != 0 && s0 != s1) throw AsmError('operanzi de dimensiuni diferite (${s0 * 8} și ${s1 * 8} biți)', ln);
        if (s0 == 0 && s1 == 0) throw AsmError('dimensiunea operației nu e precizată (scrie byte, word sau dword)', ln);
        if (a[0] is MemOp && (a[0] as MemOp).size == 0) (a[0] as MemOp).size = s1;
        if (a[1] is MemOp && (a[1] as MemOp).size == 0) (a[1] as MemOp).size = s0;
      case 'movzx':
      case 'movsx':
        need(2);
        if (a[0] is! RegOp) throw AsmError('„${i.op}” scrie într-un registru', ln);
        final s1 = sizeOf(a[1]);
        if (s1 == 0) throw AsmError('precizează dimensiunea sursei (byte sau word)', ln);
        if (s1 >= (a[0] as RegOp).size) throw AsmError('sursa lui „${i.op}” trebuie să fie mai mică decât destinația', ln);
      case 'lea':
        need(2);
        if (a[0] is! RegOp || a[1] is! MemOp) throw AsmError('lea reg, [adresă]', ln);
      case 'inc':
      case 'dec':
      case 'neg':
      case 'not':
      case 'mul':
      case 'div':
      case 'idiv':
      case 'pop':
        need(1);
        if (a[0] is ImmOp) throw AsmError('„${i.op}” nu primește o constantă', ln);
        if (sizeOf(a[0]) == 0) throw AsmError('dimensiunea operației nu e precizată (scrie byte, word sau dword)', ln);
      case 'push':
        need(1);
        if (a[0] is MemOp && (a[0] as MemOp).size == 0) (a[0] as MemOp).size = 4;
        if (sizeOf(a[0]) == 1) throw AsmError('push nu primește operanzi de 8 biți', ln);
      case 'imul':
        if (n < 1 || n > 3) throw AsmError('imul primește 1, 2 sau 3 operanzi', ln);
        if (n >= 2 && a[0] is! RegOp) throw AsmError('imul cu 2 sau 3 operanzi scrie într-un registru', ln);
        if (n == 1 && sizeOf(a[0]) == 0) throw AsmError('dimensiunea operației nu e precizată', ln);
        if (n >= 2 && a[1] is MemOp && (a[1] as MemOp).size == 0) (a[1] as MemOp).size = (a[0] as RegOp).size;
      case 'shl':
      case 'shr':
      case 'sar':
      case 'rol':
      case 'ror':
        need(2);
        if (a[1] is RegOp && (a[1] as RegOp).text != 'cl') throw AsmError('numărul de poziții e o constantă sau cl', ln);
        if (sizeOf(a[0]) == 0) throw AsmError('dimensiunea operației nu e precizată', ln);
      case 'ret':
        if (n > 1) throw AsmError('ret primește cel mult un operand', ln);
      case 'int':
        need(1);
      case 'cdq':
      case 'cwd':
      case 'cbw':
      case 'cwde':
      case 'nop':
      case 'leave':
      case 'hlt':
      case 'pushad':
      case 'popad':
        need(0);
      default:
        if (i.op.startsWith('set')) {
          need(1);
          if (sizeOf(a[0]) != 1) throw AsmError('${i.op} scrie un octet (al, bl, byte [..])', ln);
        } else if (i.op.startsWith('cmov')) {
          need(2);
          if (a[0] is! RegOp) throw AsmError('${i.op} scrie într-un registru', ln);
          if (a[1] is MemOp && (a[1] as MemOp).size == 0) (a[1] as MemOp).size = (a[0] as RegOp).size;
        } else {
          need(1); // jumps, call, loop
        }
    }
  }
}

class _ConstExpr {
  final String s;
  final AsmProgram p;
  final int ln;
  final bool labels;
  int i = 0;
  _ConstExpr(this.s, this.p, this.ln, this.labels);

  int parse() {
    final v = _or();
    _ws();
    if (i < s.length) throw AsmError('expresie greșită: „$s”', ln);
    return v;
  }

  void _ws() {
    while (i < s.length && s[i] == ' ') {
      i++;
    }
  }

  bool _eat(String t) {
    _ws();
    if (s.startsWith(t, i)) {
      i += t.length;
      return true;
    }
    return false;
  }

  int _or() {
    var v = _and();
    while (_eat('|')) {
      v |= _and();
    }
    return v;
  }

  int _and() {
    var v = _shift();
    while (_eat('&')) {
      v &= _shift();
    }
    return v;
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
    var v = _un();
    while (true) {
      if (_eat('*')) {
        v *= _un();
      } else if (_eat('/')) {
        final r = _un();
        if (r == 0) throw AsmError('împărțire la 0 într-o constantă', ln);
        v ~/= r;
      } else if (_eat('%')) {
        v %= _un();
      } else {
        return v;
      }
    }
  }

  int _un() {
    if (_eat('-')) return -_un();
    if (_eat('~')) return ~_un();
    if (_eat('(')) {
      final v = _or();
      if (!_eat(')')) throw AsmError('lipsește „)”', ln);
      return v;
    }
    _ws();
    final rest = s.substring(i);
    final ch = RegExp("^'(.)'|^\"(.)\"").firstMatch(rest);
    if (ch != null) {
      i += ch[0]!.length;
      return (ch[1] ?? ch[2]!).codeUnitAt(0);
    }
    final hex = RegExp(r'^0x([0-9a-fA-F]+)').firstMatch(rest);
    if (hex != null) {
      i += hex[0]!.length;
      return int.parse(hex[1]!, radix: 16);
    }
    final hexh = RegExp(r'^([0-9][0-9a-fA-F]*)[hH]\b').firstMatch(rest);
    if (hexh != null) {
      i += hexh[0]!.length;
      return int.parse(hexh[1]!, radix: 16);
    }
    final bin = RegExp(r'^(?:0b([01]+)|([01]+)[bB]\b)').firstMatch(rest);
    if (bin != null) {
      i += bin[0]!.length;
      return int.parse(bin[1] ?? bin[2]!, radix: 2);
    }
    final dec = RegExp(r'^[0-9]+').firstMatch(rest);
    if (dec != null) {
      i += dec[0]!.length;
      return int.parse(dec[0]!);
    }
    final name = RegExp(r'^[A-Za-z_.$?][\w.$?@]*').firstMatch(rest);
    if (name != null) {
      i += name[0]!.length;
      final n = name[0]!;
      if (n == r'$') throw AsmError(r'„$” nu e acceptat aici', ln);
      if (p.equs.containsKey(n)) return p.equs[n]!;
      if (labels && p.dataLabels.containsKey(n)) return p.dataLabels[n]!;
      if (p.labels.containsKey(n)) throw AsmError('„$n” e o etichetă de cod; aici trebuie o valoare', ln);
      throw AsmError('simbol necunoscut: „$n”', ln);
    }
    throw AsmError('expresie greșită: „$s”', ln);
  }
}

/// The machine: registers, flags, memory, and the program running on it.
class Cpu {
  final AsmProgram prog;
  final Map<String, int> r = {for (final x in _regs32) x: 0};
  bool cf = false, zf = false, sf = false, of = false;
  int eip = 0;
  final Uint8List data; // .data + .bss
  final Uint8List stack = Uint8List(stackSize);
  final Uint8List heap = Uint8List(0x10000);
  int heapUsed = 0;
  final StringBuffer out = StringBuffer();
  int steps = 0;
  bool halted = false;
  static const int maxSteps = 2000000;

  Cpu(this.prog) : data = Uint8List(((prog.dataSize + 15) & ~15) + prog.bssSize + 16) {
    data.setRange(0, prog.dataSize, prog.data.toBytes());
    r['esp'] = stackTop;
  }

  int get esp => r['esp']!;

  // ---------------------------------------------------------------- memory
  (Uint8List, int) _where(int addr, int size) {
    addr &= 0xffffffff;
    if (addr >= dataBase && addr + size <= dataBase + data.length) return (data, addr - dataBase);
    if (addr >= stackTop - stackSize && addr + size <= stackTop + 64) {
      if (addr + size > stackTop) return (_above, addr - stackTop);
      return (stack, addr - (stackTop - stackSize));
    }
    if (addr >= heapBase && addr + size <= heapBase + heap.length) return (heap, addr - heapBase);
    throw AsmError('Segmentation fault: adresa 0x${addr.toRadixString(16).padLeft(8, '0')} nu e în memoria programului');
  }

  final Uint8List _above = Uint8List(64); // where the sentinel return address sits

  int read(int addr, int size) {
    final (buf, off) = _where(addr, size);
    var v = 0;
    for (var k = size - 1; k >= 0; k--) {
      v = (v << 8) | buf[off + k];
    }
    return v;
  }

  void write(int addr, int size, int v) {
    final (buf, off) = _where(addr, size);
    for (var k = 0; k < size; k++) {
      buf[off + k] = (v >> (8 * k)) & 0xff;
    }
  }

  /// Room on the heap for a test's arrays and strings.
  int alloc(int n) {
    final a = heapBase + heapUsed;
    heapUsed += (n + 15) & ~15;
    if (heapUsed > heap.length) throw AsmError('datele testului nu încap în memorie');
    return a;
  }

  int readCString(int addr) {
    var n = 0;
    while (read(addr + n, 1) != 0) {
      n++;
      if (n > 100000) break;
    }
    return n;
  }

  String cString(int addr) {
    final b = <int>[];
    var a = addr;
    while (true) {
      final c = read(a++, 1);
      if (c == 0 || b.length > 100000) break;
      b.add(c);
    }
    return String.fromCharCodes(b);
  }

  // ---------------------------------------------------------------- operands
  static int _mask(int size) => size == 4 ? 0xffffffff : size == 2 ? 0xffff : 0xff;
  static int signed(int v, int size) {
    final bits = size * 8;
    v &= _mask(size);
    return v >= (1 << (bits - 1)) ? v - (1 << bits) : v;
  }

  int addr(MemOp m) {
    var a = m.disp;
    if (m.base != null) a += r[m.base]!;
    if (m.index != null) a += r[m.index]! * m.scale;
    return a & 0xffffffff;
  }

  int get(Opnd o, [int size = 4]) => switch (o) {
        RegOp() => (r[o.name]! >> o.shift) & _mask(o.size),
        ImmOp() => o.value & _mask(size),
        MemOp() => read(addr(o), o.size == 0 ? size : o.size),
      };

  void set(Opnd o, int v) {
    switch (o) {
      case RegOp():
        final m = _mask(o.size) << o.shift;
        r[o.name] = (r[o.name]! & ~m | ((v & _mask(o.size)) << o.shift)) & 0xffffffff;
      case MemOp():
        write(addr(o), o.size == 0 ? 4 : o.size, v);
      case ImmOp():
        throw AsmError('nu se poate scrie într-o constantă');
    }
  }

  static int sizeOf(Opnd o, [Opnd? other]) {
    if (o is RegOp) return o.size;
    if (o is MemOp && o.size != 0) return o.size;
    if (other is RegOp) return other.size;
    if (other is MemOp && other.size != 0) return other.size;
    return 4;
  }

  void push(int v) {
    r['esp'] = (esp - 4) & 0xffffffff;
    if (esp < stackTop - stackSize) throw AsmError('Stack overflow: stiva s-a umplut (o recursivitate fără oprire?)');
    write(esp, 4, v);
  }

  int pop() {
    final v = read(esp, 4);
    r['esp'] = (esp + 4) & 0xffffffff;
    return v;
  }

  void _flags(int res, int size) {
    final m = _mask(size);
    zf = (res & m) == 0;
    sf = (res >> (size * 8 - 1)) & 1 == 1;
  }

  bool cond(String c) => switch (c) {
        'e' => zf,
        'ne' => !zf,
        'g' => !zf && sf == of,
        'ge' => sf == of,
        'l' => sf != of,
        'le' => zf || sf != of,
        'a' => !cf && !zf,
        'ae' => !cf,
        'b' => cf,
        'be' => cf || zf,
        's' => sf,
        'ns' => !sf,
        'o' => of,
        'no' => !of,
        'ecxz' => r['ecx'] == 0,
        _ => throw AsmError('condiție necunoscută $c'),
      };

  int get line => prog.lineOf[eip] ?? 0;

  /// One instruction. False when the program has ended.
  bool step() {
    if (halted) return false;
    if (eip == returnSentinel || eip < 0 || eip >= prog.code.length) {
      halted = true;
      return false;
    }
    if (++steps > maxSteps) throw AsmError('programul rulează de prea mult timp (o buclă infinită?)', line);
    final i = prog.code[eip];
    try {
      _exec(i);
    } on AsmError catch (e) {
      throw AsmError(e.message, e.line == 0 ? i.line : e.line);
    }
    return !halted;
  }

  void _exec(Instr i) {
    final a = i.args;
    var next = eip + 1;
    final op = i.op;
    switch (op) {
      case 'mov':
        set(a[0], get(a[1], sizeOf(a[0], a[1])));
      case 'movzx':
        set(a[0], get(a[1], sizeOf(a[1])));
      case 'movsx':
        final s = sizeOf(a[1]);
        set(a[0], signed(get(a[1], s), s));
      case 'lea':
        set(a[0], addr(a[1] as MemOp));
      case 'xchg':
        final s = sizeOf(a[0], a[1]);
        final x = get(a[0], s), y = get(a[1], s);
        set(a[0], y);
        set(a[1], x);
      case 'add':
      case 'adc':
      case 'sub':
      case 'sbb':
      case 'cmp':
        final s = sizeOf(a[0], a[1]);
        final m = _mask(s);
        final x = get(a[0], s), y = get(a[1], s);
        final carry = (op == 'adc' || op == 'sbb') && cf ? 1 : 0;
        int res;
        if (op == 'add' || op == 'adc') {
          res = x + y + carry;
          cf = res > m;
          of = ((x ^ res) & (y ^ res) & (1 << (s * 8 - 1))) != 0;
        } else {
          res = x - y - carry;
          cf = res < 0;
          of = ((x ^ y) & (x ^ res) & (1 << (s * 8 - 1))) != 0;
        }
        _flags(res, s);
        if (op != 'cmp') set(a[0], res & m);
      case 'inc':
      case 'dec':
        final s = sizeOf(a[0]);
        final x = get(a[0], s);
        final res = op == 'inc' ? x + 1 : x - 1;
        of = op == 'inc' ? (x == (1 << (s * 8 - 1)) - 1) : (x == 1 << (s * 8 - 1));
        _flags(res, s);
        set(a[0], res);
      case 'neg':
        final s = sizeOf(a[0]);
        final x = get(a[0], s);
        final res = (-x) & _mask(s);
        cf = x != 0;
        of = x == 1 << (s * 8 - 1);
        _flags(res, s);
        set(a[0], res);
      case 'not':
        set(a[0], ~get(a[0], sizeOf(a[0])));
      case 'and':
      case 'or':
      case 'xor':
      case 'test':
        final s = sizeOf(a[0], a[1]);
        final x = get(a[0], s), y = get(a[1], s);
        final res = op == 'or' ? x | y : op == 'xor' ? x ^ y : x & y;
        cf = false;
        of = false;
        _flags(res, s);
        if (op != 'test') set(a[0], res);
      case 'shl':
      case 'shr':
      case 'sar':
      case 'rol':
      case 'ror':
        final s = sizeOf(a[0]);
        final bits = s * 8;
        final n = get(a[1], 1) & 31;
        if (n == 0) break;
        final x = get(a[0], s);
        int res;
        switch (op) {
          case 'shl':
            res = (x << n) & _mask(s);
            cf = n <= bits ? ((x >> (bits - n)) & 1) == 1 : false;
            of = n == 1 ? (((res >> (bits - 1)) & 1) == 1) != cf : of;
            _flags(res, s);
          case 'shr':
            res = x >> n;
            cf = ((x >> (n - 1)) & 1) == 1;
            of = n == 1 ? ((x >> (bits - 1)) & 1) == 1 : of;
            _flags(res, s);
          case 'sar':
            final sv = signed(x, s);
            res = (sv >> n) & _mask(s);
            cf = ((sv >> (n - 1)) & 1) == 1;
            of = n == 1 ? false : of;
            _flags(res, s);
          case 'rol':
            final k = n % bits;
            res = ((x << k) | (x >> (bits - k))) & _mask(s);
            cf = res & 1 == 1;
          default:
            final k = n % bits;
            res = ((x >> k) | (x << (bits - k))) & _mask(s);
            cf = (res >> (bits - 1)) & 1 == 1;
        }
        set(a[0], res);
      case 'mul':
      case 'imul':
        if (a.length == 1) {
          final s = sizeOf(a[0]);
          if (s == 1) {
            final x = get(RegOp('eax', 1, 0, 'al'), 1), y = get(a[0], 1);
            final res = op == 'mul' ? x * y : signed(x, 1) * signed(y, 1);
            set(RegOp('eax', 2, 0, 'ax'), res);
            cf = of = op == 'mul' ? (res >> 8) != 0 : res != signed(res, 1);
          } else {
            final x = get(RegOp('eax', s, 0, 'eax'), s), y = get(a[0], s);
            final res = op == 'mul' ? x * y : signed(x, s) * signed(y, s);
            final lo = res & _mask(s), hi = (res >> (s * 8)) & _mask(s);
            set(RegOp('eax', s, 0, 'eax'), lo);
            set(RegOp('edx', s, 0, 'edx'), hi);
            cf = of = op == 'mul' ? hi != 0 : res != signed(lo, s);
          }
        } else {
          final s = sizeOf(a[0]);
          final x = a.length == 3 ? get(a[1], s) : get(a[0], s);
          final y = a.length == 3 ? get(a[2], s) : get(a[1], s);
          final res = signed(x, s) * signed(y, s);
          set(a[0], res);
          cf = of = res != signed(res, s);
          _flags(res, s);
        }
      case 'div':
      case 'idiv':
        final s = sizeOf(a[0]);
        final d = get(a[0], s);
        if (d == 0) throw AsmError('Floating point exception: împărțire la 0');
        if (s == 1) {
          final n = get(RegOp('eax', 2, 0, 'ax'), 2);
          final q = op == 'div' ? n ~/ d : signed(n, 2) ~/ signed(d, 1);
          final rem = op == 'div' ? n % d : signed(n, 2).remainder(signed(d, 1));
          if ((op == 'div' && q > 0xff) || (op == 'idiv' && q != signed(q, 1))) throw AsmError('Floating point exception: câtul nu încape în al');
          set(RegOp('eax', 1, 0, 'al'), q);
          set(RegOp('eax', 1, 8, 'ah'), rem);
        } else {
          final hi = get(RegOp('edx', s, 0, 'edx'), s), lo = get(RegOp('eax', s, 0, 'eax'), s);
          final n = (hi << (s * 8)) | lo; // for 32 bits: the 64-bit value, as Dart's signed int
          int q, rem;
          if (op == 'div') {
            if (hi >= d) throw AsmError('Floating point exception: câtul nu încape (ai pus 0 în edx înainte de div?)');
            final bn = (BigInt.from(hi) << (s * 8)) | BigInt.from(lo);
            q = (bn ~/ BigInt.from(d)).toInt();
            rem = (bn % BigInt.from(d)).toInt();
          } else {
            final sn = s == 4 ? n : signed(n, 4);
            final sd = signed(d, s);
            q = sn ~/ sd;
            rem = sn.remainder(sd);
            if (q != signed(q, s)) throw AsmError('Floating point exception: câtul nu încape (ai făcut cdq înainte de idiv?)');
          }
          set(RegOp('eax', s, 0, 'eax'), q);
          set(RegOp('edx', s, 0, 'edx'), rem);
        }
      case 'cdq':
        r['edx'] = (r['eax']! & 0x80000000) != 0 ? 0xffffffff : 0;
      case 'cwd':
        set(RegOp('edx', 2, 0, 'dx'), (r['eax']! & 0x8000) != 0 ? 0xffff : 0);
      case 'cbw':
        set(RegOp('eax', 2, 0, 'ax'), signed(r['eax']! & 0xff, 1));
      case 'cwde':
        r['eax'] = signed(r['eax']! & 0xffff, 2) & 0xffffffff;
      case 'push':
        push(get(a[0], 4) & (a[0] is RegOp && (a[0] as RegOp).size == 2 ? 0xffff : 0xffffffff));
      case 'pop':
        set(a[0], pop());
      case 'pushad':
        final sp = esp;
        for (final x in ['eax', 'ecx', 'edx', 'ebx']) {
          push(r[x]!);
        }
        push(sp);
        for (final x in ['ebp', 'esi', 'edi']) {
          push(r[x]!);
        }
      case 'popad':
        for (final x in ['edi', 'esi', 'ebp']) {
          r[x] = pop();
        }
        pop();
        for (final x in ['ebx', 'edx', 'ecx', 'eax']) {
          r[x] = pop();
        }
      case 'leave':
        r['esp'] = r['ebp']!;
        r['ebp'] = pop();
      case 'call':
        final target = a[0] is ImmOp ? (a[0] as ImmOp).value : get(a[0]);
        if (target < 0) {
          _extern(Assembler._externs[-1 - target]);
        } else {
          push(eip + 1);
          next = target;
        }
      case 'ret':
        next = pop();
        if (a.isNotEmpty) r['esp'] = (esp + (a[0] as ImmOp).value) & 0xffffffff;
        if (next == returnSentinel) halted = true;
      case 'jmp':
        next = a[0] is ImmOp ? (a[0] as ImmOp).value : get(a[0]);
      case 'loop':
        r['ecx'] = (r['ecx']! - 1) & 0xffffffff;
        if (r['ecx'] != 0) next = (a[0] as ImmOp).value;
      case 'nop':
        break;
      case 'hlt':
        halted = true;
      case 'int':
        if ((a[0] as ImmOp).value == 0x80 && r['eax'] == 1) {
          halted = true;
        } else {
          throw AsmError('int 0x${(a[0] as ImmOp).value.toRadixString(16)}: doar exit (eax = 1) e acceptat aici');
        }
      default:
        if (op.startsWith('j')) {
          if (cond(Assembler._cond(op.substring(1))!)) next = (a[0] as ImmOp).value;
        } else if (op.startsWith('set')) {
          set(a[0], cond(Assembler._cond(op.substring(3))!) ? 1 : 0);
        } else if (op.startsWith('cmov')) {
          if (cond(Assembler._cond(op.substring(4))!)) set(a[0], get(a[1], sizeOf(a[0])));
        } else {
          throw AsmError('instrucțiunea „$op” nu e implementată');
        }
    }
    eip = next;
  }

  /// printf, puts, putchar, strlen, exit: the arguments are on the stack (cdecl).
  void _extern(String name) {
    int arg(int k) => read(esp + 4 * k, 4);
    switch (name) {
      case 'printf':
        final fmt = cString(arg(0));
        var k = 1;
        final s = fmt.replaceAllMapped(RegExp(r'%(-?\d*)(l?)([dixXucs%])'), (m) {
          final c = m[3]!;
          if (c == '%') return '%';
          final v = arg(k++);
          String t = switch (c) {
            'd' || 'i' => '${signed(v, 4)}',
            'u' => '$v',
            'x' => v.toRadixString(16),
            'X' => v.toRadixString(16).toUpperCase(),
            'c' => String.fromCharCode(v & 0xff),
            _ => cString(v),
          };
          final w = int.tryParse(m[1]!.replaceFirst('-', ''));
          if (w != null) t = m[1]!.startsWith('-') ? t.padRight(w) : t.padLeft(w);
          return t;
        });
        out.write(s);
        r['eax'] = s.length;
      case 'puts':
        final s = cString(arg(0));
        out.write('$s\n');
        r['eax'] = s.length + 1;
      case 'putchar':
        out.write(String.fromCharCode(arg(0) & 0xff));
        r['eax'] = arg(0) & 0xff;
      case 'strlen':
        r['eax'] = readCString(arg(0));
      case 'exit':
        halted = true;
    }
    // a C function may change eax, ecx, edx
    r['ecx'] = 0x1badc0de;
    r['edx'] = name == 'strlen' ? 0x1badc0de : r['edx']!;
  }
}

/// One test of a function: its arguments, the result it must give back.
class AsmCase {
  final List<dynamic> args;
  final int? ret;
  final Map<int, dynamic> mem; // argument index -> what that array or string must hold after
  final String? stdout;
  AsmCase(this.args, this.ret, this.mem, this.stdout);

  factory AsmCase.fromJson(Map j) => AsmCase(
        List.of(j['args'] as List? ?? const []),
        (j['ret'] as num?)?.toInt(),
        {for (final e in ((j['mem'] as Map?) ?? const {}).entries) int.parse('${e.key}'): e.value},
        j['stdout'] as String?,
      );
}

class AsmCaseResult {
  final AsmCase c;
  final bool ok;
  final String message;
  final int? got;
  AsmCaseResult(this.c, this.ok, this.message, [this.got]);
}

/// How a function's arguments are laid out: int, uint, char, ptr_int, ptr_byte, str, buf.
class AsmCall {
  final String entry;
  final List<String> types;
  final String returns; // int, uint, char, void
  AsmCall(this.entry, this.types, this.returns);

  factory AsmCall.fromSpec(Map spec) => AsmCall(spec['entry'] as String, [for (final t in spec['args'] as List) '$t'], spec['returns'] as String? ?? 'int');

  /// A CPU ready at the function's first instruction, with the test's arguments pushed.
  (Cpu, List<int>) prepare(AsmProgram prog, AsmCase c) {
    final cpu = Cpu(prog);
    final start = prog.labels[entry];
    if (start == null) throw AsmError('funcția „$entry” nu există: scrie eticheta $entry: (și global $entry)');
    final values = <int>[];
    for (var k = 0; k < types.length; k++) {
      final t = types[k];
      final v = k < c.args.length ? c.args[k] : 0;
      switch (t) {
        case 'ptr_int':
          final list = (v as List).cast<num>();
          final a = cpu.alloc(list.length * 4 + 4);
          for (var j = 0; j < list.length; j++) {
            cpu.write(a + 4 * j, 4, list[j].toInt());
          }
          values.add(a);
        case 'ptr_byte':
          final list = (v as List).cast<num>();
          final a = cpu.alloc(list.length + 1);
          for (var j = 0; j < list.length; j++) {
            cpu.write(a + j, 1, list[j].toInt());
          }
          values.add(a);
        case 'str':
          final s = '$v';
          final a = cpu.alloc(s.length + 1);
          for (var j = 0; j < s.length; j++) {
            cpu.write(a + j, 1, s.codeUnitAt(j));
          }
          values.add(a);
        case 'buf':
          final n = (v as num).toInt();
          final a = cpu.alloc(n + 1);
          for (var j = 0; j <= n; j++) {
            cpu.write(a + j, 1, 0xcc); // not zero: a missing terminator shows
          }
          values.add(a);
        case 'char':
          values.add(v is String ? v.codeUnitAt(0) : (v as num).toInt() & 0xff);
        default:
          values.add((v as num).toInt() & 0xffffffff);
      }
    }
    for (final v in values.reversed) {
      cpu.push(v);
    }
    cpu.push(returnSentinel);
    // callee-saved registers get values the function must give back unchanged
    cpu.r['ebx'] = 0x0b0b0b0b;
    cpu.r['esi'] = 0x05050505;
    cpu.r['edi'] = 0x0d0d0d0d;
    cpu.r['ebp'] = 0x0e0e0e0e;
    cpu.r['eax'] = 0xaaaaaaaa;
    cpu.r['ecx'] = 0xcccccccc;
    cpu.r['edx'] = 0xdddddddd;
    cpu.eip = start;
    return (cpu, values);
  }

  /// Runs one test to the end.
  AsmCaseResult run(AsmProgram prog, AsmCase c) {
    Cpu cpu;
    List<int> ptrs;
    try {
      (cpu, ptrs) = prepare(prog, c);
      final espBefore = cpu.esp + 4;
      while (cpu.step()) {}
      return check(cpu, ptrs, c, espBefore);
    } on AsmError catch (e) {
      return AsmCaseResult(c, false, e.toString());
    }
  }

  AsmCaseResult check(Cpu cpu, List<int> ptrs, AsmCase c, int espAfter) {
    if (!cpu.halted) return AsmCaseResult(c, false, 'funcția nu s-a terminat');
    if (cpu.eip != returnSentinel && cpu.steps > 0) {
      return AsmCaseResult(c, false, 'programul s-a oprit fără ret din $entry');
    }
    final saved = {'ebx': 0x0b0b0b0b, 'esi': 0x05050505, 'edi': 0x0d0d0d0d, 'ebp': 0x0e0e0e0e};
    for (final e in saved.entries) {
      if (cpu.r[e.key] != e.value) return AsmCaseResult(c, false, '${e.key} nu a fost refăcut (cdecl cere să păstrezi ebx, esi, edi, ebp: push la început, pop la sfârșit)');
    }
    if (cpu.esp != espAfter) return AsmCaseResult(c, false, 'stiva nu e echilibrată la ret (esp diferă cu ${cpu.esp - espAfter} octeți)');
    int? got;
    if (returns != 'void' && c.ret != null) {
      final raw = cpu.r['eax']!;
      got = switch (returns) { 'uint' => raw, 'char' => Cpu.signed(raw, 1), 'uchar' => raw & 0xff, _ => Cpu.signed(raw, 4) };
      final want = returns == 'uint' ? c.ret! & 0xffffffff : c.ret!;
      if (got != want) return AsmCaseResult(c, false, 'eax = $got, se aștepta $want', got);
    }
    for (final e in c.mem.entries) {
      final p = ptrs[e.key];
      final t = types[e.key];
      if (t == 'buf') {
        final size = (c.args[e.key] as num).toInt();
        if (cpu.read(p + size, 1) != 0xcc) return AsmCaseResult(c, false, 'ai scris dincolo de bufferul de $size octeți (buffer overflow)', got);
      }
      if (t == 'str' || t == 'buf') {
        final s = cpu.cString(p);
        if (s != e.value) return AsmCaseResult(c, false, 'șirul de la argumentul ${e.key + 1} e „$s”, se aștepta „${e.value}”', got);
      } else {
        final want = (e.value as List).cast<num>();
        final unit = t == 'ptr_byte' ? 1 : 4;
        final have = [for (var j = 0; j < want.length; j++) unit == 4 ? Cpu.signed(cpu.read(p + 4 * j, 4), 4) : cpu.read(p + j, 1)];
        for (var j = 0; j < want.length; j++) {
          if (have[j] != want[j].toInt()) return AsmCaseResult(c, false, 'vectorul de la argumentul ${e.key + 1} e $have, se aștepta $want', got);
        }
      }
    }
    if (c.stdout != null && cpu.out.toString() != c.stdout) {
      return AsmCaseResult(c, false, 'a afișat „${cpu.out}”, se aștepta „${c.stdout}”', got);
    }
    return AsmCaseResult(c, true, 'corect', got);
  }

  /// The C call, for the test list: suma([1, 2, 3], 3).
  String describe(AsmCase c) {
    String one(int k) {
      final v = k < c.args.length ? c.args[k] : 0;
      final t = types[k];
      if (t == 'str') return '"$v"';
      if (t == 'buf') return 'buf[$v]';
      if (t == 'char') return v is String ? "'$v'" : "'${String.fromCharCode((v as num).toInt())}'";
      return '$v';
    }

    return '$entry(${[for (var k = 0; k < types.length; k++) one(k)].join(', ')})';
  }
}
