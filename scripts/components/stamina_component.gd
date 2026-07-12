class_name StaminaComponent
extends Node
## Estamina estilo souls: la acción se permite si queda algo (>0) y el coste
## se descuenta hasta 0, así el último esfuerzo siempre sale pero te deja seco.
## La regeneración espera un momento tras cada gasto.

signal stamina_changed(current: float, max_value: float)

@export var max_stamina := 100.0
@export var regen_rate := 30.0
@export var regen_delay := 0.8
@export var blocking_regen_factor := 0.35

var stamina: float
var blocking := false

var _regen_cooldown := 0.0


func _ready() -> void:
	stamina = max_stamina


func _process(delta: float) -> void:
	if _regen_cooldown > 0.0:
		_regen_cooldown -= delta
		return
	if stamina < max_stamina:
		var rate := regen_rate * (blocking_regen_factor if blocking else 1.0)
		stamina = minf(stamina + rate * delta, max_stamina)
		stamina_changed.emit(stamina, max_stamina)


## Gasto puntual (ataque, esquiva). Falla solo si la estamina está vacía.
func try_consume(cost: float) -> bool:
	if stamina <= 0.0:
		return false
	stamina = maxf(stamina - cost, 0.0)
	_regen_cooldown = regen_delay
	stamina_changed.emit(stamina, max_stamina)
	return true


## Gasto continuo (sprint). Devuelve false cuando se agota.
func drain(amount: float) -> bool:
	if stamina <= 0.0:
		return false
	stamina = maxf(stamina - amount, 0.0)
	_regen_cooldown = maxf(_regen_cooldown, 0.4)
	stamina_changed.emit(stamina, max_stamina)
	return stamina > 0.0
