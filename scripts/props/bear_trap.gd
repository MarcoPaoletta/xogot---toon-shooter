extends Area3D
## A bear trap (GDD 19): snaps shut on the player (BearTrap_Open becomes BearTrap_Closed), deals 20 and holds
## the player for 0.8 s. It opens again 15 s later, once nobody stands on it.

const DAMAGE := 20.0
const HOLD := 0.8
const REARM := 15.0

@onready var open_model: Node3D = $Open
@onready var closed_model: Node3D = $Closed
var armed := true
var _rearm := 0.0


func _ready() -> void:
	add_to_group("bear_traps")
	body_entered.connect(_on_body_entered)
	closed_model.visible = false


func _on_body_entered(body: Node) -> void:
	if armed and body.is_in_group("player") and body.alive:
		snap(body)


func snap(p: Node) -> void:
	armed = false
	open_model.visible = false
	closed_model.visible = true
	closed_model.scale = Vector3(1.25, 0.6, 1.25)
	create_tween().tween_property(closed_model, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	p.take_damage(DAMAGE, global_position)
	p.stun(HOLD)
	Audio.play("trap_snap", 0.06, 2.0, global_position)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.burst_fx(global_position + Vector3.UP * 0.3, Color("#c8c8c8"))
		arena.hud.message("BEAR TRAP  -20", 1.2)
	_rearm = REARM


func _process(delta: float) -> void:
	if armed:
		return
	_rearm -= delta
	if _rearm <= 0.0 and get_overlapping_bodies().filter(func(b): return b.is_in_group("player")).is_empty():
		armed = true
		open_model.visible = true
		closed_model.visible = false
