extends Node
## Asset manifest. Every asset has an ID; if its file is missing we generate a
## clearly placeholder texture instead. Real art can be dropped in later by
## setting "path" in content/asset_manifest.json, with no code changes.

const MANIFEST_PATH := "res://content/asset_manifest.json"
const TILES_PATH := "res://content/tiles.json"
const TILE := 16
const STATUSES := ["PLACEHOLDER", "CONCEPT", "CANDIDATE", "APPROVED", "INTEGRATED", "TESTED"]

# UI palette from the handover: deep-blue panels, cream text, gold highlight.
const UI_PANEL := Color("#1d2b5a")
const UI_TEXT := Color("#f4ecd2")
const UI_GOLD := Color("#e8b84a")

var manifest: Dictionary = {}
var tiles: Dictionary = {}
var ui_theme: Theme
var _textures := {}
var _tileset: TileSet


func _ready() -> void:
	manifest = JsonUtil.load_dict(MANIFEST_PATH)
	tiles = JsonUtil.load_dict(TILES_PATH).get("tiles", {})
	ui_theme = _build_theme()
	get_tree().root.theme = ui_theme
	# Controls under a CanvasLayer don't inherit the window theme, so also
	# make the engine fallbacks match.
	ThemeDB.fallback_font_size = 8
	ThemeDB.get_default_theme().default_font_size = 8


func entry(asset_id: String) -> Dictionary:
	return manifest.get("assets", {}).get(asset_id, {})


func character_entry(member_id: String) -> Dictionary:
	return entry(manifest.get("characters", {}).get(member_id, ""))


func is_placeholder(asset_id: String) -> bool:
	return entry(asset_id).get("status", "PLACEHOLDER") == "PLACEHOLDER"


## Problems with the manifest itself (missing fields, unknown status, broken paths).
func validate() -> Array[String]:
	var e: Array[String] = []
	var assets: Dictionary = manifest.get("assets", {})
	if assets.is_empty():
		e.append("asset manifest has no assets")
	for id: String in assets:
		var a: Dictionary = assets[id]
		if a.get("status") not in STATUSES:
			e.append("asset %s has unknown status %s" % [id, str(a.get("status"))])
		var path: String = a.get("path", "")
		if path != "" and not ResourceLoader.exists(path):
			e.append("asset %s points at missing file %s" % [id, path])
		if a.get("kind") == "character_sheet":
			for key: String in ["frame_width", "frame_height", "frame_order", "origin_y"]:
				if not a.has(key):
					e.append("asset %s is missing %s" % [id, key])
	for member: String in manifest.get("characters", {}):
		if not assets.has(manifest["characters"][member]):
			e.append("character %s uses unknown asset %s" % [member, manifest["characters"][member]])
	return e


func texture(asset_id: String) -> Texture2D:
	if _textures.has(asset_id):
		return _textures[asset_id]
	var a := entry(asset_id)
	var tex: Texture2D
	var path: String = a.get("path", "")
	if path != "" and ResourceLoader.exists(path):
		tex = load(path)
	elif a.get("kind") == "character_sheet":
		tex = ImageTexture.create_from_image(_make_character_sheet(a))
	else:
		push_warning("No texture for asset %s" % asset_id)
		tex = ImageTexture.create_from_image(Image.create(16, 16, false, Image.FORMAT_RGBA8))
	_textures[asset_id] = tex
	return tex


# --- Tileset -----------------------------------------------------------------

func tileset() -> TileSet:
	if _tileset:
		return _tileset
	var count := tiles.size()
	var tex: Texture2D
	var path: String = entry("tileset_prologue").get("path", "")
	if path != "" and ResourceLoader.exists(path):
		tex = load(path)
	else:
		var img := Image.create(TILE * count, TILE, false, Image.FORMAT_RGBA8)
		for name: String in tiles:
			_paint_tile(img, int(tiles[name]["index"]) * TILE, tiles[name])
		tex = ImageTexture.create_from_image(img)

	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var src := TileSetAtlasSource.new()
	src.texture = tex
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	var h := TILE / 2.0
	var square := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	for name: String in tiles:
		var coords := Vector2i(int(tiles[name]["index"]), 0)
		src.create_tile(coords)
		if tiles[name].get("solid", false):
			var td := src.get_tile_data(coords, 0)
			td.add_collision_polygon(0)
			td.set_collision_polygon_points(0, 0, square)
	_tileset = ts
	return ts


