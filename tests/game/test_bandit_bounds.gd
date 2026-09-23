extends RefCounted
## GDD 7.4, differential: 60 simulated seconds with the player standing still at spawn (invulnerable) and all
## five waves forced to spawn at their normal gaps (a bandit is removed once it has lived 10 s, so the waves
## advance without the player shooting). Every physics frame, every living bandit: |X| < 18.6, |Z| < 18.6,
## -0.1 < Y < 0.6, and a sphere of radius 0.35 at its chest overlaps no world or fence collider. Each bandit
## must also have travelled at least 8 units in its first 10 s alive: a bandit that never moves FAILS. The
## negative control at the end proves that clause: a bandit with speed 0 is reported as failing.

const SIM_SECONDS := 60.0
const SCALE := 2.0

var tree: SceneTree
var a
var p
var violations := []
var checked := {}
var travel_fail := []


func _check_frame(space: PhysicsDirectSpaceState3D, sphere: SphereShape3D) -> void:
	for b in a.get_node("Bandits").get_children():
		if not b.alive:
			continue
		var pos: Vector3 = b.global_position
		if abs(pos.x) >= 18.6 or abs(pos.z) >= 18.6 or pos.y <= -0.1 or pos.y >= 0.6:
			violations.append("%s out of bounds at %s" % [b.name, pos])
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = sphere
		q.transform = Transform3D(Basis(), pos + Vector3.UP * 1.2)
		q.collision_mask = 1 | 16
		var hits := space.intersect_shape(q, 4)
		if not hits.is_empty():
			violations.append("%s inside %s at %s" % [b.name, hits[0].collider.name, pos])
		if b.age >= 10.0 and not checked.has(b):
			checked[b] = b.travelled
			if b.travelled < 8.0:
				travel_fail.append("%s travelled %.1f" % [b.name, b.travelled])
			b.take_damage(100000.0, b.global_position)


func _run():
	tree = Engine.get_main_loop()
	a = tree.current_scene
	p = a.get_node("Player")
	p.invulnerable = true
	var space: PhysicsDirectSpaceState3D = p.get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 0.35
	Engine.time_scale = SCALE
	var sim := 0.0
	var waves_seen := {}
	while sim < SIM_SECONDS:
		await tree.physics_frame
		sim += 1.0 / Engine.physics_ticks_per_second * SCALE
		waves_seen[a.spawner.wave] = true
		_check_frame(space, sphere)
	Engine.time_scale = 1.0
	var n := checked.size()
	print("INFO simulated %.0f s, waves reached %s, bandits checked through 10 s: %d, frame violations: %d" % [sim, waves_seen.keys(), n, violations.size()])
	if violations.is_empty():
		print("PASS test_bandits_stay_in_the_yard_and_out_of_geometry")
	else:
		print("FAIL test_bandits_stay_in_the_yard_and_out_of_geometry: %s" % [violations.slice(0, 5)])
	if travel_fail.is_empty() and n >= 5:
		print("PASS test_bandits_move_at_least_8_units_in_10_s (%d bandits)" % n)
	else:
		print("FAIL test_bandits_move_at_least_8_units_in_10_s: %s (checked %d)" % [travel_fail, n])

	# negative control: the same clause on a bandit that never moves must fail
	a.spawner.stop()
	var still: Node = a.get_node("WaveSpawner").bandit_scenes[0].instantiate()
	still.setup({"speed": 0.0, "range": 9.0, "burst_pause": 2.0}, p)
	a.get_node("Bandits").add_child(still)
	still.global_position = Vector3(-14, 0, 17)
	var t := 0.0
	while t < 10.2:
		await tree.physics_frame
		t += 1.0 / Engine.physics_ticks_per_second
	if still.travelled < 8.0:
		print("PASS test_negative_control_still_bandit_fails_the_travel_clause (travelled %.2f)" % still.travelled)
	else:
		print("FAIL test_negative_control_still_bandit_fails_the_travel_clause: travelled %.2f" % still.travelled)
