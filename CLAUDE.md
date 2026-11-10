# Snail Simulator 2: Y2Slime

A purposeless snail toy for crap.games in turn-of-the-millennium 3D (y2slime.crap.games; dev builds
at mcfredrick.github.io/y2slime). Sequel to Snail Simulator (`~/Crap Games/snail-simulator`, left
as it is). Design lives in `docs/DESIGN.md`; read it before adding features. Nothing in the game
may become a goal, score, unlock or fail state.

## Layout

- `godot_web_game/`: Godot 4.5.1, Compatibility renderer for the web. Scaffolded from
  crap-games-template (`copier update --trust` pulls template fixes).
  - `data/`: flowers and their slime styles, snails, chat lines. Shipped via `include_filter`.
  - `scripts/core/`: pure logic (`SnailRules`: boop, train, hide, style channels; `GameData`).
  - `scripts/world/`: `Garden` (builds the world, runs neighbor brains and interactions), `Snail`,
    `PaintLayer` (the slime), `Kit` (glTF parts and role materials), `Fx`, `Sfx`.
  - `scripts/ui/`: `Hud` (logo, slime pill, lens flare, hint, touch controls), `TouchStick`.
  - `shaders/`: sky, ground (reads the paint layer), candy plastic, jelly, chrome text.
  - `assets/`: generated kit, sounds and OFL fonts, committed so the game builds without Blender.
- `blender/`: the snail and garden kit, run inside Blender's Python.
- `tools/sfx.py`: synthesizes the sound effects.

## Commands

Run from `godot_web_game/` unless noted. `B` is `/Applications/Blender.app/Contents/MacOS/Blender`.

| Task | Command |
| --- | --- |
| Run the game | `godot --path .` |
| All checks (CI runs this before deploy) | `./test.sh` (repo root): compiles every script and runs the logic and content tests |
| Reimport (after assets or new `class_name`s) | `godot --headless --import` |
| Screenshot | `godot --path . --resolution 1152x648 -- --shot=out.png [--seed=1] [--style=chrome] [--drive=5] [--train] [--boop] [--chat] [--hide] [--touch] [--wait=2]` (flags in `scripts/debug/debug_args.gd`; run without `--headless`) |
| Kit | `$B -b --python blender/garden_kit.py` (repo root); preview with `$B -b --python blender/preview_kit.py -- out.png [--close]` |
| Sound effects | `uv run --with numpy python -I tools/sfx.py` (repo root) |
| Web build | `./export_web.sh` (repo root) |

## Conventions

- Content is data. Code reads `data/` and never hardcodes flowers, snails or chat text.
- Kit mesh names end in a material role (`_body`, `_shell`, `_eye`, `_pupil`, `_stem`, `_petal`,
  `_center`, `_cap`, `_dot`, `_rock`, `_leaf`, `_grass`); `Kit.dress` maps roles to colors. The
  snail's head is Blender +Y, which is Godot -Z.
- Snails live on the ground plane: positions and headings are `Vector2(x, z)`.
- Slime goes through `PaintLayer.stamp` only. Style channels: glitter (R), chrome (G), holo (B);
  bubble is a ring brush.
- HUD elements stay 84 px in from the left and right edges, clear of the page's share and music
  buttons.

## Gotchas

- New `class_name`s and new font or texture files need `godot --headless --import`.
- Physics runs before `_process` within a frame, so paint stamps live until the next frame or they
  are never drawn.
- GDScript can't infer types from Dictionary values: write `var x: float = d.v`.

## Verifying visual changes

Look at a rendered frame before calling a visual change done (screenshot command above). Logic
changes need `./test.sh` passing.

## Workflow Standards

- Solo project: commit directly to `main`, no PRs.
- Keep each commit a coherent unit, and don't mix refactors with features.
- Follow the user-level code standards (comments explain why, single code path, fail fast).
