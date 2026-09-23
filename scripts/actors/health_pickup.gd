extends Area3D
## The pack's medkit: rotates 90°/s, bobs ±0.1 over 1.6 s, gives 35 health.

const HEAL := 35.0

@onready var model: Node3D = $Model
var t := 0.0


func _ready() -> void:
	add_to_group("health_pickups")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	t += delta
	model.rotation.y += deg_to_rad(90.0) * delta
	model.position.y = 0.35 + sin(t * TAU / 1.6) * 0.1


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player") or not body.alive:
		return
	body.heal(HEAL)
	Audio.play("health_pickup", 0.03)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.burst_fx(global_position + Vector3.UP * 0.6, Color("#6dff7a"))
		arena.hud.message("+35 HEALTH", 1.0)
	queue_free()
