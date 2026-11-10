# Snail Simulator 2: Y2Slime

You are a snail in a glossy turn-of-the-millennium garden. Leave chrome, glitter, holo and bubble
slime trails, boop other snails, form slime trains. There is no point.

Play: https://mcfredrick.github.io/y2slime/ (y2slime.crap.games once released). The original
Snail Simulator is at https://snailsim.crap.games.

## Controls

- Arrow keys or WASD to slide, hold Shift to hurry.
- On phones, the stick slides and ZOOM hurries.
- Eat a flower to change your slime. Meet a snail face to face to boop. Tail one for a couple of
  seconds and it joins your slime train.

## Development

Godot 4.5.1. See `CLAUDE.md` for layout and commands and `docs/DESIGN.md` for the design.

```bash
./test.sh                                   # every check, also run by CI before deploy
godot --path godot_web_game                 # play
./export_web.sh                             # web build into godot_web_game/build/web
```
