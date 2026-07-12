class_name Hurtbox
extends Area3D
## Área que recibe golpes. No aplica daño por sí misma: emite la señal
## y el dueño decide (el jugador puede estar bloqueando, por ejemplo).

signal hit_received(hitbox: Hitbox)

## i-frames: mientras sea true los golpes se ignoran por completo.
var invulnerable := false
var root_node: Node3D


func _ready() -> void:
	root_node = owner if owner is Node3D else get_parent()
	monitoring = false


## Devuelve true si el golpe fue aceptado (para hitstop/shake del atacante).
func receive_hit(hitbox: Hitbox) -> bool:
	if invulnerable or not monitorable:
		return false
	hit_received.emit(hitbox)
	return true
