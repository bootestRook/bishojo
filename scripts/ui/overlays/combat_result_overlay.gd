extends V1UIViewBase
class_name CombatResultOverlay

# 文件职责：
# - 展示自动战斗结算摘要、奖励、下一状态和关键时间轴日志。
# - 确认后调用 RunManager.confirm_combat_result，页面本身不决定去向。

var result_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("战斗结算"))
	result_label = make_label("", 720)
	root_box.add_child(result_label)
	root_box.add_child(make_button("确认结算", Callable.create(app_controller, "confirm_combat_result_requested")))


func refresh() -> void:
	if run_manager == null or result_label == null:
		return

	var summary: Dictionary = run_manager.get_run_summary()
	var battle: Dictionary = run_manager.get_last_battle_summary()
	var rewards: Array = run_manager.get_last_reward_results()
	var logs: Array = run_manager.get_last_timeline_log(20)
	result_label.text = "结果：%s\n战斗类型：%s\n敌人：%s\n普通战胜利：%d 胜，目标 %d 胜\n耐久：%d 点，上限 %d 点\n金币：%d\n下一阶段：%s\n奖励：%s\n\n最近日志：\n%s" % [
		battle_result_to_text(battle.get("combat_result", "")),
		battle_type_to_text(battle.get("battle_type", "")),
		format_enemy_names(battle.get("enemy_ids", [])),
		summary.get("normal_win_count", 0),
		summary.get("normal_win_target", 0),
		summary.get("run_durability", 0),
		summary.get("run_durability_max", 0),
		summary.get("gold", 0),
		run_state_to_text(summary.get("next_state", -1)),
		format_reward_results(rewards),
		_format_logs(logs),
	]


func _format_logs(logs: Array) -> String:
	var text: String = ""
	var index: int = 0
	while index < logs.size():
		var log: Dictionary = logs[index]
		text += "%s\n" % format_log_entry(log)
		index += 1
	return text
