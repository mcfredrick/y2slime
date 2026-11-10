## An on-screen joystick drawn as a glossy aqua bubble. Tracks its own touch index so it works
## while another finger holds ZOOM.
class_name TouchStick
extends Control

var vector := Vector2.ZERO
var _touch := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	var rect := get_global_rect().grow(60)
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1 and rect.has_point(event.position):
			_touch = event.index
			_aim(event.position)
		elif not event.pressed and event.index == _touch:
			_touch = -1
			vector = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch:
		_aim(event.position)


func _aim(at: Vector2) -> void:
	var radius := size.x / 2.0
	vector = ((at - get_global_rect().get_center()) / radius).limit_length(1.0)
	queue_redraw()


func _draw() -> void:
	var c := size / 2.0
	var r := size.x / 2.0
	draw_circle(c, r, Color(0.2, 0.62, 0.95, 0.35))
	draw_arc(c, r, 0, TAU, 48, Color(0.85, 0.96, 1.0, 0.9), 2.5, true)
	var knob := c + vector * r * 0.6
	draw_circle(knob, r * 0.38, Color(0.25, 0.7, 1.0, 0.9))
	draw_circle(knob + Vector2(0, -r * 0.14), r * 0.22, Color(1, 1, 1, 0.35))
	draw_arc(knob, r * 0.38, 0, TAU, 40, Color(1, 1, 1, 0.9), 2.0, true)
