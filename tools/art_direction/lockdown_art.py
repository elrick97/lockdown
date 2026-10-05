"""Lockdown art-direction frame builder (OpenSpec change `add-art-direction`).

Runs inside Blender 5.2 (bpy + numpy). Everything is generated from scratch:
no library assets, no generated models. Usage from Blender's Python:

    exec(open(r"<repo>/tools/art_direction/lockdown_art.py").read())
    build_frame("A")   # or "B", "C"

Asset recipe follows design.md D1-D9: one shared die/tray/token/camera rig,
per-direction skins (materials, lights, post overlay).
"""
import math
import os
import shutil

import bmesh
import bpy
import numpy as np
from mathutils import Euler, Matrix, Vector

PROJECT = r"C:\Users\ricar\projects\lockdown"
OUT = os.path.join(PROJECT, "assets", "art_direction")
TILE = 256
ATLAS_COLS, ATLAS_ROWS = 3, 2
DIE = 1.0
BEVEL = 0.1
BEVEL_SEGMENTS = 3
TILT_DEG = 18.0
FRAME_W, FRAME_H = 1080, 2400
ORTHO_SCALE = 16.0  # world units across the 2400 px height -> 150 px per die
# Standard layout: +Z=1, -Z=6, +X=3, -X=4, +Y=2, -Y=5 (opposite faces sum to 7).
FACE_VALUE = {(2, 1): 1, (2, -1): 6, (0, 1): 3, (0, -1): 4, (1, 1): 2, (1, -1): 5}
ROT_TOP = {
    1: Euler((0, 0, 0)), 6: Euler((math.pi, 0, 0)),
    3: Euler((0, -math.pi / 2, 0)), 4: Euler((0, math.pi / 2, 0)),
    2: Euler((math.pi / 2, 0, 0)), 5: Euler((-math.pi / 2, 0, 0)),
}
PIPS = {
    1: [(.5, .5)],
    2: [(.28, .72), (.72, .28)],
    3: [(.28, .72), (.5, .5), (.72, .28)],
    4: [(.28, .28), (.28, .72), (.72, .28), (.72, .72)],
    5: [(.28, .28), (.28, .72), (.5, .5), (.72, .28), (.72, .72)],
    6: [(.28, .28), (.28, .5), (.28, .72), (.72, .28), (.72, .5), (.72, .72)],
}
WILD_STAR = [(0.5 + rr * math.cos(math.radians(90 + 22.5 * k)), 0.5 + rr * math.sin(math.radians(90 + 22.5 * k)))
             for k, rr in enumerate([0.37, 0.085, 0.2, 0.085] * 4)]  # 8-point star: long N/E/S/W, short diagonals
BOLT = [(0.50, 0.88), (0.67, 0.88), (0.56, 0.59), (0.71, 0.59), (0.37, 0.10), (0.47, 0.45), (0.31, 0.45)]


# ---------------------------------------------------------------- numpy utils
def _smooth(e0, e1, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3 - 2 * t)


def _resize(g, h, w):
    """Smooth bilinear resize of a 2D array."""
    gh, gw = g.shape
    y = np.linspace(0, gh - 1, h)
    x = np.linspace(0, gw - 1, w)
    y0 = np.floor(y).astype(int)
    x0 = np.floor(x).astype(int)
    y1 = np.minimum(y0 + 1, gh - 1)
    x1 = np.minimum(x0 + 1, gw - 1)
    fy = (y - y0)[:, None]
    fx = (x - x0)[None, :]
    fy = fy * fy * (3 - 2 * fy)
    fx = fx * fx * (3 - 2 * fx)
    a, b = g[y0][:, x0], g[y0][:, x1]
    c, d = g[y1][:, x0], g[y1][:, x1]
    return ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy).astype(np.float32)


def _noise(h, w, cell, rng, octaves=4, stretch=(1.0, 1.0)):
    """Fractal value noise in [0, 1]. stretch=(sy, sx) elongates features."""
    out = np.zeros((h, w), np.float32)
    amp, tot = 1.0, 0.0
    for o in range(octaves):
        gh = max(2, int(h / cell * 2 ** o / stretch[0]))
        gw = max(2, int(w / cell * 2 ** o / stretch[1]))
        out += amp * _resize(rng.random((gh + 1, gw + 1)).astype(np.float32), h, w)
        tot += amp
        amp *= 0.5
    return out / tot


def _soft(d, aa):
    """Anti-aliased inside mask from a signed distance (negative = inside)."""
    return np.clip(0.5 - d / aa, 0.0, 1.0)


def _poly_sd(px, py, poly):
    """Signed distance from points to a polygon (even-odd inside test)."""
    d = np.full(px.shape, 1e9, np.float32)
    inside = np.zeros(px.shape, bool)
    n = len(poly)
    for i in range(n):
        ax, ay = poly[i]
        bx, by = poly[(i + 1) % n]
        ex, ey = bx - ax, by - ay
        t = np.clip(((px - ax) * ex + (py - ay) * ey) / (ex * ex + ey * ey), 0, 1)
        d = np.minimum(d, np.hypot(px - ax - t * ex, py - ay - t * ey))
        cond = ((ay > py) != (by > py)) & (px < (bx - ax) * (py - ay) / (by - ay + 1e-12) + ax)
        inside ^= cond
    return np.where(inside, -d, d)


def _rrect_sd(px, py, hw, hh, r):
    qx = np.abs(px) - hw + r
    qy = np.abs(py) - hh + r
    return np.hypot(np.maximum(qx, 0), np.maximum(qy, 0)) + np.minimum(np.maximum(qx, qy), 0) - r


