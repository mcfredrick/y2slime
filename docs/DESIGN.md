# Snail Simulator 2: Y2Slime

You are a snail in a glossy turn-of-the-millennium garden. You slide around and leave slime. Other
snails do the same. There is no goal, no score and no way to lose. The sequel to Snail Simulator
(snailsim.crap.games), which stays as it is.

## Pillars

- **Purposeless.** Nothing to win, unlock or grind. Every system is a toy that responds to you.
- **Slime is the paint.** Everything a snail does shows up on the ground and stays there.
- **Snails are good company.** Neighbors wander, react to you and to each other.
- **Y2K maximalism.** Glossy, chrome, translucent and a little too much.

## Core loop

Slide around. The ground keeps every trail. Eat a flower and your slime changes. Meet a snail and
something small and nice happens. Take a picture of the garden with the share button.

## Systems

### Moving

Arrow keys or WASD steer and push; the snail turns smoothly and glides to a stop. Holding Shift (or
the touch zoom button) is a snail sprint, which is still slow. Touch uses a joystick.

### Slime

The ground carries a paint layer (a render texture covering the garden). Each snail stamps its
slime into it every few centimeters, so trails never fade and never cost more to draw as they grow.

- **Color** comes from the last flower eaten.
- **Style** comes from the flower too: gloss (plain wet slime), glitter (sparkles that twinkle as
  the camera moves), chrome (mirror slime reflecting the sky), holo (rainbow that shifts with the
  view angle), and bubble (rings of little bubbles).
- **Mixing.** Fresh slime blends over what's already there, so crossing a trail mixes the two
  colors where they meet, like wet paint.

### Neighbors

A few NPC snails wander the garden on lazy curves, eat flowers and leave their own trails.

- **Antenna boop.** Two snails meeting face to face touch antennae: sparkles, a chime, and they
  trade slime.
- **Slime train.** Follow close behind a snail for a couple of seconds and it falls in behind you
  instead. Snails in a train follow the leader's path, so their trails braid. Stop for a few seconds
  and the train breaks up.
- **Shell hide.** Some snails are shy. Sprint at one and it pulls into its shell for a moment.
- **Chat.** Near you, snails say things in Y2K chat style: away messages, emoticons, song lyrics
  they half remember. Text lives in `data/chat.json`.

### Living garden (later milestone)

Day and night, rain that leaves puddles which smear slime, leaves and ramps to slide over, and
critters that ignore you.

## Art direction

A mashup of three Y2K looks in real-time 3D:

- **Early 3D CGI.** A low-poly garden of oversized flowers, mushrooms, pebbles and leaves, modeled in
  Blender scripts and exported as a glTF kit. Distance fog in a hazy sky color.
- **Frutiger Aero.** A Bliss-style sky (deep blue to pale horizon, soft clouds), lush green ground,
  glossy translucent aqua UI panels and pill buttons, lens flare from the sun, water droplets.
- **Candy chrome.** Snail shells in translucent candy plastic with a hard specular highlight and rim
  light, chrome and holographic slime, chrome title text and starbursts.

Shaders stay simple for the Compatibility renderer (web): a stylized sky, a ground shader that
reads the paint layer, a candy-plastic shader for shells and a fresnel rim on bodies.

## Technical plan

- Godot 4.5.1, Compatibility renderer, scaffolded from crap-games-template.
- `blender/`: snail and garden kit, exported as `.glb` with materials assigned in Godot by mesh-name
  suffix (`_body`, `_shell`, `_eye`, `_petal`, `_leaf`, ...).
- `scripts/core/`: pure logic (snail brain decisions, train rules, boop detection, style table) so
  `tests/run_tests.gd` covers it without a scene.
- `data/`: flowers and their styles, snail personalities, chat lines.
- Screenshot harness (`--shot`, `--seed`, `--style`, `--train`, `--boop`) as in Fuel and Starship
  Tinkerer, plus `test.sh` run by CI before deploy.

## Milestones

1. **Playable slice.** One garden, your snail, the paint layer with all five styles, three
   neighbors with boop, train, hide and chat, the sky and Y2K UI. Deployed to github.io.
2. **Living garden.** Day and night, rain and puddles, ramps and leaves, critters, sound.
3. **Release.** Phone tuning, y2slime.crap.games, registry entry.

## Open questions

- Should the garden be bounded (a walled yard) or wrap around?
- Music: reuse Snail Simulator's SoundCloud track or find a Y2K one?
