extends Node
## Opciones persistentes del usuario (autoload "Settings"): volumen,
## sensibilidad y remapeo de teclado. Separado de GameState porque esto
## no es progreso de partida — sobrevive a "Nueva Partida".

const SETTINGS_PATH := "user://settings.cfg"

## Acciones remapeables desde el menú de opciones (solo teclado; el mando
## y los controles de ratón —ataque, bloqueo, lock-on— quedan fijos por ahora).
const REBINDABLE_ACTIONS: Array[String] = [
	"move_forward", "move_back", "move_left", "move_right",
	"sprint", "jump", "attack_heavy", "interact", "use_flask", "inventory",
]

var master_volume := 1.0  # lineal, 0–1
var mouse_sensitivity := 1.0  # multiplicador, 0.25–2.0
var key_binds := {}  # acción (String) → physical_keycode (int)


func _ready() -> void:
	load_settings()
	_apply_volume()
	for action in key_binds:
		if action in REBINDABLE_ACTIONS:
			_set_key_binding(action, key_binds[action])


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_volume()
	save_settings()


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.25, 2.0)
	save_settings()


## Cambia la tecla principal de una acción remapeable (no toca el mando).
func rebind_action(action: String, physical_keycode: int) -> void:
	if action not in REBINDABLE_ACTIONS:
		return
	_set_key_binding(action, physical_keycode)
	key_binds[action] = physical_keycode
	save_settings()


func get_key_for_action(action: String) -> int:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event.physical_keycode
	return KEY_NONE


func _set_key_binding(action: String, physical_keycode: int) -> void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var new_event := InputEventKey.new()
	new_event.physical_keycode = physical_keycode as Key
	InputMap.action_add_event(action, new_event)


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(
		bus, linear_to_db(master_volume) if master_volume > 0.0 else -80.0
	)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("controls", "key_binds", key_binds)
	cfg.save(SETTINGS_PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master_volume", 1.0)
	mouse_sensitivity = cfg.get_value("controls", "mouse_sensitivity", 1.0)
	var loaded_binds: Variant = cfg.get_value("controls", "key_binds", {})
	key_binds = loaded_binds if loaded_binds is Dictionary else {}
