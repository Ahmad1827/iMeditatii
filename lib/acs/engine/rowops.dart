// =============================================================================
// ROW OPERATIONS, EXACTLY (ALGAED)
//   A matrix of fractions (an augmented one, if the task has a bar) and the
//   three elementary operations, typed as on the blackboard:
//     L1 <-> L3        L2 = 1/2 L2        L2 = L2 - 3L1        L3 = 2L3 + L1
//   (R works for L.) The goal: reduced row echelon form, an echelon form,
//   a triangular one (for a determinant), or [I | A^-1]. The determinant's
//   factor is followed through every operation.
// =============================================================================

class RowError implements Exception {
  final String message;
  RowError(this.message);
  @override
  String toString() => message;
}

/// A rational number, always reduced, the denominator positive.
class Q implements Comparable<Q> {
  final BigInt n, d;
  Q._(this.n, this.d);

  factory Q(BigInt n, [BigInt? d]) {
    d ??= BigInt.one;
    if (d == BigInt.zero) throw RowError('împărțire la 0');
    if (d < BigInt.zero) {
      n = -n;
      d = -d;
    }
    final g = n.gcd(d);
    return g == BigInt.one || g == BigInt.zero ? Q._(n, d) : Q._(n ~/ g, d ~/ g);
  }

  factory Q.int(int v) => Q(BigInt.from(v));
  static final Q zero = Q.int(0), one = Q.int(1);

  /// "3", "-2/3", "0.25", "1.5"
  static Q parse(String s) {
    final t = s.trim().replaceAll('−', '-');
    if (t.isEmpty) throw RowError('lipsește un număr');
    final frac = RegExp(r'^([+-]?\d+)\s*/\s*(\d+)$').firstMatch(t);
    if (frac != null) return Q(BigInt.parse(frac[1]!), BigInt.parse(frac[2]!));
    final dec = RegExp(r'^([+-]?)(\d*)(?:[.,](\d+))?$').firstMatch(t);
    if (dec != null && (dec[2]!.isNotEmpty || (dec[3] ?? '').isNotEmpty)) {
      final whole = dec[2]!.isEmpty ? '0' : dec[2]!;
      final fracPart = dec[3] ?? '';
      final den = BigInt.from(10).pow(fracPart.length);
      final num = BigInt.parse(whole) * den + (fracPart.isEmpty ? BigInt.zero : BigInt.parse(fracPart));
      return Q(dec[1] == '-' ? -num : num, den);
    }
    throw RowError('„$s” nu e un număr (scrie de exemplu 3, -2/3 sau 0.5)');
  }

  Q operator +(Q o) => Q(n * o.d + o.n * d, d * o.d);
  Q operator -(Q o) => Q(n * o.d - o.n * d, d * o.d);
  Q operator *(Q o) => Q(n * o.n, d * o.d);
  Q operator /(Q o) => Q(n * o.d, d * o.n);
  Q operator -() => Q(-n, d);
  bool get isZero => n == BigInt.zero;
  bool get isOne => n == d;
  double get toDouble => n.toDouble() / d.toDouble();

  @override
  bool operator ==(Object other) => other is Q && other.n == n && other.d == d;
  @override
  int get hashCode => Object.hash(n, d);
  @override
  int compareTo(Q o) => (n * o.d).compareTo(o.n * d);
  @override
  String toString() => d == BigInt.one ? '$n' : '$n/$d';
}

typedef QMatrix = List<List<Q>>;

QMatrix copyM(QMatrix m) => [for (final r in m) List.of(r)];

bool sameM(QMatrix a, QMatrix b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].length != b[i].length) return false;
    for (var j = 0; j < a[i].length; j++) {
      if (a[i][j] != b[i][j]) return false;
    }
  }
  return true;
}

/// The reduced row echelon form (Gauss-Jordan), on the first [cols] columns' pivots.
QMatrix rref(QMatrix m0, {int? cols}) {
  final m = copyM(m0);
  final rows = m.length, nc = cols ?? m[0].length;
  var r = 0;
  for (var c = 0; c < nc && r < rows; c++) {
    var p = r;
    while (p < rows && m[p][c].isZero) {
      p++;
    }
    if (p == rows) continue;
    final t = m[p];
    m[p] = m[r];
    m[r] = t;
    final piv = m[r][c];
    m[r] = [for (final x in m[r]) x / piv];
    for (var i = 0; i < rows; i++) {
      if (i == r || m[i][c].isZero) continue;
      final f = m[i][c];
      m[i] = [for (var j = 0; j < m[i].length; j++) m[i][j] - f * m[r][j]];
    }
    r++;
  }
  return m;
}

