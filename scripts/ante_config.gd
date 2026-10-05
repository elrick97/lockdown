class_name AnteConfig
extends Resource

@export var targets: Array[int] = [150, 350, 700]
@export var throws_per_round: int = 3
@export var round_names: Array[String] = ["Open", "Risk", "Boss"]
@export var boss_antes: Array[int] = [3]
@export var boss_window_scale: float = 0.5
@export var risk_antes: Array[int] = [2]
@export var skip_reward_gold: int = 3
