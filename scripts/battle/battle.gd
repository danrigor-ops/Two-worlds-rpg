class_name Battle
extends CanvasLayer
## Battle screen, shown over the field map. Owns input (BATTLE mode).
## The rules live in Combat; this script runs the turns, menus, timing cues
## and animation. A snapshot of GameState is taken first so a lost battle
## can be retried from exactly where it started.

signal ended(result: String)   # "win" or "escape"

const ENEMIES_PATH := "res://content/enemies.json"
const SKILLS_PATH := "res://content/skills.json"
const CUE_LEAD_MS := 650.0
const HERO_POS := {"reno": Vector2(64, 62), "lumi": Vector2(44, 88)}
const ENEMY_POS := [Vector2(176, 74), Vector2(196, 50), Vector2(196, 96)]

var combat := Combat.new()
var encounter: Dictionary = {}
var encounter_id := ""
var snapshot: Dictionary = {}
var battle_log: Array[String] = []
## Test hooks: resolve every cue with this result instead of waiting for input,
## and play animations faster.
var auto_judge := ""
var speed := 1.0

var _enemy_defs: Dictionary = {}
var _skills: Dictionary = {}
var _sprites := {}   # unit id -> Sprite2D
var _field: Node2D
var _msg: Label
var _hint: Label
var _status: Label
var _menu_panel: Panel
var _menu_label: Label
var _ring: Node2D
var _menu_items: Array = []   # [{"text", "enabled", "value"}]
var _menu_index := 0
var _menu_open := false
var _cue_active := false
var _cue_time_us := 0
var _cue_result := ""
var _hints_shown := {}

signal _menu_done(value: Variant)
signal _cue_done(result: String)
signal _confirmed


func start(id: String) -> void:
	var data := JsonUtil.load_dict(ENEMIES_PATH)
	_enemy_defs = data.get("enemies", {})
	encounter = data.get("encounters", {}).get(id, {})
	encounter_id = id
	_skills = JsonUtil.load_dict(SKILLS_PATH).get("skills", {})
	snapshot = GameState.to_dict()
	layer = 30
	InputManager.push_mode(InputManager.Mode.BATTLE)
	_build_ui()
	_run.call_deferred()


# --- Setup -------------------------------------------------------------------

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#2b4a3a")
	bg.size = Vector2(240, 160)
	add_child(bg)
	var ground := ColorRect.new()
	ground.color = Color("#3f6b45")
	ground.position = Vector2(0, 40)
	ground.size = Vector2(240, 66)
	add_child(ground)
	_field = Node2D.new()
	_field.y_sort_enabled = true
	add_child(_field)
	_ring = preload("res://scripts/battle/cue_ring.gd").new()
	_ring.visible = false
	add_child(_ring)

	var top := _panel(Vector2(4, 3), Vector2(232, 16))
	add_child(top)
	_msg = Label.new()
	_msg.position = Vector2(4, 1)
	top.add_child(_msg)
	_hint = Label.new()
	_hint.position = Vector2(6, 22)
	_hint.size = Vector2(228, 20)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_color_override("font_color", Color("#f2d45c"))
	_hint.add_theme_color_override("font_outline_color", Color("#140f1c"))
	_hint.add_theme_constant_override("outline_size", 2)
	add_child(_hint)

	var bottom := _panel(Vector2(4, 108), Vector2(232, 48))
	add_child(bottom)
	_status = Label.new()
	_status.position = Vector2(4, 2)
	bottom.add_child(_status)
	_menu_panel = _panel(Vector2(140, 108), Vector2(96, 48))
	add_child(_menu_panel)
	_menu_label = Label.new()
	_menu_label.position = Vector2(4, 1)
	_menu_panel.add_child(_menu_label)
	_menu_panel.visible = false


func _panel(pos: Vector2, size: Vector2) -> Panel:
	var p := Panel.new()
	p.theme = Assets.ui_theme
	p.position = pos
	p.size = size
	return p


