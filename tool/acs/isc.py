"""ISC — Introducere în Securitatea Cibernetică: flags recovered on a decoding bench.

Topics from the ISC lectures, labs and course tests (encodings and classical
ciphers from the cryptography lab, XOR with a known plaintext, and the
theory asked in the course tests: security properties, hashes, access
control, application, web and network security).

Each scrambled text is made here by encoding the flag with the inverse of the
reference steps; the app's test decodes it again with the app's own steps.
"""
import base64, os, sys, urllib.parse
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, quiz_multi, write_course

C1 = '1. Codificări'
C2 = '2. Cifruri clasice'
C3 = '3. XOR și text cunoscut'
C4 = '4. Mai multe straturi'
C5 = '5. Teorie: principii, criptografie, sisteme, web'
C6 = '6. Grile: proprietăți, criptografie, hardware de încredere'
C7 = '7. Grile: control acces, autentificare, sisteme'
C8 = '8. Grile: aplicații, web, rețea, forensics'
CHAPTERS = [C1, C2, C3, C4, C5, C6, C7, C8]
LAB = 'Laborator ISC · criptografie'
P = []


def shift(s, by):
    out = []
    for ch in s:
        if ch.isascii() and ch.isalpha():
            base = 65 if ch.isupper() else 97
            out.append(chr((ord(ch) - base + by) % 26 + base))
        else:
            out.append(ch)
    return ''.join(out)


def vig(s, key, sign):
    out, k = [], 0
    for ch in s:
        if ch.isascii() and ch.isalpha():
            base = 65 if ch.isupper() else 97
            out.append(chr((ord(ch) - base + sign * (ord(key[k % len(key)]) - 97)) % 26 + base)); k += 1
        else:
            out.append(ch)
    return ''.join(out)


def atbash(s):
    return ''.join(chr(155 - ord(c)) if c.isupper() else chr(219 - ord(c)) if c.islower() else c for c in s)


def encode(data, op, arg):
    """The inverse of the app's step: bytes -> bytes."""
    t = data.decode('latin-1')
    if op == 'hex':
        return data.hex().encode()
    if op == 'b64':
        return base64.b64encode(data)
    if op == 'bin':
        return ' '.join(f'{b:08b}' for b in data).encode()
    if op == 'url':
        return ''.join(f'%{b:02X}' for b in data).encode()
    if op == 'rot':
        return shift(t, int(arg)).encode()
    if op == 'vig':
        return vig(t, arg, 1).encode()
    if op == 'atbash':
        return atbash(t).encode()
    if op == 'xor':
        return bytes(b ^ ord(arg[i % len(arg)]) for i, b in enumerate(data))
    return data[::-1]


def bench(id, title, ch, diff, intro, flag, steps, hint, solution, source=''):
    data = flag.encode()
    for op, arg in reversed(steps):
        data = encode(data, op, arg)
    cipher = data.decode('ascii')
    assert all(32 <= ord(c) < 127 for c in cipher), (id, 'the scrambled text must be printable: end the steps with an encoding')
    spec = {'cipher': cipher, 'flag': flag, 'reference': [{'op': o, 'arg': str(a)} for o, a in steps]}
    P.append(problem(id, title, ch, diff, f'{intro}\n\nFlag-ul are forma `ISC{{...}}`.', 'crypto', spec, hint, solution, source))


bench(1, 'Hex', C1, 'ușoară', 'Un șir de cifre hexazecimale: fiecare pereche e un octet.', 'ISC{hex_is_not_encryption}', [('hex', '')],
      'Doar cifre `0-9` și litere `a-f`, în număr par: e hex.', 'Un singur pas: din hex. Codificarea nu ascunde nimic, doar schimbă alfabetul.', LAB)
bench(2, 'Base64', C1, 'ușoară', 'Litere mari și mici, cifre, poate `+`, `/` și `=` la sfârșit.', 'ISC{base64_ends_with_equals}', [('b64', '')],
      'Semnele `=` de la sfârșit sunt completarea (padding) din base64.', 'Un singur pas: din base64. Trei octeți devin patru caractere.', LAB)
bench(3, 'Binar', C1, 'ușoară', 'Doar `0` și `1`, în grupuri de câte opt.', 'ISC{8_bits}', [('bin', '')],
      'Fiecare grup de 8 biți e codul ASCII al unui caracter.', 'Un singur pas: din binar.', LAB)
bench(4, 'Codificare URL', C1, 'ușoară', 'Un text în care fiecare caracter a fost scris ca `%xx`.', 'ISC{percent_encoding}', [('url', '')],
      '`%41` e caracterul cu codul hex 41, adică `A`.', 'Un singur pas: din URL.')
bench(5, 'Base64 peste hex', C1, 'medie', 'Două codificări una peste alta.', 'ISC{layers_of_encoding}', [('b64', ''), ('hex', '')],
      'După primul pas, uită-te la ce a rămas: ce alfabet are?', 'Din base64 iese un șir hex; din hex iese flag-ul.', LAB)

