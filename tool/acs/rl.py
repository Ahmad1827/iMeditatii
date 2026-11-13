"""RL — Rețele Locale: addresses worked out on their bits.

Topics from the RL lectures, the midterm model and the exams (seria CB/CC/CD):
IPv4 addressing and subnetting, VLSM, route aggregation, the routing table
(longest prefix match), and the theory of the data link, STP, VLANs and NAT.
Every address here is computed with Python's ipaddress module.
"""
import ipaddress, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, write_course

C1 = '1. Adrese, măști, subrețele'
C2 = '2. Împărțirea în subrețele (VLSM)'
C3 = '3. Rutare'
C4 = '4. Legătura de date și comutare'
C5 = '5. Servicii și securitate'
C6 = '6. Nivelul fizic: codificări, CRC, Hamming'
CHAPTERS = [C1, C2, C3, C4, C5, C6]
EXR = 'Examen RL (N. Țăpuș, 2012-2017)'
P = []


def f(id, label, answer, hint='', number=False, tol=0):
    d = {'id': id, 'label': label, 'answer': str(answer), 'hint': hint}
    if number:
        d['number'] = True
        d['tol'] = tol
    return d


def net(id, title, ch, diff, statement, fields, hint, solution, ip='', prefix=24, source=''):
    P.append(problem(id, title, ch, diff, statement, 'net', {'fields': fields, 'ip': ip, 'prefix': prefix}, hint, solution, source))


def addressing(id, title, diff, ip, prefix, hint):
    n = ipaddress.ip_network(f'{ip}/{prefix}', strict=False)
    hosts = list(n.hosts())
    fields = [
        f('net', 'adresa de rețea', n.network_address, 'a.b.c.d'),
        f('bc', 'adresa de difuzare (broadcast)', n.broadcast_address, 'a.b.c.d'),
        f('first', 'prima adresă de stație', hosts[0], 'a.b.c.d'),
        f('last', 'ultima adresă de stație', hosts[-1], 'a.b.c.d'),
        f('mask', 'masca, în zecimal', n.netmask, 'a.b.c.d'),
        f('n', 'câte stații pot primi adrese', len(hosts), 'un număr', number=True),
    ]
    sol = (f'`/{prefix}` lasă `{32 - prefix}` biți de stație: `2^{32 - prefix} - 2 = {len(hosts)}` stații. Masca: `{n.netmask}`. '
           f'Rețea `{n.network_address}`, difuzare `{n.broadcast_address}`, stații de la `{hosts[0]}` la `{hosts[-1]}`.')
    net(id, title, C1, diff, f'O stație are adresa `{ip}/{prefix}`. Completează datele rețelei din care face parte.', fields, hint, sol, ip=ip, prefix=prefix)


addressing(1, 'O rețea /24', 'ușoară', '192.168.10.77', 24, 'Ultimul octet întreg e de stație.')
addressing(2, 'O rețea /26', 'ușoară', '192.168.1.70', 26, 'Doi biți din ultimul octet sunt de rețea: subrețelele încep la 0, 64, 128, 192.')
addressing(3, 'O rețea /28', 'medie', '10.0.5.200', 28, 'Subrețelele au câte 16 adrese: caută multiplul de 16 de sub 200.')
addressing(4, 'O rețea /30', 'ușoară', '172.16.0.9', 30, 'O legătură punct la punct: 4 adrese, din care 2 de stație.')
addressing(5, 'O rețea /20', 'medie', '172.16.37.5', 20, 'Granița e în al treilea octet: 4 biți de rețea, deci blocuri de câte 16 (0, 16, 32, 48...).')
addressing(6, 'O rețea /22', 'medie', '10.10.45.130', 22, 'Al treilea octet merge în blocuri de câte 4: 44 e multiplu de 4.')
addressing(7, 'O rețea /27', 'medie', '192.168.200.99', 27, 'Blocuri de 32 de adrese: 0, 32, 64, 96...')
addressing(8, 'O rețea /19', 'grea', '10.200.100.1', 19, 'Blocuri de câte 32 în al treilea octet: 96 ≤ 100 < 128.')


def same(id, title, diff, a, b, prefix):
    na, nb = (ipaddress.ip_network(f'{x}/{prefix}', strict=False) for x in (a, b))
    yes = na == nb
    net(id, title, C1, diff,
        f'Stațiile `{a}` și `{b}` au amândouă masca `/{prefix}`. Găsește rețeaua fiecăreia și spune dacă pot comunica direct, fără ruter.',
        [f('a', f'rețeaua lui {a}', na.network_address, 'a.b.c.d'), f('b', f'rețeaua lui {b}', nb.network_address, 'a.b.c.d'),
         f('same', 'sunt în aceeași rețea? (da / nu)', 'da' if yes else 'nu', 'da sau nu')],
        'Două stații comunică direct doar dacă au aceeași adresă de rețea.',
        f'`{a}` e în `{na}`, `{b}` e în `{nb}`: ' + ('aceeași rețea, comunică direct.' if yes else 'rețele diferite, e nevoie de un ruter.'), ip=a, prefix=prefix)


same(9, 'Aceeași rețea?', 'ușoară', '192.168.1.126', '192.168.1.129', 25)
same(10, 'Aceeași rețea? (2)', 'medie', '10.1.34.200', '10.1.47.3', 20)
same(11, 'Aceeași rețea? (3)', 'medie', '172.16.5.62', '172.16.5.65', 26)


