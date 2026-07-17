extends Control
## Panel de opciones compartido por el menú principal y el de pausa:
## volumen, sensibilidad y remapeo de teclado. Se cierra con queue_free().

signal closed

const ACTION_LABELS := {
	"move_forward": "Avanzar",
	"move_back": "Retroceder",
	"move_left": "Izquierda",
	"move_right": "Derecha",
	"sprint": "Correr / esquivar (toque)",
	"jump": "Saltar",
	"attack_heavy": "Ataque fuerte",
	"interact": "Interactuar",
	"use_flask": "Frasco de lawen",
	"inventory": "Inventario",
}

@onready var volume_slider: HSlider = %VolumeSlider
@onready var sfx_volume_slider: HSlider = %SfxVolumeSlider
@onready var music_volume_slider: HSlider = %MusicVolumeSlider
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var binds_container: VBoxContainer = %BindsContainer
@onready var back_button: Button = %BackButton

var _rebind_buttons := {}
var _listening_action := ""


func _ready() -> void:
	volume_slider.value = Settings.master_volume * 100.0
	volume_slider.value_changed.connect(func(v: float) -> void: Settings.set_master_volume(v / 100.0))
	sfx_volume_slider.value = Settings.sfx_volume * 100.0
	sfx_volume_slider.value_changed.connect(func(v: float) -> void: Settings.set_sfx_volume(v / 100.0))
	music_volume_slider.value = Settings.music_volume * 100.0
	music_volume_slider.value_changed.connect(func(v: float) -> void: Settings.set_music_volume(v / 100.0))
	sensitivity_slider.value = Settings.mouse_sensitivity
	sensitivity_slider.value_changed.connect(Settings.set_mouse_sensitivity)
	back_button.pressed.connect(AudioManager.play_ui.bind("click"))
	back_button.pressed.connect(_on_back)
	_build_binds()


func _build_binds() -> void:
	for action in Settings.REBINDABLE_ACTIONS:
		var row := HBoxContainer.new()
		var label := Label.new()
		label.text = ACTION_LABELS.get(action, action)
		label.custom_minimum_size.x = 220
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size.x = 150
		button.text = OS.get_keycode_string(Settings.get_key_for_action(action))
		button.pressed.connect(_on_rebind_pressed.bind(action, button))
		row.add_child(button)
		binds_container.add_child(row)
		_rebind_buttons[action] = button


func _on_rebind_pressed(action: String, button: Button) -> void:
	_listening_action = action
	button.text = "Pulsa una tecla…"


func _unhandled_key_input(event: InputEvent) -> void:
	if _listening_action == "" or not event is InputEventKey or not event.pressed:
		return
	var action := _listening_action
	_listening_action = ""
	if event.physical_keycode != KEY_ESCAPE:
		Settings.rebind_action(action, event.physical_keycode)
	_rebind_buttons[action].text = OS.get_keycode_string(Settings.get_key_for_action(action))
	get_viewport().set_input_as_handled()


func _on_back() -> void:
	closed.emit()
	queue_free()
