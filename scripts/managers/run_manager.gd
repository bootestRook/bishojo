extends RefCounted
class_name RunManager

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const V1_CHARACTER_DATA = preload("res://scripts/data/v1_character_data.gd")
const V1_INITIAL_RUN_CONFIG = preload("res://scripts/data/v1_initial_run_config.gd")
const V1_STARTER_TREASURE_OPTIONS = preload("res://scripts/data/v1_starter_treasure_options.gd")
const V1_BALANCE_CONFIG = preload("res://scripts/data/balance/v1_balance_config.gd")
const V1_COMBAT_BRANCH_CONFIG = preload("res://scripts/data/battle/v1_combat_branch_config.gd")
const V1_TREASURE_CATALOG = preload("res://scripts/data/treasure/v1_treasure_catalog.gd")
const V1_RARITY_CONFIG = preload("res://scripts/data/treasure/v1_rarity_config.gd")
const INVENTORY_MODEL = preload("res://scripts/systems/inventory/inventory_model.gd")
const FORMATION_MODEL = preload("res://scripts/systems/formation/formation_model.gd")
const BRANCH_MANAGER = preload("res://scripts/systems/branch/branch_manager.gd")
const NODE_CHOICE_MANAGER = preload("res://scripts/systems/node_choice/node_choice_manager.gd")
const SHOP_MANAGER = preload("res://scripts/systems/shop/shop_manager.gd")
const SYNTHESIS_RESOLVER = preload("res://scripts/systems/synthesis/synthesis_resolver.gd")
const BATTLE_MANAGER = preload("res://scripts/systems/battle/battle_manager.gd")
const V1_ENEMY_CATALOG = preload("res://scripts/data/enemies/v1_enemy_catalog.gd")
const REWARD_MANAGER = preload("res://scripts/systems/reward/reward_manager.gd")

# 文件职责：
# - 管理一局 Run 的核心流程状态和最小运行数据骨架。
# - 为后续 UI 层提供“当前应显示哪个 Page / RunBoardMode”的只读契约数据。
# - 本阶段接入纯逻辑战斗门面，但不接入场景、节点、Autoload、输入动作或表现层 Manager。

const STATE_UNSET: int = -1
const PAGE_TYPE_UNSET: int = -1
const DEFAULT_RUN_DURABILITY_MAX: int = 5
const DEFAULT_NORMAL_WIN_TARGET: int = 10

var character_data = V1_CHARACTER_DATA.new()
var initial_run_config = V1_INITIAL_RUN_CONFIG.new()
var starter_treasure_data = V1_STARTER_TREASURE_OPTIONS.new()
var v1_balance_config = V1_BALANCE_CONFIG.new()
var v1_combat_branch_config = V1_COMBAT_BRANCH_CONFIG.new()
var treasure_catalog = V1_TREASURE_CATALOG.new()
var rarity_config = V1_RARITY_CONFIG.new()
var inventory_model = INVENTORY_MODEL.new()
var formation_model = FORMATION_MODEL.new()
var branch_manager = BRANCH_MANAGER.new()
var node_choice_manager = NODE_CHOICE_MANAGER.new()
var shop_manager = SHOP_MANAGER.new()
var synthesis_resolver = SYNTHESIS_RESOLVER.new()
var battle_manager = BATTLE_MANAGER.new()
var enemy_catalog = V1_ENEMY_CATALOG.new()
var reward_manager = REWARD_MANAGER.new()

var current_state: int = RUN_TYPES.RunState.BOOT
var current_page_type: int = PAGE_TYPE_UNSET
var current_run_board_mode: int = RUN_TYPES.RunBoardMode.NONE
var state_history: Array = []

# Run 级基础数据。初始金币等 V1 原型占位数值由 V1BalanceConfig 统一提供。
var selected_character_id: String = ""
var selected_starter_treasure_id: String = ""
var gold: int = 0
var run_durability_max: int = 0
var run_durability: int = 0
var normal_win_target: int = 0
var normal_win_count: int = 0
var starter_treasure_options: Array = []
var current_branch_options: Array = []
var current_node_choices: Array = []
var current_shop_stock: Array = []
var last_node_choice_result: Dictionary = {}
var last_shop_result: Dictionary = {}
var last_formation_validation: Dictionary = {}
var current_combat_branch_options: Array = []
var current_combat_branch_id: String = ""
var last_battle_result: Dictionary = {}
var last_battle_timeline_log: Array = []
var last_reward_results: Array = []
var current_reward_options: Array = []
var last_combat_resolution: Dictionary = {}
var battle_seed: int = 1001
var debug_run_seed: int = 0

# 当前流程临时数据。字符串取值会在后续数据配置阶段统一收口，当前只保留承接字段。
var current_branch_id: String = ""
var current_branch_type: String = ""
var current_battle_type: String = ""
var last_combat_result: String = ""
var defeat_reason: String = ""
var next_state_after_result: int = STATE_UNSET

# 早期骨架兼容字段。真实背包、商店、合成、回路与战斗数据已由纯逻辑模型接管。
var inventory_items: Array = []
var formation_units: Dictionary = {}
var locked_shop_stock: Array = []
var pending_node_choices: Array = []
var pending_rewards: Array = []
var last_synthesis_results: Array = []


func boot_to_main_menu() -> void:
	change_state(RUN_TYPES.RunState.MAIN_MENU)


func change_state(next_state: int) -> void:
	current_state = next_state
	state_history.append(next_state)
	_sync_view_contract_for_state(next_state)


