extends RefCounted
class_name V1BalanceConfig

# 文件职责：
# - 集中保存 V1 原型调试期仍待定的可玩占位数值。
# - 这些值不是最终平衡，只用于让纯逻辑整局闭环、smoke test 和后续 UI 对接有稳定默认入口。
# - 新增或调整金币、补给、商店、奖励相关占位值时优先改本文件，避免散落在 RunManager / ShopManager / 节点逻辑里。

var initial_gold: int = 8
var normal_battle_gold_reward: int = 2
var high_reward_battle_gold_reward: int = 3
var safe_battle_gold_reward: int = 1
var boss_win_gold_reward: int = 0

var shop_refresh_cost: int = 2
var sell_refund_ratio_bp: int = 5000

var supply_heal_amount: int = 1
var supply_gold_amount: int = 2
var supply_mix_gold_amount: int = 1
var gold_node_low_amount: int = 4
var gold_node_high_amount: int = 6
var gold_node_mixed_gold_amount: int = 3

var debug_run_seed: int = 20260609
var debug_battle_seed_base: int = 1001


func get_combat_gold_reward(combat_branch_id: String, battle_type: String) -> int:
	if battle_type == "boss" or combat_branch_id == "boss_final":
		return boss_win_gold_reward

	match combat_branch_id:
		"normal_safe":
			return safe_battle_gold_reward
		"normal_high_reward":
			return high_reward_battle_gold_reward
		_:
			return normal_battle_gold_reward
