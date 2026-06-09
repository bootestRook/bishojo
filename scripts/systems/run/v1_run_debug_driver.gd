extends RefCounted
class_name V1RunDebugDriver

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")

# 文件职责：
# - 在无 UI、无 Autoload、无场景节点的前提下，驱动一局 V1 纯逻辑 Run。
# - 该类只供 smoke test 和调试脚本使用；正式流程仍由 UI 事件调用 RunManager 公开方法。
# - `force_` 方法允许构造失败分支，调用点必须清楚它们不是玩家正常流程。

var run_manager = RUN_MANAGER.new()
var round_records: Array = []
var battle_result_sequence: Array = []
var force_low_power: bool = false
var force_boss_loss: bool = false


func setup_default_run() -> Dictionary:
	run_manager = RUN_MANAGER.new()
	round_records = []
	battle_result_sequence = []
	force_low_power = false
	force_boss_loss = false

	var start_result: Dictionary = run_manager.start_new_run_requested()
	if not start_result.get("ok", false):
		return _fail("start_failed")
	if not run_manager.select_character(run_manager.character_data.character_id):
		return _fail("character_select_failed")

	var init_result: Dictionary = run_manager.init_run_values()
	if not init_result.get("ok", false):
		return _fail("run_init_failed")

	var starter_options: Array = run_manager.get_starter_treasure_options()
	if starter_options.size() != 3:
		return _fail("starter_option_count_invalid")

	var starter_result: Dictionary = choose_starter("flame_blade")
	if not starter_result.get("ok", false):
		return starter_result

	run_manager.debug_grant_treasure("thunder_bell", "green", "debug_default_run")
	run_manager.debug_grant_treasure("ice_mirror", "green", "debug_default_run")
	return _summary(true, "ok")


func choose_starter(treasure_id: String) -> Dictionary:
	if run_manager.starter_treasure_options.is_empty():
		run_manager.get_starter_treasure_options()

	var ok: bool = run_manager.select_starter_treasure(treasure_id)
	if not ok:
		return _summary(false, "starter_select_failed")

	return _summary(true, "ok")


func ensure_basic_formation() -> Dictionary:
	run_manager.enter_formation_edit()
	run_manager.debug_clear_formation()

	if force_low_power or force_boss_loss:
		var low_id: String = _ensure_instance("ice_mirror")
		var low_place: Dictionary = run_manager.formation_place_instance(low_id, "r0_c0")
		if not low_place.get("ok", false):
			return _summary(false, "low_power_place_failed")
		return run_manager.confirm_formation()

	var flame_id: String = _ensure_instance("flame_blade")
	var thunder_id: String = _ensure_instance("thunder_bell")
	var ice_id: String = _ensure_instance("ice_mirror")
	var flame_place: Dictionary = run_manager.formation_place_instance(flame_id, "r0_c0")
	var thunder_place: Dictionary = run_manager.formation_place_instance(thunder_id, "r0_c1")
	var ice_place: Dictionary = run_manager.formation_place_instance(ice_id, "r1_c0")
	if not flame_place.get("ok", false) or not thunder_place.get("ok", false) or not ice_place.get("ok", false):
		return _summary(false, "basic_formation_place_failed")

	if run_manager.normal_win_count >= 6:
		var solar_id: String = _ensure_instance("solar_cannon")
		var solar_place: Dictionary = run_manager.formation_place_instance(solar_id, "r1_c1")
		if not solar_place.get("ok", false):
			return _summary(false, "solar_place_failed")

	if run_manager.normal_win_count >= 8:
		var star_id: String = _ensure_instance("star_lance")
		var star_place: Dictionary = run_manager.formation_place_instance(star_id, "r0_c2")
		if not star_place.get("ok", false):
			return _summary(false, "star_place_failed")

	return run_manager.confirm_formation()


