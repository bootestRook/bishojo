extends RefCounted
class_name NodeChoiceManager

const NODE_CHOICE_OPTION = preload("res://scripts/systems/node_choice/node_choice_option.gd")
const V1_BALANCE_CONFIG = preload("res://scripts/data/balance/v1_balance_config.gd")

# 文件职责：
# - 生成并应用补给 / 金币节点的通用 3 选 1 纯逻辑效果。
# - 不显示 UI，不负责分支路由；RunManager 在应用后推进到 SYNTHESIS_CHECK。

var current_choices: Array = []
var balance_config = V1_BALANCE_CONFIG.new()


func generate_choices(node_type: String, run_manager) -> Array:
	current_choices = []
	match node_type:
		"supply":
			current_choices.append(_make_choice("supply_heal_1", "supply", "heal", "恢复 %d 点耐久" % balance_config.supply_heal_amount, "不超过局内耐久上限。", {"durability": balance_config.supply_heal_amount}))
			current_choices.append(_make_choice("supply_gold_2", "supply", "gold", "获得 %d 金币" % balance_config.supply_gold_amount, "补充少量经济。", {"gold": balance_config.supply_gold_amount}))
			current_choices.append(_make_choice("supply_mix", "supply", "mixed", "小补给", "恢复 %d 点耐久并获得 %d 金币。" % [balance_config.supply_heal_amount, balance_config.supply_mix_gold_amount], {"durability": balance_config.supply_heal_amount, "gold": balance_config.supply_mix_gold_amount}))
		"gold":
			current_choices.append(_make_choice("gold_4", "gold", "gold", "获得 %d 金币" % balance_config.gold_node_low_amount, "稳定经济补给。", {"gold": balance_config.gold_node_low_amount}))
			current_choices.append(_make_choice("gold_6", "gold", "gold", "获得 %d 金币" % balance_config.gold_node_high_amount, "更高金币收益。", {"gold": balance_config.gold_node_high_amount}))
			current_choices.append(_make_choice("gold_3_supply", "gold", "mixed", "金币与小补给", "获得 %d 金币并恢复 %d 点耐久。" % [balance_config.gold_node_mixed_gold_amount, balance_config.supply_heal_amount], {"gold": balance_config.gold_node_mixed_gold_amount, "durability": balance_config.supply_heal_amount}))
		_:
			pass

	return current_choices.duplicate()


func get_choice(option_id: String):
	var index: int = 0
	while index < current_choices.size():
		if current_choices[index].option_id == option_id:
			return current_choices[index]
		index += 1

	return null


func apply_choice(option, run_manager) -> Dictionary:
	if option == null:
		return {"ok": false, "reason": "option_not_found"}

	var gained_gold: int = option.payload.get("gold", 0)
	var gained_durability: int = option.payload.get("durability", 0)
	run_manager.gold += gained_gold
	if gained_durability > 0:
		run_manager.run_durability += gained_durability
		if run_manager.run_durability > run_manager.run_durability_max:
			run_manager.run_durability = run_manager.run_durability_max

	return {
		"ok": true,
		"reason": "ok",
		"option_id": option.option_id,
		"gained_gold": gained_gold,
		"gained_durability": gained_durability,
	}


func _make_choice(option_id: String, node_type: String, option_type: String, title: String, description: String, payload: Dictionary):
	var option = NODE_CHOICE_OPTION.new()
	option.setup(option_id, node_type, option_type, title, description, payload)
	return option
