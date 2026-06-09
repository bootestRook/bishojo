extends RefCounted
class_name V1EnemyCatalog

const ENEMY_DATA = preload("res://scripts/data/enemies/v1_enemy_data.gd")

# 文件职责：
# - 保存 V1 普通敌人与 Boss 的纯逻辑配置。
# - 战斗分支到敌人的映射集中在这里，后续可替换为权重或关卡表。

var catalog: Dictionary = {}
var branch_enemy_map: Dictionary = {
	"normal_safe": ["training_dummy"],
	"normal_standard": ["goblin_attacker"],
	"normal_high_reward": ["shield_guard"],
	"normal": ["training_dummy"],
	"boss": ["v1_final_boss"],
}


func _init() -> void:
	_setup_catalog()


func get_enemy_data(enemy_id: String):
	if not catalog.has(enemy_id):
		return null

	var enemy = ENEMY_DATA.new()
	enemy.setup(catalog.get(enemy_id).duplicate(true))
	return enemy


func get_enemy_ids_for_battle_type(battle_type: String) -> Array:
	if branch_enemy_map.has(battle_type):
		return branch_enemy_map.get(battle_type).duplicate()
	if battle_type == "boss_combat":
		return branch_enemy_map.get("boss").duplicate()

	return branch_enemy_map.get("normal").duplicate()


func _add(data: Dictionary) -> void:
	catalog[data.get("enemy_id", "")] = data


func _setup_catalog() -> void:
	_add({
		"enemy_id": "training_dummy",
		"enemy_name": "训练假人",
		"hp": 35,
		"hp_max": 35,
		"shield": 0,
		"attack_damage": 4,
		"attack_interval_ms": 6000,
		"effect_list": [],
		"battle_type": "normal",
	})
	_add({
		"enemy_id": "goblin_attacker",
		"enemy_name": "轻袭者",
		"hp": 70,
		"hp_max": 70,
		"shield": 0,
		"attack_damage": 10,
		"attack_interval_ms": 5000,
		"effect_list": [],
		"battle_type": "normal",
	})
	_add({
		"enemy_id": "shield_guard",
		"enemy_name": "盾卫",
		"hp": 90,
		"hp_max": 90,
		"shield": 18,
		"attack_damage": 100,
		"attack_interval_ms": 2000,
		"effect_list": [],
		"battle_type": "normal",
	})
	_add({
		"enemy_id": "v1_final_boss",
		"enemy_name": "V1 终局首领",
		"hp": 160,
		"hp_max": 160,
		"shield": 25,
		"attack_damage": 14,
		"attack_interval_ms": 4500,
		"effect_list": [{"effect_type": "apply_burn_to_player", "value": 2}],
		"battle_type": "boss",
	})

