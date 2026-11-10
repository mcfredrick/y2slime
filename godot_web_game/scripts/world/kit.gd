## Parts from the Blender kit (assets/kit.glb), dressed with materials by mesh-name role.
class_name Kit

const CANDY := preload("res://shaders/candy.gdshader")
const JELLY := preload("res://shaders/jelly.gdshader")

static var _kit: Node3D


## A fresh copy of a top-level part (snail, flower, mushroom, pebble, leaf, grass, fern).
static func part(name: String) -> Node3D:
	if _kit == null:
		_kit = (load("res://assets/kit.glb") as PackedScene).instantiate()
	var source := _kit.find_child(name, false, false) as Node3D
	assert(source != null, "kit has no part " + name)
	var copy := source.duplicate() as Node3D
	copy.transform = Transform3D.IDENTITY
	return copy


## Drop the cached kit once everything is built; it never joins the scene tree, so it would
## otherwise leak at exit.
static func release() -> void:
	if _kit:
		_kit.free()
		_kit = null


## Give every mesh under `node` a material for its role. `colors` maps role to color; `candy` roles
## get the candy-plastic shader, everything else glossy jelly.
static func dress(node: Node, colors: Dictionary, candy: Array = [], wobble := 0.0) -> void:
	var cache := {}
	for mesh in node.find_children("*", "MeshInstance3D", true, false):
		var role: String = mesh.name.get_slice("_", mesh.name.get_slice_count("_") - 1)
		assert(colors.has(role), "no color for role %s on %s" % [role, mesh.name])
		if not cache.has(role):
			var mat := ShaderMaterial.new()
			mat.shader = CANDY if role in candy else JELLY
			mat.set_shader_parameter("color", colors[role])
			if role not in candy:
				mat.set_shader_parameter("wobble", wobble)
			cache[role] = mat
		(mesh as MeshInstance3D).material_override = cache[role]
