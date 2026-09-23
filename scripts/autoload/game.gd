extends Node
## Save data, scene switching, run results hand off, the wave table and the weapon table.

const ARENA_SCENE := "res://scenes/arena.tscn"
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const RESULTS_SCENE := "res://scenes/ui/results.tscn"
const SAVE_PATH := "user://save.json"

## GDD section 12. `prefab` indexes WaveSpawner.bandit_scenes (0 everywhere in 1.x, section 13.1).
const WAVES := [
	{"count": 4, "max_alive": 2, "gap": 2.5, "speed": 4.0, "range": 9.0, "burst_pause": 2.0, "prefab": 0},
	{"count": 6, "max_alive": 3, "gap": 2.0, "speed": 4.0, "range": 9.0, "burst_pause": 2.0, "prefab": 0},
	{"count": 8, "max_alive": 4, "gap": 1.8, "speed": 4.2, "range": 8.0, "burst_pause": 1.8, "prefab": 0},
	{"count": 10, "max_alive": 4, "gap": 1.5, "speed": 4.4, "range": 8.0, "burst_pause": 1.6, "prefab": 0},
	{"count": 12, "max_alive": 5, "gap": 1.2, "speed": 4.6, "range": 7.0, "burst_pause": 1.4, "prefab": 0},
]
const BREATHER := 5.0

## GDD 16.2 table order; also the weapon wheel's clockwise order (17.2).
const WEAPON_IDS := ["blaster", "pistol", "revolver", "revolver_small", "smg", "shotgun", "short_cannon",
	"sniper", "sniper_2", "grenade_launcher", "rocket_launcher", "knife_1", "knife_2", "shovel"]
const WEAPON_NAMES := {
	"blaster": "Blaster", "pistol": "Pistol", "revolver": "Revolver", "revolver_small": "Small revolver",
	"smg": "SMG", "shotgun": "Shotgun", "short_cannon": "Sawn off", "sniper": "Sniper", "sniper_2": "Light sniper",
	"grenade_launcher": "Grenade launcher", "rocket_launcher": "Rocket launcher", "knife_1": "Knife",
	"knife_2": "Combat knife", "shovel": "Shovel",
}
## The mesh of the same weapon inside the character files and the loose model's file name in Guns/glTF.
const WEAPON_MESHES := {
	"blaster": "AK", "pistol": "Pistol", "revolver": "Revolver", "revolver_small": "Revolver_Small", "smg": "SMG",
	"shotgun": "Shotgun", "short_cannon": "ShortCannon", "sniper": "Sniper", "sniper_2": "Sniper_2",
	"grenade_launcher": "GrenadeLauncher", "rocket_launcher": "RocketLauncher", "knife_1": "Knife_1",
	"knife_2": "Knife_2", "shovel": "Shovel",
}
const START_WEAPONS := ["blaster", "pistol", "knife_1"]
const GUNS_DIR := "res://assets/Toon Shooter Game Kit - Dec 2022/Guns/glTF/"

var best_score := 0
var best_wave := 0
var runs := 0
var music_on := true
var sfx_on := true
var last_result := {}
var last_frame: Texture2D
var main: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_save()
	apply_audio_settings()


func weapon_name(id: String) -> String:
	return WEAPON_NAMES.get(id, id)


func switch_to(path: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	if main and main.has_method("switch_to"):
		main.switch_to(path)
	else:
		get_tree().change_scene_to_file(path)


func start_run() -> void:
	switch_to(ARENA_SCENE)


func to_menu() -> void:
	switch_to(MENU_SCENE)


## Called by Arena.run_finished. Keeps the bests, saves and shows the results screen.
func run_complete(result: Dictionary) -> void:
	result["new_best"] = int(result.get("score", 0)) > best_score
	result["previous_best"] = best_score
	best_score = max(best_score, int(result.get("score", 0)))
	best_wave = max(best_wave, int(result.get("wave_reached", 0)))
	runs += 1
	last_result = result
	save()
	switch_to(RESULTS_SCENE)


func set_music(on: bool) -> void:
	music_on = on
	apply_audio_settings()
	save()


func set_sfx(on: bool) -> void:
	sfx_on = on
	apply_audio_settings()
	save()


func apply_audio_settings() -> void:
	var m := AudioServer.get_bus_index("Music")
	var s := AudioServer.get_bus_index("SFX")
	if m >= 0:
		AudioServer.set_bus_mute(m, not music_on)
	if s >= 0:
		AudioServer.set_bus_mute(s, not sfx_on)


func load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	best_score = int(data.get("best_score", 0))
	best_wave = int(data.get("best_wave", 0))
	runs = int(data.get("runs", 0))
	music_on = bool(data.get("music", true))
	sfx_on = bool(data.get("sfx", true))


func save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"best_score": best_score, "best_wave": best_wave, "runs": runs,
		"music": music_on, "sfx": sfx_on}))
