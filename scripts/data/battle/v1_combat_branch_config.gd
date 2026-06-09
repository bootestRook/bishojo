extends RefCounted
class_name V1CombatBranchConfig

# 文件职责：
# - 集中维护 V1 普通战分支与 Boss 分支的纯逻辑配置。
# - RunManager 只读取这里产出的分支字典，不再在流程方法里散写敌人、奖励档位或标题文案。

const BOSS_BRANCH_ID: String = "boss_final"

var normal_branch_order: Array = ["normal_safe", "normal_standard", "normal_high_reward"]
var branch_data: Dictionary = {
	"normal_safe": {
		"combat_branch_id": "normal_safe",
		"battle_type": "normal_safe",
		"title": "稳妥战",
		"description": "敌人较弱，奖励较少。",
		"reward_profile": "safe",
		"enemy_id": "training_dummy",
	},
	"normal_standard": {
		"combat_branch_id": "normal_standard",
		"battle_type": "normal_standard",
		"title": "普通战",
		"description": "标准敌人与标准奖励。",
		"reward_profile": "normal",
		"enemy_id": "goblin_attacker",
	},
	"normal_high_reward": {
		"combat_branch_id": "normal_high_reward",
		"battle_type": "normal_high_reward",
		"title": "高奖励战",
		"description": "敌人更危险，奖励更高。",
		"reward_profile": "high_reward",
		"enemy_id": "shield_guard",
	},
	"boss_final": {
		"combat_branch_id": "boss_final",
		"battle_type": "boss",
		"title": "最终首领",
		"description": "挑战 V1 终局首领。",
		"reward_profile": "boss",
		"enemy_id": "v1_final_boss",
	},
}


func get_normal_combat_options(normal_win_count: int) -> Array:
	var result: Array = []
	var index: int = 0
	while index < normal_branch_order.size():
		var branch_id: String = normal_branch_order[index]
		var option: Dictionary = branch_data.get(branch_id, {}).duplicate(true)
		option["normal_win_count"] = normal_win_count
		result.append(option)
		index += 1

	return result


func get_boss_option() -> Dictionary:
	return branch_data.get(BOSS_BRANCH_ID, {}).duplicate(true)


func get_enemy_id_for_branch(combat_branch_id: String) -> String:
	return branch_data.get(combat_branch_id, {}).get("enemy_id", "")


func get_reward_profile_for_branch(combat_branch_id: String) -> String:
	return branch_data.get(combat_branch_id, {}).get("reward_profile", "")


func is_boss_unlocked(normal_win_count: int, normal_win_target: int) -> bool:
	return normal_win_count >= normal_win_target
