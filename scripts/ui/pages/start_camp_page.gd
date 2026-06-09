extends V1UIViewBase
class_name StartCampPage

# 文件职责：
# - 展示初始营地 3 选 1 秘宝少女。
# - 点击秘宝后只调用 RunManager.select_starter_treasure，不在 UI 中发放奖励。

var status_label: Label = null
var option_box: VBoxContainer = null


func _build() -> void:
	root_box.add_child(make_title("初始营地"))
	status_label = make_label("", 110)
	root_box.add_child(status_label)
	option_box = make_section_box("StarterOptions")
	root_box.add_child(option_box)


func refresh() -> void:
	if run_manager == null or option_box == null:
		return

	status_label.text = make_status_text()
	clear_children(option_box)
	var options: Array = run_manager.get_starter_treasure_display_data()
	var index: int = 0
	while index < options.size():
		var card: Dictionary = options[index]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var button_text: String = "%s  %s  %s\n占格 %d×%d  冷却 %.1f 秒\n%s" % [
			card.get("treasure_name", ""),
			card.get("rarity_text", ""),
			card.get("size_text", ""),
			card.get("footprint_width", 1),
			card.get("footprint_height", 1),
			card.get("base_cooldown_sec", 0.0),
			card.get("effect_brief", ""),
		]
		row.add_child(make_button(button_text, Callable.create(app_controller, "select_starter_treasure_requested").bind(card.get("treasure_id", ""))))
		row.add_child(make_button("详情", Callable.create(app_controller, "open_card_detail_requested").bind(card.get("treasure_id", ""), card.get("rarity", "green"))))
		option_box.add_child(row)
		index += 1
