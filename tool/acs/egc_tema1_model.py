"""A model of the EGC Tema 1 (Hearthstone) written in ~/an3/egc/gfx-framework/src/lab_m1/Tema1.

The guide (tool/acs/ghid_egc_t1) and the exercises of the course (tool/acs/egc_tema1.py) take
their numbers from here: the layout Init() computes for a 1280×720 window, the vertices of each
mesh in shapes.cpp, ArrangeZone, the smoothing of Update, the shake, the mouse conversion, the
attack rules. Each function follows the C++ line for line (float32 is not imitated: the values
are printed rounded). Run it to check the model against facts worked out by hand.
"""
import math

W, H = 1280.0, 720.0


def layout(w=W, h=H):
    L = {'screenW': w, 'screenH': h}
    L['handH'] = h * 0.16
    L['heroZoneH'] = h * 0.16
    L['halfH'] = h * 0.18
    L['cardH'] = L['handH'] * 0.8
    L['cardW'] = L['cardH'] * 0.7
    L['cardGap'] = L['cardW'] * 0.2
    L['playerHandY'] = (L['handH'] - L['cardH']) / 2
    L['playerBoardY'] = L['handH'] + L['heroZoneH'] + (L['halfH'] - L['cardH']) / 2
    L['enemyBoardY'] = h / 2 + (L['halfH'] - L['cardH']) / 2
    L['enemyHandY'] = h - L['handH'] + (L['handH'] - L['cardH']) / 2
    L['heroH'] = L['cardH']
    L['heroW'] = L['cardW']
    L['heroX'] = (w - L['heroW']) / 2
    L['playerHeroY'] = L['handH'] + (L['heroZoneH'] - L['heroH']) / 2
    L['enemyHeroY'] = h - L['handH'] - L['heroZoneH'] + (L['heroZoneH'] - L['heroH']) / 2
    L['playerDeckX'] = w - L['cardW'] - L['cardGap'] * 2
    L['playerDeckY'] = L['playerHandY']
    L['enemyDeckX'] = L['playerDeckX']
    L['enemyDeckY'] = L['enemyHandY']
    L['endButtonW'] = L['cardW']
    L['endButtonH'] = L['cardH'] * 0.4
    L['endButtonX'] = L['playerDeckX']
    L['endButtonY'] = h / 2 - L['halfH'] / 2 - L['endButtonH'] / 2
    L['turnTime'] = 30.0
    L['timerW'] = L['endButtonW']
    L['timerH'] = (L['halfH'] - L['cardH']) / 4
    L['timerX'] = L['endButtonX']
    L['playerTimerY'] = h / 2 - (L['halfH'] - L['cardH']) / 4 - L['timerH'] / 2
    L['enemyTimerY'] = h / 2 + (L['halfH'] - L['cardH']) / 4 - L['timerH'] / 2
    return L


# the screen's horizontal bands, bottom to top (DrawBoard)
def bands(L=None):
    L = L or layout()
    h, hh, hz, hf = L['screenH'], L['handH'], L['heroZoneH'], L['halfH']
    return [('mâna jucătorului', 0, hh), ('zona eroului (jucător)', hh, hh + hz), ('tabla jucătorului', hh + hz, hh + hz + hf),
            ('tabla inamicului', h / 2, h / 2 + hf), ('zona eroului (inamic)', h - hh - hz, h - hh), ('mâna inamicului', h - hh, h)]


# ------------------------------------------------------------------ meshes (shapes.cpp)
PI = 3.14159265


def plus(t=0.15):
    v = [(-0.5, -t), (0.5, -t), (0.5, t), (-0.5, t), (-t, -0.5), (t, -0.5), (t, 0.5), (-t, 0.5)]
    return v, [0, 1, 2, 0, 2, 3, 4, 5, 6, 4, 6, 7]


def triangle():
    return [(-0.5, -0.5), (0.5, -0.5), (0.0, 0.5)], [0, 1, 2]


def diamond():
    return [(0.0, 0.5), (0.5, 0.0), (0.0, -0.5), (-0.5, 0.0)], [0, 3, 2, 0, 2, 1]


