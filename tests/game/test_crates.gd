extends RefCounted
## GDD 17.4 test_crates: eleven crates at the start, one per non starting weapon, at the arena positions;
## a scripted player walked into each one owns all fourteen weapons and the HUD reads "14 / 14 weapons";
## a picked crate is absent for 45 s and back at 46 s with the refill label; the melee crates do not return.

const POSITIONS := {
	"revolver": Vector3(-5.6, 0, 10.6), "revolver_small": Vector3(4.5, 0, 15.5), "smg": Vector3(-9.4, 0, 1.6),
	"shotgun": Vector3(11, 0, 6), "short_cannon": Vector3(15.5, 0, 9.5), "sniper": Vector3(-9.5, 0, -16),
	"sniper_2": Vector3(-15.6, 0, 12), "grenade_launcher": Vector3(-2, 0, -12), "rocket_launcher": Vector3(13, 0, -6),
	"knife_2": Vector3(8, 0, -13), "shovel": Vector3(1.5, 0, 13.2),
}

var tree: SceneTree


func _wait(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		await tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second * Engine.time_scale


func _run():
	tree = Engine.get_main_loop()
	var a = tree.current_scene
	var p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	p.invulnerable = true
	var crates: Array = a.get_node("WeaponCrates").get_children()
	var bad := []
	for c in crates:
		var want: Vector3 = POSITIONS.get(c.weapon_id, Vector3.INF)
		if c.global_position.distance_to(want) > 0.01:
			bad.append("%s at %s" % [c.weapon_id, c.global_position])
	if crates.size() == 11 and bad.is_empty():
		print("PASS test_eleven_crates_at_their_positions")
	else:
		print("FAIL test_eleven_crates_at_their_positions: %d crates, %s" % [crates.size(), bad])
	var shotgun_crate = null
	for c in crates:
		if c.weapon_id == "shotgun":
			shotgun_crate = c
		p.global_position = c.global_position + Vector3(0, 0.05, 0)
		p.velocity = Vector3.ZERO
		for f in 4:
			await tree.physics_frame
	p.global_position = Vector3(0, 0, 6)
	await tree.physics_frame
	var counter: String = a.get_node("HUD/WeaponInfo/Count").text
	if p.owned.size() == 14 and counter == "14 / 14 weapons":
		print("PASS test_walking_into_every_crate_unlocks_all_fourteen (%s)" % counter)
	else:
		print("FAIL test_walking_into_every_crate_unlocks_all_fourteen: owned %d, counter '%s'" % [p.owned.size(), counter])
	var melee_left := 0
	for c in a.get_node("WeaponCrates").get_children():
		if c.weapon_id in ["knife_2", "shovel"] and not c.is_queued_for_deletion():
			melee_left += 1
	# time travel: 45 s at ten times speed
	Engine.time_scale = 10.0
	await _wait(44.0)
	var absent_at_44: bool = not shotgun_crate.visible and not shotgun_crate.active
	await _wait(2.0)
	Engine.time_scale = 1.0
	var back_at_46: bool = shotgun_crate.visible and shotgun_crate.active and "REFILL" in shotgun_crate.get_node("Name").text
	if absent_at_44 and back_at_46 and melee_left == 0:
		print("PASS test_crate_returns_as_refill_after_45_s_melee_crates_do_not")
	else:
		print("FAIL test_crate_returns_as_refill_after_45_s_melee_crates_do_not: absent %s, back %s, melee left %d" % [absent_at_44, back_at_46, melee_left])
