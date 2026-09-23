extends Control
## Results (GDD 11.4): title, the score counting up over 1.2 s, stats, Retry and Menu over the last frame, dimmed.

@onready var bg: TextureRect = $Background
@onready var title: Label = $Panel/Layout/Title
@onready var score: Label = $Panel/Layout/Score
@onready var stats: Label = $Panel/Layout/Stats
var _target := 0
var _shown := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var r: Dictionary = Game.last_result
	if Game.last_frame:
		bg.texture = Game.last_frame
	title.text = r.get("title", "Results")
	title.add_theme_color_override("font_color", Color("#ffd36b") if r.get("won", false) else Color("#ff6a5a"))
	_target = int(r.get("score", 0))
	var secs := int(r.get("time", 0.0))
	var lines := [
		"Waves cleared: %d / %d" % [r.get("waves_cleared", 0), Game.WAVES.size()],
		"Kills: %d" % r.get("kills", 0),
		"Weapons found: %d / %d" % [r.get("weapons", 3), Game.WEAPON_IDS.size()],
		"Time: %d:%02d" % [secs / 60, secs % 60],
	]
	if r.get("survival_bonus", 0) > 0:
		lines.append("Survival bonus: +%d" % r["survival_bonus"])
	lines.append("Best: %d%s" % [Game.best_score, "   new best!" if r.get("new_best", false) else ""])
	stats.text = "\n".join(lines)
	$Panel/Layout/Buttons/Retry.pressed.connect(func(): Audio.play("ui_click", 0.04); Game.start_run())
	$Panel/Layout/Buttons/Menu.pressed.connect(func(): Audio.play("ui_click", 0.04); Game.to_menu())
	$Panel/Layout/Buttons/Retry.grab_focus()
	Audio.play_music("menu", 1.5, 0.5)
	var panel: Control = $Panel
	panel.modulate.a = 0.0
	panel.create_tween().tween_property(panel, "modulate:a", 1.0, 0.3)


func _process(delta: float) -> void:
	if _shown < _target:
		_shown = min(float(_target), _shown + _target / 1.2 * delta)
	score.text = "%d" % int(_shown)
