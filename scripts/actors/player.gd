extends CharacterBody3D
## The green soldier: movement relative to the camera, over the shoulder rig without position smoothing,
## facing, health, the fourteen weapons (three owned at start) and the weapon wheel input.

signal damaged(amount: float, from_position: Vector3)
signal died
signal health_changed(value: float)
signal weapon_changed(id: String)
signal ammo_changed
signal weapon_unlocked(id: String, refill: bool)

const SPEED := 6.5
const ACCEL_TIME := 0.08
const DECEL_TIME := 0.06
const GRAVITY := 24.0
const TURN_SPEED := deg_to_rad(720.0)
const MOUSE_DEG_PER_PX := 0.1
const PITCH_MIN := -40.0
const PITCH_MAX := 20.0
const DEFAULT_PITCH := -8.0
const FOV := 50.0
const AIM_FOV := 40.0
const AIM_TIME := 0.12
const MAX_HEALTH := 100.0
const WEAPON_MESH_NAMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]

@onready var model: Node3D = $Model
@onready var anim: AnimationPlayer = $Model/Character_Soldier/AnimationPlayer
@onready var rig: Node3D = $CameraRig
@onready var pitch_node: Node3D = $CameraRig/Pitch
@onready var arm: SpringArm3D = $CameraRig/Pitch/Arm
@onready var camera: Camera3D = $CameraRig/Pitch/Arm/Camera
@onready var aim_point: Marker3D = $AimPoint
@onready var muzzle: Marker3D = $Muzzle
@onready var weapon_slot: Node3D = $WeaponSlot
@onready var step_sound_timer := 0.0

var health := MAX_HEALTH
var alive := true
var invulnerable := false
var controls_enabled := true
var aiming := false
var firing := false
var cam_yaw := 0.0
var cam_pitch := DEFAULT_PITCH
var recoil_pitch := 0.0
var recoil_yaw := 0.0
var arm_length := 0.0
var aim_blend := 0.0
var owned: Array[String] = []
var current := ""
var previous := ""
var weapons := {}
var meshes := {}
var switch_timer := 0.0
var pending_switch := ""
var wheel_open := false
var wheel = null
var forced_anim := ""
var forced_anim_time := 0.0
var shake_time := 0.0
var shake_amount := 0.0
var shake_total := 0.0
var input_override = null   # test hook: {"move": Vector2, "fire": bool, "aim": bool}
var heartbeat_timer := 0.0


func _ready() -> void:
	add_to_group("player")
	arm_length = arm.spring_length
	arm.add_excluded_object(get_rid())
	cam_yaw = rotation.y
	for w in weapon_slot.get_children():
		weapons[w.weapon_id] = w
		w.player = self
	for m in model.find_children("*", "MeshInstance3D", true, false):
		if m.name in WEAPON_MESH_NAMES:
			meshes[str(m.name)] = m
			m.visible = false
	# the concept's red blaster: the AK's wood surface
	if meshes.has("AK"):
		meshes["AK"].set_surface_override_material(2, load("res://materials/blaster_red.tres"))
	for clip in ["Idle", "Run", "Run_Shoot", "Idle_Shoot", "Walk", "Run_Gun", "Walk_Shoot"]:
		if anim.has_animation(clip):
			anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	reset_weapons()
	_apply_camera()
	anim.play("Idle")


func reset_weapons() -> void:
	owned.clear()
	for id in Game.START_WEAPONS:
		owned.append(id)
	for id in weapons:
		weapons[id].refill()
	weapons["pistol"].ammo = 72
	current = ""
	_equip("blaster")


func weapon() -> Node:
	return weapons.get(current)


func is_owned(id: String) -> bool:
	return id in owned


## Called by a WeaponCrate. Returns true when the weapon was new.
func give_weapon(id: String) -> bool:
	var fresh := not is_owned(id)
	if fresh:
		owned.append(id)
		owned.sort_custom(func(a, b): return Game.WEAPON_IDS.find(a) < Game.WEAPON_IDS.find(b))
	weapons[id].refill()
	weapon_unlocked.emit(id, not fresh)
	if fresh and current == "blaster":
		switch_to(id)
	ammo_changed.emit()
	return fresh


