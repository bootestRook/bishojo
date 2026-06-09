extends SceneTree

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")
const BATTLE_CONFIG = preload("res://scripts/systems/battle/battle_config.gd")
const BATTLE_CONTEXT = preload("res://scripts/systems/battle/battle_context.gd")
const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")
const BATTLE_UNIT_STATE = preload("res://scripts/systems/battle/battle_unit_state.gd")
const ENEMY_STATE = preload("res://scripts/systems/battle/enemy_state.gd")
const EFFECT_DATA = preload("res://scripts/systems/battle/effect_data.gd")
const DAMAGE_PACKET = preload("res://scripts/systems/battle/damage_packet.gd")
const BATTLE_RUNNER = preload("res://scripts/systems/battle/battle_runner.gd")
const BATTLE_TIMELINE_LOGGER = preload("res://scripts/systems/battle/battle_timeline_logger.gd")
const COOLDOWN_SCHEDULER = preload("res://scripts/systems/battle/cooldown_scheduler.gd")
const CARD_STATUS_RESOLVER = preload("res://scripts/systems/battle/card_status_resolver.gd")
const PLAYER_STATUS_RESOLVER = preload("res://scripts/systems/battle/player_status_resolver.gd")
const DAMAGE_RESOLVER = preload("res://scripts/systems/battle/damage_resolver.gd")
const LIFESTEAL_RESOLVER = preload("res://scripts/systems/battle/lifesteal_resolver.gd")
const CRITICAL_RESOLVER = preload("res://scripts/systems/battle/critical_resolver.gd")
const GENERIC_DOT_RESOLVER = preload("res://scripts/systems/battle/generic_dot_resolver.gd")
const TARGET_RESOLVER = preload("res://scripts/systems/battle/target_resolver.gd")
const CHAIN_GUARD = preload("res://scripts/systems/battle/chain_guard.gd")

# 文件职责：
# - 验证 V1 战斗底层纯逻辑闭环。
# - 该测试不创建 UI 场景，不注册 Autoload，不依赖动画或表现层。

var fail_count: int = 0


func _init() -> void:
	_run_smoke()
	if fail_count > 0:
		print("[BATTLE_SMOKE] failed")
		quit(1)
	else:
		print("[BATTLE_SMOKE] passed")
		quit(0)


func _run_smoke() -> void:
	var run_manager = _make_basic_run_with_three_units()
	_check(run_manager.current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT, "构筑前置可进入 COMBAT_BRANCH_SELECT")

	var branches: Array = run_manager.generate_combat_branch_options()
	_check(branches.size() == 3, "普通战斗分支生成 3 个候选")
	_check(run_manager.select_combat_branch("normal_safe"), "可选择稳妥普通战")
	_check(run_manager.current_state == RUN_TYPES.RunState.COMBAT, "选择普通战后进入 COMBAT")
	var win_result: Dictionary = run_manager.start_current_combat()
	_check(win_result.get("result", "") == "win", "training_dummy 普通战可自动胜利")
	_check(run_manager.current_state == RUN_TYPES.RunState.COMBAT_RESULT, "战斗结束后进入 COMBAT_RESULT")
	_print_timeline_preview(win_result.get("timeline_log", []))
	_check(_has_log_type(win_result.get("timeline_log", []), "PLAYER_TRIGGER_SKILL"), "日志包含卡牌自动启动")
	_check(_has_log_type(win_result.get("timeline_log", []), "COOLDOWN_RESET"), "日志包含技能后冷却重置")
	_check(_has_log_type(win_result.get("timeline_log", []), "CHARGE"), "日志包含雷铃充能")
	_check(_has_log_cause(win_result.get("timeline_log", []), "charged_to_ready"), "充能到 0 后可立即触发")
	run_manager.resolve_combat_result()
	_check(run_manager.normal_win_count == 1, "普通战胜利后 normal_win_count +1")
	_check(run_manager.next_state_after_result == RUN_TYPES.RunState.BRANCH_SELECT, "普通战胜利后回到分支选择")

	var lose_manager = _make_basic_run_with_three_units()
	var durability_before: int = lose_manager.run_durability
	lose_manager.generate_combat_branch_options()
	lose_manager.select_combat_branch("normal_high_reward")
	var lose_result: Dictionary = lose_manager.start_current_combat()
	_check(lose_result.get("result", "") == "lose", "高攻击普通敌人可造成普通战失败")
	lose_manager.resolve_combat_result()
	_check(lose_manager.run_durability == durability_before - 1, "普通战失败后 run_durability -1")

	_check_card_statuses()
	_check_player_statuses_and_damage()
	_check_critical_and_determinism()
	_check_dot()
	_check_position_targets()
	_check_chain_guard()
	_check_timeout()
	_check_run_manager_result_routes()


