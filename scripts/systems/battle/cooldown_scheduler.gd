extends RefCounted
class_name CooldownScheduler

const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")

# 文件职责：
# - 统一推进卡牌冷却、计算下一次自然冷却检查、重置冷却并写日志。
# - 这是 V1 战斗底层最关键的时间模型入口，禁止绕过 remaining_cooldown_ms / cooldown_rate_bp。


func initialize_unit_cooldown(context, unit, config, logger) -> void:
	unit.remaining_cooldown_ms = unit.base_cooldown_ms * config.initial_cooldown_ratio_bp / 10000
	unit.last_cooldown_update_time_ms = 0
	unit.cooldown_rate_bp = 10000
	unit.cooldown_version += 1
	logger.log(context, {
		"event_type": "COOLDOWN_INIT",
		"source_id": unit.instance_id,
		"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
		"cooldown_rate_after_bp": unit.cooldown_rate_bp,
		"cause": "battle_start",
	})
	schedule_next_cooldown_check(context, unit)


func update_cooldown_to_now(context, unit, logger, cause: String = "update") -> void:
	var before: int = unit.remaining_cooldown_ms
	var rate_before: int = unit.cooldown_rate_bp
	var elapsed_ms: int = context.time_ms - unit.last_cooldown_update_time_ms
	if elapsed_ms <= 0:
		return

	var recovered_ms: int = elapsed_ms * unit.cooldown_rate_bp / 10000
	unit.remaining_cooldown_ms -= recovered_ms
	if unit.remaining_cooldown_ms < 0:
		unit.remaining_cooldown_ms = 0
	unit.last_cooldown_update_time_ms = context.time_ms
	logger.log(context, {
		"event_type": "COOLDOWN_UPDATE",
		"source_id": unit.instance_id,
		"remaining_cooldown_before_ms": before,
		"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
		"cooldown_rate_before_bp": rate_before,
		"cooldown_rate_after_bp": unit.cooldown_rate_bp,
		"cause": cause,
	})


func calc_next_ready_time(context, unit) -> int:
	if unit.remaining_cooldown_ms <= 0:
		return context.time_ms
	if unit.cooldown_rate_bp <= 0:
		return context.time_ms + 999999999

	return context.time_ms + _ceil_div(unit.remaining_cooldown_ms * 10000, unit.cooldown_rate_bp)


func schedule_next_cooldown_check(context, unit) -> void:
	var event = _make_event(context, {
		"event_type": "PLAYER_COOLDOWN_CHECK",
		"trigger_time_ms": calc_next_ready_time(context, unit),
		"priority": 10,
		"source_id": unit.instance_id,
		"target_id": unit.instance_id,
		"version": unit.cooldown_version,
		"payload": {"unit_id": unit.instance_id},
	})
	context.event_queue.push(event)


func reset_unit_cooldown(context, unit, logger) -> void:
	update_cooldown_to_now(context, unit, logger, "trigger_reset")
	var before: int = unit.remaining_cooldown_ms
	unit.remaining_cooldown_ms = unit.base_cooldown_ms
	unit.last_cooldown_update_time_ms = context.time_ms
	unit.cooldown_version += 1
	logger.log(context, {
		"event_type": "COOLDOWN_RESET",
		"source_id": unit.instance_id,
		"remaining_cooldown_before_ms": before,
		"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
		"cooldown_rate_after_bp": unit.cooldown_rate_bp,
		"cause": "skill_trigger",
	})
	schedule_next_cooldown_check(context, unit)


func enqueue_player_trigger(context, unit, priority: int, cause: String, chain_depth: int = 0) -> void:
	var event = _make_event(context, {
		"event_type": "PLAYER_TRIGGER_SKILL",
		"trigger_time_ms": context.time_ms,
		"priority": priority,
		"source_id": unit.instance_id,
		"target_id": unit.instance_id,
		"payload": {"unit_id": unit.instance_id, "cause": cause},
		"chain_depth": chain_depth,
	})
	context.event_queue.push(event)


func _make_event(context, data: Dictionary):
	context.next_event_sequence_id += 1
	var event = BATTLE_EVENT.new()
	var payload: Dictionary = data.duplicate(true)
	payload["sequence_id"] = context.next_event_sequence_id
	payload["event_id"] = "event_%d" % context.next_event_sequence_id
	event.setup(payload)
	return event


func _ceil_div(value: int, divisor: int) -> int:
	if divisor <= 0:
		return 999999999
	var result: int = value / divisor
	if value % divisor != 0:
		result += 1
	return result

