extends Control
class_name V1UIViewBase

# 文件职责：
# - 为 V1 UI 页面、面板和覆盖层提供最小共享构建工具。
# - 只封装 Godot 控件创建、全屏布局、子节点清理和通用文案，不接触玩法规则。
# - 具体流程事件仍由页面发给 V1AppController，再由 RunManager 判定是否合法。

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const V1_I18N = preload("res://scripts/ui/v1_i18n.gd")

var app_controller = null
var run_manager = null
var i18n = V1_I18N.new()
var root_box: VBoxContainer = null
var _built: bool = false


func setup(new_app_controller, new_run_manager) -> void:
	app_controller = new_app_controller
	run_manager = new_run_manager
	_ensure_layout()
	refresh()


func refresh() -> void:
	pass


func _ready() -> void:
	_ensure_layout()


func _ensure_layout() -> void:
	if _built:
		return

	_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.08, 0.09, 0.11, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	root_box = VBoxContainer.new()
	root_box.name = "RootBox"
	root_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root_box)

	_build()


func _build() -> void:
	pass


func clear_children(node: Node) -> void:
	var children: Array = node.get_children()
	var index: int = 0
	while index < children.size():
		children[index].queue_free()
		index += 1


func make_label(text: String, min_height: int = 0) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if min_height > 0:
		label.custom_minimum_size = Vector2(0, min_height)
	return label


func make_title(text: String) -> Label:
	var label := make_label(text, 96)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label


func make_button(text: String, callable: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callable)
	return button


func make_section_box(name_text: String = "") -> VBoxContainer:
	var box := VBoxContainer.new()
	box.name = name_text
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return box


func make_scroll_box() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)
	root_box.add_child(scroll)
	return box


func make_status_text() -> String:
	if run_manager == null:
		return "局内流程尚未准备"

	var summary: Dictionary = run_manager.get_run_summary()
	return "金币 %d  耐久 %d 点（上限 %d）  普通战 %d 胜（目标 %d）\n当前阶段：%s  当前界面：%s  背包 %d  上阵 %d" % [
		summary.get("gold", 0),
		summary.get("run_durability", 0),
		summary.get("run_durability_max", 0),
		summary.get("normal_win_count", 0),
		summary.get("normal_win_target", 0),
		run_state_to_text(summary.get("state", -1)),
		board_mode_to_text(summary.get("run_board_mode", RUN_TYPES.RunBoardMode.NONE)),
		summary.get("inventory_count", 0),
		summary.get("formation_count", 0),
	]


func reason_to_text(reason: String) -> String:
	match reason:
		"ok":
			return "成功"
		"not_enough_gold":
			return "金币不足"
		"item_not_found":
			return "商品不存在"
		"item_sold":
			return "商品已售"
		"instance_not_found":
			return "实例不存在"
		"slot_not_found":
			return "槽位不存在"
		"slot_locked":
			return "目标槽位未解锁"
		"slot_occupied":
			return "目标槽位已被占用"
		"out_of_bounds":
			return "占格越界"
		"cross_row_not_allowed":
			return "中型 / 大型不可跨行"
		"invalid_size_type":
			return "体型配置不存在"
		"no_units_placed":
			return "至少需要上阵 1 个秘宝少女"
		"next_state_unset":
			return "结算下一状态未设置"
		_:
			return reason


func run_state_to_text(state: int) -> String:
	match state:
		RUN_TYPES.RunState.BOOT:
			return "启动中"
		RUN_TYPES.RunState.MAIN_MENU:
			return "主菜单"
		RUN_TYPES.RunState.START_NEW_RUN:
			return "新局准备"
		RUN_TYPES.RunState.CHARACTER_SELECT:
			return "角色选择"
		RUN_TYPES.RunState.RUN_INIT:
			return "局内初始化"
		RUN_TYPES.RunState.START_CAMP, RUN_TYPES.RunState.STARTER_TREASURE_SELECT:
			return "初始营地"
		RUN_TYPES.RunState.BRANCH_SELECT:
			return "分支选择"
		RUN_TYPES.RunState.BRANCH_RESOLVE:
			return "分支处理"
		RUN_TYPES.RunState.SHOP_NODE:
			return "商店"
		RUN_TYPES.RunState.SUPPLY_NODE:
			return "补给"
		RUN_TYPES.RunState.GOLD_NODE:
			return "金币节点"
		RUN_TYPES.RunState.SYNTHESIS_CHECK:
			return "合成检查"
		RUN_TYPES.RunState.FORMATION_EDIT:
			return "回路编辑"
		RUN_TYPES.RunState.COMBAT_BRANCH_SELECT:
			return "战斗选择"
		RUN_TYPES.RunState.COMBAT, RUN_TYPES.RunState.BOSS_COMBAT:
			return "自动战斗"
		RUN_TYPES.RunState.COMBAT_RESULT:
			return "战斗结算"
		RUN_TYPES.RunState.BOSS_INTRO:
			return "最终挑战"
		RUN_TYPES.RunState.RUN_VICTORY:
			return "整局胜利"
		RUN_TYPES.RunState.RUN_DEFEAT:
			return "整局失败"
		_:
			return "未知阶段"


