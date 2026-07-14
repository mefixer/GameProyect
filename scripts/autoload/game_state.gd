extends Node
## Estado persistente de la partida (autoload "GameState").
## Sobrevive a las recargas de escena (muerte, descanso) y se guarda en disco.
##
## Vocabulario del GDD: newen = "almas" (moneda de experiencia),
## rewe = "hoguera" (checkpoint), lawen = frasco de curación.

signal newen_changed(amount: int)
signal flasks_changed(current: int, max_value: int)

const SAVE_PATH := "user://savegame.json"
const BASE_STATS := {
	"vigor": 10,
	"resistencia": 10,
	"fuerza": 10,
	"destreza": 10,
	"espiritualidad": 10,
}

var newen := 0
var level := 1
var stats := BASE_STATS.duplicate()
var flasks := 3
var max_flasks := 3

var has_respawn := false
var respawn_position := Vector3.ZERO
var has_drop := false
var dropped_newen := 0
var dropped_position := Vector3.ZERO


func _ready() -> void:
	load_game()


# ── Estadísticas derivadas ───────────────────────────────────


func max_health() -> float:
	return 20.0 + 8.0 * stats.vigor


func max_stamina() -> float:
	return 50.0 + 5.0 * stats.resistencia


func light_damage_multiplier() -> float:
	return 1.0 + 0.04 * (stats.destreza - 10)


func heavy_damage_multiplier() -> float:
	return 1.0 + 0.04 * (stats.fuerza - 10)


func level_cost() -> int:
	return 80 + 20 * level


func try_level_up(stat: String) -> bool:
	if not stats.has(stat) or newen < level_cost():
		return false
	newen -= level_cost()
	stats[stat] += 1
	level += 1
	newen_changed.emit(newen)
	return true


# ── Newen (bucle de muerte estilo souls) ─────────────────────


func add_newen(amount: int) -> void:
	newen += amount
	newen_changed.emit(newen)


## Al morir: el newen queda en el suelo donde caíste. Si ya había un
## montón anterior sin recuperar, se pierde para siempre.
func on_player_died(position: Vector3) -> void:
	dropped_newen = newen
	dropped_position = position
	has_drop = newen > 0
	newen = 0
	newen_changed.emit(newen)
	save_game()


func recover_drop() -> void:
	add_newen(dropped_newen)
	has_drop = false
	dropped_newen = 0
	save_game()


# ── Frascos de lawen ─────────────────────────────────────────


func use_flask() -> bool:
	if flasks <= 0:
		return false
	flasks -= 1
	flasks_changed.emit(flasks, max_flasks)
	return true


# ── Rewe (descanso/checkpoint) ───────────────────────────────


func rest_at_rewe(spawn_position: Vector3) -> void:
	has_respawn = true
	respawn_position = spawn_position
	flasks = max_flasks
	flasks_changed.emit(flasks, max_flasks)
	save_game()


# ── Guardado ─────────────────────────────────────────────────


func save_game() -> void:
	var data := {
		"level": level,
		"newen": newen,
		"stats": stats,
		"max_flasks": max_flasks,
		"has_respawn": has_respawn,
		"respawn_position": [respawn_position.x, respawn_position.y, respawn_position.z],
		"has_drop": has_drop,
		"dropped_newen": dropped_newen,
		"dropped_position": [dropped_position.x, dropped_position.y, dropped_position.z],
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var data: Variant = JSON.parse_string(file.get_as_text())
	if data == null or not data is Dictionary:
		return
	level = int(data.get("level", 1))
	newen = int(data.get("newen", 0))
	var saved_stats: Dictionary = data.get("stats", {})
	for stat_name in BASE_STATS:
		stats[stat_name] = int(saved_stats.get(stat_name, BASE_STATS[stat_name]))
	max_flasks = int(data.get("max_flasks", 3))
	flasks = max_flasks
	has_respawn = bool(data.get("has_respawn", false))
	respawn_position = _to_vector3(data.get("respawn_position", []))
	has_drop = bool(data.get("has_drop", false))
	dropped_newen = int(data.get("dropped_newen", 0))
	dropped_position = _to_vector3(data.get("dropped_position", []))


func _to_vector3(values: Variant) -> Vector3:
	if values is Array and values.size() == 3:
		return Vector3(values[0], values[1], values[2])
	return Vector3.ZERO
