extends Control
## Title screen: New Game, Continue, Settings.

const ITEMS := [
	{"label": "New Game", "enabled": true, "note": ""},
	{"label": "Continue", "enabled": false, "note": "Saving arrives in build step 6."},
	{"label": "Settings", "enabled": false, "note": "Settings arrive in a later step."},
]

var index := 0
var _labels: Array[Label] = []
var _note: Label
var _fireflies: Array[ColorRect] = []
var _time := 0.0


func _ready() -> void:
	InputManager.set_base_mode(InputManager.Mode.TITLE)
	var bg := ColorRect.new()
	bg.color = Color("#1a1838")
	bg.size = Vector2(240, 160)
	add_child(bg)
	for i in 14:
		var dot := ColorRect.new()
		dot.color = Assets.UI_GOLD
		dot.size = Vector2(1, 1)
		add_child(dot)
		_fireflies.append(dot)

	var title := Label.new()
	title.text = "TWO WORLDS"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Assets.UI_GOLD)
	title.add_theme_color_override("font_outline_color", Color("#140f1c"))
	title.add_theme_constant_override("outline_size", 3)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 22)
	title.size = Vector2(240, 20)
	add_child(title)
	var sub := Label.new()
	sub.text = "Prologue: The Great Escape"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 44)
	sub.size = Vector2(240, 12)
	add_child(sub)

	for i in ITEMS.size():
		var l := Label.new()
		l.position = Vector2(84, 76 + i * 13)
		l.size = Vector2(90, 12)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.gui_input.connect(_on_item_input.bind(i))
		add_child(l)
		_labels.append(l)
	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.position = Vector2(0, 120)
	_note.size = Vector2(240, 12)
	_note.add_theme_color_override("font_color", Color("#9fb0d8"))
	add_child(_note)
	var footer := Label.new()
	footer.text = "Placeholder art. Z/Enter: select  F2: touch pad"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.position = Vector2(0, 146)
	footer.size = Vector2(240, 12)
	footer.add_theme_color_override("font_color", Color("#6f7aa8"))
	add_child(footer)
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	for i in _fireflies.size():
		var f := _fireflies[i]
		f.position = Vector2(fposmod(i * 37.0 + _time * (4 + i % 3), 240.0), 60.0 + sin(_time * 0.8 + i) * 50.0 + (i % 4) * 8).round()
		f.modulate.a = 0.4 + 0.6 * absf(sin(_time * 1.5 + i * 1.7))
	var mode := InputManager.Mode.TITLE
	if InputManager.just_pressed("move_down", mode):
		index = (index + 1) % ITEMS.size()
		_refresh()
	elif InputManager.just_pressed("move_up", mode):
		index = (index - 1 + ITEMS.size()) % ITEMS.size()
		_refresh()
	elif InputManager.just_pressed("confirm", mode):
		_activate()


func _on_item_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		index = i
		_refresh()
		_activate()


func _refresh() -> void:
	for i in _labels.size():
		var item: Dictionary = ITEMS[i]
		_labels[i].text = ("> " if i == index else "  ") + item["label"]
		var c: Color = Assets.UI_GOLD if i == index else Assets.UI_TEXT
		if not item["enabled"]:
			c = c.darkened(0.45)
		_labels[i].add_theme_color_override("font_color", c)
	_note.text = ""


func _activate() -> void:
	var item: Dictionary = ITEMS[index]
	if not item["enabled"]:
		_note.text = item["note"]
		return
	GameState.new_game()
	get_tree().change_scene_to_file("res://scenes/exploration.tscn")
