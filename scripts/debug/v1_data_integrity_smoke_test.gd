extends SceneTree

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const RUN_MANAGER = preload("res://scripts/managers/run_manager.gd")
const V1_TREASURE_CATALOG = preload("res://scripts/data/treasure/v1_treasure_catalog.gd")
const V1_RARITY_CONFIG = preload("res://scripts/data/treasure/v1_rarity_config.gd")
const V1_TREASURE_SIZE_CONFIG = preload("res://scripts/data/treasure/v1_treasure_size_config.gd")
const V1_ENEMY_CATALOG = preload("res://scripts/data/enemies/v1_enemy_catalog.gd")
const V1_COMBAT_BRANCH_CONFIG = preload("res://scripts/data/battle/v1_combat_branch_config.gd")
const REWARD_MANAGER = preload("res://scripts/systems/reward/reward_manager.gd")
const SHOP_MANAGER = preload("res://scripts/systems/shop/shop_manager.gd")

# 文件职责：
# - 验证 V1 纯逻辑数据表之间的基础引用关系。
# - 本脚本不创建 UI 场景，不注册 Autoload，只检查 catalog、配置和 RunTypes 显示契约。

var fail_count: int = 0
var treasure_catalog = V1_TREASURE_CATALOG.new()
var rarity_config = V1_RARITY_CONFIG.new()
var size_config = V1_TREASURE_SIZE_CONFIG.new()
var enemy_catalog = V1_ENEMY_CATALOG.new()
var combat_branch_config = V1_COMBAT_BRANCH_CONFIG.new()


func _init() -> void:
	_run_smoke()
	if fail_count > 0:
		print("[DATA_SMOKE] failed")
		quit(1)
	else:
		print("[DATA_SMOKE] passed")
		quit(0)


func _run_smoke() -> void:
	_check_starter_treasures()
	_check_treasure_catalog()
	_check_enemy_catalog()
	_check_combat_branch_config()
	_check_reward_options()
	_check_shop_stock()
	_check_synthesis_boundary()
	_check_display_contracts()
	_check_boss_unlock_branch_generation()


func _check_starter_treasures() -> void:
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	var starter_ids: Array = run_manager.get_starter_treasure_options()
	_check(starter_ids.size() == 3, "初始营地提供 3 个候选")
	var index: int = 0
	while index < starter_ids.size():
		_check(treasure_catalog.has_treasure_id(starter_ids[index]), "初始秘宝存在于 treasure catalog: %s" % starter_ids[index])
		index += 1


func _check_treasure_catalog() -> void:
	var ids: Array = treasure_catalog.get_all_treasure_ids()
	_check(ids.size() >= 12, "treasure catalog 至少 12 个秘宝")
	_check(_ids_unique(ids), "treasure_id 唯一且非空")

	var supported_effect_types: Array = [
		"damage",
		"shield",
		"heal",
		"charge",
		"apply_haste",
		"apply_slow",
		"apply_freeze",
		"apply_lifesteal",
		"apply_poison_to_player",
		"apply_burn_to_player",
		"apply_dot_to_enemy",
		"buff",
		"gold",
	]
	var supported_target_rules: Array = [
		"enemy_single",
		"enemy_all",
		"player_core",
		"self",
		"adjacent",
		"same_row",
		"same_col",
		"front_back_overlap",
		"center_column",
		"longest_cooldown_ally",
		"random_ally",
		"run",
	]

	var index: int = 0
	while index < ids.size():
		var raw: Dictionary = treasure_catalog.catalog.get(ids[index], {})
		var treasure = treasure_catalog.get_treasure_data(ids[index], "green")
		_check(treasure != null, "秘宝可实例化: %s" % ids[index])
		_check(rarity_config.is_valid_rarity(treasure.rarity), "秘宝稀有度合法: %s" % ids[index])
		_check(size_config.is_valid_size_type(treasure.size_type), "秘宝 size_type 合法: %s" % ids[index])
		_check(_footprint_matches(treasure), "秘宝 footprint 与 size config 一致: %s" % ids[index])
		var effects: Array = raw.get("effect_list", [])
		_check(not effects.is_empty(), "秘宝 effect_list 非空: %s" % ids[index])
		var effect_index: int = 0
		while effect_index < effects.size():
			var effect: Dictionary = effects[effect_index]
			_check(supported_effect_types.has(effect.get("effect_type", "")), "effect_type 已被 resolver 承接: %s" % effect.get("effect_type", ""))
			_check(supported_target_rules.has(effect.get("target_rule", "")), "target_rule 已被 resolver 承接: %s" % effect.get("target_rule", ""))
			effect_index += 1
		index += 1


func _check_enemy_catalog() -> void:
	var enemy_ids: Array = enemy_catalog.catalog.keys()
	_check(_ids_unique(enemy_ids), "enemy_id 唯一且非空")
	var index: int = 0
	while index < enemy_ids.size():
		_check(enemy_catalog.get_enemy_data(enemy_ids[index]) != null, "敌人可实例化: %s" % enemy_ids[index])
		index += 1

	var safe_ids: Array = enemy_catalog.get_enemy_ids_for_battle_type("normal_safe")
	var boss_ids: Array = enemy_catalog.get_enemy_ids_for_battle_type("boss")
	_check(not safe_ids.is_empty() and enemy_catalog.get_enemy_data(safe_ids[0]) != null, "普通战敌人可查到")
	_check(not boss_ids.is_empty() and enemy_catalog.get_enemy_data(boss_ids[0]) != null, "Boss 敌人可查到")


