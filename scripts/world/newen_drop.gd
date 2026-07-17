extends Area3D
## Newen soltado al morir: orbe que espera en el lugar de la muerte.
## Tocarlo lo recupera; morir de nuevo sin recogerlo lo pierde para siempre.

@onready var visual: MeshInstance3D = $MeshInstance3D

var _time := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	visual.position.y = 0.6 + sin(_time * 2.5) * 0.15
	visual.rotate_y(delta * 1.5)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		GameState.recover_drop()
		Fx.burst("muerte", global_position + Vector3.UP * 0.6)
		queue_free()