func reset_run_data() -> void:
	v1_balance_config = V1_BALANCE_CONFIG.new()
	v1_combat_branch_config = V1_COMBAT_BRANCH_CONFIG.new()
	inventory_model = INVENTORY_MODEL.new()
	formation_model = FORMATION_MODEL.new()
	formation_model.setup_grid()
	branch_manager = BRANCH_MANAGER.new()
	node_choice_manager = NODE_CHOICE_MANAGER.new()
	shop_manager = SHOP_MANAGER.new()
	synthesis_resolver = SYNTHESIS_RESOLVER.new()
	battle_manager = BATTLE_MANAGER.new()
	enemy_catalog = V1_ENEMY_CATALOG.new()
	reward_manager = REWARD_MANAGER.new()
	reward_manager.balance_config = v1_balance_config
	selected_character_id = ""
	selected_starter_treasure_id = ""
	gold = 0
	run_durability_max = 0
	run_durability = 0
	normal_win_target = 0
	normal_win_count = 0
	starter_treasure_options = []
	current_branch_options = []
	current_node_choices = []
	current_shop_stock = []
	last_node_choice_result = {}
	last_shop_result = {}
	last_formation_validation = {}
	current_combat_branch_options = []
	current_combat_branch_id = ""
	last_battle_result = {}
	last_battle_timeline_log = []
	last_reward_results = []
	current_reward_options = []
	last_combat_resolution = {}
	battle_seed = v1_balance_config.debug_battle_seed_base
	debug_run_seed = v1_balance_config.debug_run_seed
	current_branch_id = ""
	current_branch_type = ""
	current_battle_type = ""
	last_combat_result = ""
	defeat_reason = ""
	next_state_after_result = STATE_UNSET
	state_history = []
	# 以下旧容器仅作为早期骨架兼容字段保留；真实实例和回路数据从本轮开始由 inventory_model / formation_model 管理。
	inventory_items = []
	formation_units = {}
	locked_shop_stock = []
	pending_node_choices = []
	pending_rewards = []
	last_synthesis_results = []


func start_new_run_requested() -> Dictionary:
	reset_run_data()
	change_state(RUN_TYPES.RunState.START_NEW_RUN)
	change_state(RUN_TYPES.RunState.CHARACTER_SELECT)
	return {"ok": true, "reason": "ok", "state": current_state}


func request_start_new_run() -> void:
	start_new_run_requested()


func finish_start_new_run() -> void:
	change_state(RUN_TYPES.RunState.CHARACTER_SELECT)


func select_character(character_id: String) -> bool:
	if character_id != character_data.character_id:
		return false

	selected_character_id = character_id
	change_state(RUN_TYPES.RunState.RUN_INIT)
	return true


func confirm_character(character_id: String) -> void:
	select_character(character_id)


func init_run_values() -> Dictionary:
	initial_run_config.initial_gold = v1_balance_config.initial_gold
	gold = v1_balance_config.initial_gold
	run_durability = initial_run_config.run_durability
	run_durability_max = initial_run_config.run_durability_max
	normal_win_count = initial_run_config.normal_win_count
	normal_win_target = initial_run_config.normal_win_target
	starter_treasure_options = starter_treasure_data.get_treasure_ids()
	battle_seed = v1_balance_config.debug_battle_seed_base
	debug_run_seed = v1_balance_config.debug_run_seed
	change_state(RUN_TYPES.RunState.START_CAMP)
	return {
		"ok": true,
		"reason": "ok",
		"state": current_state,
		"initial_gold": gold,
		"run_durability": run_durability,
		"run_durability_max": run_durability_max,
		"normal_win_count": normal_win_count,
		"normal_win_target": normal_win_target,
	}


func finish_run_init() -> void:
	init_run_values()


func get_starter_treasure_options() -> Array:
	if starter_treasure_options.is_empty():
		starter_treasure_options = starter_treasure_data.get_treasure_ids()

	change_state(RUN_TYPES.RunState.STARTER_TREASURE_SELECT)
	return starter_treasure_options.duplicate()


func request_starter_treasure_select() -> void:
	get_starter_treasure_options()


func select_starter_treasure(treasure_id: String) -> bool:
	if treasure_id not in starter_treasure_options:
		return false

	selected_starter_treasure_id = treasure_id
	inventory_model.add_treasure(treasure_id, "green", "starter_camp")
	change_state(RUN_TYPES.RunState.BRANCH_SELECT)
	return true


func confirm_starter_treasure(treasure_id: String) -> void:
	select_starter_treasure(treasure_id)


func record_selected_branch(branch_id: String, branch_type: String) -> void:
	current_branch_id = branch_id
	current_branch_type = branch_type
	change_state(RUN_TYPES.RunState.BRANCH_RESOLVE)


func generate_branch_options() -> Array:
	current_branch_options = branch_manager.generate_branch_options(self)
	change_state(RUN_TYPES.RunState.BRANCH_SELECT)
	return current_branch_options.duplicate()


func select_branch(branch_id: String) -> bool:
	var option = branch_manager.get_option(branch_id)
	if option == null:
		return false

	current_branch_id = branch_id
	current_branch_type = option.branch_type
	change_state(RUN_TYPES.RunState.BRANCH_RESOLVE)
	match option.branch_type:
		"shop":
			enter_shop_node()
		"supply":
			change_state(RUN_TYPES.RunState.SUPPLY_NODE)
		"gold":
			change_state(RUN_TYPES.RunState.GOLD_NODE)
		_:
			return false

	return true


func enter_shop_node() -> void:
	current_shop_stock = shop_manager.prepare_stock(treasure_catalog, current_shop_stock)
	change_state(RUN_TYPES.RunState.SHOP_NODE)


func get_current_node_choices() -> Array:
	if current_state == RUN_TYPES.RunState.SUPPLY_NODE:
		current_node_choices = node_choice_manager.generate_choices("supply", self)
	elif current_state == RUN_TYPES.RunState.GOLD_NODE:
		current_node_choices = node_choice_manager.generate_choices("gold", self)
	else:
		current_node_choices = []

	return current_node_choices.duplicate()


