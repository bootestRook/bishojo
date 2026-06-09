extends RefCounted
class_name RewardManager

const V1_BALANCE_CONFIG = preload("res://scripts/data/balance/v1_balance_config.gd")
const REWARD_OPTION = preload("res://scripts/systems/reward/reward_option.gd")
const REWARD_RESULT = preload("res://scripts/systems/reward/reward_result.gd")

# 文件职责：
# - 统一执行 V1 金币、秘宝和耐久奖励的纯逻辑发放。
# - 本模块不打开 UI、不生成节点，只返回结构化结果给 RunManager 记录。

var balance_config = V1_BALANCE_CONFIG.new()
var current_reward_options: Array = []


func grant_gold(run_manager, amount: int, source_type: String) -> Dictionary:
	if amount < 0:
		return _make_result(false, "negative_amount", source_type, "gold", run_manager, [], {}, {})

	var gold_before: int = run_manager.gold
	var durability_before: int = run_manager.run_durability
	run_manager.gold += amount
	return _make_result(true, "ok", source_type, "gold", run_manager, [], {
		"amount": amount,
		"source_type": source_type,
	}, {
		"gold_before": gold_before,
		"gold_after": run_manager.gold,
		"run_durability_before": durability_before,
		"run_durability_after": run_manager.run_durability,
	})


func grant_treasure(run_manager, treasure_id: String, rarity: String, source_type: String) -> Dictionary:
	if not run_manager.treasure_catalog.has_treasure_id(treasure_id):
		return _make_result(false, "treasure_not_found", source_type, "treasure", run_manager, [], {
			"treasure_id": treasure_id,
			"rarity": rarity,
		}, {})

	var gold_before: int = run_manager.gold
	var durability_before: int = run_manager.run_durability
	var instance = run_manager.inventory_model.add_treasure(treasure_id, rarity, source_type)
	return _make_result(true, "ok", source_type, "treasure", run_manager, [instance.instance_id], {
		"treasure_id": treasure_id,
		"rarity": rarity,
		"source_type": source_type,
	}, {
		"gold_before": gold_before,
		"gold_after": run_manager.gold,
		"run_durability_before": durability_before,
		"run_durability_after": run_manager.run_durability,
	})


func restore_run_durability(run_manager, amount: int, source_type: String) -> Dictionary:
	if amount < 0:
		return _make_result(false, "negative_amount", source_type, "durability", run_manager, [], {}, {})

	var gold_before: int = run_manager.gold
	var durability_before: int = run_manager.run_durability
	run_manager.run_durability += amount
	if run_manager.run_durability > run_manager.run_durability_max:
		run_manager.run_durability = run_manager.run_durability_max

	return _make_result(true, "ok", source_type, "durability", run_manager, [], {
		"amount": amount,
		"source_type": source_type,
	}, {
		"gold_before": gold_before,
		"gold_after": run_manager.gold,
		"run_durability_before": durability_before,
		"run_durability_after": run_manager.run_durability,
	})


func grant_combat_reward(run_manager, battle_type: String, combat_branch_id: String) -> Dictionary:
	var amount: int = balance_config.get_combat_gold_reward(combat_branch_id, battle_type)
	var result: Dictionary = grant_gold(run_manager, amount, "combat")
	var payload: Dictionary = result.get("payload", {})
	payload["battle_type"] = battle_type
	payload["combat_branch_id"] = combat_branch_id
	payload["reward_profile"] = _get_reward_profile(combat_branch_id, battle_type)
	result["payload"] = payload
	return result


func generate_post_battle_rewards(run_manager, battle_type: String, combat_branch_id: String) -> Array:
	current_reward_options = []
	var amount: int = balance_config.get_combat_gold_reward(combat_branch_id, battle_type)
	var option = REWARD_OPTION.new()
	option.setup({
		"reward_id": "post_battle_gold_%s" % combat_branch_id,
		"reward_type": "gold",
		"title": "战斗奖励",
		"description": "获得战斗结算金币。",
		"payload": {
			"amount": amount,
			"battle_type": battle_type,
			"combat_branch_id": combat_branch_id,
		},
		"source_type": "combat",
		"weight": 100,
		"can_skip": false,
	})
	current_reward_options.append(option)
	return current_reward_options.duplicate()


func apply_reward_option(option_id: String, run_manager) -> Dictionary:
	var option = _get_reward_option(option_id)
	if option == null:
		return _make_result(false, "reward_option_not_found", option_id, "", run_manager, [], {}, {})

	match option.reward_type:
		"gold":
			return grant_gold(run_manager, option.payload.get("amount", 0), option.source_type)
		"treasure":
			return grant_treasure(run_manager, option.payload.get("treasure_id", ""), option.payload.get("rarity", "green"), option.source_type)
		"durability":
			return restore_run_durability(run_manager, option.payload.get("amount", 0), option.source_type)
		_:
			return _make_result(false, "unsupported_reward_type", option.reward_id, option.reward_type, run_manager, [], option.payload, {})


func _get_reward_option(option_id: String):
	var index: int = 0
	while index < current_reward_options.size():
		if current_reward_options[index].reward_id == option_id:
			return current_reward_options[index]
		index += 1

	return null


func _get_reward_profile(combat_branch_id: String, battle_type: String) -> String:
	if battle_type == "boss" or combat_branch_id == "boss_final":
		return "boss"
	match combat_branch_id:
		"normal_safe":
			return "safe"
		"normal_high_reward":
			return "high_reward"
		_:
			return "normal"


func _make_result(ok: bool, reason: String, reward_id: String, reward_type: String, run_manager, added_instance_ids: Array, payload: Dictionary, overrides: Dictionary) -> Dictionary:
	var result = REWARD_RESULT.new()
	result.setup({
		"ok": ok,
		"reason": reason,
		"reward_id": reward_id,
		"reward_type": reward_type,
		"gold_before": overrides.get("gold_before", run_manager.gold),
		"gold_after": overrides.get("gold_after", run_manager.gold),
		"run_durability_before": overrides.get("run_durability_before", run_manager.run_durability),
		"run_durability_after": overrides.get("run_durability_after", run_manager.run_durability),
		"added_instance_ids": added_instance_ids,
		"unlocked_slot_ids": [],
		"payload": payload,
	})
	return result.to_data()
