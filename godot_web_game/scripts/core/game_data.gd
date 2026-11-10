## Read-only content from data/*.json.
class_name GameData

static var _cache := {}


static func load_json(name: String) -> Variant:
	if not _cache.has(name):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/%s.json" % name))
		assert(parsed != null, "data/%s.json does not parse" % name)
		_cache[name] = parsed
	return _cache[name]


static func flowers() -> Array:
	return load_json("flowers")


static func snails() -> Dictionary:
	return load_json("snails")


static func chat(kind: String) -> Array:
	return load_json("chat")[kind]
