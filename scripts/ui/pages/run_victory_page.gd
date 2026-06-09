extends V1UIViewBase
class_name RunVictoryPage

# 文件职责：
# - 展示整局胜利结算。
# - 结算数据全部来自 RunManager adapter，不重新统计规则。

var summary_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("整局胜利"))
	summary_label = make_label("", 420)
	root_box.add_child(summary_label)
	root_box.add_child(make_button("重新开始", Callable.create(app_controller, "restart_run_requested")))
	root_box.add_child(make_button("返回主菜单", Callable.create(app_controller, "return_to_main_menu_requested")))


func refresh() -> void:
	if run_manager == null or summary_label == null:
		return

	var data: Dictionary = run_manager.get_victory_summary()
	summary_label.text = "%s\n普通战胜利：%d 胜，目标 %d 胜\n最终金币：%d\n最终阵容：\n%s" % [
		data.get("title", ""),
		data.get("normal_win_count", 0),
		data.get("normal_win_target", 0),
		data.get("gold", 0),
		_format_formation(data.get("formation", {})),
	]


func _format_formation(formation: Dictionary) -> String:
	var result: String = ""
	var slots: Array = formation.get("slots", [])
	var index: int = 0
	while index < slots.size():
		var slot: Dictionary = slots[index]
		if slot.get("occupant_instance_id", "") != "":
			var occupant: Dictionary = slot.get("occupant", {})
			var treasure: Dictionary = occupant.get("treasure", {})
			result += "%s：%s\n" % [slot_to_text(slot), treasure.get("treasure_name", "")]
		index += 1
	return result
