#import "tpl.typ": *

= Întrebări de la prezentare

Răspunsuri scurte, cum le-ai spune cu voce tare. Fiecare trimite la capitolul unde e explicat pe larg.

== Framework și OpenGL

#intrebare[Ce e un mesh și ce face `InitFromData`?][O listă de vârfuri (poziție + culoare) și o listă de indici. `InitFromData` le copiază pe GPU: un VBO cu vârfurile, un IBO cu indicii și un VAO care descrie formatul. Se face o dată, în `Init`; la desen doar se leagă VAO-ul și se apelează `glDrawElements` (cap. 2).]

#intrebare[De ce indici și nu doar vârfuri?][Ca un vârf folosit de mai multe triunghiuri să fie stocat o singură dată. La cerc, centrul e în toate cele 48 de triunghiuri, dar e un singur vârf (cap. 5).]

#intrebare[Ce diferență e între `GL_TRIANGLES` și `GL_LINE_LOOP`?][Cu `GL_TRIANGLES`, fiecare 3 indici sunt un triunghi plin. Cu `GL_LINE_LOOP`, indicii sunt vârfurile unui contur închis (ultimul se leagă de primul). `CreateRectangle` folosește primul pentru `fill = true` (indicii `0,1,2,3,0,2` = două triunghiuri) și al doilea pentru contur.]

#intrebare[Ce culoare are un mesh? Toate sunt albe.][Culoarea vârfurilor nu contează la `RenderMesh2D(mesh, matrice, culoare)`: shader-ul `Color` colorează tot mesh-ul cu culoarea uniformă primită. De aceea un singur mesh `heart` dă inimi roșii pe cărți și pe erou.]

#intrebare[Ce fel de proiecție folosești și de ce?][Ortografică, `SetOrthographic(0, 1280, 0, 720, ...)`: e un joc 2D, fără perspectivă; o unitate a scenei e un pixel la rezoluția inițială, originea stânga-jos (cap. 2).]

#intrebare[Cum transformi coordonatele mouse-ului?][Fereastra are originea sus-stânga și $y$ în jos; scena are originea jos-stânga. $x = x_m dot "screenW" \/ "res.x"$, $y = "screenH" - y_m dot "screenH" \/ "res.y"$. Împărțirea la rezoluția curentă face click-urile corecte și după redimensionare.]

#intrebare[De ce `button == 1` înseamnă click stânga?][Framework-ul trimite o mască de biți: butonul GLFW $k$ setează bitul $k$. Stânga e butonul 0, deci `1 << 0 = 1` (cap. 2).]

#intrebare[De ce ai dezactivat testul de adâncime?][Toate formele au $z = 0$; ordinea pe ecran o dă ordinea de desen (algoritmul pictorului). Desenez de jos în sus: tabla, pachetele, eroii, cărțile, cartea trasă, săgeata, ecranul final.]

#intrebare[Unde desenezi și unde tratezi input-ul?][Input-ul doar schimbă starea (cursor, `isDragged`, `isSelected`, atacuri). Tot desenul e în `Update`, la fiecare cadru, din starea curentă.]

#intrebare[Ce e `deltaTimeSeconds` și unde îl folosești?][Timpul de la cadrul anterior. Îl folosesc la timer, la ritmul inamicului (o mișcare pe secundă), la shake și la pasul interpolării, ca jocul să meargă la fel de repede la orice FPS.]

== Transformări

#intrebare[De ce matrice 3 × 3 pentru 2D?][Coordonate omogene: cu $(x, y, 1)$, translația devine o înmulțire de matrice, deci orice combinație de translații, rotații și scalări e o singură matrice (cap. 3).]

#intrebare[De ce `glm::transpose` în `transform2D.h`?][GLM e column-major: constructorul `mat3(...)` umple coloană cu coloană. Am scris matricele rând cu rând, ca pe hârtie, deci le transpun ca să fie corecte.]

#intrebare[În ce ordine se aplică $T(x, y) dot S(w, h)$?][De la dreapta la stânga: întâi scalarea (pătratul unitate devine $w × h$, cu colțul în origine), apoi translația. Invers, s-ar scala și translația.]

#intrebare[Cum rotești cartea în jurul centrului ei?][$T(c) dot R(alpha) dot T(-c)$: aduc centrul în origine, rotesc, îl duc înapoi. Matricea e `parent` pentru toate bucățile cărții, deci se rotește ca un întreg.]

#intrebare[De ce formele tale sunt centrate în origine și încap în $[-0.5, 0.5]^2$?][Ca să le pot scala „pe loc” cu `Scale(size, size)` și să le poziționez după centru; toate au aceeași mărime de bază, deci același `size` dă simboluri de aceeași mărime.]

