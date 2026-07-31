@tool
extends EditorPlugin

const OllamaDockScript := preload("res://addons/ollama_content_gen/ollama_dock.gd")

var _dock: Control


func _enter_tree() -> void:
	_dock = OllamaDockScript.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, _dock)


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.queue_free()
