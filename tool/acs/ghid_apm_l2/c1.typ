#import "tpl.typ": *

= Imaginea de ansamblu

== ISA și implementare

#defn(t: "ISA (Instruction Set Architecture).")[Contractul dintre software și hardware: ce registre vede programatorul, ce instrucțiuni există, cum se scrie fiecare pe biți și ce face. Un ISA este *abstract*: nu spune cum e construit procesorul.]

O *implementare* (o microarhitectură) e un procesor concret care respectă contractul. Același ISA poate avea implementări foarte diferite: un procesor de 3 lei într-un ceas și un procesor de server pot rula exact același cod mașină. x86 și ARM sunt ISA-uri; procesorul pe care îl scrii tu în laborator e o implementare a ISA-ului RISC-V.

*RISC-V* („risk-five”) e un ISA de tip RISC (_Reduced Instruction Set Computer_), *deschis*: oricine îl poate implementa fără licență. Principiile RISC pe care le vei vedea peste tot în lucrare:

- *toate instrucțiunile au aceeași lungime* (32 de biți), deci PC-ul crește mereu cu 4;
- *puține formate*, cu câmpurile la aceleași poziții (`opcode`, `rd`, `rs1`, `rs2`, `funct3` nu se mută niciodată), deci decodarea e doar „tăiere de fire”;
- *load/store*: doar `lw`/`sw` (și rudele lor) ating memoria; aritmetica se face numai între registre;
- *32 de registre* de uz general, `x0`...`x31`, cu `x0` legat permanent la 0.

== RV32I: ce procesor construim

RISC-V e modular: un nucleu obligatoriu plus extensii. *RV32I* e nucleul pe 32 de biți: date de 32 de biți, instrucțiuni de 32 de biți, registre de 32 de biți, doar operații cu *întregi*. Nu are înmulțire/împărțire (aceea e extensia `M`) și nici virgulă mobilă (`F`, `D`). Instrucțiunile din lucrare sunt toate RV32I:

#tabel(
  columns: (auto, 1fr),
  [*Categoria*], [*Instrucțiuni din lucrare*],
  [aritmetice/logice între registre (tip R)], [`add`, `and` (și rudele: `sub`, `or`, `xor`, `sll`, `srl`, `sra`, `slt`, `sltu`)],
  [aritmetice/logice cu o constantă (tip I)], [`addi`, `andi`, `ori`, `xori`, `slti`, `sltiu`, `slli`, `srli`, `srai`],
  [citire din memorie (tip I)], [`lw`],
  [scriere în memorie (tip S)], [`sw`],
  [salt condiționat (tip B)], [`beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu`],
)

== Pipeline-ul în 5 etape

O instrucțiune trece prin 5 pași. Într-un procesor *cu pipeline*, fiecare pas e o etapă hardware separată, iar între etape stau *registre de pipeline* care țin rezultatele unui pas până la următorul front de ceas. Ca la o spălătorie: cât se usucă o tură, alta se spală.

#tabel(
  columns: (auto, auto, 1fr),
  [*Etapa*], [*Nume*], [*Ce face*],
  [IF], [Instruction Fetch], [citește instrucțiunea de la adresa PC; calculează PC + 4],
  [ID], [Instruction Decode], [desface instrucțiunea în câmpuri, citește `rs1` și `rs2` din registre, construiește imediatul],
  [EX], [Execute], [ALU: calculează rezultatul sau adresa; decide dacă un salt se ia],
  [MEM], [Memory], [`lw` citește, `sw` scrie memoria de date],
  [WB], [Write Back], [scrie rezultatul în registrul `rd`],
)

#align(center, tabel(
  columns: 9,
  [*ciclul →*], [1], [2], [3], [4], [5], [6], [7], [8],
  [`add`], [IF], [ID], [EX], [MEM], [WB], [], [], [],
  [`addi`], [], [IF], [ID], [EX], [MEM], [WB], [], [],
  [`and`], [], [], [IF], [ID], [EX], [MEM], [WB], [],
  [`ori`], [], [], [], [IF], [ID], [EX], [MEM], [WB],
))

În ciclul 4 sunt 4 instrucțiuni în lucru deodată, fiecare în altă etapă. O instrucțiune durează tot 5 cicluri (latența), dar *la fiecare ciclu se termină una* (debitul), deci programul merge de până la ~5 ori mai repede.

Registrele de pipeline poartă numele celor două etape pe care le despart: *IF/ID*, *ID/EX*, *EX/MEM*, *MEM/WB*. În lucrarea asta îl scrii doar pe primul.

== Front-end-ul și semnalele „din viitor”

Lucrarea 2 construiește *front-end-ul*: partea care aduce și înțelege instrucțiunile (IF + ID). Lucrarea 3 adaugă *back-end-ul* (EX, MEM, WB), unitatea de control, unitatea de forwarding și unitatea de detecție a hazardurilor.

Unele intrări ale lui IF și ID vin, în procesorul complet, din etape care încă nu există. Le declari acum ca porturi, scrii logica lor, iar în simulare testbench-ul le ține la valori fixe:

#tabel(
  columns: (auto, 1fr, auto, auto),
  [*Semnal*], [*Cine îl va produce (Lucrarea 3)*], [*Ce înseamnă*], [*În testbench*],
  [`PC_write`], [unitatea de detecție a hazardurilor], [0 = PC-ul stă pe loc (stall)], [1],
  [`IF_ID_write`], [unitatea de detecție a hazardurilor], [0 = IF/ID își păstrează conținutul (stall)], [1],
  [`PCSrc`], [EX (saltul se ia sau nu)], [1 = următorul PC e `PC_Branch`], [0],
  [`PC_Branch`], [EX (sumatorul PC + imm)], [adresa de salt], [0],
  [`RegWrite_WB`], [WB (bitul de control `RegWrite`)], [1 = se scrie un registru], [0],
  [`RD_WB`], [WB (câmpul `rd` al instrucțiunii care se termină)], [în ce registru se scrie], [0],
  [`ALU_DATA_WB`], [WB (rezultatul ALU sau datele din memorie)], [ce valoare se scrie], [0],
)

Consecințele valorilor fixe, pe care le vei vedea în simulare:
- *nu se oprește nimic* (`PC_write = IF_ID_write = 1`): PC-ul crește cu 4 la fiecare ciclu;
- *nu se ia niciun salt* (`PCSrc = 0`): `beq x18,x0,5c` nu sare (și în procesorul complet n-ar sări: `x18 = 18 ≠ 0 = x0`);
- *nu se scrie niciun registru* (`RegWrite_WB = 0`): `x1` rămâne 1 chiar după `addi x1,x1,1`, fiindcă nimic nu duce rezultatul înapoi.

#prof[„De ce `x1` nu devine 2 după `addi x1,x1,1`?” Pentru că `addi` nu ajunge niciodată în EX și WB: lucrarea are doar IF și ID, iar `RegWrite_WB` e 0. Front-end-ul doar *citește* și *decodifică*.]
