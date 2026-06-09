extends RefCounted
class_name EnemyState

const COMBAT_STATS = preload("res://scripts/systems/battle/combat_stats.gd")

# 文件职责：
# - 表示敌人或 Boss 在单场战斗中的运行态。
# - V1 敌人以生命、护盾、攻击间隔和可选效果列表为主，不绑定场景节点。

var enemy_id: String = ""
var enemy_name: String = ""
var hp: int = 0
var hp_max: int = 0
var shield: int = 0
var attack_damage: int = 0
var attack_interval_ms: int = 0
var next_action_time_ms: int = 0
var effect_list: Array = []
var status_map: Dictionary = {}
var stats = COMBAT_STATS.new()
var is_alive: bool = true


func setup(data: Dictionary) -> void:
	enemy_id = data.get("enemy_id", "")
	enemy_name = data.get("enemy_name", "")
	hp = data.get("hp", 0)
	hp_max = data.get("hp_max", hp)
	shield = data.get("shield", 0)
	attack_damage = data.get("attack_damage", 0)
	attack_interval_ms = data.get("attack_interval_ms", 0)
	next_action_time_ms = data.get("next_action_time_ms", attack_interval_ms)
	effect_list = data.get("effect_list", []).duplicate(true)
	status_map = {}
	stats.setup(data.get("stats", {}))
	is_alive = hp > 0

