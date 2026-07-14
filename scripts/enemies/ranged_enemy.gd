extends EnemyBase
## Variante a distancia: en vez de activar un hitbox, dispara un proyectil
## desde el Muzzle apuntando al pecho del jugador. Mantiene la distancia
## (min_range hace que retroceda si el jugador se acerca).

const PROJECTILE := preload("res://scenes/enemies/projectile.tscn")

@onready var muzzle: Marker3D = $Visual/Muzzle


func _attack_became_active() -> void:
	if target == null or not is_instance_valid(target):
		return
	var projectile := PROJECTILE.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.look_at(target.global_position + Vector3.UP * 1.0)
	projectile.hitbox.source = self
	projectile.hitbox.damage = attack_damage
	projectile.hitbox.knockback = attack_knockback
	projectile.hitbox.ignore_group = "enemies"


func _attack_active_ended() -> void:
	pass
