"""USO — Utilizarea Sistemelor de Operare: tasks solved in the in-browser shell.

Based on the USO practical tests (seria CD, 2018–2022) and the labs.
"""
import random, sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, write_course
from bashref import fill_expectations

C1 = '1. Fișiere și directoare'
C2 = '2. Permisiuni'
C3 = '3. Filtre de text'
C4 = '4. Scripturi shell'
CHAPTERS = [C1, C2, C3, C4]
T = 'Test practic USO'

rnd = random.Random(1827)

# ------------------------------------------------------------------ data
users = ['ana', 'bogdan', 'carmen', 'dan', 'elena', 'florin', 'gabi', 'horia']
weights = [9, 31, 14, 22, 5, 17, 3, 11]
acces = []
for i in range(320):
    u = rnd.choices(users, weights)[0]
    ip = f'10.0.{rnd.randint(0, 3)}.{rnd.randint(2, 250)}'
    act = rnd.choice(['login', 'logout', 'upload', 'download', 'delete'])
    acces.append(f'{u} {ip} {act}')
acces_log = '\n'.join(acces) + '\n'

csv_rows = ['nume,grupa,nota']
for n in ['Popescu', 'Ionescu', 'Marin', 'Stan', 'Dinu', 'Tudor', 'Radu', 'Neagu', 'Matei', 'Lupu', 'Ene', 'Toma', 'Sima', 'Barbu']:
    csv_rows.append(f'{n},31{rnd.randint(1, 4)}CD,{rnd.randint(3, 10)}')
users_csv = '\n'.join(csv_rows) + '\n'

levels = ['INFO', 'INFO', 'INFO', 'WARN', 'ERROR']
msgs = {'INFO': ['request served', 'cache hit', 'user logged in'], 'WARN': ['slow query', 'retrying'], 'ERROR': ['disk full', 'timeout', 'connection refused']}
def mklog(n, seed):
    r = random.Random(seed)
    out = []
    for i in range(n):
        lv = r.choice(levels)
        out.append(f'2024-01-{r.randint(10, 28)} {r.randint(10, 23)}:{r.randint(10, 59)} {lv} {r.choice(msgs[lv])}')
    return '\n'.join(out) + '\n'

PROBLEMS = []
def add(id, title, chapter, diff, statement, spec, hint='', solution='', source=''):
    spec = fill_expectations(spec)
    PROBLEMS.append(problem(id, title, chapter, diff, statement, 'shell', spec, hint, solution, source))

# ------------------------------------------------------------------ 1. files
add(1, 'Scheletul unui proiect', C1, 'ușoară', '''
Creează, în directorul tău home, structura unui proiect C:

```
proiect/
├── src/main.c
├── include/main.h
├── docs/
└── README.md
```

Fișierele `main.c` și `main.h` pot fi goale. `README.md` trebuie să conțină o singură linie: `Proiect USO`.

Lucrează în terminal. Când crezi că ai terminat, apasă **verifică**.''', {
    'setup': [],
    'checks': [
        {'type': 'dir', 'path': '~/proiect/src'},
        {'type': 'dir', 'path': '~/proiect/include'},
        {'type': 'dir', 'path': '~/proiect/docs'},
        {'type': 'file', 'path': '~/proiect/src/main.c'},
        {'type': 'file', 'path': '~/proiect/include/main.h'},
        {'type': 'file', 'path': '~/proiect/README.md', 'equals': 'Proiect USO\n', 'msg': 'README.md conține „Proiect USO”'},
    ],
    'reference': ['mkdir -p proiect/{src,include,docs}', 'touch proiect/src/main.c proiect/include/main.h', 'echo "Proiect USO" > proiect/README.md'],
}, hint='`mkdir -p` creează și directoarele părinte; acoladele `{src,include,docs}` scriu trei nume deodată. Cu `echo text > fisier` pui text într-un fișier.',
   solution='''
```bash
mkdir -p proiect/{src,include,docs}
touch proiect/src/main.c proiect/include/main.h
echo "Proiect USO" > proiect/README.md
```
`mkdir -p proiect/{src,include,docs}` se extinde la `mkdir -p proiect/src proiect/include proiect/docs`.''')

