# Esqueleto de UniRig (etapa de esqueleto, ONNX int8) en CPU: malla → articulaciones + jerarquía.
import sys, json, time, numpy as np, onnxruntime as ort, trimesh
MODEL, MESH, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
N = int(sys.argv[4]) if len(sys.argv) > 4 else 65536
BRANCH, BOS, EOS, CLS = 256, 257, 258, 266
so = ort.SessionOptions(); so.intra_op_num_threads = 0
enc = ort.InferenceSession(f'{MODEL}/encoder_q8.onnx', so, providers=['CPUExecutionProvider'])
emb = ort.InferenceSession(f'{MODEL}/embed.onnx', so, providers=['CPUExecutionProvider'])
dec = ort.InferenceSession(f'{MODEL}/decoder_q8.onnx', so, providers=['CPUExecutionProvider'])
sc = trimesh.load(MESH, force='scene'); mesh = sc.to_geometry() if hasattr(sc, 'to_geometry') else sc.dump(concatenate=True)
rng = np.random.default_rng(0)
pts, fi = trimesh.sample.sample_surface(mesh, N, seed=0); nrm = mesh.face_normals[fi]
lo, hi = mesh.bounds; c = (lo + hi) / 2; s = (hi - lo).max() / 2          # la caja va de −1 a 1 (importante)
P = ((pts - c) / s).astype(np.float32)[None]; Nn = nrm.astype(np.float32)[None]
t0 = time.time(); lat = enc.run(None, {'vertices': P, 'normals': Nn})[0]
E = lambda ids: emb.run(None, {'input_ids': np.array([ids], np.int64)})[0]
import os
PREFIX = [int(v) for v in os.environ.get('UR_PREFIX', f'{BOS},{CLS}').split(',')]
FIRST = int(os.environ.get('UR_FIRST', '-1'))
x = np.concatenate([lat, E(PREFIX)], 1).astype(np.float32)
past = {f'past.{i}.{k}': np.zeros((1, 16, 0, 64), np.float32) for i in range(24) for k in ('key', 'value')}
toks = []; cnt = 0; hdr = -1          # hdr: coordenadas que faltan de la cabecera de una rama (6 = hueso padre)
for step in range(2048):
    outs = dec.run(None, {'inputs_embeds': x, **past}); logits = outs[0][0, -1]
    names = [o.name for o in dec.get_outputs()]
    for nme, val in zip(names[1:], outs[1:]): past['past.' + nme[len('present.'):]] = val
    mask = np.full(267, -np.inf); mask[:256] = 0
    if step == 0:
        mask[259:266] = 0
        if FIRST >= 0: mask[:] = -np.inf; mask[FIRST] = 0
    elif hdr <= 0 and cnt == 0:
        mask[BRANCH] = 0; mask[EOS] = 0
    t = int(np.argmax(logits + mask))
    if t == EOS: break
    toks.append(t)
    if t == BRANCH: hdr = 6
    elif t < 256:
        if hdr > 0: hdr -= 1
        else: cnt = (cnt + 1) % 3
    x = E([t]).astype(np.float32)
print(f"tokens {len(toks)} en {time.time() - t0:.0f}s", flush=True)
ORDER = [0, 1, 2]                                     # orden de ejes de los tokens
def und(tr): v = (np.array(tr) + 0.5) / 256 * 2 - 1; return v[ORDER]
joints, parents = [], []; cur = []; prev = -1; hdr_buf = None; i = 0
seq = [t for t in toks if t < 257]
while i < len(seq):
    t = seq[i]
    if t == BRANCH:
        a_, b_ = und(seq[i + 1:i + 4]), und(seq[i + 4:i + 7]); i += 7
        prev = int(np.argmin(np.linalg.norm(np.array(joints) - b_, axis=1))) if joints else -1
        continue
    tr = seq[i:i + 3]; i += 3
    if len(tr) < 3: break
    joints.append(und(tr)); parents.append(prev); prev = len(joints) - 1
J = np.array(joints) * s + c
json.dump({'joints': J.tolist(), 'parents': parents, 'tokens': len(toks), 'seconds': round(time.time() - t0, 1)}, open(OUT, 'w'))
print(f"huesos {len(J) - 1} · articulaciones {len(J)}", flush=True)
