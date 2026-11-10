"""Quick geometry check: build the kit and render it with Workbench, colored by material role.

Run: Blender -b --python blender/preview_kit.py -- out.png [--close]  (--close frames the snail)
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

from garden_kit import build  # noqa: E402
from kit_common import clear_scene  # noqa: E402

COLORS = {"body": (0.5, 0.8, 0.4), "shell": (0.9, 0.4, 0.8), "eye": (1, 1, 1), "pupil": (0.05, 0.05, 0.1),
          "stem": (0.3, 0.6, 0.2), "petal": (1, 0.6, 0.2), "center": (1, 0.9, 0.2), "cap": (0.9, 0.15, 0.15),
          "dot": (1, 1, 1), "rock": (0.6, 0.6, 0.65), "leaf": (0.35, 0.7, 0.3), "grass": (0.4, 0.8, 0.3)}

args = sys.argv[sys.argv.index("--") + 1:]
out = args[0]
close = "--close" in args
clear_scene()
build()
scene = bpy.context.scene
scene.render.engine = "BLENDER_WORKBENCH"
scene.display.shading.color_type = "OBJECT"
scene.render.resolution_x, scene.render.resolution_y = (800, 800) if close else (1600, 500)
for o in bpy.data.objects:
    if o.type == "MESH":
        o.color = (*COLORS[o.name.rsplit("_", 1)[-1]], 1)
cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
scene.collection.objects.link(cam)
cam.data.type = "ORTHO"
cam.data.ortho_scale = 2.0 if close else 21
target = Vector((0, 0, 0.35)) if close else Vector((9, 0, 0.8))
cam.location = target + (Vector((-6, 2, 2.5)) if close else Vector((-2, -9, 5)))
cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
scene.camera = cam
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
