#import "tpl.typ": *

= Harta lucrării

== Ce ai de făcut, într-o frază

Construiești în Verilog primele două etape ale unui procesor RISC-V cu pipeline: *IF* (aduce instrucțiunea din memorie) și *ID* (o desface în câmpuri, citește registrele și construiește constanta numită „imediat”), legate printr-un registru de pipeline, *IF/ID*. Semnalele care ar veni din etapele de mai târziu (EX, MEM, WB, unitatea de hazard) încă nu există, așa că le dă testbench-ul, cu valori fixe. La final codifici 7 instrucțiuni în hexa, le pui în memorie și verifici în simulare că ID le decodifică exact ca în Fig. 4.

== Cerințele, fișierele și modulele

#tabel(
  columns: (auto, 1fr, auto, auto),
  [*Cerința*], [*Ce se cere*], [*Modulul*], [*Fișierul*],
  [1a], [multiplexor 2:1 pe 32 de biți], [`mux2_1`], [`mux2_1.v`],
  [1b], [registrul PC (bistabil D cu reset și enable)], [`PC`], [`PC.v`],
  [1c], [memoria de instrucțiuni, citire asincronă, încărcată cu `$readmemh`], [`instruction_memory`], [`instruction_memory.v`],
  [1d], [sumator pe 32 de biți (PC + 4)], [`adder`], [`adder.v`],
  [2], [etapa IF: leagă cele 4 module], [`IF`], [`IF.v`],
  [3], [bancul de registre, simulat separat], [`registers`], [`registers.v` (+ `tb_registers.v`)],
  [4], [generatorul de imediate], [`imm_gen`], [`imm_gen.v`],
  [5], [etapa ID: câmpuri + registre + imediat], [`ID`], [`ID.v`],
  [6], [registrul de pipeline IF/ID], [`IF_ID_reg`], [`RISC_V_IF_ID.v`],
  [7], [modulul top: IF → IF/ID → ID], [`RISC_V_IF_ID`], [`RISC_V_IF_ID.v`],
  [8], [cele 7 instrucțiuni codificate], [—], [`code_stud.mem`],
  [—], [testbench-ul dat], [`RISC_V_TB`], [`test_riscv_stud.v`],
)

== Ierarhia: cine pe cine instanțiază

#align(center, block(fill: rgb("#f8f9f9"), inset: 10pt, radius: 3pt, stroke: 0.5pt + gri.lighten(50%))[
#set align(left)
#mono[
RISC_V_TB #text(fill: gri)[(testbench, fără porturi)]\
└── RISC_V_IF_ID #h(4pt) #text(fill: gri)[procesor (top, cerința 7)]\
#h(1.4em)├── IF #h(4pt) #text(fill: gri)[IF_STAGE (cerința 2)]\
#h(1.4em)│ #h(0.6em)├── mux2_1 #h(4pt) #text(fill: gri)[MUX_PC]\
#h(1.4em)│ #h(0.6em)├── PC #h(4pt) #text(fill: gri)[PC_REG]\
#h(1.4em)│ #h(0.6em)├── adder #h(4pt) #text(fill: gri)[ADD4]\
#h(1.4em)│ #h(0.6em)└── instruction_memory #h(4pt) #text(fill: gri)[INSTR_MEM ← code_stud.mem]\
#h(1.4em)├── IF_ID_reg #h(4pt) #text(fill: gri)[IF_ID_REGISTER (cerința 6)]\
#h(1.4em)└── ID #h(4pt) #text(fill: gri)[ID_STAGE (cerința 5)]\
#h(3.4em)├── registers #h(4pt) #text(fill: gri)[REG_FILE]\
#h(3.4em)└── imm_gen #h(4pt) #text(fill: gri)[IMM_GEN]
]])

Numele din dreapta (`IF_STAGE`, `PC_REG`, ...) sunt *numele instanțelor*: în Vivado, în fereastra „Scope” a simulatorului, le vezi exact așa și poți trage în forma de undă orice semnal dinăuntrul lor (de exemplu `procesor/IF_STAGE/PC_IF`, PC-ul din IF, care nu e ieșire a top-ului).

#idee[Un circuit în Verilog se construiește ca un Lego: module mici (mux, registru, sumator), apoi un modul care le *instanțiază* și le leagă cu fire (IF), apoi un modul care leagă etapele (top). Nimic nu „rulează” de sus în jos ca un program: toate modulele există și lucrează în paralel, tot timpul.]