func apply_node_choice(option_id: String) -> Dictionary:
	var option = node_choice_manager.get_choice(option_id)
	last_node_choice_result = node_choice_manager.apply_choice(option, self)
	if last_node_choice_result.get("ok", false):
		change_state(RUN_TYPES.RunState.SYNTHESIS_CHECK)

	return last_node_choice_result.duplicate(true)


func shop_buy_item(shop_item_id: String) -> Dictionary:
	last_shop_result = shop_manager.buy_item(shop_item_id, self, inventory_model)
	return last_shop_result.duplicate(true)


func shop_refresh() -> Dictionary:
	last_shop_result = shop_manager.refresh_shop(self, treasure_catalog)
	if last_shop_result.get("ok", false):
		current_shop_stock = last_shop_result.get("stock", [])

	return last_shop_result.duplicate(true)


func shop_toggle_lock() -> bool:
	return shop_manager.toggle_lock()


func shop_sell_instance(instance_id: String) -> Dictionary:
	last_shop_result = shop_manager.sell_instance(instance_id, self, inventory_model, formation_model, treasure_catalog)
	return last_shop_result.duplicate(true)


func shop_leave_requested() -> void:
	shop_manager.leave_shop()
	current_shop_stock = shop_manager.current_stock
	change_state(RUN_TYPES.RunState.SYNTHESIS_CHECK)


func enter_supply_node() -> void:
	change_state(RUN_TYPES.RunState.SUPPLY_NODE)


func enter_gold_node() -> void:
	change_state(RUN_TYPES.RunState.GOLD_NODE)


func finish_branch_node() -> void:
	change_state(RUN_TYPES.RunState.SYNTHESIS_CHECK)


func run_synthesis_check() -> Array:
	last_synthesis_results = synthesis_resolver.check_and_apply(inventory_model, formation_model, rarity_config)
	enter_formation_edit()
	return last_synthesis_results.duplicate(true)


func enter_formation_edit() -> void:
	formation_model.apply_unlocks(normal_win_count)
	change_state(RUN_TYPES.RunState.FORMATION_EDIT)


func finish_synthesis_check() -> void:
	run_synthesis_check()


func formation_place_instance(instance_id: String, anchor_slot_id: String) -> Dictionary:
	var instance = inventory_model.get_instance(instance_id)
	if instance == null:
		return {"ok": false, "reason": "instance_not_found", "required_slot_ids": []}

	var treasure_data = treasure_catalog.get_treasure_data(instance.treasure_id, instance.rarity)
	var result: Dictionary = formation_model.can_place(instance_id, treasure_data, anchor_slot_id)
	if not result.get("ok", false):
		return result

	formation_model.place_instance(instance_id, treasure_data, anchor_slot_id)
	instance.is_in_inventory = false
	instance.is_in_formation = true
	instance.placed_order = formation_model.get_first_slot_sort_value(instance_id)
	return result


func formation_remove_instance(instance_id: String) -> bool:
	var instance = inventory_model.get_instance(instance_id)
	if instance == null:
		return false

	var removed: bool = formation_model.remove_instance(instance_id)
	if removed:
		instance.is_in_inventory = true
		instance.is_in_formation = false
		instance.placed_order = -1

	return removed


func formation_move_instance(instance_id: String, anchor_slot_id: String) -> Dictionary:
	var instance = inventory_model.get_instance(instance_id)
	if instance == null:
		return {"ok": false, "reason": "instance_not_found", "required_slot_ids": []}

	var treasure_data = treasure_catalog.get_treasure_data(instance.treasure_id, instance.rarity)
	var result: Dictionary = formation_model.can_place(instance_id, treasure_data, anchor_slot_id)
	if not result.get("ok", false):
		return result

	formation_model.place_instance(instance_id, treasure_data, anchor_slot_id)
	instance.is_in_inventory = false
	instance.is_in_formation = true
	instance.placed_order = formation_model.get_first_slot_sort_value(instance_id)
	return result


func validate_formation() -> Dictionary:
	last_formation_validation = formation_model.validate_formation()
	return last_formation_validation.duplicate(true)


func confirm_formation() -> Dictionary:
	var result: Dictionary = validate_formation()
	if result.get("ok", false):
		change_state(RUN_TYPES.RunState.COMBAT_BRANCH_SELECT)
		result["state"] = current_state
	else:
		result["state"] = current_state

	return result.duplicate(true)


func generate_combat_branch_options() -> Array:
	current_combat_branch_options = []
	if v1_combat_branch_config.is_boss_unlocked(normal_win_count, normal_win_target):
		current_combat_branch_options.append(v1_combat_branch_config.get_boss_option())
		change_state(RUN_TYPES.RunState.BOSS_INTRO)
		return current_combat_branch_options.duplicate(true)

	current_combat_branch_options = v1_combat_branch_config.get_normal_combat_options(normal_win_count)
	change_state(RUN_TYPES.RunState.COMBAT_BRANCH_SELECT)
	return current_combat_branch_options.duplicate(true)


func select_combat_branch(combat_branch_id: String) -> bool:
	var requested_id: String = combat_branch_id
	if requested_id == "boss":
		requested_id = "boss_final"

	var option: Dictionary = _get_combat_branch_option(requested_id)
	if option.is_empty():
		return false

	current_combat_branch_id = requested_id
	current_battle_type = option.get("battle_type", "normal_safe")
	if current_battle_type == "boss":
		change_state(RUN_TYPES.RunState.BOSS_COMBAT)
	else:
		change_state(RUN_TYPES.RunState.COMBAT)
	return true


