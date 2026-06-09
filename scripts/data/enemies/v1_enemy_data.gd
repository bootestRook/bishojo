extends RefCounted
class_name V1EnemyData

# 文件职责：
# - 保存 V1 敌人基础配置快照。
# - 只描述纯逻辑战斗字段，不绑定场景、动画或 UI 表现。

var enemy_id: String = ""
var enemy_name: String = ""
var hp: int = 0
var hp_max: int = 0
var shield: int = 0
var attack_damage: int = 0
var attack_interval_ms: int = 0
var effect_list: Array = []
var battle_type: String = "normal"


func setup(data: Dictionary) -> void:
	enemy_id = data.get("enemy_id", "")
	enemy_name = data.get("enemy_name", "")
	hp = data.get("hp", 0)
	hp_max = data.get("hp_max", hp)
	shield = data.get("shield", 0)
	attack_damage = data.get("attack_damage", 0)
	attack_interval_ms = data.get("attack_interval_ms", 0)
	effect_list = data.get("effect_list", []).duplicate(true)
	battle_type = data.get("battle_type", "normal")


func to_data() -> Dictionary:
	return {
		"enemy_id": enemy_id,
		"enemy_name": enemy_name,
		"hp": hp,
		"hp_max": hp_max,
		"shield": shield,
		"attack_damage": attack_damage,
		"attack_interval_ms": attack_interval_ms,
		"effect_list": effect_list.duplicate(true),
		"battle_type": battle_type,
	}

