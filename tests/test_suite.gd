extends RefCounted
## The test checks. Run them with tests/run_tests.gd.

var tree: SceneTree
var root: Window

var _passed := 0
var _failed: Array[String] = []
var _sections_done := 0
const SECTIONS := 27


func check(cond: bool, label: String) -> void:
	if cond:
		_passed += 1
	else:
		_failed.append(label)
		printerr("  FAIL: ", label)


func run(t: SceneTree) -> int:
	tree = t
	root = t.root
	var saves: Node = root.get_node("Saves")
	saves.save_dir = "user://test_saves/"
	saves.export_dir = "user://test_exports/"
	saves.delete_all()
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

	print("Combat rules")
	_test_combat()

	print("Leafling tutorial battle")
	await _test_leafling(gs, im)

	print("Whispering Roots puzzles")
	await _test_roots(gs, im)

	print("Inventory and saving")
	await _test_saves(gs, im)

	print("Team skill rules")
	_test_team_rules()

	print("Full prologue run (regression)")
	await _test_full_prologue(gs, im)

	print("Chapter 1 part A: Sungai Melor to Bandar Senja")
	await _test_chapter1_a(gs, im)

	print("Statuses, summons and Guardian Bloom")
	_test_statuses()

	print("Chapter 1 part B: the Clockkeeper's parcels")
	await _test_chapter1_b(gs, im)

	print("Chapter 1 part C: the Veil train and the ending")
	await _test_chapter1_c(gs, im)

	print("Chapter 2 part A: the river, the tides and the first two verses")
	await _test_chapter2_a(gs, im)

	print("Chapter 2 part B: the Sunken Jetty, the Undertow and Nenek Arus")
	await _test_chapter2_b(gs, im)

	print("Chapter 3: The Town That Forgot Its Name")
	await _test_chapter3(gs, im)

	print("Chapter 4: The Rubber Grove at Midnight")
	await _test_chapter4(gs, im)

	print("Chapter 5: A Thousand Flowers, One Promise")
	await _test_chapter5(gs, im)

	print("Chapter 6: The Midnight Carnival")
	await _test_chapter6(gs, im)

	print("Chapter 7: The Guardian of the Eastern Mountains")
	await _test_chapter7(gs, im)

	print("Chapter 8: The Night the Worlds Touched")
	await _test_chapter8(gs, im)

	print("Chapter 9: The Keeper of Forgotten Years")
	await _test_chapter9(gs, im)

	print("Chapter 10: Where Two Worlds Meet")
	await _test_chapter10(gs, im)

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


## Like _finish_dialogue, but each choice box takes the next answer in the list.
func _finish_dialogue_choices(im: Node, choices: Array) -> void:
	var n := 0
	for i in 120:
		if im.current_mode() != im.Mode.DIALOGUE:
			return
		var box: DialogueBox = tree.current_scene.dialogue
		if box.choice_panel.visible:
			for k in int(choices[mini(n, choices.size() - 1)]):
				await _tap("move_down")
			n += 1
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
	check(PauseMenu.journal_rows().size() == 3, "journal lists the three started quests")
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


func _test_combat() -> void:
	check(Combat.judge(0) == "perfect" and Combat.judge(80) == "perfect" and Combat.judge(-80) == "perfect", "within 80 ms is Perfect")
	check(Combat.judge(81) == "good" and Combat.judge(-180) == "good", "81 to 180 ms is Good")
	check(Combat.judge(181) == "miss", "past 180 ms is a miss")
	check(Combat.judge(150, 2.0) == "perfect", "the accessibility setting widens the windows")
	var reno := Combat.make_unit("reno", "Reno", "hero", {"max_hp": 42, "max_mp": 14, "atk": 14, "def": 9, "mag": 6, "res": 8, "spd": 12})
	var lumi := Combat.make_unit("lumi", "Lumi", "hero", {"max_hp": 32, "max_mp": 24, "atk": 7, "def": 7, "mag": 16, "res": 12, "spd": 10})
	var leaf := Combat.make_unit("leafling_0", "Leafling", "enemy", {"max_hp": 48, "atk": 9, "def": 8, "mag": 4, "res": 7, "spd": 6})
	check(Combat.base_damage("physical", reno, leaf) == 20, "physical base is 2*ATK-DEF (20)")
	check(Combat.base_damage("magical", lumi, leaf) == 25, "magical base is 2*MAG-RES (25)")
	check(Combat.base_damage("physical", leaf, Combat.make_unit("x", "x", "hero", {"max_hp": 1, "atk": 0, "def": 99, "mag": 0, "res": 0, "spd": 0})) == 1, "base damage is at least 1")
	check(Combat.final_damage(20, 1.0, 1.5, 1.0) == 30, "Perfect is 1.5x")
	check(Combat.final_damage(20, 1.0, 1.2, 1.0) == 24, "Good is 1.2x")
	check(Combat.final_damage(25, 1.4, 1.5, 1.0) == 53, "multipliers stack, then round once (52.5 -> 53)")
	check(Combat.final_damage(1, 1.0, 1.0, 0.5) == 1, "a landed hit does at least 1")
	check(Combat.final_damage(20, 1.0, 1.0, 0.0) == 0, "a perfect dodge does nothing")

	var c := Combat.new()
	var a := Combat.make_unit("a", "A", "hero", {"max_hp": 10, "atk": 1, "def": 1, "mag": 1, "res": 1, "spd": 10})
	var b := Combat.make_unit("b", "B", "hero", {"max_hp": 10, "atk": 1, "def": 1, "mag": 1, "res": 1, "spd": 10})
	c.setup([b, a, reno], [leaf])
	check(c.begin_round() == ["reno", "a", "b", "leafling_0"], "order is by SPD, ties by id")
	check(c.begin_round("enemy")[0] == "leafling_0", "an enemy-first round puts enemies first")
	c.begin_round()
	var first := c.next_actor()
	check(c.spend_token(first) and not c.spend_token(first), "one action token per round")
	c.guard(reno)
	check(reno["guarding"] and reno["mp"] == 14, "guard sets the stance (MP is capped at max)")
	reno["mp"] = 5
	c.guard(reno)
	check(reno["mp"] == 7, "guard gives 2 MP")
	var before: int = reno["hp"]
	var dmg := c.hit(leaf, reno, "physical", 1.0, "miss")
	check(dmg == 5 and reno["hp"] == before - 5, "guard halves damage (9 -> 4.5 -> 5)")
	check(not c.spend_mp(reno, 99) and reno["mp"] == 7, "can't spend more MP than you have")
	c.begin_round()
	while true:
		var u := c.next_actor()
		if u.is_empty() or u["id"] == "reno":
			break
	check(not reno["guarding"], "guard ends when that hero's next turn starts")
	leaf["hp"] = 0
	check(c.outcome() == "win", "no enemies left is a win")
	_sections_done += 1


func _wait_menu(battle: Node) -> void:
	for i in 300:
		if not is_instance_valid(battle) or battle._menu_open:
			return
		await tree.process_frame


func _test_leafling(gs: Node, im: Node) -> void:
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["p00_seen", "lumi_joined", "elder_warning_heard"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(2)

	# The glade door is closed until Bobo's errand has started.
	scene.warp("KA-01", "from_glade")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(19, 27)), "down")
	await _press_for("move_down", 20)
	check(scene.map.id == "KA-01" and im.current_mode() == im.Mode.DIALOGUE, "the glade is closed before Bobo's errand")
	await _finish_dialogue(im)
	check(scene.map.is_walkable(MapData.feet_to_cell(scene.leader().global_position)), "Reno is stepped back off the exit")
	gs.set_flag("bobo_parcel_quest_started")
	await _wait(3)
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(19, 27)), "down")
	await _press_for("move_down", 20)
	await _wait_transition(im)
	check(scene.map.id == "KA-06", "then it leads to the Training Glade")

	# Walk into the Leafling.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 12)), "down")
	await _press_for("move_down", 24)
	check(im.current_mode() == im.Mode.DIALOGUE, "touching the Leafling starts scene P04")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "then the battle starts")
	var battle: Battle = null
	for c in scene.get_children():
		if c is Battle:
			battle = c
	check(battle != null and battle.snapshot.get("flags", {}).has("bobo_parcel_quest_started"), "a snapshot is saved before the fight")
	await _wait_menu(battle)
	check(battle.battle_log.size() == 1 and "dodge:perfect 0" in battle.battle_log[0], "the Leafling opens with Seed Toss, dodged perfectly")
	check(not battle._menu_items.any(func(i: Dictionary) -> bool: return i["value"] == "run"), "you can't run from the tutorial")
	await _tap("confirm")   # Reno: Attack
	await _wait_menu(battle)
	check("reno -> leafling_0 perfect 30" in battle.battle_log, "Reno's Perfect attack does 30 (20 x 1.5)")
	await _tap("move_down")
	await _tap("confirm")   # Lumi: Skill
	await _wait_menu(battle)
	await _tap("confirm")   # Echo Spark
	for i in 300:
		if im.current_mode() != im.Mode.BATTLE:
			break
		await tree.process_frame
	check(gs.get_flag("leafling_tutorial_complete"), "winning sets leafling_tutorial_complete")
	check(gs.has_key_item("item_bobo_parcel"), "the parcel is recovered")
	check(gs.data["members"]["reno"]["xp"] == 5 and gs.data["members"]["lumi"]["mp"] == 24, "XP is gained and MP refills after the battle")
	check(im.current_mode() == im.Mode.DIALOGUE, "the after-battle scene plays")
	await _finish_dialogue(im)
	check(scene.npcs.is_empty(), "the Leafling is gone")
	scene.warp("KA-01", "from_glade")
	scene.warp("KA-06", "from_square")
	check(scene.npcs.is_empty(), "and stays gone after leaving and coming back")

	# Return the parcel.
	scene.warp("KA-04", "from_square")
	await _talk(scene, Vector2i(8, 9), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("PRO-002") == "rewarded" and gs.has_key_item("item_lantern"), "Bobo trades the lantern for the parcel")
	check(not gs.has_key_item("item_bobo_parcel"), "the parcel is handed over")

	# A lost battle restores the snapshot taken at its start.
	var b2 := Battle.new()
	b2.auto_judge = "miss"
	b2.speed = 20.0
	scene.add_child(b2)
	b2.start("leafling_tutorial")
	await _wait(2)
	gs.add_item("item_dewdrop_candy", -2)
	await b2._lose()
	check(gs.item_count("item_dewdrop_candy") == 2, "losing restores the state from before the battle")
	# One input per cue: a second press on the same cue is ignored.
	var results: Array[String] = []
	b2._cue_done.connect(func(r: String) -> void: results.append(r))
	b2._cue_active = true
	b2._cue_time_us = Time.get_ticks_usec() - 50000
	b2._resolve_cue(Time.get_ticks_usec())
	b2._resolve_cue(Time.get_ticks_usec())
	check(results.size() == 1 and results[0] == "perfect", "one input per cue (a press 50 ms late is Perfect)")
	b2._end("escape")
	await _wait(2)
	root.remove_child(scene)
	scene.free()
	_sections_done += 1



func _cell_of(n: Node2D) -> Vector2i:
	return MapData.feet_to_cell(n.global_position)


func _wait_explore(im: Node) -> void:
	for i in 120:
		if im.current_mode() == im.Mode.EXPLORE:
			return
		await tree.process_frame


func _face_and_press(scene: Node, cell: Vector2i, facing: String, im: Node) -> void:
	scene.leader().place_at(MapData.cell_to_feet(cell), facing)
	await tree.physics_frame
	await _tap("confirm")


