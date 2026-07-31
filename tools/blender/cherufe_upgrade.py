"""
Mejora del Cherufe: pipeline procedural -> baked PBR.

Toma la malla base del Cherufe (roca/lava/ojos, ~14k tris) y le aplica:
  - un displace sutil para romper la superficie "de plastilina" y darle silueta rocosa,
  - materiales procedurales de basalto con una red de grietas de magma emisivas
    que recorre todo el cuerpo (no solo los parches sueltos),
  - horneado (bake) de los materiales procedurales a mapas PBR 2K
    (albedo, normal, rugosidad, emision) para que Godot use PBR real.

Uso:
  blender -b <blend_base> --python cherufe_upgrade.py -- <out_glb> <tex_dir> [<out_blend>]

Reproducible: no toca el .blend original salvo que pases <out_blend>.
"""
import bpy, sys, os, math
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
OUT_GLB = argv[0]
TEX_DIR = argv[1]
OUT_BLEND = argv[2] if len(argv) > 2 else ""
os.makedirs(TEX_DIR, exist_ok=True)
RES = 2048

obj = bpy.data.objects['CherufeBody']
me = obj.data
bpy.context.view_layer.objects.active = obj
obj.select_set(True)


# ---------------------------------------------------------------- helpers
def new_img(name, colorspace, res=RES):
    img = bpy.data.images.new(name, res, res, alpha=False, float_buffer=False)
    img.colorspace_settings.name = colorspace
    return img


def link(nt, a, ao, b, bi):
    nt.links.new(a.outputs[ao], b.inputs[bi])


def ramp(nt, elements):
    """ColorRamp con paradas (pos, (r,g,b,1))."""
    n = nt.nodes.new('ShaderNodeValToRGB')
    cr = n.color_ramp
    while len(cr.elements) > 1:
        cr.elements.remove(cr.elements[-1])
    cr.elements[0].position = elements[0][0]
    cr.elements[0].color = elements[0][1]
    for pos, col in elements[1:]:
        e = cr.elements.new(pos)
        e.color = col
    return n


# ---------------------------------------------------------------- 1) geometria
# Displace sutil para romper la superficie lisa (silueta rocosa).
tex = bpy.data.textures.new("rock_disp", 'VORONOI')
tex.noise_scale = 0.35
tex.contrast = 1.4
d = obj.modifiers.new("rock_disp", 'DISPLACE')
d.texture = tex
d.texture_coords = 'GLOBAL'
d.strength = 0.11
d.mid_level = 0.5

# Segundo displace de ruido fino para grano de roca en la silueta.
tex2 = bpy.data.textures.new("rock_grain", 'MUSGRAVE') if 'MUSGRAVE' in \
    [t for t in ('MUSGRAVE',)] else None
tn = bpy.data.textures.new("rock_grain", 'CLOUDS')
tn.noise_scale = 0.12
d2 = obj.modifiers.new("rock_grain", 'DISPLACE')
d2.texture = tn
d2.texture_coords = 'GLOBAL'
d2.strength = 0.04
d2.mid_level = 0.5

bpy.ops.object.modifier_apply(modifier=d.name)
bpy.ops.object.modifier_apply(modifier=d2.name)
bpy.ops.object.shade_smooth()

# UV limpia y sin solapes para hornear (Smart UV Project).
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=0.02)
bpy.ops.object.mode_set(mode='OBJECT')


