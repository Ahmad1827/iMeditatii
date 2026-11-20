#import "tpl.typ": *

= Framework-ul, cât îți trebuie

== Ciclul de viață al unei scene

`Tema1` moștenește `gfxc::SimpleScene`. Framework-ul deschide fereastra (1280 × 720, din `main.cpp`), apelează o dată `Init()`, apoi intră în bucla principală. La *fiecare cadru* (frame), în ordinea aceasta:

#tabel(
  columns: (auto, 1fr),
  [*Pas*], [*Ce face la tine*],
  [evenimentele de input], [`OnMouseMove`, `OnMouseBtnPress`, `OnMouseBtnRelease` (doar dacă s-a întâmplat ceva); `OnInputUpdate` mereu],
  [`FrameStart()`], [șterge ecranul cu culoarea de fundal, setează viewport-ul, oprește testul de adâncime],
  [`Update(dt)`], [timer-ul, inamicul, animațiile *și* tot desenul],
  [`FrameEnd()`], [nimic],
  [swap buffers], [framework-ul afișează imaginea desenată (double buffering)],
)

`dt` (`deltaTimeSeconds`) e timpul scurs de la cadrul anterior, în secunde: la 60 de cadre pe secundă, `dt ≈ 0,0167`. Tot ce se mișcă *în timp* (timer-ul, shake-ul) folosește `dt`, ca jocul să meargă la fel de repede pe orice calculator.

#capcana[`OnMouseMove` & co. nu desenează nimic. Ele doar *schimbă starea* (poziția cursorului, `isDragged`, `isSelected`). Desenul se face integral în `Update`, din starea curentă. E modelul „imediat”: la fiecare cadru, totul se redesenează de la zero.]

== Mesh-uri: vârfuri și indici

Un *mesh* e o listă de vârfuri plus o listă de indici. Fiecare vârf (`VertexFormat`) are o poziție (`glm::vec3`) și o culoare. Indicii spun ce vârfuri formează fiecare primitivă: cu modul implicit `GL_TRIANGLES`, fiecare *trei* indici consecutivi sunt un triunghi.

```cpp
Mesh* mesh = new Mesh(name);
mesh->InitFromData(vertices, indices);   // urcă datele pe GPU (VAO, VBO, IBO)
AddMeshToList(mesh);                     // meshes[name] = mesh
```

`InitFromData` creează pe placa video un *VBO* (vertex buffer: vârfurile), un *IBO* (index buffer: indicii) și un *VAO* (cum se citesc vârfurile). Se face *o singură dată*, în `Init`. La desen, `mesh->Render()` doar leagă VAO-ul și apelează `glDrawElements`.

#idee[Toate formele tale sunt definite *o singură dată*, în coordonate mici (în jurul originii, cam în pătratul $[-0.5, 0.5]^2$), cu culoarea albă. Mărimea, poziția, rotația și culoarea le dai la fiecare desen, prin *matricea de modelare* și parametrul `color`. Așa, același mesh `heart` desenează toate inimile din joc.]

De ce culoarea din vârfuri nu contează: `RenderMesh2D(mesh, matrice, culoare)` folosește shader-ul `"Color"`, care colorează tot mesh-ul cu culoarea uniformă trimisă (`glUniform3f(..."color"...)`), ignorând culoarea vârfurilor.

== Camera ortografică și coordonatele scenei

În `Init`:

#cod("Tema1.cpp", 31, 40)

- `SetOrthographic(0, screenW, 0, screenH, ...)`: proiecție *ortografică* (fără perspectivă) în care scena vizibilă e dreptunghiul $[0, 1280] × [0, 720]$. O unitate în scenă = un pixel (la rezoluția inițială).
- Originea scenei e *colțul stânga-jos*, axa $y$ în sus.
- Camera stă în $z = 50$ și privește spre $-z$; formele 2D au $z = 0$, deci sunt între planele `near = 0.01` și `far = 800`.
- `GetCameraInput()->SetActive(false)` oprește controlul camerei cu tastatura/mouse-ul (altfel click dreapta + WASD ar muta camera).

== Coordonatele mouse-ului

Framework-ul dă poziția mouse-ului în *pixeli de fereastră*: originea în colțul *stânga-sus*, $y$ în jos. Scena are $y$ în sus. Conversia, la tine în `OnMouseMove` (și identic în `OnMouseBtnPress/Release`):

#cod("Tema1.cpp", 742, 744)

$ x_"scenă" = x_"mouse" dot "screenW" / "res.x", quad y_"scenă" = "screenH" - y_"mouse" dot "screenH" / "res.y" $

Împărțirea la rezoluția *curentă* (`window->GetResolution()`) face ca, dacă fereastra e redimensionată, click-urile să cadă tot pe obiectele corecte: scena rămâne $1280 × 720$ unități, doar pixelii se întind.

#tabel(
  columns: 3,
  [*Mouse (pixeli)*], [*Scenă*], [*Unde e*],
  [(0, 0)], [(0, 720)], [colțul stânga-sus],
  [(640, 360)], [(640, 360)], [centrul],
  [(0, 720)], [(0, 0)], [colțul stânga-jos],
  [(1280, 0)], [(1280, 720)], [colțul dreapta-sus],
)

=== Butonul mouse-ului e o mască de biți

#cod("Tema1.cpp", 755, 758)

În framework, `button` *nu* e numărul GLFW al butonului (0 = stânga), ci o *mască*: `OnMouseBtnPress(..., pressEvent, ...)` cu `pressEvent = mouseButtonAction & mouseButtonStates`, unde butonul GLFW $k$ setează bitul $k$ (`SET_BIT(item, bit)` = `item |= 1 << bit`). Butonul stâng (GLFW 0) dă `1 << 0 = 1`; dreptul (1) dă 2; mijlocul (2) dă 4. De aici `button == 1` pentru click stânga. (În laboratoare apare și `IS_BIT_SET(button, GLFW_MOUSE_BUTTON_LEFT)`, care înseamnă același lucru.)

== Desenarea 2D: `RenderMesh2D`

Primește o matrice 3 × 3 (`glm::mat3`, coordonate omogene 2D) și o transformă într-una 4 × 4 pentru shader, cu $z$ neatins:

$ mat(a, c, t_x; b, d, t_y; 0, 0, 1) arrow.r.long mat(a, c, 0, t_x; b, d, 0, t_y; 0, 0, 1, 0; 0, 0, 0, 1) $

Shader-ul calculează pentru fiecare vârf $"gl_Position" = P dot V dot M dot (x, y, 0, 1)^T$: modelare (matricea ta), vizualizare (camera), proiecție (ortografica).

== Ordinea de desen în loc de adâncime

#cod("Tema1.cpp", 549, 559)

`glDisable(GL_DEPTH_TEST)`: toate formele au $z = 0$, deci adâncimea nu poate decide ce e deasupra. Fără test de adâncime, *ce se desenează mai târziu acoperă ce s-a desenat înainte* (algoritmul pictorului). Tot desenul tău e ordonat pe straturi în `Update`: tabla, pachetele, butonul, timer-ul, eroii, mana, cărțile, cartea trasă, săgeata, ecranul de final.

#prof[„De ce cartea pe care o tragi apare deasupra celorlalte?” Pentru că în `Update` desenezi întâi toate cărțile jucătorului *care nu sunt trase*, apoi cărțile inamicului, și *abia la urmă* cartea cu `isDragged == true` (liniile 693–705). Enunțul cere explicit asta la Drag and Drop.]
