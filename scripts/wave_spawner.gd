extends Node
## Five waves from Game.WAVES (GDD 12): spawn gap, max alive, seeded spawn point choice outside the camera's
## view cone (GDD 7.4), 5 s breathers. `bandit_scenes`: [0] the bandit, [1] the Hazmat (GDD 19); each wave's
## spawn order is planned when it begins, with its Hazmats spread evenly through it.

signal wave_started(n: int)
signal wave_cleared(n: int)
signal all_waves_cleared
signal bandit_spawned(bandit: Node)
signal bandit_died(bandit: Node)

@export var bandit_scenes: Array[PackedScene] = []

var wave := 0
var spawned := 0
var alive := 0
var running := false
var in_breather := false
var _gap_timer := 0.0
var _breather_timer := 0.0
var _rng := RandomNumberGenerator.new()
var spawn_parent: Node3D
var spawn_points: Array = []
var player: Node3D
var camera: Camera3D
var _order: Array = []
@export var view_distance := 40.0      # beyond this a spawn point counts as out of view
@export var min_player_distance := 12.0


func setup(parent: Node3D, points: Array, target: Node3D, cam: Camera3D) -> void:
	spawn_parent = parent
	spawn_points = points
	player = target
	camera = cam


func start() -> void:
	running = true
	_begin_wave(1)


func stop() -> void:
	running = false


func total_waves() -> int:
	return Game.WAVES.size()


func params() -> Dictionary:
	return Game.WAVES[clamp(wave - 1, 0, total_waves() - 1)]


func wave_total() -> int:
	var p := params()
	return int(p["count"]) + int(p.get("hazmats", 0))


func remaining() -> int:
	if wave == 0:
		return 0
	return wave_total() - spawned + alive


func _begin_wave(n: int) -> void:
	wave = n
	spawned = 0
	alive = 0
	in_breather = false
	_rng.seed = 4000 + n
	_gap_timer = 0.5
	var p := params()
	var total := wave_total()
	var hz := int(p.get("hazmats", 0))
	_order.clear()
	for i in total:
		_order.append(0)
	# the first Hazmat is the second spawn; the others are spread over the rest of the wave
	for k in hz:
		var at := 1 if k == 0 else int(round(1.0 + float(k) * (total - 1) / float(hz)))
		_order[clamp(at, 0, total - 1)] = 1
	wave_started.emit(n)


func _process(delta: float) -> void:
	if not running:
		return
	if in_breather:
		_breather_timer -= delta
		if _breather_timer <= 0.0:
			_begin_wave(wave + 1)
		return
	var p := params()
	_gap_timer -= delta
	if spawned < wave_total() and alive < int(p["max_alive"]) and _gap_timer <= 0.0:
		_spawn(p)
		_gap_timer = float(p["gap"])


func pick_point() -> Vector3:
	var fwd := -camera.global_basis.z if camera else Vector3.FORWARD
	fwd.y = 0.0
	fwd = fwd.normalized()
	var ok: Array = []
	var far_pt: Vector3 = spawn_points[0]
	var far_d := -1.0
	for pt in spawn_points:
		var to: Vector3 = pt - (camera.global_position if camera else player.global_position)
		to.y = 0.0
		var d_player: float = (pt - player.global_position).length()
		if d_player > far_d:
			far_d = d_player
			far_pt = pt
		var out_of_view: bool = fwd.dot(to.normalized()) < 0.3 or to.length() > view_distance
		if out_of_view and d_player >= min_player_distance:
			ok.append(pt)
	if ok.is_empty():
		return far_pt
	# wave 1 shows the game within seconds: its enemies come from the nearest point out of view
	if wave == 1:
		ok.sort_custom(func(x, y): return x.distance_to(player.global_position) < y.distance_to(player.global_position))
		return ok[_rng.randi_range(0, min(1, ok.size() - 1))]
	return ok[_rng.randi_range(0, ok.size() - 1)]


func _spawn(p: Dictionary) -> void:
	var kind: int = _order[spawned] if spawned < _order.size() else 0
	var scene: PackedScene = bandit_scenes[min(kind, bandit_scenes.size() - 1)]
	var b: Node3D = scene.instantiate()
	b.name = ("Hazmat%d_%d" if kind == 1 else "Bandit%d_%d") % [wave, spawned + 1]
	b.setup(p, player)
	spawn_parent.add_child(b)
	b.global_position = pick_point()
	b.died.connect(_on_bandit_died)
	spawned += 1
	alive += 1
	bandit_spawned.emit(b)


func _on_bandit_died(b: Node) -> void:
	alive -= 1
	bandit_died.emit(b)
	if spawned >= wave_total() and alive <= 0:
		wave_cleared.emit(wave)
		if wave >= total_waves():
			running = false
			all_waves_cleared.emit()
		else:
			in_breather = true
			_breather_timer = Game.BREATHER
