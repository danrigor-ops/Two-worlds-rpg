class_name MapData
extends RefCounted
## One map's placeholder geometry, loaded from content/maps/<ID>.json.
## The ASCII rows are a stand-in until painted tilemaps exist.

const MAP_DIR := "res://content/maps/"
const TILES_PATH := "res://content/tiles.json"
const TILE := 16

static var _tile_defs: Dictionary = {}

var id := ""
var name := ""
var status := ""
var width := 0
var height := 0
var rows: PackedStringArray = []
var legend: Dictionary = {}
var spawns: Dictionary = {}   # name -> {"cell": Vector2i, "facing": String}
var doors: Array[Dictionary] = []  # {"id", "cell", "to_map", "to_spawn", "one_way"}
var npcs: Array[Dictionary] = []
var signs: Dictionary = {}    # Vector2i -> Array of lines
var on_enter: Array = []      # [{"scene", "if_flags", "if_not_flags"}]
var objects: Dictionary = {}  # Vector2i -> {"id", "talk": [...]}  (interactable solid tiles)
var overrides: Array = []     # [{"if_flags", "tile", "cells": [Vector2i]}]
var triggers: Array = []      # [{"cells": [Vector2i], "scene", "if_flags", "if_not_flags"}]
var no_autosave := false
var tint := ""             # a colour over the whole map (night scenes)
var tint_until_flag := ""  # the tint goes once this flag is set
var movables: Dictionary = {}  # Vector2i -> tile name (crates Root Grip can pull)
var _override_tiles: Dictionary = {}  # Vector2i -> tile name currently replaced


static func tile_defs() -> Dictionary:
	if _tile_defs.is_empty():
		_tile_defs = JsonUtil.load_dict(TILES_PATH).get("tiles", {})
	return _tile_defs


static func exists(map_id: String) -> bool:
	return FileAccess.file_exists(MAP_DIR + map_id + ".json")


static func all_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for f in DirAccess.get_files_at(MAP_DIR):
		if f.ends_with(".json"):
			ids.append(f.get_basename())
	return ids


static func load_map(map_id: String) -> MapData:
	var d := JsonUtil.load_dict(MAP_DIR + map_id + ".json")
	var m := MapData.new()
	m.id = d.get("id", map_id)
	m.name = d.get("name", map_id)
	m.status = d.get("status", "")
	m.no_autosave = d.get("no_autosave", false)
	m.tint = d.get("tint", "")
	m.tint_until_flag = d.get("tint_until_flag", "")
	m.width = int(d.get("width", 0))
	m.height = int(d.get("height", 0))
	m.rows = PackedStringArray(d.get("rows", []))
	m.legend = d.get("legend", {})
	for s: String in d.get("spawns", {}):
		var sp: Dictionary = d["spawns"][s]
		m.spawns[s] = {"cell": Vector2i(int(sp["x"]), int(sp["y"])), "facing": sp.get("facing", "down")}
	for door: Dictionary in d.get("doors", []):
		m.doors.append({
			"id": door.get("id", ""),
			"cell": Vector2i(int(door["x"]), int(door["y"])),
			"to_map": door.get("to_map", ""),
			"to_spawn": door.get("to_spawn", ""),
			"one_way": door.get("one_way", false),
			"require": door.get("require", []),
		})
	for npc: Dictionary in d.get("npcs", []):
		var n := npc.duplicate()
		n["cell"] = Vector2i(int(npc["x"]), int(npc["y"]))
		m.npcs.append(n)
	m.on_enter = d.get("on_enter", [])
	for o: Dictionary in d.get("objects", []):
		m.objects[Vector2i(int(o["x"]), int(o["y"]))] = o
	for o: Dictionary in d.get("overrides", []):
		var ov := o.duplicate()
		ov["cells"] = _cells(o.get("cells", []))
		m.overrides.append(ov)
	for t: Dictionary in d.get("triggers", []):
		var tr := t.duplicate()
		tr["cells"] = _cells(t.get("cells", []))
		m.triggers.append(tr)
	for mv: Dictionary in d.get("movables", []):
		m.movables[Vector2i(int(mv["x"]), int(mv["y"]))] = mv.get("tile", "goods_crate")
	for sign: Dictionary in d.get("signs", []):
		m.signs[Vector2i(int(sign["x"]), int(sign["y"]))] = sign.get("lines", [])
	return m


