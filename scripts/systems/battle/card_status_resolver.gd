extends RefCounted
class_name CardStatusResolver

const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")

# 文件职责：
# - 处理卡牌单位的加速、减速、冰冻状态。
# - 状态开始和结束前都先推进冷却，保证速度变化不会丢失已经恢复的冷却。


func apply_haste(context, unit, duration_ms: int, cooldown_scheduler, logger) -> void:
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, "haste_start")
	var rate_before: int = unit.cooldown_rate_bp
	unit.haste_stack = 1
	unit.haste_end_time_ms = context.time_ms + duration_ms
	recalc_cooldown_rate(unit)
	unit.cooldown_version += 1
	logger.log(context, {
		"event_type": "HASTE_START",
		"source_id": unit.instance_id,
		"cooldown_rate_before_bp": rate_before,
		"cooldown_rate_after_bp": unit.cooldown_rate_bp,
		"cause": "effect",
	})
	_enqueue_expire(context, unit, "haste", unit.haste_end_time_ms)
	cooldown_scheduler.schedule_next_cooldown_check(context, unit)


func apply_slow(context, unit, duration_ms: int, cooldown_scheduler, logger) -> void:
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, "slow_start")
	var rate_before: int = unit.cooldown_rate_bp
	unit.slow_stack = 1
	unit.slow_end_time_ms = context.time_ms + duration_ms
	recalc_cooldown_rate(unit)
	unit.cooldown_version += 1
	logger.log(context, {
		"event_type": "SLOW_START",
		"source_id": unit.instance_id,
		"cooldown_rate_before_bp": rate_before,
		"cooldown_rate_after_bp": unit.cooldown_rate_bp,
		"cause": "effect",
	})
	_enqueue_expire(context, unit, "slow", unit.slow_end_time_ms)
	cooldown_scheduler.schedule_next_cooldown_check(context, unit)


func apply_freeze(context, unit, duration_ms: int, cooldown_scheduler, logger) -> void:
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, "freeze_start")
	unit.freeze_stack = 1
	unit.freeze_end_time_ms = context.time_ms + duration_ms
	logger.log(context, {
		"event_type": "FREEZE_START",
		"source_id": unit.instance_id,
		"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
		"was_blocked_by_freeze": true,
		"cause": "effect",
	})
	_enqueue_expire(context, unit, "freeze", unit.freeze_end_time_ms)


func expire_status(context, unit, status_id: String, cooldown_scheduler, logger) -> void:
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, status_id + "_expire")
	var rate_before: int = unit.cooldown_rate_bp
	match status_id:
		"haste":
			if context.time_ms < unit.haste_end_time_ms:
				return
			unit.haste_stack = 0
			unit.haste_end_time_ms = 0
			logger.log(context, {"event_type": "HASTE_END", "source_id": unit.instance_id, "cause": "status_expire"})
		"slow":
			if context.time_ms < unit.slow_end_time_ms:
				return
			unit.slow_stack = 0
			unit.slow_end_time_ms = 0
			logger.log(context, {"event_type": "SLOW_END", "source_id": unit.instance_id, "cause": "status_expire"})
		"freeze":
			if context.time_ms < unit.freeze_end_time_ms:
				return
			unit.freeze_stack = 0
			unit.freeze_end_time_ms = 0
			logger.log(context, {
				"event_type": "FREEZE_END",
				"source_id": unit.instance_id,
				"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
				"cause": "status_expire",
			})
			if unit.remaining_cooldown_ms <= 0 or unit.is_ready_blocked_by_freeze:
				unit.is_ready_blocked_by_freeze = false
				cooldown_scheduler.enqueue_player_trigger(context, unit, 22, "freeze_end_ready", 0)
				return
		_:
			return

	recalc_cooldown_rate(unit)
	if unit.cooldown_rate_bp != rate_before:
		unit.cooldown_version += 1
		logger.log(context, {
			"event_type": "COOLDOWN_RATE_RECALC",
			"source_id": unit.instance_id,
			"cooldown_rate_before_bp": rate_before,
			"cooldown_rate_after_bp": unit.cooldown_rate_bp,
			"cause": status_id + "_expire",
		})
	cooldown_scheduler.schedule_next_cooldown_check(context, unit)


func recalc_cooldown_rate(unit) -> void:
	var rate_bp: int = 10000
	if unit.haste_stack > 0:
		rate_bp = rate_bp * 20000 / 10000
	if unit.slow_stack > 0:
		rate_bp = rate_bp * 5000 / 10000
	unit.cooldown_rate_bp = rate_bp


func _enqueue_expire(context, unit, status_id: String, trigger_time_ms: int) -> void:
	context.next_event_sequence_id += 1
	var event = BATTLE_EVENT.new()
	event.setup({
		"event_id": "event_%d" % context.next_event_sequence_id,
		"event_type": "CARD_STATUS_EXPIRE",
		"trigger_time_ms": trigger_time_ms,
		"priority": 22,
		"sequence_id": context.next_event_sequence_id,
		"source_id": unit.instance_id,
		"target_id": unit.instance_id,
		"payload": {"unit_id": unit.instance_id, "status_id": status_id},
	})
	context.event_queue.push(event)