def mask_for(id, title, diff, hosts_needed):
    bits = next(b for b in range(2, 31) if 2 ** b - 2 >= hosts_needed)
    prefix = 32 - bits
    net(id, title, C1, diff,
        f'O rețea trebuie să aibă loc pentru {hosts_needed} stații. Alege cea mai mică rețea care le cuprinde.',
        [f('p', 'prefixul', f'/{prefix}|{prefix}', '/n'), f('mask', 'masca, în zecimal', ipaddress.ip_network(f'0.0.0.0/{prefix}').netmask, 'a.b.c.d'),
         f('n', 'câte adrese de stație are', 2 ** bits - 2, 'un număr', number=True)],
        'Caută cea mai mică putere a lui 2 din care, scăzând 2 (rețea și difuzare), rămân destule adrese.',
        f'`2^{bits} - 2 = {2 ** bits - 2} ≥ {hosts_needed}`, iar `2^{bits - 1} - 2 = {2 ** (bits - 1) - 2}` nu ajunge: `{bits}` biți de stație, prefix `/{prefix}`.', ip='192.168.0.0', prefix=prefix)


mask_for(12, 'Masca pentru 50 de stații', 'ușoară', 50)
mask_for(13, 'Masca pentru 500 de stații', 'medie', 500)
mask_for(14, 'Masca pentru 30 de stații', 'ușoară', 30)
mask_for(15, 'Masca pentru 31 de stații', 'medie', 31)


def vlsm(id, title, diff, base, needs, source=''):
    block = ipaddress.ip_network(base)
    cur = int(block.network_address)
    fields, lines = [], []
    for name, n in sorted(needs, key=lambda x: -x[1]):
        bits = next(b for b in range(2, 31) if 2 ** b - 2 >= n)
        size = 2 ** bits
        cur = (cur + size - 1) // size * size
        sub = ipaddress.ip_network((cur, 32 - bits))
        assert sub.subnet_of(block), id
        fields.append(f(name, f'{name} ({n} stații)', sub, 'a.b.c.d/n'))
        lines.append(f'{name}: `{sub}` ({2 ** bits - 2} adrese de stație)')
        cur += size
    listed = ', '.join(f'{name} cu {n} stații' for name, n in needs)
    net(id, title, C2, diff,
        f'Împarte blocul `{base}` între rețelele: {listed}. Alocă în ordinea descrescătoare a mărimii, fiecare rețea cât mai mică, una după alta, fără goluri inutile.',
        fields, 'Sortează rețelele descrescător. Pentru fiecare: câți biți de stație îi trebuie, apoi următoarea adresă liberă care e multiplu al mărimii blocului.',
        'Alocarea:\n' + '\n'.join(f'- {l}' for l in lines), ip=str(block.network_address), prefix=block.prefixlen, source=source)


vlsm(16, 'Trei rețele dintr-un /24', 'medie', '192.168.1.0/24', [('LAN A', 100), ('LAN B', 50), ('LAN C', 20)])
vlsm(17, 'Rețele și legături', 'medie', '10.0.0.0/24', [('LAN A', 60), ('LAN B', 25), ('LAN C', 10), ('R1-R2', 2), ('R2-R3', 2)], 'Pregătire parțial RL')
vlsm(18, 'Un /23 pentru patru departamente', 'grea', '172.16.8.0/23', [('Vânzări', 200), ('Tehnic', 100), ('Contabilitate', 50), ('Conducere', 12)])
vlsm(19, 'Un /26 strâns', 'grea', '192.168.5.64/26', [('LAN A', 20), ('LAN B', 10), ('LAN C', 5), ('R1-R2', 2)])
vlsm(20, 'Șase rețele dintr-un /22', 'grea', '10.20.0.0/22', [('Sală 1', 250), ('Sală 2', 120), ('Sală 3', 120), ('Wi-Fi', 60), ('Servere', 14), ('R1-R2', 2)])


def aggregate(id, title, diff, nets):
    ns = [ipaddress.ip_network(n) for n in nets]
    lo, hi = min(int(n.network_address) for n in ns), max(int(n.broadcast_address) for n in ns)
    p = 32
    while True:
        s = ipaddress.ip_network((lo >> (32 - p) << (32 - p), p)) if p else ipaddress.ip_network('0.0.0.0/0')
        if int(s.network_address) <= lo and int(s.broadcast_address) >= hi:
            break
        p -= 1
    net(id, title, C3, diff,
        'Un ruter anunță rețelele ' + ', '.join(f'`{n}`' for n in nets) + '. Scrie cea mai specifică rută agregată (sumarizată) care le acoperă pe toate.',
        [f('s', 'ruta agregată', s, 'a.b.c.d/n')],
        'Scrie în binar octetul în care rețelele diferă și păstrează biții comuni de la stânga.',
        f'Biții comuni tuturor adreselor dau prefixul `/{s.prefixlen}`: `{s}`.', ip=str(ns[0].network_address), prefix=s.prefixlen)


aggregate(21, 'Agregarea a patru rețele', 'medie', ['192.168.4.0/24', '192.168.5.0/24', '192.168.6.0/24', '192.168.7.0/24'])
aggregate(22, 'Agregarea a două rețele', 'ușoară', ['10.1.2.0/24', '10.1.3.0/24'])
aggregate(23, 'Agregare cu o rețea în plus', 'grea', ['172.16.16.0/22', '172.16.20.0/23', '172.16.22.0/24'])


