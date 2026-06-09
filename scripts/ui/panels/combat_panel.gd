extends V1UIViewBase
class_name CombatPanel

# 文件职责：
# - RunBoardPage 内部自动战斗展示面板。
# - V1 不做逐帧动画，点击后瞬时运行底层 BattleManager 并展示结果摘要。

var status_label: Label = null
var battle_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("自动战斗"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	battle_label = make_label("", 360)
	root_box.add_child(battle_label)
	root_box.add_child(make_button("开始 / 运行战斗", Callable.create(app_controller, "start_current_combat_requested")))


func refresh() -> void:
	if run_manager == null or battle_label == null:
		return

	status_label.text = make_status_text()
	var summary: Dictionary = run_manager.get_run_summary()
	var battle: Dictionary = run_manager.get_last_battle_summary()
	battle_label.text = "当前战斗：%s\n当前结果：%s\n敌人：%s\n玩家核心生命：%s\n战斗耗时：%.1f 秒\n日志条数：%d" % [
		battle_type_to_text(summary.get("current_battle_type", "")),
		battle_result_to_text(battle.get("combat_result", "")),
		format_enemy_names(battle.get("enemy_ids", [])),
		battle.get("player_core_hp_after", "-"),
		battle.get("time_ms", 0) / 1000.0,
		battle.get("timeline_count", 0),
	]