bench(6, 'Cezar cu 3', C2, 'ușoară', 'Cifrul lui Cezar: fiecare literă a fost mutată cu 3 poziții înainte în alfabet.', 'ISC{veni_vidi_vici}', [('rot', 3)],
      'Mută fiecare literă înapoi cu 3.', 'Cezar, înapoi cu 3. Cifrele, acoladele și `_` rămân neschimbate.', LAB)
bench(7, 'Cezar, deplasare necunoscută', C2, 'medie', 'Tot Cezar, dar nu știi cu cât.', 'ISC{only_twentyfive_keys}', [('rot', 17)],
      'Sunt doar 25 de chei. Adaugă pasul Cezar fără număr și citește lista.', 'Forță brută: deplasarea 17 dă un text care se citește. Știi și că începe cu `ISC`.', LAB)
bench(8, 'ROT13 întors', C2, 'medie', 'Textul a fost cifrat cu ROT13 și apoi scris de la coadă la cap.', 'ISC{mirror_and_rotate}', [('rev', ''), ('rot', 13)],
      'Ordinea contează doar ca să înțelegi ce vezi: întâi întoarce textul.', 'Inversează, apoi Cezar înapoi cu 13 (ROT13 e propria lui inversă).')
bench(9, 'Atbash', C2, 'ușoară', 'Alfabetul a fost oglindit: `a ↔ z`, `b ↔ y`, ...', 'ISC{zyx_cba}', [('atbash', '')],
      'Atbash e propria lui inversă.', 'Un singur pas: Atbash.')
bench(10, 'Vigenère cu cheia dată', C2, 'medie', 'Vigenère cu cheia `lemon`: litera `i` a cheii spune cu cât e mutată litera `i` a textului.', 'ISC{attack_at_dawn}', [('vig', 'lemon')],
       'Pasul Vigenère scade cheia; ce nu e literă nu consumă din cheie.', 'Vigenère cu cheia `lemon`.', LAB)
bench(11, 'Vigenère, cheie de trei litere', C2, 'grea', 'Vigenère cu o cheie de 3 litere, necunoscută. Știi că textul începe cu `ISC`.', 'ISC{known_plaintext_breaks_it}', [('vig', 'dog')],
       'Litera cheii = litera cifrată minus litera în clar. Fă asta pentru primele trei litere.',
       'Primele trei litere cifrate sunt `LGI`: `L - I = d`, `G - S = o`, `I - C = g`. Cheia e `dog`.', LAB)

bench(12, 'XOR cu un caracter', C3, 'medie', 'Fiecare octet a fost combinat prin XOR cu caracterul `K`. Rezultatul e scris în hex.', 'ISC{xor_twice_is_identity}', [('hex', ''), ('xor', 'K')],
       'XOR cu aceeași cheie încă o dată dă înapoi textul.', 'Din hex, apoi XOR cu `K`: `(m ⊕ k) ⊕ k = m`.', LAB)
bench(13, 'XOR, cheie de un caracter, necunoscută', C3, 'grea', 'XOR cu un singur caracter necunoscut, apoi hex. Textul în clar începe cu `I`.', 'ISC{one_byte_key}', [('hex', ''), ('xor', 'z')],
       'Primul octet cifrat XOR `I` (hex `49`) este chiar cheia.', 'Primul octet e `33`: `0x33 ⊕ 0x49 = 0x7a`, adică `z`.', LAB)
bench(14, 'XOR cu cheie repetată', C3, 'grea', 'XOR cu o cheie de 3 caractere, repetată, apoi hex. Textul în clar începe cu `ISC`.', 'ISC{many_time_pad_fails}', [('hex', ''), ('xor', 'pad')],
       'Cheia = primii trei octeți cifrați XOR `I`, `S`, `C` (hex `49 53 43`).', 'Primii octeți sunt `39 32 27`: `39 ⊕ 49 = 70` (`p`), `32 ⊕ 53 = 61` (`a`), `27 ⊕ 43 = 64` (`d`). Cheia e `pad`.', 'Laborator ISC · many time pad')
bench(15, 'XOR și base64', C3, 'medie', 'XOR cu cheia `iSC`, apoi base64.', 'ISC{b64_wraps_binary}', [('b64', ''), ('xor', 'iSC')],
       'Rezultatul unui XOR nu e text, de aceea a fost împachetat în base64.', 'Din base64, apoi XOR cu `iSC`.')

bench(16, 'Trei straturi', C4, 'medie', 'Flag-ul a fost cifrat cu Cezar (cu 5), întors, apoi codificat base64.', 'ISC{peel_the_onion}', [('b64', ''), ('rev', ''), ('rot', 5)],
       'Desfaci straturile în ordinea inversă celei în care au fost puse.', 'Din base64, inversează, Cezar înapoi cu 5.')
bench(17, 'Ghicește straturile', C4, 'grea', 'Nu știi ce s-a făcut cu flag-ul. Uită-te la alfabetul fiecărui rezultat.', 'ISC{look_at_the_alphabet}', [('hex', ''), ('b64', ''), ('rot', 13)],
       'Cifre și `a-f`: hex. Litere mari, mici, cifre: base64. Text cu acolade care nu se citește: un cifru de substituție.', 'Din hex, din base64, apoi ROT13.')
