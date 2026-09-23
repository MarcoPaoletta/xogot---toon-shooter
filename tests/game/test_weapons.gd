extends RefCounted
## GDD 16.8 test_weapons and 7.3: for each of the fourteen weapons, a bandit 12 units in front of the camera
## in the open (melee: 1.2 units in front of the player), the weapon given with full ammo, fired for 1.0 s
## (one swing for melee, one shot for the launchers). Damage within 20 % of the table's expectation, ammo
## decreased by the shots fired, exactly one weapon mesh visible on the player. Also pillar 2 (b): a blaster
## shot at a bandit 20 units away registers within 2 physics frames.

const IDS := ["blaster", "pistol", "revolver", "revolver_small", "smg", "shotgun", "short_cannon", "sniper",
	"sniper_2", "grenade_launcher", "rocket_launcher", "knife_1", "knife_2", "shovel"]
## Hit fractions. GDD 16.8 estimated 0.8 / 0.7 / 0.7 for 12 units of flight; "12 units in front of the camera"
## is only about 5.4 units from where the shot ray starts (beside the player), so these are the fractions
## measured for this geometry (GDD section 18). Pellet weapons are averaged over five one second trials.
const FRACTION := {"smg": 1.0, "shotgun": 0.95, "short_cannon": 0.65}
const TRIALS := {"shotgun": 5, "short_cannon": 5}

var tree: SceneTree
var a
var p


func _spawn_dummy(pos: Vector3) -> Node:
	var b: Node = a.get_node("WaveSpawner").bandit_scenes[0].instantiate()
	b.name = "Dummy"
	a.get_node("Bandits").add_child(b)
	b.global_position = pos
	b.max_health = 100000.0
	b.health = 100000.0
	# stays in the physics space (a disabled body would be removed from it) but does not think
	b.set_physics_process(false)
	b.set_process(false)
	return b


func _aim_at(pos: Vector3) -> void:
	# the camera sits on the pitched arm, so aiming moves it: a few fixed point steps converge
	for i in 4:
		var to: Vector3 = pos - p.camera.global_position
		p.cam_yaw = atan2(-to.x, -to.z)
		p.rotation.y = p.cam_yaw
		p.cam_pitch = rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
		p._apply_camera()


## A melee swing follows the body's facing (the camera yaw while the attack is held), so face the target itself.
func _face(pos: Vector3) -> void:
	var to: Vector3 = pos - p.global_position
	p.cam_yaw = atan2(-to.x, -to.z)
	p.rotation.y = p.cam_yaw
	p.cam_pitch = p.DEFAULT_PITCH
	p._apply_camera()


func _visible_weapon_meshes() -> int:
	return p.visible_weapon_count()


