#import "tpl.typ": *

= Etapa IF (cerințele 1 și 2)

IF are o singură treabă: la fiecare ciclu, să dea etapei ID instrucțiunea de la adresa PC și să pregătească adresa următoare. Are patru piese: multiplexorul, registrul PC, sumatorul și memoria de instrucțiuni.

== Cerința 1a · Multiplexorul 2:1

#sursa("mux2_1.v", read("src/mux2_1.v"))

*Linie cu linie.*
- 5–8: două intrări de date de 32 de biți, o intrare de selecție de 1 bit, o ieșire de 32 de biți. Semnătura e exact cea din enunț.
- 10: operatorul condițional `sel ? inb : ina` („dacă `sel`, atunci `inb`, altfel `ina`”). Un `assign`, deci combinațional: ieșirea urmează intrările fără ceas.

#tabel(
  columns: (auto, auto, 1fr),
  [*`sel` (`PCSrc`)*], [*`out`*], [*În IF înseamnă*],
  [0], [`ina` = PC + 4], [mergi la instrucțiunea următoare],
  [1], [`inb` = `PC_Branch`], [un salt s-a luat: mergi la adresa calculată în EX],
)

Hardware: 32 de multiplexoare de câte 1 bit, puse unul lângă altul, toate cu același `sel`.

#prof[„Ce se întâmplă dacă `sel` e `X`?” În simulare, `?:` cu condiția `X` dă `X` pe biții unde `ina` și `inb` diferă. În testbench `PCSrc = 0` de la timpul 0, deci nu apare.]

== Cerința 1b · Registrul PC

#sursa("PC.v", read("src/PC.v"))

*Linie cu linie.*
- 9: `output reg`, pentru că `out` primește valoare într-un `always` (enunțul o cere așa).
- 11: `always @(posedge clk)`: totul se întâmplă doar pe frontul crescător. Rezultatul e un *registru* (32 de bistabile D).
- 12–13: *resetul sincron, cu prioritate*: pe un front cu `res = 1`, PC devine 0, oricare ar fi `write`. Programul începe de la adresa 0.
- 14–15: *enable*: doar dacă `write = 1` registrul încarcă `in`. Dacă `write = 0`, nicio atribuire, deci PC-ul *își păstrează valoarea*: asta e un *stall*, cerut în Lucrarea 3 de unitatea de hazard (de exemplu când o instrucțiune folosește rezultatul unui `lw` din ciclul imediat anterior).
- `<=`: neblocant, ca orice registru (cap. 2.4).

#tabel(
  columns: (auto, auto, auto, 1fr),
  [*front cu*], [*`res`*], [*`write`*], [*PC după front*],
  [], [1], [orice], [0],
  [], [0], [1], [`in` (adică PC + 4 sau `PC_Branch`)],
  [], [0], [0], [neschimbat (stall)],
)

#capcana[Înainte de primul front PC-ul n-a primit nicio valoare: e `X`. De aceea Fig. 4 începe cu `XXX...` roșu până la 5 ns. Nu e o greșeală: e normal pentru un registru cu reset sincron.]

== Cerința 1d · Sumatorul

#sursa("adder.v", read("src/adder.v"))

În IF calculează `PC + 4`. De ce 4: o instrucțiune are 32 de biți = *4 octeți*, iar memoria e *adresată pe octet* (fiecare adresă numără un octet). Instrucțiunea următoare e deci la 4 adrese mai departe: 0, 4, 8, 12, ...

#capcana[Enunțul scrie `output reg [31:0] out`. Tu ai `output [31:0] out` cu `assign`: funcțional identic. Dacă se cere strict semnătura din enunț, varianta echivalentă e `output reg [31:0] out` cu `always @(*) out = ina + inb;`. Ce *nu* merge: `output reg` cu `assign` (eroare: unui `reg` nu i se poate face `assign`).]