bench(18, 'Binar, apoi Atbash, apoi invers', C4, 'medie', 'Trei transformări, niciuna cu cheie.', 'ISC{no_key_no_secret}', [('bin', ''), ('atbash', ''), ('rev', '')],
       'Dacă un algoritm nu are cheie, cine îl cunoaște poate desface oricând.', 'Din binar, Atbash, inversează. Principiul lui Kerckhoffs: secretul trebuie să stea în cheie, nu în algoritm.')
bench(19, 'URL, base64, Vigenère', C4, 'grea', 'Un parametru dintr-o adresă web. Cheia Vigenère e `web`.', 'ISC{decode_the_query_string}', [('url', ''), ('b64', ''), ('vig', 'web')],
       'Întâi scapă de `%xx`.', 'Din URL, din base64, Vigenère cu cheia `web`.')
bench(20, 'Patru straturi', C4, 'grea', 'XOR cu `7`, hex, întors, base64.', 'ISC{four_layers_deep}', [('b64', ''), ('rev', ''), ('hex', ''), ('xor', '7')],
       'Ordinea inversă: base64, apoi întoarce, apoi hex, apoi XOR.', 'Din base64, inversează, din hex, XOR cu `7`.')

# ---------------------------------------------------------------- teorie
T = 'Test curs ISC'


def q(id, title, diff, st, right, wrong, hint, sol, source=''):
    P.append(quiz(id, title, C5, diff, st, right, wrong, hint, sol, source))


q(21, 'Date modificate', 'ușoară', 'Ce proprietate de securitate cere ca orice modificare a datelor să fie autorizată?',
  'integritatea', ['confidențialitatea', 'disponibilitatea', 'anonimatul'], 'Triada CIA.', 'Confidențialitate: cine poate citi. Integritate: cine poate modifica. Disponibilitate: datele sunt accesibile celor autorizați.', T)
q(22, 'Revenirea la o stare bună', 'ușoară', 'O companie vrea să poată reveni la starea dinaintea unui incident (rollback). Ce o ajută?',
  'un server de backup', ['un server VPN', 'un server de autentificare', 'un sistem de detecție a intruziunilor'], 'Ce păstrează copii ale datelor?', 'Backup-ul permite recuperarea; IDS-ul doar detectează, VPN-ul protejează transportul.', T)
q(23, 'Diffie-Hellman', 'ușoară', 'Ce problemă rezolvă algoritmul Diffie-Hellman?',
  'schimbul de chei peste un canal nesigur', ['criptarea datelor', 'autentificarea datelor', 'garantarea integrității'], 'Cele două părți ajung la același secret fără să-l trimită.', 'DH stabilește o cheie comună; singur nu autentifică părțile, deci e vulnerabil la un om-la-mijloc.', T)
q(24, 'Actualizare nemodificată', 'ușoară', 'Cum verifică un administrator că o actualizare nu a fost modificată de când a publicat-o producătorul?',
  'compară hash-ul (SHA-2 / SHA-3) al fișierului cu cel publicat', ['o descarcă printr-o conexiune criptată cu AES', 'o rulează și vede dacă merge', 'descarcă o variantă criptată'], 'Integritate, nu confidențialitate.', 'Un hash criptografic se schimbă la orice modificare; o semnătură digitală arată în plus și cine a publicat.', T)
q(25, 'Același utilizator?', 'medie', 'Ce proprietate garantează că administratorul unei baze de date nu poate stabili dacă același utilizator a accesat serverul de mai multe ori?',
  'imposibilitatea de corelare (unlinkability)', ['anonimatul', 'pseudonimitatea', 'autenticitatea'], 'Nu e vorba de cine este, ci de legătura dintre două accesări.', 'Cu un pseudonim identitatea e ascunsă, dar accesările se pot lega între ele; unlinkability o împiedică.', T)
q(26, 'Rostul sării', 'medie', 'De ce se adaugă o sare (salt) la parolă înainte de calculul hash-ului?',
  'ca aceeași parolă să dea hash-uri diferite și tabelele precalculate (rainbow tables) să nu mai folosească', ['ca parola să poată fi decriptată de administrator', 'ca hash-ul să fie mai scurt', 'ca să nu mai fie nevoie de hash'], 'Sarea nu e secretă, dar e diferită pentru fiecare utilizator.', 'Atacatorul trebuie să refacă munca pentru fiecare sare în parte.', T)
q(27, 'Criptare simetrică și asimetrică', 'ușoară', 'Care afirmație este corectă?',
  'la criptarea asimetrică se criptează cu cheia publică a destinatarului și se decriptează cu cheia lui privată', ['la criptarea simetrică fiecare parte are o cheie diferită', 'RSA este un cifru simetric', 'AES folosește o pereche de chei publică/privată'], 'Cheia publică poate fi cunoscută de oricine.', 'AES e simetric (aceeași cheie); RSA e asimetric. În practică, cheia simetrică e schimbată cu ajutorul celei asimetrice.')