func board_mode_to_text(mode: int) -> String:
	match mode:
		RUN_TYPES.RunBoardMode.NONE:
			return "无"
		RUN_TYPES.RunBoardMode.BRANCH_SELECT:
			return "分支选择"
		RUN_TYPES.RunBoardMode.SHOP:
			return "商店"
		RUN_TYPES.RunBoardMode.GENERIC_NODE_CHOICE:
			return "节点选择"
		RUN_TYPES.RunBoardMode.SYNTHESIS_ANIMATION:
			return "合成反馈"
		RUN_TYPES.RunBoardMode.FORMATION_EDIT:
			return "回路编辑"
		RUN_TYPES.RunBoardMode.COMBAT_BRANCH_SELECT:
			return "战斗选择"
		RUN_TYPES.RunBoardMode.COMBAT:
			return "自动战斗"
		RUN_TYPES.RunBoardMode.COMBAT_RESULT:
			return "战斗结算"
		RUN_TYPES.RunBoardMode.REWARD_SELECT:
			return "奖励选择"
		RUN_TYPES.RunBoardMode.BOSS_INTRO:
			return "最终挑战"
		_:
			return "未知界面"


func branch_type_to_text(branch_type: String) -> String:
	match branch_type:
		"shop":
			return "商店"
		"supply":
			return "补给"
		"gold":
			return "金币"
		_:
			return "事件"


func battle_result_to_text(result: String) -> String:
	match result:
		"win":
			return "胜利"
		"lose":
			return "失败"
		"timeout":
			return "超时"
		_:
			return "尚未结算"


func battle_type_to_text(battle_type: String) -> String:
	match battle_type:
		"normal_safe":
			return "稳妥战"
		"normal_standard":
			return "普通战"
		"normal_high_reward":
			return "高奖励战"
		"boss":
			return "最终首领"
		_:
			return "未选择"


func slot_to_text(slot: Dictionary) -> String:
	var row: int = slot.get("row", 0)
	var column: int = slot.get("column", 0)
	var row_text: String = "前排" if row == 0 else "后排"
	return "%s第%s格" % [row_text, number_to_cn(column + 1)]


func number_to_cn(value: int) -> String:
	match value:
		1:
			return "一"
		2:
			return "二"
		3:
			return "三"
		4:
			return "四"
		5:
			return "五"
		6:
			return "六"
		7:
			return "七"
		8:
			return "八"
		9:
			return "九"
		10:
			return "十"
		_:
			return "%d" % value


func format_instance(item: Dictionary) -> String:
	return item.get("display_name", "秘宝少女")


func format_enemy_names(enemy_ids: Array) -> String:
	if run_manager == null:
		return "未知敌人"
	var text: String = ""
	var index: int = 0
	while index < enemy_ids.size():
		var enemy = run_manager.enemy_catalog.get_enemy_data(enemy_ids[index])
		if text != "":
			text += "，"
		text += enemy.enemy_name if enemy != null else "未知敌人"
		index += 1
	return text


func format_reward_results(results: Array) -> String:
	if results.is_empty():
		return "无奖励"
	var text: String = ""
	var index: int = 0
	while index < results.size():
		var result: Dictionary = results[index]
		var gold_delta: int = result.get("gold_after", 0) - result.get("gold_before", 0)
		if gold_delta != 0:
			if text != "":
				text += "，"
			text += "金币 +%d" % gold_delta
		index += 1
	return "无奖励" if text == "" else text


func format_log_entry(log: Dictionary) -> String:
	var time_sec: float = log.get("time_ms", 0) / 1000.0
	return "%.1f秒：%s" % [time_sec, event_type_to_text(log.get("event_type", ""))]


func event_type_to_text(event_type: String) -> String:
	match event_type:
		"BATTLE_START":
			return "战斗开始"
		"COOLDOWN_INIT":
			return "秘宝冷却初始化"
		"COOLDOWN_UPDATE":
			return "冷却推进"
		"COOLDOWN_RESET":
			return "技能冷却重置"
		"PLAYER_TRIGGER_SKILL":
			return "秘宝少女发动技能"
		"APPLY_CHARGE":
			return "触发充能"
		"APPLY_DAMAGE":
			return "造成伤害"
		"APPLY_SHIELD":
			return "获得护盾"
		"ENEMY_ACTION":
			return "敌人行动"
		"BATTLE_FINISH":
			return "战斗结束"
		_:
			return "战斗事件"