dl = ['curs1.pdf', 'curs2.pdf', 'tema3.pdf', 'poza_mare.jpg', 'vacanta.jpg', 'note.txt', 'a1.tmp', 'b2.tmp', 'cache.tmp', 'Laborator 4.pdf']
add(2, 'Ordine în Downloads', C1, 'ușoară', '''
Directorul `~/Downloads` s-a umplut. Fă ordine:

• mută toate fișierele `.pdf` în `~/Documente/pdf` (directorul nu există încă);
• șterge toate fișierele `.tmp`;
• restul fișierelor rămân unde sunt.

Atenție: un fișier are un spațiu în nume.''', {
    'setup': [{'path': f'~/Downloads/{n}', 'content': f'{n}\n'} for n in dl],
    'checks': [
        *[{'type': 'file', 'path': f'~/Documente/pdf/{n}', 'msg': f'{n} e în ~/Documente/pdf'} for n in dl if n.endswith('.pdf')],
        *[{'type': 'absent', 'path': f'~/Downloads/{n}', 'msg': f'{n} nu mai e în Downloads'} for n in dl if n.endswith('.pdf') or n.endswith('.tmp')],
        *[{'type': 'file', 'path': f'~/Downloads/{n}', 'msg': f'{n} a rămas în Downloads'} for n in dl if n.endswith('.jpg') or n.endswith('.txt')],
    ],
    'reference': ['mkdir -p ~/Documente/pdf', 'mv ~/Downloads/*.pdf ~/Documente/pdf/', 'rm ~/Downloads/*.tmp'],
}, hint='Un glob ca `*.pdf` se potrivește și cu nume care au spații: shell-ul îl înlocuiește cu nume întregi, nu le mai desparte.',
   solution='''
```bash
mkdir -p ~/Documente/pdf
mv ~/Downloads/*.pdf ~/Documente/pdf/
rm ~/Downloads/*.tmp
```
Dacă ai fi scris numele de mână, `Laborator 4.pdf` ar fi trebuit pus între ghilimele.''')

add(3, 'Legătura ascunsă', C1, 'medie', '''
În directorul `~/Models` creează o **legătură simbolică ascunsă**, cu numele `.RK800`, care duce la fișierul `~/CyberLife/Connor`. Folosește o cale **relativă** pentru țintă, astfel încât legătura să meargă și dacă tot directorul home e mutat.

Verifică apoi cu `ls -la ~/Models` și `cat ~/Models/.RK800`.''', {
    'setup': [{'path': '~/CyberLife/Connor', 'content': 'Connor, RK800. Trimis de CyberLife.\n'}, {'path': '~/Models/', 'dir': True}],
    'checks': [
        {'type': 'link', 'path': '~/Models/.RK800', 'target': '~/CyberLife/Connor', 'msg': '~/Models/.RK800 e o legătură către ~/CyberLife/Connor'},
        {'type': 'output', 'cmd': 'readlink ~/Models/.RK800', 'regex': r'^\.\./', 'msg': 'ținta e scrisă relativ (../CyberLife/Connor)'},
    ],
    'reference': ['cd ~/Models', 'ln -s ../CyberLife/Connor .RK800'],
}, hint='`ln -s TINTA NUME`. O țintă relativă se citește față de directorul în care stă legătura, nu față de cel în care ești.',
   solution='''
```bash
cd ~/Models
ln -s ../CyberLife/Connor .RK800
```
Ținta `../CyberLife/Connor` e interpretată pornind din `~/Models`. Numele începe cu punct, deci `ls` fără `-a` nu-l arată.''',
   source=f'{T} · varianta 103 · 30 august 2018 · 1d')

add(4, 'Copii de siguranță', C1, 'medie', '''
În `~/teme` sunt mai multe fișiere `.c`. Fă o copie de siguranță a fiecăruia **în același director**, cu extensia `.c.bak` (de exemplu `tema1.c` → `tema1.c.bak`), fără să scrii numele fișierelor de mână: folosește o buclă `for`.''', {
    'setup': [{'path': f'~/teme/{n}', 'content': f'/* {n} */\nint main(void) {{ return 0; }}\n'} for n in ['tema1.c', 'tema2.c', 'lab_liste.c', 'heap.c']] + [{'path': '~/teme/notite.txt', 'content': 'nu e cod\n'}],
    'checks': [
        *[{'type': 'file', 'path': f'~/teme/{n}.bak', 'equals': f'/* {n} */\nint main(void) {{ return 0; }}\n', 'msg': f'{n}.bak e o copie a lui {n}'} for n in ['tema1.c', 'tema2.c', 'lab_liste.c', 'heap.c']],
        {'type': 'absent', 'path': '~/teme/notite.txt.bak', 'msg': 'notite.txt nu are copie (nu e .c)'},
        {'type': 'history', 'regex': r'\bfor\b', 'msg': 'ai folosit o buclă for'},
    ],
    'reference': ['cd ~/teme', 'for f in *.c; do cp "$f" "$f.bak"; done'],
}, hint='`for f in *.c; do ...; done` ia pe rând fiecare nume. În buclă, `"$f.bak"` e numele nou.',
   solution='''
```bash
cd ~/teme
for f in *.c; do cp "$f" "$f.bak"; done
```''')

