extends SceneTree
## Headless test runner. From the project folder:
##   godot --headless --import            (first time only, builds the class cache)
##   godot --headless --script res://tests/run_tests.gd
## Exits with code 0 when every check passes, 1 otherwise.

var _passed := 0
var _failed: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed.append(label)
		printerr("  FAIL: ", label)


func _run() -> void:
	var gs: Node = root.get_node("GameState")
	var im: Node = root.get_node("InputManager")
	var assets: Node = root.get_node("Assets")

	print("Content validation")
	var errors: Array[String] = MapData.validate_all()
	for e in errors:
		printerr("  ", e)
	check(errors.is_empty(), "all maps, spawns and doors are valid")
	check(assets.validate().is_empty(), "asset manifest is valid")
	_test_validator_catches_bad_maps()

	print("GameState")
	_test_game_state(gs)

	print("Input mode ownership")
	await _test_input_modes(im)

	print("Follow trail")
	_test_trail()

	print("Exploration integration")
	await _test_exploration(gs, im)

	print("\n%d passed, %d failed" % [_passed, _failed.size()])
	quit(0 if _failed.is_empty() else 1)


func _test_validator_catches_bad_maps() -> void:
	var m := MapData.load_map("KA-02")
	m.spawns["bad"] = {"cell": Vector2i(0, 0), "facing": "down"}   # wall
	m.spawns["on_door"] = {"cell": Vector2i(10, 14), "facing": "up"}
	var e := m.validate_self()
	check(e.any(func(s: String) -> bool: return "spawn 'bad'" in s), "validator rejects a spawn inside a wall")
	check(e.any(func(s: String) -> bool: return "spawn 'on_door'" in s), "validator rejects a spawn on a door")


func _test_game_state(gs: Node) -> void:
	gs.new_game()
	check(gs.data["version"] == gs.SCHEMA_VERSION, "new game has the schema version")
	check(gs.party() == ["reno"], "new game starts with Reno only")
	check(gs.data["wallet"]["dewdrops"] == 5 and gs.data["wallet"]["human_cents"] == 0, "starting wallet is 0 cents and 5 dewdrops")
	check(gs.quest_state("PRO-001") == "active", "PRO-001 starts active")
	check(not gs.set_leader("lumi"), "can't lead with someone not in the party")
	check(gs.add_member("lumi") and not gs.add_member("lumi"), "adding a member is idempotent")
	check(gs.add_key_item("item_x") and not gs.add_key_item("item_x"), "key items are added once")

	var saved: Dictionary = gs.to_dict()
	var round_trip: Variant = JSON.parse_string(JSON.stringify(saved))
	gs.new_game()
	var errs: Array[String] = gs.load_from_dict(round_trip)
	check(errs.is_empty(), "state survives a JSON round trip: %s" % str(errs))
	check(gs.has_member("lumi") and gs.has_key_item("item_x"), "round trip keeps party and key items")
	check(typeof(gs.data["wallet"]["dewdrops"]) == TYPE_INT, "round trip restores whole numbers as ints")

	var before: Dictionary = gs.to_dict()
	var bad: Dictionary = before.duplicate(true)
	bad["wallet"]["human_cents"] = -5
	check(not gs.load_from_dict(bad).is_empty(), "negative money is rejected")
	bad = before.duplicate(true)
	bad["leader"] = "galen"
	check(not gs.load_from_dict(bad).is_empty(), "a leader outside the party is rejected")
	bad = before.duplicate(true)
	bad["version"] = 99
	check(not gs.load_from_dict(bad).is_empty(), "a save from a newer version is rejected")
	check(not gs.load_from_dict({"hello": 1}).is_empty(), "garbage is rejected")
	check(gs.to_dict() == before, "a rejected load leaves the current state untouched")


func _test_input_modes(im: Node) -> void:
	var M: Dictionary = im.Mode
	im.set_base_mode(M.EXPLORE)
	await process_frame
	Input.action_press("confirm")
	check(not im.just_pressed("confirm", M.DIALOGUE), "a mode that doesn't own input gets nothing")
	check(im.just_pressed("confirm", M.EXPLORE), "the owning mode sees the press")
	check(not im.just_pressed("confirm", M.EXPLORE), "a press is only consumed once")
	im.push_mode(M.DIALOGUE)
	check(not im.just_pressed("confirm", M.DIALOGUE), "a consumed press can't leak into a newly opened mode")
	Input.action_release("confirm")
	await process_frame
	Input.action_press("confirm")
	check(im.just_pressed("confirm", M.DIALOGUE), "next frame the new mode gets a fresh press")
	check(im.pop_mode(M.DIALOGUE), "pop returns to the previous mode")
	check(not im.just_pressed("confirm", M.EXPLORE), "closing a box with confirm doesn't also act behind it")
	Input.action_release("confirm")
	check(not im.pop_mode(M.DIALOGUE), "popping the wrong mode is refused")
	Input.action_press("move_right")
	im.push_mode(M.TRANSITION)
	check(im.move_vector(M.EXPLORE) == Vector2.ZERO, "no movement while another mode owns input")
	im.pop_mode(M.TRANSITION)
	check(im.move_vector(M.EXPLORE).x > 0.9, "movement works for the owning mode")
	Input.action_release("move_right")
	await process_frame


