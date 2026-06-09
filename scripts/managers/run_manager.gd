extends RefCounted
class_name RunManager

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const V1_CHARACTER_DATA = preload("res://scripts/data/v1_character_data.gd")
const V1_INITIAL_RUN_CONFIG = preload("res://scripts/data/v1_initial_run_config.gd")
const V1_STARTER_TREASURE_OPTIONS = preload("res://scripts/data/v1_starter_treasure_options.gd")

# 文件职责：
# - 管理一局 Run 的核心流程状态和最小运行数据骨架。
# - 为后续 UIManager 提供“当前应显示哪个 Page / RunBoardMode”的只读契约数据。
# - 本阶段不接入场景、节点、Autoload、输入动作、战斗模拟器或外部 Manager，避免臆造项目符号。

const STATE_UNSET: int = -1
const PAGE_TYPE_UNSET: int = -1
const DEFAULT_RUN_DURABILITY_MAX: int = 5
const DEFAULT_NORMAL_WIN_TARGET: int = 10

var character_data = V1_CHARACTER_DATA.new()
var initial_run_config = V1_INITIAL_RUN_CONFIG.new()
var starter_treasure_data = V1_STARTER_TREASURE_OPTIONS.new()

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

# 当前流程临时数据。字符串取值会在后续数据配置阶段统一收口，当前只保留承接字段。
var current_branch_id: String = ""
var current_branch_type: String = ""
var current_battle_type: String = ""
var last_combat_result: String = ""
var defeat_reason: String = ""
var next_state_after_result: int = STATE_UNSET

# 后续系统的最小数据入口。本阶段只建容器，不实现背包、商店、合成、战斗或奖励规则。
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
	selected_character_id = ""
	selected_starter_treasure_id = ""
	gold = 0
	run_durability_max = 0
	run_durability = 0
	normal_win_target = 0
	normal_win_count = 0
	starter_treasure_options = []
	current_branch_id = ""
	current_branch_type = ""
	current_battle_type = ""
	last_combat_result = ""
	defeat_reason = ""
	next_state_after_result = STATE_UNSET
	state_history = []
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
	# TODO: 后续 InventoryManager 创建后，在这里把所选秘宝加入背包或交给初始上阵引导。
	change_state(RUN_TYPES.RunState.BRANCH_SELECT)
	return true


func confirm_starter_treasure(treasure_id: String) -> void:
	select_starter_treasure(treasure_id)


func record_selected_branch(branch_id: String, branch_type: String) -> void:
	current_branch_id = branch_id
	current_branch_type = branch_type
	change_state(RUN_TYPES.RunState.BRANCH_RESOLVE)


func enter_shop_node() -> void:
	change_state(RUN_TYPES.RunState.SHOP_NODE)


func enter_supply_node() -> void:
	change_state(RUN_TYPES.RunState.SUPPLY_NODE)


func enter_gold_node() -> void:
	change_state(RUN_TYPES.RunState.GOLD_NODE)


func finish_branch_node() -> void:
	change_state(RUN_TYPES.RunState.SYNTHESIS_CHECK)


func finish_synthesis_check() -> void:
	change_state(RUN_TYPES.RunState.FORMATION_EDIT)


func confirm_formation() -> void:
	change_state(RUN_TYPES.RunState.COMBAT_BRANCH_SELECT)


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
