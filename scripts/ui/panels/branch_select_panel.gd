extends V1UIViewBase
class_name BranchSelectPanel

# 文件职责：
# - RunBoardPage 内部分支选择面板。
# - 只展示 RunManager 产出的 branch options，点击后交给 RunManager.select_branch。

var status_label: Label = null
var option_box: VBoxContainer = null


func _build() -> void:
	root_box.add_child(make_title("选择本轮分支"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	option_box = make_section_box("BranchOptions")
	root_box.add_child(option_box)


func refresh() -> void:
	if run_manager == null or option_box == null:
		return

	status_label.text = make_status_text()
	clear_children(option_box)
	var options: Array = run_manager.get_branch_display_data()
	var index: int = 0
	while index < options.size():
		var option: Dictionary = options[index]
		var text: String = "%s\n类型：%s\n%s" % [
			option.get("title", ""),
			option.get("branch_type_text", ""),
			option.get("description", ""),
		]
		option_box.add_child(make_button(text, Callable.create(app_controller, "select_branch_requested").bind(option.get("branch_id", ""))))
		index += 1
