extends RefCounted
class_name ChargeResolver

# 文件职责：
# - 处理充能立即减少目标当前剩余冷却的规则。
# - 充能到 0 时如果目标冰冻，则只标记阻塞，等待冰冻结束补触发。


func apply_charge(context, source_unit, target_unit, charge_ms: int, cooldown_scheduler, logger, chain_depth: int = 0) -> void:
	cooldown_scheduler.update_cooldown_to_now(context, target_unit, logger, "charge")
	var before: int = target_unit.remaining_cooldown_ms
	target_unit.remaining_cooldown_ms -= charge_ms
	if target_unit.remaining_cooldown_ms < 0:
		target_unit.remaining_cooldown_ms = 0
	target_unit.last_cooldown_update_time_ms = context.time_ms
	target_unit.cooldown_version += 1
	logger.log(context, {
		"event_type": "CHARGE",
		"source_id": source_unit.instance_id,
		"target_id": target_unit.instance_id,
		"effect_type": "charge",
		"remaining_cooldown_before_ms": before,
		"remaining_cooldown_after_ms": target_unit.remaining_cooldown_ms,
		"cause": "effect",
		"chain_depth": chain_depth,
	})
	if target_unit.remaining_cooldown_ms <= 0:
		if target_unit.freeze_stack > 0:
			target_unit.is_ready_blocked_by_freeze = true
			logger.log(context, {
				"event_type": "PLAYER_TRIGGER_BLOCKED_BY_FREEZE",
				"source_id": target_unit.instance_id,
				"remaining_cooldown_after_ms": target_unit.remaining_cooldown_ms,
				"was_blocked_by_freeze": true,
				"cause": "charged_to_ready",
			})
		else:
			cooldown_scheduler.enqueue_player_trigger(context, target_unit, 20, "charged_to_ready", chain_depth + 1)
	else:
		cooldown_scheduler.schedule_next_cooldown_check(context, target_unit)

