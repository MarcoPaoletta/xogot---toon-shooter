extends RigidBody3D
## The Hazmat's thrown gas tank: arcs, and on its first contact (ground, prop, player) bursts into a fire patch
## on the ground below. A direct hit on the player also deals 8.

const FIRE := preload("res://scenes/fx/fire_patch.tscn")
const DIRECT_HIT := 8.0

var thrower: Node = null
var age := 0.0
var done := false
var _last_pos := Vector3.ZERO


func launch(vel: Vector3, grav: float, who: Node) -> void:
	linear_velocity = vel
	gravity_scale = grav / 9.8
	thrower = who
	angular_velocity = Vector3(randf_range(-9, 9), randf_range(-4, 4), randf_range(-9, 9))


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	age += delta
	_last_pos = global_position
	if age > 4.0:
		_burst()


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(DIRECT_HIT, global_position)
	global_position = _last_pos
	_burst()


func _burst() -> void:
	if done:
		return
	done = true
	# the fire lands on whatever is below the burst point (the ground or a container roof)
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.3, global_position + Vector3.DOWN * 6.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var ground: Vector3 = hit.position if hit else Vector3(global_position.x, 0.0, global_position.z)
	var fire: Node3D = FIRE.instantiate()
	get_parent().add_child(fire)
	fire.global_position = ground + Vector3.UP * 0.02
	Audio.play("tank_burst", 0.08, 1.0, ground)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.burst_fx(ground + Vector3.UP * 0.6, Color("#ff9a3a"))
	queue_free()
