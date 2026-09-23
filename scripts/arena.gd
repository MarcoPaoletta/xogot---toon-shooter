extends Node3D
## The run controller (GDD 8): waves, score, breathers, pickups, effects, explosions, the concept view (F1),
## pause, win and overrun. In the main menu the same scene runs with `menu_mode` on: no player, no HUD, no waves.

signal run_finished(result: Dictionary)

const TRACER := preload("res://scenes/fx/tracer.tscn")
const FLASH := preload("res://scenes/fx/muzzle_flash.tscn")
const IMPACT := preload("res://scenes/fx/impact.tscn")
const BURST := preload("res://scenes/fx/burst.tscn")
const EXPLOSION := preload("res://scenes/fx/explosion.tscn")
const HEALTH_PICKUP := preload("res://scenes/actors/health_pickup.tscn")

const KILL_SCORE := 100
const REGEN := 20.0
const METAL_WORDS := ["Container", "Fence", "Barrier", "Tank", "Tower", "Gate", "Corner", "Barrel", "StreetLight", "Car", "Tires"]
const WOOD_WORDS := ["Crate", "Pallet", "Planks", "Cardboard", "Tree"]

@export var menu_mode := false

@onready var player: Node3D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var spawner: Node = $WaveSpawner
@onready var effects: Node3D = $Effects
@onready var bandits_root: Node3D = $Bandits
@onready var pickups_root: Node3D = $Pickups
@onready var concept_cam: Camera3D = $ConceptCam
@onready var dressing: Node3D = $ConceptDressing
@onready var player_spawn: Marker3D = $PlayerSpawn

var score := 0
var kills := 0
var run_time := 0.0
var running := false
var finished := false
var waves_cleared := 0
var concept_view := false
var _concept_flash: Node3D
var _first_hit_done := false
var _first_breather_done := false


func _ready() -> void:
	add_to_group("arena")
	dressing.visible = false
	if menu_mode:
		for n in [player, hud, spawner]:
			n.process_mode = Node.PROCESS_MODE_DISABLED
		player.visible = false
		hud.visible = false
		player.get_node("CameraRig/Pitch/Arm/Camera").current = false
		for c in $WeaponCrates.get_children():
			c.get_node("Name").visible = false
		return
	player.global_position = player_spawn.global_position
	player.rotation.y = 0.0
	player.cam_yaw = 0.0
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	player.weapon_unlocked.connect(func(_id, _refill): hud.show_hint(3.0))
	var points: Array = []
	for m in $SpawnPoints.get_children():
		points.append(m.global_position)
	spawner.setup(bandits_root, points, player, player.camera)
	spawner.wave_started.connect(_on_wave_started)
	spawner.wave_cleared.connect(_on_wave_cleared)
	spawner.all_waves_cleared.connect(_on_all_cleared)
	spawner.bandit_died.connect(_on_bandit_died)
	spawner.bandit_spawned.connect(func(_b): hud.set_enemies(spawner.remaining()))
	hud.bind(player, self)
	player.wheel = hud.wheel
	player.camera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Audio.play_music("combat", 0.8, 1.0)
	running = true
	hud.set_score(0, false)
	spawner.start()
	_tutorial()


func _tutorial() -> void:
	hud.message("WASD to move, mouse to aim, hold left click to fire", 4.0, 1.9)
	await get_tree().create_timer(6.0, false).timeout
	if running and spawner.wave == 1:
		hud.message("Weapons are hidden around the yard. Hold Tab to choose one", 4.0)
		hud.show_hint(10.0)


func _process(delta: float) -> void:
	if menu_mode:
		return
	if running:
		run_time += delta
		if spawner.in_breather and player.alive:
			player.heal(REGEN * delta)
	var want_concept := Input.is_action_pressed("snap_concept_view") and running
	if want_concept != concept_view:
		_set_concept_view(want_concept)
	if concept_view and _concept_flash:
		_concept_flash.global_position = player.muzzle_position()


