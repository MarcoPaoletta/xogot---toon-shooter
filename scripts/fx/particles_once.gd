extends GPUParticles3D
## One shot particles (impact puffs, bursts, the explosion fireball): colour per use, oriented along a normal.

@export var free_after := 0.8
@export var flash: NodePath


func setup(pos: Vector3, normal: Vector3, color: Color) -> void:
	global_position = pos
	if normal.length() > 0.01 and abs(normal.normalized().dot(Vector3.UP)) < 0.999:
		look_at(pos + normal, Vector3.UP)
		rotate_object_local(Vector3.RIGHT, -PI * 0.5)
	var pm: ParticleProcessMaterial = process_material.duplicate()
	if pm.color_ramp == null:
		pm.color = color
	process_material = pm
	restart()
	emitting = true
	var fl := get_node_or_null(flash) if flash else null
	if fl:
		var t := create_tween()
		t.tween_interval(0.08)
		t.tween_property(fl, "light_energy", 0.0, 0.1)
	get_tree().create_timer(free_after, false).timeout.connect(queue_free)