q(28, 'Drepturi pe fișier', 'ușoară', 'Un fișier are drepturile `640`. Ce poate face grupul proprietar?',
  'doar să citească', ['să citească și să scrie', 'nimic', 'să citească și să execute'], '`r = 4`, `w = 2`, `x = 1`; cifrele sunt pentru proprietar, grup, ceilalți.', '`6 = rw-` pentru proprietar, `4 = r--` pentru grup, `0 = ---` pentru ceilalți.')
q(29, 'setuid', 'medie', 'Ce înseamnă bitul setuid pe un executabil deținut de root?',
  'programul rulează cu drepturile proprietarului (root), oricine l-ar lansa', ['doar root îl poate lansa', 'programul nu poate fi șters', 'programul rulează cu drepturile grupului'], 'Așa poate `passwd` să scrie în `/etc/shadow`.', 'De aceea un executabil setuid cu o vulnerabilitate duce la escaladare de privilegii.')
q(30, 'Canarul de stivă', 'medie', 'Ce detectează un canar (stack canary)?',
  'suprascrierea adresei de retur printr-o depășire de buffer pe stivă', ['executarea de cod de pe stivă', 'ghicirea adreselor din memorie', 'injecțiile SQL'], 'Valoarea e pusă între variabilele locale și adresa de retur.', 'Canarul e verificat înainte de `ret`. NX oprește executarea datelor, ASLR face adresele imprevizibile.')
q(31, 'ASLR', 'medie', 'Împotriva cărui lucru protejează ASLR?',
  'împotriva atacurilor care se bazează pe adrese cunoscute dinainte (salt la o funcție, return-to-libc)', ['împotriva depășirii propriu-zise a bufferului', 'împotriva parolelor slabe', 'împotriva interceptării traficului'], 'Address Space Layout Randomization.', 'Stiva, heap-ul și bibliotecile sunt încărcate la adrese aleatoare la fiecare rulare.')
q(32, 'Injecția SQL', 'ușoară', 'Care este apărarea corectă împotriva injecției SQL?',
  'interogări parametrizate (prepared statements)', ['ascunderea mesajelor de eroare', 'validarea datelor doar în browser, cu JavaScript', 'folosirea metodei POST în loc de GET'], 'Datele nu trebuie să ajungă niciodată să fie interpretate drept cod SQL.', 'Cu parametri, structura interogării e fixată înainte ca datele utilizatorului să fie adăugate.')
q(33, 'XSS', 'medie', 'Ce face un atac XSS (cross-site scripting)?',
  'face browserul victimei să ruleze un script al atacatorului în contextul site-ului', ['trimite interogări SQL către baza de date', 'ghicește parola administratorului', 'interceptează traficul dintre client și server'], 'Scriptul rulează cu drepturile paginii: vede cookie-urile ei.', 'Apărare: codificarea a tot ce vine de la utilizator la afișare și Content-Security-Policy.')
q(34, 'CSRF', 'grea', 'De ce funcționează un atac CSRF?',
  'browserul atașează automat cookie-urile site-ului la orice cerere către el, chiar pornită de pe alt site', ['serverul nu criptează parolele', 'atacatorul citește răspunsul serverului', 'JavaScript-ul atacatorului rulează pe site-ul țintă'], 'Atacatorul nu vede răspunsul; îi ajunge că cererea se execută.', 'Apărare: un token anti-CSRF pe care alt site nu-l poate afla, și cookie-uri `SameSite`.')
q(35, 'Cel mai mic privilegiu', 'ușoară', 'Ce spune principiul celui mai mic privilegiu?',
  'fiecare utilizator sau program primește doar drepturile de care are nevoie pentru sarcina lui', ['administratorul are toate drepturile', 'drepturile se dau pe grupuri, nu pe utilizatori', 'toate fișierele sunt implicit publice'], 'Limitează ce poate strica un cont compromis.', 'Un serviciu compromis poate face doar ce avea voie serviciul.')
q(36, 'Ce asigură TLS', 'medie', 'Ce garantează certificatul serverului într-o conexiune TLS?',
  'că vorbești cu serverul al cărui nume e în certificat (autentificarea serverului)', ['că serverul nu are vulnerabilități', 'că parola ta e puternică', 'că site-ul nu colectează date personale'], 'Certificatul leagă o cheie publică de un nume, sub semnătura unei autorități.', 'TLS dă confidențialitate și integritate pe canal și autentifică serverul; nu spune nimic despre ce face serverul cu datele.')

# ---------------------------------------------------------------- more benches
bench(41, 'Hex, XOR, base64', C4, 'grea', 'XOR cu cheia `key`, apoi hex, apoi base64.', 'ISC{hex_inside_base64}', [('b64', ''), ('hex', ''), ('xor', 'key')],
      'Base64 dă un șir care arată ca hex: încă un strat.', 'Din base64, din hex, XOR cu `key`.')
