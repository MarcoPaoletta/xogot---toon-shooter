extends RefCounted
## GDD 19: bear trap, landmine, gas can, fire, the Hazmat's throw, and melee weapons in the left hand.
## Run inside the live arena: `xo game eval --file tests/game/test_hazards.gd`.

var tree: SceneTree
var a
var p


func _frames(n: int) -> void:
	for i in n:
		await tree.physics_frame


func _seconds(s: float) -> void:
	var t := 0.0
	while t < s:
		await tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second * Engine.time_scale


func _reset_player(pos: Vector3) -> void:
	p.burn_time = 0.0
	p.stun_time = 0.0
	p.health = 100.0
	p.velocity = Vector3.ZERO
	p.global_position = pos
	p.input_override = null
	await _frames(3)


func _dummy(scene_index: int, pos: Vector3) -> Node:
	var b: Node = a.get_node("WaveSpawner").bandit_scenes[scene_index].instantiate()
	b.setup({"speed": 0.0, "range": 1.0, "burst_pause": 99.0}, p)
	a.get_node("Bandits").add_child(b)
	b.global_position = pos
	b.max_health = 1000.0
	b.health = 1000.0
	return b


func _run():
	tree = Engine.get_main_loop()
	a = tree.current_scene
	p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	p.invulnerable = false

	# bear trap: -20, snaps shut, holds the player for 0.8 s
	var trap: Node3D = a.get_node("Hazards/BearTrap4")
	await _reset_player(trap.global_position + Vector3(0, 0, 3))
	p.global_position = trap.global_position
	await _frames(3)
	var hp_after: float = p.health
	var start: Vector3 = p.global_position
	p.input_override = {"move": Vector2(0, -1), "fire": false, "aim": false}
	await _frames(20)
	var moved_while_held: float = (p.global_position - start).length()
	p.input_override = null
	if abs(hp_after - 80.0) < 0.01 and trap.closed_model.visible and not trap.open_model.visible and moved_while_held < 0.1:
		print("PASS test_bear_trap (health 100 to %.0f, closed, held %.2f units)" % [hp_after, moved_while_held])
	else:
		print("FAIL test_bear_trap: health %.1f, closed %s, moved %.2f" % [hp_after, trap.closed_model.visible, moved_while_held])

	# landmine: -30 to the player who steps on it, then it is gone
	var mine: Node3D = a.get_node("Hazards/Landmine6")
	var mine_pos: Vector3 = mine.global_position
	await _reset_player(mine_pos + Vector3(0, 0, 3))
	p.global_position = mine_pos
	await _frames(20)
	var mine_gone: bool = not is_instance_valid(mine) or mine.is_queued_for_deletion()
	var boom := false
	for e in a.get_node("Effects").get_children():
		if e.name.begins_with("CartoonExplosion"):
			boom = true
	if abs(p.health - 70.0) < 0.01 and mine_gone and boom:
		print("PASS test_landmine (health 100 to %.0f, mine gone, cartoon explosion)" % p.health)
	else:
		print("FAIL test_landmine: health %.1f, gone %s, explosion %s" % [p.health, mine_gone, boom])

	# gas can: one bullet sets it off; a bandit 1.5 units away is hurt
	var can: Node3D = a.get_node("Hazards/GasCanInner3")
	var victim := _dummy(0, can.global_position + Vector3(1.5, 0, 0))
	victim.set_physics_process(false)
	await _reset_player(can.global_position + Vector3(0, 0, 9))
	await _frames(4)
	for i in 4:
		var to: Vector3 = can.global_position + Vector3.UP * 0.5 - p.camera.global_position
		p.cam_yaw = atan2(-to.x, -to.z)
		p.rotation.y = p.cam_yaw
		p.cam_pitch = rad_to_deg(atan2(to.y, Vector2(to.x, to.z).length()))
		p._apply_camera()
	var w = p.weapons["blaster"]
	p._equip("blaster")
	w._cooldown = 0.0
	p.input_override = {"move": Vector2.ZERO, "fire": true, "fire_pressed": true, "aim": true}
	await _frames(2)
	p.input_override = null
	await _frames(6)
	var can_gone: bool = not is_instance_valid(can) or can.is_queued_for_deletion()
	var victim_damage: float = 1000.0 - victim.health
	if can_gone and victim_damage >= 30.0:
		print("PASS test_gas_can_explodes_when_shot (bandit 1.5 units away took %.0f)" % victim_damage)
	else:
		print("FAIL test_gas_can_explodes_when_shot: gone %s, bandit took %.0f" % [can_gone, victim_damage])
	victim.queue_free()

	# fire: the player, a bandit and a Hazmat stand in a fire patch
	var spot := Vector3(-16, 0, 16)
	var fire: Node3D = load("res://scenes/fx/fire_patch.tscn").instantiate()
	a.get_node("Effects").add_child(fire)
	fire.global_position = spot
	var bandit := _dummy(0, spot + Vector3(1.0, 0, 0))
	var hazmat := _dummy(1, spot + Vector3(-1.0, 0, 0.5))
	hazmat._throw_timer = 999.0     # a passive control: it stands in the fire and must not burn
	await _reset_player(spot + Vector3(0, 0, -0.8))
	await _seconds(2.0)
	var player_loss: float = 100.0 - p.health
	var bandit_loss: float = 1000.0 - bandit.health
	var hazmat_loss: float = 1000.0 - hazmat.health
	var flames_on: bool = p.get_node("Burning").emitting
	if player_loss >= 15.0 and player_loss <= 25.5 and bandit_loss >= 15.0 and hazmat_loss == 0.0 and flames_on:
		print("PASS test_fire_burns_player_and_bandit_not_hazmat (2 s: player -%.0f, bandit -%.0f, Hazmat -%.0f)" % [player_loss, bandit_loss, hazmat_loss])
	else:
		print("FAIL test_fire_burns_player_and_bandit_not_hazmat: player -%.0f, bandit -%.0f, Hazmat -%.0f, flames %s" % [player_loss, bandit_loss, hazmat_loss, flames_on])
	p.global_position = Vector3(0, 0, 6)
	bandit.queue_free()
	hazmat.queue_free()
	p.invulnerable = true
	Engine.time_scale = 5.0
	await _seconds(8.5)
	var alive_at_10: bool = is_instance_valid(fire) and not fire.is_queued_for_deletion()
	await _seconds(2.0)
	Engine.time_scale = 1.0
	var gone_at_12: bool = not is_instance_valid(fire)
	if alive_at_10 and gone_at_12:
		print("PASS test_fire_lasts_10_s_then_disappears")
	else:
		print("FAIL test_fire_lasts_10_s_then_disappears: at 10 s %s, gone at 12 s %s" % [alive_at_10, gone_at_12])

	# the Hazmat throws a gas tank that lands as a fire patch near the player
	await _reset_player(Vector3(10, 0, -15))
	p.invulnerable = true
	p.cam_yaw = 0.0
	p._apply_camera()
	var thrower := _dummy(1, Vector3(10, 0, -25.5))
	var patch = null
	var t := 0.0
	while patch == null and t < 8.0:
		await tree.physics_frame
		t += 1.0 / 60.0
		for e in a.get_node("Effects").get_children():
			if e.name.begins_with("FirePatch") and e.global_position.distance_to(p.global_position) < 4.0:
				patch = e
	if patch:
		print("PASS test_hazmat_throws_a_gas_tank_that_lands_as_fire (after %.1f s, %.1f units from the player)" % [t, patch.global_position.distance_to(p.global_position)])
	else:
		print("FAIL test_hazmat_throws_a_gas_tank_that_lands_as_fire: no fire near the player in 8 s")
	thrower.queue_free()

	# melee weapons are held in the left hand
	p.give_weapon("knife_1")
	p._equip("knife_1")
	await _frames(2)
	var held: MeshInstance3D = p.held_mesh()
	var in_left: bool = "LeftHand" in str(held.get_path()) and held.is_visible_in_tree()
	var right_knife_hidden: bool = not p.meshes["Knife_1"].is_visible_in_tree()
	p._equip("blaster")
	await _frames(2)
	var gun_right: bool = not ("LeftHand" in str(p.held_mesh().get_path())) and p.visible_weapon_count() == 1
	if in_left and right_knife_hidden and gun_right:
		print("PASS test_melee_weapons_in_the_left_hand")
	else:
		print("FAIL test_melee_weapons_in_the_left_hand: knife left %s, right knife hidden %s, gun right %s" % [in_left, right_knife_hidden, gun_right])
