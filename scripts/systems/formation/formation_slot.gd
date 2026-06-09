extends RefCounted
class_name FormationSlot

# 文件职责：
# - 表示 2×5 战斗回路中的单个槽位。
# - 槽位只记录解锁和占用实例 ID，多格单位由 FormationModel 按同一个 instance_id 统一占用多个槽。

var slot_id: String = ""
var row: int = 0
var column: int = 0
var is_unlocked: bool = false
var occupant_instance_id: String = ""


func setup(new_slot_id: String, new_row: int, new_column: int) -> void:
	slot_id = new_slot_id
	row = new_row
	column = new_column


func is_occupied() -> bool:
	return occupant_instance_id != ""