func switch_to(id: String) -> void:
	if not is_owned(id) or id == current:
		return
	if switch_timer > 0.0:
		pending_switch = id
		return
	previous = current
	switch_timer = 0.25
	Audio.play("weapon_switch", 0.05)
	var t := get_tree().create_timer(0.12, false)
	t.timeout.connect(func(): _equip(id))


func _equip(id: String) -> void:
	for m in meshes.values():
		m.visible = false
	current = id
	var mesh_name: String = Game.WEAPON_MESHES[id]
	if meshes.has(mesh_name):
		meshes[mesh_name].visible = true
	weapon_changed.emit(id)
	ammo_changed.emit()


func cycle(dir: int) -> void:
	if owned.size() < 2:
		return
	var i := owned.find(pending_switch if pending_switch != "" else current)
	switch_to(owned[(i + dir + owned.size()) % owned.size()])


func held_mesh() -> MeshInstance3D:
	return meshes.get(Game.WEAPON_MESHES.get(current, ""))


## The barrel end of the held weapon, in world space.
func muzzle_position() -> Vector3:
	var m := held_mesh()
	if m == null:
		return global_position + Vector3.UP * 1.3
	var box: AABB = m.global_transform * m.get_aabb()
	var fwd := -camera.global_basis.z
	var half: float = max(box.size.x, max(box.size.y, box.size.z)) * 0.5
	muzzle.global_position = box.get_center() + fwd * half
	return muzzle.global_position


func _unhandled_input(event: InputEvent) -> void:
	if not alive or not controls_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if wheel_open and wheel:
			wheel.add_delta(event.relative)
		else:
			look(event.relative)
	elif event.is_action_pressed("weapon_next"):
		cycle(1)
	elif event.is_action_pressed("weapon_prev"):
		cycle(-1)
	elif event.is_action_pressed("weapon_last"):
		if previous != "" and is_owned(previous):
			switch_to(previous)


## Mouse delta in pixels to camera yaw and pitch, 0.1 degree per pixel, same frame.
func look(rel: Vector2) -> void:
	cam_yaw -= deg_to_rad(rel.x * MOUSE_DEG_PER_PX)
	cam_pitch = clamp(cam_pitch - rel.y * MOUSE_DEG_PER_PX, PITCH_MIN, PITCH_MAX)
	_apply_camera()


func _apply_camera() -> void:
	# the rig is a child of the player (exact follow); only its rotation is decoupled from the body
	rig.global_rotation = Vector3(0, cam_yaw + deg_to_rad(recoil_yaw), 0)
	pitch_node.rotation = Vector3(deg_to_rad(clamp(cam_pitch + recoil_pitch, PITCH_MIN, PITCH_MAX + 5.0)), 0, 0)


func add_recoil(deg: float) -> void:
	recoil_pitch += deg
	recoil_yaw += randf_range(-0.2, 0.2)


func shake(time: float, amount: float) -> void:
	if amount >= shake_amount or shake_time <= 0.0:
		shake_time = time
		shake_total = time
		shake_amount = amount


func _input_state() -> Dictionary:
	if input_override != null:
		return input_override
	var mv := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	return {"move": mv, "fire": Input.is_action_pressed("fire"), "fire_pressed": Input.is_action_just_pressed("fire"),
		"aim": Input.is_action_pressed("aim")}


