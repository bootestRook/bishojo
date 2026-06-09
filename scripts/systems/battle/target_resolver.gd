extends RefCounted
class_name TargetResolver

const BATTLE_RNG = preload("res://scripts/systems/battle/battle_rng.gd")

# 文件职责：
# - 根据 target_rule 从 BattleContext 中解析目标。
# - 多格单位按 row / col_start / col_end 的占用范围判断，不拆成多个槽位单位。

var rng = BATTLE_RNG.new()


func resolve_targets(context, source_unit, target_rule: String, logger) -> Array:
	match target_rule:
		"enemy_single":
			return _first_alive_enemy(context)
		"enemy_all":
			return context.get_alive_enemies()
		"player_core":
			return ["player_core"]
		"self":
			return [source_unit]
		"adjacent":
			return _adjacent_units(context, source_unit)
		"same_row":
			return _same_row_units(context, source_unit)
		"same_col":
			return _same_col_units(context, source_unit)
		"front_back_overlap":
			return _front_back_overlap_units(context, source_unit)
		"center_column":
			return _center_column_units(context, source_unit)
		"longest_cooldown_ally":
			return _longest_cooldown_ally(context, source_unit)
		"random_ally":
			return _random_ally(context, source_unit, logger)
		"run":
			return ["run"]
		_:
			return []


func _first_alive_enemy(context) -> Array:
	var enemies: Array = context.get_alive_enemies()
	if enemies.is_empty():
		return []

	return [enemies[0]]


func _adjacent_units(context, source_unit) -> Array:
	var result: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and unit.row == source_unit.row:
			if unit.col_end == source_unit.col_start - 1 or unit.col_start == source_unit.col_end + 1:
				result.append(unit)
		index += 1

	return result


func _same_row_units(context, source_unit) -> Array:
	var result: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and unit.row == source_unit.row:
			result.append(unit)
		index += 1

	return result


func _same_col_units(context, source_unit) -> Array:
	var result: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and _col_overlaps(source_unit, unit):
			result.append(unit)
		index += 1

	return result


func _front_back_overlap_units(context, source_unit) -> Array:
	var result: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and unit.row != source_unit.row and _col_overlaps(source_unit, unit):
			result.append(unit)
		index += 1

	return result


func _center_column_units(context, source_unit) -> Array:
	var result: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and unit.col_start <= 2 and unit.col_end >= 2:
			result.append(unit)
		index += 1

	return result


func _longest_cooldown_ally(context, source_unit) -> Array:
	var result_unit = null
	var best_remaining: int = -1
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		var unit = units[index]
		if unit.instance_id != source_unit.instance_id and unit.remaining_cooldown_ms > best_remaining:
			best_remaining = unit.remaining_cooldown_ms
			result_unit = unit
		index += 1

	if result_unit == null:
		return []
	return [result_unit]


func _random_ally(context, source_unit, logger) -> Array:
	var candidates: Array = []
	var units: Array = context.get_alive_units()
	var index: int = 0
	while index < units.size():
		if units[index].instance_id != source_unit.instance_id:
			candidates.append(units[index])
		index += 1
	if candidates.is_empty():
		return []

	var roll: Dictionary = rng.roll_index(context, "random_ally", candidates.size())
	var selected_index: int = roll.get("result", 0)
	logger.log(context, {
		"event_type": "RNG_ROLL",
		"source_id": source_unit.instance_id,
		"target_id": candidates[selected_index].instance_id,
		"rng_roll_index": roll.get("rng_roll_index", -1),
		"crit_roll_bp": roll.get("roll_value_bp", -1),
		"cause": "random_ally",
	})
	return [candidates[selected_index]]


func _col_overlaps(left_unit, right_unit) -> bool:
	return left_unit.col_start <= right_unit.col_end and left_unit.col_end >= right_unit.col_start