func _test_trail() -> void:
	var t := FollowTrail.new()
	t.spacing = 10.0
	t.reset(Vector2.ZERO)
	for i in range(1, 31):
		t.record(Vector2(i, 0))
	check(t.target() == Vector2(20, 0), "follower target is one spacing behind the leader")
	t.record(Vector2(30.2, 0))
	check(t.points.back() == Vector2(30, 0), "tiny moves are not recorded")
	t.reverse_for_swap()
	check(t.points[0] == Vector2(30, 0) and t.points.back() == Vector2(20, 0), "swap reverses the path between the two heroes")
	check(t.target() == Vector2(30, 0), "after a swap the old leader stays put")


func _press_for(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await physics_frame
	Input.action_release(action)
	await physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await process_frame
	await process_frame
	Input.action_release(action)
	await process_frame


func _wait_transition(im: Node) -> void:
	for i in 180:
		if im.current_mode() != im.Mode.TRANSITION:
			return
		await process_frame


func _wait(frames: int) -> void:
	for i in frames:
		await process_frame


func _test_exploration(gs: Node, im: Node) -> void:
	gs.new_game()
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	current_scene = scene
	await _wait(2)
	check(scene.map.id == "KA-02", "new game starts in Reno's Home")
	var lead: Node2D = scene.leader()
	check(MapData.feet_to_cell(lead.global_position) == Vector2i(4, 4), "Reno starts at the start spawn")

	# Walk into the bed on the left and the wall above: collision must stop him.
	await _press_for("move_left", 60)
	var cell := MapData.feet_to_cell(lead.global_position)
	check(cell == Vector2i(4, 4), "the bed stops Reno (ended on %s)" % cell)
	await _press_for("move_up", 90)
	cell = MapData.feet_to_cell(lead.global_position)
	check(cell == Vector2i(4, 2), "the wall stops Reno (ended on %s)" % cell)

	# Use the door: go to the tile above it and walk down.
	lead.place_at(MapData.cell_to_feet(Vector2i(10, 13)), "down")
	await _press_for("move_down", 20)
	await _wait_transition(im)
	check(scene.map.id == "KA-01", "the door leads to Root Square")
	check(gs.has_key_item("item_railway_token") and gs.get_flag("reno_token_obtained"), "railway token added before leaving home")
	lead = scene.leader()
	check(MapData.feet_to_cell(lead.global_position) == Vector2i(7, 8), "arrived on the from_home spawn")
	check(im.current_mode() == im.Mode.DIALOGUE, "token message is showing")
	await _tap("confirm")
	check(im.current_mode() == im.Mode.EXPLORE, "confirm closes the message and returns to exploring")

	# Meet Lumi.
	check(scene.npcs.size() == 1, "Lumi waits in Root Square")
	var lumi_cell: Vector2i = scene.npcs[0]["def"]["cell"]
	lead.place_at(MapData.cell_to_feet(lumi_cell + Vector2i(1, 0)), "left")
	await _tap("confirm")
	check(im.current_mode() == im.Mode.DIALOGUE, "talking to Lumi opens a message")
	for i in 4:
		await _tap("confirm")
	check(gs.get_flag("lumi_joined") and gs.party() == ["reno", "lumi"], "Lumi joined the party")
	check(gs.quest_state("PRO-001") == "completed", "PRO-001 is completed")
	check(im.current_mode() == im.Mode.EXPLORE, "no message reopened after the last confirm")

	# Walk around; the follower must only ever stand on walkable tiles.
	var safe := true
	for step: Array in [["move_down", 40], ["move_right", 60], ["move_up", 30], ["move_left", 50]]:
		Input.action_press(step[0])
		for i in step[1]:
			await physics_frame
			if not scene.map.is_walkable(MapData.feet_to_cell(scene.follower().global_position)):
				safe = false
		Input.action_release(step[0])
	check(safe, "Lumi only stood on walkable tiles while following")
	var gap: float = scene.leader().global_position.distance_to(scene.follower().global_position)
	check(gap <= 20.0, "Lumi keeps up with Reno (gap %.1f px)" % gap)

	# Swap.
	var reno_pos: Vector2 = scene.leader().global_position
	await _tap("swap")
	check(gs.leader() == "lumi", "swap makes Lumi the leader")
	check(scene.follower().member_id == "reno", "Reno becomes the follower")
	await _wait(2)
	check(scene.follower().global_position.distance_to(reno_pos) < 0.5, "Reno doesn't jump on swap")

	# Back through the door with Lumi leading.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(7, 8)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	check(scene.map.id == "KA-02", "the door leads back home")
	check(MapData.feet_to_cell(scene.leader().global_position) == Vector2i(10, 13), "arrived on the from_square spawn")
	check(scene.members.size() == 2 and gs.leader() == "lumi", "party and leader survive the transition")
	check(im.current_mode() == im.Mode.EXPLORE, "no second token message (mode %s)" % im.mode_name())
	scene.queue_free()
	root.remove_child(scene)
	scene.free()
