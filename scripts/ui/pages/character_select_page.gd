extends V1UIViewBase
class_name CharacterSelectPage

# 文件职责：
# - 展示 V1 默认角色数据。
# - V1 暂不启用角色能力，页面只负责让玩家确认进入初始营地。

var info_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("角色选择"))
	info_label = make_label("", 320)
	root_box.add_child(info_label)
	root_box.add_child(make_button("开始冒险", Callable.create(app_controller, "select_default_character_requested")))


func refresh() -> void:
	if run_manager == null or info_label == null:
		return

	var data: Dictionary = run_manager.get_character_display_data()
	info_label.text = "默认角色：%s\n描述：%s\n角色能力：V1 暂未启用" % [
		data.get("character_name", ""),
		data.get("character_description", ""),
	]
