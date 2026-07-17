extends Node3D
## Peligro de erupción del Cherufe (Fase 2): un anillo de aviso crece durante
## el telegrafiado; si el jugador sigue dentro cuando detona, recibe daño.
## Esquivable con tiempo de sobra — el propósito es obligar a moverse.

@export var radius := 3.0
@export var telegraph_time := 1.2
@export var damage := 28.0
## Quién la invocó (para no autolesionarse ni dañar a otros enemigos).
var source: Node3D

@onready var warning_ring: MeshInstance3D = $WarningRing
@onready var hitbox: Hitbox = $Hitbox
@onready var glow: OmniLight3D = $Glow


func _ready() -> void:
	warning_ring.scale = Vector3(0.1, 1.0, 0.1)
	_resize_shapes()
	var tween := create_tween()
	tween.tween_property(warning_ring, "scale", Vector3(1.0, 1.0, 1.0), telegraph_time) \
			.set_ease(Tween.EASE_OUT)
	tween.tween_callback(_detonate)


func _resize_shapes() -> void:
	var ring_mesh: TorusMesh = warning_ring.mesh
	ring_mesh.outer_radius = radius
	ring_mesh.inner_radius = radius * 0.85
	var shape: CylinderShape3D = hitbox.get_node("CollisionShape3D").shape
	shape.radius = radius


func _detonate() -> void:
	hitbox.source = source
	hitbox.damage = damage
	hitbox.ignore_group = "enemies"
	hitbox.activate()
	glow.visible = true
	warning_ring.visible = false
	Fx.burst("lava", global_position)
	await get_tree().create_timer(0.15, true).timeout
	queue_free()
