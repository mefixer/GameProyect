extends Area3D
## Niebla de entrada a la arena del jefe: al cruzarla, despierta al jefe
## y muestra su barra de vida. Si el jefe ya fue vencido en esta partida,
## la niebla se desvanece sola y no vuelve a activarse.

@export var boss_path: NodePath
@export var boss_id := "cherufe"
@export var boss_display_name := "Cherufe"
@export var health_bar_path: NodePath

@onready var visual: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if GameState.is_boss_defeated(boss_id):
		visual.visible = false
		label.visible = false
		_triggered = true


func _on_body_entered(body: Node3D) -> void:
	if _triggered or not body.is_in_group("player"):
		return
	_triggered = true
	var boss := get_node_or_null(boss_path)
	if boss == null:
		return
	boss.awaken(body)
	var hud := get_node_or_null(health_bar_path)
	if hud:
		hud.track(boss, boss_display_name)
	create_tween().tween_property(visual, "modulate:a", 0.0, 1.5) \
			.finished.connect(func() -> void: visual.visible = false)
	label.visible = false
