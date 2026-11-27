class_name PartyMember
extends CharacterBody2D
## A hero on the field map. The node's origin is at the character's feet.
## The leader moves with physics; the follower is placed on trail points.

const DIRS := {
	"down": Vector2(0, 1), "left": Vector2(-1, 0),
	"right": Vector2(1, 0), "up": Vector2(0, -1),
}

var member_id := ""
var facing := "down"
var floats := false
var sprite: Sprite2D
var _frame_w := 32
var _frame_h := 40
var _order: Array = ["down", "left", "right", "up"]
var _moving := false
var _anim_time := 0.0


func setup(id: String) -> void:
	member_id = id
	name = id.capitalize()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)

	var a := Assets.character_entry(id)
	_frame_w = int(a.get("frame_width", 32))
	_frame_h = int(a.get("frame_height", 40))
	_order = a.get("frame_order", _order)
	floats = a.get("floats", false)
	sprite = Sprite2D.new()
	sprite.texture = Assets.texture(Assets.manifest["characters"][id])
	sprite.region_enabled = true
	sprite.centered = true
	sprite.offset = Vector2((0.5 - float(a.get("origin_x", 0.5))) * _frame_w, (0.5 - float(a.get("origin_y", 0.95))) * _frame_h)
	add_child(sprite)
	_update_frame()


func facing_vector() -> Vector2:
	return DIRS[facing]


func face(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	if absf(dir.x) > absf(dir.y):
		facing = "right" if dir.x > 0 else "left"
	else:
		facing = "down" if dir.y > 0 else "up"
	_update_frame()


func place_at(pos: Vector2, new_facing: String = "") -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_moving = false
	if new_facing in DIRS:
		facing = new_facing
	_update_frame()


## Moves with collision. Returns true if the character actually moved.
func walk(dir: Vector2, speed: float) -> bool:
	var before := global_position
	velocity = dir * speed
	move_and_slide()
	face(dir)
	_moving = global_position.distance_squared_to(before) > 0.0001
	return _moving


## Follower movement: step straight onto a recorded trail point.
func follow_to(pos: Vector2) -> void:
	var d := pos - global_position
	_moving = d.length_squared() > 0.0001
	if _moving:
		face(d)
	global_position = pos


func _process(delta: float) -> void:
	_anim_time += delta
	var y := 0.0
	if _moving and int(_anim_time * 8.0) % 2 == 0:
		y -= 1.0
	if floats:
		y += roundf(sin(_anim_time * 3.0) * 1.0) - 1.0
	sprite.position = Vector2(0, y)


func _update_frame() -> void:
	if sprite == null:
		return
	var i := maxi(0, _order.find(facing))
	sprite.region_rect = Rect2(i * _frame_w, 0, _frame_w, _frame_h)
