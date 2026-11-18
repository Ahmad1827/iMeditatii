#import "tpl.typ": *

= Greșeli tipice și cum le găsești

#tabel(
  columns: (1fr, 1fr, 1fr),
  [*Ce vezi*], [*De ce*], [*Ce faci*],
  [`X` roșu la 0–5 ns], [normal: niciun front încă, PC și IF/ID n-au valoare], [nimic],
  [`X` tot timpul pe PC], [`reset` nu ajunge la PC (portul `res` neconectat): PC-ul nu primește niciodată 0, iar `X + 4` rămâne `X`], [verifică `.res(reset)`],
  [PC rămâne 0 după reset], [`PC_write` neconectat sau `X`: `if (write)` cu `X` nu încarcă nimic], [verifică `.write(PC_write)` și testbench-ul],
  [`INSTRUCTION_ID` mereu `00000000`, PC crește corect], [`code_stud.mem` nu e găsit (vezi _warning_-ul din Tcl Console), deci memoria e plină de 0], [adaugă fișierul ca simulation source, tip Memory File],
  [`XXXXXXXX` după ultima instrucțiune], [lipsește `for`-ul care pune 0 în memorie], [inițializează memoria înainte de `$readmemh`],
  [ID decodifică instrucțiunile 0, 4, 8, ... din fișier (sare peste trei)], [memoria e adresată cu `PC[9:0]` în loc de `PC[11:2]`], [`.address(PC_IF[11:2])`],
  [instrucțiunile apar în ID în același ciclu în care le aduce IF], [lipsește registrul IF/ID sau e combinațional], [`always @(posedge clk)` cu `<=`],
  [PC sare cu 2 pași sau rezultatul depinde de ordine], [`=` în loc de `<=` în blocuri cu ceas], [`<=` în toate blocurile `posedge`],
  [semnalele de ieșire sunt amestecate (`PC_ID` arată instrucțiunea etc.)], [ordinea porturilor top-ului diferă de enunț (testbench-ul e pe poziție), sau un port în plus ca `ALU_DATA, WB`], [copiază semnătura din enunț],
  [`IMM_ID` pentru `srai` e `0x403`], [deplasările tratate ca I obișnuit], [ramura cu `funct3 == 001 / 101` → `shamt`],
  [`IMM_ID` pentru `beq` e `0x2E` (jumătate)], [lipsește `1'b0` de la coadă], [`{..., in[11:8], 1'b0}`],
  [`IMM_ID` pentru imediate negative e mic și pozitiv (`0x00000FFF`)], [extensie cu zero în loc de semn], [`{20{in[31]}}`],
  [warning „latch inferred” la sinteză], [o ramură din `always @(*)` nu atribuie ieșirea], [`default` în `case`, `else` la `if`],
  [eroare „module already defined”], [același modul în două fișiere], [un singur fișier per modul (sau o singură copie)],
  [`REG_DATA` nu e egal cu numărul registrului], [lipsește inițializarea `regs[i] = i`], [blocul `initial` cu `for`],
  [`x0` devine nenul după o scriere], [lipsește condiția `write_reg != 0`], [`if (reg_write && write_reg != 5'd0)`],
)

== Cum depanezi în Vivado

- Trage în forma de undă și semnalele *interne*: `IF_STAGE/PC_IF`, `IF_STAGE/PC_next`, `IF_STAGE/INSTRUCTION_IF`, `ID_STAGE/REG_FILE/regs`. Apoi Relaunch Simulation.
- Uită-te întâi la PC: dacă el e corect, problema e după el (memorie, IF/ID, ID); dacă nu, e în buclă (MUX, sumator, PC).
- Citește _Messages_ după elaborare: avertismentele despre porturi cu lățimi diferite („port width mismatch”) și despre porturi neconectate arată aproape mereu bug-uri reale.
- Verifică la mână o singură instrucțiune: ia hexa din `INSTRUCTION_ID`, scrie-o în binar și taie câmpurile ca în capitolul 4.
