extends SceneTree
## Headless test runner. From the project folder:
##   godot --headless --import            (first time only, builds the class cache)
##   godot --headless --script res://tests/run_tests.gd
## Exits with code 0 when every check passes, 1 otherwise.
## The checks live in test_suite.gd, loaded here once the autoloads exist.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var script: GDScript = load("res://tests/test_suite.gd")
	if script == null or not script.can_instantiate():
		printerr("test_suite.gd failed to load. See the parse errors above.")
		quit(1)
		return
	var suite: RefCounted = script.new()
	var code: int = await suite.run(self)
	quit(code)
