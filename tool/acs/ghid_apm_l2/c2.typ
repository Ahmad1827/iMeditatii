#import "tpl.typ": *

= Verilog-ul de care ai nevoie

Verilog *descrie hardware*. Nu e un program care se execută linie cu linie: fiecare `assign` și fiecare `always` e o bucată de circuit care există tot timpul și reacționează la semnalele ei. Ordinea lor în fișier nu contează.

== Module și porturi

```verilog
module adder(input [31:0] ina, inb, output [31:0] out);
    assign out = ina + inb;
endmodule
```

- `module ... endmodule`: o componentă, cu *porturi* (`input`, `output`).
- `[31:0]`: o magistrală de 32 de biți; bitul 31 e cel mai semnificativ, bitul 0 cel mai puțin semnificativ. Fără paranteze, portul are 1 bit.
- `input [31:0] ina, inb` declară *două* porturi de 32 de biți: lățimea se aplică tuturor numelor de după ea, până la următorul `input`/`output`. Asta e exact sursa bug-ului din top (cap. 7.4).

== `wire` și `reg`

#tabel(
  columns: (auto, 1fr, 1fr),
  [], [*`wire`*], [*`reg`*],
  [ce e], [un fir: nu ține minte nimic, are mereu valoarea a ceea ce îl conduce], [o variabilă căreia i se dă valoare într-un bloc `always` sau `initial`],
  [cum primește valoare], [`assign`, sau ieșirea unei instanțe], [`=` sau `<=` într-un `always`/`initial`],
  [devine hardware], [fir], [bistabil *dacă* blocul e `@(posedge clk)`; logică combinațională dacă blocul e `@(*)`],
)

#capcana[`reg` *nu* înseamnă „registru”. `instruction` din memorie și `out` din `imm_gen` sunt `output reg`, dar sunt pur combinaționale: `reg` e cerut doar de sintaxă, fiindcă primesc valoare într-un `always @(*)`.]

== `assign`, `always @(*)` și `always @(posedge clk)`

#tabel(
  columns: (auto, 1fr, auto),
  [*Construcția*], [*Ce circuit descrie*], [*Unde în lucrare*],
  [`assign y = expr;`], [logică combinațională: `y` urmează expresia instantaneu], [`mux2_1`, `adder`, câmpurile din ID, citirea registrelor],
  [`always @(*) begin ... end`], [tot combinațional, dar poți folosi `if`, `case`, `for`; `@(*)` = „la orice schimbare a oricărei intrări citite”], [`imm_gen`, citirea memoriei],
  [`always @(posedge clk) ...`], [logică secvențială: se actualizează *doar* pe frontul crescător al ceasului], [`PC`, `IF_ID_reg`, scrierea registrelor],
)

== `=` (blocant) și `<=` (neblocant)

- `a = b;` (blocant): se execută imediat, în ordine, ca într-un program. Se folosește în blocurile *combinaționale*.
- `a <= b;` (neblocant): toate atribuirile din același front se calculează din valorile *vechi* și se aplică *deodată*, la sfârșitul pasului de timp. Se folosește în blocurile *cu ceas*.

De ce contează: la frontul de ceas, `IF_ID_reg` trebuie să ia PC-ul *de dinainte* de front, iar PC-ul trebuie să ia PC + 4 calculat tot din valoarea de dinainte. Cu `<=` peste tot, toate registrele „fotografiază” intrările în aceeași clipă, exact ca bistabilele reale. Cu `=` în blocuri cu ceas, rezultatul ar depinde de ordinea în care simulatorul evaluează blocurile: o cursă (_race_).

#regula[Bloc cu `posedge clk` → `<=`. Bloc `@(*)` → `=`. Nu le amesteca în același bloc.]

== Reset sincron și enable

```verilog
always @(posedge clk) begin
    if (res)        out <= 32'b0;   // reset: are prioritate
    else if (write) out <= in;      // enable: încarcă doar dacă write = 1
end                                 // altfel: nimic, out își păstrează valoarea
```

