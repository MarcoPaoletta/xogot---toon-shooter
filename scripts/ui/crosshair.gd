extends Control
## Four 14 px lines and a 2 px dot; the gap is 6 px, 12 px while moving, 3 px while aiming; red for 0.1 s on a hit.
## A code drawn scope circle replaces it while aiming a sniper.

var gap := 6.0
var target_gap := 6.0
var hit_time := 0.0
var scoped := false


func _process(delta: float) -> void:
	gap = move_toward(gap, target_gap, 80.0 * delta)
	hit_time -= delta
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var col := Color(1, 0.25, 0.2) if hit_time > 0.0 else Color(1, 1, 1, 0.95)
	var shadow := Color(0, 0, 0, 0.6)
	if scoped:
		var r := size.y * 0.42
		draw_arc(c, r, 0, TAU, 96, Color(0, 0, 0, 0.85), 6.0, true)
		draw_line(c - Vector2(r, 0), c + Vector2(r, 0), Color(0, 0, 0, 0.8), 2.0)
		draw_line(c - Vector2(0, r), c + Vector2(0, r), Color(0, 0, 0, 0.8), 2.0)
		draw_circle(c, 3.0, col)
		return
	for d in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		var a: Vector2 = c + d * gap
		var b: Vector2 = c + d * (gap + 14.0)
		draw_line(a + Vector2(1, 1), b + Vector2(1, 1), shadow, 3.0)
		draw_line(a, b, col, 2.0)
	draw_circle(c + Vector2(1, 1), 2.0, shadow)
	draw_circle(c, 2.0, col)