func _test_roots(gs: Node, im: Node) -> void:
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["p00_seen", "lumi_joined", "elder_warning_heard", "bobo_parcel_quest_started", "leafling_tutorial_complete", "bobo_parcel_returned"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	gs.set_spawn("KA-06", "from_roots")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("lantern_obtained") and gs.quest_state("PRO-003") == "active", "the lantern opens the Whispering Roots quest")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 25)), "down")
	await _press_for("move_down", 20)
	await _wait_transition(im)
	check(scene.map.id == "KA-08", "the glade's south exit leads into the Whispering Roots")
	await _finish_dialogue(im)

	# PZ-001: Leaf Leap over three gaps.
	var map: MapData = scene.map
	await _face_and_press(scene, Vector2i(24, 9), "down", im)
	await _finish_dialogue(im)   # first-time hint trigger may have played
	await _face_and_press(scene, Vector2i(24, 9), "down", im)
	await _wait_explore(im)
	check(_cell_of(scene.leader()) == Vector2i(24, 11), "Reno leaps the first gap (now at %s)" % _cell_of(scene.leader()))
	await _face_and_press(scene, Vector2i(24, 12), "down", im)
	await _wait_explore(im)
	await _face_and_press(scene, Vector2i(24, 15), "down", im)
	await _wait_explore(im)
	check(_cell_of(scene.leader()) == Vector2i(24, 17), "and the next two")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(24, 14), "up", im)
	check(im.current_mode() == im.Mode.DIALOGUE and _cell_of(scene.leader()) == Vector2i(24, 14), "Lumi can't leap; she says Reno can")
	await _finish_dialogue(im)
	await _tap("swap")

	# Falling into a gap puts you back on safe ground.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(22, 15)), "down")
	await _press_for("move_down", 3)
	await _press_for("move_up", 20)
	await _wait(3)
	await _press_for("move_up", 20)
	await _wait(30)
	check(im.current_mode() == im.Mode.DIALOGUE, "walking into a gap is a fall")
	await _finish_dialogue(im)
	var after := _cell_of(scene.leader())
	check(map.is_walkable(after) and not map.is_pit(after), "after a fall Reno is on safe ground (%s)" % after)

	# PZ-002 / PZ-003: Echo Sight and the gate key.
	check(not map.is_walkable(Vector2i(24, 20)), "the stepping stones are hidden at first")
	await _face_and_press(scene, Vector2i(23, 18), "left", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("echo_path_revealed"), "Reno can't read the echo marker")
	await _face_and_press(scene, Vector2i(26, 24), "right", im)
	await _finish_dialogue(im)
	check(not gs.has_key_item("item_gate_key"), "the key isn't found before the echo is revealed")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(23, 18), "left", im)
	await _finish_dialogue(im)
	check(gs.get_flag("echo_path_revealed"), "Lumi's Echo Sight reveals the path")
	check("???: Remember the way home." in scene.dialogue.history, "the voice speaks (P05)")
	check(map.is_walkable(Vector2i(24, 20)) and scene.tilemap.get_cell_atlas_coords(Vector2i(24, 20)).x == scene.get_node("/root/Assets").tile_index("stone"), "the stones appear and can be walked on")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 18)), "down")
	await _press_for("move_down", 80)
	check(_cell_of(scene.leader()).y >= 23, "you can cross the pond on the stones")
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(30, 25), "right", im)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_gate_key") and gs.get_flag("gate_key_collected"), "the gate key is found at the mossy marker")
	await _face_and_press(scene, Vector2i(30, 25), "right", im)
	await _finish_dialogue(im)
	check(gs.data["key_items"].count("item_gate_key") == 1, "and only once")

	# PZ-004: Root Bridge needs Lumi's echo, then Reno's grip.
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 26)), "down")
	await _press_for("move_down", 12)
	await _finish_dialogue(im)
	check(gs.get_flag("p05_bridge_seen"), "the broken-bridge scene played")
	await _tap("swap")
	check(gs.leader() == "reno", "Reno leads")
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("root_bridge_restored"), "Reno can't rebuild the bridge without the echo")
	await _face_and_press(scene, Vector2i(24, 27), "down", im)
	await _finish_dialogue(im)
	check(_cell_of(scene.leader()).y == 27, "the chasm is too wide to leap")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	await _tap("swap")
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("root_bridge_restored") and map.is_walkable(Vector2i(24, 29)), "Echo Sight then Root Grip restores the bridge")
	check(gs.quest_state("PRO-003") in ["completed", "rewarded"], "PRO-003 is complete")

	# Puzzles stay solved after leaving, and after a save round trip.
	scene.warp("KA-06", "from_roots")
	scene.warp("KA-08", "from_glade")
	check(scene.map.is_walkable(Vector2i(24, 20)) and scene.map.is_walkable(Vector2i(24, 29)), "stones and bridge are still there after re-entering")
	var snap: Variant = JSON.parse_string(JSON.stringify(gs.to_dict()))
	gs.new_game()
	gs.load_from_dict(snap)
	scene.warp("KA-08", "from_glade")
	check(scene.map.is_walkable(Vector2i(24, 29)) and gs.has_key_item("item_gate_key"), "and after loading a save")
	root.remove_child(scene)
	scene.free()
	_sections_done += 1



func _test_saves(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	check(not saves.any_save(), "no saves at first")

	# Money and items.
	gs.data["wallet"]["human_cents"] = 40
	check(not gs.buy("item_dewdrop_candy", 15, 3), "can't buy more than you can afford")
	check(gs.data["wallet"]["human_cents"] == 40 and gs.item_count("item_dewdrop_candy") == 0, "a failed purchase changes nothing")
	check(gs.buy("item_dewdrop_candy", 15, 2) and gs.data["wallet"]["human_cents"] == 10, "buying takes the money and gives the items")
	check(gs.sell("item_dewdrop_candy", 15, 1) and gs.data["wallet"]["human_cents"] == 17, "selling gives half price rounded down (7 cents)")
	gs.add_key_item("item_lantern")
	check(not gs.sell("item_lantern", 100) and not gs.add_item("item_lantern", 1), "key items can't be sold or stacked")
	gs.data["members"]["lumi"] = gs.data["members"]["lumi"]
	gs.add_member("lumi")
	gs.data["members"]["reno"]["hp"] = 10
	check(gs.use_heal_item("item_dewdrop_candy") == "" and gs.data["members"]["reno"]["hp"] == 20, "a candy heals the most hurt hero by 10")
	check(gs.use_heal_item("item_dewdrop_candy") != "", "with none left it says so")

	# Slots.
	gs.set_flag("lumi_joined")
	check(saves.save("1").is_empty() and saves.has_save("1"), "saving to slot 1 works")
	var saved: Dictionary = gs.to_dict()
	gs.new_game()
	check(saves.load_slot("1").is_empty(), "loading slot 1 works")
	check(gs.get_flag("lumi_joined") and gs.data["wallet"]["human_cents"] == 17 and gs.has_key_item("item_lantern"), "loading restores flags, money and key items")
	check(JSON.stringify(gs.to_dict()) == JSON.stringify(saved), "the loaded state matches what was saved")
	check(not saves.load_slot("2").is_empty(), "an empty slot can't be loaded")

	# Damaged and tampered files are rejected without touching anything.
	var good := FileAccess.get_file_as_string(saves.slot_path("1"))
	check(not saves.load_text("{ not json").is_empty(), "invalid JSON is rejected")
	check(not saves.load_text(good.replace("\"human_cents\": 17", "\"human_cents\": 99999")).is_empty(), "a hand-edited save fails its checksum")
	var d: Dictionary = JSON.parse_string(good)
	d["state"]["wallet"]["human_cents"] = -5
	d["checksum"] = JSON.stringify(d["state"], "", true).sha256_text()
	check(not saves.load_text(JSON.stringify(d)).is_empty(), "a save with negative money is rejected even with a matching checksum")
	check(JSON.stringify(gs.to_dict()) == JSON.stringify(saved), "rejected loads leave the current game untouched")
	check(not saves.import_into("1", "{\"format\": \"nope\"}").is_empty(), "importing a bad file is refused")
	check(FileAccess.get_file_as_string(saves.slot_path("1")) == good, "and the good slot is not overwritten")
	check(saves.import_into("2", good).is_empty() and saves.load_slot("2").is_empty(), "importing a good file into slot 2 works")
	var ex: Array = saves.export_slot("1")
	check((ex[0] as Array).is_empty() and FileAccess.file_exists(saves.export_dir + "two-worlds-slot-1.json"), "export writes a backup file")

	# Autosave after a map transition, not during it.
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	gs.set_flag("p00_seen")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(10, 13)), "down")
	Input.action_press("move_down")
	var saved_during := false
	for i in 30:
		await tree.physics_frame
		if im.current_mode() == im.Mode.TRANSITION and saves.has_save("auto"):
			saved_during = true
	Input.action_release("move_down")
	await _wait_transition(im)
	check(not saved_during, "no autosave in the middle of a transition")
	check(saves.has_save("auto"), "autosave after arriving in a new map")
	gs.new_game()
	check(saves.load_slot("auto").is_empty() and gs.data["map_id"] == "KA-01", "the autosave resumes in Root Square")
	await _finish_dialogue(im)

	# Menu: System tab saves.
	await _tap("menu")
	for k in 3:
		await _tap("move_right")
	check(scene.menu.TABS[scene.menu.tab] == "System", "the menu has a System tab")
	await _tap("confirm")
	check(saves.has_save("1"), "Save to slot 1 from the menu")
	await _tap("cancel")
	root.remove_child(scene)
	scene.free()
	saves.delete_all()
	_sections_done += 1



func _test_team_rules() -> void:
	var c := Combat.new()
	var reno := Combat.make_unit("reno", "Reno", "hero", {"max_hp": 42, "max_mp": 14, "atk": 14, "def": 9, "mag": 6, "res": 8, "spd": 12})
	var lumi := Combat.make_unit("lumi", "Lumi", "hero", {"max_hp": 32, "max_mp": 24, "atk": 7, "def": 7, "mag": 16, "res": 12, "spd": 10})
	var boss := Combat.make_unit("thornkeeper_0", "Thornkeeper", "enemy", {"max_hp": 180, "atk": 11, "def": 9, "mag": 8, "res": 10, "spd": 5})
	c.setup([reno, lumi], [boss])
	c.begin_round()
	check(c.can_team(["reno", "lumi"], 4), "Spirit Cyclone is available with both tokens and 4 MP each")
	lumi["mp"] = 3
	check(not c.can_team(["reno", "lumi"], 4), "not without enough MP")
	lumi["mp"] = 24
	c.spend_token(lumi)
	check(not c.can_team(["reno", "lumi"], 4), "not once a partner has acted")
	c.begin_round()
	check(c.pay_team(["reno", "lumi"], 4) and reno["mp"] == 10 and lumi["mp"] == 20, "it costs 4 MP from each, once")
	check(not reno["token"] and not lumi["token"], "and uses both heroes' turns")
	check(not c.pay_team(["reno", "lumi"], 4), "it can't be paid twice in a round")
	# (19 physical + 22 magical) x 1.5 skill x timing average.
	check(Combat.team_damage([reno, lumi], boss, 1.5, ["perfect", "perfect", "perfect"]) == 92, "three Perfects: 41 x 1.5 x 1.5 = 92")
	check(Combat.team_damage([reno, lumi], boss, 1.5, ["miss", "miss", "miss"]) == 62, "three misses still land: 41 x 1.5 = 62")
	check(Combat.team_damage([reno, lumi], boss, 1.5, ["perfect", "good", "miss"]) == 76, "mixed timing scales between (x1.233 = 76)")
	reno["hp"] = 0
	check(not c.can_team(["reno", "lumi"], 4), "not if a partner is down")
	_sections_done += 1


func _milestone(gs: Node, label: String) -> void:
	# Save and resume must give the same quest state at every milestone.
	var saves: Node = root.get_node("Saves")
	var before: Dictionary = gs.data["quests"].duplicate()
	saves.save("2")
	gs.new_game()
	saves.load_slot("2")
	check(gs.data["quests"] == before, "save and resume keep quests at: " + label)


func _run_battle(scene: Node, im: Node, prefer_team: bool) -> Array[String]:
	var out: Array[String] = []
	var battle: Battle = null
	for i in 200:
		for c in scene.get_children():
			if c is Battle:
				battle = c
		if battle:
			break
		await tree.process_frame
	if battle == null:
		return out
	for i in 3000:
		if not is_instance_valid(battle) or im.current_mode() != im.Mode.BATTLE:
			break
		out.assign(battle.battle_log)
		if battle._menu_open:
			battle._menu_done.emit(_menu_pick(battle, ["team:spirit_cyclone", "attack"] if prefer_team else ["attack"]))
		await tree.process_frame
	return out