# ---------------------------------------------------------------- 2) materiales procedurales
def build_rock(mat):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    link(nt, bsdf, 'BSDF', out, 'Surface')
    coord = nt.nodes.new('ShaderNodeTexCoord')

    # --- basalto: celdas de roca oscura con variacion
    volc = nt.nodes.new('ShaderNodeTexVoronoi')
    volc.inputs['Scale'].default_value = 7.0
    volc.feature = 'F1'
    link(nt, coord, 'Object', volc, 'Vector')
    rock_ramp = ramp(nt, [
        (0.0, (0.020, 0.018, 0.017, 1)),
        (0.5, (0.045, 0.040, 0.037, 1)),
        (1.0, (0.085, 0.070, 0.060, 1)),
    ])
    link(nt, volc, 'Distance', rock_ramp, 'Fac')

    grain = nt.nodes.new('ShaderNodeTexNoise')
    grain.inputs['Scale'].default_value = 22.0
    grain.inputs['Detail'].default_value = 8.0
    link(nt, coord, 'Object', grain, 'Vector')
    grain_mul = nt.nodes.new('ShaderNodeMixRGB')
    grain_mul.blend_type = 'MULTIPLY'
    grain_mul.inputs['Fac'].default_value = 0.35
    link(nt, rock_ramp, 'Color', grain_mul, 'Color1')
    link(nt, grain, 'Fac', grain_mul, 'Color2')

    # --- red de grietas (Voronoi distance-to-edge) para el magma
    crack = nt.nodes.new('ShaderNodeTexVoronoi')
    crack.inputs['Scale'].default_value = 5.5
    crack.feature = 'DISTANCE_TO_EDGE'
    link(nt, coord, 'Object', crack, 'Vector')
    crack_mask = ramp(nt, [   # 1.0 justo en la linea de la grieta
        (0.00, (1, 1, 1, 1)),
        (0.045, (1, 1, 1, 1)),
        (0.09, (0, 0, 0, 1)),
    ])
    link(nt, crack, 'Distance', crack_mask, 'Fac')
    # rompe las grietas para que no sean continuas
    crackbreak = nt.nodes.new('ShaderNodeTexNoise')
    crackbreak.inputs['Scale'].default_value = 3.0
    link(nt, coord, 'Object', crackbreak, 'Vector')
    cb_ramp = ramp(nt, [(0.35, (0, 0, 0, 1)), (0.55, (1, 1, 1, 1))])
    link(nt, crackbreak, 'Fac', cb_ramp, 'Fac')
    crack_gate = nt.nodes.new('ShaderNodeMixRGB')
    crack_gate.blend_type = 'MULTIPLY'
    crack_gate.inputs['Fac'].default_value = 1.0
    link(nt, crack_mask, 'Color', crack_gate, 'Color1')
    link(nt, cb_ramp, 'Color', crack_gate, 'Color2')

    # albedo: roca, con borde de grieta calentado al rojo
    heat_edge = nt.nodes.new('ShaderNodeMixRGB')
    heat_edge.blend_type = 'MIX'
    heat_edge.inputs['Color2'].default_value = (0.65, 0.12, 0.02, 1)
    link(nt, crack_gate, 'Color', heat_edge, 'Fac')
    link(nt, grain_mul, 'Color', heat_edge, 'Color1')
    link(nt, heat_edge, 'Color', bsdf, 'Base Color')

    # rugosidad: roca muy rugosa, un poco pulida en algunas placas
    rgh = ramp(nt, [(0.0, (0.95, 0.95, 0.95, 1)), (1.0, (0.72, 0.72, 0.72, 1))])
    link(nt, grain, 'Fac', rgh, 'Fac')
    link(nt, rgh, 'Color', bsdf, 'Roughness')

    # normal: bump combinando placas + grano
    bumpnoise = nt.nodes.new('ShaderNodeTexNoise')
    bumpnoise.inputs['Scale'].default_value = 40.0
    bumpnoise.inputs['Detail'].default_value = 10.0
    link(nt, coord, 'Object', bumpnoise, 'Vector')
    bump1 = nt.nodes.new('ShaderNodeBump')
    bump1.inputs['Strength'].default_value = 0.25
    link(nt, bumpnoise, 'Fac', bump1, 'Height')
    bump2 = nt.nodes.new('ShaderNodeBump')
    bump2.inputs['Strength'].default_value = 0.5
    link(nt, volc, 'Distance', bump2, 'Height')
    link(nt, bump1, 'Normal', bump2, 'Normal')
    link(nt, bump2, 'Normal', bsdf, 'Normal')

    # emision: magma en las grietas, gradiente naranja->amarillo
    hotvar = nt.nodes.new('ShaderNodeTexNoise')
    hotvar.inputs['Scale'].default_value = 4.0
    link(nt, coord, 'Object', hotvar, 'Vector')
    hot_ramp = ramp(nt, [
        (0.0, (1.0, 0.18, 0.02, 1)),
        (0.6, (1.0, 0.42, 0.05, 1)),
        (1.0, (1.0, 0.72, 0.15, 1)),
    ])
    link(nt, hotvar, 'Fac', hot_ramp, 'Fac')
    emis = nt.nodes.new('ShaderNodeMixRGB')
    emis.blend_type = 'MULTIPLY'
    emis.inputs['Fac'].default_value = 1.0
    link(nt, hot_ramp, 'Color', emis, 'Color1')
    link(nt, crack_gate, 'Color', emis, 'Color2')
    link(nt, emis, 'Color', bsdf, 'Emission Color')
    bsdf.inputs['Emission Strength'].default_value = 1.0
    bsdf.inputs['Metallic'].default_value = 0.0
    return bsdf


def build_lava(mat):
    """Los parches de lava geometricos: crust oscura con magma brillante."""
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    link(nt, bsdf, 'BSDF', out, 'Surface')
    coord = nt.nodes.new('ShaderNodeTexCoord')
    flow = nt.nodes.new('ShaderNodeTexNoise')
    flow.inputs['Scale'].default_value = 6.0
    flow.inputs['Detail'].default_value = 8.0
    link(nt, coord, 'Object', flow, 'Vector')
    crust = ramp(nt, [   # crust negra + vetas incandescentes
        (0.30, (0.02, 0.01, 0.01, 1)),
        (0.52, (0.05, 0.02, 0.01, 1)),
        (0.60, (1.0, 0.35, 0.03, 1)),
        (1.0, (1.0, 0.80, 0.25, 1)),
    ])
    link(nt, flow, 'Fac', crust, 'Fac')
    link(nt, crust, 'Color', bsdf, 'Base Color')
    # emision solo en la parte incandescente
    emit_mask = ramp(nt, [(0.55, (0, 0, 0, 1)), (0.62, (1, 1, 1, 1))])
    link(nt, flow, 'Fac', emit_mask, 'Fac')
    ecol = nt.nodes.new('ShaderNodeMixRGB')
    ecol.blend_type = 'MULTIPLY'
    ecol.inputs['Fac'].default_value = 1.0
    link(nt, crust, 'Color', ecol, 'Color1')
    link(nt, emit_mask, 'Color', ecol, 'Color2')
    link(nt, ecol, 'Color', bsdf, 'Emission Color')
    bsdf.inputs['Emission Strength'].default_value = 1.0
    bsdf.inputs['Roughness'].default_value = 0.4
    return bsdf