# ------------------------------------------------------------------ 2. permissions
add(5, 'Doar north are drepturi depline', C2, 'ușoară', '''
Directorul `~/Characters` și fișierul `~/Characters/secret.txt` au acum toate permisiunile pentru toată lumea (`777`). Repară-le:

• doar proprietarul are drepturi depline asupra directorului; ceilalți (grupul și restul) pot **doar citi** conținutul lui, adică pot lista fișierele și pot intra în director ca să le citească;
• `secret.txt` poate fi citit și scris doar de proprietar.

Folosește `chmod` și verifică cu `ls -l`.''', {
    'setup': [{'path': '~/Characters/', 'dir': True, 'mode': '777'}, {'path': '~/Characters/secret.txt', 'content': 'north\n', 'mode': '777'}, {'path': '~/Characters/lista.txt', 'content': 'kara\nmarkus\n', 'mode': '644'}],
    'checks': [
        {'type': 'mode', 'path': '~/Characters', 'mode': '755'},
        {'type': 'mode', 'path': '~/Characters/secret.txt', 'mode': '600'},
    ],
    'reference': ['chmod 755 ~/Characters', 'chmod 600 ~/Characters/secret.txt'],
}, hint='La un director, ca să poți citi un fișier din el îți trebuie și dreptul x (să intri în el). r = 4, w = 2, x = 1.',
   solution='''
```bash
chmod 755 ~/Characters            # rwxr-xr-x
chmod 600 ~/Characters/secret.txt # rw-------
```
Pentru „doar citire” la un director, ceilalți au nevoie de r (listare) și de x (traversare): r-x = 5. Cu 744 ar vedea numele fișierelor, dar n-ar putea deschide niciunul.''',
   source=f'{T} · varianta 103 · 30 august 2018 · 1e')

add(6, 'Scriptul care nu pornește', C2, 'ușoară', '''
În `~/bin` e un script, `salut.sh`, dar `~/bin/salut.sh` dă `Permission denied`. Fă-l executabil **doar pentru proprietar** (grupul și ceilalți rămân cum sunt) și rulează-l: scriptul lasă în `~/salut.log` un mesaj.''', {
    'setup': [{'path': '~/bin/salut.sh', 'content': '#!/bin/bash\necho "salut, $USER" > ~/salut.log\necho "am scris in ~/salut.log"\n', 'mode': '644'}],
    'checks': [
        {'type': 'mode', 'path': '~/bin/salut.sh', 'mode': '744', 'msg': 'salut.sh are rwxr--r-- (744)'},
        {'type': 'file', 'path': '~/salut.log', 'equals': 'salut, student\n', 'msg': 'scriptul a rulat (~/salut.log există)'},
    ],
    'reference': ['chmod u+x ~/bin/salut.sh', '~/bin/salut.sh'],
}, hint='`chmod u+x` adaugă dreptul de execuție doar proprietarului (u = user). Apoi îl rulezi cu calea lui: `~/bin/salut.sh` sau `./salut.sh` din `~/bin`.',
   solution='''
```bash
chmod u+x ~/bin/salut.sh
~/bin/salut.sh
```
Forma simbolică `u+x` schimbă un singur bit; `chmod 744` ar fi dat același rezultat aici, dar îți cere să știi și celelalte permisiuni.''')

add(7, 'umask pentru fișiere private', C2, 'medie', '''
Vrei ca tot ce creezi de acum să fie privat: fișierele noi cu `rw-------` (600) și directoarele noi cu `rwx------` (700).

Setează `umask` potrivit, **apoi** creează directorul `~/privat` și în el fișierul gol `jurnal.txt` (fără `chmod`).''', {
    'setup': [],
    'checks': [
        {'type': 'mode', 'path': '~/privat', 'mode': '700'},
        {'type': 'mode', 'path': '~/privat/jurnal.txt', 'mode': '600'},
        {'type': 'history', 'regex': r'\bumask\s+0?077\b', 'msg': 'ai setat umask-ul (077)'},
    ],
    'reference': ['umask 077', 'mkdir ~/privat', 'touch ~/privat/jurnal.txt'],
}, hint='Un fișier nou pornește de la 666, un director de la 777; umask spune ce biți se scot.',
   solution='''
```bash
umask 077
mkdir ~/privat
touch ~/privat/jurnal.txt
```
666 fără 077 = 600, 777 fără 077 = 700. `umask` arată valoarea curentă (implicit 0022).''')

# ------------------------------------------------------------------ 3. text filters
add(8, 'Cei mai activi utilizatori', C3, 'medie', f'''
Fișierul `~/acces.log` are {len(acces)} de linii, de forma `utilizator ip acțiune`:

```
{chr(10).join(acces[:3])}
...
```

Scrie în `~/top3.txt` numele celor **3 utilizatori cu cele mai multe linii**, câte unul pe linie, de la cel mai activ. Fișierul e prea mare ca să-l numeri de mână: folosește un pipeline.''', {
    'setup': [{'path': '~/acces.log', 'content': acces_log}],
    'checks': [{'type': 'file', 'path': '~/top3.txt', 'from_ref': True, 'msg': '~/top3.txt are cei 3 utilizatori, în ordine'}],
    'reference': ["cut -d' ' -f1 acces.log | sort | uniq -c | sort -rn | head -3 | awk '{print $2}' > top3.txt"],
}, hint='`cut` scoate primul câmp, `sort | uniq -c` numără liniile egale, `sort -rn` le ordonează descrescător după număr, `head -3` le păstrează pe primele.',
   solution='''
```bash
cut -d' ' -f1 acces.log | sort | uniq -c | sort -rn | head -3 | awk '{print $2}' > top3.txt
```
`uniq -c` numără doar liniile egale **alăturate**, de aceea are nevoie de `sort` înainte. La final `awk '{print $2}'` scoate numărul și lasă numele.''',
   source=f'{T} · prelucrarea unui jurnal')

