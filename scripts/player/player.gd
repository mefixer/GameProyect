class_name Player
extends CharacterBody3D
## Controlador del weichafe en tercera persona.
## Movimiento relativo a la cámara; con lock-on activo camina en strafe
## mirando al objetivo (el sprint rompe el strafe, como en los soulslike).

@export_group("Movimiento")
@export var run_speed := 5.5
@export var sprint_speed := 8.5
@export var acceleration := 30.0
@export var rotation_speed := 10.0
@export var jump_velocity := 4.2

@onready var camera_rig: CameraRig = $CameraRig
@onready var visual: Node3D = $Visual

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_rig.to_world_direction(input_dir)
	var sprinting := Input.is_action_pressed("sprint") and not direction.is_zero_approx()
	var speed := sprint_speed if sprinting else run_speed

	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(direction * speed, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	_update_facing(direction, sprinting, delta)
	move_and_slide()


func _update_facing(move_direction: Vector3, sprinting: bool, delta: float) -> void:
	var face_direction := move_direction
	if camera_rig.lock_target and not sprinting:
		face_direction = camera_rig.lock_target.global_position - global_position
		face_direction.y = 0.0
	if face_direction.length_squared() < 0.001:
		return
	var target_rotation := Basis.looking_at(face_direction.normalized()).get_rotation_quaternion()
	# 1 - exp(-k*delta) hace el suavizado independiente del framerate
	visual.quaternion = visual.quaternion.slerp(target_rotation, 1.0 - exp(-rotation_speed * delta))
