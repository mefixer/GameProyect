extends Node
## Utilidades globales de game feel (autoload "GameFeel").


## Congela el tiempo un instante al conectar un golpe.
func hitstop(duration := 0.06, time_scale := 0.05) -> void:
	if Engine.time_scale < 1.0:
		return
	Engine.time_scale = time_scale
	await get_tree().create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
