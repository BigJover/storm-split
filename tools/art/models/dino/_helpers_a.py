"""Shared helpers for the 11b dino scripts BRUTE / SHIELD / ARMOR / STORM (Builder A).
Plain Python (no bpy): colour mixing and back-stripe placement along a skin spine."""


def mix(a, b, t):
    return tuple(round(x + (y - x) * t) for x, y in zip(a, b))


def spine_at(spine, z):
    """spine: [(y, z, radius), ...] in Roblox studs, any order. Linear (y, radius) at z."""
    s = sorted(spine, key=lambda p: p[1])
    if z <= s[0][1]:
        return s[0][0], s[0][2]
    for (y0, z0, r0), (y1, z1, r1) in zip(s, s[1:]):
        if z0 <= z <= z1:
            t = (z - z0) / ((z1 - z0) or 1)
            return y0 + (y1 - y0) * t, r0 + (r1 - r0) * t
    return s[-1][0], s[-1][2]


def bands(lp, name, spine, zs, width=1.0, length=0.13, segments=8, rings=4):
    """Stripes across the back: thin saddles hugging the top of the spine at each z."""
    out = []
    for i, z in enumerate(zs):
        y, r = spine_at(spine, z)
        out.append(lp.ellipsoid(f"{name}{i}", lp.rbx(0, y + r * 0.45, z), (r * width, length, r * 0.6), segments, rings))
    return out
