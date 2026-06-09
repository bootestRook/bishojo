extends RefCounted
class_name RewardOption

# 文件职责：
# - 表示一次奖励选择里的单个候选项。
# - V1 只需要纯逻辑字段，不绑定 UI 控件、图标、动画或场景节点。

var reward_id: String = ""
var reward_type: String = ""
var title: String = ""
var description: String = ""
var payload: Dictionary = {}
var source_type: String = ""
var weight: int = 0
var can_skip: bool = false


func setup(data: Dictionary) -> void:
	reward_id = data.get("reward_id", "")
	reward_type = data.get("reward_type", "")
	title = data.get("title", "")
	description = data.get("description", "")
	payload = data.get("payload", {}).duplicate(true)
	source_type = data.get("source_type", "")
	weight = data.get("weight", 0)
	can_skip = data.get("can_skip", false)


func to_data() -> Dictionary:
	return {
		"reward_id": reward_id,
		"reward_type": reward_type,
		"title": title,
		"description": description,
		"payload": payload.duplicate(true),
		"source_type": source_type,
		"weight": weight,
		"can_skip": can_skip,
	}
