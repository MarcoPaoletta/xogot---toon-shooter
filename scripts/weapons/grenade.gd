extends RigidBody3D
## Grenade launcher round: arcs, bounces up to twice (restitution 0.4), explodes on a bandit or 1.5 s after launch.

var damage_centre := 60.0
var damage_edge := 20.0
var radius := 3.0
var bounces := 0
var age := 0.0
var done := false


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
	if age >= 1.5:
		_explode()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("bandits"):
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
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.explode(global_position, radius, damage_centre, damage_edge)
	queue_free()
