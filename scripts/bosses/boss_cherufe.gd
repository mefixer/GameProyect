class_name BossCherufe
extends CharacterBody3D
## El Cherufe: ser de roca y magma que habita en los volcanes (GDD).
## FSM propia (no hereda de EnemyBase): no tiene "casa" a la que volver,
## permanece dormido hasta que el jugador cruza la niebla, y gana un
## ataque nuevo (erupción) al entrar en la Fase 2 (≤50% de vida).

signal awakened
signal phase_changed(phase: int)

enum State { DORMANT, AWAKEN, CHASE, ATTACK, HIT, DEAD }
enum Attack { SLAM, THROW, ERUPTION }

const BOSS_ID := "cherufe"
const PROJECTILE := preload("res://scenes/enemies/projectile.tscn")
const ERUPTION := preload("res://scenes/bosses/eruption_hazard.tscn")
const BODY_IDLE_COLOR := Color(0.32, 0.16, 0.13)
const BODY_PHASE2_COLOR := Color(0.42, 0.12, 0.08)

@export var max_health := 400.0
@export var newen_reward := 300

@export_group("Movimiento")
@export var chase_speed := 3.0
@export var acceleration := 14.0
@export var rotation_speed := 5.0

@export_group("Ataques — Fase 1")
@export var melee_range := 3.2
@export var slam_damage := 34.0
@export var slam_knockback := 10.0
@export var slam_windup := 0.9
@export var slam_active := 0.35
@export var slam_recovery := 0.8
@export var throw_damage := 20.0
@export var throw_windup := 0.8
@export var throw_recovery := 0.7
@export var throw_speed := 13.0
@export var attack_cooldown := 1.6

@export_group("Ataques — Fase 2 (≤50% vida)")
@export var phase2_speed_multiplier := 1.35
@export var phase2_cooldown_multiplier := 0.7
## Cada cuántos ataques normales se intercala una erupción.
@export var eruption_every := 3
@export var eruption_telegraph := 1.2
@export var eruption_damage := 28.0
@export var eruption_radius := 3.0

var state := State.DORMANT
var phase := 1

var _state_time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _target: Node3D = null
var _cooldown := 0.0
var _attack_phase := 0
var _current_attack := Attack.SLAM
var _attacks_since_eruption := 0
var _knockback := Vector3.ZERO
var _stagger := 0.4
var _material: StandardMaterial3D
var _attack_tween: Tween

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var visual: Node3D = $Visual
@onready var mesh: MeshInstance3D = $Visual/Body/CherufeBody
@onready var slam_pivot: Node3D = $Visual/SlamPivot
@onready var slam_hitbox: Hitbox = $Visual/SlamPivot/Hitbox
@onready var muzzle: Marker3D = $Visual/Muzzle
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent


func _ready() -> void:
	if GameState.is_boss_defeated(BOSS_ID):
		queue_free()
		return
	_material = mesh.get_active_material(0).duplicate()
	_material.albedo_color = BODY_IDLE_COLOR
	mesh.set_surface_override_material(0, _material)
	health.max_health = max_health
	health.reset()
	hurtbox.monitorable = false
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	slam_hitbox.source = self
	slam_hitbox.damage = slam_damage
	slam_hitbox.knockback = slam_knockback
	slam_hitbox.ignore_group = "enemies"
	slam_hitbox.hit_landed.connect(_on_slam_landed)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	if not is_on_floor():
		velocity.y -= _gravity * delta

	match state:
		State.DORMANT:
			_accelerate_towards(Vector3.ZERO, delta)
		State.AWAKEN:
			_state_awaken(delta)
		State.CHASE:
			_state_chase(delta)
		State.ATTACK:
			_state_attack(delta)
		State.HIT:
			_state_hit(delta)
		State.DEAD:
			_accelerate_towards(Vector3.ZERO, delta)

	move_and_slide()


# ── Despertar (llamado por el disparador de la arena) ─────────


func awaken(player: Node3D) -> void:
	if state != State.DORMANT:
		return
	_target = player
	_change_state(State.AWAKEN)
	awakened.emit()
	create_tween().tween_property(visual, "scale", Vector3.ONE * 1.15, 0.5) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	GameFeel.hitstop(0.1, 0.15)


func _state_awaken(delta: float) -> void:
	_accelerate_towards(Vector3.ZERO, delta)
	if _state_time >= 0.9:
		hurtbox.monitorable = true
		_change_state(State.CHASE)


# ── Estados ──────────────────────────────────────────────────


func _state_chase(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_accelerate_towards(Vector3.ZERO, delta)
		return
	var distance := global_position.distance_to(_target.global_position)
	if distance <= melee_range:
		_accelerate_towards(Vector3.ZERO, delta)
		_face_point(_target.global_position, delta)
		if _cooldown <= 0.0:
			_start_attack()
	else:
		nav.target_position = _target.global_position
		_follow_path(chase_speed * (phase2_speed_multiplier if phase == 2 else 1.0), delta)


func _state_attack(delta: float) -> void:
	_accelerate_towards(Vector3.ZERO, delta)
	match _current_attack:
		Attack.SLAM:
			_run_slam(delta)
		Attack.THROW:
			_run_throw(delta)
		Attack.ERUPTION:
			_run_eruption(delta)


func _state_hit(delta: float) -> void:
	velocity.x = _knockback.x
	velocity.z = _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, 12.0 * delta)
	if _state_time >= _stagger:
		_change_state(State.CHASE)


