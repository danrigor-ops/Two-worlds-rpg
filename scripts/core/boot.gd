extends Control
## Checks content before the game starts, then goes to the title screen.
## If something is broken, it stays here and lists the problems.


func _ready() -> void:
	InputManager.set_base_mode(InputManager.Mode.BOOT)
	var errors: Array[String] = []
	errors.append_array(Assets.validate())
	errors.append_array(MapData.validate_all(GameState.NEW_GAME_MAP, GameState.NEW_GAME_SPAWN))
	errors.append_array(Dialogue.validate())
	if not errors.is_empty():
		for e in errors:
			push_error(e)
		var label := Label.new()
		label.position = Vector2(4, 4)
		label.size = Vector2(232, 152)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = "Content check failed:\n" + "\n".join(errors.slice(0, 8))
		add_child(label)
		return
	get_tree().change_scene_to_file.call_deferred("res://scenes/title.tscn")