func tile_index(name: String) -> int:
	return int(tiles.get(name, {}).get("index", -1))


# --- Placeholder painting ----------------------------------------------------

static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	img.fill_rect(Rect2i(x, y, w, h), c)


func _paint_tile(img: Image, ox: int, def: Dictionary) -> void:
	var base := Color(def["color"])
	var acc := Color(def["accent"])
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(def["pattern"]) + ox
	_rect(img, ox, 0, TILE, TILE, base)
	match def["pattern"]:
		"speckle":
			for i in 7:
				img.set_pixel(ox + rng.randi_range(0, 15), rng.randi_range(0, 15), acc)
		"flowers":
			for p: Vector2i in [Vector2i(3, 4), Vector2i(11, 3), Vector2i(7, 10), Vector2i(13, 12)]:
				_rect(img, ox + p.x, p.y, 2, 2, acc)
				img.set_pixel(ox + p.x, p.y + 2, base.darkened(0.25))
		"tree":
			_rect(img, ox, 0, TILE, TILE, Color("#4b8a3d"))
			_rect(img, ox + 2, 1, 12, 11, acc)
			_rect(img, ox + 3, 2, 10, 9, base)
			_rect(img, ox + 5, 3, 3, 2, base.lightened(0.25))
			_rect(img, ox + 7, 12, 2, 4, Color("#5a3e2b"))
		"water":
			for y in [3, 8, 13]:
				_rect(img, ox + (y % 5), y, 5, 1, acc)
		"planks":
			for y in [0, 5, 10, 15]:
				_rect(img, ox, y, TILE, 1, acc)
			img.set_pixel(ox + 6, 2, acc)
			img.set_pixel(ox + 11, 7, acc)
			img.set_pixel(ox + 3, 12, acc)
		"brick":
			for y in [0, 4, 8, 12]:
				_rect(img, ox, y, TILE, 1, acc)
				var off := 0 if (y / 4) % 2 == 0 else 4
				for x in [off, off + 8]:
					_rect(img, ox + x, y, 1, 4, acc)
		"door":
			_rect(img, ox, 0, TILE, TILE, Color("#3e2a1c"))
			_rect(img, ox + 2, 1, 12, 15, base)
			_rect(img, ox + 3, 2, 10, 13, base.lightened(0.15))
			_rect(img, ox + 11, 8, 2, 2, acc)
		"sign":
			_rect(img, ox, 0, TILE, TILE, Color("#4b8a3d"))
			_rect(img, ox + 7, 8, 2, 8, Color("#5a3e2b"))
			_rect(img, ox + 2, 2, 12, 7, acc)
			_rect(img, ox + 4, 4, 8, 1, Color("#5a3e2b"))
			_rect(img, ox + 4, 6, 6, 1, Color("#5a3e2b"))
		"root":
			_rect(img, ox + 1, 1, 14, 14, base.darkened(0.3))
			_rect(img, ox + 3, 3, 10, 10, base)
			_rect(img, ox + 7, 7, 2, 2, acc)
		"bed":
			_rect(img, ox + 1, 1, 14, 14, Color("#5a3320"))
			_rect(img, ox + 2, 2, 12, 12, base)
			_rect(img, ox + 3, 2, 10, 4, acc)
		"exit":
			_rect(img, ox, 0, 2, TILE, acc)
			_rect(img, ox + 14, 0, 2, TILE, acc)
			for y in [3, 9]:
				_rect(img, ox + 6, y, 4, 1, base.darkened(0.3))
				_rect(img, ox + 7, y + 1, 2, 1, base.darkened(0.3))
		"stall":
			_rect(img, ox, 0, TILE, TILE, Color("#7a4528"))
			for x in range(0, TILE, 4):
				_rect(img, ox + x, 0, 2, 7, acc)
			_rect(img, ox, 7, TILE, 1, Color("#5a3320"))
			_rect(img, ox + 3, 10, 3, 3, Color("#f2d45c"))
			_rect(img, ox + 9, 10, 3, 3, Color("#6fbf4a"))
		"crate":
			_rect(img, ox, 0, TILE, TILE, Color("#4b8a3d"))
			_rect(img, ox + 2, 2, 12, 12, acc)
			_rect(img, ox + 3, 3, 10, 10, base)
			_rect(img, ox + 3, 7, 10, 1, acc)
		"roots":
			for y in [2, 7, 12]:
				_rect(img, ox + (y % 3), y, 13, 2, acc)
			_rect(img, ox + 5, 0, 2, TILE, acc)
			_rect(img, ox + 11, 4, 2, 9, base.lightened(0.15))
		"pit":
			_rect(img, ox, 0, TILE, 1, acc)
			_rect(img, ox, 15, TILE, 1, acc)
			for x in [2, 7, 12]:
				img.set_pixel(ox + x, 7, Color("#2c2140"))
		"stone":
			_rect(img, ox + 2, 3, 12, 10, acc)
			_rect(img, ox + 3, 4, 10, 8, acc.darkened(0.2))
		"bridge":
			for y in [1, 5, 9, 13]:
				_rect(img, ox + 1, y, 14, 3, acc)
			_rect(img, ox, 0, 1, TILE, acc.darkened(0.3))
			_rect(img, ox + 15, 0, 1, TILE, acc.darkened(0.3))
		"marker":
			_rect(img, ox + 3, 2, 10, 13, Color("#4a4a5e"))
			_rect(img, ox + 4, 3, 8, 11, Color("#5e5e74"))
			_rect(img, ox + 6, 5, 4, 6, acc)
		"post":
			_rect(img, ox + 5, 0, 6, 16, acc)
			_rect(img, ox + 4, 2, 8, 2, acc.darkened(0.3))
			_rect(img, ox + 4, 10, 8, 2, acc.darkened(0.3))
		"gate":
			_rect(img, ox, 0, TILE, TILE, base)
			for x in [1, 6, 11]:
				_rect(img, ox + x, 0, 3, TILE, Color("#6b4a8f"))
			_rect(img, ox, 7, TILE, 2, acc)
		"rug":
			_rect(img, ox, 0, TILE, 1, acc)
			_rect(img, ox, 15, TILE, 1, acc)
			_rect(img, ox + 6, 6, 4, 4, acc)


