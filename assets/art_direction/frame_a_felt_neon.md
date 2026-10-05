# Style frame A: Felt & Neon

The PRD candidate played straight: deep-teal felt under warm tungsten light, magenta/cyan neon on the rim and table, light CRT grain.

![frame](frame_a_felt_neon.png)

## Palette

| Role | Hex |
|---|---|
| felt | `#0A5E5E` |
| rim | `#09080A` |
| table | `#171214` |
| bone | `#EBDBBD` |
| bone_pip | `#170D12` |
| bone_pip1 | `#DB0F5C` |
| iron | `#545C66` |
| iron_pip | `#D1F7FF` |
| glass | `#38DBF5` |
| glass_pip | `#FAFCFF` |
| glass_rim | `#66F2FF` |
| carve_wild | `#FFC247` |
| carve_gem | `#F21F61` |
| carve_spark | `#FF3DB8` |
| lock | `#2EEBFF` |
| neon_magenta | `#FF1F9E` |
| neon_cyan | `#2EEBFF` |

## Geometry (triangles)

| Asset | Tris | Budget |
|---|---|---|
| Die (each) | 188 | 300 |
| Tray | 538 | 2000 |
| Charm token | 380 | n/a (icon is 2D) |
| Neon tubes (all) | 1384 | n/a |

## Textures

| File | Size |
|---|---|
| `textures/frame_a/charm_hair_trigger_albedo.png` | 512×512 |
| `textures/frame_a/charm_hair_trigger_normal.png` | 512×512 |
| `textures/frame_a/charm_hair_trigger_orm.png` | 512×512 |
| `textures/frame_a/charm_icon_512.png` | 512×512 |
| `textures/frame_a/die_bone_albedo.png` | 768×512 |
| `textures/frame_a/die_bone_normal.png` | 768×512 |
| `textures/frame_a/die_bone_orm.png` | 768×512 |
| `textures/frame_a/die_bone_wild1_albedo.png` | 768×512 |
| `textures/frame_a/die_bone_wild1_normal.png` | 768×512 |
| `textures/frame_a/die_bone_wild1_orm.png` | 768×512 |
| `textures/frame_a/die_glass_albedo.png` | 768×512 |
| `textures/frame_a/die_glass_normal.png` | 768×512 |
| `textures/frame_a/die_glass_orm.png` | 768×512 |
| `textures/frame_a/die_glass_spark1_albedo.png` | 768×512 |
| `textures/frame_a/die_glass_spark1_normal.png` | 768×512 |
| `textures/frame_a/die_glass_spark1_orm.png` | 768×512 |
| `textures/frame_a/die_iron_albedo.png` | 768×512 |
| `textures/frame_a/die_iron_normal.png` | 768×512 |
| `textures/frame_a/die_iron_orm.png` | 768×512 |
| `textures/frame_a/felt_albedo.png` | 1024×1024 |
| `textures/frame_a/felt_normal.png` | 1024×1024 |
| `textures/frame_a/felt_orm.png` | 1024×1024 |
| `textures/frame_a/rim_albedo.png` | 512×512 |
| `textures/frame_a/rim_normal.png` | 512×512 |
| `textures/frame_a/rim_orm.png` | 512×512 |
| `textures/frame_a/table_albedo.png` | 1024×2048 |
| `textures/frame_a/table_normal.png` | 1024×2048 |
| `textures/frame_a/table_orm.png` | 1024×2048 |

## Lighting (game budget: 1 directional + 2 omni/spot)

- SUN: color #FFD6A3, energy 3.2
- POINT: color #FF1F9E, energy 260.0
- POINT: color #2EEBFF, energy 260.0
- ambient #081214 × 1.0

## Overlay (one canvas shader + optional glow)

- `bloom_th` = 0.72
- `bloom` = 0.6
- `bloom_r` = 20
- `chroma` = 1
- `scan` = 0.05
- `scan_period` = 3
- `vig` = 0.35
- `grain` = 0.035

## Draw-call estimate (full 8-die tray)

8 dice × 1 = 8, tray 2, backdrop 1, neon 5, lock rings 1 (MultiMesh) → **~17** (+ directional shadow pass over dice/tray). UI is 2D canvas, batched separately.

## Godot mapping notes

- Dice/tray/backdrop: StandardMaterial3D (albedo + normal + ORM).
- Glass: transparency ALPHA, rim 0.5, emission from albedo ×0.12 (or 10-line fresnel shader).
- Neon tubes: unshaded emissive; halos painted into felt/backdrop textures, so glow is optional.
- Overlay: one CanvasItem shader (grain + scanlines + vignette + 1 px chroma) + Compatibility glow.

## Local Godot check (GL Compatibility, desktop)

![godot vs blender](gltf/preview/dice_a_felt_neon_compare.png)

- Top: `tools/art_preview.gd` render of the exported `.glb`; bottom: the same `.glb` re-imported into Blender under matching neutral light. Materials, alpha Glass and normals carry over.
- Finding: S3TC/ETC2 4×4 block compression stair-steps saturated carved-inlay edges on Glass. For integration, import die atlases as ASTC 4×4 on mobile or lossless (≤ 1.5 MB per atlas).
- Godot renders Bone slightly brighter (ambient/tonemap difference). Cosmetic; tune in the environment.
