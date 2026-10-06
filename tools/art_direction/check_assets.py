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
DICE = Path(__file__).resolve().parents[2] / "assets" / "dice"  # production dice (add-smoke-room-dice)
DICE_MATERIALS = ("bone", "iron", "glass")
TABLE = Path(__file__).resolve().parents[2] / "assets" / "table"  # add-smoke-room-table
TABLE_PX = {"felt.png": (1024, 1024), "backdrop.png": (1024, 2048)}
UI = Path(__file__).resolve().parents[2] / "assets" / "ui"  # add-smoke-room-ui-art
UI_PX = {f"button_{k}_{s}.png": (256, 128) for k in ("primary", "secondary")
         for s in ("normal", "pressed", "disabled")}
CHARMS = Path(__file__).resolve().parents[2] / "assets" / "charms"  # add-charm-icons
CHARM_COUNT = 12
SHOP = Path(__file__).resolve().parents[2] / "assets" / "shop"  # add-shop-icons
SHOP_ICONS = ("iron", "glass", "wild_6_bone", "gem_5_bone", "spark_4_bone", "re_tumble", "freeze_timer")
UI_PX.update({"panel.png": (256, 256), "plaque.png": (256, 96), "socket.png": (160, 160),
              "timer_frame.png": (512, 56), "timer_fill.png": (64, 32),
              "start_hero.png": (768, 640)})  # add-start-hero-art
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


def dice_budget(name: str) -> tuple[int, int]:
    """Production dice: material atlas 768x512, carve tile 256x256, sprite 128x128."""
    parts = name.removesuffix(".png").split("_")
    if name in ("lock_socket.png", "crack.png"):  # add-lock-signifiers
        return (256, 256)
    if parts[0] in DICE_MATERIALS:
        return (768, 512) if len(parts) == 2 else (256, 256)
    return (128, 128)


def check_dice_png(path: Path) -> list[str]:
    w, h = png_size(path.read_bytes()[:24])
    budget = dice_budget(path.name)
    ok = (w, h) == budget
    print(f"  {'ok ' if ok else 'BAD'} dice/{path.name}: {w}x{h} (expected {budget[0]}x{budget[1]})")
    return [] if ok else [f"{path}: {w}x{h}, expected {budget}"]


def main() -> int:
    errors = []
    for glb in sorted((ROOT / "gltf").glob("*.glb")):
        print(glb.name)
        errors += check_glb(glb)
    print("textures")
    for png in sorted((ROOT / "textures").rglob("*.png")):
        errors += check_png(png)
    if DICE.exists():
        print("production dice")
        for glb in sorted(DICE.glob("*.glb")):
            errors += check_glb(glb)
        for png in sorted(DICE.glob("*.png")):
            errors += check_dice_png(png)
    if TABLE.exists():
        print("production table")
        for png in sorted(TABLE.glob("*.png")):
            w, h = png_size(png.read_bytes()[:24])
            ok = (w, h) == TABLE_PX.get(png.name)
            print(f"  {'ok ' if ok else 'BAD'} table/{png.name}: {w}x{h}")
            if not ok:
                errors.append(f"{png}: {w}x{h}, expected {TABLE_PX.get(png.name)}")
    if UI.exists():
        print("production UI kit")
        found = {p.name for p in UI.glob("*.png")}
        for name in sorted(set(UI_PX) - found):
            errors.append(f"ui/{name}: missing")
        for png in sorted(UI.glob("*.png")):
            w, h = png_size(png.read_bytes()[:24])
            ok = (w, h) == UI_PX.get(png.name)
            print(f"  {'ok ' if ok else 'BAD'} ui/{png.name}: {w}x{h}")
            if not ok:
                errors.append(f"{png}: {w}x{h}, expected {UI_PX.get(png.name)}")
    if CHARMS.exists():
        print("charm icons")
        pngs = sorted(CHARMS.glob("*.png"))
        if len(pngs) != CHARM_COUNT:
            errors.append(f"charms: {len(pngs)} icons, expected {CHARM_COUNT}")
        for png in pngs:
            w, h = png_size(png.read_bytes()[:24])
            ok = (w, h) == (256, 256)
            print(f"  {'ok ' if ok else 'BAD'} charms/{png.name}: {w}x{h}")
            if not ok:
                errors.append(f"{png}: {w}x{h}, expected 256x256")
    if SHOP.exists():
        print("shop icons")
        for name in SHOP_ICONS:
            png = SHOP / f"{name}.png"
            if not png.exists():
                errors.append(f"shop/{name}.png: missing")
                continue
            w, h = png_size(png.read_bytes()[:24])
            ok = (w, h) == (256, 256)
            print(f"  {'ok ' if ok else 'BAD'} shop/{png.name}: {w}x{h}")
            if not ok:
                errors.append(f"{png}: {w}x{h}, expected 256x256")
    print(f"\n{len(errors)} problem(s)")
    for e in errors:
        print("  -", e)
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
