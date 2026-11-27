extends Node
## Quest lifecycle: locked -> active -> completed -> rewarded.
## Quests move forward on their own when story flags change, and each reward
## is granted exactly once (GameState.claim_reward), however often this runs.

signal notice(text: String)

const QUESTS_PATH := "res://content/quests.json"

var defs: Array = []
var _refreshing := false


func _ready() -> void:
	defs = JsonUtil.load_dict(QUESTS_PATH).get("quests", [])
	GameState.flag_changed.connect(func(_f: String, _v: Variant) -> void: refresh())


func def(quest_id: String) -> Dictionary:
	for q: Dictionary in defs:
		if q["id"] == quest_id:
			return q
	return {}


func refresh() -> void:
	if _refreshing:
		return
	_refreshing = true
	var changed := true
	while changed:
		changed = false
		for q: Dictionary in defs:
			changed = _step(q) or changed
	_refreshing = false


func _step(q: Dictionary) -> bool:
	var id: String = q["id"]
	match GameState.quest_state(id):
		"locked":
			var start: Array = q.get("start_flags", [])
			if not start.is_empty() and start.all(GameState.get_flag):
				GameState.set_quest_state(id, "active")
				notice.emit("New quest: %s" % q["name"])
				return true
		"active":
			var done: Array = q.get("complete_flags", [])
			if not done.is_empty() and done.all(GameState.get_flag):
				GameState.set_quest_state(id, "completed")
				notice.emit("Quest complete: %s" % q["name"])
				return true
		"completed":
			if q.has("reward"):
				if GameState.claim_reward(id, q["reward"]):
					for line in reward_lines(q["reward"]):
						notice.emit(line)
				GameState.set_quest_state(id, "rewarded")
				return true
	return false


func reward_lines(reward: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var items := GameState.item_defs()
	for k: String in reward.get("key_items", []):
		lines.append("Received %s!" % items.get(k, {}).get("name", k))
	var stack: Dictionary = reward.get("items", {})
	for i: String in stack:
		lines.append("Received %s x%d!" % [items.get(i, {}).get("name", i), int(stack[i])])
	if reward.has("dewdrops"):
		lines.append("Received %d Dewdrops!" % int(reward["dewdrops"]))
	return lines


func journal_text(quest_id: String) -> String:
	var q := def(quest_id)
	var state := GameState.quest_state(quest_id)
	var j: Dictionary = q.get("journal", {})
	if state in ["completed", "rewarded"]:
		return j.get("completed", "Done.")
	return j.get("active", "")


## Quests the player has seen (not locked), in story order.
func visible_quests() -> Array:
	return defs.filter(func(q: Dictionary) -> bool: return GameState.quest_state(q["id"]) != "locked")
