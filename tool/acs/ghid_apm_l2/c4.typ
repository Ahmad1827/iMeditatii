#import "tpl.typ": *

= Formatele instrucțiunilor și codificarea (cerința 8)

Capitolul ăsta vine înaintea lui ID pentru că `imm_gen` și ID nu se pot înțelege fără formate.

== Cele șase formate

#align(center, tabel(
  columns: 8,
  [*biții*], [*31...25*], [*24...20*], [*19...15*], [*14...12*], [*11...7*], [*6...0*], [*tipul*],
  [R], table.cell(fill: c-f7)[funct7], table.cell(fill: c-rs2)[rs2], table.cell(fill: c-rs1)[rs1], table.cell(fill: c-f3)[funct3], table.cell(fill: c-rd)[rd], table.cell(fill: c-op)[opcode], [registru-registru],
  [I], table.cell(colspan: 2, fill: c-imm)[imm\[11:0\]], table.cell(fill: c-rs1)[rs1], table.cell(fill: c-f3)[funct3], table.cell(fill: c-rd)[rd], table.cell(fill: c-op)[opcode], [imediat, `lw`, `jalr`],
  [S], table.cell(fill: c-imm)[imm\[11:5\]], table.cell(fill: c-rs2)[rs2], table.cell(fill: c-rs1)[rs1], table.cell(fill: c-f3)[funct3], table.cell(fill: c-imm)[imm\[4:0\]], table.cell(fill: c-op)[opcode], [`sw` (store)],
  [B], table.cell(fill: c-imm)[imm\[12\|10:5\]], table.cell(fill: c-rs2)[rs2], table.cell(fill: c-rs1)[rs1], table.cell(fill: c-f3)[funct3], table.cell(fill: c-imm)[imm\[4:1\|11\]], table.cell(fill: c-op)[opcode], [salt condiționat],
  [U], table.cell(colspan: 4, fill: c-imm)[imm\[31:12\]], table.cell(fill: c-rd)[rd], table.cell(fill: c-op)[opcode], [`lui`, `auipc`],
  [J], table.cell(colspan: 4, fill: c-imm)[imm\[20\|10:1\|11\|19:12\]], table.cell(fill: c-rd)[rd], table.cell(fill: c-op)[opcode], [`jal`],
))

#regula(t: "Cele trei alegeri care fac decodarea simplă.")[
+ `opcode`, `rd`, `rs1`, `rs2`, `funct3` stau *mereu* la aceleași biți. ID le poate tăia fără să știe formatul.
+ Bitul de semn al oricărui imediat e *mereu* `inst[31]`: extensia de semn poate începe înainte să știi formatul.
+ Biții imediatului sunt amestecați (la S, B, J) tocmai ca să rămână pe pozițiile de mai sus: complexitatea se mută în `imm_gen`, unde costă doar fire.
]

== Opcode-uri și funct3

#grid(columns: (1fr, 1fr), gutter: 12pt,
  tabel(
    columns: (auto, auto, auto),
    [*Tip*], [*opcode*], [*instrucțiuni*],
    [R], [`0110011` (`0x33`)], [add, sub, and, or, ...],
    [I aritm.], [`0010011` (`0x13`)], [addi, ori, slli, ...],
    [I load], [`0000011` (`0x03`)], [lw, lb, lh, ...],
    [S], [`0100011` (`0x23`)], [sw, sb, sh],
    [B], [`1100011` (`0x63`)], [beq, bne, ...],
    [I jalr], [`1100111` (`0x67`)], [jalr],
    [U], [`0110111` (`0x37`)], [lui],
    [U], [`0010111` (`0x17`)], [auipc],
    [J], [`1101111` (`0x6F`)], [jal],
  ),
  tabel(
    columns: (auto, 1fr),
    [*funct3*], [*înseamnă*],
    [`000`], [add/sub, addi, beq, lb, sb],
    [`001`], [sll, slli, bne, lh, sh],
    [`010`], [slt, slti, lw, sw],
    [`011`], [sltu, sltiu],
    [`100`], [xor, xori, blt, lbu],
    [`101`], [srl/sra, srli/srai, bge, lhu],
    [`110`], [or, ori, bltu],
    [`111`], [and, andi, bgeu],
  ),
)

`funct7` deosebește perechile care au același `funct3`: `0000000` pentru `add`, `srl`, `srli`; `0100000` pentru `sub`, `sra`, `srai`.

== Metoda, în 5 pași

