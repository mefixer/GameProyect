extends CanvasLayer
## Pantalla de estado del personaje: nivel, newen, estadísticas y
## equipamiento actual. Solo hay un arma y un escudo en esta demo —
## el marco queda listo para cuando existan varias piezas para elegir.

@onready var panel: Control = %Panel
@onready var close_button: Button = %CloseButton
@onready var level_label: Label = %LevelLabel
@onready var newen_label: Label = %NewenLabel
@onready var stats_label: Label = %StatsLabel
@onready var weapon_label: Label = %WeaponLabel
@onready var shield_label: Label = %ShieldLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	close_button.pressed.connect(_close)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		if panel.visible:
			_close()
			get_viewport().set_input_as_handled()
		elif _in_level() and UiState.try_open():
			_open()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause") and panel.visible:
		_close()
		get_viewport().set_input_as_handled()


func _in_level() -> bool:
	var scene := get_tree().current_scene
	return scene != null and scene.is_in_group("level")


func _open() -> void:
	panel.visible = true
	level_label.text = "Nivel %d" % GameState.level
	newen_label.text = "Newen: %d" % GameState.newen
	var s := GameState.stats
	stats_label.text = (
		"Vigor %d   Resistencia %d   Fuerza %d   Destreza %d   Espiritualidad %d"
		% [s.vigor, s.resistencia, s.fuerza, s.destreza, s.espiritualidad]
	)
	weapon_label.text = "Arma: Toki (hacha ceremonial)"
	shield_label.text = "Escudo: cuero curtido"


func _close() -> void:
	panel.visible = false
	UiState.close()
