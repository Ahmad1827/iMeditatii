"""Builds the EGC Tema 1 guide: web/materiale/egc-tema-1.pdf.

The code shown is src/*, a copy of the Tema 1 (Hearthstone) from
~/an3/egc/gfx-framework/src/lab_m1/Tema1 as it was handed in. Every number in the guide
(the layout for 1280×720, the vertices of the meshes, the positions of ArrangeZone, the
animation steps) comes from tool/acs/egc_tema1_model.py: build.py writes them to gen.json,
the .typ files read it.

Needs the Typst compiler for Python (`pip install typst`); the drawings use @preview/cetz.
"""
import json
import pathlib
import sys

import typst

HERE = pathlib.Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent))
import egc_tema1_model as m  # noqa: E402

OUT = HERE.parents[2] / 'web' / 'materiale' / 'egc-tema-1.pdf'


def r(x, n=2):
    return round(x + 0.0, n)


def gen():
    L = m.layout()
    g = {'L': {k: r(v, 3) for k, v in L.items()}}
    g['bands'] = [[name, r(a, 2), r(b, 2)] for name, a, b in m.bands(L)]
    meshes = {}
    for name, f in m.MESHES.items():
        v, idx = f()
        meshes[name] = {'v': [[r(x, 4), r(y, 4)] for x, y in v], 'i': idx, 'tri': len(idx) // 3, 'bbox': [r(x, 3) for x in m.bbox(v)]}
    # smaller versions for drawing the fans (fewer segments, same shape)
    meshes['circle12'] = {'v': [[r(x, 4), r(y, 4)] for x, y in m.circle(12)[0]]}
    meshes['heart16'] = {'v': [[r(x, 4), r(y, 4)] for x, y in m.heart(16)[0]]}
    meshes['sword16'] = {'v': [[r(x, 4), r(y, 4)] for x, y in m.sword(16)[0]]}
    g['meshes'] = meshes
    g['arrange'] = {str(n): [r(x, 2) for x in m.arrange_x(n, L)] for n in range(1, 8)}
    g['heart_extent'] = [r(x, 4) for x in m.heart_extent()]
    g['sword_r'] = [[i, r(2 * m.PI * i / 64, 3), r(m.sword_r(2 * m.PI * i / 64), 3)] for i in range(0, 64, 8)] + [[16, r(m.PI / 2, 3), r(m.sword_r(m.PI / 2), 3)], [48, r(3 * m.PI / 2, 3), r(m.sword_r(3 * m.PI / 2), 3)]]
    g['sword_r'] = sorted({tuple(x) for x in g['sword_r']})
    # a card that leaves the deck: x along the frames at 60 fps
    dt = 1 / 60
    x0, tx = L['playerDeckX'], m.arrange_x(6, L)[5]
    g['deal'] = {'x0': r(x0), 'tx': r(tx), 'step': r(min(1, 8 * dt), 4),
                 'frames': [[f, r(m.smooth(x0, tx, dt, f))] for f in (0, 1, 2, 5, 10, 20, 30, 60)]}
    # how long until the card is within 1 px, at several frame rates
    def frames_to(eps, dt):
        x, n = x0, 0
        while abs(tx - x) > eps:
            x = m.smooth(x, tx, dt, 1)
            n += 1
        return n
    g['deal_fps'] = [[fps, frames_to(1, 1 / fps), r(frames_to(1, 1 / fps) / fps, 3)] for fps in (30, 60, 144)]
    # the shake: angle for timer values
    g['shake'] = [[r(t, 3), int(t * 20), m.shake_angle(t)] for t in (0.6, 0.58, 0.55, 0.52, 0.49, 0.3, 0.04, 0.0)]
    g['mana'] = [[k, mm, m.mana_colours(k, mm)] for k, mm in ((1, 1), (2, 4), (0, 3), (7, 10))]
    return g


def main():
    (HERE / 'gen.json').write_text(json.dumps(gen(), ensure_ascii=False, indent=1), encoding='utf-8')
    OUT.parent.mkdir(parents=True, exist_ok=True)
    typst.compile(str(HERE / 'main.typ'), output=str(OUT), root=str(HERE))
    print(OUT)


if __name__ == '__main__':
    main()
