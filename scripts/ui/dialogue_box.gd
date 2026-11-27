class_name DialogueBox
extends CanvasLayer
## Plays dialogue scenes: lines with name and portrait, typewriter text,
## up to three choices, and story steps (flags, items, party joins).
## Owns input (DIALOGUE mode) while open.

signal finished
signal event(name: String)   # story events the field handles (e.g. "prologue_end")

const CHARS_PER_SEC := 45.0
const HISTORY_MAX := 50

var history: Array[String] = []   # shown lines, newest last (for a future log screen)
var panel: Panel
var name_label: Label
var text_label: Label
var arrow: Label
var portrait_frame: Panel
var portrait: TextureRect
var choice_panel: Panel
var choice_labels: Array[Label] = []

var _queue: Array = []
var _on_done := Callable()
var _choices: Array = []
var _choice_index := 0
var _typing := 0.0
var _blink := 0.0


func _ready() -> void:
	layer = 10
	panel = _panel(Vector2(4, 110), Vector2(232, 46))
	add_child(panel)
	portrait_frame = _panel(Vector2(4, 4), Vector2(30, 30))
	panel.add_child(portrait_frame)
	portrait = TextureRect.new()
	portrait.position = Vector2(3, 3)
	portrait.size = Vector2(24, 24)
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	portrait_frame.add_child(portrait)
	name_label = Label.new()
	name_label.add_theme_color_override("font_color", Assets.UI_GOLD)
	panel.add_child(name_label)
	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.clip_text = true
	panel.add_child(text_label)
	arrow = Label.new()
	arrow.text = "v"
	arrow.position = Vector2(223, 33)
	arrow.add_theme_color_override("font_color", Assets.UI_GOLD)
	panel.add_child(arrow)
	choice_panel = _panel(Vector2(108, 60), Vector2(124, 46))
	add_child(choice_panel)
	visible = false
	choice_panel.visible = false


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.theme = Assets.ui_theme
	p.position = pos
	p.size = size
	return p


func is_open() -> bool:
	return visible


## Plays a scene by id from content/dialogue.
func play_scene(scene_id: String, on_done := Callable()) -> void:
	play(Dialogue.scene(scene_id), on_done)


## Plays plain narrator lines (signs, notices).
func show_lines(lines: Array, on_done := Callable()) -> void:
	var steps: Array = []
	for l in lines:
		steps.append({"speaker": "narrator", "text": str(l)})
	play(steps, on_done)


func play(steps: Array, on_done := Callable()) -> void:
	if visible:
		# Already open: queue after the current conversation.
		_queue.append_array(steps)
		return
	_queue = steps.duplicate()
	_on_done = on_done
	visible = true
	InputManager.push_mode(InputManager.Mode.DIALOGUE)
	_advance()


func _advance() -> void:
	while not _queue.is_empty():
		var step: Dictionary = _queue.pop_front()
		if not GameState.conditions_met(step):
			continue
		if step.has("text"):
			_show_line(step)
			return
		if step.has("choice"):
			_show_choice(step["choice"])
			return
		_apply(step)
	_close()


func _apply(step: Dictionary) -> void:
	if step.has("set_flag"):
		GameState.set_flag(step["set_flag"])
	if step.has("key_item"):
		GameState.add_key_item(step["key_item"])
	if step.has("take_key_item"):
		GameState.remove_key_item(step["take_key_item"])
	if step.has("item"):
		GameState.add_item(step["item"], int(step.get("count", 1)))
	if step.has("join"):
		GameState.add_member(step["join"])
	if step.has("event"):
		event.emit(step["event"])
	if step.has("quest"):
		GameState.set_quest_state(step["quest"], step.get("state", "active"))


func _show_line(step: Dictionary) -> void:
	var sp := Dialogue.speaker(step.get("speaker", "narrator"))
	var tex := _portrait_for(sp)
	portrait_frame.visible = tex != null
	portrait.texture = tex
	var left := 38.0 if tex else 6.0
	name_label.text = sp.get("name", "")
	name_label.position = Vector2(left, 1)
	var has_name: bool = name_label.text != ""
	text_label.position = Vector2(left, 12.0 if has_name else 4.0)
	text_label.size = Vector2(226.0 - left, 32.0 if has_name else 40.0)
	text_label.text = step["text"]
	text_label.visible_ratio = 0.0
	_typing = 0.0
	if GameState.setting("instant_text"):
		text_label.visible_ratio = 1.0
	history.append(("%s: " % name_label.text if has_name else "") + step["text"])
	if history.size() > HISTORY_MAX:
		history.pop_front()


func _portrait_for(sp: Dictionary) -> Texture2D:
	var char_id: String = sp.get("character", "")
	if char_id == "" or not Assets.manifest.get("characters", {}).has(char_id):
		return null
	# Placeholder portrait: the head of the overworld sprite's front frame.
	var at := AtlasTexture.new()
	at.atlas = Assets.texture(Assets.manifest["characters"][char_id])
	at.region = Rect2(4, 0, 24, 24)
	return at


func _show_choice(options: Array) -> void:
	_choices = options
	_choice_index = 0
	for l in choice_labels:
		l.queue_free()
	choice_labels.clear()
	choice_panel.size = Vector2(124, 8 + 12 * options.size())
	choice_panel.position = Vector2(108, 108 - choice_panel.size.y)
	for i in options.size():
		var l := Label.new()
		l.position = Vector2(4, 3 + i * 12)
		choice_panel.add_child(l)
		choice_labels.append(l)
	choice_panel.visible = true
	_refresh_choice()


func _refresh_choice() -> void:
	for i in choice_labels.size():
		choice_labels[i].text = ("> " if i == _choice_index else "  ") + str(_choices[i]["text"])
		choice_labels[i].add_theme_color_override("font_color", Assets.UI_GOLD if i == _choice_index else Assets.UI_TEXT)


func _process(delta: float) -> void:
	if not visible:
		return
	var mode := InputManager.Mode.DIALOGUE
	if choice_panel.visible:
		if InputManager.just_pressed("move_down", mode):
			_choice_index = (_choice_index + 1) % _choices.size()
			_refresh_choice()
		elif InputManager.just_pressed("move_up", mode):
			_choice_index = (_choice_index - 1 + _choices.size()) % _choices.size()
			_refresh_choice()
		elif InputManager.just_pressed("confirm", mode):
			choose(_choice_index)
		return
	if text_label.visible_ratio < 1.0:
		_typing += delta * CHARS_PER_SEC
		text_label.visible_characters = int(_typing)
		if text_label.visible_characters >= text_label.get_total_character_count():
			text_label.visible_ratio = 1.0
	_blink += delta
	arrow.visible = text_label.visible_ratio >= 1.0 and int(_blink * 3.0) % 2 == 0
	if InputManager.just_pressed("confirm", mode) or InputManager.just_pressed("cancel", mode):
		if text_label.visible_ratio < 1.0:
			text_label.visible_ratio = 1.0
		else:
			_advance()


func choose(index: int) -> void:
	var opt: Dictionary = _choices[index]
	history.append("> " + str(opt["text"]))
	choice_panel.visible = false
	var then: Array = opt.get("then", [])
	_queue = then + _queue
	_advance()


func _close() -> void:
	visible = false
	choice_panel.visible = false
	InputManager.pop_mode(InputManager.Mode.DIALOGUE)
	var cb := _on_done
	_on_done = Callable()
	if cb.is_valid():
		cb.call()
	finished.emit()
