class_name CoinJarView
extends CanvasLayer
## The Coin Jar puzzle screen. Up/down picks a coin, A drops it on the pile.
## B leaves (the coins stay where they are until you come back to the jar).

signal closed(solved: bool)

var jar := CoinJar.new()
var row := 0
var panel: Panel
var list_label: Label
var pile_label: Label
var msg_label: Label
var _rows: Array = []


func _ready() -> void:
	layer = 15
	panel = Panel.new()
	panel.theme = Assets.ui_theme
	panel.position = Vector2(4, 4)
	panel.size = Vector2(232, 152)
	add_child(panel)
	var title := Label.new()
	title.text = "Encik Lim's coins: make piles of 50 cents"
	title.position = Vector2(8, 3)
	title.add_theme_color_override("font_color", Assets.UI_GOLD)
	panel.add_child(title)
	list_label = Label.new()
	list_label.position = Vector2(8, 18)
	panel.add_child(list_label)
	pile_label = Label.new()
	pile_label.position = Vector2(124, 18)
	pile_label.size = Vector2(100, 70)
	pile_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(pile_label)
	msg_label = Label.new()
	msg_label.position = Vector2(8, 100)
	msg_label.size = Vector2(216, 48)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_color_override("font_color", Color("#c9d3f0"))
	panel.add_child(msg_label)
	visible = false


func open() -> void:
	visible = true
	row = 0
	InputManager.push_mode(InputManager.Mode.MENU)
	msg_label.text = "Reno: How many is fifty?\nLumi: It's written on them."
	_refresh()


func close() -> void:
	visible = false
	InputManager.pop_mode(InputManager.Mode.MENU)
	closed.emit(jar.is_solved())


func _process(_delta: float) -> void:
	if not visible:
		return
	var m := InputManager.Mode.MENU
	if InputManager.just_pressed("cancel", m):
		close()
	elif InputManager.just_pressed("move_down", m):
		row = (row + 1) % _rows.size()
		_refresh()
	elif InputManager.just_pressed("move_up", m):
		row = (row - 1 + _rows.size()) % _rows.size()
		_refresh()
	elif InputManager.just_pressed("confirm", m):
		choose(_rows[row])


## A row value: a coin (int) or "repour". Public so tests can drive it.
func choose(value: Variant) -> void:
	if value is String:
		jar.repour()
		msg_label.text = "You tip the coins back into the jar and start again."
		_refresh()
		return
	var r := jar.add(int(value))
	match r:
		"none":
			msg_label.text = "There are no %d cent coins left." % value
		"over":
			msg_label.text = "That's more than fifty! The pile slides apart."
			if jar.wrong >= 2:
				msg_label.text += "\nLumi: Start with the big coins, then fill the gap with small ones."
		"pile":
			msg_label.text = "Fifty cents exactly. A neat little stack! (%d of %d)" % [jar.piles_done, jar.piles_needed()]
			if not jar.still_possible():
				msg_label.text = "Lumi: Hmm. What's left won't make fifties. Tip the jar out again?"
		"solved":
			msg_label.text = "Lumi: That's all of them!"
			_refresh()
			close()
			return
		_:
			if not jar.still_possible():
				msg_label.text = "Lumi: That one won't come out right. Try another coin."
				jar.undo_last()
			else:
				msg_label.text = ""
	_refresh()


func _refresh() -> void:
	_rows = []
	var lines: PackedStringArray = []
	for v: int in CoinJar.DENOMS:
		_rows.append(v)
	_rows.append("repour")
	for i in _rows.size():
		var v: Variant = _rows[i]
		var text: String = "Tip the jar out again" if v is String else "%2d cents  x%d" % [v, int(jar.remaining.get(v, 0))]
		lines.append(("> " if i == row else "  ") + text)
	list_label.text = "\n".join(lines)
	var pile_text := " + ".join(jar.pile.map(func(c: int) -> String: return str(c)))
	pile_label.text = "Pile: %d cents\n%s\n\nStacks done: %d of %d" % [jar.pile_total(), pile_text, jar.piles_done, jar.piles_needed()]
