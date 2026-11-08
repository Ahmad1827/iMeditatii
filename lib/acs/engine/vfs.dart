// =============================================================================
// A FILE SYSTEM IN MEMORY, for the USO shell
//   Directories, files and symbolic links with Unix permissions. The student
//   is `student`; their home is /home/student and everything in it is theirs.
//   /etc and /usr belong to root (readable, not writable). Pure Dart.
// =============================================================================

import 'dart:collection';

enum VType { file, dir, link }

class VNode {
  final VType type;
  String data; // a file's text; a link's target
  final SplayTreeMap<String, VNode> kids = SplayTreeMap();
  int mode;
  String owner;
  int mtime;

  VNode.file(this.data, this.mode, this.owner, this.mtime) : type = VType.file;
  VNode.dir(this.mode, this.owner, this.mtime) : type = VType.dir, data = '';
  VNode.link(this.data, this.owner, this.mtime) : type = VType.link, mode = 0x1ff;

  bool get isDir => type == VType.dir;
  bool get isFile => type == VType.file;
  bool get isLink => type == VType.link;

  VNode clone() {
    final n = switch (type) {
      VType.file => VNode.file(data, mode, owner, mtime),
      VType.dir => VNode.dir(mode, owner, mtime),
      VType.link => VNode.link(data, owner, mtime),
    };
    for (final e in kids.entries) {
      n.kids[e.key] = e.value.clone();
    }
    return n;
  }

  int get size => isDir ? 4096 : (isLink ? data.length : _utf8Len(data));
}

int _utf8Len(String s) {
  var n = 0;
  for (final r in s.runes) {
    n += r < 0x80 ? 1 : r < 0x800 ? 2 : r < 0x10000 ? 3 : 4;
  }
  return n;
}

/// An error a command prints as `cmd: message`.
class ShError implements Exception {
  final String message;
  final int status;
  ShError(this.message, [this.status = 1]);
  @override
  String toString() => message;
}

class Vfs {
  VNode root;
  int clock = 1;
  int umask = 18; // 022
  static const String user = 'student';
  static const String home = '/home/student';

  Vfs._(this.root);

  factory Vfs.standard() {
    final fs = Vfs._(VNode.dir(493, 'root', 0));
    for (final d in ['/bin', '/etc', '/tmp', '/usr', '/usr/bin', '/var', '/var/log', '/home', '/dev']) {
      fs._mk(d, 'root', d == '/tmp' ? 511 : 493);
    }
    fs._mk(home, user, 493);
    fs.root.kids['etc']!.kids['passwd'] = VNode.file(
        'root:x:0:0:root:/root:/bin/bash\n'
        'daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin\n'
        'www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin\n'
        'student:x:1000:1000:Student ACS,,,:/home/student:/bin/bash\n'
        'guest:x:1001:1001::/home/guest:/bin/sh\n',
        420,
        'root',
        0);
    fs.root.kids['etc']!.kids['hostname'] = VNode.file('acs\n', 420, 'root', 0);
    fs.root.kids['etc']!.kids['shadow'] = VNode.file('root:*:19000:0:99999:7:::\n', 416, 'root', 0);
    fs.root.kids['dev']!.kids['null'] = VNode.file('', 438, 'root', 0);
    return fs;
  }

  void _mk(String path, String owner, int mode) {
    var cur = root;
    for (final part in path.split('/').where((p) => p.isNotEmpty)) {
      cur = cur.kids.putIfAbsent(part, () => VNode.dir(mode, owner, 0));
    }
  }

  Vfs clone() => Vfs._(root.clone())
    ..clock = clock
    ..umask = umask;

  int tick() => ++clock;

  /// [path] made absolute against [cwd], with . and .. resolved by name.
  static String absolute(String path, String cwd) {
    final parts = <String>[];
    final full = path.startsWith('/') ? path : '$cwd/$path';
    for (final p in full.split('/')) {
      if (p.isEmpty || p == '.') continue;
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else {
        parts.add(p);
      }
    }
    return '/${parts.join('/')}';
  }

  /// The node at [path], following links (the last one only if [follow]); null if missing.
  VNode? lookup(String path, String cwd, {bool follow = true}) => _walk(absolute(path, cwd), follow, 0)?.$1;

  /// The node and its real absolute path.
  (VNode, String)? _walk(String abs, bool follow, int depth) {
    if (depth > 20) throw ShError('Too many levels of symbolic links');
    final parts = abs.split('/').where((p) => p.isNotEmpty).toList();
    var cur = root;
    var real = <String>[];
    for (var i = 0; i < parts.length; i++) {
      if (!cur.isDir) return null;
      final next = cur.kids[parts[i]];
      if (next == null) return null;
      final last = i == parts.length - 1;
      if (next.isLink && (!last || follow)) {
        final target = absolute(next.data, '/${real.join('/')}');
        final rest = parts.sublist(i + 1).join('/');
        return _walk(rest.isEmpty ? target : '$target/$rest', follow, depth + 1);
      }
      real.add(parts[i]);
      cur = next;
    }
    return (cur, '/${real.join('/')}');
  }

  /// The real absolute path (links resolved).
  String realpath(String path, String cwd) {
    final r = _walk(absolute(path, cwd), true, 0);
    if (r == null) throw ShError('$path: No such file or directory');
    return r.$2;
  }

  /// The directory a new entry [path] goes in, and its name.
  (VNode, String) parentOf(String path, String cwd) {
    final abs = absolute(path, cwd);
    final i = abs.lastIndexOf('/');
    final dirPath = i <= 0 ? '/' : abs.substring(0, i);
    final name = abs.substring(i + 1);
    final dir = lookup(dirPath, '/');
    if (dir == null) throw ShError('$path: No such file or directory');
    if (!dir.isDir) throw ShError('$path: Not a directory');
    if (name.isEmpty) throw ShError('$path: Is a directory');
    return (dir, name);
  }