func _unhandled_input(event: InputEvent) -> void:
	if menu_mode or finished:
		return
	if event.is_action_pressed("pause"):
		hud.toggle_pause()
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not get_tree().paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ------------------------------------------------------------------ waves and score

func add_score(points: int, pop := true) -> void:
	score += points
	hud.set_score(score, pop, points)


func _on_wave_started(n: int) -> void:
	hud.set_wave(n, spawner.total_waves())
	hud.set_enemies(spawner.remaining())
	hud.announce("WAVE %d" % n)
	Audio.play("wave_start", 0.0)
	Audio.set_music_level(1.0, 0.5)


func _on_wave_cleared(n: int) -> void:
	waves_cleared = n
	var bonus: int = 250 * n
	add_score(bonus, true)
	hud.announce("WAVE CLEARED, +%d" % bonus)
	Audio.play("wave_cleared", 0.0)
	Audio.duck(-6.0, 1.0)
	if n < spawner.total_waves():
		Audio.set_music_level(0.6, 0.5)
		if not _first_breather_done:
			_first_breather_done = true
			get_tree().create_timer(1.9, false).timeout.connect(func(): hud.message("Health returns between waves", 3.0))
		if n >= 1:
			_spawn_health_pickups()


func _spawn_health_pickups() -> void:
	for m in $PickupPoints.get_children():
		var taken := false
		for p in pickups_root.get_children():
			if p.is_in_group("health_pickups") and p.global_position.distance_to(m.global_position) < 1.0:
				taken = true
		if not taken:
			var p: Node3D = HEALTH_PICKUP.instantiate()
			pickups_root.add_child(p)
			p.global_position = m.global_position


func _on_bandit_died(_b: Node) -> void:
	kills += 1
	add_score(KILL_SCORE, true)
	hud.set_enemies(spawner.remaining())


func _on_all_cleared() -> void:
	running = false
	player.invulnerable = true
	Audio.stop_music(0.6)
	Audio.play("yard_held", 0.0)
	Engine.time_scale = 0.4
	await get_tree().create_timer(2.0, true, false, true).timeout
	Engine.time_scale = 1.0
	_finish(true)


func _on_player_damaged(_amount: float, from_position: Vector3) -> void:
	hud.damage_flash(from_position)
	if not _first_hit_done:
		_first_hit_done = true
		hud.message("Sandbags block their shots, not yours", 4.0)


func _on_player_died() -> void:
	running = false
	spawner.stop()
	Audio.stop_music(0.3)
	Audio.play("overrun", 0.0)
	await get_tree().create_timer(1.5, false).timeout
	_finish(false)


func _finish(won: bool) -> void:
	if finished:
		return
	finished = true
	var bonus := int(round(player.health)) * 5 if won else 0
	score += bonus
	var img := get_viewport().get_texture().get_image()
	Game.last_frame = ImageTexture.create_from_image(img)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var result := {
		"won": won,
		"title": "Yard held" if won else "Overrun at wave %d" % spawner.wave,
		"score": score,
		"survival_bonus": bonus,
		"waves_cleared": waves_cleared,
		"wave_reached": spawner.wave,
		"kills": kills,
		"time": run_time,
		"weapons": player.owned.size(),
	}
	run_finished.emit(result)
	Game.run_complete(result)


func restart() -> void:
	Game.start_run()


# ------------------------------------------------------------------ the concept view (F1, development only)

