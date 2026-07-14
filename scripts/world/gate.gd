extends StaticBody3D
## Puerta de atajo: bloquea el paso hasta que una palanca la abre.
## El estado se persiste en GameState.shortcuts, así queda abierta
## para siempre aunque mueras o reinicies (regla souls de los atajos).

@export var shortcut_id := "atajo_1"

@onready var visual: MeshInstance3D = $MeshInstance3D
@onready var collision: CollisionShape3D = $CollisionShape3D


func _ready() -> void:
	if GameState.is_shortcut_open(shortcut_id):
		_apply_open(true)


func open() -> void:
	GameState.open_shortcut(shortcut_id)
	_apply_open(false)


func _apply_open(instant: bool) -> void:
	collision.set_deferred("disabled", true)
	if instant:
		visual.position.y -= 3.2
		return
	create_tween().tween_property(visual, "position:y", visual.position.y - 3.2, 1.4) \
			.set_ease(Tween.EASE_IN_OUT)
