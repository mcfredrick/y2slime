## The garden: sky, lawn and paint layer, scattered props and flowers, your snail and the
## neighbors. Runs the neighbors' brains and the snail-to-snail interactions each physics frame.
class_name Garden
extends Node3D

signal player_slime_changed(color: Color, style: String)

const SIZE := 40.0
## Snails stay inside this circle; a ring of ferns marks it.
const RADIUS := 16.5
const FLOWER_COUNT := 14
const FLOWER_REACH := 0.75
const FLOWER_REGROW := 7.0
const BOOP_COOLDOWN := 4.0
const CHAT_REACH := 3.5
const PATH_STEP := 0.1
const SUN := Vector3(0.35, 0.28, -0.89)

var rng := RandomNumberGenerator.new()
var paint: PaintLayer
var player: Snail
var neighbors: Array[Snail] = []
var train: Array[Snail] = []
## The player's recent path, newest first, for train cars to follow.
var path := PackedVector2Array()
var obstacles: Array = []
var flowers: Array = []
## Tall things that duck out of the camera's way.
var plants: Array[Node3D] = []

var _follow_time := {}
var _boop_cooldown := {}
var _chat_cooldown := {}
var _wander_target := {}
var _idle := 0.0


func build(seed_value: int) -> void:
	rng.seed = seed_value
	paint = PaintLayer.new()
	paint.garden_size = SIZE
	add_child(paint)
	_build_environment()
	_build_ground()
	_scatter_props()
	for i in FLOWER_COUNT:
		_add_flower()
	var specs: Dictionary = GameData.snails()
	player = Snail.create(specs.player, paint)
	player.is_player = true
	add_child(player)
	player.place(Vector2.ZERO, Vector2(0, -1))
	for spec in specs.neighbors:
		var n := Snail.create(spec, paint)
		add_child(n)
		n.place(_random_spot(4.0), Vector2.from_angle(rng.randf() * TAU))
		neighbors.append(n)
		_chat_cooldown[n] = rng.randf_range(2.0, 6.0)
	Kit.release()


func _build_environment() -> void:
	var sky_mat := ShaderMaterial.new()
	sky_mat.shader = load("res://shaders/sky.gdshader")
	sky_mat.set_shader_parameter("sun_dir", SUN)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_exposure = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.fog_enabled = true
	env.fog_light_color = Color(0.72, 0.86, 1.0)
	env.fog_density = 0.02
	env.fog_sky_affect = 0.0
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.2
	sun.light_color = Color(1.0, 0.96, 0.88)
	sun.shadow_enabled = true
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -SUN, Vector3.UP)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(SIZE * 3.0, SIZE * 3.0)
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/ground.gdshader")
	mat.set_shader_parameter("paint_color", paint.color_view.get_texture())
	mat.set_shader_parameter("paint_style", paint.style_view.get_texture())
	mat.set_shader_parameter("garden_size", SIZE)
	var ground := MeshInstance3D.new()
	ground.mesh = plane
	ground.material_override = mat
	add_child(ground)


func _scatter_props() -> void:
	# A ring of ferns and mushrooms marks the edge of the garden.
	for i in 48:
		var a := TAU * i / 48.0 + rng.randf_range(-0.05, 0.05)
		var r := RADIUS + 1.2 + rng.randf_range(0.0, 1.5)
		_prop("fern" if i % 3 else "mushroom", Vector2.from_angle(a) * r, rng.randf_range(1.6, 2.6), false)
	for i in 70:
		_prop("grass", _random_spot(0.0, 2.0), rng.randf_range(0.6, 1.4), false)
	for i in 8:
		_prop("leaf", _random_spot(3.0), rng.randf_range(0.9, 1.4), false)
	for i in 10:
		_prop("pebble", _random_spot(3.0), rng.randf_range(1.0, 2.2), true)
	for i in 6:
		_prop("mushroom", _random_spot(4.0), rng.randf_range(0.8, 1.3), true)


func _prop(kind: String, at: Vector2, size: float, solid: bool) -> void:
	var colors := {"stem": Color(0.94, 0.9, 0.78), "cap": Color(0.95, 0.18, 0.22), "dot": Color(1, 1, 1),
		"rock": Color(0.62, 0.66, 0.74), "leaf": Color(0.3, 0.72, 0.28), "grass": Color(0.35, 0.8, 0.25)}
	if kind == "leaf" or kind == "fern":
		colors.stem = Color(0.25, 0.55, 0.2)
	var node := Kit.part(kind)
	Kit.dress(node, colors, [] if kind != "mushroom" else ["cap"])
	node.position = Vector3(at.x, 0, at.y)
	node.rotation.y = rng.randf() * TAU
	node.scale = Vector3.ONE * size
	add_child(node)
	if kind in ["grass", "mushroom", "fern"]:
		plants.append(node)
	if solid:
		obstacles.append({"at": at, "radius": (0.4 if kind == "pebble" else 0.25) * size + 0.35})


