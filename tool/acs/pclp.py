"""PCLP — Programarea Calculatoarelor: C programs checked on tests.

The exam problems (PCLP seria CD, 2015–2020) are in data/pclp_c.json; the
"repair the program" tasks below come from the exams' Subiectul 2 (what a
piece of code really does): the starter is that code, with its bug.
"""
import json, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course
from cprob import C_START, statement, check

C0 = '1. Programe de reparat'
CHAPTERS = [C0, '2. Șiruri de caractere', '3. Operații pe biți', '4. Structuri și alocare dinamică', '5. Probleme de examen']
RENAME = {'5. Subiectul 1 · Probleme de examen': '5. Probleme de examen'}

PROBLEMS = []

HERE = os.path.dirname(os.path.abspath(__file__))
for k, p in enumerate(json.load(open(os.path.join(HERE, 'data', 'pclp_c.json'))), start=7):
    tests = check(p['title'], p['code'], [dict(t) for t in p['tests']])
    st = statement(p['description'], p['input'], p['output'], p['constraints'], (tests[0]['input'], tests[0]['output']))
    sol = p['solution'] or ''
    sol = (sol + '\n\n' if sol else '') + '```c\n' + p['code'].strip() + '\n```'
    PROBLEMS.append(problem(k, p['title'], RENAME.get(p['chapter'], p['chapter']), p['difficulty'], st, 'c',
                            {'tests': tests, 'starter': C_START, 'reference': p['code']}, p['hint'], sol, p['source']))


def fix(id, title, diff, desc, inp, out, buggy, good, tests, hint, sol, source=''):
    tests = check(title, good, [{'input': t} for t in tests], starter=buggy)
    st = statement(desc + '\n\nProgramul de mai jos (în editor) se compilează, dar nu face ce trebuie. **Găsește greșeala și repar-o**: testele trebuie să treacă.', inp, out, [], (tests[0]['input'], tests[0]['output']))
    PROBLEMS.append(problem(id, title, C0, diff, st, 'c', {'tests': tests, 'starter': buggy, 'reference': good}, hint, sol + '\n\n```c\n' + good.strip() + '\n```', source))


fix(1, 'Minimul și maximul care nu se întorc', 'ușoară', '''
Funcția `minmax` ar trebui să găsească cel mai mic și cel mai mare element al unui vector și să le dea înapoi programului principal, care le afișează.''',
    'Pe prima linie `n` (1 ≤ n ≤ 1000), pe a doua `n` numere întregi.', 'Minimul și maximul, separate printr-un spațiu.',
    '''#include <stdio.h>

void minmax(int v[], int n, int mn, int mx) {
    mn = mx = v[0];
    for (int i = 1; i < n; i++) {
        if (v[i] < mn) mn = v[i];
        if (v[i] > mx) mx = v[i];
    }
}

int main(void) {
    int n, v[1000], mn = 0, mx = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) scanf("%d", &v[i]);
    minmax(v, n, mn, mx);
    printf("%d %d\\n", mn, mx);
    return 0;
}
''', '''#include <stdio.h>

void minmax(int v[], int n, int *mn, int *mx) {
    *mn = *mx = v[0];
    for (int i = 1; i < n; i++) {
        if (v[i] < *mn) *mn = v[i];
        if (v[i] > *mx) *mx = v[i];
    }
}

int main(void) {
    int n, v[1000], mn = 0, mx = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) scanf("%d", &v[i]);
    minmax(v, n, &mn, &mx);
    printf("%d %d\\n", mn, mx);
    return 0;
}
''', ['5\n3 9 -2 7 4\n', '1\n42\n', '4\n-1 -5 -3 -4\n', '6\n0 0 0 0 0 1\n'],
    'În C argumentele se transmit prin valoare: funcția primește copii ale lui `mn` și `mx`. Ca să le schimbe pe cele din `main`, are nevoie de adresele lor.',
    'Parametrii devin pointeri (`int *mn, int *mx`), funcția scrie prin ei (`*mn = ...`), iar `main` le trimite adresele (`&mn, &mx`).',
    'Examen PCLP · Subiectul 2 · recursivitate cu pointer de ieșire')