bench(42, 'Cezar peste binar', C4, 'medie', 'Flag-ul a fost cifrat cu Cezar (cu 7) și apoi scris în binar.', 'ISC{bits_then_letters}', [('bin', ''), ('rot', 7)],
      'Din binar iese un text cu acolade care nu se citește încă.', 'Din binar, apoi Cezar înapoi cu 7.')
bench(43, 'Vigenère cu cheie lungă', C2, 'grea', 'Vigenère cu cheia `security`.', 'ISC{longer_keys_help_a_little}', [('vig', 'security')],
      'Cheia se repetă peste literele textului; acoladele și `_` nu consumă din ea.', 'Vigenère cu cheia `security`. O cheie mai lungă rezistă mai mult la analiza frecvențelor, dar repetarea ei o trădează (testul Kasiski).')
bench(44, 'Atbash și Cezar', C2, 'medie', 'Atbash, apoi Cezar cu 4.', 'ISC{two_substitutions_are_one}', [('rot', 4), ('atbash', '')],
      'Desface întâi ultimul pas aplicat.', 'Cezar înapoi cu 4, apoi Atbash. Două substituții monoalfabetice compuse sunt tot o substituție monoalfabetică: nu e mai sigur.')
bench(45, 'XOR cu cheie de 4, text cunoscut', C3, 'grea', 'XOR cu o cheie de 4 caractere, repetată, apoi hex. Textul în clar începe cu `ISC{`.', 'ISC{four_known_bytes}', [('hex', ''), ('xor', 'w1fi')],
      'Patru octeți cunoscuți dau patru octeți de cheie.', 'Primii patru octeți cifrați XOR `49 53 43 7b` dau cheia `w1fi`.', 'Laborator ISC · many time pad')
bench(46, 'URL peste hex', C1, 'ușoară', 'Un text hex care a trecut printr-un formular web.', 'ISC{url_then_hex}', [('url', ''), ('hex', '')],
      'Întâi `%xx`, apoi hex.', 'Din URL, apoi din hex.')


# ---------------------------------------------------------------- the TSSC tests
TC = 'Test curs TSSC'
EF = 'Examen final TSSC (2022)'
E19 = 'Examen TSSC (2019)'


def g(id, ch, title, diff, st, right, wrong, sol, src, hint=''):
    P.append(quiz(id, title, ch, diff, st, right, wrong, hint, sol, src))


g(101, C6, 'Date stocate, nemodificate', 'ușoară', 'Ce proprietate de securitate protejează datele stocate (at rest) împotriva modificării?',
  'integritatea', ['disponibilitatea', 'confidențialitatea', 'autenticitatea'], 'Integritate: orice modificare a datelor trebuie să fie autorizată (și detectabilă).', TC)
g(102, C6, 'Cine a trimis e-mailul', 'medie', 'Ce concept se asigură certificând că un e-mail a fost trimis chiar de cel care apare ca expeditor, astfel încât acesta să nu poată nega?',
  'non-repudierea', ['integritatea', 'auditul', 'confidențialitatea'], 'Semnătura digitală leagă mesajul de cheia privată a expeditorului: el nu mai poate spune că nu l-a trimis.', TC)
g(105, C6, 'Rainbow tables', 'medie', 'Ce tip de atac se face împotriva funcțiilor hash folosind un rainbow table?',
  'un atac de tip forță brută (precalculat)', ['un atac cu text cifrat ales', 'un atac de coliziune', 'un atac cu text clar ales'],
  'Tabelele precalculează lanțuri de hash-uri pentru parole posibile: forță brută cu un compromis timp-memorie. Sarea (salt) le face inutile.', TC)
g(106, C6, 'Ce vrea atacatorul', 'ușoară', 'Ești atacator și vrei să compromiți date criptate. Ce ți-ar fi cel mai util?',
  'o cheie slabă', ['un cifru bloc', 'traficul capturat', 'un algoritm public'], 'Cu un algoritm bun, secretul e în cheie (principiul lui Kerckhoffs): o cheie scurtă sau previzibilă se ghicește.', TC)
g(109, C6, 'Criptarea discului', 'ușoară', 'Ce tip de criptare se folosește pentru criptarea unui hard disk?', 'simetrică', ['asimetrică', 'hashing', 'WPA2'],
  'Volume mari, criptate și decriptate des: AES. Cheia simetrică poate fi apoi protejată de TPM sau de o parolă.', TC)
P.append(quiz_multi(110, 'Root of Trust', C6, 'medie', 'Ce poate fi folosit ca Root of Trust? (unul sau mai multe)',
                    ['un sistem de operare', 'un HSM', 'un modul TPM', 'un hypervisor'], [1, 2],
                    solution='Rădăcina de încredere e hardware, greu de modificat: HSM și TPM. Sistemul de operare și hypervisorul sunt software, verificate pornind de la ea.', source=TC))
