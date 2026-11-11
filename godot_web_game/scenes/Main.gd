extends Node3D

const CAMERA_OFFSET := Vector3(0, 3.0, 4.2)
const LOOK_AHEAD := Vector3(0, 0.4, -2.0)

var garden: Garden
var camera: Camera3D
var hud: Hud


func _ready() -> void:
	var debug := DebugArgs.parse()
	garden = Garden.new()
	add_child(garden)
	garden.build(int(debug.get("seed", randi())))
	camera = Camera3D.new()
	camera.fov = 62.0
	add_child(camera)
	_follow(1.0)
	hud = Hud.new()
	add_child(hud)
	hud.setup(camera, Garden.SUN, "--touch" in OS.get_cmdline_user_args())
	hud.show_slime(garden.player.slime_color, garden.player.slime_style)
	garden.player_slime_changed.connect(hud.show_slime)
	_warm_up()
	DebugArgs.apply(debug, self)


## Browsers compile each shader the first time it draws, and Label3D rasterizes glyphs on first
## use, which froze the game for a moment at the first boop and the first chat bubble. Draw a
## sparkle and every chat line once under the ground, out of sight, while the garden first loads.
func _warm_up() -> void:
	var under := garden.player.ground + Vector2(0, -2.5)
	# Deep enough that the stars never rise through the ground.
	Fx.sparkle(garden, under, -3.0)
	var bubble := Snail.make_bubble()
	var lines: Array = []
	for kind in GameData.load_json("chat"):
		lines.append_array(GameData.chat(kind))
	bubble.text = "\n".join(lines)
	bubble.modulate.a = 0.01
	bubble.outline_modulate.a = 0.01
	bubble.position = Vector3(under.x, -1.0, under.y)
	garden.add_child(bubble)
	for i in 3:
		await get_tree().process_frame
	bubble.queue_free()


func _physics_process(delta: float) -> void:
	var player := garden.player
	var keys := Vector2(
		_key_strength(KEY_D, "ui_right") - _key_strength(KEY_A, "ui_left"),
		_key_strength(KEY_S, "ui_down") - _key_strength(KEY_W, "ui_up"))
	var stick := hud.stick_vector()
	var want := stick if stick != Vector2.ZERO else keys.limit_length(1.0)
	if DebugArgs.drive_time > 0.0:
		want = DebugArgs.drive_vector()
	player.desire = want
	player.sprinting = Input.is_key_pressed(KEY_SHIFT) or hud.zoom_held()
	if want != Vector2.ZERO:
		hud.moved()
	_follow(clampf(4.0 * delta, 0.0, 1.0))
	garden.duck_plants(Vector2(camera.position.x, camera.position.z), delta)


func _key_strength(key: Key, action: String) -> float:
	return 1.0 if Input.is_physical_key_pressed(key) else Input.get_action_strength(action)


## The camera rides behind and above, looking a little ahead, and doesn't turn with the snail so
## the controls always mean the same direction on screen.
func _follow(weight: float) -> void:
	var at := Vector3(garden.player.ground.x, 0, garden.player.ground.y)
	camera.position = camera.position.lerp(at + CAMERA_OFFSET, weight)
	camera.look_at(camera.position - CAMERA_OFFSET + LOOK_AHEAD, Vector3.UP)
