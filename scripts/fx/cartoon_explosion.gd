extends Node3D
## The cartoon explosion (GDD 19) for gas cans, landmines and the launchers: a flash star, a fireball of
## flat shaded balls with dark rims, a smoke column, debris, sparks, a shockwave ring on the ground, a light.

const Textures := preload("res://scripts/fx/textures.gd")

@onready var ring: MeshInstance3D = $Shockwave
@onready var flash: MeshInstance3D = $Flash
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	for c in get_children():
		if c is GPUParticles3D:
			c.restart()
			c.emitting = true
	var rm: StandardMaterial3D = load("res://materials/shockwave.tres").duplicate()
	ring.material_override = rm
	ring.scale = Vector3(0.2, 1.0, 0.2)
	var fm: StandardMaterial3D = flash.material_override.duplicate()
	fm.albedo_texture = Textures.star()
	fm.albedo_color = Color("#fff3b0")
	flash.material_override = fm
	flash.scale = Vector3.ONE * 0.2
	var t := create_tween().set_parallel(true)
	t.tween_property(ring, "scale", Vector3(7.0, 1.0, 7.0), 0.38).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(rm, "albedo_color:a", 0.0, 0.38).set_ease(Tween.EASE_IN)
	t.tween_property(flash, "scale", Vector3.ONE * 3.2, 0.06)
	t.tween_property(flash, "scale", Vector3.ONE * 0.01, 0.1).set_delay(0.06)
	t.tween_property(light, "light_energy", 0.0, 0.4).set_ease(Tween.EASE_IN)
	get_tree().create_timer(2.0, false).timeout.connect(queue_free)
