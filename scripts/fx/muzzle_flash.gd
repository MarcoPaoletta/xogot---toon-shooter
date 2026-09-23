extends Node3D
## The concept's yellow flash: a billboard star and a short omni light, 0.05 s.

const Textures := preload("res://scripts/fx/textures.gd")

@export var life := 0.05
@export var continuous := false
@onready var quad: MeshInstance3D = $Quad
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	var m: StandardMaterial3D = quad.material_override.duplicate()
	m.albedo_texture = Textures.star()
	quad.material_override = m
	quad.rotation.z = randf() * TAU


func set_color(c: Color) -> void:
	(quad.material_override as StandardMaterial3D).albedo_color = c


func _process(delta: float) -> void:
	if continuous:
		quad.rotation.z = randf() * TAU
		var s := randf_range(0.8, 1.2)
		quad.scale = Vector3(s, s, s)
		return
	life -= delta
	if life <= 0.0:
		queue_free()
