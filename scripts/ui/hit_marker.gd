extends Control
## A 40 px arc at the screen edge toward the shooter, 0.6 s.

var angle := 0.0
var time := 0.0


func show_from(a: float) -> void:
	angle = a
	time = 0.6


func _process(delta: float) -> void:
	if time > 0.0:
		time -= delta
		queue_redraw()


func _draw() -> void:
	if time <= 0.0:
		return
	var c := size * 0.5
	var r: float = min(size.x, size.y) * 0.42
	var col := Color(1, 0.2, 0.15, clamp(time / 0.6, 0.0, 1.0))
	var span := 40.0 / r
	draw_arc(c, r, angle - PI * 0.5 - span, angle - PI * 0.5 + span, 24, col, 10.0, true)
