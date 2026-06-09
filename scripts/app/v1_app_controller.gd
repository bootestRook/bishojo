extends Control
class_name V1AppController

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")
const UI_MANAGER = preload("res://scripts/ui/v1_ui_manager.gd")

# 文件职责：
# - 作为 main scene 根控制器创建并持有 RunManager 与 UIManager。
# - 接收 UI 页面、面板、覆盖层发出的操作请求，再调用 RunManager 公开方法。
# - 不注册 Autoload，不直接写玩法规则，不复制构筑、战斗或整局流程判断。

var run_manager = null
var ui_manager = null
var selected_formation_instance_id: String = ""
var last_ui_message: String = ""
var _initialized: bool = false


func _ready() -> void:
	if _initialized:
		return

	_initialized = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	run_manager = RUN_MANAGER.new()
	run_manager.boot_to_main_menu()
	ui_manager = UI_MANAGER.new()
	ui_manager.setup(self, run_manager)


func refresh_ui() -> void:
	if ui_manager != null:
		ui_manager.refresh()


func start_new_run_requested() -> void:
	selected_formation_instance_id = ""
	last_ui_message = ""
	run_manager.start_new_run_requested()
	refresh_ui()


func select_default_character_requested() -> void:
	var character: Dictionary = run_manager.get_character_display_data()
	select_character_requested(character.get("character_id", ""))


func select_character_requested(character_id: String) -> void:
	var ok: bool = run_manager.select_character(character_id)
	if ok:
		run_manager.init_run_values()
	last_ui_message = "角色选择成功" if ok else "角色不存在"
	refresh_ui()


func select_starter_treasure_requested(treasure_id: String) -> void:
	var ok: bool = run_manager.select_starter_treasure(treasure_id)
	last_ui_message = "获得初始秘宝少女" if ok else "初始秘宝不可选"
	refresh_ui()


func select_branch_requested(branch_id: String) -> void:
	var ok: bool = run_manager.select_branch(branch_id)
	last_ui_message = "分支已选择" if ok else "分支不存在"
	refresh_ui()


func apply_node_choice_requested(option_id: String) -> void:
	var result: Dictionary = run_manager.apply_node_choice(option_id)
	last_ui_message = reason_to_text(result.get("reason", ""))
	if result.get("ok", false):
		run_synthesis_check_requested()
	else:
		refresh_ui()


func shop_buy_requested(shop_item_id: String) -> void:
	var result: Dictionary = run_manager.shop_buy_item(shop_item_id)
	last_ui_message = reason_to_text(result.get("reason", ""))
	refresh_ui()


func shop_refresh_requested() -> void:
	var result: Dictionary = run_manager.shop_refresh()
	last_ui_message = reason_to_text(result.get("reason", ""))
	refresh_ui()


func shop_toggle_lock_requested() -> void:
	var locked: bool = run_manager.shop_toggle_lock()
	last_ui_message = "商店已锁定" if locked else "商店已解锁"
	refresh_ui()


func shop_sell_requested(instance_id: String) -> void:
	var result: Dictionary = run_manager.shop_sell_instance(instance_id)
	if selected_formation_instance_id == instance_id:
		selected_formation_instance_id = ""
	last_ui_message = reason_to_text(result.get("reason", ""))
	refresh_ui()


func shop_leave_requested() -> void:
	run_manager.shop_leave_requested()
	run_synthesis_check_requested()


func run_synthesis_check_requested() -> void:
	var results: Array = run_manager.run_synthesis_check()
	last_ui_message = "合成检查完成：%d 条结果" % results.size()
	refresh_ui()
	if results.size() > 0 and ui_manager != null:
		ui_manager.show_overlay("synthesis_result_popup")


func select_inventory_instance_requested(instance_id: String) -> void:
	selected_formation_instance_id = instance_id
	last_ui_message = "已选择 %s" % _instance_label(instance_id)
	if ui_manager != null:
		ui_manager.hide_overlay("bag_overlay")
	refresh_ui()


func formation_slot_requested(slot_id: String, occupant_instance_id: String) -> void:
	if selected_formation_instance_id == "":
		if occupant_instance_id != "":
			selected_formation_instance_id = occupant_instance_id
			last_ui_message = "已选择上阵单位 %s" % _instance_label(occupant_instance_id)
		else:
			last_ui_message = "请先从背包选择单位"
		refresh_ui()
		return

	if occupant_instance_id == selected_formation_instance_id:
		var removed: bool = run_manager.formation_remove_instance(selected_formation_instance_id)
		last_ui_message = "已下阵" if removed else "下阵失败"
		selected_formation_instance_id = ""
		refresh_ui()
		return

	var selected_data: Dictionary = _find_inventory_display(selected_formation_instance_id)
	var result: Dictionary = {}
	if selected_data.get("is_in_formation", false):
		result = run_manager.formation_move_instance(selected_formation_instance_id, slot_id)
	else:
		result = run_manager.formation_place_instance(selected_formation_instance_id, slot_id)

	last_ui_message = reason_to_text(result.get("reason", ""))
	if not result.get("ok", false) and ui_manager != null:
		ui_manager.show_overlay("invalid_formation_popup")
	refresh_ui()


