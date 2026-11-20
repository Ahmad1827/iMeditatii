#import "tpl.typ": *

= Logica jocului

== Începutul: `Init`, partea de joc

#cod("Tema1.cpp", 99, 114)

+ Câte 30 de cărți aleatoare în fiecare pachet (`FillDeck`).
+ Câte 5 extrase pentru fiecare (`TakeFromDeck`): 5 în mână, 25 în pachet, ca în enunț. Toate pornesc din poziția pachetului, deci la pornire se vede animația împărțirii.
+ Mana pusă pe 0, apoi `StartTurn(player, ...)`: runda 1 a jucătorului, `maxMana` devine 1, mana 1, și se mai extrage o carte. Prima ta tură începe cu 6 cărți în mână și 1 mana.

#capcana[`Player` are inițial `mana = 1, maxMana = 1`. Dacă nu le-ai pune pe 0 în `Init`, `StartTurn` le-ar crește la 2 chiar din prima rundă. De aceea liniile 108–111.]

== `FillDeck`

#cod("Tema1.cpp", 117, 133)

ATK și HP sunt aleatoare în ${1, ..., 5}$ (`1 + rand() % 5`), tipul aleator dintre cele 5 (`rand() % TYPE_COUNT`, convertit la `CardType`). Costul și efectul vin din tip, prin `GetTypeStyle`. Mărimea curentă și cea țintă pornesc egale cu mărimea normală. `srand(time(NULL))` din `Init` face ca pachetele să fie altele la fiecare pornire.

== `TakeFromDeck`: o carte din pachet în mână

#cod("Tema1.cpp", 136, 166)

+ Pachet gol → nimic.
+ Mâna plină (10 cărți *în mână*, numărate după `zone`) → nimic: cartea rămâne în pachet.
+ Altfel: ultima carte din pachet (`back()` + `pop_back()`, $O(1)$), trece în zona `HAND`, *poziția ei curentă e pusă pe pachet* (al jucătorului sau al inamicului) și e adăugată în vectorul de cărți.
+ `ArrangeZone(cards, HAND)` îi dă poziția țintă în mână (și le mută pe celelalte ca grupul să rămână centrat).

Animația cerută de enunț („cartea apare în zona pachetului și se deplasează spre poziția finală din mână”) iese singură: poziția curentă e pachetul, ținta e locul din mână, iar `Update` o apropie cadru cu cadru.

== `PlayCard`: din mână pe tablă

#cod("Tema1.cpp", 169, 180)

Cartea trece în `BOARD` și ține minte *runda proprietarului* în care a fost pusă. Apoi se rearanjează *ambele* zone: mâna (a rămas un gol) și tabla (a apărut o carte). Mana o scade apelantul (`OnMouseBtnRelease` sau `EnemyTurn`), după ce a verificat că ajunge.

== Rundele: `StartTurn` și `EndTurn`

#cod("Tema1.cpp", 245, 280)

`StartTurn` pentru un jucător: e rândul lui, `round++`, `maxMana` crește cu 1 până la 10, mana se *reumple* (`mana = maxMana`), timer-ul repornește de la 30 s, *toate* cărțile lui pot ataca din nou (`hasAttacked = false`), extrage o carte.

`EndTurn` știe a cui e tura după `player.isMyTurn`:
- *din tura ta*: anulează Silence-ul neterminat, deselectează și „lasă din mână” orice carte (dacă ții o carte trasă când expiră timpul, ea se întoarce în mână prin `ArrangeZone`), apoi pornește tura inamicului și îi dă o secundă (`enemyTimer = enemyDelay`) până la prima mișcare;
- *din tura inamicului*: pornește tura ta.

#capcana[Parametrul lui `StartTurn` se numește tot `player`, ca membrul clasei. În funcție, `player` e *parametrul* (care poate fi `enemy`): îl *ascunde* (shadowing) pe membrul `this->player`. E corect, dar e o întrebare bună la prezentare: „în `StartTurn(enemy, ...)`, ce `player` se modifică?” — inamicul.]

