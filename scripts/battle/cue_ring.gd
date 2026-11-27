extends Node2D
## The timing cue: a ring that shrinks onto its target. Press A as it closes.

var progress := 0.0   # 0 = just appeared, 1 = closed (the cue moment)
var color := Color("#e8b84a")


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var r := lerpf(22.0, 6.0, clampf(progress, 0.0, 1.0))
	draw_arc(Vector2.ZERO, 6.0, 0.0, TAU, 16, Color(1, 1, 1, 0.6), 1.0)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 24, color, 2.0)
