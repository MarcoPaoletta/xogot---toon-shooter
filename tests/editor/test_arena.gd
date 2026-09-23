extends Node
## GDD 7.1: every child of Props and Perimeter has a StaticBody3D with at least one CollisionShape3D, the baked
## navigation mesh has more than 200 polygons and no vertex outside |X| < 18.6, |Z| < 18.6; eleven weapon crates.

var arena: Node3D


func before_all() -> void:
	arena = load("res://scenes/arena.tscn").instantiate()


func after_all() -> void:
	arena.free()


func _has_body_with_shape(n: Node) -> bool:
	var bodies: Array = [n] if n is StaticBody3D else []
	bodies.append_array(n.find_children("*", "StaticBody3D", true, false))
	for b in bodies:
		for c in b.get_children():
			if c is CollisionShape3D and c.shape != null:
				return true
	return false


func test_every_reachable_prop_has_collision() -> Variant:
	var missing := []
	for group in ["Props", "Perimeter"]:
		for c in arena.get_node(group).get_children():
			if not _has_body_with_shape(c):
				missing.append(str(c.name))
	return true if missing.is_empty() else "no collision: " + ", ".join(missing)


func test_navigation_mesh_is_baked_inside_the_yard() -> Variant:
	var nm: NavigationMesh = arena.get_node("Nav").navigation_mesh
	if nm == null:
		return "no navigation mesh"
	if nm.get_polygon_count() <= 200:
		return "only %d polygons" % nm.get_polygon_count()
	for v in nm.get_vertices():
		if abs(v.x) >= 18.6 or abs(v.z) >= 18.6:
			return "vertex outside the yard: %s" % v
	return true


func test_eleven_weapon_crates_one_per_unlockable_weapon() -> Variant:
	var ids := []
	for c in arena.get_node("WeaponCrates").get_children():
		ids.append(c.get("weapon_id"))
		if c.get_node_or_null("Gun") == null:
			return "%s has no Gun model" % c.name
	ids.sort()
	var want := ["grenade_launcher", "knife_2", "revolver", "revolver_small", "rocket_launcher", "short_cannon", "shotgun",
		"smg", "sniper", "sniper_2", "shovel"]
	want.sort()
	return true if ids == want else "crates: %s" % [ids]


func test_concept_cam_is_perspective_at_the_rig_pose() -> Variant:
	var cc: Camera3D = arena.get_node("ConceptCam")
	if cc.projection != Camera3D.PROJECTION_PERSPECTIVE:
		return "ConceptCam is not perspective"
	if cc.position.distance_to(Vector3(1.4, 3.0, 12.6)) > 0.01 or abs(cc.rotation_degrees.x + 8.0) > 0.1:
		return "ConceptCam at %s %s" % [cc.position, cc.rotation_degrees]
	return true
