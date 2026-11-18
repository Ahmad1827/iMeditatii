#import "tpl.typ": *

= Întrebări de la prezentare

#let qa(q, a) = block(breakable: false, above: 0.9em, below: 0.6em)[
  #text(weight: "bold", fill: albastru.darken(15%))[#q]\
  #a
]

== Despre pipeline și front-end

#qa[Ce e front-end-ul unui procesor?][Partea care aduce și decodifică instrucțiunile: aici IF + ID. Back-end-ul (EX, MEM, WB) le execută.]
#qa[De ce un registru de pipeline între IF și ID?][Ca fiecare etapă să lucreze un ciclu întreg pe instrucțiunea ei: ID pe cea adusă în ciclul trecut, IF deja pe următoarea. Fără el, ID ar vedea ce aduce IF chiar acum și n-ar exista pipeline.]
#qa[Ce semnale sunt „din viitor” și cine le va produce?][`PC_write` și `IF_ID_write` (unitatea de detecție a hazardurilor), `PCSrc` și `PC_Branch` (EX), `RegWrite_WB`, `RD_WB`, `ALU_DATA_WB` (WB). Acum le dă testbench-ul: 1, 1, 0, 0, 0, 0, 0.]
#qa[Ce fac `PC_write` și `IF_ID_write`?][Sunt semnalele de stall. Pe 0, PC-ul și IF/ID își păstrează valoarea, iar aceeași instrucțiune mai stă un ciclu în ID (de exemplu când folosește rezultatul unui `lw` din ciclul anterior: hazard load-use).]
#qa[Ce vor face `PCSrc` și `PC_Branch` în Lucrarea 3?][Când un salt se ia, EX pune `PCSrc = 1` și `PC_Branch = PC + imm` (de exemplu `0x18 + 0x5C = 0x74` pentru `beq`-ul nostru), iar la frontul următor PC-ul sare acolo.]
#qa[De ce `x1` rămâne 1 după `addi x1,x1,1`?][Pentru că instrucțiunea nu ajunge în EX și WB (nu există încă), iar `RegWrite_WB = 0`. Lucrarea 2 doar citește și decodifică.]
#qa[De ce `beq` nu sare?][`PCSrc` e fixat pe 0 în testbench. (Și în procesorul complet n-ar sări: `x18 = 18 ≠ 0`.)]

== Despre IF

#qa[De ce PC + 4?][O instrucțiune are 4 octeți, iar memoria e adresată pe octet.]
#qa[Răspunsul la „Obs”: cum iei cei 10 biți de adresă fără deplasare?][Cu tăietura `PC[11:2]`: biții 1:0 (mereu `00`) se aruncă, ceea ce e împărțirea la 4, iar 11:2 sunt cei 10 biți de index. Sunt doar fire.]
#qa[De ce memoria de instrucțiuni e asincronă?][Așa cere enunțul: instrucțiunea trebuie să apară în același ciclu în care se schimbă PC-ul, ca IF/ID s-o prindă la frontul următor. O memorie sincronă ar mai adăuga un ciclu.]
#qa[De ce `for`-ul înainte de `$readmemh`?][Ca locațiile neacoperite de fișier să fie 0, nu `X`. Ordinea contează: invers, `for`-ul ar șterge programul.]
#qa[Ce e `$readmemh`?][O funcție de sistem de simulare care citește un fișier text cu valori hexa, câte una pe linie, într-o memorie Verilog, de la adresa 0.]
#qa[Resetul e sincron sau asincron?][Sincron: e verificat doar în `always @(posedge clk)`. Asincron ar fi fost `always @(posedge clk or posedge res)`.]
#qa[De ce `X` la începutul simulării?][Până la primul front (5 ns) PC-ul și IF/ID n-au primit nicio valoare. La frontul de la 5 ns resetul le face 0.]
#qa[Câte instrucțiuni încap în memorie? Cât e de mare?][1024 de cuvinte × 4 octeți = 4 KB, adresele de octet 0x000...0xFFF.]

== Despre ID

