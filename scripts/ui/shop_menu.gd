class_name ShopMenu
extends CanvasLayer
## A spirit stall (content/shops.json). Prices are in Dewdrops.
## Up/down picks, A buys one, B leaves.

signal closed

var shop_id := ""
var row := 0
var panel: Panel
var title_label: Label
var list_label: Label
var detail_label: Label
var _items: Array = []


func _ready() -> void:
	layer = 15
	panel = Panel.new()
	panel.theme = Assets.ui_theme
	panel.position = Vector2(4, 4)
	panel.size = Vector2(232, 152)
	add_child(panel)
	title_label = Label.new()
	title_label.position = Vector2(8, 3)
	title_label.add_theme_color_override("font_color", Assets.UI_GOLD)
	panel.add_child(title_label)
	list_label = Label.new()
	list_label.position = Vector2(8, 18)
	panel.add_child(list_label)
	detail_label = Label.new()
	detail_label.position = Vector2(8, 100)
	detail_label.size = Vector2(216, 48)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_color_override("font_color", Color("#c9d3f0"))
	panel.add_child(detail_label)
	visible = false


static func shop_def(id: String) -> Dictionary:
	return JsonUtil.load_dict("res://content/shops.json").get("shops", {}).get(id, {})


func open(id: String) -> void:
	shop_id = id
	_items = shop_def(id).get("items", [])
	row = 0
	visible = true
	InputManager.push_mode(InputManager.Mode.MENU)
	_refresh("")


func close() -> void:
	visible = false
	InputManager.pop_mode(InputManager.Mode.MENU)
	closed.emit()


func _process(_delta: float) -> void:
	if not visible:
		return
	var m := InputManager.Mode.MENU
	if InputManager.just_pressed("cancel", m) or InputManager.just_pressed("menu", m):
		close()
	elif InputManager.just_pressed("move_down", m) and not _items.is_empty():
		row = (row + 1) % _items.size()
		_refresh("")
	elif InputManager.just_pressed("move_up", m) and not _items.is_empty():
		row = (row - 1 + _items.size()) % _items.size()
		_refresh("")
	elif InputManager.just_pressed("confirm", m) and not _items.is_empty():
		_refresh(buy(_items[row]))


## Buys one. Returns the line to show.
func buy(item_id: String) -> String:
	var def: Dictionary = GameState.item_defs().get(item_id, {})
	var price := int(def.get("price_dp", 0))
	if price <= 0:
		return "That's not for sale."
	if GameState.item_count(item_id) >= 99:
		return "Your bag can't hold any more of those."
	if not GameState.buy_with_dewdrops(item_id, price):
		return "Not enough Dewdrops."
	return "Bought a %s." % def.get("name", item_id)


func _refresh(feedback: String) -> void:
	title_label.text = "%s     Dewdrops %d" % [shop_def(shop_id).get("name", "Stall"), int(GameState.data["wallet"]["dewdrops"])]
	var defs := GameState.item_defs()
	var lines: PackedStringArray = []
	for i in _items.size():
		var d: Dictionary = defs.get(_items[i], {})
		lines.append("%s%-18s %d DP  (have %d)" % ["> " if i == row else "  ", d.get("name", _items[i]), int(d.get("price_dp", 0)), GameState.item_count(_items[i])])
	list_label.text = "\n".join(lines)
	if feedback != "":
		detail_label.text = feedback
	elif not _items.is_empty():
		detail_label.text = defs.get(_items[row], {}).get("text", "")
