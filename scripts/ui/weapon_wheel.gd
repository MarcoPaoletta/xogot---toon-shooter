extends Control
## The weapon wheel (GDD 17.2): hold Tab, steer with the accumulated mouse delta, release to equip.
## Fourteen sectors clockwise from the top in table order; each shows the weapon's real 3D model rotating
## on its vertical axis, rendered by ModelsViewport only while the wheel is open.

const OUTER := 300.0
const INNER := 190.0
const DEAD_ZONE := 40.0
const SPIN := 60.0
const LOCKED := preload("res://materials/wheel_locked.tres")

@onready var dim: ColorRect = $Dim
@onready var ring: Control = $Ring
@onready var models: TextureRect = $Models
@onready var viewport: SubViewport = $ModelsViewport
@onready var slots: Array = [
	$ModelsViewport/WheelScene/Slot1, $ModelsViewport/WheelScene/Slot2, $ModelsViewport/WheelScene/Slot3,
	$ModelsViewport/WheelScene/Slot4, $ModelsViewport/WheelScene/Slot5, $ModelsViewport/WheelScene/Slot6,
	$ModelsViewport/WheelScene/Slot7, $ModelsViewport/WheelScene/Slot8, $ModelsViewport/WheelScene/Slot9,
	$ModelsViewport/WheelScene/Slot10, $ModelsViewport/WheelScene/Slot11, $ModelsViewport/WheelScene/Slot12,
	$ModelsViewport/WheelScene/Slot13, $ModelsViewport/WheelScene/Slot14]
@onready var name_label: Label = $Name
@onready var ammo_label: Label = $Ammo
@onready var counter: Label = $Counter

var player: Node = null
var is_open := false
var accumulated := Vector2.ZERO
var hovered := -1
var _unlocked_seen := {}
var _scales := []
var _time_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	models.texture = viewport.get_texture()
	ring.draw.connect(_draw_ring)
	for i in slots.size():
		_scales.append(1.0)


func sector_count() -> int:
	return Game.WEAPON_IDS.size()


func open(p: Node) -> void:
	player = p
	is_open = true
	accumulated = Vector2.ZERO
	hovered = -1
	visible = true
	modulate.a = 0.0
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_refresh_locks()
	_set_time_scale(0.25)
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(self, "modulate:a", 1.0, 0.1)
	Audio.play("ui_hover", 0.02, -4.0)


## Closes the wheel and returns the hovered weapon id, or "" when nothing (or a locked weapon) is hovered.
func close() -> String:
	is_open = false
	_set_time_scale(1.0)
	var t := create_tween().set_ignore_time_scale(true)
	t.tween_property(self, "modulate:a", 0.0, 0.1)
	t.tween_callback(func():
		if not is_open:
			visible = false
			viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED)
	if hovered < 0:
		return ""
	var id: String = Game.WEAPON_IDS[hovered]
	return id if player and player.is_owned(id) else ""


func _set_time_scale(v: float) -> void:
	if _time_tween:
		_time_tween.kill()
	_time_tween = create_tween().set_ignore_time_scale(true)
	_time_tween.tween_property(Engine, "time_scale", v, 0.1)


## The angle of the accumulated delta, clockwise from the top, picks one of the fourteen sectors.
func add_delta(rel: Vector2) -> void:
	accumulated += rel
	if accumulated.length() > 220.0:
		accumulated = accumulated.normalized() * 220.0
	hovered = sector_for(accumulated)


func sector_for(v: Vector2) -> int:
	if v.length() < DEAD_ZONE:
		return -1
	var a := fposmod(atan2(v.x, -v.y), TAU)
	var step := TAU / sector_count()
	return int(round(a / step)) % sector_count()


func _refresh_locks() -> void:
	for i in slots.size():
		var id: String = Game.WEAPON_IDS[i]
		var owned: bool = player != null and player.is_owned(id)
		for m in slots[i].find_children("*", "MeshInstance3D", true, false):
			m.material_override = null if owned else LOCKED
		if owned and not _unlocked_seen.get(id, false):
			_unlocked_seen[id] = true
			var pivot: Node3D = slots[i].get_node("Pivot")
			var base: Vector3 = pivot.scale
			var t := create_tween().set_ignore_time_scale(true)
			t.tween_property(pivot, "scale", base * 1.25, 0.15)
			t.tween_property(pivot, "scale", base, 0.15)


func _process(delta: float) -> void:
	if not visible:
		return
	var real := delta / maxf(Engine.time_scale, 0.01)
	for i in slots.size():
		var slot: Node3D = slots[i]
		slot.rotation.y += deg_to_rad(SPIN) * real
		var want := 1.2 if i == hovered else 1.0
		_scales[i] = move_toward(_scales[i], want, real / 0.08 * 0.2)
		slot.scale = Vector3.ONE * _scales[i]
	var show: int = hovered if hovered >= 0 else Game.WEAPON_IDS.find(player.current if player else "blaster")
	var id: String = Game.WEAPON_IDS[max(show, 0)]
	name_label.text = Game.weapon_name(id).to_upper()
	if player and player.is_owned(id):
		ammo_label.text = player.weapons[id].ammo_text()
		ammo_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		ammo_label.text = "LOCKED: find it in the yard"
		ammo_label.add_theme_color_override("font_color", Color("#c8c8c8"))
	counter.text = "%d / %d weapons" % [player.owned.size() if player else 0, sector_count()]
	ring.queue_redraw()


func _draw_ring() -> void:
	var c := ring.size * 0.5
	var n := sector_count()
	var step := TAU / n
	var held := Game.WEAPON_IDS.find(player.current) if player else -1
	for i in n:
		var mid := i * step - PI * 0.5
		var gap_o := 1.5 / OUTER
		var gap_i := 1.5 / INNER
		var pts := PackedVector2Array()
		var seg := 10
		for k in seg + 1:
			var a := mid - step * 0.5 + gap_o + (step - 2.0 * gap_o) * k / seg
			pts.append(c + Vector2(cos(a), sin(a)) * OUTER)
		for k in seg + 1:
			var a := mid + step * 0.5 - gap_i - (step - 2.0 * gap_i) * k / seg
			pts.append(c + Vector2(cos(a), sin(a)) * INNER)
		var owned: bool = player != null and player.is_owned(Game.WEAPON_IDS[i])
		var col := Color("#2f6fd6") if i == hovered else Color(0.118, 0.118, 0.133, 0.85)
		if not owned:
			col.a *= 0.45
		ring.draw_colored_polygon(pts, col)
		if i == held:
			var outline := pts.duplicate()
			outline.append(pts[0])
			ring.draw_polyline(outline, Color.WHITE, 3.0, true)
