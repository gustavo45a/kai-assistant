import bpy, sys, json, math, os
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; glb, js, out = a[0], a[1], a[2]
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for m in meshes:
    for s in m.material_slots:
        if s.material and s.material.use_nodes:
            b = s.material.node_tree.nodes.get('Principled BSDF')
            if b: b.inputs['Alpha'].default_value = 0.35
        try: s.material.surface_render_method = 'BLENDED'
        except Exception: pass
d = json.load(open(js)); J = [Vector((x, -z, y)) for x, y, z in d['joints']]; par = d['parents']; tags = d.get('tags', ['cuerpo'] * len(J))
COL = {'cuerpo': (0.1, 0.6, 1), 'cola': (1, 0.4, 0.05), 'oreja_L': (0.2, 1, 0.3), 'oreja_R': (0.2, 1, 0.3), 'mandibula': (1, 0.1, 0.8), 'parpado_L': (1, 1, 0.1), 'parpado_R': (1, 1, 0.1), 'cuerpo_completado': (0.6, 0.3, 1)}
MB = {}
def mat_for(t):
    if t not in MB:
        m = bpy.data.materials.new(t); m.use_nodes = True; b_ = m.node_tree.nodes['Principled BSDF']
        b_.inputs['Emission Color'].default_value = COL.get(t, (1, 1, 1)) + (1,); b_.inputs['Emission Strength'].default_value = 4; MB[t] = m
    return MB[t]
mj = bpy.data.materials.new('j'); mj.use_nodes = True; bj = mj.node_tree.nodes['Principled BSDF']
bj.inputs['Emission Color'].default_value = (1, 0.85, 0.1, 1); bj.inputs['Emission Strength'].default_value = 3
mb = bpy.data.materials.new('b'); mb.use_nodes = True; bb = mb.node_tree.nodes['Principled BSDF']
bb.inputs['Emission Color'].default_value = (0.1, 0.6, 1, 1); bb.inputs['Emission Strength'].default_value = 3
H = max(j.z for j in J) - min(j.z for j in J); r = H * 0.012
for i, p in enumerate(J):
    bpy.ops.mesh.primitive_uv_sphere_add(radius=r * (1.0 if tags[i] != 'cuerpo' else 1.6), location=p, segments=12, ring_count=6); bpy.context.object.data.materials.append(mat_for(tags[i]))
    if par[i] >= 0:
        q = J[par[i]]; v = p - q; L = v.length
        if L < 1e-6: continue
        bpy.ops.mesh.primitive_cylinder_add(radius=r * 0.7, depth=L, location=(p + q) / 2, vertices=8)
        c = bpy.context.object; c.rotation_euler = v.to_track_quat('Z', 'Y').to_euler(); c.data.materials.append(mat_for(tags[i]))
sc = bpy.context.scene; sc.render.engine = 'CYCLES'; sc.cycles.samples = 16; sc.view_settings.view_transform = 'Standard'
w = bpy.data.worlds.new('w'); sc.world = w; w.use_nodes = True; w.node_tree.nodes['Background'].inputs[0].default_value = (0.08, 0.08, 0.1, 1)
bpy.ops.object.light_add(type='SUN'); bpy.context.object.data.energy = 3; bpy.context.object.rotation_euler = (0.7, 0.2, 0.6)
zs = [p.z for m in meshes for p in [m.matrix_world @ Vector(c) for c in m.bound_box]]; zc = (max(zs) + min(zs)) / 2; Hm = max(zs) - min(zs)
cx = sum(p.x for p in J) / len(J); cy = sum(p.y for p in J) / len(J)
views = [('frente', 0, Hm * 1.1, zc, 1.0), ('lado', 90, Hm * 1.1, zc, 1.0), ('atras', 180, Hm * 1.1, zc, 1.0), ('cara', 0, Hm * 0.38, max(zs) - Hm * 0.2, 1.0)]
for name, ang, scale, z, _ in views:
    t = math.radians(ang); bpy.ops.object.camera_add(location=(cx + 30 * math.sin(t), cy - 30 * math.cos(t), z)); cam = bpy.context.object
    cam.rotation_euler = (math.radians(90), 0, t); cam.data.type = 'ORTHO'; cam.data.ortho_scale = scale; sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = 420, 520; sc.render.filepath = f"{out}_{name}.png"; bpy.ops.render.render(write_still=True)
