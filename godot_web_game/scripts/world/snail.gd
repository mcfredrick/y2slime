## One snail, yours or a neighbor's. Moves on the ground plane toward whatever direction it's told,
## lays slime behind it, and acts out boops, hiding and chat. Decisions live in Garden and
## SnailRules; this node only moves and animates.
class_name Snail
extends Node3D

const SPEED := 0.9
const SPRINT := 2.1
const TURN := 4.0
const ACCEL := 2.5
const SLIME_WIDTH := 0.32
const SLIME_STEP := 0.06
## From the snail's origin to its head and to where slime comes out.
const HEAD := 0.62
const TAIL := 0.3

var display_name := ""
var shy := false
var is_player := false
var slime_color := Color.WHITE
var slime_style := "gloss"
## Ground position (x, z) and unit heading on the ground.
var ground := Vector2.ZERO
var heading := Vector2(0, -1)
var speed := 0.0
## Set each frame by Garden: where to go (zero to stop) and whether to sprint.
var desire := Vector2.ZERO
var sprinting := false

var paint: PaintLayer
var _since_stamp := 0.0
var _busy := 0.0
var _hidden := 0.0
var _model: Node3D
var _antennae: Array[Node3D] = []
var _foot: Node3D
var _bubble: Label3D
var _bubble_time := 0.0
var _boop_time := 0.0


static func create(spec: Dictionary, painter: PaintLayer) -> Snail:
	var s := Snail.new()
	s.display_name = spec.name
	s.shy = spec.get("shy", false)
	s.slime_color = Color(spec.slime)
	s.slime_style = spec.style
	s.paint = painter
	s._model = Kit.part("snail")
	Kit.dress(s._model, {"body": Color(spec.body), "shell": Color(spec.shell), "eye": Color(1, 1, 1),
		"pupil": Color(0.05, 0.03, 0.12)}, ["shell"], 1.0)
	s.add_child(s._model)
	s._antennae = [s._model.find_child("*antenna_l", true, false), s._model.find_child("*antenna_r", true, false)]
	s._foot = s._model.find_child("*foot_body", true, false)
	s._bubble = make_bubble()
	s._bubble.position = Vector3(0, 1.25, 0)
	s._bubble.visible = false
	s.add_child(s._bubble)
	return s


static func make_bubble() -> Label3D:
	var bubble := Label3D.new()
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.font_size = 44
	bubble.pixel_size = 0.004
	bubble.outline_size = 14
	bubble.modulate = Color(0.05, 0.1, 0.35)
	bubble.outline_modulate = Color(0.85, 0.97, 1.0)
	bubble.no_depth_test = true
	return bubble


func head() -> Vector2:
	return ground + heading * HEAD


func is_hidden() -> bool:
	return _hidden > 0.0


func is_busy() -> bool:
	return _busy > 0.0 or _hidden > 0.0


func set_slime(color: Color, style: String) -> void:
	slime_color = color
	slime_style = style


func place(at: Vector2, facing: Vector2) -> void:
	ground = at
	heading = facing.normalized()
	_sync_transform()


func _physics_process(delta: float) -> void:
	_busy = maxf(_busy - delta, 0.0)
	_tick_hide(delta)
	var want := desire if not is_busy() else Vector2.ZERO
	if want.length() > 0.01:
		var target_angle := want.angle()
		var angle := lerp_angle(heading.angle(), target_angle, clampf(TURN * delta, 0.0, 1.0))
		heading = Vector2.from_angle(angle)
	var top := (SPRINT if sprinting else SPEED) * clampf(want.length(), 0.0, 1.0)
	speed = move_toward(speed, top, ACCEL * delta)
	var step := heading * speed * delta
	ground += step
	_sync_transform()
	_since_stamp += step.length()
	if _since_stamp >= SLIME_STEP:
		_since_stamp = 0.0
		paint.stamp(ground - heading * TAIL, SLIME_WIDTH, slime_color, slime_style)


func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 + float(get_instance_id() % 97)
	_boop_time = maxf(_boop_time - delta, 0.0)
	for i in _antennae.size():
		var side := -1.0 if i == 0 else 1.0
		var sway := sin(t * 2.2 + i) * 0.12
		# A boop leans both stalks forward to touch tips with the other snail.
		var lean := -0.9 if _boop_time > 0.0 else 0.0
		_antennae[i].rotation = Vector3(lean + sway * 0.5, 0, side * sway)
	if _bubble.visible:
		_bubble_time -= delta
		if _bubble_time <= 0.0:
			_bubble.visible = false


## Touch antennae with another snail and take on its slime.
func boop(other_color: Color, other_style: String) -> void:
	_busy = 1.3
	_boop_time = 1.0
	speed = 0.0
	set_slime(other_color, other_style)


func hide_in_shell(seconds: float) -> void:
	if is_hidden():
		return
	_hidden = seconds
	speed = 0.0
	var tween := create_tween().set_parallel()
	tween.tween_property(_foot, "scale", Vector3(0.55, 0.6, 0.5), 0.15)
	for a in _antennae:
		tween.tween_property(a, "scale", Vector3.ONE * 0.05, 0.15)


func _tick_hide(delta: float) -> void:
	if _hidden <= 0.0:
		return
	_hidden -= delta
	if _hidden <= 0.0:
		var tween := create_tween().set_parallel()
		tween.tween_property(_foot, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK)
		for a in _antennae:
			tween.tween_property(a, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK)


func say(text: String, seconds := 3.0) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble_time = seconds


func _sync_transform() -> void:
	position = Vector3(ground.x, 0, ground.y)
	# The kit's snail faces Godot -Z; turn that toward the heading.
	rotation.y = atan2(-heading.x, -heading.y)
