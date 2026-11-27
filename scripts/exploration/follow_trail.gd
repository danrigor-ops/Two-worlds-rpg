class_name FollowTrail
extends RefCounted
## Breadcrumb trail for the companion. Only positions the leader actually
## stood on (after collision) are recorded, so the follower always stands on a
## safe prior position and can't be pushed into walls.

const MIN_STEP := 1.0
const MAX_POINTS := 512

var spacing := 18.0
var points: Array[Vector2] = []
var _last_index := 0


func reset(pos: Vector2) -> void:
	points = [pos]
	_last_index = 0


## Starts a trail from an explicit list (oldest first), for example when a
## new member joins from where they were standing.
func reset_path(path: Array[Vector2]) -> void:
	points = path.duplicate()
	_last_index = 0


func record(pos: Vector2) -> void:
	if not points.is_empty() and points.back().distance_to(pos) < MIN_STEP:
		return
	points.append(pos)
	_trim()


## The recorded point about `spacing` pixels of path behind the newest one.
func target() -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	var dist := 0.0
	var i := points.size() - 1
	while i > 0 and dist < spacing:
		dist += points[i].distance_to(points[i - 1])
		i -= 1
	_last_index = i
	return points[i]


## For a character swap: the follower becomes the leader and vice versa.
## Keep only the stretch of path between them and reverse it, so the new
## follower walks back along ground that was already walked.
func reverse_for_swap() -> void:
	target()
	var seg := points.slice(_last_index)
	seg.reverse()
	points = seg
	_last_index = 0


func _trim() -> void:
	if points.size() <= MAX_POINTS:
		return
	points = points.slice(points.size() - MAX_POINTS)
