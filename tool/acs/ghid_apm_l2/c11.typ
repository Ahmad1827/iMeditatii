#import "tpl.typ": *

= Exerciții rezolvate

Acoperă rezolvarea, fă exercițiul pe hârtie, apoi verifică. Toate răspunsurile sunt calculate de modelul circuitului.

== Codificare: din asamblare în hexa

#for d in g.practice {
  problema(none, [Codifică #mono(d.text) (format #d.fmt).], [
    #instr(d)
    #if d.fmt == "B" [Deplasamentul #d.spec_imm se scrie pe 13 biți în complement față de 2; bitul 0 nu se stochează.]
    #if d.fmt == "S" [`rs2` e registrul scris în memorie, `rs1` e baza; imediatul #d.spec_imm se împarte în imm\[11:5\] și imm\[4:0\].]
    #if d.text.starts-with("srai") [`funct7 = 0100000` deosebește `srai` de `srli`; `shamt = 31` în biții 24:20.]
    #if d.text.starts-with("andi") [−16 pe 12 biți = `0xFF0`: o mască ce șterge cei 4 biți de jos.]
    #if d.text.starts-with("lw x6,0x40") [Deplasamentul `0x40` = 64.]
    `IMM_ID` dat de `imm_gen`: #mono("0x" + d.imm_gen).
  ])
}

== Decodificare: din hexa în asamblare

#for d in g.words {
  problema(none, [Ce instrucțiune este #mono("0x" + d.hex)? Ce arată `OPCODE_ID`, `RD_ID`, `RS1_ID`, `RS2_ID`, `FUNCT3_ID`, `FUNCT7_ID` și `IMM_ID` când e în ID?], [
    #instr(d, titlu: "0x" + d.hex)
    Este #mono(d.decoded). Ieșirile lui ID (hexa): `OPCODE` #mono(str(d.fields.opcode, base: 16)), `RD` #mono(str(d.fields.rd, base: 16)), `RS1` #mono(str(d.fields.rs1, base: 16)), `RS2` #mono(str(d.fields.rs2, base: 16)), `FUNCT3` #mono(str(d.fields.funct3, base: 16)), `FUNCT7` #mono(str(d.fields.funct7, base: 16)), `IMM_ID` #mono(d.imm_gen)#if d.fmt in ("U", "J") [ (ramura `default`: `imm_gen` din lucrare nu tratează #d.fmt; ISA-ul ar da #d.spec_imm)].
  ])
}

== Pipeline și semnale

#problema(none, [Programul din lucrare, cu testbench-ul dat. Ce valori au `PC_ID` și `INSTRUCTION_ID` în intervalul 45–55 ns? Dar `PC_IF`?], [
  Frontul de la 45 ns e al cincilea (5, 15, 25, 35, 45), al patrulea fără reset. IF/ID primește ce era în IF înainte de front: `PC_ID = 0x0C`, `INSTRUCTION_ID = 0x0010E213` (`ori x4,x1,1`). PC-ul din IF trece la `0x10`.
])

#problema(none, [În testbench se schimbă `PC_write` și `IF_ID_write` pe 0 între 30 și 40 ns (deci la frontul de la 35 ns). Ce instrucțiune e în ID între 25 și 45 ns?], [
  La 25 ns ID primește `addi` (PC 4), iar PC-ul trece la 8. La 35 ns nici PC-ul, nici IF/ID nu se încarcă: ID ține tot `addi`, PC-ul rămâne 8. La 45 ns totul merge iar: ID primește `and` (PC 8). Deci `addi` stă în ID 20 ns (două cicluri): un stall de un ciclu, exact ce va cere unitatea de hazard.
])

#problema(none, [În același testbench se pune `PCSrc = 1` și `PC_Branch = 0x0` între 40 și 50 ns. Ce se întâmplă?], [
  La frontul de la 45 ns, MUX-ul alege `PC_Branch`, deci PC-ul devine 0 în loc de `0x10`. IF/ID primește totuși, la același front, instrucțiunea care era în IF (`ori`, PC `0x0C`). Apoi programul o ia de la capăt: la 55 ns ID vede `add` (PC 0). (În procesorul complet, instrucțiunea adusă greșit ar fi golită prin `IF.Flush`.)
])

#problema(none, [Testbench-ul face `RegWrite_WB = 1`, `RD_WB = 5`, `ALU_DATA_WB = 0x100` între 40 și 50 ns. Ce arată `REG_DATA1_ID` la instrucțiunea `sw x4,4(x5)`?], [
  Scrierea se face la frontul de la 45 ns. `sw` intră în ID la 55 ns și citește `rs1 = x5`, care acum e `0x100`: `REG_DATA1_ID = 0x00000100` (în loc de 5). `REG_DATA2_ID` (`x4`) rămâne 4.
])

#problema(none, [Aceeași scriere, dar cu `RD_WB = 0`. Ce se schimbă?], [
  Nimic: scrierea în `x0` e ignorată, iar `x0` rămâne 0.
])

#problema(none, [Ce index de memorie folosesc PC-urile `0x7C`, `0x400`, `0xFFC` și `0x1004`?], [
  `PC[11:2]`: `0x7C` → 31; `0x400` → 256; `0xFFC` → 1023; `0x1004` → 1 (bitul 12 se ignoră: memoria „se învârte” la 4 KB).
])

#problema(none, [Câte cicluri după reset ajunge `beq` în ID? La ce timp?], [
  E a 7-a instrucțiune (PC `0x18`). Primul front fără reset (15 ns) aduce `add` în ID; `beq` vine cu 6 fronturi mai târziu, la 75 ns.
])