func _make_basic_run_with_three_units():
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	run_manager.get_starter_treasure_options()
	run_manager.select_starter_treasure("flame_blade")
	var thunder = run_manager.inventory_model.add_treasure("thunder_bell", "green", "debug")
	var ice = run_manager.inventory_model.add_treasure("ice_mirror", "green", "debug")
	run_manager.enter_formation_edit()
	var flame = _find_instance(run_manager, "flame_blade", "green")
	run_manager.formation_place_instance(flame.instance_id, "r0_c0")
	run_manager.formation_place_instance(thunder.instance_id, "r0_c1")
	run_manager.formation_place_instance(ice.instance_id, "r1_c0")
	_check(run_manager.validate_formation().get("ok", false), "三单位阵容 validate 成功")
	run_manager.confirm_formation()
	return run_manager


func _check_card_statuses() -> void:
	var config = BATTLE_CONFIG.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var scheduler = COOLDOWN_SCHEDULER.new()
	var status = CARD_STATUS_RESOLVER.new()

	var haste_context = _make_status_context()
	var haste_unit = _make_unit("haste_unit", 4000)
	haste_context.player_units.append(haste_unit)
	scheduler.initialize_unit_cooldown(haste_context, haste_unit, config, logger)
	status.apply_haste(haste_context, haste_unit, 2000, scheduler, logger)
	_check(haste_unit.cooldown_rate_bp == 20000, "加速使 cooldown_rate_bp = 20000")

	var slow_context = _make_status_context()
	var slow_unit = _make_unit("slow_unit", 4000)
	slow_context.player_units.append(slow_unit)
	scheduler.initialize_unit_cooldown(slow_context, slow_unit, config, logger)
	status.apply_slow(slow_context, slow_unit, 2000, scheduler, logger)
	_check(slow_unit.cooldown_rate_bp == 5000, "减速使 cooldown_rate_bp = 5000")

	var mixed_context = _make_status_context()
	var mixed_unit = _make_unit("mixed_unit", 4000)
	mixed_context.player_units.append(mixed_unit)
	scheduler.initialize_unit_cooldown(mixed_context, mixed_unit, config, logger)
	status.apply_haste(mixed_context, mixed_unit, 2000, scheduler, logger)
	status.apply_slow(mixed_context, mixed_unit, 2000, scheduler, logger)
	_check(mixed_unit.cooldown_rate_bp == 10000, "加速 + 减速后 cooldown_rate_bp 回到 10000")

	var freeze_context = _make_status_context()
	var freeze_unit = _make_unit("freeze_unit", 500)
	freeze_context.player_units.append(freeze_unit)
	scheduler.initialize_unit_cooldown(freeze_context, freeze_unit, config, logger)
	status.apply_freeze(freeze_context, freeze_unit, 1000, scheduler, logger)
	freeze_context.time_ms = 600
	scheduler.update_cooldown_to_now(freeze_context, freeze_unit, logger, "freeze_test")
	_check(freeze_unit.remaining_cooldown_ms == 0 and freeze_unit.freeze_stack > 0, "冰冻期间冷却可以归零但仍被冰冻阻塞")
	freeze_unit.is_ready_blocked_by_freeze = true
	freeze_context.time_ms = 1000
	status.expire_status(freeze_context, freeze_unit, "freeze", scheduler, logger)
	_check(not freeze_context.event_queue.is_empty(), "冰冻结束后冷却为 0 会补触发")


