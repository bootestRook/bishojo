extends RefCounted
class_name BattleLogEntry

# 文件职责：
# - 记录战斗底层可复盘日志条目。
# - 字段覆盖冷却、充能、暴击、伤害、护盾、治疗、吸血、剧毒、燃烧、DOT、敌人行动和胜负原因。

var log_id: String = ""
var time_ms: int = 0
var event_type: String = ""
var source_id: String = ""
var source_name: String = ""
var source_layer: String = ""
var target_id: String = ""
var target_name: String = ""
var target_layer: String = ""
var effect_id: String = ""
var effect_type: String = ""
var damage_kind: String = ""
var damage_type: String = ""
var raw_damage: int = 0
var pre_crit_damage: int = 0
var final_damage: int = 0
var actual_hp_damage: int = 0
var shield_damage: int = 0
var can_crit: bool = false
var crit_rate_bp: int = 0
var crit_roll_bp: int = -1
var is_crit: bool = false
var crit_damage_bp: int = 0
var rng_roll_index: int = -1
var heal_amount: int = 0
var actual_restored_hp: int = 0
var cleanse_amount: int = 0
var lifesteal_bp: int = 0
var lifesteal_heal_amount: int = 0
var hp_before: int = 0
var hp_after: int = 0
var shield_before: int = 0
var shield_after: int = 0
var poison_before: int = 0
var poison_after: int = 0
var burn_before: int = 0
var burn_after: int = 0
var status_id: String = ""
var status_target_layer: String = ""
var stack_before: int = 0
var stack_after: int = 0
var remaining_cooldown_before_ms: int = 0
var remaining_cooldown_after_ms: int = 0
var cooldown_rate_before_bp: int = 0
var cooldown_rate_after_bp: int = 0
var was_blocked_by_freeze: bool = false
var cause: String = ""
var chain_depth: int = 0


func setup(data: Dictionary) -> void:
	var keys: Array = data.keys()
	var index: int = 0
	while index < keys.size():
		var key = keys[index]
		match key:
			"log_id": log_id = data.get(key, log_id)
			"time_ms": time_ms = data.get(key, time_ms)
			"event_type": event_type = data.get(key, event_type)
			"source_id": source_id = data.get(key, source_id)
			"source_name": source_name = data.get(key, source_name)
			"source_layer": source_layer = data.get(key, source_layer)
			"target_id": target_id = data.get(key, target_id)
			"target_name": target_name = data.get(key, target_name)
			"target_layer": target_layer = data.get(key, target_layer)
			"effect_id": effect_id = data.get(key, effect_id)
			"effect_type": effect_type = data.get(key, effect_type)
			"damage_kind": damage_kind = data.get(key, damage_kind)
			"damage_type": damage_type = data.get(key, damage_type)
			"raw_damage": raw_damage = data.get(key, raw_damage)
			"pre_crit_damage": pre_crit_damage = data.get(key, pre_crit_damage)
			"final_damage": final_damage = data.get(key, final_damage)
			"actual_hp_damage": actual_hp_damage = data.get(key, actual_hp_damage)
			"shield_damage": shield_damage = data.get(key, shield_damage)
			"can_crit": can_crit = data.get(key, can_crit)
			"crit_rate_bp": crit_rate_bp = data.get(key, crit_rate_bp)
			"crit_roll_bp": crit_roll_bp = data.get(key, crit_roll_bp)
			"is_crit": is_crit = data.get(key, is_crit)
			"crit_damage_bp": crit_damage_bp = data.get(key, crit_damage_bp)
			"rng_roll_index": rng_roll_index = data.get(key, rng_roll_index)
			"heal_amount": heal_amount = data.get(key, heal_amount)
			"actual_restored_hp": actual_restored_hp = data.get(key, actual_restored_hp)
			"cleanse_amount": cleanse_amount = data.get(key, cleanse_amount)
			"lifesteal_bp": lifesteal_bp = data.get(key, lifesteal_bp)
			"lifesteal_heal_amount": lifesteal_heal_amount = data.get(key, lifesteal_heal_amount)
			"hp_before": hp_before = data.get(key, hp_before)
			"hp_after": hp_after = data.get(key, hp_after)
			"shield_before": shield_before = data.get(key, shield_before)
			"shield_after": shield_after = data.get(key, shield_after)
			"poison_before": poison_before = data.get(key, poison_before)
			"poison_after": poison_after = data.get(key, poison_after)
			"burn_before": burn_before = data.get(key, burn_before)
			"burn_after": burn_after = data.get(key, burn_after)
			"status_id": status_id = data.get(key, status_id)
			"status_target_layer": status_target_layer = data.get(key, status_target_layer)
			"stack_before": stack_before = data.get(key, stack_before)
			"stack_after": stack_after = data.get(key, stack_after)
			"remaining_cooldown_before_ms": remaining_cooldown_before_ms = data.get(key, remaining_cooldown_before_ms)
			"remaining_cooldown_after_ms": remaining_cooldown_after_ms = data.get(key, remaining_cooldown_after_ms)
			"cooldown_rate_before_bp": cooldown_rate_before_bp = data.get(key, cooldown_rate_before_bp)
			"cooldown_rate_after_bp": cooldown_rate_after_bp = data.get(key, cooldown_rate_after_bp)
			"was_blocked_by_freeze": was_blocked_by_freeze = data.get(key, was_blocked_by_freeze)
			"cause": cause = data.get(key, cause)
			"chain_depth": chain_depth = data.get(key, chain_depth)
		index += 1


func to_data() -> Dictionary:
	return {
		"time_ms": time_ms,
		"event_type": event_type,
		"source_id": source_id,
		"target_id": target_id,
		"effect_type": effect_type,
		"damage_kind": damage_kind,
		"raw_damage": raw_damage,
		"final_damage": final_damage,
		"actual_hp_damage": actual_hp_damage,
		"shield_damage": shield_damage,
		"crit_roll_bp": crit_roll_bp,
		"is_crit": is_crit,
		"rng_roll_index": rng_roll_index,
		"heal_amount": heal_amount,
		"actual_restored_hp": actual_restored_hp,
		"lifesteal_heal_amount": lifesteal_heal_amount,
		"hp_before": hp_before,
		"hp_after": hp_after,
		"shield_before": shield_before,
		"shield_after": shield_after,
		"poison_before": poison_before,
		"poison_after": poison_after,
		"burn_before": burn_before,
		"burn_after": burn_after,
		"remaining_cooldown_before_ms": remaining_cooldown_before_ms,
		"remaining_cooldown_after_ms": remaining_cooldown_after_ms,
		"cooldown_rate_before_bp": cooldown_rate_before_bp,
		"cooldown_rate_after_bp": cooldown_rate_after_bp,
		"was_blocked_by_freeze": was_blocked_by_freeze,
		"cause": cause,
		"chain_depth": chain_depth,
	}

