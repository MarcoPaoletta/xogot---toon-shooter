extends RigidBody3D
## Grenade launcher round: arcs, bounces up to twice (restitution 0.4), explodes on a bandit or 1.5 s after launch.

signal exploded(position: Vector3, radius: float, damage_centre: float, damage_edge: float)

var damage_centre := 60.0
var damage_edge := 20.0
var radius := 3.0
var bounces := 0
var age := 0.0
var done := false
var _last_pos := Vector3.ZERO


func launch(vel: Vector3, grav: float, dc: float, de: float, r: float, _owner: Node) -> void:
	linear_velocity = vel
	gravity_scale = grav / 9.8
	damage_centre = dc
	damage_edge = de
	radius = r
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	age += delta
	_last_pos = global_position
	if age >= 1.5:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bandits"):
		# the solver pushes a grenade out of a character body before this signal arrives, so it explodes
		# where it was on its last frame before the contact, not where it was thrown back to
		global_position = _last_pos
		_explode()
		return
	bounces += 1
	if bounces <= 2:
		Audio.play("grenade_bounce", 0.1, -4.0, global_position)
	else:
		linear_velocity *= 0.5


func _explode() -> void:
	if done:
		return
	done = true
	exploded.emit(global_position, radius, damage_centre, damage_edge)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.explode(global_position, radius, damage_centre, damage_edge)
	queue_free()
