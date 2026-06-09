extends RefCounted
class_name TreasureInstance

# 文件职责：
# - 表示玩家在单局内拥有的一份秘宝少女实例。
# - 实例只记录身份、来源、稀有度和所在层级，不保存 UI 节点或战斗状态。

var instance_id: String = ""
var treasure_id: String = ""
var rarity: String = "green"
var source_type: String = ""
var is_in_inventory: bool = true
var is_in_formation: bool = false
var created_order: int = 0
var placed_order: int = -1
var locked_reason: String = ""


func setup(new_instance_id: String, new_treasure_id: String, new_rarity: String, new_source_type: String, new_created_order: int) -> void:
	instance_id = new_instance_id
	treasure_id = new_treasure_id
	rarity = new_rarity
	source_type = new_source_type
	created_order = new_created_order


func to_data() -> Dictionary:
	return {
		"instance_id": instance_id,
		"treasure_id": treasure_id,
		"rarity": rarity,
		"source_type": source_type,
		"is_in_inventory": is_in_inventory,
		"is_in_formation": is_in_formation,
		"created_order": created_order,
		"placed_order": placed_order,
		"locked_reason": locked_reason,
	}
