extends RefCounted
class_name V1SlotUnlockConfig

# 文件职责：
# - 集中配置战斗回路槽位解锁节奏，FormationModel 只消费查询结果。
# - 当前是 V1 占位节奏：0 胜给 3 格，随后按普通战胜利逐步扩展；后续平衡只需要改这里。

var unlock_steps: Array = [
	{"normal_win_count": 0, "slot_ids": ["r0_c0", "r0_c1", "r1_c0"]},
	{"normal_win_count": 2, "slot_ids": ["r1_c1", "r0_c2"]},
	{"normal_win_count": 4, "slot_ids": ["r1_c2", "r0_c3"]},
	{"normal_win_count": 6, "slot_ids": ["r1_c3"]},
	{"normal_win_count": 8, "slot_ids": ["r0_c4", "r1_c4"]},
]


func get_unlocked_slot_ids(normal_win_count: int) -> Array:
	var result: Array = []
	var index: int = 0
	while index < unlock_steps.size():
		var step: Dictionary = unlock_steps[index]
		if normal_win_count >= step.get("normal_win_count", 0):
			var ids: Array = step.get("slot_ids", [])
			var id_index: int = 0
			while id_index < ids.size():
				if not result.has(ids[id_index]):
					result.append(ids[id_index])
				id_index += 1
		index += 1

	return result


func is_slot_unlocked(slot_id: String, normal_win_count: int) -> bool:
	return get_unlocked_slot_ids(normal_win_count).has(slot_id)
