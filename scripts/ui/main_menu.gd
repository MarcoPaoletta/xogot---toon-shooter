extends Node3D
## Title screen: the built yard, live (sun, shadows, swaying trees), seen by MenuCam orbiting it once every 48 s.

const RADIUS := 24.0
const HEIGHT := 7.5
const PERIOD := 48.0
const LOOK_AT := Vector3(0, 1.5, -4)

@onready var cam: Camera3D = $MenuCam
@onready var title: Label = $UI/Title
@onready var best: Label = $UI/Best
var t := 0.0
var _title_y := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	cam.current = true
	Audio.play_music("menu", 1.0, 1.0)
	best.text = "Best: %s · wave %d" % [_fmt(Game.best_score), Game.best_wave] if Game.runs > 0 else "Hold the yard for five waves"
	_title_y = title.position.y
	$UI/Buttons/Play.pressed.connect(func(): _click(); Game.start_run())
	$UI/Buttons/Quit.pressed.connect(func(): _click(); get_tree().quit())
	var music: CheckButton = $UI/Buttons/Toggles/Music
	var sound: CheckButton = $UI/Buttons/Toggles/Sound
	music.button_pressed = Game.music_on
	sound.button_pressed = Game.sfx_on
	music.toggled.connect(func(on): _click(); Game.set_music(on))
	sound.toggled.connect(func(on): Game.set_sfx(on); _click())
	for b in [$UI/Buttons/Play, $UI/Buttons/Quit, music, sound]:
		b.button_down.connect(func(): _squash(b))
		b.mouse_entered.connect(func(): Audio.play("ui_hover", 0.04, -6.0))
	$UI/Buttons/Play.grab_focus()
	_place(0.0)


func _fmt(v: int) -> String:
	var s := str(v)
	return s if s.length() <= 3 else s.substr(0, s.length() - 3) + " " + s.substr(s.length() - 3)


func _click() -> void:
	Audio.play("ui_click", 0.04)


func _squash(b: Control) -> void:
	b.pivot_offset = b.size * 0.5
	var tw := b.create_tween()
	tw.tween_property(b, "scale", Vector2(0.94, 0.94), 0.04)
	tw.tween_property(b, "scale", Vector2.ONE, 0.04)


func _process(delta: float) -> void:
	t += delta
	_place(t)
	title.position.y = _title_y + sin(t * TAU / 2.0) * 3.0


## Starts on the concept's side (azimuth measured from +Z) and orbits continuously.
func _place(time: float) -> void:
	var a := time / PERIOD * TAU
	cam.global_position = Vector3(sin(a) * RADIUS, HEIGHT, cos(a) * RADIUS)
	cam.look_at(LOOK_AT, Vector3.UP)
