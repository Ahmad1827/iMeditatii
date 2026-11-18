#import "tpl.typ": *

= Bancul de registre (cerința 3)

#sursa("registers.v", read("src/registers.v"))

== Structura

- 15: `reg [31:0] regs [0:31]`: 32 de registre (`x0`...`x31`) a câte 32 de biți. Adresa unui registru are 5 biți, pentru că 2#super[5] = 32.
- E o *memorie multi-port*: 2 porturi de citire (cei doi operanzi ai unei instrucțiuni ca `add x3, x1, x2`) și 1 port de scriere (rezultatul). Toate trei pot lucra în același ciclu.

== Inițializarea (liniile 18–22)

Enunțul cere, „pentru o mai bună simulare”, ca registrul `xi` să înceapă cu valoarea `i`: `x1 = 1`, `x2 = 2`, ..., `x31 = 31`. Câștigul: în forma de undă, `REG_DATA1_ID` și `REG_DATA2_ID` sunt *egale cu numărul registrului citit*, deci vezi dintr-o privire dacă s-a citit registrul corect (în Fig. 4, la `beq x18,...`, `REG_DATA1_ID = 0x12` = 18). `x0` începe și el cu 0, cum trebuie.

== Scrierea: sincronă (liniile 25–28)

- Doar pe frontul crescător, doar dacă `reg_write = 1`.
- `write_reg != 5'd0`: *scrierea în `x0` e ignorată*. Regula RISC-V: `x0` e mereu 0. Cum pornește de la 0 și nu poate fi scris, rămâne 0 pentru totdeauna.
- `<=`, ca la orice registru.

== Citirea: asincronă (liniile 31–32)

Două `assign`-uri: `read_data1` urmează *imediat* `read_reg1`, fără ceas. Imediat ce o instrucțiune nouă intră în IF/ID, `RS1_ID` și `RS2_ID` se schimbă, iar operanzii apar pe `REG_DATA1_ID`/`REG_DATA2_ID` *în același ciclu*: ID poate să-i predea etapei EX la frontul următor.

#idee[De ce citire asincronă și scriere sincronă: citirea trebuie să încapă în ciclul lui ID; scrierea trebuie controlată (doar pe front, doar cu permisiune), altfel valori intermediare, încă nestabilizate, ar ajunge în registre.]

#capcana[Ce vezi dacă citești și scrii *același* registru în același ciclu: până la front citești valoarea veche, după front pe cea nouă. În procesorul complet (Lucrarea 3), WB scrie un registru pe care ID îl poate citi în același ciclu; varianta clasică din Patterson–Hennessy rezolvă asta scriind în prima jumătate a ciclului (pe frontul descrescător) sau cu un bypass în bancul de registre. Pentru Lucrarea 2 nu contează: nu se scrie nimic.]

== Simularea separată: un testbench pentru `registers`

Cerința 3 spune „să se implementeze *și simuleze separat*”. Un testbench minim, care arată toate cele patru comportamente (citirea asincronă, scrierea sincronă, `x0` protejat, scrierea oprită):

#sursa("tb_registers.v", read("src/tb_registers.v"))

Ce trebuie să vezi (fronturi crescătoare la 5, 15, 25, 35, 45, 55 ns). Fiecare rând e un interval în care nu se schimbă nimic:

#tabel(
  columns: (auto, auto, auto, auto, auto, auto, auto, auto),
  [*interval (ns)*], [*`read_reg1`*], [*`read_reg2`*], [*`reg_write`*], [*`write_reg`*], [*`write_data`*], [*`read_data1`*], [*`read_data2`*],
  ..g.regs_tb.map(r => (
    [#r.from–#r.to], [#r.r1], [#r.r2], [#r.we], [#r.wr], mono(r.wd), mono(r.d1), mono(r.d2),
  )).flatten(),
)

Ce demonstrează fiecare moment:
- *12 ns*: `read_reg1` devine 7 între fronturi, iar `read_data1` devine 7 *pe loc*: citirea e asincronă.
- *18 → 25 ns*: cerem scrierea lui `0xAB` în `x3` la 18 ns, dar `read_data2` (care citește `x3`) arată tot 3 până la frontul de la 25 ns, apoi `0xAB`: scrierea e sincronă.
- *28 → 35 ns*: încercăm să scriem `0xFF` în `x0`; `read_data1` (care citește `x0`) rămâne 0 și după frontul de la 35 ns.
- *38 ns →*: cu `reg_write = 0` nu se mai scrie nimic: `x4` rămâne 4.

#vivado[Ca să simulezi doar bancul de registre: Simulation Sources → click dreapta pe `tb_registers` → Set as Top, apoi Run Simulation → Run Behavioral Simulation. Ca să vezi și registrele din interior, în fereastra Scope deschide `dut` și trage `regs` în forma de undă.]
