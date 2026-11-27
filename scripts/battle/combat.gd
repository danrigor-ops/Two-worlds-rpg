class_name Combat
extends RefCounted
## Turn-based combat rules, kept free of any visuals so they can be tested.
##
## Each round every living unit gets one action token. Units act in order of
## SPD (highest first), ties broken by id. Damage is deterministic:
##   physical base = max(1, 2*ATK - DEF), magical base = max(1, 2*MAG - RES)
##   base x skill multiplier x timing multiplier x guard/dodge, rounded once,
##   at least 1 when a hit lands.
## Timed hits: Perfect within 80 ms of the cue = 1.5x, Good within 180 ms = 1.2x.
## Prototype numbers from the handover, not balanced.

const PERFECT_MS := 80.0
const GOOD_MS := 180.0
const MULT := {"perfect": 1.5, "good": 1.2, "miss": 1.0}
const DODGE_MULT := {"perfect": 0.0, "good": 0.5, "miss": 1.0}
const GUARD_MULT := 0.5
const GUARD_MP := 2

var units: Array[Dictionary] = []
var round_number := 0
var _queue: Array[Dictionary] = []


## Perfect, good or miss, from how far (ms) the press was from the cue.
## scale > 1 widens both windows (accessibility setting).
static func judge(delta_ms: float, scale := 1.0) -> String:
	var d := absf(delta_ms)
	if d <= PERFECT_MS * scale:
		return "perfect"
	if d <= GOOD_MS * scale:
		return "good"
	return "miss"


static func base_damage(kind: String, attacker: Dictionary, defender: Dictionary) -> int:
	if kind == "magical":
		return maxi(1, 2 * int(attacker["mag"]) - int(defender["res"]))
	return maxi(1, 2 * int(attacker["atk"]) - int(defender["def"]))


## One rounding at the end. defense_mult covers guard and dodges.
static func final_damage(base: int, skill_mult: float, timing_mult: float, defense_mult: float) -> int:
	if defense_mult <= 0.0:
		return 0
	return maxi(1, roundi(base * skill_mult * timing_mult * defense_mult))


static func make_unit(id: String, name: String, side: String, stats: Dictionary) -> Dictionary:
	var u := {
		"id": id, "name": name, "side": side,
		"max_hp": int(stats["max_hp"]), "hp": int(stats.get("hp", stats["max_hp"])),
		"max_mp": int(stats.get("max_mp", 0)), "mp": int(stats.get("mp", stats.get("max_mp", 0))),
		"guarding": false, "token": false,
	}
	for k in ["atk", "def", "mag", "res", "spd"]:
		u[k] = int(stats[k])
	return u


func setup(heroes: Array, enemies: Array) -> void:
	units.clear()
	units.append_array(heroes)
	units.append_array(enemies)
	round_number = 0


func unit(id: String) -> Dictionary:
	for u in units:
		if u["id"] == id:
			return u
	return {}


func side(s: String, alive_only := true) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for u in units:
		if u["side"] == s and (not alive_only or u["hp"] > 0):
			out.append(u)
	return out


## Gives every living unit a token and fixes this round's order.
## first_side ("enemy" or "hero") acts before the other side this round,
## for ambushes and scripted tutorial openings.
func begin_round(first_side := "") -> Array[String]:
	round_number += 1
	_queue.clear()
	for u in units:
		u["token"] = u["hp"] > 0
		if u["token"]:
			_queue.append(u)
	_queue.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if first_side != "" and a["side"] != b["side"]:
			return a["side"] == first_side
		return a["spd"] > b["spd"] if a["spd"] != b["spd"] else a["id"] < b["id"])
	var ids: Array[String] = []
	for u in _queue:
		ids.append(u["id"])
	return ids


## The next unit that still has a token, or {} when the round is over.
## Starting a turn ends that unit's guard.
func next_actor() -> Dictionary:
	while not _queue.is_empty():
		var u: Dictionary = _queue.pop_front()
		if u["token"] and u["hp"] > 0:
			u["guarding"] = false
			return u
	return {}


func spend_token(u: Dictionary) -> bool:
	if not u["token"]:
		return false
	u["token"] = false
	return true


func spend_mp(u: Dictionary, cost: int) -> bool:
	if u["mp"] < cost:
		return false
	u["mp"] -= cost
	return true


## Applies a hit. timing is the attacker's cue result; dodge is the
## defender's (for enemy attacks on heroes). Returns damage dealt.
func hit(attacker: Dictionary, target: Dictionary, kind: String, skill_mult: float, timing: String, dodge := "miss") -> int:
	var defense: float = DODGE_MULT[dodge]
	if target["guarding"]:
		defense *= GUARD_MULT
	var dmg := final_damage(base_damage(kind, attacker, target), skill_mult, MULT[timing], defense)
	target["hp"] = maxi(0, int(target["hp"]) - dmg)
	return dmg


func guard(u: Dictionary) -> void:
	u["guarding"] = true
	u["mp"] = mini(u["max_mp"], u["mp"] + GUARD_MP)


func heal(u: Dictionary, amount: int) -> int:
	var before: int = u["hp"]
	u["hp"] = mini(u["max_hp"], before + amount)
	return u["hp"] - before


func outcome() -> String:
	if side("enemy").is_empty():
		return "win"
	if side("hero").is_empty():
		return "lose"
	return ""
