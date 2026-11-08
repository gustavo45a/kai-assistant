# Cuerpo de UniRig (tipo 264) + cola de UniRig (tipo 265) + orejas y cara desde la geometría → esqueleto final con nombres.
import sys, json, numpy as np, cv2
sys.path.insert(0, sys.argv[1]); import rig
body_j, tail_j, obj, tex, out, obj_cola = sys.argv[2:8]
B = json.load(open(body_j)); Tj = json.load(open(tail_j))
V, VT, G, _ = rig.load_obj(obj); names, info, P = rig.classify(V, G); J = rig.joints_r15(names, info, P)
off = np.array([J['LowerTorso'][0], 0, J['LowerTorso'][2]]); P0 = P - off            # mismo marco que el GLB exportado
joints = [np.array(p) for p in B['joints']]; parents = list(B['parents']); tags = ['cuerpo'] * len(joints)
zmin_body = P0[:, 2].min()
# --- cola: raíz que propone UniRig (tipo 265) + línea central de la malla de la cola (4 huesos, para la física)
CV, _, CG, _ = rig.load_obj(obj_cola)
TV = CV[CV[:, 2] < zmin_body - 0.01]                      # vértices detrás del cuerpo = cola
TJ = np.array(Tj['joints']); body_arr = np.array(joints)
cand = TJ[TJ[:, 2] < zmin_body + 0.05 * P0[:, 1].max()]
root = cand[np.argmax(cand[:, 2])] if len(cand) else TV[np.argmax(TV[:, 2])]
if len(TV) > 50:
    d = np.linalg.norm(TV - root, axis=1); qs = np.quantile(d, [0.18, 0.4, 0.62, 0.84, 0.99])
    pts = [root] + [TV[np.abs(d - q) < (d.max() * 0.06)].mean(0) for q in qs[:-1]] + [TV[np.argmax(d)]]
else:
    pts = list(cand)
prev = int(np.argmin(np.linalg.norm(body_arr - root, axis=1)))
for p_ in pts:
    joints.append(np.array(p_)); parents.append(prev); tags.append('cola'); prev = len(joints) - 1
# --- completar extremidades que UniRig no puso (codo, muñeca, mano, rodilla, tobillo, pie)
Hh = P0[:, 1].max()
for chain in (['LeftUpperArm', 'LeftLowerArm', 'LeftHand', '_LeftHandTip'], ['RightUpperArm', 'RightLowerArm', 'RightHand', '_RightHandTip'],
              ['LeftUpperLeg', 'LeftLowerLeg', 'LeftFoot', '_LeftToe'], ['RightUpperLeg', 'RightLowerLeg', 'RightFoot', '_RightToe']):
    prev_idx = None
    for k in chain:
        tgt = J[k] - off; arr = np.array(joints); dd = np.linalg.norm(arr - tgt, axis=1); i_ = int(np.argmin(dd))
        if dd[i_] < 0.07 * Hh: prev_idx = i_; continue
        if prev_idx is None: prev_idx = i_
        joints.append(tgt); parents.append(prev_idx); tags.append('cuerpo_completado'); prev_idx = len(joints) - 1
# --- orejas: punta más alta de cada lado de la cabeza
head_vi = info[[g for g, n in names.items() if n == 'Head'][0]]['vi']; H = P0[head_vi]
head_j = int(np.argmax([j[1] for j in joints[:len(B['joints'])]]))
cx = J['Head'][0] - off[0]
for side, sel in (('L', H[H[:, 0] > cx]), ('R', H[H[:, 0] <= cx])):
    tip = sel[np.argmax(sel[:, 1])]; top = tip[1]; hh = top - J['Head'][1]
    near = sel[np.abs(sel[:, 0] - tip[0]) < 0.22 * hh]
    tip = np.array([tip[0], top - 0.06 * hh, near[near[:, 1] > top - 0.1 * hh][:, 2].mean()])   # punta dentro de la oreja visible
    base = near[(near[:, 1] > top - 0.45 * hh) & (near[:, 1] < top - 0.35 * hh)]
    b = base.mean(0) if len(base) else tip - [0, 0.35 * hh, 0]
    mid = b + (tip - b) * 0.5
    joints.append(b); parents.append(head_j); tags.append('oreja_' + side)
    parents.append(len(joints) - 1); joints.append(mid); tags.append('oreja_' + side)
    parents.append(len(joints) - 1); joints.append(tip); tags.append('oreja_' + side)
# --- cara: mandíbula y párpados en los puntos detectados en la textura
t_ = cv2.imread(tex, cv2.IMREAD_UNCHANGED)
ff = rig.face_features(V, VT, G, names, P, J, t_)
neck = J['Head'] - off
mouth = ff['mouth'][0] - off
joints.append(neck + (mouth - neck) * 0.35); parents.append(head_j); tags.append('mandibula')
parents.append(len(joints) - 1); joints.append(mouth); tags.append('mandibula')
for side in ('L', 'R'):
    e = ff['eye_' + side][0] - off; r_ = ff['eye_' + side][1]
    joints.append(e + [0, r_ * 1.0, -r_ * 0.3]); parents.append(head_j); tags.append('parpado_' + side)
    parents.append(len(joints) - 1); joints.append(e + [0, r_ * 1.0, r_ * 0.2]); tags.append('parpado_' + side)
json.dump({'joints': [list(map(float, j)) for j in joints], 'parents': parents, 'tags': tags,
           'fuente': {'cuerpo': 'UniRig tipo 264', 'cola': 'UniRig tipo 265', 'orejas_cara': 'geometría/textura'}}, open(out, 'w'))
from collections import Counter; print(out, Counter(tags))