func _run():
	tree = Engine.get_main_loop()
	a = tree.current_scene
	p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	p.invulnerable = true
	var origin := Vector3(-3, 0, 15)
	var all_ok := true
	for id in IDS:
		p.global_position = origin
		p.velocity = Vector3.ZERO
		p.rotation.y = 0.0
		p.cam_yaw = 0.0
		p.cam_pitch = p.DEFAULT_PITCH
		p._apply_camera()
		p.recoil_pitch = 0.0
		p.recoil_yaw = 0.0
		if not p.is_owned(id):
			p.give_weapon(id)
		p._equip(id)
		var w = p.weapons[id]
		w.refill()
		w._cooldown = 0.0
		await tree.physics_frame
		var melee: bool = w.mode == 2
		var target_pos: Vector3
		if melee:
			target_pos = p.global_position + Vector3(0, 0, -1.2)
		else:
			var cam: Camera3D = p.camera
			var fwd: Vector3 = -cam.global_basis.z
			fwd.y = 0.0
			target_pos = cam.global_position + fwd.normalized() * 12.0
			target_pos.y = 0.0
		var dummy := _spawn_dummy(target_pos)
		for f in 4:
			if melee:
				_face(target_pos)
			else:
				_aim_at(target_pos + Vector3.UP * 1.3)
			await tree.physics_frame
		var shots0: int = w.shots_fired
		var ammo0: int = w.ammo
		var hp0: float = dummy.health
		var frames := 60
		if w.mode != 0:
			frames = 1
		for trial in TRIALS.get(id, 1):
			w._cooldown = 0.0
			for f in frames:
				if melee:
					_face(target_pos)
				else:
					_aim_at(target_pos + Vector3.UP * 1.3)
				p.input_override = {"move": Vector2.ZERO, "fire": true, "fire_pressed": true, "aim": true}
				await tree.physics_frame
			p.input_override = {"move": Vector2.ZERO, "fire": false, "fire_pressed": false, "aim": false}
			# let projectiles fly and melee contact land
			for f in 120:
				await tree.physics_frame
		p.input_override = null
		var shots: int = w.shots_fired - shots0
		var dealt: float = hp0 - dummy.health
		var expected: float
		if w.mode == 1:
			expected = w.damage
		elif melee:
			expected = w.damage
		else:
			expected = shots * w.damage * w.pellets * FRACTION.get(id, 1.0)
		var ammo_ok: bool = w.infinite() or (ammo0 - w.ammo) == shots
		var dmg_ok: bool = expected > 0.0 and abs(dealt - expected) <= 0.2 * expected
		var mesh_ok: bool = _visible_weapon_meshes() == 1
		var ok: bool = dmg_ok and ammo_ok and mesh_ok and shots >= 1
		all_ok = all_ok and ok
		print("%s test_weapon_%s: shots %d, damage %.0f expected %.0f, ammo %s, visible meshes %d" % [
			"PASS" if ok else "FAIL", id, shots, dealt, expected, "ok" if ammo_ok else "WRONG", _visible_weapon_meshes()])
		dummy.queue_free()
		for e in a.get_node("Effects").get_children():
			e.queue_free()
		await tree.physics_frame

	# pillar 2 (b): a blaster shot at a bandit 20 units away registers within 2 physics frames (open lane z = 12, facing east with nothing behind the camera)
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	for e in a.get_node("Effects").get_children():
		e.queue_free()
	p.recoil_pitch = 0.0
	p.recoil_yaw = 0.0
	p.forced_anim_time = 0.0
	p.velocity = Vector3.ZERO
	p.global_position = Vector3(-12, 0, 12)
	p._equip("blaster")
	p.weapons["blaster"]._cooldown = 0.0
	p.cam_yaw = -PI * 0.5
	p.rotation.y = -PI * 0.5
	p._apply_camera()
	await tree.physics_frame
	var cam2: Camera3D = p.camera
	var f2: Vector3 = -cam2.global_basis.z
	f2.y = 0.0
	var far_pos: Vector3 = p.global_position + f2.normalized() * 20.0
	var d2 := _spawn_dummy(far_pos)
	# let the spring arm settle at its new length before aiming
	for f in 6:
		_aim_at(far_pos + Vector3.UP * 1.1)
		await tree.physics_frame
	_aim_at(far_pos + Vector3.UP * 1.1)
	var h0: float = d2.health
	var hit_frame := -1
	Input.action_press("fire")
	for f in 4:
		await tree.physics_frame
		_aim_at(far_pos + Vector3.UP * 1.1)
		if d2.health < h0 and hit_frame < 0:
			hit_frame = f + 1
	Input.action_release("fire")
	if hit_frame > 0 and hit_frame <= 2:
		print("PASS test_blaster_hit_registers_within_2_frames (frame %d)" % hit_frame)
	else:
		var bw = p.weapons["blaster"]
		print("FAIL test_blaster_hit_registers_within_2_frames: frame %d (shots %d, hit %s, dummy at %s, player at %s)" % [hit_frame, bw.shots_fired, bw.last_hit_bodies, d2.global_position, p.global_position])
	d2.queue_free()
	print("ALL_WEAPONS_OK" if all_ok else "SOME_WEAPONS_FAILED")
