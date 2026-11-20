#import "tpl.typ": *

= Desenarea

== `DrawBoard`: fundalul

#cod("Tema1.cpp", 571, 583)

Șase dreptunghiuri (benzile din capitolul 6) și o linie galbenă de 4 unități centrată pe $y = 360$ (de la 358 la 362): delimitarea celor două jumătăți ale tablei (4p din barem). Mâinile sunt mai închise, zonele eroilor mai deschise, iar cele două jumătăți au nuanțe de verde ușor diferite.

== `DrawCard`: o carte, din bucăți

#cod("Tema1.cpp", 409, 446)

*Pas cu pas:*

+ *Cărțile moarte nu se desenează* (`zone == DEAD`): de aceea nu trebuie șterse din vector.
+ *Centrul rămâne pe loc când cartea crește.* `w, h` sunt mărimea *curentă* (care crește la hover/selectare), iar `card.x, card.y` e colțul pentru mărimea *normală*. `x = card.x - (w - cardW) / 2` mută colțul la stânga cu jumătate din creștere: cartea se mărește egal în toate părțile, nu doar spre dreapta-sus.
+ *Rotația* în jurul centrului (capitolul 3), pentru shake.
+ *Chenarul* e un dreptunghi negru *mai mare* cu `border` în fiecare parte, desenat *înaintea* cărții: se vede doar marginea lui. Grosimea e 4% din lățime; 8% și mov dacă e selectată; 8% și *verde* dacă mai poate ataca (`CanAttack`) — conturul cărților utilizabile din barem.
+ *Cartea inamicului din mână* se desenează *cu spatele*: un dreptunghi maro și unul mai deschis, la 60% din mărime, în mijloc. Toate arată la fel (cerința „desenate identice între ele”), iar funcția se oprește aici (`return`): nu se văd tipul și statisticile.
+ *Fundalul* în culoarea tipului, apoi *simbolul* tipului, alb, în centrul jumătății de jos.

#cod("Tema1.cpp", 448, 469)

+ *Statisticile*: trei coloane, de la stânga: *mana* (cercuri albastre), *ATK* (săbii galbene), *HP* (inimi roșii). Valoarea $v$ e desenată ca $v$ simboluri, unul sub altul, pornind de sus. Simbolul $v$ din coloana $s$ are centrul în

$ (x + "space" + s ("size" + "space") + "size"\/2, quad "topY" - v ("size" + "space") + "size"\/2) $

cu `size` = 12% din lățime și `space` = 30% din `size`. Cele trei tablouri paralele (`values`, `statShapes`, `statColors`) țin, pe aceeași poziție, valoarea, mesh-ul și culoarea fiecărei coloane, ca un singur `for` să le deseneze pe toate.

#idee[Valorile sunt între 1 și 5 (ATK, HP), iar costul între 1 și 4, deci o coloană are cel mult 5 simboluri: la mărimea normală, cel mai de jos ajunge la $approx 42$ de unități deasupra bazei cărții, peste simbolul tipului (care se termină la $approx 35$). Nu se suprapun.]

#prof[„Unde sunt proprietățile cărților?” — „Pe coloana din stânga: cercurile albastre sunt costul de mana, săbiile galbene atacul, inimile roșii viața. Câte simboluri, atât valoarea.” Dacă o carte primește damage, coloana de inimi scade imediat (e desenată din `card.hp` la fiecare cadru).]

== `DrawHero`

#cod("Tema1.cpp", 472, 501)

Eroul e o carte aurie (culoare fixă), cu un cerc alb ca simbol și *viața ca inimi*: `p.hp` inimi, câte 10 pe coloană (`col = i / 10`, `row = i % 10`). La 30 HP: 3 coloane pline. Se rotește la shake ca o carte (`p.angle`).

#capcana[Viața eroului poate trece de 30 prin *Lifesteal* (`owner.hp += attacker.atk`, fără plafon). Atunci apare o a patra coloană de inimi. În Hearthstone viața eroului e plafonată la maxim; enunțul nu cere asta, deci nu e greșit, dar fii pregătit să explici.]

== `DrawMana`: cristalele

#cod("Tema1.cpp", 504, 525)

10 romburi pe un rând, în stânga eroului, centrate vertical pe el. Pentru cristalul $i$ ($0..9$):

#tabel(
  columns: (auto, auto, 1fr),
  [*Condiția*], [*Culoarea*], [*Înseamnă*],
  [`i < p.mana`], [albastru], [mana pe care o ai acum],
  [`i < p.maxMana`], [alb], [mana deblocată, dar cheltuită în runda asta],
  [altfel], [negru], [încă nedeblocată (runda nu e destul de mare)],
)

Exact cum cere enunțul (albastre, albe, negre). Ordinea testelor contează: `mana <= maxMana` mereu, deci primele `mana` sunt albastre, următoarele până la `maxMana` albe, restul negre. Exemple:

#tabel(
  columns: (auto, auto, 1fr),
  [*mana*], [*maxMana*], [*Cele 10 cristale*],
  ..g.mana.map(x => (str(x.at(0)), str(x.at(1)), x.at(2).join(", "))).flatten(),
)

`startX` e ales ca ultimul cristal să se termine la `0.15 · heroW` în stânga eroului: $"startX" + 10 dot "size" + 9 dot "gap" = "heroX" - 0.15 dot "heroW"$.

== `DrawArrow`

Pentru cartea selectată (cel mult una), săgeata roșie din centrul ei până la cursor (matricea e explicată în capitolul 3). Se desenează *după* cărți, ca să fie deasupra lor. Cât timp nu e nicio carte selectată, bucla nu desenează nimic.

== `DrawTimer` (în `time.cpp`)

#cod("time.cpp", 22, 35)

Exact sugestia din enunț: trei dreptunghiuri suprapuse — chenarul închis, *fundalul* gri de lățime maximă (`timerW`) și *bara galbenă*, de lățime

$ "width" = "timerW" dot "turnTimer" \/ "turnTime" $

care scade liniar de la plin (30 s rămase) la zero. Bara stă sub linia de mijloc în tura ta și deasupra ei în tura inamicului (`playerTimerY` / `enemyTimerY`).

== Ordinea completă a desenului în `Update`

#cod("Tema1.cpp", 670, 717)

+ tabla (`DrawBoard`);
+ pachetele: *cel mult 3* dreptunghiuri, fiecare decalat cu 4% din lățime (în sus la tine, în jos la inamic, spre interiorul ecranului): par un teanc. `min(3, deck.size())`: când rămân 2 cărți se văd 2, când pachetul se golește dispare;
+ butonul: verde în tura ta, gri în a inamicului;
+ timer-ul, eroii, cristalele;
+ cărțile tale care *nu* sunt trase, toate cărțile inamicului, apoi cartea trasă (deasupra tuturor);
+ săgeata;
+ ecranul final, peste tot: un dreptunghi verde (ai câștigat: `enemy.hp <= 0`) sau roșu, cu chenar negru, în mijlocul ecranului.