Depășirea: `ina + inb` pe 32 de biți ignoră transportul din bitul 31 (rezultatul e modulo 2#super[32]). Pentru PC nu contează: memoria are oricum doar 4 KB.

== Cerința 1c · Memoria de instrucțiuni

#sursa("instruction_memory.v", read("src/instruction_memory.v"))

*Structura.*
- 9: adresa are 10 biți, pentru că memoria are 2#super[10] = 1024 de cuvinte.
- 10: `output reg`, pentru că `instruction` primește valoare în `always @(*)`.
- 12: 1024 de cuvinte × 32 de biți = 4 KB. *Un cuvânt = o instrucțiune întreagă* (enunțul: „o linie de memorie va cuprinde toți cei 32 de biți ai unei instrucțiuni”).

*Încărcarea programului (liniile 14–19).*
- `for`-ul pune 0 în toate cele 1024 de cuvinte. Fără el, cuvintele pe care `$readmemh` nu le atinge ar rămâne `X`, iar după ultima instrucțiune ai vedea `XXXXXXXX` în loc de 0 (și toate câmpurile din ID ar fi `X`).
- `$readmemh("code_stud.mem", codeMemory)`: citește fișierul, un număr hexa pe linie, în `codeMemory[0]`, `codeMemory[1]`, ... Ordinea contează: `for`-ul întâi, `$readmemh` după, altfel `for`-ul ar șterge programul.

*Citirea asincronă (liniile 21–23).* `always @(*)` cu `=`: instrucțiunea apare de îndată ce se schimbă adresa, fără ceas. Asta cere enunțul („în acest caz nu este nevoie de semnal `clk`”). Efectul: în același ciclu în care PC-ul ia o valoare nouă, `INSTRUCTION_IF` arată deja instrucțiunea de la acea adresă, gata să fie prinsă de IF/ID la frontul următor.

=== Adresa: din octeți în cuvinte, și răspunsul la „Obs”

PC-ul numără *octeți* (0, 4, 8, ...), memoria numără *cuvinte* (0, 1, 2, ...). Cuvântul `k` stă la adresa de octet `4k`, deci indexul e `PC / 4`. Enunțul propune `PC >> 2` (împărțirea la 4 e o deplasare la dreapta cu 2), apoi ultimii 10 biți.

#regula(t: "Răspunsul la „Obs”.")[Se iau direct biții `PC[11:2]`. A ignora cei 2 biți de jos *este* împărțirea la 4 (ei sunt mereu `00` pentru o adresă aliniată), iar biții 11...2 sunt exact cei 10 biți de index. Nu trebuie nicio deplasare: e doar o tăietură, adică fire. În cod se face în `IF.v`: `.address(PC_IF[11:2])`.]

#tabel(
  columns: (auto, auto, auto, auto),
  [*PC (hexa)*], [*PC, biții 11...0*], [*`PC[11:2]`*], [*instrucțiunea*],
  [`0x000`], [`0000 0000 00|00`], [0], [`add x2,x1,x0`],
  [`0x004`], [`0000 0000 01|00`], [1], [`addi x1,x1,1`],
  [`0x008`], [`0000 0000 10|00`], [2], [`and x3,x1,x2`],
  [`0x00C`], [`0000 0000 11|00`], [3], [`ori x4,x1,1`],
  [`0x010`], [`0000 0001 00|00`], [4], [`sw x4,4(x5)`],
  [`0x014`], [`0000 0001 01|00`], [5], [`lw x12,8(x0)`],
  [`0x018`], [`0000 0001 10|00`], [6], [`beq x18,x0,5c`],
  [`0xFFC`], [`1111 1111 11|00`], [1023], [ultimul cuvânt],
  [`0x1000`], [`0000 0000 00|00` (bitul 12 = 1)], [0], [se ia de la capăt: biții de peste 11 se ignoră],
)

#idee[De ce `PC[11:2]` și nu `PC[9:0]`: `PC[9:0]` ar adresa cu PC-ul *în octeți*, deci ar citi cuvintele 0, 4, 8, ...: ar sări peste trei instrucțiuni din patru. Asta e exact problema descrisă în enunț.]

== Cerința 2 · Modulul IF

#sursa("IF.v", read("src/IF.v"))