func start_current_combat() -> Dictionary:
	if current_state != RUN_TYPES.RunState.COMBAT and current_state != RUN_TYPES.RunState.BOSS_COMBAT:
		return {"ok": false, "reason": "invalid_state", "state": current_state}
	if current_battle_type == "":
		return {"ok": false, "reason": "battle_type_unset", "state": current_state}

	battle_seed += 1
	if current_battle_type == "boss":
		last_battle_result = battle_manager.start_boss_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_seed)
	else:
		last_battle_result = battle_manager.start_normal_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, current_battle_type, battle_seed)

	last_combat_result = last_battle_result.get("result", "")
	last_battle_timeline_log = battle_manager.get_last_timeline_log()
	change_state(RUN_TYPES.RunState.COMBAT_RESULT)
	last_battle_result["ok"] = true
	last_battle_result["combat_branch_id"] = current_combat_branch_id
	return last_battle_result.duplicate(true)


func resolve_combat_result() -> Dictionary:
	if last_combat_result == "":
		last_combat_resolution = {"ok": false, "reason": "combat_result_unset", "state": current_state}
		return last_combat_resolution.duplicate(true)

	if current_battle_type == "boss":
		if last_combat_result == "win":
			current_reward_options = reward_manager.generate_post_battle_rewards(self, current_battle_type, current_combat_branch_id)
			var boss_reward_result: Dictionary = reward_manager.grant_combat_reward(self, current_battle_type, current_combat_branch_id)
			last_reward_results.append(boss_reward_result)
			next_state_after_result = RUN_TYPES.RunState.RUN_VICTORY
		else:
			defeat_reason = "boss_lose"
			next_state_after_result = RUN_TYPES.RunState.RUN_DEFEAT
		last_combat_resolution = _make_combat_resolution_result()
		return last_combat_resolution.duplicate(true)

	if last_combat_result == "win":
		normal_win_count += 1
		current_reward_options = reward_manager.generate_post_battle_rewards(self, current_battle_type, current_combat_branch_id)
		var reward_result: Dictionary = reward_manager.grant_combat_reward(self, current_battle_type, current_combat_branch_id)
		last_reward_results.append(reward_result)
		if normal_win_count >= normal_win_target:
			next_state_after_result = RUN_TYPES.RunState.BOSS_INTRO
		else:
			next_state_after_result = RUN_TYPES.RunState.BRANCH_SELECT
	else:
		run_durability -= 1
		if run_durability <= 0:
			defeat_reason = "durability_zero"
			next_state_after_result = RUN_TYPES.RunState.RUN_DEFEAT
		else:
			next_state_after_result = RUN_TYPES.RunState.BRANCH_SELECT

	last_combat_resolution = _make_combat_resolution_result()
	return last_combat_resolution.duplicate(true)


func enter_boss_combat_requested() -> Dictionary:
	current_combat_branch_options = [v1_combat_branch_config.get_boss_option()]
	var ok: bool = select_combat_branch("boss_final")
	return {"ok": ok, "reason": "ok" if ok else "boss_option_not_found", "state": current_state}


func record_selected_combat_branch(battle_type: String) -> void:
	current_battle_type = battle_type
	change_state(RUN_TYPES.RunState.COMBAT)


func record_combat_result(battle_type: String, result: String) -> void:
	current_battle_type = battle_type
	last_combat_result = result
	change_state(RUN_TYPES.RunState.COMBAT_RESULT)


func set_next_state_after_result(next_state: int) -> void:
	# 后续战斗结算阶段会根据普通战胜负、Boss 胜负、耐久与胜场目标写入该字段。
	next_state_after_result = next_state


func confirm_combat_result() -> Dictionary:
	if next_state_after_result == STATE_UNSET:
		return {"ok": false, "reason": "next_state_unset", "state": current_state}

	change_state(next_state_after_result)
	return {"ok": true, "reason": "ok", "state": current_state}


func debug_grant_treasure(treasure_id: String, rarity: String = "green", source_type: String = "debug") -> Dictionary:
	# 调试边界：只供 smoke test 和纯逻辑驱动搭建构筑输入，不代表正式奖励入口。
	var result: Dictionary = reward_manager.grant_treasure(self, treasure_id, rarity, source_type)
	last_reward_results.append(result)
	return result.duplicate(true)


func debug_force_normal_win_count(value: int) -> void:
	# 调试边界：用于验证 Boss 解锁和终局路由，不从正式流程直接调用。
	normal_win_count = value


func debug_force_run_durability(value: int) -> void:
	# 调试边界：用于构造耐久归零失败分支。
	run_durability = value


func debug_find_instance_id(treasure_id: String, rarity: String = "green") -> String:
	# 调试边界：驱动层需要通过 RunManager 取得实例 id 后再调用公开放置接口。
	var instances: Array = inventory_model.get_all_instances()
	var index: int = 0
	while index < instances.size():
		if instances[index].treasure_id == treasure_id and instances[index].rarity == rarity:
			return instances[index].instance_id
		index += 1

	return ""


func debug_find_instance_ids(treasure_id: String, rarity: String = "green") -> Array:
	# 调试边界：只用于 smoke test 验证合成、重复奖励等纯逻辑结果。
	var result: Array = []
	var instances: Array = inventory_model.get_all_instances()
	var index: int = 0
	while index < instances.size():
		if instances[index].treasure_id == treasure_id and instances[index].rarity == rarity:
			result.append(instances[index].instance_id)
		index += 1

	return result


func debug_clear_formation() -> void:
	# 调试边界：用于快速构造空阵、弱阵和 Boss 失败分支；正式回路编辑仍应逐个移除。
	var instances: Array = inventory_model.get_formation_instances()
	var index: int = 0
	while index < instances.size():
		formation_remove_instance(instances[index].instance_id)
		index += 1


