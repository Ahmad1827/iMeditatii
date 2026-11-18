"""APM — Arhitectura Procesoarelor Moderne: Lucrarea 2, the RISC-V front-end (IF + ID).

Instructions encoded and decoded on their bits (the 'riscv' workspace has a bit bench),
the lab's imm_gen, the register file, the waveform of the lab's testbench, Verilog
questions and the lab's modules written by hand (graded by a barem). Every number
comes from apm_model.py, the lab's design modelled in Python and checked on Fig. 4.
The guide that goes with it: web/materiale/apm-lucrarea-2.pdf (ghid_apm_l2/).
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from common import problem, quiz, quiz_multi, true_false, write_course
import apm_model as m

C1 = '1. Pipeline-ul RISC-V și front-end-ul'
C2 = '2. Etapa IF: PC, sumator, memorie'
C3 = '3. Codificarea instrucțiunilor'
C4 = '4. Decodificarea instrucțiunilor'
C5 = '5. Generatorul de imediate'
C6 = '6. Bancul de registre și etapa ID'
C7 = '7. Simularea: forma de undă'
C8 = '8. Verilog: modulele lucrării, scrise de mână'
C9 = '9. Verilog: semantică și capcane'
CHAPTERS = [C1, C2, C3, C4, C5, C6, C7, C8, C9]
L2 = 'APM · Lucrarea 2 (RISC-V: IF + ID)'
P = []


def hexes(v):
    v &= 0xFFFFFFFF
    return '|'.join(dict.fromkeys([f'0x{v:08x}', f'{v:08x}', f'0x{v:x}', f'{v:x}']))


def f(id, label, answer, hint='', number=False, tol=0):
    d = {'id': id, 'label': label, 'answer': str(answer), 'hint': hint}
    if number:
        d['number'] = True
        d['tol'] = tol
    return d


def calc(id, title, ch, diff, statement, fields, hint, solution):
    P.append(problem(id, title, ch, diff, statement, 'calc', {'fields': fields}, hint, solution, L2))


def bench(id, title, ch, diff, statement, fields, hint, solution, word=None):
    spec = {'fields': fields}
    if word is not None:
        spec['word'] = f'{word & 0xFFFFFFFF:08X}'
    P.append(problem(id, title, ch, diff, statement, 'riscv', spec, hint, solution, L2))


def q(id, title, ch, diff, st, right, wrong, hint='', sol=''):
    P.append(quiz(id, title, ch, diff, st, right, wrong, hint, sol, L2))


def tf(id, title, ch, diff, st, truth, sol, hint=''):
    P.append(true_false(id, title, ch, diff, st, truth, hint, sol, L2))


def show_fields(text, hexo=False):
    """The encoding of [text], as a fenced block: the fields with their bits."""
    w = m.encode(text, hex_offsets=hexo)
    name = text.split()[0]
    fmt = m.INSTR[name][0]
    names = {'R': 'funct7 rs2 rs1 funct3 rd opcode', 'SH': 'funct7 shamt rs1 funct3 rd opcode', 'I': 'imm[11:0] rs1 funct3 rd opcode',
             'S': 'imm[11:5] rs2 rs1 funct3 imm[4:0] opcode', 'B': '[12] [10:5] rs2 rs1 funct3 [4:1] [11] opcode',
             'U': 'imm[31:12] rd opcode', 'J': '[20] [10:1] [11] [19:12] rd opcode'}[fmt].split()
    cut = m.binary(w, m.GROUPS[fmt]).split()
    width = [max(len(a), len(b)) for a, b in zip(names, cut)]
    top = ' '.join(a.ljust(n) for a, n in zip(names, width))
    bot = ' '.join(b.ljust(n) for b, n in zip(cut, width))
    nib = ' '.join(f'{w:032b}'[i:i + 4] for i in range(0, 32, 4))
    return f'```\n{top}\n{bot}\n= {nib}\n= 0x{w:08X}\n```'


FMT_NAME = {'R': 'R', 'SH': 'I (deplasare)', 'I': 'I', 'S': 'S', 'B': 'B', 'U': 'U', 'J': 'J'}

# ---------------------------------------------------------------- 1. the pipeline (grile)
q(1, 'Etapele pipeline-ului', C1, 'ușoară', 'Care este ordinea corectă a celor 5 etape ale pipeline-ului RISC-V din lucrare?',
  'IF → ID → EX → MEM → WB', ['ID → IF → EX → WB → MEM', 'IF → EX → ID → MEM → WB', 'IF → ID → MEM → EX → WB'],
  'Întâi aduci instrucțiunea, apoi o înțelegi, apoi o execuți.',
  'IF aduce instrucțiunea, ID o decodifică și citește registrele, EX calculează, MEM accesează memoria de date, WB scrie rezultatul în registre.')
q(2, 'Ce e front-end-ul', C1, 'ușoară', 'Ce înseamnă „front-end-ul” procesorului în Lucrarea 2?',
  'etapele IF și ID: aducerea și decodificarea instrucțiunilor', ['etapele EX, MEM și WB', 'unitatea de detecție a hazardurilor', 'memoria de date și ALU-ul'],
  sol='Front-end-ul aduce și înțelege instrucțiunile (IF + ID); back-end-ul (EX, MEM, WB) le execută și vine în Lucrarea 3.')
q(3, 'RV32I', C1, 'ușoară', 'Ce înseamnă că procesorul respectă extensia RV32I?',
  'date, registre și instrucțiuni de 32 de biți, doar operații cu întregi, fără înmulțire/împărțire și fără virgulă mobilă',
  ['instrucțiuni de 16 biți și date de 32 de biți', '32 de instrucțiuni în total', 'operații pe 32 de biți, inclusiv înmulțire și virgulă mobilă'],
  sol='RV32I e nucleul de bază pe 32 de biți: aritmetică și logică pe întregi, load/store, salturi. Înmulțirea e extensia M, virgula mobilă F/D.')
q(4, 'ISA și implementare', C1, 'ușoară', 'Care afirmație despre ISA este corectă?',
  'ISA-ul e contractul abstract (registre, instrucțiuni, codificări); procesorul din laborator e o implementare a lui',
  ['ISA-ul e schema electrică a procesorului', 'fiecare procesor RISC-V are alt format al instrucțiunilor', 'ISA-ul RISC-V se folosește doar cu licență plătită'],
  sol='Un ISA spune *ce* face procesorul, nu *cum* e construit. RISC-V e deschis: oricine îl poate implementa, dar toate implementările respectă același format și aceeași execuție.')
q(5, 'Cine produce PC_write', C1, 'medie', 'În procesorul complet (Lucrarea 3), cine produce semnalele `PC_write` și `IF_ID_write`?',
  'unitatea de detecție a hazardurilor', ['etapa EX', 'etapa WB', 'unitatea de forwarding'],
  sol='Unitatea de detecție a hazardurilor oprește PC-ul și IF/ID (stall) când o instrucțiune trebuie să aștepte, de exemplu după un `lw` al cărui rezultat e folosit imediat.')
q(6, 'Cine produce PCSrc', C1, 'medie', 'De unde vin, în procesorul complet, `PCSrc` și `PC_Branch`?',
  'din etapa EX: decizia de salt și adresa de salt calculată', ['din etapa WB', 'din unitatea de hazard', 'din memoria de instrucțiuni'],
  sol='EX compară registrele și calculează `PC + imm`; dacă saltul se ia, `PCSrc = 1` și MUX-ul din IF alege `PC_Branch`.')
q(7, 'Semnalele din WB', C1, 'medie', 'Ce semnale ale lui ID vin, în procesorul complet, din etapa WB?',
  '`RegWrite_WB`, `RD_WB` și `ALU_DATA_WB`', ['`RS1_ID` și `RS2_ID`', '`PCSrc` și `PC_Branch`', '`IMM_ID` și `FUNCT3_ID`'],
  sol='WB spune dacă se scrie (`RegWrite_WB`), în ce registru (`RD_WB`) și ce valoare (`ALU_DATA_WB`). În Lucrarea 2 le dă testbench-ul: 0, 0, 0.')
q(8, 'De ce x1 nu crește', C1, 'medie', 'În simularea lucrării, după `addi x1,x1,1` registrul `x1` rămâne 1. De ce?',
  'instrucțiunea nu trece prin EX și WB (nu există încă), iar `RegWrite_WB = 0` în testbench',
  ['`addi` nu scrie niciodată registre', '`x1` e legat la 1 permanent', 'scrierea se face abia la sfârșitul simulării'],
  sol='Lucrarea 2 doar aduce și decodifică. Nimic nu duce rezultatul înapoi în registre: `RegWrite_WB` e 0 tot timpul.')
q(9, 'De ce un registru de pipeline', C1, 'medie', 'De ce e nevoie de registrul IF/ID?',
  'ca ID să lucreze un ciclu întreg pe instrucțiunea adusă în ciclul trecut, în timp ce IF o aduce pe următoarea',
  ['ca să încetinească procesorul', 'ca să memoreze toate instrucțiunile programului', 'ca să calculeze PC + 4'],
  sol='Fără IF/ID, ID ar vedea mereu instrucțiunea pe care IF o aduce chiar acum. Registrul de pipeline separă etapele: fiecare lucrează pe altă instrucțiune, în paralel.')
tf(10, 'beq în simulare', C1, 'ușoară', 'În simularea lucrării, `beq x18,x0,5c` face saltul la `PC + 0x5C`.', False,
   'Fals: `PCSrc` e fixat pe 0 în testbench, deci MUX-ul alege mereu PC + 4. (Și în procesorul complet n-ar sări: `x18 = 18 ≠ 0`.)')
q(11, 'Debitul unui pipeline', C1, 'medie', 'Un pipeline cu 5 etape, fără opriri, după ce s-a umplut. Câte instrucțiuni se termină la fiecare ciclu?',
  'una', ['cinci', 'una la fiecare 5 cicluri', 'depinde de instrucțiune'],
  sol='O instrucțiune durează tot 5 cicluri (latența), dar la fiecare ciclu una iese din WB (debitul e de o instrucțiune pe ciclu).')
quiz_multi_ = quiz_multi(12, 'Principii RISC', C1, 'medie', 'Care sunt principii ale RISC-V care apar în lucrare? (unul sau mai multe)',
                         ['toate instrucțiunile au 32 de biți', 'opcode, rd, rs1, rs2, funct3 stau mereu la aceiași biți', 'doar load/store accesează memoria',
                          'instrucțiunile aritmetice pot lua operanzi direct din memorie', 'fiecare instrucțiune are alt număr de octeți'],
                         [0, 1, 2], solution='Lungime fixă (PC + 4), câmpuri la poziții fixe (decodare prin fire), arhitectură load/store. Operanzi din memorie și lungimi variabile sunt trăsături CISC (x86).', source=L2)
P.append(quiz_multi_)

# ---------------------------------------------------------------- 2. IF
for i, pc in enumerate([0x2C, 0x100, 0x7FC, 0xFFC, 0x1008]):
    idx = (pc >> 2) & 0x3FF
    calc(20 + i, f'Indexul din memorie pentru PC = 0x{pc:X}', C2, 'ușoară' if pc < 0x1000 else 'medie',
         f'Memoria de instrucțiuni primește `PC_IF[11:2]`. Ce index (linie din `codeMemory`) citește la `PC = 0x{pc:X}`?' +
         (' (PC-ul a depășit 4 KB.)' if pc >= 0x1000 else ''),
         [f('idx', 'indexul (zecimal)', idx, 'un număr', number=True)],
         'Biții 11...2 ai PC-ului: împarte la 4 și păstrează doar 10 biți (modulo 1024).',
         f'`0x{pc:X} = {pc}`, `{pc} / 4 = {pc // 4}`' + (f', iar pe 10 biți (modulo 1024) rămâne `{idx}`: bitul 12 al PC-ului se ignoră.' if pc >= 0x1000 else f', deci linia `{idx}`.'))
calc(25, 'Adresa instrucțiunii k', C2, 'ușoară', 'Instrucțiunea a 12-a din `code.mem` (linia 11, numărând de la 0). La ce PC se află?',
     [f('pc', 'PC (hexa)', hexes(44), '0x...')], 'Fiecare linie e un cuvânt de 4 octeți.', 'Linia `k` e la adresa `4k`: `4 · 11 = 44 = 0x2C`.')
calc(26, 'Mărimea memoriei', C2, 'ușoară', '`reg [31:0] codeMemory [0:1023];` Câte instrucțiuni încap și câți octeți are memoria? Câți biți are adresa ei?',
     [f('n', 'instrucțiuni', 1024, number=True), f('b', 'octeți', 4096, number=True), f('a', 'biți de adresă', 10, number=True)],
     '1024 de cuvinte de 32 de biți.', '1024 de cuvinte × 4 octeți = 4096 de octeți (4 KB); `2^10 = 1024`, deci 10 biți de adresă.')
calc(27, 'PC după n fronturi', C2, 'ușoară', 'Testbench-ul lucrării: ceas cu perioada 10 ns (fronturi crescătoare la 5, 15, 25, ... ns), `reset = 1` până la 10 ns, fără opriri și fără salturi. Ce valoare are PC-ul din IF (`PC_IF`) imediat după frontul de la 115 ns?',
     [f('pc', 'PC_IF (hexa)', hexes(0x2C), '0x...')], 'Frontul de la 5 ns pune PC = 0; fiecare front de după adaugă 4.',
     'Fronturile de după reset: 15, 25, ..., 115 ns, adică 11 fronturi. `PC = 11 · 4 = 44 = 0x2C`.')
calc(28, 'Un stall', C2, 'medie', 'Ca la problema anterioară, dar testbench-ul pune `PC_write = 0` și `IF_ID_write = 0` exact la fronturile de la 35 și 45 ns. Ce valoare are `PC_IF` după frontul de la 65 ns?',
     [f('pc', 'PC_IF (hexa)', hexes(0x10), '0x...')], 'La un front cu `PC_write = 0` PC-ul nu se schimbă.',
     'Fronturi care încarcă PC-ul după reset: 15, 25, 55, 65 (cele de la 35 și 45 sunt oprite): 4 fronturi, `PC = 16 = 0x10`.')
calc(29, 'Un salt forțat', C2, 'medie', 'Testbench-ul lucrării, dar la frontul de la 45 ns `PCSrc = 1` și `PC_Branch = 0x40`. Ce valoare are `PC_IF` după frontul de la 45 ns? Dar după cel de la 55 ns? Ce PC are instrucțiunea din ID între 45 și 55 ns?',
     [f('a', 'PC_IF după 45 ns', hexes(0x40), '0x...'), f('b', 'PC_IF după 55 ns', hexes(0x44), '0x...'), f('c', 'PC_ID între 45 și 55 ns', hexes(0x0C), '0x...')],
     'MUX-ul alege `PC_Branch` doar la frontul la care `PCSrc = 1`. IF/ID ia ce era în IF *înainte* de front.',
     'Înainte de frontul de la 45 ns, IF era la `0x0C` (`ori`). La front: PC ← `0x40`, IF/ID ← (`0x0C`, `ori`). La 55 ns PC ← `0x44`.')
q(30, 'Răspunsul la „Obs”', C2, 'ușoară', 'Cum se obțin cei 10 biți de adresă ai memoriei de instrucțiuni din PC, fără deplasare?',
  'cu tăietura `PC[11:2]`', ['cu `PC[9:0]`', 'cu `PC[31:22]`', 'cu `PC[10:1]`'],
  'Cei 2 biți de jos ai unei adrese aliniate sunt mereu 00.',
  '`PC[11:2]` aruncă biții 1:0 (împărțirea la 4) și păstrează exact 10 biți. `PC[9:0]` ar adresa cu PC-ul în octeți și ar sări peste trei instrucțiuni din patru.')
q(31, 'De ce + 4', C2, 'ușoară', 'De ce PC-ul crește cu 4?', 'o instrucțiune are 4 octeți, iar memoria e adresată pe octet',
  ['pentru că sunt 4 etape înainte de WB', 'pentru că memoria are 4 KB', 'pentru că instrucțiunile au 4 câmpuri'],
  sol='32 de biți = 4 octeți; instrucțiunea următoare e la 4 adrese de octet mai departe.')
q(32, 'Resetul PC-ului', C2, 'ușoară', '`always @(posedge clk) if (res) out <= 0; else if (write) out <= in;` Ce fel de reset are PC-ul?',
  'sincron, cu prioritate față de `write`', ['asincron', 'sincron, dar doar dacă `write = 1`', 'nu are reset'],
  sol='Resetul e testat doar pe front (sincron) și înaintea lui `write` (prioritar). Asincron ar fi `@(posedge clk or posedge res)`.')
q(33, 'PC_write = 0', C2, 'ușoară', 'Ce face registrul PC la un front cu `res = 0` și `write = 0`?',
  'își păstrează valoarea (stall)', ['devine 0', 'ia valoarea `in`', 'devine X'],
  sol='Nicio ramură nu atribuie `out`, deci registrul își ține valoarea: PC-ul îngheață.')
q(34, 'Citirea asincronă', C2, 'medie', 'De ce memoria de instrucțiuni are citire asincronă (`always @(*)`)?',
  'ca instrucțiunea să apară în același ciclu în care se schimbă PC-ul, gata pentru IF/ID la frontul următor',
  ['ca să consume mai puțin', 'pentru că `$readmemh` nu merge cu ceas', 'ca să poată fi scrisă de program'],
  sol='Cu o memorie sincronă, instrucțiunea ar apărea abia la frontul următor: IF ar dura două cicluri.')
q(35, 'Fără for-ul de inițializare', C2, 'medie', 'În `instruction_memory` lipsește `for`-ul care pune 0 în `codeMemory`. Ce apare în ID după ultima instrucțiune a programului?',
  '`X` pe `INSTRUCTION_ID` și pe toate câmpurile', ['0 peste tot, ca înainte', 'iarăși prima instrucțiune', 'ultima instrucțiune, repetată'],
  sol='Locațiile pe care `$readmemh` nu le atinge rămân neinițializate, adică `X`.')
q(36, 'Rolul MUX-ului', C2, 'ușoară', 'În IF, ce alege multiplexorul cu `sel = PCSrc`?',
  'următorul PC: PC + 4 (sel = 0) sau `PC_Branch` (sel = 1)', ['instrucțiunea dintre două memorii', 'registrul `rs1` sau `rs2`', 'imediatul sau `REG_DATA2`'],
  sol='`assign out = sel ? inb : ina;` cu `ina = PC + 4`, `inb = PC_Branch`.')

# ---------------------------------------------------------------- 3. encoding (bench)
ENC = [
    ('add x2,x1,x0', 'ușoară', True), ('addi x1,x1,1', 'ușoară', True), ('and x3,x1,x2', 'ușoară', True), ('ori x4,x1,1', 'ușoară', True),
    ('sw x4,4(x5)', 'medie', True), ('lw x12,8(x0)', 'medie', True), ('beq x18,x0,0x5c', 'grea', True),
    ('sub x5,x6,x7', 'ușoară', False), ('xor x10,x11,x12', 'ușoară', False), ('or x1,x2,x3', 'ușoară', False), ('sll x4,x4,x5', 'medie', False),
    ('sra x9,x8,x7', 'medie', False), ('slt x3,x1,x2', 'ușoară', False), ('addi x5,x0,-1', 'medie', False), ('andi x2,x2,-16', 'medie', False),
    ('xori x6,x6,-1', 'medie', False), ('slti x3,x4,10', 'ușoară', False), ('sltiu x8,x9,2047', 'medie', False), ('slli x10,x11,4', 'medie', False),
    ('srli x10,x11,31', 'medie', False), ('srai x3,x3,31', 'grea', False), ('lw x6,0x40(x10)', 'medie', False), ('lw x5,-12(x2)', 'grea', False),
    ('sw x6,-4(x2)', 'grea', False), ('sw x9,100(x1)', 'medie', False), ('bne x5,x0,-8', 'grea', False), ('bge x1,x2,0x100', 'grea', False),
    ('blt x5,x6,2048', 'grea', False), ('bltu x3,x4,16', 'medie', False), ('bgeu x3,x4,-20', 'grea', False),
]
TIPS = {
    'R': 'Tip R: `funct7 | rs2 | rs1 | funct3 | rd | opcode`, cu opcode `0110011`. Atenție: `rs2` vine înaintea lui `rs1` în cuvânt.',
    'SH': 'Deplasare cu imediat: format I, dar biții 31:25 sunt `funct7` (`0100000` doar la `srai`) și biții 24:20 sunt `shamt`.',
    'I': 'Tip I: `imm[11:0] | rs1 | funct3 | rd | opcode`. Un imediat negativ se scrie în complement față de 2 pe 12 biți.',
    'S': 'Tip S: imediatul se rupe: `imm[11:5]` în biții 31:25, `imm[4:0]` în biții 11:7. `rs2` e registrul scris în memorie, `rs1` e baza.',
    'B': 'Tip B: deplasamentul pe 13 biți (bitul 0 nu se scrie): `imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | 1100011`.',
}
for i, (text, diff, lab) in enumerate(ENC):
    w = m.encode(text)
    name = text.split()[0]
    fmt = m.INSTR[name][0]
    shown = 'beq x18,x0,5c' if text == 'beq x18,x0,0x5c' else text
    extra = ' (deplasamentul `5c` e în hexa, ca în enunț)' if lab and name == 'beq' else ''
    sol = f'Format {FMT_NAME[fmt]}.\n\n{show_fields(text)}'
    if fmt == 'B':
        off = m.spec_imm(w)
        sol += f'\n\nDeplasamentul `{off}` pe 13 biți: `{off & 0x1FFF:013b}`; bitul 0 nu se stochează.'
    if fmt == 'S':
        sol += f'\n\n`{text.split()[0]} rs2, imm(rs1)`: datele vin din `rs2`, adresa e `rs1 + imm`.'
    bench(100 + i, f'Codifică {shown}', C3, diff,
          f'Codifică instrucțiunea `{shown}`{extra} și scrie cuvântul de 32 de biți în hexa.' + (' (Cerința 8 din lucrare.)' if lab else ''),
          [f('hex', 'cuvântul (hexa)', hexes(w), '0x........')], TIPS[fmt], sol)

# ---------------------------------------------------------------- 4. decoding (bench)
DEC = [0x00A50533, 0x40B50533, 0xFFF00293, 0x0002A303, 0xFE62AE23, 0xFE0516E3, 0x00C59593, 0x4025D593, 0x00F37393, 0x0062C2B3,
       0x00352423, 0x01C12083, 0x00B57663, 0xFFF5C513, 0x0080006F, 0x123452B7]
for i, w in enumerate(DEC):
    text = m.decode(w)
    name = text.split()[0]
    fmt = m.INSTR[name][0]
    fl = m.fields(w)
    fields = [f('fmt', 'formatul (R, I, S, B, U, J)', 'I' if fmt == 'SH' else fmt, 'o literă'), f('name', 'instrucțiunea (mnemonica)', name, 'add, lw...')]
    if fmt not in ('S', 'B'):
        fields.append(f('rd', 'rd (numărul registrului)', fl['rd'], 'un număr', number=True))
    if fmt not in ('U', 'J'):
        fields.append(f('rs1', 'rs1', fl['rs1'], 'un număr', number=True))
    if fmt in ('R', 'S', 'B'):
        fields.append(f('rs2', 'rs2', fl['rs2'], 'un număr', number=True))
    imm = m.spec_imm(w)
    if fmt == 'U':
        fields.append(f('imm', 'imm[31:12] (hexa)', '|'.join(dict.fromkeys([f'0x{w >> 12:x}', f'{w >> 12:x}', f'0x{w >> 12:05x}', f'{w >> 12:05x}'])), '0x...'))
    elif imm is not None:
        fields.append(f('imm', 'imediatul (zecimal, cu semn)' if fmt != 'SH' else 'shamt (zecimal)', imm, 'un număr', number=True))
    diff = 'ușoară' if fmt == 'R' else ('grea' if fmt in ('B', 'J') or (imm is not None and imm < 0) else 'medie')
    bench(200 + i, f'Decodifică 0x{w:08X}', C4, diff,
          f'Ce instrucțiune RV32I este cuvântul `0x{w:08X}`? Completează câmpurile.' + (' (`jal` nu e în lucrare, dar formatul J e în Fig. 3.)' if fmt == 'J' else '') + (' (`lui` nu e în lucrare, dar formatul U e în Fig. 3.)' if fmt == 'U' else ''),
          fields, 'Scrie cuvântul în binar, citește opcode-ul (biții 6:0): el dă formatul. Apoi taie câmpurile formatului.',
          f'Opcode `{fl["opcode"]:07b}` → format {FMT_NAME[fmt]}.\n\n{show_fields(text)}\n\nEste `{text}`.', word=w)

# ---------------------------------------------------------------- 5. imm_gen (bench)
IMM = ['lw x5,-12(x2)', 'addi x7,x0,-1', 'andi x3,x4,255', 'xori x6,x6,-1', 'slti x8,x9,-100', 'sltiu x8,x9,2047', 'slli x10,x11,4',
       'srai x10,x11,3', 'srli x10,x11,31', 'sw x4,4(x5)', 'sw x9,-8(x2)', 'beq x18,x0,0x5c', 'bne x1,x2,-4', 'blt x5,x6,2048', 'bge x5,x6,-4096',
       'bgeu x3,x4,-20', 'lui x5,0x12345', 'add x2,x1,x0', 'jal x1,8', 'jalr x0,0(x1)']
for i, text in enumerate(IMM):
    w = m.encode(text)
    name = text.split()[0]
    fmt = m.INSTR[name][0]
    out = m.imm_gen(w)
    signed = out - (1 << 32) if out >> 31 else out
    shown = 'beq x18,x0,5c' if text == 'beq x18,x0,0x5c' else text
    if name in ('lui', 'jal', 'jalr', 'add'):
        isa = m.spec_imm(w)
        why = {'add': lambda: 'Tipul R nu are imediat: ramura `default` dă 0.',
               'lui': lambda: f'Opcode `0110111` nu e în `case`: ramura `default` dă 0. (ISA-ul ar da `0x{isa & 0xFFFFFFFF:08X}`, dar `lui` nu e în lista cerinței 4.)',
               'jal': lambda: f'Opcode `1101111` nu e în `case`: `default`, 0. (ISA-ul ar da `{isa}`; formatul J nu e cerut în Lucrarea 2.)',
               'jalr': lambda: 'Opcode `1100111` nu e în `case` (doar `0000011` e tratat ca load): `default`, 0. Imediatul ISA e 0 oricum aici.'}[name]()
        diff = 'grea' if name != 'add' else 'ușoară'
    else:
        why = {'I': 'Ramura de tip I: `{{20{in[31]}}, in[31:20]}`.', 'SH': 'Deplasare: ramura `funct3 == 001 / 101` dă `{27\'b0, in[24:20]}` (doar `shamt`).',
               'S': 'Ramura S: `{{20{in[31]}}, in[31:25], in[11:7]}`.', 'B': 'Ramura B: `{{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1\'b0}`.'}[fmt]
        diff = 'grea' if fmt == 'B' or signed < 0 else 'medie'
    bench(300 + i, f'IMM_ID pentru {shown}', C5, diff,
          f'Instrucțiunea `{shown}` (cuvântul `0x{w:08X}`) e în etapa ID. Ce scoate `imm_gen`-ul din lucrare pe `IMM_ID`? Dă valoarea în hexa (32 de biți) și în zecimal, cu semn.',
          [f('hex', 'IMM_ID (hexa, 32 de biți)', hexes(out), '0x........'), f('dec', 'IMM_ID (zecimal, cu semn)', signed, 'un număr', number=True)],
          'Opcode-ul alege ramura din `case`; bitul de semn e mereu `in[31]`.',
          f'{show_fields(text)}\n\n{why} Rezultat: `0x{out:08X}` = `{signed}`.', word=w)

q(330, 'De ce shamt la deplasări', C5, 'medie', 'De ce `imm_gen` ia doar biții 24:20 la `slli`, `srli`, `srai`?',
  'deplasarea e de cel mult 31 de poziții (5 biți), iar biții 31:25 sunt `funct7`, nu imediat',
  ['pentru că deplasările nu au imediat', 'pentru că așa se face extensia de semn', 'pentru că biții 31:25 sunt `rs2`'],
  sol='La `srai`, `funct7 = 0100000`: tratat ca I obișnuit, imediatul ar ieși `0x400 + shamt`.')
q(331, 'Bitul 0 la B', C5, 'medie', 'De ce imediatul de tip B se termină cu `1\'b0` în `imm_gen`?',
  'adresele de salt sunt pare, bitul 0 nu se stochează; `1\'b0` adăugat e „Shift left 1” din Fig. 3',
  ['ca să facă extensia de semn', 'ca să obțină 33 de biți', 'pentru că `beq` sare doar înapoi'],
  sol='Cei 12 biți stocați sunt imm[12:1]; lipind 0 la coadă, `IMM_ID` e deplasamentul în octeți, gata de adunat la PC.')
q(332, 'Extensia de semn', C5, 'ușoară', 'Imediatul `addi` de 12 biți `0xFFF`. Ce trebuie să iasă pe 32 de biți?',
  '`0xFFFFFFFF` (−1)', ['`0x00000FFF` (4095)', '`0xFFF00000`', '`0x0000FFFF`'],
  sol='Extensia de semn copiază bitul 11 (aici 1) în toți biții de sus: −1 rămâne −1.')
q(333, 'Bitul de semn', C5, 'ușoară', 'Care bit e bitul de semn al imediatului, la toate formatele RISC-V?',
  '`inst[31]`', ['`inst[0]`', '`inst[11]`', '`inst[20]` la I, `inst[7]` la B'],
  sol='E o alegere deliberată a ISA-ului: extensia de semn începe înainte să știi formatul.')
q(334, 'Fără default', C5, 'medie', 'Ce se întâmplă dacă din `case`-ul lui `imm_gen` lipsește `default`?',
  'sinteza pune un latch pentru `out` (pe opcode-urile netratate își ține valoarea veche)',
  ['nimic, `out` devine 0 automat', 'eroare de compilare', '`out` devine Z'],
  sol='Într-un `always @(*)`, o ieșire neatribuită pe un drum trebuie să-și țină valoarea: memorie pe nivel, adică latch.')

# ---------------------------------------------------------------- 6. registers and ID
def regs_after(writes):
    r = list(range(32))
    for rd, v in writes:
        if rd:
            r[rd] = v & 0xFFFFFFFF
    return r


RD = [
    ('add x3,x1,x2', [], 'ușoară'), ('sw x4,4(x5)', [], 'ușoară'), ('beq x18,x0,0x5c', [], 'ușoară'),
    ('add x7,x7,x9', [(7, 0x100)], 'medie'), ('sub x5,x0,x6', [(0, 0x55), (6, 0x20)], 'medie'), ('lw x12,8(x0)', [(12, 0xFF)], 'medie'),
    ('and x31,x30,x31', [(30, 0xF0F0), (31, 0xFF)], 'medie'),
]
for i, (text, writes, diff) in enumerate(RD):
    w = m.encode(text)
    fl = m.fields(w)
    r = regs_after(writes)
    shown = 'beq x18,x0,5c' if text.endswith('0x5c') else text
    wtxt = '' if not writes else ' Înainte, WB a scris (cu `RegWrite_WB = 1`): ' + ', '.join(f'`RD_WB = {rd}`, `ALU_DATA_WB = 0x{v:X}`' for rd, v in writes) + '.'
    calc(400 + i, f'REG_DATA pentru {shown}', C6, diff,
         f'Bancul de registre al lucrării pornește cu `xi = i`.{wtxt} Instrucțiunea `{shown}` intră în ID. Ce arată `RS1_ID`, `RS2_ID`, `REG_DATA1_ID` și `REG_DATA2_ID`?',
         [f('rs1', 'RS1_ID (zecimal)', fl['rs1'], number=True), f('rs2', 'RS2_ID (zecimal)', fl['rs2'], number=True),
          f('d1', 'REG_DATA1_ID (hexa)', hexes(r[fl['rs1']]), '0x...'), f('d2', 'REG_DATA2_ID (hexa)', hexes(r[fl['rs2']]), '0x...')],
         'ID citește mereu registrele din biții 19:15 și 24:20, oricare ar fi formatul. O scriere în x0 se ignoră.',
         f'`rs1 = {fl["rs1"]}`, `rs2 = {fl["rs2"]}` (biții 19:15 și 24:20).' + (' La `beq x18,x0,...` biții 24:20 sunt `x0`.' if 'beq' in text else '') +
         (f' Scrierea în x0 e ignorată.' if any(rd == 0 for rd, _ in writes) else '') +
         f' Deci `REG_DATA1_ID = 0x{r[fl["rs1"]]:X}`, `REG_DATA2_ID = 0x{r[fl["rs2"]]:X}`.' +
         (' La `lw x12,8(x0)` biții 24:20 fac parte din imediat (`8` → `01000` = x8), deci se citește x8, deși `lw` nu-l folosește.' if text.startswith('lw') else ''))
calc(410, 'RD_ID pentru sw', C6, 'medie', 'Ce arată `RD_ID` când `sw x4,4(x5)` e în ID? Dar `FUNCT7_ID`?',
     [f('rd', 'RD_ID (zecimal)', 4, number=True), f('f7', 'FUNCT7_ID (zecimal)', 0, number=True)],
     'ID taie biții 11:7 și 31:25 fără să știe formatul.', 'La S, biții 11:7 sunt `imm[4:0] = 00100` = 4, iar biții 31:25 sunt `imm[11:5] = 0`. Fig. 4 arată `RD_ID = 04` la `sw`.')
calc(411, 'RD_ID pentru beq', C6, 'grea', 'Ce arată `RD_ID` (în hexa) când `beq x18,x0,5c` e în ID? Dar `FUNCT7_ID`?',
     [f('rd', 'RD_ID (hexa)', '0x1c|1c|0x01c', '0x..'), f('f7', 'FUNCT7_ID (hexa)', '0x2|2|0x02|02', '0x..')],
     'La B, biții 11:7 sunt `imm[4:1]` urmat de `imm[11]`; biții 31:25 sunt `imm[12]` urmat de `imm[10:5]`.',
     '`0x5C`: `imm[4:1] = 1110`, `imm[11] = 0` → `11100` = `0x1C`. `imm[12] = 0`, `imm[10:5] = 000010` → `0000010` = `0x02`. Exact ca în Fig. 4.')
q(412, 'x0 în registre', C6, 'ușoară', 'Cum se asigură, în `registers`, că `x0` rămâne mereu 0?',
  'scrierea e făcută doar dacă `write_reg != 0`, iar x0 pornește de la 0', ['`x0` e un `wire` legat la masă', 'se rescrie 0 în x0 la fiecare front', 'citirea lui x0 e oprită'],
  sol='`if (reg_write && write_reg != 5\'d0) regs[write_reg] <= write_data;`')
q(413, 'Citire și scriere', C6, 'medie', 'Cum sunt porturile bancului de registre din lucrare?',
  '2 porturi de citire asincrone și 1 port de scriere sincron', ['1 port de citire și 1 de scriere, ambele sincrone', '2 porturi de citire sincrone și 2 de scriere', 'un singur port, folosit alternativ'],
  sol='Doi operanzi se citesc combinațional, în ciclul lui ID; rezultatul se scrie doar pe front, cu `reg_write = 1`.')
calc(414, 'Scriere și citire în același ciclu', C6, 'grea',
     'Testbench-ul separat al bancului de registre: `read_reg2 = 3` tot timpul; la 18 ns pune `reg_write = 1`, `write_reg = 3`, `write_data = 0xAB`. Fronturi la 5, 15, 25, ... ns. Ce arată `read_data2` la 20 ns și la 30 ns?',
     [f('a', 'read_data2 la 20 ns (hexa)', hexes(3), '0x..'), f('b', 'read_data2 la 30 ns (hexa)', hexes(0xAB), '0x..')],
     'Scrierea e sincronă, citirea asincronă.', 'Până la frontul de la 25 ns, x3 e încă 3. După front x3 = `0xAB`, iar citirea asincronă îl arată imediat.')
q(415, 'Unde se scrie, în ID', C6, 'medie', 'În modulul ID, de unde vine adresa de scriere a bancului de registre?',
  'din `RD_WB` (instrucțiunea care se termină în WB)', ['din `RD_ID` (instrucțiunea din ID)', 'din `RS1_ID`', 'din `IMM_ID`'],
  sol='Instrucțiunea care se scrie acum a intrat în pipeline cu 3 cicluri mai devreme: adresa ei vine din WB, nu din ID.')
q(416, 'PC_ID în ID', C6, 'medie', 'Ce face modulul ID cu intrarea `PC_ID` în Lucrarea 2?',
  'nimic încă: va merge prin ID/EX la EX, pentru `PC + imm`', ['o adună cu 4', 'o scrie în registrul x1', 'o dă lui `imm_gen`'],
  sol='`PC_ID` e trecut mai departe; adresa de salt se calculează în EX (Lucrarea 3).')

# ---------------------------------------------------------------- 7. the waveform
TL = {t: (pc, ins, o) for t, pc, ins, o in m.lab_timeline()}


def at(time):
    """The values shown at [time] ns: those after the last edge before it."""
    edge = max(t for t in TL if t <= time)
    return TL[edge]


WAVE = [(22, 'ușoară'), (47, 'medie'), (58, 'medie'), (68, 'medie'), (80, 'medie'), (100, 'medie'), (203, 'grea')]
for i, (time, diff) in enumerate(WAVE):
    pc, ins, o = at(time)
    calc(500 + i, f'Forma de undă la {time} ns', C7, diff,
         f'Simularea lucrării (programul din cerința 8, testbench-ul dat: fronturi la 5, 15, 25, ... ns, `reset = 1` până la 10 ns). Ce valori au, la {time} ns, `PC_ID`, `INSTRUCTION_ID`, `OPCODE_ID` și `IMM_ID`?',
         [f('pc', 'PC_ID (hexa)', hexes(o['PC_ID']), '0x...'), f('ins', 'INSTRUCTION_ID (hexa)', hexes(o['INSTRUCTION_ID']), '0x........'),
          f('op', 'OPCODE_ID (hexa)', hexes(o['OPCODE_ID']), '0x..'), f('imm', 'IMM_ID (hexa)', hexes(o['IMM_ID']), '0x........')],
         'Găsește ultimul front dinainte. IF/ID a primit atunci instrucțiunea pe care IF o avea înainte de front.',
         f'Ultimul front: {max(t for t in TL if t <= time)} ns. ID are `{m.decode(o["INSTRUCTION_ID"]) or "0 (după program)"}` de la `PC = 0x{o["PC_ID"]:X}`: '
         f'`INSTRUCTION_ID = 0x{o["INSTRUCTION_ID"]:08X}`, `OPCODE_ID = 0x{o["OPCODE_ID"]:02X}`, `IMM_ID = 0x{o["IMM_ID"]:08X}`.')
calc(510, 'Când ajunge beq în ID', C7, 'ușoară', 'În simularea lucrării, la ce timp (ns) intră `beq x18,x0,5c` în ID? Ce `PC_ID` are?',
     [f('t', 'timpul (ns)', 75, number=True), f('pc', 'PC_ID (hexa)', hexes(0x18), '0x..')],
     'Primul front fără reset (15 ns) aduce `add`; `beq` e a 7-a instrucțiune.', '`add` la 15 ns, apoi câte una la 10 ns: a 7-a la `15 + 6 · 10 = 75` ns, `PC_ID = 6 · 4 = 0x18`.')
calc(511, 'REG_DATA1 la beq', C7, 'ușoară', 'Când `beq x18,x0,5c` e în ID, ce arată `REG_DATA1_ID` și `RS1_ID` (hexa)?',
     [f('d1', 'REG_DATA1_ID', hexes(0x12), '0x..'), f('rs1', 'RS1_ID', '0x12|12', '0x..')],
     'Registrele pornesc cu `xi = i`.', '`rs1 = x18`; x18 = 18 = `0x12`. În Fig. 4 apare `00000012` și `12`.')
calc(512, 'Radix', C7, 'ușoară', 'În Vivado, `OPCODE_ID` apare ca 51, 19, 35, 99 (zecimal). Ce sunt în hexa?',
     [f('a', '51', '0x33|33', '0x..'), f('b', '19', '0x13|13', '0x..'), f('c', '35', '0x23|23', '0x..'), f('d', '99', '0x63|63', '0x..')],
     'Click dreapta → Radix → Hexadecimal.', '51 = `0x33` (R), 19 = `0x13` (I aritmetic), 35 = `0x23` (S), 99 = `0x63` (B).')
q(513, 'X la început', C7, 'ușoară', 'De ce Fig. 4 arată `XXX` roșu pe `PC_ID` între 0 și 5 ns?',
  'până la primul front, registrele PC și IF/ID n-au primit nicio valoare', ['memoria nu e încă încărcată', 'reset e 1', 'e o greșeală în cod'],
  sol='Primul front e la 5 ns (ceasul pornește din 0); atunci resetul le face 0.')
q(514, 'Întârzierea IF/ID', C7, 'ușoară', 'Cu cât rămâne `PC_ID` în urma PC-ului din IF, în simularea fără opriri?',
  'cu 4 (un ciclu)', ['cu 8 (două cicluri)', 'cu 0', 'cu 1'],
  sol='IF/ID introduce exact un ciclu: instrucțiunea adusă în ciclul n e decodificată în ciclul n + 1.')
calc(515, 'Ultimul front', C7, 'medie', 'Simularea lucrării se oprește la 210 ns (`#10 reset=0; #200 $finish;`). La ce timp e ultimul front crescător și ce valori au atunci `PC_IF` și `PC_ID` (hexa)?',
     [f('t', 'ultimul front (ns)', 205, number=True), f('a', 'PC_IF', hexes(0x50), '0x..'), f('b', 'PC_ID', hexes(0x4C), '0x..')],
     'Fronturi la 5, 15, ..., 205.', 'De la 15 la 205 ns sunt 20 de fronturi fără reset: `PC_IF = 20 · 4 = 80 = 0x50`; `PC_ID` e cu 4 în urmă: `0x4C`.')

# ---------------------------------------------------------------- 8. written (Verilog by hand)
GH = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'ghid_apm_l2', 'src')


def src(name):
    with open(os.path.join(GH, name), encoding='utf-8') as fh:
        return fh.read().strip()


def written(id, title, diff, statement, model, barem, hint=''):
    total = sum(p for _, p in barem)
    spec = {'model': model.strip(), 'barem': [{'text': t, 'points': p} for t, p in barem]}
    P.append(problem(id, title, C8, diff, statement + f'\n\n**Scrie modulul** ({str(total).replace(".", ",").removesuffix(",0")}p): pe foaie sau aici, apoi compară-l cu modelul și cu baremul.',
                     'scris', spec, hint, model.strip(), L2))


def code(s):
    return f'```\n{s}\n```'


written(600, 'Cerința 1a · mux2_1', 'ușoară', 'Scrie modulul `mux2_1(input [31:0] ina, inb, input sel, output [31:0] out)`: `out = ina` când `sel = 0`, `inb` când `sel = 1`.',
        code(src('mux2_1.v')), [('semnătura (porturi și lățimi) ca în enunț', 0.5), ('`assign` cu operatorul `?:` (sau `always @(*)` cu `if`/`case`, ieșirea `reg`)', 1), ('ordinea corectă: `sel = 1` → `inb`', 0.5)])
written(601, 'Cerința 1b · PC', 'ușoară', 'Scrie registrul `PC(input clk, res, write, input [31:0] in, output reg [31:0] out)`: reset sincron la 0, încarcă `in` pe frontul crescător doar dacă `write = 1`.',
        code(src('PC.v')), [('`always @(posedge clk)`', 0.5), ('resetul testat primul, `out <= 0`', 0.5), ('`else if (write) out <= in;`, altfel păstrează', 0.5), ('`<=` (neblocant) și `output reg`', 0.5)])
written(602, 'Cerința 1d · adder', 'ușoară', 'Scrie sumatorul `adder(input [31:0] ina, inb, output reg [31:0] out)` din enunț.',
        'Cu `output reg`, cum cere enunțul:\n\n' + code('module adder(input [31:0] ina, inb,\n             output reg [31:0] out);\n    always @(*) out = ina + inb;\nendmodule') +
        '\n\nEchivalent, varianta din laborator (`output` simplu cu `assign`):\n\n' + code(src('adder.v')),
        [('porturile de 32 de biți', 0.5), ('`always @(*)` cu `=` pentru `output reg` (sau `assign` cu `output` fără `reg`)', 1), ('nu `assign` pe un `reg`', 0.5)])
written(603, 'Cerința 1c · instruction_memory', 'medie', 'Scrie memoria de instrucțiuni `instruction_memory(input [9:0] address, output reg [31:0] instruction)`: 1024 de cuvinte de 32 de biți, încărcate din `code_stud.mem`, citire asincronă.',
        code(src('instruction_memory.v')),
        [('`reg [31:0] codeMemory [0:1023]`', 0.5), ('inițializarea cu 0 (for) înainte de `$readmemh`', 0.5), ('`$readmemh("code_stud.mem", codeMemory)` într-un `initial`', 0.5), ('citire asincronă: `always @(*)` cu `=` (fără `clk`)', 0.5)])
written(604, 'Cerința 2 · modulul IF', 'medie', 'Scrie modulul `IF(input clk, reset, input PCSrc, PC_write, input [31:0] PC_Branch, output [31:0] PC_IF, INSTRUCTION_IF)` care leagă `mux2_1`, `PC`, `adder` și `instruction_memory`.',
        code(src('IF.v')),
        [('firele interne pentru PC + 4 și pentru ieșirea MUX-ului', 0.5), ('MUX: `ina = PC + 4`, `inb = PC_Branch`, `sel = PCSrc`', 0.5), ('PC: `in` = ieșirea MUX-ului, `write = PC_write`, `res = reset`, `out = PC_IF`', 0.5),
         ('sumatorul: `PC_IF + 4`', 0.5), ('memoria adresată cu `PC_IF[11:2]`', 1)])
written(605, 'Cerința 3 · registers', 'medie', 'Scrie bancul de registre `registers(input clk, reg_write, input [4:0] read_reg1, read_reg2, write_reg, input [31:0] write_data, output [31:0] read_data1, read_data2)`: 32 × 32 de biți, citire asincronă, scriere sincronă, `x0` mereu 0, registrul `i` inițializat cu `i`.',
        code(src('registers.v')),
        [('`reg [31:0] regs [0:31]`', 0.5), ('`initial` cu `for`: `regs[i] = i`', 0.5), ('scriere în `always @(posedge clk)` cu `reg_write`', 0.5), ('`x0` protejat (`write_reg != 0`)', 0.5), ('citire asincronă cu `assign`', 0.5)])
written(606, 'Cerința 3 · testbench pentru registers', 'medie', 'Scrie un testbench care simulează separat bancul de registre și arată: citirea asincronă, scrierea sincronă, că x0 nu se poate scrie și că fără `reg_write` nu se scrie nimic.',
        code(src('tb_registers.v')),
        [('instanțierea lui `registers` și un ceas', 0.5), ('o schimbare a adresei de citire între fronturi (citire asincronă)', 0.5), ('o scriere urmărită înainte și după front', 0.5), ('o încercare de scriere în x0', 0.5), ('o scriere cu `reg_write = 0`', 0.5)])
written(607, 'Cerința 4 · imm_gen', 'grea', 'Scrie `imm_gen(input [31:0] in, output reg [31:0] out)` pentru: `lw`, `addi`, `andi`, `ori`, `xori`, `slti`, `sltiu`, `slli`, `srli`, `srai`, `sw` și salturile `beq`...`bgeu`.',
        code(src('imm_gen.v')),
        [('`always @(*)` cu `case` pe opcode', 0.5), ('I (`lw` și aritmetice): `{{20{in[31]}}, in[31:20]}`', 0.5), ('deplasările: doar `in[24:20]`, după `funct3`', 0.5),
         ('S: `{{20{in[31]}}, in[31:25], in[11:7]}`', 0.5), ('B: `{{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1\'b0}`', 1), ('`default` (fără latch)', 0.5)])
written(608, 'Cerința 5 · modulul ID', 'medie', 'Scrie modulul `ID` din enunț: taie câmpurile instrucțiunii, instanțiază `registers` și `imm_gen`.',
        code(src('ID.v')),
        [('câmpurile: opcode 6:0, rd 11:7, funct3 14:12, rs1 19:15, rs2 24:20, funct7 31:25', 1), ('registrele: citire cu `RS1_ID`, `RS2_ID`', 0.5),
         ('scrierea din WB: `RegWrite_WB`, `RD_WB`, `ALU_DATA_WB`', 0.5), ('`imm_gen` pe toată instrucțiunea', 0.5)])
written(609, 'Cerința 6 · registrul IF/ID', 'ușoară', 'Scrie registrul de pipeline IF/ID: pe front, cu reset pune 0, altfel, dacă `write = 1`, ia PC-ul și instrucțiunea din IF.',
        code('// Cerinta 6' + src('RISC_V_IF_ID.v').split('// Cerinta 6')[1]),
        [('două ieșiri `reg` de 32 de biți', 0.5), ('`always @(posedge clk)` cu reset prioritar', 0.5), ('încărcare doar cu `write`, altfel păstrează', 0.5), ('`<=`', 0.5)])
written(610, 'Cerința 7 · modulul top', 'medie', 'Scrie modulul `RISC_V_IF_ID` cu porturile din enunț (în aceeași ordine), care leagă IF, IF/ID și ID.',
        code(src('RISC_V_IF_ID.v').split('// Cerinta 6')[0].strip()),
        [('porturile în ordinea din enunț (testbench-ul instanțiază pe poziție)', 1), ('un singur port `ALU_DATA_WB` de 32 de biți', 0.5),
         ('firele `PC_IF`, `INSTRUCTION_IF` între IF și IF/ID', 0.5), ('IF/ID → ID prin `PC_ID`, `INSTRUCTION_ID`', 0.5), ('`clk`/`reset` la toate', 0.5)])
written(611, 'Cerința 8 · code_stud.mem', 'medie', 'Scrie fișierul `code_stud.mem` pentru programul: `add x2,x1,x0`, `addi x1,x1,1`, `and x3,x1,x2`, `ori x4,x1,1`, `sw x4,4(x5)`, `lw x12,8(x0)`, `beq x18,x0,5c`.',
        code(src('code_stud.mem')) + '\n\nCâte o instrucțiune pe linie, hexa, fără `0x`.',
        [(f'`{t}` → `{m.h(w)}`', 0.5) for t, w in zip(m.LAB_PROGRAM, m.LAB_HEX)] + [('ordinea programului, o linie per instrucțiune', 0.5)])

# ---------------------------------------------------------------- 9. Verilog semantics
q(700, 'Blocant sau neblocant', C9, 'ușoară', 'Ce atribuire se folosește în `always @(posedge clk)` pentru PC și IF/ID?',
  '`<=` (neblocant)', ['`=` (blocant)', '`assign`', 'oricare, e la fel'],
  sol='Cu `<=`, toate registrele iau la front valorile calculate din starea de dinainte, ca bistabilele reale.')
q(701, 'reg nu e registru', C9, 'medie', '`output reg [31:0] instruction` din memoria de instrucțiuni, atribuit în `always @(*)`. Ce hardware devine?',
  'logică combinațională (citirea memoriei); `reg` e cerut doar de sintaxă', ['un registru de 32 de biți', 'un latch', 'o memorie sincronă'],
  sol='`reg` înseamnă „primește valoare într-un bloc procedural”. Cu `@(*)` și toate drumurile acoperite, e combinațional.')
q(702, 'Instanțiere pe poziție', C9, 'medie', 'Testbench-ul instanțiază `RISC_V_IF_ID` pe poziție. Ce se întâmplă dacă top-ul declară `input [31:0] ALU_DATA, WB,` în loc de `ALU_DATA_WB`?',
  'top-ul are un port în plus și toate semnalele de după se leagă decalat, la porturi greșite',
  ['nimic, Verilog leagă după nume', 'eroare de sintaxă', 'doar `ALU_DATA_WB` rămâne neconectat'],
  sol='Virgula declară două porturi. Pe poziție, `RD_WB` ajunge la `WB`, `PC_ID` la `RD_WB` și tot așa (cu _warning_-uri de lățime).')
q(703, 'Concatenare și replicare', C9, 'ușoară', 'Ce înseamnă `{{20{in[31]}}, in[31:20]}`?',
  '20 de copii ale bitului 31, urmate de biții 31...20: 32 de biți', ['bitul 31 înmulțit cu 20', 'biții 20...31 inversați', '20 de biți de 0, apoi biții 31...20'],
  sol='`{n{x}}` replică, `{a, b}` lipește. Rezultatul e imediatul I extins cu semn.')
q(704, 'initial și $readmemh', C9, 'medie', 'Care afirmație despre `initial $readmemh("code_stud.mem", codeMemory);` e corectă?',
  'rulează o dată, la timpul 0 al simulării, și încarcă memoria de la adresa 0', ['rulează la fiecare front de ceas', 'scrie memoria în fișier', 'citește fișierul în binar'],
  sol='`initial` rulează o singură dată; `$readmemh` citește valori hexa, una pe linie.')
q(705, 'Latch', C9, 'medie', 'Care cod produce un latch?', '`always @(*) if (sel) y = a;`', ['`always @(*) if (sel) y = a; else y = b;`', '`assign y = sel ? a : b;`', '`always @(posedge clk) if (sel) y <= a;`'],
  sol='Fără `else`, când `sel = 0` `y` își ține valoarea: latch. Varianta cu `posedge clk` e un registru cu enable, nu latch.')
q(706, 'Reset asincron', C9, 'medie', 'Cum ar arăta lista de sensibilitate a PC-ului cu reset *asincron*?',
  '`always @(posedge clk or posedge res)`', ['`always @(posedge clk)`', '`always @(*)`', '`always @(res)`'],
  sol='Resetul asincron trebuie să declanșeze blocul și fără front de ceas.')
q(707, 'output reg și assign', C9, 'medie', 'Enunțul dă `adder(... output reg [31:0] out)`. Ce variantă e *greșită*?',
  '`output reg [31:0] out` cu `assign out = ina + inb;`', ['`output reg` cu `always @(*) out = ina + inb;`', '`output [31:0] out` cu `assign out = ina + inb;`', 'toate sunt corecte'],
  sol='Unui `reg` nu i se poate face `assign` (eroare). Celelalte două sunt echivalente.')
q(708, 'Perioada ceasului', C9, 'ușoară', '`always #5 clk = ~clk;` cu `timescale 1ns/1ps`. Care e frecvența ceasului?',
  '100 MHz (perioadă 10 ns)', ['200 MHz', '50 MHz', '5 MHz'],
  sol='Ceasul se inversează la 5 ns: o perioadă are 10 ns, adică 100 MHz.')
q(709, 'Tăietura', C9, 'ușoară', 'Câți biți are `INSTRUCTION_ID[24:20]`?', '5', ['4', '20', '24'], sol='Biții 24, 23, 22, 21, 20.')
tf(710, 'Module în același fișier', C9, 'ușoară', 'Un fișier Verilog poate conține mai multe module (de exemplu `RISC_V_IF_ID` și `IF_ID_reg`).', True,
   'Adevărat. Contează doar ca fiecare modul să fie definit o singură dată în tot proiectul.')
q(711, 'Modul definit de două ori', C9, 'medie', 'Vivado dă la elaborare eroarea că modulul `RISC_V_IF_ID` e definit de mai multe ori. Cauza probabilă?',
  'același modul e în două fișiere din proiect (de exemplu o copie veche a top-ului)', ['lipsește testbench-ul', '`code_stud.mem` nu e găsit', 'porturile sunt pe poziție'],
  sol='Scoate copia: fiecare modul trebuie să existe o singură dată.')
q(712, 'Fișierul .mem negăsit', C9, 'medie', 'În simulare PC-ul crește corect, dar `INSTRUCTION_ID` e mereu `00000000`. Cauza probabilă?',
  '`code_stud.mem` nu e găsit de simulator, iar memoria a rămas plină de 0', ['IF/ID nu are reset', '`imm_gen` lipsește', 'ceasul e prea rapid'],
  sol='Adaugă `.mem`-ul ca simulation source (Memory File) și caută _warning_-ul `$readmemh` în Tcl Console.')

write_course('apm', CHAPTERS, P)
