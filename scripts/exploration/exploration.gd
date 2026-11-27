extends Node2D
## Exploration mode: the map, the party, the camera, doors and interaction.

const SPEED := 72.0
const FADE_TIME := 0.25
const INTERACT_REACH := 12.0
const CAMERA_LIFT := Vector2(0, -12)
const MAX_LEAP := 2        # Leaf Leap clears up to this many pit tiles
const LEAP_TIME := 0.4

var map: MapData
var tilemap: TileMapLayer
var actors: Node2D
var camera: Camera2D
var dialogue: DialogueBox
var menu: PauseMenu
var shop: ShopMenu
var coin_jar: CoinJarView
var fade: ColorRect
var map_label: Label
var members := {}           # member id -> PartyMember (in the party)
var npcs: Array[Dictionary] = []   # {"node": PartyMember, "def": Dictionary}
var _notices: Array[String] = []
var _encounter_running := false
## Test hooks passed to battles.
var battle_auto_judge := ""
var battle_speed := 1.0
var _last_safe := Vector2.ZERO   # last leader position on solid ground (for falls)
var _busy := false               # leaping or falling
var trail := FollowTrail.new()
var transitioning := false
var _label_time := 0.0


func _ready() -> void:
	InputManager.set_base_mode(InputManager.Mode.EXPLORE)
	tilemap = TileMapLayer.new()
	tilemap.name = "Ground"
	tilemap.tile_set = Assets.tileset()
	add_child(tilemap)
	actors = Node2D.new()
	actors.name = "Actors"
	actors.y_sort_enabled = true
	add_child(actors)
	camera = Camera2D.new()
	camera.process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	add_child(camera)

	var hud := CanvasLayer.new()
	hud.layer = 5
	add_child(hud)
	map_label = Label.new()
	map_label.theme = Assets.ui_theme
	map_label.position = Vector2(4, 3)
	map_label.add_theme_color_override("font_outline_color", Color("#140f1c"))
	map_label.add_theme_constant_override("outline_size", 2)
	hud.add_child(map_label)
	dialogue = DialogueBox.new()
	add_child(dialogue)
	dialogue.event.connect(_on_story_event)
	menu = PauseMenu.new()
	add_child(menu)
	menu.load_requested.connect(func() -> void: get_tree().change_scene_to_file.call_deferred("res://scenes/exploration.tscn"))
	shop = ShopMenu.new()
	add_child(shop)
	coin_jar = CoinJarView.new()
	add_child(coin_jar)
	coin_jar.closed.connect(_on_coin_jar_closed)
	GameState.party_changed.connect(_on_party_changed)
	GameState.flag_changed.connect(_on_flag_changed)
	Quests.notice.connect(_on_notice)
	var fade_layer := CanvasLayer.new()
	fade_layer.layer = 20
	add_child(fade_layer)
	fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.size = Vector2(240, 160)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.modulate.a = 0.0
	fade_layer.add_child(fade)

	load_map(GameState.data["map_id"], GameState.data["spawn"])
	_run_on_enter()


func _exit_tree() -> void:
	if GameState.flag_changed.is_connected(_on_flag_changed):
		GameState.flag_changed.disconnect(_on_flag_changed)
	if GameState.party_changed.is_connected(_on_party_changed):
		GameState.party_changed.disconnect(_on_party_changed)
	if Quests.notice.is_connected(_on_notice):
		Quests.notice.disconnect(_on_notice)


func _on_notice(text: String) -> void:
	_notices.append(text)


func leader() -> PartyMember:
	return members.get(GameState.leader())


func follower() -> PartyMember:
	for id: String in members:
		if id != GameState.leader():
			return members[id]
	return null


# --- Map loading -------------------------------------------------------------

func load_map(map_id: String, spawn_name: String = "") -> void:
	for child in actors.get_children():
		child.queue_free()
		actors.remove_child(child)
	members.clear()
	npcs.clear()
	map = MapData.load_map(map_id)
	map.apply_overrides(GameState.get_flag)

	tilemap.clear()
	for y in map.height:
		for x in map.width:
			_paint_cell(Vector2i(x, y))
	var px := map.pixel_size()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = px.x
	camera.limit_bottom = px.y

	var start := _pick_start(spawn_name)
	var pos := MapData.cell_to_feet(start["cell"])
	for id: String in GameState.party():
		members[id] = _spawn_member(id, pos, start["facing"])
	trail.reset(pos)
	_last_safe = pos

	for def in map.npcs:
		if def.has("hide_if_flag") and GameState.get_flag(def["hide_if_flag"]):
			continue
		if def.has("member") and GameState.has_member(def["member"]):
			continue
		var npc := _spawn_member(def.get("member", def.get("character", "")), MapData.cell_to_feet(def["cell"]), def.get("facing", "down"))
		npcs.append({"node": npc, "def": def})

	GameState.set_position(map.id, start["cell"], start["facing"])
	camera.global_position = pos + CAMERA_LIFT
	camera.reset_smoothing()
	map_label.text = map.name
	map_label.visible = true
	_label_time = 2.0


