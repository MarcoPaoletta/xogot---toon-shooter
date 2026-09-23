extends RefCounted
## GDD 9: every character instance shows exactly one weapon mesh (player, live bandits, the concept dressing).

const NAMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]


func _count(n: Node) -> int:
	var c := 0
	for m in n.find_children("*", "MeshInstance3D", true, false):
		if m.name in NAMES and m.visible:
			c += 1
	return c


func _run():
	var tree: SceneTree = Engine.get_main_loop()
	var a = tree.current_scene
	a.get_node("Player").invulnerable = true
	var t := 0.0
	while a.get_node("Bandits").get_child_count() < 1 and t < 8.0:
		await tree.physics_frame
		t += 1.0 / 60.0
	var bad := []
	var checked := 0
	var chars: Array = [a.get_node("Player"), a.get_node("ConceptDressing/BanditPose1"), a.get_node("ConceptDressing/BanditPose2")]
	chars.append_array(a.get_node("Bandits").get_children())
	for c in chars:
		checked += 1
		var n := _count(c)
		if n != 1:
			bad.append("%s shows %d" % [c.name, n])
	if bad.is_empty() and checked >= 4:
		print("PASS test_every_character_shows_exactly_one_weapon (%d characters)" % checked)
	else:
		print("FAIL test_every_character_shows_exactly_one_weapon: %s (checked %d)" % [bad, checked])
