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
const HERO_SLOTS := [Vector2(66, 58), Vector2(46, 80), Vector2(26, 102)]   # three active heroes
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
var _team: Dictionary = {}
var _phase := {}   # enemy uid -> phase index

signal _menu_done(value: Variant)
signal _cue_done(result: String)
signal _confirmed


func start(id: String) -> void:
	var data := JsonUtil.load_dict(ENEMIES_PATH)
	_enemy_defs = data.get("enemies", {})
	encounter = data.get("encounters", {}).get(id, {})
	encounter_id = id
	var sk := JsonUtil.load_dict(SKILLS_PATH)
	_skills = sk.get("skills", {})
	_team = sk.get("team", {})
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
	_status.position = Vector2(4, 1)
	_status.add_theme_constant_override("line_spacing", -3)
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
	var active := GameState.active_party()
	for id: String in active:
		var stats: Dictionary = GameState.data["members"][id].duplicate()
		var bonus := GameState.equip_bonus(id)
		for k: String in bonus:
			stats[k] = int(stats[k]) + int(bonus[k])
		heroes.append(Combat.make_unit(id, names.get(id, {}).get("name", id), "hero", stats))
		var pos: Vector2 = HERO_POS.get(id, Vector2(54, 75)) if active.size() <= 2 else HERO_SLOTS[active.find(id)]
		_add_sprite(id, id, pos, "right")
	var enemies: Array = []
	var list: Array = encounter.get("enemies", [])
	for i in list.size():
		var def: Dictionary = _enemy_defs[list[i]]
		var uid := "%s_%d" % [list[i], i]
		var u := Combat.make_unit(uid, def["name"], "enemy", def["stats"])
		u["def_id"] = list[i]
		u["immune"] = def.get("immune", [])
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
			if u["hp"] > 0 and Combat.has_status(u, "poison"):
				# Poison (Chapter 4): 6% of max HP after each of the unit's own actions.
				var pdmg := Combat.poison_damage(u)
				u["hp"] = maxi(0, int(u["hp"]) - pdmg)
				_log("%s poison %d" % [u["id"], pdmg])
				await _say("%s takes %d poison damage." % [u["name"], pdmg])
			Combat.tick_status(u)
			_refresh_status()
			for e in combat.side("enemy"):
				await _check_phase(e)
			for e in combat.side("enemy"):
				if e.has("summoner") and combat.unit(e["summoner"])["hp"] <= 0:
					e["hp"] = 0
					_sprites[e["id"]].modulate.a = 0.0
					await _say("The %s flutters away." % e["name"])
			var result := combat.outcome()
			if _story_end_reached():
				result = "win"
			if result == "win":
				await _win()
				return
			if result == "lose":
				await _lose()
				_phase.clear()
				_setup_combat()
				await _say("Try again!")
				break