g(111, C6, 'Stocare securizată în hardware', 'medie', 'Un administrator vrea stocare securizată, în hardware. Ce platformă poate folosi?',
  'oricare dintre TPM, TrustZone și SGX', ['doar TPM', 'doar TrustZone', 'doar SGX'], 'Toate trei pot sigila date (sealed storage): datele se decriptează doar pe aceeași platformă, în aceeași stare.', TC)
g(112, C6, 'Atestare la distanță cu SGX', 'grea', 'Un verificator vrea să ateste de la distanță că un program rulează într-o enclavă SGX la un furnizor de cloud. Ce poate servi drept dovadă?',
  'un certificat (o cotă) semnat de procesorul cu SGX', ['un certificat semnat de sistemul de operare', 'un certificat semnat de programul din enclavă', 'un certificat semnat de hypervisor'],
  'Sistemul de operare și hypervisorul nu sunt de încredere în modelul SGX; doar procesorul (cu cheile lui) garantează ce rulează în enclavă.', TC)
g(113, C6, 'Câte medii izolate oferă TrustZone', 'medie', 'Câte medii de execuție izolate, asistate de hardware, oferă TrustZone?', '1', ['oricâte', '2', '0'],
  'TrustZone împarte procesorul în două lumi, normală și securizată: există o singură lume securizată. SGX, în schimb, permite oricâte enclave.', TC)
g(114, C6, 'TEE: TrustZone și SGX', 'medie', 'Câte TEE-uri (medii de execuție de încredere) pot fi create cu TrustZone? Dar cu SGX?', '1 / oricâte', ['oricâte / 1', 'oricâte / oricâte', '1 / 1'],
  'O singură lume securizată la TrustZone; enclave câte vrei la SGX.', E19)
g(115, C6, 'Cheie simetrică și hash', 'ușoară', 'Care dintre următorii algoritmi folosește o cheie simetrică și o funcție hash?', 'HMAC', ['SHA2', 'RSA', '3DES'],
  'HMAC = un hash calculat peste mesaj și cheia secretă: integritate și autentificare.', EF)
g(116, C6, 'Trusted timestamp', 'medie', 'Care dintre următoarele scheme poate fi folosită pentru un „trusted timestamp” (marcă de timp de încredere)?', 'RSA (o semnătură)', ['SHA256', 'AES256', 'SCA'],
  'Autoritatea semnează hash-ul documentului împreună cu momentul: e nevoie de o semnătură, nu doar de un hash sau de criptare simetrică.', EF)
g(117, C6, 'TCB', 'medie', 'Ce conține trusted computing base (TCB)?', 'toate componentele hardware și software de încredere',
  ['toate politicile de securitate', 'toate aplicațiile instalate', 'toate procesele care rulează ca root'], 'TCB-ul e tot ce, dacă e compromis, compromite securitatea sistemului; se vrea cât mai mic.', EF)
g(118, C6, 'Root of Trust la criptarea discului', 'ușoară', 'Care este „Root of Trust” folosit de sistemul de operare la criptarea hard disk-ului (de exemplu BitLocker)?', 'TPM', ['kernelul', 'UEFI', 'MBR'],
  'TPM-ul eliberează cheia doar dacă măsurătorile pornirii sunt cele așteptate.', EF)
g(119, C6, 'Protecția datelor în tranzit', 'ușoară', 'Ce tehnologie protejează datele în tranzit?', 'IPsec', ['TPM', 'HSM', 'TEE'], 'Celelalte protejează chei și date pe dispozitiv; IPsec criptează pachetele în rețea.', EF)

g(130, C7, 'Monitorul de referință', 'medie', 'Ce tip de control al accesului cere un monitor de referință care decide la ce obiecte au acces subiecții, după etichete impuse de sistem?',
  'Mandatory Access Control (MAC)', ['Discretionary Access Control (DAC)', 'Non-Discretionary Access Control', 'controlul bazat pe reguli'], 'La MAC politica e a sistemului (etichete, niveluri), nu a proprietarului; exemple: SELinux, Bell-LaPadula.', TC)
g(131, C7, 'Modelul din Linux', 'ușoară', 'Linux folosește un model de control al accesului definit de proprietarul (creatorul) informației. Cum se numește?', 'DAC', ['MAC', 'RBAC', 'UCON'],
  'Proprietarul fișierului își alege permisiunile (`chmod`).', TC)
g(132, C7, 'Chinese Wall', 'grea', 'Clase de conflict: `{Tesla, Dacia, BMW}`, `{ING, BCR, BRD}`, `{Microsoft, UIPath, Bitdefender}`. Bob a accesat un obiect de la Tesla și cinci de la BCR. Ce NU mai are voie să acceseze, după politica Chinese Wall?',
  'un obiect de la Dacia', ['un obiect de la UIPath', 'un obiect de la Tesla', 'un obiect de la BCR'],
  'Odată ales Tesla, celelalte firme din aceeași clasă de conflict îi sunt interzise. Tesla și BCR rămân permise, iar din a treia clasă poate încă alege una.', TC)
