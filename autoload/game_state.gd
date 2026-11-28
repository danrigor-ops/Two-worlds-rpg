extends Node
## The one authoritative game state. Scenes read from it and change it only
## through these methods, so a later save system can serialize one dictionary.

signal flag_changed(flag: String, value: Variant)
signal party_changed
signal leader_changed(member_id: String)

const ACTIVE_SIZE := 3
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
	var d := {
		"version": SCHEMA_VERSION,
		"chapter": "prologue",
		"map_id": NEW_GAME_MAP,
		"spawn": NEW_GAME_SPAWN,
		"tile": {"x": -1, "y": -1},
		"facing": "down",
		"leader": "reno",
		"party": ["reno"],
		"mission": [],
		"members": members,
		"wallet": {"human_cents": 0, "dewdrops": 5},
		"inventory": {},
		"key_items": [],
		"quests": quests,
		"flags": {},
		"rewards_claimed": {},
		"playtime_sec": 0.0,
		"settings": {"diagonal_movement": true, "timing_window_scale": 1.0, "instant_text": false},
	}
	_normalize(d)   # content JSON gives floats; stats are whole numbers
	return d


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


## The first three in party order fight; the rest wait in reserve (and still earn XP).
## During a split-up mission (Chapter 8) only the mission team fights and walks.
func active_party() -> Array:
	var m: Array = data.get("mission", [])
	return (m if not m.is_empty() else data["party"]).slice(0, ACTIVE_SIZE)


## Who walks the map: Reno and/or Lumi, limited to the mission team if there is one.
func walking_party() -> Array:
	var m: Array = data.get("mission", [])
	return (m if not m.is_empty() else data["party"]).filter(walks)


func in_mission() -> bool:
	return not data.get("mission", []).is_empty()


## Splits the party: only these members fight and walk until clear_mission().
## The leader moves to the team's first walker.
func set_mission(ids: Array) -> void:
	data["mission"] = ids.filter(has_member)
	var walkers := walking_party()
	if not walkers.is_empty() and leader() not in walkers:
		data["leader"] = walkers[0]
		leader_changed.emit(walkers[0])
	party_changed.emit()


func clear_mission() -> void:
	data["mission"] = []
	party_changed.emit()


## Only Reno and Lumi walk the map; companions travel along (characters.json "walks").
func walks(id: String) -> bool:
	return bool(JsonUtil.load_dict(CHARACTERS_PATH).get("characters", {}).get(id, {}).get("walks", false))


## Moves a member to the front of the party order (into the active three).
func move_to_front(id: String) -> bool:
	if not has_member(id):
		return false
	data["party"].erase(id)
	data["party"].push_front(id)
	party_changed.emit()
	return true


func has_member(id: String) -> bool:
	return id in data["party"]


## Adds a recruited member. Returns false if unknown or already present.
func add_member(id: String) -> bool:
	if has_member(id) or not data["members"].has(id):
		return false
	data["party"].append(id)
	# A new companion joins at the party's level (the average XP of the others).
	var total := 0
	for other: String in data["party"]:
		if other != id:
			total += int(data["members"][other]["xp"])
	var m: Dictionary = data["members"][id]
	if data["party"].size() > 1:
		m["xp"] = maxi(int(m["xp"]), total / (data["party"].size() - 1))
		apply_levels(id)
		m["hp"] = m["max_hp"]
		m["mp"] = m["max_mp"]
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


func remove_key_item(item_id: String) -> bool:
	if item_id not in data["key_items"]:
		return false
	data["key_items"].erase(item_id)
	return true


func has_key_item(item_id: String) -> bool:
	return item_id in data["key_items"]


const ITEMS_PATH := "res://content/items.json"
const STACK_CAP := 99

static var _items: Dictionary = {}


static func item_defs() -> Dictionary:
	if _items.is_empty():
		_items = JsonUtil.load_dict(ITEMS_PATH).get("items", {})
	return _items


func item_count(item_id: String) -> int:
	return int(data["inventory"].get(item_id, 0))


