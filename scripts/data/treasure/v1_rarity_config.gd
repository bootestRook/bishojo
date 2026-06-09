extends RefCounted
class_name V1RarityConfig

# 文件职责：
# - 集中维护 V1 稀有度顺序和 2 合 1 升格边界。
# - yellow 是 V1 最高稀有度，查询不到的稀有度一律不可升格。

const GREEN: String = "green"
const BLUE: String = "blue"
const PURPLE: String = "purple"
const YELLOW: String = "yellow"

var rarity_order: Array = [GREEN, BLUE, PURPLE, YELLOW]


func get_next_rarity(rarity: String) -> String:
	match rarity:
		GREEN:
			return BLUE
		BLUE:
			return PURPLE
		PURPLE:
			return YELLOW
		_:
			return ""


func can_upgrade(rarity: String) -> bool:
	return get_next_rarity(rarity) != ""


func get_rarity_order(rarity: String) -> int:
	var index: int = 0
	while index < rarity_order.size():
		if rarity_order[index] == rarity:
			return index
		index += 1

	return -1


func is_valid_rarity(rarity: String) -> bool:
	return get_rarity_order(rarity) >= 0
