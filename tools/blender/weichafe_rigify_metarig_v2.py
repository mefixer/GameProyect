"""
Paso 1 (v2) del pipeline de animación del weichafe: añadir un **metarig humano**
(Rigify) alineado a la altura real de `HumanoBase` en `weichafe_vestido_v2.blend`
— reemplaza a `rig_weichafe_metarig.py`, que apuntaba a `WeichafeBody` en el
`.blend` viejo (`weichafe_base.blend`), ya movido a la colección `_legacy_sin_usar`.

NO modifica el .blend original: guarda en un archivo aparte (`weichafe_rigify_wip.blend`)
para iterar el ajuste del metarig sin ensuciar la fuente principal.

Uso (headless):
  blender -b assets/models/weichafe/blender_source/weichafe_vestido_v2.blend \
          --python tools/blender/weichafe_rigify_metarig_v2.py -- <salida.blend>

Uso (vía BlenderMCP, con el .blend ya abierto): pega el cuerpo de este script en
execute_blender_code (sin la parte de guardado) para hacerlo en vivo y con captura.
"""
import bpy, sys, addon_utils

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else ""

for _name in ("rigify", "bl_ext.blender_org.rigify", "bl_ext.system.rigify"):
	try:
		addon_utils.enable(_name, default_set=True)
		break
	except Exception:
		pass

body = bpy.data.objects.get("HumanoBase")
assert body, "No se encontró el objeto 'HumanoBase'"
target_h = body.dimensions.z  # altura real del mesh vestido (medida, no asumida)

# 1) añadir metarig humano estándar
bpy.ops.object.armature_human_metarig_add()
meta = bpy.context.active_object
meta.name = "WeichafeMetarig"

# 2) escalar el metarig (por defecto ~1.8 m) a la altura real del weichafe
cur_h = meta.dimensions.z
s = target_h / cur_h if cur_h else 1.0
meta.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)
meta.location = (0.0, 0.0, 0.0)   # ambos en el origen

print(f"METARIG_ADDED altura_mesh={target_h:.4f}m escala={s:.4f} huesos={len(meta.data.bones)}")

# 3) (opcional) guardar a un archivo aparte
if OUT:
	bpy.ops.wm.save_as_mainfile(filepath=OUT)
	print("SAVED", OUT)

# --- Próximos pasos (se hacen mejor EN VIVO por BlenderMCP, con captura) ---
#  a) Entrar a Edit Mode del metarig y encajar los huesos al mesh (cadera, columna,
#     hombros, codos, muñecas, rodillas, tobillos), usando WeichafeRig (el rig
#     gemelo de proporciones correctas, en _legacy_sin_usar) como referencia.
#  b) bpy.ops.pose.rigify_generate()  -> genera el rig DEF-/ORG- definitivo.
#  c) Append del rig generado a weichafe_vestido_v2.blend y skinning automático.
