extends CanvasLayer
## Menú de pausa: reanudar, opciones, guardar y volver al menú, salir.
## Autoload persistente — escucha la acción "pause" incluso sin partida
## activa, pero solo actúa dentro de una escena de nivel (grupo "level").

const OPTIONS_MENU := preload("res://scenes/ui/options_menu.tscn")
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var panel: Control = %Panel
@onready var resume_button: Button = %ResumeButton
@onready var options_button: Button = %OptionsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var quit_button: Button = %QuitButton
@onready var options_container: Control = %OptionsContainer

var _options_instance: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	resume_button.pressed.connect(_close)
	options_button.pressed.connect(_on_options)
	main_menu_button.pressed.connect(_on_main_menu)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if panel.visible:
		_close()
		get_viewport().set_input_as_handled()
	elif _in_level() and UiState.try_open():
		panel.visible = true
		get_viewport().set_input_as_handled()


func _in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("level")


func _close() -> void:
	if _options_instance:
		_options_instance.queue_free()
		_options_instance = null
	panel.visible = false
	UiState.close()


func _on_options() -> void:
	if _options_instance:
		return
	_options_instance = OPTIONS_MENU.instantiate()
	options_container.add_child(_options_instance)
	_options_instance.closed.connect(func() -> void: _options_instance = null)


func _on_main_menu() -> void:
	GameState.save_game()
	_close()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
