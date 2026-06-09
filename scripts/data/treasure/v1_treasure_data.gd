extends RefCounted
class_name V1TreasureData

# 文件职责：
# - 保存单个秘宝少女的基础配置快照。
# - 该数据只描述构筑、商店、占格和战斗前可读字段，不执行任何战斗效果。

var treasure_id: String = ""
var treasure_name: String = ""
var rarity: String = "green"
var size_type: String = "small"
var footprint_width: int = 1
var footprint_height: int = 1
var price: int = 0
var tags: Array = []
var base_cooldown_ms: int = 0
var effect_list: Array = []
var position_rule: String = ""
var upgrade_rule: String = "same_name_2_to_1"
var description: String = ""


func setup(data: Dictionary) -> void:
	treasure_id = data.get("treasure_id", "")
	treasure_name = data.get("treasure_name", "")
	rarity = data.get("rarity", "green")
	size_type = data.get("size_type", "small")
	footprint_width = data.get("footprint_width", 1)
	footprint_height = data.get("footprint_height", 1)
	price = data.get("price", 0)
	tags = data.get("tags", []).duplicate()
	base_cooldown_ms = data.get("base_cooldown_ms", 0)
	effect_list = data.get("effect_list", []).duplicate(true)
	position_rule = data.get("position_rule", "")
	upgrade_rule = data.get("upgrade_rule", "same_name_2_to_1")
	description = data.get("description", "")


func to_data() -> Dictionary:
	return {
		"treasure_id": treasure_id,
		"treasure_name": treasure_name,
		"rarity": rarity,
		"size_type": size_type,
		"footprint_width": footprint_width,
		"footprint_height": footprint_height,
		"price": price,
		"tags": tags.duplicate(),
		"base_cooldown_ms": base_cooldown_ms,
		"effect_list": effect_list.duplicate(true),
		"position_rule": position_rule,
		"upgrade_rule": upgrade_rule,
		"description": description,
	}
