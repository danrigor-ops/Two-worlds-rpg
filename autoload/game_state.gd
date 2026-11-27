extends Node
## The one authoritative game state. Scenes read from it and change it only
## through these methods, so a later save system can serialize one dictionary.

signal flag_changed(flag: String, value: Variant)
signal party_changed
signal leader_changed(member_id: String)

const SCHEMA_VERSION := 1
const CHARACTERS_PATH := "res://content/characters.json"
const QUESTS_PATH := "res://content/quests.json"
const QUEST_STATES := ["locked", "active", "completed", "rewarded"]
const FACINGS := ["down", "left", "right", "up"]
const NEW_GAME_MAP := "KA-02"
const NEW_GAME_SPAWN := "start"

var data: Dictionary = {}


func _ready() -> void:
	new_game()


func new_game() -> void:
	data = default_state()


func default_state() -> Dictionary:
	var chars: Dictionary = JsonUtil.load_dict(CHARACTERS_PATH).get("characters", {})
	var members := {}
	for id: String in chars:
		var s: Dictionary = chars[id]["stats"].duplicate()
		s["hp"] = s["max_hp"]
		s["mp"] = s["max_mp"]
		s["xp"] = 0
		members[id] = s
	var quests := {}
	for q: Dictionary in JsonUtil.load_dict(QUESTS_PATH).get("quests", []):
		quests[q["id"]] = q.get("start", "locked")
	return {
		"version": SCHEMA_VERSION,
		"chapter": "prologue",
		"map_id": NEW_GAME_MAP,
		"spawn": NEW_GAME_SPAWN,
		"tile": {"x": -1, "y": -1},
		"facing": "down",
		"leader": "reno",
		"party": ["reno"],
		"members": members,
		"wallet": {"human_cents": 0, "dewdrops": 5},
		"inventory": {},
		"key_items": [],
		"quests": quests,
		"flags": {},
		"rewards_claimed": {},
		"playtime_sec": 0.0,
		"settings": {"diagonal_movement": true, "timing_window_scale": 1.0},
	}


# --- Flags -------------------------------------------------------------------

func get_flag(flag: String) -> bool:
	return bool(data["flags"].get(flag, false))


func set_flag(flag: String, value: bool = true) -> void:
	if get_flag(flag) == value:
		return
	data["flags"][flag] = value
	flag_changed.emit(flag, value)


# --- Party -------------------------------------------------------------------

func party() -> Array:
	return data["party"]


func leader() -> String:
	return data["leader"]


func has_member(id: String) -> bool:
	return id in data["party"]


## Adds a recruited member. Returns false if unknown or already present.
func add_member(id: String) -> bool:
	if has_member(id) or not data["members"].has(id):
		return false
	data["party"].append(id)
	party_changed.emit()
	return true


func set_leader(id: String) -> bool:
	if not has_member(id):
		return false
	data["leader"] = id
	leader_changed.emit(id)
	return true


# --- Position ----------------------------------------------------------------

func set_position(map_id: String, cell: Vector2i, facing: String) -> void:
	data["map_id"] = map_id
	data["spawn"] = ""
	data["tile"] = {"x": cell.x, "y": cell.y}
	if facing in FACINGS:
		data["facing"] = facing


func set_spawn(map_id: String, spawn: String) -> void:
	data["map_id"] = map_id
	data["spawn"] = spawn
	data["tile"] = {"x": -1, "y": -1}


func saved_cell() -> Vector2i:
	return Vector2i(int(data["tile"]["x"]), int(data["tile"]["y"]))


# --- Items and quests --------------------------------------------------------

func add_key_item(item_id: String) -> bool:
	if item_id in data["key_items"]:
		return false
	data["key_items"].append(item_id)
	return true


func has_key_item(item_id: String) -> bool:
	return item_id in data["key_items"]


func quest_state(quest_id: String) -> String:
	return data["quests"].get(quest_id, "locked")


func set_quest_state(quest_id: String, state: String) -> bool:
	if state not in QUEST_STATES or not data["quests"].has(quest_id):
		return false
	data["quests"][quest_id] = state
	return true