func _test_full_prologue(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(2)
	await _finish_dialogue(im)
	check(gs.get_flag("reno_token_obtained"), "P00: token")
	scene.warp("KA-01", "from_home")
	var lumi_cell: Vector2i = scene.npcs[0]["def"]["cell"]
	scene.leader().place_at(MapData.cell_to_feet(lumi_cell + Vector2i(1, 0)), "left")
	await tree.physics_frame
	await _tap("confirm")
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("lumi_joined"), "P01: Lumi joins")
	_milestone(gs, "Lumi joined")
	scene.warp("KA-05", "from_square")
	await _talk(scene, Vector2i(12, 8), im)
	check(gs.get_flag("elder_warning_heard"), "P02: Nenek's warning")
	scene.warp("KA-04", "from_square")
	await _talk(scene, Vector2i(8, 9), im)
	await _wait(3)
	await _finish_dialogue(im)
	_milestone(gs, "Bobo's errand")
	scene.warp("KA-06", "from_square")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 12)), "down")
	await _press_for("move_down", 24)
	await _finish_dialogue(im)
	await _run_battle(scene, im, false)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("leafling_tutorial_complete"), "P04: Leafling beaten")
	scene.warp("KA-04", "from_square")
	await _talk(scene, Vector2i(8, 9), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("lantern_obtained"), "P03: lantern")
	_milestone(gs, "lantern")
	scene.warp("KA-08", "from_glade")
	await _wait(2)
	await _finish_dialogue(im)
	await _tap("swap")
	await _face_and_press(scene, Vector2i(23, 18), "left", im)
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(30, 25), "right", im)
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	await _tap("swap")
	await _face_and_press(scene, Vector2i(22, 27), "left", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("gate_key_collected") and gs.get_flag("root_bridge_restored"), "P05: key and bridge")
	check(gs.quest_state("PRO-004") == "active", "the Thornkeeper quest begins")
	_milestone(gs, "bridge restored")

	# P06: the gate is sealed until the Thornkeeper is beaten.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 32)), "down")
	await _press_for("move_down", 30)
	await _wait_transition(im)
	check(scene.map.id == "KA-07", "the bridge leads to the Forbidden Gate")
	await _face_and_press(scene, Vector2i(15, 15), "down", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("thornkeeper_defeated"), "")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 15)), "down")
	await _press_for("move_down", 24)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "walking up to the Thornkeeper starts the boss fight")
	var blog: Array[String] = await _run_battle(scene, im, true)
	check(blog.any(func(l: String) -> bool: return l.begins_with("phase 2")), "the boss reached its last phase")
	check(blog.any(func(l: String) -> bool: return l.begins_with("team reno,lumi")), "Spirit Cyclone was used")
	var first_team := blog.find(blog.filter(func(l: String) -> bool: return l.begins_with("team"))[0]) if blog.any(func(l: String) -> bool: return l.begins_with("team")) else -1
	check(first_team > blog.find("phase 2"), "Spirit Cyclone is only learned in the last phase")
	check(blog.any(func(l: String) -> bool: return l == "thornkeeper_0 guard"), "the Thornkeeper guards in its first phase")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("thornkeeper_defeated") and gs.quest_state("PRO-004") == "rewarded", "P06: Thornkeeper beaten, PRO-004 rewarded")
	check(gs.has_key_item("item_guardian_seed") and int(gs.data["wallet"]["dewdrops"]) == 8, "Guardian Seed and 3 Dewdrops (5 + 3)")
	check(scene.npcs.is_empty(), "the Thornkeeper is gone")
	_milestone(gs, "Thornkeeper beaten")

	# PZ-005: open the gate and cross.
	await _face_and_press(scene, Vector2i(15, 19), "down", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("forbidden_gate_open") and gs.quest_state("PRO-005") == "active", "PZ-005: the gate opens")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 19)), "down")
	await _press_for("move_down", 30)
	await _wait_transition(im)
	check(scene.map.id == "SM-01", "through the gate to Sungai Melor")
	check(im.current_mode() == im.Mode.DIALOGUE, "P07 plays on arrival")
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	for i in 240:
		if tree.current_scene != null and tree.current_scene != scene:
			break
		await tree.process_frame
	check(gs.get_flag("prologue_completed") and gs.get_flag("chapter_01_unlocked"), "prologue complete and Chapter 1 unlocked")
	check(gs.quest_state("PRO-005") == "rewarded", "every prologue quest is finished")
	check(tree.current_scene != null and tree.current_scene.name == "EndOfContent", "the end-of-content screen shows (not a blank screen)")
	check(saves.has_save("auto"), "the game autosaved at the end")
	gs.new_game()
	saves.load_slot("auto")
	check(gs.get_flag("prologue_completed") and gs.data["map_id"] == "SM-01", "Continue resumes in Sungai Melor after the prologue")
	var flags_in_order := ["reno_token_obtained", "lumi_joined", "elder_warning_heard", "bobo_parcel_quest_started", "leafling_tutorial_complete",
		"bobo_parcel_returned", "lantern_obtained", "gate_key_collected", "echo_path_revealed", "root_bridge_restored",
		"thornkeeper_defeated", "forbidden_gate_open", "prologue_completed", "chapter_01_unlocked"]
	check(flags_in_order.all(gs.get_flag), "all 14 required prologue flags are set")
	check(int(gs.data["members"]["reno"]["level"]) == 2 and int(gs.data["members"]["lumi"]["level"]) == 2, "the prologue's 30 XP makes both heroes level 2")
	if is_instance_valid(scene):
		if scene.is_inside_tree():
			root.remove_child(scene)
		scene.free()
	var end_screen := tree.current_scene
	if end_screen:
		root.remove_child(end_screen)
		end_screen.free()
	saves.delete_all()
	_sections_done += 1


func _test_chapter1_a(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	# Levels: XP to reach L is 10*(L-1)^2, with the 7.2 growth table.
	gs.new_game()
	gs.add_member("lumi")
	check(gs.xp_for_level(3) == 40 and gs.xp_for_level(6) == 250, "XP curve is 10*(L-1)^2")
	var ups: Array[String] = gs.gain_xp("reno", 40)
	var r: Dictionary = gs.data["members"]["reno"]
	check(ups.size() == 2 and int(r["level"]) == 3, "40 XP takes Reno from level 1 to 3")
	check([r["max_hp"], r["max_mp"], r["atk"], r["def"], r["mag"], r["res"], r["spd"]] == [54, 18, 18, 11, 8, 10, 14], "Reno Lv3 stats match the growth table")
	gs.gain_xp("lumi", 250)
	var l: Dictionary = gs.data["members"]["lumi"]
	check([l["level"], l["max_hp"], l["max_mp"], l["atk"], l["def"], l["mag"], l["res"], l["spd"]] == [6, 52, 39, 12, 12, 26, 17, 15], "Lumi Lv6 stats match the growth table")
	var old: Dictionary = gs.to_dict()
	old["members"]["reno"] = {"level": 1, "max_hp": 42, "max_mp": 14, "atk": 14, "def": 9, "mag": 6, "res": 8, "spd": 12, "hp": 42, "mp": 14, "xp": 30}
	check(gs.load_from_dict(old).is_empty() and int(gs.data["members"]["reno"]["level"]) == 2, "an older save with 30 XP loads at level 2")

	# Items and the spirit stall.
	gs.new_game()
	gs.add_member("lumi")
	gs.data["members"]["lumi"]["mp"] = 5
	gs.add_item("item_firefly_tea", 1)
	check(gs.use_heal_item("item_firefly_tea") == "" and int(gs.data["members"]["lumi"]["mp"]) == 17, "Firefly Tea restores 12 MP")
	check(gs.use_heal_item("item_kaya_toast") == "None left.", "can't use what you don't have")
	gs.data["wallet"]["dewdrops"] = 3
	var stall := ShopMenu.new()
	root.add_child(stall)
	check(stall.buy("item_firefly_tea") == "Bought a Firefly Tea." and int(gs.data["wallet"]["dewdrops"]) == 1, "buying at a stall takes Dewdrops")
	check(stall.buy("item_starfruit_dumpling") == "Not enough Dewdrops." and gs.item_count("item_starfruit_dumpling") == 0, "a stall won't sell without enough Dewdrops")
	check(stall.buy("item_kaya_toast") == "That's not for sale.", "gift items aren't sold")
	stall.free()

	# PZ-101 rules.
	var jar := CoinJar.new()
	check(jar.piles_needed() == 4 and jar.still_possible(), "the jar holds 200 cents, four piles")
	check(jar.add(50) == "pile", "a single fifty is a pile")
	check(jar.add(20) == "added" and jar.add(20) == "added" and jar.add(20) == "over" and jar.wrong == 1 and jar.pile.is_empty(), "too much tips the pile back with no other penalty")
	check(jar.remaining[20] == 3, "tipped coins go back")
	jar.repour()
	check(jar.piles_done == 0 and jar.remaining[50] == 1, "re-pouring starts again")

	# Integration: the whole of part A.
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "chapter_01_unlocked", "lumi_joined"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	gs.data["wallet"]["dewdrops"] = 8
	gs.set_spawn("SM-01", "start")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	check(im.current_mode() == im.Mode.DIALOGUE, "C00 plays when Chapter 1 starts")
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_started") and gs.quest_state("C01-001") == "active", "C01-001 Unseen begins")
	var woman: Dictionary = scene.npcs.filter(func(n: Dictionary) -> bool: return n["def"]["id"] == "basket_woman")[0]
	await _talk(scene, Vector2i(24, 15), im)
	check(woman["node"].facing == "left", "humans don't turn to look at the spirits")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(12, 12)), "up")
	await _press_for("move_up", 12)
	await _wait(2)
	check(scene.map.id == "SM-01" and im.current_mode() == im.Mode.DIALOGUE, "the sundry shop is shut before Old Kettle's favour")
	await _finish_dialogue(im)

	scene.warp("SM-03", "from_square")
	await _press_for("move_up", 12)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_kopitiam_overheard"), "C01: the train rumour is overheard")
	await _talk(scene, Vector2i(9, 3), im)
	check(gs.get_flag("ch01_visibility_learned") and gs.get_flag("ch01_kettle_favour_asked"), "C01: Old Kettle explains and asks a favour")
	await _talk(scene, Vector2i(9, 3), im, 0)
	await _wait(5)
	check(scene.shop.visible and im.current_mode() == im.Mode.MENU, "Old Kettle's shelf opens as a Dewdrop stall")
	scene.shop.buy("item_moonleaf_bun")
	await _tap("cancel")
	check(not scene.shop.visible and int(gs.data["wallet"]["dewdrops"]) == 7 and gs.item_count("item_moonleaf_bun") == 1, "bought a Moonleaf Bun for 1 Dewdrop")

	scene.warp("SM-04", "from_square")
	await _talk(scene, Vector2i(9, 7), im)
	await _wait(5)
	check(scene.coin_jar.visible, "PZ-101: the Coin Jar opens")
	scene.coin_jar.choose(50)
	scene.coin_jar.choose(50)
	check(scene.coin_jar.msg_label.text.contains("no 50"), "no coins left of a kind is explained")
	for c in [20, 20, 10, 20, 10, 10, 5, 5, 10, 10, 10, 10, 5, 1, 1, 1, 1]:
		scene.coin_jar.choose(c)
	check(not gs.get_flag("ch01_coin_jar_solved"), "")
	scene.coin_jar.choose(1)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_coin_jar_solved") and gs.get_flag("pz101_coin_jar_solved"), "C02: the coins are sorted")

	scene.warp("SM-03", "from_square")
	await _talk(scene, Vector2i(9, 3), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("C01-001") == "rewarded" and int(gs.data["wallet"]["dewdrops"]) == 10 and gs.item_count("item_kaya_toast") == 2, "C01-001 done: 3 Dewdrops and 2 Kaya Toast")
	check(gs.quest_state("C01-002") == "active", "C01-002 The Bus begins")
	_milestone(gs, "kettle tip")

	scene.warp("SM-05", "from_village")
	await _talk(scene, Vector2i(17, 7), im, 0)
	await _wait(3)
	check(scene.map.id == "SM-05" and not gs.get_flag("ch01_bus_boarded"), "PZ-102: following the wrong passenger misses the bus, no penalty")
	await _talk(scene, Vector2i(17, 7), im, 1)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "TR-01" and gs.get_flag("pz102_bus_boarded"), "PZ-102: the man with the rambutans gets us on")
	await _finish_dialogue(im)
	await _wait(3)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BS-01", "C03: the bus arrives at Bandar Senja")
	await _finish_dialogue(im)
	await _wait(5)
	await _finish_dialogue(im)
	await _wait(5)
	check(gs.get_flag("ch01_arrived_bandar_senja") and gs.quest_state("C01-002") in ["completed", "rewarded"], "C01-002 done")
	gs.new_game()
	saves.load_slot("auto")
	check(gs.data["map_id"] == "BS-01" and gs.get_flag("ch01_arrived_bandar_senja"), "the arrival at Bandar Senja is autosaved")

	# Optional postcard on the jetty.
	scene.warp("SM-02", "from_village")
	var before: int = scene.npcs.size()
	await _face_and_press(scene, Vector2i(26, 5), "right", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_postcard") and gs.quest_state("C01-S01") == "active", "C01-S01: the postcard is picked up")
	check(scene.npcs.size() == before - 1, "the postcard is gone from the jetty")
	root.remove_child(scene)
	scene.free()
	saves.delete_all()
	_sections_done += 1


## The first enabled menu value from prefs; else the first enabled entry
## (target menus), else guard.
func _menu_pick(battle: Battle, prefs: Array) -> Variant:
	for want: Variant in prefs:
		for it: Dictionary in battle._menu_items:
			if it["enabled"] and it["value"] == want:
				return want
	if battle._menu_items.any(func(it: Dictionary) -> bool: return it["value"] == "attack"):
		return "guard"
	for it: Dictionary in battle._menu_items:
		if it["enabled"]:
			return it["value"]
	return null


func _test_statuses() -> void:
	var a := Combat.make_unit("a", "A", "hero", {"max_hp": 40, "atk": 10, "def": 5, "mag": 5, "res": 5, "spd": 12})
	var b := Combat.make_unit("b", "B", "enemy", {"max_hp": 40, "atk": 10, "def": 5, "mag": 5, "res": 5, "spd": 10})
	var c := Combat.make_unit("c", "C", "enemy", {"max_hp": 40, "atk": 10, "def": 5, "mag": 5, "res": 5, "spd": 4})
	var cb := Combat.new()
	cb.setup([a], [b, c])
	check(cb.begin_round() == ["a", "b", "c"], "SPD order")
	Combat.add_status(a, "slow", 3, true)
	check(cb.begin_round() == ["b", "a", "c"], "Slow cuts SPD by 30% (12 -> 8.4)")
	c["haste"] = true
	check(cb.begin_round()[0] == "c" and not c["haste"], "Green Light: a hastened ally acts first next round, once")
	Combat.tick_status(a)
	check(int(a["status"]["slow"]) == 3, "a self-applied status doesn't count down on the turn it lands")
	Combat.tick_status(a)
	Combat.tick_status(a)
	Combat.tick_status(a)
	check(not Combat.has_status(a, "slow"), "Slow lasts 3 turns")
	b["immune"] = ["slow"]
	check(not Combat.add_status(b, "slow", 3) and not Combat.has_status(b, "slow"), "immune enemies ignore Slow")
	var plain := cb.hit(b, a, "physical", 1.0, "miss")
	a["hp"] = 40
	Combat.add_status(a, "shielded", 2)
	check(plain == 15 and cb.hit(b, a, "physical", 1.0, "miss") == 11, "Shielded takes 30% off (15 -> 10.5, rounded to 11)")
	a["guarding"] = true
	check(cb.hit(b, a, "physical", 1.0, "miss") == 5, "Guard and Shielded stack (15 x 0.5 x 0.7 = 5.25 -> 5)")
	_sections_done += 1


func _test_chapter1_b(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_started", "ch01_visibility_learned", "ch01_coin_jar_solved",
			"ch01_kettle_tip_heard", "ch01_bus_boarded", "ch01_arrived_bandar_senja", "ch01_postcard_found"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	gs.add_key_item("item_postcard")
	gs.gain_xp("reno", 40)
	gs.gain_xp("lumi", 40)
	gs.data["wallet"]["dewdrops"] = 10
	gs.set_spawn("BS-01", "from_bus")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	check(im.current_mode() == im.Mode.EXPLORE, "no arrival scene again once arrived")

	# Mr Slot takes the postcard (C01-S01).
	await _talk(scene, Vector2i(24, 12), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_postcard_posted") and not gs.has_key_item("item_postcard") and gs.quest_state("C01-S01") == "rewarded" and int(gs.data["wallet"]["dewdrops"]) == 12, "C01-S01: Mr Slot posts the postcard, 2 Dewdrops")

	# C04: overhear Pak Darus, meet the Clockkeeper.
	scene.warp("BS-02", "from_forecourt")
	await _press_for("move_up", 30)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_darus_overheard"), "C04: Pak Darus is overheard")
	await _talk(scene, Vector2i(20, 2), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("C01-003") == "active", "C01-003: the parcels quest begins")

	# C05: the goods shed. Root Grip pulls crates one tile.
	scene.warp("BS-03", "from_forecourt")
	await _wait(2)
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(11, 9), "left", im)
	check(scene.map.movables.has(Vector2i(11, 9)) and _cell_of(scene.leader()) == Vector2i(12, 9), "Root Grip pulls the crate toward Reno, who steps back")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(9, 5), "right", im)
	check(im.current_mode() == im.Mode.DIALOGUE and scene.map.movables.has(Vector2i(10, 5)), "only Reno can Root Grip")
	await _finish_dialogue(im)
	await _tap("swap")
	await _face_and_press(scene, Vector2i(9, 5), "right", im)
	check(scene.map.movables.has(Vector2i(9, 5)), "the second crate is pulled out of the aisle")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(10, 13)), "up")
	await _press_for("move_up", 170)
	check(_cell_of(scene.leader()).y == 3, "PZ-103: the aisle to the parcel shelf is clear")
	await _tap("confirm")
	await _finish_dialogue(im)
	check(gs.has_key_item("item_parcel_a") and gs.get_flag("pz103_crates_solved"), "C05: Parcel A found")
	await _face_and_press(scene, Vector2i(33, 22), "right", im)
	await _finish_dialogue(im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.movables.has(Vector2i(10, 9)) and scene.map.movables.has(Vector2i(10, 5)), "the reset lever puts the crates back")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(28, 3), "up", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_dead_letter_tag_read") and gs.quest_state("C01-S02") in ["completed", "rewarded"], "C01-S02: Lumi reads the 1951 tag")
	await _tap("swap")
	# A Dust Bundle: telegraphs Roll Over, and the first Guardian Bloom test.
	gs.set_flag("ch01_guardian_bloom_learned")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(21, 16)), "up")
	await _press_for("move_up", 30)
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "attack"])
	await _wait(3)
	await _finish_dialogue(im)
	check(blog.any(func(l: String) -> bool: return l.contains("telegraph Roll Over")), "Dust Bundle telegraphs Roll Over")
	check(blog.any(func(l: String) -> bool: return l.begins_with("bloom perfect,perfect 15%")), "Guardian Bloom: two cues, 15% heal")
	check(gs.get_flag("bs03_dust_a_beaten"), "the Dust Bundle is beaten")
	gs.set_flag("ch01_guardian_bloom_learned", false)

	# C06: Memory Touch on the smudged label, then the right signboard.
	scene.warp("BS-04", "from_forecourt")
	await _face_and_press(scene, Vector2i(4, 14), "up", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("ch01_label_read"), "Reno can't read the smudged label")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(4, 14), "up", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_label_read") and gs.has_key_item("item_label_fragments"), "C06: Memory Touch gives the fragments")
	await _face_and_press(scene, Vector2i(9, 10), "up", im)
	await _finish_dialogue(im)
	check(not gs.has_key_item("item_parcel_c"), "PZ-105: the wrong shop just gets a funny line")
	await _face_and_press(scene, Vector2i(19, 10), "up", im)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_parcel_c") and gs.get_flag("pz105_label_solved"), "C06: Parcel C is at the bicycle repairer's")
	await _tap("swap")

	# Place: only while Pak Darus looks away.
	scene.warp("BS-02", "from_forecourt")
	scene.set_loop_step("pak_darus", 0)
	await _face_and_press(scene, Vector2i(6, 8), "up", im)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_parcel_a") and not gs.get_flag("ch01_parcel_a_returned"), "Place waits while the stationmaster is looking")
	scene.set_loop_step("pak_darus", 1)
	await _face_and_press(scene, Vector2i(6, 8), "up", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_parcel_a_returned") and gs.get_flag("ch01_parcel_r1") and not gs.get_flag("ch01_parcel_r2"), "Parcel A placed: first reaction")
	scene.set_loop_step("pak_darus", 1)
	await _face_and_press(scene, Vector2i(6, 8), "up", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_parcel_c_returned") and gs.get_flag("ch01_parcel_r2") and not gs.get_flag("ch01_parcels_returned"), "Parcel C placed: second reaction")
	_milestone(gs, "two parcels returned")

	# C07: the rail yard, signal levers and the Monarch.
	scene.warp("BS-05", "from_hall")
	await _wait(2)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("C01-004") == "active", "C01-004 begins in the rail yard")
	await _face_and_press(scene, Vector2i(10, 13), "up", im)
	await _finish_dialogue(im)
	check(gs.get_flag("bs05_lever_1") and scene.map.tile_name(Vector2i(10, 12)) == "lever_on", "a lever flips and shows it")
	await _face_and_press(scene, Vector2i(4, 8), "left", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("pz104_signals_solved"), "PZ-104: a wrong route rolls the handcar back")
	await _face_and_press(scene, Vector2i(22, 13), "up", im)
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(4, 8), "left", im)
	await _finish_dialogue(im)
	check(gs.get_flag("pz104_signals_solved") and scene.map.is_walkable(Vector2i(38, 6)), "PZ-104: switched, straight, switched opens the siding")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(38, 8)), "up")
	await _press_for("move_up", 50)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Paper Moth Monarch fight starts")
	blog = await _run_battle_with(scene, im, ["team:spirit_cyclone", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon ticket_moth")), "below half HP the Monarch summons a Ticket Moth")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_moth_monarch_defeated") and gs.has_key_item("item_parcel_b") and gs.has_key_item("equip_moth_wing_charm"), "BOSS-101 beaten: Parcel B and the charm")
	check(gs.get_flag("ch01_guardian_bloom_learned") and gs.quest_state("C01-004") in ["completed", "rewarded"], "Guardian Bloom learned, C01-004 done")
	check(gs.equip_bonus("lumi").get("spd", 0) == 2, "the Moth-Wing Charm gives Lumi SPD +2")

	# Last parcel, then the tickets.
	scene.warp("BS-02", "from_yard")
	scene.set_loop_step("pak_darus", 1)
	await _face_and_press(scene, Vector2i(6, 8), "up", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_parcels_returned") and gs.quest_state("C01-003") == "rewarded" and gs.item_count("item_moonleaf_bun") == 2, "C01-003 done: all three parcels back, 2 Moonleaf Buns")
	await _talk(scene, Vector2i(20, 2), im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_veil_ticket") and gs.get_flag("ch01_tickets_obtained"), "C08: the Clockkeeper stamps two Veil tickets")
	_milestone(gs, "tickets")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 1)), "up")
	await _press_for("move_up", 12)
	await _wait_transition(im)
	check(scene.map.id == "BS-06", "Platform 2 opens with the tickets")
	root.remove_child(scene)
	scene.free()
	saves.delete_all()
	_sections_done += 1


