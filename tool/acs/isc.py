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
from common import problem, quiz, write_course

C1 = '1. Codificări'
C2 = '2. Cifruri clasice'
C3 = '3. XOR și text cunoscut'
C4 = '4. Mai multe straturi'
C5 = '5. Teorie: principii, criptografie, sisteme, web'
CHAPTERS = [C1, C2, C3, C4, C5]
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

write_course('isc', CHAPTERS, P)
