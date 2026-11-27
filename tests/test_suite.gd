extends RefCounted
## The test checks. Run them with tests/run_tests.gd.

var tree: SceneTree
var root: Window

var _passed := 0
var _failed: Array[String] = []
var _sections_done := 0
const SECTIONS := 7


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed.append(label)
		printerr("  FAIL: ", label)


func run(t: SceneTree) -> int:
	tree = t
	root = t.root
	var gs: Node = root.get_node("GameState")
	var im: Node = root.get_node("InputManager")
	var assets: Node = root.get_node("Assets")

	print("Content validation")
	var errors: Array[String] = MapData.validate_all()
	for e in errors:
		printerr("  ", e)
	check(errors.is_empty(), "all maps, spawns and doors are valid")
	check(assets.validate().is_empty(), "asset manifest is valid")
	var derr := Dialogue.validate()
	for e in derr:
		printerr("  ", e)
	check(derr.is_empty(), "all dialogue scenes are valid")
	_test_validator_catches_bad_maps()

	print("GameState")
	_test_game_state(gs)

	print("Input mode ownership")
	await _test_input_modes(im)

	print("Follow trail")
	_test_trail()

	print("Quests")
	_test_quests(gs)

	print("Exploration integration")
	await _test_exploration(gs, im)

	_sections_done += 1
	print("\n%d passed, %d failed" % [_passed, _failed.size()])
	if _sections_done != SECTIONS:
		printerr("Only %d of %d test sections finished: a script error stopped one. See the errors above." % [_sections_done, SECTIONS])
		return 1
	return 0 if _failed.is_empty() else 1


func _test_validator_catches_bad_maps() -> void:
	var m := MapData.load_map("KA-02")
	m.spawns["bad"] = {"cell": Vector2i(0, 0), "facing": "down"}   # wall
	m.spawns["on_door"] = {"cell": Vector2i(10, 14), "facing": "up"}
	var e := m.validate_self()
	check(e.any(func(s: String) -> bool: return "spawn 'bad'" in s), "validator rejects a spawn inside a wall")
	check(e.any(func(s: String) -> bool: return "spawn 'on_door'" in s), "validator rejects a spawn on a door")
	_sections_done += 1


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
	_sections_done += 1


func _test_quests(gs: Node) -> void:
	var quests: Node = root.get_node("Quests")
	gs.new_game()
	check(gs.quest_state("PRO-002") == "locked", "PRO-002 starts locked")
	gs.set_flag("bobo_parcel_returned")
	check(gs.quest_state("PRO-002") == "locked", "a locked quest can't complete early")
	gs.new_game()
	gs.set_flag("bobo_parcel_quest_started")
	check(gs.quest_state("PRO-002") == "active", "start flag activates the quest")
	gs.set_flag("bobo_parcel_returned")
	check(gs.quest_state("PRO-002") == "rewarded", "complete flag completes and rewards it")
	check(gs.item_count("item_dewdrop_candy") == 2, "reward given once")
	quests.refresh()
	quests.refresh()
	check(gs.item_count("item_dewdrop_candy") == 2, "refreshing again gives nothing more")
	check(not gs.set_quest_state("PRO-002", "active"), "quests never move backwards")
	check(not gs.add_item("item_dewdrop_candy", -3), "can't remove more items than you have")
	check(gs.add_item("item_dewdrop_candy", 97) and not gs.add_item("item_dewdrop_candy", 1), "stacks stop at 99")
	check(not gs.add_dewdrops(-100), "dewdrops can't go negative")
	check(PauseMenu.format_cents(1505) == "$15.05", "money shows as dollars and cents")
	gs.new_game()
	_sections_done += 1


func _test_input_modes(im: Node) -> void:
	var M: Dictionary = im.Mode
	im.set_base_mode(M.EXPLORE)
	await tree.process_frame
	Input.action_press("confirm")
	check(not im.just_pressed("confirm", M.DIALOGUE), "a mode that doesn't own input gets nothing")
	check(im.just_pressed("confirm", M.EXPLORE), "the owning mode sees the press")
	check(not im.just_pressed("confirm", M.EXPLORE), "a press is only consumed once")
	im.push_mode(M.DIALOGUE)
	check(not im.just_pressed("confirm", M.DIALOGUE), "a consumed press can't leak into a newly opened mode")
	Input.action_release("confirm")
	await tree.process_frame
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
	await tree.process_frame
	_sections_done += 1


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
	_sections_done += 1


func _press_for(action: String, frames: int) -> void:
	Input.action_press(action)
	for i in frames:
		await tree.physics_frame
	Input.action_release(action)
	await tree.physics_frame


func _tap(action: String) -> void:
	Input.action_press(action)
	await tree.process_frame
	await tree.process_frame
	Input.action_release(action)
	await tree.process_frame


func _wait_transition(im: Node) -> void:
	for i in 180:
		if im.current_mode() != im.Mode.TRANSITION:
			return
		await tree.process_frame


func _wait(frames: int) -> void:
	for i in frames:
		await tree.process_frame


func _finish_dialogue(im: Node, choice := 0) -> void:
	for i in 80:
		if im.current_mode() != im.Mode.DIALOGUE:
			return
		var box: DialogueBox = tree.current_scene.dialogue
		if box.choice_panel.visible:
			for k in choice:
				await _tap("move_down")
		await _tap("confirm")


func _talk(scene: Node, cell: Vector2i, im: Node, choice := 0) -> void:
	scene.leader().place_at(MapData.cell_to_feet(cell + Vector2i(0, 1)), "up")
	await tree.physics_frame
	await _tap("confirm")
	await _finish_dialogue(im, choice)


