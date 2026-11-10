## Little one-shot effects.
class_name Fx

static var _star: Texture2D


## A burst of twinkling stars at a ground point, for boops.
static func sparkle(parent: Node3D, at: Vector2) -> void:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * 0.18
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _star_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	p.mesh = quad
	p.one_shot = true
	p.explosiveness = 0.9
	p.amount = 24
	p.lifetime = 1.0
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.8
	p.gravity = Vector3(0, -1.2, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 0.6, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1), Color(1, 0.6, 0.95), Color(0.5, 0.9, 1), Color(0.5, 0.9, 1, 0)])
	p.color_ramp = ramp
	p.position = Vector3(at.x, 0.45, at.y)
	p.finished.connect(p.queue_free)
	parent.add_child(p)
	p.emitting = true


static func _star_texture() -> Texture2D:
	if _star == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.6), Color(1, 1, 1, 0)])
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		_star = tex
	return _star
