# Style frame B: Smoke Room

Restraint test: oxblood felt in a single hard lamp pool, near-black surroundings, one amber accent, heavy contrast and film grain.

![frame](frame_b_smoke_room.png)

## Palette

| Role | Hex |
|---|---|
| felt | `#5C0D0F` |
| rim | `#210D09` |
| table | `#1C110A` |
| bone | `#E0CCA3` |
| bone_pip | `#1F0F0A` |
| bone_pip1 | `#850F0D` |
| iron | `#454547` |
| iron_pip | `#FAD68F` |
| glass | `#FAA338` |
| glass_pip | `#FFF7E6` |
| glass_rim | `#FFBF66` |
| carve_wild | `#F5B852` |
| carve_gem | `#BF141F` |
| carve_spark | `#FFF7E0` |
| lock | `#FF9E29` |
| brass | `#CC994C` |

## Geometry (triangles)

| Asset | Tris | Budget |
|---|---|---|
| Die (each) | 188 | 300 |
| Tray | 538 | 2000 |
| Charm token | 380 | n/a (icon is 2D) |
| Neon tubes (all) | 528 | n/a |

## Textures

| File | Size |
|---|---|
| `textures/frame_b/charm_hair_trigger_albedo.png` | 512×512 |
| `textures/frame_b/charm_hair_trigger_normal.png` | 512×512 |
| `textures/frame_b/charm_hair_trigger_orm.png` | 512×512 |
| `textures/frame_b/charm_icon_512.png` | 512×512 |
| `textures/frame_b/die_bone_albedo.png` | 768×512 |
| `textures/frame_b/die_bone_normal.png` | 768×512 |
| `textures/frame_b/die_bone_orm.png` | 768×512 |
| `textures/frame_b/die_bone_wild1_albedo.png` | 768×512 |
| `textures/frame_b/die_bone_wild1_normal.png` | 768×512 |
| `textures/frame_b/die_bone_wild1_orm.png` | 768×512 |
| `textures/frame_b/die_glass_albedo.png` | 768×512 |
| `textures/frame_b/die_glass_normal.png` | 768×512 |
| `textures/frame_b/die_glass_orm.png` | 768×512 |
| `textures/frame_b/die_glass_spark1_albedo.png` | 768×512 |
| `textures/frame_b/die_glass_spark1_normal.png` | 768×512 |
| `textures/frame_b/die_glass_spark1_orm.png` | 768×512 |
| `textures/frame_b/die_iron_albedo.png` | 768×512 |
| `textures/frame_b/die_iron_normal.png` | 768×512 |
| `textures/frame_b/die_iron_orm.png` | 768×512 |
| `textures/frame_b/felt_albedo.png` | 1024×1024 |
| `textures/frame_b/felt_normal.png` | 1024×1024 |
| `textures/frame_b/felt_orm.png` | 1024×1024 |
| `textures/frame_b/rim_albedo.png` | 512×512 |
| `textures/frame_b/rim_normal.png` | 512×512 |
| `textures/frame_b/rim_orm.png` | 512×512 |
| `textures/frame_b/table_albedo.png` | 1024×2048 |
| `textures/frame_b/table_normal.png` | 1024×2048 |
| `textures/frame_b/table_orm.png` | 1024×2048 |

## Lighting (game budget: 1 directional + 2 omni/spot)

- SPOT: color #FFDBA8, energy 3200.0
- SUN: color #99B2FF, energy 0.25
- ambient #030202 × 1.0

## Overlay (one canvas shader + optional glow)

- `bloom_th` = 0.8
- `bloom` = 0.35
- `bloom_r` = 16
- `chroma` = 0
- `scan` = 0.0
- `scan_period` = 3
- `vig` = 0.6
- `grain` = 0.07

## Draw-call estimate (full 8-die tray)

8 dice × 1 = 8, tray 2, backdrop 1, neon 1, lock rings 1 (MultiMesh) → **~13** (+ directional shadow pass over dice/tray). UI is 2D canvas, batched separately.

## Godot mapping notes

- Lamp pool is painted into felt/backdrop, so the spot light is optional (can be 1 directional).
- Glass: transparency ALPHA + rim; amber tint stays readable over oxblood thanks to value contrast.
- Overlay: grain + strong vignette only (cheapest of the three).

## Local Godot check (GL Compatibility, desktop)

![godot vs blender](gltf/preview/dice_b_smoke_room_compare.png)

- Top: `tools/art_preview.gd` render of the exported `.glb`; bottom: the same `.glb` re-imported into Blender under matching neutral light. Materials, alpha Glass and normals carry over.
- Finding: S3TC/ETC2 4×4 block compression stair-steps saturated carved-inlay edges on Glass. For integration, import die atlases as ASTC 4×4 on mobile or lossless (≤ 1.5 MB per atlas).
- Godot renders Bone slightly brighter (ambient/tonemap difference). Cosmetic; tune in the environment.