add(9, 'Liniile pare', C3, 'ușoară', f'''
Scrie în `~/pare.csv` doar liniile cu număr par (a 2-a, a 4-a, ...) din `~/catalog.csv`, în ordinea în care apar. Prima linie a fișierului (antetul) e linia 1.''', {
    'setup': [{'path': '~/catalog.csv', 'content': users_csv}],
    'checks': [{'type': 'file', 'path': '~/pare.csv', 'from_ref': True, 'msg': '~/pare.csv are exact liniile pare'}],
    'reference': ["sed -n '2~2p' catalog.csv > pare.csv"],
}, hint="În `sed`, adresa `prima~pas` alege liniile prima, prima+pas, ...; `-n` oprește afișarea automată, iar `p` afișează liniile alese.",
   solution='''
```bash
sed -n '2~2p' catalog.csv > pare.csv
```
Merge și `awk 'NR % 2 == 0' catalog.csv > pare.csv`.''',
   source=f'{T} · varianta 125 · 30 ianuarie 2022 · 2c')

add(10, 'Studenții cu note de trecere', C3, 'medie', '''
Din `~/catalog.csv` (`nume,grupa,nota`, cu antet), scrie în `~/promovati.txt` numele studenților cu nota **cel puțin 5**, sortate alfabetic, câte unul pe linie. Antetul nu intră în rezultat.''', {
    'setup': [{'path': '~/catalog.csv', 'content': users_csv}],
    'checks': [{'type': 'file', 'path': '~/promovati.txt', 'from_ref': True, 'msg': '~/promovati.txt are numele corecte, sortate'}],
    'reference': ["awk -F, 'NR > 1 && $3 >= 5 {print $1}' catalog.csv | sort > promovati.txt"],
}, hint='`awk -F,` desparte liniile la virgulă; `NR > 1` sare peste antet, iar `$3 >= 5` alege nota.',
   solution='''
```bash
awk -F, 'NR > 1 && $3 >= 5 {print $1}' catalog.csv | sort > promovati.txt
```''')

logs = {'web.log': mklog(40, 1), 'db.log': mklog(25, 2), 'cron.log': 'INFO job started\nINFO job finished\n', 'auth.log': mklog(30, 3)}
add(11, 'Erorile din jurnale', C3, 'medie', '''
În `~/logs` sunt mai multe fișiere `.log`. Fiecare linie are un nivel: `INFO`, `WARN` sau `ERROR`.

• în `~/erori.txt` scrie **numărul total** de linii cu `ERROR` din toate jurnalele (doar numărul);
• în `~/cu_erori.txt` scrie numele fișierelor (doar numele, fără `logs/`) care au cel puțin o eroare, sortate.''', {
    'setup': [{'path': f'~/logs/{n}', 'content': t} for n, t in logs.items()],
    'checks': [
        {'type': 'file', 'path': '~/erori.txt', 'from_ref': True, 'msg': '~/erori.txt are numărul corect de erori'},
        {'type': 'file', 'path': '~/cu_erori.txt', 'from_ref': True, 'msg': '~/cu_erori.txt are fișierele cu erori'},
    ],
    'reference': ['cat logs/*.log | grep -c ERROR > erori.txt', 'cd logs && grep -l ERROR *.log | sort > ../cu_erori.txt'],
}, hint='`grep -c` numără liniile potrivite, dar pe fiecare fișier în parte dacă îi dai mai multe; ca să ai un singur total, adună-le întâi cu `cat`. `grep -l` scrie doar numele fișierelor.',
   solution='''
```bash
cat logs/*.log | grep -c ERROR > erori.txt
cd logs && grep -l ERROR *.log | sort > ../cu_erori.txt
```''')

conf = 'server=localhost\nport=8080\ndb_host=localhost\ndb_port=5432\n# localhost e doar pentru teste\nlog=/var/log/app.log\n'
add(12, 'Configurare mutată pe server', C3, 'medie', '''
Aplicația din `~/config/app.conf` trece de pe calculatorul tău pe un server. Modifică fișierul **pe loc** (fără să-l deschizi într-un editor):

• fiecare `localhost` devine `10.0.0.5` (inclusiv în comentariu);
• linia `port=8080` devine `port=9090`; celelalte porturi rămân.''', {
    'setup': [{'path': '~/config/app.conf', 'content': conf}],
    'checks': [{'type': 'file', 'path': '~/config/app.conf', 'from_ref': True, 'msg': 'app.conf are noile valori'}],
    'reference': ["sed -i 's/localhost/10.0.0.5/g; s/^port=8080$/port=9090/' config/app.conf"],
}, hint="`sed -i` scrie rezultatul înapoi în fișier. `s/a/b/g` înlocuiește toate aparițiile de pe linie; `^` și `$` leagă tiparul de începutul și sfârșitul liniei.",
   solution='''
```bash
sed -i 's/localhost/10.0.0.5/g; s/^port=8080$/port=9090/' config/app.conf
```
Fără `^...$`, `s/port=8080/port=9090/` ar fi mers aici, dar ar fi atins și o linie ca `db_port=8080`.''')

