import bpy
import json
import textwrap
import threading
import urllib.request
import urllib.error

bl_info = {
    "name": "Generador de Contenido (Ollama)",
    "author": "Proyecto Soulslike 3D",
    "version": (1, 0, 0),
    "blender": (4, 2, 0),
    "location": "View3D > Sidebar > Ollama",
    "description": "Genera nombres, descripciones/lore y prompts de textura con Llama 3.1 8B local via Ollama.",
    "category": "3D View",
}

OLLAMA_API_URL = "http://127.0.0.1:11434/api/generate"
OLLAMA_MODEL = "llama3.1:8b"

LORE_SYSTEM_PROMPT = (
    "Eres un narrador de un videojuego souls-like ambientado en una reinterpretacion "
    "oscura de la cultura mapuche. Respondes siempre en espanol, en tono serio y "
    "evocador, sin anadir explicaciones fuera de la respuesta."
)

SYSTEM_PROMPTS = {
    "NOMBRE": LORE_SYSTEM_PROMPT
    + " Responde UNICAMENTE con un nombre corto (2-4 palabras), sin comillas ni texto adicional.",
    "DESCRIPCION": LORE_SYSTEM_PROMPT
    + " Escribe una descripcion breve (2-4 frases), estilo texto de lore de inventario.",
    "TEXTURA": (
        "You write dense, comma-separated keyword prompts (style, materials, "
        "lighting) for a texture/image generator. Reply with ONE line only, no explanations."
    ),
}

_lock = threading.Lock()
_result = {"status": "idle", "text": ""}


def _call_ollama(prompt, system_prompt):
    body = json.dumps(
        {
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "system": system_prompt,
            "stream": False,
        }
    ).encode("utf-8")
    req = urllib.request.Request(
        OLLAMA_API_URL,
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=120) as response:
            data = json.loads(response.read().decode("utf-8"))
        text = data.get("response", "").strip()
        with _lock:
            _result["status"] = "done"
            _result["text"] = text
    except urllib.error.URLError as exc:
        with _lock:
            _result["status"] = "error"
            _result["text"] = "No se pudo conectar con Ollama (¿esta corriendo 'ollama serve'?): %s" % exc
    except Exception as exc:  # noqa: BLE001 - se reporta cualquier fallo en el panel
        with _lock:
            _result["status"] = "error"
            _result["text"] = "Error inesperado: %s" % exc


def _poll_result():
    scene = bpy.context.scene
    if scene is None:
        return 0.3
    with _lock:
        status = _result["status"]
        text = _result["text"]
    if status == "done":
        scene.ollama_output = text
        scene.ollama_status = "Listo."
        with _lock:
            _result["status"] = "idle"
        return None
    if status == "error":
        scene.ollama_output = ""
        scene.ollama_status = text
        with _lock:
            _result["status"] = "idle"
        return None
    return 0.3


class OLLAMA_OT_generate(bpy.types.Operator):
    bl_idname = "ollama.generate_content"
    bl_label = "Generar"
    bl_description = "Genera contenido con Llama 3.1 8B (Ollama local)"

    def execute(self, context):
        scene = context.scene
        prompt = scene.ollama_prompt.strip()
        if not prompt:
            self.report({"WARNING"}, "Escribe un prompt primero.")
            return {"CANCELLED"}
        system_prompt = SYSTEM_PROMPTS.get(scene.ollama_content_type, LORE_SYSTEM_PROMPT)
        scene.ollama_status = "Generando..."
        scene.ollama_output = ""
        with _lock:
            _result["status"] = "running"
            _result["text"] = ""
        threading.Thread(target=_call_ollama, args=(prompt, system_prompt), daemon=True).start()
        bpy.app.timers.register(_poll_result, first_interval=0.3)
        return {"FINISHED"}


class OLLAMA_OT_copy_output(bpy.types.Operator):
    bl_idname = "ollama.copy_output"
    bl_label = "Copiar"
    bl_description = "Copia el texto generado al portapapeles"

    def execute(self, context):
        context.window_manager.clipboard = context.scene.ollama_output
        self.report({"INFO"}, "Copiado al portapapeles.")
        return {"FINISHED"}


class OLLAMA_PT_panel(bpy.types.Panel):
    bl_label = "Generador de Contenido (Ollama)"
    bl_idname = "OLLAMA_PT_panel"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "Ollama"

    def draw(self, context):
        layout = self.layout
        scene = context.scene

        layout.prop(scene, "ollama_content_type", text="Tipo")
        layout.prop(scene, "ollama_prompt", text="")
        layout.operator("ollama.generate_content", icon="PLAY")

        if scene.ollama_status:
            layout.label(text=scene.ollama_status)

        if scene.ollama_output:
            box = layout.box()
            col = box.column(align=True)
            for line in textwrap.wrap(scene.ollama_output, width=40) or [""]:
                col.label(text=line)
            layout.operator("ollama.copy_output", icon="COPYDOWN")


CLASSES = (
    OLLAMA_OT_generate,
    OLLAMA_OT_copy_output,
    OLLAMA_PT_panel,
)


def register():
    for cls in CLASSES:
        bpy.utils.register_class(cls)

    bpy.types.Scene.ollama_content_type = bpy.props.EnumProperty(
        name="Tipo de contenido",
        items=[
            ("NOMBRE", "Nombre", "Nombre corto para un objeto/personaje/item"),
            ("DESCRIPCION", "Descripcion / Lore", "Descripcion breve estilo lore"),
            ("TEXTURA", "Prompt de textura", "Prompt en ingles para generador de texturas"),
        ],
        default="DESCRIPCION",
    )
    bpy.types.Scene.ollama_prompt = bpy.props.StringProperty(
        name="Prompt",
        description="Describe que queres generar",
        default="",
    )
    bpy.types.Scene.ollama_output = bpy.props.StringProperty(name="Resultado", default="")
    bpy.types.Scene.ollama_status = bpy.props.StringProperty(name="Estado", default="")


def unregister():
    del bpy.types.Scene.ollama_status
    del bpy.types.Scene.ollama_output
    del bpy.types.Scene.ollama_prompt
    del bpy.types.Scene.ollama_content_type

    for cls in reversed(CLASSES):
        bpy.utils.unregister_class(cls)


if __name__ == "__main__":
    register()
