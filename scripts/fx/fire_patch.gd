extends Area3D
## A patch of burning ground (GDD 19): 10 s of flames on a scorched disc of radius 2.2, then a 1 s fade.
## Every player or enemy standing in it keeps burning for 1.5 s after leaving (10 damage per second).

const LIFE := 10.0
const FADE := 1.0

@onready var flames: GPUParticles3D = $Flames
@onready var scorch: MeshInstance3D = $Scorch
@onready var light: OmniLight3D = $Light
@onready var crackle: AudioStreamPlayer3D = $Crackle
var t := 0.0
var _ending := false


func _ready() -> void:
	add_to_group("fire_patches")
	var m: ShaderMaterial = scorch.material_override.duplicate()
	scorch.material_override = m
	m.set_shader_parameter("fade", 0.0)
	create_tween().tween_method(func(v): m.set_shader_parameter("fade", v), 0.0, 1.0, 0.25)
	flames.emitting = true
	var s: AudioStreamWAV = crackle.stream.duplicate()
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(round(s.get_length() * s.mix_rate))
	crackle.stream = s
	crackle.volume_db = -4.0
	crackle.play()


func _physics_process(delta: float) -> void:
	t += delta
	if not _ending:
		for b in get_overlapping_bodies():
			if b.has_method("ignite"):
				b.ignite(1.5)
		light.light_energy = 2.4 + sin(t * 17.0) * 0.4 + sin(t * 29.0) * 0.3
	if t >= LIFE and not _ending:
		_ending = true
		flames.emitting = false
		var m: ShaderMaterial = scorch.material_override
		var tw := create_tween().set_parallel(true)
		tw.tween_method(func(v): m.set_shader_parameter("fade", v), 1.0, 0.0, FADE)
		tw.tween_property(light, "light_energy", 0.0, FADE)
		tw.tween_property(crackle, "volume_db", -40.0, FADE)
		tw.chain().tween_callback(queue_free)