func _check_player_statuses_and_damage() -> void:
	var config = BATTLE_CONFIG.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var player_status = PLAYER_STATUS_RESOLVER.new()
	var damage_resolver = DAMAGE_RESOLVER.new()
	var lifesteal_resolver = LIFESTEAL_RESOLVER.new()

	var shield_context = _make_status_context()
	player_status.add_shield(shield_context, 10, config, logger, "debug")
	var shield_packet = DAMAGE_PACKET.new()
	shield_packet.setup({"source_id": "enemy", "target_id": "player_core", "target_layer": "player_core", "damage_kind": "enemy_attack", "raw_damage": 7, "can_crit": false})
	damage_resolver.apply_to_player_core(shield_context, shield_packet, config, logger)
	_check(shield_context.player_shield_stack == 3 and shield_context.player_core_hp == shield_context.player_core_hp_max, "护盾 1 层抵挡 1 点普通伤害")

	var burn_context = _make_status_context()
	player_status.add_shield(burn_context, 10, config, logger, "debug")
	player_status.apply_burn(burn_context, 4, logger, "debug")
	player_status.tick_burn(burn_context, config, damage_resolver, logger)
	_check(burn_context.player_burn_stack == 3, "燃烧 tick 后层数 -1")
	_check(burn_context.player_shield_stack == 8 and burn_context.player_core_hp == burn_context.player_core_hp_max, "有护盾时燃烧伤害先减半再被护盾吸收")

	var poison_context = _make_status_context()
	player_status.add_shield(poison_context, 10, config, logger, "debug")
	player_status.apply_poison(poison_context, 4, 5000, logger, "debug")
	player_status.tick_poison(poison_context, config, damage_resolver, logger)
	_check(poison_context.player_core_hp == poison_context.player_core_hp_max - 4, "剧毒每 1000ms tick 且忽视护盾")
	_check(poison_context.player_shield_stack == 10, "剧毒不消耗护盾")

	var heal_context = _make_status_context()
	heal_context.player_core_hp = 50
	heal_context.player_poison_stack = 10
	heal_context.player_burn_stack = 10
	player_status.heal_player(heal_context, 20, config, logger, "debug")
	_check(heal_context.player_core_hp == 60, "治疗恢复 player_core_hp")
	_check(heal_context.player_poison_stack == 9 and heal_context.player_burn_stack == 9, "治疗清除治疗量 5% 的中毒和燃烧")
	player_status.heal_player(heal_context, 20, config, logger, "debug")
	_check(heal_context.player_core_hp == 60 and heal_context.player_poison_stack == 8, "满血时治疗也能清异常")

	var lifesteal_context = _make_status_context()
	lifesteal_context.player_core_hp = 30
	lifesteal_context.player_poison_stack = 5
	lifesteal_context.player_burn_stack = 5
	var source_unit = _make_unit("lifesteal_unit", 4000)
	source_unit.lifesteal_bp = 10000
	var enemy = ENEMY_STATE.new()
	enemy.setup({"enemy_id": "shield_enemy", "enemy_name": "盾敌", "hp": 100, "hp_max": 100, "shield": 15, "attack_damage": 0, "attack_interval_ms": 0})
	var packet = DAMAGE_PACKET.new()
	packet.setup({"source_id": source_unit.instance_id, "target_id": enemy.enemy_id, "target_layer": "enemy", "damage_kind": "direct", "raw_damage": 20, "can_crit": false, "can_trigger_lifesteal": true})
	var damage_result = damage_resolver.apply_to_enemy(lifesteal_context, packet, enemy, config, logger)
	lifesteal_resolver.apply_lifesteal(lifesteal_context, source_unit, damage_result, logger)
	_check(lifesteal_context.player_core_hp == 35, "吸血按 actual_hp_damage 恢复，不按护盾吸收部分恢复")
	_check(lifesteal_context.player_poison_stack == 5 and lifesteal_context.player_burn_stack == 5, "吸血不清中毒和燃烧")

	var overflow_enemy = ENEMY_STATE.new()
	overflow_enemy.setup({"enemy_id": "low_hp_enemy", "enemy_name": "低血敌", "hp": 5, "hp_max": 5, "shield": 10, "attack_damage": 0, "attack_interval_ms": 0})
	var overflow_packet = DAMAGE_PACKET.new()
	overflow_packet.setup({"source_id": "debug", "target_id": overflow_enemy.enemy_id, "target_layer": "enemy", "damage_kind": "direct", "raw_damage": 20, "can_crit": false})
	var overflow_result = damage_resolver.apply_to_enemy(_make_status_context(), overflow_packet, overflow_enemy, config, logger)
	_check(overflow_result.final_damage == 20 and overflow_result.shield_damage == 10 and overflow_result.actual_hp_damage == 5, "DamageResult 排除护盾吸收和溢出伤害")


func _check_critical_and_determinism() -> void:
	var config = BATTLE_CONFIG.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var crit = CRITICAL_RESOLVER.new()
	var context_a = _make_status_context()
	var context_b = _make_status_context()
	context_a.battle_seed = 777
	context_b.battle_seed = 777
	var packet_a = DAMAGE_PACKET.new()
	var packet_b = DAMAGE_PACKET.new()
	packet_a.setup({"source_id": "a", "target_id": "b", "damage_kind": "direct", "can_crit": true, "crit_rate_bp": 5000, "crit_damage_bp": 20000})
	packet_b.setup({"source_id": "a", "target_id": "b", "damage_kind": "direct", "can_crit": true, "crit_rate_bp": 5000, "crit_damage_bp": 20000})
	var result_a = crit.resolve(context_a, packet_a, config, logger)
	var result_b = crit.resolve(context_b, packet_b, config, logger)
	_check(result_a.roll_value_bp == result_b.roll_value_bp and result_a.result == result_b.result, "同一 seed 的暴击 roll 可复盘")
	_check(result_a.rng_roll_index == 1 and result_a.threshold_bp == 5000, "暴击日志记录 rng_roll_index、roll_value_bp、threshold_bp")


