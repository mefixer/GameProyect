extends Node3D
## Rewe: el "checkpoint" del juego (la hoguera soulslike). Descansar cura,
## rellena los frascos de lawen, fija el punto de reaparición, guarda la
## partida, abre el menú de nivel y reinicia a los enemigos.

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Prompt
@onready var spawn_point: Marker3D = $SpawnPoint
@onready var menu: CanvasLayer = $ReweMenu

var _player_inside := false


func _ready() -> void:
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	menu.closed.connect(_on_menu_closed)


func _physics_process(_delta: float) -> void:
	if _player_inside and not menu.visible \
			and Input.is_action_just_pressed("interact"):
		_rest()


func _rest() -> void:
	GameState.rest_at_rewe(spawn_point.global_position)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.open()


func _on_menu_closed() -> void:
	# Levantarse del rewe: el mundo se reinicia (enemigos incluidos), como
	# en los souls. La recarga cura al jugador y lo coloca en el rewe.
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = true
		prompt.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		prompt.visible = false
