extends CanvasLayer
## HUD (GDD 11.2 and 17.3): score with count up and pops, wave and enemies, announcements, health bar,
## crosshair, damage vignette and edge marker, weapon name, ammo and weapon count, pause menu.

@onready var score_label: Label = $Score
@onready var score_pop: Label = $ScorePop
@onready var wave_label: Label = $Wave
@onready var enemies_label: Label = $Enemies
@onready var message_label: Label = $Message
@onready var health_bar: ProgressBar = $Health
@onready var health_label: Label = $Health/Value
@onready var crosshair: Control = $Crosshair
@onready var vignette: ColorRect = $DamageVignette
@onready var hit_marker: Control = $HitMarker
@onready var weapon_name: Label = $WeaponInfo/Name
@onready var ammo_label: Label = $WeaponInfo/Ammo
@onready var count_label: Label = $WeaponInfo/Count
@onready var hint_label: Label = $WeaponInfo/Hint
@onready var pause_menu: Control = $PauseMenu
@onready var wheel: Control = $WeaponWheel

var player: Node = null
var arena: Node = null
var _shown_score := 0.0
var _score_target := 0
var _message_tween: Tween
var _hint_time := 0.0
var _vignette := 0.0
var _health_fill: StyleBoxFlat
var _msg_base_y := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_menu.visible = false
	message_label.modulate.a = 0.0
	_msg_base_y = message_label.position.y
	score_pop.modulate.a = 0.0
	hint_label.visible = false
	_health_fill = health_bar.get_theme_stylebox("fill").duplicate()
	health_bar.add_theme_stylebox_override("fill", _health_fill)
	$PauseMenu/Panel/Buttons/Resume.pressed.connect(toggle_pause)
	$PauseMenu/Panel/Buttons/Restart.pressed.connect(func(): _click(); Game.start_run())
	$PauseMenu/Panel/Buttons/Menu.pressed.connect(func(): _click(); Game.to_menu())
	var music: CheckButton = $PauseMenu/Panel/Buttons/Music
	var sound: CheckButton = $PauseMenu/Panel/Buttons/Sound
	music.button_pressed = Game.music_on
	sound.button_pressed = Game.sfx_on
	music.toggled.connect(func(on): _click(); Game.set_music(on))
	sound.toggled.connect(func(on): Game.set_sfx(on); _click())
	for b in $PauseMenu/Panel/Buttons.get_children():
		if b is BaseButton:
			b.button_down.connect(func(): _squash(b))
			b.mouse_entered.connect(func(): Audio.play("ui_hover", 0.04, -6.0))


func _click() -> void:
	Audio.play("ui_click", 0.04)


func _squash(b: Control) -> void:
	b.pivot_offset = b.size * 0.5
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(0.94, 0.94), 0.04)
	t.tween_property(b, "scale", Vector2.ONE, 0.04)


func bind(p: Node, a: Node) -> void:
	player = p
	arena = a
	p.health_changed.connect(set_health)
	p.weapon_changed.connect(func(_id): _update_weapon(true))
	p.ammo_changed.connect(func(): _update_weapon(false))
	set_health(p.health)
	_update_weapon(false)


func _process(delta: float) -> void:
	# score count up
	if _shown_score < _score_target:
		_shown_score = min(float(_score_target), _shown_score + max(200.0, (_score_target - _shown_score) * 6.0) * delta)
		score_label.text = "%d" % int(_shown_score)
	# vignette fade (0.4 s)
	if _vignette > 0.0:
		_vignette = max(0.0, _vignette - delta * 0.35 / 0.4)
		(vignette.material as ShaderMaterial).set_shader_parameter("amount", _vignette)
	# crosshair state
	if player:
		var hv := Vector2(player.velocity.x, player.velocity.z).length()
		crosshair.target_gap = 3.0 if player.aiming else (12.0 if hv > 1.0 else 6.0)
		var w = player.weapon()
		crosshair.scoped = w != null and w.scoped and player.aiming and player.aim_blend > 0.9
		crosshair.visible = player.alive and not player.wheel_open
		if player.health < 30.0 and player.alive:
			health_bar.modulate.a = 0.65 + 0.35 * sin(Time.get_ticks_msec() * 0.012)
		else:
			health_bar.modulate.a = 1.0
	if _hint_time > 0.0:
		_hint_time -= delta
		hint_label.visible = _hint_time > 0.0