func get_run_summary() -> Dictionary:
	# UI adapter：聚合顶部状态栏和调试文本所需的只读 Run 摘要，避免 UI 深入读取多个模型。
	return {
		"state": current_state,
		"state_name": get_run_state_name(current_state),
		"page_type": current_page_type,
		"page_type_name": get_page_type_name(current_page_type),
		"run_board_mode": current_run_board_mode,
		"run_board_mode_name": get_run_board_mode_name(current_run_board_mode),
		"gold": gold,
		"run_durability": run_durability,
		"run_durability_max": run_durability_max,
		"normal_win_count": normal_win_count,
		"normal_win_target": normal_win_target,
		"selected_character_id": selected_character_id,
		"selected_starter_treasure_id": selected_starter_treasure_id,
		"current_branch_id": current_branch_id,
		"current_branch_type": current_branch_type,
		"current_battle_type": current_battle_type,
		"current_combat_branch_id": current_combat_branch_id,
		"last_combat_result": last_combat_result,
		"defeat_reason": defeat_reason,
		"next_state": next_state_after_result,
		"next_state_name": get_run_state_name(next_state_after_result),
		"inventory_count": inventory_model.get_all_instances().size(),
		"formation_count": inventory_model.get_formation_instances().size(),
	}


func get_character_display_data() -> Dictionary:
	# UI adapter：V1 只有一个默认角色，但页面仍通过结构化数据读取，便于后续扩展多角色。
	return {
		"character_id": character_data.character_id,
		"character_name": character_data.character_name,
		"character_description": character_data.character_description,
		"character_ability_id": character_data.character_ability_id,
		"character_ability_enabled": character_data.character_ability_enabled,
	}


func get_starter_treasure_display_data() -> Array:
	if starter_treasure_options.is_empty():
		starter_treasure_options = starter_treasure_data.get_treasure_ids()

	var result: Array = []
	var index: int = 0
	while index < starter_treasure_options.size():
		result.append(get_card_detail_display_data(starter_treasure_options[index], "green"))
		index += 1

	return result


func get_inventory_display_data() -> Array:
	var result: Array = []
	var instances: Array = inventory_model.get_all_instances()
	var index: int = 0
	while index < instances.size():
		result.append(_make_instance_display_data(instances[index]))
		index += 1

	return result


func get_formation_display_data() -> Dictionary:
	var slot_data: Array = []
	var slots: Array = formation_model.get_all_slots()
	var index: int = 0
	while index < slots.size():
		var slot = slots[index]
		var occupant: Dictionary = {}
		if slot.occupant_instance_id != "":
			var instance = inventory_model.get_instance(slot.occupant_instance_id)
			if instance != null:
				occupant = _make_instance_display_data(instance)
		slot_data.append({
			"slot_id": slot.slot_id,
			"row": slot.row,
			"column": slot.column,
			"is_unlocked": slot.is_unlocked,
			"is_occupied": slot.is_occupied(),
			"occupant_instance_id": slot.occupant_instance_id,
			"occupant": occupant,
		})
		index += 1

	return {
		"row_count": formation_model.row_count,
		"column_count": formation_model.column_count,
		"slots": slot_data,
		"validation": validate_formation(),
	}


func get_shop_display_data() -> Dictionary:
	var item_data: Array = []
	var index: int = 0
	while index < current_shop_stock.size():
		var item = current_shop_stock[index]
		var treasure: Dictionary = get_card_detail_display_data(item.treasure_id, item.rarity)
		item_data.append({
			"shop_item_id": item.shop_item_id,
			"treasure_id": item.treasure_id,
			"rarity": item.rarity,
			"price": item.price,
			"is_sold": item.is_sold,
			"treasure": treasure,
		})
		index += 1

	return {
		"gold": gold,
		"items": item_data,
		"refresh_cost": shop_manager.config.refresh_cost,
		"is_locked": shop_manager.is_locked,
		"last_shop_result": last_shop_result.duplicate(true),
	}


func get_branch_display_data() -> Array:
	if current_branch_options.is_empty() and current_state == RUN_TYPES.RunState.BRANCH_SELECT:
		current_branch_options = branch_manager.generate_branch_options(self)

	var result: Array = []
	var index: int = 0
	while index < current_branch_options.size():
		var option = current_branch_options[index]
		result.append({
			"branch_id": option.branch_id,
			"branch_type": option.branch_type,
			"branch_type_text": _branch_type_text(option.branch_type),
			"title": option.title,
			"description": option.description,
			"weight": option.weight,
			"payload": option.payload.duplicate(true),
		})
		index += 1

	return result


func get_node_choice_display_data() -> Array:
	if current_node_choices.is_empty():
		get_current_node_choices()

	var result: Array = []
	var index: int = 0
	while index < current_node_choices.size():
		var option = current_node_choices[index]
		result.append({
			"option_id": option.option_id,
			"node_type": option.node_type,
			"node_type_text": _node_type_text(option.node_type),
			"option_type": option.option_type,
			"option_type_text": _option_type_text(option.option_type),
			"title": option.title,
			"description": option.description,
			"payload": option.payload.duplicate(true),
			"reward_text": _format_payload_reward(option.payload),
			"weight": option.weight,
			"can_skip": option.can_skip,
		})
		index += 1

	return result


func get_combat_branch_display_data() -> Array:
	if current_combat_branch_options.is_empty() and (current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT or current_state == RUN_TYPES.RunState.BOSS_INTRO):
		generate_combat_branch_options()

	var result: Array = []
	var index: int = 0
	while index < current_combat_branch_options.size():
		var option: Dictionary = current_combat_branch_options[index].duplicate(true)
		var enemy = enemy_catalog.get_enemy_data(option.get("enemy_id", ""))
		option["battle_type_text"] = _battle_type_text(option.get("battle_type", ""))
		option["reward_profile_text"] = _reward_profile_text(option.get("reward_profile", ""))
		option["enemy_name"] = enemy.enemy_name if enemy != null else "未知敌人"
		result.append(option)
		index += 1

	return result


