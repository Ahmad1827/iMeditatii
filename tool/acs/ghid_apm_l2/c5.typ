#import "tpl.typ": *

= Generatorul de imediate (cerința 4)

Multe instrucțiuni poartă o constantă, *imediatul*, împrăștiată în cei 32 de biți. `imm_gen` o adună la loc și o *extinde cu semn* la 32 de biți, ca EX s-o poată aduna direct la un registru sau la PC.

#sursa("imm_gen.v", read("src/imm_gen.v"))

== Linie cu linie

- 13–14: `opcode` și `funct3` sunt fire declarate și atribuite în aceeași linie (`wire [6:0] opcode = in[6:0];` e prescurtarea pentru `wire` + `assign`).
- 16: `always @(*)` cu `=`: combinațional.
- 17: `case (opcode)`: alege formula după opcode.
- 18–19, *`lw`*: format I. `{{20{in[31]}}, in[31:20]}` = 20 de copii ale bitului de semn, apoi cei 12 biți ai imediatului.
- 21–25, *opcode `0010011`*: aceeași formulă, *cu o excepție*: deplasările (`funct3 = 001` pentru `slli`, `101` pentru `srli`/`srai`) au imediatul `shamt = in[24:20]`, 5 biți, extins cu zero.
- 27–28, *`sw`*: format S. Biții de sus `in[31:25]` (imm\[11:5\]) lipiți de cei de jos `in[11:7]` (imm\[4:0\]), cu semn.
- 30–31, *salturile*: format B. `{19{in[31]}}` + `in[31]` (imm\[12\]) + `in[7]` (imm\[11\]) + `in[30:25]` (imm\[10:5\]) + `in[11:8]` (imm\[4:1\]) + `1'b0` (imm\[0\]). Total: 19 + 1 + 1 + 6 + 4 + 1 = 32 de biți.
- 33–34, *`default`*: orice alt opcode (tip R, dar și U, J, `jalr`) dă 0. Fără `default`, `out` ar fi un latch (cap. 2.6).

== Extensia de semn

Un imediat de 12 biți în complement față de 2 acoperă −2048...2047. Ca să păstreze aceeași valoare pe 32 de biți, biții noi de sus trebuie să fie *copii ale bitului de semn*:

#tabel(
  columns: (auto, auto, auto, auto),
  [*valoarea*], [*pe 12 biți*], [*extins cu semn (corect)*], [*extins cu zero (greșit)*],
  [1], [`0x001`], [`0x00000001`], [`0x00000001`],
  [−1], [`0xFFF`], [`0xFFFFFFFF`], [`0x00000FFF` = 4095],
  [−12], [`0xFF4`], [`0xFFFFFFF4`], [`0x00000FF4` = 4084],
  [2047], [`0x7FF`], [`0x000007FF`], [`0x000007FF`],
  [−2048], [`0x800`], [`0xFFFFF800`], [`0x00000800` = 2048],
)

În RISC-V bitul de semn e *mereu* `in[31]`, la toate formatele cu imediat. De aceea toate ramurile din `imm_gen` replică același bit.

== De ce deplasările sunt speciale

`slli`, `srli`, `srai` deplasează un număr de 32 de biți cu cel mult 31 de poziții: le ajung 5 biți (`shamt`, biții 24:20). Biții 31:25 nu sunt imediat, ci un `funct7`: `0000000` pentru `srli`, `0100000` pentru `srai`. Dacă `srai x10,x11,3` ar fi tratat ca un I obișnuit, imediatul ar ieși `0x403` = 1027, nu 3. De aceea ramura citește `funct3` și ia doar `shamt`.

== De ce B se termină cu `1'b0` („Shift left 1”)

Adresele de salt sunt mereu pare (instrucțiunile sunt aliniate cel puțin la 2 octeți în RISC-V), deci bitul 0 al deplasamentului e mereu 0 și nu se stochează. Cei 12 biți din instrucțiune sunt imm\[12:1\], iar raza crește la ±4 KB. În Fig. 3 din enunț scrie „Shift left 1 se va face în modulul IMM Gen”: `1'b0` lipit la coadă *este* deplasarea la stânga cu 1. Rezultatul: `IMM_ID` pentru `beq` e deja deplasamentul în octeți (`0x5C`), gata de adunat la PC în EX.

== Toate instrucțiunile cerute, cu exemple

Coloana „`IMM_ID`” e ce scoate modulul tău; „valoarea” e imediatul cu semn, în zecimal.

#tabel(
  columns: (auto, auto, auto, auto, auto),
  [*instrucțiunea*], [*cuvântul*], [*format*], [*`IMM_ID`*], [*valoarea*],
  ..g.imm.map(d => (
    mono(d.text), mono(d.hex), [#d.fmt], mono(d.imm_gen),
    if d.spec_imm == none [—] else if d.fmt in ("U", "J") or d.text.starts-with("jalr") [#text(fill: rosu)[ISA: #d.spec_imm]] else [#d.spec_imm],
  )).flatten(),
)

#capcana[Ultimele rânduri: `lui`, `jal` și `jalr` *nu* sunt în lista cerinței, iar modulul tău dă 0 pentru ele (ramura `default`), deși ISA-ul le dă un imediat (în roșu). E corect pentru Lucrarea 2. Dacă în Lucrarea 3 adaugi `jal`/`lui`, trebuie ramuri noi: U = `{in[31:12], 12'b0}`, J = `{{11{in[31]}}, in[31], in[19:12], in[20], in[30:21], 1'b0}`, iar `jalr` (opcode `1100111`) ca `lw`.]

== Un exemplu desfăcut complet: `bne x1, x2, -4`

#instr(g.imm.at(14))

- `in[31] = 1`: imediatul e negativ, deci cei 19 biți de sus sunt 1.
- `in[7] = 1` (imm\[11\]), `in[30:25] = 111111` (imm\[10:5\]), `in[11:8] = 1110` (imm\[4:1\]), plus `0`.
- Pe 13 biți: `1 1 111111 1110 0` = `1111111111100` = −4. Pe 32 de biți: `0xFFFFFFFC`.
- Sensul: „dacă `x1 ≠ x2`, întoarce-te cu o instrucțiune” (o buclă).