func _add_flower() -> void:
	var spec: Dictionary = GameData.flowers()[rng.randi() % GameData.flowers().size()]
	var node := Kit.part("flower")
	var petal := Color(spec.color)
	Kit.dress(node, {"stem": Color(0.3, 0.7, 0.25), "petal": petal, "center": Color(1, 0.9, 0.3)}, ["petal"])
	var at := _random_spot(2.0)
	node.position = Vector3(at.x, 0, at.y)
	node.rotation.y = rng.randf() * TAU
	node.scale = Vector3.ONE * rng.randf_range(0.7, 1.0)
	add_child(node)
	plants.append(node)
	flowers.append({"node": node, "at": at, "color": petal, "style": spec.style, "eaten": false})


## A spot inside the garden, away from the middle (where you start) and clear of solid props.
func _random_spot(clear_of_start: float, clearance := 1.0) -> Vector2:
	for attempt in 50:
		var p := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * (RADIUS - 1.0)
		if p.length() < clear_of_start:
			continue
		var blocked := false
		for o in obstacles:
			if p.distance_to(o.at) < o.radius + clearance:
				blocked = true
				break
		if not blocked:
			return p
	return Vector2.from_angle(rng.randf() * TAU) * (RADIUS - 1.0)


func _physics_process(delta: float) -> void:
	_track_path()
	_update_train(delta)
	for n in neighbors:
		_think(n, delta)
	for s in [player] + neighbors:
		_keep_in_bounds(s)
	_check_boops(delta)
	_check_hiding()
	_check_flowers()
	_chat(delta)


## Plants between the camera and your snail sink into the lawn so they never block the view, then
## pop back up once the camera has passed.
func duck_plants(camera_ground: Vector2, delta: float) -> void:
	var to_player := player.ground - camera_ground
	for node in plants:
		var at := Vector2(node.position.x, node.position.z)
		var t := clampf((at - camera_ground).dot(to_player) / to_player.length_squared(), 0.0, 1.0)
		var off := at.distance_to(camera_ground + to_player * t)
		var blocking := t < 0.92 and off < 1.0
		node.scale.y = lerpf(node.scale.y, node.scale.x * (0.08 if blocking else 1.0), clampf(delta * 8.0, 0.0, 1.0))


func _track_path() -> void:
	if path.is_empty() or path[0].distance_to(player.ground) >= PATH_STEP:
		path.insert(0, player.ground)
		var keep := int((train.size() + 2) * SnailRules.TRAIN_GAP / PATH_STEP) + 20
		if path.size() > keep:
			path.resize(keep)


func _update_train(delta: float) -> void:
	_idle = _idle + delta if player.speed < 0.05 else 0.0
	if _idle >= SnailRules.TRAIN_IDLE and not train.is_empty():
		for n in train:
			n.say(_line("train_leave"))
			_wander_target.erase(n)
		train.clear()
		return
	var lead_dir := player.heading
	for n in neighbors:
		if n in train or n.is_busy():
			continue
		var following := SnailRules.is_following(player.ground, lead_dir, n.ground, player.speed > 0.2)
		_follow_time[n] = _follow_time.get(n, 0.0) + delta if following else 0.0
		if _follow_time[n] >= SnailRules.FOLLOW_TIME:
			_follow_time[n] = 0.0
			train.append(n)
			n.say(_line("train_join"))


func _think(n: Snail, _delta: float) -> void:
	n.sprinting = false
	var idx := train.find(n)
	if idx >= 0:
		var spot := SnailRules.along_path(path, SnailRules.TRAIN_GAP * (idx + 1))
		var to := spot - n.ground
		n.desire = to.normalized() * clampf(to.length() / 0.4, 0.0, 1.0) if to.length() > 0.08 else Vector2.ZERO
		n.sprinting = to.length() > 1.5
		return
	if not _wander_target.has(n) or n.ground.distance_to(_wander_target[n]) < 0.6 or rng.randf() < 0.002:
		_wander_target[n] = _pick_wander_target(n)
	var dir: Vector2 = (_wander_target[n] - n.ground).normalized()
	n.desire = (dir + _avoid(n) * 1.5).normalized() * 0.8


