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
		})
	for npc: Dictionary in d.get("npcs", []):
		var n := npc.duplicate()
		n["cell"] = Vector2i(int(npc["x"]), int(npc["y"]))
		m.npcs.append(n)
	m.on_enter = d.get("on_enter", [])
	for sign: Dictionary in d.get("signs", []):
		m.signs[Vector2i(int(sign["x"]), int(sign["y"]))] = sign.get("lines", [])
	return m


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func tile_name(cell: Vector2i) -> String:
	if not in_bounds(cell) or cell.y >= rows.size() or cell.x >= rows[cell.y].length():
		return ""
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
		elif not door_at(c).is_empty():
			e.append(p + "spawn '%s' at %s is on a door and would re-trigger it" % [s, c])
		if spawns[s]["facing"] not in ["down", "left", "right", "up"]:
			e.append(p + "spawn '%s' has a bad facing" % s)
	for door in doors:
		if tile_name(door["cell"]) not in ["door", "exit"]:
			e.append(p + "door '%s' at %s is not on a door tile" % [door["id"], door["cell"]])
	for npc in npcs:
		if not is_walkable(npc["cell"]):
			e.append(p + "npc '%s' at %s is not on a walkable tile" % [npc.get("id", "?"), npc["cell"]])
		for t: Dictionary in npc.get("talk", []):
			if not Dialogue.has_scene(t.get("scene", "")):
				e.append(p + "npc '%s' uses missing scene '%s'" % [npc.get("id", "?"), t.get("scene", "")])
	for t: Dictionary in on_enter:
		if not Dialogue.has_scene(t.get("scene", "")):
			e.append(p + "on_enter uses missing scene '%s'" % t.get("scene", ""))
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