fix(2, 'Macroul pentru paritate', 'medie', '''
Programul citește `n` numere și afișează câte dintre ele au **succesorul** (numărul + 1) impar, adică sunt pare. Folosește un macrou ca să testeze paritatea.''',
    'Pe prima linie `n`, apoi `n` numere naturale.', 'Câte numere `x` au `x + 1` impar.',
    '''#include <stdio.h>

#define IMPAR(x) x % 2 == 1

int main(void) {
    int n, x, cate = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) {
        scanf("%d", &x);
        if (IMPAR(x + 1))
            cate++;
    }
    printf("%d\\n", cate);
    return 0;
}
''', '''#include <stdio.h>

#define IMPAR(x) ((x) % 2 == 1)

int main(void) {
    int n, x, cate = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) {
        scanf("%d", &x);
        if (IMPAR(x + 1))
            cate++;
    }
    printf("%d\\n", cate);
    return 0;
}
''', ['5\n1 2 3 4 6\n', '3\n7 9 11\n', '4\n0 10 20 31\n', '1\n8\n'],
    'Un macrou înlocuiește text, nu calculează valori. Scrie de mână ce devine `IMPAR(x + 1)`.',
    '`IMPAR(x + 1)` devine `x + 1 % 2 == 1`, adică `x + (1 % 2) == 1`, adică `x + 1 == 1`. Parametrii unui macrou (și tot macroul) se pun între paranteze.',
    'Examen PCLP · Subiectul 2 · macrouri pentru paritate')

fix(3, 'Lungimea unui vector primit ca parametru', 'medie', '''
Funcția `media` calculează media elementelor unui vector. Programul citește un vector și afișează media cu două zecimale.''',
    'Pe prima linie `n` (1 ≤ n ≤ 100), pe a doua `n` numere întregi.', 'Media, cu două zecimale.',
    '''#include <stdio.h>

double media(int v[]) {
    int n = sizeof(v) / sizeof(v[0]);
    double s = 0;
    for (int i = 0; i < n; i++)
        s += v[i];
    return s / n;
}

int main(void) {
    int n, v[100];
    scanf("%d", &n);
    for (int i = 0; i < n; i++) scanf("%d", &v[i]);
    printf("%.2f\\n", media(v));
    return 0;
}
''', '''#include <stdio.h>

double media(int v[], int n) {
    double s = 0;
    for (int i = 0; i < n; i++)
        s += v[i];
    return s / n;
}

int main(void) {
    int n, v[100];
    scanf("%d", &n);
    for (int i = 0; i < n; i++) scanf("%d", &v[i]);
    printf("%.2f\\n", media(v, n));
    return 0;
}
''', ['4\n1 2 3 4\n', '1\n7\n', '5\n10 -10 3 3 4\n', '3\n1 1 2\n'],
    'Ce primește de fapt o funcție când îi dai un vector? Afișează `sizeof(v)` în funcție și în `main`.',
    'Un vector dat ca parametru devine un pointer: în funcție `sizeof(v)` e mărimea unui pointer (4 sau 8), nu a vectorului. Lungimea se transmite separat.',
    'Examen PCLP · Subiectul 2 · sizeof pe pointer și pe tablou')

