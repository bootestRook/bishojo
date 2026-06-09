extends V1UIViewBase
class_name BagOverlay

# 文件职责：
# - 展示 Run 内所有秘宝少女实例，提供选择上阵、商店出售和详情入口。
# - 出售是否可用由当前 RunState 决定，实际出售仍交给 RunManager。

var list_box: VBoxContainer = null
var status_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("背包"))
	status_label = make_label("", 90)
	root_box.add_child(status_label)
	list_box = make_section_box("BagList")
	root_box.add_child(list_box)
	root_box.add_child(make_button("关闭背包", Callable.create(app_controller, "close_overlay_requested").bind("bag_overlay")))


func refresh() -> void:
	if run_manager == null or list_box == null:
		return

	status_label.text = make_status_text()
	clear_children(list_box)
	var items: Array = run_manager.get_inventory_display_data()
	var can_sell: bool = run_manager.current_state == RUN_TYPES.RunState.SHOP_NODE
	var index: int = 0
	while index < items.size():
		var item: Dictionary = items[index]
		var treasure: Dictionary = item.get("treasure", {})
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text: String = "%s  %s  %s\n来源：%s\n状态：%s  可上阵：%s  可出售：%s" % [
			treasure.get("treasure_name", ""),
			item.get("rarity_text", ""),
			treasure.get("size_text", ""),
			item.get("source_text", ""),
			"已上阵" if item.get("is_in_formation", false) else "背包中",
			"是",
			"是" if can_sell else "否",
		]
		row.add_child(make_button(text, Callable.create(app_controller, "select_inventory_instance_requested").bind(item.get("instance_id", ""))))
		var sell_button := make_button("出售", Callable.create(app_controller, "shop_sell_requested").bind(item.get("instance_id", "")))
		sell_button.disabled = not can_sell
		row.add_child(sell_button)
		row.add_child(make_button("详情", Callable.create(app_controller, "open_card_detail_requested").bind(item.get("treasure_id", ""), item.get("rarity", "green"))))
		list_box.add_child(row)
		index += 1