def routing(id, title, diff, table, dests, source=''):
    rows = [(ipaddress.ip_network(n), via) for n, via in table]
    fields, why = [], []
    for i, d in enumerate(dests):
        ad = ipaddress.ip_address(d)
        best = max((r for r in rows if ad in r[0]), key=lambda r: r[0].prefixlen)
        fields.append(f(f'd{i}', f'pachet către {d}', best[1], 'interfața'))
        why.append(f'`{d}` se potrivește cel mai lung cu `{best[0]}` → `{best[1]}`')
    tab = '```\n' + '\n'.join(f'{str(n):<20} {via}' for n, via in table) + '\n```'
    net(id, title, C3, diff,
        f'Un ruter are tabela de rutare:\n\n{tab}\n\nPe ce interfață trimite fiecare pachet?',
        fields, 'Dintre rutele care conțin destinația câștigă cea cu prefixul cel mai lung; ruta implicită `0.0.0.0/0` se potrivește cu orice.',
        '\n'.join(f'- {w}' for w in why), ip=dests[0], prefix=rows[0][0].prefixlen, source=source)


routing(24, 'Cea mai lungă potrivire', 'medie',
        [('10.0.0.0/8', 'eth0'), ('10.1.0.0/16', 'eth1'), ('10.1.2.0/24', 'eth2'), ('0.0.0.0/0', 'ppp0')],
        ['10.1.2.9', '10.1.3.9', '10.200.0.1', '8.8.8.8'])
routing(25, 'Rute care se suprapun', 'grea',
        [('192.168.0.0/16', 'eth0'), ('192.168.64.0/18', 'eth1'), ('192.168.96.0/20', 'eth2'), ('192.168.100.0/24', 'eth3'), ('0.0.0.0/0', 'eth4')],
        ['192.168.100.200', '192.168.101.1', '192.168.127.1', '192.168.130.1', '192.169.0.1'])
routing(26, 'Ruta implicită', 'ușoară',
        [('172.16.0.0/24', 'eth0'), ('172.16.1.0/24', 'eth1'), ('0.0.0.0/0', 'eth2')],
        ['172.16.1.254', '172.16.2.1', '172.16.0.0'])

# ---------------------------------------------------------------- teorie
def q(id, title, ch, diff, st, right, wrong, hint, sol, source=''):
    P.append(quiz(id, title, ch, diff, st, right, wrong, hint, sol, source))


q(27, 'Ce face ARP', C4, 'ușoară', 'O stație știe adresa IP a destinației din rețeaua ei, dar nu și adresa MAC. Ce protocol folosește ca s-o afle?',
  'ARP', ['DNS', 'DHCP', 'ICMP'], 'Leagă nivelul rețea de nivelul legătură de date.', 'Cererea ARP e trimisă prin difuzare (`FF:FF:FF:FF:FF:FF`); răspunde doar stația cu acel IP.')
q(28, 'Adresa MAC destinație, printr-un ruter', C4, 'medie',
  'Stația A trimite un pachet stației B, aflată în altă rețea, prin ruterul implicit R. Ce adresă MAC destinație are cadrul care pleacă de la A?',
  'adresa MAC a interfeței lui R din rețeaua lui A', ['adresa MAC a lui B', 'adresa de difuzare FF:FF:FF:FF:FF:FF', 'adresa MAC a interfeței lui R din rețeaua lui B'],
  'Adresele MAC au sens doar într-o rețea locală; adresele IP rămân aceleași cap la cap.',
  'A trimite cadrul ruterului implicit; antetul IP are în continuare destinația B. La fiecare salt se schimbă adresele MAC, nu și cele IP.', 'Examen RL 2022-2023 · antetele cadrelor')
q(29, 'Tabela CAM', C4, 'ușoară', 'Un switch primește un cadru către o adresă MAC pe care nu o are în tabela CAM. Ce face?',
  'îl trimite pe toate porturile din același VLAN, mai puțin cel de intrare', ['îl aruncă', 'îl trimite înapoi pe portul de intrare', 'îl trimite doar pe porturile trunchi'],
  'Switch-ul învață adresele sursă și caută adresele destinație.', 'Inundare (flooding). Adresa sursă a cadrului e învățată pe portul de intrare.')
q(30, 'Root bridge', C4, 'medie', 'Cum este ales switch-ul rădăcină (root bridge) în STP?',
  'cel cu cel mai mic Bridge ID (prioritate, apoi adresa MAC)', ['cel cu cele mai multe porturi', 'cel cu cea mai mare adresă MAC', 'cel pornit primul'],
  'Bridge ID = prioritate + adresă MAC.', 'Pentru a face un switch rădăcină, i se micșorează prioritatea. Toate porturile rădăcinii sunt „designated”.', 'Examen RL 2022-2023 · „Cum poate un switch să devină Root Switch?”')
q(31, 'Costuri STP', C4, 'medie', 'În STP clasic, ce cost are o legătură FastEthernet (100 Mb/s) și ce cost are una GigabitEthernet?',
  '19 și 4', ['100 și 10', '10 și 1', '4 și 19'], 'Costul scade când viteza crește.', '10 Mb/s: 100; 100 Mb/s: 19; 1 Gb/s: 4; 10 Gb/s: 2. Portul rădăcină e cel cu costul total cel mai mic până la rădăcină.', 'Examen RL 2022-2023')
