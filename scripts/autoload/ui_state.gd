extends Node
## Coordina qué menú de pantalla completa está abierto (autoload "UiState").
## Pausa/inventario/rewe comparten esta exclusión mutua para no apilarse
## ni pelear por el modo del ratón.

var menu_open := false


## Devuelve false si ya hay otro menú abierto (el llamador no debe abrirse).
func try_open() -> bool:
	if menu_open:
		return false
	menu_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return true


func close() -> void:
	menu_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
