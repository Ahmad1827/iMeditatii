#import "tpl.typ": *

= Mouse-ul: drag and drop, selecție, atac

== Testul „e cursorul în dreptunghi?”

Peste tot apare același test din enunț:

$ x_min <= x_"mouse" <= x_max quad "și" quad y_min <= y_"mouse" <= y_max $

la tine scris ca `card.x <= mx && mx <= card.x + cardW && card.y <= my && my <= card.y + cardH`. Se folosesc mărimea și poziția *normale* ale cărții (`cardW`, `cardH`, colțul `x, y`), nu cele mărite de hover: zona de click nu „sare” când cartea crește.

== `OnMouseMove`: cursorul și hover-ul

#cod("Tema1.cpp", 740, 752)

Salvează cursorul (în coordonatele scenei: îl folosesc săgeata și cartea trasă) și marchează ca `isHovered` cărțile *tale* din mână sau de pe tablă aflate sub cursor. Scalarea efectivă se face în `Update`.

== `OnMouseBtnPress`: ce înseamnă un click

#cod("Tema1.cpp", 761, 796)

Testele sunt în *ordinea priorităților*; primul care se potrivește face ceva și iese (`return`):

+ nu e click stânga, nu e tura ta sau jocul s-a terminat → nimic;
+ conversia cursorului (capitolul 2);
+ *modul Silence*: tot click-ul e „consumat” — dacă ai nimerit o carte inamică de pe tablă cu Tank sau Lifesteal, îi anulezi efectul și ieși din mod; altfel nu se întâmplă nimic (nici butonul, nici selecția);
+ *butonul de final* → `EndTurn()`.

#cod("Tema1.cpp", 798, 829)

5. *Ai o carte selectată* (atac în curs): verifici întâi dacă inamicul are Tank (`ok`). Click pe o carte inamică de pe tablă *permisă* (orice carte dacă nu există Tank, altfel doar Tank-urile) → `Attack`. Click pe eroul inamic, doar dacă nu există Tank → `AttackHero`. Dacă nu ai nimerit o țintă, continui (poate vrei să selectezi altă carte).

#cod("Tema1.cpp", 831, 857)

6. *Click pe o carte proprie de pe tablă*: dacă era selectată, o deselectezi; altfel, dacă poate ataca, deselectezi tot și o selectezi pe ea (cel mult o carte selectată). O carte care nu poate ataca ignoră click-ul.
+ *Click pe o carte din mână*: o prinzi (`isDragged = true`). Bucla merge *de la sfârșit spre început*: cărțile de la sfârșitul vectorului sunt desenate ultimele, deci sunt deasupra; dacă două cărți s-ar suprapune, o prinzi pe cea de sus. `break`: o singură carte.

#capcana[O carte se poate *prinde* oricând în tura ta, chiar dacă nu ai mana pentru ea; verificarea manei se face abia la eliberare. E intenționat: poți „încerca” s-o pui, iar dacă nu ai mana, se întoarce animat în mână (plasare invalidă).]

== Deplasarea

Cât timp ții butonul apăsat, cartea are `isDragged == true`, iar în fiecare cadru `Update` îi pune ținta în cursor, cu centrul cărții sub vârful cursorului:

#cod("Tema1.cpp", 598, 601)

Cartea nu sare direct la cursor, ci se apropie rapid de el (interpolarea din capitolul 10): de aceea pare să-l urmeze lin, cu o mică întârziere.

== `OnMouseBtnRelease`: plasare validă sau nu

#cod("Tema1.cpp", 860, 904)

La eliberare, pentru cartea trasă (cel mult una):

- *plasare validă*, dacă *toate* sunt adevărate: cursorul e în jumătatea ta de tablă ($0 <= x <= "screenW"$, $"handH" + "heroZoneH" <= y <= "screenH" \/ 2$, adică $y in [230.4, 360]$), ai mai puțin de 7 cărți pe tablă și destulă mana (`manaCost <= mana`). Atunci plătești mana, `PlayCard` și, pentru o carte Silence, intri în modul Silence dacă inamicul are o țintă (Tank sau Lifesteal pe tablă);
- *plasare invalidă*, altfel: `ArrangeZone(playerCards, HAND)` îi redă ținta din mână, iar `Update` o duce acolo animat (translație), cum cere enunțul.

#prof[„Cum verifici unde ai lăsat cartea?” — „La eliberarea butonului, cu același test de dreptunghi ca la selecție, dar pe dreptunghiul jumătății mele de tablă: $[0, 1280] × [230.4, 360]$. Pe lângă poziție, verific și limita de 7 cărți și mana. Dacă vreuna nu e îndeplinită, cartea primește înapoi ținta din mână și se întoarce animat.”]
