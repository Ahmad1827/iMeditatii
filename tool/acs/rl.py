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
CHAPTERS = [C1, C2, C3, C4, C5]
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

write_course('rl', CHAPTERS, P)