## Saved tile if it is still valid, else the named spawn, else "start".
func _paint_cell(cell: Vector2i) -> void:
	var idx := Assets.tile_index(map.tile_name(cell))
	if idx >= 0:
		tilemap.set_cell(cell, 0, Vector2i(idx, 0))
	else:
		tilemap.erase_cell(cell)


## Story flags can reveal tiles (Echo Sight stones, the root bridge).
func _on_flag_changed(_flag: String, _value: Variant) -> void:
	if map == null:
		return
	for cell in map.apply_overrides(GameState.get_flag):
		_paint_cell(cell)
	for npc in npcs.duplicate():
		if npc["def"].has("hide_if_flag") and GameState.get_flag(npc["def"]["hide_if_flag"]):
			npcs.erase(npc)
			npc["node"].queue_free()


func _pick_start(spawn_name: String) -> Dictionary:
	if spawn_name != "" and map.spawns.has(spawn_name):
		return map.spawns[spawn_name]
	var cell := GameState.saved_cell()
	if map.is_walkable(cell) and map.door_at(cell).is_empty():
		return {"cell": cell, "facing": GameState.data["facing"]}
	if map.spawns.has("start"):
		return map.spawns["start"]
	return map.spawns.values()[0]


func _spawn_member(id: String, pos: Vector2, facing: String) -> PartyMember:
	var m := PartyMember.new()
	m.setup(id)
	actors.add_child(m)
	m.place_at(pos, facing)
	return m


# --- Frame loop --------------------------------------------------------------

func _physics_process(_delta: float) -> void:
	if transitioning or _busy or leader() == null:
		return
	var lead := leader()
	var dir := InputManager.move_vector(InputManager.Mode.EXPLORE)
	if not GameState.setting("diagonal_movement") and dir != Vector2.ZERO:
		dir = Vector2(signf(dir.x), 0) if absf(dir.x) > absf(dir.y) else Vector2(0, signf(dir.y))
	if lead.walk(dir, SPEED):
		trail.record(lead.global_position)
	var f := follower()
	if f:
		f.follow_to(trail.target())
	camera.global_position = lead.global_position + CAMERA_LIFT

	var cell := MapData.feet_to_cell(lead.global_position)
	GameState.set_position(map.id, cell, lead.facing)
	if InputManager.current_mode() != InputManager.Mode.EXPLORE:
		return
	if map.is_pit(cell):
		_fall()
		return
	if map.is_walkable(cell):
		_last_safe = lead.global_position
	var door := map.door_at(cell)
	if not door.is_empty():
		_try_door(door, cell)
		return
	for tr: Dictionary in map.trigger_at(cell):
		if GameState.conditions_met(tr):
			dialogue.play_scene(tr["scene"])
			return
	for npc in npcs:
		if npc["def"].has("encounter") and npc["node"].global_position.distance_to(lead.global_position) < 14.0:
			start_encounter(npc)
			return


func _process(delta: float) -> void:
	if InputManager.current_mode() == InputManager.Mode.EXPLORE:
		GameState.add_playtime(delta)
	if _label_time > 0.0:
		_label_time -= delta
		map_label.visible = _label_time > 0.0
	var mode := InputManager.Mode.EXPLORE
	if InputManager.current_mode() != mode or transitioning:
		return
	if not _notices.is_empty():
		var lines := _notices.duplicate()
		_notices.clear()
		dialogue.show_lines(lines)
	elif InputManager.just_pressed("confirm", mode):
		_interact()
	elif InputManager.just_pressed("swap", mode):
		swap_leader()
	elif InputManager.just_pressed("menu", mode):
		menu.open()


# --- Actions -----------------------------------------------------------------

func swap_leader() -> bool:
	var f := follower()
	if f == null or transitioning or _busy:
		return false
	if not map.is_walkable(MapData.feet_to_cell(f.global_position)) or map.is_pit(MapData.feet_to_cell(f.global_position)):
		# The follower is floating over a gap: bring them to the leader first.
		f.place_at(leader().global_position, f.facing)
		trail.reset(f.global_position)
	trail.reverse_for_swap()
	GameState.set_leader(f.member_id)
	return true