func _hero_turn(u: Dictionary) -> bool:
	while true:
		_tutorial_hint(u["id"] + "_turn")
		var fogged := Combat.has_status(u, "fog")
		if fogged:
			_hint.text = "Memory Fog: %s can't remember any skills this turn." % u["name"]
		var items := [
			{"text": "Attack", "enabled": true, "value": "attack"},
			{"text": "Skill", "enabled": not fogged, "value": "skill"},
			{"text": "Guard", "enabled": true, "value": "guard"},
			{"text": "Item", "enabled": true, "value": "item"},
		]
		for tid: String in _team:
			var t: Dictionary = _team[tid]
			if t.has("requires_flag") and not GameState.get_flag(t["requires_flag"]):
				continue
			if u["id"] in t["users"] and t["users"].all(func(id: String) -> bool: return not combat.unit(id).is_empty()):
				var team_ok: bool = combat.can_team(t["users"], int(t["mp_each"])) and not (t["users"] as Array).any(func(id: String) -> bool: return Combat.has_status(combat.unit(id), "fog"))
				items.insert(2, {"text": t.get("short", "Team"), "enabled": team_ok, "value": "team:" + tid})
		if encounter.get("can_escape", true):
			items.append({"text": "Run", "enabled": true, "value": "run"})
		var cmd: Variant = await _choose("%s's turn" % u["name"], items, false)
		if str(cmd).begins_with("team:"):
			var tdef: Dictionary = _team[str(cmd).trim_prefix("team:")]
			if tdef.get("kind", "") == "support":
				await _team_support(tdef)
			else:
				await _team_attack(tdef)
			return false
		match cmd:
			"attack":
				await _attack(u, "physical", 1.0, "%s attacks!" % u["name"])
				return false
			"skill":
				var opts := []
				for sid: String in _skills:
					var sk: Dictionary = _skills[sid]
					if sk["user"] == u["id"] and (not sk.has("requires_flag") or GameState.get_flag(sk["requires_flag"])):
						opts.append({"text": "%s %dMP" % [sk["name"], sk["mp"]], "enabled": u["mp"] >= int(sk["mp"]), "value": sid})
				var sid: Variant = await _choose("Skill", opts, true)
				if sid == null:
					continue
				var sk: Dictionary = _skills[sid]
				combat.spend_mp(u, int(sk["mp"]))
				if sk["kind"] == "heal":
					await _heal(u, sk)
				elif sk.get("target", "one") == "all":
					await _attack_all(u, sk["kind"], float(sk["mult"]), "%s uses %s!" % [u["name"], sk["name"]])
				else:
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
					if defs.get(iid, {}).has("heal_hp") or defs.get(iid, {}).has("heal_mp"):
						opts.append({"text": "%s x%d" % [defs[iid]["name"], GameState.item_count(iid)], "enabled": true, "value": iid})
				if opts.is_empty():
					await _say("No items to use.")
					continue
				var iid: Variant = await _choose("Item", opts, true)
				if iid == null:
					continue
				var hp := int(defs[iid].get("heal_hp", 0))
				var mp := int(defs[iid].get("heal_mp", 0))
				var target := _lowest_hp_hero() if hp > 0 else _lowest_mp_hero()
				if not GameState.add_item(iid, -1):
					continue
				combat.spend_token(u)
				var healed := combat.heal(target, hp)
				var before: int = target["mp"]
				target["mp"] = mini(target["max_mp"], before + mp)
				var parts: Array[String] = []
				if hp > 0:
					parts.append("%d HP" % healed)
				if mp > 0:
					parts.append("%d MP" % (target["mp"] - before))
				await _say("%s recovers %s!" % [target["name"], " and ".join(parts)])
				return false
			"run":
				combat.spend_token(u)
				await _say("Reno and Lumi ran away!")
				return true
	return false


## With more than one enemy standing, the player picks who to hit.
func _pick_target() -> Dictionary:
	var foes := combat.side("enemy")
	if foes.size() == 1:
		return foes[0]
	var opts := []
	for e in foes:
		opts.append({"text": "%s %d/%d" % [e["name"], e["hp"], e["max_hp"]], "enabled": true, "value": e["id"]})
	var id: Variant = await _choose("Target", opts, false)
	return combat.unit(str(id))


func _attack(u: Dictionary, kind: String, mult: float, text: String) -> void:
	var target: Dictionary = await _pick_target()
	combat.spend_token(u)
	_msg.text = text
	_tutorial_hint("cue_attack")
	var judgement: String = await _cue(_sprites[target["id"]].position + Vector2(0, -18), u["id"], target["id"])
	var dmg := combat.hit(u, target, kind, mult, judgement)
	_log("%s -> %s %s %d" % [u["id"], target["id"], judgement, dmg])
	await _say("%s %d damage!%s" % [_judgement_text(judgement), dmg, " (It's guarding.)" if target["guarding"] else ""])
	if target["hp"] <= 0:
		_sprites[target["id"]].modulate.a = 0.25


## Healing skills (Maris): MAG x mult HP to the weakest ally, or to everyone
## standing with target "all". No timing cue: healing always lands in full.
func _heal(u: Dictionary, sk: Dictionary) -> void:
	combat.spend_token(u)
	var allies := combat.side("hero")
	var targets: Array = allies
	if sk.get("target", "one") != "all":
		allies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["hp"]) / a["max_hp"] < float(b["hp"]) / b["max_hp"])
		targets = [allies[0]]
	var amount := roundi(float(u["mag"]) * float(sk["mult"]))
	var parts: PackedStringArray = []
	for t: Dictionary in targets:
		var before := int(t["hp"])
		t["hp"] = mini(int(t["max_hp"]), before + amount)
		parts.append("%s +%d" % [t["name"], int(t["hp"]) - before])
		_log("%s heal %s %d" % [u["id"], t["id"], int(t["hp"]) - before])
	await _say("%s uses %s! %s HP." % [u["name"], sk["name"], ", ".join(parts)])