func add_playtime(delta: float) -> void:
	data["playtime_sec"] = float(data["playtime_sec"]) + delta


func setting(key: String) -> Variant:
	return data["settings"].get(key)


# --- Serialization -----------------------------------------------------------

func to_dict() -> Dictionary:
	return data.duplicate(true)


## Replaces the state only if the incoming dictionary is valid.
## Returns the list of problems; empty means it was loaded.
func load_from_dict(incoming: Dictionary) -> Array[String]:
	var copy := migrate(incoming.duplicate(true))
	var errors := validate(copy)
	if errors.is_empty():
		_normalize(copy)
		data = copy
		party_changed.emit()
	return errors


## Upgrades older save versions. Version 1 is the first, so nothing to do yet.
func migrate(d: Dictionary) -> Dictionary:
	return d


static func validate(d: Dictionary) -> Array[String]:
	var e: Array[String] = []
	if not JsonUtil.is_whole(d.get("version")):
		e.append("version missing")
		return e
	if int(d["version"]) > SCHEMA_VERSION:
		e.append("save is from a newer version (%d)" % int(d["version"]))
		return e
	if int(d["version"]) != SCHEMA_VERSION:
		e.append("unsupported version %d" % int(d["version"]))
		return e
	var need := {
		"chapter": TYPE_STRING, "map_id": TYPE_STRING, "spawn": TYPE_STRING,
		"tile": TYPE_DICTIONARY, "facing": TYPE_STRING, "leader": TYPE_STRING,
		"party": TYPE_ARRAY, "members": TYPE_DICTIONARY, "wallet": TYPE_DICTIONARY,
		"inventory": TYPE_DICTIONARY, "key_items": TYPE_ARRAY, "quests": TYPE_DICTIONARY,
		"flags": TYPE_DICTIONARY, "rewards_claimed": TYPE_DICTIONARY, "settings": TYPE_DICTIONARY,
	}
	for key: String in need:
		if typeof(d.get(key)) != need[key]:
			e.append("'%s' missing or wrong type" % key)
	if not e.is_empty():
		return e
	if d["facing"] not in FACINGS:
		e.append("bad facing '%s'" % d["facing"])
	if not (JsonUtil.is_whole(d["tile"].get("x")) and JsonUtil.is_whole(d["tile"].get("y"))):
		e.append("tile position must be whole numbers")
	if d["party"].is_empty():
		e.append("party is empty")
	for id: Variant in d["party"]:
		if not d["members"].has(id):
			e.append("party member '%s' has no stats" % str(id))
	if d["leader"] not in d["party"]:
		e.append("leader '%s' is not in the party" % d["leader"])
	for key: String in ["human_cents", "dewdrops"]:
		var v: Variant = d["wallet"].get(key)
		if not JsonUtil.is_whole(v) or int(v) < 0:
			e.append("wallet.%s must be a whole number >= 0" % key)
	for item: String in d["inventory"]:
		var n: Variant = d["inventory"][item]
		if not JsonUtil.is_whole(n) or int(n) < 0 or int(n) > 99:
			e.append("inventory '%s' count out of range" % item)
	for q: String in d["quests"]:
		if d["quests"][q] not in QUEST_STATES:
			e.append("quest %s has bad state '%s'" % [q, str(d["quests"][q])])
	if d["map_id"].is_empty():
		e.append("map_id is empty")
	return e


## JSON turns ints into floats; put them back.
static func _normalize(d: Dictionary) -> void:
	d["version"] = int(d["version"])
	d["tile"] = {"x": int(d["tile"]["x"]), "y": int(d["tile"]["y"])}
	for key: String in d["wallet"]:
		d["wallet"][key] = int(d["wallet"][key])
	for item: String in d["inventory"]:
		d["inventory"][item] = int(d["inventory"][item])
	for id: String in d["members"]:
		var m: Dictionary = d["members"][id]
		for stat: String in m:
			if JsonUtil.is_whole(m[stat]):
				m[stat] = int(m[stat])