func _physics_process(delta: float) -> void:
	var st := _input_state() if (alive and controls_enabled) else {"move": Vector2.ZERO, "fire": false, "aim": false}
	aiming = st.get("aim", false)
	firing = st.get("fire", false)
	var mv: Vector2 = st.get("move", Vector2.ZERO)

	# movement relative to the camera yaw
	var basis_y := Basis(Vector3.UP, cam_yaw)
	var wish := basis_y * Vector3(mv.x, 0, mv.y)
	if wish.length() > 1.0:
		wish = wish.normalized()
	var w := weapon()
	var speed := SPEED * (1.1 if (w and w.mode == 2) else 1.0)
	var target := wish * speed
	var hv := Vector3(velocity.x, 0, velocity.z)
	var rate := (speed / ACCEL_TIME) if wish.length() > 0.01 else (SPEED / DECEL_TIME)
	hv = hv.move_toward(target, rate * delta)
	velocity.x = hv.x
	velocity.z = hv.z
	if is_on_floor():
		velocity.y = -0.1
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	# facing: camera yaw while aiming or firing, movement direction otherwise
	if aiming or firing:
		rotation.y = cam_yaw
	elif hv.length() > 0.3:
		var want := atan2(-hv.x, -hv.z)
		rotation.y = rotate_toward(rotation.y, want, TURN_SPEED * delta)

	# recoil returns over 0.12 s
	recoil_pitch = move_toward(recoil_pitch, 0.0, max(abs(recoil_pitch), 0.6) / 0.12 * delta)
	recoil_yaw = move_toward(recoil_yaw, 0.0, 0.2 / 0.12 * delta)

	# aim: FOV and arm length over 0.12 s
	aim_blend = move_toward(aim_blend, 1.0 if aiming else 0.0, delta / AIM_TIME)
	var aim_fov: float = w.aim_fov if w else AIM_FOV
	camera.fov = lerp(FOV, aim_fov, aim_blend)
	arm.spring_length = lerp(arm_length, arm_length * 5.2 / 6.6, aim_blend)
	_apply_camera()

	# shake as an offset on the camera, never on the rig
	if shake_time > 0.0:
		shake_time -= delta
		var k := shake_amount * (shake_time / maxf(shake_total, 0.001))
		camera.h_offset = randf_range(-k, k)
		camera.v_offset = randf_range(-k, k)
	else:
		camera.h_offset = 0.0
		camera.v_offset = 0.0

	# the weapon wheel: open while Tab is held, equip the hovered weapon on release
	if wheel:
		var want_wheel: bool = alive and controls_enabled and not get_tree().paused and \
			(st.get("wheel", false) if input_override != null else Input.is_action_pressed("weapon_wheel"))
		if want_wheel and not wheel_open:
			wheel_open = true
			wheel.open(self)
		elif not want_wheel and wheel_open:
			wheel_open = false
			var chosen: String = wheel.close()
			if chosen != "":
				switch_to(chosen)

	# weapon
	if switch_timer > 0.0:
		switch_timer -= delta
		if switch_timer <= 0.0 and pending_switch != "":
			var p := pending_switch
			pending_switch = ""
			switch_to(p)
	if w:
		w.tick(delta)
		if alive and controls_enabled and switch_timer <= 0.0 and not wheel_open:
			var wants: bool = st.get("fire", false) if w.automatic else st.get("fire_pressed", false)
			if wants and w.ready_to_fire():
				w.fire()
				ammo_changed.emit()

	_update_animation(hv, delta)

	# footsteps and the low health heartbeat
	if hv.length() > 1.0 and is_on_floor():
		step_sound_timer -= delta
		if step_sound_timer <= 0.0:
			step_sound_timer = 0.32
			Audio.play("step_%d" % randi_range(1, 4), 0.1, -8.0)
	if alive and health < 30.0:
		heartbeat_timer -= delta
		if heartbeat_timer <= 0.0:
			heartbeat_timer = 1.2
			Audio.play("heartbeat", 0.02, -2.0)


func play_forced(clip: String, time: float, speed := 1.0) -> void:
	forced_anim = clip
	forced_anim_time = time
	anim.play(clip, 0.05, speed)


func _update_animation(hv: Vector3, delta: float) -> void:
	if not alive:
		return
	if forced_anim_time > 0.0:
		forced_anim_time -= delta
		return
	var moving := hv.length() > 0.4
	var shooting := firing or aiming
	var clip := "Idle"
	if moving:
		clip = "Run_Shoot" if shooting else "Run"
	elif firing:
		clip = "Idle_Shoot"
	if anim.current_animation != clip:
		anim.play(clip, 0.1)


func take_damage(amount: float, from_position: Vector3) -> void:
	if not alive or invulnerable:
		return
	health = max(0.0, health - amount)
	health_changed.emit(health)
	damaged.emit(amount, from_position)
	shake(0.15, 0.06)
	Audio.play("player_hit", 0.08)
	Audio.muffle(0.3)
	if health <= 0.0:
		_die()


func heal(amount: float) -> void:
	if not alive:
		return
	health = min(MAX_HEALTH, health + amount)
	health_changed.emit(health)


func _die() -> void:
	alive = false
	velocity = Vector3.ZERO
	anim.play("Death", 0.1)
	shake(0.3, 0.12)
	died.emit()