q(32, 'Trunchi și VLAN nativ', C4, 'medie', 'Pe o legătură trunchi 802.1Q, cum circulă cadrele din VLAN-ul nativ?',
  'fără etichetă (untagged)', ['cu eticheta 0', 'cu două etichete', 'nu pot circula pe trunchi'],
  'Eticheta 802.1Q are 4 octeți și conține identificatorul VLAN-ului.', 'Toate celelalte VLAN-uri sunt etichetate; cel nativ trece neetichetat, de aceea trebuie să fie același la ambele capete.', 'Examen RL 2022-2023')
q(33, 'Codificarea Manchester', C4, 'medie', 'Ce proprietate are codificarea Manchester?',
  'fiecare bit are o tranziție la mijlocul intervalului, deci semnalul își duce singur ceasul', ['folosește trei niveluri de tensiune', 'nu are nicio tranziție pentru șiruri lungi de 0', 'dublează viteza de transfer față de NRZ'],
  'Receptorul se sincronizează pe tranziții.', 'Prețul: lățimea de bandă necesară e dublă față de NRZ.', 'Examen RL 2022-2023')
q(34, 'NAT cu supraîncărcare', C5, 'ușoară', 'Cum deosebește un ruter care face PAT (NAT cu supraîncărcare) conexiunile mai multor stații care ies cu aceeași adresă publică?',
  'după numărul de port sursă, pe care îl ține într-o tabelă de translatare', ['după adresa MAC a stației', 'după TTL', 'nu le poate deosebi'],
  'PAT = Port Address Translation.', 'Fiecare conexiune primește un port sursă unic pe adresa publică; răspunsurile sunt translatate înapoi după tabelă.')
q(35, 'Acces din afară, printr-un NAT', C5, 'medie', 'Un server aflat în spatele unui NAT trebuie să fie accesibil din Internet pe portul 443. Ce se configurează pe ruter?',
  'redirecționarea portului 443 către server (port forwarding, NAT static)', ['o rută implicită către server', 'un VLAN separat', 'dezactivarea ARP'],
  'Conexiunile inițiate din afară nu au o intrare în tabela de translatare.', 'DNAT / port forwarding: o regulă statică trimite ce sosește pe adresa publică, portul 443, la adresa privată a serverului.')
q(36, 'OSPF', C3, 'medie', 'Pe ce se bazează costul unei legături în OSPF?',
  'pe lățimea de bandă a legăturii', ['pe numărul de salturi', 'pe întârzierea măsurată cu ping', 'pe adresa IP a vecinului'],
  'Cost = lățimea de bandă de referință / lățimea de bandă a interfeței.', 'OSPF e un protocol de tip stare a legăturilor: fiecare ruter rulează Dijkstra pe aceeași hartă. RIP numără salturi.', 'Examen RL 2022-2023')
q(37, 'ARP poisoning', C5, 'medie', 'Un atacator conectat la un switch trimite răspunsuri ARP false, ca să se așeze între două stații. Ce mecanism al switch-ului oprește atacul?',
  'Dynamic ARP Inspection, pe baza tabelei DHCP snooping', ['STP', 'un VLAN nativ diferit', 'dezactivarea portului trunchi'],
  'Switch-ul trebuie să știe ce pereche IP-MAC e legitimă pe fiecare port.', 'DHCP snooping ține perechile IP-MAC-port; DAI aruncă răspunsurile ARP care nu se potrivesc. Port security limitează adresele MAC pe port.', 'Examen RL 2022-2023 · atac Person-In-The-Middle')
q(38, 'TCP și UDP', C5, 'ușoară', 'Care serviciu este oferit de TCP, dar nu și de UDP?',
  'livrarea sigură și în ordine a datelor', ['adresarea prin porturi', 'suma de control', 'transportul peste IP'],
  'UDP e fără conexiune.', 'TCP numerotează octeții, confirmă și retransmite; UDP doar multiplexează prin porturi.')

# ---------------------------------------------------------------- more, from the exams
def classful(id, title, diff, cls, mask_prefix):
    base = {'A': 8, 'B': 16, 'C': 24}[cls]
    sub_bits = max(0, mask_prefix - base)
    hosts = 2 ** (32 - mask_prefix) - 2
    ip = {'A': '10.0.0.0', 'B': '172.16.0.0', 'C': '192.168.1.0'}[cls]
    mask = ipaddress.ip_network(f'0.0.0.0/{mask_prefix}').netmask
    net(id, title, C1, diff,
        f'O rețea de clasă {cls} (prefixul implicit `/{base}`) este împărțită cu masca `{mask}`. Câte subrețele se obțin și câte stații are fiecare?',
        [f('p', 'prefixul măștii', f'/{mask_prefix}|{mask_prefix}', '/n'), f('s', 'câți biți sunt împrumutați pentru subrețele', sub_bits, 'un număr', number=True),
         f('n', 'câte subrețele', 2 ** sub_bits, 'un număr', number=True), f('h', 'câte stații în fiecare subrețea', hosts, 'un număr', number=True)],
        f'Clasa {cls} fixează primii {base} biți. Biții măștii de după ei numără subrețelele; biții rămași de 0 numără stațiile.',
        f'Masca are `{mask_prefix}` biți de 1: `{mask_prefix} - {base} = {sub_bits}` biți de subrețea, deci `2^{sub_bits} = {2 ** sub_bits}` subrețele; `32 - {mask_prefix} = {32 - mask_prefix}` biți de stație: `2^{32 - mask_prefix} - 2 = {hosts}` stații.',
        ip=ip, prefix=mask_prefix, source=EXR)


