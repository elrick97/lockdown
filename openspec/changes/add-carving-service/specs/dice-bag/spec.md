## ADDED Requirements

### Requirement: Die is a typed object bundling material and carving
Each die in the bag SHALL be represented by a `DiceBag.Die` inner class instance with:
- `material_id: StringName` — material key (e.g. `&"standard"`, `&"bone"`)
- `carved_face: int` — the specific face value the carving activates on (`-1` = uncarved)
- `carve_type: StringName` — the carving effect (`&""` = none; `&"wild"`, `&"gem"`, `&"spark"` are the M1 types)

`DiceBag._dice` SHALL be `Array[DiceBag.Die]`. `draw()` SHALL return `Array[DiceBag.Die]`. `return_dice()` SHALL accept `Array[DiceBag.Die]`.

#### Scenario: Standard die has no carving
- **WHEN** `DiceBag.add()` is called with a material ID
- **THEN** the resulting Die has `carved_face = -1` and `carve_type = &""`

### Requirement: add_carved registers a pre-carved die in the bag
`DiceBag.add_carved(material_id, carved_face, carve_type, count=1)` SHALL append `count` Die instances with the specified carving fields to the bag.

#### Scenario: Carved die retains fields through draw
- **WHEN** a carved die is added via `add_carved(mat, 6, &"wild")` and then drawn
- **THEN** the returned Die has `carved_face = 6` and `carve_type = &"wild"`
