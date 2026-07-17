extends Node
## Autoload "Fx": partículas de game feel (Fase 9). Igual que AudioManager,
## es el único punto de entrada — pool de GPUParticles3D one-shot con
## presets construidos por código (sin .tscn por efecto), más helpers para
## emisores persistentes (trail de arma, brasas del rewe).

const POOL_SIZE := 12

## Presets: color, cantidad, tamaño, velocidad, gravedad, vida.
const PRESETS := {
	"chispas": {
		color = Color(1.0, 0.85, 0.4), amount = 16, size = 0.06,
		velocity = 4.0, gravity = Vector3(0, -9.0, 0), lifetime = 0.35,
	},
	"chispas_parry": {
		color = Color(1.0, 0.95, 0.6), amount = 28, size = 0.08,
		velocity = 6.0, gravity = Vector3(0, -4.0, 0), lifetime = 0.45,
	},
	"polvo": {
		color = Color(0.55, 0.48, 0.38, 0.7), amount = 10, size = 0.16,
		velocity = 1.6, gravity = Vector3(0, 0.8, 0), lifetime = 0.5,
	},
	"muerte": {
		color = Color(0.35, 0.9, 0.5), amount = 24, size = 0.1,
		velocity = 2.5, gravity = Vector3(0, 1.5, 0), lifetime = 0.8,
	},
	"lava": {
		color = Color(1.0, 0.45, 0.1), amount = 32, size = 0.12,
		velocity = 5.0, gravity = Vector3(0, -6.0, 0), lifetime = 0.6,
	},
	"curacion": {
		color = Color(0.4, 1.0, 0.55), amount = 14, size = 0.09,
		velocity = 1.2, gravity = Vector3(0, 2.0, 0), lifetime = 0.7,
	},
}

var _pool: Array[GPUParticles3D] = []
var _materials := {}  # preset (String) → ParticleProcessMaterial
var _meshes := {}  # preset (String) → QuadMesh


func _ready() -> void:
	for preset_name: String in PRESETS:
		_materials[preset_name] = _build_material(PRESETS[preset_name])
		_meshes[preset_name] = _build_mesh(PRESETS[preset_name])
	for i in POOL_SIZE:
		var particles := GPUParticles3D.new()
		particles.one_shot = true
		particles.emitting = false
		particles.explosiveness = 1.0
		add_child(particles)
		_pool.append(particles)


## Ráfaga one-shot en una posición del mundo.
func burst(preset_name: String, position: Vector3) -> void:
	if not PRESETS.has(preset_name):
		return
	var particles := _next_free()
	var preset: Dictionary = PRESETS[preset_name]
	particles.process_material = _materials[preset_name]
	particles.draw_pass_1 = _meshes[preset_name]
	particles.amount = preset.amount
	particles.lifetime = preset.lifetime
	particles.global_position = position
	particles.restart()


## Emisor persistente para el trail del arma: emite mientras `emitting`
## sea true (el jugador lo enciende en los frames activos del ataque).
func create_trail(parent: Node3D, color := Color(0.9, 0.95, 1.0, 0.6)) -> GPUParticles3D:
	var trail := GPUParticles3D.new()
	trail.emitting = false
	trail.amount = 40
	trail.lifetime = 0.25
	trail.local_coords = false
	trail.process_material = _build_material({
		color = color, size = 0.07, velocity = 0.1,
		gravity = Vector3.ZERO, lifetime = 0.25,
	})
	trail.draw_pass_1 = _build_mesh({ size = 0.07, color = color })
	parent.add_child(trail)
	return trail


## Brasas ambientales (rewe): emisor en bucle, lento y ascendente.
func create_embers(parent: Node3D, offset := Vector3.ZERO) -> GPUParticles3D:
	var embers := GPUParticles3D.new()
	embers.amount = 12
	embers.lifetime = 2.5
	embers.preprocess = 2.0
	var mat := _build_material({
		color = Color(1.0, 0.55, 0.15), size = 0.05, velocity = 0.5,
		gravity = Vector3(0, 0.6, 0), lifetime = 2.5,
	})
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = 0.5
	embers.process_material = mat
	embers.draw_pass_1 = _build_mesh({ size = 0.05, color = Color(1.0, 0.55, 0.15) })
	embers.position = offset
	parent.add_child(embers)
	return embers


# ── Construcción de recursos ─────────────────────────────────


func _build_material(preset: Dictionary) -> ParticleProcessMaterial:
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 60.0
	var velocity: float = preset.get("velocity", 2.0)
	mat.initial_velocity_min = velocity * 0.5
	mat.initial_velocity_max = velocity
	mat.gravity = preset.get("gravity", Vector3.ZERO)
	mat.scale_min = 0.7
	mat.scale_max = 1.3
	# Se desvanecen al final de la vida
	var ramp := Gradient.new()
	var color: Color = preset.get("color", Color.WHITE)
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	var ramp_texture := GradientTexture1D.new()
	ramp_texture.gradient = ramp
	mat.color_ramp = ramp_texture
	return mat


func _build_mesh(preset: Dictionary) -> QuadMesh:
	var quad := QuadMesh.new()
	var size: float = preset.get("size", 0.08)
	quad.size = Vector2(size, size)
	var draw_mat := StandardMaterial3D.new()
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw_mat.vertex_color_use_as_albedo = true
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var color: Color = preset.get("color", Color.WHITE)
	draw_mat.emission_enabled = true
	draw_mat.emission = Color(color.r, color.g, color.b)
	draw_mat.emission_energy_multiplier = 1.5
	quad.material = draw_mat
	return quad


func _next_free() -> GPUParticles3D:
	for particles in _pool:
		if not particles.emitting:
			return particles
	return _pool[0]