## Adds (or with a negative n removes) consumables. Never goes below 0 or above the cap.
func add_item(item_id: String, n: int = 1) -> bool:
	if item_defs().get(item_id, {}).get("kind", "") == "key":
		return false   # key items live in key_items and can't be stacked, used up or sold
	var now := item_count(item_id)
	var next := now + n
	if next < 0 or next > STACK_CAP:
		return false
	if next == 0:
		data["inventory"].erase(item_id)
	else:
		data["inventory"][item_id] = next
	return true


## Buying is all-or-nothing: either money and items both change, or neither.
func buy(item_id: String, price_cents: int, n: int = 1) -> bool:
	var total := price_cents * n
	var cents := int(data["wallet"]["human_cents"])
	if n <= 0 or price_cents < 0 or total > cents or item_count(item_id) + n > STACK_CAP:
		return false
	if not add_item(item_id, n):
		return false
	data["wallet"]["human_cents"] = cents - total
	return true


## Ordinary shop goods sell for half price, rounded down. Key items can't be sold.
func sell(item_id: String, price_cents: int, n: int = 1) -> bool:
	if n <= 0 or item_count(item_id) < n or item_defs().get(item_id, {}).get("kind", "") == "key":
		return false
	add_item(item_id, -n)
	data["wallet"]["human_cents"] = int(data["wallet"]["human_cents"]) + (price_cents / 2) * n
	return true


## Uses a healing item outside battle. HP items go to the member with the
## lowest HP share, MP items to the lowest MP share. Returns "" on success, or
## the reason it couldn't be used.
func use_heal_item(item_id: String) -> String:
	var def: Dictionary = item_defs().get(item_id, {})
	var hp := int(def.get("heal_hp", 0))
	var mp := int(def.get("heal_mp", 0))
	if hp <= 0 and mp <= 0:
		return "That can't be used here."
	if item_count(item_id) <= 0:
		return "None left."
	var key := "hp" if hp > 0 else "mp"
	var target := ""
	var best := 2.0
	for id: String in party():
		var m: Dictionary = data["members"][id]
		var share := float(m[key]) / float(m["max_" + key])
		if share < best:
			best = share
			target = id
	if best >= 1.0 and (hp <= 0 or mp <= 0 or _all_full("mp")):
		return "Everyone is already full of energy."
	add_item(item_id, -1)
	var m: Dictionary = data["members"][target]
	m["hp"] = mini(int(m["max_hp"]), int(m["hp"]) + hp)
	m["mp"] = mini(int(m["max_mp"]), int(m["mp"]) + mp)
	return ""


func _all_full(key: String) -> bool:
	for id: String in party():
		var m: Dictionary = data["members"][id]
		if int(m[key]) < int(m["max_" + key]):
			return false
	return true


## Spirit stalls take Dewdrops.
func buy_with_dewdrops(item_id: String, price_dp: int, n: int = 1) -> bool:
	if price_dp * n > int(data["wallet"]["dewdrops"]) or item_count(item_id) + n > 99:
		return false
	if not add_item(item_id, n):
		return false
	data["wallet"]["dewdrops"] = int(data["wallet"]["dewdrops"]) - price_dp * n
	return true


# --- Levels ------------------------------------------------------------------

const GROWTH_PATH := "res://content/growth.json"
const MAX_LEVEL := 30


## XP needed to reach level L (04 rule): 10 * (L - 1)^2.
static func xp_for_level(level: int) -> int:
	return 10 * (level - 1) * (level - 1)


## Adds XP and applies any level-ups. Returns one line per level gained.
func gain_xp(member_id: String, xp: int) -> Array[String]:
	var m: Dictionary = data["members"][member_id]
	m["xp"] = int(m["xp"]) + xp
	return apply_levels(member_id)


