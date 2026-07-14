extends Node3D
## Brazo giratorio de peligro: castiga quedarse quieto y sirve para probar
## el bloqueo, la esquiva con i-frames y la reacción de golpe del jugador.

@export var spin_speed := 2.0
@export var parry_stun := 2.0

var _stun_time := 0.0

@onready var hitbox: Hitbox = $Arm/Hitbox


func _ready() -> void:
	hitbox.source = get_parent()
	hitbox.activate()
	if get_parent().has_signal("parried"):
		get_parent().parried.connect(func() -> void: _stun_time = parry_stun)


func _physics_process(delta: float) -> void:
	# Parry recibido o maniquí "muerto" (fuera del grupo): el brazo se detiene
	_stun_time = maxf(_stun_time - delta, 0.0)
	if _stun_time > 0.0 or not get_parent().is_in_group("lock_target"):
		if hitbox.monitoring:
			hitbox.deactivate()
		return
	if not hitbox.monitoring:
		hitbox.activate()
	rotate_y(spin_speed * delta)
