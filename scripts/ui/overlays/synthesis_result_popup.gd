extends V1UIViewBase
class_name SynthesisResultPopup

# 文件职责：
# - 展示最近一次自动 2 合 1 升格结果。
# - 无合成时显示短提示；确认只关闭覆盖层，不推进底层流程。

var result_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("合成反馈"))
	result_label = make_label("", 520)
	root_box.add_child(result_label)
	root_box.add_child(make_button("确认", Callable.create(app_controller, "close_overlay_requested").bind("synthesis_result_popup")))


func refresh() -> void:
	if run_manager == null or result_label == null:
		return

	var results: Array = run_manager.get_last_synthesis_results()
	if results.is_empty():
		result_label.text = "本次没有触发合成，已进入回路编辑。"
		return

	var text: String = ""
	var index: int = 0
	while index < results.size():
		var result: Dictionary = results[index]
		var card: Dictionary = run_manager.get_card_detail_display_data(result.get("treasure_id", ""), result.get("new_rarity", "green"))
		text += "%s 完成升格\n稀有度：%s 升为 %s\n保留原有上阵位置：%s\n\n" % [
			card.get("treasure_name", "秘宝少女"),
			_rarity_text(result.get("old_rarity", "")),
			_rarity_text(result.get("new_rarity", "")),
			"是" if not result.get("kept_formation_slot_ids", []).is_empty() else "否",
		]
		index += 1
	result_label.text = text


func _rarity_text(rarity: String) -> String:
	match rarity:
		"green":
			return "绿"
		"blue":
			return "蓝"
		"purple":
			return "紫"
		"yellow":
			return "黄"
		_:
			return rarity
