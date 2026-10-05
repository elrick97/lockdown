"""Verify art-direction outputs against the art-direction spec budgets (stdlib only).

Checks every .glb in assets/art_direction/gltf (triangles per mesh, embedded
texture sizes) and every PNG under assets/art_direction/textures (dimensions
are multiples of 4 for ETC2/ASTC, within the per-asset budget).

Usage: python tools/art_direction/check_assets.py   (exit code 1 on any failure)
"""
import json
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2] / "assets" / "art_direction"
DIE_TRIS_MAX = 300
BUDGET_PX = {"die_": (768, 512), "felt": (1024, 1024), "rim": (1024, 1024), "charm": (512, 512),
             "table": (1024, 2048)}


def png_size(data: bytes) -> tuple[int, int]:
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    return struct.unpack(">II", data[16:24])


def read_glb(path: Path) -> tuple[dict, bytes]:
    raw = path.read_bytes()
    magic, _version, _length = struct.unpack("<III", raw[:12])
    if magic != 0x46546C67:
        raise ValueError(f"{path.name}: not a GLB")
    jlen, _ = struct.unpack("<II", raw[12:20])
    gltf = json.loads(raw[20:20 + jlen])
    blen, _ = struct.unpack("<II", raw[20 + jlen:28 + jlen])
    return gltf, raw[28 + jlen:28 + jlen + blen]


def check_glb(path: Path) -> list[str]:
    errors = []
    gltf, binary = read_glb(path)
    for mesh in gltf["meshes"]:
        tris = 0
        for prim in mesh["primitives"]:
            if prim.get("mode", 4) != 4:
                errors.append(f"{path.name}/{mesh['name']}: non-triangle primitive")
            count = gltf["accessors"][prim["indices"]]["count"] if "indices" in prim else \
                gltf["accessors"][prim["attributes"]["POSITION"]]["count"]
            tris += count // 3
        ok = tris <= DIE_TRIS_MAX
        print(f"  {'ok ' if ok else 'BAD'} {mesh['name']}: {tris} tris (max {DIE_TRIS_MAX})")
        if not ok:
            errors.append(f"{path.name}/{mesh['name']}: {tris} tris > {DIE_TRIS_MAX}")
    for img in gltf.get("images", []):
        view = gltf["bufferViews"][img["bufferView"]]
        start = view.get("byteOffset", 0)
        w, h = png_size(binary[start:start + view["byteLength"]])
        ok = w % 4 == 0 and h % 4 == 0 and w <= 768 and h <= 512
        print(f"  {'ok ' if ok else 'BAD'} texture {img.get('name', '?')}: {w}x{h}")
        if not ok:
            errors.append(f"{path.name}/{img.get('name')}: {w}x{h} outside die_atlas_px or not /4")
    return errors


def check_png(path: Path) -> list[str]:
    w, h = png_size(path.read_bytes()[:24])
    budget = next((b for prefix, b in BUDGET_PX.items() if path.name.startswith(prefix)), None)
    ok = w % 4 == 0 and h % 4 == 0 and (budget is None or (w <= budget[0] and h <= budget[1]))
    print(f"  {'ok ' if ok else 'BAD'} {path.parent.name}/{path.name}: {w}x{h}"
          + (f" (budget {budget[0]}x{budget[1]})" if budget else ""))
    return [] if ok else [f"{path}: {w}x{h}"]


def main() -> int:
    errors = []
    for glb in sorted((ROOT / "gltf").glob("*.glb")):
        print(glb.name)
        errors += check_glb(glb)
    print("textures")
    for png in sorted((ROOT / "textures").rglob("*.png")):
        errors += check_png(png)
    print(f"\n{len(errors)} problem(s)")
    for e in errors:
        print("  -", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
