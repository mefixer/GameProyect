extends Control
## Menú principal: nueva partida, continuar (si hay checkpoint guardado),
## opciones y salir.

const DEFAULT_LEVEL := "res://scenes/levels/bosque.tscn"
const OPTIONS_MENU := preload("res://scenes/ui/options_menu.tscn")

@onready var continue_button: Button = %ContinueButton
@onready var new_game_button: Button = %NewGameButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_container: Control = %OptionsContainer

var _options_instance: Control = null


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_button.disabled = not GameState.has_respawn
	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	options_button.pressed.connect(_on_options)
	quit_button.pressed.connect(func() -> void: get_tree().quit())


func _on_continue() -> void:
	var target := GameState.respawn_scene if GameState.respawn_scene != "" else DEFAULT_LEVEL
	get_tree().change_scene_to_file(target)


func _on_new_game() -> void:
	GameState.reset_new_game()
	get_tree().change_scene_to_file(DEFAULT_LEVEL)


func _on_options() -> void:
	if _options_instance:
		return
	_options_instance = OPTIONS_MENU.instantiate()
	options_container.add_child(_options_instance)
	_options_instance.closed.connect(func() -> void: _options_instance = null)
