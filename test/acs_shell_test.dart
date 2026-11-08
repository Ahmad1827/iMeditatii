// The USO shell against the real bash: the same commands, on the same files,
// must print the same thing (C locale). Without bash on the machine, only
// the cases with a written answer run.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:iMeditatii/acs/engine/shell.dart';
import 'package:iMeditatii/acs/engine/vfs.dart';

const files = {
  'notes.txt': 'alpha\nBeta\ngamma delta\nalpha\n\nepsilon 42\n',
  'nums.txt': '3\n1\n2\n10\n2\n',
  'users.csv': 'ana,22,bucuresti\nion,31,cluj\nmaria,27,iasi\ndan,19,cluj\nelena,35,bucuresti\n',
  'log/app.log': 'INFO start\nERROR disk full\nWARN low memory\nERROR timeout\nINFO stop\n',
  'log/old.log': 'ERROR old\n',
  'src/a.c': 'int main(){}\n',
  'src/b.h': '#define X 1\n',
  'script.sh': '#!/bin/bash\necho "args: \$#"\nfor x in "\$@"; do echo "[\$x]"; done\n',
};

const cases = [
  'echo hello world',
  'echo "a  b"   c',
  "echo 'single \$HOME'",
  'x=5; echo \$((x * 3 + 1))',
  'cat notes.txt | wc -l',
  'wc -l notes.txt',
  'wc notes.txt',
  'wc -w < notes.txt',
  'sort nums.txt',
  'sort -n nums.txt',
  'sort -nr nums.txt | head -2',
  'sort -u nums.txt',
  'sort nums.txt | uniq -c',
  'sort nums.txt | uniq -d',
  'cut -d, -f1,3 users.csv',
  'cut -d, -f2- users.csv | head -2',
  'cut -c1-3 notes.txt',
  'sort -t, -k2 -n users.csv',
  'sort -t, -k3,3 -k2,2nr users.csv',
  'grep alpha notes.txt',
  'grep -c alpha notes.txt',
  'grep -i beta notes.txt',
  'grep -v a notes.txt',
  'grep -n ERROR log/app.log',
  'grep -r ERROR log | sort',
  'grep -rl ERROR . | sort',
  "grep -E '^(INFO|WARN)' log/app.log",
  "grep -o '[0-9]\\+' notes.txt",
  "grep -w alpha notes.txt",
  'tr a-z A-Z < notes.txt',
  "tr -d 'a' < notes.txt",
  "tr -s '\\n' < notes.txt",
  'head -n 2 notes.txt',
  'tail -n 2 notes.txt',
  'tail -n +3 nums.txt',
  'head -c 7 notes.txt',
  "sed 's/alpha/ALFA/' notes.txt",
  "sed -n '2,3p' notes.txt",
  "sed '/^\$/d' notes.txt",
  "sed -E 's/([a-z]+) ([a-z]+)/\\2 \\1/' notes.txt",
  "sed 's/a/A/g' notes.txt | head -3",
  "sed -n '2~2p' nums.txt",
  "sed '1d;\$d' nums.txt",
  "awk -F, '{print \$1}' users.csv",
  "awk -F, '\$2 > 25 {print \$1, \$2}' users.csv",
  "awk -F, '{s += \$2} END {print s}' users.csv",
  "awk -F, '{c[\$3]++} END {for (k in c) print k, c[k]}' users.csv | sort",
  "awk '{print NR \": \" \$0}' nums.txt",
  "awk 'NF > 1' notes.txt",
  "awk '{print \$NF}' notes.txt",
  "awk -F, '{printf \"%-6s|%3d\\n\", \$1, \$2}' users.csv",
  "awk 'BEGIN {x = 7; print x / 2, x % 4, length(\"abc\")}'",
  "awk -F, 'NR == 2 {print toupper(\$1)}' users.csv",
  "awk '{gsub(/a/, \"@\"); print}' notes.txt",
  'find . -name "*.log" | sort',
  'find . -type d | sort',
  'find src -type f -name "*.c"',
  'find . -maxdepth 1 -type f | sort',
  'ls',
  'ls src log',
  'ls -a src',
  'ls | wc -l',
  'ls *.txt',
  'echo src/*',
  'echo {a,b}{1,2}',
  'echo {1..5}',
  'for i in 1 2 3; do echo "n=\$i"; done',
  'i=0; while [ \$i -lt 3 ]; do echo \$i; i=\$((i+1)); done',
  'if [ -f notes.txt ]; then echo yes; else echo no; fi',
  'if [ -d nothere ]; then echo yes; else echo no; fi',
  '[ 3 -gt 2 ] && echo ok || echo bad',
  'test -z "" && echo empty',
  'a=hello; echo \${#a} \${a^^} \${a:1:3}',
  'f=archive.tar.gz; echo \${f%.gz} \${f%%.*} \${f#*.} \${f##*.}',
  's="a b c"; for w in \$s; do echo "<\$w>"; done',
  's="a b c"; for w in "\$s"; do echo "<\$w>"; done',
  'echo \$(echo inner) `echo back`',
  'echo "today: \$(wc -l < nums.txt) lines"',
  'printf "%s=%d\\n" a 1 b 2',
  'printf "%5.2f|%-4s|%03d\\n" 3.14159 ab 7',
  'bash script.sh one "two three"',
  'mkdir -p d/e/f && ls d/e',
  'touch t1 t2 && ls t*',
  'cp notes.txt n2.txt && cat n2.txt | wc -c',
  'mv nums.txt numbers.txt && ls numbers.txt',
  'rm notes.txt && ls notes.txt; echo \$?',
  'cat nothere; echo \$?',
  'false; echo \$?',
  'echo a > o.txt; echo b >> o.txt; cat o.txt',
  'echo err 1>&2 2>/dev/null; echo done',
  'ls nothere 2>/dev/null; echo st=\$?',
  'cat <<EOF\nline \$HOME\nEOF',
  'case abc in a*) echo starts;; *) echo other;; esac',
  'f() { echo "fn \$1"; return 3; }; f x; echo \$?',
  'seq 3',
  'seq 2 2 8',
  'seq -s, 4',
  'basename /a/b/c.txt .txt; dirname /a/b/c.txt',
  'echo a,b,c | tr , "\\n" | sort -r',
  'paste -sd+ numbers.txt 2>/dev/null || paste -sd+ nums.txt',
  'expr 7 + 3 \\* 2',
  'x=10; let x+=5; echo \$x',
  'echo "\$((2**10)) \$((17 % 5)) \$((7 / 2))"',
  'cat users.csv | awk -F, \'{print \$3}\' | sort | uniq -c | sort -rn | head -1',
  'chmod 750 script.sh && ls -l script.sh | cut -c1-10',
  'chmod u=rw,go= notes.txt && stat -c %a notes.txt',
  'chmod +x script.sh && ./script.sh z',
  'umask 077; touch secret; stat -c %a secret',
  'ln -s notes.txt link && cat link | head -1',
  'echo "  spaced   out  " | xargs echo',
  'nl nums.txt',
  'rev <<< "abc"',
  'read a b <<< "x y z"; echo "\$a|\$b"',
  'while read line; do echo "> \$line"; done < nums.txt',
  'diff nums.txt notes.txt | head -3',
];