# ------------------------------------------------------------------ 4. scripts
numara_runs = [
    {'args': ['.verif/date'], 'setup': [{'path': '~/.verif/date/a.txt'}, {'path': '~/.verif/date/b.txt'}, {'path': '~/.verif/date/c.csv'}, {'path': '~/.verif/date/sub/', 'dir': True}, {'path': '~/.verif/date/sub/d.txt'}], 'from_ref': True},
    {'args': ['.verif/gol'], 'setup': [{'path': '~/.verif/gol/', 'dir': True}], 'from_ref': True},
    {'args': [], 'from_ref': True},
    {'args': ['nu_exista'], 'from_ref': True},
]
add(13, 'Câte fișiere sunt într-un director', C4, 'medie', '''
Scrie scriptul `~/numara.sh` (cu `nano numara.sh`) care primește ca argument un director și afișează **numărul de fișiere obișnuite** din el (fără subdirectoare și fără ce e în ele).

• fără argument afișează `Utilizare: numara.sh director` și iese cu codul 1;
• dacă argumentul nu e un director, afișează `Nu e director: <arg>` și iese cu codul 2.

Scriptul e rulat de verificare cu `bash ~/numara.sh ...` pe alte directoare decât ale tale.''', {
    'setup': [{'path': '~/exemplu/x.txt'}, {'path': '~/exemplu/y.txt'}, {'path': '~/exemplu/z/', 'dir': True}],
    'checks': [{'type': 'script', 'path': '~/numara.sh', 'runs': numara_runs}],
    'reference': ['''cat > ~/numara.sh <<'EOF'
#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Utilizare: numara.sh director"
    exit 1
fi
if [ ! -d "$1" ]; then
    echo "Nu e director: $1"
    exit 2
fi
n=0
for f in "$1"/*; do
    if [ -f "$f" ]; then
        n=$((n + 1))
    fi
done
echo $n
EOF'''],
}, hint='`$#` e numărul de argumente, `$1` primul. `[ -d x ]` testează un director, `[ -f x ]` un fișier obișnuit. Poți număra și cu `find "$1" -maxdepth 1 -type f | wc -l`.',
   solution='''
```bash
#!/bin/bash
if [ $# -lt 1 ]; then
    echo "Utilizare: numara.sh director"
    exit 1
fi
if [ ! -d "$1" ]; then
    echo "Nu e director: $1"
    exit 2
fi
n=0
for f in "$1"/*; do
    if [ -f "$f" ]; then
        n=$((n + 1))
    fi
done
echo $n
```
Un director gol lasă globul `"$1"/*` neschimbat (un singur „nume” care nu există), de aceea testul `-f` e necesar: îl elimină.''')

suma_runs = [
    {'args': ['.verif/numere.txt'], 'setup': [{'path': '~/.verif/numere.txt', 'content': '4\n10\n-3\n7\n'}], 'from_ref': True},
    {'args': ['.verif/mari.txt'], 'setup': [{'path': '~/.verif/mari.txt', 'content': '\n'.join(str(i * 37 % 101) for i in range(1, 60)) + '\n'}], 'from_ref': True},
    {'args': ['.verif/gol.txt'], 'setup': [{'path': '~/.verif/gol.txt', 'content': ''}], 'from_ref': True},
    {'args': ['.verif/lipsa.txt'], 'from_ref': True},
]
add(14, 'Suma dintr-un fișier', C4, 'medie', '''
Scrie `~/suma.sh`: primește numele unui fișier cu câte un număr întreg pe linie și afișează **suma** lor.

• un fișier gol are suma 0;
• dacă fișierul nu există, afișează `Fisierul nu exista` și iese cu codul 2.

Citește fișierul linie cu linie, cu `while read`.''', {
    'setup': [{'path': '~/numere.txt', 'content': '4\n10\n-3\n7\n'}],
    'checks': [{'type': 'script', 'path': '~/suma.sh', 'runs': suma_runs}],
    'reference': ['''cat > ~/suma.sh <<'EOF'
#!/bin/bash
if [ ! -f "$1" ]; then
    echo "Fisierul nu exista"
    exit 2
fi
s=0
while read -r x; do
    s=$((s + x))
done < "$1"
echo $s
EOF'''],
}, hint='`while read -r x; do ...; done < fisier` citește câte o linie în `x`. Aritmetica se face cu `$((...))`.',
   solution='''
```bash
#!/bin/bash
if [ ! -f "$1" ]; then
    echo "Fisierul nu exista"
    exit 2
fi
s=0
while read -r x; do
    s=$((s + x))
done < "$1"
echo $s
```
Redirectarea `< "$1"` stă după `done`: toată bucla citește din fișier.''')

