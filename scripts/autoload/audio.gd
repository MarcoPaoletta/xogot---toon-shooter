extends Node
## SFX pool with random pitch variation (GDD 10, rule 3) and the music players with crossfade.
## The players are saved nodes in res://scenes/audio.tscn; this script only drives them.

const SFX_DIR := "res://assets/audio/sfx/"
const MUSIC_DIR := "res://assets/audio/music/"

@onready var _flat: Array = $Flat.get_children()
@onready var _positional: Array = $Positional.get_children()
@onready var _music: Array = [$MusicA, $MusicB]

var _cache := {}
var _flat_i := 0
var _pos_i := 0
var _music_i := 0
var current_music := ""
var _music_level := 1.0
var _level_tween: Tween
var _duck_tween: Tween
var _lowpass_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _stream(name: String) -> AudioStream:
	if not _cache.has(name):
		var path := SFX_DIR + name + ".wav"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


## Plays a sound effect. `pitch_var` 0.06 means a random pitch scale between 0.94 and 1.06.
## With `at` the sound is positional (AudioStreamPlayer3D), otherwise flat.
func play(name: String, pitch_var := 0.06, volume_db := 0.0, at = null) -> void:
	var s := _stream(name)
	if s == null:
		return
	var p
	if at is Vector3:
		p = _positional[_pos_i]
		_pos_i = (_pos_i + 1) % _positional.size()
		p.global_position = at
	else:
		p = _flat[_flat_i]
		_flat_i = (_flat_i + 1) % _flat.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.0 - pitch_var, 1.0 + pitch_var)
	p.play()


func play_music(name: String, fade := 0.8, level := 1.0) -> void:
	if name == current_music:
		set_music_level(level, fade)
		return
	current_music = name
	var old: AudioStreamPlayer = _music[_music_i]
	_music_i = 1 - _music_i
	var new: AudioStreamPlayer = _music[_music_i]
	var stream: AudioStreamWAV = load(MUSIC_DIR + name + ".wav").duplicate()
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	new.stream = stream
	new.volume_db = -60.0
	new.play()
	_music_level = level
	var t := create_tween().set_parallel(true)
	t.tween_property(new, "volume_db", linear_to_db(level), fade)
	if old.playing:
		t.tween_property(old, "volume_db", -60.0, fade)
		t.chain().tween_callback(old.stop)


func stop_music(fade := 0.5) -> void:
	current_music = ""
	for p in _music:
		if p.playing:
			var t := create_tween()
			t.tween_property(p, "volume_db", -60.0, fade)
			t.tween_callback(p.stop)


## Scales the current music (the breather drops it to 60 % over 0.5 s).
func set_music_level(level: float, time := 0.5) -> void:
	_music_level = level
	var p: AudioStreamPlayer = _music[_music_i]
	if _level_tween:
		_level_tween.kill()
	_level_tween = create_tween()
	_level_tween.tween_property(p, "volume_db", linear_to_db(max(level, 0.001)), time)


## Music ducks by `db` for `time` seconds (the wave cleared fanfare).
func duck(db := -6.0, time := 1.0) -> void:
	var bus := AudioServer.get_bus_index("Music")
	if _duck_tween:
		_duck_tween.kill()
	_duck_tween = create_tween()
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(bus, v), -4.0 + db, -4.0 + db, time)
	_duck_tween.tween_method(func(v): AudioServer.set_bus_volume_db(bus, v), -4.0 + db, -4.0, 0.4)


## 0.3 s low pass on the music when the player is hit.
func muffle(time := 0.3) -> void:
	var bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_effect_enabled(bus, 0, true)
	if _lowpass_tween:
		_lowpass_tween.kill()
	_lowpass_tween = create_tween()
	_lowpass_tween.tween_interval(time)
	_lowpass_tween.tween_callback(func(): AudioServer.set_bus_effect_enabled(bus, 0, false))
