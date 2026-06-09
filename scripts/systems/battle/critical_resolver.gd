extends RefCounted
class_name CriticalResolver

const BATTLE_RNG = preload("res://scripts/systems/battle/battle_rng.gd")
const CRITICAL_RESULT = preload("res://scripts/systems/battle/critical_result.gd")

# 文件职责：
# - 统一处理暴击率、暴击伤害和 RNG 复盘数据。

var rng = BATTLE_RNG.new()


func resolve(context, packet, config, logger):
	var result = CRITICAL_RESULT.new()
	var threshold: int = packet.crit_rate_bp
	if threshold > config.crit_rate_cap_bp:
		threshold = config.crit_rate_cap_bp
	if threshold < 0:
		threshold = 0

	if not packet.can_crit or threshold <= 0:
		result.setup({
			"battle_seed": context.battle_seed,
			"rng_roll_index": -1,
			"roll_type": "crit",
			"roll_value_bp": -1,
			"threshold_bp": threshold,
			"result": false,
			"crit_damage_bp": packet.crit_damage_bp,
		})
		return result

	var roll: Dictionary = rng.roll_bp(context, "crit", threshold)
	result.setup({
		"battle_seed": roll.get("battle_seed", 0),
		"rng_roll_index": roll.get("rng_roll_index", -1),
		"roll_type": roll.get("roll_type", "crit"),
		"roll_value_bp": roll.get("roll_value_bp", -1),
		"threshold_bp": roll.get("threshold_bp", threshold),
		"result": roll.get("result", false),
		"crit_damage_bp": packet.crit_damage_bp,
	})
	logger.log(context, {
		"event_type": "CRIT_ROLL",
		"source_id": packet.source_id,
		"target_id": packet.target_id,
		"damage_kind": packet.damage_kind,
		"can_crit": packet.can_crit,
		"crit_rate_bp": threshold,
		"crit_roll_bp": result.roll_value_bp,
		"is_crit": result.result,
		"crit_damage_bp": result.crit_damage_bp,
		"rng_roll_index": result.rng_roll_index,
		"cause": "damage_packet",
	})
	return result

