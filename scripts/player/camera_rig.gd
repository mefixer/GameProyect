class_name CameraRig
extends Node3D
## Cámara orbital con colisión (SpringArm3D) y sistema de lock-on.
## El rig es top_level: sigue la posición del jugador con suavizado,
## pero no hereda su rotación.

@export var mouse_sensitivity := 0.003
@export var stick_speed := 2.8
@export var min_pitch := -1.1
@export var max_pitch := 0.5
@export var pivot_height := 1.4
@export var follow_speed := 25.0
@export var lock_break_distance := 14.0
@export var shake_magnitude := 0.25

var lock_target: Node3D = null

var _yaw := 0.0
var _pitch := -0.35
var _trauma := 0.0

@onready var _player: CharacterBody3D = get_parent()
@onready var _pitch_node: Node3D = $Pitch
@onready var _camera: Camera3D = $Pitch/SpringArm3D/Camera3D
@onready var _lock_area: Area3D = $LockOnArea
@onready var _marker: MeshInstance3D = $LockMarker


func _ready() -> void:
	top_level = true
	global_position = _player.global_position + Vector3(0.0, pivot_height, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if lock_target == null:
			var sensitivity := mouse_sensitivity * Settings.mouse_sensitivity
			_yaw -= event.relative.x * sensitivity
			_pitch = clampf(_pitch - event.relative.y * sensitivity, min_pitch, max_pitch)
	elif event.is_action_pressed("lock_on"):
		_toggle_lock_on()
	elif event.is_action_pressed("switch_target_right"):
		_switch_target(1)
	elif event.is_action_pressed("switch_target_left"):
		_switch_target(-1)
	elif event is InputEventMouseButton and event.pressed \
			and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not UiState.menu_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(delta: float) -> void:
	_validate_lock_target()

	var stick := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if lock_target == null and not stick.is_zero_approx():
		var speed := stick_speed * Settings.mouse_sensitivity
		_yaw -= stick.x * speed * delta
		_pitch = clampf(_pitch - stick.y * speed * delta, min_pitch, max_pitch)

	if lock_target:
		var to_target := lock_target.global_position - _player.global_position
		var flat_distance := Vector2(to_target.x, to_target.z).length()
		var desired_yaw := atan2(-to_target.x, -to_target.z)
		var desired_pitch := clampf(atan2(to_target.y, flat_distance) * 0.5 - 0.25, min_pitch, max_pitch)
		_yaw = lerp_angle(_yaw, desired_yaw, 1.0 - exp(-8.0 * delta))
		_pitch = lerpf(_pitch, desired_pitch, 1.0 - exp(-8.0 * delta))

	rotation.y = _yaw
	_pitch_node.rotation.x = _pitch

	var pivot := _player.global_position + Vector3(0.0, pivot_height, 0.0)
	global_position = global_position.lerp(pivot, 1.0 - exp(-follow_speed * delta))

	_marker.visible = lock_target != null
	if lock_target:
		_marker.global_position = lock_target.global_position + Vector3(0.0, 2.0, 0.0)

	# Sacudida por trauma: decae sola y usa los offsets de la cámara
	if _trauma > 0.0:
		_trauma = maxf(_trauma - 2.5 * delta, 0.0)
		var shake := _trauma * _trauma * shake_magnitude
		_camera.h_offset = randf_range(-shake, shake)
		_camera.v_offset = randf_range(-shake, shake)
	else:
		_camera.h_offset = 0.0
		_camera.v_offset = 0.0


## Acumula sacudida de cámara (golpes, bloqueos, impactos).
func add_trauma(amount: float) -> void:
	_trauma = minf(_trauma + amount, 1.0)


## Convierte el input 2D (get_vector) a una dirección en el mundo
## relativa a la orientación horizontal de la cámara.
func to_world_direction(input: Vector2) -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	return (right * input.x - forward * input.y).limit_length(1.0)


func _toggle_lock_on() -> void:
	if lock_target:
		lock_target = null
		return
	lock_target = _best_target()


func _validate_lock_target() -> void:
	if lock_target == null:
		return
	if not is_instance_valid(lock_target) \
			or not lock_target.is_in_group("lock_target") \
			or _player.global_position.distance_to(lock_target.global_position) > lock_break_distance:
		lock_target = null


func _candidates() -> Array[Node3D]:
	var result: Array[Node3D] = []
	for body in _lock_area.get_overlapping_bodies():
		if body.is_in_group("lock_target"):
			result.append(body)
	return result


func _best_target() -> Node3D:
	var best: Node3D = null
	var best_angle := INF
	for candidate in _candidates():
		var angle := absf(_horizontal_angle_to(candidate))
		if angle < best_angle:
			best_angle = angle
			best = candidate
	return best


func _switch_target(direction: int) -> void:
	if lock_target == null:
		return
	var current := _horizontal_angle_to(lock_target)
	var best: Node3D = null
	var best_delta := INF
	for candidate in _candidates():
		if candidate == lock_target:
			continue
		var delta_angle := wrapf(_horizontal_angle_to(candidate) - current, -PI, PI)
		if signf(delta_angle) == float(direction) and absf(delta_angle) < best_delta:
			best_delta = absf(delta_angle)
			best = candidate
	if best:
		lock_target = best


## Ángulo horizontal del nodo respecto al centro de la cámara
## (negativo = izquierda, positivo = derecha).
func _horizontal_angle_to(node: Node3D) -> float:
	var local := _camera.global_transform.affine_inverse() * node.global_position
	return atan2(local.x, -local.z)