## Area skills (Ripple Echo): one cue, every standing enemy is hit.
func _attack_all(u: Dictionary, kind: String, mult: float, text: String) -> void:
	combat.spend_token(u)
	var foes := combat.side("enemy")
	_msg.text = text
	var judgement: String = await _cue(Vector2(186, 56), u["id"], foes[0]["id"])
	var parts: PackedStringArray = []
	for t in foes:
		var dmg := combat.hit(u, t, kind, mult, judgement)
		_log("%s -> %s %s %d (all)" % [u["id"], t["id"], judgement, dmg])
		parts.append("%s %d" % [t["name"], dmg])
		if t["hp"] <= 0:
			_sprites[t["id"]].modulate.a = 0.25
	await _say("%s%s." % [(_judgement_text(judgement) + " ") if judgement != "miss" else "", ", ".join(parts)])


func _team_attack(t: Dictionary) -> void:
	var users: Array = t["users"]
	var target: Dictionary = await _pick_target()
	combat.pay_team(users, int(t["mp_each"]))
	var judgements: Array[String] = []
	for i in int(t["cues"]):
		_msg.text = "%s! (%d/%d)" % [t["name"], i + 1, int(t["cues"])]
		judgements.append(await _cue(_sprites[target["id"]].position + Vector2(0, -18), users[i % users.size()], target["id"]))
	var dmg := combat.team_hit(users, target, float(t["mult"]), judgements)
	_log("team %s %s %d" % [",".join(users), ",".join(judgements), dmg])
	await _say("%s! %d damage!" % [t["name"], dmg])
	if target["hp"] <= 0:
		_sprites[target["id"]].modulate.a = 0.25


## Guardian Bloom: both heroes' turns, two cues. Shielded always applies;
## the heal is 15% of each hero's max HP, or 10% if a cue was missed.
func _team_support(t: Dictionary) -> void:
	var users: Array = t["users"]
	combat.pay_team(users, int(t["mp_each"]))
	var judgements: Array[String] = []
	for i in int(t["cues"]):
		_msg.text = "%s! (%d/%d)" % [t["name"], i + 1, int(t["cues"])]
		var who: String = users[i % users.size()]
		judgements.append(await _cue(_sprites[who].position + Vector2(0, -18), who, who))
	var pct := float(t.get("heal_pct_miss", 10)) if "miss" in judgements else float(t.get("heal_pct", 15))
	var parts: PackedStringArray = []
	for h in combat.side("hero"):
		Combat.add_status(h, t.get("applies", "shielded"), int(t.get("turns", 2)), true)
		var healed := combat.heal(h, roundi(h["max_hp"] * pct / 100.0))
		parts.append("%s +%d HP" % [h["name"], healed])
	_log("bloom %s %d%%" % [",".join(judgements), int(pct)])
	await _say("%s! Shielded. %s" % [t["name"], ", ".join(parts)])


## Story bosses end at a threshold instead of being knocked out.
func _story_end_reached() -> bool:
	for e in combat.side("enemy"):
		var def: Dictionary = _enemy_defs.get(e.get("def_id", ""), {})
		if def.has("end_below") and float(e["hp"]) / e["max_hp"] <= float(def["end_below"]):
			return true
	return false


## Bosses change attacks as their HP drops (phases in enemies.json).
func _current_attacks(u: Dictionary) -> Array:
	var def: Dictionary = _enemy_defs[u["def_id"]]
	if not def.has("phases"):
		return def["attacks"]
	var share := float(u["hp"]) / float(u["max_hp"])
	var phases: Array = def["phases"]
	var idx := phases.size() - 1
	for i in phases.size():
		if share > float(phases[i]["above"]):
			idx = i
			break
	return phases[idx]["attacks"]


