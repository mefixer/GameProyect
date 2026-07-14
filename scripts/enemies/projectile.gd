extends Node3D
## Proyectil simple: vuela recto (-Z), daña vía Hitbox y desaparece al
## impactar con algo o al agotar su vida.

@export var speed := 12.0
@export var lifetime := 4.0

@onready var hitbox: Hitbox = $Hitbox


func _ready() -> void:
	hitbox.activate()
	hitbox.hit_landed.connect(func(_hurtbox: Hurtbox) -> void: queue_free())
	hitbox.body_entered.connect(func(_body: Node3D) -> void: queue_free())
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	global_position += -global_transform.basis.z * speed * delta