classful(40, 'Clasa A cu masca 255.255.240.0', 'medie', 'A', 20)
classful(41, 'Clasa B cu aceeași mască', 'medie', 'B', 20)
classful(42, 'Clasa C cu masca 255.255.255.224', 'ușoară', 'C', 27)
net(43, 'Măștile /23, /24, /25', C1, 'ușoară', 'Câte adrese de stație are o rețea cu prefixul `/23`? Dar `/24` și `/25`?',
    [f('a', '/23', 510, 'un număr', number=True), f('b', '/24', 254, 'un număr', number=True), f('c', '/25', 126, 'un număr', number=True)],
    'Fiecare bit în plus în prefix înjumătățește rețeaua.', '`2^9 - 2 = 510`, `2^8 - 2 = 254`, `2^7 - 2 = 126`.', ip='192.168.0.0', prefix=23, source=EXR)
addressing(44, 'O rețea /29', 'ușoară', '141.85.37.77', 29, 'Blocuri de câte 8 adrese: 72 ≤ 77 < 80.')
addressing(45, 'O rețea /21', 'medie', '188.17.42.9', 21, 'Al treilea octet în blocuri de câte 8: 40 ≤ 42 < 48.')
addressing(46, 'O rețea /18', 'grea', '10.130.200.17', 18, 'Al treilea octet în blocuri de 64: 192 ≤ 200.')
addressing(47, 'O rețea /27 din spațiul de examen', 'medie', '188.17.32.90', 27, 'Blocuri de 32: 64 ≤ 90 < 96.')
same(48, 'Aceeași rețea? (4)', 'grea', '10.1.31.255', '10.1.32.1', 19)
vlsm(49, 'Două VLAN-uri dintr-un /19', 'medie', '10.1.0.0/19', [('VLAN10', 300), ('VLAN20', 200)], 'Model parțial RL')
vlsm(50, 'Un /24 public pentru un campus', 'grea', '141.85.37.0/24', [('Laborator', 100), ('Cămin', 60), ('Secretariat', 25), ('Servere', 6), ('R1-R2', 2), ('R1-R3', 2)], 'Examen RL · adresarea de nivel 3')
vlsm(51, 'Un /27 pentru două VLAN-uri', 'grea', '188.17.32.64/27', [('VLAN7', 12), ('VLAN8', 5), ('R1-R2', 2)], 'Examen RL · adresarea de nivel 3')
aggregate(52, 'Agregarea a opt rețele', 'medie', ['10.4.8.0/24', '10.4.9.0/24', '10.4.10.0/24', '10.4.11.0/24', '10.4.12.0/24', '10.4.13.0/24', '10.4.14.0/24', '10.4.15.0/24'])
routing(53, 'Tabela de rutare a unui ruter de margine', 'medie',
        [('10.0.24.0/24', 'gre0'), ('10.1.0.0/23', 'eth0'), ('10.1.2.0/24', 'eth1'), ('10.0.0.0/8', 'eth2'), ('0.0.0.0/0', 'ppp0')],
        ['10.1.1.40', '10.1.2.40', '10.0.24.2', '10.9.9.9', '141.85.0.1'], 'Examen RL 2022-2023 · tunel GRE')


def calc(id, title, ch, diff, statement, fields, hint, solution, source=''):
    P.append(problem(id, title, ch, diff, statement, 'calc', {'fields': fields}, hint, solution, source))


def manchester(bits):  # IEEE 802.3: 0 = high→low, 1 = low→high
    return ' '.join('LH' if b == '1' else 'HL' for b in bits)


def diff_manchester(bits, start='H'):
    # a transition at the start of the bit for 0, none for 1; always one in the middle
    out, level = [], start  # level: the level at the end of the previous bit
    for b in bits:
        first = level if b == '1' else ('L' if level == 'H' else 'H')
        second = 'L' if first == 'H' else 'H'
        out.append(first + second)
        level = second
    return ' '.join(out)


def nrzi(bits, start='L'):
    out, level = [], start
    for b in bits:
        if b == '1':
            level = 'H' if level == 'L' else 'L'
        out.append(level)
    return ''.join(out)


def ami(bits):
    out, last = [], '-'
    for b in bits:
        if b == '0':
            out.append('0')
        else:
            last = '+' if last == '-' else '-'
            out.append(last)
    return ''.join(out)


_b = '00001111'
calc(54, 'Manchester pentru 00001111', C6, 'ușoară',
     f'Codifică șirul `{_b}` în **Manchester** (convenția IEEE 802.3: `0` = tranziție de la nivel înalt la jos, `HL`; `1` = de la jos la înalt, `LH`). Scrie nivelurile, câte două pe bit, cu `H` și `L` (spațiile nu contează).',
     [f('m', 'semnalul Manchester', manchester(_b), 'HL LH ...')],
     'Fiecare bit are o tranziție la mijloc: sensul ei e bitul.', f'`{manchester(_b)}`. Atenție: unele cărți folosesc convenția inversă (G. E. Thomas); la examen se precizează.', EXR)