func _interact() -> void:
	var lead := leader()
	var probe := lead.global_position + lead.facing_vector() * INTERACT_REACH + Vector2(0, -3)
	for npc in npcs:
		if npc["node"].global_position.distance_to(probe) <= INTERACT_REACH:
			_talk_to(npc)
			return
	var cell := MapData.feet_to_cell(probe)
	if map.signs.has(cell):
		dialogue.show_lines(map.signs[cell])
		return
	if map.objects.has(cell):
		var scene_id := pick_scene(map.objects[cell].get("talk", []))
		if scene_id != "":
			dialogue.play_scene(scene_id)
		return
	_try_leap(lead)


# --- Field abilities ---------------------------------------------------------

## Leaf Leap (Reno): facing up to MAX_LEAP pit tiles with solid ground beyond.
## Contextual: press A facing a gap. Uses no combat MP.
func _try_leap(lead: PartyMember) -> bool:
	var dir := Vector2i(lead.facing_vector())
	var from := MapData.feet_to_cell(lead.global_position)
	var c := from + dir
	var pits := 0
	while map.is_pit(c) and pits <= MAX_LEAP:
		pits += 1
		c += dir
	if pits == 0:
		return false
	if lead.member_id != "reno":
		dialogue.play_scene("leap_lumi")
	elif pits > MAX_LEAP or not map.is_walkable(c) or map.is_pit(c):
		dialogue.play_scene("leap_too_far")
	else:
		_leap(lead, MapData.cell_to_feet(c))
	return true


func _leap(lead: PartyMember, to: Vector2) -> void:
	_busy = true
	InputManager.push_mode(InputManager.Mode.CUTSCENE)
	var from := lead.global_position
	var t := create_tween()
	t.tween_method(func(k: float) -> void:
		lead.global_position = from.lerp(to, k)
		lead.sprite.position.y = -sin(k * PI) * 10.0
		trail.record(lead.global_position)
		camera.global_position = lead.global_position + CAMERA_LIFT
		var f := follower()
		if f:
			f.follow_to(trail.target()), 0.0, 1.0, LEAP_TIME)
	await t.finished
	lead.sprite.position.y = 0
	_last_safe = to
	InputManager.pop_mode(InputManager.Mode.CUTSCENE)
	_busy = false


## Stepping onto a pit: drop in, then come back on the last safe ground.
func _fall() -> void:
	_busy = true
	InputManager.push_mode(InputManager.Mode.CUTSCENE)
	var lead := leader()
	var t := create_tween()
	t.tween_property(lead.sprite, "scale", Vector2(0.2, 0.2), 0.3)
	await t.finished
	lead.sprite.scale = Vector2.ONE
	lead.place_at(_last_safe, lead.facing)
	trail.reset(_last_safe)
	var f := follower()
	if f:
		f.place_at(_last_safe, f.facing)
	InputManager.pop_mode(InputManager.Mode.CUTSCENE)
	_busy = false
	dialogue.play_scene("fall")


func _talk_to(npc: Dictionary) -> void:
	if npc["def"].has("encounter"):
		start_encounter(npc)
		return
	var node: PartyMember = npc["node"]
	if not npc["def"].get("unaware", false):
		# Humans can't see the spirits, so they don't turn to look.
		node.face(leader().global_position - node.global_position)
	var scene_id := pick_scene(npc["def"].get("talk", []))
	if scene_id != "":
		dialogue.play_scene(scene_id)


## First entry whose conditions hold.
static func pick_scene(entries: Array) -> String:
	for t: Dictionary in entries:
		if GameState.conditions_met(t):
			return t.get("scene", "")
	return ""


## Story events raised by dialogue steps.
## "travel:MAP:SPAWN" moves the party after the scene (the bus, the train).
## "shop:ID" opens a spirit stall and "coin_jar" the PZ-101 puzzle.
func _on_story_event(name: String) -> void:
	var parts := name.split(":")
	match parts[0]:
		"travel":
			await dialogue.finished
			await _wait_for_explore()
			travel(parts[1], parts[2])
			return
		"shop":
			await dialogue.finished
			await _wait_for_explore()
			shop.open(parts[1])
			return
		"autosave":
			await dialogue.finished
			await _wait_for_explore()
			Saves.autosave()
			return
		"coin_jar":
			await dialogue.finished
			await _wait_for_explore()
			coin_jar.open()
			return
	if name == "prologue_end":
		await dialogue.finished
		await _wait_for_explore()
		Saves.autosave()
		var t := create_tween()
		t.tween_property(fade, "modulate:a", 1.0, 0.6)
		await t.finished
		get_tree().change_scene_to_file.call_deferred("res://scenes/end_of_content.tscn")


