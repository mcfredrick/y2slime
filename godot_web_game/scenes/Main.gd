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
	DebugArgs.apply(debug, self)


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
