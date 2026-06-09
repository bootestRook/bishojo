extends V1UIViewBase
class_name ShopPanel

# 文件职责：
# - RunBoardPage 内部商店面板。
# - 购买、刷新、锁定、出售和离开都通过 V1AppController 转发到 RunManager。

var status_label: Label = null
var result_label: Label = null
var item_box: VBoxContainer = null


func _build() -> void:
	root_box.add_child(make_title("商店"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	result_label = make_label("", 70)
	root_box.add_child(result_label)
	item_box = make_section_box("ShopItems")
	root_box.add_child(item_box)
	var controls := HBoxContainer.new()
	controls.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(make_button("刷新", Callable.create(app_controller, "shop_refresh_requested")))
	controls.add_child(make_button("锁定 / 解锁", Callable.create(app_controller, "shop_toggle_lock_requested")))
	controls.add_child(make_button("背包 / 出售", Callable.create(app_controller, "open_bag_requested")))
	controls.add_child(make_button("离开商店", Callable.create(app_controller, "shop_leave_requested")))
	root_box.add_child(controls)


func refresh() -> void:
	if run_manager == null or item_box == null:
		return

	var data: Dictionary = run_manager.get_shop_display_data()
	status_label.text = "金币：%d  刷新费用：%d  锁定：%s" % [
		data.get("gold", 0),
		data.get("refresh_cost", 0),
		"是" if data.get("is_locked", false) else "否",
	]
	result_label.text = "反馈：%s" % app_controller.last_ui_message
	clear_children(item_box)
	var items: Array = data.get("items", [])
	var index: int = 0
	while index < items.size():
		var item: Dictionary = items[index]
		var treasure: Dictionary = item.get("treasure", {})
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var item_text: String = "%s  %s  %s  价格 %d\n冷却 %.1f 秒  %s\n状态：%s" % [
			treasure.get("treasure_name", ""),
			treasure.get("rarity_text", ""),
			treasure.get("size_text", ""),
			item.get("price", 0),
			treasure.get("base_cooldown_sec", 0.0),
			treasure.get("effect_brief", ""),
			"已售" if item.get("is_sold", false) else "可购买",
		]
		var buy_button := make_button(item_text, Callable.create(app_controller, "shop_buy_requested").bind(item.get("shop_item_id", "")))
		buy_button.disabled = item.get("is_sold", false)
		row.add_child(buy_button)
		row.add_child(make_button("详情", Callable.create(app_controller, "open_card_detail_requested").bind(item.get("treasure_id", ""), item.get("rarity", "green"))))
		item_box.add_child(row)
		index += 1