func get_last_battle_summary() -> Dictionary:
	var result: Dictionary = last_battle_result.duplicate(true)
	result["battle_type"] = current_battle_type
	result["combat_branch_id"] = current_combat_branch_id
	result["combat_result"] = last_combat_result
	result["timeline_count"] = last_battle_timeline_log.size()
	return result


func get_last_timeline_log(limit: int = 30) -> Array:
	var result: Array = []
	var total: int = last_battle_timeline_log.size()
	var start_index: int = 0
	if limit > 0 and total > limit:
		start_index = total - limit

	var index: int = start_index
	while index < total:
		var entry = last_battle_timeline_log[index]
		result.append(entry.to_data())
		index += 1

	return result


func get_last_reward_results() -> Array:
	return last_reward_results.duplicate(true)


func get_last_synthesis_results() -> Array:
	return last_synthesis_results.duplicate(true)


func get_victory_summary() -> Dictionary:
	return {
		"title": "整局胜利",
		"normal_win_count": normal_win_count,
		"normal_win_target": normal_win_target,
		"gold": gold,
		"formation": get_formation_display_data(),
	}


func get_defeat_summary() -> Dictionary:
	return {
		"title": "整局失败",
		"defeat_reason": defeat_reason,
		"defeat_reason_text": _defeat_reason_text(defeat_reason),
		"normal_win_count": normal_win_count,
		"normal_win_target": normal_win_target,
		"gold": gold,
		"formation": get_formation_display_data(),
	}


func get_card_detail_display_data(treasure_id: String, rarity: String = "green") -> Dictionary:
	var treasure = treasure_catalog.get_treasure_data(treasure_id, rarity)
	if treasure == null:
		return {
			"treasure_id": treasure_id,
			"rarity": rarity,
			"exists": false,
		}

	return _make_treasure_display_data(treasure)


func get_run_state_name(state: int) -> String:
	match state:
		STATE_UNSET:
			return "UNSET"
		RUN_TYPES.RunState.BOOT:
			return "BOOT"
		RUN_TYPES.RunState.MAIN_MENU:
			return "MAIN_MENU"
		RUN_TYPES.RunState.START_NEW_RUN:
			return "START_NEW_RUN"
		RUN_TYPES.RunState.CHARACTER_SELECT:
			return "CHARACTER_SELECT"
		RUN_TYPES.RunState.RUN_INIT:
			return "RUN_INIT"
		RUN_TYPES.RunState.START_CAMP:
			return "START_CAMP"
		RUN_TYPES.RunState.STARTER_TREASURE_SELECT:
			return "STARTER_TREASURE_SELECT"
		RUN_TYPES.RunState.BRANCH_SELECT:
			return "BRANCH_SELECT"
		RUN_TYPES.RunState.BRANCH_RESOLVE:
			return "BRANCH_RESOLVE"
		RUN_TYPES.RunState.SHOP_NODE:
			return "SHOP_NODE"
		RUN_TYPES.RunState.SUPPLY_NODE:
			return "SUPPLY_NODE"
		RUN_TYPES.RunState.GOLD_NODE:
			return "GOLD_NODE"
		RUN_TYPES.RunState.SYNTHESIS_CHECK:
			return "SYNTHESIS_CHECK"
		RUN_TYPES.RunState.FORMATION_EDIT:
			return "FORMATION_EDIT"
		RUN_TYPES.RunState.COMBAT_BRANCH_SELECT:
			return "COMBAT_BRANCH_SELECT"
		RUN_TYPES.RunState.COMBAT:
			return "COMBAT"
		RUN_TYPES.RunState.COMBAT_RESULT:
			return "COMBAT_RESULT"
		RUN_TYPES.RunState.BOSS_INTRO:
			return "BOSS_INTRO"
		RUN_TYPES.RunState.BOSS_COMBAT:
			return "BOSS_COMBAT"
		RUN_TYPES.RunState.RUN_VICTORY:
			return "RUN_VICTORY"
		RUN_TYPES.RunState.RUN_DEFEAT:
			return "RUN_DEFEAT"
		_:
			return "UNKNOWN_%d" % state


func get_page_type_name(page_type: int) -> String:
	match page_type:
		PAGE_TYPE_UNSET:
			return "UNSET"
		RUN_TYPES.PageType.MAIN_MENU_PAGE:
			return "MAIN_MENU_PAGE"
		RUN_TYPES.PageType.CHARACTER_SELECT_PAGE:
			return "CHARACTER_SELECT_PAGE"
		RUN_TYPES.PageType.START_CAMP_PAGE:
			return "START_CAMP_PAGE"
		RUN_TYPES.PageType.RUN_BOARD_PAGE:
			return "RUN_BOARD_PAGE"
		RUN_TYPES.PageType.RUN_VICTORY_PAGE:
			return "RUN_VICTORY_PAGE"
		RUN_TYPES.PageType.RUN_DEFEAT_PAGE:
			return "RUN_DEFEAT_PAGE"
		RUN_TYPES.PageType.SETTINGS_PAGE:
			return "SETTINGS_PAGE"
		RUN_TYPES.PageType.COLLECTION_PAGE:
			return "COLLECTION_PAGE"
		RUN_TYPES.PageType.HELP_PAGE:
			return "HELP_PAGE"
		RUN_TYPES.PageType.DEBUG_PAGE:
			return "DEBUG_PAGE"
		RUN_TYPES.PageType.BAG_PAGE:
			return "BAG_PAGE"
		_:
			return "UNKNOWN_%d" % page_type