  /// May the student [what] ('r', 'w' or 'x') this node?
  static bool may(VNode n, String what) {
    final bit = what == 'r' ? 4 : what == 'w' ? 2 : 1;
    final shift = n.owner == user ? 6 : 0;
    return (n.mode >> shift) & bit != 0;
  }

  static void need(VNode n, String what, String name) {
    if (!may(n, what)) throw ShError('$name: Permission denied');
  }

  /// A file's text, checking it exists and can be read.
  String read(String path, String cwd) {
    final n = lookup(path, cwd);
    if (n == null) throw ShError('$path: No such file or directory');
    if (n.isDir) throw ShError('$path: Is a directory');
    need(n, 'r', path);
    return n.data;
  }

  /// Writes (or appends to) a file, creating it with the umask's permissions.
  void write(String path, String cwd, String text, {bool append = false}) {
    final existing = lookup(path, cwd);
    if (existing != null) {
      if (existing.isDir) throw ShError('$path: Is a directory');
      need(existing, 'w', path);
      existing.data = append ? existing.data + text : text;
      existing.mtime = tick();
      return;
    }
    final (dir, name) = parentOf(path, cwd);
    need(dir, 'w', path);
    // a dangling link: write where it points
    final l = dir.kids[name];
    if (l != null && l.isLink) {
      write(absolute(l.data, absolute('$path/..', cwd)), '/', text, append: append);
      return;
    }
    dir.kids[name] = VNode.file(text, 438 & ~umask, user, tick());
  }

  VNode mkdir(String path, String cwd, {bool parents = false}) {
    if (parents) {
      final abs = absolute(path, cwd);
      var cur = '/';
      VNode? n;
      for (final p in abs.split('/').where((p) => p.isNotEmpty)) {
        cur = cur == '/' ? '/$p' : '$cur/$p';
        n = lookup(cur, '/');
        if (n == null) {
          n = mkdir(cur, '/');
        } else if (!n.isDir) {
          throw ShError("cannot create directory '$path': File exists");
        }
      }
      return n ?? root;
    }
    if (lookup(path, cwd, follow: false) != null) throw ShError("cannot create directory '$path': File exists");
    final (dir, name) = parentOf(path, cwd);
    if (!may(dir, 'w')) throw ShError("cannot create directory '$path': Permission denied");
    final d = VNode.dir(511 & ~umask, user, tick());
    dir.kids[name] = d;
    return d;
  }

  void remove(String path, String cwd) {
    final (dir, name) = parentOf(path, cwd);
    if (!dir.kids.containsKey(name)) throw ShError("cannot remove '$path': No such file or directory");
    if (!may(dir, 'w')) throw ShError("cannot remove '$path': Permission denied");
    dir.kids.remove(name);
    dir.mtime = tick();
  }

  /// Puts [node] at [path] (replacing a file there).
  void place(String path, String cwd, VNode node) {
    final (dir, name) = parentOf(path, cwd);
    need(dir, 'w', path);
    dir.kids[name] = node;
    dir.mtime = tick();
  }

  /// Every path under [abs] (itself first), depth first, names sorted; links not followed.
  Iterable<(String, VNode, int)> walk(String abs, VNode n, [int depth = 0]) sync* {
    yield (abs, n, depth);
    if (n.isDir) {
      for (final e in n.kids.entries) {
        yield* walk(abs == '/' ? '/${e.key}' : '$abs/${e.key}', e.value, depth + 1);
      }
    }
  }

  /// `-rwxr-x---` for a node.
  static String modeString(VNode n) {
    final t = n.isDir ? 'd' : n.isLink ? 'l' : '-';
    final b = StringBuffer(t);
    for (var s = 6; s >= 0; s -= 3) {
      final m = (n.mode >> s) & 7;
      b.write(m & 4 != 0 ? 'r' : '-');
      b.write(m & 2 != 0 ? 'w' : '-');
      b.write(m & 1 != 0 ? 'x' : '-');
    }
    return b.toString();
  }

  /// Applies a chmod mode: octal ("750") or symbolic ("u+x,go-w", "a=r").
  static int applyMode(int mode, String spec, bool isDir) {
    if (RegExp(r'^[0-7]{1,4}$').hasMatch(spec)) return int.parse(spec, radix: 8) & 0xfff;
    var m = mode;
    for (final clause in spec.split(',')) {
      final match = RegExp(r'^([ugoa]*)([-+=])([rwxX]*)$').firstMatch(clause);
      if (match == null) throw ShError("invalid mode: '$spec'");
      var who = match.group(1)!;
      if (who.isEmpty) who = 'a';
      final op = match.group(2)!;
      var bits = 0;
      for (final c in match.group(3)!.split('')) {
        if (c == 'r') bits |= 4;
        if (c == 'w') bits |= 2;
        if (c == 'x') bits |= 1;
        if (c == 'X' && (isDir || mode & 73 != 0)) bits |= 1;
      }
      for (final w in who.split('')) {
        final shifts = w == 'a' ? [6, 3, 0] : [w == 'u' ? 6 : w == 'g' ? 3 : 0];
        for (final s in shifts) {
          if (op == '+') m |= bits << s;
          if (op == '-') m &= ~(bits << s);
          if (op == '=') m = (m & ~(7 << s)) | (bits << s);
        }
      }
    }
    return m;
  }
}