def fan(n):
    idx = []
    for i in range(n):
        idx += [0, i + 1, (i + 1) % n + 1]
    return idx


def star(points=10):
    v = [(0.0, 0.0)]
    for i in range(points):
        a = PI / 2 + i * 2 * PI / points
        r = 0.5 if i % 2 == 0 else 0.2
        v.append((r * math.cos(a), r * math.sin(a)))
    return v, fan(points)


def circle(segments=48):
    v = [(0.0, 0.0)] + [(0.5 * math.cos(2 * PI * i / segments), 0.5 * math.sin(2 * PI * i / segments)) for i in range(segments)]
    return v, fan(segments)


def arrow():
    v = [(0.0, -0.15), (0.75, -0.15), (0.75, 0.15), (0.0, 0.15), (0.75, -0.5), (1.0, 0.0), (0.75, 0.5)]
    return v, [0, 1, 2, 0, 2, 3, 4, 5, 6]


HEART_A = 0.38


def heart(segments=64, a=HEART_A):
    off = 0.875 * a
    v = [(0.0, off)]
    for i in range(segments):
        t = 2 * PI * i / segments
        r = a * (1 - math.cos(t))
        v.append((-r * math.sin(t), r * math.cos(t) + off))
    return v, fan(segments)


SWORD = dict(a=0.3, b=0.1, c=1.05, n=3, m=2, scale=0.38, scaleX=0.9, offsetY=-0.385)


def sword_r(t, a=0.3, b=0.1, c=1.05, n=3, m=2):
    return a + b * math.sin(n * t) / (c + math.cos(m * t))


def sword(segments=64):
    s = SWORD
    v = [(0.0, s['offsetY'])]
    for i in range(segments):
        t = 2 * PI * i / segments
        r = sword_r(t)
        v.append((s['scaleX'] * r * math.cos(t), -s['scale'] * r * math.sin(t) + s['offsetY']))
    return v, fan(segments)


def rectangle(fill=True):
    v = [(0, 0), (1, 0), (1, 1), (0, 1)]
    return v, ([0, 1, 2, 3, 0, 2] if fill else [0, 1, 2, 3])


MESHES = {'square': rectangle, 'circle': circle, 'diamond': diamond, 'triangle': triangle, 'plus': plus,
          'star': star, 'arrow': arrow, 'heart': heart, 'sword': sword}


def bbox(v):
    xs, ys = [p[0] for p in v], [p[1] for p in v]
    return min(xs), max(xs), min(ys), max(ys)


# ------------------------------------------------------------------ 2D transforms (transform2D.h), column vectors
def T(tx, ty):
    return [[1, 0, tx], [0, 1, ty], [0, 0, 1]]


def S(sx, sy):
    return [[sx, 0, 0], [0, sy, 0], [0, 0, 1]]


def R(rad):
    c, s = math.cos(rad), math.sin(rad)
    return [[c, -s, 0], [s, c, 0], [0, 0, 1]]