func _pick_wander_target(n: Snail) -> Vector2:
	# Neighbors are partial to flowers but mostly just mosey.
	var open := flowers.filter(func(f): return not f.eaten)
	if not open.is_empty() and rng.randf() < 0.4:
		open.sort_custom(func(a, b): return a.at.distance_to(n.ground) < b.at.distance_to(n.ground))
		return open[0].at
	return _random_spot(0.0, 0.5)


func _avoid(n: Snail) -> Vector2:
	var push := Vector2.ZERO
	for o in obstacles:
		var away: Vector2 = n.ground - o.at
		var d := away.length()
		if d < o.radius + 1.0:
			push += away.normalized() * (o.radius + 1.0 - d)
	return push


func _keep_in_bounds(s: Snail) -> void:
	for o in obstacles:
		var away: Vector2 = s.ground - o.at
		if away.length() < o.radius:
			s.ground = o.at + away.normalized() * o.radius
	if s.ground.length() > RADIUS:
		s.ground = s.ground.normalized() * RADIUS
	for other in [player] + neighbors:
		if other == s:
			continue
		var apart: Vector2 = s.ground - other.ground
		if apart.length() < 0.55 and apart.length() > 0.001:
			s.ground = other.ground + apart.normalized() * 0.55


func _check_boops(delta: float) -> void:
	for k in _boop_cooldown.keys():
		_boop_cooldown[k] -= delta
		if _boop_cooldown[k] <= 0.0:
			_boop_cooldown.erase(k)
	var all: Array = [player] + neighbors
	for i in all.size():
		for j in range(i + 1, all.size()):
			var a: Snail = all[i]
			var b: Snail = all[j]
			if a.is_hidden() or b.is_hidden() or _boop_cooldown.has(a) or _boop_cooldown.has(b):
				continue
			if SnailRules.is_boop(a.head(), a.heading, b.head(), b.heading):
				boop(a, b)


func boop(a: Snail, b: Snail) -> void:
	var a_slime := [a.slime_color, a.slime_style]
	a.boop(b.slime_color, b.slime_style)
	b.boop(a_slime[0], a_slime[1])
	_boop_cooldown[a] = BOOP_COOLDOWN
	_boop_cooldown[b] = BOOP_COOLDOWN
	Fx.sparkle(self, a.head().lerp(b.head(), 0.5))
	Sfx.play("boop")
	for s in [a, b]:
		if not s.is_player:
			s.say(_line("boop"), 2.0)
	if a == player or b == player:
		player_slime_changed.emit(player.slime_color, player.slime_style)


func _check_hiding() -> void:
	for n in neighbors:
		if not n.is_hidden() and SnailRules.should_hide(n.shy, n.ground, player.ground, player.heading, player.speed):
			n.hide_in_shell(3.0)
			n.say(_line("hide"), 1.5)
			train.erase(n)


func _check_flowers() -> void:
	for f in flowers:
		if f.eaten:
			continue
		for s in [player] + neighbors:
			if s.head().distance_to(f.at) < FLOWER_REACH and not s.is_hidden():
				_eat(f, s)
				break


func _eat(f: Dictionary, s: Snail) -> void:
	f.eaten = true
	s.set_slime(f.color, f.style)
	if s == player:
		Sfx.play("munch")
		player_slime_changed.emit(f.color, f.style)
	var node: Node3D = f.node
	var tween := node.create_tween()
	tween.tween_property(node, "scale", Vector3.ZERO, 0.3).set_trans(Tween.TRANS_BACK)
	tween.tween_interval(FLOWER_REGROW)
	tween.tween_callback(func():
		f.at = _random_spot(1.5)
		node.position = Vector3(f.at.x, 0, f.at.y)
		f.eaten = false)
	tween.tween_property(node, "scale", Vector3.ONE * rng.randf_range(0.7, 1.0), 0.6).set_trans(Tween.TRANS_ELASTIC)


func _chat(delta: float) -> void:
	for n in neighbors:
		_chat_cooldown[n] -= delta
		if _chat_cooldown[n] > 0.0 or n.ground.distance_to(player.ground) > CHAT_REACH or n.is_busy():
			continue
		n.say(_line("near"))
		_chat_cooldown[n] = rng.randf_range(6.0, 12.0)


func _line(kind: String) -> String:
	var lines := GameData.chat(kind)
	return lines[rng.randi() % lines.size()]
