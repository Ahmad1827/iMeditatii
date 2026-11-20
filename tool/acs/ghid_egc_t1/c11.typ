#import "tpl.typ": *

= Inamicul și o tură completă

== `EnemyTurn`: câte o mișcare pe secundă

#cod("Tema1.cpp", 283, 307)

`EnemyTurn` e apelată din `Update` la fiecare cadru cât e tura inamicului. Primele linii o fac să *acționeze o dată pe secundă*: `enemyTimer` scade cu `dt`, iar funcția iese până când ajunge la 0; atunci se resetează la `enemyDelay = 1` și inamicul face *o singură* mișcare. Așa jucătorul vede ce face inamicul, pas cu pas.

Apoi se adună informațiile: cartea deja selectată (`selected`), câte cărți are pe tablă, ce poate juca (din mână, cu `manaCost <= enemy.mana`) și cu ce poate ataca (`CanAttack`).

Fiecare mișcare e prima posibilă din lista:

#tabel(
  columns: (auto, 1fr),
  [*Prioritatea*], [*Mișcarea*],
  [1. are o carte selectată], [atacă cu ea: dacă tu ai Tank, o țintă aleatoare dintre Tank-uri; altfel o țintă aleatoare dintre cărțile tale de pe tablă *și* eroul tău (`pick == targets.size()` înseamnă eroul)],
  [2. are loc pe tablă și o carte jucabilă], [pune o carte aleatoare dintre cele jucabile; dacă e Silence și tu ai Tank/Lifesteal pe tablă, anulează efectul uneia aleatoare],
  [3. are cărți care pot ataca], [*selectează* una aleatoare (se vede chenarul mov o secundă), iar la următoarea mișcare atacă (prioritatea 1)],
  [4. altfel], [`EndTurn()`],
)

#cod("Tema1.cpp", 309, 336)

Un detaliu la ținta aleatoare: `rand() % (targets.size() + 1)` alege uniform un număr între 0 și `targets.size()`; ultimul înseamnă eroul. Cu 3 cărți pe tablă, eroul are șansa $1\/4$. Dacă tabla ta e goală, singura alegere e eroul.

#idee[Selecția într-o secundă și atacul în următoarea fac atacul inamicului *vizibil*: întâi chenarul mov, apoi shake-ul. Enunțul cere doar „mișcări random: plasare cărți, atac cărți inamice”.]

Inamicul pune *toate* cărțile pe care și le permite (prioritatea 2 vine înaintea atacului 3), apoi atacă cu tot ce poate, apoi termină tura. Timer-ul de 30 s merge și în tura lui (`UpdateTimer` nu verifică a cui e tura), dar inamicul termină cu mult înainte.

== O tură completă, pas cu pas

Să zicem că ești în runda ta 4: `maxMana` 4, ai pe tablă o carte Charge 3/2 (ATK 3, HP 2) pusă în runda 3 și o carte Normal 1/1 pusă acum o rundă; inamicul are un Tank 2/4 și un Lifesteal 4/1, eroul lui are 30 HP.

+ *`StartTurn(player, ...)`*: `round = 4`, `maxMana = 4`, `mana = 4`, `turnTimer = 30`, ambele cărți au `hasAttacked = false`, extragi o carte (să zicem un Silence 2/3). Ambele cărți de pe tablă au chenarul verde (`round < 4`).
+ *Tragi Silence-ul* pe tablă: `OnMouseBtnPress` îl găsește în mână → `isDragged`; `Update` îl mută după cursor, desenat deasupra; `OnMouseBtnRelease`: cursorul e la $y = 300 in [230.4, 360]$, ai 2 cărți pe tablă $< 7$, $2 <= 4$ mana → `mana = 2`, `PlayCard` (`round = 4`, nu va putea ataca acum), mâna și tabla se rearanjează animat. Inamicul are Tank și Lifesteal → `isSilencing = true`.
+ *Click pe Tank-ul inamic*: în modul Silence, ținta e validă → `effect = EFFECT_NONE`, `isSilencing = false`. Tank-ul rămâne albastru, dar nu mai protejează.
+ *Click pe cartea Charge* → selectată (chenar mov, mărită ×1.3), săgeata o urmează cursorul.
+ *Click pe eroul inamic*: `ok = 0` (nu mai e niciun Tank activ) și cursorul e în dreptunghiul eroului → `AttackHero`: eroul are $30 - 3 = 27$ HP, se scutură; Charge are `hasAttacked = true`, chenarul verde dispare.
+ *Click pe cartea Normal 1/1, apoi pe Lifesteal-ul 4/1*: `Attack` → Lifesteal $1 - 1 = 0$ HP, Normal $1 - 4 = -3$ HP: *amândouă* mor (`RemoveDead` pe ambele liste), tablele se strâng. (Lifesteal-ul n-a atacat, deci nu fură viață: efectul e doar la atacul *lui*.)
+ *Click pe buton* → `EndTurn`: tura inamicului, care după o secundă începe să joace.

#prof[Dacă te întreabă ceva „ce se întâmplă dacă...”, urmărește exact funcțiile în ordinea din lista de mai sus. Aproape orice întrebare despre logică e despre: ordinea testelor din `OnMouseBtnPress`, condițiile din `CanAttack`, filtrul de Tank (`ok`) sau verificările de la eliberare.]
