extends RefCounted
class_name V1StarterTreasureOptions

# 文件职责：
# - 定义初始营地 3 选 1 的候选秘宝少女 ID。
# - 本阶段只返回候选 ID，不创建秘宝实例，不写入背包，也不处理上阵、合成、尺寸或战斗效果。

var starter_treasure_ids: Array = [
	"flame_blade",
	"thunder_bell",
	"ice_mirror",
]


func get_treasure_ids() -> Array:
	return starter_treasure_ids.duplicate()


func has_treasure_id(treasure_id: String) -> bool:
	return treasure_id in starter_treasure_ids
