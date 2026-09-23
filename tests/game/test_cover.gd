extends RefCounted
## Pillar 3: the player 0.8 units behind a SackTrench, a bandit 15 units away on the far side at the same
## height, firing its normal 5 degree bursts at the player's AimPoint (forced every 0.15 s so the test does not
## depend on its line of sight rule): zero damage over 10 s. Then the player steps 2 units sideways into the
## open (three units, see GDD section 18): damage within 2 s.

var tree: SceneTree


func _run():
	tree = Engine.get_main_loop()
	var a = tree.current_scene
	var p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	var wall: Node3D = a.get_node("Props/SandbagWest1")
	var axis: Vector3 = wall.global_basis.x.normalized()
	var normal: Vector3 = wall.global_basis.z.normalized()
	var centre: Vector3 = (wall.get_node("Shape") as Node3D).global_position
	# centred behind the wall, 0.8 from its back face (half depth 0.46) plus the capsule radius
	var cover_pos: Vector3 = centre + normal * (0.46 + 0.8 + 0.45)
	cover_pos.y = 0.0
	p.global_position = cover_pos
	p.velocity = Vector3.ZERO
	var bpos: Vector3 = centre - normal * 15.0
	bpos.y = 0.0
	var b: Node = a.get_node("WaveSpawner").bandit_scenes[0].instantiate()
	b.setup({"speed": 0.0, "range": 20.0, "burst_pause": 2.0}, p)
	a.get_node("Bandits").add_child(b)
	b.global_position = bpos
	b.max_health = 100000.0
	b.health = 100000.0
	b.set_physics_process(false)
	await tree.physics_frame
	var dir: Vector3 = p.global_position - b.global_position
	b.rotation.y = atan2(-dir.x, -dir.z)
	p.health = 100.0
	var t := 0.0
	var shot_t := 0.0
	var shots := 0
	while t < 10.0:
		await tree.physics_frame
		var dt := 1.0 / Engine.physics_ticks_per_second
		t += dt
		shot_t += dt
		if shot_t >= 0.15:
			shot_t = 0.0
			b._shoot()
			shots += 1
	var behind: float = 100.0 - p.health
	if behind == 0.0:
		print("PASS test_cover_blocks_bandit_shots (%d shots, 0 damage over 10 s)" % shots)
	else:
		print("FAIL test_cover_blocks_bandit_shots: %.0f damage from %d shots" % [behind, shots])
	# three units sideways (GDD section 18: with a 3.35 wide wall, two units from the middle leaves the line of
	# fire only 0.13 units past the wall's end because of parallax); the capsule is clearly in the open
	p.global_position = cover_pos + axis * 3.0
	await tree.physics_frame
	t = 0.0
	var first_hit := -1.0
	while t < 2.0:
		await tree.physics_frame
		var dt := 1.0 / Engine.physics_ticks_per_second
		t += dt
		shot_t += dt
		if shot_t >= 0.15:
			shot_t = 0.0
			b._shoot()
		if p.health < 100.0 and first_hit < 0.0:
			first_hit = t
	if first_hit > 0.0:
		print("PASS test_open_ground_takes_damage (first hit after %.2f s)" % first_hit)
	else:
		print("FAIL test_open_ground_takes_damage: no hit in 2 s")
	b.queue_free()
