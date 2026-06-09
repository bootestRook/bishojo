extends RefCounted
class_name BattleRng

# 文件职责：
# - 提供确定性整数随机，避免依赖全局随机状态。
# - 同一 battle_seed 与同一调用顺序必须得到同一 roll_value_bp。

const MODULUS: int = 2147483647
const MULTIPLIER: int = 48271


func roll_bp(context, roll_type: String, threshold_bp: int) -> Dictionary:
	context.rng_roll_index += 1
	var state: int = _state_for_roll(context.battle_seed, context.rng_roll_index)
	var roll_value_bp: int = state % 10000
	return {
		"battle_seed": context.battle_seed,
		"rng_roll_index": context.rng_roll_index,
		"roll_type": roll_type,
		"roll_value_bp": roll_value_bp,
		"threshold_bp": threshold_bp,
		"result": roll_value_bp < threshold_bp,
	}


func roll_index(context, roll_type: String, count: int) -> Dictionary:
	context.rng_roll_index += 1
	var state: int = _state_for_roll(context.battle_seed, context.rng_roll_index)
	var index: int = 0
	if count > 0:
		index = state % count

	return {
		"battle_seed": context.battle_seed,
		"rng_roll_index": context.rng_roll_index,
		"roll_type": roll_type,
		"roll_value_bp": state % 10000,
		"threshold_bp": count,
		"result": index,
	}


func _state_for_roll(seed: int, roll_index: int) -> int:
	var state: int = seed
	if state <= 0:
		state = 1
	var index: int = 0
	while index < roll_index:
		state = (state * MULTIPLIER + 1) % MODULUS
		index += 1

	return state

