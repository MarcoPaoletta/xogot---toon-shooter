extends RefCounted
## GDD 6 and pillar 2 (a). Run inside the live arena: `xo game eval --file tests/game/test_camera.gd`.

func _run():
	var tree: SceneTree = Engine.get_main_loop()
	var a = tree.current_scene
	var p = a.get_node("Player")
	a.spawner.stop()
	p.invulnerable = true
	await tree.physics_frame
	var c: Camera3D = p.camera
	var cc: Camera3D = a.get_node("ConceptCam")
	var dpos: float = c.global_position.distance_to(cc.global_position)
	var dang: float = rad_to_deg(c.global_basis.get_rotation_quaternion().angle_to(cc.global_basis.get_rotation_quaternion()))
	if dpos <= 0.05 and dang <= 0.5:
		print("PASS test_camera_at_spawn_is_concept_cam (%.4f units, %.3f deg)" % [dpos, dang])
	else:
		print("FAIL test_camera_at_spawn_is_concept_cam: %.4f units, %.3f deg" % [dpos, dang])
	var before: Vector3 = c.global_position
	p.global_position += Vector3(1, 0, 0)
	var moved: Vector3 = c.global_position - before
	if moved.distance_to(Vector3(1, 0, 0)) <= 0.001:
		print("PASS test_camera_follows_in_the_same_frame (moved %s)" % moved)
	else:
		print("FAIL test_camera_follows_in_the_same_frame: moved %s" % moved)