# ── Ataques ──────────────────────────────────────────────────


func _start_attack() -> void:
	_change_state(State.ATTACK)
	_attack_phase = 0
	_attacks_since_eruption += 1
	if phase == 2 and _attacks_since_eruption > eruption_every:
		_attacks_since_eruption = 0
		_current_attack = Attack.ERUPTION
	elif _target and global_position.distance_to(_target.global_position) <= melee_range:
		_current_attack = Attack.SLAM
	else:
		_current_attack = Attack.THROW
	_flash(Color(1.0, 0.6, 0.2))  # telegrafiado: brillo anaranjado más intenso


func _run_slam(_delta: float) -> void:
	if _attack_phase == 0:
		if _target and is_instance_valid(_target):
			_face_point(_target.global_position, 8.0 * get_physics_process_delta_time())
		if _state_time >= slam_windup:
			_attack_phase = 1
			slam_hitbox.activate()
			var forward := -visual.global_transform.basis.z
			velocity.x = forward.x * 4.0
			velocity.z = forward.z * 4.0
	elif _attack_phase == 1 and _state_time >= slam_windup + slam_active:
		_attack_phase = 2
		slam_hitbox.deactivate()
	elif _attack_phase == 2 and _state_time >= slam_windup + slam_active + slam_recovery:
		_end_attack()


func _run_throw(_delta: float) -> void:
	if _attack_phase == 0:
		if _target and is_instance_valid(_target):
			_face_point(_target.global_position, 8.0 * get_physics_process_delta_time())
		if _state_time >= throw_windup:
			_attack_phase = 1
			_fire_rock()
	elif _attack_phase == 1 and _state_time >= throw_windup + throw_recovery:
		_end_attack()


func _run_eruption(_delta: float) -> void:
	if _attack_phase == 0:
		if _state_time >= 0.05:
			_attack_phase = 1
			_spawn_eruption()
	elif _attack_phase == 1 and _state_time >= eruption_telegraph + 0.5:
		_end_attack()


func _fire_rock() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var rock := PROJECTILE.instantiate()
	get_tree().current_scene.add_child(rock)
	rock.global_position = muzzle.global_position
	rock.scale = Vector3.ONE * 2.2
	rock.speed = throw_speed
	rock.look_at(_target.global_position + Vector3.UP * 1.0)
	rock.hitbox.source = self
	rock.hitbox.damage = throw_damage
	rock.hitbox.knockback = 6.0
	rock.hitbox.ignore_group = "enemies"
	rock.hitbox.hit_landed.connect(_on_slam_landed)


func _spawn_eruption() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var hazard := ERUPTION.instantiate()
	get_tree().current_scene.add_child(hazard)
	hazard.global_position = _target.global_position
	hazard.radius = eruption_radius
	hazard.telegraph_time = eruption_telegraph
	hazard.damage = eruption_damage
	hazard.source = self


func _end_attack() -> void:
	_cooldown = attack_cooldown * (phase2_cooldown_multiplier if phase == 2 else 1.0)
	_change_state(State.CHASE)


func _on_slam_landed(hurtbox: Hurtbox) -> void:
	AudioManager.play_combat("jefe_impacto", hurtbox.global_position)
	Fx.burst("lava", hurtbox.global_position)


# ── Reacciones ───────────────────────────────────────────────


func _on_hit_received(from_hitbox: Hitbox) -> void:
	if state == State.DEAD or state == State.DORMANT:
		return
	health.apply_damage(from_hitbox.damage)
	if not health.is_alive():
		return
	_flash(Color.WHITE)
	if phase == 1 and health.health <= health.max_health * 0.5:
		_enter_phase2()
	var away := global_position - from_hitbox.global_position
	away.y = 0.0
	away = away.normalized() if not away.is_zero_approx() else Vector3.BACK
	_knockback = away * from_hitbox.knockback * 0.3
	_enter_stagger(0.3)


func _enter_phase2() -> void:
	phase = 2
	phase_changed.emit(phase)
	_material.albedo_color = BODY_PHASE2_COLOR
	Fx.burst("lava", global_position + Vector3.UP * 1.7)
	GameFeel.hitstop(0.2, 0.05)
	create_tween().tween_property(visual, "scale", Vector3.ONE * 1.25, 0.4) \
			.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_died() -> void:
	_change_state(State.DEAD)
	GameState.add_newen(newen_reward)
	GameState.defeat_boss(BOSS_ID)
	Fx.burst("lava", global_position + Vector3.UP * 1.7)
	Fx.burst("muerte", global_position + Vector3.UP * 1.0)
	if _attack_tween:
		_attack_tween.kill()
	slam_hitbox.deactivate()
	hurtbox.set_deferred("monitorable", false)
	set_deferred("collision_layer", 0)
	create_tween().tween_property(visual, "rotation_degrees:x", 80.0, 1.2).set_ease(Tween.EASE_OUT)


# ── Auxiliares ───────────────────────────────────────────────


func _enter_stagger(duration: float) -> void:
	_stagger = duration
	slam_hitbox.deactivate()
	_change_state(State.HIT)


func _change_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


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


func _flash(color: Color) -> void:
	_material.albedo_color = color
	var base := BODY_PHASE2_COLOR if phase == 2 else BODY_IDLE_COLOR
	create_tween().tween_property(_material, "albedo_color", base, 0.3)
