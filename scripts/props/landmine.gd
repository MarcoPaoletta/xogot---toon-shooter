extends Area3D
## A landmine (GDD 19): the player steps on it, it beeps, and 0.15 s later explodes: 30 to the player who
## stepped on it, and the cartoon explosion hurts anyone else within 3.5 units. One use.

const DAMAGE := 30.0

@onready var light: OmniLight3D = $Light
var triggered := false
var t := 0.0


func _ready() -> void:
	add_to_group("landmines")
	body_entered.connect(_on_body_entered)
	t = randf() * 1.2


func _process(delta: float) -> void:
	t += delta
	light.visible = fmod(t, 1.2) < 0.12 or triggered


func _on_body_entered(body: Node) -> void:
	if triggered or not body.is_in_group("player") or not body.alive:
		return
	triggered = true
	light.light_energy = 3.0
	Audio.play("mine_beep", 0.02, 2.0, global_position)
	await get_tree().create_timer(0.15, false).timeout
	body.take_damage(DAMAGE, global_position)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.explode(global_position + Vector3.UP * 0.3, 3.5, 30.0, 10.0, 0.0, 0.95)
		arena.hud.message("LANDMINE  -30", 1.2)
	queue_free()
