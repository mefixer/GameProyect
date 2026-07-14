class_name Hitbox
extends Area3D
## Área que inflige daño a los Hurtbox que toca mientras está activa.
## Activar solo durante los frames activos del ataque.

signal hit_landed(hurtbox: Hurtbox)

@export var damage := 15.0
@export var knockback := 5.0
## 0 = máximo un golpe por activación; >0 permite regolpear cada N segundos
## (para peligros continuos como el maniquí giratorio).
@export var rehit_interval := 0.0
## Fuego amigo: si el dueño de la hurtbox está en este grupo, no se golpea
## (los enemigos usan "enemies" para no dañarse entre ellos).
@export var ignore_group := ""

## Quién golpea: se usa para no golpearse a sí mismo y para el knockback.
var source: Node3D

var _recent_hits := {}


func _ready() -> void:
	monitoring = false
	area_entered.connect(_on_area_entered)


func activate() -> void:
	_recent_hits.clear()
	monitoring = true


func deactivate() -> void:
	monitoring = false


func _on_area_entered(area: Area3D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox.root_node == source:
		return
	if ignore_group != "" and hurtbox.root_node and hurtbox.root_node.is_in_group(ignore_group):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _recent_hits.has(hurtbox) \
			and (rehit_interval <= 0.0 or now - _recent_hits[hurtbox] < rehit_interval):
		return
	_recent_hits[hurtbox] = now
	if hurtbox.receive_hit(self):
		hit_landed.emit(hurtbox)