+ Identifici *formatul* din instrucțiune (tabelul de mai sus).
+ Scrii *opcode*-ul și *funct3* (și *funct7* la R și la deplasări).
+ Scrii *numerele registrelor* pe 5 biți: `x18` = `10010`.
+ Scrii *imediatul* în binar, cu complement față de 2 dacă e negativ, pe 12 biți (I, S) sau 13 biți (B), și îl împarți pe bucățile formatului.
+ Pui câmpurile în ordine de la bitul 31 la bitul 0, grupezi câte 4 biți și citești hexa.

#capcana[Ordinea operanzilor în asamblare *nu* e ordinea câmpurilor: `add rd, rs1, rs2`, dar în cuvânt `rs2` vine înaintea lui `rs1`. La `sw rs2, imm(rs1)` registrul care se *scrie în memorie* e `rs2` (primul operand), iar baza adresei e `rs1`.]

== Cele 7 instrucțiuni, bit cu bit

=== `add x2, x1, x0` (R)
`rd = x2 = 00010`, `rs1 = x1 = 00001`, `rs2 = x0 = 00000`, `funct3 = 000`, `funct7 = 0000000`, `opcode = 0110011`.
#instr(g.lab.at(0))

=== `addi x1, x1, 1` (I)
`imm = 1 = 000000000001` (12 biți), `rs1 = 00001`, `funct3 = 000`, `rd = 00001`, `opcode = 0010011`.
#instr(g.lab.at(1))

=== `and x3, x1, x2` (R)
Ca `add`, cu `funct3 = 111`; `rs2 = x2 = 00010`, `rs1 = x1`, `rd = x3 = 00011`.
#instr(g.lab.at(2))

=== `ori x4, x1, 1` (I)
Ca `addi`, cu `funct3 = 110`; `rd = x4 = 00100`.
#instr(g.lab.at(3))

=== `sw x4, 4(x5)` (S)
Înseamnă: memoria de la adresa `x5 + 4` primește valoarea lui `x4`. Deci `rs2 = x4` (datele), `rs1 = x5` (baza). `imm = 4 = 0000000 00100`: `imm[11:5] = 0000000`, `imm[4:0] = 00100`. Fiindcă un `sw` nu scrie niciun registru, nu are `rd`: biții 11:7 sunt folosiți pentru `imm[4:0]`.
#instr(g.lab.at(4))

=== `lw x12, 8(x0)` (I)
Înseamnă: `x12` primește cuvântul de la adresa `x0 + 8 = 8`. `rd = x12 = 01100`, `rs1 = x0`, `imm = 8 = 000000001000`, `funct3 = 010`, `opcode = 0000011`.
#instr(g.lab.at(5))

=== `beq x18, x0, 5c` (B)
Înseamnă: dacă `x18 == x0`, sari la `PC + 0x5C`. Deplasamentul e în *hexa* (`5c`): `0x5C = 92` de octeți. Pe 13 biți: `0 0000 0101 1100`, adică `imm[12] = 0`, `imm[11] = 0`, `imm[10:5] = 000010`, `imm[4:1] = 1110`, `imm[0] = 0` (nu se scrie). `rs1 = x18 = 10010`, `rs2 = x0`, `funct3 = 000`.
#instr(g.lab.at(6))

#capcana[Cele mai dese greșeli la `beq`: (1) să citești `5c` ca zecimal; (2) să scrii bitul `imm[0]` (care nu se stochează) și să decalezi totul cu un bit; (3) să pui `imm[11]` lângă `imm[12]`, sus: el stă *jos*, la bitul 7. Verificare: `RD_ID` arată `0x1C` pentru `beq` în Fig. 4, adică biții 11:7 = `11100` = `imm[4:1]` urmat de `imm[11]`.]

== Fișierul `code_stud.mem`

#sursa("code_stud.mem", read("src/code_stud.mem"))

Câte o instrucțiune pe linie, în hexa, fără `0x`, în ordinea programului: linia `k` ajunge în `codeMemory[k]`, adică la adresa de octet `4k`. Literele mari sau mici nu contează pentru `$readmemh`.

#vivado[Fișierul `.mem` trebuie adăugat în proiect (Add Sources → Add or create simulation sources, cu tipul „Memory File”) sau pus în directorul în care rulează simularea (`<proiect>.sim/sim_1/behav/xsim`). Dacă Vivado nu-l găsește, dă un _warning_ în Tcl Console, iar memoria rămâne plină de 0: toate câmpurile din ID vor fi 0 tot timpul.]
