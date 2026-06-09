extends V1UIViewBase
class_name RunBoardPage

const BRANCH_SELECT_PANEL_SCENE = preload("res://scenes/ui/panels/branch_select_panel.tscn")
const SHOP_PANEL_SCENE = preload("res://scenes/ui/panels/shop_panel.tscn")
const GENERIC_NODE_CHOICE_PANEL_SCENE = preload("res://scenes/ui/panels/generic_node_choice_panel.tscn")
const FORMATION_PANEL_SCENE = preload("res://scenes/ui/panels/formation_panel.tscn")
const COMBAT_BRANCH_PANEL_SCENE = preload("res://scenes/ui/panels/combat_branch_panel.tscn")
const COMBAT_PANEL_SCENE = preload("res://scenes/ui/panels/combat_panel.tscn")

# 文件职责：
# - V1 局内主页面，承载分支、商店、补给/金币、合成、回路、战斗和结算模式。
# - SupplyNode、GoldNode、SynthesisCheck、FormationEdit、CombatResult 都只作为内部模式或覆盖层出现。

var status_label: Label = null
var mode_container: VBoxContainer = null
var snapshot_grid: GridContainer = null
var mode_panels: Dictionary = {}
var synthesis_panel: VBoxContainer = null
var boss_intro_panel: VBoxContainer = null
var confirm_button: Button = null


func _build() -> void:
	root_box.add_child(make_title("局内面板"))
	status_label = make_label("", 120)
	root_box.add_child(status_label)
	mode_container = make_section_box("ModeContainer")
	root_box.add_child(mode_container)
	_create_mode_panels()
	root_box.add_child(make_label("当前 2×5 回路快照", 48))
	snapshot_grid = GridContainer.new()
	snapshot_grid.columns = 5
	snapshot_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	snapshot_grid.custom_minimum_size = Vector2(0, 260)
	root_box.add_child(snapshot_grid)
	var bottom := HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(make_button("背包", Callable.create(app_controller, "open_bag_requested")))
	bottom.add_child(make_button("调试自动上阵", Callable.create(app_controller, "formation_auto_arrange_requested")))
	confirm_button = make_button("确认阵容", Callable.create(app_controller, "confirm_formation_requested"))
	bottom.add_child(confirm_button)
	bottom.add_child(make_button("返回主菜单", Callable.create(app_controller, "return_to_main_menu_requested")))
	root_box.add_child(bottom)


func refresh() -> void:
	if run_manager == null:
		return

	var summary: Dictionary = run_manager.get_run_summary()
	status_label.text = "%s\n当前分支：%s  当前战斗：%s  战斗结果：%s  下一阶段：%s\n提示：%s" % [
		make_status_text(),
		branch_type_to_text(summary.get("current_branch_type", "")),
		battle_type_to_text(summary.get("current_battle_type", "")),
		battle_result_to_text(summary.get("last_combat_result", "")),
		run_state_to_text(summary.get("next_state", -1)),
		app_controller.last_ui_message,
	]
	_refresh_mode(summary.get("run_board_mode", RUN_TYPES.RunBoardMode.NONE))
	_refresh_snapshot_grid()
	if confirm_button != null:
		confirm_button.disabled = run_manager.current_state != RUN_TYPES.RunState.FORMATION_EDIT


func _create_mode_panels() -> void:
	_add_panel(RUN_TYPES.RunBoardMode.BRANCH_SELECT, BRANCH_SELECT_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.SHOP, SHOP_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.GENERIC_NODE_CHOICE, GENERIC_NODE_CHOICE_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.FORMATION_EDIT, FORMATION_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.COMBAT_BRANCH_SELECT, COMBAT_BRANCH_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.COMBAT, COMBAT_PANEL_SCENE)
	_add_panel(RUN_TYPES.RunBoardMode.COMBAT_RESULT, COMBAT_PANEL_SCENE)

	synthesis_panel = make_section_box("SynthesisPanel")
	synthesis_panel.visible = false
	synthesis_panel.add_child(make_title("合成检查"))
	synthesis_panel.add_child(make_label("分支节点已完成。点击继续会执行 2 合 1 自动合成检查，然后进入回路编辑。", 180))
	synthesis_panel.add_child(make_button("继续合成检查", Callable.create(app_controller, "run_synthesis_check_requested")))
	mode_container.add_child(synthesis_panel)
	mode_panels[RUN_TYPES.RunBoardMode.SYNTHESIS_ANIMATION] = synthesis_panel

	boss_intro_panel = make_section_box("BossIntroPanel")
	boss_intro_panel.visible = false
	boss_intro_panel.add_child(make_title("最终首领已解锁"))
	boss_intro_panel.add_child(make_label("普通战胜利数已达标，下一场为最终首领战。", 160))
	boss_intro_panel.add_child(make_button("进入最终挑战", Callable.create(app_controller, "enter_boss_requested")))
	boss_intro_panel.add_child(make_button("查看最终挑战提示", Callable.create(app_controller, "open_boss_unlocked_popup_requested")))
	mode_container.add_child(boss_intro_panel)
	mode_panels[RUN_TYPES.RunBoardMode.BOSS_INTRO] = boss_intro_panel


func _add_panel(mode: int, scene: PackedScene) -> void:
	var panel = scene.instantiate()
	panel.visible = false
	panel.setup(app_controller, run_manager)
	mode_container.add_child(panel)
	mode_panels[mode] = panel


func _refresh_mode(mode: int) -> void:
	var keys: Array = mode_panels.keys()
	var index: int = 0
	while index < keys.size():
		var key: int = keys[index]
		mode_panels[key].visible = key == mode
		index += 1

	var panel = mode_panels.get(mode, null)
	if panel != null and panel.has_method("refresh"):
		panel.refresh()

	if app_controller.ui_manager != null:
		if mode == RUN_TYPES.RunBoardMode.COMBAT_RESULT:
			app_controller.ui_manager.show_overlay("combat_result_overlay")
		else:
			app_controller.ui_manager.hide_overlay("combat_result_overlay")


func _refresh_snapshot_grid() -> void:
	if snapshot_grid == null:
		return

	clear_children(snapshot_grid)
	var formation: Dictionary = run_manager.get_formation_display_data()
	var slots: Array = formation.get("slots", [])
	var index: int = 0
	while index < slots.size():
		var slot: Dictionary = slots[index]
		var label := make_label(_snapshot_slot_text(slot), 110)
		snapshot_grid.add_child(label)
		index += 1


func _snapshot_slot_text(slot: Dictionary) -> String:
	var base: String = "%s\n" % slot_to_text(slot)
	if not slot.get("is_unlocked", false):
		return base + "锁定"
	if slot.get("occupant_instance_id", "") == "":
		return base + "空"
	var occupant: Dictionary = slot.get("occupant", {})
	return base + occupant.get("display_name", "秘宝少女")
