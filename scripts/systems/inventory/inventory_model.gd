extends RefCounted
class_name InventoryModel

const TREASURE_INSTANCE = preload("res://scripts/systems/inventory/treasure_instance.gd")

# 文件职责：
# - 管理 Run 内秘宝实例集合。
# - 只处理实例增删查和合成候选查找，不负责 UI、战斗、商店库存或回路占格。

var instances: Dictionary = {}
var created_counter: int = 0


func add_treasure(treasure_id: String, rarity: String, source_type: String):
	created_counter += 1
	var instance_id: String = "treasure_%d" % created_counter
	var instance = TREASURE_INSTANCE.new()
	instance.setup(instance_id, treasure_id, rarity, source_type, created_counter)
	instances[instance_id] = instance
	return instance


func remove_instance(instance_id: String) -> bool:
	if not instances.has(instance_id):
		return false

	instances.erase(instance_id)
	return true


func get_instance(instance_id: String):
	return instances.get(instance_id, null)


func get_all_instances() -> Array:
	return instances.values()


func get_inventory_instances() -> Array:
	var result: Array = []
	var all_instances: Array = get_all_instances()
	var index: int = 0
	while index < all_instances.size():
		var instance = all_instances[index]
		if instance.is_in_inventory:
			result.append(instance)
		index += 1

	return result


func get_formation_instances() -> Array:
	var result: Array = []
	var all_instances: Array = get_all_instances()
	var index: int = 0
	while index < all_instances.size():
		var instance = all_instances[index]
		if instance.is_in_formation:
			result.append(instance)
		index += 1

	return result


func count_by_treasure_and_rarity(treasure_id: String, rarity: String) -> int:
	var count: int = 0
	var all_instances: Array = get_all_instances()
	var index: int = 0
	while index < all_instances.size():
		var instance = all_instances[index]
		if instance.treasure_id == treasure_id and instance.rarity == rarity:
			count += 1
		index += 1

	return count


func find_synthesis_candidates() -> Array:
	var result: Array = []
	var all_instances: Array = get_all_instances()
	var left_index: int = 0
	while left_index < all_instances.size():
		var right_index: int = left_index + 1
		while right_index < all_instances.size():
			var left_instance = all_instances[left_index]
			var right_instance = all_instances[right_index]
			if left_instance.treasure_id == right_instance.treasure_id and left_instance.rarity == right_instance.rarity:
				result.append({"a": left_instance, "b": right_instance})
			right_index += 1
		left_index += 1

	return result
