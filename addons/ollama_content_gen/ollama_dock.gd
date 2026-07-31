@tool
extends VBoxContainer
## Panel de editor para generar diálogos, lore y descripciones de ítems con
## Llama 3.1 8B corriendo en Ollama (localhost:11434).
## Requisito: `ollama serve` activo (systemd: `systemctl status ollama`).

const OllamaClientScript := preload("res://scripts/autoload/ollama_client.gd")

var _client
var _prompt_edit: TextEdit
var _output_edit: TextEdit
var _generate_button: Button
var _status_label: Label


func _ready() -> void:
	name = "Ollama"
	custom_minimum_size = Vector2(280, 0)

	var title := Label.new()
	title.text = "Generador de contenido\n(Ollama · llama3.1:8b)"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(title)

	_prompt_edit = TextEdit.new()
	_prompt_edit.placeholder_text = "Ej: diálogo de un weichafe herido que advierte sobre el jefe del bosque"
	_prompt_edit.custom_minimum_size = Vector2(0, 100)
	_prompt_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(_prompt_edit)

	_generate_button = Button.new()
	_generate_button.text = "Generar"
	_generate_button.pressed.connect(_on_generate_pressed)
	add_child(_generate_button)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	add_child(_status_label)

	_output_edit = TextEdit.new()
	_output_edit.editable = false
	_output_edit.custom_minimum_size = Vector2(0, 150)
	_output_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	add_child(_output_edit)

	_client = OllamaClientScript.new()
	add_child(_client)
	_client.generation_finished.connect(_on_generation_finished)
	_client.generation_failed.connect(_on_generation_failed)


func _on_generate_pressed() -> void:
	var prompt := _prompt_edit.text.strip_edges()
	if prompt.is_empty():
		return
	_status_label.text = "Generando..."
	_generate_button.disabled = true
	_client.generate(prompt, OllamaClientScript.LORE_SYSTEM_PROMPT)


func _on_generation_finished(text: String) -> void:
	_output_edit.text = text
	_status_label.text = "Listo."
	_generate_button.disabled = false


func _on_generation_failed(error_message: String) -> void:
	_status_label.text = error_message
	_generate_button.disabled = false
