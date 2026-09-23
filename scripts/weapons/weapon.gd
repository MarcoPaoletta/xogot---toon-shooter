extends Node3D
## One script for the fourteen weapon prefabs (GDD 16.2). Each prefab only sets these numbers;
## the mesh is the character's own mesh of the same name.

enum Mode { HITSCAN, PROJECTILE, MELEE }

const MASK_PLAYER_SHOT := 1 | 4    # world + bandits
const MELEE_CONTACT := 0.35        # of the Punch clip (0.87 s)

@export var weapon_id := "blaster"
@export var mode: Mode = Mode.HITSCAN
@export var automatic := true
@export var rate := 8.0
@export var damage := 10.0
@export var damage_edge := 0.0
@export var cone_hip := 1.2
@export var cone_aim := 0.5
@export var cone_growth := 0.0
@export var cone_max := 0.0
@export var pellets := 1
@export var max_range := 60.0
@export var ammo_max := -1
@export var recoil := 0.6
@export var aim_fov := 40.0
@export var scoped := false
@export var knockback := 0.0
@export var knockback_min_pellets := 1
@export var stagger := 0.0
@export var projectile_scene: PackedScene
@export var projectile_speed := 0.0
@export var projectile_gravity := 0.0
@export var blast_radius := 0.0
@export var reach := 0.0
@export var arc := 90.0
@export var swing_speed := 1.0
@export var fire_sound := "blaster"
@export var hit_sound := ""
@export var tracer_color := Color("#ffd36b")

var player: Node = null
var ammo := 0
var _cooldown := 0.0
var _extra_cone := 0.0
var _since_shot := 99.0
var shots_fired := 0          # for the test suites
var last_hit_bodies: Array = []


func refill() -> void:
	ammo = ammo_max


func infinite() -> bool:
	return ammo_max < 0


func ammo_text() -> String:
	return "∞" if infinite() else "%d / %d" % [ammo, ammo_max]


func ready_to_fire() -> bool:
	return _cooldown <= 0.0


func tick(delta: float) -> void:
	_cooldown -= delta
	_since_shot += delta
	if _since_shot > 0.3:
		_extra_cone = 0.0


func _arena() -> Node:
	return get_tree().get_first_node_in_group("arena")


func fire() -> void:
	if not infinite() and ammo <= 0:
		Audio.play("empty_click", 0.03)
		_cooldown = 0.25
		return
	_cooldown = 1.0 / rate
	_since_shot = 0.0
	shots_fired += 1
	last_hit_bodies.clear()
	if not infinite():
		ammo -= 1
	match mode:
		Mode.HITSCAN:
			_fire_hitscan()
		Mode.PROJECTILE:
			_fire_projectile()
		Mode.MELEE:
			_swing()
	if recoil > 0.0:
		player.add_recoil(recoil)


## Uniform direction inside a cone of `cone_deg` around `fwd`.
static func spread(fwd: Vector3, cone_deg: float) -> Vector3:
	if cone_deg <= 0.0:
		return fwd
	var side := fwd.cross(Vector3.UP)
	if side.length() < 0.01:
		side = fwd.cross(Vector3.RIGHT)
	side = side.normalized()
	var up := side.cross(fwd).normalized()
	var r := deg_to_rad(cone_deg) * sqrt(randf())
	var a := randf() * TAU
	return (fwd * cos(r) + (side * cos(a) + up * sin(a)) * sin(r)).normalized()


## Launch direction so an arcing projectile lands on `target` (the low solution); 45 degrees when out of reach.
static func ballistic(from: Vector3, target: Vector3, speed: float, g: float) -> Vector3:
	var d := target - from
	var flat := Vector2(d.x, d.z)
	var x := flat.length()
	if x < 0.01:
		return d.normalized()
	var y := d.y
	var v2 := speed * speed
	var disc := v2 * v2 - g * (g * x * x + 2.0 * y * v2)
	var angle := PI * 0.25
	if disc >= 0.0:
		angle = atan((v2 - sqrt(disc)) / (g * x))
	var h := flat.normalized()
	return Vector3(h.x * cos(angle), sin(angle), h.y * cos(angle)).normalized()