def _height_to_normal(hgt, strength):
    gy, gx = np.gradient(hgt)
    n = np.stack([-gx * strength, -gy * strength, np.ones_like(hgt)], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return n * 0.5 + 0.5


def _box_blur(a, r, axis):
    if r < 1:
        return a
    pad = [(0, 0)] * a.ndim
    pad[axis] = (r + 1, r)
    c = np.cumsum(np.pad(a, pad, mode="edge"), axis=axis)
    hi = np.take(c, range(2 * r + 1, c.shape[axis]), axis=axis)
    lo = np.take(c, range(0, c.shape[axis] - 2 * r - 1), axis=axis)
    return (hi - lo) / (2 * r + 1)


def _blur(a, r):
    for _ in range(3):
        a = _box_blur(_box_blur(a, r, 0), r, 1)
    return a


def hexcol(c):
    return "#%02X%02X%02X" % tuple(int(round(max(0, min(1, v)) * 255)) for v in c[:3])


# ------------------------------------------------------------ image plumbing
def save_image(name, arr, path, noncolor=False):
    """arr: (H, W, 3|4) float, row 0 = bottom (Blender order). Writes a PNG."""
    h, w, c = arr.shape
    if c == 3:
        arr = np.concatenate([arr, np.ones((h, w, 1), np.float32)], 2)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img = bpy.data.images.get(name)
    if img is not None:
        bpy.data.images.remove(img)
    img = bpy.data.images.new(name, w, h, alpha=True)
    img.pixels.foreach_set(np.clip(arr, 0, 1).astype(np.float32).ravel())
    img.filepath_raw = path
    img.file_format = "PNG"
    img.save()
    if noncolor:
        img.colorspace_settings.name = "Non-Color"
    return img


def load_pixels(path):
    img = bpy.data.images.load(path, check_existing=False)
    w, h = img.size
    arr = np.empty(w * h * 4, np.float32)
    img.pixels.foreach_get(arr)
    bpy.data.images.remove(img)
    return arr.reshape(h, w, 4)


# --------------------------------------------------------------- die atlases
def _tile_grid():
    u = (np.arange(TILE, dtype=np.float32) + 0.5) / TILE
    return np.meshgrid(u, u)  # U across, V up (row 0 = bottom)


def _symbol(kind, U, V):
    """Carved-face symbol: returns (mask, shade) in tile space."""
    aa = 1.5 / TILE
    dx, dy = U - 0.5, V - 0.5
    if kind == "wild":
        mask = _soft(_poly_sd(U, V, WILD_STAR), aa)
        shade = 0.8 + 0.35 * np.clip(1 - np.hypot(dx, dy) / 0.36, 0, 1)
    elif kind == "gem":
        mask = _soft((np.abs(dx) / 0.22 + np.abs(dy) / 0.31 - 1) * 0.18, aa)
        shade = np.where(dx < 0, 1.0, 0.72) * np.where(dy > 0, 1.0, 0.82)
        table = _soft((np.abs(dx) / 0.1 + np.abs(dy) / 0.14 - 1) * 0.08, aa)
        shade = shade * (1 - table) + 1.25 * table
    elif kind == "spark":
        mask = _soft(_poly_sd(U, V, BOLT), aa)
        shade = 0.85 + 0.3 * (V - 0.1)
    else:
        raise ValueError(kind)
    return mask, shade


def make_die_atlas(kind, pal, carve=None, seed=7):
    """Albedo (RGBA), normal, ORM for one die material variant.

    kind: 'bone' | 'iron' | 'glass'. carve: {face_value: 'wild'|'gem'|'spark'}.
    AO is baked into albedo (design D3); ORM = (AO, roughness, metallic).
    """
    carve = carve or {}
    rng = np.random.default_rng(seed)
    H, W = TILE * ATLAS_ROWS, TILE * ATLAS_COLS
    alb = np.zeros((H, W, 4), np.float32)
    hgt = np.zeros((H, W), np.float32)
    orm = np.zeros((H, W, 3), np.float32)
    U, V = _tile_grid()
    edge = np.minimum(np.minimum(U, 1 - U), np.minimum(V, 1 - V))  # 0 at tile border
    flat0 = BEVEL / DIE  # flat face starts here (bevel band maps to the border)
    if kind == "bone":
        grain = _noise(H, W, 40, rng, 4, (1, 6))
        speck = _noise(H, W, 6, rng, 2)
        base_full = np.array(pal["bone"])[None, None, :] * (0.9 + 0.16 * grain[..., None])
        base_full *= (1 - 0.12 * (speck > 0.72))[..., None]
    elif kind == "iron":
        brush = _noise(H, W, 30, rng, 5, (1, 14))
        base_full = np.array(pal["iron"])[None, None, :] * (0.78 + 0.42 * brush[..., None])
    else:
        swirl = _noise(H, W, 90, rng, 3)
        base_full = np.array(pal["glass"])[None, None, :] * (0.9 + 0.2 * swirl[..., None])
    for v in range(1, 7):
        c, r = (v - 1) % ATLAS_COLS, (v - 1) // ATLAS_COLS
        sl = (slice(r * TILE, (r + 1) * TILE), slice(c * TILE, (c + 1) * TILE))
        base = base_full[sl].copy()
        h = np.zeros((TILE, TILE), np.float32)
        ao = 0.86 + 0.14 * _smooth(0.0, flat0 + 0.04, edge)
        rough = np.full((TILE, TILE), 0.5, np.float32)
        metal = np.zeros((TILE, TILE), np.float32)
        alpha = np.ones((TILE, TILE), np.float32)
        if kind == "bone":
            rough[:] = 0.42
        elif kind == "iron":
            worn = 1 - _smooth(0.02, flat0 + 0.02, edge)
            base = base + 0.16 * worn[..., None]
            rough[:] = 0.36
            metal[:] = 0.65
        else:
            thick = 1 - _smooth(0.0, 0.24, edge)
            base = base * (0.72 + 0.55 * _smooth(0.0, 0.32, edge))[..., None]
            streak = np.exp(-(((U - V) - 0.18) / 0.07) ** 2) * _smooth(0.05, 0.2, edge)
            base = base + 0.32 * streak[..., None]
            alpha = 0.40 + 0.48 * thick + 0.18 * streak
            rough[:] = 0.06
        sym = carve.get(v)
        if sym:
            mask, shade = _symbol(sym, U, V)
            col = np.array(pal["carve_" + sym])[None, None, :] * shade[..., None]
            # recessed inlay with an occluded groove around it
            base = base * (1 - mask[..., None]) + col * mask[..., None]
            h -= 0.35 * mask
            rough = rough * (1 - mask) + 0.25 * mask
            metal = metal * (1 - mask) + (0.0 if sym == "gem" else 0.9) * mask
            alpha = alpha * (1 - mask) + mask
            ring = np.exp(-((mask - 0.5) / 0.25) ** 2)
            ao = ao * (1 - 0.25 * ring)
        else:
            pip_col = np.array(pal[kind + "_pip1"] if (v == 1 and kind + "_pip1" in pal) else pal[kind + "_pip"])
            radius = 0.115 if v == 1 else 0.082
            dist = np.full((TILE, TILE), 9.0, np.float32)
            for pu, pv in PIPS[v]:
                rr = np.hypot(U - pu, V - pv)
                dist = np.minimum(dist, rr)
            pm = _soft(dist - radius, 1.5 / TILE)
            dish = np.sqrt(np.clip(1 - (dist / radius) ** 2, 0, 1))
            h -= 0.6 * dish * pm
            fill = pip_col[None, None, :] * (0.72 + 0.28 * np.clip(1 - dist / radius, 0, 1))[..., None]
            base = base * (1 - pm[..., None]) + fill * pm[..., None]
            ring = np.exp(-((dist - radius) / 0.018) ** 2) * (dist > radius)
            ao = ao * (1 - 0.3 * ring)
            rough = rough * (1 - pm) + 0.55 * pm
            metal = metal * (1 - pm)
            alpha = alpha * (1 - pm) + pm
        alb[sl][..., :3] = base * ao[..., None]
        alb[sl][..., 3] = alpha
        hgt[sl] = h
        orm[sl] = np.stack([ao, rough, metal], -1)
    nrm = _height_to_normal(hgt, 9.0)
    return alb, nrm, orm


# ------------------------------------------------------------------ geometry
def make_die_mesh(name="DieMesh"):
    """Beveled cube with a six-tile atlas UV layout (design D2)."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=DIE)
    bmesh.ops.bevel(bm, geom=list(bm.edges), offset=BEVEL, segments=BEVEL_SEGMENTS,
                    affect="EDGES", profile=0.5, clamp_overlap=True)
    uv = bm.loops.layers.uv.new("UVMap")
    pad = 2.0 / TILE
    for f in bm.faces:
        n = f.normal
        axis = max(range(3), key=lambda i: abs(n[i]))
        sign = 1 if n[axis] > 0 else -1
        v = FACE_VALUE[(axis, sign)]
        col, row = (v - 1) % ATLAS_COLS, (v - 1) // ATLAS_COLS
        for loop in f.loops:
            x, y, z = loop.vert.co
            pu, pv = {(0, 1): (y, z), (0, -1): (-y, z), (1, 1): (-x, z), (1, -1): (x, z),
                      (2, 1): (x, y), (2, -1): (x, -y)}[(axis, sign)]
            tu = pad + (pu / DIE + 0.5) * (1 - 2 * pad)
            tv = pad + (pv / DIE + 0.5) * (1 - 2 * pad)
            loop[uv].uv = ((col + tu) / ATLAS_COLS, (row + tv) / ATLAS_ROWS)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    # Harden the flat faces: flat loops get the face normal, bevel loops stay smooth.
    me.update()
    vnorm = [v.normal.copy() for v in me.vertices]
    custom = [None] * len(me.loops)
    for p in me.polygons:
        flat = max(abs(c) for c in p.normal) > 0.999
        for li in p.loop_indices:
            custom[li] = p.normal.copy() if flat else vnorm[me.loops[li].vertex_index]
    me.normals_split_custom_set(custom)
    return me


def tri_count(obj):
    dg = bpy.context.evaluated_depsgraph_get()
    me = obj.evaluated_get(dg).to_mesh()
    n = sum(len(p.vertices) - 2 for p in me.polygons)
    obj.evaluated_get(dg).to_mesh_clear()
    return n


def base_tris(obj):
    """Triangles of the authored mesh, without modifiers (e.g. the outline hull)."""
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def die_rotation(top, yaw_deg):
    return Matrix.Rotation(math.radians(yaw_deg), 3, "Z") @ ROT_TOP[top].to_matrix()


def front_face_value(rot):
    """Face value pointing most toward the camera (world -Y)."""
    best, best_y = None, 9.0
    for (axis, sign), v in FACE_VALUE.items():
        vec = Vector([sign if i == axis else 0 for i in range(3)])
        y = (rot @ vec).y
        if y < best_y:
            best, best_y = v, y
    return best


def rrect_points(w, h, r, seg=6):
    pts = []
    for cx, cy, a0 in ((w / 2 - r, h / 2 - r, 0), (-(w / 2 - r), h / 2 - r, 90),
                       (-(w / 2 - r), -(h / 2 - r), 180), (w / 2 - r, -(h / 2 - r), 270)):
        for i in range(seg + 1):
            a = math.radians(a0 + 90 * i / seg)
            pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


# ------------------------------------------------------------- node helpers
def _sock(sockets, ident):
    return next(s for s in sockets if s.identifier == ident or s.name == ident)


def _tex(nt, img, x=-700, y=0):
    t = nt.nodes.new("ShaderNodeTexImage")
    t.image = img
    t.location = (x, y)
    return t


def _mix(nt, blend, a, b, fac=1.0):
    m = nt.nodes.new("ShaderNodeMix")
    m.data_type = "RGBA"
    m.blend_type = blend
    _sock(m.inputs, "Factor_Float").default_value = fac
    for ident, src in (("A_Color", a), ("B_Color", b)):
        if isinstance(src, (tuple, list)):
            _sock(m.inputs, ident).default_value = tuple(src) + (1.0,) * (4 - len(src))
        else:
            nt.links.new(src, _sock(m.inputs, ident))
    return _sock(m.outputs, "Result_Color")


def _new_mat(name):
    m = bpy.data.materials.get(name)
    if m is not None:
        bpy.data.materials.remove(m)
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    m.node_tree.nodes.clear()
    return m


def pbr_material(name, alb, nrm, orm, glass=False, rim=None, emit=0.0, nstr=1.0):
    """Principled-only material: maps 1:1 to Godot StandardMaterial3D (design D3)."""
    m = _new_mat(name)
    nt = m.node_tree
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    out.location = (400, 0)
    b = nt.nodes.new("ShaderNodeBsdfPrincipled")
    ta, tn, to = _tex(nt, alb, y=300), _tex(nt, nrm, y=0), _tex(nt, orm, y=-300)
    sep = nt.nodes.new("ShaderNodeSeparateColor")
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = nstr
    L = nt.links
    L.new(ta.outputs["Color"], b.inputs["Base Color"])
    L.new(to.outputs["Color"], sep.inputs[0])
    L.new(sep.outputs["Green"], b.inputs["Roughness"])
    L.new(sep.outputs["Blue"], b.inputs["Metallic"])
    L.new(tn.outputs["Color"], nm.inputs["Color"])
    L.new(nm.outputs["Normal"], b.inputs["Normal"])
    L.new(b.outputs[0], out.inputs["Surface"])
    if glass:
        L.new(ta.outputs["Alpha"], b.inputs["Alpha"])
        m.surface_render_method = "BLENDED"
        b.inputs["Specular IOR Level"].default_value = 0.9
    if emit or rim:
        e = _mix(nt, "MULTIPLY", ta.outputs["Color"], (emit, emit, emit), 1.0)
        if rim:
            lw = nt.nodes.new("ShaderNodeLayerWeight")
            lw.inputs["Blend"].default_value = 0.35
            pw = nt.nodes.new("ShaderNodeMath")
            pw.operation = "POWER"
            pw.inputs[1].default_value = 1.6
            L.new(lw.outputs["Facing"], pw.inputs[0])
            rc = _mix(nt, "MULTIPLY", (0, 0, 0), rim, 1.0)
            mm = nt.nodes.new("ShaderNodeMix")
            mm.data_type = "RGBA"
            mm.blend_type = "ADD"
            L.new(pw.outputs[0], _sock(mm.inputs, "Factor_Float"))
            L.new(e, _sock(mm.inputs, "A_Color"))
            _sock(mm.inputs, "B_Color").default_value = tuple(rim) + (1.0,)
            e = _sock(mm.outputs, "Result_Color")
        L.new(e, b.inputs["Emission Color"])
        b.inputs["Emission Strength"].default_value = 1.0
    return m


def toon_material(name, alb, nrm, orm, glass=False, bands=(0.32, 0.62), spec=0.55, nstr=1.0):
    """Toon look for direction C (Godot: diffuse_mode/specular_mode = TOON)."""
    m = _new_mat(name)
    nt = m.node_tree
    L = nt.links
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    ta, tn = _tex(nt, alb, y=300), _tex(nt, nrm, y=0)
    nm = nt.nodes.new("ShaderNodeNormalMap")
    nm.inputs["Strength"].default_value = nstr
    L.new(tn.outputs["Color"], nm.inputs["Color"])
    dif = nt.nodes.new("ShaderNodeBsdfDiffuse")
    L.new(nm.outputs["Normal"], dif.inputs["Normal"])
    s2r = nt.nodes.new("ShaderNodeShaderToRGB")
    L.new(dif.outputs[0], s2r.inputs[0])
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    els = ramp.color_ramp.elements
    els[0].position, els[0].color = 0.0, (0.6, 0.56, 0.72, 1)
    els[1].position, els[1].color = bands[0], (0.86, 0.84, 0.9, 1)
    e3 = els.new(bands[1])
    e3.color = (1.0, 1.0, 1.0, 1)
    L.new(s2r.outputs["Color"], ramp.inputs["Fac"])
    lit = _mix(nt, "MULTIPLY", ta.outputs["Color"], ramp.outputs["Color"], 1.0)
    gl = nt.nodes.new("ShaderNodeBsdfGlossy")
    gl.inputs["Roughness"].default_value = 0.18
    L.new(nm.outputs["Normal"], gl.inputs["Normal"])
    s2r2 = nt.nodes.new("ShaderNodeShaderToRGB")
    L.new(gl.outputs[0], s2r2.inputs[0])
    ramp2 = nt.nodes.new("ShaderNodeValToRGB")
    ramp2.color_ramp.interpolation = "CONSTANT"
    ramp2.color_ramp.elements[0].color = (0, 0, 0, 1)
    ramp2.color_ramp.elements[1].position = 0.55
    ramp2.color_ramp.elements[1].color = (spec, spec, spec, 1)
    L.new(s2r2.outputs["Color"], ramp2.inputs["Fac"])
    col = _mix(nt, "ADD", lit, ramp2.outputs["Color"], 1.0)
    em = nt.nodes.new("ShaderNodeEmission")
    L.new(col, em.inputs["Color"])
    if glass:
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        ms = nt.nodes.new("ShaderNodeMixShader")
        L.new(ta.outputs["Alpha"], ms.inputs[0])
        L.new(tr.outputs[0], ms.inputs[1])
        L.new(em.outputs[0], ms.inputs[2])
        L.new(ms.outputs[0], out.inputs["Surface"])
        m.surface_render_method = "BLENDED"
    else:
        L.new(em.outputs[0], out.inputs["Surface"])
    return m


def flat_material(name, color, alpha=1.0, strength=1.0, cull=False):
    """Unlit color (UI placeholders, neon tubes, outlines)."""
    m = _new_mat(name)
    nt = m.node_tree
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = tuple(color[:3]) + (1.0,)
    em.inputs["Strength"].default_value = strength
    if alpha < 1.0:
        tr = nt.nodes.new("ShaderNodeBsdfTransparent")
        ms = nt.nodes.new("ShaderNodeMixShader")
        ms.inputs[0].default_value = alpha
        nt.links.new(tr.outputs[0], ms.inputs[1])
        nt.links.new(em.outputs[0], ms.inputs[2])
        nt.links.new(ms.outputs[0], out.inputs["Surface"])
        m.surface_render_method = "BLENDED"
    else:
        nt.links.new(em.outputs[0], out.inputs["Surface"])
    m.use_backface_culling = cull
    return m


def image_material(name, img, strength=1.0):
    """Unlit RGBA image (charm icon in the UI row)."""
    m = _new_mat(name)
    nt = m.node_tree
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    t = _tex(nt, img)
    em = nt.nodes.new("ShaderNodeEmission")
    em.inputs["Strength"].default_value = strength
    tr = nt.nodes.new("ShaderNodeBsdfTransparent")
    ms = nt.nodes.new("ShaderNodeMixShader")
    nt.links.new(t.outputs["Color"], em.inputs["Color"])
    nt.links.new(t.outputs["Alpha"], ms.inputs[0])
    nt.links.new(tr.outputs[0], ms.inputs[1])
    nt.links.new(em.outputs[0], ms.inputs[2])
    nt.links.new(ms.outputs[0], out.inputs["Surface"])
    m.surface_render_method = "BLENDED"
    return m


# ================================================================ scene parts
TRAY_W, TRAY_H, RIM_W, RIM_H, FLOOR = 6.6, 8.0, 0.32, 0.34, 0.06
TRAY_Y = 0.17  # world y of the tray centre (screen band 24.5%-73.5%)
SIGN_Y = 5.55  # world y of the neon pictogram band
TEX_DIR = None  # set per frame


def _link(obj, coll=None):
    (coll or bpy.context.scene.collection).objects.link(obj)
    return obj


def _mesh_obj(name, me, mats=()):
    ob = bpy.data.objects.new(name, me)
    for m in mats:
        me.materials.append(m)
    return _link(ob)


def _flat_poly_mesh(name, pts, z=0.0):
    bm = bmesh.new()
    vs = [bm.verts.new((x, y, z)) for x, y in pts]
    bm.faces.new(vs)
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return me


def _ring_mesh(name, outer, inner, z=0.0):
    bm = bmesh.new()
    vo = [bm.verts.new((x, y, z)) for x, y in outer]
    vi = [bm.verts.new((x, y, z)) for x, y in inner]
    n = len(vo)
    for i in range(n):
        bm.faces.new((vo[i], vo[(i + 1) % n], vi[(i + 1) % n], vi[i]))
    me = bpy.data.meshes.new(name)
    bm.to_mesh(me)
    bm.free()
    return me


def tex_set(name, alb, nrm=None, orm=None):
    """Save a texture set under the frame's texture dir; returns Blender images."""
    a = save_image(name + "_albedo", alb, os.path.join(TEX_DIR, name + "_albedo.png"))
    n = save_image(name + "_normal", nrm, os.path.join(TEX_DIR, name + "_normal.png"), True) if nrm is not None else None
    o = save_image(name + "_orm", orm, os.path.join(TEX_DIR, name + "_orm.png"), True) if orm is not None else None
    return a, n, o


def make_tray(cfg):
    """Rounded tray: felt floor (slot 0) + rim (slot 1)."""
    pal = cfg["pal"]
    seg = 8
    outer = rrect_points(TRAY_W, TRAY_H, 0.7, seg)
    inner = rrect_points(TRAY_W - 2 * RIM_W, TRAY_H - 2 * RIM_W, 0.7 - RIM_W, seg)
    bm = bmesh.new()
    vob = [bm.verts.new((x, y, 0.0)) for x, y in outer]
    vot = [bm.verts.new((x, y, RIM_H)) for x, y in outer]
    vit = [bm.verts.new((x, y, RIM_H)) for x, y in inner]
    vib = [bm.verts.new((x, y, FLOOR)) for x, y in inner]
    n = len(outer)
    for i in range(n):
        j = (i + 1) % n
        for quad in ((vob[i], vob[j], vot[j], vot[i]), (vot[i], vot[j], vit[j], vit[i]),
                     (vit[i], vit[j], vib[j], vib[i])):
            bm.faces.new(quad).material_index = 1
    bm.faces.new(list(reversed(vib))).material_index = 0
    bm.normal_update()
    top_ring = [e for e in bm.edges if all(abs(v.co.z - RIM_H) < 1e-6 for v in e.verts)
                and len(e.link_faces) == 2 and any(abs(f.normal.z) < 0.5 for f in e.link_faces)]
    bmesh.ops.bevel(bm, geom=top_ring, offset=0.05, segments=2, affect="EDGES", clamp_overlap=True)
    uv = bm.loops.layers.uv.new("UVMap")
    hw, hh = TRAY_W / 2, TRAY_H / 2
    for f in bm.faces:
        for loop in f.loops:
            x, y, z = loop.vert.co
            if f.material_index == 0:
                loop[uv].uv = ((x + hw - RIM_W) / (TRAY_W - 2 * RIM_W), (y + hh - RIM_W) / (TRAY_H - 2 * RIM_W))
            else:  # rim: planar xy, nudged by height so walls get variation
                loop[uv].uv = ((x + hw) / TRAY_W, (y + hh) / TRAY_H + z * 0.05)
    me = bpy.data.meshes.new("TrayMesh")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = p.material_index == 1 and abs(p.normal.z) < 0.99

    # felt: fibres + mottling + baked wall AO + painted light pool / neon halos
    rng = np.random.default_rng(11)
    S = 1024
    fib = _noise(S, S, 3, rng, 3)
    mot = _noise(S, S, 160, rng, 3)
    u = (np.arange(S) + 0.5) / S
    Ux, Vy = np.meshgrid(u, u)
    wx = (Ux - 0.5) * (TRAY_W - 2 * RIM_W)
    wy = (Vy - 0.5) * (TRAY_H - 2 * RIM_W)
    sd = _rrect_sd(wx, wy, TRAY_W / 2 - RIM_W, TRAY_H / 2 - RIM_W, 0.7 - RIM_W)
    ao = 0.55 + 0.45 * _smooth(0.0, 0.75, -sd)
    col = np.array(pal["felt"])[None, None, :] * (0.86 + 0.2 * fib[..., None]) * (0.9 + 0.2 * mot[..., None])
    light = np.ones_like(sd)
    if cfg.get("felt_pool"):
        a0, a1, r0 = cfg["felt_pool"]
        light = a0 + a1 * np.exp(-(np.hypot(wx, wy - 0.4) / r0) ** 2)
    col = col * (ao * light)[..., None]
    for gcol, side, amt in cfg.get("felt_halos", []):
        wgt = _smooth(-0.3, 0.6, wy / (TRAY_H / 2) * side)
        col = col + np.array(gcol)[None, None, :] * (amt * np.exp(sd / 0.55) * wgt)[..., None]
    fn = _height_to_normal(fib * 0.6 + mot * 0.4, 6.0)
    forms = np.stack([ao, np.full_like(ao, 0.95), np.zeros_like(ao)], -1)
    fa, fnn, fo = tex_set("felt", col, fn, forms)

    R = 512
    rn = _noise(R, R, cfg.get("rim_grain_cell", 20), rng, 4, cfg.get("rim_stretch", (1, 1)))
    amp = cfg.get("rim_noise", 0.4)
    rcol = np.array(pal["rim"])[None, None, :] * (1 - amp / 2 + amp * rn[..., None])
    rorm = np.stack([np.ones_like(rn), np.full_like(rn, cfg["rim_rough"]), np.full_like(rn, cfg["rim_metal"])], -1)
    ra, rnn, ro = tex_set("rim", rcol, _height_to_normal(rn, 3.0), rorm)
    if cfg["toon"]:
        mf = toon_material("M_Felt", fa, fnn, fo, nstr=0.5, spec=0.0)
        mr = toon_material("M_Rim", ra, rnn, ro, spec=0.7)
    else:
        mf = pbr_material("M_Felt", fa, fnn, fo, nstr=0.6)
        mr = pbr_material("M_Rim", ra, rnn, ro)
    tray = _mesh_obj("Tray", me, (mf, mr))
    tray.location = (0, TRAY_Y, 0)
    if cfg["toon"]:
        add_outline(tray, 0.05)
    return tray


def make_table(cfg):
    """Backdrop plane under the tray (a 2D background in-game)."""
    rng = np.random.default_rng(5)
    W, H = 1024, 2048
    tw, th = 14.0, 28.0
    U, V = np.meshgrid((np.arange(W) + 0.5) / W, (np.arange(H) + 0.5) / H)
    wx, wy = (U - 0.5) * tw, (V - 0.5) * th
    pal = cfg["pal"]
    if cfg["table"] == "planks":
        pu = wx / 1.15 + 50
        grain = _noise(H, W, 18, rng, 4, (10, 1))
        tone = (np.sin(np.floor(pu) * 12.9898) * 43758.5453) % 1.0
        col = np.array(pal["table"])[None, None, :] * (0.7 + 0.35 * grain[..., None] + 0.25 * tone[..., None])
        f = pu % 1.0
        gap = np.exp(-f ** 2 / 0.0004) + np.exp(-(f - 1.0) ** 2 / 0.0004)
        col *= (1 - 0.6 * gap)[..., None]
        bump = grain * 0.5 - gap * 0.8
    else:  # arcade carpet: navy with three offset halftone dot grids
        col = np.ones((H, W, 3), np.float32) * np.array(pal["table"])[None, None, :]
        nz = _noise(H, W, 120, rng, 2)
        for cr, ox, oy, pitch, rad in ((pal["carpet1"], 0.0, 0.0, 0.62, 0.11),
                                        (pal["carpet2"], 0.31, 0.2, 0.62, 0.07),
                                        (pal["carpet3"], 0.15, 0.41, 0.93, 0.05)):
            gx = ((wx + ox) / pitch) % 1.0 - 0.5
            gy = ((wy + oy) / pitch) % 1.0 - 0.5
            m = _soft(np.hypot(gx, gy) * pitch - rad * 0.75 * (0.6 + 0.8 * nz), 0.02) * cfg.get("carpet_amt", 0.8)
            col = col * (1 - m[..., None]) + np.array(cr)[None, None, :] * m[..., None]
        bump = nz * 0.2
    if cfg.get("table_pool"):
        a0, a1, r0 = cfg["table_pool"]
        col *= (a0 + a1 * np.exp(-(np.hypot(wx, wy - TRAY_Y) / r0) ** 2))[..., None]
    for gcol, gx, gy, gr, amt in cfg.get("table_halos", []):
        col += np.array(gcol)[None, None, :] * (amt * np.exp(-((wx - gx) ** 2 + (wy - gy) ** 2) / gr ** 2))[..., None]
    nrm = _height_to_normal(bump, 3.0)
    orm = np.stack([np.ones((H, W)), np.full((H, W), 0.7), np.zeros((H, W))], -1).astype(np.float32)
    ta, tn, to = tex_set("table", col, nrm, orm)
    mat = toon_material("M_Table", ta, tn, to, spec=0.0) if cfg["toon"] else pbr_material("M_Table", ta, tn, to, nstr=0.4)
    me = _flat_poly_mesh("TableMesh", [(-tw / 2, -th / 2), (tw / 2, -th / 2), (tw / 2, th / 2), (-tw / 2, th / 2)])
    uvl = me.uv_layers.new(name="UVMap")
    for loop in me.loops:
        x, y, _ = me.vertices[loop.vertex_index].co
        uvl.data[loop.index].uv = (x / tw + 0.5, y / th + 0.5)
    ob = _mesh_obj("Table", me, (mat,))
    ob.location = (0, 0, -0.001)
    return ob


def _tube(name, polylines, mat, depth=0.035, z=0.06):
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = depth
    cu.bevel_resolution = 0
    for pts, cyclic in polylines:
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for i, (x, y) in enumerate(pts):
            sp.points[i].co = (x, y, z, 1)
        sp.use_cyclic_u = cyclic
    tmp = _link(bpy.data.objects.new(name + "_curve", cu))
    dg = bpy.context.evaluated_depsgraph_get()
    me = bpy.data.meshes.new_from_object(tmp.evaluated_get(dg))
    bpy.data.objects.remove(tmp)
    bpy.data.curves.remove(cu)
    return _mesh_obj(name, me, (mat,))


def _circle(cx, cy, r, n=14):
    return [(cx + r * math.cos(2 * math.pi * i / n), cy + r * math.sin(2 * math.pi * i / n)) for i in range(n)]


def neon_die(cx, cy, s):
    loops = [([(cx + x * s, cy + y * s) for x, y in rrect_points(1.0, 1.0, 0.2, 3)], True)]
    for px, py in PIPS[5]:
        loops.append((_circle(cx + (px - 0.5) * s, cy + (py - 0.5) * s, 0.07 * s, 10), True))
    return loops


def neon_bolt(cx, cy, s):
    return [([(cx + (x - 0.5) * s, cy + (y - 0.5) * s) for x, y in BOLT], True)]


def neon_chevrons(cx, cy, s, direction):
    out = []
    for k in (0, 1):
        ox = cx + direction * k * 0.32 * s
        out.append(([(ox - direction * 0.18 * s, cy + 0.3 * s), (ox + direction * 0.12 * s, cy),
                     (ox - direction * 0.18 * s, cy - 0.3 * s)], False))
    return out


def make_neon(cfg):
    objs = []
    for i, (kind, cx, cy, s, col, strength) in enumerate(cfg.get("neon", [])):
        mat = flat_material(f"M_Neon{i}", col, strength=strength)
        if kind == "die":
            pl, depth, z = neon_die(cx, cy, s), 0.03, 0.04
        elif kind == "bolt":
            pl, depth, z = neon_bolt(cx, cy, s), 0.03, 0.04
        elif kind in ("chev_r", "chev_l"):
            pl, depth, z = neon_chevrons(cx, cy, s, 1 if kind == "chev_r" else -1), 0.03, 0.04
        else:  # "rim": strip along the tray rim top; cy = +1 top half, -1 bottom half
            pts = [(x, y + TRAY_Y) for x, y in rrect_points(TRAY_W - RIM_W, TRAY_H - RIM_W, 0.7 - RIM_W / 2, 8)]
            keep = [p for p in pts if (p[1] - TRAY_Y) * cy > -0.15]
            k0 = next(i for i, p in enumerate(pts) if p in keep and pts[i - 1] not in keep)
            ordered = [pts[(k0 + i) % len(pts)] for i in range(len(pts)) if pts[(k0 + i) % len(pts)] in keep]
            pl, depth, z = [(ordered, False)], 0.026, RIM_H + 0.03
        objs.append(_tube(f"Neon{i}", pl, mat, depth=depth, z=z))
    return objs


def make_lock_ring(name, x, y, cfg):
    m = bpy.data.materials.get("M_LockRing") or flat_material("M_LockRing", cfg["pal"]["lock"],
                                                             strength=cfg.get("lock_strength", 2.5))
    ob = _mesh_obj(name, _ring_mesh(name, rrect_points(1.46, 1.46, 0.3, 4), rrect_points(1.32, 1.32, 0.23, 4)), (m,))
    ob.location = (x, y + TRAY_Y, FLOOR + 0.004)
    if cfg["toon"]:
        mo = bpy.data.materials.get("M_LockOutline") or flat_material("M_LockOutline", (0, 0, 0))
        ol = _mesh_obj(name + "_ol", _ring_mesh(name + "_ol", rrect_points(1.54, 1.54, 0.34, 4),
                                                rrect_points(1.24, 1.24, 0.2, 4)), (mo,))
        ol.location = (x, y + TRAY_Y, FLOOR + 0.002)
    return ob


def add_outline(ob, width=0.045):
    """Inverted hull (Godot: next_pass material with grow + cull front)."""
    mo = bpy.data.materials.get("M_Outline") or flat_material("M_Outline", (0.02, 0.0, 0.04), cull=True)
    ob.data.materials.append(mo)
    sol = ob.modifiers.new("Outline", "SOLIDIFY")
    sol.thickness = width
    sol.offset = 1.0
    sol.use_flip_normals = True
    sol.use_rim = False
    sol.material_offset = len(ob.data.materials) - 1
    return sol


# ------------------------------------------------------------------- dice
DIE_MATS = {}


def die_material(cfg, kind, carve=None):
    key = (kind, tuple(sorted((carve or {}).items())))
    if key in DIE_MATS:
        return DIE_MATS[key]
    tag = kind + "".join(f"_{s}{v}" for v, s in sorted((carve or {}).items()))
    alb, nrm, orm = make_die_atlas(kind, cfg["pal"], carve)
    a, n, o = tex_set("die_" + tag, alb, nrm, orm)
    glass = kind == "glass"
    pbr = pbr_material("M_Die_" + tag + "_pbr", a, n, o, glass=glass,
                       rim=cfg["pal"].get("glass_rim") if glass else None,
                       emit=cfg.get("glass_emit", 0.12) if glass else 0.0)
    look = toon_material("M_Die_" + tag, a, n, o, glass=glass) if cfg["toon"] else pbr
    DIE_MATS[key] = (look, pbr)
    return DIE_MATS[key]


def make_die(cfg, name, kind, top, yaw, x, y, z=None, carve_top=None, carve_front=None, rot=None):
    rot = rot if rot is not None else die_rotation(top, yaw)
    carve = {}
    if carve_top:
        carve[top] = carve_top
    if carve_front:
        carve[front_face_value(rot)] = carve_front
    look, pbr = die_material(cfg, kind, carve)
    me = bpy.data.meshes.get("DieMesh") or make_die_mesh("DieMesh")
    ob = _link(bpy.data.objects.new(name, me.copy()))
    ob.data.materials.append(look)
    ob["pbr_material"] = pbr.name
    zc = FLOOR + DIE / 2 if z is None else z
    ob.matrix_world = Matrix.Translation((x, y + TRAY_Y, zc)) @ rot.to_4x4()
    if cfg["toon"]:
        add_outline(ob)
    return ob


def key_tumble(ob, axis, angle_deg, shift=(0, 0, 0)):
    """Keys at frames 0 and 2 so EEVEE motion blur at frame 1 smears the tumble."""
    base = ob.matrix_world.copy()
    pivot = base.translation.copy()
    for f, k in ((0, -0.5), (2, 0.5)):
        rot = Matrix.Rotation(math.radians(angle_deg * k), 4, Vector(axis).normalized())
        ob.matrix_world = Matrix.Translation(pivot + Vector(shift) * k) @ rot @ Matrix.Translation(-pivot) @ base
        ob.keyframe_insert("location", frame=f)
        ob.keyframe_insert("rotation_euler", frame=f)
    ob.matrix_world = base


# --------------------------------------------------------------- charm token
def make_charm_token(cfg, loc):
    """Hair Trigger charm: a medallion with a die + bolt emblem (512² source)."""
    c = cfg["charm"]
    S = 512
    u = (np.arange(S) + 0.5) / S - 0.5
    X, Y = np.meshgrid(u, u)
    r = np.hypot(X, Y)
    aa = 1.5 / S
    col = np.ones((S, S, 3), np.float32) * np.array(c["base"])[None, None, :]
    metal = np.full((S, S), c["base_metal"], np.float32)
    rough = np.full((S, S), 0.35, np.float32)
    hgt = np.zeros((S, S), np.float32)
    ring = _soft(0.40 - r, aa)
    col = col * (1 - ring[..., None]) + np.array(c["rim"])[None, None, :] * ring[..., None]
    metal = metal * (1 - ring) + c["rim_metal"] * ring
    groove = np.exp(-((r - 0.40) / 0.006) ** 2)
    col *= (1 - 0.6 * groove)[..., None]
    sign = -1.0 if c.get("engraved") else 1.0
    dsd = _rrect_sd(X + 0.07, Y - 0.06, 0.17, 0.17, 0.05)
    pips = np.full_like(r, 9.0)
    for k in (-1, 0, 1):  # three pips on the diagonal so the glyph reads as a die
        pips = np.minimum(pips, np.hypot(X + 0.07 + 0.085 * k, Y - 0.06 - 0.085 * k))
    die = np.maximum(_soft(np.abs(dsd) - 0.022, aa), _soft(pips - 0.034, aa))
    poly = [((x - 0.5) * 0.62 + 0.09, (y - 0.5) * 0.62 - 0.05) for x, y in BOLT]
    bsd = _poly_sd(X, Y, poly)
    bolt = _soft(bsd, aa)
    bolt_ol = _soft(np.abs(bsd) - 0.02, aa) * (1 - bolt)
    for mask, mc in ((die, c["die"]), (bolt_ol, c["outline_col"]), (bolt, c["bolt"])):
        col = col * (1 - mask[..., None]) + np.array(mc)[None, None, :] * mask[..., None]
        metal *= 1 - mask
        rough = rough * (1 - mask) + 0.3 * mask
    emblem = np.maximum(np.maximum(die, bolt), bolt_ol)
    hgt += sign * 0.5 * emblem
    shade = 0.92 + 0.08 * _smooth(0.5, 0.0, r)
    col *= shade[..., None]
    alb = np.concatenate([col, np.ones((S, S, 1), np.float32)], -1)
    a, n, o = tex_set("charm_hair_trigger", alb, _height_to_normal(hgt, 14.0),
                      np.stack([np.ones_like(r), rough, metal], -1))
    if cfg["toon"]:
        mat = toon_material("M_Charm", a, n, o, spec=0.6)
    else:
        mat = pbr_material("M_Charm", a, n, o, emit=c.get("emit", 0.0))
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=32, radius1=0.5, radius2=0.5, depth=0.12)
    rims = [e for e in bm.edges if len(e.link_faces) == 2 and
            abs(e.link_faces[0].normal.z - e.link_faces[1].normal.z) > 0.5]
    bmesh.ops.bevel(bm, geom=rims, offset=0.03, segments=2, affect="EDGES", clamp_overlap=True)
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for loop in f.loops:
            x, y, _ = loop.vert.co
            loop[uv].uv = (x + 0.5, y + 0.5)
    me = bpy.data.meshes.new("CharmMesh")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = abs(p.normal.z) < 0.99
    ob = _mesh_obj("Charm_HairTrigger", me, (mat,))
    ob.location = loc
    if cfg["toon"]:
        add_outline(ob, 0.03)
    return ob


