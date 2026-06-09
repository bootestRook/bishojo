extends V1UIViewBase
class_name InvalidFormationPopup

# 文件职责：
# - 显示 validate_formation 或 can_place 的失败原因。
# - 中文解释在 UI 层完成，底层仍返回稳定 reason key。

var message_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("阵容无效"))
	message_label = make_label("", 360)
	root_box.add_child(message_label)
	root_box.add_child(make_button("关闭", Callable.create(app_controller, "close_overlay_requested").bind("invalid_formation_popup")))


func refresh() -> void:
	if run_manager == null or message_label == null:
		return

	var validation: Dictionary = run_manager.validate_formation()
	message_label.text = "最近反馈：%s\n阵容检查：%s\n说明：锁定槽、重叠、越界、多格跨行或未上阵单位都会阻止确认。" % [
		app_controller.last_ui_message,
		reason_to_text(validation.get("reason", "")),
	]
