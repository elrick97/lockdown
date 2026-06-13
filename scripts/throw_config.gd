class_name ThrowConfig
extends Resource
## Named tunables for the throw loop (throw-loop spec). Playtest variants
## (e.g. 2.0/2.5/3.0 s windows) are alternative .tres files of this resource.

enum TumbleRenderer { SPRITE_2D, VIEWPORT_3D }

@export var tumble_duration_s: float = 1.5
@export var lock_window_duration_s: float = 2.5
@export var tap_forgiveness_radius_px: float = 96.0
@export var resume_countdown_s: float = 3.0
@export var draw_size: int = 6
@export var starting_bag_size: int = 8
## Dice-tumble spike: which presentation renderer drives the tumble (A/B seam).
@export var tumble_renderer: TumbleRenderer = TumbleRenderer.SPRITE_2D
