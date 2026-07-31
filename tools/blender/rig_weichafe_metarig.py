"""
Paso 1 del pipeline de animación del weichafe: añadir un **metarig humano** (Rigify)
alineado a la altura del modelo. Deja el modelo listo para: ajustar huesos al mesh →
generar el rig Rigify → pesar (skinning) → importar animaciones (Mixamo/Quaternius) y
**retargetear** al esqueleto.

NO modifica el .blend original: guarda en un archivo aparte.

Uso (headless):
  blender -b assets/models/weichafe/blender_source/weichafe_base.blend \
          --python tools/blender/rig_weichafe_metarig.py -- <salida.blend>

Uso (vía BlenderMCP, con Blender abierto): pega el cuerpo de este script en
execute_blender_code (sin la parte de guardado) para hacerlo en vivo y con captura.
"""
import bpy, sys, addon_utils

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else ""

# Rigify trae el operador del metarig humano. En Blender 5.x es una "extensión"
# (no un addon llamado 'rigify'), y normalmente ya viene activa. Lo intentamos por
# varios nombres posibles, sin fallar si no aplica: el operador suele estar disponible igual.
for _name in ("rigify", "bl_ext.blender_org.rigify", "bl_ext.system.rigify"):
    try:
        addon_utils.enable(_name, default_set=True)
        break
    except Exception:
        pass

body = bpy.data.objects.get("WeichafeBody")
assert body, "No se encontró el objeto 'WeichafeBody'"
target_h = body.dimensions.z  # altura real del mesh (~1.67 m)

# 1) añadir metarig humano estándar
bpy.ops.object.armature_human_metarig_add()
meta = bpy.context.active_object
meta.name = "WeichafeMetarig"

# 2) escalar el metarig (por defecto ~1.8 m) a la altura del weichafe
cur_h = meta.dimensions.z
s = target_h / cur_h if cur_h else 1.0
meta.scale = (s, s, s)
bpy.ops.object.transform_apply(scale=True)
meta.location = (0.0, 0.0, 0.0)   # ambos en el origen

print(f"METARIG_ADDED altura_mesh={target_h:.2f}m escala={s:.3f} huesos={len(meta.data.bones)}")

# 3) (opcional) guardar a un archivo aparte
if OUT:
    bpy.ops.wm.save_as_mainfile(filepath=OUT)
    print("SAVED", OUT)

# --- Próximos pasos (se hacen mejor EN VIVO por BlenderMCP, con captura) ---
#  a) Entrar a Edit Mode del metarig y encajar los huesos al mesh (hombros, codos,
#     rodillas, columna) — esto necesita ojo, por eso conviene hacerlo interactivo.
#  b) bpy.ops.pose.rigify_generate()  -> genera el rig de control definitivo.
#  c) Seleccionar mesh + rig -> bpy.ops.object.parent_set(type='ARMATURE_AUTO') (pesos automáticos).
#  d) Importar un .glb/.fbx de animación (Mixamo/Quaternius) y retargetear al rig.
