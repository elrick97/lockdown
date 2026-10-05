## ADDED Requirements

### Requirement: DiceMaterial carries its visuals as data
`DiceMaterial` SHALL reference its look as textures: `albedo` (RGBA; alpha used for Glass), `normal`, and `orm` (AO, roughness, metallic), each one 768×512 atlas in the standard face layout, plus `transparent: bool` and `rim: float` for faked Glass. The renderer SHALL build each die's material from these fields only, so adding a material needs a `.tres` and textures, and no code.

#### Scenario: Materials render from data
- **WHEN** a Bone, Iron or Glass die is drawn
- **THEN** its look comes entirely from its `DiceMaterial` textures and flags

### Requirement: Carved faces are stamped from carve tiles
For each material and carving, the game SHALL ship one 256×256 carve tile per map (albedo, normal, ORM). It shows the carving on that material's face background. When a carved die is drawn, the renderer SHALL copy the material's atlases and replace the carved face's tile with the carve tile, caching the result per (material, carving, face). Uncarved dice SHALL share the material's atlases.

#### Scenario: Wild on a Bone 6
- **GIVEN** a Bone die carved Wild on face 6
- **WHEN** it is drawn
- **THEN** its atlas equals the Bone atlas except the face-6 tile, which equals the Bone Wild tile

#### Scenario: Cache reuse
- **WHEN** two Bone dice carved Wild on face 6 are drawn
- **THEN** both use the same stamped atlas
