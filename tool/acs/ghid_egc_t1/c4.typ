#import "tpl.typ": *

= Structurile de date

== `Card.h`: zone, tipuri, efecte

#cod("Card.h", 8, 33)

- `Zone` spune *unde* e o carte: în pachet (`DECK`), în mână (`HAND`), pe tablă (`BOARD`) sau moartă (`DEAD`). O carte nu se mută dintr-un vector în altul când e jucată sau moare: își schimbă doar `zone`.
- `CardType` e tipul (cel care dă culoarea, simbolul și costul). `TYPE_COUNT` e un truc: valoarea lui (5) e numărul de tipuri, folosit în `rand() % TYPE_COUNT`.
- `Effect` e efectul *activ*. E separat de tip intenționat: *Silence* șterge efectul (`effect = EFFECT_NONE`), dar cartea rămâne de tipul ei (aceeași culoare, același simbol).
- `GetTypeStyle` e un tabel: pentru fiecare tip, culoarea, numele mesh-ului simbolului, costul și efectul.

#tabel(
  columns: (auto, auto, auto, auto, 1fr),
  [*Tip*], [*Culoare*], [*Simbol*], [*Cost*], [*Efect*],
  [`NORMAL`], [gri], [cerc], [1], [niciunul],
  [`TANK`], [albastru], [romb], [4], [adversarul trebuie să-l atace întâi],
  [`CHARGE`], [portocaliu], [triunghi], [3], [poate ataca din runda în care e pus],
  [`LIFESTEAL`], [roșu], [plus], [3], [ATK-ul lui se adaugă la viața eroului propriu],
  [`SILENCE`], [mov], [stea], [2], [la plasare, anulează Tank / Lifesteal unei cărți inamice],
)

#cod("Card.h", 35, 64)

#tabel(
  columns: (auto, 1fr),
  [*Câmp*], [*Rol*],
  [`zone`, `isEnemy`], [unde e și al cui e],
  [`isDragged`], [e trasă cu mouse-ul acum],
  [`isSelected`], [e aleasă pentru atac (săgeata pornește din ea)],
  [`hasAttacked`], [a atacat deja în runda asta],
  [`isHovered`], [cursorul e deasupra ei (pentru scalare)],
  [`atk`, `hp`, `manaCost`], [statisticile],
  [`round`], [runda proprietarului în care a fost pusă pe tablă (−1 = încă nepusă); pentru regula „nu atacă în runda în care e pusă”],
  [`x, y` / `targetX, targetY`], [poziția *curentă* (colțul stânga-jos) și cea *spre care* se mișcă],
  [`w, h` / `targetW, targetH`], [mărimea curentă și cea dorită (hover, selectare)],
  [`angle`, `shakeTimer`], [rotația de acum și cât mai durează shake-ul],
)

#idee[Perechile *curent / țintă* sunt cheia tuturor animațiilor de translație și scalare: logica jocului schimbă doar ținta (`targetX = ...`), iar `Update` apropie, cadru cu cadru, valoarea curentă de țintă. Logica nu trebuie să știe nimic despre animații.]

== `Player.h`

#fisier("Player.h")

Același tip descrie și jucătorul, și inamicul (membrii `player` și `enemy`). `hp` e viața *eroului*; `round` crește la fiecare `StartTurn` al acelui jucător; `angle` și `shakeTimer` sunt pentru shake-ul cărții erou când e atacată. Valorile inițiale `mana = 1`, `maxMana = 1` sunt suprascrise în `Init` cu 0 (vezi capitolul 8).

== `Tema1.h`: starea jocului

Membrii protejați, pe grupe:

- *dimensiuni* calculate o dată în `Init`: `screenW, screenH`, înălțimile benzilor `handH, heroZoneH, halfH`, mărimea cărții `cardW, cardH, cardGap`;
- *poziții fixe*: Y-ul mâinilor și al tablelor, pachetele, butonul, eroii, timer-ul;
- *cărțile*: patru vectori `std::vector<tema1::Card>`: `playerDeck`, `enemyDeck` (pachetele) și `playerCards`, `enemyCards` (*toate* celelalte cărți ale fiecăruia: în mână, pe tablă sau moarte, deosebite prin `zone`);
- *jucătorii*: `player`, `enemy`;
- *starea turei*: `enemyTimer, enemyDelay` (ritmul inamicului), `turnTime, turnTimer` (cele 30 de secunde), `gameOver`, `isSilencing`;
- *limitele*: `maxHandSize = 10`, `maxBoardSize = 7` (ca în Hearthstone);
- `cursorX, cursorY`: ultima poziție a cursorului, *deja în coordonatele scenei*.

#capcana[O singură listă (`playerCards`) pentru mână, tablă și cimitir înseamnă că *orice* funcție care lucrează cu „cărțile din mână” trebuie să filtreze după `zone == HAND`. Le vei vedea peste tot: `ArrangeZone`, `TakeFromDeck` (numără doar mâna), `RemoveDead`, testele de click. Avantajul: o carte nu se copiază niciodată dintr-un vector în altul, deci referințele (`Card&`) la ea rămân valide cât timp nu se adaugă cărți în vector.]
