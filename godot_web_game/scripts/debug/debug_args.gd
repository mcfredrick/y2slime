## Command-line hooks for screenshots and checks. Pass after `--`:
##   --seed=<n>       fixed garden layout
##   --style=<style>  start your slime in that style (gloss, glitter, chrome, holo, bubble)
##   --drive=<s>      slide your snail in loops for that many seconds (sped up) to lay trails
##   --train          two neighbors fall in behind you
##   --boop           boop the nearest neighbor
##   --chat           every neighbor says something
##   --hide           shy neighbors hide
##   --touch          show the touch controls on desktop
##   --shot=<png>     save a screenshot after --wait seconds (default 2) and quit
class_name DebugArgs

static var drive_time := 0.0
static var _drive_start := 0.0


static func parse() -> Dictionary:
	var out := {}
	for arg in OS.get_cmdline_user_args():
		var parts := arg.trim_prefix("--").split("=", true, 1)
		out[parts[0]] = parts[1] if parts.size() > 1 else ""
	return out


## A wandering loop so a few seconds of driving paints overlapping curves.
static func drive_vector() -> Vector2:
	var t := Time.get_ticks_msec() / 1000.0 - _drive_start
	return Vector2.from_angle(t * 0.9 + sin(t * 0.37) * 2.0)


static func apply(args: Dictionary, main: Node3D) -> void:
	var garden: Garden = main.garden
	var player := garden.player
	if args.has("style"):
		player.set_slime(Color(GameData.flowers().filter(func(f): return f.style == args.style)[0].color), args.style)
		main.hud.show_slime(player.slime_color, player.slime_style)
	if args.has("chat"):
		for n in garden.neighbors:
			n.say(garden._line("near"), 99.0)
	if args.has("drive"):
		drive_time = float(args.drive)
		_drive_start = Time.get_ticks_msec() / 1000.0
		Engine.time_scale = 4.0
		await main.get_tree().create_timer(drive_time, true, false, true).timeout
		Engine.time_scale = 1.0
		drive_time = 0.0
		player.desire = Vector2.ZERO
	var nearest := garden.neighbors.duplicate()
	nearest.sort_custom(func(a, b): return a.ground.distance_to(player.ground) < b.ground.distance_to(player.ground))
	if args.has("train"):
		for i in 2:
			var n: Snail = nearest[i]
			n.place(player.ground - player.heading * SnailRules.TRAIN_GAP * (i + 1), player.heading)
			garden.train.append(n)
	if args.has("boop"):
		var n: Snail = nearest[0]
		n.place(player.head() + player.heading * (Snail.HEAD + 0.3), -player.heading)
		garden.boop(player, n)
	if args.has("hide"):
		for n in garden.neighbors:
			if n.shy:
				n.hide_in_shell(99.0)
	if args.has("shot"):
		await main.get_tree().create_timer(float(args.get("wait", "2"))).timeout
		await RenderingServer.frame_post_draw
		main.get_viewport().get_texture().get_image().save_png(args.shot)
		main.get_tree().quit()