func _check_dot() -> void:
	var config = BATTLE_CONFIG.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var damage_resolver = DAMAGE_RESOLVER.new()
	var dot = GENERIC_DOT_RESOLVER.new()
	var context = _make_status_context()
	var source_unit = _make_unit("dot_source", 4000)
	var enemy = ENEMY_STATE.new()
	enemy.setup({"enemy_id": "dot_enemy", "enemy_name": "DOT 敌人", "hp": 6, "hp_max": 6, "shield": 0, "attack_damage": 0, "attack_interval_ms": 0})
	context.enemies.append(enemy)
	var effect = EFFECT_DATA.new()
	effect.setup({"effect_type": "apply_dot_to_enemy", "target_rule": "enemy_single", "value": 3, "duration_ms": 2000, "tick_interval_ms": 1000, "stack_rule": "refresh", "max_stacks": 1, "can_crit": false, "can_trigger_lifesteal": false})
	dot.apply_dot(context, source_unit, enemy, effect, config, logger)
	var tick_one = context.event_queue.pop()
	context.time_ms = tick_one.trigger_time_ms
	dot.handle_tick(context, tick_one, config, damage_resolver, logger)
	_check(enemy.hp == 3, "对敌 DOT 能按 tick 造成伤害")
	var tick_two = context.event_queue.pop()
	context.time_ms = tick_two.trigger_time_ms
	dot.handle_tick(context, tick_two, config, damage_resolver, logger)
	_check(not enemy.is_alive, "DOT tick 可以击杀敌人")
	_check(_has_log_cause(context.timeline_log, "dot_no_crit_no_lifesteal_no_chain"), "DOT 默认不暴击、不吸血、不触发连锁")


func _check_position_targets() -> void:
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	run_manager.normal_win_count = 10
	run_manager.enter_formation_edit()
	var large = run_manager.inventory_model.add_treasure("solar_cannon", "green", "debug")
	var left = run_manager.inventory_model.add_treasure("flame_blade", "green", "debug")
	var right = run_manager.inventory_model.add_treasure("thunder_bell", "green", "debug")
	var back = run_manager.inventory_model.add_treasure("ice_mirror", "green", "debug")
	run_manager.formation_place_instance(left.instance_id, "r0_c0")
	run_manager.formation_place_instance(large.instance_id, "r0_c1")
	run_manager.formation_place_instance(right.instance_id, "r0_c4")
	run_manager.formation_place_instance(back.instance_id, "r1_c2")
	var context = run_manager.battle_manager.context_builder.build(run_manager.inventory_model, run_manager.formation_model, run_manager.treasure_catalog, run_manager.enemy_catalog, "normal_safe", 123)
	var source = _find_battle_unit(context, large.instance_id)
	var resolver = TARGET_RESOLVER.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var adjacent: Array = resolver.resolve_targets(context, source, "adjacent", logger)
	var same_row: Array = resolver.resolve_targets(context, source, "same_row", logger)
	var same_col: Array = resolver.resolve_targets(context, source, "same_col", logger)
	var overlap: Array = resolver.resolve_targets(context, source, "front_back_overlap", logger)
	_check(_target_has(adjacent, left.instance_id) and _target_has(adjacent, right.instance_id), "adjacent 正确读取多格单位左右外侧")
	_check(_target_has(same_row, left.instance_id) and _target_has(same_row, right.instance_id), "same_row 正确读取同排单位")
	_check(_target_has(same_col, back.instance_id), "same_col 正确读取列范围重叠")
	_check(_target_has(overlap, back.instance_id), "front_back_overlap 正确读取另一行列重叠")


func _check_chain_guard() -> void:
	var config = BATTLE_CONFIG.new()
	var logger = BATTLE_TIMELINE_LOGGER.new()
	var guard = CHAIN_GUARD.new()
	var context = _make_status_context()
	var delayed: bool = false
	var index: int = 0
	while index <= config.max_chain_events_per_same_time:
		var event = BATTLE_EVENT.new()
		event.setup({"event_type": "PLAYER_TRIGGER_SKILL", "trigger_time_ms": 1000, "source_id": "chain", "target_id": "chain", "chain_depth": index})
		if guard.should_delay_event(context, event, config, logger):
			delayed = event.trigger_time_ms == 1001
		index += 1
	_check(delayed, "同一毫秒超过连锁上限后延后到 time_ms + 1")


