// =============================================================================
// A USO TASK: the files it starts with and what must be true at the end
//   spec.setup: [{path, content | dir | link, mode?, owner?}]   (~ is home)
//   spec.cwd:   where the shell starts (default ~)
//   spec.checks: what is checked when the student presses Verifică:
//     {type: dir | file | absent | link | mode | exec | cwd | script | history | output, ...}
//   spec.reference: commands that solve it (the tests run them).
// =============================================================================

import 'shell.dart';
import 'vfs.dart';

class TaskCheck {
  final String label;
  final bool ok;
  final String detail; // what was found instead, when it fails
  const TaskCheck(this.label, this.ok, [this.detail = '']);
}

String _home(String p) => p == '~' ? Vfs.home : (p.startsWith('~/') ? '${Vfs.home}${p.substring(1)}' : p);

class ShellTask {
  final Map<String, dynamic> spec;
  ShellTask(this.spec);

  String get startDir => _home(spec['cwd'] as String? ?? '~');

  List<Map<String, dynamic>> get _setup => [for (final e in spec['setup'] as List? ?? const []) (e as Map).cast<String, dynamic>()];
  List<Map<String, dynamic>> get checks => [for (final e in spec['checks'] as List? ?? const []) (e as Map).cast<String, dynamic>()];
  List<String> get reference => [for (final e in spec['reference'] as List? ?? const []) '$e'];

  /// A new file system, as the task starts.
  Vfs build() {
    final fs = Vfs.standard();
    apply(fs, _setup);
    return fs;
  }

  static void apply(Vfs fs, List<Map<String, dynamic>> entries) {
    for (final e in entries) {
      final path = _home(e['path'] as String);
      final clean = path.endsWith('/') ? path.substring(0, path.length - 1) : path;
      final parent = clean.substring(0, clean.lastIndexOf('/'));
      if (parent.isNotEmpty) fs.mkdir(parent, '/', parents: true);
      VNode n;
      if (e['dir'] == true || path.endsWith('/')) {
        n = fs.lookup(clean, '/') ?? fs.mkdir(clean, '/');
      } else if (e['link'] != null) {
        n = VNode.link(e['link'] as String, Vfs.user, fs.tick());
        fs.place(clean, '/', n);
      } else {
        fs.write(clean, '/', e['content'] as String? ?? '');
        n = fs.lookup(clean, '/', follow: false)!;
      }
      if (e['mode'] != null) n.mode = int.parse('${e['mode']}', radix: 8);
      if (e['owner'] != null) n.owner = e['owner'] as String;
    }
  }

  Shell shell() => Shell(build(), cwd: startDir);

  /// Every check, against the shell as the student left it.
  List<TaskCheck> verify(Shell sh) => [for (final c in checks) _check(sh, c)];

  static bool passed(List<TaskCheck> r) => r.isNotEmpty && r.every((c) => c.ok);

