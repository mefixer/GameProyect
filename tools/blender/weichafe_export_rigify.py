"""
Fase 7 del pipeline de animación del weichafe: exportar el mesh + ropa + rig
Rigify (con Idle/Walk) de `weichafe_vestido_v2.blend` a un .glb standalone.

Excluye explícitamente todo lo que quedó en la colección `_legacy_sin_usar`
(WeichafeBody, WeichafeRig, WeichafeRig.001, Cuerpo, Pelo, PeloBase, Botas)
y los objetos auxiliares de la escena (Area/Sun/Sun.001, luces de referencia).

Uso (headless):
  blender -b assets/models/weichafe/blender_source/weichafe_vestido_v2.blend \
          --python tools/blender/weichafe_export_rigify.py -- <salida.glb>
"""
import bpy, sys

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT_GLB = argv[0] if argv else "/tmp/weichafe_rigify_v1.glb"

LEGACY_COLLECTION = "_legacy_sin_usar"
EXPORT_OBJECTS = [
    "HumanoBase", "RIG-WeichafeMetarig",
    "Taparrabos", "Trariwe", "Trarilonko", "Makun", "Collar", "Faja", "Plumas",
    "Mocasines.L", "Mocasines.R", "Polainas.L", "Polainas.R", "Pelo.001",
]

legacy = bpy.data.collections.get(LEGACY_COLLECTION)
legacy_names = {o.name for o in legacy.objects} if legacy else set()

missing = [n for n in EXPORT_OBJECTS if n not in bpy.data.objects]
assert not missing, f"Faltan objetos esperados: {missing}"

bpy.ops.object.select_all(action='DESELECT')
for name in EXPORT_OBJECTS:
    o = bpy.data.objects[name]
    assert o.name not in legacy_names, f"{name} está en _legacy_sin_usar, no se exporta"
    o.hide_set(False)
    o.hide_viewport = False
    o.select_set(True)

bpy.context.view_layer.objects.active = bpy.data.objects["RIG-WeichafeMetarig"]

bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format='GLB',
    use_selection=True,
    export_apply=True,    # hornea Subsurf/etc; el exportador excluye el Armature del bake (queda como skin)
    export_animations=True,
    export_skins=True,
    export_yup=True,
    export_image_format='AUTO',
)
print("EXPORTED", OUT_GLB)
