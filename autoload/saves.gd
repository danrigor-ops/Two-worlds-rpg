extends Node
## Save slots: three manual slots plus one autosave, as JSON files.
##
## Writes go to a temporary file first and are renamed over the old file
## only after they are complete, so a crash can't leave a half-written slot.
## Every file carries a checksum; loading checks it and validates the state
## before replacing anything. A bad file is rejected and nothing changes.

const FORMAT := "two-worlds-save"
const SLOTS := ["auto", "1", "2", "3"]

var save_dir := "user://saves/"
var export_dir := "user://exports/"
var import_path := "user://import.json"


func slot_path(slot: String) -> String:
	return save_dir + ("autosave" if slot == "auto" else "slot_" + slot) + ".json"


func has_save(slot: String) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func any_save() -> bool:
	return SLOTS.any(has_save)


## Builds the file contents for the current state.
func pack() -> String:
	var state := GameState.to_dict()
	# Checksum the state as it will read back (JSON numbers become floats).
	var body := JSON.stringify(JSON.parse_string(JSON.stringify(state)), "", true)
	var map_name: String = MapData.load_map(state["map_id"]).name if MapData.exists(state["map_id"]) else state["map_id"]
	return JSON.stringify({
		"format": FORMAT,
		"version": GameState.SCHEMA_VERSION,
		"saved_at": int(Time.get_unix_time_from_system()),
		"summary": {"map": map_name, "playtime_sec": int(state["playtime_sec"]), "leader": state["leader"]},
		"checksum": body.sha256_text(),
		"state": state,
	}, "  ", true)


## Checks file contents. Returns [errors, state].
func unpack(text: String) -> Array:
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return [["not a JSON save file"], {}]
	var d: Dictionary = parsed
	if d.get("format") != FORMAT:
		return [["not a Two Worlds save"], {}]
	if typeof(d.get("state")) != TYPE_DICTIONARY:
		return [["save has no game state"], {}]
	var state: Dictionary = d["state"]
	var errors: Array[String] = []
	if JSON.stringify(state, "", true).sha256_text() != d.get("checksum", ""):
		errors.append("checksum does not match (the file was changed or damaged)")
	errors.append_array(GameState.validate(GameState.migrate(state.duplicate(true))))
	return [errors, state]


func save(slot: String) -> Array[String]:
	if slot not in SLOTS:
		return ["unknown slot %s" % slot]
	return _write(slot_path(slot), pack())


func autosave() -> Array[String]:
	return save("auto")


func load_slot(slot: String) -> Array[String]:
	if not has_save(slot):
		return ["slot %s is empty" % slot]
	return load_text(FileAccess.get_file_as_string(slot_path(slot)))


## Validates first; only a good save replaces the current state.
func load_text(text: String) -> Array[String]:
	var r := unpack(text)
	var errors: Array[String] = []
	errors.assign(r[0])
	if not errors.is_empty():
		return errors
	return GameState.load_from_dict(r[1])


func summary(slot: String) -> String:
	if not has_save(slot):
		return "(empty)"
	var r := unpack(FileAccess.get_file_as_string(slot_path(slot)))
	if not (r[0] as Array).is_empty():
		return "(damaged)"
	var d: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(slot_path(slot)))
	var s: Dictionary = d.get("summary", {})
	var t := int(s.get("playtime_sec", 0))
	return "%s  %d:%02d" % [s.get("map", "?"), t / 3600, (t / 60) % 60]


## Copies a slot to the exports folder. Returns [errors, absolute path].
func export_slot(slot: String) -> Array:
	if not has_save(slot):
		return [["slot %s is empty" % slot], ""]
	var path := export_dir + "two-worlds-%s.json" % ("autosave" if slot == "auto" else "slot-" + slot)
	var errors := _write(path, FileAccess.get_file_as_string(slot_path(slot)))
	return [errors, ProjectSettings.globalize_path(path)]


## Imports a save file into a slot. The slot is only replaced if the file
## is a valid save.
func import_into(slot: String, text: String) -> Array[String]:
	var r := unpack(text)
	var errors: Array[String] = []
	errors.assign(r[0])
	if not errors.is_empty():
		return errors
	return _write(slot_path(slot), text)


func _write(path: String, text: String) -> Array[String]:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return ["can't write %s (%s)" % [tmp, error_string(FileAccess.get_open_error())]]
	f.store_string(text)
	f.close()
	if FileAccess.get_file_as_string(tmp) != text:
		DirAccess.remove_absolute(tmp)
		return ["write check failed for %s" % path]
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var err := DirAccess.rename_absolute(tmp, path)
	if err != OK:
		return ["can't replace %s (%s)" % [path, error_string(err)]]
	return []


func delete_all() -> void:
	for slot in SLOTS:
		if has_save(slot):
			DirAccess.remove_absolute(slot_path(slot))
