extends CharacterBody3D
## The red bandit, the single enemy behaviour of 1.x (GDD 7.4): advance on the navigation mesh
## to the preferred range with line of sight, then hold and fire bursts of 3.

signal died(bandit: Node)
signal fired(origin: Vector3, hit_point: Vector3, hit_player: bool)

enum State { SPAWN, ADVANCE, HOLD, DEAD }

const MASK_BANDIT_SHOT := 1 | 2   # world + player
const WEAPON_MESH_NAMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]
const CONE := 5.0          # horizontal half angle of the spread, degrees
const CONE_VERTICAL := 0.5  # vertical: shots at the belt never lob over chest height cover (pillar 3)
const DAMAGE := 6.0
const GRAVITY := 24.0

const BURN_DPS := 10.0

@export var max_health := 30.0
@export var weapon_mesh := "Pistol"      # the one weapon mesh left visible ("" hides them all)
@export var fire_immune := false
@export var score_value := 100
@export var move_clip := "Run_Shoot"
@export var hold_clip := "Idle_Shoot"

@onready var model: Node3D = $Model
@onready var anim: AnimationPlayer = $Model.find_children("*", "AnimationPlayer", true, false)[0]
@onready var nav: NavigationAgent3D = $NavAgent
@onready var eyes: RayCast3D = $Eyes
@onready var muzzle: Marker3D = $Muzzle
@onready var shape: CollisionShape3D = $Shape

var state := State.SPAWN
var health := 30.0
var alive := true
var speed := 4.0
var preferred_range := 9.0
var burst_pause := 2.0
var player: Node3D = null
var travelled := 0.0
var age := 0.0
var _replan := 0.0
var _burst_left := 0
var _burst_timer := 0.0
var _los_lost := 0.0
var _knock := Vector3.ZERO
var _stagger := 0.0
var _hit_anim := 0.0
var _safe_velocity := Vector3.ZERO
var burn_time := 0.0
var _burn_tick := 0.0