== Cum arată totul, pe o pagină

#align(center, cetz.canvas(length: 0.62cm, {
  import cetz.draw: *
  let bx(a, b, t, f: white) = { rect(a, b, fill: f, stroke: 0.8pt); content(((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2), t) }
  // IF
  rect((-0.6, -3.6), (11.2, 4.4), stroke: (dash: "dashed", paint: gri), radius: 0.2)
  content((10.6, 4.0), text(9pt, fill: gri)[IF])
  bx((0, 0), (1.2, 2), [MUX], f: c-op)
  bx((2.4, 0), (3.8, 2), [PC], f: c-rd)
  bx((5.6, -0.6), (9.4, 2.6), [#set align(center); Memoria de\ instrucțiuni], f: c-f3)
  bx((3.2, 2.9), (4.8, 3.9), [+4], f: c-f7)
  line((1.2, 1), (2.4, 1), mark: (end: ">"))
  line((3.8, 1), (5.6, 1), mark: (end: ">"))
  content((4.7, 0.6), text(7pt)[PC\[11:2\]])
  line((3.1, 2), (3.1, 2.9), mark: (end: ">"))
  line((4.8, 3.4), (5.2, 3.4), (5.2, 4.2), (-0.3, 4.2), (-0.3, 1.5), (0, 1.5), mark: (end: ">"))
  content((2.4, 4.45), text(7pt)[PC + 4])
  line((-1.6, 0.5), (0, 0.5), mark: (end: ">"))
  content((-1.6, 0.1), text(7pt)[PC_Branch])
  line((0.6, -1.4), (0.6, 0), mark: (end: ">"))
  content((0.6, -1.8), text(7pt)[PCSrc])
  line((3.1, -1.4), (3.1, 0), mark: (end: ">"))
  content((3.1, -1.8), text(7pt)[PC_write])
  // IF/ID
  bx((12, -3.2), (13.4, 4.0), [#set align(center); IF\ /\ ID], f: c-rs2)
  line((9.4, 1), (12, 1), mark: (end: ">"))
  content((10.7, 1.35), text(7pt)[INSTR_IF])
  line((3.8, -0.3), (4.4, -0.3), (4.4, -2.6), (12, -2.6), mark: (end: ">"))
  content((8, -2.25), text(7pt)[PC_IF])
  line((12.7, -4.2), (12.7, -3.2), mark: (end: ">"))
  content((12.7, -4.6), text(7pt)[IF_ID_write])
  // ID
  rect((14.2, -3.6), (24.6, 4.4), stroke: (dash: "dashed", paint: gri), radius: 0.2)
  content((24.0, 4.0), text(9pt, fill: gri)[ID])
  bx((15.6, 0.4), (19.6, 3.2), [#set align(center); Registre\ (32 × 32 biți)], f: c-rs1)
  bx((15.6, -2.8), (19.6, -0.8), [Imm Gen], f: c-imm)
  line((13.4, 1), (14.8, 1), (14.8, 2.4), (15.6, 2.4), mark: (end: ">"))
  content((15, 3.0), text(7pt)[rs1, rs2])
  line((14.8, 1), (14.8, -1.8), (15.6, -1.8), mark: (end: ">"))
  line((19.6, 2.4), (21, 2.4), mark: (end: ">"))
  line((19.6, 1.2), (21, 1.2), mark: (end: ">"))
  content((22.6, 2.4), text(7pt)[REG_DATA1_ID])
  content((22.6, 1.2), text(7pt)[REG_DATA2_ID])
  line((19.6, -1.8), (21, -1.8), mark: (end: ">"))
  content((22.2, -1.8), text(7pt)[IMM_ID])
  content((22.8, -0.55), text(7pt)[OPCODE, RD, F3,\ RS1, RS2, F7])
  line((14.8, -0.2), (19.6, -0.2), (21, -0.2), mark: (end: ">"))
  line((17.6, 5.2), (17.6, 3.2), mark: (end: ">"))
  content((17.6, 5.6), text(7pt)[RegWrite_WB, RD_WB, ALU_DATA_WB])
}))

Săgețile din afara chenarelor punctate (`PC_Branch`, `PCSrc`, `PC_write`, `IF_ID_write`, cele trei `_WB`) sunt *semnalele din viitor*: în Lucrarea 3 le vor produce etapele EX, MEM, WB și unitatea de hazard; acum le dă testbench-ul (cap. 1.4).