#align(center, cetz.canvas(length: 0.7cm, {
  import cetz.draw: *
  let bx(a, b, t, f: white) = { rect(a, b, fill: f, stroke: 0.8pt); content(((a.at(0) + b.at(0)) / 2, (a.at(1) + b.at(1)) / 2), t) }
  bx((0, 0), (1.6, 2.4), [#set align(center); MUX\ `MUX_PC`], f: c-op)
  bx((3.2, 0), (5.2, 2.4), [#set align(center); PC\ `PC_REG`], f: c-rd)
  bx((7.6, -0.4), (11.6, 2.8), [#set align(center); memoria\ `INSTR_MEM`], f: c-f3)
  bx((4.4, 3.4), (6.4, 4.6), [#set align(center); +4 `ADD4`], f: c-f7)
  line((1.6, 1.2), (3.2, 1.2), mark: (end: ">"))
  content((2.4, 1.6), text(7.5pt)[PC_next])
  line((5.2, 1.2), (7.6, 1.2), mark: (end: ">"))
  content((6.4, 0.8), text(7.5pt)[PC_IF\[11:2\]])
  line((5.6, 1.2), (5.6, 3.4), mark: (end: ">"))
  line((6.4, 4.0), (7.0, 4.0), (7.0, 5.2), (-0.8, 5.2), (-0.8, 1.8), (0, 1.8), mark: (end: ">"))
  content((3.2, 5.55), text(7.5pt)[PC_plus4 (intrarea 0 a MUX-ului)])
  line((-2.2, 0.6), (0, 0.6), mark: (end: ">"))
  content((-2.2, 0.2), text(7.5pt)[PC_Branch (1)])
  line((0.8, -1.2), (0.8, 0), mark: (end: ">"))
  content((0.8, -1.55), text(7.5pt)[PCSrc])
  line((4.2, -1.2), (4.2, 0), mark: (end: ">"))
  content((4.2, -1.55), text(7.5pt)[PC_write, clk, reset])
  line((11.6, 1.2), (13.4, 1.2), mark: (end: ">"))
  content((13.4, 1.6), text(7.5pt)[INSTRUCTION_IF])
  line((5.6, 1.2), (5.6, -0.6), (13.4, -0.6), mark: (end: ">"))
  content((13.4, -0.25), text(7.5pt)[PC_IF])
}))

*Ce se întâmplă.*
- Firele interne `PC_plus4` (ieșirea sumatorului) și `PC_next` (ieșirea MUX-ului) nu sunt porturi: există doar înăuntrul lui IF.
- *Bucla*: PC → sumator → MUX → înapoi în PC. La fiecare front, PC ia ce a ales MUX-ul. Bucla nu „se învârte” la infinit pentru că PC e un registru: rupe bucla și o lasă să avanseze o dată pe ciclu.
- `PC_IF` merge în trei locuri: la sumator, la memorie (doar biții 11:2) și afară, spre IF/ID.
- *Singurul element cu stare din IF e PC-ul.* Restul (MUX, sumator, citirea memoriei) e combinațional: în cursul unui ciclu, după ce PC-ul s-a schimbat, `PC_plus4`, `PC_next` și `INSTRUCTION_IF` se stabilesc imediat.
- Constanta 4 e dată direct la instanțiere (`.inb(32'd4)`): sumatorul e generic, IF îl face „+4”.

#tabel(
  columns: (auto, auto, auto, auto, 1fr),
  [*după frontul de la*], [*`reset`*], [*PC_IF*], [*PC_plus4 = PC_next*], [*INSTRUCTION_IF*],
  [0–5 ns (încă niciun front)], [1], [`X`], [`X`], [`X`],
  [5 ns], [1], [`0x00`], [`0x04`], [`00008133` (`add`)],
  [15 ns], [0], [`0x04`], [`0x08`], [`00108093` (`addi`)],
  [25 ns], [0], [`0x08`], [`0x0C`], [`0020F1B3` (`and`)],
  [65 ns], [0], [`0x18`], [`0x1C`], [`04090E63` (`beq`, ultima)],
  [75 ns], [0], [`0x1C`], [`0x20`], [`00000000` (după program)],
)
