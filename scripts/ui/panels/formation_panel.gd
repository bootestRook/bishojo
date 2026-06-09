extends V1UIViewBase
class_name FormationPanel

# 文件职责：
# - RunBoardPage 内部 2×5 回路编辑面板。
# - 支持点击选中 + 点击槽位的调试稳定路径，拖拽后续可在本面板内扩展。

var status_label: Label = null
var selected_label: Label = null
var validation_label: Label = null
var grid: GridContainer = null


func _build() -> void:
	root_box.add_child(make_title("回路编辑"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	selected_label = make_label("", 70)
	root_box.add_child(selected_label)
	grid = GridContainer.new()
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_box.add_child(grid)
	validation_label = make_label("", 70)
	root_box.add_child(validation_label)
	var controls := HBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(make_button("背包", Callable.create(app_controller, "open_bag_requested")))
	controls.add_child(make_button("调试自动上阵", Callable.create(app_controller, "formation_auto_arrange_requested")))
	controls.add_child(make_button("下阵所选", Callable.create(app_controller, "formation_remove_selected_requested")))
	controls.add_child(make_button("确认阵容", Callable.create(app_controller, "confirm_formation_requested")))
	root_box.add_child(controls)


func refresh() -> void:
	if run_manager == null or grid == null:
		return

	status_label.text = make_status_text()
	selected_label.text = "当前选中：%s" % _selected_text()
	clear_children(grid)
	var data: Dictionary = run_manager.get_formation_display_data()
	var slots: Array = data.get("slots", [])
	var index: int = 0
	while index < slots.size():
		var slot: Dictionary = slots[index]
		var text: String = _slot_text(slot)
		var button := make_button(text, Callable.create(app_controller, "formation_slot_requested").bind(slot.get("slot_id", ""), slot.get("occupant_instance_id", "")))
		button.custom_minimum_size = Vector2(0, 150)
		grid.add_child(button)
		index += 1

	var validation: Dictionary = data.get("validation", {})
	validation_label.text = "阵容检查：%s" % reason_to_text(validation.get("reason", ""))


func _slot_text(slot: Dictionary) -> String:
	var base: String = "%s\n" % slot_to_text(slot)
	if not slot.get("is_unlocked", false):
		return base + "锁定"
	if slot.get("occupant_instance_id", "") == "":
		return base + "空槽"

	var occupant: Dictionary = slot.get("occupant", {})
	var treasure: Dictionary = occupant.get("treasure", {})
	return base + "%s\n%s" % [
		treasure.get("treasure_name", ""),
		occupant.get("display_name", ""),
	]


func _selected_text() -> String:
	if app_controller.selected_formation_instance_id == "":
		return "未选择"
	var inventory: Array = run_manager.get_inventory_display_data()
	var index: int = 0
	while index < inventory.size():
		if inventory[index].get("instance_id", "") == app_controller.selected_formation_instance_id:
			return inventory[index].get("display_name", "秘宝少女")
		index += 1
	return "秘宝少女"