Q detQ(QMatrix m0) {
  final m = copyM(m0);
  final n = m.length;
  var d = Q.one;
  for (var c = 0; c < n; c++) {
    var p = c;
    while (p < n && m[p][c].isZero) {
      p++;
    }
    if (p == n) return Q.zero;
    if (p != c) {
      final t = m[p];
      m[p] = m[c];
      m[c] = t;
      d = -d;
    }
    d = d * m[c][c];
    for (var i = c + 1; i < n; i++) {
      final f = m[i][c] / m[c][c];
      m[i] = [for (var j = 0; j < n; j++) m[i][j] - f * m[c][j]];
    }
  }
  return d;
}

/// Row echelon form: each row's first nonzero is right of the one above; zero rows last.
bool isEchelon(QMatrix m, int cols) {
  var last = -1;
  var zeroSeen = false;
  for (final r in m) {
    var lead = -1;
    for (var j = 0; j < cols; j++) {
      if (!r[j].isZero) {
        lead = j;
        break;
      }
    }
    if (lead == -1) {
      zeroSeen = true;
      continue;
    }
    if (zeroSeen || lead <= last) return false;
    last = lead;
  }
  return true;
}

bool isUpperTriangular(QMatrix m) {
  for (var i = 0; i < m.length; i++) {
    for (var j = 0; j < i && j < m[i].length; j++) {
      if (!m[i][j].isZero) return false;
    }
  }
  return true;
}

class RowOp {
  final String text;
  final QMatrix before;
  final Q detFactor; // det(after) = detFactor * det(before)
  RowOp(this.text, this.before, this.detFactor);
}

class RowOpsTask {
  final QMatrix start;
  final int split; // columns before the bar (all of them when there is none)
  final String goal; // rref echelon triangular inverse
  QMatrix m;
  final List<RowOp> history = [];
  Q detFactor = Q.one; // det(m) = detFactor * det(start)

  RowOpsTask(this.start, this.split, this.goal) : m = copyM(start);

  factory RowOpsTask.fromSpec(Map s) {
    final rows = [for (final r in s['matrix'] as List) [for (final x in r as List) Q.parse('$x')]];
    if (s['goal'] == 'inverse') {
      final n = rows.length;
      for (var i = 0; i < n; i++) {
        rows[i].addAll([for (var j = 0; j < n; j++) i == j ? Q.one : Q.zero]);
      }
      return RowOpsTask(rows, n, 'inverse');
    }
    return RowOpsTask(rows, (s['split'] as num?)?.toInt() ?? rows[0].length, s['goal'] as String? ?? 'rref');
  }

  int get rows => m.length;
  int get cols => m[0].length;
  bool get augmented => split < cols;

  static final _row = RegExp(r'[LlRr]\s*(\d+)');

  int _r(String t) {
    final k = int.parse(t);
    if (k < 1 || k > rows) throw RowError('nu există linia $k (sunt $rows linii)');
    return k - 1;
  }

  /// Parses "2", "-1/3", "", "-" as a coefficient.
  static Q _coef(String t) {
    final s = t.replaceAll(' ', '').replaceAll('*', '').replaceAll('·', '');
    if (s.isEmpty || s == '+') return Q.one;
    if (s == '-') return -Q.one;
    // (1/2) or 1/2
    final inner = s.startsWith('(') && s.endsWith(')') ? s.substring(1, s.length - 1) : s.replaceAll('(', '').replaceAll(')', '');
    final sign = inner.startsWith('-') ? -Q.one : Q.one;
    final body = inner.replaceFirst(RegExp(r'^[+-]'), '');
    return sign * Q.parse(body.isEmpty ? '1' : body);
  }

