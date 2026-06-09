extends RefCounted
class_name BattleTimelineLogger

const BATTLE_LOG_ENTRY = preload("res://scripts/systems/battle/battle_log_entry.gd")

# 文件职责：
# - 为战斗上下文写入统一 BattleLogEntry。
# - 调用方只传关键字段，缺省字段保留默认值，保证 smoke 和未来 UI 都能读取同一日志结构。


func log(context, data: Dictionary):
	var entry = BATTLE_LOG_ENTRY.new()
	var payload: Dictionary = data.duplicate(true)
	payload["time_ms"] = payload.get("time_ms", context.time_ms)
	payload["log_id"] = "log_%d" % (context.timeline_log.size() + 1)
	entry.setup(payload)
	context.timeline_log.append(entry)
	return entry

