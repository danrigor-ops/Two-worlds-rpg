extends Node2D
## Exploration mode: the map, the party, the camera, doors and interaction.

const SPEED := 72.0
const FADE_TIME := 0.25
const INTERACT_REACH := 12.0
const CAMERA_LIFT := Vector2(0, -12)

var map: MapData
var tilemap: TileMapLayer
var actors: Node2D
var camera: Camera2D
var message_box: MessageBox
var fade: ColorRect
var map_label: Label
var members := {}           # member id -> PartyMember (in the party)
var npcs: Array[Dictionary] = []   # {"node": PartyMember, "def": Dictionary}
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
	message_box = MessageBox.new()
	add_child(message_box)
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

	tilemap.clear()
	for y in map.height:
		for x in map.width:
			var idx := Assets.tile_index(map.tile_name(Vector2i(x, y)))
			if idx >= 0:
				tilemap.set_cell(Vector2i(x, y), 0, Vector2i(idx, 0))
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

	for def in map.npcs:
		if def.has("hide_if_flag") and GameState.get_flag(def["hide_if_flag"]):
			continue
		if def.has("member") and GameState.has_member(def["member"]):
			continue
		var npc := _spawn_member(def.get("member", "lumi"), MapData.cell_to_feet(def["cell"]), def.get("facing", "down"))
		npcs.append({"node": npc, "def": def})

	GameState.set_position(map.id, start["cell"], start["facing"])
	camera.global_position = pos + CAMERA_LIFT
	camera.reset_smoothing()
	map_label.text = map.name
	map_label.visible = true
	_label_time = 2.0


## Saved tile if it is still valid, else the named spawn, else "start".
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
	if transitioning or leader() == null:
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
	var door := map.door_at(cell)
	if not door.is_empty():
		_use_door(door)


func _process(delta: float) -> void:
	if InputManager.current_mode() == InputManager.Mode.EXPLORE:
		GameState.add_playtime(delta)
	if _label_time > 0.0:
		_label_time -= delta
		map_label.visible = _label_time > 0.0
	if InputManager.just_pressed("confirm", InputManager.Mode.EXPLORE):
		_interact()
	elif InputManager.just_pressed("swap", InputManager.Mode.EXPLORE):
		swap_leader()


# --- Actions -----------------------------------------------------------------

func swap_leader() -> bool:
	var f := follower()
	if f == null or transitioning:
		return false
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
		message_box.show_lines(map.signs[cell])


func _talk_to(npc: Dictionary) -> void:
	var def: Dictionary = npc["def"]
	var node: PartyMember = npc["node"]
	node.face(leader().global_position - node.global_position)
	if def.get("member") == "lumi":
		# Placeholder for scene P01. The full scene arrives with the dialogue step.
		message_box.show_lines([
			"Lumi: You're late.",
			"Reno: For what?",
			"Lumi: For the ridiculous plan you made yesterday.",
			"Lumi joined the party! (Placeholder. The full P01 scene comes with the dialogue step.)",
		], _join_member.bind(npc))


func _join_member(npc: Dictionary) -> void:
	var node: PartyMember = npc["node"]
	var id := node.member_id
	if not GameState.add_member(id):
		return
	npcs.erase(npc)
	members[id] = node
	if id == "lumi":
		GameState.set_flag("lumi_joined")
		GameState.set_quest_state("PRO-001", "completed")
	# Start the trail where she stood, so she walks over to Reno's path.
	var path: Array[Vector2] = [node.global_position, leader().global_position]
	trail.reset_path(path)


func _use_door(door: Dictionary) -> void:
	transitioning = true
	InputManager.push_mode(InputManager.Mode.TRANSITION)
	var notes: Array = []
	if map.id == "KA-02" and GameState.add_key_item("item_railway_token"):
		# Handover rule: the railway token is added before Reno leaves home.
		GameState.set_flag("reno_token_obtained")
		notes.append("Got the Old Railway Token. (Key item)")
	var t := create_tween()
	t.tween_property(fade, "modulate:a", 1.0, FADE_TIME)
	await t.finished
	GameState.set_spawn(door["to_map"], door["to_spawn"])
	load_map(door["to_map"], door["to_spawn"])
	t = create_tween()
	t.tween_property(fade, "modulate:a", 0.0, FADE_TIME)
	await t.finished
	InputManager.pop_mode(InputManager.Mode.TRANSITION)
	transitioning = false
	if not notes.is_empty():
		message_box.show_lines(notes)