func _setup_combat() -> void:
	for s in _sprites.values():
		s.queue_free()
	_sprites.clear()
	var heroes: Array = []
	var names: Dictionary = JsonUtil.load_dict(GameState.CHARACTERS_PATH).get("characters", {})
	for id: String in GameState.party():
		heroes.append(Combat.make_unit(id, names.get(id, {}).get("name", id), "hero", GameState.data["members"][id]))
		_add_sprite(id, id, HERO_POS.get(id, Vector2(54, 75)), "right")
	var enemies: Array = []
	var list: Array = encounter.get("enemies", [])
	for i in list.size():
		var def: Dictionary = _enemy_defs[list[i]]
		var uid := "%s_%d" % [list[i], i]
		var u := Combat.make_unit(uid, def["name"], "enemy", def["stats"])
		u["def_id"] = list[i]
		enemies.append(u)
		_add_sprite(uid, def.get("character", list[i]), ENEMY_POS[i % ENEMY_POS.size()], "left")
	combat.setup(heroes, enemies)
	_refresh_status()


func _add_sprite(uid: String, char_id: String, pos: Vector2, facing: String) -> void:
	var a := Assets.character_entry(char_id)
	var s := Sprite2D.new()
	s.texture = Assets.texture(Assets.manifest["characters"][char_id])
	s.region_enabled = true
	var order: Array = a.get("frame_order", ["down", "left", "right", "up"])
	var fw := int(a.get("frame_width", 32))
	var fh := int(a.get("frame_height", 40))
	s.region_rect = Rect2(order.find(facing) * fw, 0, fw, fh)
	s.offset = Vector2(0, -fh * 0.45)
	s.position = pos
	_field.add_child(s)
	_sprites[uid] = s


# --- Turn loop ---------------------------------------------------------------

func _run() -> void:
	_setup_combat()
	await _say("%s appeared!" % ", ".join(combat.side("enemy").map(func(u: Dictionary) -> String: return u["name"])))
	while true:
		var first := "enemy" if combat.round_number == 0 and encounter.get("enemy_first", false) else ""
		combat.begin_round(first)
		while true:
			var u := combat.next_actor()
			if u.is_empty():
				break
			_refresh_status()
			if u["side"] == "hero":
				var escaped: bool = await _hero_turn(u)
				if escaped:
					_end("escape")
					return
			else:
				await _enemy_turn(u)
			_refresh_status()
			var result := combat.outcome()
			if result == "win":
				await _win()
				return
			if result == "lose":
				await _lose()
				_setup_combat()
				await _say("Try again!")
				break


func _hero_turn(u: Dictionary) -> bool:
	while true:
		_tutorial_hint(u["id"] + "_turn")
		var items := [
			{"text": "Attack", "enabled": true, "value": "attack"},
			{"text": "Skill", "enabled": true, "value": "skill"},
			{"text": "Guard", "enabled": true, "value": "guard"},
			{"text": "Item", "enabled": true, "value": "item"},
		]
		if encounter.get("can_escape", true):
			items.append({"text": "Run", "enabled": true, "value": "run"})
		var cmd: Variant = await _choose("%s's turn" % u["name"], items, false)
		match cmd:
			"attack":
				await _attack(u, "physical", 1.0, "%s attacks!" % u["name"])
				return false
			"skill":
				var opts := []
				for sid: String in _skills:
					var sk: Dictionary = _skills[sid]
					if sk["user"] == u["id"]:
						opts.append({"text": "%s %dMP" % [sk["name"], sk["mp"]], "enabled": u["mp"] >= int(sk["mp"]), "value": sid})
				var sid: Variant = await _choose("Skill", opts, true)
				if sid == null:
					continue
				var sk: Dictionary = _skills[sid]
				combat.spend_mp(u, int(sk["mp"]))
				await _attack(u, sk["kind"], float(sk["mult"]), "%s uses %s!" % [u["name"], sk["name"]])
				return false
			"guard":
				combat.spend_token(u)
				combat.guard(u)
				await _say("%s guards. (+%d MP)" % [u["name"], Combat.GUARD_MP])
				return false
			"item":
				var defs := GameState.item_defs()
				var opts := []
				for iid: String in GameState.data["inventory"]:
					if defs.get(iid, {}).has("heal_hp"):
						opts.append({"text": "%s x%d" % [defs[iid]["name"], GameState.item_count(iid)], "enabled": true, "value": iid})
				if opts.is_empty():
					await _say("No items to use.")
					continue
				var iid: Variant = await _choose("Item", opts, true)
				if iid == null:
					continue
				var target := _lowest_hp_hero()
				if not GameState.add_item(iid, -1):
					continue
				combat.spend_token(u)
				var healed := combat.heal(target, int(defs[iid]["heal_hp"]))
				await _say("%s recovers %d HP!" % [target["name"], healed])
				return false
			"run":
				combat.spend_token(u)
				await _say("Reno and Lumi ran away!")
				return true
	return false


