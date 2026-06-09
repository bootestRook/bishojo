extends RefCounted
class_name LifestealResolver

const PLAYER_STATUS_RESOLVER = preload("res://scripts/systems/battle/player_status_resolver.gd")

# 文件职责：
# - 按 actual_hp_damage 计算吸血回血。
# - 吸血调用 restore_player_hp，不清除中毒和燃烧。

var player_status_resolver = PLAYER_STATUS_RESOLVER.new()


func apply_lifesteal(context, source_unit, damage_result, logger) -> int:
	if source_unit == null:
		return 0
	var lifesteal_bp: int = source_unit.lifesteal_bp
	if source_unit.stats.lifesteal_bp > lifesteal_bp:
		lifesteal_bp = source_unit.stats.lifesteal_bp
	if lifesteal_bp <= 0 or damage_result.actual_hp_damage <= 0:
		return 0

	var heal_amount: int = damage_result.actual_hp_damage * lifesteal_bp / 10000
	var restored: int = player_status_resolver.restore_player_hp(context, heal_amount, logger, source_unit.instance_id, "lifesteal_no_cleanse")
	logger.log(context, {
		"event_type": "LIFESTEAL",
		"source_id": source_unit.instance_id,
		"target_id": "player_core",
		"lifesteal_bp": lifesteal_bp,
		"lifesteal_heal_amount": heal_amount,
		"actual_restored_hp": restored,
		"cause": "actual_hp_damage_only",
	})
	return restored

