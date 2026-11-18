#import "tpl.typ": *

= Foaie de memorat

#set text(9.5pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
[
*Formatele* (biții 31 → 0)
#tabel(
  columns: (auto, 1fr),
  [R], [funct7 · rs2 · rs1 · f3 · rd · op],
  [I], [imm\[11:0\] · rs1 · f3 · rd · op],
  [S], [imm\[11:5\] · rs2 · rs1 · f3 · imm\[4:0\] · op],
  [B], [\[12\]\[10:5\] · rs2 · rs1 · f3 · \[4:1\]\[11\] · op],
  [U], [imm\[31:12\] · rd · op],
  [J], [\[20\]\[10:1\]\[11\]\[19:12\] · rd · op],
)
*Pozițiile fixe*: op 6:0, rd 11:7, f3 14:12, rs1 19:15, rs2 24:20, f7 31:25. Semnul: mereu bitul 31.

*Opcode-uri*: R `0110011` (33) · I `0010011` (13) · lw `0000011` (03) · sw `0100011` (23) · B `1100011` (63) · jalr `1100111` (67) · lui `0110111` (37) · auipc `0010111` (17) · jal `1101111` (6F).

*funct3*: add/addi/beq `000` · sll/bne `001` · slt/lw/sw `010` · sltu `011` · xor/blt `100` · srl/sra/bge `101` · or/bltu `110` · and/bgeu `111`.

*funct7*: `0000000`; `0100000` pentru sub, sra, srai.

*`imm_gen`*
- I: `{{20{in[31]}}, in[31:20]}`
- shift: `{27'b0, in[24:20]}`
- S: `{{20{in[31]}}, in[31:25], in[11:7]}`
- B: `{{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1'b0}`
- altfel: `0`
],
[
*Programul din lucrare*
#tabel(
  columns: (auto, auto, auto),
  [*PC*], [*instrucțiunea*], [*hexa*],
  ..g.lab.enumerate().map(((i, d)) => ([#mono("0x" + str(i * 4, base: 16))], mono(d.text), mono(d.hex))).flatten(),
)

*IF*: MUX(`PCSrc`: 0 → PC+4, 1 → `PC_Branch`) → PC (reset sincron → 0, `PC_write` = enable) → memorie (`PC[11:2]`, asincronă, `$readmemh`) → `INSTRUCTION_IF`.

*IF/ID*: pe front, cu reset → 0, cu `IF_ID_write` → ia (`PC_IF`, `INSTRUCTION_IF`), altfel ține.

*ID*: câmpuri = tăieturi; registre: 2 citiri asincrone (`rs1`, `rs2`), 1 scriere sincronă (din WB), `x0 = 0`, `xi = i` la început; `imm_gen`.

*Testbench*: ceas 10 ns, fronturi la 5, 15, ...; reset până la 10 ns (prinde frontul de la 5); `$finish` la 210 ns; `PC_write = IF_ID_write = 1`, `PCSrc = 0`, `RegWrite_WB = 0`.

*Timpii*: `add` în ID la 15 ns, apoi câte una la 10 ns; `beq` la 75 ns (`PC_ID = 0x18`, `IMM_ID = 0x5C`, `RD_ID = 0x1C`). `PC_ID` = `PC_IF` − 4.

*Verilog*: `<=` în `posedge`, `=` în `@(*)`; `reg` ≠ registru; `default` contra latch; porturile top-ului în ordinea din enunț (testbench pe poziție).
],
)
