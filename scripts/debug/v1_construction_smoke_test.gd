extends SceneTree

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")
const POSITION_RELATION_RESOLVER = preload("res://scripts/systems/formation/position_relation_resolver.gd")

# 文件职责：
# - 验证 V1 构筑系统纯逻辑骨架能完成核心流程串联。
# - 该脚本只直接调用 RunManager 和纯数据模型，不创建 UI 场景，不依赖 Autoload，不接入战斗系统。

var fail_count: int = 0


func _init() -> void:
	_run_smoke()
	if fail_count > 0:
		print("[SMOKE] failed")
		quit(1)
	else:
		print("[SMOKE] passed")
		quit(0)


func _run_smoke() -> void:
	var run_manager = RUN_MANAGER.new()

	_check(run_manager.current_state == RUN_TYPES.RunState.BOOT, "初始状态为 BOOT")
	run_manager.start_new_run_requested()
	_check(run_manager.current_state == RUN_TYPES.RunState.CHARACTER_SELECT, "开局请求进入角色选择")
	_check(run_manager.get_state_history().has(RUN_TYPES.RunState.START_NEW_RUN), "状态历史记录 START_NEW_RUN")

	_check(run_manager.select_character(run_manager.character_data.character_id), "V1 唯一角色可被选择")
	_check(run_manager.current_state == RUN_TYPES.RunState.RUN_INIT, "选择角色后进入 RUN_INIT")
	run_manager.init_run_values()
	_check(run_manager.current_state == RUN_TYPES.RunState.START_CAMP, "初始化 Run 后进入 START_CAMP")
	_check(run_manager.gold == run_manager.initial_run_config.initial_gold, "初始金币写入 RunManager")
	_check(run_manager.run_durability == run_manager.initial_run_config.run_durability, "初始耐久写入 RunManager")

	var starter_options: Array = run_manager.get_starter_treasure_options()
	_check(run_manager.current_state == RUN_TYPES.RunState.STARTER_TREASURE_SELECT, "请求初始秘宝后进入 STARTER_TREASURE_SELECT")
	_check(starter_options.size() == 3, "初始营地返回 3 个候选秘宝")
	_check(_catalog_has_all(run_manager, starter_options), "初始候选秘宝都存在于目录")
	_check(run_manager.select_starter_treasure("flame_blade"), "选择初始秘宝 flame_blade")
	_check(run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT, "选择初始秘宝后进入 BRANCH_SELECT")
	_check(run_manager.inventory_model.count_by_treasure_and_rarity("flame_blade", "green") == 1, "初始秘宝进入背包实例集合")

	var branch_options: Array = run_manager.generate_branch_options()
	_check(branch_options.size() == 3, "分支生成 3 个候选")
	_check(run_manager.select_branch("branch_shop"), "可选择商店分支")
	_check(run_manager.current_state == RUN_TYPES.RunState.SHOP_NODE, "商店分支进入 SHOP_NODE")
	_check(run_manager.current_shop_stock.size() == 5, "商店生成 5 个库存项")

	run_manager.gold = 20
	var first_shop_item = run_manager.current_shop_stock[0]
	var buy_result: Dictionary = run_manager.shop_buy_item(first_shop_item.shop_item_id)
	_check(buy_result.get("ok", false), "商店可购买秘宝")
	_check(run_manager.inventory_model.get_instance(buy_result.get("instance_id", "")) != null, "购买结果写入背包实例")
	_check(run_manager.shop_toggle_lock(), "商店锁定开关可打开")
	var refresh_result: Dictionary = run_manager.shop_refresh()
	_check(refresh_result.get("ok", false), "商店可刷新库存")
	_check(run_manager.current_shop_stock.size() == 5, "刷新后仍保持 5 个库存项")
	var sell_result: Dictionary = run_manager.shop_sell_instance(buy_result.get("instance_id", ""))
	_check(sell_result.get("ok", false), "商店可出售背包实例")
	run_manager.shop_leave_requested()
	_check(run_manager.current_state == RUN_TYPES.RunState.SYNTHESIS_CHECK, "离开商店进入 SYNTHESIS_CHECK")

	run_manager.generate_branch_options()
	_check(run_manager.select_branch("branch_gold"), "可选择金币分支")
	_check(run_manager.current_state == RUN_TYPES.RunState.GOLD_NODE, "金币分支进入 GOLD_NODE")
	var gold_before: int = run_manager.gold
	var gold_choices: Array = run_manager.get_current_node_choices()
	_check(gold_choices.size() == 3, "金币节点生成 3 个候选")
	var node_result: Dictionary = run_manager.apply_node_choice("gold_4")
	_check(node_result.get("ok", false), "金币节点选择可应用")
	_check(run_manager.gold == gold_before + 4, "金币节点修改 Run 金币")
	_check(run_manager.current_state == RUN_TYPES.RunState.SYNTHESIS_CHECK, "节点选择后进入 SYNTHESIS_CHECK")

	run_manager.generate_branch_options()
	_check(run_manager.select_branch("branch_supply"), "可选择补给分支")
	_check(run_manager.current_state == RUN_TYPES.RunState.SUPPLY_NODE, "补给分支进入 SUPPLY_NODE")
	var supply_choices: Array = run_manager.get_current_node_choices()
	_check(supply_choices.size() == 3, "补给节点生成 3 个候选")

	run_manager.run_synthesis_check()
	_check(run_manager.current_state == RUN_TYPES.RunState.FORMATION_EDIT, "合成检查后进入 FORMATION_EDIT")
	_check(run_manager.formation_model.get_all_slots().size() == 10, "回路为 2x5 共 10 格")
	_check(run_manager.formation_model.get_unlocked_slots().size() == 3, "0 胜默认解锁 3 格")

	var starter_instance = _find_instance(run_manager, "flame_blade", "green")
	var place_result: Dictionary = run_manager.formation_place_instance(starter_instance.instance_id, "r0_c0")
	_check(place_result.get("ok", false), "初始秘宝可放入已解锁槽位")
	run_manager.confirm_formation()
	_check(run_manager.current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT, "确认有效回路后进入 COMBAT_BRANCH_SELECT")

	run_manager.inventory_model.add_treasure("moon_dagger", "green", "debug")
	run_manager.inventory_model.add_treasure("moon_dagger", "green", "debug")
	var synthesis_logs: Array = run_manager.run_synthesis_check()
	_check(synthesis_logs.size() == 1, "两件同名同稀有度秘宝触发一次合成")
	_check(run_manager.inventory_model.count_by_treasure_and_rarity("moon_dagger", "blue") == 1, "绿色 2 合 1 升为蓝色")

	run_manager.inventory_model.add_treasure("ice_mirror", "yellow", "debug")
	run_manager.inventory_model.add_treasure("ice_mirror", "yellow", "debug")
	var yellow_logs: Array = run_manager.run_synthesis_check()
	_check(yellow_logs.is_empty(), "黄色稀有度不再继续合成")
	_check(run_manager.inventory_model.count_by_treasure_and_rarity("ice_mirror", "yellow") == 2, "黄色同名秘宝保持两件")

	_check_footprints_and_placement(run_manager)
	_check_position_relations(run_manager)


