extends Area3D
## A weapon crate placed by hand in the arena (GDD 17.1): the Crate model with the weapon's loose model
## floating above it (the `Gun` child added in the arena scene). Walking in unlocks the weapon; the crate
## comes back 45 s later as an ammo refill (melee crates do not come back).

const RESPAWN := 45.0

@export var weapon_id := "shotgun"

@onready var gun: Node3D = get_node_or_null("Gun")
@onready var label: Label3D = $Name
@onready var light: OmniLight3D = $Light
var t := 0.0
var refill := false
var active := true
var _respawn_timer := 0.0


func _ready() -> void:
	add_to_group("weapon_crates")
	body_entered.connect(_on_body_entered)
	label.text = Game.weapon_name(weapon_id).to_upper()


func _process(delta: float) -> void:
	t += delta
	if gun:
		gun.rotation.y += deg_to_rad(90.0) * delta
		gun.position.y = 1.4 + sin(t * TAU / 1.6) * 0.08
	if not active:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_set_active(true)


func _set_active(on: bool) -> void:
	active = on
	visible = on
	set_deferred("monitoring", on)
	if on and refill:
		label.text = "%s  REFILL" % Game.weapon_name(weapon_id).to_upper()


func _on_body_entered(body: Node) -> void:
	if not active or not body.is_in_group("player") or not body.alive:
		return
	var fresh: bool = body.give_weapon(weapon_id)
	Audio.play("crate_pickup", 0.03)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.burst_fx(global_position + Vector3.UP * 1.0, Color("#ffd36b"))
		arena.hud.message(("UNLOCKED: " if fresh else "REFILL: ") + Game.weapon_name(weapon_id).to_upper(), 1.5)
	if weapon_id in ["knife_1", "knife_2", "shovel"]:
		queue_free()
		return
	refill = true
	_respawn_timer = RESPAWN
	_set_active(false)
