// The coding style check: what it circles, and that its fixes give clean code.
import 'package:flutter_test/flutter_test.dart';

import 'package:iMeditatii/code_style.dart';

List<String> msgs(String code, {String lang = 'cpp'}) => [for (final i in CodeStyle.check(code, lang: lang)) '${i.line}: ${i.message}'];

void main() {
  const clean = '''
#include <iostream>
using namespace std;

int main() {
    int n, s = 0;
    cin >> n;
    for (int i = 0; i < n; i++) {
        if (i % 2 == 0 && i != 4) {
            s += i;
        } else {
            s -= i;
        }
    }
    cout << s << "\\n"; // a,b=c  in a comment and "x,y" in a string don't count
    return 0;
}''';

  test('a clean program has no issues and scores 100', () {
    expect(msgs(clean), isEmpty);
    expect(CodeStyle.score(CodeStyle.check(clean)), 100);
  });

  test('the usual mistakes are found on their lines', () {
    const messy = '''
#include <iostream>
using namespace std;
int main(){
int n,s=0;
    cin>>n;
    for(int i=0;i<n;i++) {
        if (i%2==0) s+=i;\x20\x20
    }
    s = 1; n = 2;
    return 0;
}''';
    final m = msgs(messy);
    expect(m, contains('3: Pune un spațiu înainte de `{`.'));
    expect(m, contains('4: Indentare: aici 4 spații, nu 0.'));
    expect(m, contains('4: Pune un spațiu după virgulă.'));
    expect(m, contains('4: Pune câte un spațiu de o parte și de alta a lui `=`.'));
    expect(m, contains('5: Pune câte un spațiu de o parte și de alta a lui `>>`.'));
    expect(m, contains('6: Pune un spațiu între `for` și `(`.'));
    expect(m, contains('6: Pune un spațiu după `;` în `for`.'));
    expect(m, contains('6: Pune câte un spațiu de o parte și de alta a lui `<`.'));
    expect(m, contains('7: Pune câte un spațiu de o parte și de alta a lui `==`.'));
    expect(m, contains('7: Pune câte un spațiu de o parte și de alta a lui `%`.'));
    expect(m, contains('7: Spații la sfârșitul liniei.'));
    expect(m, contains('9: O singură instrucțiune pe linie: mut-o pe linia următoare.'));
    expect(CodeStyle.score(CodeStyle.check(messy)), lessThan(80));
  });

  test('fix all leaves only what has no fix', () {
    const messy = 'int main(){\nint a,b;\nif(a==b){\na=b;\n}\nreturn 0;\n}';
    final fixed = CodeStyle.fixAll(messy, CodeStyle.check(messy));
    expect(fixed, 'int main() {\n    int a, b;\n    if (a == b) {\n        a = b;\n    }\n    return 0;\n}');
    expect(msgs(fixed), isEmpty);
  });

  test('brackets without a pair are errors, and the indentation is not guessed then', () {
    final m = msgs('int main() {\n    if (x {\n    }\n');
    expect(m.where((e) => e.contains('nu e închisă') || e.contains('Se aștepta')), isNotEmpty);
    expect(m.where((e) => e.contains('Indentare')), isEmpty);
  });

  test('templates, pointers and shifts are not taken for comparisons', () {
    expect(msgs('int main() {\n    for (pair<int, int> a : v) {\n    }\n}'), isEmpty);
    expect(msgs('int main() {\n    vector<int> v;\n    int x = 1 << 3;\n    p->x = 2;\n    if (p->x > 0) {\n    }\n}'), isEmpty);
  });

  test('python: indentation by 4, keyword arguments without spaces', () {
    const py = 'def f(x, y=1):\n  return x+y\n\nprint(f(2,y=3), end="")\n';
    final m = msgs(py, lang: 'python');
    expect(m, contains('2: Indentarea în Python: câte 4 spații pe nivel (aici 2).'));
    expect(m, contains('4: Pune un spațiu după virgulă.'));
    expect(m.where((e) => e.contains('`=`')), isEmpty);
    expect(msgs('n = int(input())\nif n == 1:\n    print("da", n // 2, n % 3, n / 4)\n', lang: 'python'), isEmpty);
    expect(msgs('print(n//2)', lang: 'python'), ['1: Pune câte un spațiu de o parte și de alta a lui `//`.']);
  });

  test("the compiler's errors land on their lines, explained", () {
    const code = 'int main() {\n    int x = 1\n    y = 2;\n}';
    const out = 'main.cpp:2:14: error: expected \';\' at end of declaration\n'
        'main.cpp:3:5: error: use of undeclared identifier \'y\'\n';
    final e = CodeStyle.fromCompiler(out, code);
    expect(e.map((i) => '${i.line}:${i.col} ${i.message}'), [
      '2:13 Lipsește `;` (de obicei la sfârșitul instrucțiunii de dinainte).',
      '3:4 `y` nu e declarat: declară-l (de ex. `int y;`) sau verifică scrierea.',
    ]);
    final py = CodeStyle.fromCompiler('Traceback (most recent call last):\n  File "<exec>", line 2, in <module>\nNameError: name \'z\' is not defined',
        'x = 1\nprint(z)', lang: 'python');
    expect(py.single.line, 2);
    expect(py.single.message, contains('`z` nu e definit'));
  });
}
