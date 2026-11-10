## Plays the generated sound effects in assets/sfx/ (made by tools/sfx.py).
class_name Sfx

static var _players := {}


static func play(name: String) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not _players.has(name) or not is_instance_valid(_players[name]):
		var p := AudioStreamPlayer.new()
		p.stream = load("res://assets/sfx/%s.wav" % name)
		p.volume_db = -6.0
		tree.root.add_child(p)
		_players[name] = p
	var player: AudioStreamPlayer = _players[name]
	player.pitch_scale = randf_range(0.92, 1.08)
	player.play()
