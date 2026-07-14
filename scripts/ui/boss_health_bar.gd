extends CanvasLayer
## Barra de vida de jefe: oculta hasta que el jefe despierta; se conecta
## a sus señales de vida y fase por código desde el disparador de la arena.

@onready var panel: Control = %Panel
@onready var name_label: Label = %BossName
@onready var health_bar: ProgressBar = %HealthBar
@onready var phase_label: Label = %PhaseLabel

var _boss: Node = null


func _ready() -> void:
	panel.visible = false


func track(boss: Node, display_name: String) -> void:
	_boss = boss
	name_label.text = display_name
	panel.visible = true
	boss.health.health_changed.connect(_on_health_changed)
	boss.health.died.connect(_on_boss_died)
	boss.phase_changed.connect(_on_phase_changed)
	_on_health_changed(boss.health.health, boss.health.max_health)


func _on_health_changed(current: float, max_value: float) -> void:
	health_bar.max_value = max_value
	health_bar.value = current


func _on_phase_changed(phase: int) -> void:
	phase_label.text = "Fase %d" % phase
	phase_label.visible = true


func _on_boss_died() -> void:
	create_tween().tween_property(panel, "modulate:a", 0.0, 1.0) \
			.set_delay(1.0).finished.connect(func() -> void: panel.visible = false)