func _check_footprints_and_placement(run_manager) -> void:
	run_manager.normal_win_count = 10
	run_manager.enter_formation_edit()
	run_manager.formation_model.clear_all()

	var medium_instance = run_manager.inventory_model.add_treasure("star_lance", "green", "debug")
	var medium_result: Dictionary = run_manager.formation_place_instance(medium_instance.instance_id, "r0_c0")
	_check(medium_result.get("ok", false), "中型秘宝可横向占 2 格")
	_check(run_manager.formation_model.get_slots_occupied_by(medium_instance.instance_id).size() == 2, "中型秘宝实际占用 2 格")

	run_manager.formation_model.clear_all()
	var large_instance = run_manager.inventory_model.add_treasure("solar_cannon", "green", "debug")
	var large_result: Dictionary = run_manager.formation_place_instance(large_instance.instance_id, "r0_c0")
	_check(large_result.get("ok", false), "大型秘宝可横向占 3 格")
	_check(run_manager.formation_model.get_slots_occupied_by(large_instance.instance_id).size() == 3, "大型秘宝实际占用 3 格")

	run_manager.formation_model.clear_all()
	run_manager.normal_win_count = 0
	run_manager.enter_formation_edit()
	var locked_instance = run_manager.inventory_model.add_treasure("flame_blade", "green", "debug")
	var locked_result: Dictionary = run_manager.formation_place_instance(locked_instance.instance_id, "r0_c4")
	_check(not locked_result.get("ok", true), "未解锁槽位不可放置")
	_check(locked_result.get("reason", "") == "slot_locked", "锁格失败原因正确")

	run_manager.formation_model.clear_all()
	run_manager.normal_win_count = 10
	run_manager.enter_formation_edit()
	var first_instance = run_manager.inventory_model.add_treasure("flame_blade", "green", "debug")
	var second_instance = run_manager.inventory_model.add_treasure("thunder_bell", "green", "debug")
	_check(run_manager.formation_place_instance(first_instance.instance_id, "r0_c0").get("ok", false), "重叠测试第一件可放置")
	var overlap_result: Dictionary = run_manager.formation_place_instance(second_instance.instance_id, "r0_c0")
	_check(not overlap_result.get("ok", true), "已有占用槽位不可重叠放置")
	_check(overlap_result.get("reason", "") == "slot_occupied", "重叠失败原因正确")