#intrebare[Cum desenezi săgeata?][Mesh-ul merge de la $(0, 0)$ la $(1, 0)$. $T("start") dot R("atan2"(d_y, d_x)) dot S(ell, "grosime")$, cu $ell$ distanța până la cursor: vârful ajunge exact în cursor.]

== Forme

#intrebare[Cum ai desenat cercul? Câte triunghiuri?][Evantai din centru: centrul plus 48 de puncte pe cerc la unghiurile $2 pi i \/ 48$; triunghiurile $(0, i + 1, (i+1) mod 48 + 1)$. 48 de triunghiuri, 144 de indici. Modulo-ul închide cercul.]

#intrebare[Cum ai făcut inima?][Cardioida $r = a(1 - cos theta)$ din enunț, rotită cu 90° ($x = -r sin theta$, $y = r cos theta$) ca scobitura să fie sus și vârful jos, plus $0.875a$ pe $y$ ca să fie centrată (y între $-2a$ și $a\/4$). Evantai din pol (cuspida). $a = 0.38$ ca să încapă în pătratul unitate.]

#intrebare[Și sabia?][$r = a + b sin(3 theta) \/ (1.05 + cos 2 theta)$: numitorul aproape se anulează la $theta = pi\/2, 3pi\/2$, deci acolo raza explodează și dă lama. Am turtit-o pe $y$ (0.38), am oglindit-o ca lama să fie sus și am centrat-o cu $-0.385$.]

#intrebare[Cum e făcută steaua?][Evantai din centru cu 10 puncte, raza alternând 0.5 (colțuri) și 0.2 (scobituri), pornind de la $pi\/2$ ca primul colț să fie sus.]

== Logica

#intrebare[Cum aranjezi cărțile?][$x_k = ("screenW" - (n w + (n-1) g)) \/ 2 + k (w + g)$, cu $k$ numărând doar cărțile din zonă, în ordinea din vector, deci ordinea relativă se păstrează. `ArrangeZone` setează doar ținta; mișcarea e în `Update` (cap. 6).]

#intrebare[Cum faci animația de translație?][La fiecare cadru $x += (x_"țintă" - x) dot min(1, 8 d t)$: o fracțiune fixă din distanța rămasă, deci ease-out exponențial. La fel pentru $y$, $w$, $h$ (cap. 10).]

#intrebare[Cum verifici plasarea pe tablă?][La eliberare: cursorul în $[0, 1280] × [230.4, 360]$ (jumătatea mea), mai puțin de 7 cărți pe tablă și `manaCost <= mana`. Altfel, `ArrangeZone(HAND)` și cartea se întoarce animat.]

#intrebare[De ce nu poate ataca o carte pusă în runda curentă?][`card.round` ține runda proprietarului în care a fost pusă; `CanAttack` cere `card.round < round`. Excepție: Charge.]

#intrebare[Cum funcționează Tank?][Înainte de atac verific dacă adversarul are un Tank pe tablă (`ok`). Dacă da, doar Tank-urile sunt ținte valide, iar eroul nu poate fi atacat. Aceeași regulă și pentru inamic.]

#intrebare[Ce se întâmplă când ambele cărți mor?][`Attack` scade HP-ul la amândouă simultan, apoi `RemoveDead` pe ambele liste: ambele trec în `DEAD`, nu se mai desenează, iar tablele se rearanjează.]

#intrebare[De ce nu ștergi cărțile moarte din vector?][Ca referințele (`Card&`) să rămână valide și indicii să nu se schimbe în mijlocul unei bucle. O carte moartă e doar marcată `DEAD` și sărită peste tot.]

#intrebare[Cum funcționează inamicul?][O mișcare pe secundă: dacă are o carte selectată, atacă cu ea o țintă aleatoare (respectând Tank-ul); altfel pune o carte aleatoare pe care și-o permite; altfel selectează un atacator aleator; altfel termină tura (cap. 11).]

#intrebare[Ce se întâmplă când expiră cele 30 de secunde?][`UpdateTimer` ajunge la 0 și apelează `EndTurn()`, ca și cum ai fi apăsat butonul. Cartea pe care o țineai se întoarce în mână.]

#intrebare[Când se termină jocul?][Când un erou ajunge la HP ≤ 0, în `AttackHero` (singurul loc unde eroul primește damage): `gameOver = true`, input-ul se oprește și apare dreptunghiul verde sau roșu.]

#intrebare[Ce ai schimba dacă ai avea mai mult timp?][Funcție comună pentru shake, plafon de viață la Lifesteal, `OnWindowResize` care recalculează layout-ul, text pentru valori (bonus), un inamic mai inteligent (de ex. să atace doar când supraviețuiește). Vezi capitolul următor.]
