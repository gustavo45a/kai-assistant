# Prueba de deformación: dobla codos/rodillas, enrolla la cola, mueve orejas y abre la mandíbula; render en reposo y en pose.
import bpy, sys, math
from mathutils import Euler
a = sys.argv[sys.argv.index('--') + 1:]; glb, out = a
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
arm = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE'][0]
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 12; sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[1].default_value = 0.7
bpy.ops.object.light_add(type='SUN'); bpy.context.object.data.energy = 3; bpy.context.object.rotation_euler = (0.7, 0.2, 0.6)
zs = [ (m.matrix_world @ v.co).z for m in meshes for v in m.data.vertices]; H = max(zs) - min(zs); zc = (max(zs) + min(zs)) / 2
def cams(tag):
    for k, ang in enumerate((20, 100)):
        t = math.radians(ang); bpy.ops.object.camera_add(location=(30 * math.sin(t), -30 * math.cos(t), zc)); c = bpy.context.object
        c.rotation_euler = (math.radians(90), 0, t); c.data.type = 'ORTHO'; c.data.ortho_scale = H * 1.25; sc.camera = c
        sc.render.resolution_x, sc.render.resolution_y = 380, 420; sc.render.filepath = f"{out}_{tag}{k}.png"; bpy.ops.render.render(write_still=True)
cams('reposo')
pb = arm.pose.bones
# brazos y piernas: los huesos "cuerpo" que no son columna (los dos más bajos/laterales se detectan por posición)
for b in pb:
    n = b.name
    if n.startswith('cola'): b.rotation_mode = 'XYZ'; b.rotation_euler = Euler((math.radians(-22), math.radians(10), 0))
    elif n.startswith('oreja'): b.rotation_mode = 'XYZ'; b.rotation_euler = Euler((math.radians(25), 0, math.radians(15)))
    elif n.startswith('mandibula'): b.rotation_mode = 'XYZ'; b.rotation_euler = Euler((math.radians(18), 0, 0))
# codos y rodillas: huesos cuyo padre es lateral (|x| grande) y van hacia abajo
import mathutils
for b in pb:
    if not (b.name.startswith('cuerpo')) or b.parent is None: continue
    head = arm.matrix_world @ b.head; tail = arm.matrix_world @ b.tail
    d = (tail - head)
    if abs(head.x) > H * 0.06 and head.z > zc and d.z < 0:            # antebrazos
        b.rotation_mode = 'XYZ'; b.rotation_euler = Euler((math.radians(55), 0, 0))
    elif abs(head.x) > H * 0.02 and head.z < zc - H * 0.15 and d.z < 0:   # piernas bajas
        b.rotation_mode = 'XYZ'; b.rotation_euler = Euler((math.radians(-35), 0, 0))
bpy.context.view_layer.update()
cams('pose')
