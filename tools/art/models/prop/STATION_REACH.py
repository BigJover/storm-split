"""Raptor Dummy (training station `reach`, Shared/Outpost STATIONS[1]): a padded training raptor on
a lashed post. Frame = Server/Outpost buildStation's `base` (axis-aligned, the station centre on
the floor); like the blocky build the post stands at z -4 and the raptor faces +Z. The station's
sand pad (cylinder, attribute Station, the sign's adornee) stays the runtime's own part."""

import importlib.util
from pathlib import Path

_s = importlib.util.spec_from_file_location("_camp", Path(__file__).with_name("_camp.py"))
C = importlib.util.module_from_spec(_s)
_s.loader.exec_module(C)


def build(lp):
    k = C.Camp(lp)
    z = -4.0
    # stand: two crossed feet + wedges, the post, rope lashings
    k.add("wood", C.rbox((0, 0.18, z), (3.2, 0.36, 0.5), bevel=0.08),
          C.rbox((0, 0.18, z), (0.5, 0.36, 3.2), bevel=0.08),
          C.rod((0, 0.2, z), (0, 4.6, z), 0.36, segments=10, top=0.85))
    for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        k.add("dark", C.bar((dx * 1.1, 0.3, z + dz * 1.1), (dx * 0.3, 1.4, z + dz * 0.3), 0.22, 0.2))
    k.add("rope", C.ring((0, 1.9, z), 0.37, 0.07, 12, 4), C.ring((0, 2.15, z), 0.37, 0.07, 12, 4),
          C.ring((0, 3.9, z), 0.33, 0.07, 12, 4))
    # the raptor sack: body, belly padding, neck, head, tail, little arms, legs
    k.add("body", C.ell((0, 5.5, z), (1.15, 1.25, 1.75), 14, 9),
          C.rod((0, 6.2, z + 1.2), (0, 7.0, z + 1.75), 0.45, segments=10, top=0.85),
          C.ell((0, 7.25, z + 1.95), (0.62, 0.56, 0.8), 12, 7),
          C.ell((0, 7.05, z + 2.7), (0.44, 0.34, 0.72), 10, 6),
          C.rod((0, 5.6, z - 1.3), (0, 5.45, z - 2.7), 0.78, segments=10, top=0.6),
          C.rod((0, 5.45, z - 2.65), (0, 5.95, z - 3.7), 0.47, segments=10, top=0.15))
    for i in range(4):  # quills down the back
        zz = z + 1.0 - i * 0.7
        k.add("dark", C.ell((0, 6.62 - abs(i - 1) * 0.08, zz), (0.12, 0.28, 0.24), 6, 4, rot=(-25, 0, 0)))
    for x in (-1, 1):
        for t in (0.15, 0.35, 0.55):  # teeth
            k.add("eye", C.rod((x * 0.32, 6.86, z + 2.45 + t * 1.2), (x * 0.3, 6.62, z + 2.45 + t * 1.2), 0.06, segments=5, top=0.1))
    for x in (-1, 1):
        k.add("body", C.rod((x * 0.8, 5.4, z + 1.1), (x * 0.95, 4.9, z + 1.7), 0.16, segments=6, top=0.6))
        k.add("eye", C.ell((x * 0.5, 7.42, z + 2.25), (0.12, 0.14, 0.14), 8, 5))
        k.add("dark", C.ell((x * 0.58, 7.44, z + 2.28), (0.06, 0.08, 0.08), 6, 4))
        # stitched X patch on each flank
        k.add("dark", C.bar((x * 1.12, 5.2, z - 0.5), (x * 1.12, 6.0, z + 0.3), 0.06, 0.06),
              C.bar((x * 1.12, 6.0, z - 0.5), (x * 1.12, 5.2, z + 0.3), 0.06, 0.06))
    k.add("dark", C.ell((0, 6.88, z + 2.75), (0.42, 0.05, 0.6), 8, 4))  # mouth line
    # padding: straw-coloured cushion strapped under the belly + rope bands round the sack
    k.add("rope", C.ell((0, 4.65, z), (1.3, 0.55, 1.9), 12, 6),
          C.ring((0, 5.5, z - 0.9), 1.08, 0.08, 14, 4, rot=(90, 0, 0)),
          C.ring((0, 5.5, z + 0.9), 1.0, 0.08, 14, 4, rot=(90, 0, 0)))
    colors = {"wood": C.WOOD, "dark": C.DARK, "rope": (196, 170, 120), "body": C.RAPTOR,
              "eye": (240, 236, 220)}
    return k.model("11f", colors, 2500, (2.0, 8.0, 8.5),
                   meta={"prop": "station", "station": "reach", "display": "Raptor Dummy",
                         "replaces": "Server/Outpost buildStation reach: Post, Body, Head, Padding"})
