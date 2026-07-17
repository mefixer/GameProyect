extends Node
## Autoload "AudioManager": SFX posicional (pool de AudioStreamPlayer3D),
## sonidos de UI (2D) y música con crossfade entre dos reproductores.

const FOOTSTEPS := {
	"pasto": [
		preload("res://assets/audio/sfx/footsteps/pasto_0.ogg"),
		preload("res://assets/audio/sfx/footsteps/pasto_1.ogg"),
		preload("res://assets/audio/sfx/footsteps/pasto_2.ogg"),
		preload("res://assets/audio/sfx/footsteps/pasto_3.ogg"),
		preload("res://assets/audio/sfx/footsteps/pasto_4.ogg"),
	],
	"piedra": [
		preload("res://assets/audio/sfx/footsteps/piedra_0.ogg"),
		preload("res://assets/audio/sfx/footsteps/piedra_1.ogg"),
		preload("res://assets/audio/sfx/footsteps/piedra_2.ogg"),
		preload("res://assets/audio/sfx/footsteps/piedra_3.ogg"),
		preload("res://assets/audio/sfx/footsteps/piedra_4.ogg"),
	],
	"madera": [
		preload("res://assets/audio/sfx/footsteps/madera_0.ogg"),
		preload("res://assets/audio/sfx/footsteps/madera_1.ogg"),
		preload("res://assets/audio/sfx/footsteps/madera_2.ogg"),
		preload("res://assets/audio/sfx/footsteps/madera_3.ogg"),
		preload("res://assets/audio/sfx/footsteps/madera_4.ogg"),
	],
}
const DEFAULT_SURFACE := "pasto"

const COMBAT := {
	"golpe_ligero": [
		preload("res://assets/audio/sfx/combat/golpe_ligero_1.ogg"),
		preload("res://assets/audio/sfx/combat/golpe_ligero_2.ogg"),
	],
	"golpe_fuerte": [
		preload("res://assets/audio/sfx/combat/golpe_fuerte_1.ogg"),
		preload("res://assets/audio/sfx/combat/golpe_fuerte_2.ogg"),
	],
	"parry": preload("res://assets/audio/sfx/combat/parry.ogg"),
	"bloqueo": preload("res://assets/audio/sfx/combat/bloqueo.ogg"),
	"esquiva": preload("res://assets/audio/sfx/combat/esquiva.ogg"),
	"jugador_dano": preload("res://assets/audio/sfx/combat/jugador_dano.ogg"),
	"jefe_impacto": preload("res://assets/audio/sfx/combat/jefe_impacto.ogg"),
}

const UI_SOUNDS := {
	"click": preload("res://assets/audio/sfx/ui/click.ogg"),
	"hover": preload("res://assets/audio/sfx/ui/hover.ogg"),
}

const POOL_SIZE := 8
const MUSIC_FADE := 1.5

var _pool: Array[AudioStreamPlayer3D] = []
var _pool_index := 0
var _ui_player: AudioStreamPlayer
var _music_players: Array[AudioStreamPlayer] = []
var _music_active := 0
var _music_tween: Tween


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		player.bus = "SFX"
		player.max_distance = 40.0
		add_child(player)
		_pool.append(player)
	_ui_player = AudioStreamPlayer.new()
	_ui_player.bus = "UI"
	add_child(_ui_player)
	for i in 2:
		var music := AudioStreamPlayer.new()
		music.bus = "Music"
		music.volume_db = -80.0
		add_child(music)
		_music_players.append(music)


## Superficie según el grupo del StaticBody bajo el jugador ("surface_<tipo>");
## sin grupo reconocido, cae en pasto (todo el bosque hoy es un único suelo).
func play_footstep(surface: String, position: Vector3) -> void:
	var variants: Array = FOOTSTEPS.get(surface, FOOTSTEPS[DEFAULT_SURFACE])
	_play_at(variants.pick_random(), position, -8.0)


func play_combat(sound_name: String, position: Vector3) -> void:
	var entry: Variant = COMBAT.get(sound_name)
	if entry == null:
		return
	var stream: AudioStream = entry.pick_random() if entry is Array else entry
	_play_at(stream, position)


func play_ui(sound_name: String) -> void:
	var stream: AudioStream = UI_SOUNDS.get(sound_name)
	if stream == null:
		return
	_ui_player.stream = stream
	_ui_player.pitch_scale = randf_range(0.97, 1.03)
	_ui_player.play()


func play_music(stream: AudioStream, fade := MUSIC_FADE) -> void:
	if stream == null:
		return
	var current := _music_players[_music_active]
	if current.stream == stream and current.playing:
		return
	var next_index := 1 - _music_active
	var next := _music_players[next_index]
	next.stream = stream
	next.volume_db = -80.0
	next.play()
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(next, "volume_db", 0.0, fade)
	_music_tween.tween_property(current, "volume_db", -80.0, fade)
	var old_player := current
	_music_tween.chain().tween_callback(old_player.stop)
	_music_active = next_index


func stop_music(fade := MUSIC_FADE) -> void:
	var current := _music_players[_music_active]
	if not current.playing:
		return
	if _music_tween:
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(current, "volume_db", -80.0, fade)
	_music_tween.tween_callback(current.stop)


func _play_at(stream: AudioStream, position: Vector3, volume_db := 0.0) -> void:
	if stream == null:
		return
	var player := _pool[_pool_index]
	_pool_index = (_pool_index + 1) % _pool.size()
	player.stream = stream
	player.global_position = position
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.94, 1.06)
	player.play()