ren_setup = [{'path': f'~/.verif/poze/{n}', 'content': n} for n in ['munte.jpeg', 'mare.jpeg', 'oras.JPEG', 'harta.png', 'deja.jpg']]
add(15, 'Redenumire în serie', C4, 'grea', '''
Scrie `~/redenumeste.sh`, care redenumește în **directorul curent** toate fișierele cu extensia `.jpeg` în `.jpg` (păstrând restul numelui) și afișează pentru fiecare o linie `vechi -> nou`, în ordine alfabetică.

Exemplu, cu `munte.jpeg` și `mare.jpeg`:

```
mare.jpeg -> mare.jpg
munte.jpeg -> munte.jpg
```

Extensia scrisă cu majuscule (`.JPEG`) nu se atinge. Verificarea rulează scriptul în alte directoare și se uită și la ce fișiere au rămas.''', {
    'setup': [{'path': '~/poze/munte.jpeg', 'content': 'm'}, {'path': '~/poze/mare.jpeg', 'content': 'x'}],
    'checks': [{'type': 'script', 'path': '~/redenumeste.sh', 'runs': [
        {'cwd': '~/.verif/poze', 'setup': ren_setup, 'from_ref': True},
        {'cwd': '~/.verif/poze', 'setup': ren_setup, 'after': 'ls ~/.verif/poze', 'from_ref': True},
        {'cwd': '~/.verif/alt', 'setup': [{'path': '~/.verif/alt/a b.jpeg', 'content': '1'}, {'path': '~/.verif/alt/c.txt', 'content': '2'}], 'after': 'ls ~/.verif/alt', 'from_ref': True},
    ]}],
    'reference': ['''cat > ~/redenumeste.sh <<'EOF'
#!/bin/bash
for f in *.jpeg; do
    [ -e "$f" ] || continue
    nou="${f%.jpeg}.jpg"
    mv "$f" "$nou"
    echo "$f -> $nou"
done
EOF'''],
}, hint='`${f%.jpeg}` taie sufixul `.jpeg` din valoarea lui `f`. Pune numele între ghilimele, ca să meargă și cu spații.',
   solution='''
```bash
#!/bin/bash
for f in *.jpeg; do
    [ -e "$f" ] || continue
    nou="${f%.jpeg}.jpg"
    mv "$f" "$nou"
    echo "$f -> $nou"
done
```
`[ -e "$f" ] || continue` sare peste cazul în care nu există niciun `.jpeg` (globul rămâne atunci literal).''')

# ------------------------------------------------------------------ more (2026-11)
proj = [
    {'path': '~/proiect/src/main.c', 'content': 'int main(void) { return 0; }\n'},
    {'path': '~/proiect/src/main.c~', 'content': 'int main() {}\n'},
    {'path': '~/proiect/src/util.c', 'content': '/* util */\n'},
    {'path': '~/proiect/src/.util.c.swp', 'content': 'x'},
    {'path': '~/proiect/build/make.log', 'content': 'gcc -c main.c\ngcc -c util.c\n'},
    {'path': '~/proiect/build/test/run.log', 'content': 'ok 1\nok 2\nnot ok 3\n'},
    {'path': '~/proiect/notes.txt~', 'content': 'vechi\n'},
    {'path': '~/proiect/notes.txt', 'content': 'nou\n'},
    {'path': '~/proiect/install.log', 'content': 'done\n'},
]
add(16, 'Toate jurnalele într-un loc', C1, 'medie', '''
În `~/proiect` sunt fișiere `.log` împrăștiate prin mai multe subdirectoare (`build/`, `build/test/`, ...). Strânge-le pe toate, **copiate** (originalele rămân), direct în directorul nou `~/loguri`, fără subdirectoare:

```
loguri/
├── install.log
├── make.log
└── run.log
```''', {
    'setup': proj,
    'checks': [
        {'type': 'file', 'path': '~/loguri/make.log', 'equals': 'gcc -c main.c\ngcc -c util.c\n', 'msg': 'loguri/make.log e copia jurnalului din build/'},
        {'type': 'file', 'path': '~/loguri/run.log', 'equals': 'ok 1\nok 2\nnot ok 3\n', 'msg': 'loguri/run.log e copia celui din build/test/'},
        {'type': 'file', 'path': '~/loguri/install.log', 'equals': 'done\n'},
        {'type': 'file', 'path': '~/proiect/build/test/run.log', 'msg': 'originalele au rămas pe loc'},
        {'type': 'output', 'cmd': 'ls ~/loguri', 'from_ref': True, 'msg': 'în ~/loguri sunt doar cele trei jurnale'},
    ],
    'reference': ['mkdir ~/loguri', "find ~/proiect -name '*.log' -exec cp {} ~/loguri \\;"],
}, hint="`find dir -name '*.log'` le găsește la orice adâncime; `-exec cp {} dest \\;` rulează `cp` pentru fiecare, cu `{}` în locul numelui. Pune ghilimele la `'*.log'`, altfel shell-ul îl expandează înainte ca `find` să-l vadă.",
   solution='''
```bash
mkdir ~/loguri
find ~/proiect -name '*.log' -exec cp {} ~/loguri \\;
```
Sau, fără `-exec`: `for f in $(find ~/proiect -name '*.log'); do cp "$f" ~/loguri; done` (merge cât timp numele n-au spații).''')

