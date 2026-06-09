extends RefCounted
class_name RewardResult

# 文件职责：
# - 记录一次奖励发放前后的 Run 级结果。
# - 字段保持扁平，方便 RunManager.last_reward_results、smoke test 和未来 UI 日志直接读取。

var ok: bool = false
var reason: String = ""
var reward_id: String = ""
var reward_type: String = ""
var gold_before: int = 0
var gold_after: int = 0
var run_durability_before: int = 0
var run_durability_after: int = 0
var added_instance_ids: Array = []
var unlocked_slot_ids: Array = []
var payload: Dictionary = {}


func setup(data: Dictionary) -> void:
	ok = data.get("ok", false)
	reason = data.get("reason", "")
	reward_id = data.get("reward_id", "")
	reward_type = data.get("reward_type", "")
	gold_before = data.get("gold_before", 0)
	gold_after = data.get("gold_after", 0)
	run_durability_before = data.get("run_durability_before", 0)
	run_durability_after = data.get("run_durability_after", 0)
	added_instance_ids = data.get("added_instance_ids", []).duplicate()
	unlocked_slot_ids = data.get("unlocked_slot_ids", []).duplicate()
	payload = data.get("payload", {}).duplicate(true)


func to_data() -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"reward_id": reward_id,
		"reward_type": reward_type,
		"gold_before": gold_before,
		"gold_after": gold_after,
		"run_durability_before": run_durability_before,
		"run_durability_after": run_durability_after,
		"added_instance_ids": added_instance_ids.duplicate(),
		"unlocked_slot_ids": unlocked_slot_ids.duplicate(),
		"payload": payload.duplicate(true),
	}
