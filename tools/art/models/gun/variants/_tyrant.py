"""Tyrant King gun / grenade pieces (premium theme, PREMIUM_SKINS.md, batch 11p4): bone, teeth and crimson,
gold only as trim, glowing red eyes / throats / runes in group `glow` (Neon in game; Shared/SkinFx's pack
tier ramps them as the weapon heats). Authored in the gun frame (_gun.py: grip at (0, 0, 0), barrel -Z,
+Y up) with the `_gun.py` primitives (passed in as G).

  fang(G, a, b, r)                   a tooth: a 3-sided cone from a (root) to b (point)
  jaw_muzzle(g, G, bore, front, ...) a rex mouth round the barrel's last stretch: upper jaw over it, lower
                                     jaw under it, fangs top and bottom (clear of the barrel), glowing eyes
                                     on the upper jaw's sides and a glowing throat ring inside the mouth.
                                     The barrel's tip and the `muzzle` piece stay out in front of the jaws.
"""

COLORS = {
    "bone": (234, 224, 198), "bone2": (196, 180, 150), "accent": (156, 22, 36), "crimson2": (96, 16, 26),
    "gold": (214, 170, 64), "glow": (255, 34, 44),
}


def fang(G, a, b, r=0.018):
    return G.rod(a, b, r, 3, top=0.05)


def jaw_muzzle(g, G, bore, front, length=0.36, w=0.2, h=0.22, teeth=4, eyes=True, lower=True, gape=9, hump=True):
    """The jaws gape: the upper one tilts its front up, the lower one down (gape degrees each)."""
    import math
    t = math.tan(math.radians(gape))
    zc = front + length / 2

    def up(z, y):  # the upper jaw's underside lifts toward the front
        return y + (zc - z) * t

    def dn(z, y):
        return y - (zc - z) * t

    g.add("bone",
          G.rbox((0, bore + h * 0.52, zc), (w, h * 0.42, length), bevel=0.012, taper=(0.7, 0.85), rot=(gape, 0, 0)),
          *[fang(G, (x * w * 0.34, up(z, bore + h * 0.32), z), (x * w * 0.34, up(z, bore - h * 0.02), z - 0.01), 0.022)
            for x in (-1, 1) for z in [front + 0.05 + i * (length - 0.12) / max(1, teeth - 1) for i in range(teeth)]])
    if hump:
        g.add("bone", G.ell((0, bore + h * 0.72, zc + length * 0.42), (w * 0.55, h * 0.36, length * 0.3), 6, 3))  # cranium hump
    if lower:
        g.add("bone2",
              G.rbox((0, bore - h * 0.52, zc + 0.02), (w * 0.86, h * 0.32, length * 0.94), bevel=0.012, taper=(0.7, 0.85), rot=(-gape, 0, 0)),
              *[fang(G, (x * w * 0.3, dn(z, bore - h * 0.34), z), (x * w * 0.3, dn(z, bore - h * 0.02), z - 0.01), 0.02)
                for x in (-1, 1) for z in [front + 0.08 + i * (length - 0.16) / max(1, teeth - 2) for i in range(max(1, teeth - 1))]])
    if eyes:
        ez = zc + length * 0.28
        g.add("glow", *[G.ell((x * w * 0.48, bore + h * 0.74, ez), (0.016, 0.03, 0.04), 4, 3) for x in (-1, 1)])
        g.add("bone2", *[G.rbox((x * w * 0.42, bore + h * 0.92, ez), (w * 0.32, h * 0.12, length * 0.24), bevel=0.0) for x in (-1, 1)])  # brows
    g.add("glow", G.ring((0, bore, front + length * 0.8), w * 0.3, 0.012, 6, 3, axis="z"))


def prop_skull(g, G, c=(0, 0, 0), s=1.0, gape=24, eyes="glow", teeth=3, jaw=True):
    """A roaring rex skull charm for the grenades (kit frame, facing -Z, about c, s = 1: ~0.62 long):
    bone cranium + snout, dark sockets with glowing eyes (eyes = paint group or None), fangs, an open
    lower jaw (gape degrees)."""
    import math
    cx, cy, cz = c

    def p(x, y, z):
        return (cx + x * s, cy + y * s, cz + z * s)

    g.add("bone",
          G.ell(p(0, 0.06, 0.08), (0.28 * s, 0.24 * s, 0.28 * s), 8, 5),
          G.rbox(p(0, 0.0, -0.2), (0.36 * s, 0.2 * s, 0.34 * s), bevel=0.03 * s, taper=(0.74, 0.86)),
          *[fang(G, p(x * 0.13, -0.08, -0.12 - 0.08 * i), p(x * 0.13, -0.18, -0.13 - 0.08 * i), 0.024 * s)
            for x in (-1, 1) for i in range(teeth)])
    g.add("bone2", *[G.ell(p(x * 0.15, 0.13, -0.1), (0.1 * s, 0.05 * s, 0.11 * s), 5, 3) for x in (-1, 1)])  # brows
    g.add("dark", *[G.ell(p(x * 0.17, 0.06, -0.12), (0.06 * s, 0.065 * s, 0.06 * s), 5, 3) for x in (-1, 1)],
          *[G.ell(p(x * 0.06, 0.06, -0.37), (0.025 * s, 0.02 * s, 0.02 * s), 4, 3) for x in (-1, 1)])
    if eyes:
        g.add(eyes, *[G.ell(p(x * 0.19, 0.06, -0.14), (0.045 * s, 0.05 * s, 0.045 * s), 5, 3) for x in (-1, 1)])
    if jaw:
        a = math.radians(gape)
        hx, hy, hz = 0, -0.12, 0.02  # hinge

        def q(y, z):  # a point on the lower jaw, opened by gape about the hinge
            return (hy + y * math.cos(a) + z * math.sin(a), hz - y * math.sin(a) + z * math.cos(a))

        y0, z0 = q(-0.04, -0.2)
        g.add("bone2", G.rbox(p(0, y0, z0), (0.3 * s, 0.08 * s, 0.38 * s), bevel=0.02 * s, taper=(0.7, 0.8), rot=(-gape, 0, 0)),
              *[fang(G, p(x * 0.1, *q(0.0, -0.1 - 0.09 * i)), p(x * 0.1, *q(0.1, -0.11 - 0.09 * i)), 0.022 * s)
                for x in (-1, 1) for i in range(teeth - 1)])
