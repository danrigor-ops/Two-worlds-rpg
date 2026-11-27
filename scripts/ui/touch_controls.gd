extends Control
## On-screen buttons for phones and tablets. They press the same actions as
## the keyboard, so game code never needs to know which device was used.
## Shown automatically on touch screens; press F2 to toggle on a desktop.

const COLOR_FILL := Color(0.11, 0.17, 0.35, 0.45)
const COLOR_PRESSED := Color(0.91, 0.72, 0.29, 0.7)
const COLOR_LABEL := Color(0.96, 0.93, 0.82, 0.9)

# name -> [center, radius, action, label]
var buttons := {
	"up": [Vector2(30, 112), 9.0, "move_up", "^"],
	"down": [Vector2(30, 140), 9.0, "move_down", "v"],
	"left": [Vector2(16, 126), 9.0, "move_left", "<"],
	"right": [Vector2(44, 126), 9.0, "move_right", ">"],
	"a": [Vector2(222, 122), 11.0, "confirm", "A"],
	"b": [Vector2(200, 140), 9.0, "cancel", "B"],
	"swap": [Vector2(200, 108), 8.0, "swap", "S"],
	"menu": [Vector2(228, 12), 7.0, "menu", "M"],
}
var _touches := {}  # touch index -> button name


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			var hit := _button_at(event.position)
			if hit != "":
				_set_touch(event.index, hit)
				get_viewport().set_input_as_handled()
		elif _touches.has(event.index):
			_set_touch(event.index, "")
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Lets you try the pad with a mouse on desktop (F2).
		if event.pressed:
			var hit := _button_at(event.position)
			if hit != "":
				_set_touch(-1, hit)
				get_viewport().set_input_as_handled()
		elif _touches.has(-1):
			_set_touch(-1, "")
	elif event is InputEventScreenDrag and _touches.has(event.index):
		var hit := _button_at(event.position)
		if hit != _touches[event.index]:
			_set_touch(event.index, hit)
		get_viewport().set_input_as_handled()


func _set_touch(index: int, name: String) -> void:
	var old: String = _touches.get(index, "")
	if old != "":
		Input.action_release(buttons[old][2])
		_touches.erase(index)
	if name != "":
		Input.action_press(buttons[name][2])
		_touches[index] = name
	queue_redraw()


func release_all() -> void:
	for index: int in _touches.keys():
		_set_touch(index, "")


func _button_at(pos: Vector2) -> String:
	for name: String in buttons:
		var b: Array = buttons[name]
		if pos.distance_to(b[0]) <= b[1] + 3.0:
			return name
	return ""


func _draw() -> void:
	var font := get_theme_default_font()
	var held := _touches.values()
	for name: String in buttons:
		var b: Array = buttons[name]
		draw_circle(b[0], b[1], COLOR_PRESSED if name in held else COLOR_FILL)
		draw_arc(b[0], b[1], 0.0, TAU, 20, COLOR_LABEL, 1.0)
		draw_string(font, b[0] + Vector2(-3, 3), b[3], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, COLOR_LABEL)