func play_one_round(branch_preference: String, combat_branch_preference: String) -> Dictionary:
	if run_manager.current_state != RUN_TYPES.RunState.BRANCH_SELECT:
		return _summary(false, "not_at_branch_select")
	if run_manager.normal_win_count >= run_manager.normal_win_target:
		return _summary(false, "boss_unlocked")

	var record: Dictionary = _new_round_record(branch_preference, combat_branch_preference)
	run_manager.generate_branch_options()
	var branch_id: String = _branch_id_from_preference(branch_preference)
	if not run_manager.select_branch(branch_id):
		return _summary(false, "branch_select_failed")

	record["branch"] = branch_id
	var node_result: Dictionary = _resolve_current_branch_node(branch_preference)
	record["node_result"] = node_result
	if not node_result.get("ok", false):
		return _summary(false, node_result.get("reason", "node_resolve_failed"))

	run_manager.run_synthesis_check()
	record["synthesis_count"] = run_manager.last_synthesis_results.size()
	var formation_result: Dictionary = ensure_basic_formation()
	record["formation_result"] = formation_result
	if not formation_result.get("ok", false):
		return _summary(false, formation_result.get("reason", "formation_failed"))

	var combat_options: Array = run_manager.generate_combat_branch_options()
	record["combat_option_count"] = combat_options.size()
	if run_manager.current_state == RUN_TYPES.RunState.BOSS_INTRO:
		return _summary(false, "boss_unlocked")

	var combat_branch_id: String = combat_branch_preference
	if combat_branch_id == "":
		combat_branch_id = "normal_safe"
	if not run_manager.select_combat_branch(combat_branch_id):
		return _summary(false, "combat_branch_select_failed")

	var battle_result: Dictionary = run_manager.start_current_combat()
	record["passed_combat_result"] = run_manager.current_state == RUN_TYPES.RunState.COMBAT_RESULT
	record["combat_result"] = battle_result.get("result", "")
	record["battle_summary"] = battle_result.get("summary", {})
	if not battle_result.get("ok", false):
		return _summary(false, battle_result.get("reason", "battle_start_failed"))

	var resolution: Dictionary = run_manager.resolve_combat_result()
	record["resolution"] = resolution
	if not resolution.get("ok", false):
		return _summary(false, resolution.get("reason", "combat_resolve_failed"))

	var confirm: Dictionary = run_manager.confirm_combat_result()
	record["confirm_result"] = confirm
	record["next_state"] = confirm.get("state", run_manager.current_state)
	record["gold_after"] = run_manager.gold
	record["durability_after"] = run_manager.run_durability
	record["normal_win_count_after"] = run_manager.normal_win_count
	round_records.append(record)
	battle_result_sequence.append(record["combat_result"])
	return record.duplicate(true)


func play_until_boss(max_rounds: int) -> Dictionary:
	var rounds_played: int = 0
	var branch_sequence: Array = ["shop", "supply", "gold", "gold"]
	while run_manager.normal_win_count < run_manager.normal_win_target:
		if rounds_played >= max_rounds:
			return _summary(false, "max_rounds_exceeded")

		var branch_preference: String = branch_sequence[rounds_played % branch_sequence.size()]
		var round_result: Dictionary = play_one_round(branch_preference, "normal_safe")
		if not round_result.get("ok", false):
			return round_result

		rounds_played += 1

	if run_manager.current_state != RUN_TYPES.RunState.BOSS_INTRO:
		run_manager.generate_combat_branch_options()

	return _summary(true, "ok")


func play_boss() -> Dictionary:
	if force_boss_loss:
		var loss_formation: Dictionary = ensure_basic_formation()
		if not loss_formation.get("ok", false):
			return _summary(false, loss_formation.get("reason", "boss_loss_formation_failed"))

	if run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT and run_manager.normal_win_count >= run_manager.normal_win_target:
		run_manager.generate_combat_branch_options()
	if run_manager.current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT and run_manager.normal_win_count >= run_manager.normal_win_target:
		run_manager.generate_combat_branch_options()
	if run_manager.current_state == RUN_TYPES.RunState.BOSS_INTRO:
		var enter_result: Dictionary = run_manager.enter_boss_combat_requested()
		if not enter_result.get("ok", false):
			return enter_result

	if run_manager.current_state != RUN_TYPES.RunState.BOSS_COMBAT:
		return _summary(false, "boss_combat_not_ready")

	var battle_result: Dictionary = run_manager.start_current_combat()
	if not battle_result.get("ok", false):
		return _summary(false, battle_result.get("reason", "boss_start_failed"))

	var resolution: Dictionary = run_manager.resolve_combat_result()
	if not resolution.get("ok", false):
		return resolution

	var confirm: Dictionary = run_manager.confirm_combat_result()
	var result: Dictionary = _summary(confirm.get("ok", false), confirm.get("reason", "boss_confirm_failed"))
	result["battle_result"] = battle_result.get("result", "")
	result["resolution"] = resolution
	result["confirm_result"] = confirm
	battle_result_sequence.append(battle_result.get("result", ""))
	return result


