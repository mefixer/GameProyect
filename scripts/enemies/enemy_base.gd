class_name EnemyBase
extends CharacterBody3D
## Enemigo con FSM: vigila su puesto, persigue al jugador, telegrafía sus
## ataques y vuelve a casa si lo pierde (curándose, estilo souls).
## Las variantes (pesado, rápido, a distancia) se configuran por exports.

enum State { IDLE, CHASE, ATTACK, HIT, RETURN, DEAD }

const WEAPON_IDLE := Vector3(-20.0, 0.0, 0.0)

@export_group("Identidad")
@export var body_color := Color(0.7, 0.25, 0.2)
@export var max_health := 90.0
@export var newen_reward := 25

@export_group("Movimiento")
@export var chase_speed := 4.0
@export var return_speed := 3.0
@export var acceleration := 20.0
@export var rotation_speed := 8.0

@export_group("Percepción")
@export var detection_range := 9.0
@export var deaggro_range := 16.0

@export_group("Ataque")
@export var attack_damage := 14.0
@export var attack_knockback := 5.0
@export var attack_range := 1.9
## Variantes a distancia: si el jugador se acerca más que esto, retroceden.
@export var min_range := 0.0
@export var attack_windup := 0.5
@export var attack_active := 0.25
@export var attack_recovery := 0.6
@export var attack_cooldown := 1.4
@export var hit_stagger := 0.35
@export var parry_stagger := 2.0

var state := State.IDLE
var target: Node3D = null

var _state_time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _home: Vector3
var _cooldown := 0.0
var _attack_phase := 0
var _knockback := Vector3.ZERO
var _stagger := 0.35
var _material: StandardMaterial3D
var _attack_tween: Tween

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var visual: Node3D = $Visual
@onready var mesh: MeshInstance3D = $Visual/Body
@onready var weapon_pivot: Node3D = get_node_or_null("Visual/WeaponPivot")
@onready var hitbox: Hitbox = get_node_or_null("Visual/WeaponPivot/Weapon/Hitbox")
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	_home = global_position
	_material = mesh.get_active_material(0).duplicate()
	_material.albedo_color = body_color
	mesh.set_surface_override_material(0, _material)
	health.max_health = max_health
	health.reset()
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	if weapon_pivot:
		weapon_pivot.rotation_degrees = WEAPON_IDLE
	if hitbox:
		hitbox.source = self
		hitbox.damage = attack_damage
		hitbox.knockback = attack_knockback
		hitbox.ignore_group = "enemies"


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= _gravity * delta

	match state:
		State.IDLE:
			_state_idle(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HIT:
			_state_hit(delta)
		State.RETURN:
			_state_return(delta)
		State.DEAD:
			_accelerate_towards(Vector3.ZERO, delta)

	move_and_slide()


# ── Estados ──────────────────────────────────────────────────


func _state_idle(delta: float) -> void:
	_accelerate_towards(Vector3.ZERO, delta)
	var player := _find_player()
	if player and global_position.distance_to(player.global_position) <= detection_range:
		_aggro(player)


func _state_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target) or _target_dead():
		target = null
		_change_state(State.RETURN)
		return
	var distance := global_position.distance_to(target.global_position)
	if distance > deaggro_range:
		target = null
		_change_state(State.RETURN)
		return

	if min_range > 0.0 and distance < min_range:
		# Demasiado cerca (variante a distancia): retrocede de cara al jugador
		var away := global_position - target.global_position
		away.y = 0.0
		away = away.normalized()
		_accelerate_towards(away * return_speed, delta)
		_face_towards(-away, delta)
	elif distance <= attack_range:
		_accelerate_towards(Vector3.ZERO, delta)
		_face_point(target.global_position, delta)
		if _cooldown <= 0.0:
			_start_attack()
	else:
		nav.target_position = target.global_position
		_follow_path(chase_speed, delta)


func _state_attack(delta: float) -> void:
	_accelerate_towards(Vector3.ZERO, delta)
	if _attack_phase == 0:
		# El windup sigue apuntando al jugador; la dirección queda fijada al golpear
		if target and is_instance_valid(target):
			_face_point(target.global_position, delta)
		if _state_time >= attack_windup:
			_attack_phase = 1
			_attack_became_active()
	elif _attack_phase == 1 and _state_time >= attack_windup + attack_active:
		_attack_phase = 2
		_attack_active_ended()
	elif _attack_phase == 2 \
			and _state_time >= attack_windup + attack_active + attack_recovery:
		_cooldown = attack_cooldown
		_change_state(State.CHASE)


func _state_hit(delta: float) -> void:
	velocity.x = _knockback.x
	velocity.z = _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, 15.0 * delta)
	if _state_time >= _stagger:
		_change_state(State.CHASE if target else State.RETURN)