func _current_phase(u: Dictionary) -> Dictionary:
	var def: Dictionary = _enemy_defs[u["def_id"]]
	if not def.has("phases"):
		return {}
	var share := float(u["hp"]) / float(u["max_hp"])
	var phases: Array = def["phases"]
	for i in phases.size():
		if share > float(phases[i]["above"]):
			return phases[i]
	return phases[phases.size() - 1]


func _check_phase(u: Dictionary) -> void:
	var def: Dictionary = _enemy_defs.get(u.get("def_id", ""), {})
	if not def.has("phases") or u["hp"] <= 0:
		return
	var share := float(u["hp"]) / float(u["max_hp"])
	var phases: Array = def["phases"]
	var idx := phases.size() - 1
	for i in phases.size():
		if share > float(phases[i]["above"]):
			idx = i
			break
	if idx <= int(_phase.get(u["id"], 0)):
		return
	_phase[u["id"]] = idx
	u["turn_in_phase"] = 0
	u.erase("charging")
	var ph: Dictionary = phases[idx]
	_log("phase %d" % idx)
	if ph.has("enter_text"):
		await _say(ph["enter_text"])
	if ph.has("teach_flag"):
		GameState.set_flag(ph["teach_flag"])
	if ph.has("ensure_mp"):
		# The first team skill must be possible: top both heroes up to its cost.
		for h in combat.side("hero"):
			h["mp"] = maxi(int(h["mp"]), int(ph["ensure_mp"]))
		_refresh_status()
	if ph.get("hint", "") == "cyclone":
		_hint.text = "Choose Team: Spirit Cyclone uses both heroes' turns. Press A on all three rings!"


func _enemy_turn(u: Dictionary) -> void:
	combat.spend_token(u)
	var ph := _current_phase(u)
	if ph.has("summon") and not _has_summon(u):
		await _summon(u, ph["summon"])
		return
	var atk: Dictionary
	if u.has("charging"):
		atk = u["charging"]
		u.erase("charging")
	else:
		var attacks := _current_attacks(u)
		# Moves cycle in order, starting again whenever a new phase begins,
		# so a phase's opening move (Final Stop's warning) always comes first.
		var n := int(u.get("turn_in_phase", 0))
		u["turn_in_phase"] = n + 1
		atk = attacks[(n + int(u.get("offset", 0))) % attacks.size()]
		if atk.get("telegraph", false):
			# Telegraphed: announced now, lands on its next turn. Guard or dodge it.
			u["charging"] = atk
			_log("%s telegraph %s" % [u["id"], atk["name"]])
			await _say(atk.get("telegraph_text", "%s is getting ready to use %s!" % [u["name"], atk["name"]]))
			return
	if atk.get("guard", false):
		combat.guard(u)
		_log("%s guard" % u["id"])
		await _say("%s uses %s! It braces itself." % [u["name"], atk["name"]])
		return
	if atk.get("support", "") == "haste":
		for e in combat.side("enemy"):
			if e != u:
				e["haste"] = true
		_log("%s haste" % u["id"])
		await _say("%s uses %s! Its friends will move first next round." % [u["name"], atk["name"]])
		return
	var heroes := combat.side("hero")
	var targets: Array = heroes if atk.get("target", "one") == "all" else [heroes[(combat.round_number - 1) % heroes.size()]]
	var aim: Dictionary = targets[0]
	_msg.text = "%s uses %s%s!" % [u["name"], atk["name"], "" if targets.size() > 1 else " on " + aim["name"]]
	if atk.get("kind", "") == "status":
		var landed := Combat.add_status(aim, atk["applies"], int(atk.get("turns", 1)))
		_log("%s -> %s status %s" % [u["id"], aim["id"], atk["applies"]])
		await _say("%s %s" % [aim["name"], STATUS_TEXT.get(atk["applies"], "is affected!") if landed else "isn't affected."])
		return
	_tutorial_hint("cue_dodge")
	var judgement: String = await _cue(_sprites[aim["id"]].position + Vector2(0, -18), u["id"], aim["id"])
	var parts: PackedStringArray = []
	for target: Dictionary in targets:
		var dmg := combat.hit(u, target, atk["kind"], float(atk["mult"]), "miss", judgement)
		_log("%s -> %s dodge:%s %d" % [u["id"], target["id"], judgement, dmg])
		parts.append("%s dodged" % target["name"] if dmg == 0 else "%s takes %d" % [target["name"], dmg])
		if target["hp"] <= 0:
			_sprites[target["id"]].modulate.a = 0.35
		elif dmg > 0 and atk.has("applies") and Combat.add_status(target, atk["applies"], int(atk.get("turns", 1))):
			parts.append("%s %s" % [target["name"], STATUS_TEXT.get(atk["applies"], "")])
	await _say(("Half dodged! " if judgement == "good" else "") + ", ".join(parts) + ".")


