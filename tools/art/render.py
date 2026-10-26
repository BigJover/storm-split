"""Preview renders for the art pass (PLAN 11a T146, #430). Runs inside Blender only.

One 512 px 3/4 front view per model (plus a side view, `<key>_side.png`): Workbench, studio light so smooth shading reads,
object colours = the paint-group preview colours, neutral grey background, orthographic
camera framed on the model's bounds (the same framing rule for every model).
"""

import math

import bpy
from mathutils import Vector

import lowpoly

SIZE = 512
BACKGROUND = (0.62, 0.64, 0.66)


THREE_QUARTER = (-0.9, 1.0, 0.65)
SIDE = (-1.0, 0.0, 0.05)  # the model's right flank, near eye level: proportions
BACK = (0.9, -1.0, 0.45)  # 3/4 from behind (hunters: backpacks, sheaths, hair)


def render(path, objs, view=THREE_QUARTER):
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_WORKBENCH"
    scene.render.resolution_x = SIZE
    scene.render.resolution_y = SIZE
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGB"
    scene.render.image_settings.compression = 90
    shading = scene.display.shading
    shading.light = "STUDIO"
    shading.color_type = "OBJECT"
    shading.show_cavity = False
    shading.show_shadows = False
    if scene.world is None:
        scene.world = bpy.data.worlds.new("preview")
    scene.world.color = BACKGROUND
    scene.view_settings.view_transform = "Standard"

    lo, hi = lowpoly.bounds(objs)
    centre = Vector((lo + hi) / 2)
    extent = max(hi - lo)
    # 3/4 view: front (+Y), the model's left (-X... its right faces the camera), from above
    direction = Vector(view).normalized()
    cam_data = bpy.data.cameras.new("preview")
    cam_data.type = "ORTHO"
    cam_data.ortho_scale = extent * (0.95 if view == THREE_QUARTER else 1.1)  # side: whole length
    cam_data.clip_end = extent * 20
    cam = bpy.data.objects.new("preview", cam_data)
    scene.collection.objects.link(cam)
    cam.location = centre + direction * extent * 4
    cam.rotation_euler = (centre - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
    bpy.data.objects.remove(cam)
    return path


def contact_sheet(path, pngs, columns=4):
    """Tile preview PNGs into one sheet for Jovan's per-batch approval (#438)."""
    import numpy as np

    images = [bpy.data.images.load(str(p)) for p in pngs]
    rows = math.ceil(len(images) / columns)
    sheet = np.ones((rows * SIZE, columns * SIZE, 4), dtype=np.float32)
    for i, img in enumerate(images):
        px = np.empty(SIZE * SIZE * 4, dtype=np.float32)
        img.pixels.foreach_get(px)
        r, c = rows - 1 - i // columns, i % columns  # Blender images start bottom-left
        sheet[r * SIZE:(r + 1) * SIZE, c * SIZE:(c + 1) * SIZE] = px.reshape(SIZE, SIZE, 4)
    out = bpy.data.images.new("sheet", columns * SIZE, rows * SIZE)
    out.pixels.foreach_set(sheet.ravel())
    out.filepath_raw = str(path)
    out.file_format = "PNG"
    out.save()
    return path
