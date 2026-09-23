extends StaticBody3D
## A gas can (GDD 19): any bullet, pellet, blade or blast that touches it sets it off. The explosion hurts
## everyone within 4 units (60 at the centre, 15 at the edge) and sets off other gas cans nearby.

var exploded := false


func _ready() -> void:
	add_to_group("gas_cans")


func hit(_amount := 0.0, _from := Vector3.ZERO) -> void:
	detonate(0.0)


func detonate(delay := 0.0) -> void:
	if exploded:
		return
	exploded = true
	if delay > 0.0:
		await get_tree().create_timer(delay, false).timeout
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.explode(global_position + Vector3.UP * 0.5, 4.0, 60.0, 15.0, 1.0, 1.15)
	queue_free()
