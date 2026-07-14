extends Node3D
## Raíz del nivel: al cargar, coloca al jugador en el último rewe donde
## descansó y materializa el newen soltado en la muerte anterior.

const NEWEN_DROP := preload("res://scenes/world/newen_drop.tscn")


func _ready() -> void:
	if GameState.has_respawn:
		var player := get_tree().get_first_node_in_group("player") as Node3D
		if player:
			player.global_position = GameState.respawn_position
	if GameState.has_drop:
		var drop := NEWEN_DROP.instantiate()
		add_child(drop)
		drop.global_position = GameState.dropped_position
