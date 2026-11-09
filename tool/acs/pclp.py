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

def write(id, title, chapter, diff, desc, inp, out, constraints, ref, tests, hint, sol, source=''):
    """A program written from the start: the reference must pass every test."""
    tests = check(title, ref, [{'input': t} for t in tests])
    st = statement(desc, inp, out, constraints, (tests[0]['input'], tests[0]['output']))
    PROBLEMS.append(problem(id, title, chapter, diff, st, 'c', {'tests': tests, 'starter': C_START, 'reference': ref}, hint, sol + '\n\n```c\n' + ref.strip() + '\n```', source))


S2, S3, S4 = CHAPTERS[1], CHAPTERS[2], CHAPTERS[3]

write(17, 'Cel mai lung cuvânt', S2, 'ușoară', '''
Se citește o linie de text (cel mult 1000 de caractere). Cuvintele sunt despărțite de unul sau mai multe spații. Afișează cel mai lung cuvânt și lungimea lui; dacă sunt mai multe la fel de lungi, pe **primul**.''',
    'O linie de text, cu cel puțin un cuvânt.', 'Cuvântul, un spațiu și lungimea lui.', ['linia are cel mult 1000 de caractere'],
    """#include <stdio.h>
#include <string.h>

int main(void) {
    char s[1002], best[1002] = "";
    if (!fgets(s, sizeof s, stdin)) return 0;
    s[strcspn(s, "\\n")] = 0;
    for (char *w = strtok(s, " "); w; w = strtok(NULL, " "))
        if (strlen(w) > strlen(best)) strcpy(best, w);
    printf("%s %zu\\n", best, strlen(best));
    return 0;
}
""", ['programarea calculatoarelor e frumoasa\n', 'a bb cc d\n', '   spatii   la   inceput\n', 'unu\n', 'x yy zzz yyy zzzz\n'],
    '`strtok(s, " ")` dă pe rând cuvintele (sare peste spațiile repetate). Nu uita să scoți `\\n` pe care îl lasă `fgets`.',
    'Ții cel mai lung cuvânt găsit până acum și îl înlocuiești doar la o lungime **strict** mai mare: așa rămâne primul dintre cele egale.')

write(18, 'Palindrom, fără spații și semne', S2, 'medie', '''
Se citește o linie de text. Spune dacă e palindrom când se iau în seamă **doar literele**, fără să conteze majusculele (de exemplu `Ene purta patru pene.` e palindrom). Afișează `DA` sau `NU`.''',
    'O linie de text, cu cel puțin o literă.', '`DA` sau `NU`.', ['linia are cel mult 1000 de caractere', 'textul folosește doar caractere ASCII'],
    """#include <stdio.h>
#include <string.h>
#include <ctype.h>

int main(void) {
    char s[1002];
    if (!fgets(s, sizeof s, stdin)) return 0;
    int i = 0, j = (int)strlen(s) - 1, ok = 1;
    while (i < j) {
        if (!isalpha((unsigned char)s[i])) { i++; continue; }
        if (!isalpha((unsigned char)s[j])) { j--; continue; }
        if (tolower((unsigned char)s[i]) != tolower((unsigned char)s[j])) { ok = 0; break; }
        i++; j--;
    }
    printf("%s\\n", ok ? "DA" : "NU");
    return 0;
}
""", ['Ene purta patru pene.\n', 'Ana are mere\n', 'Step on no pets!\n', 'a\n', 'ab, BA\n', 'abca\n'],
    'Doi indici, unul de la început și unul de la sfârșit, care sar peste ce nu e literă (`isalpha`) și compară cu `tolower`.',
    'Fără să copiezi textul: indicii se apropie, fiecare oprindu-se doar la litere.')

write(19, 'Biți de 1 și puteri ale lui 2', S3, 'ușoară', '''
Pentru fiecare număr natural citit, afișează câți biți de 1 are în reprezentarea binară și dacă e o putere a lui 2 (`DA` / `NU`).''',
    'Numere naturale mai mici decât $2^{32}$, câte unul pe linie, până la sfârșitul intrării.', 'Pentru fiecare număr, o linie: numărul de biți de 1, un spațiu, `DA` sau `NU`.', ['0 nu e putere a lui 2'],
    """#include <stdio.h>

int main(void) {
    unsigned int x;
    while (scanf("%u", &x) == 1) {
        int c = 0;
        for (unsigned int y = x; y; y &= y - 1) c++;
        printf("%d %s\\n", c, x != 0 && (x & (x - 1)) == 0 ? "DA" : "NU");
    }
    return 0;
}
""", ['1\n6\n64\n', '0\n', '4294967295\n2147483648\n', '255\n256\n257\n'],
    '`x & (x - 1)` șterge cel mai din dreapta bit de 1 al lui `x`.',
    'De câte ori poți face `x &= x - 1` până ajungi la 0: atâția biți de 1. O putere a lui 2 are exact un bit de 1: `x != 0 && (x & (x - 1)) == 0`.')

write(20, 'Rotația unui octet', S3, 'medie', '''
Se citesc un octet `b` (0 ≤ b ≤ 255) și un număr `k`. Afișează octetul rotit **la stânga** cu `k` poziții (biții care ies prin stânga intră prin dreapta), în zecimal și apoi pe 8 biți.''',
    'Pe o linie, `b` și `k`.', 'Valoarea rotită, un spațiu, și cei 8 biți ai ei.', ['0 ≤ b ≤ 255', '0 ≤ k ≤ 1000'],
    """#include <stdio.h>

int main(void) {
    unsigned int b, k;
    scanf("%u %u", &b, &k);
    k %= 8;
    unsigned char r = (unsigned char)((b << k) | (b >> ((8 - k) % 8)));
    printf("%u ", r);
    for (int i = 7; i >= 0; i--) putchar(r >> i & 1 ? '1' : '0');
    putchar('\\n');
    return 0;
}
""", ['150 1\n', '1 7\n', '255 3\n', '128 1\n', '77 0\n', '77 8\n', '6 1003\n'],
    'O rotație cu 8 poziții lasă octetul neschimbat: lucrează cu `k % 8`. Rotația = `(b << k) | (b >> (8 - k))`, păstrând doar ultimii 8 biți.',
    'Atenție la `k % 8 == 0`: atunci deplasarea la dreapta trebuie să fie tot 0 (de aici `% 8`). Rezultatul pus într-un `unsigned char` taie biții de peste 8.')

