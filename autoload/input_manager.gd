extends Node
## Input abstraction and mode ownership.
##
## Keyboard, gamepad and on-screen touch buttons all drive the same named
## actions. Exactly one mode owns input at a time (top of the mode stack), and
## each press can be consumed once per frame, so the confirm that closes a
## message box can't also trigger an interaction behind it.

signal mode_changed(new_mode: int, old_mode: int)

enum Mode { BOOT, TITLE, EXPLORE, DIALOGUE, MENU, CUTSCENE, BATTLE, TRANSITION }

const KEYS := {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
	"confirm": [KEY_Z, KEY_ENTER, KEY_SPACE],
	"cancel": [KEY_X, KEY_BACKSPACE],
	"swap": [KEY_C, KEY_TAB],
	"menu": [KEY_M, KEY_ESCAPE],
}
const PAD_BUTTONS := {
	"move_up": [JOY_BUTTON_DPAD_UP],
	"move_down": [JOY_BUTTON_DPAD_DOWN],
	"move_left": [JOY_BUTTON_DPAD_LEFT],
	"move_right": [JOY_BUTTON_DPAD_RIGHT],
	"confirm": [JOY_BUTTON_A],
	"cancel": [JOY_BUTTON_B],
	"swap": [JOY_BUTTON_Y],
	"menu": [JOY_BUTTON_START],
}
const PAD_AXES := {
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
}

var touch_controls: Control
var _stack: Array[int] = [Mode.BOOT]
var _consumed := {}


func _enter_tree() -> void:
	_register_actions()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	touch_controls = preload("res://scripts/ui/touch_controls.gd").new()
	layer.add_child(touch_controls)
	touch_controls.visible = DisplayServer.is_touchscreen_available()


## Actions are registered in code so they work without editing the Input Map.
## Anything you add in Project Settings > Input Map is kept.
func _register_actions() -> void:
	for action: String in KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.35)
		for key: int in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action, ev)
		for button: int in PAD_BUTTONS.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = button
			InputMap.action_add_event(action, jb)
		if PAD_AXES.has(action):
			var jm := InputEventJoypadMotion.new()
			jm.axis = PAD_AXES[action][0]
			jm.axis_value = PAD_AXES[action][1]
			InputMap.action_add_event(action, jm)


func _unhandled_input(event: InputEvent) -> void:
	# F2 shows the on-screen touch buttons on a desktop, for testing with a mouse.
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F2:
		touch_controls.visible = not touch_controls.visible


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and touch_controls:
		touch_controls.release_all()


# --- Modes -------------------------------------------------------------------

func current_mode() -> int:
	return _stack.back()


func mode_name(mode: int = -1) -> String:
	return Mode.keys()[current_mode() if mode < 0 else mode]


func set_base_mode(mode: int) -> void:
	var old := current_mode()
	_stack = [mode]
	if old != mode:
		mode_changed.emit(mode, old)


func push_mode(mode: int) -> void:
	var old := current_mode()
	_stack.push_back(mode)
	mode_changed.emit(mode, old)


func pop_mode(expected: int) -> bool:
	if _stack.size() <= 1 or current_mode() != expected:
		push_warning("pop_mode(%s) ignored; current mode is %s" % [mode_name(expected), mode_name()])
		return false
	var old: int = _stack.pop_back()
	mode_changed.emit(current_mode(), old)
	return true


# --- Queries (always pass the mode that is asking) ---------------------------

## True once per frame, and only for the mode that currently owns input.
func just_pressed(action: StringName, mode: int) -> bool:
	if current_mode() != mode:
		return false
	var frame := Engine.get_process_frames()
	if _consumed.get(action, -1) == frame:
		return false
	if not Input.is_action_just_pressed(action):
		return false
	_consumed[action] = frame
	return true


func move_vector(mode: int) -> Vector2:
	if current_mode() != mode:
		return Vector2.ZERO
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")
