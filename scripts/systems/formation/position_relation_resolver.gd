extends RefCounted
class_name PositionRelationResolver

# 文件职责：
# - 基于 FormationModel 的占用状态查询站位关系。
# - 多格单位按同一个 instance_id 的占用范围整体判断，不按单槽拆成多个单位。


func get_occupied_range(formation_model, instance_id: String) -> Dictionary:
	var occupied: Array = formation_model.get_slots_occupied_by(instance_id)
	if occupied.is_empty():
		return {"ok": false, "slot_ids": []}

	var row_min: int = 999999
	var row_max: int = -1
	var col_min: int = 999999
	var col_max: int = -1
	var slot_ids: Array = []
	var index: int = 0
	while index < occupied.size():
		var slot = occupied[index]
		if slot.row < row_min:
			row_min = slot.row
		if slot.row > row_max:
			row_max = slot.row
		if slot.column < col_min:
			col_min = slot.column
		if slot.column > col_max:
			col_max = slot.column
		slot_ids.append(slot.slot_id)
		index += 1

	return {
		"ok": true,
		"row_min": row_min,
		"row_max": row_max,
		"col_min": col_min,
		"col_max": col_max,
		"slot_ids": slot_ids,
	}


func find_adjacent_instances(formation_model, instance_id: String) -> Array:
	var result: Array = []
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return result

	var row: int = occupied_range.get("row_min", 0)
	_append_occupant_at(formation_model, result, row, occupied_range.get("col_min", 0) - 1, instance_id)
	_append_occupant_at(formation_model, result, row, occupied_range.get("col_max", 0) + 1, instance_id)
	return result


func find_same_row_instances(formation_model, instance_id: String) -> Array:
	var result: Array = []
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return result

	var all_slots: Array = formation_model.get_occupied_slots()
	var index: int = 0
	while index < all_slots.size():
		var slot = all_slots[index]
		if slot.row >= occupied_range.get("row_min", 0) and slot.row <= occupied_range.get("row_max", 0):
			_append_unique_instance(result, slot.occupant_instance_id, instance_id)
		index += 1

	return result


func find_same_col_instances(formation_model, instance_id: String) -> Array:
	var result: Array = []
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return result

	var all_slots: Array = formation_model.get_occupied_slots()
	var index: int = 0
	while index < all_slots.size():
		var slot = all_slots[index]
		if slot.column >= occupied_range.get("col_min", 0) and slot.column <= occupied_range.get("col_max", 0):
			_append_unique_instance(result, slot.occupant_instance_id, instance_id)
		index += 1

	return result


func find_front_back_overlap_instances(formation_model, instance_id: String) -> Array:
	var result: Array = []
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return result

	var all_slots: Array = formation_model.get_occupied_slots()
	var index: int = 0
	while index < all_slots.size():
		var slot = all_slots[index]
		var row_is_other: bool = slot.row < occupied_range.get("row_min", 0) or slot.row > occupied_range.get("row_max", 0)
		var col_overlaps: bool = slot.column >= occupied_range.get("col_min", 0) and slot.column <= occupied_range.get("col_max", 0)
		if row_is_other and col_overlaps:
			_append_unique_instance(result, slot.occupant_instance_id, instance_id)
		index += 1

	return result


func is_on_edge(formation_model, instance_id: String) -> bool:
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return false

	return occupied_range.get("row_min", 0) == 0 or occupied_range.get("row_max", 0) == formation_model.row_count - 1 or occupied_range.get("col_min", 0) == 0 or occupied_range.get("col_max", 0) == formation_model.column_count - 1


func is_on_corner(formation_model, instance_id: String) -> bool:
	var occupied: Array = formation_model.get_slots_occupied_by(instance_id)
	var index: int = 0
	while index < occupied.size():
		var slot = occupied[index]
		var row_corner: bool = slot.row == 0 or slot.row == formation_model.row_count - 1
		var col_corner: bool = slot.column == 0 or slot.column == formation_model.column_count - 1
		if row_corner and col_corner:
			return true
		index += 1

	return false


func includes_center_column(formation_model, instance_id: String) -> bool:
	var occupied_range: Dictionary = get_occupied_range(formation_model, instance_id)
	if not occupied_range.get("ok", false):
		return false

	var center_column: int = 2
	return occupied_range.get("col_min", 0) <= center_column and occupied_range.get("col_max", 0) >= center_column


func _append_occupant_at(formation_model, result: Array, row: int, column: int, self_instance_id: String) -> void:
	if column < 0 or column >= formation_model.column_count:
		return

	var slot_id: String = "r%d_c%d" % [row, column]
	var slot = formation_model.get_slot(slot_id)
	if slot == null:
		return

	_append_unique_instance(result, slot.occupant_instance_id, self_instance_id)


func _append_unique_instance(result: Array, candidate_instance_id: String, self_instance_id: String) -> void:
	if candidate_instance_id == "" or candidate_instance_id == self_instance_id:
		return

	if not result.has(candidate_instance_id):
		result.append(candidate_instance_id)