func _ready() -> void:
	add_to_group("bandits")
	health = max_health
	for m in model.find_children("*", "MeshInstance3D", true, false):
		if m.name in WEAPON_MESH_NAMES:
			m.visible = m.name == weapon_mesh
	for clip in ["Run_Shoot", "Idle_Shoot", "Run", "Idle"]:
		if anim.has_animation(clip):
			anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	nav.velocity_computed.connect(func(v): _safe_velocity = v)
	anim.play(move_clip)
	model.scale = Vector3.ONE * 0.01
	var t := create_tween()
	t.tween_property(model, "scale", Vector3.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	t.tween_callback(func(): if state == State.SPAWN: state = State.ADVANCE)


func setup(params: Dictionary, target: Node3D) -> void:
	speed = params.get("speed", 4.0)
	preferred_range = params.get("range", 9.0)
	burst_pause = params.get("burst_pause", 2.0)
	player = target


func _aim_point() -> Vector3:
	return player.get_node("AimPoint").global_position


func sees_player() -> bool:
	if player == null:
		return false
	eyes.target_position = eyes.to_local(_aim_point())
	eyes.force_raycast_update()
	return not eyes.is_colliding()


func _physics_process(delta: float) -> void:
	if not alive:
		return
	age += delta
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.1
	_stagger -= delta
	_hit_anim -= delta
	var want := Vector3.ZERO
	if player and state != State.SPAWN and _stagger <= 0.0:
		var to := _aim_point() - global_position
		to.y = 0.0
		var dist := to.length()
		var los := sees_player()
		var player_alive: bool = player.get("alive") != false
		match state:
			State.ADVANCE:
				_replan -= delta
				if _replan <= 0.0:
					_replan = 0.5
					nav.target_position = player.global_position
				var next := nav.get_next_path_position()
				var dir := next - global_position
				dir.y = 0.0
				if dir.length() > 0.05:
					want = dir.normalized() * speed
				if dist <= preferred_range and los and player_alive:
					state = State.HOLD
					_burst_left = 3
					_burst_timer = 0.3
			State.HOLD:
				if dist > preferred_range + 2.0 or not player_alive:
					state = State.ADVANCE
				elif not los:
					_los_lost += delta
					if _los_lost > 0.4:
						state = State.ADVANCE
				else:
					_los_lost = 0.0
				_face(to, delta, deg_to_rad(360.0))
				_attack_tick(delta, los, player_alive)
	nav.velocity = want
	var hv := _safe_velocity if nav.avoidance_enabled else want
	if want == Vector3.ZERO:
		hv = Vector3.ZERO
	hv += _knock
	_knock = _knock.move_toward(Vector3.ZERO, 12.0 * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	var before := global_position
	move_and_slide()
	var moved := global_position - before
	moved.y = 0.0
	travelled += moved.length()
	if state == State.ADVANCE and hv.length() > 0.3:
		_face(hv, delta, deg_to_rad(720.0))
	if _hit_anim <= 0.0:
		var clip := hold_clip if state == State.HOLD else move_clip
		if anim.current_animation != clip:
			anim.play(clip, 0.1)
	_burn(delta)


## The attack while holding position; the bandit fires bursts of three. The Hazmat overrides this.
func _attack_tick(delta: float, los: bool, player_alive: bool) -> void:
	_burst_timer -= delta
	if _burst_timer <= 0.0 and los and player_alive:
		if _burst_left > 0:
			_shoot()
			_burst_left -= 1
			_burst_timer = 0.15
		else:
			_burst_left = 3
			_burst_timer = burst_pause


## Fire (GDD 19): standing in flames keeps a character burning; 10 damage per second.
func ignite(seconds: float) -> void:
	if alive and not fire_immune:
		burn_time = max(burn_time, seconds)


func _burn(delta: float) -> void:
	var fx := get_node_or_null("Burning")
	if burn_time > 0.0:
		burn_time -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = 0.5
			take_damage(BURN_DPS * 0.5, global_position)
	if fx:
		fx.emitting = burn_time > 0.0 and alive


func _face(dir: Vector3, delta: float, turn: float) -> void:
	if dir.length() < 0.01:
		return
	var want := atan2(-dir.x, -dir.z)
	rotation.y = rotate_toward(rotation.y, want, turn * delta)


func _shoot() -> void:
	var origin := muzzle.global_position
	var aim := _aim_point()
	var fwd := (aim - origin).normalized()
	var side := fwd.cross(Vector3.UP).normalized()
	var up := side.cross(fwd).normalized()
	var r := sqrt(randf())
	var a := randf() * TAU
	var dir := (fwd + side * tan(deg_to_rad(CONE * r * cos(a))) + up * tan(deg_to_rad(CONE_VERTICAL * r * sin(a)))).normalized()
	var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * 40.0, MASK_BANDIT_SHOT, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end: Vector3 = hit.position if hit else origin + dir * 40.0
	var hit_player: bool = hit != {} and hit.collider == player
	fired.emit(origin, end, hit_player)
	var arena := get_tree().get_first_node_in_group("arena")
	if arena:
		arena.bandit_shot_fx(origin, end, hit.get("normal", Vector3.UP), hit != {} and not hit_player)
	Audio.play("bandit_pistol", 0.08, -3.0, origin)
	if hit_player:
		player.take_damage(DAMAGE, global_position)
	elif hit and hit.collider.has_method("hit"):
		hit.collider.hit(DAMAGE, global_position)


func take_damage(amount: float, from: Vector3, knock_units := 0.0, stagger_time := 0.0) -> void:
	if not alive:
		return
	health -= amount
	Audio.play("hit_bandit", 0.1, -2.0, global_position + Vector3.UP)
	if knock_units > 0.0:
		knock(from, knock_units)
	if health <= 0.0:
		_die()
		return
	_hit_anim = max(0.43, stagger_time)
	if stagger_time > 0.0:
		_stagger = stagger_time
	anim.play("HitReact", 0.05)


## Pushes the bandit `units` away from `from` (over about 0.35 s).
func knock(from: Vector3, units: float) -> void:
	var d := global_position - from
	d.y = 0.0
	if d.length() < 0.01:
		d = -global_basis.z
	_knock = d.normalized() * sqrt(2.0 * 12.0 * units)   # decelerates at 12 u/s², so it slides exactly `units`


func _die() -> void:
	alive = false
	burn_time = 0.0
	var fx := get_node_or_null("Burning")
	if fx:
		fx.emitting = false
	state = State.DEAD
	shape.set_deferred("disabled", true)
	collision_layer = 0
	anim.play("Death", 0.05)
	Audio.play("bandit_death", 0.08, 0.0, global_position + Vector3.UP)
	died.emit(self)
	var t := create_tween()
	t.tween_interval(1.0)
	t.tween_property(self, "position:y", position.y - 0.8, 0.8)
	t.tween_callback(queue_free)
