class_name PauseMenu
extends CanvasLayer
## Pause menu with Journal, Items and Party tabs. Owns input (MENU mode).
## Left/right switch tabs, up/down pick an entry, cancel or menu closes.

const TABS := ["Journal", "Items", "Party"]

var tab := 0
var row := 0
var panel: Panel
var tab_labels: Array[Label] = []
var list_label: Label
var detail_label: Label
var _rows: Array = []   # [{"text", "detail"}]


func _ready() -> void:
	layer = 15
	panel = Panel.new()
	panel.theme = Assets.ui_theme
	panel.position = Vector2(4, 4)
	panel.size = Vector2(232, 152)
	add_child(panel)
	for i in TABS.size():
		var l := Label.new()
		l.position = Vector2(8 + i * 56, 3)
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
	elif InputManager.just_pressed("move_right", m):
		tab = (tab + 1) % TABS.size()
		row = 0
		_refresh()
	elif InputManager.just_pressed("move_left", m):
		tab = (tab - 1 + TABS.size()) % TABS.size()
		row = 0
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
		_:
			_rows = party_rows()
	row = clampi(row, 0, maxi(0, _rows.size() - 1))
	var lines: PackedStringArray = []
	for i in _rows.size():
		lines.append(("> " if i == row else "  ") + str(_rows[i]["text"]))
	list_label.text = "\n".join(lines) if not lines.is_empty() else "  (nothing yet)"
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
		rows.append({"text": "%s x%d" % [defs.get(i, {}).get("name", i), GameState.item_count(i)], "detail": defs.get(i, {}).get("text", "")})
	return rows


static func party_rows() -> Array:
	var rows: Array = []
	var names: Dictionary = JsonUtil.load_dict(GameState.CHARACTERS_PATH).get("characters", {})
	for id: String in GameState.party():
		var s: Dictionary = GameState.data["members"][id]
		rows.append({
			"text": "%s Lv%d  HP %d/%d  MP %d/%d" % [names.get(id, {}).get("name", id), s["level"], s["hp"], s["max_hp"], s["mp"], s["max_mp"]],
			"detail": "ATK %d  DEF %d  MAG %d  RES %d  SPD %d" % [s["atk"], s["def"], s["mag"], s["res"], s["spd"]],
		})
	return rows
