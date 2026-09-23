extends Node3D
## A static character for ConceptDressing: one weapon mesh visible, a looping clip.

@export var weapon_mesh := "Pistol"
@export var clip := "Run_Shoot"
@export var clip_offset := 0.2

const WEAPON_MESH_NAMES := ["AK", "GrenadeLauncher", "Knife_1", "Knife_2", "Pistol", "Revolver", "Revolver_Small",
	"RocketLauncher", "ShortCannon", "Shotgun", "Shovel", "SMG", "Sniper", "Sniper_2"]


func _ready() -> void:
	for m in find_children("*", "MeshInstance3D", true, false):
		if m.name in WEAPON_MESH_NAMES:
			m.visible = m.name == weapon_mesh
	var anim: AnimationPlayer = find_children("*", "AnimationPlayer", true, false)[0]
	anim.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	anim.play(clip)
	anim.seek(clip_offset, true)
