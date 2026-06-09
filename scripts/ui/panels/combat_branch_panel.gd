extends V1UIViewBase
class_name CombatBranchPanel

# 文件职责：
# - RunBoardPage 内部战斗分支选择面板。
# - Boss 解锁前展示普通战分支，Boss 解锁后由 BossIntro 面板接管。

var status_label: Label = null
var option_box: VBoxContainer = null


func _build() -> void:
	root_box.add_child(make_title("选择战斗"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	option_box = make_section_box("CombatBranchOptions")
	root_box.add_child(option_box)


func refresh() -> void:
	if run_manager == null or option_box == null:
		return

	status_label.text = make_status_text()
	clear_children(option_box)
	var options: Array = run_manager.get_combat_branch_display_data()
	var index: int = 0
	while index < options.size():
		var option: Dictionary = options[index]
		var text: String = "%s\n敌人：%s\n类型：%s  奖励：%s\n当前胜利：%d" % [
			option.get("title", ""),
			option.get("enemy_name", ""),
			option.get("battle_type_text", ""),
			option.get("reward_profile_text", ""),
			run_manager.normal_win_count,
		]
		option_box.add_child(make_button(text, Callable.create(app_controller, "select_combat_branch_requested").bind(option.get("combat_branch_id", ""))))
		index += 1
