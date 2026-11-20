#import "tpl.typ": *

= Foaie de memorat

#set text(9.8pt)
#grid(columns: (1fr, 1fr), gutter: 14pt,
  [
    *Framework*
    - Bucla: input → `FrameStart` → `Update(dt)` → `FrameEnd`; totul se redesenează la fiecare cadru.
    - Mesh = vârfuri + indici; `InitFromData` → VBO, IBO, VAO, o dată în `Init`.
    - `GL_TRIANGLES`: câte 3 indici; dreptunghiul plin = `0,1,2, 3,0,2`.
    - `RenderMesh2D(mesh, mat3, culoare)`: shader `Color`, culoarea uniformă.
    - Camera ortografică $[0, 1280] × [0, 720]$, origine stânga-jos.
    - Mouse: $y_"scenă" = "screenH" - y_m dot "screenH" \/ "res.y"$.
    - `button == 1`: mască, bitul 0 = stânga.
    - Depth test oprit → ordinea de desen decide.

    *Transformări*
    - $(x, y, 1)$: omogene; $M = A B C$ aplică întâi $C$.
    - `transpose`: GLM e column-major.
    - `DrawRect` = $"parent" dot T(x, y) dot S(w, h)$ pe pătratul $[0,1]^2$.
    - Rotație în jurul centrului: $T(c) R(alpha) T(-c)$.
    - Simbol: $"rot" dot T(x + w\/2, y + h\/4) dot S(0.35 w)$.
    - Săgeată: $T("start") R("atan2") S(ell, 0.6 w)$.

    *Forme*
    - Evantai: $(0, i+1, (i+1) mod n + 1)$, $n$ triunghiuri.
    - Cerc 48, stea 10 (raze 0.5 / 0.2), inimă și sabie 64.
    - Inimă: $r = a(1 - cos theta)$, $(-r sin theta, r cos theta + 0.875a)$, $a = 0.38$.
    - Sabie: $r = 0.3 + 0.1 sin 3 theta \/ (1.05 + cos 2 theta)$; $(0.9 r cos, -0.38 r sin - 0.385)$.
  ],
  [
    *Layout (1280 × 720)*
    - Benzi: 0.16 mână, 0.16 erou, 0.18 tablă (× 2): $4 dot 0.16 + 2 dot 0.18 = 1$.
    - Carte $64.5 × 92.2$, spațiu 12.9.
    - `ArrangeZone`: $x_k = ("W" - n w - (n-1) g)\/2 + k(w + g)$.
    - Plasare validă: $y in [230.4, 360]$, < 7 pe tablă, mana destulă.

    *Joc*
    - Start: 30 în pachet, 5 în mână; prima tură 6 cărți, 1 mana.
    - `StartTurn`: `round++`, `maxMana` +1 (≤ 10), mana plină, timer 30, `hasAttacked` false, o carte.
    - `CanAttack`: pe tablă ∧ tura lui ∧ (`round` mai mic ∨ Charge) ∧ ¬`hasAttacked`.
    - Atac: ambele simultan, `RemoveDead` pe ambele liste.
    - Tank: dacă există, doar el e țintă, eroul nu.
    - Lifesteal: `owner.hp += atk`. Silence: `effect = NONE` (Tank/Lifesteal).
    - Costuri: Normal 1, Silence 2, Charge 3, Lifesteal 3, Tank 4.
    - Inamic: 1 mișcare/s: atacă cu cea selectată > pune o carte > selectează > `EndTurn`.

    *Animații*
    - $x += (x_t - x) min(1, 8 d t)$: ease-out, pentru x, y, w, h.
    - Hover ×1.15, selectat ×1.3, centrul fix.
    - Shake: 0.6 s, ±0.15 rad, schimbare la 0.05 s.
    - Timer: lățime $= "timerW" dot t \/ 30$; la 0 → `EndTurn`.
    - Cartea trasă: desenată ultima; ținta = cursorul.
  ],
)
