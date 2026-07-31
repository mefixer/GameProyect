extends Node
## Autoload "OllamaClient": genera texto (diálogos, lore, descripciones de ítems)
## llamando al servidor local de Ollama (http://127.0.0.1:11434).
## Requisito: `ollama serve` corriendo (ya está como servicio systemd) y el
## modelo `llama3.1:8b` descargado (`ollama pull llama3.1:8b`).
##
## Uso básico:
##   OllamaClient.generation_finished.connect(func(text): print(text))
##   OllamaClient.generate("Escribe el saludo de un weichafe cansado de la batalla")

signal generation_finished(text: String)
signal generation_failed(error_message: String)

const API_URL := "http://127.0.0.1:11434/api/generate"
const MODEL := "llama3.1:8b"

const LORE_SYSTEM_PROMPT := "Eres un narrador de un videojuego souls-like ambientado en una " \
		+ "reinterpretación oscura de la cultura mapuche. Respondes siempre en español, " \
		+ "en tono serio y evocador, sin salirte del personaje ni añadir explicaciones fuera de la respuesta."

var _http: HTTPRequest


func _ready() -> void:
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)


## Llamada genérica: prompt libre + system prompt opcional.
func generate(prompt: String, system_prompt: String = "") -> void:
	var body := {
		"model": MODEL,
		"prompt": prompt,
		"system": system_prompt,
		"stream": false,
	}
	var err := _http.request(
			API_URL,
			["Content-Type: application/json"],
			HTTPClient.METHOD_POST,
			JSON.stringify(body)
	)
	if err != OK:
		generation_failed.emit("No se pudo conectar con Ollama (¿está corriendo 'ollama serve'?). Código: %d" % err)


## Diálogo de un NPC dada su personalidad y la situación actual.
func generate_npc_dialogue(npc_name: String, personality: String, situation: String) -> void:
	var prompt := (
			"Personaje: %s.\nPersonalidad: %s.\nSituación: %s.\n" % [npc_name, personality, situation]
			+ "Escribe UNA línea de diálogo breve (máx. 2 frases) que diría este personaje."
	)
	generate(prompt, LORE_SYSTEM_PROMPT)


## Descripción/lore de un ítem del juego, estilo texto de inventario souls-like.
func generate_item_lore(item_name: String, hints: String) -> void:
	var prompt := (
			"Ítem: %s.\nPistas de contexto: %s.\n" % [item_name, hints]
			+ "Escribe una descripción de lore breve (2-4 frases) para el ítem."
	)
	generate(prompt, LORE_SYSTEM_PROMPT)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		generation_failed.emit("Ollama respondió con error (código HTTP %d)." % response_code)
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY or not parsed.has("response"):
		generation_failed.emit("Respuesta de Ollama con formato inesperado.")
		return
	generation_finished.emit(String(parsed["response"]).strip_edges())
