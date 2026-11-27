class_name JsonUtil
extends RefCounted
## Small helpers for reading the data-driven content files.


static func load_dict(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Missing content file: %s" % path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Content file is not a JSON object: %s" % path)
		return {}
	return parsed


## JSON numbers come back as floats. True when v is a whole number.
static func is_whole(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	return typeof(v) == TYPE_FLOAT and is_finite(v) and v == floorf(v)
