# Los checkpoints oficiales de UniRig (de VAST-AI en Hugging Face) guardan objetos Box: hay que cargarlos con weights_only=False.
try:
    import torch
    _tl = torch.load
    def _load(*a, **k):
        k['weights_only'] = False
        return _tl(*a, **k)
    torch.load = _load
except Exception:
    pass
# spconv en CPU no aplica bias/activación dentro de la convolución dispersa: lo hago después (resultado idéntico)
try:
    import spconv.pytorch.ops as _ops, torch as _t
    _ic = _ops.indice_conv
    def _indice_conv(features, filters, *a, bias=None, act_alpha=0.0, act_beta=0.0, act_type=None, **k):
        if features.is_cuda: return _ic(features, filters, *a, bias=bias, act_alpha=act_alpha, act_beta=act_beta, **({} if act_type is None else {'act_type': act_type}), **k)
        out = _ic(features, filters, *a, **k)
        if bias is not None: out = out + bias
        name = str(act_type) if act_type is not None else 'None_'
        if 'ReLU' in name and 'Leaky' not in name: out = _t.relu(out)
        elif 'Leaky' in name: out = _t.nn.functional.leaky_relu(out, act_alpha)
        return out
    _ops.indice_conv = _indice_conv
except Exception:
    pass