func play_full_run(max_rounds: int) -> Dictionary:
	var setup: Dictionary = setup_default_run()
	if not setup.get("ok", false):
		return setup
	if max_rounds <= 0:
		return _summary(false, "max_rounds_exceeded")

	var until_boss: Dictionary = play_until_boss(max_rounds)
	if not until_boss.get("ok", false):
		return until_boss

	var boss_result: Dictionary = play_boss()
	if not boss_result.get("ok", false):
		return boss_result

	var result: Dictionary = _summary(run_manager.current_state == RUN_TYPES.RunState.RUN_VICTORY, "ok")
	result["rounds"] = round_records.duplicate(true)
	result["battle_result_sequence"] = battle_result_sequence.duplicate()
	result["boss_result"] = boss_result
	return result


func force_normal_win_count(value: int) -> void:
	run_manager.debug_force_normal_win_count(value)


func force_low_player_power_profile() -> void:
	# 调试边界：后续 ensure_basic_formation 会只放一名防御单位，用于稳定触发普通战失败。
	force_low_power = true
	force_boss_loss = false


func force_boss_loss_profile() -> void:
	# 调试边界：后续 Boss 战只放一名低输出单位，用于验证 boss_lose 路由。
	force_boss_loss = true
	force_low_power = false


func _resolve_current_branch_node(branch_preference: String) -> Dictionary:
	match branch_preference:
		"shop":
			var buy_result: Dictionary = _buy_first_affordable_shop_item()
			run_manager.shop_leave_requested()
			buy_result["left_shop"] = run_manager.current_state == RUN_TYPES.RunState.SYNTHESIS_CHECK
			return buy_result
		"supply":
			run_manager.get_current_node_choices()
			return run_manager.apply_node_choice("supply_gold_2")
		"gold":
			run_manager.get_current_node_choices()
			return run_manager.apply_node_choice("gold_4")
		_:
			return {"ok": false, "reason": "unsupported_branch_preference"}


func _buy_first_affordable_shop_item() -> Dictionary:
	var index: int = 0
	while index < run_manager.current_shop_stock.size():
		var item = run_manager.current_shop_stock[index]
		if not item.is_sold and run_manager.gold >= item.price:
			return run_manager.shop_buy_item(item.shop_item_id)
		index += 1

	return {"ok": true, "reason": "no_affordable_item", "skipped_buy": true}


func _ensure_instance(treasure_id: String) -> String:
	var existing_id: String = _find_any_rarity_instance(treasure_id)
	if existing_id != "":
		return existing_id

	var result: Dictionary = run_manager.debug_grant_treasure(treasure_id, "green", "debug_run_driver")
	var added_ids: Array = result.get("added_instance_ids", [])
	if added_ids.is_empty():
		return ""

	return added_ids[0]


func _find_any_rarity_instance(treasure_id: String) -> String:
	var rarity_order: Array = ["yellow", "purple", "blue", "green"]
	var index: int = 0
	while index < rarity_order.size():
		var instance_id: String = run_manager.debug_find_instance_id(treasure_id, rarity_order[index])
		if instance_id != "":
			return instance_id
		index += 1

	return ""


func _branch_id_from_preference(branch_preference: String) -> String:
	match branch_preference:
		"shop":
			return "branch_shop"
		"supply":
			return "branch_supply"
		"gold":
			return "branch_gold"
		_:
			return branch_preference


func _new_round_record(branch_preference: String, combat_branch_preference: String) -> Dictionary:
	return {
		"ok": true,
		"reason": "ok",
		"run_state_before": run_manager.current_state,
		"gold_before": run_manager.gold,
		"durability_before": run_manager.run_durability,
		"normal_win_count_before": run_manager.normal_win_count,
		"branch_preference": branch_preference,
		"combat_branch_preference": combat_branch_preference,
	}


func _summary(ok: bool, reason: String) -> Dictionary:
	return {
		"ok": ok,
		"reason": reason,
		"run_state": run_manager.current_state,
		"gold": run_manager.gold,
		"durability": run_manager.run_durability,
		"normal_win_count": run_manager.normal_win_count,
		"normal_win_target": run_manager.normal_win_target,
		"defeat_reason": run_manager.defeat_reason,
		"state_history": run_manager.get_state_history(),
	}


func _fail(reason: String) -> Dictionary:
	return _summary(false, reason)
