# Malla con cola (GLB) + nuestro esqueleto (JSON) → FBX con armature, la entrada del skinning de UniRig.
import bpy, sys, json
from mathutils import Vector
a = sys.argv[sys.argv.index('--') + 1:]; glb, js, out = a
bpy.ops.wm.read_factory_settings(use_empty=True); bpy.ops.import_scene.gltf(filepath=glb)
mesh = [o for o in bpy.context.scene.objects if o.type == 'MESH'][0]
d = json.load(open(js)); J = [Vector((x, -z, y)) for x, y, z in d['joints']]; par = d['parents']; tags = d['tags']
ch = {i: [k for k, p in enumerate(par) if p == i] for i in range(len(J))}
arm = bpy.data.armatures.new('Rig'); ob = bpy.data.objects.new('Rig', arm); bpy.context.scene.collection.objects.link(ob)
bpy.context.view_layer.objects.active = ob; bpy.ops.object.mode_set(mode='EDIT'); eb = {}
H = max(j.z for j in J) - min(j.z for j in J)
for i, p in enumerate(J):
    b = arm.edit_bones.new(f"{tags[i]}_{i:02d}"); b.head = p
    if len(ch[i]) == 1 and (J[ch[i][0]] - p).length > 1e-4: b.tail = J[ch[i][0]]
    elif par[i] >= 0 and (p - J[par[i]]).length > 1e-4: b.tail = p + (p - J[par[i]]).normalized() * H * 0.04
    else: b.tail = p + Vector((0, 0, H * 0.04))
    eb[i] = b
for i, p in enumerate(par):
    if p >= 0: eb[i].parent = eb[p]
bpy.ops.object.mode_set(mode='OBJECT')
mesh.parent = ob
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.fbx(filepath=out, use_selection=True, add_leaf_bones=False, bake_anim=False, object_types={'ARMATURE', 'MESH'})
print('FBX', out, len(J), 'huesos')
