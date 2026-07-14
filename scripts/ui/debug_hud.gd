extends CanvasLayer
## HUD provisional de vida y estamina (la UI definitiva llega en la Fase 7).

@onready var health_bar: ProgressBar = %HealthBar
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var newen_label: Label = %NewenLabel
@onready var flask_label: Label = %FlaskLabel


func _ready() -> void:
	GameState.newen_changed.connect(_on_newen_changed)
	GameState.flasks_changed.connect(_on_flasks_changed)
	_on_newen_changed(GameState.newen)
	_on_flasks_changed(GameState.flasks, GameState.max_flasks)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	player.health.health_changed.connect(_on_health_changed)
	player.stamina.stamina_changed.connect(_on_stamina_changed)
	_on_health_changed(player.health.health, player.health.max_health)
	_on_stamina_changed(player.stamina.stamina, player.stamina.max_stamina)


func _on_newen_changed(amount: int) -> void:
	newen_label.text = "Newen: %d" % amount


func _on_flasks_changed(current: int, max_value: int) -> void:
	flask_label.text = "Lawen: %d/%d" % [current, max_value]


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _on_stamina_changed(current: float, max_value: float) -> void:
	stamina_bar.max_value = max_value
	stamina_bar.value = current
