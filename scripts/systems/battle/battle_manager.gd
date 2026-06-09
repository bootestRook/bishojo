extends RefCounted
class_name BattleManager

const BATTLE_CONTEXT_BUILDER = preload("res://scripts/systems/battle/battle_context_builder.gd")
const BATTLE_RUNNER = preload("res://scripts/systems/battle/battle_runner.gd")

# 文件职责：
# - 作为纯逻辑战斗门面，给 RunManager 和 smoke test 调用。
# - 不注册 Autoload，不依赖 UI，不创建场景节点。

var context_builder = BATTLE_CONTEXT_BUILDER.new()
var battle_runner = BATTLE_RUNNER.new()
var last_battle_context = null
var last_battle_result: Dictionary = {}


func start_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_type: String, battle_seed: int) -> Dictionary:
	last_battle_context = context_builder.build(inventory_model, formation_model, treasure_catalog, enemy_catalog, battle_type, battle_seed)
	last_battle_result = battle_runner.run(last_battle_context)
	return last_battle_result.duplicate(true)


func start_normal_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_type: String, battle_seed: int) -> Dictionary:
	return start_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_type, battle_seed)


func start_boss_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, battle_seed: int) -> Dictionary:
	return start_battle(formation_model, inventory_model, treasure_catalog, enemy_catalog, "boss", battle_seed)


func get_last_battle_context():
	return last_battle_context


func get_last_timeline_log() -> Array:
	if last_battle_context == null:
		return []

	return last_battle_context.timeline_log.duplicate()

