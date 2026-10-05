class_name ThrowResult
extends RefCounted
## Resolve payload of a throw (throw-loop spec): everything add-scoring needs.

## Final face of every tray die (all dice are locked by resolve time).
var faces: Array[int] = []
## Die indices in the order they were locked (force-locks last, index order).
var locked_order: Array[int] = []
## Window (1-3) in which each die in locked_order was locked. Parallel array.
var lock_windows: Array[int] = []
## Remaining time per window at the moment it ended; skipped windows are
## credited at full duration. Raw input for Heat.
var window_remaining_s: Array[float] = [0.0, 0.0, 0.0]
## Material pip adjustment arrays — parallel to faces.
var pip_offsets: Array[int] = []
var pip_multipliers: Array[int] = []
## Shattered slots (Glass dice that were re-rolled) — excluded from scoring.
var shattered: Array[bool] = []
## Active carve type per die slot (empty string = no carving active this roll).
## Parallel to faces; non-empty only when the rolled face matches carved_face.
var carve_types: Array[StringName] = []
