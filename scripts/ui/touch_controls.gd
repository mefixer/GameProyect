class_name TouchControls
extends CanvasLayer
## Controles táctiles para Android: joystick de movimiento, arrastre para
## cámara, y un botón por cada acción de combate/menú del InputMap — misma
## paridad que teclado/ratón y mando. Se autodestruye en plataformas no
## móviles (OS.has_feature("mobile")), así que en escritorio no hace nada.
##
## Multitouch manual: cada índice de toque queda "asignado" al primer
## control que lo captura al bajar el dedo (botón > joystick > cámara);
## esa asignación decide a quién van los eventos de arrastre y de soltar.
## Los botones usan Input.parse_input_event(InputEventAction) en vez de
## Input.action_press/release a secas: algunas acciones (pause, inventory,
## lock_on, switch_target_*) se consumen vía _unhandled_input leyendo el
## evento (event.is_action_pressed(...)), no solo por polling — solo un
## evento real inyectado en la cola dispara ambos casos a la vez.

const JOYSTICK_RADIUS := 80.0
const JOYSTICK_MARGIN := 50.0
const CAMERA_TOUCH_SENSITIVITY := 1.0

## offset = centro del botón relativo a la esquina ("corner"); negativo
## en x/y significa "hacia adentro" de esa esquina. Medidas afinadas para
## el emulador Pixel9_API36 (2424x1080) — revisar en pantallas muy distintas.
const BUTTON_DEFS := [
	{"action": "attack_light", "label": "Ataque", "corner": "br", "offset": Vector2(-110, -110), "radius": 56.0, "color": Color(0.82, 0.24, 0.22)},
	{"action": "attack_heavy", "label": "Fuerte", "corner": "br", "offset": Vector2(-110, -250), "radius": 48.0, "color": Color(0.55, 0.13, 0.12)},
	{"action": "block", "label": "Bloq.", "corner": "br", "offset": Vector2(-250, -110), "radius": 48.0, "color": Color(0.22, 0.42, 0.82)},
	{"action": "jump", "label": "Salto", "corner": "br", "offset": Vector2(-235, -235), "radius": 42.0, "color": Color(0.28, 0.68, 0.34)},
	{"action": "sprint", "label": "Correr", "corner": "br", "offset": Vector2(-370, -160), "radius": 46.0, "color": Color(0.78, 0.62, 0.16)},
	{"action": "use_flask", "label": "Lawen", "corner": "br", "offset": Vector2(-380, -300), "radius": 38.0, "color": Color(0.32, 0.78, 0.48)},
	{"action": "interact", "label": "E", "corner": "br", "offset": Vector2(-260, -350), "radius": 34.0, "color": Color(0.55, 0.55, 0.55)},
	{"action": "lock_on", "label": "Fijar", "corner": "br", "offset": Vector2(-140, -380), "radius": 36.0, "color": Color(0.5, 0.32, 0.8)},
	{"action": "switch_target_left", "label": "‹", "corner": "br", "offset": Vector2(-215, -420), "radius": 24.0, "color": Color(0.5, 0.32, 0.8, 0.75)},
	{"action": "switch_target_right", "label": "›", "corner": "br", "offset": Vector2(-65, -420), "radius": 24.0, "color": Color(0.5, 0.32, 0.8, 0.75)},
	{"action": "inventory", "label": "Inv", "corner": "tl", "offset": Vector2(50, 145), "radius": 32.0, "color": Color(0.4, 0.4, 0.4)},
	{"action": "pause", "label": "II", "corner": "tr", "offset": Vector2(-55, 55), "radius": 32.0, "color": Color(0.4, 0.4, 0.4)},
]

var _joystick_base: Control
var _joystick_knob: Control
var _buttons: Dictionary = {}  # action_name -> Control
var _touch_owner: Dictionary = {}  # touch index -> "joystick" | "camera" | action_name
var _camera_rig: CameraRig = null


func _ready() -> void:
	if not OS.has_feature("mobile"):
		queue_free()
		return
	# Sin esto, Godot deja de llamar a _input() en cuanto se pausa el árbol
	# al abrir un menú — y los botones de inventory/pause son la única
	# forma de volver a cerrarlo desde los controles táctiles.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		_camera_rig = player.camera_rig
	_build_ui()


func _input(event: InputEvent) -> void:
	# Solo se consume el evento si de verdad le pertenece a un control
	# propio (botón/joystick/cámara). Si no, tiene que seguir su camino
	# normal — si no, ningún botón real de un menú (p.ej. "Cerrar",
	# "Reanudar") podría volver a recibir toques nunca más.
	if event is InputEventScreenTouch:
		if event.pressed:
			if _on_touch_down(event.index, event.position):
				get_viewport().set_input_as_handled()
		elif _touch_owner.has(event.index):
			_on_touch_up(event.index)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if _touch_owner.has(event.index):
			_on_touch_drag(event.index, event.position, event.relative)
			get_viewport().set_input_as_handled()


# ── Construcción de la UI ────────────────────────────────────