func get_run_board_mode_name(mode: int) -> String:
	match mode:
		RUN_TYPES.RunBoardMode.NONE:
			return "NONE"
		RUN_TYPES.RunBoardMode.BRANCH_SELECT:
			return "BRANCH_SELECT"
		RUN_TYPES.RunBoardMode.SHOP:
			return "SHOP"
		RUN_TYPES.RunBoardMode.GENERIC_NODE_CHOICE:
			return "GENERIC_NODE_CHOICE"
		RUN_TYPES.RunBoardMode.SYNTHESIS_ANIMATION:
			return "SYNTHESIS_ANIMATION"
		RUN_TYPES.RunBoardMode.FORMATION_EDIT:
			return "FORMATION_EDIT"
		RUN_TYPES.RunBoardMode.COMBAT_BRANCH_SELECT:
			return "COMBAT_BRANCH_SELECT"
		RUN_TYPES.RunBoardMode.COMBAT:
			return "COMBAT"
		RUN_TYPES.RunBoardMode.COMBAT_RESULT:
			return "COMBAT_RESULT"
		RUN_TYPES.RunBoardMode.REWARD_SELECT:
			return "REWARD_SELECT"
		RUN_TYPES.RunBoardMode.BOSS_INTRO:
			return "BOSS_INTRO"
		_:
			return "UNKNOWN_%d" % mode


func get_display_contract() -> Dictionary:
	return {
		"state": current_state,
		"page_type": current_page_type,
		"run_board_mode": current_run_board_mode,
	}


func get_state_history() -> Array:
	return state_history.duplicate()


func _sync_view_contract_for_state(state: int) -> void:
	current_page_type = PAGE_TYPE_UNSET
	current_run_board_mode = RUN_TYPES.RunBoardMode.NONE

	match state:
		RUN_TYPES.RunState.MAIN_MENU:
			current_page_type = RUN_TYPES.PageType.MAIN_MENU_PAGE
		RUN_TYPES.RunState.CHARACTER_SELECT:
			current_page_type = RUN_TYPES.PageType.CHARACTER_SELECT_PAGE
		RUN_TYPES.RunState.START_CAMP, RUN_TYPES.RunState.STARTER_TREASURE_SELECT:
			current_page_type = RUN_TYPES.PageType.START_CAMP_PAGE
		RUN_TYPES.RunState.BRANCH_SELECT:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.BRANCH_SELECT
		RUN_TYPES.RunState.SHOP_NODE:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.SHOP
		RUN_TYPES.RunState.SUPPLY_NODE, RUN_TYPES.RunState.GOLD_NODE:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.GENERIC_NODE_CHOICE
		RUN_TYPES.RunState.SYNTHESIS_CHECK:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.SYNTHESIS_ANIMATION
		RUN_TYPES.RunState.FORMATION_EDIT:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.FORMATION_EDIT
		RUN_TYPES.RunState.COMBAT_BRANCH_SELECT:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.COMBAT_BRANCH_SELECT
		RUN_TYPES.RunState.COMBAT, RUN_TYPES.RunState.BOSS_COMBAT:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.COMBAT
		RUN_TYPES.RunState.COMBAT_RESULT:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.COMBAT_RESULT
		RUN_TYPES.RunState.BOSS_INTRO:
			current_page_type = RUN_TYPES.PageType.RUN_BOARD_PAGE
			current_run_board_mode = RUN_TYPES.RunBoardMode.BOSS_INTRO
		RUN_TYPES.RunState.RUN_VICTORY:
			current_page_type = RUN_TYPES.PageType.RUN_VICTORY_PAGE
		RUN_TYPES.RunState.RUN_DEFEAT:
			current_page_type = RUN_TYPES.PageType.RUN_DEFEAT_PAGE


func _get_combat_branch_option(combat_branch_id: String) -> Dictionary:
	var index: int = 0
	while index < current_combat_branch_options.size():
		if current_combat_branch_options[index].get("combat_branch_id", "") == combat_branch_id:
			return current_combat_branch_options[index]
		index += 1

	return {}


func _get_current_combat_reward_gold() -> int:
	return v1_balance_config.get_combat_gold_reward(current_combat_branch_id, current_battle_type)


func _make_combat_resolution_result() -> Dictionary:
	return {
		"ok": true,
		"reason": "ok",
		"battle_type": current_battle_type,
		"combat_branch_id": current_combat_branch_id,
		"combat_result": last_combat_result,
		"normal_win_count": normal_win_count,
		"run_durability": run_durability,
		"next_state": next_state_after_result,
		"defeat_reason": defeat_reason,
		"last_reward_results": last_reward_results.duplicate(true),
	}


func _make_instance_display_data(instance) -> Dictionary:
	var treasure: Dictionary = get_card_detail_display_data(instance.treasure_id, instance.rarity)
	var occupied_slot_ids: Array = []
	var slots: Array = formation_model.get_slots_occupied_by(instance.instance_id)
	var index: int = 0
	while index < slots.size():
		occupied_slot_ids.append(slots[index].slot_id)
		index += 1

	return {
		"instance_id": instance.instance_id,
		"short_instance_id": _short_id(instance.instance_id),
		"display_name": "%s 第%d件" % [treasure.get("treasure_name", "秘宝少女"), instance.created_order],
		"treasure_id": instance.treasure_id,
		"rarity": instance.rarity,
		"rarity_text": _rarity_text(instance.rarity),
		"source_type": instance.source_type,
		"source_text": _source_text(instance.source_type),
		"is_in_inventory": instance.is_in_inventory,
		"is_in_formation": instance.is_in_formation,
		"created_order": instance.created_order,
		"placed_order": instance.placed_order,
		"occupied_slot_ids": occupied_slot_ids,
		"treasure": treasure,
	}