# ------------------------------------------------------------------ camera/UI
def make_camera(name, scale, target):
    cam = bpy.data.cameras.new(name)
    cam.type = "ORTHO"
    cam.ortho_scale = scale
    cam.clip_start = 0.1
    cam.clip_end = 200.0
    ob = _link(bpy.data.objects.new(name, cam))
    t = math.radians(TILT_DEG)
    fwd = Vector((0, math.sin(t), -math.cos(t)))
    ob.location = Vector(target) - fwd * 40.0
    ob.rotation_euler = (t, 0, 0)
    return ob


def ui_rect(cam, name, x, y, w, h, r, mat, z=-2.0):
    r = max(0.0, min(r, w / 2 - 1e-4, h / 2 - 1e-4))
    pts = rrect_points(w, h, r, 6) if r > 0 else [(w / 2, h / 2), (-w / 2, h / 2), (-w / 2, -h / 2), (w / 2, -h / 2)]
    ob = _mesh_obj(name, _flat_poly_mesh(name, pts), (mat,))
    ob.parent = cam
    ob.location = (x, y, z)
    return ob


def ui_panel(cam, ui, name, x, y, w, h, fill=None, outline=True, r=None):
    r = ui["radius"] if r is None else r
    mats = UI_MATS
    if ui.get("shadow"):
        ui_rect(cam, name + "_shadow", x + 0.07, y - 0.09, w + 2 * ui["ow"], h + 2 * ui["ow"], r + ui["ow"],
                mats["shadow"], z=-2.06)
    if outline:  # a ring, so translucent panels don't show a filled rect through them
        ow = ui["ow"]
        rr = max(0.01, min(r, w / 2 - 1e-3, h / 2 - 1e-3))
        ring = _ring_mesh(name + "_ol", rrect_points(w + 2 * ow, h + 2 * ow, rr + ow, 6), rrect_points(w, h, rr, 6))
        ol = _mesh_obj(name + "_ol", ring, (mats["outline"],))
        ol.parent = cam
        ol.location = (x, y, -2.0)
    return ui_rect(cam, name, x, y, w, h, r, fill or mats["panel"])


