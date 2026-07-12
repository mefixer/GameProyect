extends Node3D
## Brazo giratorio de peligro: castiga quedarse quieto y sirve para probar
## el bloqueo, la esquiva con i-frames y la reacción de golpe del jugador.

@export var spin_speed := 2.0

@onready var hitbox: Hitbox = $Arm/Hitbox


func _ready() -> void:
	hitbox.source = get_parent()
	hitbox.activate()


func _physics_process(delta: float) -> void:
	# Si el maniquí padre está "muerto" (fuera del grupo), el brazo no daña
	if not get_parent().is_in_group("lock_target"):
		if hitbox.monitoring:
			hitbox.deactivate()
		return
	if not hitbox.monitoring:
		hitbox.activate()
	rotate_y(spin_speed * delta)