_b = '01010101'
calc(55, 'Manchester diferențial', C6, 'medie',
     f'Codifică `{_b}` în **Manchester diferențial**: la mijlocul fiecărui bit e mereu o tranziție; la începutul bitului, `0` are o tranziție, `1` nu. Linia era la nivelul `H` înainte de primul bit. Scrie nivelurile, câte două pe bit.',
     [f('m', 'semnalul', diff_manchester(_b), 'HL LH ...')],
     'Pornește de la nivelul de dinainte: un `0` îl schimbă la început, un `1` îl păstrează; apoi schimbă-l la mijloc.',
     f'`{diff_manchester(_b)}`. Informația e în prezența tranziției de la început, nu în nivel: inversarea firelor nu strică nimic.', EXR)
_b = '10110010'
calc(56, 'NRZ-I', C6, 'ușoară',
     f'Codifică `{_b}` în **NRZ-I**: un `1` schimbă nivelul la începutul bitului, un `0` îl lasă. Linia era la `L` înainte. Scrie câte un nivel pe bit (`H`/`L`).',
     [f('m', 'semnalul NRZ-I', nrzi(_b), 'opt litere H/L')],
     'Urmărește doar biții de 1: fiecare comută.', f'`{nrzi(_b)}`. Un șir lung de 0 rămâne fără tranziții: receptorul pierde sincronizarea.', EXR)
_b = '00001111'
calc(57, 'AMI (Alternate Mark Inversion)', C6, 'ușoară',
     f'Codifică `{_b}` în **AMI** (bipolar): `0` = nivel zero, fiecare `1` alternează între `+` și `-`, primul `1` fiind `+`. Scrie câte un simbol pe bit (`0`, `+`, `-`).',
     [f('m', 'semnalul AMI', ami(_b), 'ex.: 00+-')],
     'Doar biții de 1 contează pentru alternanță.', f'`{ami(_b)}`. Media semnalului e zero (fără componentă continuă), iar doi `+` la rând ar arăta o eroare.', EXR)


def crc(data, poly):
    bits = list(map(int, data + '0' * (len(poly) - 1)))
    p = list(map(int, poly))
    for i in range(len(data)):
        if bits[i]:
            for j in range(len(p)):
                bits[i + j] ^= p[j]
    return ''.join(map(str, bits[-(len(poly) - 1):]))


for id, data, poly, diff in ((58, '1101011011', '10011', 'medie'), (59, '11010110', '1011', 'ușoară')):
    r = crc(data, poly)
    deg = len(poly) - 1
    gx = ' + '.join(('x' if k == 1 else ('1' if k == 0 else f'x^{k}')) for k in range(deg, -1, -1) if poly[deg - k] == '1')
    calc(id, f'CRC cu generatorul {poly}', C6, diff,
         f'Mesajul `{data}` se trimite cu CRC, polinomul generator fiind `G(x) = {gx}` (biții `{poly}`). Care este restul (CRC-ul) și ce cadru se transmite?',
         [f('r', f'restul ({deg} biți)', r, f'{deg} biți'), f('t', 'cadrul transmis (mesaj + rest)', data + r, 'biți')],
         f'Adaugă `{deg}` zerouri la mesaj și împarte (XOR, fără transport) la `{poly}`; restul are `{deg}` biți.',
         f'`{data}{"0" * deg}` împărțit la `{poly}` dă restul `{r}`. Se trimite `{data}{r}`; receptorul împarte tot cadrul la `{poly}` și trebuie să obțină restul 0.', EXR)


def hamming74(d):  # d1 d2 d3 d4 -> p1 p2 d1 p3 d2 d3 d4
    d1, d2, d3, d4 = map(int, d)
    p1, p2, p3 = d1 ^ d2 ^ d4, d1 ^ d3 ^ d4, d2 ^ d3 ^ d4
    return ''.join(map(str, (p1, p2, d1, p3, d2, d3, d4)))


_w = hamming74('1011')
calc(60, 'Hamming (7, 4): codificare', C6, 'medie',
     'Codifică datele `1011` cu codul Hamming (7, 4). Pozițiile sunt numerotate de la 1; biții de paritate (pară) stau pe pozițiile 1, 2, 4, iar datele pe 3, 5, 6, 7.',
     [f('c', 'cuvântul de cod (7 biți, poziția 1 prima)', _w, '7 biți')],
     'Paritatea de pe poziția `2^k` acoperă pozițiile care au bitul `k` setat: p1 → 1, 3, 5, 7; p2 → 2, 3, 6, 7; p4 → 4, 5, 6, 7.',
     f'd3 = 1, d5 = 0, d6 = 1, d7 = 1. p1 = d3⊕d5⊕d7 = {_w[0]}, p2 = d3⊕d6⊕d7 = {_w[1]}, p4 = d5⊕d6⊕d7 = {_w[3]}: `{_w}`.')
_recv = list(_w); _recv[5] = '1' if _recv[5] == '0' else '0'; _recv = ''.join(_recv)


def syndrome(c):
    b = [0] + list(map(int, c))
    s1 = b[1] ^ b[3] ^ b[5] ^ b[7]
    s2 = b[2] ^ b[3] ^ b[6] ^ b[7]
    s4 = b[4] ^ b[5] ^ b[6] ^ b[7]
    return s1 + 2 * s2 + 4 * s4


