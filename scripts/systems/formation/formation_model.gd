extends RefCounted
class_name FormationModel

const FORMATION_SLOT = preload("res://scripts/systems/formation/formation_slot.gd")
const SIZE_CONFIG = preload("res://scripts/data/treasure/v1_treasure_size_config.gd")
const UNLOCK_CONFIG = preload("res://scripts/systems/formation/v1_slot_unlock_config.gd")

# 文件职责：
# - 管理 V1 2×5 战斗回路的纯逻辑占格。
# - 不处理拖拽 UI、不创建节点、不结算战斗，只维护槽位状态和合法性检查。

var row_count: int = 2
var column_count: int = 5
var slots: Dictionary = {}
var slot_order: Array = []
var size_config = SIZE_CONFIG.new()
var unlock_config = UNLOCK_CONFIG.new()


func setup_grid() -> void:
	slots = {}
	slot_order = []
	var row: int = 0
	while row < row_count:
		var column: int = 0
		while column < column_count:
			var slot_id: String = _make_slot_id(row, column)
			var slot = FORMATION_SLOT.new()
			slot.setup(slot_id, row, column)
			slots[slot_id] = slot
			slot_order.append(slot_id)
			column += 1
		row += 1


func apply_unlocks(normal_win_count: int) -> void:
	var unlocked_ids: Array = unlock_config.get_unlocked_slot_ids(normal_win_count)
	var index: int = 0
	while index < slot_order.size():
		var slot = slots[slot_order[index]]
		slot.is_unlocked = unlocked_ids.has(slot.slot_id)
		index += 1


func get_slot(slot_id: String):
	return slots.get(slot_id, null)


func get_all_slots() -> Array:
	var result: Array = []
	var index: int = 0
	while index < slot_order.size():
		result.append(slots[slot_order[index]])
		index += 1

	return result


func get_unlocked_slots() -> Array:
	var result: Array = []
	var all_slots: Array = get_all_slots()
	var index: int = 0
	while index < all_slots.size():
		if all_slots[index].is_unlocked:
			result.append(all_slots[index])
		index += 1

	return result


func get_occupied_slots() -> Array:
	var result: Array = []
	var all_slots: Array = get_all_slots()
	var index: int = 0
	while index < all_slots.size():
		if all_slots[index].is_occupied():
			result.append(all_slots[index])
		index += 1

	return result


func get_slots_occupied_by(instance_id: String) -> Array:
	var result: Array = []
	var all_slots: Array = get_all_slots()
	var index: int = 0
	while index < all_slots.size():
		if all_slots[index].occupant_instance_id == instance_id:
			result.append(all_slots[index])
		index += 1

	return result


func clear_instance(instance_id: String) -> void:
	var occupied: Array = get_slots_occupied_by(instance_id)
	var index: int = 0
	while index < occupied.size():
		occupied[index].occupant_instance_id = ""
		index += 1


func clear_all() -> void:
	var all_slots: Array = get_all_slots()
	var index: int = 0
	while index < all_slots.size():
		all_slots[index].occupant_instance_id = ""
		index += 1


func can_place(instance_id: String, treasure_data, anchor_slot_id: String) -> Dictionary:
	var anchor_slot = get_slot(anchor_slot_id)
	if anchor_slot == null:
		return {"ok": false, "reason": "slot_not_found", "required_slot_ids": []}

	if not size_config.is_valid_size_type(treasure_data.size_type):
		return {"ok": false, "reason": "invalid_size_type", "required_slot_ids": []}

	var footprint: Dictionary = size_config.get_footprint(treasure_data.size_type)
	var width: int = footprint.get("width", 0)
	var height: int = footprint.get("height", 0)
	if height > 1:
		return {"ok": false, "reason": "cross_row_not_allowed", "required_slot_ids": []}

	return _can_place_footprint(instance_id, width, height, anchor_slot_id)


func _can_place_footprint(instance_id: String, width: int, height: int, anchor_slot_id: String) -> Dictionary:
	var anchor_slot = get_slot(anchor_slot_id)
	if anchor_slot == null:
		return {"ok": false, "reason": "slot_not_found", "required_slot_ids": []}

	if height > 1:
		return {"ok": false, "reason": "cross_row_not_allowed", "required_slot_ids": []}

	if anchor_slot.column + width > column_count:
		return {"ok": false, "reason": "out_of_bounds", "required_slot_ids": []}

	var required_slot_ids: Array = []
	var offset: int = 0
	while offset < width:
		var slot_id: String = _make_slot_id(anchor_slot.row, anchor_slot.column + offset)
		var slot = get_slot(slot_id)
		if slot == null:
			return {"ok": false, "reason": "slot_not_found", "required_slot_ids": required_slot_ids}
		required_slot_ids.append(slot_id)
		if not slot.is_unlocked:
			return {"ok": false, "reason": "slot_locked", "required_slot_ids": required_slot_ids}
		if slot.occupant_instance_id != "" and slot.occupant_instance_id != instance_id:
			return {"ok": false, "reason": "slot_occupied", "required_slot_ids": required_slot_ids}
		offset += 1

	return {"ok": true, "reason": "ok", "required_slot_ids": required_slot_ids}


func place_instance(instance_id: String, treasure_data, anchor_slot_id: String) -> bool:
	var result: Dictionary = can_place(instance_id, treasure_data, anchor_slot_id)
	if not result.get("ok", false):
		return false

	clear_instance(instance_id)
	var required_slot_ids: Array = result.get("required_slot_ids", [])
	var index: int = 0
	while index < required_slot_ids.size():
		slots[required_slot_ids[index]].occupant_instance_id = instance_id
		index += 1

	return true


func remove_instance(instance_id: String) -> bool:
	var occupied: Array = get_slots_occupied_by(instance_id)
	if occupied.is_empty():
		return false

	clear_instance(instance_id)
	return true


func move_instance(instance_id: String, anchor_slot_id: String) -> bool:
	# 模型层只知道当前已占用范围；新上阵和尺寸查询由 RunManager 负责。
	var occupied: Array = get_slots_occupied_by(instance_id)
	if occupied.is_empty():
		return false

	var result: Dictionary = _can_place_footprint(instance_id, occupied.size(), 1, anchor_slot_id)
	if not result.get("ok", false):
		return false

	clear_instance(instance_id)
	var required_slot_ids: Array = result.get("required_slot_ids", [])
	var index: int = 0
	while index < required_slot_ids.size():
		slots[required_slot_ids[index]].occupant_instance_id = instance_id
		index += 1

	return true


func has_any_unit_placed() -> bool:
	return not get_occupied_slots().is_empty()


func validate_formation() -> Dictionary:
	if not has_any_unit_placed():
		return {"ok": false, "reason": "no_units_placed"}

	return {"ok": true, "reason": "ok"}


func get_first_slot_sort_value(instance_id: String) -> int:
	var occupied: Array = get_slots_occupied_by(instance_id)
	if occupied.is_empty():
		return 999999

	var best: int = 999999
	var index: int = 0
	while index < occupied.size():
		var slot = occupied[index]
		var value: int = slot.row * 100 + slot.column
		if value < best:
			best = value
		index += 1

	return best


func _make_slot_id(row: int, column: int) -> String:
	return "r%d_c%d" % [row, column]
