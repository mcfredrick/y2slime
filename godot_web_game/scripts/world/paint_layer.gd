## The slime on the ground. Two render textures cover the garden and are never cleared: one holds
## slime color, the other style channels (SnailRules.style_channels). Snails stamp brushes into
## both, each stamp drawn once and then dropped, so trails last forever at a fixed cost and fresh
## slime blends over old slime where trails cross.
class_name PaintLayer
extends Node

const RESOLUTION := 2048
## Coverage of one stamp; overlapping stamps build up and blend colors.
const STAMP_ALPHA := 0.55

var garden_size := 40.0
var color_view: SubViewport
var style_view: SubViewport

var _dot: Texture2D
var _ring: Texture2D
## Stamps with the frame they were added in; each is freed once that frame has been rendered.
var _drawn: Array = []


func _ready() -> void:
	color_view = _make_view()
	style_view = _make_view()
	_dot = _brush(false)
	_ring = _brush(true)


func _make_view() -> SubViewport:
	var view := SubViewport.new()
	view.size = Vector2i(RESOLUTION, RESOLUTION)
	view.transparent_bg = true
	view.disable_3d = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
	add_child(view)
	return view


## Lay slime at a ground point (x, z) `width` meters across.
func stamp(at: Vector2, width: float, color: Color, style: String) -> void:
	var px := (at / garden_size + Vector2(0.5, 0.5)) * RESOLUTION
	var size := width / garden_size * RESOLUTION
	if style == "bubble":
		# Bubble slime is a froth of little rings instead of a smear.
		for i in 3:
			var off := Vector2(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5)) * size
			_put(px + off, size * randf_range(0.3, 0.55), _ring, color, Color(0, 0, 0))
		return
	_put(px, size, _dot, color, SnailRules.style_channels(style))


func _put(px: Vector2, size: float, tex: Texture2D, color: Color, channels: Color) -> void:
	for pair in [[color_view, color], [style_view, channels]]:
		var s := Sprite2D.new()
		s.texture = tex
		s.position = px
		s.scale = Vector2.ONE * size / tex.get_width()
		s.modulate = Color(pair[1].r, pair[1].g, pair[1].b, STAMP_ALPHA)
		pair[0].add_child(s)
		_drawn.append([Engine.get_process_frames(), s])


func _process(_delta: float) -> void:
	# Physics runs before _process within a frame, so only stamps from earlier frames have been
	# drawn into the never-cleared textures yet.
	var now := Engine.get_process_frames()
	var keep: Array = []
	for entry in _drawn:
		if entry[0] < now:
			entry[1].queue_free()
		else:
			keep.append(entry)
	_drawn = keep


func _brush(ring: bool) -> Texture2D:
	var g := Gradient.new()
	if ring:
		g.offsets = PackedFloat32Array([0.0, 0.6, 0.72, 0.9, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 0.1), Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	else:
		g.offsets = PackedFloat32Array([0.0, 0.7, 1.0])
		g.colors = PackedColorArray([Color.WHITE, Color.WHITE, Color(1, 1, 1, 0)])
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	return tex
