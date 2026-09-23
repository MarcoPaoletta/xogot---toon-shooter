extends MeshInstance3D
## A 0.03 x 0.03 unshaded additive line from the muzzle to the hit point, visible for 0.05 s.

const LIFE := 0.05
static var _materials := {}      # one material per colour, shared (see particles_once.gd)
var life := LIFE


func setup(from: Vector3, to: Vector3, color: Color) -> void:
	var d := to - from
	var length := d.length()
	if length < 0.05:
		queue_free()
		return
	global_position = from + d * 0.5
	look_at(to, Vector3.UP if abs(d.normalized().y) < 0.99 else Vector3.RIGHT)
	scale = Vector3(1, 1, length)
	var key := color.to_html()
	if not _materials.has(key):
		var m: StandardMaterial3D = material_override.duplicate()
		m.albedo_color = color
		_materials[key] = m
	material_override = _materials[key]


func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