## A 4-frame (down, left, right, up) 32x40 stand-in for a character. It is
## deliberately simple; it only marks colours from the concept art.
func _make_character_sheet(a: Dictionary) -> Image:
	var fw := int(a["frame_width"])
	var fh := int(a["frame_height"])
	var order: Array = a["frame_order"]
	var p: Dictionary = a["placeholder"]
	var hair := Color(p["hair"])
	var skin := Color(p["skin"])
	var body := Color(p["body"])
	var acc := Color(p["accent"])
	var legs := Color(p["legs"])
	var lumi: bool = p["style"] == "lumi"
	var eye := Color("#1a1420")
	var img := Image.create(fw * order.size(), fh, false, Image.FORMAT_RGBA8)
	if p["style"] == "leafling":
		_paint_leafling(img, order, fw, body, hair, acc, eye)
		_outline(img)
		return img
	for i in order.size():
		var f: String = order[i]
		var o := i * fw
		if lumi:
			_rect(img, o + 9, 21, 14, 15, body)        # flowing dress
			_rect(img, o + 8, 33, 16, 3, body)
			_rect(img, o + 9, 28, 14, 2, acc)          # blue sash
			_rect(img, o + 11, 36, 10, 1, acc)         # echo glow under feet
		else:
			_rect(img, o + 11, 32, 4, 6, legs)
			_rect(img, o + 17, 32, 4, 6, legs)
			_rect(img, o + 9, 21, 14, 12, body)        # tunic
			_rect(img, o + 8, 20, 16, 3, acc)          # red scarf
			_rect(img, o + 20, 24, 4, 6, Color("#7a5a3a"))  # satchel
		_rect(img, o + 8, 7, 16, 14, skin)             # head
		match f:
			"up":
				_rect(img, o + 7, 4, 18, 17, hair)
			"left":
				_rect(img, o + 7, 4, 18, 6, hair)
				_rect(img, o + 17, 4, 8, 14, hair)
				_rect(img, o + 10, 13, 2, 3, eye)
			"right":
				_rect(img, o + 7, 4, 18, 6, hair)
				_rect(img, o + 7, 4, 8, 14, hair)
				_rect(img, o + 20, 13, 2, 3, eye)
			_:
				_rect(img, o + 7, 4, 18, 6, hair)
				_rect(img, o + 12, 13, 2, 3, eye)
				_rect(img, o + 18, 13, 2, 3, eye)
		if lumi and f != "up":
			_rect(img, o + 6, 8, 3, 18, hair)          # long hair
			_rect(img, o + 23, 8, 3, 18, hair)
			_rect(img, o + 20, 6, 2, 2, acc)           # flower clip
		elif p["style"] == "elder" and f != "up":
			_rect(img, o + 8, 1, 16, 5, hair)          # hair bun
			_rect(img, o + 12, 0, 8, 2, hair)
		elif p["style"] == "merchant" and f != "up":
			_rect(img, o + 6, 2, 20, 3, acc)           # wide hat
			_rect(img, o + 10, 0, 12, 3, acc)
		elif p["style"] == "reno":
			for sx: int in [8, 12, 17, 21]:            # spiky hair
				_rect(img, o + sx, 2, 2, 2, hair)
			_rect(img, o + 13, 1, 3, 2, Color("#6fbf4a"))  # leaf
	_outline(img)
	return img


