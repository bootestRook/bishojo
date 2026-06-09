extends RefCounted
class_name RunManager

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const V1_CHARACTER_DATA = preload("res://scripts/data/v1_character_data.gd")
const V1_INITIAL_RUN_CONFIG = preload("res://scripts/data/v1_initial_run_config.gd")
const V1_STARTER_TREASURE_OPTIONS = preload("res://scripts/data/v1_starter_treasure_options.gd")
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

var current_state: int = RUN_TYPES.RunState.BOOT
var current_page_type: int = PAGE_TYPE_UNSET
var current_run_board_mode: int = RUN_TYPES.RunBoardMode.NONE
var state_history: Array = []

# Run 级基础数据。初始金币在策划中仍为“待定”，由 initial_run_config 暂存占位值。
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
var battle_seed: int = 1001

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
	inventory_model = INVENTORY_MODEL.new()
	formation_model = FORMATION_MODEL.new()
	formation_model.setup_grid()
	branch_manager = BRANCH_MANAGER.new()
	node_choice_manager = NODE_CHOICE_MANAGER.new()
	shop_manager = SHOP_MANAGER.new()
	synthesis_resolver = SYNTHESIS_RESOLVER.new()
	battle_manager = BATTLE_MANAGER.new()
	enemy_catalog = V1_ENEMY_CATALOG.new()
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
	battle_seed = 1001
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


func start_new_run_requested() -> void:
	reset_run_data()
	change_state(RUN_TYPES.RunState.START_NEW_RUN)
	change_state(RUN_TYPES.RunState.CHARACTER_SELECT)


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


func init_run_values() -> void:
	gold = initial_run_config.initial_gold
	run_durability = initial_run_config.run_durability
	run_durability_max = initial_run_config.run_durability_max
	normal_win_count = initial_run_config.normal_win_count
	normal_win_target = initial_run_config.normal_win_target
	starter_treasure_options = starter_treasure_data.get_treasure_ids()
	change_state(RUN_TYPES.RunState.START_CAMP)


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


func confirm_formation() -> void:
	var result: Dictionary = validate_formation()
	if result.get("ok", false):
		change_state(RUN_TYPES.RunState.COMBAT_BRANCH_SELECT)


func generate_combat_branch_options() -> Array:
	current_combat_branch_options = []
	if normal_win_count >= normal_win_target:
		current_combat_branch_options.append({
			"combat_branch_id": "boss",
			"battle_type": "boss",
			"title": "最终 Boss",
			"description": "挑战 V1 终局首领。",
			"reward_gold": 0,
		})
		change_state(RUN_TYPES.RunState.BOSS_INTRO)
		return current_combat_branch_options.duplicate(true)

	current_combat_branch_options.append({
		"combat_branch_id": "normal_safe",
		"battle_type": "normal_safe",
		"title": "稳妥战",
		"description": "敌人较弱，奖励较少。",
		"reward_gold": 1,
	})
	current_combat_branch_options.append({
		"combat_branch_id": "normal_standard",
		"battle_type": "normal_standard",
		"title": "普通战",
		"description": "标准敌人与标准奖励。",
		"reward_gold": 2,
	})
	current_combat_branch_options.append({
		"combat_branch_id": "normal_high_reward",
		"battle_type": "normal_high_reward",
		"title": "高奖励战",
		"description": "敌人更危险，奖励更高。",
		"reward_gold": 3,
	})
	change_state(RUN_TYPES.RunState.COMBAT_BRANCH_SELECT)
	return current_combat_branch_options.duplicate(true)


func select_combat_branch(combat_branch_id: String) -> bool:
	var option: Dictionary = _get_combat_branch_option(combat_branch_id)
	if option.is_empty():
		return false

	current_combat_branch_id = combat_branch_id
	current_battle_type = option.get("battle_type", "normal_safe")
	if current_battle_type == "boss":
		change_state(RUN_TYPES.RunState.BOSS_COMBAT)
	else:
		change_state(RUN_TYPES.RunState.COMBAT)
	return true


func start_current_combat() -> Dictionary:
	if current_battle_type == "":
		current_battle_type = "normal_safe"

	battle_seed += 1
	if current_battle_type == "boss":
		last_battle_result = battle_manager.start_boss_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_seed)
	else:
		last_battle_result = battle_manager.start_normal_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, current_battle_type, battle_seed)

	last_combat_result = last_battle_result.get("result", "")
	last_battle_timeline_log = battle_manager.get_last_timeline_log()
	change_state(RUN_TYPES.RunState.COMBAT_RESULT)
	return last_battle_result.duplicate(true)


func resolve_combat_result() -> void:
	if current_battle_type == "boss":
		if last_combat_result == "win":
			next_state_after_result = RUN_TYPES.RunState.RUN_VICTORY
		else:
			defeat_reason = "boss_lose"
			next_state_after_result = RUN_TYPES.RunState.RUN_DEFEAT
		return

	if last_combat_result == "win":
		normal_win_count += 1
		gold += _get_current_combat_reward_gold()
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


func enter_boss_combat_requested() -> void:
	current_combat_branch_options = [{
		"combat_branch_id": "boss",
		"battle_type": "boss",
		"title": "最终 Boss",
		"description": "挑战 V1 终局首领。",
		"reward_gold": 0,
	}]
	select_combat_branch("boss")


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


func confirm_combat_result() -> void:
	if next_state_after_result == STATE_UNSET:
		return

	change_state(next_state_after_result)


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
	var option: Dictionary = _get_combat_branch_option(current_combat_branch_id)
	if option.is_empty():
		return 2

	return option.get("reward_gold", 2)