func apply_levels(member_id: String) -> Array[String]:
	var lines: Array[String] = []
	var m: Dictionary = data["members"][member_id]
	var g: Dictionary = JsonUtil.load_dict(GROWTH_PATH).get("growth", {}).get(member_id, {})
	var name: String = JsonUtil.load_dict(CHARACTERS_PATH).get("characters", {}).get(member_id, {}).get("name", member_id)
	while int(m["level"]) < MAX_LEVEL and int(m["xp"]) >= xp_for_level(int(m["level"]) + 1):
		m["level"] = int(m["level"]) + 1
		for stat: String in g:
			m[stat] = int(m[stat]) + int(g[stat])
		m["hp"] = mini(int(m["max_hp"]), int(m["hp"]) + int(g.get("max_hp", 0)))
		m["mp"] = mini(int(m["max_mp"]), int(m["mp"]) + int(g.get("max_mp", 0)))
		lines.append("%s reached level %d!" % [name, int(m["level"])])
	return lines


func add_dewdrops(n: int) -> bool:
	var next := int(data["wallet"]["dewdrops"]) + n
	if next < 0:
		return false
	data["wallet"]["dewdrops"] = next
	return true


func is_reward_claimed(reward_id: String) -> bool:
	return data["rewards_claimed"].has(reward_id)


## Grants a reward exactly once. Returns false (and changes nothing) if it was
## already claimed. reward: {key_items: [], items: {id: n}, dewdrops: n, flags: []}
func claim_reward(reward_id: String, reward: Dictionary) -> bool:
	if is_reward_claimed(reward_id):
		return false
	data["rewards_claimed"][reward_id] = true
	for k: String in reward.get("key_items", []):
		add_key_item(k)
	var items: Dictionary = reward.get("items", {})
	for i: String in items:
		add_item(i, mini(int(items[i]), STACK_CAP - item_count(i)))
	if reward.has("dewdrops"):
		add_dewdrops(int(reward["dewdrops"]))
	for f: String in reward.get("flags", []):
		set_flag(f)
	return true


## True when every flag in if_flags is set, none in if_not_flags is, and
## (if given) if_leader is the current leader.
func conditions_met(def: Dictionary) -> bool:
	if def.has("if_leader") and def["if_leader"] != leader():
		return false
	for f: String in def.get("if_flags", []):
		if not get_flag(f):
			return false
	for f: String in def.get("if_not_flags", []):
		if get_flag(f):
			return false
	for k: String in def.get("if_key_items", []):
		if not has_key_item(k):
			return false
	if def.has("if_any_key_items") and not (def["if_any_key_items"] as Array).any(has_key_item):
		return false
	return true


## Charms are worn by one member (item "equip_to") and add to their stats.
func equip_bonus(member_id: String) -> Dictionary:
	var out := {}
	var defs := item_defs()
	for k: String in data["key_items"]:
		var d: Dictionary = defs.get(k, {})
		if d.get("kind", "") == "charm" and d.get("equip_to", "") == member_id:
			for stat: String in d.get("bonus", {}):
				out[stat] = int(out.get(stat, 0)) + int(d["bonus"][stat])
	return out


func quest_state(quest_id: String) -> String:
	return data["quests"].get(quest_id, "locked")


signal quest_changed(quest_id: String, state: String)


## Quests only move forward: locked -> active -> completed -> rewarded.
func set_quest_state(quest_id: String, state: String) -> bool:
	if state not in QUEST_STATES or not data["quests"].has(quest_id):
		return false
	if QUEST_STATES.find(state) <= QUEST_STATES.find(quest_state(quest_id)):
		return false
	data["quests"][quest_id] = state
	quest_changed.emit(quest_id, state)
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
		for id: String in data["members"]:
			apply_levels(id)   # older saves stored XP before levels existed
		party_changed.emit()
	return errors


## Upgrades older save versions. Version 1 is the first, so nothing to do yet.
func migrate(d: Dictionary) -> Dictionary:
	if not d.has("mission"):
		d["mission"] = []
	# Companions added in later chapters: older saves get their starting stats.
	if d.get("members") is Dictionary:
		var fresh: Dictionary = default_state()["members"]
		for id: String in fresh:
			if not d["members"].has(id):
				d["members"][id] = fresh[id]
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
	if d.has("mission"):
		if typeof(d["mission"]) != TYPE_ARRAY:
			e.append("'mission' must be a list")
		else:
			for id: Variant in d["mission"]:
				if id not in d["party"]:
					e.append("mission member '%s' is not in the party" % str(id))
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
