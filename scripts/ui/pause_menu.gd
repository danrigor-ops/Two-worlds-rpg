class_name PauseMenu
extends CanvasLayer
## Pause menu with Journal, Items and Party tabs. Owns input (MENU mode).
## Left/right switch tabs, up/down pick an entry, cancel or menu closes.

const TABS := ["Journal", "Items", "Party", "System"]
const VISIBLE_ROWS := 7
const TIMING_STEPS := [1.0, 1.5, 2.0]
const TIMING_NAMES := {1.0: "Normal", 1.5: "Relaxed", 2.0: "Very relaxed"}

signal load_requested

var tab := 0
var row := 0
var panel: Panel
var tab_labels: Array[Label] = []
var list_label: Label
var detail_label: Label
var _rows: Array = []   # [{"text", "detail", "action": Callable -> String}]
var _feedback := ""


func _ready() -> void:
	layer = 15
	panel = Panel.new()
	panel.theme = Assets.ui_theme
	panel.position = Vector2(4, 4)
	panel.size = Vector2(232, 152)
	add_child(panel)
	for i in TABS.size():
		var l := Label.new()
		l.position = Vector2(8 + i * 54, 3)
		panel.add_child(l)
		tab_labels.append(l)
	list_label = Label.new()
	list_label.position = Vector2(8, 18)
	list_label.size = Vector2(216, 84)
	panel.add_child(list_label)
	detail_label = Label.new()
	detail_label.position = Vector2(8, 106)
	detail_label.size = Vector2(216, 42)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_color_override("font_color", Color("#c9d3f0"))
	panel.add_child(detail_label)
	visible = false


func open() -> void:
	tab = 0
	row = 0
	visible = true
	InputManager.push_mode(InputManager.Mode.MENU)
	_refresh()


func close() -> void:
	visible = false
	InputManager.pop_mode(InputManager.Mode.MENU)


func _process(_delta: float) -> void:
	if not visible:
		return
	var m := InputManager.Mode.MENU
	if InputManager.just_pressed("cancel", m) or InputManager.just_pressed("menu", m):
		close()
	elif InputManager.just_pressed("confirm", m) and not _rows.is_empty() and _rows[row].has("action"):
		_feedback = _rows[row]["action"].call()
		if visible:
			_refresh()
	elif InputManager.just_pressed("move_right", m):
		tab = (tab + 1) % TABS.size()
		row = 0
		_feedback = ""
		_refresh()
	elif InputManager.just_pressed("move_left", m):
		tab = (tab - 1 + TABS.size()) % TABS.size()
		row = 0
		_feedback = ""
		_refresh()
	elif InputManager.just_pressed("move_down", m) and not _rows.is_empty():
		row = (row + 1) % _rows.size()
		_refresh()
	elif InputManager.just_pressed("move_up", m) and not _rows.is_empty():
		row = (row - 1 + _rows.size()) % _rows.size()
		_refresh()


func _refresh() -> void:
	for i in tab_labels.size():
		tab_labels[i].text = ("[%s]" if i == tab else " %s ") % TABS[i]
		tab_labels[i].add_theme_color_override("font_color", Assets.UI_GOLD if i == tab else Assets.UI_TEXT)
	match TABS[tab]:
		"Journal":
			_rows = journal_rows()
		"Items":
			_rows = item_rows()
		"Party":
			_rows = party_rows()
		_:
			_rows = system_rows()
	row = clampi(row, 0, maxi(0, _rows.size() - 1))
	var first := clampi(row - VISIBLE_ROWS / 2, 0, maxi(0, _rows.size() - VISIBLE_ROWS))
	var lines: PackedStringArray = []
	for i in range(first, mini(_rows.size(), first + VISIBLE_ROWS)):
		lines.append(("> " if i == row else "  ") + str(_rows[i]["text"]))
	list_label.text = "\n".join(lines) if not lines.is_empty() else "  (nothing yet)"
	if _feedback != "":
		detail_label.text = _feedback
		_feedback = ""
	else:
		detail_label.text = _rows[row]["detail"] if not _rows.is_empty() else ""


static func journal_rows() -> Array:
	var rows: Array = []
	for q: Dictionary in Quests.visible_quests():
		var state := GameState.quest_state(q["id"])
		var mark := "Done" if state in ["completed", "rewarded"] else "Now "
		rows.append({"text": "%s  %s" % [mark, q["name"]], "detail": Quests.journal_text(q["id"])})
	return rows


## Money is integer cents; 1963 display is dollars and cents.
static func format_cents(cents: int) -> String:
	return "$%d.%02d" % [cents / 100, cents % 100]