write(21, 'Clasamentul', S4, 'medie', '''
Se citesc `n` studenți, fiecare cu nume și medie. Afișează-i în ordinea **descrescătoare a mediei**; la medii egale, în ordine **alfabetică** a numelui. Folosește un vector de structuri și `qsort`.''',
    'Pe prima linie `n`; pe următoarele `n` linii, un nume (fără spații, cel mult 30 de caractere) și o medie cu două zecimale.', 'Câte un student pe linie: numele și media, cu două zecimale.', ['1 ≤ n ≤ 1000'],
    """#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    char nume[32];
    double medie;
} Student;

int cmp(const void *a, const void *b) {
    const Student *x = a, *y = b;
    if (x->medie != y->medie) return x->medie < y->medie ? 1 : -1;
    return strcmp(x->nume, y->nume);
}

int main(void) {
    int n;
    scanf("%d", &n);
    Student *v = malloc(n * sizeof *v);
    for (int i = 0; i < n; i++) scanf("%31s %lf", v[i].nume, &v[i].medie);
    qsort(v, n, sizeof *v, cmp);
    for (int i = 0; i < n; i++) printf("%s %.2f\\n", v[i].nume, v[i].medie);
    free(v);
    return 0;
}
""", ['4\nIonescu 8.50\nPopescu 9.25\nAdam 8.50\nMarin 7.00\n', '1\nUnul 10.00\n', '3\nc 5.00\nb 5.00\na 5.00\n', '5\nE 6.10\nD 9.90\nC 6.10\nB 9.90\nA 1.00\n'],
    'Funcția de comparare întoarce un număr negativ când primul trebuie să stea înainte. Compară mediile, iar la egalitate numele cu `strcmp`.',
    'Nu întoarce `y->medie - x->medie` convertit la `int`: diferențele sub 1 ar deveni 0. Compară explicit.')

write(22, 'Transpusa, alocată dinamic', S4, 'medie', '''
Se citește o matrice cu `n` linii și `m` coloane. Alocă dinamic (cu `malloc`) matricea și transpusa ei, afișează transpusa (`m` linii cu câte `n` numere) și eliberează memoria.''',
    'Pe prima linie `n` și `m`; apoi `n` linii cu câte `m` numere întregi.', 'Transpusa: `m` linii cu câte `n` numere separate prin spațiu.', ['1 ≤ n, m ≤ 300'],
    """#include <stdio.h>
#include <stdlib.h>

int main(void) {
    int n, m;
    scanf("%d %d", &n, &m);
    int **a = malloc(n * sizeof *a);
    for (int i = 0; i < n; i++) {
        a[i] = malloc(m * sizeof **a);
        for (int j = 0; j < m; j++) scanf("%d", &a[i][j]);
    }
    int **t = malloc(m * sizeof *t);
    for (int j = 0; j < m; j++) {
        t[j] = malloc(n * sizeof **t);
        for (int i = 0; i < n; i++) t[j][i] = a[i][j];
    }
    for (int j = 0; j < m; j++) {
        for (int i = 0; i < n; i++) printf("%d%c", t[j][i], i + 1 < n ? ' ' : '\\n');
        free(t[j]);
    }
    for (int i = 0; i < n; i++) free(a[i]);
    free(a);
    free(t);
    return 0;
}
""", ['2 3\n1 2 3\n4 5 6\n', '1 1\n7\n', '3 1\n1\n2\n3\n', '1 4\n-1 0 1 2\n'],
    'O matrice dinamică: un vector de `n` pointeri (`int **`), fiecare spre o linie de `m` întregi.',
    'Fiecare `malloc` are perechea lui `free`: întâi liniile, apoi vectorul de pointeri.')

fix(23, 'Media care iese întreagă', 'ușoară', '''
Programul citește `n` note și ar trebui să afișeze media lor, cu două zecimale.''',
    'Pe prima linie `n` (1 ≤ n ≤ 100), pe a doua `n` note întregi între 1 și 10.', 'Media, cu două zecimale.',
    """#include <stdio.h>

int main(void) {
    int n, x, s = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) {
        scanf("%d", &x);
        s += x;
    }
    double m = s / n;
    printf("%.2f\\n", m);
    return 0;
}
""", """#include <stdio.h>

int main(void) {
    int n, x, s = 0;
    scanf("%d", &n);
    for (int i = 0; i < n; i++) {
        scanf("%d", &x);
        s += x;
    }
    double m = (double)s / n;
    printf("%.2f\\n", m);
    return 0;
}
""", ['3\n7 8 10\n', '2\n10 10\n', '4\n5 6 6 6\n', '1\n9\n'],
    'Ce tip are `s / n` când `s` și `n` sunt `int`? Contează că rezultatul ajunge într-un `double`?',
    '`s / n` e o împărțire **întreagă** (25 / 3 = 8), făcută înainte de conversia la `double`. Unul dintre operanzi trebuie să fie real: `(double)s / n`.')

write_course('pclp', CHAPTERS, PROBLEMS)