add(17, 'Curățenie după editor', C1, 'ușoară', '''
Editorul a lăsat prin `~/proiect` copii de siguranță: fișiere al căror nume se termină în `~` (de exemplu `main.c~`) și fișiere de swap, ascunse, terminate în `.swp`. Șterge-le pe **toate**, oricât de adânc ar fi, fără să atingi nimic altceva.''', {
    'setup': proj,
    'checks': [
        {'type': 'absent', 'path': '~/proiect/src/main.c~'},
        {'type': 'absent', 'path': '~/proiect/notes.txt~'},
        {'type': 'absent', 'path': '~/proiect/src/.util.c.swp'},
        {'type': 'file', 'path': '~/proiect/src/main.c', 'msg': 'main.c a rămas'},
        {'type': 'file', 'path': '~/proiect/notes.txt', 'msg': 'notes.txt a rămas'},
        {'type': 'output', 'cmd': 'cd ~/proiect && find . -type f | sort', 'from_ref': True, 'msg': 'au rămas exact celelalte fișiere'},
    ],
    'reference': ["find ~/proiect -type f \\( -name '*~' -o -name '*.swp' \\) -delete"],
}, hint="`find` cu `-o` (sau) între două `-name`, totul între paranteze scrise `\\(` și `\\)`; la final `-delete`. Întâi rulează fără `-delete`, să vezi ce ar șterge.",
   solution='''
```bash
find ~/proiect -type f \\( -name '*~' -o -name '*.swp' \\) -delete
```
Fără paranteze, `-delete` s-ar lega doar de al doilea `-name`. Două comenzi separate (`find ... -name '*~' -delete`, apoi pentru `.swp`) dau același rezultat.''')

add(18, 'Ce poate rula oricine', C2, 'medie', '''
În `~/scripturi` sunt câteva fișiere, cu permisiuni diferite. Scrie în `~/publice.txt` numele (doar numele, sortate) fișierelor pe care **ceilalți** (others) le pot executa.

Apoi scoate dreptul de **scriere** pentru grup și pentru ceilalți de pe **toate** fișierele din `~/scripturi`, fără să schimbi altceva.''', {
    'setup': [
        {'path': '~/scripturi/backup.sh', 'content': '#!/bin/bash\n', 'mode': '775'},
        {'path': '~/scripturi/deploy.sh', 'content': '#!/bin/bash\n', 'mode': '770'},
        {'path': '~/scripturi/curata.sh', 'content': '#!/bin/bash\n', 'mode': '777'},
        {'path': '~/scripturi/note.txt', 'content': 'x\n', 'mode': '666'},
        {'path': '~/scripturi/run.sh', 'content': '#!/bin/bash\n', 'mode': '751'},
    ],
    'checks': [
        {'type': 'file', 'path': '~/publice.txt', 'equals': 'backup.sh\ncurata.sh\nrun.sh\n', 'msg': '~/publice.txt are fișierele executabile de oricine'},
        {'type': 'mode', 'path': '~/scripturi/backup.sh', 'mode': '755'},
        {'type': 'mode', 'path': '~/scripturi/deploy.sh', 'mode': '750'},
        {'type': 'mode', 'path': '~/scripturi/curata.sh', 'mode': '755'},
        {'type': 'mode', 'path': '~/scripturi/note.txt', 'mode': '644'},
        {'type': 'mode', 'path': '~/scripturi/run.sh', 'mode': '751'},
    ],
    'reference': ['cd ~/scripturi && find . -type f -perm -o=x | sed "s|^./||" | sort > ~/publice.txt', 'chmod go-w ~/scripturi/*'],
}, hint='`ls -l` arată permisiunile: al treilea grup `rwx` e al celorlalți. `find -perm -o=x` alege fișierele care au cel puțin bitul x pentru others. Pentru a doua parte, `chmod` simbolic: `go-w`.',
   solution='''
```bash
cd ~/scripturi
find . -type f -perm -o=x | sed 's|^./||' | sort > ~/publice.txt
chmod go-w ~/scripturi/*
```
Cu octal ar trebui un `chmod` diferit pentru fiecare fișier; forma simbolică `go-w` scoate un singur bit și le lasă pe celelalte cum erau.''')

