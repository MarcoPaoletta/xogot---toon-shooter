extends RefCounted
## GDD 7.2, the three facing tests, with real mouse motion events and the real input actions.

var tree: SceneTree
var a
var p


func _motion(px: float) -> void:
	# 0.1 degree per pixel: sent in 100 px steps like a real mouse
	var left := px
	while abs(left) > 0.01:
		var step: float = clamp(left, -100.0, 100.0)
		var ev := InputEventMouseMotion.new()
		ev.relative = Vector2(step, 0)
		ev.screen_relative = Vector2(step, 0)
		Input.parse_input_event(ev)
		left -= step
		await tree.process_frame


func _angle(v1: Vector3, v2: Vector3) -> float:
	return rad_to_deg(v1.angle_to(v2))


func _reset(pos: Vector3) -> void:
	p.global_position = pos
	p.velocity = Vector3.ZERO
	p.rotation.y = 0.0
	p.cam_yaw = 0.0
	p.cam_pitch = p.DEFAULT_PITCH
	p._apply_camera()
	await tree.physics_frame


func _run():
	tree = Engine.get_main_loop()
	a = tree.current_scene
	p = a.get_node("Player")
	a.spawner.stop()
	for b in a.get_node("Bandits").get_children():
		b.queue_free()
	p.invulnerable = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	await _reset(Vector3(0, 0, 6))

	# 1. from spawn: fire one frame, facing -Z, and the crosshair ray lands on a 1 x 1 wall placed on it
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1, 1, 0.2)
	shape.shape = box
	wall.add_child(shape)
	a.get_node("Effects").add_child(wall)
	for f in 3:
		await tree.physics_frame
	var r: Array = p.weapons["blaster"].aim_ray()
	wall.global_position = r[0] + r[1] * 6.0
	for f in 3:
		await tree.physics_frame
	var w = p.weapons["blaster"]
	Input.action_press("fire")
	await tree.physics_frame
	await tree.physics_frame
	Input.action_release("fire")
	var fwd: Vector3 = -p.global_basis.z
	var hit_wall: bool = w.last_hit_bodies.has(wall)
	if _angle(fwd, Vector3(0, 0, -1)) <= 2.0 and hit_wall:
		print("PASS test_facing_from_spawn (forward %s, shot hit the wall on the crosshair ray)" % fwd)
	else:
		print("FAIL test_facing_from_spawn: forward %s, hit wall %s (shots %d, hit %s, wall at %s, ray now %s)" % [fwd, hit_wall, w.shots_fired, w.last_hit_bodies, wall.global_position, w.aim_ray()])
	wall.queue_free()
	await tree.physics_frame

	# 2. camera rotated 90 degrees right, fire held, move_forward for 30 frames
	await _reset(Vector3(0, 0, 6))
	await _motion(900.0)
	var start: Vector3 = p.global_position
	Input.action_press("fire")
	Input.action_press("move_forward")
	for i in 30:
		await tree.physics_frame
	Input.action_release("move_forward")
	Input.action_release("fire")
	fwd = -p.global_basis.z
	var d: Vector3 = p.global_position - start
	if _angle(fwd, Vector3(1, 0, 0)) <= 2.0 and d.x >= 2.5 and abs(d.z) < 0.3:
		print("PASS test_facing_camera_90 (forward %s, moved %s)" % [fwd, d])
	else:
		print("FAIL test_facing_camera_90: forward %s, moved %s" % [fwd, d])

	# 3. camera rotated 180 degrees, fire held, move_right for 30 frames (from an open spot, see GDD section 18)
	await _reset(Vector3(0, 0, 10))
	await _motion(1800.0)
	start = p.global_position
	Input.action_press("fire")
	Input.action_press("move_right")
	for i in 30:
		await tree.physics_frame
	Input.action_release("move_right")
	Input.action_release("fire")
	fwd = -p.global_basis.z
	d = p.global_position - start
	if _angle(fwd, Vector3(0, 0, 1)) <= 2.0 and d.x <= -2.5:
		print("PASS test_facing_camera_180 (forward %s, moved %s)" % [fwd, d])
	else:
		print("FAIL test_facing_camera_180: forward %s, moved %s" % [fwd, d])
