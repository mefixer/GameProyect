extends StaticBody3D
## Maniquí de entrenamiento: recibe daño, parpadea, "muere" y reaparece.

signal parried

@export var respawn_time := 3.0

@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var mesh: MeshInstance3D = $MeshInstance3D

var _material: StandardMaterial3D
var _base_color: Color


func _ready() -> void:
	_material = mesh.get_active_material(0).duplicate()
	mesh.set_surface_override_material(0, _material)
	_base_color = _material.albedo_color
	hurtbox.hit_received.connect(_on_hit_received)
	health.died.connect(_on_died)


func _on_hit_received(hitbox: Hitbox) -> void:
	health.apply_damage(hitbox.damage)
	if health.is_alive():
		_flash(Color.WHITE)


## Llamado por el jugador al hacer parry a un golpe de este maniquí.
func on_parried() -> void:
	_flash(Color(1.0, 0.95, 0.4))
	parried.emit()


func _on_died() -> void:
	# Al morir deja de ser fijable y de recibir golpes hasta reaparecer
	remove_from_group("lock_target")
	hurtbox.set_deferred("monitorable", false)
	create_tween().tween_property(self, "rotation_degrees:x", -85.0, 0.4).set_ease(Tween.EASE_OUT)
	get_tree().create_timer(respawn_time).timeout.connect(_respawn)


func _respawn() -> void:
	rotation_degrees.x = 0.0
	health.reset()
	add_to_group("lock_target")
	hurtbox.set_deferred("monitorable", true)
	_flash(Color(0.4, 1.0, 0.5))


func _flash(color: Color) -> void:
	_material.albedo_color = color
	create_tween().tween_property(_material, "albedo_color", _base_color, 0.25)