func _on_coin_jar_closed(solved: bool) -> void:
	if solved:
		coin_jar.queue_free()
		coin_jar = CoinJarView.new()
		add_child(coin_jar)
		coin_jar.closed.connect(_on_coin_jar_closed)
		dialogue.play_scene("C02_coin_jar_solved")


func _wait_for_explore() -> void:
	# Quest notices may follow the scene; let them finish first.
	for i in 600:
		if InputManager.current_mode() == InputManager.Mode.EXPLORE and _notices.is_empty():
			return
		await get_tree().process_frame


func _run_on_enter() -> void:
	var scene_id := pick_scene(map.on_enter)
	if scene_id != "":
		dialogue.play_scene(scene_id)


## A dialogue step added someone to the party: if they're standing on this
## map as an NPC, they become the follower from where they stand.
func _on_party_changed() -> void:
	for npc in npcs.duplicate():
		var node: PartyMember = npc["node"]
		if GameState.has_member(node.member_id) and not members.has(node.member_id):
			npcs.erase(npc)
			members[node.member_id] = node
			var path: Array[Vector2] = [node.global_position, leader().global_position]
			trail.reset_path(path)


## Visible encounter: intro scene, battle, then outro scene on a win.
func start_encounter(npc: Dictionary) -> void:
	if _encounter_running:
		return
	_encounter_running = true
	var enc: Dictionary = npc["def"]["encounter"]
	if enc.has("intro_scene"):
		dialogue.play_scene(enc["intro_scene"])
		await dialogue.finished
	var battle := Battle.new()
	battle.auto_judge = battle_auto_judge
	battle.speed = battle_speed
	add_child(battle)
	battle.start(enc["id"])
	var result: String = await battle.ended
	if result == "win":
		npcs.erase(npc)
		npc["node"].queue_free()
		if enc.has("outro_scene"):
			dialogue.play_scene(enc["outro_scene"])
			await dialogue.finished
		Saves.autosave()
	else:
		# Ran away: step back so the encounter doesn't start again at once.
		var lead := leader()
		var away: Vector2 = (lead.global_position - npc["node"].global_position).normalized()
		lead.walk(away * 24.0 * 60.0, 1.0)
		trail.reset(lead.global_position)
	_encounter_running = false


## Doors can require story flags; if one is missing, its scene explains why
## and the leader steps back off the door.
func _try_door(door: Dictionary, cell: Vector2i) -> void:
	for r: Dictionary in door["require"]:
		if not GameState.conditions_met(r):
			var lead := leader()
			var back := cell - Vector2i(lead.facing_vector())
			lead.place_at(MapData.cell_to_feet(back), lead.facing)
			trail.reset(lead.global_position)
			var f := follower()
			if f:
				f.place_at(lead.global_position, f.facing)
			dialogue.play_scene(r["else_scene"])
			return
	_use_door(door)


func _use_door(door: Dictionary) -> void:
	transitioning = true
	InputManager.push_mode(InputManager.Mode.TRANSITION)
	var notes: Array = []
	if map.id == "KA-02" and GameState.add_key_item("item_railway_token"):
		# Handover rule: the railway token is added before Reno leaves home.
		GameState.set_flag("reno_token_obtained")
		notes.append("Got the Old Railway Token. (Key item)")
	await travel(door["to_map"], door["to_spawn"], notes)


## Fades to another map, autosaves once it's safe, then runs its on_enter scene.
func travel(map_id: String, spawn: String, notes: Array = []) -> void:
	if not transitioning:
		transitioning = true
		InputManager.push_mode(InputManager.Mode.TRANSITION)
	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, FADE_TIME)
	await t.finished
	GameState.set_spawn(map_id, spawn)
	load_map(map_id, spawn)
	t = create_tween()
	t.tween_property(fade, "modulate:a", 0.0, FADE_TIME)
	await t.finished
	InputManager.pop_mode(InputManager.Mode.TRANSITION)
	transitioning = false
	# Safe moment to autosave: the transition is over and nothing is mid-change.
	Saves.autosave()
	if not notes.is_empty():
		dialogue.show_lines(notes)
	_run_on_enter()


## Instant map change without the fade (used by tests and debug tools).
func warp(map_id: String, spawn: String) -> void:
	GameState.set_spawn(map_id, spawn)
	load_map(map_id, spawn)
	_run_on_enter()