UI_MATS = {}


def build_ui(cam, cfg, icon_img):
    """Neutral placeholder HUD (no text): PRD §5 bands, camera-space units."""
    ui = cfg["ui"]
    UI_MATS.clear()
    UI_MATS.update({
        "panel": flat_material("M_UI_Panel", ui["panel"], alpha=ui["panel_a"]),
        "outline": flat_material("M_UI_Outline", ui["outline"], strength=ui.get("outline_strength", 1.0)),
        "bar": flat_material("M_UI_Bar", ui["bar"], alpha=ui["bar_a"]),
        "accent": flat_material("M_UI_Accent", ui["accent"], strength=ui.get("accent_strength", 1.0)),
        "button": flat_material("M_UI_Button", ui["button"], strength=ui.get("button_strength", 1.0)),
        "label": flat_material("M_UI_Label", ui["label"]),
        "track": flat_material("M_UI_Track", ui["panel"], alpha=min(1.0, ui["panel_a"] + 0.1)),
        "shadow": flat_material("M_UI_Shadow", (0.0, 0.0, 0.0), alpha=0.85),
    })
    m = UI_MATS
    # HUD band (top): ante | score | target
    for nm, x, w in (("Ante", -2.47, 1.75), ("Score", 0.0, 2.85), ("Target", 2.47, 1.75)):
        ui_panel(cam, ui, "HUD_" + nm, x, 6.9, w, 1.5)
        ui_rect(cam, "HUD_" + nm + "_label", x, 7.27, w * 0.5, 0.14, 0.07, m["bar"], z=-1.99)
        if nm == "Score":
            ui_rect(cam, "HUD_Score_value", x, 6.72, w * 0.78, 0.62, 0.12, m["accent"], z=-1.99)
        else:
            ui_rect(cam, "HUD_" + nm + "_value", x, 6.76, w * 0.7, 0.42, 0.1, m["bar"], z=-1.99)
    # lock-window progress: 3 window pips + draining timer bar
    for i in range(3):
        mat = m["accent"] if i < 2 else m["track"]
        ui_rect(cam, f"Window{i}", 2.62 + i * 0.36, 4.74, 0.2, 0.2, 0.1, mat, z=-1.99)
    ui_rect(cam, "Timer_track", 0.0, 4.42, 6.7, 0.17, 0.085, m["track"])
    fill_w = 6.7 * 0.58
    ui_rect(cam, "Timer_fill", -3.35 + fill_w / 2, 4.42, fill_w, 0.17, 0.085, m["accent"], z=-1.99)
    # charm row (5 slots, Hair Trigger in slot 1)
    for i, x in enumerate((-2.6, -1.3, 0.0, 1.3, 2.6)):
        ui_panel(cam, ui, f"Charm{i}", x, -4.72, 1.08, 1.08, r=ui["radius"] * 1.2)
    icon = ui_rect(cam, "Charm0_icon", -2.6, -4.72, 1.0, 1.0, 0.0, image_material("M_UI_Icon", icon_img), z=-1.98)
    icon.data.uv_layers.new(name="UVMap")
    for loop in icon.data.loops:
        x, y, _ = icon.data.vertices[loop.vertex_index].co
        icon.data.uv_layers[0].data[loop.index].uv = (x + 0.5, y + 0.5)
    # bottom: bag counter | THROW | trinkets
    ui_panel(cam, ui, "Bag", -2.72, -6.55, 1.05, 1.05, r=0.52)
    ui_rect(cam, "Bag_glyph", -2.72, -6.55, 0.38, 0.38, 0.09, m["bar"], z=-1.99)
    ui_panel(cam, ui, "Throw", 0.0, -6.55, 3.3, 1.15, fill=m["button"], r=0.575)
    ui_rect(cam, "Throw_label", 0.0, -6.55, 1.5, 0.24, 0.12, m["label"], z=-1.99)
    for i, x in enumerate((2.38, 3.1)):
        ui_panel(cam, ui, f"Trinket{i}", x, -6.55, 0.62, 0.62, r=ui["radius"])


