extends SceneTree

const RUN_TYPES = preload("res://scripts/core/run_types.gd")
const MAIN_SCENE = preload("res://scenes/app/main.tscn")
const PAGE_SCENES: Array = [
	preload("res://scenes/ui/pages/main_menu_page.tscn"),
	preload("res://scenes/ui/pages/character_select_page.tscn"),
	preload("res://scenes/ui/pages/start_camp_page.tscn"),
	preload("res://scenes/ui/pages/run_board_page.tscn"),
	preload("res://scenes/ui/pages/run_victory_page.tscn"),
	preload("res://scenes/ui/pages/run_defeat_page.tscn"),
]
const PANEL_SCENES: Array = [
	preload("res://scenes/ui/panels/branch_select_panel.tscn"),
	preload("res://scenes/ui/panels/shop_panel.tscn"),
	preload("res://scenes/ui/panels/generic_node_choice_panel.tscn"),
	preload("res://scenes/ui/panels/formation_panel.tscn"),
	preload("res://scenes/ui/panels/combat_branch_panel.tscn"),
	preload("res://scenes/ui/panels/combat_panel.tscn"),
]
const OVERLAY_SCENES: Array = [
	preload("res://scenes/ui/overlays/bag_overlay.tscn"),
	preload("res://scenes/ui/overlays/card_detail_overlay.tscn"),
	preload("res://scenes/ui/overlays/synthesis_result_popup.tscn"),
	preload("res://scenes/ui/overlays/combat_result_overlay.tscn"),
	preload("res://scenes/ui/overlays/invalid_formation_popup.tscn"),
	preload("res://scenes/ui/overlays/boss_unlocked_popup.tscn"),
]

# 文件职责：
# - 验证 V1 最小 UI 可玩原型能加载 main scene，并通过页面 / 面板 / 覆盖层驱动一段完整流程。
# - 该 smoke 不验证美术表现，只验证 UI 壳、RunManager 接入、页面切换和关键手动路径可达。

var fail_count: int = 0
var app = null


func _init() -> void:
	call_deferred("_run_and_exit")


func _run_and_exit() -> void:
	_run_smoke()
	if app != null:
		app.queue_free()
		await process_frame
		await process_frame

	if fail_count > 0:
		print("[UI_SMOKE] failed")
		quit(1)
	else:
		print("[UI_SMOKE] passed")
		quit(0)


func _run_smoke() -> void:
	_check_scene_loads()
	_create_app()
	_check_page_registry()
	_check_start_flow()
	_check_branch_node_formation_combat_flow()
	_check_boss_victory_flow()
	_check_defeat_page_flow()
	_check_no_visible_code_symbols()
	_check_no_autoload_section()


func _check_scene_loads() -> void:
	_check(MAIN_SCENE.can_instantiate(), "main scene 可以加载")
	_check_scene_array(PAGE_SCENES, "页面场景可以加载")
	_check_scene_array(PANEL_SCENES, "面板场景可以加载")
	_check_scene_array(OVERLAY_SCENES, "覆盖层场景可以加载")


func _check_scene_array(scenes: Array, label: String) -> void:
	var index: int = 0
	while index < scenes.size():
		_check(scenes[index].can_instantiate(), "%s #%d" % [label, index])
		index += 1


func _create_app() -> void:
	app = MAIN_SCENE.instantiate()
	get_root().add_child(app)
	app._ready()
	_check(app.run_manager != null, "V1AppController 可以创建 RunManager")
	_check(app.ui_manager != null, "V1AppController 可以创建 UIManager")
	_check(app.run_manager.current_state == RUN_TYPES.RunState.MAIN_MENU, "启动进入 MainMenuPage")


func _check_page_registry() -> void:
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.MAIN_MENU_PAGE) != null, "UIManager 引用 MainMenuPage")
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.CHARACTER_SELECT_PAGE) != null, "UIManager 引用 CharacterSelectPage")
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.START_CAMP_PAGE) != null, "UIManager 引用 StartCampPage")
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.RUN_BOARD_PAGE) != null, "UIManager 引用 RunBoardPage")
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.RUN_VICTORY_PAGE) != null, "UIManager 引用 RunVictoryPage")
	_check(app.ui_manager.get_page(RUN_TYPES.PageType.RUN_DEFEAT_PAGE) != null, "UIManager 引用 RunDefeatPage")


func _check_start_flow() -> void:
	app.start_new_run_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.CHARACTER_SELECT, "MainMenuPage 可以触发 start_new_run")
	app.select_default_character_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.START_CAMP, "CharacterSelectPage 可以触发选择默认角色")
	var starters: Array = app.run_manager.get_starter_treasure_display_data()
	_check(starters.size() == 3, "StartCampPage 可以读取 3 个初始秘宝")
	app.select_starter_treasure_requested("flame_blade")
	_check(app.run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT, "选择初始秘宝后进入 RunBoardPage / BRANCH_SELECT")
	_check(app.run_manager.current_run_board_mode == RUN_TYPES.RunBoardMode.BRANCH_SELECT, "RunBoardMode 为 BRANCH_SELECT")


