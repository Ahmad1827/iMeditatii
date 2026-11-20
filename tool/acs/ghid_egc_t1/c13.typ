#import "tpl.typ": *

= Puncte slabe și cum le explici

Nimic de aici nu e o cerință neîndeplinită. Sunt lucrurile pe care un asistent atent le poate observa în cod; e bine să le știi înaintea lui și să ai răspunsul pregătit.

#tabel(
  columns: (auto, 1fr, 1fr),
  [*Ce*], [*De ce se întâmplă*], [*Ce spui*],
  [Viața eroului trece de 30], [Lifesteal face `owner.hp += atk` fără plafon; apare a 4-a coloană de inimi], [Enunțul nu cere plafon; s-ar rezolva cu `min(30, ...)`],
  [Codul de shake repetat de 4 ori], [aceeași logică pentru cărțile tale, ale inamicului și cei doi eroi], [ar merge într-o funcție `UpdateShake(timer, angle, dt)`; comportamentul e identic],
  [La redimensionare, scena se întinde], [`OnWindowResize` e gol; layout-ul e calculat o dată], [click-urile rămân corecte datorită conversiei; pentru proporții păstrate, ar trebui recalculat layout-ul],
  [Mâna plină: cartea rămâne în pachet], [`TakeFromDeck` iese dacă sunt 10 cărți în mână], [în Hearthstone cartea s-ar arde; enunțul lasă la latitudinea ta],
  [Pachet gol: nimic], [`TakeFromDeck` iese], [fără „fatigue”; nu e cerut],
  [Inamicul atacă și sinucigaș], [ținte complet aleatoare], [enunțul cere mișcări random; un algoritm mai bun e bonus],
  [Selecția rămâne dacă dai click în gol], [nu există deselectare la click pe fundal], [deselectezi cu click din nou pe aceeași carte sau alegi alta],
  [În modul Silence, butonul nu răspunde], [tot click-ul e consumat de alegerea țintei], [există mereu o țintă (modul pornește doar dacă există), iar timer-ul termină oricum tura],
  [Cărțile moarte rămân în vector], [doar `zone = DEAD`], [intenționat: referințe valide; sunt cel mult 30 de cărți pe jucător],
  [Zona de click e mărimea normală], [testele folosesc `cardW`, `cardH`, nu `w`, `h`], [intenționat: cartea mărită nu „fură” click-urile vecinelor],
)

#capcana[Nu spune „nu știu de ce merge”. Dacă nu-ți amintești o linie, citește-o cu voce tare și explic-o pe loc: codul tău e scurt și fiecare funcție face un singur lucru.]
