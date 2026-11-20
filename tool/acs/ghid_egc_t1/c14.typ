#import "tpl.typ": *

= Exerciții rezolvate

Toate pe fereastra de 1280 × 720: `cardW` = #L.cardW, `cardH` = #L.cardH, `cardGap` = #f2(L.cardGap). Aceleași tipuri de exerciții (și altele) le găsești în aplicație, la cursul EGC, capitolul „Tema 1: Card Games”.

#problema("ArrangeZone pentru 3 cărți")[Ai 3 cărți pe tabla ta. Ce `targetX` primește fiecare și ce `targetY`?][
Grupul are $3 dot 64.512 + 2 dot 12.9024 = 219.341$; începe la $(1280 - 219.341) \/ 2 = 530.33$. Pasul e $w + g = 77.414$: $x = 530.33, 607.74, 685.16$. Cartea din mijloc stă la 607.74, exact `heroX`. `targetY = playerBoardY = 249.12` pentru toate.
]

#problema("Mouse-ul pe o fereastră mărită")[Fereastra a fost mărită la 1920 × 1080. Mouse-ul e la $(960, 270)$ (pixeli de fereastră). Unde e în scenă?][
$x = 960 dot 1280 \/ 1920 = 640$, $y = 720 - 270 dot 720 \/ 1080 = 720 - 180 = 540$. Punctul $(640, 540)$: în banda zonei eroului inamic ($y in [489.6, 604.8]$), pe mijloc, adică pe eroul inamic.
]

#problema("Matricea lui DrawRect")[Ce matrice construiește `DrawRect(500, 249.12, cardW, cardH, ...)` (fără `parent`)? Unde ajunge colțul $(1, 1)$ al pătratului unitate?][
$M = T(500, 249.12) dot S(64.512, 92.16) = mat(64.512, 0, 500; 0, 92.16, 249.12; 0, 0, 1)$. $(1, 1) arrow.r.bar (64.512 + 500, 92.16 + 249.12) = (564.512, 341.28)$: colțul dreapta-sus al cărții.
]

#problema("Rotația din shake")[Cartea de la exercițiul anterior se scutură cu unghiul $0.15$ rad. Unde ajunge colțul ei stânga-jos $(500, 249.12)$?][
Centrul: $(500 + 32.256, 249.12 + 46.08) = (532.256, 295.2)$. Colțul relativ la centru: $(-32.256, -46.08)$. Rotit: $(-32.256 cos 0.15 + 46.08 sin 0.15, -32.256 sin 0.15 - 46.08 cos 0.15) = (-25.008, -50.383)$. Plus centrul: $approx (507.25, 244.82)$. Centrul însuși rămâne pe loc.
]

#problema("Hover")[O carte din mână are `card.x = 500`. Cursorul e deasupra ei de destul timp încât `w` a ajuns la țintă. Ce lățime și ce `x` folosește `DrawCard`?][
Ținta e $1.15 dot 64.512 = 74.189$. $x = 500 - (74.189 - 64.512) \/ 2 = 495.16$: cartea s-a extins cu 4.84 în fiecare parte, centrul a rămas la $500 + 32.256$.
]

#problema("Interpolarea")[O carte e la $x = 0$, ținta e $100$. Unde e după 2 cadre la 60 FPS? Dar la 30 FPS? Dar după un cadru de 0.2 s?][
60 FPS: $"step" = 8 \/ 60 = 0.1333$; după 2 cadre a rămas $100 dot (1 - 0.1333)^2 = 75.11$, deci $x = 24.89$. 30 FPS: $"step" = 0.2667$, $x = 100 dot (1 - 0.7333^2) = 46.22$ — în același timp (1/15 s) a parcurs mai mult, pentru că formula nu e perfect independentă de FPS. Cadru de 0.2 s: $8 dot 0.2 = 1.6$, `min` îl face 1: sare direct la 100.
]

#problema("Inima, două vârfuri")[Care sunt vârfurile `heart` pentru $i = 16$ și $i = 32$ (din 64)?][
$i = 16$: $theta = pi\/2$, $r = 0.38 (1 - 0) = 0.38$, $(x, y) = (-0.38 dot 1, 0.38 dot 0 + 0.3325) = (-0.38, 0.3325)$: marginea din stânga, la înălțimea cuspidei. $i = 32$: $theta = pi$, $r = 0.76$, $(0, -0.76 + 0.3325) = (0, -0.4275)$: vârful de jos al inimii.
]

