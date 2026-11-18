#import "tpl.typ": *

= Etapa ID, registrul IF/ID și modulul top (cerințele 5, 6, 7)

== Cerința 5 · Modulul ID

#sursa("ID.v", read("src/ID.v"))

*Câmpurile (liniile 26–31).* Doar fire: fiecare `assign` e o tăietură din instrucțiune, fără nicio poartă logică.

#tabel(
  columns: (auto, auto, auto, 1fr),
  [*ieșirea*], [*biții*], [*lățimea*], [*la ce folosește mai târziu*],
  [`OPCODE_ID`], [6:0], [7], [unitatea de control: tipul instrucțiunii],
  [`RD_ID`], [11:7], [5], [registrul destinație, dus prin pipeline până la WB],
  [`FUNCT3_ID`], [14:12], [3], [controlul ALU, tipul de salt, lățimea lui load/store],
  [`RS1_ID`], [19:15], [5], [adresa de citire 1; unitatea de forwarding],
  [`RS2_ID`], [24:20], [5], [adresa de citire 2; unitatea de forwarding],
  [`FUNCT7_ID`], [31:25], [7], [deosebește `add`/`sub`, `srl`/`sra`],
)

ID taie *toate* câmpurile, oricare ar fi formatul. Pentru `sw`, `RD_ID` e de fapt imm\[4:0\] (de aceea Fig. 4 arată `RD_ID = 04` la `sw x4,4(x5)`); pentru `addi`, `RS2_ID` și `FUNCT7_ID` sunt bucăți din imediat. E în regulă: unitatea de control din Lucrarea 3 decide, după opcode, ce câmpuri contează (de exemplu `RegWrite = 0` pentru `sw`, deci `rd` e ignorat).

*Bancul de registre (liniile 33–42).* Adresele de citire vin din instrucțiunea curentă (`RS1_ID`, `RS2_ID`). Partea de scriere vine din *WB* (`RegWrite_WB`, `RD_WB`, `ALU_DATA_WB`), *nu* din instrucțiunea curentă: instrucțiunea care se scrie acum în registre a intrat în pipeline cu 3 cicluri mai devreme.

*`imm_gen` (liniile 44–47)* primește toată instrucțiunea și dă `IMM_ID`.

*`PC_ID`* e intrare, dar ID nu-l folosește încă. În procesorul complet merge mai departe, prin ID/EX, la EX, unde se calculează adresa de salt `PC_ID + IMM_ID`.

#prof[„Ce e `clk` în ID?” Doar pentru scrierea în bancul de registre. Tot restul lui ID e combinațional.]

== Cerința 6 · Registrul de pipeline IF/ID

Este al doilea modul din `RISC_V_IF_ID.v` (un fișier Verilog poate conține mai multe module):

#sursa("RISC_V_IF_ID.v (partea a doua)", "// Cerinta 6" + read("src/RISC_V_IF_ID.v").split("// Cerinta 6").at(1))

- Ține două valori de 32 de biți: PC-ul și instrucțiunea.
- Pe front: cu `res = 1` le pune pe 0; altfel, dacă `write = 1`, le ia de la IF; dacă `write = 0`, le păstrează.
- *De ce e nevoie de el*: PC-ul se schimbă la fiecare ciclu. Fără IF/ID, ID ar vedea mereu instrucțiunea pe care IF o aduce *chiar acum*, și n-ar avea un ciclu întreg să lucreze pe ea. Cu IF/ID, ID lucrează pe instrucțiunea adusă *în ciclul trecut*, iar IF o aduce deja pe următoarea: asta e paralelismul pipeline-ului.
- *Instrucțiunea 0 după reset*: un cuvânt plin de 0 are opcode `0000000`, care nu e o instrucțiune RV32I; decodorul tău scoate 0 peste tot pentru el. Funcționează ca o „bulă” (nicio operație).
- *`write` (`IF_ID_write`)*: 0 = stall. Lucrează împreună cu `PC_write`: când unitatea de hazard le pune pe amândouă pe 0, PC-ul și IF/ID îngheață, iar aceeași instrucțiune mai stă un ciclu în ID.

#idee[În procesorul complet IF/ID mai are nevoie de un *flush* (golire): când se ia un salt, instrucțiunea deja adusă de pe calea greșită trebuie transformată în bulă (`IF.Flush` din Fig. 1). Asta e Lucrarea 3.]

== Cerința 7 · Modulul top

#sursa("RISC_V_IF_ID.v (partea întâi)", read("src/RISC_V_IF_ID.v").split("// Cerinta 6").at(0).trim())

- Firele interne `PC_IF` și `INSTRUCTION_IF` leagă IF de IF/ID.
- `PC_ID` și `INSTRUCTION_ID` sunt ieșiri ale lui IF/ID, intrări ale lui ID și, în același timp, *ieșiri ale top-ului*: un port de ieșire e și el un fir, care poate merge în mai multe locuri.
- `clk` și `reset` sunt globale („semnale unice la nivelul pipe-ului”) și ajung la tot ce are stare: PC, IF/ID, bancul de registre.
- Toate instanțierile sunt pe nume: sigur, nu depinde de ordinea porturilor.
- *Ordinea porturilor top-ului* e exact cea din enunț, pentru că testbench-ul îl instanțiază *pe poziție* (cap. 2.9).

== Bug-ul din varianta inițială a top-ului

Varianta de pornire avea:

```verilog
input [31:0] ALU_DATA, WB,     // GREȘIT: două porturi, „ALU_DATA” și „WB”
```

în loc de

```verilog
input [31:0] ALU_DATA_WB,      // CORECT: un port
```

Virgula a făcut din `ALU_DATA_WB` *două* porturi de 32 de biți. Top-ul avea un port în plus, iar testbench-ul, care leagă pe poziție, ar fi pus fiecare semnal de după acel loc pe portul următor: `RD_WB` pe `WB`, `PC_ID` pe `RD_WB`, și așa mai departe, cu lățimi nepotrivite (Vivado dă doar _warning_-uri pentru asta). În plus, corpul modulului era gol, deci nimic nu era legat. Varianta de acum: un singur port `ALU_DATA_WB` și cele trei instanțe legate.

== Testbench-ul dat

#sursa("test_riscv_stud.v", read("src/test_riscv_stud.v"))

- Un testbench *nu are porturi*: e „lumea de afară”. Ce conduce el e `reg`; ce doar privește e `wire`.
- 21–37: instanțierea top-ului *pe poziție*: de aici vine importanța ordinii porturilor.
- 39: `always #5 clk=~clk;`: perioadă 10 ns, fronturi crescătoare la 5, 15, 25, ... ns.
- 41–51: la timpul 0, `reset = 1` și toate semnalele „din viitor” pe valorile fixe (cap. 1.4).
- 53: `#10 reset=1'b0;`: resetul ține 10 ns, deci prinde *un singur* front (cel de la 5 ns).
- 54: `#200 $finish;`: simularea se oprește la 210 ns.

#capcana[Testbench-ul nu are #raw("`timescale"); top-ul are #raw("`timescale 1ns / 1ps"). În Vivado fișierele fără directivă primesc implicit 1ns/1ps, deci totul e consecvent. Cu alte simulatoare (Icarus), lipsa poate da un avertisment sau altă unitate de timp: pune aceeași linie și la începutul testbench-ului.]