const STATUS_TEXT := {
	"poison": "is poisoned!",
	"slow": "is slowed!",
	"fog": "forgets their skills for a turn!",
	"shielded": "is shielded!",
	"soaked": "is soaked! (DEF down)",
}


func _has_summon(u: Dictionary) -> bool:
	for e in combat.side("enemy"):
		if e.get("summoner", "") == u["id"]:
			return true
	return false


## Boss phase summons: one at a time, worth no XP (no farming).
func _summon(u: Dictionary, def_id: String) -> void:
	var def: Dictionary = _enemy_defs[def_id]
	var uid := "%s_s%d" % [def_id, combat.round_number]
	var m := Combat.make_unit(uid, def["name"], "enemy", def["stats"])
	m["def_id"] = def_id
	m["summoner"] = u["id"]
	m["no_xp"] = true
	m["token"] = false
	m["offset"] = 1
	combat.units.append(m)
	if _sprites.has(uid):
		_sprites[uid].queue_free()
	_add_sprite(uid, def.get("character", def_id), ENEMY_POS[1], "left")
	_log("%s summon %s" % [u["id"], def_id])
	await _say("%s calls a %s!" % [u["name"], def["name"]])
	_refresh_status()


func _lowest_hp_hero() -> Dictionary:
	var best: Dictionary = {}
	for h in combat.side("hero"):
		if best.is_empty() or float(h["hp"]) / h["max_hp"] < float(best["hp"]) / best["max_hp"]:
			best = h
	return best


func _lowest_mp_hero() -> Dictionary:
	var best: Dictionary = {}
	for h in combat.side("hero"):
		if best.is_empty() or float(h["mp"]) / max(1, h["max_mp"]) < float(best["mp"]) / max(1, best["max_mp"]):
			best = h
	return best


func _win() -> void:
	var xp := 0
	for e in combat.side("enemy", false):
		if not e.get("no_xp", false):
			xp += int(_enemy_defs[e["def_id"]].get("xp", 0))
	await _say("Victory! Gained %d XP." % xp, true)
	var ups: Array[String] = []
	for id: String in GameState.party():
		var m: Dictionary = GameState.data["members"][id]
		ups.append_array(GameState.gain_xp(id, xp))
		# Prologue rule (working proposal): HP and MP refill after each battle.
		m["hp"] = m["max_hp"]
		m["mp"] = m["max_mp"]
	for line in ups:
		await _say(line, true)
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
	_menu_panel.size.y = 6 + 10 * items.size()
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
	var heroes := combat.side("hero", false)
	for h in heroes:
		lines.append("%s%s  HP %d/%d  MP %d/%d" % [h["name"], _tags(h), h["hp"], h["max_hp"], h["mp"], h["max_mp"]])
	var foes := combat.side("enemy", false).filter(func(e: Dictionary) -> bool: return e["hp"] > 0 or not e.has("summoner"))
	if heroes.size() >= 3:
		# Three heroes: the foes share one line.
		lines.append("  ".join(foes.slice(0, 2).map(func(e: Dictionary) -> String: return "%s%s %d" % [e["name"], _tags(e), e["hp"]])))
	else:
		for e: Dictionary in foes.slice(0, 2):
			lines.append("%s%s  HP %d/%d" % [e["name"], _tags(e), e["hp"], e["max_hp"]])
	_status.text = "\n".join(lines)


static func _tags(u: Dictionary) -> String:
	var t := " [G]" if u["guarding"] else ""
	for k: String in u["status"]:
		t += " [%s]" % {"slow": "Slow", "shielded": "Shield", "fog": "Fog", "soaked": "Soak", "poison": "Psn"}.get(k, k)
	return t


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
