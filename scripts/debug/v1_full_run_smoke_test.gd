extends SceneTree

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")
const V1_RUN_DEBUG_DRIVER = preload("res://scripts/systems/run/v1_run_debug_driver.gd")
const REWARD_MANAGER = preload("res://scripts/systems/reward/reward_manager.gd")

# 文件职责：
# - 验证 V1 纯逻辑整局闭环能在无 UI、无 Autoload、无场景节点时完整运行。
# - 覆盖胜利、普通失败续跑、耐久归零、Boss 失败、奖励、节点、合成、阵型和确定性。

var fail_count: int = 0


func _init() -> void:
	_run_smoke()
	if fail_count > 0:
		print("[FULL_RUN_SMOKE] failed")
		quit(1)
	else:
		print("[FULL_RUN_SMOKE] passed")
		quit(0)


func _run_smoke() -> void:
	_check_normal_victory_run()
	_check_normal_fail_continue()
	_check_durability_zero_defeat()
	_check_boss_defeat()
	_check_boss_unlock()
	_check_rewards()
	_check_shop_supply_gold_loop()
	_check_synthesis_in_run()
	_check_formation_validation()
	_check_determinism()
	_check_max_rounds_cap()


func _check_normal_victory_run() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	var result: Dictionary = driver.play_full_run(12)
	_check(result.get("ok", false), "正常胜利 Run 可完成")
	_check(driver.run_manager.current_state == RUN_TYPES.RunState.RUN_VICTORY, "Boss 胜利后进入 RUN_VICTORY")
	_check(driver.run_manager.normal_win_count >= driver.run_manager.normal_win_target, "normal_win_count 达到目标")
	_check(driver.run_manager.get_state_history().has(RUN_TYPES.RunState.COMBAT_RESULT), "state_history 包含 COMBAT_RESULT")
	_check(_rounds_all_passed_combat_result(result.get("rounds", [])), "每轮都经过 COMBAT_RESULT")
	_check(_rounds_all_confirmed_to_reasonable_state(result.get("rounds", [])), "每轮 confirm_combat_result 后进入合理状态")


func _check_normal_fail_continue() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.force_low_player_power_profile()
	var durability_before: int = driver.run_manager.run_durability
	var result: Dictionary = driver.play_one_round("gold", "normal_high_reward")
	_check(result.get("ok", false), "普通战失败分支仍能完成结算")
	_check(result.get("combat_result", "") != "win", "弱阵容高奖励战不会胜利")
	_check(driver.run_manager.run_durability == durability_before - 1, "普通战失败 run_durability -1")
	_check(driver.run_manager.run_durability > 0 and driver.run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT, "耐久未归零时回到 BRANCH_SELECT")
	_check(driver.run_manager.normal_win_count == 0, "普通战失败 normal_win_count 不增加")


func _check_durability_zero_defeat() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.force_low_player_power_profile()
	driver.run_manager.debug_force_run_durability(1)
	var result: Dictionary = driver.play_one_round("gold", "normal_high_reward")
	_check(result.get("ok", false), "耐久归零分支完成结算")
	_check(driver.run_manager.current_state == RUN_TYPES.RunState.RUN_DEFEAT, "耐久归零进入 RUN_DEFEAT")
	_check(driver.run_manager.defeat_reason == "durability_zero", "耐久归零失败原因正确")


func _check_boss_defeat() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.force_normal_win_count(driver.run_manager.normal_win_target)
	driver.run_manager.generate_combat_branch_options()
	driver.force_boss_loss_profile()
	var result: Dictionary = driver.play_boss()
	_check(result.get("ok", false), "Boss 失败分支完成结算")
	_check(driver.run_manager.current_state == RUN_TYPES.RunState.RUN_DEFEAT, "Boss 失败进入 RUN_DEFEAT")
	_check(driver.run_manager.defeat_reason == "boss_lose", "Boss 失败原因正确")


func _check_boss_unlock() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.force_normal_win_count(driver.run_manager.normal_win_target - 1)
	var result: Dictionary = driver.play_one_round("gold", "normal_safe")
	_check(result.get("ok", false), "达标前最后一场普通战可结算")
	_check(driver.run_manager.normal_win_count == driver.run_manager.normal_win_target, "最后一场胜利后 normal_win_count 达标")
	_check(result.get("resolution", {}).get("next_state", -1) == RUN_TYPES.RunState.BOSS_INTRO, "达标后 next_state_after_result 指向 BOSS_INTRO")
	var options: Array = driver.run_manager.generate_combat_branch_options()
	_check(options.size() == 1 and options[0].get("combat_branch_id", "") == "boss_final", "Boss 解锁后不再生成普通战分支")


