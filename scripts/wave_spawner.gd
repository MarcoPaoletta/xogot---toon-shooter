extends Node
## Five waves from Game.WAVES (GDD 12): spawn gap, max alive, seeded spawn point choice outside the camera's
## view cone (GDD 7.4), 5 s breathers. `bandit_scenes` has one entry in 1.x; the second enemy behaviour of
## the on camera iteration is a second entry and a `prefab` index in the wave table.

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


func remaining() -> int:
	if wave == 0:
		return 0
	return int(params()["count"]) - spawned + alive


func _begin_wave(n: int) -> void:
	wave = n
	spawned = 0
	alive = 0
	in_breather = false
	_rng.seed = 4000 + n
	_gap_timer = 0.5
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
	if spawned < int(p["count"]) and alive < int(p["max_alive"]) and _gap_timer <= 0.0:
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
		var out_of_view: bool = fwd.dot(to.normalized()) < 0.3 or to.length() > 26.0
		if out_of_view and d_player >= 12.0:
			ok.append(pt)
	if ok.is_empty():
		return far_pt
	return ok[_rng.randi_range(0, ok.size() - 1)]


func _spawn(p: Dictionary) -> void:
	var scene: PackedScene = bandit_scenes[int(p.get("prefab", 0))]
	var b: Node3D = scene.instantiate()
	b.name = "Bandit%d_%d" % [wave, spawned + 1]
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
	if spawned >= int(params()["count"]) and alive <= 0:
		wave_cleared.emit(wave)
		if wave >= total_waves():
			running = false
			all_waves_cleared.emit()
		else:
			in_breather = true
			_breather_timer = Game.BREATHER
