extends RefCounted
class_name V1UIManager

const RUN_TYPES = preload("res://scripts/core/run_types.gd")

const MAIN_MENU_PAGE_SCENE = preload("res://scenes/ui/pages/main_menu_page.tscn")
const CHARACTER_SELECT_PAGE_SCENE = preload("res://scenes/ui/pages/character_select_page.tscn")
const START_CAMP_PAGE_SCENE = preload("res://scenes/ui/pages/start_camp_page.tscn")
const RUN_BOARD_PAGE_SCENE = preload("res://scenes/ui/pages/run_board_page.tscn")
const RUN_VICTORY_PAGE_SCENE = preload("res://scenes/ui/pages/run_victory_page.tscn")
const RUN_DEFEAT_PAGE_SCENE = preload("res://scenes/ui/pages/run_defeat_page.tscn")

const BAG_OVERLAY_SCENE = preload("res://scenes/ui/overlays/bag_overlay.tscn")
const CARD_DETAIL_OVERLAY_SCENE = preload("res://scenes/ui/overlays/card_detail_overlay.tscn")
const SYNTHESIS_RESULT_POPUP_SCENE = preload("res://scenes/ui/overlays/synthesis_result_popup.tscn")
const COMBAT_RESULT_OVERLAY_SCENE = preload("res://scenes/ui/overlays/combat_result_overlay.tscn")
const INVALID_FORMATION_POPUP_SCENE = preload("res://scenes/ui/overlays/invalid_formation_popup.tscn")
const BOSS_UNLOCKED_POPUP_SCENE = preload("res://scenes/ui/overlays/boss_unlocked_popup.tscn")

# 文件职责：
# - 根据 RunManager 的显示契约切换六个独立 Page。
# - 持有局内覆盖层实例，并提供 show / hide / card detail 数据入口。
# - 不解释玩法规则，不直接修改背包、回路、商店等模型。

var app_controller = null
var run_manager = null
var root: Control = null
var pages: Dictionary = {}
var overlays: Dictionary = {}
var active_page_type: int = -1
var card_detail_treasure_id: String = ""
var card_detail_rarity: String = "green"


func setup(new_root: Control, new_run_manager) -> void:
	root = new_root
	app_controller = new_root
	run_manager = new_run_manager
	_create_pages()
	_create_overlays()
	refresh()


func refresh() -> void:
	if run_manager == null:
		return

	var contract: Dictionary = run_manager.get_display_contract()
	var page_type: int = contract.get("page_type", -1)
	_show_page(page_type)

	var page = pages.get(page_type, null)
	if page != null:
		page.refresh()

	_refresh_visible_overlays()


func show_overlay(overlay_id: String) -> void:
	var overlay = overlays.get(overlay_id, null)
	if overlay == null:
		return

	overlay.visible = true
	overlay.refresh()


func hide_overlay(overlay_id: String) -> void:
	var overlay = overlays.get(overlay_id, null)
	if overlay == null:
		return

	overlay.visible = false


func set_card_detail(treasure_id: String, rarity: String = "green") -> void:
	card_detail_treasure_id = treasure_id
	card_detail_rarity = rarity
	var overlay = overlays.get("card_detail_overlay", null)
	if overlay != null:
		overlay.set_card(treasure_id, rarity)


func get_page(page_type: int):
	return pages.get(page_type, null)


func get_overlay(overlay_id: String):
	return overlays.get(overlay_id, null)


func _create_pages() -> void:
	_add_page(RUN_TYPES.PageType.MAIN_MENU_PAGE, MAIN_MENU_PAGE_SCENE)
	_add_page(RUN_TYPES.PageType.CHARACTER_SELECT_PAGE, CHARACTER_SELECT_PAGE_SCENE)
	_add_page(RUN_TYPES.PageType.START_CAMP_PAGE, START_CAMP_PAGE_SCENE)
	_add_page(RUN_TYPES.PageType.RUN_BOARD_PAGE, RUN_BOARD_PAGE_SCENE)
	_add_page(RUN_TYPES.PageType.RUN_VICTORY_PAGE, RUN_VICTORY_PAGE_SCENE)
	_add_page(RUN_TYPES.PageType.RUN_DEFEAT_PAGE, RUN_DEFEAT_PAGE_SCENE)


func _add_page(page_type: int, scene: PackedScene) -> void:
	var page = scene.instantiate()
	page.visible = false
	page.setup(app_controller, run_manager)
	root.add_child(page)
	pages[page_type] = page


func _create_overlays() -> void:
	_add_overlay("bag_overlay", BAG_OVERLAY_SCENE)
	_add_overlay("card_detail_overlay", CARD_DETAIL_OVERLAY_SCENE)
	_add_overlay("synthesis_result_popup", SYNTHESIS_RESULT_POPUP_SCENE)
	_add_overlay("combat_result_overlay", COMBAT_RESULT_OVERLAY_SCENE)
	_add_overlay("invalid_formation_popup", INVALID_FORMATION_POPUP_SCENE)
	_add_overlay("boss_unlocked_popup", BOSS_UNLOCKED_POPUP_SCENE)


func _add_overlay(overlay_id: String, scene: PackedScene) -> void:
	var overlay = scene.instantiate()
	overlay.visible = false
	overlay.setup(app_controller, run_manager)
	root.add_child(overlay)
	overlays[overlay_id] = overlay


func _show_page(page_type: int) -> void:
	active_page_type = page_type
	var keys: Array = pages.keys()
	var index: int = 0
	while index < keys.size():
		var key: int = keys[index]
		pages[key].visible = key == page_type
		index += 1


func _refresh_visible_overlays() -> void:
	var keys: Array = overlays.keys()
	var index: int = 0
	while index < keys.size():
		var overlay = overlays[keys[index]]
		if overlay.visible:
			overlay.refresh()
		index += 1
