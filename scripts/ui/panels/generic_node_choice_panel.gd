extends V1UIViewBase
class_name GenericNodeChoicePanel

# 文件职责：
# - RunBoardPage 内部补给 / 金币通用 2～3 选 1 面板。
# - 节点效果只通过 RunManager.apply_node_choice 执行。

var status_label: Label = null
var option_box: VBoxContainer = null


func _build() -> void:
	root_box.add_child(make_title("节点选择"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	option_box = make_section_box("NodeChoices")
	root_box.add_child(option_box)


func refresh() -> void:
	if run_manager == null or option_box == null:
		return

	var summary: Dictionary = run_manager.get_run_summary()
	status_label.text = "%s\n当前分支：%s" % [
		make_status_text(),
		branch_type_to_text(summary.get("current_branch_type", "")),
	]
	clear_children(option_box)
	var options: Array = run_manager.get_node_choice_display_data()
	var index: int = 0
	while index < options.size():
		var option: Dictionary = options[index]
		var text: String = "%s\n类型：%s，%s\n%s\n奖励：%s" % [
			option.get("title", ""),
			option.get("node_type_text", ""),
			option.get("option_type_text", ""),
			option.get("description", ""),
			option.get("reward_text", ""),
		]
		option_box.add_child(make_button(text, Callable.create(app_controller, "apply_node_choice_requested").bind(option.get("option_id", ""))))
		index += 1
