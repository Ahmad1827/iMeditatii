#import "tpl.typ": *

= Animațiile

Toate animațiile tale sunt făcute în `Update`, din două mecanisme: *apropierea de țintă* (translații și scalări) și *timer-ul de shake* (rotații).

== Apropierea de țintă (interpolare exponențială)

#cod("Tema1.cpp", 594, 615)

La fiecare cadru, fiecare valoare (`x`, `y`, `w`, `h`) parcurge o *fracțiune fixă* din distanța rămasă până la țintă:

$ x arrow.l x + (x_"țintă" - x) dot "step", quad "step" = min(1, 8 dot d t) $

Distanța rămasă se înmulțește la fiecare cadru cu $1 - "step"$, deci scade *exponențial*: mișcarea e rapidă la început și încetinește lin la sosire (un _ease-out_), fără să depășească ținta. Funcționează la fel pentru orice schimbare de țintă, chiar în mijlocul unei mișcări: dacă ținta se schimbă (o altă carte pleacă din mână), cartea pur și simplu o ia spre noua țintă, din locul în care e.

*Un exemplu cu numere*: o carte nouă pleacă din pachet ($x = #g.deal.x0$) spre locul 6 din mână ($x = #g.deal.tx$), la 60 de cadre pe secundă ($"step" = #g.deal.step$):

#tabel(
  columns: g.deal.frames.len() + 1,
  [*cadrul*], ..g.deal.frames.map(f => [#f.at(0)]),
  [*x*], ..g.deal.frames.map(f => [#f.at(1)]),
)

În jumătate de secundă (30 de cadre) a parcurs peste 98% din drum. Cât durează până ajunge la mai puțin de 1 unitate de țintă:

#tabel(
  columns: 3,
  [*FPS*], [*cadre*], [*secunde*],
  ..g.deal_fps.map(x => (str(x.at(0)), str(x.at(1)), str(x.at(2)))).flatten(),
)

#idee[Factorul `8 · dt` face viteza *aproape* independentă de FPS (cu cât sunt mai multe cadre, cu atât pasul e mai mic). Nu perfect: forma exactă ar fi $"step" = 1 - e^(-8 d t)$; pentru `dt` mic, $1 - e^(-8 d t) approx 8 d t$, deci diferența se vede doar la FPS foarte mic. `min(1, ...)` împiedică depășirea țintei dacă un cadru durează mai mult de $1\/8$ s (pas 1 = sare direct în țintă).]

Cu acest singur mecanism ai rezolvat patru cerințe:

#tabel(
  columns: (auto, 1fr),
  [*Cerința*], [*Ce schimbă ținta*],
  [extragerea din pachet], [`TakeFromDeck`: poziția curentă = pachetul, ținta = locul din mână],
  [organizarea automată], [`ArrangeZone` după orice schimbare: celelalte cărți se strâng sau se depărtează],
  [întoarcerea după o plasare invalidă], [`ArrangeZone(HAND)` în `OnMouseBtnRelease`],
  [drag and drop], [ținta = cursorul, la fiecare cadru],
)

Cărțile inamicului folosesc aceeași apropiere pentru `x` și `y` (liniile 629–631): și ele vin din pachet, se strâng în mână și merg pe tablă animat.

== Scalarea la hover și la selectare

Ținta de mărime (liniile 603–610): normală (×1), *×1.15* când cursorul e deasupra, *×1.3* când e selectată (selectarea are prioritate). Mărimea curentă se apropie de țintă la fel ca poziția, deci cartea *crește și scade lin*. `DrawCard` o desenează centrată pe locul ei (capitolul 7). Doar cărțile tale au hover și selectare; ale inamicului nu se scalează.

== Shake-ul (animația de atac)

#cod("Tema1.cpp", 617, 627)

`Attack` și `AttackHero` pun `shakeTimer = 0.6` (secunde) pe ambii participanți. La fiecare cadru timer-ul scade cu `dt`; cât e pozitiv, unghiul sare între *+0.15* și *−0.15* radiani ($approx plus.minus 8.6 degree$), după paritatea lui `(int)(shakeTimer * 20)`: valoarea se schimbă la fiecare $1\/20 = 0.05$ s, deci în 0.6 s sunt 12 schimbări (6 oscilații complete). Când timer-ul ajunge la zero, unghiul revine la 0 și cartea stă dreaptă.

#tabel(
  columns: 3,
  [*shakeTimer*], [*(int)(shakeTimer · 20)*], [*angle*],
  ..g.shake.map(x => (str(x.at(0)), str(x.at(1)), str(x.at(2)))).flatten(),
)

Unghiul e folosit în `DrawCard` (și `DrawHero` pentru eroi) ca rotație în jurul centrului: exact cerința „își modifică rotația între 2 praguri de câteva ori după efectuarea atacului”.

#capcana[Codul de shake e scris de patru ori (cărțile tale, ale inamicului, eroul tău, eroul inamic), aproape identic. Un asistent poate întreba „de ce nu o funcție?”. Răspuns onest: ar fi mai curat ca o funcție `UpdateShake(float& timer, float& angle, float dt)`; comportamentul e același.]

#prof[„Arată-mi animațiile.” Ordinea bună: (1) pornește jocul — cărțile vin din pachet; (2) trage o carte și las-o în afara tablei — se întoarce; (3) pune o carte — mâna se strânge, tabla se centrează; (4) trece cu mouse-ul peste o carte — crește; selecteaz-o — crește mai mult, apare săgeata; (5) atacă — ambele se scutură, cea moartă dispare și tabla se strânge.]
