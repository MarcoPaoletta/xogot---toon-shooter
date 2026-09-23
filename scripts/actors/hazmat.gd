extends "res://scripts/actors/bandit.gd"
## The Hazmat (GDD 19): the second enemy behaviour. Advances like a bandit to 12 units with line of sight,
## then throws a gas tank with the Punch clip every 3.2 s. The tank bursts into a fire patch where it lands.
## The suit makes him immune to fire. He carries no gun: the gas tank waits in his left hand.

const TANK := preload("res://scenes/weapons/gas_tank.tscn")
const THROW_SPEED := 13.0
const THROW_GRAVITY := 20.0
const PUNCH := 0.87
const RELEASE_AT := 0.32       # of the Punch clip: the left arm is fully forward

@export var throw_range := 12.0
@export var throw_pause := 3.2

@onready var held_tank: Node3D = find_child("HeldTank", true, false)
var _throw_timer := 1.2
var _throwing := 0.0
var _released := false


func setup(params: Dictionary, target: Node3D) -> void:
	super.setup(params, target)
	preferred_range = throw_range
	speed = params.get("speed", 4.0) * 0.85


func _attack_tick(delta: float, los: bool, player_alive: bool) -> void:
	_throw_timer -= delta
	if _throwing > 0.0:
		_throwing -= delta
		if not _released and _throwing <= PUNCH * (1.0 - RELEASE_AT):
			_released = true
			_release()
		return
	if _throw_timer <= 0.0 and los and player_alive:
		_throwing = PUNCH
		_released = false
		_throw_timer = throw_pause
		_hit_anim = PUNCH
		anim.play("Punch", 0.05)


func _release() -> void:
	if player == null:
		return
	var from: Vector3 = held_tank.global_position if held_tank else global_position + Vector3.UP * 1.6
	if held_tank:
		held_tank.visible = false
		get_tree().create_timer(1.2, false).timeout.connect(func(): if is_instance_valid(held_tank) and alive: held_tank.visible = true)
	# aim where the player will be when the tank lands (flight time estimated from the flat distance)
	var flat: float = Vector2(player.global_position.x - from.x, player.global_position.z - from.z).length()
	var flight: float = flat / (THROW_SPEED * 0.8)
	var target: Vector3 = player.global_position + Vector3(player.velocity.x, 0, player.velocity.z) * flight
	var dir: Vector3 = preload("res://scripts/weapons/weapon.gd").ballistic(from, target, THROW_SPEED, THROW_GRAVITY)
	var tank: Node3D = TANK.instantiate()
	var arena := get_tree().get_first_node_in_group("arena")
	(arena.get_node("Effects") if arena else get_parent()).add_child(tank)
	tank.global_position = from
	tank.launch(dir * THROW_SPEED, THROW_GRAVITY, self)
	Audio.play("throw", 0.08, -2.0, from)


func _die() -> void:
	super._die()
	if held_tank:
		held_tank.visible = false