calc(61, 'Hamming (7, 4): un bit greșit', C6, 'grea',
     f'Se primește cuvântul Hamming (7, 4) `{_recv}` (poziția 1 prima, paritate pară pe pozițiile 1, 2, 4). Un singur bit s-a schimbat pe drum. Pe ce poziție, și ce date s-au trimis?',
     [f('p', 'poziția bitului greșit', syndrome(_recv), 'un număr', number=True), f('d', 'datele corecte (pozițiile 3, 5, 6, 7)', '1011', '4 biți')],
     'Recalculează cele trei parități: sindromul, citit în binar (p4 p2 p1), e chiar poziția greșită.',
     f'Sindromul dă `{syndrome(_recv)}`: bitul de pe poziția {syndrome(_recv)} se inversează și obții `{_w}`, cu datele `1011`.')
calc(62, 'STP: rădăcina și porturile', C4, 'grea',
     'Patru switch-uri sunt legate în inel: Sw1–Sw2, Sw2–Sw3, Sw3–Sw4 și Sw4–Sw1. Legătura Sw1–Sw4 e de 10 Mb/s (cost STP 100), restul sunt FastEthernet (cost 19). Prioritățile sunt egale și `MAC(Sw1) < MAC(Sw2) < MAC(Sw3) < MAC(Sw4)`.',
     [f('root', 'switch-ul rădăcină', 'Sw1|1', 'SwX'), f('c4', 'costul drumului de la Sw4 la rădăcină', 57, 'un număr', number=True),
      f('rp4', 'portul rădăcină al lui Sw4 duce spre', 'Sw3|3', 'SwX'), f('c3', 'costul de la Sw3 la rădăcină', 38, 'un număr', number=True),
      f('bl', 'portul blocat este pe switch-ul', 'Sw4|4', 'SwX'), f('blto', '…pe legătura spre', 'Sw1|1', 'SwX')],
     'Rădăcina are cel mai mic Bridge ID. Fiecare alt switch își alege portul cu costul total minim spre ea; pe fiecare segment, un port desemnat; ce rămâne se blochează.',
     'Rădăcina e Sw1. Sw2: 19 direct. Sw3: prin Sw2, 38 (prin Sw4 ar fi 119). Sw4: direct 100 sau prin Sw3 `19 · 3 = 57`: portul rădăcină e spre Sw3. Pe legătura Sw1–Sw4, portul lui Sw1 e desemnat (rădăcina are toate porturile desemnate), iar cel al lui Sw4 se blochează.',
     'Examen RL · adresarea de nivel 2, STP')
calc(63, 'Cât durează un cadru', C6, 'ușoară',
     'Un cadru Ethernet de 1500 de octeți se trimite pe o legătură de 100 Mb/s, pe un cablu de 200 m (semnalul se propagă cu `2·10⁸` m/s).',
     [f('tt', 'timpul de transmisie (μs)', 120, 'μs', number=True, tol=0.01), f('tp', 'timpul de propagare (μs)', 1, 'μs', number=True, tol=0.01)],
     'Transmisie: biți / debit. Propagare: distanță / viteză.', '`1500 · 8 / 10⁸ s = 120 μs`; `200 / 2·10⁸ s = 1 μs`. Pe o rețea locală, transmisia domină.')
calc(64, 'Lungimea minimă a cadrului (CSMA/CD)', C6, 'medie',
     'Într-o rețea cu CSMA/CD de 10 Mb/s, timpul dus-întors maxim al semnalului (round trip) este de 51,2 μs. Ca o coliziune să fie detectată înainte de sfârșitul trimiterii, cât de lung trebuie să fie cel mai scurt cadru?',
     [f('b', 'în biți', 512, 'un număr', number=True), f('o', 'în octeți', 64, 'un număr', number=True)],
     'Emițătorul trebuie să mai transmită când se întoarce vestea coliziunii: durata cadrului ≥ round trip.',
     '`10⁷ b/s · 51,2·10⁻⁶ s = 512` biți = 64 de octeți: lungimea minimă a cadrului Ethernet.', EXR)


q(70, 'CSMA/CD și CSMA/CA', C4, 'ușoară', 'Unde se folosește CSMA/CA în loc de CSMA/CD și de ce?',
  'în rețelele fără fir, unde emițătorul nu poate detecta coliziunile în timp ce transmite', ['în rețelele cu fibră optică, pentru viteză', 'în Ethernet-ul full-duplex', 'în rețelele token ring'],
  'CD = detectare, CA = evitare.', 'Un radio nu poate asculta cât emite (semnalul propriu acoperă tot), iar o stație ascunsă nu se aude deloc; de aceea se evită coliziunile (așteptare aleatoare, RTS/CTS, confirmări). Ethernet-ul full-duplex nu mai are coliziuni deloc.', EXR)
q(71, 'NAT: avantaje', C5, 'ușoară', 'Care este principalul avantaj al NAT?',
  'mai multe stații cu adrese private pot ieși în Internet printr-o singură adresă publică', ['crește viteza legăturii', 'criptează traficul', 'elimină nevoia de rutare'],
  'Adresele IPv4 publice sunt puține.', 'Bonus: stațiile din spate nu sunt accesibile direct din afară. Dezavantaj: aplicațiile care pun adresa IP în date (FTP activ, SIP) au nevoie de ajutor.', EXR)