#qa[De ce `x0` e mereu 0 și cum ai implementat asta?][Regula RISC-V: `x0` e constanta 0 (`nop = addi x0,x0,0`, `mv rd,rs = addi rd,rs,0`, adresare absolută ca `lw x12,8(x0)`). Scrierea în adresa 0 e ignorată (`write_reg != 0`), iar `x0` pornește de la 0.]
#qa[De ce citirea din registre e asincronă, iar scrierea sincronă?][Operanzii trebuie să fie gata în același ciclu din ID; scrierea trebuie controlată: doar pe front, doar cu `RegWrite`.]
#qa[De ce `xi` pornește cu valoarea `i`?][Pentru simulare: `REG_DATA1/2` arată direct numărul registrului citit, deci vezi imediat dacă `rs1`/`rs2` sunt corecte.]
#qa[De ce `RD_ID` arată 4 la `sw`?][ID taie câmpurile fără să știe formatul. La `sw`, biții 11:7 sunt imm\[4:0\] = 4. Unitatea de control din Lucrarea 3 va ignora `rd` pentru store.]
#qa[Ce face `imm_gen`?][Reasamblează biții imediatului după format și îi extinde cu semn la 32 de biți: I (`lw`, `addi`...), shamt pentru deplasări, S (`sw`), B (salturi, cu bitul 0 = 0).]
#qa[De ce deplasările au alt imediat?][Au nevoie doar de 5 biți (`shamt`, 0...31); biții 31:25 sunt `funct7` (deosebesc `srli` de `srai`), nu imediat.]
#qa[De ce imediatul B se termină cu 0?][Adresele de salt sunt pare, bitul 0 nu se stochează; `1'b0` adăugat la coadă e „Shift left 1” din Fig. 3.]
#qa[Ce dă `imm_gen` pentru `add`? Pentru `lui`?][0 pentru ambele (ramura `default`). Pentru `add` e corect (R nu are imediat); `lui` nu e cerută în Lucrarea 2.]
#qa[Ce e extensia de semn?][Copierea bitului de semn în biții noi de sus, ca un număr negativ să rămână negativ: −1 pe 12 biți (`0xFFF`) devine `0xFFFFFFFF`, nu `0x00000FFF`.]
#qa[De ce bitul de semn e mereu `inst[31]`?][Alegere a ISA-ului: extensia de semn poate porni înainte să știi formatul, iar hardware-ul e mai simplu.]

== Despre Verilog

#qa[Blocant sau neblocant?][`<=` în blocurile cu ceas (PC, IF/ID, scrierea registrelor): toate registrele se actualizează „deodată”, din valorile vechi. `=` în blocurile combinaționale (`imm_gen`, citirea memoriei).]
#qa[De ce `output reg` la memorie, deși e combinațională?][`reg` e cerut de sintaxă pentru orice semnal atribuit într-un `always`; nu înseamnă registru.]
#qa[Ce e un latch și cum l-ai evitat?][O memorie pe nivel, pusă de sinteză când o ieșire a unui `always @(*)` nu primește valoare pe un drum. `default` în `case` și `else` la `if`.]
#qa[De ce instanțiere pe nume?][Ordinea nu contează și nu poți încurca firele. Testbench-ul dat folosește poziția, de aceea ordinea porturilor top-ului trebuie să fie exact cea din enunț.]
#qa[Care a fost bug-ul din top?][`input [31:0] ALU_DATA, WB` a declarat două porturi în loc de `ALU_DATA_WB`; cu instanțierea pe poziție, toate semnalele de după s-ar fi decalat cu un port. Plus corpul gol.]
#qa[Ce înseamnă `{{20{in[31]}}, in[31:20]}`?][Concatenarea a 20 de copii ale bitului 31 cu biții 31...20: imediatul I, extins cu semn la 32 de biți.]

== Întrebări de calcul care pot apărea

#qa[Codifică `addi x5, x0, -1`.][`imm = 0xFFF`, `rs1 = 0`, `funct3 = 000`, `rd = 00101`, `opcode = 0010011` → `0xFFF00293`.]
#qa[Ce instrucțiune e `0x00A50533`?][`0110011` = R, `funct3 = 000`, `funct7 = 0` → `add`; `rd = 01010` = x10, `rs1 = 01010` = x10, `rs2 = 01010` = x10: `add x10, x10, x10`.]
#qa[La ce index din memorie e instrucțiunea de la PC = `0x2C`?][`0x2C >> 2 = 11`.]
#qa[Ce `PC_ID` e pe ecran la 100 ns?][Ultimul front a fost la 95 ns, când IF/ID a primit PC-ul din IF, `0x20`.]
