extends RefCounted
class_name BattleContextBuilder

const BATTLE_CONTEXT = preload("res://scripts/systems/battle/battle_context.gd")
const BATTLE_UNIT_STATE = preload("res://scripts/systems/battle/battle_unit_state.gd")
const ENEMY_STATE = preload("res://scripts/systems/battle/enemy_state.gd")
const EFFECT_DATA = preload("res://scripts/systems/battle/effect_data.gd")
const BATTLE_CONFIG = preload("res://scripts/systems/battle/battle_config.gd")

# 文件职责：
# - 从构筑系统快照构建单场 BattleContext。
# - 只读取 inventory_model / formation_model / treasure_catalog / enemy_catalog，不修改构筑数据。

var config = BATTLE_CONFIG.new()


func build(inventory_model, formation_model, treasure_catalog, enemy_catalog, battle_type: String, battle_seed: int):
	var context = BATTLE_CONTEXT.new()
	context.battle_id = "battle_%d" % battle_seed
	context.battle_type = _normalize_battle_type(battle_type)
	context.battle_seed = battle_seed
	context.player_core_hp_max = config.player_core_hp_max
	context.player_core_hp = context.player_core_hp_max
	context.player_units = _build_units(inventory_model, formation_model, treasure_catalog)
	context.enemies = _build_enemies(enemy_catalog, battle_type)
	return context


func _build_units(inventory_model, formation_model, treasure_catalog) -> Array:
	var result: Array = []
	var instances: Array = inventory_model.get_formation_instances()
	var index: int = 0
	while index < instances.size():
		var instance = instances[index]
		var treasure_data = treasure_catalog.get_treasure_data(instance.treasure_id, instance.rarity)
		if treasure_data != null:
			var occupied_slots: Array = formation_model.get_slots_occupied_by(instance.instance_id)
			if not occupied_slots.is_empty():
				result.append(_make_unit(instance, treasure_data, occupied_slots))
		index += 1

	return result


func _make_unit(instance, treasure_data, occupied_slots: Array):
	var unit = BATTLE_UNIT_STATE.new()
	unit.instance_id = instance.instance_id
	unit.treasure_id = instance.treasure_id
	unit.treasure_name = treasure_data.treasure_name
	unit.rarity = instance.rarity
	unit.size_type = treasure_data.size_type
	unit.base_cooldown_ms = treasure_data.base_cooldown_ms
	unit.tags = treasure_data.tags.duplicate()
	unit.effect_list = _convert_effects(treasure_data.effect_list)
	_fill_slot_range(unit, occupied_slots)
	return unit


func _fill_slot_range(unit, occupied_slots: Array) -> void:
	var index: int = 0
	var col_start: int = 999999
	var col_end: int = -1
	while index < occupied_slots.size():
		var slot = occupied_slots[index]
		unit.slot_ids.append(slot.slot_id)
		unit.row = slot.row
		if slot.column < col_start:
			col_start = slot.column
		if slot.column > col_end:
			col_end = slot.column
		index += 1
	unit.col_start = col_start
	unit.col_end = col_end


func _convert_effects(raw_effects: Array) -> Array:
	var result: Array = []
	var index: int = 0
	while index < raw_effects.size():
		var effect = EFFECT_DATA.new()
		effect.setup(raw_effects[index])
		result.append(effect)
		index += 1

	return result


func _build_enemies(enemy_catalog, battle_type: String) -> Array:
	var result: Array = []
	var enemy_ids: Array = enemy_catalog.get_enemy_ids_for_battle_type(battle_type)
	var index: int = 0
	while index < enemy_ids.size():
		var enemy_data = enemy_catalog.get_enemy_data(enemy_ids[index])
		if enemy_data != null:
			var enemy = ENEMY_STATE.new()
			enemy.setup(enemy_data.to_data())
			result.append(enemy)
		index += 1

	return result


func _normalize_battle_type(battle_type: String) -> String:
	if battle_type == "boss" or battle_type == "boss_combat":
		return "boss"
	return "normal"