q(72, 'Sateliții geostaționari', C6, 'medie', 'La ce altitudine sunt sateliții geostaționari?',
  'aproximativ 35 786 km, deasupra ecuatorului', ['aproximativ 1 000 km', 'aproximativ 20 200 km, ca sateliții GPS', 'la orice altitudine, pe orbite polare'],
  'Perioada orbitei e egală cu o zi.', 'Se rotesc odată cu Pământul, deci par ficși pe cer: antena nu trebuie urmărită. Întârzierea dus-întors e de peste 0,5 s.', EXR)
q(73, 'Cablul torsadat', C6, 'ușoară', 'De ce sunt răsucite firele dintr-un cablu UTP?',
  'pentru a reduce interferențele (diafonia) dintre perechi și din exterior', ['pentru a crește rezistența mecanică', 'pentru a putea transmite curent mai mare', 'pentru a reduce costul'],
  'Fiecare fir al perechii prinde același zgomot.', 'Transmisia diferențială scade cele două semnale: zgomotul comun dispare. Cu cât pasul răsucirii e mai mic, cu atât categoria e mai bună.', EXR)
q(74, 'VLAN', C4, 'ușoară', 'Ce realizează un VLAN?',
  'împarte un switch (sau mai multe) în domenii de difuzare separate', ['crește viteza porturilor', 'criptează traficul dintre porturi', 'unește mai multe rețele IP într-una'],
  'Difuzările nu trec dintr-un VLAN în altul.', 'Între VLAN-uri e nevoie de rutare (router-on-a-stick sau un switch de nivel 3).', 'Examen RL 2022-2023')
q(75, 'Proxy ARP', C4, 'medie', 'Ce face un ruter care rulează Proxy ARP?',
  'răspunde la cereri ARP pentru adrese din altă rețea cu propria lui adresă MAC', ['ține tabela ARP a tuturor stațiilor din Internet', 'transformă cererile ARP în cereri DNS', 'blochează cererile ARP'],
  'Stația crede că destinația e în rețeaua ei.', 'Cadrele ajung la ruter, care le rutează mai departe; așa pot comunica stații fără ruter implicit configurat (sau cu o mască greșită).', 'Examen RL 2022-2023')
q(76, 'Tunel GRE', C3, 'medie', 'Ce face un tunel GRE între două rutere?',
  'încapsulează pachetele IP în alte pachete IP, ca rețelele de la capete să pară direct legate', ['criptează traficul dintre rutere', 'înlocuiește NAT-ul', 'leagă două VLAN-uri pe același switch'],
  'Un pachet în pachet.', 'Antetul exterior are adresele publice ale ruterelor; cel interior, adresele private. GRE nu criptează: pentru asta se pune peste el IPsec.', 'Examen RL 2022-2023')
q(77, 'BGP: alegerea drumului', C3, 'grea', 'Un AS vrea ca traficul care **intră** spre rețelele lui să vină pe o anumită legătură, nu pe cealaltă. Ce atribut BGP folosește, de obicei?',
  'AS_PATH prepend (lungește drumul anunțat pe legătura nedorită)', ['LOCAL_PREF pe ruterele proprii', 'costul OSPF', 'TTL-ul pachetelor'],
  'LOCAL_PREF influențează traficul care iese, nu cel care intră.', 'Celelalte AS-uri preferă drumul cu AS_PATH mai scurt; repetând propriul număr de AS pe legătura nedorită, o faci mai puțin atractivă. Se folosește și MED, între doi vecini.', 'Examen RL 2022-2023')
q(78, 'Distance vector și link state', C3, 'medie', 'Ce deosebește un protocol de rutare de tip „link state” (OSPF) de unul „distance vector” (RIP)?',
  'fiecare ruter cunoaște toată topologia și calculează singur drumurile (Dijkstra)', ['folosește numărul de salturi ca metrică', 'trimite periodic întreaga tabelă de rutare vecinilor', 'nu are nevoie de vecini'],
  'RIP îi crede pe vecini pe cuvânt.', 'La distance vector fiecare ruter știe doar distanțele anunțate de vecini (Bellman-Ford), de unde convergența lentă și „count to infinity”.')
q(79, 'Atacul VLAN hopping', C5, 'medie', 'Cum se apără o rețea de VLAN hopping prin dublă etichetare?',
  'VLAN-ul nativ al trunchiurilor nu e folosit de nicio stație, iar porturile de acces nu negociază trunchiuri', ['se activează STP', 'se dezactivează ARP', 'se folosesc adrese IP publice'],
  'Atacul pune două etichete: prima, a VLAN-ului nativ, e scoasă de primul switch.', 'Dacă VLAN-ul nativ nu are stații (sau e etichetat și el) și DTP e oprit pe porturile de acces, cadrul cu două etichete nu mai trece.')
q(80, 'Port security', C5, 'ușoară', 'Ce face „port security” pe un switch?',
  'limitează adresele MAC care pot folosi un port și reacționează la cele străine', ['criptează traficul de pe port', 'blochează porturile neutilizate prin STP', 'autentifică utilizatorii cu parolă'],
  'Sticky MAC învață prima adresă și o păstrează.', 'Previne atacurile de umplere a tabelei CAM și conectarea unui calculator străin în priză.', EXR)

write_course('rl', CHAPTERS, P)