func _attack(u: Dictionary, kind: String, mult: float, text: String) -> void:
	combat.spend_token(u)
	var target: Dictionary = combat.side("enemy")[0]
	_msg.text = text
	_tutorial_hint("cue_attack")
	var judgement: String = await _cue(_sprites[target["id"]].position + Vector2(0, -18), u["id"], target["id"])
	var dmg := combat.hit(u, target, kind, mult, judgement)
	_log("%s -> %s %s %d" % [u["id"], target["id"], judgement, dmg])
	await _say("%s %d damage!" % [_judgement_text(judgement), dmg])
	if target["hp"] <= 0:
		_sprites[target["id"]].modulate.a = 0.25


func _enemy_turn(u: Dictionary) -> void:
	combat.spend_token(u)
	var def: Dictionary = _enemy_defs[u["def_id"]]
	var atk: Dictionary = def["attacks"][(combat.round_number - 1) % def["attacks"].size()]
	var heroes := combat.side("hero")
	var target: Dictionary = heroes[(combat.round_number - 1) % heroes.size()]
	_msg.text = "%s uses %s on %s!" % [u["name"], atk["name"], target["name"]]
	_tutorial_hint("cue_dodge")
	var judgement: String = await _cue(_sprites[target["id"]].position + Vector2(0, -18), u["id"], target["id"])
	var dmg := combat.hit(u, target, atk["kind"], float(atk["mult"]), "miss", judgement)
	_log("%s -> %s dodge:%s %d" % [u["id"], target["id"], judgement, dmg])
	if dmg == 0:
		await _say("%s dodged it completely!" % target["name"])
	else:
		await _say("%s%s takes %d damage." % ["Half dodged! " if judgement == "good" else "", target["name"], dmg])
	if target["hp"] <= 0:
		_sprites[target["id"]].modulate.a = 0.35


func _lowest_hp_hero() -> Dictionary:
	var best: Dictionary = {}
	for h in combat.side("hero"):
		if best.is_empty() or float(h["hp"]) / h["max_hp"] < float(best["hp"]) / best["max_hp"]:
			best = h
	return best


func _win() -> void:
	var xp := 0
	for e in combat.side("enemy", false):
		xp += int(_enemy_defs[e["def_id"]].get("xp", 0))
	await _say("Victory! Gained %d XP." % xp, true)
	for id: String in GameState.party():
		var m: Dictionary = GameState.data["members"][id]
		m["xp"] = int(m["xp"]) + xp
		# Prologue rule (working proposal): HP and MP refill after each battle.
		m["hp"] = m["max_hp"]
		m["mp"] = m["max_mp"]
	for k: String in encounter.get("win_key_items", []):
		GameState.add_key_item(k)
	for f: String in encounter.get("win_flags", []):
		GameState.set_flag(f)
	_end("win")


func _lose() -> void:
	await _say("Reno and Lumi are worn out...", true)
	GameState.load_from_dict(snapshot)
	_log("retry")


func _end(result: String) -> void:
	InputManager.pop_mode(InputManager.Mode.BATTLE)
	ended.emit(result)
	queue_free()


# --- Timing cues -------------------------------------------------------------

## Moves the attacker toward the target and shows the ring. Resolves on the
## first press (one input per cue) or when the window has passed.
func _cue(pos: Vector2, attacker_id: String, _target_id: String) -> String:
	var sprite: Sprite2D = _sprites[attacker_id]
	var home := sprite.position
	var t := create_tween()
	t.tween_property(sprite, "position", home.lerp(pos + Vector2(0, 18), 0.6), 0.3 / speed)
	if auto_judge != "":
		await t.finished
		_cue_result = auto_judge
	else:
		_ring.position = pos
		_ring.progress = 0.0
		_ring.visible = true
		_cue_time_us = Time.get_ticks_usec() + int(CUE_LEAD_MS * 1000.0)
		_cue_active = true
		_cue_result = await _cue_done
		_ring.visible = false
	var back := create_tween()
	back.tween_property(sprite, "position", home, 0.2 / speed)
	await back.finished
	return _cue_result