def mul(*ms):
    out = [[1, 0, 0], [0, 1, 0], [0, 0, 1]]
    for m in ms:
        out = [[sum(out[i][k] * m[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return out


def apply(m, p):
    x, y = p
    return (m[0][0] * x + m[0][1] * y + m[0][2], m[1][0] * x + m[1][1] * y + m[1][2])


# ------------------------------------------------------------------ game logic
TYPES = {  # GetTypeStyle: colour, shape, mana cost, effect
    'NORMAL': ((0.55, 0.55, 0.55), 'circle', 1, 'NONE'),
    'TANK': ((0.25, 0.45, 0.85), 'diamond', 4, 'TANK'),
    'CHARGE': ((0.90, 0.50, 0.10), 'triangle', 3, 'CHARGE'),
    'LIFESTEAL': ((0.75, 0.15, 0.20), 'plus', 3, 'LIFESTEAL'),
    'SILENCE': ((0.55, 0.25, 0.75), 'star', 2, 'SILENCE'),
}


def arrange_x(n, L=None):
    """targetX of the n cards of a zone, left to right (ArrangeZone)."""
    L = L or layout()
    total = n * L['cardW'] + (n - 1) * L['cardGap']
    start = (L['screenW'] - total) / 2
    return [start + k * (L['cardW'] + L['cardGap']) for k in range(n)]


def smooth(x, target, dt, frames, speed=8.0):
    """x after [frames] frames of Update at a fixed dt: x += (target - x) * min(1, speed * dt)."""
    step = min(1.0, speed * dt)
    for _ in range(frames):
        x += (target - x) * step
    return x


def shake_angle(timer):
    """The angle Update sets for a card whose shakeTimer (already decreased this frame) is [timer]."""
    if timer > 0:
        return 0.15 if int(timer * 20) % 2 == 0 else -0.15
    return 0.0


def mouse_to_scene(mx, my, res=(1280, 720), L=None):
    L = L or layout()
    return mx * L['screenW'] / res[0], L['screenH'] - my * L['screenH'] / res[1]


def attack(a, b):
    """(hpA, atkA), (hpB, atkB) -> the hp after A attacks B."""
    return a[0] - b[1], b[0] - a[1]


def mana_colours(mana, max_mana):
    return ['albastru' if i < mana else ('alb' if i < max_mana else 'negru') for i in range(10)]


def max_mana_at(round_):
    """maxMana at the start of a player's round [round_] (1, 2, ...): Init sets 0, each StartTurn +1, up to 10."""
    return min(10, round_)


def heart_extent(a=HEART_A):
    """Exact bounds of the heart: x = -r sin t, y = r cos t + 0.875a, r = a(1 - cos t)."""
    # y - off = a(1 - c)c, max at c = 1/2 -> a/4; min at c = -1 -> -2a. |x| = a(1 - c)s, max at t = 2π/3 -> a·1.5·√3/2
    return (-a * 1.5 * math.sqrt(3) / 2, a * 1.5 * math.sqrt(3) / 2, -2 * a + 0.875 * a, a / 4 + 0.875 * a)


def _check():
    L = layout()
    assert abs(L['handH'] - 115.2) < 1e-9 and abs(L['halfH'] - 129.6) < 1e-9
    assert abs(L['cardH'] - 92.16) < 1e-9 and abs(L['cardW'] - 64.512) < 1e-9
    # the six bands fill the screen without gaps
    b = bands(L)
    assert abs(b[2][2] - H / 2) < 1e-9 and abs(b[3][1] - H / 2) < 1e-9 and abs(b[4][1] - b[3][2]) < 1e-9
    # a zone is centred: first left edge + last right edge = screen width
    xs = arrange_x(5, L)
    assert abs(xs[0] + xs[-1] + L['cardW'] - W) < 1e-9
    # the heart fits the unit square and is centred vertically
    x0, x1, y0, y1 = heart_extent()
    assert abs(y0 + y1) < 1e-12 and x1 - x0 < 1 and y1 - y0 < 1
    hv, _ = heart(4096)
    hb = bbox(hv)
    assert abs(hb[2] - y0) < 1e-3 and abs(hb[3] - y1) < 1e-3 and abs(hb[1] - x1) < 1e-3
    # rotation about the card's centre leaves the centre where it is
    cx, cy = 300.0, 200.0
    m = mul(T(cx, cy), R(0.15), T(-cx, -cy))
    p = apply(m, (cx, cy))
    assert abs(p[0] - cx) < 1e-9 and abs(p[1] - cy) < 1e-9
    # shake: 0.6 s at 20 changes per second
    assert shake_angle(0.59) == -0.15 and shake_angle(0.54) == 0.15 and shake_angle(0) == 0
    assert mouse_to_scene(640, 0) == (640.0, 720.0)
    assert attack((5, 3), (2, 4)) == (1, -1)
    assert mana_colours(2, 4)[:5] == ['albastru', 'albastru', 'alb', 'alb', 'negru']
    # fans: n triangles, 3n indices
    assert len(circle()[1]) == 144 and len(star()[1]) == 30 and len(heart()[1]) == 192
    print('egc_tema1_model: ok')


if __name__ == '__main__':
    _check()