func _run_battle_with(scene: Node, im: Node, prefs: Array) -> Array[String]:
	var out: Array[String] = []
	var battle: Battle = null
	for i in 200:
		for c in scene.get_children():
			if c is Battle:
				battle = c
		if battle:
			break
		await tree.process_frame
	if battle == null:
		return out
	var used := {}
	for i in 8000:
		if not is_instance_valid(battle) or im.current_mode() != im.Mode.BATTLE:
			break
		out.assign(battle.battle_log)
		if battle._menu_open:
			# Each team skill in prefs is tried once, then plain attacks.
			var p: Array = prefs.filter(func(v: String) -> bool: return not used.has(v) or v == "attack")
			var v: Variant = _menu_pick(battle, p)
			if str(v).begins_with("team:guardian"):
				used[v] = true
			battle._menu_done.emit(v)
		await tree.process_frame
	return out


func _test_chapter1_c(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_started", "ch01_arrived_bandar_senja", "ch01_parcels_quest_started",
			"ch01_parcels_returned", "ch01_moth_monarch_defeated", "ch01_guardian_bloom_learned", "ch01_tickets_obtained", "lantern_obtained"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	for k in ["item_veil_ticket", "item_blank_punched_ticket", "item_lantern", "equip_moth_wing_charm"]:
		gs.add_key_item(k)
	gs.gain_xp("reno", 160)
	gs.gain_xp("lumi", 160)
	gs.set_spawn("BS-02", "from_platform")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 1)), "up")
	await _press_for("move_up", 12)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BS-06" and im.current_mode() == im.Mode.DIALOGUE, "C08 plays on Platform 2")
	await _finish_dialogue(im)
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "VT-01" and gs.get_flag("ch01_veil_train_entered"), "C08: aboard the Veil train")
	var auto: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saves.save_dir + "autosave.json"))
	check(auto["state"]["map_id"] == "BS-06", "autosave before departure, none inside the train")
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.quest_state("C01-006") == "active", "C01-006 Tickets, Please begins")

	# VT-01: Memory Moths carry the first slip.
	await _talk(scene, Vector2i(11, 4), im, 0)
	check(not gs.get_flag("ch01_passenger_1_restored"), "no slip yet: nothing to give")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(21, 6)), "right")
	await _press_for("move_right", 30)
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:spirit_cyclone", "attack"])
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.has_key_item("item_slip_chalk"), "the Memory Moths drop the chalk slip")
	await _talk(scene, Vector2i(11, 4), im, 0)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_passenger_1_restored") and not gs.has_key_item("item_slip_chalk"), "PZ-107: the teacher gets her destination back")

	# VT-02: the dining car.
	scene.warp("VT-02", "from_third")
	await _wait(2)
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(28, 6)), "right")
	await _press_for("move_right", 30)
	blog = await _run_battle_with(scene, im, ["team:spirit_cyclone", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("dodge")), "the dining car fight ran")
	await _wait(3)
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(15, 4), im, 2)
	check(not gs.get_flag("ch01_passenger_2_restored"), "PZ-107: a wrong slip doesn't fit, no penalty")
	await _talk(scene, Vector2i(15, 4), im, 1)
	check(gs.get_flag("ch01_passenger_2_restored"), "PZ-107: the grandmother remembers her grandson")

	# VT-03: the roof, Leaf Leap and Gentle Float.
	scene.warp("VT-03", "from_dining")
	await _wait(2)
	await _finish_dialogue(im)
	for x in [11, 21]:
		scene.leader().place_at(MapData.cell_to_feet(Vector2i(x, 5)), "right")
		await tree.physics_frame
		await _tap("confirm")
		await tree.create_timer(0.7).timeout
	check(_cell_of(scene.leader()) == Vector2i(24, 5), "PZ-106: two Leaf Leaps across the carriage gaps")
	await _press_for("move_right", 100)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_gentle_float_unlocked"), "Gentle Float unlocked on the roof")
	await _face_and_press(scene, Vector2i(31, 5), "right", im)
	check(im.current_mode() == im.Mode.DIALOGUE, "the wide gap is too far for Reno")
	await _finish_dialogue(im)
	await _tap("swap")
	await _face_and_press(scene, Vector2i(31, 5), "right", im)
	await tree.create_timer(0.7).timeout
	check(_cell_of(scene.leader()) == Vector2i(36, 5) and scene.leader().member_id == "lumi", "PZ-106: Gentle Float crosses four tiles")
	await _tap("swap")
	await _talk(scene, Vector2i(42, 4), im)
	check(gs.has_key_item("item_slip_cloth"), "the cloth slip is on the roof")
	scene.warp("VT-02", "from_roof")
	await _talk(scene, Vector2i(23, 7), im, 2)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_passenger_3_restored") and gs.get_flag("ch01_guards_van_unlocked"), "three destinations back: the Guard's Van opens")
	check(gs.quest_state("C01-006") in ["completed", "rewarded"] and gs.quest_state("C01-007") == "active", "C01-006 done, C01-007 begins")

	# VT-04: the optional lantern keyhole and Lost Luggage.
	scene.warp("VT-04", "from_roof")
	await _face_and_press(scene, Vector2i(17, 4), "up", im)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(scene.npcs.any(func(n: Dictionary) -> bool: return n["def"]["id"] == "lost_luggage"), "PZ-108: the lantern reveals the Lost Luggage")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(19, 7)), "up")
	await _press_for("move_up", 20)
	await _finish_dialogue(im)
	blog = await _run_battle_with(scene, im, ["attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("telegraph Snap Shut")), "Lost Luggage telegraphs Snap Shut")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_lost_luggage_defeated") and gs.equip_bonus("lumi").get("mag", 0) == 3, "C01-S03: Brass Lantern Hook (MAG +3)")

	# VT-05: the Forgotten Conductor.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(37, 6)), "right")
	await _press_for("move_right", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "VT-05", "into the Guard's Van")
	auto = JSON.parse_string(FileAccess.get_file_as_string(saves.save_dir + "autosave.json"))
	check(auto["state"]["map_id"] == "VT-05", "autosave at the Guard's Van door (pre-boss)")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(17, 7)), "right")
	await _press_for("move_right", 30)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Conductor fight starts")
	var battle: Battle = null
	for c in scene.get_children():
		if c is Battle:
			battle = c
	blog = await _run_battle_with(scene, im, ["attack"])
	check(blog.any(func(l: String) -> bool: return l == "phase 2"), "the Conductor reaches Final Stop")
	check(blog.any(func(l: String) -> bool: return l.contains("telegraph Final Stop")), "Final Stop is announced a round ahead")
	check(blog.any(func(l: String) -> bool: return l.contains("status fog")), "Where Are You Going? fogs a hero")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch01_conductor_calmed") and not gs.has_key_item("item_blank_punched_ticket"), "C10: the Conductor is calmed at the story threshold")
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "VT-06", "C11: the Veil Halt")
	await _finish_dialogue(im)
	await _wait(5)
	await _wait_transition(im)
	await _wait(5)
	check(scene.map.id == "BS-06", "dawn at Platform 2")
	await _finish_dialogue(im)
	await _wait(3)
	await _finish_dialogue(im)
	for i in 240:
		if tree.current_scene != null and tree.current_scene != scene:
			break
		await tree.process_frame
	var need := ["ch01_veil_train_entered", "ch01_gentle_float_unlocked", "ch01_passenger_1_restored", "ch01_passenger_2_restored", "ch01_passenger_3_restored",
		"ch01_guards_van_unlocked", "ch01_conductor_calmed", "ch01_lumi_origin_glimpsed", "river_route_unlocked", "chapter_01_completed", "chapter_02_unlocked"]
	check(need.all(gs.get_flag), "every end-of-chapter flag is set")
	check(gs.has_key_item("item_conductors_whistle"), "the Conductor's Whistle")
	check(["C01-005", "C01-006", "C01-007", "C01-008"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C01-005 to C01-008 are finished")
	check(tree.current_scene != null and tree.current_scene.name == "EndOfContent", "the Chapter 1 complete screen shows")
	gs.new_game()
	saves.load_slot("auto")
	check(gs.get_flag("chapter_01_completed") and gs.data["map_id"] == "BS-06", "the chapter ending is autosaved")
	if is_instance_valid(scene):
		if scene.is_inside_tree():
			root.remove_child(scene)
		scene.free()
	var end_screen := tree.current_scene
	if end_screen:
		root.remove_child(end_screen)
		end_screen.free()
	saves.delete_all()
	_sections_done += 1


func _test_chapter2_a(gs: Node, im: Node) -> void:
	# Soaked: physical hits treat the target's DEF as 30% lower.
	var hit_by := Combat.make_unit("h", "H", "enemy", {"max_hp": 40, "atk": 10, "def": 5, "mag": 5, "res": 5, "spd": 5})
	var wet := Combat.make_unit("w", "W", "hero", {"max_hp": 40, "atk": 5, "def": 10, "mag": 5, "res": 10, "spd": 5})
	check(Combat.base_damage("physical", hit_by, wet) == 10, "dry: 2*10 - 10")
	Combat.add_status(wet, "soaked", 2)
	check(Combat.base_damage("physical", hit_by, wet) == 13, "Soaked: DEF 10 counts as 7 for physical hits")
	check(Combat.base_damage("magical", hit_by, wet) == 1, "Soaked doesn't touch RES")

	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_guardian_bloom_learned", "ch01_gentle_float_unlocked",
			"chapter_01_completed", "chapter_02_unlocked", "river_route_unlocked", "ch01_arrived_bandar_senja"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	for k in ["item_conductors_whistle", "item_lantern"]:
		gs.add_key_item(k)
	gs.gain_xp("reno", 300)
	gs.gain_xp("lumi", 300)
	gs.set_spawn("BS-01", "from_river")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)

	# BS-01's south road leads down to the river.
	await _press_for("move_down", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-01" and im.current_mode() == im.Mode.DIALOGUE, "C2-01 plays at Senja River Landing")
	await _finish_dialogue(im)
	await _wait(3)
	check(gs.get_flag("ch02_started") and gs.get_flag("ch02_song_quest_started"), "the Kingfisher sisters ask for help")
	check(gs.quest_state("C02-001") in ["completed", "rewarded"] and gs.quest_state("C02-002") == "active", "C02-001 done, C02-002 The Tide Song begins")
	check(scene._tint != null and scene._tint.color != Color.WHITE, "the landing is dark until the Undertow is calmed")
	var auto: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saves.save_dir + "autosave.json"))
	check(auto["state"]["map_id"] == "RV-01", "autosave on arrival at the river")

	# RV-02: PZ-201, the mangrove tides.
	scene.warp("RV-02", "from_landing")
	await _wait(2)
	await _finish_dialogue(im)
	check(scene._tint == null or scene._tint.color == Color.WHITE, "the tint stays on the landing")
	check(scene.map.is_walkable(Vector2i(12, 14)) and not scene.map.is_walkable(Vector2i(18, 14)), "low tide: mud path, deep channel")
	await _talk(scene, Vector2i(9, 12), im)
	check(gs.get_flag("ch02_tide_call_learned") and gs.get_flag("rv02_tide_high"), "Tide Call learned at the first marker; the tide rises")
	check(not scene.map.is_walkable(Vector2i(12, 14)) and scene.map.is_walkable(Vector2i(18, 14)), "high tide: mud floods, logs float")
	await _talk(scene, Vector2i(9, 12), im)
	check(not gs.get_flag("rv02_tide_high") and scene.map.is_walkable(Vector2i(12, 14)), "the whistle sends the tide back down")
	# Flooding the mud under the party puts them back on dry land.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(12, 14)), "right")
	await _wait(3)
	gs.set_flag("rv02_tide_high")
	await _wait(2)
	check(scene.map.is_walkable(_cell_of(scene.leader())), "a rising tide never strands the party in deep water")
	gs.set_flag("rv02_tide_high", false)
	await _wait(2)

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(10, 14)), "right")
	await _press_for("move_right", 90)
	check(_cell_of(scene.leader()) == Vector2i(16, 14), "low tide: across the mud to the first islet, stopped by the channel")
	await _talk(scene, Vector2i(15, 12), im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(16, 14)), "right")
	await _press_for("move_right", 160)
	check(_cell_of(scene.leader()) == Vector2i(24, 14), "high tide: over the logs to the second islet, stopped by flooded mud")
	await _talk(scene, Vector2i(24, 12), im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 14)), "right")
	await _press_for("move_right", 90)
	await _wait(2)
	check(im.current_mode() == im.Mode.DIALOGUE, "reaching Pak Lumpur's island plays a line")
	await _finish_dialogue(im)
	check(gs.get_flag("pz201_mangrove_crossed"), "PZ-201 solved")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(44, 14)), "right")
	await _press_for("move_right", 60)
	await _wait(2)
	check(scene.map.id == "RV-02" and im.current_mode() == im.Mode.DIALOGUE, "Pak Lumpur won't let us leave without the verse")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(36, 14), im)
	check(gs.has_key_item("item_tide_verse_1") and gs.get_flag("ch02_verse_1"), "C2-02: Pak Lumpur sings the first verse")

	# RV-03: Kampung Air, Old Pole and Ripple Echo.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(45, 14)), "right")
	await _press_for("move_right", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-03", "east through the roots to Kampung Air")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(21, 6), im)
	check(not gs.get_flag("ch02_verse_2"), "Old Pole only remembers a feeling for Reno")
	await _tap("swap")
	await _talk(scene, Vector2i(21, 6), im)
	check(gs.has_key_item("item_tide_verse_2") and gs.get_flag("ch02_ripple_learned"), "C2-03: Lumi's Memory Touch finds verse 2 and Ripple Echo")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(8, 21), "left", im)
	await _wait(2)
	check(im.current_mode() == im.Mode.DIALOGUE, "Mak Siput's stall")
	await _finish_dialogue(im)
	await _wait(3)
	check(scene.shop.visible, "her stall opens")
	scene.shop.close()
	await _wait(2)

	# Back in the mangroves: Ripple Echo hits both Silt Wisps.
	scene.warp("RV-02", "from_village")
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(31, 17)), "right")
	await _press_for("move_right", 30)
	var blog: Array[String] = await _run_battle_with(scene, im, ["skill", "ripple_echo", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("lumi") and l.ends_with("(all)")), "Ripple Echo hits every enemy")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("rv02_wisps_beaten"), "the Silt Wisps settle")
	check(gs.quest_state("C02-002") == "active", "two verses so far; the third is in part B")

	scene.queue_free()
	await _wait(2)
	_sections_done += 1