  TaskCheck _check(Shell sh, Map<String, dynamic> c) {
    final fs = sh.fs;
    final path = c['path'] == null ? '' : _home(c['path'] as String);
    final shown = c['path'] as String? ?? '';
    final label = c['msg'] as String? ?? _defaultLabel(c, shown);
    switch (c['type']) {
      case 'dir':
        final n = fs.lookup(path, '/');
        return TaskCheck(label, n != null && n.isDir, n == null ? 'nu există' : 'nu e director');
      case 'file':
        final n = fs.lookup(path, '/');
        if (n == null) return TaskCheck(label, false, 'nu există');
        if (!n.isFile) return TaskCheck(label, false, 'nu e fișier');
        return _content(label, n.data, c);
      case 'absent':
        final n = fs.lookup(path, '/', follow: false);
        return TaskCheck(label, n == null, 'încă există');
      case 'link':
        final n = fs.lookup(path, '/', follow: false);
        if (n == null) return TaskCheck(label, false, 'nu există');
        if (!n.isLink) return TaskCheck(label, false, 'nu e o legătură simbolică');
        final target = c['target'] as String?;
        if (target != null) {
          final want = fs.lookup(_home(target), '/');
          final got = fs.lookup(path, '/');
          if (want == null || !identical(want, got)) return TaskCheck(label, false, 'duce la „${n.data}”');
        }
        return TaskCheck(label, true);
      case 'mode':
        final n = fs.lookup(path, '/', follow: false);
        if (n == null) return TaskCheck(label, false, 'nu există');
        final want = int.parse('${c['mode']}', radix: 8);
        final got = n.mode & 511;
        return TaskCheck(label, got == want, 'are ${got.toRadixString(8).padLeft(3, '0')} (${Vfs.modeString(n)})');
      case 'exec':
        final n = fs.lookup(path, '/');
        if (n == null) return TaskCheck(label, false, 'nu există');
        return TaskCheck(label, Vfs.may(n, 'x'), 'nu are drept de execuție');
      case 'cwd':
        return TaskCheck(label, sh.cwd == path, 'ești în ${sh.shortCwd}');
      case 'history':
        final re = RegExp(c['regex'] as String);
        return TaskCheck(label, sh.history.any(re.hasMatch), 'n-ai folosit încă așa ceva');
      case 'output':
        // a command run on the student's files must print this
        final copy = Shell(fs.clone(), cwd: Vfs.home);
        final (o, _, _) = copy.capture(c['cmd'] as String);
        return _content(label, o, c);
      case 'script':
        final n = fs.lookup(path, '/');
        if (n == null) return TaskCheck(label, false, 'scriptul nu există');
        for (final run in (c['runs'] as List).cast<Map>()) {
          final f2 = fs.clone();
          apply(f2, [for (final e in run['setup'] as List? ?? const []) (e as Map).cast<String, dynamic>()]);
          final s2 = Shell(f2, cwd: _home(run['cwd'] as String? ?? '~'));
          final args = [for (final a in run['args'] as List? ?? const []) '$a'];
          final quoted = args.map((a) => "'${a.replaceAll("'", "'\\''")}'").join(' ');
          var (o, e, st) = s2.capture('bash ${c['path']} $quoted', stdin: run['stdin'] as String? ?? '');
          if (run['after'] != null) {
            // what the script left behind, seen through a command
            final r = s2.capture(run['after'] as String);
            o = r.$1;
            e = '$e${r.$2}';
          }
          final want = run['stdout'] as String;
          final okOut = _norm(o) == _norm(want);
          final okSt = run['status'] == null || run['status'] == st;
          if (!okOut || !okSt) {
            final call = 'bash $shown${args.isEmpty ? '' : ' $quoted'}';
            final detail = !okOut
                ? '$call a afișat:\n${_preview(o)}${e.trim().isEmpty ? '' : '\n(erori: ${_preview(e)})'}\nse aștepta:\n${_preview(want)}'
                : '$call a ieșit cu codul $st, se aștepta ${run['status']}';
            return TaskCheck(label, false, detail);
          }
        }
        return TaskCheck(label, true);
    }
    return TaskCheck(label, false, 'verificare necunoscută');
  }

  static String _norm(String s) => s.replaceAll('\r', '').replaceFirst(RegExp(r'\s+$'), '');

  static String _preview(String s) {
    final t = _norm(s);
    if (t.isEmpty) return '(nimic)';
    final lines = t.split('\n');
    return lines.length > 6 ? '${lines.take(6).join('\n')}\n…' : t;
  }

  TaskCheck _content(String label, String data, Map<String, dynamic> c) {
    if (c['equals'] != null) {
      final ok = _norm(data) == _norm(c['equals'] as String);
      return TaskCheck(label, ok, 'conținutul nu e cel așteptat:\n${_preview(data)}');
    }
    if (c['contains'] != null) {
      return TaskCheck(label, data.contains(c['contains'] as String), 'nu conține „${c['contains']}”');
    }
    if (c['regex'] != null) {
      return TaskCheck(label, RegExp(c['regex'] as String, multiLine: true).hasMatch(data), 'conținutul nu e cel așteptat:\n${_preview(data)}');
    }
    if (c['lines'] != null) {
      final n = data.isEmpty ? 0 : '\n'.allMatches(data.endsWith('\n') ? data : '$data\n').length;
      return TaskCheck(label, n == c['lines'], 'are $n linii');
    }
    return TaskCheck(label, true);
  }

  static String _defaultLabel(Map c, String path) => switch (c['type']) {
        'dir' => 'există directorul $path',
        'file' => 'fișierul $path e corect',
        'absent' => '$path nu mai există',
        'link' => '$path e o legătură simbolică${c['target'] == null ? '' : ' către ${c['target']}'}',
        'mode' => '$path are permisiunile ${c['mode']}',
        'exec' => '$path se poate executa',
        'cwd' => 'ești în $path',
        'script' => 'scriptul $path trece testele',
        _ => '${c['type']}',
      };
}