fix(4, 'Până la cuvântul „stop”', 'ușoară', '''
Programul citește cuvinte, câte unul pe rând, până la cuvântul `stop` (care nu se numără), și afișează câte cuvinte au fost înainte de el. După `stop` pot urma alte cuvinte, care nu contează.''',
    'Cuvinte de cel mult 30 de litere, separate prin spații sau linii noi; `stop` apare sigur.', 'Numărul de cuvinte dinainte de `stop`.',
    '''#include <stdio.h>
#include <string.h>

int main(void) {
    char s[31];
    int n = 0;
    while (scanf("%30s", s) == 1) {
        if (s == "stop")
            break;
        n++;
    }
    printf("%d\\n", n);
    return 0;
}
''', '''#include <stdio.h>
#include <string.h>

int main(void) {
    char s[31];
    int n = 0;
    while (scanf("%30s", s) == 1) {
        if (strcmp(s, "stop") == 0)
            break;
        n++;
    }
    printf("%d\\n", n);
    return 0;
}
''', ['unu doi trei stop patru\n', 'stop\n', 'a b c d e f stop g h\n', 'stopare stop\n'],
    '`s == "stop"` compară două adrese: a vectorului `s` și a literalului. Nu sunt niciodată egale.',
    'Șirurile se compară cu `strcmp`, care întoarce 0 când sunt egale.',
    'Examen PCLP · Subiectul 2 · strcmp și literal de șir')

fix(5, 'Bitul care nu se testează', 'medie', '''
Programul citește un număr `x` și afișează pozițiile biților egali cu 1 din el, de la 0 (bitul cel mai puțin semnificativ) la 31, separate prin spații.''',
    'Un număr natural `x` < 2³¹.', 'Pozițiile biților de 1, crescător, separate prin spații (o linie goală dacă x = 0).',
    '''#include <stdio.h>

int main(void) {
    unsigned int x;
    scanf("%u", &x);
    for (int k = 0; k < 32; k++)
        if (x & 1u << k != 0)
            printf("%d ", k);
    printf("\\n");
    return 0;
}
''', '''#include <stdio.h>

int main(void) {
    unsigned int x;
    scanf("%u", &x);
    for (int k = 0; k < 32; k++)
        if ((x & (1u << k)) != 0)
            printf("%d ", k);
    printf("\\n");
    return 0;
}
''', ['13\n', '1\n', '1024\n', '2147483647\n', '6\n'],
    'Care operator se aplică primul: `&`, `<<` sau `!=`? Caută tabelul de precedență al operatorilor din C.',
    '`!=` are prioritate mai mare decât `&`: `x & 1u << k != 0` înseamnă `x & ((1u << k) != 0)`, adică `x & 1`. Parantezele repară ordinea.',
    'Examen PCLP · Subiectul 2 · operații pe biți')

fix(6, 'Cazul de bază greșit', 'medie', '''
Funcția `suma_cifre` ar trebui să întoarcă suma cifrelor unui număr natural, recursiv. Programul citește numere până la sfârșitul intrării și afișează, pentru fiecare, suma cifrelor lui.''',
    'Numere naturale ≤ 2 000 000 000, câte unul pe linie.', 'Pentru fiecare număr, suma cifrelor, pe câte o linie.',
    '''#include <stdio.h>

int suma_cifre(int n) {
    if (n < 10)
        return 0;
    return n % 10 + suma_cifre(n / 10);
}

int main(void) {
    int n;
    while (scanf("%d", &n) == 1)
        printf("%d\\n", suma_cifre(n));
    return 0;
}
''', '''#include <stdio.h>

int suma_cifre(int n) {
    if (n < 10)
        return n;
    return n % 10 + suma_cifre(n / 10);
}

int main(void) {
    int n;
    while (scanf("%d", &n) == 1)
        printf("%d\\n", suma_cifre(n));
    return 0;
}
''', ['123\n', '0\n7\n', '999999999\n', '1000\n2000000000\n'],
    'Urmărește pe hârtie `suma_cifre(5)` și `suma_cifre(12)`. Ce se pierde la cazul de bază?',
    'Cazul de bază (`n < 10`) e chiar ultima cifră, care trebuie adunată: `return n;`, nu `return 0;`.',
    'Examen PCLP · Subiectul 2 · recursivitate')

write_course('pclp', CHAPTERS, PROBLEMS)