Resetul e *sincron*: e verificat doar pe front. Dacă ar fi fost asincron, lista de sensibilitate ar fi fost `@(posedge clk or posedge res)`. Când nici `res`, nici `write` nu sunt 1, nu se atribuie nimic, iar un `reg` își *ține* valoarea: asta e memoria bistabilului, și aici e exact ce vrem (stall).

== Latch-ul nedorit

Într-un `always @(*)`, dacă există un drum prin cod pe care ieșirea *nu* primește valoare, ea trebuie să-și țină valoarea veche, iar sinteza pune un *latch* (o memorie declanșată pe nivel): aproape mereu o greșeală. De aceea `case`-ul din `imm_gen` are `default`, iar `if`-ul din ramura `0010011` are `else`: pe orice drum, `out` primește ceva.

== Numere, tăieturi, concatenare, replicare

#tabel(
  columns: (auto, 1fr),
  [*Scriere*], [*Înțeles*],
  [`32'b0`], [32 de biți, toți 0 (`b` = binar)],
  [`32'd4`], [valoarea 4 pe 32 de biți (`d` = zecimal)],
  [`7'b0110011`], [7 biți, scris bit cu bit: opcode-ul de tip R],
  [`32'h00008133`], [32 de biți în hexa],
  [`in[31]`], [un singur bit],
  [`in[11:7]`], [biții 11, 10, 9, 8, 7 (5 biți): o *tăietură* (part-select)],
  [`{a, b}`], [*concatenare*: `a` în biții de sus, `b` în cei de jos],
  [`{20{in[31]}}`], [*replicare*: bitul `in[31]` repetat de 20 de ori],
  [`{{20{in[31]}}, in[31:20]}`], [20 de copii ale bitului de semn, apoi cei 12 biți: extensia de semn la 32 de biți],
)

== Memorii, `initial`, `for` și `$readmemh`

```verilog
reg [31:0] codeMemory [0:1023];   // 1024 de cuvinte, fiecare de 32 de biți
```

Prima paranteză e lățimea unui cuvânt, a doua e numărul de cuvinte (adresele 0...1023).

Un bloc `initial` rulează *o singură dată*, la timpul 0 al simulării. Cu un `for` și o variabilă `integer` inițializezi memoria; `$readmemh("fișier", memorie)` citește un fișier text cu câte un număr hexa pe linie și îl pune în memorie de la adresa 0 în sus. Locațiile pe care fișierul nu le atinge rămân cum erau (de aceea le pui pe toate pe 0 înainte).

#capcana[`initial`, `for`-ul de inițializare și `$readmemh` sunt construcții de *simulare*. Pe FPGA, conținutul inițial al unei memorii se dă altfel (fișiere de inițializare pentru block RAM); unele unelte acceptă totuși `$readmemh` la sinteză.]

== Instanțierea: pe nume și pe poziție

```verilog
adder ADD4(.ina(PC_IF), .inb(32'd4), .out(PC_plus4));   // pe nume
RISC_V_IF_ID procesor(clk, reset, IF_ID_write, ...);     // pe poziție
```

- *Pe nume* (`.port(semnal)`): ordinea nu contează, o greșeală de ordine nu poate încurca firele. Tu ai folosit-o peste tot.
- *Pe poziție*: al k-lea semnal merge la al k-lea port din declarația modulului. Testbench-ul dat folosește poziția, deci *ordinea porturilor din top trebuie să fie exact cea din enunț*.

== Valorile `X` și `Z`

Un semnal Verilog are 4 valori: `0`, `1`, `X` (necunoscut) și `Z` (neconectat, impedanță mare). Un `reg` începe în `X` până primește o valoare. Vivado desenează `X` cu roșu. `Z` pe o intrare (un port uitat neconectat) se propagă de obicei ca `X` prin logică.

== `timescale` și întârzierile

#raw("`timescale 1ns / 1ps") spune că `#1` înseamnă o nanosecundă (cu precizie de o picosecundă). În testbench, `always #5 clk = ~clk;` inversează ceasul la fiecare 5 ns: perioadă 10 ns, adică 100 MHz. Fronturile crescătoare sunt la 5, 15, 25, ... ns, pentru că ceasul pornește din 0.