add(19, 'Cuvintele cele mai dese', C3, 'grea', '''
În `~/text.txt` e un paragraf. Scrie în `~/frecvente.txt` cele **5 cuvinte cele mai frecvente**, cu numărul lor, în formatul `numar cuvant` (un spațiu între ele), de la cel mai frecvent. Cuvintele se compară **fără a ține cont de majuscule** (scrie-le cu litere mici), iar punctuația nu face parte din cuvânt. La egalitate, ordinea alfabetică.''', {
    'setup': [{'path': '~/text.txt', 'content': 'Shell-ul citeste o linie. Shell-ul o imparte in cuvinte, apoi cauta comanda.\nComanda primeste cuvintele ca argumente; argumentele sunt cuvinte, iar cuvintele sunt separate de spatii.\nO linie, o comanda: asa lucreaza shell-ul. Linie dupa linie.\n'}],
    'checks': [{'type': 'file', 'path': '~/frecvente.txt', 'from_ref': True, 'msg': '~/frecvente.txt are cele 5 cuvinte, cu numărul lor'}],
    'reference': ["tr 'A-Z' 'a-z' < text.txt | tr -cs 'a-z-' '\\n' | grep -v '^$' | sort | uniq -c | sort -k1,1nr -k2,2 | head -5 | awk '{print $1, $2}' > frecvente.txt"],
}, hint="Pașii: litere mici (`tr 'A-Z' 'a-z'`), un cuvânt pe linie (`tr -cs 'a-z-' '\\n'` înlocuiește tot ce nu e literă sau cratimă cu un singur `\\n`), apoi `sort | uniq -c`, sortare după număr descrescător și după cuvânt.",
   solution='''
```bash
tr 'A-Z' 'a-z' < text.txt | tr -cs 'a-z-' '\\n' | grep -v '^$' \\
  | sort | uniq -c | sort -k1,1nr -k2,2 | head -5 | awk '{print $1, $2}' > frecvente.txt
```
`sort -k1,1nr -k2,2`: întâi după primul câmp, numeric și descrescător, apoi după cuvânt. `awk` scoate spațiile de aliniere pe care le pune `uniq -c`.''')

add(20, 'Un script cu opțiuni', C4, 'grea', '''
Scrie `~/numara.sh`, care primește un **cuvânt** și apoi unul sau mai multe **fișiere** și afișează, pentru fiecare fișier, pe câte o linie, `fisier: N`, unde N e numărul de linii ale fișierului care conțin cuvântul. La final afișează `total: S`.

• fără argumente suficiente (mai puțin de 2), afișează `Utilizare: numara.sh cuvant fisier...` și iese cu codul **1**;
• un fișier care nu există se raportează ca `fisier: lipsa` și nu intră în total.

```
$ ~/numara.sh ERROR web.log db.log nu_e.log
web.log: 7
db.log: 3
nu_e.log: lipsa
total: 10
```''', {
    'setup': [{'path': '~/web.log', 'content': mklog(40, 1)}, {'path': '~/db.log', 'content': mklog(25, 2)}],
    'checks': [{'type': 'script', 'path': '~/numara.sh', 'runs': [
        {'cwd': '~/.verif', 'setup': [{'path': '~/.verif/a.log', 'content': mklog(30, 7)}, {'path': '~/.verif/b.log', 'content': mklog(12, 8)}], 'args': ['ERROR', 'a.log', 'b.log'], 'from_ref': True},
        {'cwd': '~/.verif', 'setup': [{'path': '~/.verif/a.log', 'content': mklog(30, 7)}], 'args': ['WARN', 'a.log', 'lipsa.log'], 'from_ref': True},
        {'cwd': '~/.verif', 'setup': [{'path': '~/.verif/a.log', 'content': 'ERROR x\n'}], 'args': ['ERROR'], 'from_ref': True},
    ]}],
    'reference': ['''cat > ~/numara.sh <<'EOF'
#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Utilizare: numara.sh cuvant fisier..."
    exit 1
fi
w="$1"
shift
total=0
for f in "$@"; do
    if [ -f "$f" ]; then
        n=$(grep -c -- "$w" "$f")
        echo "$f: $n"
        total=$((total + n))
    else
        echo "$f: lipsa"
    fi
done
echo "total: $total"
EOF'''],
}, hint='`$#` e numărul de argumente; după `shift`, `"$@"` sunt doar fișierele. `grep -c` dă numărul de linii potrivite, iar `$(...)` îl pune într-o variabilă.',
   solution='''
```bash
#!/bin/bash
if [ $# -lt 2 ]; then
    echo "Utilizare: numara.sh cuvant fisier..."
    exit 1
fi
w="$1"
shift
total=0
for f in "$@"; do
    if [ -f "$f" ]; then
        n=$(grep -c -- "$w" "$f")
        echo "$f: $n"
        total=$((total + n))
    else
        echo "$f: lipsa"
    fi
done
echo "total: $total"
```
`--` îi spune lui `grep` că ce urmează nu mai sunt opțiuni (cuvântul ar putea începe cu `-`).''')


write_course('uso', CHAPTERS, PROBLEMS)
