extends V1UIViewBase
class_name MainMenuPage

# 文件职责：
# - V1 局外入口页面。
# - 只提供开始新局、退出和基础调试说明入口，不创建 Run 数据。

var message_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("大巴扎类 V1 原型"))
	root_box.add_child(make_label("手机竖屏最小界面可玩原型\n主菜单、角色选择、初始营地、局内循环、最终首领、结算", 150))
	root_box.add_child(make_button("开始新局", Callable.create(app_controller, "start_new_run_requested")))
	root_box.add_child(make_button("退出", Callable.create(app_controller, "quit_requested")))
	message_label = make_label("", 80)
	root_box.add_child(message_label)


func refresh() -> void:
	if message_label != null and app_controller != null:
		message_label.text = app_controller.last_ui_message