func _build_ui() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_joystick_base = _make_circle(JOYSTICK_RADIUS, Color(1, 1, 1, 0.15))
	_place_at_corner(_joystick_base, "bl", Vector2(JOYSTICK_RADIUS + JOYSTICK_MARGIN, -(JOYSTICK_RADIUS + JOYSTICK_MARGIN)))
	root.add_child(_joystick_base)

	_joystick_knob = _make_circle(JOYSTICK_RADIUS * 0.45, Color(1, 1, 1, 0.4))
	_joystick_base.add_child(_joystick_knob)
	_center_knob()

	for def in BUTTON_DEFS:
		var btn := _make_circle(def.radius, def.color)
		_place_at_corner(btn, def.corner, def.offset)
		var label := Label.new()
		label.text = def.label
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 13)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(label)
		root.add_child(btn)
		_buttons[def.action] = btn


func _make_circle(radius: float, color: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(radius * 2.0, radius * 2.0)
	c.size = c.custom_minimum_size
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(int(radius))
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(panel)
	return c


func _place_at_corner(c: Control, corner: String, center_offset: Vector2) -> void:
	match corner:
		"bl":
			c.anchor_left = 0.0; c.anchor_right = 0.0; c.anchor_top = 1.0; c.anchor_bottom = 1.0
		"br":
			c.anchor_left = 1.0; c.anchor_right = 1.0; c.anchor_top = 1.0; c.anchor_bottom = 1.0
		"tl":
			c.anchor_left = 0.0; c.anchor_right = 0.0; c.anchor_top = 0.0; c.anchor_bottom = 0.0
		"tr":
			c.anchor_left = 1.0; c.anchor_right = 1.0; c.anchor_top = 0.0; c.anchor_bottom = 0.0
	c.position = center_offset - c.size * 0.5


# ── Multitouch ───────────────────────────────────────────────


## Devuelve true solo si el toque cayó en uno de mis controles (y por lo
## tanto debe consumirse); false lo deja seguir su camino normal, para que
## los botones reales de un menú ("Cerrar", "Reanudar"...) sigan recibiendo
## toques.
func _on_touch_down(index: int, pos: Vector2) -> bool:
	# Los botones (incluidos inventory/pause) siguen activos con un menú
	# abierto: son la única forma de cerrarlo desde los controles táctiles.
	for action in _buttons:
		var btn: Control = _buttons[action]
		if btn.get_global_rect().has_point(pos):
			_touch_owner[index] = action
			_press_action(action)
			btn.modulate = Color(1.4, 1.4, 1.4)
			return true
	if UiState.menu_open:
		return false
	if _joystick_base.get_global_rect().grow(24.0).has_point(pos):
		_touch_owner[index] = "joystick"
		_update_joystick(pos)
		return true
	if pos.x > get_viewport().get_visible_rect().size.x * 0.5:
		_touch_owner[index] = "camera"
		return true
	return false


func _on_touch_up(index: int) -> void:
	if not _touch_owner.has(index):
		return
	var touch_owner: String = _touch_owner[index]
	_touch_owner.erase(index)
	if touch_owner == "joystick":
		_reset_joystick()
	elif touch_owner == "camera":
		pass
	else:
		_release_action(touch_owner)
		if _buttons.has(touch_owner):
			_buttons[touch_owner].modulate = Color(1, 1, 1)


func _on_touch_drag(index: int, pos: Vector2, relative: Vector2) -> void:
	if not _touch_owner.has(index):
		return
	var touch_owner: String = _touch_owner[index]
	if touch_owner == "joystick":
		_update_joystick(pos)
	elif touch_owner == "camera" and _camera_rig:
		_camera_rig.apply_touch_delta(relative * CAMERA_TOUCH_SENSITIVITY)


# ── Joystick de movimiento ───────────────────────────────────


func _update_joystick(pos: Vector2) -> void:
	var center: Vector2 = _joystick_base.get_global_rect().get_center()
	var vec := (pos - center).limit_length(JOYSTICK_RADIUS)
	_joystick_knob.position = _joystick_base.size * 0.5 - _joystick_knob.size * 0.5 + vec
	var norm := vec / JOYSTICK_RADIUS
	_set_directional("move_right", norm.x)
	_set_directional("move_left", -norm.x)
	_set_directional("move_back", norm.y)
	_set_directional("move_forward", -norm.y)


func _set_directional(action: String, value: float) -> void:
	if value > 0.05:
		Input.action_press(action, clampf(value, 0.0, 1.0))
	else:
		Input.action_release(action)


func _reset_joystick() -> void:
	_center_knob()
	for action in ["move_forward", "move_back", "move_left", "move_right"]:
		Input.action_release(action)


func _center_knob() -> void:
	_joystick_knob.position = _joystick_base.size * 0.5 - _joystick_knob.size * 0.5


# ── Botones (inyectan un InputEventAction real) ──────────────


func _press_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	ev.strength = 1.0
	Input.parse_input_event(ev)


func _release_action(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
