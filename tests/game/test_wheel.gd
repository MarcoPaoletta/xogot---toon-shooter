extends RefCounted
## GDD 17.4 test_wheel: with Tab held, a 120 px mouse delta toward sector k, then release, equips weapon k if
## unlocked and leaves the held weapon unchanged if locked; time scale 0.25 while open, 1.0 after; every slot
## holds the right Guns/glTF model; locked slots carry the silhouette override, unlocked ones do not; the
## models rotate between two frames.

var tree: SceneTree
var p


func _motion(v: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.relative = v
	ev.screen_relative = v
	Input.parse_input_event(ev)
	await tree.process_frame


func _choose(k: int) -> void:
	Input.action_press("weapon_wheel")
	for f in 12:
		await tree.physics_frame
	var ang := k * TAU / 14.0
	await _motion(Vector2(sin(ang), -cos(ang)) * 120.0)
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release("weapon_wheel")
	var t := 0.0
	while t < 0.6:
		await tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second * Engine.time_scale


func _run():
	tree = Engine.get_main_loop()
	var a = tree.current_scene
	p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	p.invulnerable = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var wheel = a.get_node("HUD/WeaponWheel")
	await tree.physics_frame

	# time scale while open
	Input.action_press("weapon_wheel")
	for f in 20:
		await tree.physics_frame
	var ts_open := Engine.time_scale
	var slots_ok := true
	var model_bad := []
	for i in 14:
		var slot: Node3D = wheel.slots[i]
		var model: Node = slot.get_node("Pivot/Model")
		var want: String = Game.WEAPON_MESHES[Game.WEAPON_IDS[i]] + ".gltf"
		if not model.scene_file_path.ends_with("/" + want):
			model_bad.append("%d:%s" % [i + 1, model.scene_file_path.get_file()])
		var owned: bool = p.is_owned(Game.WEAPON_IDS[i])
		for m in slot.find_children("*", "MeshInstance3D", true, false):
			if (m.material_override != null) == owned:
				slots_ok = false
	var r0: float = wheel.slots[0].rotation.y
	await tree.process_frame
	await tree.process_frame
	var rotating: bool = abs(wheel.slots[0].rotation.y - r0) > 0.0001
	Input.action_release("weapon_wheel")
	for f in 20:
		await tree.physics_frame
	var ts_closed := Engine.time_scale
	if abs(ts_open - 0.25) < 0.01 and abs(ts_closed - 1.0) < 0.01:
		print("PASS test_wheel_slows_time_while_open (%.2f open, %.2f closed)" % [ts_open, ts_closed])
	else:
		print("FAIL test_wheel_slows_time_while_open: %.2f open, %.2f closed" % [ts_open, ts_closed])
	if model_bad.is_empty():
		print("PASS test_wheel_slots_hold_the_real_models")
	else:
		print("FAIL test_wheel_slots_hold_the_real_models: %s" % [model_bad])
	if slots_ok:
		print("PASS test_wheel_locked_slots_are_silhouettes")
	else:
		print("FAIL test_wheel_locked_slots_are_silhouettes")
	if rotating:
		print("PASS test_wheel_models_rotate")
	else:
		print("FAIL test_wheel_models_rotate")

	# choosing an unlocked weapon (pistol, sector 1) equips it; a locked one (sniper, sector 7) does not
	await _choose(1)
	var after_unlocked: String = p.current
	await _choose(7)
	var after_locked: String = p.current
	if after_unlocked == "pistol" and after_locked == "pistol":
		print("PASS test_wheel_equips_unlocked_and_ignores_locked")
	else:
		print("FAIL test_wheel_equips_unlocked_and_ignores_locked: after pistol %s, after locked sniper %s" % [after_unlocked, after_locked])
	# after unlocking, the same gesture equips it
	p.give_weapon("sniper")
	for f in 30:
		await tree.physics_frame
	await _choose(7)
	if p.current == "sniper":
		print("PASS test_wheel_equips_after_unlock")
	else:
		print("FAIL test_wheel_equips_after_unlock: holding %s" % p.current)