func set_score(v: int, pop := true, delta_points := 0) -> void:
	_score_target = v
	if not pop:
		_shown_score = v
		score_label.text = "%d" % v
		return
	if delta_points > 0:
		score_pop.text = "+%d" % delta_points
		score_pop.modulate.a = 1.0
		score_pop.scale = Vector2(1.3, 1.3)
		var t := score_pop.create_tween().set_parallel(true)
		t.tween_property(score_pop, "scale", Vector2.ONE, 0.15)
		t.tween_property(score_pop, "modulate:a", 0.0, 0.45).set_delay(0.15)


func set_wave(n: int, total: int) -> void:
	wave_label.text = "Wave %d / %d" % [n, total]


func set_enemies(n: int) -> void:
	enemies_label.text = "%d left" % n


## A wave announcement: slides in over 0.4 s, holds 1.2 s, slides out over 0.4 s.
func announce(text: String) -> void:
	message(text, 1.2, 0.4, true)


func message(text: String, hold := 2.0, slide := 0.3, big := false) -> void:
	message_label.text = text
	message_label.add_theme_font_size_override("font_size", 64 if big else 36)
	if _message_tween:
		_message_tween.kill()
	message_label.modulate.a = 0.0
	var base_y := _msg_base_y
	message_label.position.y = base_y - 30.0
	_message_tween = message_label.create_tween()
	_message_tween.set_parallel(true)
	_message_tween.tween_property(message_label, "modulate:a", 1.0, slide)
	_message_tween.tween_property(message_label, "position:y", base_y, slide).set_ease(Tween.EASE_OUT)
	_message_tween.chain().tween_interval(hold)
	_message_tween.chain().tween_property(message_label, "modulate:a", 0.0, slide)


func show_hint(time: float) -> void:
	_hint_time = max(_hint_time, time)
	hint_label.visible = true


func set_health(v: float) -> void:
	health_bar.value = v
	health_label.text = "%d" % int(ceil(v))
	var col := Color("#56c956") if v > 60.0 else (Color("#f0a13a") if v > 30.0 else Color("#e8453c"))
	_health_fill.bg_color = col


func damage_flash(from_position: Vector3) -> void:
	_vignette = 0.35
	(vignette.material as ShaderMaterial).set_shader_parameter("amount", _vignette)
	if player:
		var cam: Camera3D = player.camera
		var to := from_position - cam.global_position
		var fwd := -cam.global_basis.z
		var right := cam.global_basis.x
		fwd.y = 0.0
		right.y = 0.0
		var a := atan2(to.dot(right.normalized()), to.dot(fwd.normalized()))
		hit_marker.show_from(a)


func crosshair_hit() -> void:
	crosshair.hit_time = 0.1


func _update_weapon(flash: bool) -> void:
	if player == null or player.current == "":
		return
	var w = player.weapon()
	weapon_name.text = Game.weapon_name(player.current)
	ammo_label.text = w.ammo_text()
	ammo_label.add_theme_color_override("font_color", Color("#ff5a4a") if (not w.infinite() and w.ammo <= 0) else Color.WHITE)
	count_label.text = "%d / %d weapons" % [player.owned.size(), Game.WEAPON_IDS.size()]
	if flash:
		weapon_name.modulate = Color(1.6, 1.4, 0.6)
		weapon_name.create_tween().tween_property(weapon_name, "modulate", Color.WHITE, 0.3)


func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_menu.visible = paused
	_click()
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		$PauseMenu/Panel/Buttons/Resume.grab_focus()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
