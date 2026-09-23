extends Node
## Holds the current screen in SceneSlot and fades between screens (0.3 s).

@onready var slot: Node = $SceneSlot
@onready var fader: ColorRect = $Fader/Rect
var busy := false


func _ready() -> void:
	Game.main = self
	fader.color.a = 1.0
	_load(Game.MENU_SCENE)
	_fade(0.0)


func switch_to(path: String) -> void:
	if busy:
		return
	busy = true
	var t := _fade(1.0)
	await t.finished
	_load(path)
	await _fade(0.0).finished
	busy = false


func _load(path: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	for c in slot.get_children():
		c.queue_free()
	var scene: Node = load(path).instantiate()
	slot.add_child(scene)


func _fade(to: float) -> Tween:
	var t := create_tween().set_ignore_time_scale(true)
	t.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	t.tween_property(fader, "color:a", to, 0.3)
	return t