func _check_position_relations(run_manager) -> void:
	run_manager.normal_win_count = 10
	run_manager.enter_formation_edit()
	run_manager.formation_model.clear_all()
	var resolver = POSITION_RELATION_RESOLVER.new()

	var instance_a = run_manager.inventory_model.add_treasure("flame_blade", "green", "debug")
	var instance_b = run_manager.inventory_model.add_treasure("thunder_bell", "green", "debug")
	var instance_c = run_manager.inventory_model.add_treasure("ice_mirror", "green", "debug")
	var instance_d = run_manager.inventory_model.add_treasure("golden_purse", "green", "debug")

	run_manager.formation_place_instance(instance_a.instance_id, "r0_c1")
	run_manager.formation_place_instance(instance_b.instance_id, "r0_c2")
	run_manager.formation_place_instance(instance_c.instance_id, "r1_c1")
	run_manager.formation_place_instance(instance_d.instance_id, "r0_c0")

	var adjacent: Array = resolver.find_adjacent_instances(run_manager.formation_model, instance_a.instance_id)
	_check(adjacent.has(instance_b.instance_id), "相邻关系包含右侧单位")
	_check(adjacent.has(instance_d.instance_id), "相邻关系包含左侧单位")

	var same_row: Array = resolver.find_same_row_instances(run_manager.formation_model, instance_a.instance_id)
	_check(same_row.has(instance_b.instance_id), "同排关系包含右侧单位")
	_check(same_row.has(instance_d.instance_id), "同排关系包含左侧单位")

	var same_col: Array = resolver.find_same_col_instances(run_manager.formation_model, instance_a.instance_id)
	_check(same_col.has(instance_c.instance_id), "同列关系包含前后单位")

	var overlap: Array = resolver.find_front_back_overlap_instances(run_manager.formation_model, instance_a.instance_id)
	_check(overlap.has(instance_c.instance_id), "前后对应关系包含同列异排单位")
	_check(resolver.is_on_edge(run_manager.formation_model, instance_d.instance_id), "边缘关系可识别")
	_check(resolver.is_on_corner(run_manager.formation_model, instance_d.instance_id), "角落关系可识别")
	_check(resolver.includes_center_column(run_manager.formation_model, instance_b.instance_id), "中列关系可识别")


func _catalog_has_all(run_manager, treasure_ids: Array) -> bool:
	var index: int = 0
	while index < treasure_ids.size():
		if not run_manager.treasure_catalog.has_treasure_id(treasure_ids[index]):
			return false
		index += 1

	return true


func _find_instance(run_manager, treasure_id: String, rarity: String):
	var instances: Array = run_manager.inventory_model.get_all_instances()
	var index: int = 0
	while index < instances.size():
		if instances[index].treasure_id == treasure_id and instances[index].rarity == rarity:
			return instances[index]
		index += 1

	return null


func _check(ok: bool, label: String) -> void:
	if ok:
		print("[PASS] ", label)
	else:
		fail_count += 1
		print("[FAIL] ", label)