func _check_branch_node_formation_combat_flow() -> void:
	var branch_options: Array = app.run_manager.get_branch_display_data()
	_check(branch_options.size() >= 3, "BranchSelectPanel 能读取 branch options")
	app.select_branch_requested("branch_gold")
	_check(app.run_manager.current_state == RUN_TYPES.RunState.GOLD_NODE, "选择 gold 节点后进入 GenericNodeChoice")
	var choices: Array = app.run_manager.get_node_choice_display_data()
	_check(not choices.is_empty(), "GenericNodeChoicePanel 能读取 node choices")
	app.apply_node_choice_requested(choices[0].get("option_id", ""))
	_check(app.run_manager.current_state == RUN_TYPES.RunState.FORMATION_EDIT, "应用 node choice 后进入 FormationEdit")
	app.open_bag_requested()
	_check(app.ui_manager.get_overlay("bag_overlay").visible, "BagOverlay 可以打开")
	_check(app.run_manager.get_inventory_display_data().size() >= 1, "BagOverlay 能读取 inventory display data")
	app.close_overlay_requested("bag_overlay")
	var formation: Dictionary = app.run_manager.get_formation_display_data()
	_check(formation.get("slots", []).size() == 10, "FormationPanel 能读取 2×5 槽位")
	app.formation_auto_arrange_requested()
	_check(app.run_manager.validate_formation().get("ok", false), "自动上阵或测试放置能成功")
	app.confirm_formation_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.COMBAT_BRANCH_SELECT, "confirm_formation 后进入 COMBAT_BRANCH_SELECT")
	var combat_options: Array = app.run_manager.get_combat_branch_display_data()
	_check(not combat_options.is_empty(), "CombatBranchPanel 能读取战斗分支")
	app.select_combat_branch_requested("normal_safe")
	app.start_current_combat_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.COMBAT_RESULT, "选择并启动普通战后进入 COMBAT_RESULT")
	_check(app.ui_manager.get_overlay("combat_result_overlay").visible, "CombatResultOverlay 能显示")
	app.confirm_combat_result_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.BRANCH_SELECT or app.run_manager.current_state == RUN_TYPES.RunState.BOSS_INTRO or app.run_manager.current_state == RUN_TYPES.RunState.RUN_DEFEAT, "CombatResultOverlay 能确认并进入下一状态")


func _check_boss_victory_flow() -> void:
	app.run_manager.debug_force_normal_win_count(app.run_manager.normal_win_target)
	app.run_manager.enter_formation_edit()
	var index: int = 0
	while index < 9:
		app.run_manager.debug_grant_treasure("flame_blade", "green", "ui_smoke")
		index += 1
	app.formation_auto_arrange_requested()
	_check(app.run_manager.validate_formation().get("ok", false), "Boss 前强阵容可合法上阵")
	app.confirm_formation_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.BOSS_INTRO, "强制 normal_win_count 达标后 UI 能进入 Boss 流程")
	app.enter_boss_requested()
	app.start_current_combat_requested()
	_check(app.run_manager.last_combat_result == "win", "Boss 战斗可胜利")
	app.confirm_combat_result_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.RUN_VICTORY, "Boss 胜利能显示 RunVictoryPage")


func _check_defeat_page_flow() -> void:
	app.return_to_main_menu_requested()
	app.start_new_run_requested()
	app.select_default_character_requested()
	app.select_starter_treasure_requested("flame_blade")
	app.run_manager.record_combat_result("boss", "lose")
	app.run_manager.resolve_combat_result()
	app.confirm_combat_result_requested()
	_check(app.run_manager.current_state == RUN_TYPES.RunState.RUN_DEFEAT, "构造失败能显示 RunDefeatPage")


func _check_no_autoload_section() -> void:
	var file = FileAccess.open("res://project.godot", FileAccess.READ)
	_check(file != null, "project.godot 可读取")
	if file == null:
		return
	var text: String = file.get_as_text()
	_check(text.find("[autoload]") == -1, "project.godot 没有新增 [autoload] 段")


func _check_no_visible_code_symbols() -> void:
	var texts: Array = []
	_collect_control_texts("Label", texts)
	_collect_control_texts("Button", texts)
	var forbidden: Array = [
		"RunState",
		"RunBoardMode",
		"RunBoardPage",
		"treasure_",
		"r0_c",
		"r1_c",
		"normal_",
		"boss_",
		"green",
		"blue",
		"purple",
		"yellow",
		"small",
		"medium",
		"large",
		"Debug",
		"Boss",
		"HP",
		"Tags",
		"->",
		"→",
		"{",
		"}",
	]
	var ok: bool = true
	var text_index: int = 0
	while text_index < texts.size():
		var text: String = texts[text_index]
		var forbidden_index: int = 0
		while forbidden_index < forbidden.size():
			if text.find(forbidden[forbidden_index]) != -1:
				ok = false
				print("[UI_TEXT_SYMBOL] ", forbidden[forbidden_index], " in ", text)
			forbidden_index += 1
		text_index += 1

	_check(ok, "游戏内按钮和标签不显示代码符号")


func _collect_control_texts(type_name: String, texts: Array) -> void:
	var nodes: Array = app.find_children("*", type_name, true, false)
	var index: int = 0
	while index < nodes.size():
		texts.append(nodes[index].text)
		index += 1


func _check(ok: bool, label: String) -> void:
	if ok:
		print("[PASS] ", label)
	else:
		fail_count += 1
		print("[FAIL] ", label)
