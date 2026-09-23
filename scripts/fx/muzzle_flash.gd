extends Node3D
## The concept's yellow flash: a billboard star and a short omni light, 0.05 s.

const Textures := preload("res://scripts/fx/textures.gd")

static var _materials := {}      # one material per colour, shared (see particles_once.gd)

@export var life := 0.05
@export var continuous := false
@onready var quad: MeshInstance3D = $Quad
@onready var light: OmniLight3D = $Light


func _ready() -> void:
	set_color(Color("#ffe066"))
	quad.rotation.z = randf() * TAU


func set_color(c: Color) -> void:
	var key := c.to_html()
	if not _materials.has(key):
		var m: StandardMaterial3D = load("res://materials/flash.tres").duplicate()
		m.albedo_texture = Textures.star()
		m.albedo_color = c
		_materials[key] = m
	quad.material_override = _materials[key]


func _process(delta: float) -> void:
	if continuous:
		quad.rotation.z = randf() * TAU
		var s := randf_range(0.8, 1.2)
		quad.scale = Vector3(s, s, s)
		return
	life -= delta
	if life <= 0.0:
		queue_free()