func _test_exploration(gs: Node, im: Node) -> void:
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(2)
	check(scene.map.id == "KA-02", "new game starts in Reno's Home")
	check(im.current_mode() == im.Mode.DIALOGUE, "the P00 wake-up scene plays on a new game")
	await _finish_dialogue(im)
	check(gs.get_flag("p00_seen") and gs.has_key_item("item_railway_token"), "P00 sets its flag and gives the railway token")
	check("Reno: ...After breakfast." in scene.dialogue.history, "P00 lines come from the dialogue file")
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
	lead = scene.leader()
	check(MapData.feet_to_cell(lead.global_position) == Vector2i(7, 8), "arrived on the from_home spawn")
	check(im.current_mode() == im.Mode.EXPLORE, "no token message, P00 already gave it")

	# Nenek before Lumi joins.
	scene.warp("KA-05", "from_square")
	await _talk(scene, Vector2i(12, 8), im)
	check("Nenek Rimba: Reno. Lumi was looking for you by the great root. Go and find her. (placeholder)" in scene.dialogue.history, "Nenek sends Reno to find Lumi first")
	check(not gs.get_flag("elder_warning_heard"), "the warning needs Lumi")
	scene.warp("KA-01", "from_hollow")
	await _wait(2)

	# Meet Lumi and pick the second flavour choice.
	check(scene.npcs.size() == 1, "Lumi waits in Root Square")
	var lumi_cell: Vector2i = scene.npcs[0]["def"]["cell"]
	scene.leader().place_at(MapData.cell_to_feet(lumi_cell + Vector2i(1, 0)), "left")
	await tree.physics_frame
	await _tap("confirm")
	check(im.current_mode() == im.Mode.DIALOGUE, "talking to Lumi opens dialogue")
	await _finish_dialogue(im, 1)
	check("Lumi: You promised that before the mushroom pond, too." in scene.dialogue.history, "the chosen flavour reply plays")
	check(not ("Lumi: You don't even know how human money works." in scene.dialogue.history), "other choice replies don't play")
	check(gs.get_flag("lumi_joined") and gs.party() == ["reno", "lumi"], "Lumi joined the party")
	await _wait(3)
	check(gs.quest_state("PRO-001") == "completed", "PRO-001 is completed")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.EXPLORE, "back to exploring after the quest notice")
	check(scene.follower() != null and scene.follower().member_id == "lumi", "Lumi is now the follower")

	# Walk around; the follower must only ever stand on walkable tiles.
	var safe := true
	for step: Array in [["move_down", 40], ["move_right", 60], ["move_up", 30], ["move_left", 50]]:
		Input.action_press(step[0])
		for i in step[1]:
			await tree.physics_frame
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
	await _tap("swap")

	# Nenek's warning, then repeat talk.
	scene.warp("KA-05", "from_square")
	await _talk(scene, Vector2i(12, 8), im)
	check(gs.get_flag("elder_warning_heard"), "P02 sets elder_warning_heard")
	var lines_before: int = scene.dialogue.history.size()
	await _talk(scene, Vector2i(12, 8), im)
	check(scene.dialogue.history.size() == lines_before + 1, "talking again gives one short line, not the scene again")

	# Bobo: start, repeat, return, reward once.
	scene.warp("KA-04", "from_square")
	await _talk(scene, Vector2i(8, 9), im)
	check(gs.get_flag("bobo_parcel_quest_started"), "Bobo starts the parcel errand")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("PRO-002") == "active", "PRO-002 becomes active")
	await _talk(scene, Vector2i(8, 9), im)
	check(gs.quest_state("PRO-002") == "active", "talking again doesn't change the quest")
	scene.warp("KA-01", "from_market")
	scene.warp("KA-04", "from_square")
	check(scene.npcs.size() == 1 and gs.quest_state("PRO-002") == "active", "leaving and coming back keeps Bobo and the quest")
	gs.set_flag("leafling_tutorial_complete")   # stand-in until the combat step
	await _talk(scene, Vector2i(8, 9), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("PRO-002") == "rewarded", "PRO-002 is rewarded after the parcel comes back")
	check(gs.has_key_item("item_lantern") and gs.get_flag("lantern_obtained"), "the lantern is given")
	check(gs.item_count("item_dewdrop_candy") == 2, "two Dewdrop Candies are given")
	await _talk(scene, Vector2i(8, 9), im)
	scene.get_node("/root/Quests").refresh()
	check(gs.item_count("item_dewdrop_candy") == 2, "talking again and re-checking quests gives nothing more")
	check(not gs.claim_reward("PRO-002", {"items": {"item_dewdrop_candy": 2}}), "a claimed reward can't be claimed again")

	# Pause menu owns input.
	await _tap("menu")
	check(im.current_mode() == im.Mode.MENU, "menu opens")
	check(PauseMenu.journal_rows().size() == 2, "journal lists the two started quests")
	await _tap("swap")
	check(gs.leader() == "reno", "swap does nothing while the menu is open")
	await _tap("cancel")
	check(im.current_mode() == im.Mode.EXPLORE, "cancel closes the menu")

	# Save round trip keeps all of it.
	var snap: Dictionary = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.new_game()
	check(gs.load_from_dict(snap).is_empty() and gs.quest_state("PRO-002") == "rewarded" and gs.item_count("item_dewdrop_candy") == 2, "a save after these milestones restores the same quest state")

	# Back home: P00 must not replay.
	scene.warp("KA-01", "from_market")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(7, 8)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	check(scene.map.id == "KA-02", "the door leads back home")
	check(MapData.feet_to_cell(scene.leader().global_position) == Vector2i(10, 13), "arrived on the from_square spawn")
	check(scene.members.size() == 2, "the party survives the transition")
	check(im.current_mode() == im.Mode.EXPLORE, "P00 doesn't replay when coming home")
	root.remove_child(scene)
	scene.free()
	_sections_done += 1