func _make_treasure_display_data(treasure) -> Dictionary:
	return {
		"exists": true,
		"treasure_id": treasure.treasure_id,
		"treasure_name": treasure.treasure_name,
		"rarity": treasure.rarity,
		"rarity_text": _rarity_text(treasure.rarity),
		"size_type": treasure.size_type,
		"size_text": _size_text(treasure.size_type),
		"footprint_width": treasure.footprint_width,
		"footprint_height": treasure.footprint_height,
		"price": treasure.price,
		"tags": treasure.tags.duplicate(),
		"base_cooldown_ms": treasure.base_cooldown_ms,
		"base_cooldown_sec": treasure.base_cooldown_ms / 1000.0,
		"effect_list": treasure.effect_list.duplicate(true),
		"effect_brief": _format_effect_list(treasure.effect_list),
		"position_rule": treasure.position_rule,
		"upgrade_rule": treasure.upgrade_rule,
		"description": treasure.description,
	}


func _format_effect_list(effect_list: Array) -> String:
	if effect_list.is_empty():
		return "无效果"

	var text: String = ""
	var index: int = 0
	while index < effect_list.size():
		var effect: Dictionary = effect_list[index]
		var value_text: String = ""
		if effect.has("value"):
			value_text = "，数值 %s" % effect.get("value")
		elif effect.has("value_ms"):
			value_text = "，减少冷却 %.1f 秒" % (effect.get("value_ms") / 1000.0)
		elif effect.has("value_bp"):
			value_text = "，强化 %.0f%%" % (effect.get("value_bp") / 100.0)
		if text != "":
			text += "；"
		text += "%s，目标：%s%s" % [
			_effect_type_text(effect.get("effect_type", "")),
			_target_rule_text(effect.get("target_rule", "")),
			value_text,
		]
		index += 1

	return text


func _effect_type_text(effect_type: String) -> String:
	match effect_type:
		"damage":
			return "造成伤害"
		"charge":
			return "充能"
		"shield":
			return "获得护盾"
		"heal":
			return "治疗"
		"buff":
			return "强化"
		"gold":
			return "获得金币"
		"apply_burn_to_player":
			return "施加燃烧"
		_:
			return "触发效果"


func _target_rule_text(target_rule: String) -> String:
	match target_rule:
		"enemy_single":
			return "单个敌人"
		"enemy_all":
			return "所有敌人"
		"player_core":
			return "玩家核心"
		"self":
			return "自身"
		"adjacent":
			return "左右相邻秘宝少女"
		"same_row":
			return "同排秘宝少女"
		"same_col":
			return "同列秘宝少女"
		"front_back_overlap":
			return "前后对应秘宝少女"
		"longest_cooldown_ally":
			return "冷却最长的秘宝少女"
		"center_column":
			return "中列位置"
		"run":
			return "本局资源"
		_:
			return "默认目标"


func _format_payload_reward(payload: Dictionary) -> String:
	var parts: Array = []
	var gold_amount: int = payload.get("gold", 0)
	var durability_amount: int = payload.get("durability", 0)
	if gold_amount > 0:
		parts.append("金币 +%d" % gold_amount)
	if durability_amount > 0:
		parts.append("耐久 +%d" % durability_amount)
	if parts.is_empty():
		return "无直接奖励"

	var text: String = ""
	var index: int = 0
	while index < parts.size():
		if text != "":
			text += "，"
		text += parts[index]
		index += 1
	return text


func _branch_type_text(branch_type: String) -> String:
	match branch_type:
		"shop":
			return "商店"
		"supply":
			return "补给"
		"gold":
			return "金币"
		_:
			return "事件"


func _node_type_text(node_type: String) -> String:
	match node_type:
		"supply":
			return "补给节点"
		"gold":
			return "金币节点"
		_:
			return "事件节点"


func _option_type_text(option_type: String) -> String:
	match option_type:
		"heal":
			return "恢复"
		"gold":
			return "金币"
		"mixed":
			return "混合"
		_:
			return "奖励"


func _battle_type_text(battle_type: String) -> String:
	match battle_type:
		"normal_safe":
			return "稳妥战"
		"normal_standard":
			return "普通战"
		"normal_high_reward":
			return "高奖励战"
		"boss":
			return "最终 Boss"
		_:
			return "战斗"


func _reward_profile_text(profile: String) -> String:
	match profile:
		"safe":
			return "少量奖励"
		"normal":
			return "标准奖励"
		"high_reward":
			return "高额奖励"
		"boss":
			return "通关奖励"
		_:
			return "奖励"


func _rarity_text(rarity: String) -> String:
	match rarity:
		"green":
			return "绿"
		"blue":
			return "蓝"
		"purple":
			return "紫"
		"yellow":
			return "黄"
		_:
			return rarity


func _source_text(source_type: String) -> String:
	match source_type:
		"starter_camp":
			return "初始营地"
		"shop":
			return "商店"
		"combat":
			return "战斗奖励"
		"debug", "debug_synthesis", "ui_smoke":
			return "调试"
		_:
			return "局内获得"


func _short_id(value: String) -> String:
	if value.length() <= 12:
		return value

	return value.substr(0, 12)


func _size_text(size_type: String) -> String:
	match size_type:
		"small":
			return "小型"
		"medium":
			return "中型"
		"large":
			return "大型"
		_:
			return size_type


func _defeat_reason_text(reason: String) -> String:
	match reason:
		"durability_zero":
			return "局内耐久归零"
		"boss_lose":
			return "最终首领战失败"
		"debug_abort":
			return "调试终止"
		_:
			return reason
