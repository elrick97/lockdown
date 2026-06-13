class_name RoundState
extends RefCounted

signal round_won
signal round_lost

var current_throw: int = 0
var total: int = 0
var target: int = 0
var is_done: bool = false

var _throws_per_round: int


func _init(p_target: int, p_throws_per_round: int = 3) -> void:
	target = p_target
	_throws_per_round = p_throws_per_round


func add_score(score: int) -> void:
	if is_done:
		return
	current_throw += 1
	total += score
	if total >= target:
		is_done = true
		round_won.emit()
	elif current_throw >= _throws_per_round:
		is_done = true
		round_lost.emit()


func reset(new_target: int) -> void:
	target = new_target
	current_throw = 0
	total = 0
	is_done = false