func _check_combat_branch_config() -> void:
	var options: Array = combat_branch_config.get_normal_combat_options(0)
	options.append(combat_branch_config.get_boss_option())
	var index: int = 0
	while index < options.size():
		var option: Dictionary = options[index]
		var enemy_id: String = option.get("enemy_id", "")
		_check(enemy_catalog.get_enemy_data(enemy_id) != null, "combat branch enemy_id 存在: %s" % enemy_id)
		_check(combat_branch_config.get_enemy_id_for_branch(option.get("combat_branch_id", "")) == enemy_id, "combat branch enemy 查询一致: %s" % option.get("combat_branch_id", ""))
		_check(combat_branch_config.get_reward_profile_for_branch(option.get("combat_branch_id", "")) != "", "combat branch reward_profile 非空: %s" % option.get("combat_branch_id", ""))
		index += 1


func _check_reward_options() -> void:
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	var manager = REWARD_MANAGER.new()
	var options: Array = manager.generate_post_battle_rewards(run_manager, "normal_safe", "normal_safe")
	var index: int = 0
	while index < options.size():
		var payload: Dictionary = options[index].payload
		if payload.has("treasure_id"):
			_check(treasure_catalog.has_treasure_id(payload.get("treasure_id", "")), "reward treasure_id 存在: %s" % payload.get("treasure_id", ""))
		index += 1


func _check_shop_stock() -> void:
	var shop_manager = SHOP_MANAGER.new()
	var stock: Array = shop_manager.prepare_stock(treasure_catalog, [])
	_check(not stock.is_empty(), "商店可生成库存")
	var index: int = 0
	while index < stock.size():
		_check(treasure_catalog.has_treasure_id(stock[index].treasure_id), "商店库存 treasure_id 存在: %s" % stock[index].treasure_id)
		index += 1


func _check_synthesis_boundary() -> void:
	_check(not rarity_config.can_upgrade("yellow"), "yellow 不能继续合成")


func _check_display_contracts() -> void:
	var run_manager = RUN_MANAGER.new()
	var states: Array = [
		RUN_TYPES.RunState.CHARACTER_SELECT,
		RUN_TYPES.RunState.START_CAMP,
		RUN_TYPES.RunState.STARTER_TREASURE_SELECT,
		RUN_TYPES.RunState.BRANCH_SELECT,
		RUN_TYPES.RunState.SHOP_NODE,
		RUN_TYPES.RunState.SUPPLY_NODE,
		RUN_TYPES.RunState.GOLD_NODE,
		RUN_TYPES.RunState.SYNTHESIS_CHECK,
		RUN_TYPES.RunState.FORMATION_EDIT,
		RUN_TYPES.RunState.COMBAT_BRANCH_SELECT,
		RUN_TYPES.RunState.COMBAT,
		RUN_TYPES.RunState.COMBAT_RESULT,
		RUN_TYPES.RunState.BOSS_INTRO,
		RUN_TYPES.RunState.BOSS_COMBAT,
		RUN_TYPES.RunState.RUN_VICTORY,
		RUN_TYPES.RunState.RUN_DEFEAT,
	]
	var index: int = 0
	while index < states.size():
		run_manager.change_state(states[index])
		var contract: Dictionary = run_manager.get_display_contract()
		_check(contract.get("page_type", -1) != -1, "关键状态 page_type 非明显错误: %d" % states[index])
		if _is_run_board_state(states[index]):
			_check(contract.get("run_board_mode", RUN_TYPES.RunBoardMode.NONE) != RUN_TYPES.RunBoardMode.NONE, "RunBoard 状态 mode 非 NONE: %d" % states[index])
		index += 1


func _check_boss_unlock_branch_generation() -> void:
	var run_manager = RUN_MANAGER.new()
	run_manager.start_new_run_requested()
	run_manager.select_character(run_manager.character_data.character_id)
	run_manager.init_run_values()
	run_manager.debug_force_normal_win_count(run_manager.normal_win_target)
	var options: Array = run_manager.generate_combat_branch_options()
	_check(run_manager.current_state == RUN_TYPES.RunState.BOSS_INTRO, "达标后生成战斗分支进入 BOSS_INTRO")
	_check(options.size() == 1 and options[0].get("combat_branch_id", "") == "boss_final", "达标后不再生成普通战分支")


func _footprint_matches(treasure) -> bool:
	var footprint: Dictionary = size_config.get_footprint(treasure.size_type)
	return treasure.footprint_width == footprint.get("width", -1) and treasure.footprint_height == footprint.get("height", -1)


func _ids_unique(ids: Array) -> bool:
	var seen: Dictionary = {}
	var index: int = 0
	while index < ids.size():
		var id: String = ids[index]
		if id == "" or seen.has(id):
			return false
		seen[id] = true
		index += 1

	return true


func _is_run_board_state(state: int) -> bool:
	match state:
		RUN_TYPES.RunState.BRANCH_SELECT, RUN_TYPES.RunState.SHOP_NODE, RUN_TYPES.RunState.SUPPLY_NODE, RUN_TYPES.RunState.GOLD_NODE:
			return true
		RUN_TYPES.RunState.SYNTHESIS_CHECK, RUN_TYPES.RunState.FORMATION_EDIT, RUN_TYPES.RunState.COMBAT_BRANCH_SELECT:
			return true
		RUN_TYPES.RunState.COMBAT, RUN_TYPES.RunState.COMBAT_RESULT, RUN_TYPES.RunState.BOSS_INTRO, RUN_TYPES.RunState.BOSS_COMBAT:
			return true
		_:
			return false


func _check(ok: bool, label: String) -> void:
	if ok:
		print("[PASS] ", label)
	else:
		fail_count += 1
		print("[FAIL] ", label)