## A small walking leaf wearing a parcel. Placeholder only.
static func _paint_leafling(img: Image, order: Array, fw: int, leaf: Color, vein: Color, parcel: Color, eye: Color) -> void:
	for i in order.size():
		var o := i * fw
		var f: String = order[i]
		for y in range(20, 37):
			var half := int(7.0 * sin(PI * (y - 19) / 18.0)) + 1
			_rect(img, o + 16 - half, y, half * 2, 1, leaf)
		_rect(img, o + 15, 21, 2, 15, vein)
		_rect(img, o + 15, 17, 2, 4, vein)                   # stem
		_rect(img, o + 12, 36, 3, 2, vein)                   # feet
		_rect(img, o + 18, 36, 3, 2, vein)
		_rect(img, o + 10, 12, 12, 8, parcel)                 # the parcel
		_rect(img, o + 15, 12, 2, 8, parcel.darkened(0.35))
		match f:
			"down":
				_rect(img, o + 12, 26, 2, 3, eye)
				_rect(img, o + 18, 26, 2, 3, eye)
			"left":
				_rect(img, o + 11, 26, 2, 3, eye)
			"right":
				_rect(img, o + 19, 26, 2, 3, eye)


static func _outline(img: Image) -> void:
	var src := img.duplicate() as Image
	var line := Color("#140f1c")
	for y in img.get_height():
		for x in img.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx >= 0 and ny >= 0 and nx < img.get_width() and ny < img.get_height() and src.get_pixel(nx, ny).a > 0.0:
					img.set_pixel(x, y, line)
					break


func _build_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 8
	var panel := StyleBoxFlat.new()
	panel.bg_color = UI_PANEL
	panel.border_color = UI_GOLD
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(3)
	panel.set_content_margin_all(4)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_color("font_color", "Label", UI_TEXT)
	return t
