extends RefCounted
class_name BattleEventQueue

# 文件职责：
# - 提供稳定的战斗事件优先队列。
# - 排序键固定为 trigger_time_ms ASC、priority ASC、sequence_id ASC，保证同一毫秒可复盘。

var events: Array = []


func push(event) -> void:
	var insert_index: int = 0
	while insert_index < events.size():
		if _comes_before(event, events[insert_index]):
			break
		insert_index += 1

	events.insert(insert_index, event)


func pop():
	if events.is_empty():
		return null

	var event = events[0]
	events.remove_at(0)
	return event


func peek():
	if events.is_empty():
		return null

	return events[0]


func is_empty() -> bool:
	return events.is_empty()


func clear() -> void:
	events.clear()


func _comes_before(left, right) -> bool:
	if left.trigger_time_ms != right.trigger_time_ms:
		return left.trigger_time_ms < right.trigger_time_ms
	if left.priority != right.priority:
		return left.priority < right.priority

	return left.sequence_id < right.sequence_id