func _resolve_cue(press_us: int) -> void:
	if not _cue_active:
		return
	_cue_active = false
	var scale := float(GameState.setting("timing_window_scale"))
	_cue_done.emit(Combat.judge((press_us - _cue_time_us) / 1000.0, scale))


func _judgement_text(j: String) -> String:
	return {"perfect": "PERFECT!", "good": "Good!", "miss": ""}[j]


# --- Menus and messages ------------------------------------------------------

func _choose(title: String, items: Array, can_back: bool) -> Variant:
	_menu_items = items
	_menu_index = 0
	while _menu_index < items.size() and not items[_menu_index]["enabled"]:
		_menu_index += 1
	if _menu_index >= items.size():
		_menu_index = 0
	_msg.text = title
	_menu_panel.size.y = 6 + 9 * items.size()
	_menu_panel.position.y = 156 - _menu_panel.size.y
	_menu_open = true
	_menu_back_allowed = can_back
	_refresh_menu()
	var v: Variant = await _menu_done
	_menu_open = false
	_menu_panel.visible = false
	return v


var _menu_back_allowed := false


func _refresh_menu() -> void:
	_menu_panel.visible = true
	var lines: PackedStringArray = []
	for i in _menu_items.size():
		var it: Dictionary = _menu_items[i]
		lines.append(("> " if i == _menu_index else "  ") + it["text"] + ("" if it["enabled"] else " (x)"))
	_menu_label.text = "\n".join(lines)
	_menu_label.add_theme_constant_override("line_spacing", -2)


func _say(text: String, wait_confirm := false) -> void:
	_msg.text = text
	if wait_confirm and auto_judge == "":
		await _confirmed
	else:
		await get_tree().create_timer(0.7 / speed).timeout


func _tutorial_hint(key: String) -> void:
	if not encounter.get("tutorial", false):
		_hint.text = ""
		return
	var hints := {
		"reno_turn": "Tutorial: choose Attack.",
		"cue_attack": "Press A just as the ring closes for a stronger hit!",
		"cue_dodge": "Watch out! Press A as the ring closes to dodge.",
		"lumi_turn": "Tutorial: try Lumi's Echo Spark under Skill.",
	}
	_hint.text = hints.get(key, "") if not _hints_shown.has(key) else ""
	_hints_shown[key] = true


func _refresh_status() -> void:
	var lines: PackedStringArray = []
	for h in combat.side("hero", false):
		lines.append("%s%s  HP %d/%d  MP %d/%d" % [h["name"], " [G]" if h["guarding"] else "", h["hp"], h["max_hp"], h["mp"], h["max_mp"]])
	for e in combat.side("enemy", false):
		lines.append("%s  HP %d/%d" % [e["name"], e["hp"], e["max_hp"]])
	_status.text = "\n".join(lines)


func _log(s: String) -> void:
	battle_log.append(s)


func _process(_delta: float) -> void:
	var mode := InputManager.Mode.BATTLE
	if _cue_active:
		_ring.progress = 1.0 - (_cue_time_us - Time.get_ticks_usec()) / (CUE_LEAD_MS * 1000.0)
		if InputManager.just_pressed("confirm", mode):
			_resolve_cue(Time.get_ticks_usec())
		elif Time.get_ticks_usec() > _cue_time_us + int(Combat.GOOD_MS * 1000.0 * float(GameState.setting("timing_window_scale"))):
			_resolve_cue(Time.get_ticks_usec())
		return
	if _menu_open:
		if InputManager.just_pressed("move_down", mode):
			_move_menu(1)
		elif InputManager.just_pressed("move_up", mode):
			_move_menu(-1)
		elif InputManager.just_pressed("confirm", mode):
			var it: Dictionary = _menu_items[_menu_index]
			if it["enabled"]:
				_menu_done.emit(it["value"])
		elif _menu_back_allowed and InputManager.just_pressed("cancel", mode):
			_menu_done.emit(null)
		return
	if InputManager.just_pressed("confirm", mode):
		_confirmed.emit()


func _move_menu(step: int) -> void:
	for i in _menu_items.size():
		_menu_index = (_menu_index + step + _menu_items.size()) % _menu_items.size()
		if _menu_items[_menu_index]["enabled"]:
			break
	_refresh_menu()