## The crosshair ray starts beside the player, so nothing between the camera and the player blocks it.
func aim_ray() -> Array:
	var cam: Camera3D = player.camera
	var origin := cam.global_position
	var fwd := -cam.global_basis.z
	var chest: Vector3 = player.global_position + Vector3.UP * 1.4
	var start := origin + fwd * maxf(0.0, (chest - origin).dot(fwd))
	return [start, fwd]


func current_cone() -> float:
	return (cone_aim if player.aiming else cone_hip) + _extra_cone


func _fire_hitscan() -> void:
	var r := aim_ray()
	var start: Vector3 = r[0]
	var fwd: Vector3 = r[1]
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var cone := current_cone()
	var muzzle: Vector3 = player.muzzle_position()
	var arena := _arena()
	var hits := {}
	for i in pellets:
		var dir := spread(fwd, cone)
		var q := PhysicsRayQueryParameters3D.create(start, start + dir * max_range, MASK_PLAYER_SHOT, [player.get_rid()])
		var hit := space.intersect_ray(q)
		var end: Vector3 = hit.position if hit else start + dir * max_range
		var body = hit.collider if hit else null
		var is_bandit: bool = body != null and body.is_in_group("bandits")
		last_hit_bodies.append(body)
		if arena:
			arena.shot_fx(muzzle, end, hit.get("normal", Vector3.UP), hit != {}, is_bandit, tracer_color, i == 0, body)
		if is_bandit:
			hits[body] = hits.get(body, 0) + 1
			body.take_damage(damage, player.global_position, 0.0, stagger)
	for b in hits:
		if knockback > 0.0 and hits[b] >= knockback_min_pellets and is_instance_valid(b):
			b.knock(player.global_position, knockback)
		if arena:
			arena.hit_confirmed()
	if cone_growth > 0.0:
		_extra_cone = min(_extra_cone + cone_growth, cone_max - cone_hip)
	Audio.play(fire_sound, 0.06, 0.0)


func _fire_projectile() -> void:
	var r := aim_ray()
	var start: Vector3 = r[0]
	var fwd: Vector3 = r[1]
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(start, start + fwd * 60.0, MASK_PLAYER_SHOT, [player.get_rid()])
	var hit := space.intersect_ray(q)
	var target: Vector3 = hit.position if hit else start + fwd * 60.0
	var muzzle: Vector3 = player.muzzle_position()
	var p: Node3D = projectile_scene.instantiate()
	var arena := _arena()
	(arena.get_node("Effects") if arena else get_tree().current_scene).add_child(p)
	p.global_position = muzzle
	var dir := (target - muzzle).normalized()
	if projectile_gravity > 0.0:
		dir = ballistic(muzzle, target, projectile_speed, projectile_gravity)
	p.launch(dir * projectile_speed, projectile_gravity, damage, damage_edge, blast_radius, player)
	if arena:
		arena.flash_fx(muzzle, tracer_color)
	Audio.play(fire_sound, 0.06, 0.0)


func _swing() -> void:
	player.play_forced("Punch", 0.87 / swing_speed, swing_speed)
	Audio.play(fire_sound, 0.08, -2.0)
	var t := get_tree().create_timer(0.87 * MELEE_CONTACT / swing_speed, false)
	t.timeout.connect(_melee_contact)


func _melee_contact() -> void:
	if player == null or not player.alive:
		return
	var arena := _arena()
	if arena == null:
		return
	var fwd: Vector3 = -player.global_basis.z
	var hit_any := false
	for b in arena.get_node("Bandits").get_children():
		if not b.alive:
			continue
		var to: Vector3 = b.global_position - player.global_position
		to.y = 0.0
		if to.length() > reach + 0.45:
			continue
		if to.length() > 0.2 and rad_to_deg(fwd.angle_to(to.normalized())) > arc * 0.5:
			continue
		b.take_damage(damage, player.global_position, 0.0, stagger)
		if knockback > 0.0:
			b.knock(player.global_position, knockback)
		arena.impact_fx(b.global_position + Vector3.UP * 1.2, -to.normalized(), true)
		hit_any = true
	if hit_any:
		arena.hit_confirmed()
		if hit_sound != "":
			Audio.play(hit_sound, 0.08)
