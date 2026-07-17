class_name Player
extends CharacterBody3D
## Controlador del weichafe: movimiento (Fase 1) + combate núcleo (Fase 2).
## Máquina de estados: MOVE, DODGE, ATTACK, BLOCK, HIT, DEAD.
## Con lock-on activo camina en strafe mirando al objetivo; el sprint lo rompe.

enum State { MOVE, DODGE, ATTACK, BLOCK, HIT, DEAD }

const WEAPON_IDLE := Vector3(-25.0, 0.0, 0.0)
const SHIELD_IDLE_POS := Vector3(-0.42, 1.15, 0.0)
const SHIELD_BLOCK_POS := Vector3(-0.15, 1.25, -0.3)

## Tiempos en segundos; los frames activos del hitbox van de windup a windup+active.
## "light2" es el segundo golpe del combo ligero: más rápido, encadenable
## solo desde el recovery de "light" con el input en buffer.
const ATTACKS := {
	light = { windup = 0.25, active = 0.20, recovery = 0.30, damage = 15.0, stamina = 20.0 },
	light2 = { windup = 0.16, active = 0.18, recovery = 0.35, damage = 17.0, stamina = 15.0 },
	heavy = { windup = 0.45, active = 0.25, recovery = 0.45, damage = 32.0, stamina = 35.0 },
}

## Ventana del buffer de inputs: una acción pulsada durante un ataque se
## guarda y se ejecuta en el primer frame legal (estilo souls).
const BUFFER_WINDOW := 0.3

@export_group("Movimiento")
@export var run_speed := 5.5
@export var sprint_speed := 8.5
@export var block_speed := 2.5
@export var acceleration := 30.0
@export var rotation_speed := 10.0
@export var jump_velocity := 4.2

@export_group("Combate")
@export var dodge_speed := 9.0
@export var dodge_duration := 0.45
@export var iframes_start := 0.05
@export var iframes_end := 0.35
@export var stamina_cost_dodge := 25.0
@export var sprint_stamina_per_sec := 12.0
@export var hit_stagger := 0.4
@export var guard_break_stagger := 0.9
## Ventana de parry: los primeros N segundos tras levantar el escudo.
@export var parry_window := 0.18

@export_group("Audio")
@export var footstep_interval_walk := 0.42
@export var footstep_interval_sprint := 0.28

var state := State.MOVE

var _state_time := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _sprint_held := 0.0
var _dodge_direction := Vector3.ZERO
var _attack: Dictionary
var _attack_name := "light"
var _footstep_timer := 0.0
var _buffered_action := ""
var _buffer_time := 0.0
var _attack_sprint_held := 0.0
var _hitbox_active := false
var _knockback := Vector3.ZERO
var _stagger_duration := 0.4
var _attack_tween: Tween
var _weapon_trail: GPUParticles3D
var _body_material: StandardMaterial3D
var _body_base_color: Color
var _shield_material: StandardMaterial3D
var _shield_base_color: Color

@onready var camera_rig: CameraRig = $CameraRig
@onready var visual: Node3D = $Visual
@onready var body_mesh: MeshInstance3D = $Visual/Body/WeichafeBody
@onready var weapon_pivot: Node3D = $Visual/WeaponPivot
@onready var shield_pivot: Node3D = $Visual/ShieldPivot
@onready var shield_mesh: MeshInstance3D = $Visual/ShieldPivot/Shield
@onready var hitbox: Hitbox = $Visual/WeaponPivot/Weapon/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var health: HealthComponent = $HealthComponent
@onready var stamina: StaminaComponent = $StaminaComponent


