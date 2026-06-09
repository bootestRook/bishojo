extends RefCounted
class_name SynthesisResolver

# 文件职责：
# - 执行 V1 2 合 1 自动升格规则。
# - 只处理实例稀有度、实例移除和回路占位保留，不改秘宝基础配置，不触发战斗效果。


func check_and_apply(inventory_model, formation_model, rarity_config) -> Array:
	var logs: Array = []
	var did_apply: bool = true
	while did_apply:
		did_apply = false
		var candidates: Array = inventory_model.find_synthesis_candidates()
		var index: int = 0
		while index < candidates.size():
			var pair: Dictionary = candidates[index]
			var instance_a = pair.get("a", null)
			var instance_b = pair.get("b", null)
			if can_synthesize(instance_a, instance_b, rarity_config):
				var primary = choose_primary_instance(instance_a, instance_b, formation_model)
				var consumed = instance_b
				if primary == instance_b:
					consumed = instance_a
				logs.append(apply_synthesis_pair(primary, consumed, inventory_model, formation_model, rarity_config))
				did_apply = true
				break
			index += 1

	return logs


func can_synthesize(instance_a, instance_b, rarity_config) -> bool:
	if instance_a == null or instance_b == null:
		return false
	if instance_a.instance_id == instance_b.instance_id:
		return false
	if instance_a.treasure_id != instance_b.treasure_id:
		return false
	if instance_a.rarity != instance_b.rarity:
		return false

	return rarity_config.can_upgrade(instance_a.rarity)


func choose_primary_instance(instance_a, instance_b, formation_model):
	if instance_a.is_in_formation and not instance_b.is_in_formation:
		return instance_a
	if instance_b.is_in_formation and not instance_a.is_in_formation:
		return instance_b
	if instance_a.is_in_formation and instance_b.is_in_formation:
		var order_a: int = formation_model.get_first_slot_sort_value(instance_a.instance_id)
		var order_b: int = formation_model.get_first_slot_sort_value(instance_b.instance_id)
		if order_a <= order_b:
			return instance_a
		return instance_b

	if instance_a.created_order <= instance_b.created_order:
		return instance_a

	return instance_b


func apply_synthesis_pair(primary_instance, consumed_instance, inventory_model, formation_model, rarity_config) -> Dictionary:
	var kept_formation_slot_ids: Array = []
	var kept_slots: Array = formation_model.get_slots_occupied_by(primary_instance.instance_id)
	var index: int = 0
	while index < kept_slots.size():
		kept_formation_slot_ids.append(kept_slots[index].slot_id)
		index += 1

	var old_rarity: String = primary_instance.rarity
	var new_rarity: String = rarity_config.get_next_rarity(old_rarity)
	if consumed_instance.is_in_formation:
		formation_model.remove_instance(consumed_instance.instance_id)

	inventory_model.remove_instance(consumed_instance.instance_id)
	primary_instance.rarity = new_rarity

	return {
		"consumed_instance_id": consumed_instance.instance_id,
		"result_instance_id": primary_instance.instance_id,
		"treasure_id": primary_instance.treasure_id,
		"old_rarity": old_rarity,
		"new_rarity": new_rarity,
		"kept_formation_slot_ids": kept_formation_slot_ids,
	}
