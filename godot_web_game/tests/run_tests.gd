## Run: godot --headless --path godot_web_game --script res://tests/run_tests.gd
extends SceneTree

var _failures := 0


func _init() -> void:
	# Every test_ method runs, so a new test can't be written and then forgotten here.
	for m in get_method_list():
		if m.name.begins_with("test_"):
			call(m.name)
	print("FAILED: %d" % _failures if _failures else "all tests passed")
	quit(1 if _failures else 0)


func check(cond: bool, msg: String) -> void:
	if not cond:
		_failures += 1
		push_error(msg)


func test_boop_needs_heads_close_and_facing() -> void:
	var east := Vector2(1, 0)
	var west := Vector2(-1, 0)
	check(SnailRules.is_boop(Vector2.ZERO, east, Vector2(0.4, 0), west), "face to face boops")
	check(not SnailRules.is_boop(Vector2.ZERO, east, Vector2(2.0, 0), west), "too far apart")
	check(not SnailRules.is_boop(Vector2.ZERO, east, Vector2(0.4, 0), east), "nose to tail is no boop")
	check(not SnailRules.is_boop(Vector2.ZERO, west, Vector2(0.4, 0), east), "back to back is no boop")


func test_following_means_close_behind_and_moving() -> void:
	var north := Vector2(0, -1)
	check(SnailRules.is_following(Vector2.ZERO, north, Vector2(0, -1.2), true), "close behind, heading its way")
	check(not SnailRules.is_following(Vector2.ZERO, north, Vector2(0, -1.2), false), "standing still")
	check(not SnailRules.is_following(Vector2.ZERO, north, Vector2(0, -3.0), true), "too far behind")
	check(not SnailRules.is_following(Vector2.ZERO, north, Vector2(1.2, 0), true), "beside it")


func test_only_shy_snails_hide_from_a_rush() -> void:
	var fast := SnailRules.HIDE_SPEED + 0.1
	var at := Vector2(1.0, 0)
	check(SnailRules.should_hide(true, at, Vector2.ZERO, Vector2(1, 0), fast), "shy snail hides from a rush")
	check(not SnailRules.should_hide(false, at, Vector2.ZERO, Vector2(1, 0), fast), "bold snails don't hide")
	check(not SnailRules.should_hide(true, at, Vector2.ZERO, Vector2(1, 0), 0.5), "a slow approach is fine")
	check(not SnailRules.should_hide(true, at, Vector2.ZERO, Vector2(-1, 0), fast), "rushing away is fine")


func test_train_cars_sit_along_the_path() -> void:
	var path := PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(2, 0), Vector2(2, 1)])
	check(SnailRules.along_path(path, 0.5).is_equal_approx(Vector2(0.5, 0)), "halfway down the first step")
	check(SnailRules.along_path(path, 2.5).is_equal_approx(Vector2(2, 0.5)), "around the corner")
	check(SnailRules.along_path(path, 10.0) == Vector2(2, 1), "past the end stays at the end")


func test_content_is_complete() -> void:
	for f in GameData.flowers():
		check(f.style in SnailRules.STYLES, "flower has unknown style " + str(f.style))
	var used := GameData.flowers().map(func(f): return f.style)
	for style in SnailRules.STYLES:
		check(style in used, "no flower gives %s slime" % style)
	var snails: Dictionary = GameData.snails()
	for spec in [snails.player] + snails.neighbors:
		check(spec.style in SnailRules.STYLES, "%s has unknown style" % spec.name)
	check(snails.neighbors.any(func(n): return n.shy), "someone should be shy so hiding can happen")
	for kind in ["near", "boop", "train_join", "train_leave", "hide"]:
		check(not GameData.chat(kind).is_empty(), "no chat lines for " + kind)
