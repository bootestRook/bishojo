extends RefCounted
class_name BattleEvent

# 文件职责：
# - 表示时间轴上的一个待处理事件。
# - 排序由 BattleEventQueue 统一按 time_ms / priority / sequence_id 处理。

var event_id: String = ""
var event_type: String = ""
var trigger_time_ms: int = 0
var priority: int = 0
var sequence_id: int = 0
var source_id: String = ""
var target_id: String = ""
var payload: Dictionary = {}
var version: int = 0
var chain_depth: int = 0


func setup(data: Dictionary) -> void:
	event_id = data.get("event_id", "")
	event_type = data.get("event_type", "")
	trigger_time_ms = data.get("trigger_time_ms", 0)
	priority = data.get("priority", 0)
	sequence_id = data.get("sequence_id", 0)
	source_id = data.get("source_id", "")
	target_id = data.get("target_id", "")
	payload = data.get("payload", {}).duplicate(true)
	version = data.get("version", 0)
	chain_depth = data.get("chain_depth", 0)

