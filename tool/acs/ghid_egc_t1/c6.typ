#import "tpl.typ": *

= Așezarea pe ecran (`Init`)

== Totul e proporțional cu ecranul

#cod("Tema1.cpp", 54, 97)

Nicio poziție nu e scrisă în pixeli: toate sunt fracțiuni din `screenH` (și `screenW`), deci tabla arată la fel la orice rezoluție inițială. Pentru fereastra implicită de *1280 × 720*:

#tabel(
  columns: (auto, auto, 1fr),
  [*Mărime*], [*Valoare*], [*De unde*],
  [`handH`, `heroZoneH`], [#L.handH], [16% din 720],
  [`halfH`], [#L.halfH], [18% din 720 (o jumătate de tablă)],
  [`cardH`], [#L.cardH], [80% din `handH`: cartea încape în banda mâinii cu margini],
  [`cardW`], [#L.cardW], [70% din `cardH` (raportul unei cărți de joc)],
  [`cardGap`], [#f2(L.cardGap)], [20% din `cardW`],
  [`playerHandY`], [#L.playerHandY], [cartea centrată vertical în banda mâinii],
  [`playerBoardY`], [#L.playerBoardY], [`handH + heroZoneH +` marginea în jumătatea de tablă],
  [`enemyBoardY`], [#L.enemyBoardY], [`screenH / 2 +` aceeași margine],
  [`enemyHandY`], [#L.enemyHandY], [`screenH - handH +` marginea],
  [`heroX`, `playerHeroY`, `enemyHeroY`], [#f2(L.heroX), #L.playerHeroY, #L.enemyHeroY], [eroul centrat pe orizontală, în zona lui],
  [`playerDeckX` (și `enemyDeckX`)], [#f2(L.playerDeckX)], [`screenW - cardW - 2 · cardGap`: lângă marginea dreaptă],
  [`endButtonX, endButtonY`], [#f2(L.endButtonX), #f2(L.endButtonY)], [sub pachet, pe mijlocul jumătății de tablă a jucătorului],
  [`endButtonW × endButtonH`], [#L.endButtonW × #f2(L.endButtonH)], [cât o carte, 40% din înălțime],
  [`timerH`], [#L.timerH], [un sfert din margine (`halfH - cardH`)],
  [`playerTimerY`, `enemyTimerY`], [#f2(L.playerTimerY), #f2(L.enemyTimerY)], [chiar sub / chiar peste linia de mijloc],
)

== Cele șase benzi

De jos în sus (`DrawBoard`): mâna ta, zona eroului tău, jumătatea ta de tablă, jumătatea inamicului, zona eroului inamic, mâna inamicului. Înălțimile: $4 dot 0.16 + 2 dot 0.18 = 1$, deci benzile acoperă exact ecranul, iar granița dintre cele două jumătăți e exact la $"screenH" \/ 2 = 360$.

#let sc = 0.0095
#align(center, cetz.canvas(length: 1cm, {
  import cetz.draw: *
  let culori = (rgb(51, 38, 26), rgb(82, 64, 43), rgb(64, 102, 64), rgb(77, 115, 77), rgb(82, 64, 43), rgb(51, 38, 26))
  for (i, b) in g.bands.enumerate() {
    rect((0, b.at(1) * sc), (1280 * sc, b.at(2) * sc), fill: culori.at(i), stroke: none)
    content((-0.15, (b.at(1) + b.at(2)) / 2 * sc), anchor: "east", text(7pt)[#b.at(0) \ $y in [#b.at(1), #b.at(2)]$])
  }
  rect((0, 358 * sc), (1280 * sc, 362 * sc), fill: rgb(230, 204, 77), stroke: none)
  // eroii
  rect((L.heroX * sc, L.playerHeroY * sc), ((L.heroX + L.heroW) * sc, (L.playerHeroY + L.heroH) * sc), fill: rgb(191, 153, 64), stroke: 0.5pt)
  rect((L.heroX * sc, L.enemyHeroY * sc), ((L.heroX + L.heroW) * sc, (L.enemyHeroY + L.heroH) * sc), fill: rgb(191, 153, 64), stroke: 0.5pt)
  // 5 cărți în mâna ta
  for x in g.arrange.at("5") {
    rect((x * sc, L.playerHandY * sc), ((x + L.cardW) * sc, (L.playerHandY + L.cardH) * sc), fill: rgb(140, 140, 140), stroke: 0.5pt)
    rect((x * sc, L.enemyHandY * sc), ((x + L.cardW) * sc, (L.enemyHandY + L.cardH) * sc), fill: rgb(115, 51, 26), stroke: 0.5pt)
  }
  // 2 cărți pe tablă, de fiecare parte
  for x in g.arrange.at("2") {
    rect((x * sc, L.playerBoardY * sc), ((x + L.cardW) * sc, (L.playerBoardY + L.cardH) * sc), fill: rgb(64, 115, 217), stroke: 0.5pt)
    rect((x * sc, L.enemyBoardY * sc), ((x + L.cardW) * sc, (L.enemyBoardY + L.cardH) * sc), fill: rgb(230, 128, 26), stroke: 0.5pt)
  }
  // pachetele, butonul, timer-ul
  rect((L.playerDeckX * sc, L.playerDeckY * sc), ((L.playerDeckX + L.cardW) * sc, (L.playerDeckY + L.cardH) * sc), fill: rgb(115, 51, 26), stroke: 0.5pt)
  rect((L.enemyDeckX * sc, L.enemyDeckY * sc), ((L.enemyDeckX + L.cardW) * sc, (L.enemyDeckY + L.cardH) * sc), fill: rgb(115, 51, 26), stroke: 0.5pt)
  rect((L.endButtonX * sc, L.endButtonY * sc), ((L.endButtonX + L.endButtonW) * sc, (L.endButtonY + L.endButtonH) * sc), fill: rgb(51, 191, 77), stroke: 0.5pt)
  rect((L.timerX * sc, L.playerTimerY * sc), ((L.timerX + L.timerW * 0.6) * sc, (L.playerTimerY + L.timerH) * sc), fill: rgb(255, 191, 51), stroke: 0.3pt)
  // cristalele de mana, în stânga eroilor
  for y in (L.playerHeroY, L.enemyHeroY) {
    let size = L.heroH * 0.3
    let gap = size * 0.25
    let sx = L.heroX - L.heroW * 0.15 - 10 * size - 9 * gap
    for i in range(10) {
      let cx = sx + i * (size + gap) + size / 2
      let cy = y + L.heroH / 2
      line(((cx - size / 2) * sc, cy * sc), (cx * sc, (cy + size / 2) * sc), ((cx + size / 2) * sc, cy * sc), (cx * sc, (cy - size / 2) * sc), close: true,
        fill: if i < 3 { rgb(51, 102, 255) } else if i < 5 { white } else { black }, stroke: none)
    }
  }
  content(((L.endButtonX - 4) * sc, (L.endButtonY + L.endButtonH / 2) * sc), anchor: "east", text(7pt, fill: white)[buton →])
  content(((L.playerDeckX - 4) * sc, (L.playerDeckY + L.cardH / 2) * sc), anchor: "east", text(7pt, fill: white)[pachet →])
  rect((0, 0), (1280 * sc, 720 * sc), stroke: 0.6pt + black)
}))

#align(center)[#text(9pt, fill: gri)[Tabla la scară (1280 × 720), cu poziții calculate ca în `Init`: 5 cărți în fiecare mână, 2 pe fiecare jumătate de tablă, 3 mana disponibile din 5.]]

#capcana[`OnWindowResize` e gol, iar dimensiunile sunt calculate o singură dată, în `Init`. Dacă redimensionezi fereastra, scena (1280 × 720 unități) se *întinde* pe noua fereastră, iar click-urile rămân corecte datorită conversiei din `OnMouseMove`, care împarte la rezoluția curentă. Cărțile se deformează proporțional cu fereastra, dar nimic nu se strică.]

== Unde stă o carte: `ArrangeZone`

#cod("Tema1.cpp", 368, 406)

Pentru $n$ cărți de lățime $w$ cu spațiu $g$ între ele, grupul are lățimea $W_n = n w + (n - 1) g$. Ca să fie *centrat*, începe la $x_0 = ("screenW" - W_n) \/ 2$, iar cartea a $k$-a (numărând doar cărțile din zonă) are

$ x_k = x_0 + k (w + g) $

Contorul `k` crește *doar* pentru cărțile din zona cerută, în ordinea din vector, deci ordinea relativă a cărților rămâne aceeași (cerință din enunț). Y-ul depinde doar de zonă și de proprietar. Funcția *nu mută* nicio carte: scrie doar `targetX`, `targetY`; mișcarea o face `Update`.

#tabel(
  columns: (auto, 1fr),
  [*n*], [*`targetX` ale celor n cărți (1280 × 720)*],
  ..range(1, 8).map(n => (str(n), g.arrange.at(str(n)).map(x => str(x)).join(", "))).flatten(),
)

Verificare: pentru 5 cărți, prima începe la #g.arrange.at("5").at(0) și ultima se termină la #g.arrange.at("5").at(4) + #L.cardW = #f2(g.arrange.at("5").at(4) + L.cardW), iar $452.92 + 827.08 = 1280$: margini egale. Pentru un număr impar de cărți, cea din mijloc stă exact la `heroX` = #f2(L.heroX), deasupra eroului.

#idee[Cu cel mult 7 cărți pe tablă (`maxBoardSize`), grupul are cel mult $7 dot 64.5 + 6 dot 12.9 approx 529$ de unități, deci încape mereu. În mână pot fi până la 10 (`maxHandSize`): $10 dot 64.5 + 9 dot 12.9 approx 761$, tot sub 1280, deci nu e nevoie de rânduri multiple sau de micșorarea distanței (enunțul lasă asta la latitudinea ta).]
