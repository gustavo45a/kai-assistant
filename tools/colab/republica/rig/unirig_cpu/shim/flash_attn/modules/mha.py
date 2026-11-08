# Reemplazo de flash_attn.modules.mha.MHA con atención estándar de PyTorch (mismos nombres de pesos: Wq, Wkv, Wqkv, out_proj).
import torch, torch.nn as nn, torch.nn.functional as F
class MHA(nn.Module):
    def __init__(self, embed_dim, num_heads, cross_attn=False, qkv_proj_bias=True, out_proj_bias=True, **kw):
        super().__init__(); self.embed_dim, self.num_heads = embed_dim, num_heads; self.head_dim = embed_dim // num_heads; self.cross_attn = cross_attn
        if cross_attn:
            self.Wq = nn.Linear(embed_dim, embed_dim, bias=qkv_proj_bias); self.Wkv = nn.Linear(embed_dim, 2 * embed_dim, bias=qkv_proj_bias)
        else:
            self.Wqkv = nn.Linear(embed_dim, 3 * embed_dim, bias=qkv_proj_bias)
        self.out_proj = nn.Linear(embed_dim, embed_dim, bias=out_proj_bias)
    def forward(self, x, x_kv=None, key_padding_mask=None, **kw):
        b, s, _ = x.shape; h, d = self.num_heads, self.head_dim
        if self.cross_attn:
            q = self.Wq(x).view(b, s, h, d); kv = self.Wkv(x if x_kv is None else x_kv); sk = kv.shape[1]
            kv = kv.view(b, sk, 2, h, d); k, v = kv[:, :, 0], kv[:, :, 1]
        else:
            q, k, v = self.Wqkv(x).view(b, s, 3, h, d).unbind(2)
        o = F.scaled_dot_product_attention(q.transpose(1, 2), k.transpose(1, 2), v.transpose(1, 2)).transpose(1, 2).reshape(b, s, h * d)
        return self.out_proj(o)
