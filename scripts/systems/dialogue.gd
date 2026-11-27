class_name Dialogue
extends RefCounted
## Dialogue content: scenes are lists of steps in content/dialogue/*.json.
##
## Step types:
##   {"speaker": "reno", "text": "..."}            a line
##   {"choice": [{"text": "...", "then": [steps]}]} up to three flavour choices
##   {"set_flag": "x"} {"key_item": "id"} {"join": "lumi"}
##   {"item": "id", "count": n} {"quest": "PRO-002", "state": "active"}
## Any step can carry "if_flags" / "if_not_flags" to only run sometimes.

const DIR := "res://content/dialogue/"

static var _scenes: Dictionary = {}
static var _speakers: Dictionary = {}


static func _ensure_loaded() -> void:
	if not _scenes.is_empty():
		return
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".json"):
			continue
		var d := JsonUtil.load_dict(DIR + f)
		_scenes.merge(d.get("scenes", {}))
		_speakers.merge(d.get("speakers", {}))


static func has_scene(id: String) -> bool:
	_ensure_loaded()
	return _scenes.has(id)


static func scene(id: String) -> Array:
	_ensure_loaded()
	return _scenes.get(id, [])


static func speaker(id: String) -> Dictionary:
	_ensure_loaded()
	return _speakers.get(id, {"name": id.capitalize()})


static func scene_ids() -> Array:
	_ensure_loaded()
	return _scenes.keys()


## Checks every scene's steps. Returns readable problems.
static func validate() -> Array[String]:
	_ensure_loaded()
	var e: Array[String] = []
	for id: String in _scenes:
		_validate_steps(id, _scenes[id], e)
	return e


static func _validate_steps(id: String, steps: Array, e: Array[String]) -> void:
	for step: Dictionary in steps:
		if step.has("text"):
			if not _speakers.has(step.get("speaker", "")):
				e.append("scene %s: unknown speaker '%s'" % [id, step.get("speaker", "")])
		elif step.has("choice"):
			var opts: Array = step["choice"]
			if opts.is_empty() or opts.size() > 3:
				e.append("scene %s: a choice needs 1 to 3 options" % id)
			for o: Dictionary in opts:
				_validate_steps(id, o.get("then", []), e)
		elif step.has("key_item") or step.has("item"):
			var item: String = step.get("key_item", step.get("item", ""))
			if not JsonUtil.load_dict("res://content/items.json").get("items", {}).has(item):
				e.append("scene %s: unknown item '%s'" % [id, item])
		elif not (step.has("set_flag") or step.has("join") or step.has("quest")):
			e.append("scene %s: step has no known type: %s" % [id, str(step)])
