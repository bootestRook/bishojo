extends RefCounted
class_name ChainGuard

# 文件职责：
# - 保护同一毫秒内的连锁事件，避免无限循环。
# - 超过上限的事件延后到 time_ms + 1，不直接丢弃。


func should_delay_event(context, event, config, logger) -> bool:
	if context.current_chain_time_ms != event.trigger_time_ms:
		context.current_chain_time_ms = event.trigger_time_ms
		context.chain_event_count_this_time = 0

	context.chain_event_count_this_time += 1
	if context.chain_event_count_this_time <= config.max_chain_events_per_same_time:
		return false

	event.trigger_time_ms += 1
	context.chain_event_count_this_time = 0
	logger.log(context, {
		"event_type": "CHAIN_LIMIT_DELAY",
		"source_id": event.source_id,
		"target_id": event.target_id,
		"cause": "max_chain_events_per_same_time",
		"chain_depth": event.chain_depth,
	})
	return true


func can_unit_trigger_now(context, unit, config) -> bool:
	return context.time_ms - unit.last_trigger_time_ms >= config.min_trigger_interval_ms


func next_allowed_trigger_time(unit, config) -> int:
	return unit.last_trigger_time_ms + config.min_trigger_interval_ms

