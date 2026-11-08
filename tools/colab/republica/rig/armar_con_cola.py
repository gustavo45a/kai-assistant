# Une el avatar R15 + la cola (accesorio de otro modelo), con colores del personaje en la cola. Exporta OBJ+PNG y GLB para UniRig.
import bpy, sys, os, math, numpy as np
from mathutils import Vector, Matrix
argv = sys.argv[sys.argv.index('--') + 1:]
sys.path.insert(0, argv[0]); import rig
av_obj, av_tex, tail_obj, tail_group, out_dir, name, col_base, col_tip = argv[1:9]
col_base = [float(x) for x in col_base.split(',')]; col_tip = [float(x) for x in col_tip.split(',')]
os.makedirs(out_dir, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
V, VT, G, _ = rig.load_obj(av_obj); names, info, P = rig.classify(V, G); J = rig.joints_r15(names, info, P)
A = np.array([[1, 0, 0], [0, 0, -1], [0, 1, 0]], float)        # y-arriba mirando +Z → Blender z-arriba mirando −Y
def mk(name_, verts, faces, uvs=None):
    me = bpy.data.meshes.new(name_); me.from_pydata(verts.tolist(), [], faces); me.update()
    if uvs is not None:
        uv = me.uv_layers.new(name='UVMap')
        for k, l in enumerate(me.loops): uv.data[k].uv = uvs[k]
    ob = bpy.data.objects.new(name_, me); bpy.context.scene.collection.objects.link(ob); return ob
# cuerpo (una sola malla, con UV y textura)
verts = (P - np.array([J['LowerTorso'][0], 0, J['LowerTorso'][2]])) @ A.T
faces, uvs = [], []
for g, fs in G.items():
    for f in fs:
        faces.append([a[0] - 1 for a in f]); uvs += [tuple(VT[a[1] - 1]) if a[1] > 0 else (0, 0) for a in f]
body = mk(name, verts, faces, uvs)
m = bpy.data.materials.new(name + '_piel'); m.use_nodes = True; nt = m.node_tree; b = nt.nodes['Principled BSDF']
t = nt.nodes.new('ShaderNodeTexImage'); t.image = bpy.data.images.load(av_tex); nt.links.new(t.outputs['Color'], b.inputs['Base Color'])
body.data.materials.append(m)
# cola: grupo del otro modelo, girada para salir de la espalda, escalada a la altura del personaje
TV, TVT, TG, _ = rig.load_obj(tail_obj)
tf = TG[tail_group]; vi = sorted({a[0] - 1 for f in tf for a in f}); remap = {v: k for k, v in enumerate(vi)}
tp = TV[vi].copy(); tp = rig.ry180(tp)                           # Roblox mira a −Z: la cola queda en −Z (atrás) tras el giro
body_all = rig.ry180(TV[[a[0] - 1 for g_, fs_ in TG.items() if not g_.startswith('Handle') for f in fs_ for a in f]])
h_src = body_all[:, 1].max() - body_all[:, 1].min(); h_dst = P[:, 1].max() - P[:, 1].min(); s = h_dst / h_src * 0.8
# raíz de la cola = su punto más cercano al cuerpo; va pegada atrás de la cadera del personaje
root = tp[np.argmax(tp[:, 2])]
lt = P[info[[g for g, n in names.items() if n == 'LowerTorso'][0]]['vi']]
anchor = np.array([J['LowerTorso'][0], J['LowerTorso'][1] - 0.05 * h_dst, lt[:, 2].min() + 0.08 * h_dst])
tp = (tp - root) * s; ang = math.radians(28); Rx = np.array([[1, 0, 0], [0, math.cos(ang), -math.sin(ang)], [0, math.sin(ang), math.cos(ang)]]); tp = tp @ Rx.T + anchor   # la levanta un poco
tverts = (tp - np.array([J['LowerTorso'][0], 0, J['LowerTorso'][2]])) @ A.T
tfaces = [[remap[a[0] - 1] for a in f] for f in tf]
tail = mk(name + '_cola', tverts, tfaces)
# color de la cola: degradado de la base a la punta (vertex color)
d = np.linalg.norm(tp - anchor, axis=1); u = (d - d.min()) / (np.ptp(d) + 1e-9)
ca = tail.data.color_attributes.new('Col', 'FLOAT_COLOR', 'POINT')
for k, uu in enumerate(u):
    w = np.clip((uu - 0.62) / 0.2, 0, 1); ca.data[k].color = tuple(np.array(col_base) * (1 - w) + np.array(col_tip) * w) + (1,)
mt = bpy.data.materials.new(name + '_cola'); mt.use_nodes = True; n2 = mt.node_tree
at = n2.nodes.new('ShaderNodeVertexColor'); at.layer_name = 'Col'; n2.links.new(at.outputs['Color'], n2.nodes['Principled BSDF'].inputs['Base Color'])
tail.data.materials.append(mt)
for o in (body, tail):
    for p in o.data.polygons: p.use_smooth = True
# un solo objeto (UniRig recibe una malla)
bpy.ops.object.select_all(action='DESELECT'); body.select_set(True); tail.select_set(True); bpy.context.view_layer.objects.active = body
bpy.ops.object.join()
bpy.ops.export_scene.gltf(filepath=os.path.join(out_dir, name + '_con_cola.glb'), export_format='GLB', use_selection=True)
bpy.ops.wm.obj_export(filepath=os.path.join(out_dir, name + '_con_cola.obj'), export_selected_objects=True, export_materials=True, path_mode='COPY')
# vista previa (frente, lado, atrás)
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 12; sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[1].default_value = 0.8
bpy.ops.object.light_add(type='SUN'); bpy.context.object.data.energy = 3; bpy.context.object.rotation_euler = (0.7, 0.2, 0.6)
H = h_dst
for k, ang in enumerate((0, 90, 180)):
    a = math.radians(ang); bpy.ops.object.camera_add(location=(10 * math.sin(a), -10 * math.cos(a), H / 2)); cam = bpy.context.object
    cam.rotation_euler = (math.radians(90), 0, a); cam.data.type = 'ORTHO'; cam.data.ortho_scale = H * 1.15; sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 300, 360; sc.render.filepath = os.path.join(out_dir, f'{name}_vista{k}.png'); bpy.ops.render.render(write_still=True)
print('LISTO', name)
