extends V1UIViewBase
class_name CardDetailOverlay

# 文件职责：
# - 展示秘宝少女完整可读信息。
# - 数据来源为 RunManager.get_card_detail_display_data，不绑定具体背包实例节点。

var treasure_id: String = ""
var rarity: String = "green"
var detail_label: Label = null


func _build() -> void:
	root_box.add_child(make_title("秘宝详情"))
	detail_label = make_label("", 620)
	root_box.add_child(detail_label)
	root_box.add_child(make_button("关闭详情", Callable.create(app_controller, "close_overlay_requested").bind("card_detail_overlay")))


func set_card(new_treasure_id: String, new_rarity: String = "green") -> void:
	treasure_id = new_treasure_id
	rarity = new_rarity
	refresh()


func refresh() -> void:
	if run_manager == null or detail_label == null:
		return

	var data: Dictionary = run_manager.get_card_detail_display_data(treasure_id, rarity)
	detail_label.text = "名称：%s\n稀有度：%s\n体型：%s\n占格：%d×%d\n冷却：%.1f 秒\n价格：%d\n定位：%s\n技能：%s\n描述：%s" % [
		data.get("treasure_name", ""),
		data.get("rarity_text", ""),
		data.get("size_text", ""),
		data.get("footprint_width", 1),
		data.get("footprint_height", 1),
		data.get("base_cooldown_sec", 0.0),
		data.get("price", 0),
		_format_tags(data.get("tags", [])),
		data.get("effect_brief", ""),
		data.get("description", ""),
	]


func _format_tags(tags: Array) -> String:
	var text: String = ""
	var index: int = 0
	while index < tags.size():
		if text != "":
			text += "，"
		text += _tag_to_text(tags[index])
		index += 1
	return "普通" if text == "" else text


func _tag_to_text(tag: String) -> String:
	match tag:
		"damage":
			return "输出"
		"charge":
			return "充能"
		"starter":
			return "初始"
		"shield", "defense":
			return "防御"
		"crit":
			return "暴击"
		"burst":
			return "爆发"
		"haste":
			return "加速"
		"position":
			return "站位"
		"buff":
			return "强化"
		"economy":
			return "经济"
		_:
			return "普通"
