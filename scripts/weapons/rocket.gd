extends Area3D
## Rocket: flies straight at 30 u/s with a smoke trail and explodes on any contact.

var velocity := Vector3.ZERO
var damage_centre := 120.0
var damage_edge := 30.0
var radius := 4.0
var age := 0.0
var done := false


func launch(vel: Vector3, _grav: float, dc: float, de: float, r: float, _owner: Node) -> void:
	velocity = vel
	damage_centre = dc
	damage_edge = de
	radius = r
	look_at(global_position + vel, Vector3.UP)


func _ready() -> void:
	body_entered.connect(func(_b): _explode())


func _physics_process(delta: float) -> void:
	age += delta
	var step := velocity * delta
	# a swept ray so a fast rocket never tunnels through a thin fence
	var q := PhysicsRayQueryParameters3D.create(global_position, global_position + step, collision_mask)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position
		_explode()
		return
	global_position += step
	if age > 3.0:
		_explode()


func _explode() -> void:
	if done:
		return
	done = true
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.explode(global_position, radius, damage_centre, damage_edge)
	var trail := get_node_or_null("Trail")
	if trail:
		# leave the smoke behind to fade on its own
		var pos: Vector3 = trail.global_position
		remove_child(trail)
		get_parent().add_child(trail)
		trail.global_position = pos
		trail.emitting = false
		get_tree().create_timer(0.8).timeout.connect(trail.queue_free)
	queue_free()
