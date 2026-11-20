#import "tpl.typ": *

= Ce cere tema și ce ai făcut

== Enunțul pe scurt

Tema 1 din 2026 („Card Games”) cere un joc de cărți 2D în OpenGL și C++, în framework-ul laboratorului, la alegere dintre *Gwent*, *Hearthstone* și *Genius Invokation TCG*. Tu ai ales *Hearthstone*, într-o variantă simplificată: ambii jucători au același erou, aceleași tipuri de cărți și nu există spell-uri.

#tabel(
  columns: (auto, 1fr),
  [*Regula din enunț*], [*Cum e în codul tău*],
  [5 cărți în mână, 25 în pachet], [`FillDeck(..., 30)` apoi de 5 ori `TakeFromDeck` în `Init` (30 − 5 = 25)],
  [eroul: 30 HP, 0 ATK], [`Player::hp = 30`; `AttackHero` nu răspunde cu damage (eroul n-are ATK)],
  [fiecare carte: ATK, HP, cost de mana], [`Card::atk`, `hp`, `manaCost`; ATK și HP aleatoare între 1 și 5, costul după tip],
  [începi cu 1 mana, +1 pe rundă, maxim 10], [`StartTurn`: `maxMana++` dacă `< 10`, apoi `mana = maxMana`],
  [runda se termină la buton], [click în dreptunghiul `endButton` → `EndTurn()`],
  [o carte atacă o dată pe rundă], [`hasAttacked`, resetat în `StartTurn`],
  [cărțile puse în runda curentă nu atacă], [`card.round < round` în `CanAttack` (doar Charge sare peste)],
  [la atac, ambele primesc damage simultan], [`Attack`: `target.hp -= attacker.atk; attacker.hp -= target.atk;`],
  [HP ≤ 0 → cartea e distrusă], [`RemoveDead`: zona devine `DEAD`],
  [jocul se termină când un erou ajunge la 0], [`AttackHero`: `gameOver = true`, ecran verde (ai câștigat) sau roșu],
)

Cerințele *comune* (pentru toate cele trei jocuri) sunt: tabla de joc cu zone, *drag and drop* din mână pe tablă, *extragerea* cărților din pachet cu animație de translație și *organizarea automată* a cărților (centrate, la distanță constantă, cu animație la orice schimbare).

== Baremul și unde e fiecare punct în cod

#barem[Baremul e orientativ: asistentul poate da punctaj parțial sau poate scădea pentru hard-coding. Pentru a fi punctată, tema *trebuie prezentată* la laborator.]

#tabel(
  columns: (1fr, auto, 1.25fr),
  [*Cerința*], [*Puncte*], [*Unde e în cod*],
  table.cell(colspan: 3, fill: gri.lighten(85%))[*Cerințe comune (90p)*],
  [Tabla: două jumătăți], [4], [`DrawBoard`: două benzi verzi + linia galbenă de la `screenH / 2`],
  [Zonele pentru mâini], [3], [`DrawBoard`: benzile maro de jos și de sus, înalte `handH`],
  [Cărți colorate după tip], [2], [`GetTypeStyle(type).color` în `DrawCard`],
  [Simbolul tipului], [2], [`RenderMesh2D(meshes[style.shape], ...)` în `DrawCard`],
  [Proprietățile cărților prin forme], [5], [cele trei coloane (mana, ATK, HP) din `DrawCard`],
  [Pachetele de cărți], [4], [3 dreptunghiuri decalate în `Update`, pentru fiecare pachet],
  [Drag & Drop], [35], [`OnMouseBtnPress` (prinde), `Update` (urmărește), `OnMouseBtnRelease` (lasă / se întoarce)],
  [Extragerea din pachet], [15], [`TakeFromDeck`: cartea pornește din `(deckX, deckY)`],
  [Organizarea automată], [20], [`ArrangeZone` + interpolarea din `Update`],
  table.cell(colspan: 3, fill: gri.lighten(85%))[*Hearthstone de bază (60p)*],
  [Sistemul de mana], [10], [`StartTurn`, verificarea `manaCost <= mana` la plasare],
  [Contur cărți care mai pot ataca], [5], [`DrawCard`: chenar verde dacă `CanAttack(card)`],
  [Buton terminare rundă], [5], [dreptunghiul verde/gri, `EndTurn`],
  [Inamic], [5], [`EnemyTurn`: plasează și atacă la întâmplare],
  [UI viață erou + cristale mana], [10], [`DrawHero` (inimi), `DrawMana` (romburi albastre/albe/negre)],
  [Atac (4 × 5p)], [20], [selectare proprie, selectare inamic, `Attack`, `RemoveDead`],
  [Sfârșitul jocului], [5], [`AttackHero`, `gameOver`, ecranul final],
  table.cell(colspan: 3, fill: gri.lighten(85%))[*Hearthstone avansat (75p)*],
  [Săgeata la atac], [10], [`DrawArrow`, mesh-ul `arrow`],
  [Timer], [10], [`time.cpp`: `UpdateTimer`, `DrawTimer`],
  [Simboluri complexe HP / ATK / MP], [10], [`CreateHeart`, `CreateSword`, `CreateCircle`],
  [Lifesteal / Charge / Tank / Silence], [5 + 5 + 10 + 5], [`Attack`, `CanAttack`, filtrul `ok` din atac, `isSilencing`],
  [Scalare la hover și selectare], [10], [`Update`: `scale = 1.15` / `1.3`, `DrawCard` centrează],
  [Animația de atac (shake)], [10], [`shakeTimer`, `angle` în `Update`; rotația în `DrawCard`],
)

Ai implementat *toate* cerințele de bază și *toate* cele avansate: 150 + 75 = 225 de puncte posibile din barem, fără bonusuri.

== Fișierele temei

#tabel(
  columns: (auto, 1fr),
  [*Fișier*], [*Ce conține*],
  [`Tema1.h`], [clasa `m1::Tema1`, derivată din `gfxc::SimpleScene`: metodele și toți membrii (dimensiuni, poziții, vectorii de cărți, cei doi jucători)],
  [`Tema1.cpp`], [aproape tot: `Init`, logica jocului, desenarea, mouse-ul, inamicul, animațiile],
  [`time.cpp`], [timer-ul rundei: `UpdateTimer` și `DrawTimer` (tot metode ale lui `Tema1`, doar puse în alt fișier)],
  [`Card.h`], [`Zone`, `CardType`, `Effect`, `TypeStyle`, `GetTypeStyle` și structura `Card`],
  [`Player.h`], [structura `Player`: viață, mana, runda, rândul cui e, shake-ul eroului],
  [`object2D.h/.cpp`], [din laboratorul 3: `CreateSquare`, `CreateRectangle`],
  [`shapes.h/.cpp`], [formele tale: plus, triunghi, romb, stea, cerc, săgeată, inimă, sabie],
  [`transform2D.h`], [matricele 3 × 3: `Translate`, `Scale`, `Rotate`],
)

Tema se pornește din `main.cpp` (`World *world = new m1::Tema1();`) și e inclusă în `lab_list.h` cu `#include "lab_m1/Tema1/Tema1.h"`, cum cere enunțul.

#prof[Prima întrebare e de obicei „arată-mi jocul și spune-mi ce ai implementat”. Ai pregătit în minte lista de mai sus, *în ordinea baremului*: tabla, drag and drop, extragerea, aranjarea, mana, conturul, butonul, inamicul, UI, atacul, final; apoi avansatele: săgeata, timer-ul, simbolurile, cele 4 efecte, hover și shake. Arată fiecare în joc când o spui.]