g(133, C7, 'Autentificare cu mai mulți factori', 'ușoară', 'Care dintre următoarele este o autentificare cu mai mulți factori?', 'PIN și smart card', ['parolă și PIN', 'amprentă și scanarea irisului', 'smart card și ecuson'],
  'Factorii trebuie să fie de tipuri diferite: ceva ce știi (PIN), ceva ce ai (card), ceva ce ești (biometrie). Doi factori de același tip nu se pun.', TC)
g(134, C7, 'cat cu setuid', 'grea', '`super-secret.txt` are drepturile `-rw-rw---- root root`, iar `/bin/cat` are `-rwsr-xr-x root root`. Utilizatorul `mihai` rulează `cat super-secret.txt`. Se afișează conținutul?',
  'da, din cauza bitului setuid de pe `/bin/cat`', ['nu, mihai nu are drept de citire', 'da, din cauza permisiunilor DAC ale fișierului', 'da, din cauza bitului setuid de pe fișier'],
  '`cat` rulează cu utilizatorul efectiv `root`, care citește orice. Un setuid pe un utilitar ca acesta e o gaură de securitate.', TC)
g(135, C7, 'Ce nu e factor de autentificare', 'ușoară', 'Care dintre următoarele NU este un model (factor) de autentificare?', 'ceva ce există', ['ceva ce știi', 'ceva ce ești', 'ceva ce ai'],
  'Cele trei categorii: cunoaștere, posesie, inerență.', EF)
g(136, C7, 'Bypass la KMCI', 'grea', 'Cum poate un atacator ocoli „Kernel Mode Code Integrity” (KMCI), care permite doar cod de kernel semnat?',
  'cu un atac de tip return-oriented programming', ['nu se poate ocoli o protecție din kernel', 'cu cheia publică a unui driver recunoscut', 'modificând un modul de kernel valid și reinstalându-l'],
  'ROP nu introduce cod nou: înlănțuie bucăți din codul deja semnat, deci verificarea semnăturii nu îl oprește. Un modul modificat nu mai are semnătura validă.', EF)
g(137, C7, 'Sandboxing pe mobil', 'ușoară', 'La ce folosește sandboxing-ul în sistemele de operare mobile?', 'la limitarea accesului aplicațiilor la resurse (fișiere, rețea...)',
  ['la verificarea identității dezvoltatorului', 'la prevenirea oricărui atac asupra sistemului', 'la limitarea numărului de aplicații care rulează simultan'], 'Fiecare aplicație are directorul ei și doar permisiunile cerute.', EF)
g(138, C7, 'Semnarea aplicațiilor mobile', 'ușoară', 'Semnarea unei aplicații mobile este folosită pentru a...', 'identifica dezvoltatorul',
  ['activa mecanismul DEP', 'oferi un nivel ridicat de securitate la execuție', 'plasa aplicația într-un sandbox dedicat'], 'Semnătura spune cine a publicat aplicația și că nu a fost modificată; nu spune că aplicația e sigură.', E19)
g(139, C7, 'JIT și DEP', 'grea', 'Ce mecanism de protecție devine inutil (trebuie relaxat) când se folosește un compilator „just in time”?', 'DEP', ['firewall-ul', 'ACE', 'BitLocker'],
  'JIT-ul scrie cod în memorie și apoi îl execută: are nevoie de pagini care sunt și scriabile, și executabile, exact ce interzice DEP (W^X).', E19)
g(140, C7, 'Atac asupra Secure World', 'medie', 'Ce tip de atac se poate realiza împotriva unei aplicații care rulează în TrustZone Secure World?', 'toate variantele',
  ['return to libc', 'buffer overflow', 'return oriented programming'], 'Izolarea nu face codul corect: o aplicație vulnerabilă din lumea securizată poate fi exploatată la fel.', E19)
g(141, C7, 'Driverul care ține minte tastele', 'ușoară', 'Un driver de sunet compromis salvează toate tastele apăsate într-un fișier accesibil tuturor programelor. Ce tip de atac este?', 'cal troian (Trojan horse)',
  ['buffer overflow', 'DAC', 'XSS'], 'Un program care pare legitim și face pe ascuns altceva.', E19)

g(150, C8, 'Ciocanul', 'ușoară', 'Ce componentă a securității e afectată când cineva distruge un calculator cu un ciocan?', 'disponibilitatea', ['confidențialitatea', 'integritatea', 'toate variantele'],
  'Datele nu sunt citite sau modificate de nimeni; doar nu mai pot fi folosite.', EF)
g(151, C8, 'Florin și e-mailul', 'ușoară', 'Florin trimite un e-mail, iar compania vrea să poată dovedi asta. Ce concept trebuie implementat?', 'non-repudierea', ['integritatea', 'confidențialitatea', 'autentificarea'],
  'Dovada că el l-a trimis, pe care nu o poate nega: semnătură digitală.', EF)
g(152, C8, 'Poza cu informații clasificate', 'ușoară', 'O investigație descoperă o poză care conține informații clasificate. Ce metodă a folosit atacatorul ca să exfiltreze datele prin rețea?', 'steganografia',
  ['încapsularea datelor', 'deschiderea de socketuri', 'criptarea'], 'Datele sunt ascunse în pixelii unei imagini aparent banale.', EF)