# --------------------------------------------------------------- lights/world
def make_world_and_lights(cfg):
    sc = bpy.context.scene
    w = bpy.data.worlds.get("LockdownWorld") or bpy.data.worlds.new("LockdownWorld")
    sc.world = w
    w.use_nodes = True
    bg = next(n for n in w.node_tree.nodes if n.type == "BACKGROUND")
    bg.inputs["Color"].default_value = tuple(cfg["ambient"][0]) + (1.0,)
    bg.inputs["Strength"].default_value = cfg["ambient"][1]
    out = []
    for i, L in enumerate(cfg["lights"]):
        ld = bpy.data.lights.new(f"L{i}_{L['type']}", L["type"])
        ld.color = L["color"]
        ld.energy = L["energy"]
        for k, v in L.get("extra", {}).items():
            setattr(ld, k, v)
        ob = _link(bpy.data.objects.new(ld.name, ld))
        if "loc" in L:
            ob.location = L["loc"]
        if "dir" in L:
            ob.rotation_euler = Vector(L["dir"]).normalized().to_track_quat("-Z", "Y").to_euler()
        out.append(ob)
    return out


# -------------------------------------------------------------- render + post
RAW = os.path.join(bpy.app.tempdir or os.environ.get("TEMP", "."), "lockdown_raw")


