## The Y2K overlay: chrome logo, a glossy aqua "now sliming" pill, a lens flare off the sun, the
## first-time controls hint and touch controls. Kept 84 px in from the page's share and music
## buttons in the top corners.
class_name Hud
extends CanvasLayer

const INSET := 84.0
const AQUA := Color(0.2, 0.62, 0.95)
const INK := Color(0.04, 0.12, 0.35)

var _camera: Camera3D
var _sun: Vector3
var _flare: Control
var _swatch: ColorRect
var _style_label: Label
var _hint: Label
var _stick: TouchStick
var _zoom: Button
var _font: Font


func setup(camera: Camera3D, sun: Vector3, force_touch: bool) -> void:
	_camera = camera
	_sun = sun.normalized()
	_font = load("res://assets/fonts/Fredoka.ttf")
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = _font
	root.theme = theme
	add_child(root)

	_flare = Control.new()
	_flare.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flare.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flare.draw.connect(_draw_flare)
	root.add_child(_flare)

	_build_logo(root)
	_build_slime_pill(root)
	var touch := force_touch or DisplayServer.is_touchscreen_available()
	_hint = Label.new()
	_hint.text = "drag the stick to slide  ~  hold ZOOM to hurry" if touch else "arrows / WASD to slide  ~  hold Shift to hurry"
	_hint.add_theme_font_size_override("font_size", 22)
	_hint.add_theme_color_override("font_color", Color(1, 1, 1))
	_hint.add_theme_color_override("font_outline_color", INK)
	_hint.add_theme_constant_override("outline_size", 8)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_top = -150 if touch else -140
	_hint.offset_bottom = _hint.offset_top + 40
	_hint.grow_horizontal = Control.GROW_DIRECTION_BOTH
	root.add_child(_hint)
	if touch:
		_build_touch(root)


func _build_logo(root: Control) -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(INSET, 14)
	box.add_theme_constant_override("separation", -10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(box)
	var small := Label.new()
	small.text = "Snail Simulator 2"
	small.add_theme_font_size_override("font_size", 20)
	small.add_theme_color_override("font_color", Color(1, 1, 1))
	small.add_theme_color_override("font_outline_color", INK)
	small.add_theme_constant_override("outline_size", 7)
	box.add_child(small)
	var big := Label.new()
	big.text = "Y2SLIME"
	big.add_theme_font_size_override("font_size", 52)
	big.add_theme_color_override("font_outline_color", INK)
	big.add_theme_constant_override("outline_size", 12)
	var chrome := ShaderMaterial.new()
	chrome.shader = load("res://shaders/chrome_text.gdshader")
	chrome.set_shader_parameter("height", 64.0)
	big.material = chrome
	box.add_child(big)


func _build_slime_pill(root: Control) -> void:
	var pill := _aqua_panel(28)
	pill.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	pill.position = Vector2(INSET, -86)
	pill.size = Vector2(300, 56)
	pill.grow_vertical = Control.GROW_DIRECTION_BEGIN
	root.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	pill.add_child(row)
	_swatch = ColorRect.new()
	_swatch.custom_minimum_size = Vector2(30, 30)
	row.add_child(_swatch)
	_style_label = Label.new()
	_style_label.add_theme_font_size_override("font_size", 22)
	_style_label.add_theme_color_override("font_color", Color(1, 1, 1))
	_style_label.add_theme_color_override("font_outline_color", INK)
	_style_label.add_theme_constant_override("outline_size", 6)
	row.add_child(_style_label)


## A glossy translucent aqua panel with the Y2K highlight across its top half.
func _aqua_panel(radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(AQUA, 0.78)
	box.set_corner_radius_all(radius)
	box.set_border_width_all(2)
	box.border_color = Color(0.85, 0.96, 1.0, 0.95)
	box.shadow_color = Color(0.0, 0.15, 0.4, 0.35)
	box.shadow_size = 6
	box.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", box)
	var shine := StyleBoxFlat.new()
	shine.bg_color = Color(1, 1, 1, 0.32)
	shine.corner_radius_top_left = radius - 4
	shine.corner_radius_top_right = radius - 4
	shine.corner_radius_bottom_left = 6
	shine.corner_radius_bottom_right = 6
	# Drawn on the panel itself, under its children, so the shine never covers the content.
	panel.draw.connect(func(): shine.draw(panel.get_canvas_item(), Rect2(6, 3, panel.size.x - 12, panel.size.y * 0.45)))
	return panel


func _build_touch(root: Control) -> void:
	_stick = TouchStick.new()
	_stick.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stick.position = Vector2(INSET - 20, -270)
	_stick.size = Vector2(170, 170)
	root.add_child(_stick)
	_zoom = Button.new()
	_zoom.text = "ZOOM"
	_zoom.focus_mode = Control.FOCUS_NONE
	_zoom.add_theme_font_size_override("font_size", 26)
	_zoom.add_theme_color_override("font_color", Color.WHITE)
	_zoom.add_theme_color_override("font_outline_color", INK)
	_zoom.add_theme_constant_override("outline_size", 6)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(1.0, 0.45, 0.85, 0.8)
	box.set_corner_radius_all(60)
	box.set_border_width_all(2)
	box.border_color = Color(1, 0.9, 1)
	for state in ["normal", "hover", "pressed", "focus"]:
		_zoom.add_theme_stylebox_override(state, box)
	_zoom.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_zoom.size = Vector2(120, 120)
	_zoom.position = Vector2(-INSET - 100, -200)
	root.add_child(_zoom)


func show_slime(color: Color, style: String) -> void:
	_swatch.color = color
	_style_label.text = "now sliming: %s" % style.to_upper()


func moved() -> void:
	if _hint and _hint.modulate.a >= 1.0:
		var tween := _hint.create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(_hint, "modulate:a", 0.0, 0.8)
		tween.tween_callback(_hint.queue_free)
		_hint.modulate.a = 0.999


func stick_vector() -> Vector2:
	return _stick.vector if _stick else Vector2.ZERO


func zoom_held() -> bool:
	return _zoom != null and _zoom.button_pressed


func _process(_delta: float) -> void:
	_flare.queue_redraw()


## Rings and blobs strung from the sun through the middle of the screen, like a 2000-era render.
func _draw_flare() -> void:
	var sun_point := _camera.global_position + _sun * 500.0
	if _camera.is_position_behind(sun_point):
		return
	var view := _flare.size
	var at := _camera.unproject_position(sun_point)
	var center := view / 2.0
	var edge := clampf(1.0 - at.distance_to(center) / view.length(), 0.0, 1.0)
	_flare.draw_circle(at, 60, Color(1, 0.98, 0.85, 0.25 * edge))
	var blobs := [[0.35, 26, Color(0.6, 0.9, 1, 0.2)], [0.7, 14, Color(1, 0.7, 0.95, 0.25)],
		[1.25, 40, Color(0.7, 1, 0.8, 0.12)], [1.6, 20, Color(0.8, 0.85, 1, 0.2)], [2.1, 60, Color(1, 0.9, 0.6, 0.08)]]
	for b in blobs:
		var p: Vector2 = at.lerp(center, b[0])
		_flare.draw_circle(p, b[1], Color(b[2], b[2].a * edge))
		_flare.draw_arc(p, b[1], 0, TAU, 32, Color(1, 1, 1, 0.18 * edge), 1.5)
