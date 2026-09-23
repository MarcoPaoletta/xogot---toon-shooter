extends RefCounted
## GDD 9 and 19: the player, every bandit and the concept dressing show exactly one weapon mesh; a Hazmat shows
## none of the fourteen guns and carries his gas tank in the left hand.

const NAMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]


## Weapon meshes shown by a character. `local` counts the meshes' own visibility flags, for the concept
## dressing, which is hidden as a whole during play.
func _count(n: Node, local := false) -> int:
	var c := 0
	for m in n.find_children("*", "MeshInstance3D", true, false):
		if m.name in NAMES and (m.visible if local else m.is_visible_in_tree()):
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
	var hz: Node3D = a.get_node("WaveSpawner").bandit_scenes[1].instantiate()
	a.get_node("Bandits").add_child(hz)
	hz.global_position = Vector3(0, 0, -20)
	await tree.physics_frame
	for c in chars:
		checked += 1
		var n := _count(c, c.name.begins_with("BanditPose"))
		if n != 1:
			bad.append("%s shows %d" % [c.name, n])
	if _count(hz) != 0 or not hz.find_child("HeldTank", true, false).is_visible_in_tree():
		bad.append("the Hazmat shows %d guns, tank visible %s" % [_count(hz), hz.find_child("HeldTank", true, false).is_visible_in_tree()])
	if bad.is_empty() and checked >= 4:
		print("PASS test_every_character_shows_exactly_one_weapon (%d characters)" % checked)
	else:
		print("FAIL test_every_character_shows_exactly_one_weapon: %s (checked %d)" % [bad, checked])