func _test_chapter2_b(gs: Node, im: Node) -> void:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_guardian_bloom_learned", "ch01_gentle_float_unlocked",
			"chapter_01_completed", "chapter_02_unlocked", "ch02_started", "ch02_song_quest_started", "ch02_tide_call_learned", "ch02_mangrove_seen",
			"pz201_mangrove_crossed", "ch02_verse_1", "ch02_village_seen", "ch02_verse_2", "ch02_ripple_learned"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	for k in ["item_conductors_whistle", "item_lantern", "item_tide_verse_1", "item_tide_verse_2"]:
		gs.add_key_item(k)
	gs.gain_xp("reno", 420)
	gs.gain_xp("lumi", 420)
	gs.set_spawn("RV-01", "from_mangrove")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)

	# C02-S01 starts by overhearing the fisherman.
	await _talk(scene, Vector2i(19, 21), im)
	check(gs.get_flag("ch02_lost_things_heard") and gs.quest_state("C02-S01") == "active", "C02-S01: the river is keeping lost things")
	scene.warp("RV-02", "from_landing")
	await _wait(3)
	await _talk(scene, Vector2i(4, 20), im)
	check(gs.has_key_item("item_lost_toy_boat"), "the toy boat in the mangrove roots")
	scene.warp("RV-03", "from_mangrove")
	await _wait(3)
	await _talk(scene, Vector2i(31, 22), im)
	check(gs.has_key_item("item_lost_bell"), "the bicycle bell on a Kampung Air stilt")

	# RV-04: PZ-202, crates and tides.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(37, 14)), "right")
	await _press_for("move_right", 40)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-04" and im.current_mode() == im.Mode.DIALOGUE, "C2-04 at the Sunken Jetty")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(10, 19), im)
	check(gs.has_key_item("item_lost_ring"), "the wedding ring in the jetty mud")
	check(not scene.map.is_walkable(Vector2i(22, 8)), "low tide: the far deck is out of reach")
	for y in range(12, 7, -1):
		await _face_and_press(scene, Vector2i(20, y), "down", im)
		await _wait(2)
	for y in range(14, 7, -1):
		await _face_and_press(scene, Vector2i(21, y), "down", im)
		await _wait(2)
	check(scene.map.movables.has(Vector2i(20, 8)) and scene.map.movables.has(Vector2i(21, 8)), "PZ-202: Root Grip lines two crates up in the gap")
	await _talk(scene, Vector2i(5, 6), im)
	check(gs.get_flag("rv04_tide_high"), "the jetty's tide marker raises the tide")
	check(scene.map.tile_name(Vector2i(20, 8)) == "crate_float" and scene.map.is_walkable(Vector2i(21, 8)) and scene.map.is_walkable(Vector2i(22, 8)),
		"high tide: the crates float and the deck is level")
	await _face_and_press(scene, Vector2i(19, 8), "right", im)
	await _wait(2)
	check(im.current_mode() == im.Mode.EXPLORE, "a floating crate can't be gripped")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(19, 8)), "right")
	await _press_for("move_right", 200)
	await _wait(2)
	if im.current_mode() == im.Mode.BATTLE:
		await _run_battle_with(scene, im, ["skill", "ripple_echo", "attack"])
		await _wait(3)
		await _finish_dialogue(im)
		await _press_for("move_right", 120)
		await _wait(2)
	await _finish_dialogue(im)
	check(gs.get_flag("pz202_jetty_crossed"), "PZ-202 solved: into the bell house")

	# BOSS-201: the Barnacle Bell.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(35, 7)), "right")
	await _press_for("move_right", 40)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Barnacle Bell fight starts")
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon rust_crab")), "below half HP the Bell calls a Rust Crab")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait(3)
	check(gs.get_flag("ch02_bell_quieted") and gs.has_key_item("item_tide_verse_3"), "C2-04: the third verse")
	check(gs.equip_bonus("reno").get("def", 0) == 3, "the Soggy Bell Clapper: Reno DEF +3")
	check(gs.quest_state("C02-002") in ["completed", "rewarded"], "C02-002 The Tide Song is complete")
	var auto: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saves.save_dir + "autosave.json"))
	check(auto["state"]["flags"].get("ch02_bell_quieted", false), "autosave after the Barnacle Bell")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(36, 12)), "down")
	await _press_for("move_down", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-03", "the skiff goes back to Kampung Air")

	# Things the River Kept: back at the landing, while the fisherman looks away.
	scene.warp("RV-01", "from_mangrove")
	await _wait(3)
	var returned := 0
	for i in 600:
		if returned == 3:
			break
		var fisher: Dictionary = scene._npc_by_id("fisherman")
		if not fisher.is_empty() and fisher["node"].facing != "left":
			await _face_and_press(scene, Vector2i(18, 20), "down", im)
			await _finish_dialogue(im)
			returned = int(gs.get_flag("ch02_boat_returned")) + int(gs.get_flag("ch02_bell_returned")) + int(gs.get_flag("ch02_ring_returned"))
		await tree.process_frame
	check(gs.get_flag("ch02_lost_things_returned") and gs.quest_state("C02-S01") in ["completed", "rewarded"], "C02-S01: three lost things go home")

	# C2-05: the Tide Song calls the Veil boat.
	await _talk(scene, Vector2i(23, 14), im)
	await _wait(3)
	check(gs.get_flag("pz203_song_sung") and gs.get_flag("ch02_boat_called"), "C2-05: the Tide Song calls the Veil boat")
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-05", "the boat sinks to the Drowned Crossing")
	auto = JSON.parse_string(FileAccess.get_file_as_string(saves.save_dir + "autosave.json"))
	check(auto["state"]["map_id"] == "RV-01" and auto["state"]["flags"].get("ch02_boat_called", false), "autosave before boarding, none at the boss")
	await _finish_dialogue(im)

	# BOSS-202: the Undertow.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 12)), "up")
	await _press_for("move_up", 40)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Undertow fight starts")
	blog = await _run_battle_with(scene, im, ["attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("telegraph Whirlpool")), "Whirlpool is announced a round ahead")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch02_undertow_calmed"), "C2-07: the Undertow is calmed at the story threshold")
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-06", "C2-08: Nenek Arus's pool")
	await _finish_dialogue(im)
	check(gs.has_key_item("item_tide_pearl") and gs.get_flag("ch02_name_cut_learned"), "Nenek Arus: a name cut out, and the Tide Pearl")
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "RV-01" and scene._tint.color == Color.WHITE, "C2-09: morning on the river")
	await _finish_dialogue(im)
	for i in 240:
		if tree.current_scene != null and tree.current_scene != scene:
			break
		await tree.process_frame
	var need := ["ch02_tide_song_complete", "ch02_boat_called", "ch02_undertow_calmed", "ch02_name_cut_learned", "bandar_kencana_route_unlocked",
		"chapter_02_completed", "chapter_03_unlocked"]
	check(need.all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C02-002", "C02-003", "C02-004"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]),
		"C02-002 to C02-004 are finished")
	check(tree.current_scene != null and tree.current_scene.name == "EndOfContent", "the Chapter 2 complete screen shows")
	gs.new_game()
	saves.load_slot("auto")
	check(gs.get_flag("chapter_02_completed") and gs.data["map_id"] == "RV-01", "the chapter ending is autosaved")
	if is_instance_valid(scene):
		if scene.is_inside_tree():
			root.remove_child(scene)
		scene.free()
	var end_screen := tree.current_scene
	if end_screen:
		root.remove_child(end_screen)
		end_screen.free()
	saves.delete_all()
	_sections_done += 1


