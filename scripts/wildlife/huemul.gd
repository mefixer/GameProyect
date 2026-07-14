extends CharacterBody3D
## Huemul: fauna ambiental no interactiva. Pasta tranquilo y, si el
## jugador se acerca demasiado, huye trotando unos metros antes de
## volver a calmarse. Decorativo — no tiene vida ni combate.

@export var flee_distance := 6.0
@export var calm_distance := 11.0
@export var flee_speed := 4.0
@export var acceleration := 8.0
@export var rotation_speed := 6.0

var _fleeing := false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var visual: Node3D = $Visual


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		var distance := global_position.distance_to(player.global_position)
		if distance < flee_distance:
			_fleeing = true
		elif distance > calm_distance:
			_fleeing = false

		if _fleeing:
			var away := global_position - player.global_position
			away.y = 0.0
			if not away.is_zero_approx():
				away = away.normalized()
				_accelerate_towards(away * flee_speed, delta)
				_face_towards(away, delta)
				move_and_slide()
				return

	_accelerate_towards(Vector3.ZERO, delta)
	move_and_slide()


func _accelerate_towards(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_rotation := Basis.looking_at(direction.normalized()).get_rotation_quaternion()
	visual.quaternion = visual.quaternion.slerp(target_rotation, 1.0 - exp(-rotation_speed * delta))