#problema("Câți indici")[Câți indici au mesh-urile `circle` (48 de segmente), `star`, `heart` (64), `plus`, `arrow`? Câte triunghiuri desenează o carte Tank cu ATK 3, HP 2, cost 4, fără chenarul și fundalul?][
Evantaiul cu $n$ segmente are $n$ triunghiuri, $3n$ indici: cerc 144, stea 30, inimă 192 (și sabia 192). Plusul 12, săgeata 9. Carte Tank: simbolul romb (2 triunghiuri), 4 cercuri de mana ($4 dot 48$), 3 săbii ($3 dot 64$), 2 inimi ($2 dot 64$): $2 + 192 + 192 + 128 = 514$ triunghiuri.
]

#problema("Cristalele de mana")[Ești în runda ta 4 și ai pus un Silence. Ce culori au cele 10 cristale?][
`maxMana = 4`, `mana = 4 - 2 = 2`: 2 albastre (0, 1), 2 albe (2, 3), 6 negre (4–9).
]

#problema("Un atac")[Cartea ta Lifesteal 4/3 (ATK 4, HP 3) atacă o carte inamică 2/5. Eroul tău are 25 HP. Ce se întâmplă?][
Simultan: a ta $3 - 2 = 1$ HP, a lui $5 - 4 = 1$ HP. Niciuna nu moare. Lifesteal: eroul tău $25 + 4 = 29$. Ambele se scutură 0.6 s; cartea ta nu mai poate ataca în runda asta.
]

#problema("Tank")[Inamicul are pe tablă un Tank 1/6 și o carte 3/1. Cu ce poți ataca cu cartea ta 5/2 și ce rezultă?][
Doar Tank-ul e țintă validă (nici cartea 3/1, nici eroul). Tank $6 - 5 = 1$, a ta $2 - 1 = 1$. Dacă ai un Silence în mână și 2 mana, pune-l întâi și anulează-i Tank-ul: atunci poți ataca direct eroul.
]

#problema("Săgeata")[Cartea selectată are centrul în $(600, 295.2)$, cursorul e în $(700, 495.2)$. Care sunt parametrii celor trei transformări din `DrawArrow`?][
$d = (100, 200)$, $ell = sqrt(100^2 + 200^2) = 223.61$, $theta = "atan2"(200, 100) = 1.107$ rad $= 63.43°$. $M = T(600, 295.2) dot R(1.107) dot S(223.61, 38.71)$ (grosimea $0.6 dot 64.512$). Vârful $(1, 0)$ ajunge în $(600 + 223.61 cos 63.43°, 295.2 + 223.61 sin 63.43°) = (700, 495.2)$.
]

#problema("Timer-ul")[Au mai rămas 12 secunde din tură. Cât de lată e bara galbenă?][
$64.512 dot 12 \/ 30 = 25.80$ (40% din lățimea fundalului).
]

#problema("Shake")[`shakeTimer` tocmai a scăzut la 0.52, apoi la 0.49. Ce unghiuri are cartea în cele două cadre?][
`(int)(0.52 · 20) = 10`, par: $+0.15$. `(int)(0.49 · 20) = 9`, impar: $-0.15$. Unghiul se schimbă la fiecare 0.05 s.
]

#problema("O plasare refuzată")[În runda ta 2 (2 mana, nimic cheltuit) tragi un Charge (cost 3) pe tablă și îl lași la $y = 300$. Ce se întâmplă, în ce funcții?][
`OnMouseBtnPress` îl prinde (`isDragged`; mana nu e verificată aici). `Update` îl mută după cursor. `OnMouseBtnRelease`: $y = 300 in [230.4, 360]$ e bine, tabla are loc, dar $3 > 2$ → plasare invalidă: `ArrangeZone(playerCards, HAND)` îi dă înapoi `targetX, targetY` din mână, iar `Update` îl duce animat înapoi. Mana rămâne 2.
]
