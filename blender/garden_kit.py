"""Build the snail and the garden props, and export them as one glTF kit for Godot.

Run: Blender -b --python blender/garden_kit.py
Writes godot_web_game/assets/kit.glb.

Each part is a top-level empty (snail, flower, mushroom, pebble, leaf, grass, fern). Mesh names end
in a material role (`_body`, `_shell`, `_eye`, `_pupil`, `_stem`, `_petal`, `_center`, `_cap`,
`_dot`, `_rock`, `_leaf`, `_grass`) and Godot assigns materials from that, so the kit exports
without materials. +Y is the snail's head (Godot -Z), +Z is up, and a snail is about a meter long.
"""

import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

import bpy  # noqa: E402
from mathutils import Euler, Vector  # noqa: E402

from kit_common import clear_scene, empty, lathe_bm, mesh_obj, sphere_bm, transform_bm, tube_bm  # noqa: E402

OUT = Path(__file__).resolve().parent.parent / "godot_web_game" / "assets" / "kit.glb"


def moved(bm, at, rot=(0, 0, 0)):
    m = Euler(rot).to_matrix()
    return transform_bm(bm, lambda v: m @ v + Vector(at))


# ---------------------------------------------------------------- snail

def snail():
    root = empty("snail")

    def lift(t):
        # The head end rises off the ground into a neck.
        return max(t - 0.1, 0.0) ** 2 * 0.9

    foot = lathe_bm([(-0.62, 0.02), (-0.55, 0.1), (-0.3, 0.17), (0.0, 0.2), (0.3, 0.19), (0.45, 0.17),
                     (0.56, 0.12), (0.6, 0.02)], segments=24, squash=(1.0, 0.75), lift=lift)
    mesh_obj("foot_body", moved(foot, (0, 0, 0.12)), root)

    # Eye stalks hang off pivots at the head so Godot can wave them, and so a boop can touch tips.
    for side, name in ((-1, "antenna_l"), (1, "antenna_r")):
        pivot = empty(name, root, loc=(side * 0.07, 0.5, 0.33))
        pts = [(side * 0.05 * t, 0.08 * t, 0.3 * t) for t in (i / 6 for i in range(7))]
        mesh_obj("stalk_body", tube_bm([Vector(p) for p in pts], [0.03 - 0.008 * i / 6 for i in range(7)], 10),
                 pivot)
        tip = Vector(pts[-1])
        mesh_obj("eye_eye", moved(sphere_bm(0.06, 16, 8), tip), pivot)
        mesh_obj("pupil_pupil", moved(sphere_bm(0.03, 12, 6), tip + Vector((0, 0.045, 0.005))), pivot)
    for side in (-1, 1):
        pts = [(side * (0.06 + 0.05 * t), 0.56 + 0.12 * t, 0.33 - 0.06 * t) for t in (i / 4 for i in range(5))]
        mesh_obj(f"feeler{side}_body", tube_bm([Vector(p) for p in pts], [0.018] * 5, 8), root)

    # The shell sits on its own pivot; hiding pulls the body in under it.
    shell = empty("shell", root, loc=(0, -0.12, 0.42))
    pts, radii = [], []
    turns = 2.6
    end = turns * 2 * math.pi
    growth = math.log(0.24 / 0.02) / end
    for i in range(61):
        a = end * i / 60
        r = 0.02 * math.exp(growth * a)
        # Each whorl's tube is a little fatter than the gap to the one inside it, so they touch.
        pts.append(Vector((0.05 * (1 - i / 60), r * math.cos(a), r * math.sin(a))))
        radii.append(0.015 + r * 0.62)
    spiral = tube_bm(pts, radii, 20)
    mesh_obj("shell_shell", transform_bm(spiral, lambda v: Vector((v.x * 0.85, -v.y, v.z))), shell)
    return root


# ---------------------------------------------------------------- garden