func _check_rewards() -> void:
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	var reward_manager = REWARD_MANAGER.new()
	var safe_result: Dictionary = reward_manager.grant_combat_reward(run_manager, "normal_safe", "normal_safe")
	var normal_result: Dictionary = reward_manager.grant_combat_reward(run_manager, "normal_standard", "normal_standard")
	var high_result: Dictionary = reward_manager.grant_combat_reward(run_manager, "normal_high_reward", "normal_high_reward")
	var safe_delta: int = safe_result.get("gold_after", 0) - safe_result.get("gold_before", 0)
	var normal_delta: int = normal_result.get("gold_after", 0) - normal_result.get("gold_before", 0)
	var high_delta: int = high_result.get("gold_after", 0) - high_result.get("gold_before", 0)
	_check(normal_delta > 0, "普通战胜利奖励金币增加")
	_check(high_delta >= normal_delta, "高奖励战金币不少于普通战")
	_check(safe_delta <= normal_delta, "稳妥战金币不高于普通战")
	_check(normal_result.has("gold_before") and normal_result.has("gold_after"), "reward_result 记录 gold_before / gold_after")


func _check_shop_supply_gold_loop() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	var shop_round: Dictionary = driver.play_one_round("shop", "normal_safe")
	_check(shop_round.get("ok", false), "商店节点可进入整局循环")
	_check(shop_round.get("node_result", {}).get("ok", false), "金币足够时商店可购买或明确跳过")
	var supply_round: Dictionary = driver.play_one_round("supply", "normal_safe")
	_check(supply_round.get("ok", false), "补给节点可进入整局循环")
	var gold_round: Dictionary = driver.play_one_round("gold", "normal_safe")
	_check(gold_round.get("ok", false), "金币节点可进入整局循环")


func _check_synthesis_in_run() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.run_manager.debug_grant_treasure("moon_dagger", "green", "debug_synthesis")
	driver.run_manager.debug_grant_treasure("moon_dagger", "green", "debug_synthesis")
	var logs: Array = driver.run_manager.run_synthesis_check()
	_check(not logs.is_empty(), "整局中可触发合成")
	_check(driver.run_manager.debug_find_instance_id("moon_dagger", "blue") != "", "两件 green 合成 blue")


func _check_formation_validation() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	driver.setup_default_run()
	driver.run_manager.enter_formation_edit()
	driver.run_manager.debug_clear_formation()
	var empty_result: Dictionary = driver.run_manager.confirm_formation()
	_check(not empty_result.get("ok", true), "空阵 confirm_formation 失败")
	var valid_result: Dictionary = driver.ensure_basic_formation()
	_check(valid_result.get("ok", false), "合法阵型 confirm_formation 成功")
	_check(driver.run_manager.current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT, "合法阵型进入 COMBAT_BRANCH_SELECT")


func _check_determinism() -> void:
	var driver_a = V1_RUN_DEBUG_DRIVER.new()
	var driver_b = V1_RUN_DEBUG_DRIVER.new()
	var result_a: Dictionary = driver_a.play_full_run(12)
	var result_b: Dictionary = driver_b.play_full_run(12)
	_check(result_a.get("ok", false) and result_b.get("ok", false), "两次 full_run 都成功")
	_check(driver_a.run_manager.current_state == driver_b.run_manager.current_state, "确定性：最终状态一致")
	_check(driver_a.run_manager.normal_win_count == driver_b.run_manager.normal_win_count, "确定性：胜场一致")
	_check(driver_a.run_manager.run_durability == driver_b.run_manager.run_durability, "确定性：耐久一致")
	_check(_arrays_equal(result_a.get("battle_result_sequence", []), result_b.get("battle_result_sequence", [])), "确定性：关键战斗结果序列一致")


func _check_max_rounds_cap() -> void:
	var driver = V1_RUN_DEBUG_DRIVER.new()
	var result: Dictionary = driver.play_full_run(0)
	_check(not result.get("ok", true), "max_rounds 超限时返回失败")
	_check(result.get("reason", "") == "max_rounds_exceeded", "max_rounds 失败原因明确")


func _rounds_all_passed_combat_result(rounds: Array) -> bool:
	if rounds.is_empty():
		return false
	var index: int = 0
	while index < rounds.size():
		if not rounds[index].get("passed_combat_result", false):
			return false
		index += 1

	return true


func _rounds_all_confirmed_to_reasonable_state(rounds: Array) -> bool:
	if rounds.is_empty():
		return false
	var index: int = 0
	while index < rounds.size():
		var confirm: Dictionary = rounds[index].get("confirm_result", {})
		var state: int = confirm.get("state", -1)
		if not confirm.get("ok", false):
			return false
		if state != RUN_TYPES.RunState.BRANCH_SELECT and state != RUN_TYPES.RunState.BOSS_INTRO and state != RUN_TYPES.RunState.RUN_DEFEAT:
			return false
		index += 1

	return true


func _arrays_equal(left: Array, right: Array) -> bool:
	if left.size() != right.size():
		return false
	var index: int = 0
	while index < left.size():
		if left[index] != right[index]:
			return false
		index += 1

	return true


func _check(ok: bool, label: String) -> void:
	if ok:
		print("[PASS] ", label)
	else:
		fail_count += 1
		print("[FAIL] ", label)
