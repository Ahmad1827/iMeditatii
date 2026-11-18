#import "tpl.typ": *

= Simularea, ciclu cu ciclu

== Ce se întâmplă la fiecare front

Fronturile crescătoare sunt la 5, 15, 25, ... ns. Un rând al tabelelor de mai jos arată valorile *imediat după* frontul respectiv, valabile până la frontul următor. `PC_IF` și `INSTRUCTION_IF` sunt semnale interne (le găsești în Scope, sub `procesor/IF_STAGE`); restul sunt ieșirile top-ului, ca în Fig. 4. Toate valorile sunt în hexa.

#let rows = g.timeline.slice(0, 11)

#text(9pt)[
#tabel(
  columns: (auto, auto, auto, auto, auto, 1fr),
  [*front*], [*PC_IF*], [*INSTRUCTION_IF*], [*PC_ID*], [*INSTRUCTION_ID*], [*ID decodifică*],
  [0–5 ns], [`X`], [`X`], [`X`], [`X`], [nimic: registrele n-au primit încă valoare],
  ..rows.map(r => ([#r.t ns], mono(r.pc_if), mono(r.ins_if), mono(r.PC_ID), mono(r.INSTRUCTION_ID), mono(r.what))).flatten(),
)
]

#text(9pt)[
#tabel(
  columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
  [*front*], [*OPCODE*], [*RD*], [*FUNCT3*], [*RS1*], [*RS2*], [*FUNCT7*], [*IMM_ID*], [*REG_DATA1*], [*REG_DATA2*],
  ..rows.map(r => ([#r.t], mono(r.OPCODE_ID), mono(r.RD_ID), mono(r.FUNCT3_ID), mono(r.RS1_ID), mono(r.RS2_ID), mono(r.FUNCT7_ID), mono(r.IMM_ID), mono(r.REG_DATA1_ID), mono(r.REG_DATA2_ID))).flatten(),
)
]

De la 75 ns IF citește zerouri de după program, iar de la 85 ns și ID vede numai zerouri; PC-ul crește în continuare cu 4. Ultimul front, la #g.timeline.last().t ns, lasă #mono("PC_IF = 0x" + g.timeline.last().pc_if) și #mono("PC_ID = 0x" + g.timeline.last().PC_ID), apoi `$finish` oprește simularea la 210 ns.

== Cum se citește

- *0–5 ns*: niciun front încă. PC-ul și IF/ID n-au valoare: `X` (roșu în Vivado). Câmpurile din ID sunt și ele `X`, fiindcă vin din `INSTRUCTION_ID`. `REG_DATA1/2` sunt `X` din același motiv (adresa de citire e `X`).
- *5 ns* (front cu `reset = 1`): PC ← 0 și IF/ID ← 0. Memoria arată imediat `mem[0] = 00008133` pe `INSTRUCTION_IF`, dar ID vede încă instrucțiunea 0: toate câmpurile 0, `REG_DATA = x0 = 0`.
- *10 ns*: `reset` coboară (între fronturi: nu schimbă nimic pe loc).
- *15 ns*: IF/ID ← (`PC = 0`, `00008133`), PC ← 4. *ID decodifică `add`*: opcode `33`, `RD = 02`, `RS1 = 01` și `REG_DATA1 = 1` (din inițializarea `xi = i`).
- *25...65 ns*: câte o instrucțiune pe ciclu, în ordine: `addi` (25), `and` (35), `ori` (45), `sw` (55), `lw` (65).
- *75 ns*: ID e pe `beq` (`PC_ID = 0x18`): `IMM_ID = 0x5C`, `RS1 = 0x12`, `REG_DATA1 = 0x12`, `RD_ID = 0x1C`. Saltul *nu* se ia: `PCSrc` e 0.

#regula(t: "Întârzierea de un ciclu.")[IF/ID introduce exact un ciclu: instrucțiunea adusă în ciclul _n_ e decodificată în ciclul _n_ + 1. În forma de undă, `PC_ID` rămâne mereu cu 4 în urma lui `PC_IF`.]

== Verificarea pe Fig. 4

Fig. 4 din enunț are exact valorile din tabelele de mai sus. Câteva puncte de control, rapide:

#tabel(
  columns: (auto, 1fr, auto),
  [*la*], [*semnalul*], [*valoarea*],
  [15–25 ns], [`INSTRUCTION_ID`], [`00008133`],
  [35–45 ns], [`INSTRUCTION_ID` / `FUNCT3_ID`], [`0020F1B3` / `7`],
  [55–65 ns], [`OPCODE_ID` / `RD_ID` / `IMM_ID`], [`23` / `04` / `00000004`],
  [65–75 ns], [`RD_ID` / `IMM_ID` (`lw x12, 8(x0)`)], [`0C` / `00000008`],
  [75–85 ns], [`PC_ID` / `IMM_ID` / `REG_DATA1_ID` / `RS1_ID`], [`00000018` / `0000005C` / `00000012` / `12`],
)

#capcana[Dacă în Vivado vezi 51, 19, 35, 99 sau 92, valorile sunt în *zecimal*: 51 = `0x33`, 19 = `0x13`, 35 = `0x23`, 99 = `0x63`, 92 = `0x5C`. Click dreapta pe semnal → Radix → Hexadecimal, ca să arate ca Fig. 4.]

== Pașii în Vivado

+ Creează proiectul (RTL Project, fără surse la început) și adaugă ca *design sources*: `mux2_1.v`, `PC.v`, `adder.v`, `instruction_memory.v`, `IF.v`, `registers.v`, `imm_gen.v`, `ID.v`, `RISC_V_IF_ID.v`.
+ Adaugă ca *simulation sources*: `test_riscv_stud.v` și `code_stud.mem` (tipul „Memory File”). Opțional, `tb_registers.v`.
+ Simulation Sources → `RISC_V_TB` → Set as Top.
+ Run Simulation → Run Behavioral Simulation. Simularea se oprește singură la 210 ns (`$finish`); dacă nu vezi tot, apasă „Zoom Fit”.
+ Pune radixul pe hexa pentru magistrale. Ca să vezi PC-ul din IF, trage `procesor/IF_STAGE/PC_IF` din Scope în forma de undă și repornește simularea (Relaunch).

#vivado[Un singur modul pe nume în tot proiectul: dacă `RISC_V_IF_ID` apare în două fișiere (de exemplu o copie veche a top-ului), elaborarea dă eroare de modul definit de două ori. La fel pentru `IF_ID_reg`.]
