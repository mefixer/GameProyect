extends CanvasLayer
## Menú del rewe: muestra el newen y permite subir de nivel repartiendo
## puntos entre las 5 estadísticas. Se abre pausado; cerrarlo reinicia el mundo.

signal closed

## Nombre visible y efecto de cada estadística (el orden importa).
const STAT_INFO := {
	"vigor": "+8 de vida máxima",
	"resistencia": "+5 de estamina máxima",
	"fuerza": "+4% de daño con ataque fuerte",
	"destreza": "+4% de daño con ataque ligero",
	"espiritualidad": "(reservado: trance del kultrún)",
}

@onready var newen_label: Label = %NewenLabel
@onready var level_label: Label = %LevelLabel
@onready var grid: GridContainer = %StatsGrid
@onready var close_button: Button = %CloseButton

var _plus_buttons := {}
var _value_labels := {}


func _ready() -> void:
	visible = false
	close_button.pressed.connect(_close)
	_build_rows()


func open() -> void:
	visible = true
	_refresh()


func _close() -> void:
	visible = false
	closed.emit()


func _build_rows() -> void:
	for stat_name: String in STAT_INFO:
		var name_label := Label.new()
		name_label.text = stat_name.capitalize()
		grid.add_child(name_label)

		var value_label := Label.new()
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(value_label)
		_value_labels[stat_name] = value_label

		var plus := Button.new()
		plus.text = "+"
		plus.pressed.connect(_on_plus_pressed.bind(stat_name))
		grid.add_child(plus)
		_plus_buttons[stat_name] = plus

		var effect_label := Label.new()
		effect_label.text = STAT_INFO[stat_name]
		effect_label.modulate = Color(1, 1, 1, 0.6)
		grid.add_child(effect_label)


func _on_plus_pressed(stat_name: String) -> void:
	if GameState.try_level_up(stat_name):
		_refresh()


func _refresh() -> void:
	newen_label.text = "Newen: %d" % GameState.newen
	level_label.text = "Nivel %d — subir cuesta %d newen" % [GameState.level, GameState.level_cost()]
	var can_afford := GameState.newen >= GameState.level_cost()
	for stat_name: String in STAT_INFO:
		_value_labels[stat_name].text = str(GameState.stats[stat_name])
		_plus_buttons[stat_name].disabled = not can_afford