def build_eye(mat):
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new('ShaderNodeOutputMaterial')
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    link(nt, bsdf, 'BSDF', out, 'Surface')
    bsdf.inputs['Base Color'].default_value = (1.0, 0.85, 0.35, 1)
    bsdf.inputs['Emission Color'].default_value = (1.0, 0.78, 0.25, 1)
    bsdf.inputs['Emission Strength'].default_value = 1.0
    bsdf.inputs['Roughness'].default_value = 0.35
    return bsdf


mat_rock = me.materials['CherufeRock']
mat_lava = me.materials['LavaVein']
mat_eye = me.materials['EyeGlow']
build_rock(mat_rock)
build_lava(mat_lava)
build_eye(mat_eye)


# ---------------------------------------------------------------- 3) bake
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 48
scene.render.bake.use_pass_direct = False
scene.render.bake.use_pass_indirect = False
scene.render.bake.margin = 12

img_albedo = new_img("cherufe_albedo", 'sRGB')
img_rough = new_img("cherufe_roughness", 'Non-Color')
img_normal = new_img("cherufe_normal", 'Non-Color')
img_emis = new_img("cherufe_emission", 'sRGB')


def set_bake_target(img):
    """Pone un nodo Image Texture activo apuntando a img en cada material."""
    for mat in (mat_rock, mat_lava, mat_eye):
        nt = mat.node_tree
        node = nt.nodes.get("BAKE_TARGET")
        if node is None:
            node = nt.nodes.new('ShaderNodeTexImage')
            node.name = "BAKE_TARGET"
            node.location = (-800, -400)
        node.image = img
        nt.nodes.active = node
        node.select = True


def bake(img, bake_type, **kw):
    set_bake_target(img)
    bpy.ops.object.bake(type=bake_type, **kw)
    img.filepath_raw = os.path.join(TEX_DIR, img.name + ".png")
    img.file_format = 'PNG'
    img.save()
    print("BAKED", img.name)


bake(img_albedo, 'DIFFUSE', pass_filter={'COLOR'})
bake(img_rough, 'ROUGHNESS')
bake(img_normal, 'NORMAL', normal_space='TANGENT')
bake(img_emis, 'EMIT')


# ---------------------------------------------------------------- 4) material final PBR
final = bpy.data.materials.new("CherufeBaked")
final.use_nodes = True
nt = final.node_tree
nt.nodes.clear()
out = nt.nodes.new('ShaderNodeOutputMaterial')
bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
link(nt, bsdf, 'BSDF', out, 'Surface')

t_alb = nt.nodes.new('ShaderNodeTexImage'); t_alb.image = img_albedo
link(nt, t_alb, 'Color', bsdf, 'Base Color')

t_rgh = nt.nodes.new('ShaderNodeTexImage'); t_rgh.image = img_rough
t_rgh.image.colorspace_settings.name = 'Non-Color'
link(nt, t_rgh, 'Color', bsdf, 'Roughness')

t_nrm = nt.nodes.new('ShaderNodeTexImage'); t_nrm.image = img_normal
t_nrm.image.colorspace_settings.name = 'Non-Color'
nmap = nt.nodes.new('ShaderNodeNormalMap')
link(nt, t_nrm, 'Color', nmap, 'Color')
link(nt, nmap, 'Normal', bsdf, 'Normal')

t_emi = nt.nodes.new('ShaderNodeTexImage'); t_emi.image = img_emis
link(nt, t_emi, 'Color', bsdf, 'Emission Color')
bsdf.inputs['Emission Strength'].default_value = 4.5
bsdf.inputs['Metallic'].default_value = 0.0

# una sola ranura de material -> un solo material limpio en Godot
me.materials.clear()
me.materials.append(final)
for p in me.polygons:
    p.material_index = 0

# ---------------------------------------------------------------- 5) export
if OUT_BLEND:
    bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)

bpy.ops.object.select_all(action='DESELECT')
obj.select_set(True)
bpy.context.view_layer.objects.active = obj
bpy.ops.export_scene.gltf(
    filepath=OUT_GLB,
    export_format='GLB',
    use_selection=True,
    export_apply=True,
    export_image_format='AUTO',
    export_yup=True,
)
print("EXPORTED", OUT_GLB)