def flower():
    root = empty("flower")
    stem = [(0.03 * math.sin(t * 3), 0.0, 1.6 * t) for t in (i / 10 for i in range(11))]
    mesh_obj("stem_stem", tube_bm([Vector(p) for p in stem], [0.05] * 11, 10), root)
    for side in (-1, 1):
        leaf = sphere_bm(0.25, 16, 8, lambda v: Vector((v.x * 1.0, v.y * 0.35, v.z * 0.08)))
        mesh_obj(f"leaf{side}_stem", moved(leaf, (side * 0.22, 0, 0.5 + 0.2 * side), (0.3, -0.5 * side, 0)), root)
    head = empty("head", root, loc=(0, 0, 1.6))
    for i in range(7):
        a = 2 * math.pi * i / 7
        petal = sphere_bm(0.26, 16, 8, lambda v: Vector((v.x * 1.4, v.y * 0.7, v.z * 0.2)))
        mesh_obj(f"p{i}_petal", moved(petal, (0.3 * math.cos(a), 0.3 * math.sin(a), 0), (0.25, 0, a)), head)
    mesh_obj("disc_center", sphere_bm(0.16, 20, 10, lambda v: Vector((v.x, v.y, v.z * 0.6))), head)
    head.rotation_euler = (math.radians(-25), 0, 0)
    return root


def mushroom():
    root = empty("mushroom")
    mesh_obj("stalk_stem", lathe_bm([(0.0, 0.16), (0.5, 0.12), (0.75, 0.14)], axis="z", segments=20), root)
    cap = lathe_bm([(0.65, 0.5), (0.75, 0.52), (0.95, 0.42), (1.1, 0.22), (1.18, 0.0)], axis="z", segments=28)
    mesh_obj("cap_cap", cap, root)
    for i in range(7):
        a = 2 * math.pi * i / 7 + 0.4
        el = 0.6 if i % 2 else 0.95
        r = 0.42 if i % 2 else 0.2
        at = Vector((r * math.cos(a), r * math.sin(a), 0.65 + 0.4 * (1 - r) + (0.05 if el > 0.9 else 0)))
        mesh_obj(f"d{i}_dot", moved(sphere_bm(0.07, 12, 6, lambda v: Vector((v.x, v.y, v.z * 0.4))), at), root)
    return root


def pebble():
    root = empty("pebble")
    rock = sphere_bm(0.3, 12, 6, lambda v: Vector((v.x * 1.3, v.y, v.z * 0.6 + 0.05 * math.sin(v.x * 20))))
    mesh_obj("rock_rock", moved(rock, (0, 0, 0.12)), root, smooth=False)
    return root


def leaf():
    root = empty("leaf")
    blade = sphere_bm(1.0, 24, 12, lambda v: Vector((v.x * 0.55 * (1 - 0.3 * v.y), v.y * 1.2, v.z * 0.03 + 0.12 * v.x * v.x)))
    mesh_obj("blade_leaf", moved(blade, (0, 0, 0.03)), root)
    rib = [(0, -1.25 + 2.4 * t, 0.06) for t in (i / 8 for i in range(9))]
    mesh_obj("rib_stem", tube_bm([Vector(p) for p in rib], [0.025] * 9, 6), root)
    return root


def grass():
    root = empty("grass")
    for i in range(9):
        a = 2 * math.pi * i / 9
        h = 0.5 + 0.25 * ((i * 7) % 3)
        lean = Vector((math.cos(a), math.sin(a), 0)) * 0.25
        pts = [Vector((0.06 * math.cos(a), 0.06 * math.sin(a), 0)) + lean * (t * t) + Vector((0, 0, h * t))
               for t in (j / 5 for j in range(6))]
        mesh_obj(f"b{i}_grass", tube_bm(pts, [0.035 * (1 - j / 6) for j in range(6)], 5), root)
    return root


def fern():
    root = empty("fern")
    for i in range(6):
        a = 2 * math.pi * i / 6 + 0.3
        frond = sphere_bm(1.0, 16, 8, lambda v: Vector((v.x * 0.16, v.y * 0.7, v.z * 0.02)))
        bent = transform_bm(frond, lambda v: Vector((v.x, v.y + 0.7, v.z + 0.25 * (1 - ((v.y + 0.7) / 1.4 - 0.6) ** 2 * 3))))
        mesh_obj(f"f{i}_leaf", moved(bent, (0, 0, 0.1), (0, 0, a)), root)
    return root


def build():
    for i, part in enumerate((snail, flower, mushroom, pebble, leaf, grass, fern)):
        part().location = (i * 3.0, 0, 0)


if __name__ == "__main__":
    clear_scene()
    build()
    OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(OUT), export_format="GLB", export_yup=True, export_apply=False,
                              export_materials="NONE")
    print("exported", OUT)