func _test_chapter3(gs: Node, im: Node) -> void:
	# Party rules: three fight, new members join at the party's level, old saves gain new companions.
	gs.new_game()
	gs.add_member("lumi")
	gs.gain_xp("reno", 500)
	gs.gain_xp("lumi", 300)
	check(gs.add_member("elias") and int(gs.data["members"]["elias"]["xp"]) == 400 and int(gs.data["members"]["elias"]["level"]) == 7, "Elias joins at the party's average XP (level 7)")
	check(gs.active_party() == ["reno", "lumi", "elias"] and not gs.walks("elias") and gs.walks("lumi"), "three active heroes; companions don't walk the map")
	gs.move_to_front("elias")
	check(gs.party()[0] == "elias", "a member can be moved to the front")
	var old: Dictionary = gs.to_dict()
	old["members"].erase("elias")
	old["party"] = ["reno", "lumi"]
	check(gs.load_from_dict(old).is_empty() and gs.data["members"].has("elias"), "older saves gain the new companions' stats")

	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_guardian_bloom_learned", "ch01_gentle_float_unlocked",
			"chapter_01_completed", "chapter_02_unlocked", "ch02_started", "ch02_undertow_calmed", "ch02_ripple_learned", "chapter_02_completed", "chapter_03_unlocked"]:
		gs.set_flag(f)
	gs.add_member("lumi")
	gs.gain_xp("reno", 640)
	gs.gain_xp("lumi", 640)
	gs.set_spawn("RV-01", "from_kencana")
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)

	# C3-00: the paper barge.
	await _face_and_press(scene, Vector2i(21, 22), "down", im)
	await _finish_dialogue(im)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BK-01" and gs.get_flag("ch03_started"), "C3-00: the paper barge to Bandar Kencana")
	await _finish_dialogue(im)
	check(gs.get_flag("ch03_wharf_seen") and gs.quest_state("C03-001") == "active", "C3-01: a town forgetting its name")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(2, 14)), "left")
	await _press_for("move_left", 30)
	await _wait(2)
	check(scene.map.id == "BK-01" and im.current_mode() == im.Mode.DIALOGUE, "the Veil crack isn't open yet")
	await _finish_dialogue(im)

	# C3-02: Elias in the radio.
	scene.warp("BK-02", "from_wharf")
	await _wait(3)
	await _talk(scene, Vector2i(12, 2), im)
	check(gs.get_flag("ch03_valve_needed") and not gs.has_member("elias"), "a voice in the radio needs a valve")
	scene.warp("BK-03", "from_wharf")
	await _wait(3)
	await _talk(scene, Vector2i(16, 3), im)
	check(gs.has_key_item("item_glass_valve"), "the spare valve in the photographer's desk")
	scene.warp("BK-02", "from_wharf")
	await _wait(3)
	await _talk(scene, Vector2i(12, 2), im)
	check(gs.has_member("elias") and gs.get_flag("ch03_elias_joined") and not gs.has_key_item("item_glass_valve"), "C3-02: Elias joins")
	check(not scene.members.has("elias"), "Elias rides along without walking the map")

	# PZ-301: the photographs.
	scene.warp("BK-03", "from_wharf")
	await _wait(3)
	await _talk(scene, Vector2i(4, 1), im)
	check(not gs.get_flag("ch03_photo_1"), "Reno can't read the photographs")
	await _tap("swap")
	await _talk(scene, Vector2i(4, 1), im, 1)
	check(not gs.get_flag("ch03_photo_1"), "PZ-301: a wrong caption slides off")
	await _talk(scene, Vector2i(4, 1), im, 0)
	await _talk(scene, Vector2i(8, 1), im, 1)
	await _talk(scene, Vector2i(12, 1), im, 2)
	check(gs.get_flag("ch03_photos_restored") and gs.quest_state("C03-002") in ["completed", "rewarded"], "PZ-301: three captions restore the human town's memory")
	await _tap("swap")

	# BK-04 and PZ-302.
	scene.warp("BK-01", "from_veil")
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(2, 14)), "left")
	await _press_for("move_left", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BK-04", "through the crack into Kencana-in-the-Veil")
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(20, 2)), "up")
	await _press_for("move_up", 30)
	await _wait(2)
	check(scene.map.id == "BK-04", "the Hall of Records is shut until the name is found")
	await _finish_dialogue(im)
	# Mast 1 from above, mast 2 from above, mast 3 from below.
	await _face_and_press(scene, Vector2i(8, 5), "down", im)
	await _finish_dialogue(im, 2)
	check(not gs.get_flag("ch03_mast_1"), "PZ-302: the wrong band is static")
	await _face_and_press(scene, Vector2i(8, 5), "down", im)
	await _finish_dialogue(im, 0)
	await _face_and_press(scene, Vector2i(31, 5), "down", im)
	await _finish_dialogue(im, 1)
	await _talk(scene, Vector2i(20, 25), im, 2)
	check(gs.get_flag("ch03_masts_done"), "PZ-302: KEN, CA, NA")

	# A three-hero battle with Static Burst.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(24, 8)), "up")
	await _press_for("move_up", 30)
	var blog: Array[String] = await _run_battle_with(scene, im, ["skill", "static_burst", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("elias") and l.ends_with("(all)")), "Elias fights: Static Burst hits every enemy")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("bk04_mixed_beaten") and int(gs.data["members"]["elias"]["xp"]) > 0, "the mast guards are beaten; Elias earns XP too")

	# BOSS-301.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(20, 2)), "up")
	await _press_for("move_up", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BK-05", "into the Hall of Records")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(12, 8)), "up")
	await _press_for("move_up", 40)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Blank Clerk fight starts")
	blog = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon ink_blot")), "the Clerk calls Ink Blots")
	check(blog.any(func(l: String) -> bool: return l.contains("telegraph Redact")), "Redact is announced a round ahead")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch03_clerk_defeated") and gs.has_key_item("item_clerks_ledger") and gs.equip_bonus("elias").get("res", 0) == 3, "BOSS-301: the ledger and the Crystal Earpiece")
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "BK-01", "C3-07 back at the wharf")
	await _finish_dialogue(im)
	for i in 240:
		if tree.current_scene != null and tree.current_scene != scene:
			break
		await tree.process_frame
	check(["ch03_name_restored", "bukit_getah_route_unlocked", "chapter_03_completed", "chapter_04_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C03-001", "C03-002", "C03-003", "C03-004"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C03-001 to C03-004 are finished")
	check(tree.current_scene != null and tree.current_scene.name == "EndOfContent", "the Chapter 3 complete screen shows")
	if is_instance_valid(scene):
		if scene.is_inside_tree():
			root.remove_child(scene)
		scene.free()
	var end_screen := tree.current_scene
	if end_screen:
		root.remove_child(end_screen)
		end_screen.free()
	saves.delete_all()
	_sections_done += 1


## A new game set up at the end of the given chapter, with Elias, at the given XP.
func _chapter_start(gs: Node, flags: Array, xp: int, map_id: String, spawn: String) -> Node:
	var saves: Node = root.get_node("Saves")
	saves.delete_all()
	gs.new_game()
	gs.data["settings"]["instant_text"] = true
	for f in ["prologue_completed", "lumi_joined", "spirit_cyclone_learned", "ch01_guardian_bloom_learned", "ch01_gentle_float_unlocked", "ch02_ripple_learned"] + flags:
		gs.set_flag(f)
	gs.add_member("lumi")
	gs.gain_xp("reno", xp)
	gs.gain_xp("lumi", xp)
	if "ch03_elias_joined" in flags:
		gs.add_member("elias")
	if "ch05_maris_joined" in flags:
		gs.add_member("maris")
	if "ch06_taro_joined" in flags:
		gs.add_member("taro")
	if "ch07_galen_joined" in flags:
		gs.add_member("galen")
	gs.set_spawn(map_id, spawn)
	var scene: Node = load("res://scenes/exploration.tscn").instantiate()
	scene.battle_auto_judge = "perfect"
	scene.battle_speed = 20.0
	root.add_child(scene)
	tree.current_scene = scene
	await _wait(3)
	return scene


## After a chapter_end event: wait for the end screen, check it, and clean up.
func _chapter_end_screen(scene: Node, label: String) -> void:
	for i in 240:
		if tree.current_scene != null and tree.current_scene != scene:
			break
		await tree.process_frame
	check(tree.current_scene != null and tree.current_scene.name == "EndOfContent", "the %s complete screen shows" % label)
	if is_instance_valid(scene):
		if scene.is_inside_tree():
			root.remove_child(scene)
		scene.free()
	var end_screen := tree.current_scene
	if end_screen:
		root.remove_child(end_screen)
		end_screen.free()
	root.get_node("Saves").delete_all()


func _test_chapter4(gs: Node, im: Node) -> void:
	var a := Combat.make_unit("p", "P", "hero", {"max_hp": 200, "atk": 5, "def": 5, "mag": 5, "res": 5, "spd": 5})
	check(Combat.poison_damage(a) == 12, "Poison: 6% of max HP")

	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "chapter_04_unlocked", "ch03_elias_joined", "ch03_name_restored", "ch03_wharf_seen"], 900, "BK-01", "from_estate")
	await _face_and_press(scene, Vector2i(29, 16), "right", im)
	await _finish_dialogue(im)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "GT-01" and gs.get_flag("ch04_started"), "C4-00: the lorry up to Bukit Getah")
	await _finish_dialogue(im)
	check(scene._tint != null and scene._tint.color != Color.WHITE, "the estate is dark")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(20, 2)), "up")
	await _press_for("move_up", 40)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "GT-02", "into the rubber grove")
	await _finish_dialogue(im)
	check(not scene.map.is_walkable(Vector2i(12, 8)), "a frightened tree blocks the lane")
	await _face_and_press(scene, Vector2i(11, 8), "right", im)
	await _finish_dialogue(im, 1)
	check(not gs.get_flag("ch04_tree_1"), "PZ-401: the wrong words make the tree shiver harder")
	await _face_and_press(scene, Vector2i(11, 8), "right", im)
	await _finish_dialogue(im, 0)
	check(gs.get_flag("ch04_whisper_learned") and gs.get_flag("ch04_tree_1") and scene.map.is_walkable(Vector2i(12, 8)), "PZ-401: Forest Whisper calms the first tree")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(23, 20), "right", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("ch04_tree_2"), "Lumi can't Forest Whisper")
	await _tap("swap")
	await _face_and_press(scene, Vector2i(23, 20), "right", im)
	await _finish_dialogue(im, 1)
	await _face_and_press(scene, Vector2i(35, 12), "right", im)
	await _finish_dialogue(im, 2)
	check(gs.get_flag("pz401_grove_calm") and gs.quest_state("C04-001") in ["completed", "rewarded"], "PZ-401: the grove is calm")

	# A battle with Poison and Root Uppercut.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 25)), "up")
	await _press_for("move_up", 40)
	var blog: Array[String] = await _run_battle_with(scene, im, ["skill", "root_uppercut", "attack"])
	check(blog.size() > 2, "the Grove Shades fight ran")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("gt02_shades_beaten"), "the Grove Shades scatter")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(45, 15)), "right")
	await _press_for("move_right", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "GT-03", "the smokehouse clearing")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(15, 6), im, 1)
	check(not gs.get_flag("ch04_titis_calmed"), "PZ-402: a harsh answer makes Titis hide again")
	await _tap("confirm")
	await _finish_dialogue_choices(im, [0, 1, 0])
	check(gs.get_flag("ch04_titis_calmed"), "PZ-402: three gentle answers calm Titis")
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 9)), "down")
	await _press_for("move_down", 30)
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Fear-Shadow fight starts")
	blog = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon grove_shade")), "the Fear-Shadow splits into Grove Shades")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch04_shadow_beaten") and gs.equip_bonus("lumi").get("mag", 0) == 3, "BOSS-401 beaten: the Sap-Drop Charm")
	await _wait(5)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "GT-01" and scene._tint.color == Color.WHITE, "C4-06: dawn on the estate")
	await _finish_dialogue(im)
	check(["seribu_bunga_route_unlocked", "chapter_04_completed", "chapter_05_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C04-001", "C04-002", "C04-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C04-001 to C04-003 are finished")
	await _chapter_end_screen(scene, "Chapter 4")
	_sections_done += 1


func _test_chapter5(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_unlocked", "ch04_estate_seen",
		"ch04_shadow_beaten", "ch04_whisper_learned"], 1300, "GT-01", "from_forest")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(37, 23)), "right")
	await _press_for("move_right", 40)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "SB-01", "C5-01: the old forest trail")
	await _finish_dialogue(im)
	await _tap("swap")
	await _talk(scene, Vector2i(21, 12), im)
	check(not gs.has_member("maris"), "Lumi can't pull the dead vines")
	await _tap("swap")
	await _talk(scene, Vector2i(21, 12), im)
	check(gs.has_member("maris") and gs.get_flag("ch05_maris_joined") and not scene.members.has("maris"), "C5-02: Maris joins and travels along")
	check(gs.active_party() == ["reno", "lumi", "elias"] and gs.party().size() == 4, "four members: Maris starts in reserve")
	var rows: Array = PauseMenu.party_rows()
	check(rows[3]["text"].begins_with("(R)") and rows[3].has("action"), "the Party menu marks the reserve and can move her up")
	rows[3]["action"].call()
	check(gs.active_party().has("maris") and not gs.active_party().has("elias"), "Formation: Maris moves to the front, Elias to reserve")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(37, 14)), "right")
	await _press_for("move_right", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "SB-02", "the Thousand Flowers")
	await _finish_dialogue(im)
	check(not scene.map.is_walkable(Vector2i(15, 8)), "the stream has no bridge")
	await _face_and_press(scene, Vector2i(12, 8), "right", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch05_bridge_1") and scene.map.is_walkable(Vector2i(15, 8)) and scene.map.is_walkable(Vector2i(13, 8)), "PZ-501: Maris Regrows a vine bridge")
	await _talk(scene, Vector2i(6, 4), im)
	check(not gs.get_flag("ch05_memory_1"), "the blossom needs Lumi")
	await _tap("swap")
	await _talk(scene, Vector2i(6, 4), im)
	await _talk(scene, Vector2i(23, 24), im)
	await _face_and_press(scene, Vector2i(28, 20), "right", im)
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(40, 6), im)
	check(gs.get_flag("ch05_memories_seen") and gs.quest_state("C05-002") in ["completed", "rewarded"], "PZ-502: three memories, the Promise and the crying Oathkeeper")
	await _tap("swap")

	# Bloom Heal in a fight.
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(22, 13)), "up")
	await _press_for("move_up", 40)
	var blog: Array[String] = await _run_battle_with(scene, im, ["skill", "bloom_heal", "attack"])
	check(blog.size() > 2, "the Pollen Puff fight ran")
	await _wait(3)
	await _finish_dialogue(im)

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(45, 14)), "right")
	await _press_for("move_right", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "SB-03", "the Heart of the Sanctuary")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 9)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")   # walked up to it: A starts the fight
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Forgetting Bloom fight starts")
	blog = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "skill", "bloom_heal", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("heal")), "Maris heals in the boss fight")
	check(blog.any(func(l: String) -> bool: return l.contains("summon thorn_sprite")), "the Bloom calls Thorn Sprites")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch05_bloom_beaten") and gs.has_key_item("item_carnival_stub") and gs.equip_bonus("maris").get("res", 0) == 2, "BOSS-501: the Petal Brooch and a carnival ticket")
	await _wait(3)
	await _finish_dialogue(im)
	check(["carnival_route_unlocked", "chapter_05_completed", "chapter_06_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C05-001", "C05-002", "C05-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C05-001 to C05-003 are finished")
	await _chapter_end_screen(scene, "Chapter 5")
	_sections_done += 1


func _test_chapter6(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_completed", "ch05_maris_joined",
		"chapter_06_unlocked", "ch05_started"], 2200, "SB-01", "from_carnival")
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(31, 28)), "down")
	await _press_for("move_down", 30)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "PM-01", "C6-01: the south path leads to Pasar Malam Impian")
	await _finish_dialogue(im)
	check(gs.get_flag("ch06_started"), "the carnival opens")
	await _talk(scene, Vector2i(20, 13), im)
	check(gs.get_flag("ch06_taro_lied") and not gs.has_member("taro"), "C6-02: Taro sends us the wrong way")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(33, 7)), "up")
	await _press_for("move_up", 20)
	await _finish_dialogue(im)
	check(scene.map.id == "PM-01", "the Ghost Train is performers only")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(14, 7)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "PM-02", "the Hall of Mirrors")
	await _finish_dialogue(im)
	check(not scene.map.is_walkable(Vector2i(7, 15)), "the false mirrors look solid")
	if gs.leader() == "lumi":
		await _tap("swap")
	await _talk(scene, Vector2i(2, 1), im)
	check(not gs.get_flag("ch06_mirrors_seen"), "Reno only sees his own face")
	await _tap("swap")
	await _talk(scene, Vector2i(2, 1), im)
	check(gs.get_flag("ch06_mirrors_seen") and scene.map.is_walkable(Vector2i(7, 15)) and scene.map.is_walkable(Vector2i(21, 11)), "PZ-601: Echo Sight shows the doorway mirrors")
	await _talk(scene, Vector2i(25, 11), im)
	check(gs.has_member("taro") and gs.get_flag("ch06_taro_joined") and not scene.members.has("taro") and gs.party().size() == 5, "C6-04: Taro joins (five in the party)")
	gs.move_to_front("taro")
	check(gs.active_party().has("taro"), "Taro moves to the front")
	await _tap("swap")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(3, 18)), "down")
	await _press_for("move_down", 20)
	await _wait_transition(im)
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(33, 7)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "PM-03", "the Ghost Train platform")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 13)), "up")
	await _press_for("move_up", 16)
	await _finish_dialogue_choices(im, [1])
	check(gs.get_flag("ch06_decoy_offered") and not gs.get_flag("ch06_decoy_used"), "C6-05: Taro offers a Decoy (we try to be quick)")
	scene.set_loop_step("ticket_taker", 0)
	await _talk(scene, Vector2i(22, 5), im)
	check(not gs.get_flag("ch06_lever_pulled"), "PZ-602: the ticket-taker catches us at the lever")
	scene.set_loop_step("ticket_taker", 1)
	await _talk(scene, Vector2i(22, 5), im)
	check(gs.get_flag("ch06_lever_pulled"), "the lever goes over while he looks away")
	await _talk(scene, Vector2i(10, 4), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "PM-04" and gs.get_flag("ch06_ride_taken"), "C6-06: the Ghost Train rides to the Big Top")
	await _finish_dialogue(im)

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 9)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Ringmaster fight starts")
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "skill", "dazzle", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("taro") and l.contains("(all)")), "Taro's Dazzle hits every enemy")
	check(blog.any(func(l: String) -> bool: return l.contains("summon funhouse_double")), "the Ringmaster calls a Funhouse Double")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch06_ringmaster_beaten") and gs.has_key_item("item_oneway_ticket") and gs.equip_bonus("taro").get("spd", 0) == 3, "BOSS-601: the Juggler's Ribbon and a one-way ticket")
	await _wait(3)
	await _finish_dialogue(im)
	check(["eastern_route_unlocked", "chapter_06_completed", "chapter_07_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C06-001", "C06-002", "C06-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C06-001 to C06-003 are finished")
	await _chapter_end_screen(scene, "Chapter 6")
	_sections_done += 1


func _test_chapter7(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_completed", "ch05_maris_joined",
		"chapter_06_completed", "ch06_started", "ch06_taro_joined", "ch06_ringmaster_beaten", "chapter_07_unlocked"], 2700, "PM-01", "from_train")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(20, 26), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "EH-01", "C7-01: the carnival caravan rides east to the Cloud Range")
	await _finish_dialogue(im)
	check(gs.get_flag("ch07_started"), "the chapter starts")
	if gs.leader() == "reno":
		await _tap("swap")
	await _talk(scene, Vector2i(18, 8), im)
	check(not gs.get_flag("ch07_mist_1"), "Lumi can't push the mist")
	await _tap("swap")
	await _talk(scene, Vector2i(18, 8), im)
	check(gs.get_flag("ch07_mist_1") and scene.map.is_walkable(Vector2i(18, 8)), "PZ-701: Spirit Cyclone blows the mist away")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(18, 1)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "EH-02", "the Moss Forest")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(17, 15), im)
	await _talk(scene, Vector2i(9, 7), im)
	check(gs.get_flag("ch07_mist_cleared") and gs.quest_state("C07-001") in ["completed", "rewarded"], "all three mist banks are gone")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(9, 1)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "EH-03", "the Guardian's Gate")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(15, 12), im)
	check(not gs.get_flag("ch07_stone_1") and not scene.map.is_walkable(Vector2i(15, 12)), "nobody can break a silent stone yet")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 19)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "C7-03: Galen's trial starts")
	await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "skill", "attack"])
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch07_galen_trial_won") and gs.has_member("galen") and gs.get_flag("ch07_galen_joined") and gs.party().size() == 6, "Galen yields and joins (six in the party)")
	gs.move_to_front("galen")
	for c in [Vector2i(15, 12), Vector2i(8, 8), Vector2i(22, 4)]:
		await _talk(scene, c, im)
	check(["ch07_stone_1", "ch07_stone_2", "ch07_stone_3"].all(gs.get_flag) and scene.map.is_walkable(Vector2i(22, 4)), "PZ-702: Galen breaks the three silent stones")

	scene.leader().place_at(MapData.cell_to_feet(Vector2i(22, 1)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "EH-04", "the Oath Stone summit")
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 10)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Hush fight starts")
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "skill", "stone_rain", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("galen counter")), "Galen counters a physical hit")
	check(blog.any(func(l: String) -> bool: return l.contains("-> galen")), "attacks are drawn to Galen")
	check(blog.any(func(l: String) -> bool: return l.contains("summon stone_silencer")), "the Hush wakes a Stone Silencer")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch07_hush_beaten") and gs.has_key_item("item_oath_rubbing") and gs.equip_bonus("galen").get("def", 0) == 3, "BOSS-701: the Moss Mantle and the Oath Stone rubbing")
	await _wait(3)
	await _finish_dialogue(im)
	check(["ch07_lantern_moon_warned", "chapter_07_completed", "chapter_08_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C07-001", "C07-002", "C07-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C07-001 to C07-003 are finished")
	await _chapter_end_screen(scene, "Chapter 7")
	_sections_done += 1


func _test_chapter8(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_completed", "ch05_maris_joined",
		"chapter_06_completed", "ch06_taro_joined", "chapter_07_completed", "ch07_started", "ch07_galen_joined", "ch07_hush_beaten", "ch07_summit_seen", "chapter_08_unlocked"], 3300, "EH-04", "from_gate")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(12, 16), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "LM-01", "C8-01: the Lantern Path leads to Bandar Senja under the Lantern Moon")
	await _finish_dialogue(im)
	check(gs.get_flag("ch08_started") and not scene.map.npcs.is_empty(), "three tears have opened")

	# Mission A: Lumi, Maris and Elias.
	await _talk(scene, Vector2i(4, 12), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "LM-02" and gs.active_party() == ["lumi", "maris", "elias"], "C8-02: the river team is Lumi, Maris and Elias")
	check(scene.members.size() == 1 and scene.members.has("lumi") and gs.leader() == "lumi", "only Lumi walks the river mission")
	var bad: Dictionary = gs.data.duplicate(true)
	bad["mission"] = ["nobody"]
	check(not gs.validate(bad).is_empty() and gs.validate(gs.data.duplicate(true)).is_empty(), "a save mid-mission is valid; a mission member outside the party is rejected")
	var old: Dictionary = gs.data.duplicate(true)
	old.erase("mission")
	check(gs.migrate(old).get("mission") == [], "older saves get an empty mission")
	var rows: Array = PauseMenu.party_rows()
	check(rows.any(func(r: Dictionary) -> bool: return r["text"].begins_with("(away)")) and not rows.any(func(r: Dictionary) -> bool: return r.has("action")), "the Party menu shows who is away and locks formation")
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(12, 10), "right", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch08_river_bridge") and scene.map.is_walkable(Vector2i(15, 10)), "Maris regrows a bridge over the spill")
	await _talk(scene, Vector2i(22, 4), im)
	check(gs.get_flag("ch08_knot_seen"), "Lumi's Echo Sight finds the knot")
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(25, 15)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Riptide Wraith fight starts")
	var blog: Array[String] = await _run_battle_with(scene, im, ["skill", "bloom_heal", "attack"])
	check(not blog.any(func(l: String) -> bool: return l.begins_with("reno"))and blog.any(func(l: String) -> bool: return l.begins_with("maris")), "only the river team fights")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait_transition(im)
	await _wait(3)
	check(gs.get_flag("ch08_river_sealed") and scene.map.id == "LM-01" and not gs.in_mission() and scene.members.size() == 2, "the river tear is sealed and the party regroups")

	# Mission B: Reno, Taro and Galen.
	await _talk(scene, Vector2i(29, 12), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "LM-03" and gs.active_party() == ["reno", "taro", "galen"] and gs.leader() == "reno", "C8-03: the market team is Reno, Taro and Galen")
	await _finish_dialogue(im)
	await _face_and_press(scene, Vector2i(21, 10), "right", im)
	await _finish_dialogue(im)
	check(not gs.get_flag("ch08_market_stone"), "Galen won't break the stone with a human so close")
	await _face_and_press(scene, Vector2i(19, 10), "right", im)
	await _finish_dialogue_choices(im, [0])
	await _wait(3)
	check(gs.get_flag("ch08_watchman_gone"), "Taro's paper-cat Decoy leads the watchman away")
	await _face_and_press(scene, Vector2i(21, 10), "right", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch08_market_stone") and scene.map.is_walkable(Vector2i(22, 10)), "Galen breaks the silent stone")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(23, 10)), "right")
	await _press_for("move_right", 30)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Lantern Glutton fight starts")
	blog = await _run_battle_with(scene, im, ["skill", "dazzle", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("galen counter")), "Galen counters the Glutton")
	await _wait(3)
	await _finish_dialogue(im)
	await _wait_transition(im)
	await _wait(3)
	check(gs.get_flag("ch08_market_sealed") and gs.get_flag("ch08_two_sealed") and scene.map.id == "LM-01", "both tears sealed: the railway tear opens")

	# Mission C: Reno and Lumi.
	await _wait(3)
	await _talk(scene, Vector2i(17, 4), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "LM-04" and gs.active_party() == ["reno", "lumi"], "C8-04: Reno and Lumi take the railway tear together")
	await _finish_dialogue(im)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 13)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "the Echo of 1951 fight starts")
	blog = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "attack"])
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch08_echo_beaten") and gs.has_key_item("item_archive_ticket") and gs.equip_bonus("lumi").get("mag", 0) == 3, "BOSS-803: the Lantern Moon Charm and the Keeper's ticket")
	await _wait(3)
	await _finish_dialogue(im)
	check(not gs.in_mission() and ["ch08_archive_revealed", "chapter_08_completed", "chapter_09_unlocked"].all(gs.get_flag), "the party regroups and every end-of-chapter flag is set")
	check(["C08-001", "C08-002", "C08-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C08-001 to C08-003 are finished")
	await _chapter_end_screen(scene, "Chapter 8")
	_sections_done += 1


func _test_chapter9(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_completed", "ch05_maris_joined",
		"chapter_06_completed", "ch06_taro_joined", "chapter_07_completed", "ch07_galen_joined", "chapter_08_completed", "ch08_started", "ch08_two_sealed",
		"ch08_river_sealed", "ch08_market_sealed", "ch08_echo_beaten", "chapter_09_unlocked"], 4000, "LM-01", "from_railway")
	for k in ["item_oath_rubbing", "item_archive_ticket"]:
		gs.add_key_item(k)
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(17, 4), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "AR-01", "C9-01: the railway tear opens into the Archive Between Worlds")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(16, 18), im)
	check(gs.get_flag("ch09_gate_1") and scene.map.is_walkable(Vector2i(16, 18)), "PZ-901: the Oath Stone Rubbing opens gate one")
	await _talk(scene, Vector2i(9, 12), im, 0)
	check(not gs.get_flag("ch09_gate_2"), "the wrong answer keeps gate two shut")
	await _talk(scene, Vector2i(9, 12), im, 1)
	check(gs.get_flag("ch09_gate_2"), "\"Everyone who keeps it\" opens gate two")
	await _talk(scene, Vector2i(22, 6), im)
	check(gs.get_flag("ch09_gates_open") and gs.quest_state("C09-001") in ["completed", "rewarded"], "the Ticket to Nowhere opens gate three")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(22, 1)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "AR-02", "the Reading Room of 1951")
	await _finish_dialogue(im)
	if gs.leader() == "lumi":
		await _tap("swap")
	await _talk(scene, Vector2i(6, 6), im)
	check(not gs.get_flag("ch09_page_1"), "Reno can't read pages written in light")
	await _tap("swap")
	for c in [Vector2i(6, 6), Vector2i(15, 4), Vector2i(24, 6)]:
		await _talk(scene, c, im)
	check(gs.get_flag("ch09_pages_read"), "PZ-902: Lumi reads all three pages of 1951")
	await _wait(3)
	await _talk(scene, Vector2i(15, 10), im)
	check(gs.get_flag("ch09_truth_known") and gs.has_key_item("item_mayas_page"), "the hidden fourth page: Maya's last words")
	await _tap("swap")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 1)), "up")
	await _press_for("move_up", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "AR-03", "the Keeper's desk")
	await _finish_dialogue(im)
	gs.move_to_front("maris")
	gs.move_to_front("galen")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 10)), "up")
	await _press_for("move_up", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "C9-04: the first confrontation with the Keeper")
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "skill", "stone_rain", "bloom_heal", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon erased_page")), "the Keeper erases pages into enemies")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch09_keeper_confronted") and gs.equip_bonus("reno").get("atk", 0) >= 3, "BOSS-901: he breaks off at 40% and drops the Oathkeeper's Pin")
	await _wait(3)
	await _finish_dialogue(im)
	check(["chapter_09_completed", "chapter_10_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C09-001", "C09-002", "C09-003"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C09-001 to C09-003 are finished")
	await _chapter_end_screen(scene, "Chapter 9")
	_sections_done += 1


func _test_chapter10(gs: Node, im: Node) -> void:
	var scene: Node = await _chapter_start(gs, ["chapter_03_completed", "ch03_elias_joined", "chapter_04_completed", "chapter_05_completed", "ch05_maris_joined",
		"chapter_06_completed", "ch06_taro_joined", "chapter_07_completed", "ch07_galen_joined", "chapter_08_completed", "chapter_09_completed",
		"ch09_desk_seen", "ch09_keeper_confronted", "chapter_10_unlocked"], 5200, "AR-03", "from_reading")
	gs.add_key_item("item_mayas_page")
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(15, 6), im, 0)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "FC-01", "C10-01: the golden door opens onto the First Crossing")
	await _finish_dialogue(im)
	check(not scene.map.is_walkable(Vector2i(28, 12)), "a wall of silence blocks the bridge")
	await _talk(scene, Vector2i(6, 10), im)
	await _face_and_press(scene, Vector2i(12, 13), "down", im)
	await _finish_dialogue(im)
	await _talk(scene, Vector2i(19, 10), im)
	check(not gs.get_flag("ch10_bridge_open"), "three lanterns aren't enough")
	await _face_and_press(scene, Vector2i(25, 13), "down", im)
	await _finish_dialogue(im)
	check(gs.get_flag("ch10_bridge_open") and scene.map.is_walkable(Vector2i(28, 12)), "PZ-1001: Elias, Maris, Taro and Galen relight the Promise lanterns")
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(30, 12)), "right")
	await _press_for("move_right", 20)
	await _wait_transition(im)
	await _wait(3)
	check(scene.map.id == "FC-02", "the Heart of the Crossing")
	await _finish_dialogue(im)
	for id in ["galen", "lumi", "reno"]:
		gs.move_to_front(id)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(12, 12)), "right")
	await _press_for("move_right", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "C10-02: the final battle with the Keeper")
	var blog: Array[String] = await _run_battle_with(scene, im, ["team:guardian_bloom", "team:spirit_cyclone", "skill", "stone_rain", "attack"])
	check(blog.any(func(l: String) -> bool: return l.contains("summon erased_page")), "the Keeper fights in phases")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch10_keeper_down") and gs.get_flag("ch10_promise_learned"), "the Keeper falls; the Great Silence rises; Promise Renewed is learned")
	await _wait(3)
	scene.leader().place_at(MapData.cell_to_feet(Vector2i(15, 12)), "right")
	await _press_for("move_right", 40)
	if im.current_mode() == im.Mode.EXPLORE:
		await _tap("confirm")
	await _finish_dialogue(im)
	check(im.current_mode() == im.Mode.BATTLE, "C10-03: the Great Silence")
	blog = await _run_battle_with(scene, im, ["team:promise_renewed", "team:guardian_bloom", "skill", "stone_rain", "attack"])
	check(blog.any(func(l: String) -> bool: return l.begins_with("team reno,lumi perfect,perfect,perfect,perfect")), "Promise Renewed lands (four cues)")
	check(blog.any(func(l: String) -> bool: return l.contains("summon silence_shard")), "the Silence breaks into shards")
	await _wait(3)
	await _finish_dialogue(im)
	check(gs.get_flag("ch10_silence_beaten") and gs.has_key_item("item_renewed_promise"), "BOSS-1002: the Promise is renewed")
	await _wait(3)
	await _finish_dialogue(im)
	check(["chapter_10_completed", "epilogue_unlocked"].all(gs.get_flag), "every end-of-chapter flag is set")
	check(["C10-001", "C10-002"].all(func(q: String) -> bool: return gs.quest_state(q) in ["completed", "rewarded"]), "C10-001 and C10-002 are finished")
	await _chapter_end_screen(scene, "Chapter 10")
	_sections_done += 1
