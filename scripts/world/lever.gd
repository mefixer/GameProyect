extends Node3D
## Palanca de un solo uso: al activarla abre la puerta enlazada.
## Si el atajo ya estaba abierto (partida guardada), aparece ya usada.

@export var gate: NodePath

@onready var area: Area3D = $Area3D
@onready var prompt: Label3D = $Prompt
@onready var arm: Node3D = $ArmPivot

var _player_inside := false
var _used := false


func _ready() -> void:
	prompt.visible = false
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	var gate_node := get_node_or_null(gate)
	if gate_node and GameState.is_shortcut_open(gate_node.shortcut_id):
		_used = true
		arm.rotation_degrees.x = -60.0


func _physics_process(_delta: float) -> void:
	if _player_inside and not _used and Input.is_action_just_pressed("interact"):
		_activate()


func _activate() -> void:
	_used = true
	prompt.visible = false
	create_tween().tween_property(arm, "rotation_degrees:x", -60.0, 0.4) \
			.set_ease(Tween.EASE_OUT)
	var gate_node := get_node_or_null(gate)
	if gate_node:
		gate_node.open()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _used:
		_player_inside = true
		prompt.visible = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_inside = false
		prompt.visible = false