def setup_render(cfg):
    sc = bpy.context.scene
    try:
        sc.render.engine = "BLENDER_EEVEE"
    except TypeError as e:
        print("engine:", e)
    sc.eevee.taa_render_samples = cfg.get("samples", 48)
    sc.view_settings.view_transform = "Standard"
    sc.view_settings.look = "None"
    sc.view_settings.exposure = cfg.get("exposure", 0.0)
    sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.motion_blur_shutter = 0.6
    sc.frame_start, sc.frame_end = 0, 2


def render_to(path, res, cam, transparent=False, motion_blur=False, subframes=16, shutter=0.6):
    """Render frame 1. Motion blur is accumulated from sub-frame renders, because EEVEE's
    velocity-buffer blur skips alpha-blended surfaces (the Glass dice)."""
    sc = bpy.context.scene
    sc.camera = cam
    sc.render.resolution_x, sc.render.resolution_y = res
    sc.render.film_transparent = transparent
    sc.render.use_motion_blur = False
    os.makedirs(os.path.dirname(path), exist_ok=True)
    if not motion_blur:
        sc.frame_set(1)
        sc.render.filepath = path
        bpy.ops.render.render(write_still=True)
        return path
    acc = None
    tmp = path[:-4] + "_sub.png"
    for s in np.linspace(-shutter / 2, shutter / 2, subframes):
        f = 1.0 + float(s)
        sc.frame_set(int(math.floor(f)), subframe=f - math.floor(f))
        sc.render.filepath = tmp
        bpy.ops.render.render(write_still=True)
        px = load_pixels(tmp)
        acc = px if acc is None else acc + px
    sc.frame_set(1)
    save_image("accum", acc / subframes, path)
    return path


