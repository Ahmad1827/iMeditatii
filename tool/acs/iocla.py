"""IOCLA — Introducere în Organizarea Calculatoarelor și Limbaje de Asamblare.

Functions written in NASM (x86, 32 bits) and called as from C (cdecl), on the
in-browser emulator. Topics from the IOCLA labs and quizzes (seria CD, 2022).
Each test's expected result comes from the Python function beside it.
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course

C1 = '1. Registre și aritmetică'
C2 = '2. Operații pe biți'
C3 = '3. Vectori și șiruri'
C4 = '4. Stiva și apeluri de funcții'
CHAPTERS = [C1, C2, C3, C4]
Q = 'Laborator IOCLA'

PROBLEMS = []


def starter(name, sig, body='    ; scrie codul aici\n'):
    return f'''section .text
global {name}

; {sig}
{name}:
    push ebp
    mov ebp, esp
    ; primul argument e la [ebp+8], al doilea la [ebp+12], ...

{body}
    leave
    ret
'''


def s32(v):
    v &= 0xffffffff
    return v - (1 << 32) if v >= 1 << 31 else v


def add(id, title, ch, diff, statement, entry, sig, types, returns, cases, ref, hint='', solution='', source=Q, mem=None, starter_body=None):
    tests = []
    for args in cases:
        r = ref(*[list(a) if isinstance(a, list) else a for a in args])
        t = {'args': args}
        if returns != 'void':
            t['ret'] = r if not isinstance(r, tuple) else r[0]
        if mem:
            outs = r[1] if isinstance(r, tuple) else r
            t['mem'] = {str(k): v for k, v in mem(args, outs).items()}
        tests.append(t)
    spec = {'entry': entry, 'signature': sig, 'args': types, 'returns': returns, 'tests': tests,
            'starter': starter(entry, sig, starter_body or '    ; scrie codul aici\n'), 'reference': solution_code[id]}
    PROBLEMS.append(problem(id, title, ch, diff, statement, 'asm', spec, hint, solution or f'```nasm\n{solution_code[id].strip()}\n```', source))


solution_code = {}

# ------------------------------------------------------------------ 1
solution_code[1] = '''section .text
global medie

medie:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    add eax, [ebp+12]
    add eax, [ebp+16]
    cdq                 ; edx:eax = suma, cu semn
    mov ecx, 3
    idiv ecx            ; eax = cât, edx = rest
    leave
    ret
'''
add(1, 'Media a trei numere', C1, 'ușoară', '''
Scrie în asamblare funcția

```c
int medie(int a, int b, int c);
```

care întoarce media aritmetică a celor trei numere, **trunchiată spre 0**, ca în C: `(a + b + c) / 3`. Numerele pot fi negative.

Argumentele sunt pe stivă (cdecl): după `push ebp; mov ebp, esp`, `a` e la `[ebp+8]`, `b` la `[ebp+12]`, `c` la `[ebp+16]`. Rezultatul se întoarce în `eax`.''',
    'medie', 'int medie(int a, int b, int c)', ['int', 'int', 'int'], 'int',
    [[3, 4, 5], [1, 2, 2], [10, 20, 31], [-7, 1, 0], [-1, -1, -2], [1000000, 2000000, 3000001], [0, 0, 0]],
    lambda a, b, c: int((a + b + c) / 3),
    hint='`idiv` împarte `edx:eax` la operand: înainte, `cdq` extinde semnul lui `eax` în `edx`. Fără `cdq`, un număr negativ dă un rezultat greșit (sau o excepție).')

solution_code[2] = '''section .text
global diferenta

diferenta:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    sub eax, [ebp+12]
    jge gata            ; a - b >= 0: e deja pozitiv
    neg eax
gata:
    leave
    ret
'''
add(2, 'Distanța dintre două numere', C1, 'ușoară', '''
```c
int diferenta(int a, int b);   // |a - b|
```

Întoarce valoarea absolută a diferenței. Folosește o comparație și un salt condiționat (sau `neg`).''',
    'diferenta', 'int diferenta(int a, int b)', ['int', 'int'], 'int',
    [[7, 3], [3, 7], [-5, 5], [0, 0], [-10, -20], [123456, -654321]],
    lambda a, b: abs(a - b),
    hint='După `sub eax, ebx`, flagurile spun semnul rezultatului: `jge` sare dacă e ≥ 0 (cu semn). `neg eax` schimbă semnul.')

solution_code[3] = '''section .text
global imparte

imparte:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    cdq
    idiv dword [ebp+12]
    mov ecx, [ebp+16]   ; ecx = adresa variabilei rest
    mov [ecx], edx      ; *rest = edx
    leave
    ret
'''
add(3, 'Câtul și restul', C1, 'medie', '''
```c
int imparte(int a, int b, int *rest);
```

Întoarce câtul `a / b` și scrie restul `a % b` la adresa `rest` (ca în C, pentru numere negative câtul se trunchiază spre 0, iar restul are semnul lui `a`). `b` nu e niciodată 0.

Al treilea argument e o **adresă**: încarc-o într-un registru și scrie prin el (`mov [ecx], edx`).''',
    'imparte', 'int imparte(int a, int b, int *rest)', ['int', 'int', 'ptr_int'], 'int',
    [[17, 5, [0]], [20, 4, [0]], [-17, 5, [0]], [17, -5, [0]], [3, 10, [0]], [-100, -7, [0]]],
    lambda a, b, r: (int(a / b), [a - int(a / b) * b]),
    mem=lambda args, outs: {2: outs},
    hint='`idiv` lasă câtul în `eax` și restul în `edx`. Adresa e o valoare ca oricare: `mov ecx, [ebp+16]` o aduce în `ecx`, apoi `[ecx]` e memoria de la ea.')

# ------------------------------------------------------------------ 2. bits
solution_code[4] = '''section .text
global numara_biti

numara_biti:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
    xor eax, eax
bucla:
    test edx, edx
    jz gata
    mov ecx, edx
    and ecx, 1
    add eax, ecx
    shr edx, 1
    jmp bucla
gata:
    leave
    ret
'''
add(4, 'Câți biți de 1', C2, 'ușoară', '''
```c
int numara_biti(unsigned int x);
```

Întoarce numărul de biți egali cu 1 din reprezentarea lui `x` (de exemplu 13 = `1101` are 3). Fără `popcnt`: deplasează și testează bitul cel mai din dreapta.''',
    'numara_biti', 'int numara_biti(unsigned int x)', ['uint'], 'int',
    [[13], [0], [1], [255], [0x80000000], [0xFFFFFFFF], [0x12345678]],
    lambda x: bin(x & 0xffffffff).count('1'),
    hint='`and ecx, 1` păstrează doar ultimul bit; `shr edx, 1` îl aruncă și aduce următorul. Bucla se oprește când numărul ajunge 0.',
    source='Laborator IOCLA · operații pe biți')

solution_code[5] = '''section .text
global inverseaza_octeti

inverseaza_octeti:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
    xor eax, eax
    mov ecx, 4
bucla:
    shl eax, 8
    mov al, dl          ; octetul cel mai de jos al lui edx
    shr edx, 8
    loop bucla
    leave
    ret
'''
add(5, 'Little endian pe dos', C2, 'medie', '''
```c
unsigned int inverseaza_octeti(unsigned int x);
```

Întoarce `x` cu cei patru octeți în ordine inversă: `0x11223344` devine `0x44332211`. Așa se trece un număr din little endian (cum îl ține x86 în memorie) în big endian (ordinea din rețea).

Fără `bswap`: folosește deplasări și registrele de 8 biți (`al`, `dl`).''',
    'inverseaza_octeti', 'unsigned int inverseaza_octeti(unsigned int x)', ['uint'], 'uint',
    [[0x11223344], [0x000000FF], [0xDEADBEEF], [0], [0x01020304], [0xFF000000]],
    lambda x: int.from_bytes((x & 0xffffffff).to_bytes(4, 'little'), 'big'),
    hint='`al` e octetul cel mai de jos al lui `eax`. Ia octeții lui `x` de jos în sus și pune-i în rezultat de sus în jos: `shl eax, 8` face loc, `mov al, dl` pune octetul.',
    source='Test IOCLA · reprezentarea datelor în memorie')

solution_code[6] = '''section .text
global putere_doi

putere_doi:
    push ebp
    mov ebp, esp
    mov ecx, [ebp+8]
    xor eax, eax
    test ecx, ecx
    jz gata             ; 0 nu e putere a lui 2
    lea edx, [ecx-1]
    test ecx, edx       ; x & (x - 1)
    setz al
gata:
    leave
    ret
'''
add(6, 'Putere a lui 2', C2, 'medie', '''
```c
int putere_doi(unsigned int x);   // 1 dacă x e 1, 2, 4, 8, ..., altfel 0
```

Fără buclă: un număr e putere a lui 2 dacă are un singur bit de 1, adică `x & (x - 1)` e 0 (și `x` nu e 0).''',
    'putere_doi', 'int putere_doi(unsigned int x)', ['uint'], 'int',
    [[1], [2], [64], [0], [3], [96], [0x80000000], [0xFFFFFFFF], [1024]],
    lambda x: 1 if x and (x & (x - 1)) == 0 else 0,
    hint='`test a, b` face `a & b` doar pentru flaguri. `setz al` pune 1 în `al` dacă ZF = 1 (rezultatul a fost 0). Grijă: restul lui `eax` trebuie să fie 0.')

solution_code[7] = '''section .text
global roteste

roteste:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    mov ecx, [ebp+12]
    rol eax, cl
    leave
    ret
'''
add(7, 'Rotație la stânga', C2, 'ușoară', '''
```c
unsigned int roteste(unsigned int x, int k);   // 0 <= k < 32
```

Rotește biții lui `x` cu `k` poziții la stânga: biții care ies prin stânga intră înapoi prin dreapta. `roteste(0x80000001, 1)` = `0x00000003`.

Numărul de poziții, când nu e o constantă, trebuie să fie în `cl`.''',
    'roteste', 'unsigned int roteste(unsigned int x, int k)', ['uint', 'int'], 'uint',
    [[0x80000001, 1], [1, 31], [0x12345678, 8], [0xF0000000, 4], [0xDEADBEEF, 0], [0xABCD, 16]],
    lambda x, k: ((x << k) | (x >> (32 - k))) & 0xffffffff if k else x,
    hint='`rol eax, cl`. Doar `cl` poate ține numărul de poziții al unei deplasări sau rotații.')

# ------------------------------------------------------------------ 3. arrays and strings
solution_code[8] = '''section .text
global suma_pare

suma_pare:
    push ebp
    mov ebp, esp
    push ebx
    mov ebx, [ebp+8]    ; v
    mov ecx, [ebp+12]   ; n
    xor eax, eax
    test ecx, ecx
    jz gata
bucla:
    mov edx, [ebx]
    test edx, 1
    jnz urmatorul
    add eax, edx
urmatorul:
    add ebx, 4
    loop bucla
gata:
    pop ebx
    leave
    ret
'''
add(8, 'Suma elementelor pare', C3, 'ușoară', '''
```c
int suma_pare(int *v, int n);
```

Întoarce suma elementelor pare din vectorul `v` de `n` întregi (`n` poate fi 0). Un `int` ocupă 4 octeți: elementul `i` e la adresa `v + 4*i`.

Dacă folosești `ebx`, `esi` sau `edi`, salvează-le pe stivă la început și refă-le la sfârșit: convenția cdecl o cere, iar testele verifică.''',
    'suma_pare', 'int suma_pare(int *v, int n)', ['ptr_int', 'int'], 'int',
    [[[1, 2, 3, 4], 4], [[], 0], [[7], 1], [[-2, -3, 10, 0, 5], 5], [[2] * 50, 50], [[100, 201, 302, 403], 4]],
    lambda v, n: sum(x for x in v if x % 2 == 0),
    hint='Un element par are bitul 0 egal cu 0: `test edx, 1` urmat de `jnz` sare peste cele impare. `[ebx + 4*esi]` sau `add ebx, 4` trec la următorul.')

solution_code[9] = '''section .text
global maxim

maxim:
    push ebp
    mov ebp, esp
    push esi
    mov esi, [ebp+8]
    mov ecx, [ebp+12]
    mov eax, [esi]      ; primul element
    mov edx, 1
bucla:
    cmp edx, ecx
    jge gata
    cmp [esi + 4*edx], eax
    jle mai_mic
    mov eax, [esi + 4*edx]
mai_mic:
    inc edx
    jmp bucla
gata:
    pop esi
    leave
    ret
'''
add(9, 'Maximul unui vector', C3, 'ușoară', '''
```c
int maxim(int *v, int n);   // n >= 1
```

Întoarce cel mai mare element. Numerele au semn: compară cu `jg`/`jl` (cu semn), nu cu `ja`/`jb` (fără semn).''',
    'maxim', 'int maxim(int *v, int n)', ['ptr_int', 'int'], 'int',
    [[[3, 9, 2], 3], [[-5], 1], [[-5, -2, -9], 3], [[1, 2, 3, 4, 5, 6], 6], [[0, -1, 2147483647, -2147483648], 4]],
    lambda v, n: max(v),
    hint='`[esi + 4*edx]` e elementul `edx`. Cu `ja`, -1 (0xFFFFFFFF) ar părea cel mai mare număr.')

solution_code[10] = '''section .text
global lungime

lungime:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
    xor eax, eax
bucla:
    cmp byte [edx + eax], 0
    je gata
    inc eax
    jmp bucla
gata:
    leave
    ret
'''
add(10, 'strlen', C3, 'ușoară', '''
```c
int lungime(char *s);
```

Întoarce lungimea șirului `s`, fără terminatorul `\\0`. Un caracter ocupă un octet: compară cu `byte [...]`.''',
    'lungime', 'int lungime(char *s)', ['str'], 'int',
    [['salut'], [''], ['a'], ['Introducere in Organizarea Calculatoarelor'], ['12345 67890']],
    lambda s: len(s),
    hint='`cmp byte [edx + eax], 0` compară octetul de la `s + eax` cu 0. Fără `byte`, asamblorul nu știe câți octeți să compare.')

solution_code[11] = '''section .text
global majuscule

majuscule:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
bucla:
    mov al, [edx]
    test al, al
    jz gata
    cmp al, 'a'
    jb urmatorul
    cmp al, 'z'
    ja urmatorul
    sub al, 32          ; 'a' - 'A' = 32
    mov [edx], al
urmatorul:
    inc edx
    jmp bucla
gata:
    leave
    ret
'''
add(11, 'Totul cu majuscule', C3, 'medie', '''
```c
void majuscule(char *s);
```

Transformă pe loc literele mici din `s` în litere mari. Celelalte caractere (cifre, spații, semne) rămân la fel. În ASCII, `'a' - 'A'` = 32.''',
    'majuscule', 'void majuscule(char *s)', ['str'], 'void',
    [['salut'], ['Hello, World!'], [''], ['abc xyz 123'], ['deja MARE'], ['{az}[AZ]`@']],
    lambda s: s.upper() if all(ord(c) < 128 for c in s) else s,
    mem=lambda args, out: {0: ''.join(chr(ord(c) - 32) if 'a' <= c <= 'z' else c for c in args[0])},
    hint="Compară caracterul cu `'a'` și `'z'` (cu `jb`/`ja`: caracterele sunt fără semn). `{` și `` ` `` sunt chiar lângă litere: nu le atinge.")

solution_code[12] = '''section .text
global inverseaza

inverseaza:
    push ebp
    mov ebp, esp
    push esi
    push edi
    mov esi, [ebp+8]            ; stânga
    mov ecx, [ebp+12]
    lea edi, [esi + 4*ecx - 4]  ; dreapta
bucla:
    cmp esi, edi
    jae gata
    mov eax, [esi]
    mov edx, [edi]
    mov [esi], edx
    mov [edi], eax
    add esi, 4
    sub edi, 4
    jmp bucla
gata:
    pop edi
    pop esi
    leave
    ret
'''
add(12, 'Vectorul pe dos', C3, 'medie', '''
```c
void inverseaza(int *v, int n);   // n >= 1
```

Inversează pe loc ordinea elementelor: `{1, 2, 3, 4}` devine `{4, 3, 2, 1}`. Folosește doi indici (sau două adrese) care se apropie.''',
    'inverseaza', 'void inverseaza(int *v, int n)', ['ptr_int', 'int'], 'void',
    [[[1, 2, 3, 4], 4], [[7], 1], [[1, 2, 3], 3], [[-1, 0, 1, 2, 3, 4, 5, 6, 7], 9]],
    lambda v, n: list(reversed(v)),
    mem=lambda args, out: {0: list(reversed(args[0]))},
    hint='`lea edi, [esi + 4*ecx - 4]` calculează adresa ultimului element fără să citească memoria. Schimbă elementele de la `[esi]` și `[edi]` până se întâlnesc.')

# ------------------------------------------------------------------ 4. stack and calls
solution_code[13] = '''section .text
global factorial

factorial:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    cmp eax, 1
    jle baza
    dec eax
    push eax
    call factorial      ; eax = factorial(n - 1)
    add esp, 4          ; cdecl: cel care cheamă scoate argumentele
    imul eax, [ebp+8]
    jmp gata
baza:
    mov eax, 1
gata:
    leave
    ret
'''
add(13, 'Factorial recursiv', C4, 'medie', '''
```c
int factorial(int n);   // 0 <= n <= 12
```

Scrie funcția **recursiv**: pentru `n <= 1` întoarce 1, altfel `n * factorial(n - 1)`. Apelul recursiv se face ca din C: pui argumentul pe stivă, `call factorial`, apoi scoți argumentul (`add esp, 4`).

Folosește „pas cu pas” ca să vezi cum crește stiva la fiecare apel.''',
    'factorial', 'int factorial(int n)', ['int'], 'int',
    [[0], [1], [5], [7], [10], [12]],
    lambda n: __import__('math').factorial(n),
    hint='După `call`, `eax` are rezultatul apelului. `n` îl găsești din nou la `[ebp+8]`: fiecare apel are propriul `ebp`.',
    source='Curs IOCLA · stiva și apelurile de funcții')

solution_code[14] = '''section .text
global fib

fib:
    push ebp
    mov ebp, esp
    mov ecx, [ebp+8]
    xor eax, eax        ; a = f(0)
    mov edx, 1          ; b = f(1)
    test ecx, ecx
    jz gata
bucla:
    add eax, edx        ; a + b
    xchg eax, edx       ; (a, b) = (b, a + b)
    loop bucla
gata:
    leave
    ret
'''
def fibp(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a
add(14, 'Șirul lui Fibonacci', C4, 'ușoară', '''
```c
int fib(int n);   // f(0) = 0, f(1) = 1, f(n) = f(n-1) + f(n-2); 0 <= n <= 40
```

Calculează iterativ (o buclă cu `loop` merge bine). Recursiv ar funcționa, dar pentru `n = 40` ar face sute de milioane de apeluri.''',
    'fib', 'int fib(int n)', ['int'], 'int',
    [[0], [1], [2], [10], [20], [40]],
    fibp,
    hint='Ține doi termeni consecutivi în două registre. `loop eticheta` scade `ecx` și sare dacă nu a ajuns la 0.')

solution_code[15] = '''section .text
global numara

numara:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]    ; s
    mov cl, [ebp+12]    ; c (un char e pus pe stivă ca int)
    xor eax, eax
bucla:
    mov ch, [edx]
    test ch, ch
    jz gata
    cmp ch, cl
    jne urm
    inc eax
urm:
    inc edx
    jmp bucla
gata:
    leave
    ret
'''
add(15, 'De câte ori apare un caracter', C4, 'ușoară', '''
```c
int numara(char *s, char c);
```

Întoarce de câte ori apare `c` în `s`. Un `char` dat ca argument ocupă tot 4 octeți pe stivă (ca un `int`), dar contează doar octetul de jos: `mov cl, [ebp+12]`.''',
    'numara', 'int numara(char *s, char c)', ['str', 'char'], 'int',
    [['banana', 'a'], ['banana', 'n'], ['', 'x'], ['mississippi', 's'], ['aaaa', 'b'], ['a b c d', ' ']],
    lambda s, c: s.count(c),
    hint='Pe stivă fiecare argument ocupă 4 octeți, oricât de mic e tipul lui.')

solution_code[16] = '''section .text
global copiaza

copiaza:
    push ebp
    mov ebp, esp
    push esi
    push edi
    mov edi, [ebp+8]    ; dst
    mov esi, [ebp+12]   ; src
    mov ecx, [ebp+16]   ; n
    xor eax, eax
    test ecx, ecx
    jz gata
    dec ecx             ; loc pentru terminator
bucla:
    test ecx, ecx
    jz pune_zero
    mov dl, [esi + eax]
    test dl, dl
    jz pune_zero
    mov [edi + eax], dl
    inc eax
    dec ecx
    jmp bucla
pune_zero:
    mov byte [edi + eax], 0
gata:
    pop edi
    pop esi
    leave
    ret
'''
def cop(n, src, size):
    k = min(len(src), size - 1) if size > 0 else 0
    return (k, src[:k])
add(16, 'Copiere fără buffer overflow', C4, 'grea', '''
```c
int copiaza(char *dst, char *src, int n);
```

Copiază șirul `src` în bufferul `dst` de `n` octeți, **fără să scrie dincolo de el**: cel mult `n - 1` caractere, urmate de `\\0`. Întoarce câte caractere a copiat. Pentru `n = 0` nu scrie nimic și întoarce 0.

Așa se apără programele de buffer overflow (`strcpy` nu verifică nimic: dacă `src` e mai lung, suprascrie stiva). Testele pun bufferul exact de mărimea `n` și verifică ce a rămas în el.''',
    'copiaza', 'int copiaza(char *dst, char *src, int n)', ['buf', 'str', 'int'], 'int',
    [[16, 'salut', 16], [4, 'salut', 4], [1, 'abc', 1], [6, 'abcdef', 6], [10, '', 10], [8, 'exact7!', 8]],
    lambda size, src, n: cop(size, src, n),
    mem=lambda args, out: {0: out} if args[2] > 0 else {},
    hint='Numără câte caractere mai ai voie (`n - 1`) și oprește-te la primul dintre: bufferul plin sau `\\0` în sursă. Terminatorul se scrie mereu (dacă `n > 0`).',
    source='Curs IOCLA · buffer overflow')

# ------------------------------------------------------------------ more (2026-11)
solution_code[17] = '''section .text
global putere

putere:
    push ebp
    mov ebp, esp
    mov ecx, [ebp+12]   ; e
    mov eax, 1
bucla:
    test ecx, ecx
    jz gata
    imul eax, [ebp+8]   ; eax = eax * b (păstrează doar ultimii 32 de biți)
    dec ecx
    jmp bucla
gata:
    leave
    ret
'''
add(17, 'Ridicarea la putere', C1, 'ușoară', '''
```c
int putere(int b, int e);   // b la puterea e, e >= 0
```

Întoarce $b^e$ prin înmulțiri repetate. Ca în C, dacă rezultatul nu încape pe 32 de biți, se păstrează doar ultimii 32 (testele au și un astfel de caz). $b^0 = 1$.''',
    'putere', 'int putere(int b, int e)', ['int', 'int'], 'int',
    [[2, 10], [3, 0], [-2, 5], [7, 3], [10, 9], [2, 31], [3, 25], [-1, 1001]],
    lambda b, e: s32(b ** e),
    hint='`imul eax, [ebp+8]` înmulțește `eax` cu `b` și păstrează rezultatul pe 32 de biți. Un contor în `ecx`, decrementat până la 0.')

solution_code[18] = '''section .text
global paritate

paritate:
    push ebp
    mov ebp, esp
    mov edx, [ebp+8]
    xor eax, eax
bucla:
    test edx, edx
    jz gata
    xor eax, edx        ; bitul 0 al lui eax adună (xor) toți biții
    shr edx, 1
    jmp bucla
gata:
    and eax, 1
    leave
    ret
'''
add(18, 'Bitul de paritate', C2, 'medie', '''
```c
int paritate(unsigned int x);
```

Întoarce **1** dacă `x` are un număr **impar** de biți de 1 și **0** altfel: e bitul de paritate pe care îl adaugă un protocol de comunicație ca să descopere o eroare de un bit.''',
    'paritate', 'int paritate(unsigned int x)', ['int'], 'int',
    [[0], [1], [3], [7], [0xff], [0x80000000], [0xffffffff], [0x12345678], [1023]],
    lambda x: bin(x & 0xffffffff).count('1') % 2,
    hint='XOR-ul tuturor biților dă paritatea. Sau numără biții de 1 și păstrează doar bitul 0 al numărului.')

solution_code[19] = '''section .text
global produs_scalar

produs_scalar:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push ebx
    mov esi, [ebp+8]    ; a
    mov edi, [ebp+12]   ; b
    mov ecx, [ebp+16]   ; n
    xor ebx, ebx        ; suma
    xor edx, edx        ; i
bucla:
    cmp edx, ecx
    jge gata
    mov eax, [esi + 4*edx]
    imul eax, [edi + 4*edx]
    add ebx, eax
    inc edx
    jmp bucla
gata:
    mov eax, ebx
    pop ebx
    pop edi
    pop esi
    leave
    ret
'''
add(19, 'Produsul scalar', C3, 'medie', '''
```c
int produs_scalar(int *a, int *b, int n);
```

Întoarce $\\sum_{i=0}^{n-1} a_i b_i$. Vectorii au câte `n` elemente (`n` poate fi 0).

Ai nevoie de mai multe registre decât `eax`, `ecx`, `edx`: dacă folosești `ebx`, `esi`, `edi`, salvează-le și refă-le (cdecl).''',
    'produs_scalar', 'int produs_scalar(int *a, int *b, int n)', ['ptr_int', 'ptr_int', 'int'], 'int',
    [[[1, 2, 3], [4, 5, 6], 3], [[], [], 0], [[-1, 2], [3, -4], 2], [[7], [6], 1], [[1] * 20, list(range(20)), 20], [[100000, 100000], [30000, 1], 2]],
    lambda a, b, n: s32(sum(x * y for x, y in zip(a[:n], b[:n]))),
    hint='Adresarea `[esi + 4*edx]` ia elementul `edx` al vectorului de la `esi`. `imul` cu un operand din memorie scutește o încărcare.')

solution_code[20] = '''section .text
global cuvinte

cuvinte:
    push ebp
    mov ebp, esp
    push esi
    mov esi, [ebp+8]
    xor eax, eax        ; numărul de cuvinte
    xor ecx, ecx        ; 1 dacă suntem într-un cuvânt
bucla:
    mov dl, [esi]
    test dl, dl
    jz gata
    cmp dl, ' '
    je spatiu
    test ecx, ecx
    jnz urm
    inc eax             ; începe un cuvânt nou
    mov ecx, 1
    jmp urm
spatiu:
    xor ecx, ecx
urm:
    inc esi
    jmp bucla
gata:
    pop esi
    leave
    ret
'''
add(20, 'Câte cuvinte are un șir', C3, 'medie', '''
```c
int cuvinte(char *s);
```

Întoarce numărul de **cuvinte** din șirul `s`: secvențe de caractere diferite de spațiu, despărțite de unul sau mai multe spații. Șirul poate începe sau se poate termina cu spații, sau poate fi gol.''',
    'cuvinte', 'int cuvinte(char *s)', ['str'], 'int',
    [['ana are mere'], [''], ['   '], ['  doua   cuvinte  '], ['x'], ['a b c d e f'], ['unu  ']],
    lambda s: len(s.split()),
    hint='Un cuvânt începe acolo unde un caracter nu e spațiu, dar cel dinainte era (sau e începutul). Ține un registru „sunt într-un cuvânt”.')

solution_code[21] = '''section .text
global suma_cifre

suma_cifre:
    push ebp
    mov ebp, esp
    mov eax, [ebp+8]
    cmp eax, 10
    jb baza             ; n < 10: chiar n
    xor edx, edx
    mov ecx, 10
    div ecx             ; eax = n / 10, edx = n % 10
    push edx            ; păstrează ultima cifră peste apel
    push eax
    call suma_cifre     ; eax = suma_cifre(n / 10)
    add esp, 4
    pop edx
    add eax, edx
baza:
    leave
    ret
'''
add(21, 'Suma cifrelor, recursiv', C4, 'medie', '''
```c
unsigned int suma_cifre(unsigned int n);
```

Scrie funcția **recursiv**: pentru `n < 10` întoarce `n`, altfel ultima cifră plus `suma_cifre(n / 10)`.

Atenție: apelul recursiv poate strica `edx` și `ecx` (cdecl nu le păstrează). Ce vrei să ai și după apel trebuie pus pe stivă.''',
    'suma_cifre', 'unsigned int suma_cifre(unsigned int n)', ['int'], 'uint',
    [[0], [7], [10], [12345], [99999], [4294967295], [1000000000]],
    lambda n: sum(map(int, str(n))),
    hint='`div ecx` (fără semn) împarte `edx:eax` la `ecx`: pune `edx = 0` înainte. Restul apare în `edx`: salvează-l cu `push` înainte de `call`.',
    source='Curs IOCLA · stiva și apelurile de funcții')

write_course('iocla', CHAPTERS, PROBLEMS)