func _ready() -> void:
	# Estadísticas del personaje (GameState persiste entre recargas de escena)
	health.max_health = GameState.max_health()
	health.reset()
	stamina.max_stamina = GameState.max_stamina()
	stamina.stamina = stamina.max_stamina
	weapon_pivot.rotation_degrees = WEAPON_IDLE
	shield_pivot.position = SHIELD_IDLE_POS
	hitbox.source = self
	hitbox.hit_landed.connect(_on_hit_landed)
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)
	# Material propio para poder parpadear sin afectar a otras instancias
	_body_material = body_mesh.get_active_material(0).duplicate()
	body_mesh.set_surface_override_material(0, _body_material)
	_body_base_color = _body_material.albedo_color
	_shield_material = shield_mesh.get_active_material(0).duplicate()
	shield_mesh.set_surface_override_material(0, _shield_material)
	_shield_base_color = _shield_material.albedo_color
	# Trail del arma: emite solo durante los frames activos del ataque
	_weapon_trail = Fx.create_trail(hitbox)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_buffer_time += delta
	_capture_combat_buffer(delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta

	match state:
		State.MOVE:
			_state_move(delta)
		State.DODGE:
			_state_dodge(delta)
		State.ATTACK:
			_state_attack(delta)
		State.BLOCK:
			_state_block(delta)
		State.HIT:
			_state_hit(delta)
		State.DEAD:
			_accelerate_towards(Vector3.ZERO, delta)

	move_and_slide()


# ── Estados ──────────────────────────────────────────────────


func _state_move(delta: float) -> void:
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	# Estilo souls: toque corto de sprint = esquiva, mantenido = correr
	var sprint_pressed := Input.is_action_pressed("sprint")
	if sprint_pressed:
		_sprint_held += delta
	if Input.is_action_just_released("sprint"):
		var was_tap := _sprint_held <= 0.2
		_sprint_held = 0.0
		if was_tap and is_on_floor() and _try_dodge():
			return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_rig.to_world_direction(input_dir)
	var sprinting := sprint_pressed and _sprint_held > 0.2 and not direction.is_zero_approx()
	if sprinting:
		sprinting = stamina.drain(sprint_stamina_per_sec * delta)

	_accelerate_towards(direction * (sprint_speed if sprinting else run_speed), delta)
	_update_facing(direction, sprinting, delta)
	_update_footsteps(direction, sprinting, delta)

	if is_on_floor():
		if Input.is_action_just_pressed("attack_light"):
			_try_attack("light")
		elif Input.is_action_just_pressed("attack_heavy"):
			_try_attack("heavy")
		elif Input.is_action_just_pressed("use_flask"):
			_try_use_flask()
		elif Input.is_action_pressed("block") and stamina.stamina > 0.0:
			_enter_block()


func _state_dodge(delta: float) -> void:
	hurtbox.invulnerable = _state_time >= iframes_start and _state_time <= iframes_end
	var falloff := 1.0 - 0.5 * (_state_time / dodge_duration)
	velocity.x = _dodge_direction.x * dodge_speed * falloff
	velocity.z = _dodge_direction.z * dodge_speed * falloff
	_face_towards(_dodge_direction, delta)
	if _state_time >= dodge_duration:
		hurtbox.invulnerable = false
		_change_state(State.MOVE)


func _state_attack(delta: float) -> void:
	_accelerate_towards(Vector3.ZERO, delta)
	var windup: float = _attack.windup
	var active_end: float = windup + _attack.active
	if not _hitbox_active and _state_time >= windup and _state_time < active_end:
		_hitbox_active = true
		hitbox.activate()
		_weapon_trail.emitting = true
		# Pequeño empuje hacia delante que acompaña el golpe
		var forward := -visual.global_transform.basis.z
		velocity.x = forward.x * 2.5
		velocity.z = forward.z * 2.5
	elif _hitbox_active and _state_time >= active_end:
		_hitbox_active = false
		hitbox.deactivate()
		_weapon_trail.emitting = false

	# Recovery cancelable: esquiva o segundo golpe del combo salen ya,
	# sin esperar a que termine la animación
	if _state_time >= active_end:
		if _consume_buffer("dodge"):
			if is_on_floor() and _try_dodge():
				return
		elif _attack_name == "light" and _consume_buffer("light"):
			if _try_attack("light2"):
				return

	if _state_time >= active_end + _attack.recovery:
		_change_state(State.MOVE)
		# Ataque en cola al terminar (encadena heavy→light, light2→light…)
		if _consume_buffer("light"):
			_try_attack("light")
		elif _consume_buffer("heavy"):
			_try_attack("heavy")


func _state_block(delta: float) -> void:
	if not Input.is_action_pressed("block") or stamina.stamina <= 0.0:
		_lower_shield()
		_change_state(State.MOVE)
		return
	if Input.is_action_just_pressed("attack_light") and _try_attack("light"):
		return
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := camera_rig.to_world_direction(input_dir)
	_accelerate_towards(direction * block_speed, delta)
	_update_facing(direction, false, delta)


func _state_hit(delta: float) -> void:
	velocity.x = _knockback.x
	velocity.z = _knockback.z
	_knockback = _knockback.move_toward(Vector3.ZERO, 20.0 * delta)
	if _state_time >= _stagger_duration:
		_change_state(State.MOVE)


# ── Acciones ─────────────────────────────────────────────────


func _try_attack(attack_name: String) -> bool:
	var def: Dictionary = ATTACKS[attack_name]
	if not stamina.try_consume(def.stamina):
		return false
	_lower_shield()
	_attack = def
	_attack_name = attack_name
	_hitbox_active = false
	var multiplier := GameState.light_damage_multiplier() if attack_name.begins_with("light") \
			else GameState.heavy_damage_multiplier()
	hitbox.damage = def.damage * multiplier
	_change_state(State.ATTACK)
	# Con lock-on el golpe sale ya orientado al objetivo
	if camera_rig.lock_target:
		var to_target: Vector3 = camera_rig.lock_target.global_position - global_position
		to_target.y = 0.0
		if not to_target.is_zero_approx():
			visual.quaternion = Basis.looking_at(to_target.normalized()).get_rotation_quaternion()
	_animate_attack(attack_name)
	return true


func _try_dodge() -> bool:
	if not stamina.try_consume(stamina_cost_dodge):
		return false
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_dodge_direction = camera_rig.to_world_direction(input_dir)
	if _dodge_direction.is_zero_approx():
		_dodge_direction = -visual.global_transform.basis.z
	_dodge_direction = _dodge_direction.normalized()
	AudioManager.play_combat("esquiva", global_position)
	Fx.burst("polvo", global_position + Vector3.UP * 0.1)
	_change_state(State.DODGE)
	var tween := create_tween()
	tween.tween_property(visual, "scale:y", 0.55, dodge_duration * 0.3)
	tween.tween_property(visual, "scale:y", 1.0, dodge_duration * 0.5)
	return true


func _try_use_flask() -> void:
	if health.health >= health.max_health or not GameState.use_flask():
		return
	health.heal(health.max_health * 0.4)
	_flash(Color(0.4, 1.0, 0.55))
	Fx.burst("curacion", global_position + Vector3.UP * 1.0)


func _enter_block() -> void:
	_change_state(State.BLOCK)
	stamina.blocking = true
	create_tween().tween_property(shield_pivot, "position", SHIELD_BLOCK_POS, 0.12)


func _lower_shield() -> void:
	stamina.blocking = false
	create_tween().tween_property(shield_pivot, "position", SHIELD_IDLE_POS, 0.15)


func _enter_stagger(duration: float) -> void:
	_stagger_duration = duration
	_clear_buffer()  # un golpe recibido no debe "recordar" inputs previos
	if _attack_tween:
		_attack_tween.kill()
	hitbox.deactivate()
	_weapon_trail.emitting = false
	_hitbox_active = false
	hurtbox.invulnerable = false
	visual.scale = Vector3.ONE
	create_tween().tween_property(weapon_pivot, "rotation_degrees", WEAPON_IDLE, 0.1)
	_change_state(State.HIT)


# ── Buffer de inputs (estilo souls) ──────────────────────────


## Durante un ataque, guarda la siguiente acción pulsada para ejecutarla
## en el primer frame legal — sin esto, los inputs entre animaciones se
## pierden y el combate se siente "sordo".
func _capture_combat_buffer(delta: float) -> void:
	if state != State.ATTACK:
		_attack_sprint_held = 0.0
		return
	if Input.is_action_just_pressed("attack_light"):
		_set_buffer("light")
	elif Input.is_action_just_pressed("attack_heavy"):
		_set_buffer("heavy")
	# La esquiva es toque corto de sprint: replicar la detección de tap
	if Input.is_action_just_pressed("sprint"):
		_attack_sprint_held = delta
	elif Input.is_action_pressed("sprint") and _attack_sprint_held > 0.0:
		_attack_sprint_held += delta
	if Input.is_action_just_released("sprint"):
		if _attack_sprint_held > 0.0 and _attack_sprint_held <= 0.2:
			_set_buffer("dodge")
		_attack_sprint_held = 0.0


func _set_buffer(action: String) -> void:
	_buffered_action = action
	_buffer_time = 0.0


## Consume y devuelve true solo si esa acción está en buffer y fresca.
func _consume_buffer(action: String) -> bool:
	if _buffered_action != action or _buffer_time > BUFFER_WINDOW:
		return false
	_buffered_action = ""
	return true


func _clear_buffer() -> void:
	_buffered_action = ""


# ── Reacciones ───────────────────────────────────────────────


func _on_hit_received(from_hitbox: Hitbox) -> void:
	if state == State.DEAD:
		return
	var attack_origin := from_hitbox.global_position
	if from_hitbox.source:
		attack_origin = from_hitbox.source.global_position
	var away := global_position - attack_origin
	away.y = 0.0
	away = away.normalized() if not away.is_zero_approx() else Vector3.BACK

	if state == State.BLOCK and _is_facing(attack_origin):
		# Parry: golpe recibido justo al levantar el escudo → gratis y castiga
		if _state_time <= parry_window:
			_execute_parry(from_hitbox)
			return
		# Bloqueo: sin daño, pero cuesta estamina; si te deja en 0, rompe la guardia
		stamina.try_consume(from_hitbox.damage * 1.2)
		AudioManager.play_combat("bloqueo", global_position)
		camera_rig.add_trauma(0.25)
		_knockback = away * from_hitbox.knockback * 0.5
		if stamina.stamina <= 0.0:
			_lower_shield()
			_enter_stagger(guard_break_stagger)
		return

	health.apply_damage(from_hitbox.damage)
	AudioManager.play_combat("jugador_dano", global_position)
	_flash(Color(1.0, 0.25, 0.2))
	camera_rig.add_trauma(0.5)
	if health.is_alive():
		_lower_shield()
		_knockback = away * from_hitbox.knockback
		_enter_stagger(hit_stagger)


func _execute_parry(from_hitbox: Hitbox) -> void:
	AudioManager.play_combat("parry", global_position)
	Fx.burst("chispas_parry", shield_pivot.global_position)
	GameFeel.hitstop(0.15)
	camera_rig.add_trauma(0.3)
	_flash_shield(Color(1.0, 0.95, 0.55))
	# "Punch" del escudo hacia delante y de vuelta
	var punch := create_tween()
	punch.tween_property(shield_pivot, "position", SHIELD_BLOCK_POS + Vector3(0, 0, -0.25), 0.06)
	punch.tween_property(shield_pivot, "position", SHIELD_BLOCK_POS, 0.18)
	if from_hitbox.source and from_hitbox.source.has_method("on_parried"):
		from_hitbox.source.on_parried()


func _flash_shield(color: Color) -> void:
	_shield_material.albedo_color = color
	create_tween().tween_property(_shield_material, "albedo_color", _shield_base_color, 0.35)


func _on_hit_landed(hurtbox: Hurtbox) -> void:
	var sound := "golpe_ligero" if _attack_name == "light" else "golpe_fuerte"
	AudioManager.play_combat(sound, hurtbox.global_position)
	Fx.burst("chispas", hurtbox.global_position)
	GameFeel.hitstop()
	camera_rig.add_trauma(0.35)


func _on_died() -> void:
	_change_state(State.DEAD)
	GameState.on_player_died(global_position)
	if _attack_tween:
		_attack_tween.kill()
	hitbox.deactivate()
	hurtbox.set_deferred("monitorable", false)
	stamina.blocking = false
	visual.scale = Vector3.ONE
	create_tween().tween_property(visual, "rotation_degrees:z", 90.0, 0.5).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(2.5).timeout.connect(
		func() -> void: get_tree().reload_current_scene()
	)


# ── Auxiliares ───────────────────────────────────────────────


func _change_state(new_state: State) -> void:
	state = new_state
	_state_time = 0.0


func _accelerate_towards(target_velocity: Vector3, delta: float) -> void:
	var horizontal := Vector3(velocity.x, 0.0, velocity.z)
	horizontal = horizontal.move_toward(target_velocity, acceleration * delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z


func _update_facing(move_direction: Vector3, sprinting: bool, delta: float) -> void:
	var face_direction := move_direction
	if camera_rig.lock_target and not sprinting:
		face_direction = camera_rig.lock_target.global_position - global_position
		face_direction.y = 0.0
	_face_towards(face_direction, delta)


func _face_towards(direction: Vector3, delta: float) -> void:
	if direction.length_squared() < 0.001:
		return
	var target_rotation := Basis.looking_at(direction.normalized()).get_rotation_quaternion()
	# 1 - exp(-k*delta) hace el suavizado independiente del framerate
	visual.quaternion = visual.quaternion.slerp(target_rotation, 1.0 - exp(-rotation_speed * delta))


func _update_footsteps(direction: Vector3, sprinting: bool, delta: float) -> void:
	if not is_on_floor() or direction.is_zero_approx():
		_footstep_timer = 0.0
		return
	_footstep_timer -= delta
	if _footstep_timer <= 0.0:
		_footstep_timer = footstep_interval_sprint if sprinting else footstep_interval_walk
		AudioManager.play_footstep(_current_surface(), global_position)


## Superficie del suelo bajo el jugador según el grupo del StaticBody
## ("surface_piedra", "surface_madera"…); sin grupo reconocido, cae en pasto.
func _current_surface() -> String:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5, global_position - Vector3.UP * 1.5
	)
	query.collision_mask = 1  # capa "mundo"
	var result := space_state.intersect_ray(query)
	if result and result.collider:
		for surface_name in ["piedra", "madera"]:
			if result.collider.is_in_group("surface_%s" % surface_name):
				return surface_name
	return "pasto"


func _is_facing(point: Vector3) -> bool:
	var to_point := point - global_position
	to_point.y = 0.0
	if to_point.is_zero_approx():
		return true
	return (-visual.global_transform.basis.z).dot(to_point.normalized()) > -0.2


func _animate_attack(attack_name: String) -> void:
	if _attack_tween:
		_attack_tween.kill()
	var def: Dictionary = ATTACKS[attack_name]
	_attack_tween = create_tween()
	if attack_name.begins_with("light"):
		# Tajo horizontal; el segundo golpe del combo vuelve en espejo
		var dir := 1.0 if attack_name == "light" else -1.0
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", Vector3(-15, 80 * dir, 0), def.windup
		).set_ease(Tween.EASE_OUT)
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", Vector3(-15, -80 * dir, 0), def.active
		)
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", WEAPON_IDLE, def.recovery
		).set_ease(Tween.EASE_IN_OUT)
	else:
		# Golpe descendente
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", Vector3(-120, 0, 0), def.windup
		).set_ease(Tween.EASE_OUT)
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", Vector3(45, 0, 0), def.active
		)
		_attack_tween.tween_property(
			weapon_pivot, "rotation_degrees", WEAPON_IDLE, def.recovery
		).set_ease(Tween.EASE_IN_OUT)


func _flash(color: Color) -> void:
	_body_material.albedo_color = color
	create_tween().tween_property(_body_material, "albedo_color", _body_base_color, 0.3)