def post(src, dst, p):
    """Single overlay (design D6): bloom, chroma offset, scanlines, vignette, grain."""
    a = load_pixels(src)
    rgb = a[..., :3].copy()
    h, w = rgb.shape[:2]
    lum = rgb.max(-1)
    sat = lum - rgb.min(-1)
    wgt = _smooth(p["bloom_th"], p["bloom_th"] + 0.2, lum) * (0.2 + 0.8 * np.clip(sat * 2, 0, 1))
    f = 4
    hs, ws = h // f, w // f
    small = (rgb * wgt[..., None])[:hs * f, :ws * f].reshape(hs, f, ws, f, 3).mean((1, 3))
    glow = _blur(small, max(1, p["bloom_r"] // f)) + 0.6 * _blur(small, max(1, 3 * p["bloom_r"] // f))
    rgb += p["bloom"] * np.stack([_resize(glow[..., c], h, w) for c in range(3)], -1)
    k = p.get("chroma", 0)
    if k:
        rgb[..., 0] = np.roll(rgb[..., 0], k, axis=1)
        rgb[..., 2] = np.roll(rgb[..., 2], -k, axis=1)
    if p.get("scan"):
        y = np.arange(h, dtype=np.float32)
        rgb *= (1 - p["scan"] * (0.5 + 0.5 * np.cos(2 * np.pi * y / p["scan_period"])))[:, None, None]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.hypot((xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2)) / 1.414
    rgb *= (1 - p["vig"] * _smooth(0.3, 1.0, d))[..., None]
    g = np.random.default_rng(3).normal(0, 1, (h, w)).astype(np.float32)
    mid = 0.35 + 0.65 * (1 - np.abs(rgb.mean(-1) - 0.5) * 2)
    rgb += (p["grain"] * g * mid)[..., None]
    out = np.concatenate([np.clip(rgb, 0, 1), np.ones((h, w, 1), np.float32)], -1)
    save_image("post_out", out, dst)
    return out


def downsample2(arr):
    h, w, c = arr.shape
    return arr[:h // 2 * 2, :w // 2 * 2].reshape(h // 2, 2, w // 2, 2, c).mean((1, 3))


# --------------------------------------------------------- readability strip
STRIP_YAW = [12, -10, 20, -8, 8]
STRIP_DICE = [("bone", 5, None, None), ("iron", 3, None, None), ("glass", 5, None, None),
              ("bone", 1, "wild", None), ("glass", 1, "spark", None)]


def readability_strip(cfg, key, dst):
    ox = 60.0
    sw, sh = 1100, 300
    felt = bpy.data.materials["M_Felt"]
    me = _flat_poly_mesh("StripFelt", [(-6, -2.5), (6, -2.5), (6, 2.5), (-6, 2.5)])
    uvl = me.uv_layers.new(name="UVMap")
    for loop in me.loops:
        x, y, _ = me.vertices[loop.vertex_index].co
        uvl.data[loop.index].uv = (0.5 + x / 20.0, 0.5 + y / 14.0)
    plane = _mesh_obj("StripFelt", me, (felt,))
    plane.location = (ox, 0, FLOOR)
    dice = []
    for i, (kind, top, ct, cf) in enumerate(STRIP_DICE):
        dice.append(make_die(cfg, f"Strip{i}", kind, top, STRIP_YAW[i], ox + (i - 2) * 1.6, -TRAY_Y,
                             z=FLOOR * 2 + DIE / 2, carve_top=ct, carve_front=cf))
    sl = cfg["strip_light"]
    ld = bpy.data.lights.new("StripKey", "POINT")
    ld.color, ld.energy, ld.shadow_soft_size = sl[0], sl[1], 1.0
    lo = _link(bpy.data.objects.new("StripKey", ld))
    lo.location = (ox - 2.0, 2.0, 5.0)
    cam = make_camera("StripCam", sw / 126.0, (ox, 0, 0.5))
    p1 = render_to(os.path.join(RAW, f"{key}_strip_settled.png"), (sw, sh), cam)
    for i, d in enumerate(dice):
        key_tumble(d, (1, 0.5 + 0.2 * i, 0.3), 95, (0.25, 0.1, 0))
    p2 = render_to(os.path.join(RAW, f"{key}_strip_blur.png"), (sw, sh), cam, motion_blur=True, subframes=32)
    settled = load_pixels(p1)[..., :3]
    blur = load_pixels(p2)[..., :3]
    gray = (settled @ np.array([0.2126, 0.7152, 0.0722], np.float32))[..., None].repeat(3, -1)
    gap = np.full((12, sw, 3), 0.04, np.float32)
    # rows top->bottom: colour, grayscale, motion blur (arrays are bottom-first)
    sheet = np.concatenate([blur, gap, gray, gap, settled], 0)
    save_image("strip_out", np.concatenate([sheet, np.ones(sheet.shape[:2] + (1,), np.float32)], -1), dst)
    for ob in dice + [plane, lo, cam]:
        bpy.data.objects.remove(ob)
    return dst


# -------------------------------------------------------------------- export
EXPORT_DICE = [("bone", 5, None, None), ("bone", 1, "wild", None), ("iron", 3, None, None),
               ("glass", 5, None, None), ("glass", 1, "spark", None)]


def export_glb(cfg, path):
    """Dice variants with their Principled materials (glTF + Godot preview)."""
    objs = []
    me_src = bpy.data.meshes["DieMesh"]
    for i, (kind, top, ct, cf) in enumerate(EXPORT_DICE):
        rot = die_rotation(top, 0)
        carve = {}
        if ct:
            carve[top] = ct
        if cf:
            carve[front_face_value(rot)] = cf
        _, pbr = die_material(cfg, kind, carve)
        tag = kind + "".join(f"_{s}" for _, s in sorted(carve.items()))
        ob = _link(bpy.data.objects.new("die_" + tag, me_src.copy()))
        ob.data.materials.append(pbr)
        ob.matrix_world = Matrix.Translation(((i - 2) * 1.5, 0, DIE / 2)) @ rot.to_4x4()
        objs.append(ob)
    for ob in bpy.context.view_layer.objects:
        ob.select_set(False)
    for ob in objs:
        ob.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=path, use_selection=True, export_format="GLB", export_apply=False,
                              export_yup=True, export_animations=False, export_cameras=False, export_lights=False)
    stats = [(ob.name, tri_count(ob)) for ob in objs]
    for ob in objs:
        bpy.data.objects.remove(ob)
    return stats


# --------------------------------------------------------------- asset sheet
def write_asset_sheet(cfg, key, path, stats):
    pal = cfg["pal"]
    lines = [f"# Style frame {key}: {cfg['title']}", "", cfg["pitch"], "",
             f"![frame](frame_{key.lower()}_{cfg['slug']}.png)", "",
             "## Palette", "", "| Role | Hex |", "|---|---|"]
    for k, v in pal.items():
        lines.append(f"| {k} | `{hexcol(v)}` |")
    lines += ["", "## Geometry (triangles)", "", "| Asset | Tris | Budget |", "|---|---|---|"]
    for name, n, budget in stats["geo"]:
        lines.append(f"| {name} | {n} | {budget} |")
    lines += ["", "## Textures", "", "| File | Size |", "|---|---|"]
    for f, wh in stats["tex"]:
        lines.append(f"| `{f}` | {wh[0]}×{wh[1]} |")
    lines += ["", "## Lighting (game budget: 1 directional + 2 omni/spot)", ""]
    for L in cfg["lights"]:
        lines.append(f"- {L['type']}: color {hexcol(L['color'])}, energy {L['energy']}")
    lines.append(f"- ambient {hexcol(cfg['ambient'][0])} × {cfg['ambient'][1]}")
    lines += ["", "## Overlay (one canvas shader + optional glow)", ""]
    lines += [f"- `{k}` = {v}" for k, v in cfg["post"].items()]
    lines += ["", "## Draw-call estimate (full 8-die tray)", "", stats["draws"], "",
              "## Godot mapping notes", ""] + [f"- {n}" for n in cfg["godot_notes"]]
    lines += ["", "## Local Godot check (GL Compatibility, desktop)", "",
              f"![godot vs blender](gltf/preview/dice_{key.lower()}_{cfg['slug']}_compare.png)", "",
              "- Top: `tools/art_preview.gd` render of the exported `.glb`; bottom: the same `.glb` re-imported "
              "into Blender under matching neutral light. Materials, alpha Glass and normals carry over.",
              "- Finding: S3TC/ETC2 4×4 block compression stair-steps saturated carved-inlay edges on Glass. "
              "For integration, import die atlases as ASTC 4×4 on mobile or lossless (≤ 1.5 MB per atlas).",
              "- Godot renders Bone slightly brighter (ambient/tonemap difference). Cosmetic; tune in the environment."]
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("\n".join(lines) + "\n")


# ---------------------------------------------------------------- frame build
def reset_scene():
    for ob in list(bpy.data.objects):
        bpy.data.objects.remove(ob)
    for coll in (bpy.data.meshes, bpy.data.materials, bpy.data.lights, bpy.data.cameras,
                 bpy.data.curves, bpy.data.actions):
        for b in list(coll):
            coll.remove(b)
    for img in list(bpy.data.images):
        if img.type == "IMAGE":
            bpy.data.images.remove(img)
    DIE_MATS.clear()


FRAME_DICE = [  # name, kind, top, yaw, x, y, locked, carve_top, carve_front
    ("Die_Bone1", "bone", 5, 8, -1.75, 2.2, True, None, None),
    ("Die_BoneWild", "bone", 1, -6, 0.0, 2.25, True, "wild", None),
    ("Die_Bone2", "bone", 5, 14, 1.75, 2.15, True, None, None),
    ("Die_Iron", "iron", 3, -12, -1.25, -0.05, False, None, None),
    ("Die_GlassSpark", "glass", 1, 28, 1.3, -0.15, False, "spark", None),
]


def build_scene(key):
    global TEX_DIR
    cfg = DIRECTIONS[key]
    TEX_DIR = os.path.join(OUT, "textures", f"frame_{key.lower()}")
    shutil.rmtree(TEX_DIR, ignore_errors=True)  # no stale variants from earlier builds
    reset_scene()
    setup_render(cfg)
    make_table(cfg)
    make_tray(cfg)
    make_neon(cfg)
    dice = []
    for name, kind, top, yaw, x, y, locked, ct, cf in FRAME_DICE:
        dice.append(make_die(cfg, name, kind, top, yaw, x, y, carve_top=ct, carve_front=cf))
        if locked:
            make_lock_ring("Lock_" + name, x, y, cfg)
    tumble = make_die(cfg, "Die_GlassTumble", "glass", 4, 0, 0.3, -2.3, z=1.35,
                      rot=Euler((math.radians(35), math.radians(25), math.radians(50))).to_matrix())
    key_tumble(tumble, (1, 0.4, 0.2), 110, (0.45, 0.25, 0))
    dice.append(tumble)
    make_world_and_lights(cfg)
    token = make_charm_token(cfg, (100.0, 0.0, 0.06))
    return cfg, dice, token


def render_frame(key, cfg, token):
    icon_cam = make_camera("IconCam", 1.03, (100.0, 0.0, 0.1))
    icon_cam.rotation_euler = (math.radians(10), 0, 0)
    icon_cam.location = Vector((100.0, -40 * math.sin(math.radians(10)), 40 * math.cos(math.radians(10))))
    kl = bpy.data.lights.new("IconKey", "POINT")
    kl.color, kl.energy, kl.shadow_soft_size = cfg["strip_light"][0], 120.0, 1.5
    key_ob = _link(bpy.data.objects.new("IconKey", kl))
    key_ob.location = (99.0, -1.2, 2.6)
    icon_src = render_to(os.path.join(RAW, f"{key}_icon512.png"), (512, 512), icon_cam, transparent=True)
    bpy.data.objects.remove(key_ob)
    icon512 = load_pixels(icon_src)
    slug = cfg["slug"]
    save_image("icon512", icon512, os.path.join(OUT, "textures", f"frame_{key.lower()}", "charm_icon_512.png"))
    icon256 = save_image("icon256", downsample2(icon512),
                         os.path.join(OUT, f"frame_{key.lower()}_charm_icon.png"))
    cam = make_camera("FrameCam", ORTHO_SCALE, (0, 0, 0))
    build_ui(cam, cfg, icon256)
    raw = render_to(os.path.join(RAW, f"{key}_frame_raw.png"), (FRAME_W, FRAME_H), cam, motion_blur=True)
    post(raw, os.path.join(OUT, f"frame_{key.lower()}_{slug}.png"), cfg["post"])
    return cam


def finish_frame(key, cfg, dice, token):
    slug = cfg["slug"]
    readability_strip(cfg, key, os.path.join(OUT, f"frame_{key.lower()}_readability.png"))
    exp = export_glb(cfg, os.path.join(OUT, "gltf", f"dice_{key.lower()}_{slug}.glb"))
    tray = bpy.data.objects["Tray"]
    neon_tris = sum(tri_count(o) for o in bpy.data.objects if o.name.startswith("Neon"))
    geo = [("Die (each)", exp[0][1], 300), ("Tray", base_tris(tray), 2000),
           ("Charm token", base_tris(token), "n/a (icon is 2D)"), ("Neon tubes (all)", neon_tris, "n/a")]
    if cfg["toon"]:
        geo.append(("Die + outline hull", tri_count(dice[0]), "hull = 2nd pass"))
    tex = []
    tdir = os.path.join(OUT, "textures", f"frame_{key.lower()}")
    for f in sorted(os.listdir(tdir)):
        img = bpy.data.images.load(os.path.join(tdir, f), check_existing=False)
        tex.append((f"textures/frame_{key.lower()}/{f}", tuple(img.size)))
        bpy.data.images.remove(img)
    n_neon = len([o for o in bpy.data.objects if o.name.startswith("Neon")])
    per_die = 2 if cfg["toon"] else 1
    total = 8 * per_die + 2 + (1 if cfg["toon"] else 0) + 1 + n_neon + 1
    draws = (f"8 dice × {per_die} = {8 * per_die}, tray 2{' + 1 hull' if cfg['toon'] else ''}, backdrop 1, "
             f"neon {n_neon}, lock rings 1 (MultiMesh) → **~{total}** (+ directional shadow pass over dice/tray). "
             "UI is 2D canvas, batched separately.")
    write_asset_sheet(cfg, key, os.path.join(OUT, f"frame_{key.lower()}_{slug}.md"),
                      {"geo": geo, "tex": tex, "draws": draws})
    save_blend(os.path.join(OUT, "source", f"frame_{key.lower()}_{slug}.blend"))
    return geo, exp


def save_blend(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    base = os.path.dirname(path)
    absolute = {}
    for img in bpy.data.images:
        if img.filepath and os.path.isabs(bpy.path.abspath(img.filepath)):
            absolute[img.name] = img.filepath
            img.filepath = "//" + os.path.relpath(bpy.path.abspath(img.filepath), base).replace("\\", "/")
    bpy.ops.wm.save_as_mainfile(filepath=path, copy=True)
    if os.path.exists(path + "1"):  # Blender's previous-version backup; not an asset
        os.remove(path + "1")
    for img in bpy.data.images:
        if img.name in absolute:
            img.filepath = absolute[img.name]


# ---------------------------------------------------------------- directions
MAG, CYAN = (1.0, 0.12, 0.62), (0.18, 0.92, 1.0)
AMBER, BRASS = (1.0, 0.62, 0.16), (0.80, 0.60, 0.30)
PINK, MINT, YELLOW = (1.0, 0.22, 0.58), (0.25, 1.0, 0.72), (1.0, 0.80, 0.10)

DIRECTIONS = {
    "A": {
        "title": "Felt & Neon", "slug": "felt_neon", "toon": False,
        "pitch": "The PRD candidate played straight: deep-teal felt under warm tungsten light, "
                 "magenta/cyan neon on the rim and table, light CRT grain.",
        "pal": {"felt": (0.04, 0.37, 0.37), "rim": (0.035, 0.03, 0.04), "table": (0.09, 0.07, 0.08),
                "bone": (0.92, 0.86, 0.74), "bone_pip": (0.09, 0.05, 0.07), "bone_pip1": (0.86, 0.06, 0.36),
                "iron": (0.33, 0.36, 0.40), "iron_pip": (0.82, 0.97, 1.0),
                "glass": (0.22, 0.86, 0.96), "glass_pip": (0.98, 0.99, 1.0), "glass_rim": (0.4, 0.95, 1.0),
                "carve_wild": (1.0, 0.76, 0.28), "carve_gem": (0.95, 0.12, 0.38), "carve_spark": (1.0, 0.24, 0.72),
                "lock": CYAN, "neon_magenta": MAG, "neon_cyan": CYAN},
        "rim_rough": 0.22, "rim_metal": 0.0, "rim_grain_cell": 60, "rim_noise": 0.12,
        "table": "planks",
        "felt_halos": [(MAG, 1, 0.16), (CYAN, -1, 0.16)],
        "table_halos": [(MAG, -1.65, SIGN_Y, 1.1, 0.22), (CYAN, 0.0, SIGN_Y, 1.0, 0.22),
                        (MAG, 1.65, SIGN_Y, 1.1, 0.22), (MAG, 0.0, TRAY_Y + 4.3, 3.2, 0.10),
                        (CYAN, 0.0, TRAY_Y - 4.3, 3.2, 0.10)],
        "neon": [("rim", 0, 1, 0, MAG, 1.6), ("rim", 0, -1, 0, CYAN, 1.6),
                 ("die", -1.65, SIGN_Y, 0.95, MAG, 1.6), ("bolt", 0.0, SIGN_Y, 1.15, CYAN, 1.6),
                 ("die", 1.65, SIGN_Y, 0.95, MAG, 1.6)],
        "lights": [
            {"type": "SUN", "color": (1.0, 0.84, 0.64), "energy": 3.2, "dir": (0.55, -0.6, -1.6), "extra": {"angle": 0.12}},
            {"type": "POINT", "color": MAG, "energy": 260.0, "loc": (-3.4, 5.2, 1.6), "extra": {"shadow_soft_size": 0.6}},
            {"type": "POINT", "color": CYAN, "energy": 260.0, "loc": (3.4, -4.6, 1.6), "extra": {"shadow_soft_size": 0.6}},
        ],
        "ambient": ((0.03, 0.07, 0.08), 1.0),
        "strip_light": ((1.0, 0.84, 0.64), 500.0),
        "glass_emit": 0.12,
        "ui": {"panel": (0.015, 0.05, 0.06), "panel_a": 0.8, "outline": CYAN, "ow": 0.028, "outline_strength": 1.4,
               "bar": (0.55, 0.78, 0.8), "bar_a": 0.5, "accent": MAG, "button": (0.92, 0.1, 0.56),
               "label": (0.12, 0.0, 0.07), "radius": 0.22},
        "charm": {"base": (0.03, 0.03, 0.05), "base_metal": 0.0, "rim": (0.42, 0.45, 0.52), "rim_metal": 0.9,
                  "die": CYAN, "bolt": MAG, "outline_col": (0.02, 0.02, 0.03), "emit": 0.55},
        "post": {"bloom_th": 0.72, "bloom": 0.6, "bloom_r": 20, "chroma": 1, "scan": 0.05, "scan_period": 3,
                 "vig": 0.35, "grain": 0.035},
        "godot_notes": ["Dice/tray/backdrop: StandardMaterial3D (albedo + normal + ORM).",
                        "Glass: transparency ALPHA, rim 0.5, emission from albedo ×0.12 (or 10-line fresnel shader).",
                        "Neon tubes: unshaded emissive; halos painted into felt/backdrop textures, so glow is optional.",
                        "Overlay: one CanvasItem shader (grain + scanlines + vignette + 1 px chroma) + Compatibility glow."],
    },
    "B": {
        "title": "Smoke Room", "slug": "smoke_room", "toon": False,
        "pitch": "Restraint test: oxblood felt in a single hard lamp pool, near-black surroundings, "
                 "one amber accent, heavy contrast and film grain.",
        "pal": {"felt": (0.36, 0.05, 0.06), "rim": (0.13, 0.05, 0.035), "table": (0.11, 0.065, 0.04),
                "bone": (0.88, 0.80, 0.64), "bone_pip": (0.12, 0.06, 0.04), "bone_pip1": (0.52, 0.06, 0.05),
                "iron": (0.27, 0.27, 0.28), "iron_pip": (0.98, 0.84, 0.56),
                "glass": (0.98, 0.64, 0.22), "glass_pip": (1.0, 0.97, 0.9), "glass_rim": (1.0, 0.75, 0.4),
                "carve_wild": (0.96, 0.72, 0.32), "carve_gem": (0.75, 0.08, 0.12), "carve_spark": (1.0, 0.97, 0.88),
                "lock": AMBER, "brass": BRASS},
        "rim_rough": 0.5, "rim_metal": 0.0, "rim_grain_cell": 12, "rim_noise": 0.3,
        "table": "planks", "felt_pool": (0.42, 0.9, 3.0), "table_pool": (0.06, 1.0, 5.5),
        "table_halos": [(AMBER, 0.0, SIGN_Y, 0.9, 0.12)],
        "neon": [("die", 0.0, SIGN_Y, 0.85, AMBER, 1.5)],
        "lights": [
            {"type": "SPOT", "color": (1.0, 0.86, 0.66), "energy": 3200.0, "loc": (0.4, 1.4, 9.0),
             "dir": (-0.05, -0.15, -1.0), "extra": {"spot_size": math.radians(48), "spot_blend": 0.45,
                                                     "shadow_soft_size": 0.35}},
            {"type": "SUN", "color": (0.6, 0.7, 1.0), "energy": 0.25, "dir": (-0.4, 0.5, -1.0), "extra": {"angle": 0.2}},
        ],
        "ambient": ((0.012, 0.009, 0.009), 1.0),
        "strip_light": ((1.0, 0.86, 0.66), 650.0),
        "glass_emit": 0.18,
        "ui": {"panel": (0.055, 0.03, 0.025), "panel_a": 0.9, "outline": BRASS, "ow": 0.018,
               "bar": (0.92, 0.82, 0.64), "bar_a": 0.45, "accent": AMBER, "button": (0.36, 0.05, 0.05),
               "label": (0.92, 0.82, 0.64), "radius": 0.1},
        "charm": {"base": (0.86, 0.64, 0.30), "base_metal": 0.35, "rim": (0.60, 0.42, 0.18), "rim_metal": 0.5,
                  "die": (0.12, 0.06, 0.03), "bolt": (0.5, 0.06, 0.05), "outline_col": (0.12, 0.06, 0.03),
                  "engraved": True},
        "post": {"bloom_th": 0.8, "bloom": 0.35, "bloom_r": 16, "chroma": 0, "scan": 0.0, "scan_period": 3,
                 "vig": 0.6, "grain": 0.07},
        "godot_notes": ["Lamp pool is painted into felt/backdrop, so the spot light is optional (can be 1 directional).",
                        "Glass: transparency ALPHA + rim; amber tint stays readable over oxblood thanks to value contrast.",
                        "Overlay: grain + strong vignette only (cheapest of the three)."],
    },
    "C": {
        "title": "Arcade Cabinet", "slug": "arcade", "toon": True,
        "pitch": "Graphic and bold: saturated violet felt, toon-banded shading with thick outlines, "
                 "arcade-carpet backdrop, scanline overlay. Most readable by construction.",
        "pal": {"felt": (0.36, 0.12, 0.62), "rim": (1.0, 0.70, 0.08), "table": (0.05, 0.035, 0.14),
                "carpet1": PINK, "carpet2": MINT, "carpet3": YELLOW,
                "bone": (1.0, 0.95, 0.85), "bone_pip": (0.12, 0.05, 0.22), "bone_pip1": PINK,
                "iron": (0.34, 0.36, 0.46), "iron_pip": MINT,
                "glass": (1.0, 0.36, 0.66), "glass_pip": (1.0, 1.0, 1.0), "glass_rim": (1.0, 0.6, 0.85),
                "carve_wild": YELLOW, "carve_gem": (0.2, 0.9, 1.0), "carve_spark": MINT,
                "lock": MINT},
        "rim_rough": 0.3, "rim_metal": 0.0, "rim_grain_cell": 200, "rim_noise": 0.1,
        "table": "carpet", "carpet_amt": 0.38,
        "felt_halos": [],
        "neon": [("chev_r", -1.75, SIGN_Y, 1.0, MINT, 1.3), ("bolt", 0.0, SIGN_Y, 1.2, PINK, 1.3),
                 ("chev_l", 1.75, SIGN_Y, 1.0, MINT, 1.3)],
        "lights": [
            {"type": "SUN", "color": (1.0, 0.98, 0.95), "energy": 3.6, "dir": (0.5, -0.7, -1.5), "extra": {"angle": 0.05}},
            {"type": "POINT", "color": PINK, "energy": 120.0, "loc": (-3.0, 3.5, 2.0)},
        ],
        "ambient": ((0.32, 0.24, 0.45), 0.7),
        "strip_light": ((1.0, 0.98, 0.95), 450.0),
        "glass_emit": 0.1,
        "lock_strength": 1.6,
        "ui": {"panel": (0.17, 0.06, 0.33), "panel_a": 1.0, "outline": (0.02, 0.0, 0.04), "ow": 0.065,
               "bar": (1.0, 1.0, 1.0), "bar_a": 0.92, "accent": MINT, "button": YELLOW,
               "label": (0.12, 0.04, 0.22), "radius": 0.26, "shadow": True},
        "charm": {"base": YELLOW, "base_metal": 0.0, "rim": (0.12, 0.04, 0.22), "rim_metal": 0.0,
                  "die": (0.12, 0.04, 0.22), "bolt": PINK, "outline_col": (0.12, 0.04, 0.22)},
        "post": {"bloom_th": 0.85, "bloom": 0.25, "bloom_r": 12, "chroma": 2, "scan": 0.12, "scan_period": 4,
                 "vig": 0.12, "grain": 0.015},
        "godot_notes": ["Dice/tray/charm: StandardMaterial3D diffuse_mode TOON + specular_mode TOON (export uses the PBR twin).",
                        "Outlines: next_pass material, cull FRONT, vertex grow 0.035 (inverted hull, +1 draw per die).",
                        "Backdrop carpet is a 2D texture; neon chevrons/bolt unshaded emissive.",
                        "Overlay: scanlines (4 px) + 2 px chroma + light vignette."],
    },
}


def build_frame(key):
    cfg, dice, token = build_scene(key)
    render_frame(key, cfg, token)
    return finish_frame(key, cfg, dice, token)


# ------------------------------------------------- Godot side-by-side (D9)
def godot_side_by_side(key):
    """Re-import the exported .glb into an empty scene (round-trip check), render it
    under the same neutral setup as tools/art_preview.gd, stack it under Godot's render."""
    slug = DIRECTIONS[key]["slug"]
    glb = os.path.join(OUT, "gltf", f"dice_{key.lower()}_{slug}.glb")
    godot_png = os.path.join(OUT, "gltf", "preview", f"dice_{key.lower()}_{slug}_godot.png")
    reset_scene()
    setup_render({"samples": 32})
    bpy.ops.import_scene.gltf(filepath=glb)
    floor_mat = _new_mat("M_Floor")
    nt = floor_mat.node_tree
    b = nt.nodes.new("ShaderNodeBsdfPrincipled")
    b.inputs["Base Color"].default_value = (0.16, 0.17, 0.18, 1)
    b.inputs["Roughness"].default_value = 0.95
    nt.links.new(b.outputs[0], nt.nodes.new("ShaderNodeOutputMaterial").inputs["Surface"])
    _mesh_obj("Floor", _flat_poly_mesh("Floor", [(-7, -3), (7, -3), (7, 3), (-7, 3)]), (floor_mat,))
    make_world_and_lights({"ambient": ((0.4, 0.4, 0.45), 1.0), "lights": [
        {"type": "SUN", "color": (1, 1, 1), "energy": 3.0, "dir": (0.45, 0.55, -1.0), "extra": {"angle": 0.05}}]})
    cam = make_camera("CheckCam", 1100 / 126.0, (0, 0, 0.5))
    ref = render_to(os.path.join(RAW, f"{key}_glb_blender.png"), (1100, 300), cam)
    top = load_pixels(godot_png)
    bottom = load_pixels(ref)
    gap = np.full((10, 1100, 4), 0.02, np.float32)
    gap[..., 3] = 1
    out = os.path.join(OUT, "gltf", "preview", f"dice_{key.lower()}_{slug}_compare.png")
    save_image("compare", np.concatenate([bottom, gap, top], 0), out)  # bottom-first rows: Godot on top
    return out