static func item_rows() -> Array:
	var defs := GameState.item_defs()
	var w: Dictionary = GameState.data["wallet"]
	var rows: Array = [{"text": "Money %s   Dewdrops %d" % [format_cents(int(w["human_cents"])), int(w["dewdrops"])],
		"detail": "Human money in dollars and cents. Dewdrops are spirit money."}]
	for k: String in GameState.data["key_items"]:
		rows.append({"text": "* " + defs.get(k, {}).get("name", k), "detail": defs.get(k, {}).get("text", "")})
	for i: String in GameState.data["inventory"]:
		var row := {"text": "%s x%d" % [defs.get(i, {}).get("name", i), GameState.item_count(i)], "detail": defs.get(i, {}).get("text", "")}
		if defs.get(i, {}).has("heal_hp") or defs.get(i, {}).has("heal_mp"):
			row["detail"] += " Press A to use."
			row["action"] = func() -> String:
				var why := GameState.use_heal_item(i)
				return why if why != "" else "Used one. Someone feels better!"
		rows.append(row)
	return rows


static func party_rows() -> Array:
	var rows: Array = []
	var names: Dictionary = JsonUtil.load_dict(GameState.CHARACTERS_PATH).get("characters", {})
	# No formation changes while the party is split up for a mission.
	var many := GameState.party().size() > GameState.ACTIVE_SIZE and not GameState.in_mission()
	for id: String in GameState.party():
		var s: Dictionary = GameState.data["members"][id]
		var reserve := not (id in GameState.active_party())
		var row := {
			"text": "%s%s Lv%d  HP %d/%d  MP %d/%d" % [("(away) " if GameState.in_mission() else "(R) ") if reserve else "", names.get(id, {}).get("name", id), s["level"], s["hp"], s["max_hp"], s["mp"], s["max_mp"]],
			"detail": "ATK %d  DEF %d  MAG %d  RES %d  SPD %d" % [s["atk"], s["def"], s["mag"], s["res"], s["spd"]],
		}
		if many:
			# Formation: the first three fight. A moves this member to the front.
			row["detail"] += "\nA: move to the front (the first three fight; (R) waits in reserve)"
			row["action"] = func() -> String:
				GameState.move_to_front(id)
				return "%s moves to the front." % names.get(id, {}).get("name", id)
		rows.append(row)
	return rows


func system_rows() -> Array:
	var rows: Array = []
	for slot in ["1", "2", "3"]:
		rows.append({"text": "Save to slot %s  %s" % [slot, Saves.summary(slot)], "detail": "Save your progress here.",
			"action": func() -> String:
				var e := Saves.save(slot)
				return "Saved to slot %s." % slot if e.is_empty() else "Couldn't save: " + e[0]})
	for slot in ["auto", "1", "2", "3"]:
		var label: String = "Auto" if slot == "auto" else slot
		rows.append({"text": "Load %s  %s" % [label, Saves.summary(slot)], "detail": "Load this save. Unsaved progress is lost.",
			"action": func() -> String:
				var e := Saves.load_slot(slot)
				if not e.is_empty():
					return "Couldn't load: " + e[0]
				close()
				load_requested.emit()
				return ""})
	for slot in ["auto", "1", "2", "3"]:
		if Saves.has_save(slot):
			rows.append({"text": "Export %s" % ("Auto" if slot == "auto" else "slot " + slot), "detail": "Copy this save to a file you can back up.",
				"action": func() -> String:
					var r := Saves.export_slot(slot)
					return "Exported to " + r[1] if (r[0] as Array).is_empty() else "Couldn't export: " + r[0][0]})
	rows.append({"text": "Import into slot 3", "detail": "Reads %s. Slot 3 is only replaced if the file is a valid save." % ProjectSettings.globalize_path(Saves.import_path),
		"action": func() -> String:
			if not FileAccess.file_exists(Saves.import_path):
				return "No file at " + ProjectSettings.globalize_path(Saves.import_path)
			var e := Saves.import_into("3", FileAccess.get_file_as_string(Saves.import_path))
			return "Imported into slot 3." if e.is_empty() else "Not imported: " + e[0]})
	var scale := float(GameState.setting("timing_window_scale"))
	rows.append({"text": "Timing windows: %s" % TIMING_NAMES.get(scale, str(scale)), "detail": "Wider windows make timed hits and dodges easier.",
		"action": func() -> String:
			var i := TIMING_STEPS.find(scale)
			GameState.data["settings"]["timing_window_scale"] = TIMING_STEPS[(i + 1) % TIMING_STEPS.size()]
			return ""})
	var diag: bool = GameState.setting("diagonal_movement")
	rows.append({"text": "Diagonal moves: %s" % ("On" if diag else "Off"), "detail": "Off keeps movement to four directions.",
		"action": func() -> String:
			GameState.data["settings"]["diagonal_movement"] = not diag
			return ""})
	rows.append({"text": "Quit to title", "detail": "Unsaved progress is lost.",
		"action": func() -> String:
			close()
			get_tree().change_scene_to_file.call_deferred("res://scenes/title.tscn")
			return ""})
	return rows