func _check_timeout() -> void:
	var runner = BATTLE_RUNNER.new()
	var context = _make_status_context()
	var enemy = ENEMY_STATE.new()
	enemy.setup({"enemy_id": "timeout_enemy", "enemy_name": "超时敌人", "hp": 999, "hp_max": 999, "shield": 0, "attack_damage": 0, "attack_interval_ms": 1000})
	context.enemies.append(enemy)
	var result: Dictionary = runner.run(context)
	_check(result.get("result", "") == "timeout", "超时后 result = timeout 且不会卡死")


func _check_run_manager_result_routes() -> void:
	var win_route = _make_basic_run_with_three_units()
	win_route.last_combat_result = "win"
	win_route.current_battle_type = "normal_safe"
	win_route.normal_win_count = win_route.normal_win_target - 1
	win_route.resolve_combat_result()
	_check(win_route.next_state_after_result == RUN_TYPES.RunState.BOSS_INTRO, "normal_win_count 达标后进入 Boss")

	var boss_win = _make_basic_run_with_three_units()
	boss_win.current_battle_type = "boss"
	boss_win.last_combat_result = "win"
	boss_win.resolve_combat_result()
	_check(boss_win.next_state_after_result == RUN_TYPES.RunState.RUN_VICTORY, "Boss 胜利进入 RUN_VICTORY")

	var boss_lose = _make_basic_run_with_three_units()
	boss_lose.current_battle_type = "boss"
	boss_lose.last_combat_result = "lose"
	boss_lose.resolve_combat_result()
	_check(boss_lose.next_state_after_result == RUN_TYPES.RunState.RUN_DEFEAT and boss_lose.defeat_reason == "boss_lose", "Boss 失败进入 RUN_DEFEAT")

	var durability_zero = _make_basic_run_with_three_units()
	durability_zero.current_battle_type = "normal_safe"
	durability_zero.last_combat_result = "lose"
	durability_zero.run_durability = 1
	durability_zero.resolve_combat_result()
	_check(durability_zero.next_state_after_result == RUN_TYPES.RunState.RUN_DEFEAT and durability_zero.defeat_reason == "durability_zero", "普通战失败且耐久归零进入 RUN_DEFEAT")


func _make_status_context():
	var context = BATTLE_CONTEXT.new()
	context.battle_id = "debug_context"
	context.battle_type = "normal"
	context.battle_seed = 42
	context.player_core_hp_max = 60
	context.player_core_hp = 60
	return context


func _make_unit(instance_id: String, cooldown_ms: int):
	var unit = BATTLE_UNIT_STATE.new()
	unit.instance_id = instance_id
	unit.treasure_id = instance_id
	unit.treasure_name = instance_id
	unit.rarity = "green"
	unit.base_cooldown_ms = cooldown_ms
	unit.row = 0
	unit.col_start = 0
	unit.col_end = 0
	unit.slot_ids = ["r0_c0"]
	return unit


func _find_instance(run_manager, treasure_id: String, rarity: String):
	var instances: Array = run_manager.inventory_model.get_all_instances()
	var index: int = 0
	while index < instances.size():
		if instances[index].treasure_id == treasure_id and instances[index].rarity == rarity:
			return instances[index]
		index += 1
	return null


func _find_battle_unit(context, instance_id: String):
	var index: int = 0
	while index < context.player_units.size():
		if context.player_units[index].instance_id == instance_id:
			return context.player_units[index]
		index += 1
	return null


func _has_log_type(logs: Array, event_type: String) -> bool:
	var index: int = 0
	while index < logs.size():
		if logs[index].event_type == event_type:
			return true
		index += 1
	return false


func _has_log_cause(logs: Array, cause: String) -> bool:
	var index: int = 0
	while index < logs.size():
		if logs[index].cause == cause:
			return true
		index += 1
	return false


func _target_has(targets: Array, instance_id: String) -> bool:
	var index: int = 0
	while index < targets.size():
		if targets[index].instance_id == instance_id:
			return true
		index += 1
	return false


func _print_timeline_preview(logs: Array) -> void:
	print("[TIMELINE] count=", logs.size())
	var index: int = 0
	while index < logs.size() and index < 8:
		print("[TIMELINE] ", logs[index].time_ms, " ", logs[index].event_type, " ", logs[index].source_id, " -> ", logs[index].target_id, " cause=", logs[index].cause)
		index += 1


func _check(ok: bool, label: String) -> void:
	if ok:
		print("[PASS] ", label)
	else:
		fail_count += 1
		print("[FAIL] ", label)