static func _cells(list: Array) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for c: Array in list:
		out.append(Vector2i(int(c[0]), int(c[1])))
	return out


## Swaps in override tiles whose flags are set (revealed stones, a rebuilt
## bridge). has_flag is a Callable(String) -> bool. Returns the cells that changed.
func apply_overrides(has_flag: Callable) -> Array[Vector2i]:
	var next := {}
	for ov: Dictionary in overrides:
		if (ov.get("if_flags", []) as Array).all(has_flag) and not (ov.get("if_not_flags", []) as Array).any(has_flag):
			for c: Vector2i in ov["cells"]:
				next[c] = ov["tile"]
	var changed: Array[Vector2i] = []
	for c: Vector2i in next:
		if _override_tiles.get(c, "") != next[c]:
			changed.append(c)
	for c: Vector2i in _override_tiles:
		if not next.has(c):
			changed.append(c)
	_override_tiles = next
	return changed


func move_movable(from: Vector2i, to: Vector2i) -> void:
	movables[to] = movables[from]
	movables.erase(from)


func is_pit(cell: Vector2i) -> bool:
	return tile_name(cell) == "pit"


func trigger_at(cell: Vector2i) -> Array:
	return triggers.filter(func(t: Dictionary) -> bool: return cell in t["cells"])


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func tile_name(cell: Vector2i) -> String:
	if not in_bounds(cell) or cell.y >= rows.size() or cell.x >= rows[cell.y].length():
		return ""
	if movables.has(cell):
		return movables[cell]
	if _override_tiles.has(cell):
		return _override_tiles[cell]
	return legend.get(rows[cell.y][cell.x], "")


func is_walkable(cell: Vector2i) -> bool:
	var t := tile_name(cell)
	return t != "" and tile_defs().has(t) and not tile_defs()[t].get("solid", false)


func door_at(cell: Vector2i) -> Dictionary:
	for door in doors:
		if door["cell"] == cell:
			return door
	return {}


func pixel_size() -> Vector2i:
	return Vector2i(width * TILE, height * TILE)


## Where a character's feet stand when placed on a cell.
static func cell_to_feet(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE - 4.0)


static func feet_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))


