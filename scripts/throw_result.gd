class_name ThrowResult
extends RefCounted
## Resolve payload of a throw (throw-loop spec): everything add-scoring needs.

## Final face of every tray die (all dice are locked by resolve time).
var faces: Array[int] = []
## Die indices in the order they were locked (force-locks last, index order).
var locked_order: Array[int] = []
## Remaining time per window at the moment it ended; skipped windows are
## credited at full duration. Raw input for Heat.
var window_remaining_s: Array[float] = [0.0, 0.0, 0.0]