func _set_concept_view(on: bool) -> void:
	concept_view = on
	dressing.visible = on
	hud.visible = not on
	bandits_root.visible = not on
	$WeaponCrates.visible = not on
	pickups_root.visible = not on
	player.controls_enabled = not on
	if on:
		player.global_position = player_spawn.global_position
		player.velocity = Vector3.ZERO
		player.rotation.y = 0.0
		player.cam_yaw = 0.0
		player.cam_pitch = player.DEFAULT_PITCH
		player._apply_camera()
		if player.current != "blaster" and player.is_owned("blaster"):
			player._equip("blaster")
		concept_cam.current = true
		player.play_forced("Run_Shoot", 1.0e9)
		_concept_flash = FLASH.instantiate()
		_concept_flash.continuous = true
		effects.add_child(_concept_flash)
		_concept_flash.global_position = player.muzzle_position()
	else:
		player.forced_anim_time = 0.0
		player.camera.current = true
		if _concept_flash:
			_concept_flash.queue_free()
			_concept_flash = null


# ------------------------------------------------------------------ effects

func _surface_sound(body: Object) -> String:
	var n := ""
	var node := body as Node
	while node and node != self:
		n += str(node.name)
		node = node.get_parent()
	for w in METAL_WORDS:
		if w in n:
			return "impact_metal"
	for w in WOOD_WORDS:
		if w in n:
			return "impact_wood"
	return "impact_sand"


func shot_fx(muzzle: Vector3, end: Vector3, normal: Vector3, hit_something: bool, is_bandit: bool, color: Color, with_flash := true, body: Object = null) -> void:
	var t: Node3D = TRACER.instantiate()
	effects.add_child(t)
	t.setup(muzzle, end, color)
	if with_flash:
		flash_fx(muzzle, Color("#ffe066"))
	if hit_something:
		impact_fx(end, normal, is_bandit, body)


func flash_fx(pos: Vector3, color: Color) -> void:
	var f: Node3D = FLASH.instantiate()
	effects.add_child(f)
	f.global_position = pos
	f.set_color(color)


func impact_fx(pos: Vector3, normal: Vector3, on_bandit: bool, body: Object = null) -> void:
	var p: GPUParticles3D = IMPACT.instantiate()
	effects.add_child(p)
	p.setup(pos, normal, Color("#ff5a4a") if on_bandit else Color("#d9b48a"))
	if not on_bandit:
		Audio.play("impact_sand" if body == null else _surface_sound(body), 0.1, -8.0, pos)


func bandit_shot_fx(origin: Vector3, end: Vector3, normal: Vector3, hit_world: bool) -> void:
	var t: Node3D = TRACER.instantiate()
	effects.add_child(t)
	t.setup(origin, end, Color("#ff8a5a"))
	flash_fx(origin, Color("#ff8a5a"))
	if hit_world:
		impact_fx(end, normal, false)


func burst_fx(pos: Vector3, color: Color) -> void:
	var b: GPUParticles3D = BURST.instantiate()
	effects.add_child(b)
	b.setup(pos, Vector3.UP, color)


func hit_confirmed() -> void:
	hud.crosshair_hit()


## Launcher explosions (GDD 16.2): linear falloff from the centre to the edge, the player takes 50 %.
func explode(pos: Vector3, radius: float, damage_centre: float, damage_edge: float) -> void:
	var e: GPUParticles3D = EXPLOSION.instantiate()
	effects.add_child(e)
	e.setup(pos, Vector3.UP, Color("#ffb347"))
	Audio.play("explosion", 0.06, 2.0, pos)
	if player.visible:
		var d_player: float = player.global_position.distance_to(pos)
		player.shake(0.25, 0.15 * clamp(1.5 - d_player / 20.0, 0.3, 1.0))
	var any := false
	for b in bandits_root.get_children():
		if not b.alive:
			continue
		var d: float = (b.global_position + Vector3.UP * 1.0).distance_to(pos)
		if d <= radius:
			b.take_damage(lerp(damage_centre, damage_edge, d / radius), pos, 1.0)
			any = true
	var dp: float = (player.global_position + Vector3.UP * 1.0).distance_to(pos)
	if dp <= radius and player.alive:
		player.take_damage(0.5 * lerp(damage_centre, damage_edge, dp / radius), pos)
	if any:
		hit_confirmed()