void main() {
  final hasBash = !Platform.isWindows && File('/bin/bash').existsSync();

  Shell fresh() {
    final fs = Vfs.standard();
    final sh = Shell(fs);
    for (final e in files.entries) {
      final path = '${Vfs.home}/${e.key}';
      final dir = path.substring(0, path.lastIndexOf('/'));
      fs.mkdir(dir, '/', parents: true);
      fs.write(path, '/', e.value);
    }
    return sh;
  }

  String ours(String cmd) {
    final sh = fresh();
    final out = sh.run(cmd, tty: false);
    return out.where((c) => !c.$2).map((c) => c.$1).join();
  }

  String theirs(String cmd) {
    final dir = Directory.systemTemp.createTempSync('acs_sh');
    try {
      for (final e in files.entries) {
        final f = File('${dir.path}/${e.key}');
        f.parent.createSync(recursive: true);
        f.writeAsStringSync(e.value);
      }
      final r = Process.runSync('/bin/bash', ['--norc', '--noprofile', '-c', cmd],
          workingDirectory: dir.path, environment: {'LC_ALL': 'C', 'HOME': Vfs.home, 'PATH': '/usr/bin:/bin'}, includeParentEnvironment: false);
      return r.stdout as String;
    } finally {
      dir.deleteSync(recursive: true);
    }
  }

  group('the same as bash', () {
    for (final c in cases) {
      test(c.replaceAll('\n', r'\n'), () {
        expect(ours(c), theirs(c));
      }, skip: hasBash ? false : 'no bash here');
    }
  });

  test('permissions are enforced', () {
    final sh = fresh();
    expect(sh.run('chmod 000 notes.txt; cat notes.txt').map((c) => c.$1).join(), contains('Permission denied'));
    expect(sh.run('./script.sh').map((c) => c.$1).join(), contains('Permission denied'));
    expect(sh.run('echo hi > /etc/x').map((c) => c.$1).join(), contains('Permission denied'));
  });

  test('an endless loop stops', () {
    final sh = fresh();
    final out = sh.run('while true; do :; done').map((c) => c.$1).join();
    expect(out, contains('buclă infinită'));
  });

  test('nano asks the page for the editor', () {
    final sh = fresh();
    String? opened;
    sh.onEdit = (p) => opened = p;
    sh.run('nano proiect/x.txt');
    expect(opened, '${Vfs.home}/proiect/x.txt');
  });

  test('a command split over lines waits for the rest', () {
    expect(Shell.complete('for i in 1 2; do'), isFalse);
    expect(Shell.complete('echo "abc'), isFalse);
    expect(Shell.complete('for i in 1 2; do echo \$i; done'), isTrue);
  });
}