func _state_return(delta: float) -> void:
	var player := _find_player()
	if player and global_position.distance_to(player.global_position) <= detection_range:
		_aggro(player)
		return
	if global_position.distance_to(_home) <= 1.0:
		health.reset()  # volver a su puesto lo cura (estilo souls)
		_change_state(State.IDLE)
		return
	nav.target_position = _home
	_follow_path(return_speed, delta)


# ── Ataque (las variantes a distancia sobreescriben estos dos) ──


func _attack_became_active() -> void:
	if hitbox:
		hitbox.activate()
	# Embiste un paso al soltar el golpe
	var forward := -visual.global_transform.basis.z
	velocity.x = forward.x * 3.0
	velocity.z = forward.z * 3.0
	if weapon_pivot:
		_tween_weapon(Vector3(40, 0, 0), attack_active)


func _attack_active_ended() -> void:
	if hitbox:
		hitbox.deactivate()
	if weapon_pivot:
		_tween_weapon(WEAPON_IDLE, attack_recovery)


func _start_attack() -> void:
	_change_state(State.ATTACK)
	_attack_phase = 0
	_flash(Color(1.0, 0.85, 0.25))  # telegrafiado: destello amarillo
	if weapon_pivot:
		_tween_weapon(Vector3(-110, 0, 0), attack_windup)


# ── Reacciones ───────────────────────────────────────────────


func _on_hit_received(from_hitbox: Hitbox) -> void:
	if state == State.DEAD:
		return
	health.apply_damage(from_hitbox.damage)
	if not health.is_alive():
		return
	_flash(Color.WHITE)
	# Recibir daño siempre agrede, aunque el jugador esté fuera del rango de visión
	if from_hitbox.source and from_hitbox.source.is_in_group("player"):
		target = from_hitbox.source
	var away := global_position - from_hitbox.global_position
	away.y = 0.0
	away = away.normalized() if not away.is_zero_approx() else Vector3.BACK
	_knockback = away * from_hitbox.knockback * 0.6
	_enter_stagger(hit_stagger)


## Llamado por el jugador al hacer parry a un golpe de este enemigo.
func on_parried() -> void:
	if state == State.DEAD:
		return
	_flash(Color(1.0, 0.95, 0.4))
	_knockback = visual.global_transform.basis.z * 2.0
	_enter_stagger(parry_stagger)


func _on_died() -> void:
	_change_state(State.DEAD)
	GameState.add_newen(newen_reward)
	remove_from_group("lock_target")
	if _attack_tween:
		_attack_tween.kill()
	if hitbox:
		hitbox.deactivate()
	hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	create_tween().tween_property(visual, "rotation_degrees:z", 90.0, 0.5).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(4.0).timeout.connect(queue_free)


# ── Auxiliares ───────────────────────────────────────────────


func _aggro(player: Node3D) -> void:
	target = player
	_flash(Color.WHITE)
	_change_state(State.CHASE)


func _enter_stagger(duration: float) -> void:
	_stagger = duration
	if _attack_tween:
		_attack_tween.kill()
	if hitbox:
		hitbox.deactivate()
	if weapon_pivot:
		create_tween().tween_property(weapon_pivot, "rotation_degrees", WEAPON_IDLE, 0.15)
	_change_state(State.HIT)


func _change_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _find_player() -> Node3D:
	var player := get_tree().get_first_node_in_group("player")
	if player is Player and player.state != Player.State.DEAD:
		return player
	return null


func _target_dead() -> bool:
	return target is Player and target.state == Player.State.DEAD


func _follow_path(speed: float, delta: float) -> void:
	if nav.is_navigation_finished():
		_accelerate_towards(Vector3.ZERO, delta)
		return
	var next := nav.get_next_path_position()
	var direction := next - global_position
	direction.y = 0.0
	if direction.length() > 0.05:
		direction = direction.normalized()
		_accelerate_towards(direction * speed, delta)
		_face_towards(direction, delta)


func _accelerate_towards(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _face_point(point: Vector3, delta: float) -> void:
	var direction := point - global_position
	direction.y = 0.0
	_face_towards(direction, delta)


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_rotation := Basis.looking_at(direction.normalized()).get_rotation_quaternion()
	visual.quaternion = visual.quaternion.slerp(target_rotation, 1.0 - exp(-rotation_speed * delta))


func _tween_weapon(to_rotation: Vector3, duration: float) -> void:
	if _attack_tween:
		_attack_tween.kill()
	_attack_tween = create_tween()
	_attack_tween.tween_property(weapon_pivot, "rotation_degrees", to_rotation, duration)


func _flash(color: Color) -> void:
	_material.albedo_color = color
	create_tween().tween_property(_material, "albedo_color", body_color, 0.3)
