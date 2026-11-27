extends SceneTree
## Headless test runner. From the project folder:
##   godot --headless --import            (first time only, builds the class cache)
##   godot --headless --script res://tests/run_tests.gd
## Exits with code 0 when every check passes, 1 otherwise.
## The checks live in test_suite.gd, loaded here once the autoloads exist.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var suite: RefCounted = load("res://tests/test_suite.gd").new()
	var code: int = await suite.run(self)
	quit(code)