#tabel(
  columns: (auto, auto, auto),
  [*Runda proprie*], [*maxMana*], [*Ce poți pune (costuri: Normal 1, Silence 2, Charge 3, Lifesteal 3, Tank 4)*],
  [1], [1], [doar Normal],
  [2], [2], [2 × Normal sau Silence],
  [3], [3], [Charge sau Lifesteal, sau combinații de cost total ≤ 3],
  [4], [4], [și Tank],
  [10 și după], [10], [plafonul],
)

== `CanAttack`

#cod("Tema1.cpp", 183, 192)

O carte poate ataca dacă *toate* sunt adevărate:
+ e pe tablă;
+ e tura proprietarului ei;
+ a fost pusă într-o rundă *anterioară* a proprietarului (`card.round < round`) *sau* are Charge;
+ n-a atacat deja în runda asta.

Comparația folosește runda *proprietarului* (`player.round` sau `enemy.round`), pentru că fiecare jucător își numără propriile runde. O carte pusă de tine în runda 3 are `round = 3`; în runda ta 4, $3 < 4$ și poate ataca. Aceeași funcție decide și chenarul verde (`DrawCard`), și dacă poți selecta cartea, și ce cărți poate folosi inamicul.

== `Attack` și `AttackHero`

#cod("Tema1.cpp", 195, 230)

*Carte contra carte*: amândouă primesc damage *simultan* — fiecare pierde din HP cât e ATK-ul celeilalte — exact formula din enunț: A $(X "HP", Y "ATK")$ contra B $(Z "HP", W "ATK")$ → A rămâne cu $X - W$, B cu $Z - Y$. Apoi: atacatorul e marcat că a atacat și deselectat, ambele încep să se scuture (`shakeTimer = 0.6`), Lifesteal adaugă ATK-ul atacatorului la viața eroului propriu (`owner`), iar cărțile cu HP ≤ 0 sunt scoase din joc (`RemoveDead` pe *ambele* liste: pot muri amândouă).

*Carte contra erou*: doar eroul primește damage (eroul are 0 ATK, deci nu răspunde). Dacă eroul ajunge la HP ≤ 0, jocul se termină.

#idee[Atacatorul e `Card&`, o *referință* la elementul din vector. `RemoveDead` nu șterge elemente (schimbă doar `zone`), deci referința rămâne validă. Dacă ai fi folosit `erase`, după `RemoveDead` referințele ar fi putut indica alte cărți.]

== `RemoveDead`

#cod("Tema1.cpp", 233, 242)

Cărțile de pe tablă cu HP ≤ 0 trec în zona `DEAD` (nu se mai desenează, nu se mai numără, nu se mai pot selecta) și se deselectează. Apoi tabla se rearanjează: cărțile rămase se strâng, centrate, cu animație.

== Efectele speciale

#tabel(
  columns: (auto, 1fr, auto),
  [*Efect*], [*Cum e implementat*], [*Unde*],
  [Charge], [`|| card.effect == EFFECT_CHARGE` în `CanAttack`: ignoră regula rundei], [`CanAttack`],
  [Lifesteal], [`owner.hp += attacker.atk` după atac (și pe carte, și pe erou)], [`Attack`, `AttackHero`],
  [Tank], [dacă adversarul are măcar un Tank pe tablă (`ok = 1`), țintele permise sunt *doar* Tank-urile, iar eroul *nu* poate fi atacat], [`OnMouseBtnPress`, `EnemyTurn`],
  [Silence], [la plasare, dacă inamicul are pe tablă un Tank sau un Lifesteal, intri în modul `isSilencing`: următorul click valid pe o astfel de carte îi face `effect = EFFECT_NONE`], [`OnMouseBtnRelease`, `OnMouseBtnPress`],
)

#prof[„Ce face Silence?” — „Când pun pe tablă o carte Silence și inamicul are o carte cu Tank sau Lifesteal, aleg una dintre ele cu click și îi anulez efectul. Cartea rămâne de același tip vizual (culoarea și simbolul vin din `type`), dar `effect` devine `EFFECT_NONE`, deci nu mai protejează eroul și nu mai fură viață.” Arată în joc: după Silence pe Tank, poți ataca eroul.]
