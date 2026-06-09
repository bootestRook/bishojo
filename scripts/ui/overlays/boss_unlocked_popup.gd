extends V1UIViewBase
class_name BossUnlockedPopup

# 文件职责：
# - 最终首领解锁提示覆盖层。
# - 点击进入最终挑战只调用 RunManager.enter_boss_combat_requested。

var message_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("最终首领已解锁"))
	message_label = make_label("", 320)
	root_box.add_child(message_label)
	root_box.add_child(make_button("进入最终挑战", Callable.create(app_controller, "enter_boss_requested")))
	root_box.add_child(make_button("关闭提示", Callable.create(app_controller, "close_overlay_requested").bind("boss_unlocked_popup")))


func refresh() -> void:
	if run_manager == null or message_label == null:
		return

	var summary: Dictionary = run_manager.get_run_summary()
	message_label.text = "普通战胜利已达标：当前 %d 胜，目标 %d 胜\n进入最终首领战后，胜利会进入整局胜利，失败会进入整局失败。" % [
		summary.get("normal_win_count", 0),
		summary.get("normal_win_target", 0),
	]