g(153, C8, 'Certificat emis fără să-l ceri', 'medie', 'Un server web descoperă că există un certificat TLS valid emis pentru domeniul lui, deși nu l-a cerut. Ce tehnologie i-a permis să afle?', 'certificate transparency',
  ['certificate enforcement', 'certificate revocation list', 'certificate privacy'], 'Autoritățile publică fiecare certificat emis în jurnale publice, verificabile: proprietarul domeniului poate vedea orice certificat emis pe numele lui.', EF)
g(154, C8, 'Unde se validează datele', 'ușoară', 'O aplicație web are un singur server și în spate o bază de date în cluster. Unde trebuie validate datele primite de la utilizator?', 'pe serverul web',
  ['nicăieri, dacă se folosește HTTPS', 'cu o extensie de browser', 'doar în JavaScript, pe client'], 'Validarea din client se ocolește ușor; serverul e ultimul punct pe care îl controlezi înainte de baza de date.', EF)
g(155, C8, 'tar și backup-ul', 'medie', 'Comanda `tar czvf backup.tar.gz .` arhivează directorul curent. Poate duce la compromiterea serverului?',
  'da, dacă directorul e servit pe web și drepturile lui sunt greșite', ['da, dacă unul dintre fișiere conține viruși', 'nu, tar nu are vulnerabilități cunoscute', 'nu, un atacator nu poate rula tar pe server'],
  'Arhiva ajunge chiar în directorul arhivat: dacă e public pe web, oricine descarcă tot codul și configurațiile (parole, chei).', EF)
g(156, C8, 'TOR: intrări și ieșiri', 'grea', 'Ce poate afla un atacator care observă toate intrările și ieșirile unei rețele TOR?', 'tot: cine cu cine vorbește (corelând traficul)',
  ['doar cine accesează, nu și ce', 'nimic, totul e anonim', 'doar ce se accesează, nu și cine'], 'TOR nu rezistă unui adversar global: momentele și volumele pachetelor de la intrare și de la ieșire se pot corela.', EF)
g(157, C8, 'Ce vede serverul prin TOR', 'medie', 'Ce află un server web accesat prin rețeaua TOR de calculatorul lui Mihai?', 'adresa IP a ultimului nod din circuit (nodul de ieșire)',
  ['adresele IP ale tuturor nodurilor', 'nimic', 'adresa IP a lui Mihai'], 'Serverul vede conexiunea venind de la nodul de ieșire.', EF)
g(158, C8, 'YouTube care te trimite în altă parte', 'medie', 'Florin accesează YouTube, dar ajunge pe un site de „tech support”. Ce atac poate explica asta?', 'DNS poisoning',
  ['CSRF', 'phishing', 'adware'], 'Numele de domeniu corect e rezolvat la o adresă greșită.', EF)
g(159, C8, 'Atacuri STP', 'medie', 'Ce metodă protejează împotriva atacurilor asupra protocolului STP?', 'BPDU guard', ['MITM', 'sticky MAC', 'VLAN hopping'],
  'Pe porturile spre stații nu trebuie să apară BPDU-uri; dacă apar (un atacator care vrea să devină root bridge), portul se închide.', E19)
g(160, C8, 'Raportul de forensics pentru CEO', 'ușoară', 'Care e cea mai importantă componentă a unui raport de forensics pentru un CEO?', 'sumarul',
  ['detalierea informațiilor identificate', 'numele investigatorului', 'procedura folosită'], 'Un rezumat pe înțelesul conducerii: ce s-a întâmplat, ce impact are, ce e de făcut.', E19)
g(161, C8, 'Procesele active', 'ușoară', 'În ce etapă a unei investigații se salvează informațiile despre procesele active pe calculatorul analizat?', 'colectare',
  ['analiză', 'pregătire', 'raportare'], 'Datele volatile (memorie, procese, conexiuni) se colectează primele, înainte de a opri mașina.', E19)
g(162, C8, 'Certificat expirat pe un singur PC', 'medie', 'Într-o companie mare, un singur PC afișează „SSL certificate has expired”. Care e cauza probabilă?', 'data sistemului pe acel PC este greșită',
  ['certificatul nu a fost reînnoit', 'are loc un atac man-in-the-middle', 'browserul nu e actualizat'], 'Dacă certificatul ar fi expirat cu adevărat, l-ar vedea toate calculatoarele.', E19)
g(163, C8, 'Cookie-uri', 'ușoară', 'Care afirmație despre cookie-urile HTTP este adevărată?', 'sunt folosite pentru a implementa autentificarea pe web',
  ['nu trebuie folosite niciodată, pentru că utilizatorul le poate modifica', 'cookie-urile criptate sunt perfect sigure', 'sunt cea mai bună formă de urmărire a utilizatorului'], 'Sesiunea după login e de obicei un cookie; marcat `HttpOnly`, `Secure`, `SameSite`.', E19)

write_course('isc', CHAPTERS, P)