func formation_remove_selected_requested() -> void:
	if selected_formation_instance_id == "":
		last_ui_message = "未选择上阵单位"
		refresh_ui()
		return

	var removed: bool = run_manager.formation_remove_instance(selected_formation_instance_id)
	last_ui_message = "已下阵" if removed else "下阵失败"
	if removed:
		selected_formation_instance_id = ""
	refresh_ui()


func formation_auto_arrange_requested() -> void:
	run_manager.enter_formation_edit()
	var placed: int = 0
	var inventory: Array = run_manager.get_inventory_display_data()
	var formation: Dictionary = run_manager.get_formation_display_data()
	var slots: Array = formation.get("slots", [])
	var instance_index: int = 0
	while instance_index < inventory.size():
		var item: Dictionary = inventory[instance_index]
		if not item.get("is_in_formation", false):
			var slot_index: int = 0
			while slot_index < slots.size():
				var slot: Dictionary = slots[slot_index]
				var result: Dictionary = run_manager.formation_place_instance(item.get("instance_id", ""), slot.get("slot_id", ""))
				if result.get("ok", false):
					placed += 1
					formation = run_manager.get_formation_display_data()
					slots = formation.get("slots", [])
					break
				slot_index += 1
		instance_index += 1

	last_ui_message = "调试自动上阵完成：%d 个单位" % placed
	refresh_ui()


func confirm_formation_requested() -> void:
	var result: Dictionary = run_manager.confirm_formation()
	last_ui_message = reason_to_text(result.get("reason", ""))
	if result.get("ok", false):
		run_manager.generate_combat_branch_options()
	else:
		if ui_manager != null:
			ui_manager.show_overlay("invalid_formation_popup")
	refresh_ui()


func select_combat_branch_requested(combat_branch_id: String) -> void:
	var ok: bool = run_manager.select_combat_branch(combat_branch_id)
	last_ui_message = "战斗分支已选择" if ok else "战斗分支不存在"
	refresh_ui()


func enter_boss_requested() -> void:
	var result: Dictionary = run_manager.enter_boss_combat_requested()
	last_ui_message = reason_to_text(result.get("reason", ""))
	refresh_ui()


func start_current_combat_requested() -> void:
	var result: Dictionary = run_manager.start_current_combat()
	last_ui_message = reason_to_text(result.get("reason", ""))
	if result.get("ok", false):
		run_manager.resolve_combat_result()
	refresh_ui()


func confirm_combat_result_requested() -> void:
	var result: Dictionary = run_manager.confirm_combat_result()
	last_ui_message = reason_to_text(result.get("reason", ""))
	if result.get("ok", false) and run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT:
		run_manager.generate_branch_options()
	refresh_ui()


func restart_run_requested() -> void:
	start_new_run_requested()


func return_to_main_menu_requested() -> void:
	selected_formation_instance_id = ""
	run_manager.reset_run_data()
	run_manager.boot_to_main_menu()
	refresh_ui()


func open_bag_requested() -> void:
	if ui_manager != null:
		ui_manager.show_overlay("bag_overlay")


func open_card_detail_requested(treasure_id: String, rarity: String = "green") -> void:
	if ui_manager != null:
		ui_manager.set_card_detail(treasure_id, rarity)
		ui_manager.show_overlay("card_detail_overlay")


func open_boss_unlocked_popup_requested() -> void:
	if ui_manager != null:
		ui_manager.show_overlay("boss_unlocked_popup")


func close_overlay_requested(overlay_id: String) -> void:
	if ui_manager != null:
		ui_manager.hide_overlay(overlay_id)


func quit_requested() -> void:
	get_tree().quit(0)


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


func _find_inventory_display(instance_id: String) -> Dictionary:
	var inventory: Array = run_manager.get_inventory_display_data()
	var index: int = 0
	while index < inventory.size():
		if inventory[index].get("instance_id", "") == instance_id:
			return inventory[index]
		index += 1
	return {}


func _instance_label(instance_id: String) -> String:
	var data: Dictionary = _find_inventory_display(instance_id)
	return data.get("display_name", "秘宝少女")