## Checks one map on its own. Returns readable problems.
func validate_self() -> Array[String]:
	var e: Array[String] = []
	var p := "%s: " % id
	if rows.size() != height:
		e.append(p + "has %d rows, expected %d" % [rows.size(), height])
	for y in rows.size():
		if rows[y].length() != width:
			e.append(p + "row %d is %d wide, expected %d" % [y, rows[y].length(), width])
		for ch in rows[y]:
			if not legend.has(ch):
				e.append(p + "row %d uses '%s' which is not in the legend" % [y, ch])
				break
	for ch: String in legend:
		if not tile_defs().has(legend[ch]):
			e.append(p + "legend '%s' -> unknown tile '%s'" % [ch, legend[ch]])
	if width * TILE < 240 or height * TILE < 160:
		e.append(p + "is smaller than one screen (240x160)")
	for s: String in spawns:
		var c: Vector2i = spawns[s]["cell"]
		if not is_walkable(c):
			e.append(p + "spawn '%s' at %s is not on a walkable tile" % [s, c])
		elif is_pit(c):
			e.append(p + "spawn '%s' at %s is over a pit" % [s, c])
		elif not door_at(c).is_empty():
			e.append(p + "spawn '%s' at %s is on a door and would re-trigger it" % [s, c])
		if spawns[s]["facing"] not in ["down", "left", "right", "up"]:
			e.append(p + "spawn '%s' has a bad facing" % s)
	for door in doors:
		if tile_name(door["cell"]) not in ["door", "exit", "gate", "veil"]:
			e.append(p + "door '%s' at %s is not on a door tile" % [door["id"], door["cell"]])
		for r: Dictionary in door["require"]:
			if not Dialogue.has_scene(r.get("else_scene", "")):
				e.append(p + "door '%s' uses missing scene '%s'" % [door["id"], r.get("else_scene", "")])
	for npc in npcs:
		if not is_walkable(npc["cell"]):
			e.append(p + "npc '%s' at %s is not on a walkable tile" % [npc.get("id", "?"), npc["cell"]])
		for t: Dictionary in npc.get("talk", []):
			if not Dialogue.has_scene(t.get("scene", "")):
				e.append(p + "npc '%s' uses missing scene '%s'" % [npc.get("id", "?"), t.get("scene", "")])
	for npc in npcs:
		if npc.has("encounter"):
			var enc: Dictionary = npc["encounter"]
			if not JsonUtil.load_dict("res://content/enemies.json").get("encounters", {}).has(enc.get("id", "")):
				e.append(p + "npc '%s' uses missing encounter '%s'" % [npc.get("id", "?"), enc.get("id", "")])
			for k in ["intro_scene", "outro_scene"]:
				if enc.has(k) and not Dialogue.has_scene(enc[k]):
					e.append(p + "npc '%s' uses missing scene '%s'" % [npc.get("id", "?"), enc[k]])
	for cell: Vector2i in objects:
		if not (tile_defs().get(tile_name(cell), {}).get("solid", false)):
			e.append(p + "object '%s' at %s should sit on a solid tile" % [objects[cell].get("id", "?"), cell])
		for t: Dictionary in objects[cell].get("talk", []):
			if not Dialogue.has_scene(t.get("scene", "")):
				e.append(p + "object '%s' uses missing scene '%s'" % [objects[cell].get("id", "?"), t.get("scene", "")])
	for ov: Dictionary in overrides:
		if not tile_defs().has(ov.get("tile", "")):
			e.append(p + "override uses unknown tile '%s'" % ov.get("tile", ""))
		for c: Vector2i in ov["cells"]:
			if not in_bounds(c):
				e.append(p + "override cell %s is outside the map" % c)
	for tr: Dictionary in triggers:
		if not Dialogue.has_scene(tr.get("scene", "")):
			e.append(p + "trigger uses missing scene '%s'" % tr.get("scene", ""))
		for c: Vector2i in tr["cells"]:
			if not is_walkable(c):
				e.append(p + "trigger cell %s can't be walked on" % c)
	for t: Dictionary in on_enter:
		if not Dialogue.has_scene(t.get("scene", "")):
			e.append(p + "on_enter uses missing scene '%s'" % t.get("scene", ""))
	for cell: Vector2i in movables:
		if legend.get(rows[cell.y][cell.x], "") == "" or tile_defs().get(legend[rows[cell.y][cell.x]], {}).get("solid", true):
			e.append(p + "movable at %s must start on walkable ground" % cell)
	for cell: Vector2i in signs:
		if tile_name(cell) != "sign":
			e.append(p + "sign at %s is not on a sign tile" % cell)
	return e


## Checks every map plus the links between them: each door leads to a real
## spawn on a walkable tile, and the other map has a door back.
static func validate_all(start_map := "KA-02", start_spawn := "start") -> Array[String]:
	var e: Array[String] = []
	var maps := {}
	for map_id in all_ids():
		var m := load_map(map_id)
		if m.id != map_id:
			e.append("%s.json declares id %s" % [map_id, m.id])
		maps[m.id] = m
		e.append_array(m.validate_self())
	for map_id: String in maps:
		var m: MapData = maps[map_id]
		for door in m.doors:
			var target: MapData = maps.get(door["to_map"])
			if target == null:
				e.append("%s: door '%s' leads to missing map %s" % [map_id, door["id"], door["to_map"]])
				continue
			if not target.spawns.has(door["to_spawn"]):
				e.append("%s: door '%s' leads to missing spawn %s:%s" % [map_id, door["id"], door["to_map"], door["to_spawn"]])
			if not door["one_way"]:
				var back := false
				for d2 in target.doors:
					if d2["to_map"] == map_id:
						back = true
				if not back:
					e.append("%s: door '%s' has no return door in %s" % [map_id, door["id"], door["to_map"]])
	if not maps.has(start_map) or not maps[start_map].spawns.has(start_spawn):
		e.append("new game spawn %s:%s does not exist" % [start_map, start_spawn])
	return e