  /// Applies one operation written as text.
  void apply(String text) {
    final t = text.trim().replaceAll('←', '=').replaceAll('<->', '↔').replaceAll('<=>', '↔').replaceAll('−', '-');
    if (t.isEmpty) throw RowError('scrie o operație, de exemplu L2 = L2 - 3L1');
    final before = copyM(m);
    // swap
    final sw = RegExp(r'^[LlRr]\s*(\d+)\s*↔\s*[LlRr]\s*(\d+)$').firstMatch(t);
    if (sw != null) {
      final a = _r(sw[1]!), b = _r(sw[2]!);
      if (a == b) throw RowError('schimbi o linie cu ea însăși');
      final x = m[a];
      m[a] = m[b];
      m[b] = x;
      detFactor = -detFactor;
      history.add(RowOp('L${a + 1} ↔ L${b + 1}', before, -Q.one));
      return;
    }
    // "L2 - 3L1 -> L2" written the other way
    final arrow = RegExp(r'^(.+?)\s*(?:->|→)\s*([LlRr]\s*\d+)$').firstMatch(t);
    final eq = arrow != null ? null : RegExp(r'^([LlRr]\s*\d+)\s*=\s*(.+)$').firstMatch(t);
    final target = arrow?[2] ?? eq?[1];
    final rhs = arrow?[1] ?? eq?[2];
    if (target == null || rhs == null) throw RowError('nu înțeleg „$text”. Exemple: L1 <-> L2, L2 = 1/2 L2, L3 = L3 - 2L1');
    final ti = _r(_row.firstMatch(target)![1]!);
    // division by a number: L2 = L2 / 3
    final div = RegExp(r'^\s*([LlRr]\s*\d+)\s*/\s*(\(?[-+]?[\d.,/ ]+\)?)\s*$').firstMatch(rhs);
    final terms = <(Q, int)>[];
    if (div != null) {
      terms.add((Q.one / _coef(div[2]!), _r(_row.firstMatch(div[1]!)![1]!)));
    } else {
      // terms: [coef] L k, joined by + or -
      final re = RegExp(r'([+-]?\s*(?:\(\s*[-+]?[\d.,]+(?:\s*/\s*\d+)?\s*\)|[\d.,]+(?:\s*/\s*\d+)?)?\s*[*·]?\s*)[LlRr]\s*(\d+)(?:\s*/\s*(\d+))?');
      var consumed = '';
      for (final mm in re.allMatches(rhs)) {
        var c = _coef(mm[1]!);
        if (mm[3] != null) c = c / Q.parse(mm[3]!);
        terms.add((c, _r(mm[2]!)));
        consumed += mm[0]!;
      }
      if (consumed.replaceAll(' ', '') != rhs.replaceAll(' ', '')) throw RowError('nu înțeleg „$rhs”. Exemple: L2 - 3L1, 1/2 L2, 2L3 + L1');
    }
    if (terms.isEmpty) throw RowError('în dreapta trebuie liniile, de exemplu L2 - 3L1');
    var selfCoef = Q.zero;
    for (final (c, r) in terms) {
      if (r == ti) selfCoef = selfCoef + c;
    }
    if (selfCoef.isZero) throw RowError('L${ti + 1} trebuie să rămână în combinație (cu un coeficient nenul), altfel nu e o operație elementară');
    final others = terms.where((x) => x.$2 != ti).toList();
    final newRow = [for (var j = 0; j < cols; j++) m[ti][j] * selfCoef];
    for (final (c, r) in others) {
      for (var j = 0; j < cols; j++) {
        newRow[j] = newRow[j] + c * m[r][j];
      }
    }
    m[ti] = newRow;
    detFactor = detFactor * selfCoef;
    final desc = [
      if (!selfCoef.isOne) '${_show(selfCoef)}L${ti + 1}' else 'L${ti + 1}',
      for (final (c, r) in others) '${c.n < BigInt.zero ? '- ' : '+ '}${_show(c.n < BigInt.zero ? -c : c, lead: false)}L${r + 1}',
    ].join(' ');
    history.add(RowOp('L${ti + 1} = $desc', before, selfCoef));
  }

  static String _show(Q c, {bool lead = true}) {
    if (c.isOne) return '';
    if (c == -Q.one) return '-';
    return c.d == BigInt.one ? '$c' : '($c)';
  }

  void undo() {
    if (history.isEmpty) return;
    final op = history.removeLast();
    m = op.before;
    detFactor = detFactor / op.detFactor;
  }

  void reset() {
    m = copyM(start);
    history.clear();
    detFactor = Q.one;
  }

  /// Where the goal stands.
  (bool, String) goalState() {
    switch (goal) {
      case 'rref':
        final want = rref(start, cols: split);
        final ok = sameM(m, want);
        return (ok, ok ? 'forma eșalon redusă: da' : 'forma eșalon redusă: nu încă');
      case 'echelon':
        final ok = isEchelon(m, split);
        return (ok, ok ? 'formă eșalon: da' : 'formă eșalon: nu încă');
      case 'triangular':
        final ok = isUpperTriangular(m);
        return (ok, ok ? 'superior triunghiulară: da' : 'superior triunghiulară: nu încă');
      case 'inverse':
        var ok = true;
        for (var i = 0; i < rows && ok; i++) {
          for (var j = 0; j < split; j++) {
            if (m[i][j] != (i == j ? Q.one : Q.zero)) {
              ok = false;
              break;
            }
          }
        }
        return (ok, ok ? 'în stânga e I: în dreapta e inversa' : 'în stânga trebuie să ajungă matricea unitate');
    }
    return (false, '');
  }

  /// The pivot positions of the current matrix (for highlighting).
  Set<(int, int)> pivots() {
    final out = <(int, int)>{};
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < split; j++) {
        if (!m[i][j].isZero) {
          out.add((i, j));
          break;
        }
      }
    }
    return out;
  }
}
