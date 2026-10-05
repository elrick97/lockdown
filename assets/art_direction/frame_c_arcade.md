# Style frame C: Arcade Cabinet

Graphic and bold: saturated violet felt, toon-banded shading with thick outlines, arcade-carpet backdrop, scanline overlay. Most readable by construction.

![frame](frame_c_arcade.png)

## Palette

| Role | Hex |
|---|---|
| felt | `#5C1F9E` |
| rim | `#FFB214` |
| table | `#0D0924` |
| carpet1 | `#FF3894` |
| carpet2 | `#40FFB8` |
| carpet3 | `#FFCC1A` |
| bone | `#FFF2D9` |
| bone_pip | `#1F0D38` |
| bone_pip1 | `#FF3894` |
| iron | `#575C75` |
| iron_pip | `#40FFB8` |
| glass | `#FF5CA8` |
| glass_pip | `#FFFFFF` |
| glass_rim | `#FF99D9` |
| carve_wild | `#FFCC1A` |
| carve_gem | `#33E6FF` |
| carve_spark | `#40FFB8` |
| lock | `#40FFB8` |

## Geometry (triangles)

| Asset | Tris | Budget |
|---|---|---|
| Die (each) | 188 | 300 |
| Tray | 538 | 2000 |
| Charm token | 380 | n/a (icon is 2D) |
| Neon tubes (all) | 120 | n/a |
| Die + outline hull | 376 | hull = 2nd pass |

## Textures

| File | Size |
|---|---|
| `textures/frame_c/charm_hair_trigger_albedo.png` | 512×512 |
| `textures/frame_c/charm_hair_trigger_normal.png` | 512×512 |
| `textures/frame_c/charm_hair_trigger_orm.png` | 512×512 |
| `textures/frame_c/charm_icon_512.png` | 512×512 |
| `textures/frame_c/die_bone_albedo.png` | 768×512 |
| `textures/frame_c/die_bone_normal.png` | 768×512 |
| `textures/frame_c/die_bone_orm.png` | 768×512 |
| `textures/frame_c/die_bone_wild1_albedo.png` | 768×512 |
| `textures/frame_c/die_bone_wild1_normal.png` | 768×512 |
| `textures/frame_c/die_bone_wild1_orm.png` | 768×512 |
| `textures/frame_c/die_glass_albedo.png` | 768×512 |
| `textures/frame_c/die_glass_normal.png` | 768×512 |
| `textures/frame_c/die_glass_orm.png` | 768×512 |
| `textures/frame_c/die_glass_spark1_albedo.png` | 768×512 |
| `textures/frame_c/die_glass_spark1_normal.png` | 768×512 |
| `textures/frame_c/die_glass_spark1_orm.png` | 768×512 |
| `textures/frame_c/die_iron_albedo.png` | 768×512 |
| `textures/frame_c/die_iron_normal.png` | 768×512 |
| `textures/frame_c/die_iron_orm.png` | 768×512 |
| `textures/frame_c/felt_albedo.png` | 1024×1024 |
| `textures/frame_c/felt_normal.png` | 1024×1024 |
| `textures/frame_c/felt_orm.png` | 1024×1024 |
| `textures/frame_c/rim_albedo.png` | 512×512 |
| `textures/frame_c/rim_normal.png` | 512×512 |
| `textures/frame_c/rim_orm.png` | 512×512 |
| `textures/frame_c/table_albedo.png` | 1024×2048 |
| `textures/frame_c/table_normal.png` | 1024×2048 |
| `textures/frame_c/table_orm.png` | 1024×2048 |

## Lighting (game budget: 1 directional + 2 omni/spot)

- SUN: color #FFFAF2, energy 3.6
- POINT: color #FF3894, energy 120.0
- ambient #523D73 × 0.7

## Overlay (one canvas shader + optional glow)

- `bloom_th` = 0.85
- `bloom` = 0.25
- `bloom_r` = 12
- `chroma` = 2
- `scan` = 0.12
- `scan_period` = 4
- `vig` = 0.12
- `grain` = 0.015

## Draw-call estimate (full 8-die tray)

8 dice × 2 = 16, tray 2 + 1 hull, backdrop 1, neon 3, lock rings 1 (MultiMesh) → **~24** (+ directional shadow pass over dice/tray). UI is 2D canvas, batched separately.

## Godot mapping notes

- Dice/tray/charm: StandardMaterial3D diffuse_mode TOON + specular_mode TOON (export uses the PBR twin).
- Outlines: next_pass material, cull FRONT, vertex grow 0.035 (inverted hull, +1 draw per die).
- Backdrop carpet is a 2D texture; neon chevrons/bolt unshaded emissive.
- Overlay: scanlines (4 px) + 2 px chroma + light vignette.

## Local Godot check (GL Compatibility, desktop)

![godot vs blender](gltf/preview/dice_c_arcade_compare.png)

- Top: `tools/art_preview.gd` render of the exported `.glb`; bottom: the same `.glb` re-imported into Blender under matching neutral light. Materials, alpha Glass and normals carry over.
- Finding: S3TC/ETC2 4×4 block compression stair-steps saturated carved-inlay edges on Glass. For integration, import die atlases as ASTC 4×4 on mobile or lossless (≤ 1.5 MB per atlas).
- Godot renders Bone slightly brighter (ambient/tonemap difference). Cosmetic; tune in the environment.
