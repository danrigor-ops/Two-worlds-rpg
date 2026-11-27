class_name MessageBox
extends CanvasLayer
## Minimal message box. Placeholder for the full dialogue system (build step 3).
## It owns input while open (DIALOGUE mode).

var panel: Panel
var label: Label
var arrow: Label
var _lines: Array = []
var _index := 0
var _on_done := Callable()
var _blink := 0.0


func _ready() -> void:
	layer = 10
	panel = Panel.new()
	panel.theme = Assets.ui_theme
	panel.position = Vector2(4, 116)
	panel.size = Vector2(232, 40)
	add_child(panel)
	label = Label.new()
	label.position = Vector2(8, 4)
	label.size = Vector2(216, 32)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(label)
	arrow = Label.new()
	arrow.text = "v"
	arrow.position = Vector2(222, 28)
	arrow.add_theme_color_override("font_color", Assets.UI_GOLD)
	panel.add_child(arrow)
	visible = false


func is_open() -> bool:
	return visible


func show_lines(lines: Array, on_done := Callable()) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_on_done = on_done
	label.text = str(_lines[0])
	visible = true
	InputManager.push_mode(InputManager.Mode.DIALOGUE)


func _process(delta: float) -> void:
	if not visible:
		return
	_blink += delta
	arrow.visible = int(_blink * 3.0) % 2 == 0
	if InputManager.just_pressed("confirm", InputManager.Mode.DIALOGUE) \
			or InputManager.just_pressed("cancel", InputManager.Mode.DIALOGUE):
		_index += 1
		if _index < _lines.size():
			label.text = str(_lines[_index])
		else:
			_close()


func _close() -> void:
	visible = false
	InputManager.pop_mode(InputManager.Mode.DIALOGUE)
	var cb := _on_done
	_on_done = Callable()
	if cb.is_valid():
		cb.call()
