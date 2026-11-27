extends Control
## Shown at the end of the built content, so the game never ends on a blank
## screen. The save made just before is kept, so Continue resumes in Sungai Melor.


func _ready() -> void:
	InputManager.set_base_mode(InputManager.Mode.CUTSCENE)
	var bg := ColorRect.new()
	bg.color = Color("#1a1838")
	bg.size = Vector2(240, 160)
	add_child(bg)
	var lines := [
		["PROLOGUE COMPLETE", 16, Assets.UI_GOLD, 28],
		["The Great Escape", 8, Assets.UI_TEXT, 50],
		["Next: Chapter 1", 8, Color("#9fb0d8"), 80],
		["The Last Train to Bandar Senja", 8, Assets.UI_TEXT, 92],
		["Chapter 1 is not built yet. Your game is saved.", 8, Color("#9fb0d8"), 118],
		["Press A to return to the title", 8, Assets.UI_GOLD, 140],
	]
	for l: Array in lines:
		var label := Label.new()
		label.text = l[0]
		label.add_theme_font_size_override("font_size", l[1])
		label.add_theme_color_override("font_color", l[2])
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(0, l[3])
		label.size = Vector2(240, 20)
		add_child(label)


func _process(_delta: float) -> void:
	if InputManager.just_pressed("confirm", InputManager.Mode.CUTSCENE):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
