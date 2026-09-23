extends Node
## Structure of every scene named in GDD section 8 (and 16.5, 17.4): the file exists, the root has the right
## type and name, the named children exist. Runs in the editor: `xo test run --root res://tests/editor`.

const SCENES := {
	"res://scenes/main.tscn": ["Node", "Main", ["SceneSlot", "Fader", "Fader/Rect"]],
	"res://scenes/arena.tscn": ["Node3D", "Arena", ["Environment", "Sun", "Ground", "Grass", "Perimeter", "Props", "ConceptCam",
		"ConceptDressing/BanditPose1", "ConceptDressing/BanditPose2", "Nav", "PlayerSpawn", "SpawnPoints", "PickupPoints",
		"Player", "Bandits", "Pickups", "Effects", "WaveSpawner", "HUD", "WeaponCrates"]],
	"res://scenes/actors/player.tscn": ["CharacterBody3D", "Player", ["Shape", "Model", "AimPoint", "CameraRig/Pitch/Arm/Camera",
		"WeaponSlot", "Muzzle", "Burning", "Model/Character_Soldier/CharacterArmature/Skeleton3D/LeftHand/Knife1Left",
		"Model/Character_Soldier/CharacterArmature/Skeleton3D/LeftHand/Knife2Left",
		"Model/Character_Soldier/CharacterArmature/Skeleton3D/LeftHand/ShovelLeft"]],
	"res://scenes/actors/bandit.tscn": ["CharacterBody3D", "Bandit", ["Shape", "Model", "NavAgent", "Eyes", "Muzzle", "Burning"]],
	"res://scenes/actors/health_pickup.tscn": ["Area3D", "HealthPickup", ["Shape", "Model", "Light"]],
	"res://scenes/actors/weapon_crate.tscn": ["Area3D", "WeaponCrate", ["Shape", "Crate", "Name", "Light"]],
	"res://scenes/fx/tracer.tscn": ["MeshInstance3D", "Tracer", []],
	"res://scenes/fx/muzzle_flash.tscn": ["Node3D", "MuzzleFlash", ["Quad", "Light"]],
	"res://scenes/fx/impact.tscn": ["GPUParticles3D", "Impact", []],
	"res://scenes/fx/explosion.tscn": ["GPUParticles3D", "Explosion", ["Light"]],
	"res://scenes/weapons/grenade.tscn": ["RigidBody3D", "Grenade", ["Model", "Shape"]],
	"res://scenes/weapons/rocket.tscn": ["Area3D", "Rocket", ["Model", "Shape", "Trail"]],
	"res://scenes/ui/main_menu.tscn": ["Node3D", "MainMenu", ["Arena", "MenuCam", "UI/Title", "UI/Subtitle", "UI/Buttons/Play",
		"UI/Best", "UI/Buttons/Toggles/Music", "UI/Buttons/Toggles/Sound", "UI/Buttons/Quit", "UI/Credit"]],
	"res://scenes/ui/hud.tscn": ["CanvasLayer", "HUD", ["Crosshair", "Health", "Wave", "Score", "Enemies", "Message",
		"DamageVignette", "HitMarker", "PauseMenu/Dim", "PauseMenu/Panel/Buttons/Resume", "PauseMenu/Panel/Buttons/Restart",
		"PauseMenu/Panel/Buttons/Menu", "PauseMenu/Panel/Buttons/Music", "PauseMenu/Panel/Buttons/Sound", "WeaponWheel"]],
	"res://scenes/ui/weapon_wheel.tscn": ["Control", "WeaponWheel", ["Ring", "ModelsViewport/WheelScene", "Models", "Name", "Ammo", "Counter"]],
	"res://scenes/actors/hazmat.tscn": ["CharacterBody3D", "Hazmat", ["Shape", "Model", "NavAgent", "Eyes", "Muzzle",
		"Model/Character_Hazmat/CharacterArmature/Skeleton3D/LeftHand/HeldTank"]],
	"res://scenes/weapons/gas_tank.tscn": ["RigidBody3D", "GasTank", ["Model", "Shape"]],
	"res://scenes/fx/fire_patch.tscn": ["Area3D", "FirePatch", ["Shape", "Scorch", "Flames", "Light", "Crackle"]],
	"res://scenes/fx/burning.tscn": ["GPUParticles3D", "Burning", []],
	"res://scenes/fx/cartoon_explosion.tscn": ["Node3D", "CartoonExplosion", ["Fireball", "Smoke", "Debris", "Sparks", "Shockwave", "Flash", "Light"]],
	"res://scenes/props/gas_can.tscn": ["StaticBody3D", "GasCan", ["Model", "Shape"]],
	"res://scenes/props/bear_trap.tscn": ["Area3D", "BearTrap", ["Open", "Closed", "Shape"]],
	"res://scenes/props/landmine.tscn": ["Area3D", "Landmine", ["Model", "Shape", "Light"]],
	"res://scenes/ui/results.tscn": ["Control", "Results", ["Background", "Panel/Layout/Title", "Panel/Layout/Score",
		"Panel/Layout/Stats", "Panel/Layout/Buttons/Retry", "Panel/Layout/Buttons/Menu"]],
}


func _check(path: String, spec: Array) -> Variant:
	if not ResourceLoader.exists(path):
		return "%s is missing" % path
	var inst: Node = load(path).instantiate()
	var problems := []
	if inst.get_class() != spec[0]:
		problems.append("root type %s" % inst.get_class())
	if inst.name != spec[1]:
		problems.append("root name %s" % inst.name)
	for child in spec[2]:
		if inst.get_node_or_null(child) == null:
			problems.append("no %s" % child)
	inst.free()
	return true if problems.is_empty() else "%s: %s" % [path, ", ".join(problems)]


func test_every_scene_has_its_named_nodes() -> Variant:
	var errs := []
	for path in SCENES:
		var r = _check(path, SCENES[path])
		if r is String:
			errs.append(r)
	return true if errs.is_empty() else "; ".join(errs)


func test_fourteen_weapon_prefabs_share_one_script() -> Variant:
	var ids := ["blaster", "pistol", "revolver", "revolver_small", "smg", "shotgun", "short_cannon", "sniper", "sniper_2",
		"grenade_launcher", "rocket_launcher", "knife_1", "knife_2", "shovel"]
	for id in ids:
		var path := "res://scenes/weapons/%s.tscn" % id
		if not ResourceLoader.exists(path):
			return "missing " + path
		var w: Node = load(path).instantiate()
		var ok: bool = w.get_script() != null and w.get_script().resource_path == "res://scripts/weapons/weapon.gd" and w.get("weapon_id") == id
		w.free()
		if not ok:
			return "bad prefab " + path
	var player: Node = load("res://scenes/actors/player.tscn").instantiate()
	var n: int = player.get_node("WeaponSlot").get_child_count()
	player.free()
	return true if n == 14 else "Player/WeaponSlot holds %d weapons" % n


func test_prop_prefabs_have_collision() -> Variant:
	var dir := DirAccess.open("res://scenes/props")
	var count := 0
	for f in dir.get_files():
		if not f.ends_with(".tscn"):
			continue
		var inst: Node = load("res://scenes/props/" + f).instantiate()
		# solid props are static bodies; the bear trap and the landmine (GDD 19) are triggers you step on
		var ok: bool = (inst is StaticBody3D or inst is Area3D) and inst.get_node_or_null("Shape") is CollisionShape3D and inst.get_node("Shape").shape != null
		inst.free()
		if not ok:
			return "prop without collision: " + f
		count += 1
	return true if count >= 34 else "only %d prop prefabs" % count
