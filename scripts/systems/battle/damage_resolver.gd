extends RefCounted
class_name DamageResolver

const DAMAGE_RESULT = preload("res://scripts/systems/battle/damage_result.gd")
const CRITICAL_RESOLVER = preload("res://scripts/systems/battle/critical_resolver.gd")

# 文件职责：
# - 统一处理伤害加成、暴击、护盾吸收、生命扣减和 BattleLog。
# - 任何实际扣血都应该通过这里，保证吸血、护盾和溢出统计一致。

var critical_resolver = CRITICAL_RESOLVER.new()


func apply_to_enemy(context, packet, enemy, config, logger):
	var result = _resolve_common(context, packet, enemy.hp, enemy.shield, config, logger)
	enemy.shield = result.target_shield_after
	enemy.hp = result.target_hp_after
	if enemy.hp <= 0:
		enemy.is_alive = false

	_log_damage(context, packet, result, logger)
	if not enemy.is_alive:
		logger.log(context, {
			"event_type": "ENEMY_DEAD",
			"source_id": packet.source_id,
			"target_id": enemy.enemy_id,
			"hp_before": result.target_hp_before,
			"hp_after": result.target_hp_after,
			"cause": packet.damage_kind,
		})
	return result


func apply_to_player_core(context, packet, config, logger):
	var shield_before: int = context.player_shield_stack
	if packet.damage_kind == "poison":
		context.player_shield_stack = 0

	var result = _resolve_common(context, packet, context.player_core_hp, context.player_shield_stack, config, logger)
	context.player_core_hp = result.target_hp_after
	context.player_shield_stack = result.target_shield_after
	if packet.damage_kind == "poison":
		result.target_shield_before = shield_before
		result.target_shield_after = shield_before
		context.player_shield_stack = shield_before

	_log_damage(context, packet, result, logger)
	if context.player_core_hp <= 0:
		logger.log(context, {
			"event_type": "PLAYER_CORE_DEAD",
			"source_id": packet.source_id,
			"target_id": "player_core",
			"hp_before": result.target_hp_before,
			"hp_after": result.target_hp_after,
			"cause": packet.damage_kind,
		})
	return result


func _resolve_common(context, packet, hp: int, shield: int, config, logger):
	var result = DAMAGE_RESULT.new()
	result.packet_id = packet.packet_id
	result.raw_damage = packet.raw_damage
	result.damage_kind = packet.damage_kind
	result.damage_type = packet.damage_type
	result.can_crit = packet.can_crit
	result.crit_rate_bp = packet.crit_rate_bp
	result.crit_damage_bp = packet.crit_damage_bp
	result.target_hp_before = hp
	result.target_shield_before = shield

	var adjusted: int = packet.raw_damage
	adjusted = adjusted + adjusted * packet.damage_bonus_bp / 10000
	adjusted = adjusted + adjusted * packet.damage_taken_bonus_bp / 10000
	adjusted -= packet.damage_reduce_flat
	if adjusted < 0:
		adjusted = 0
	result.pre_crit_damage = adjusted

	var crit = critical_resolver.resolve(context, packet, config, logger)
	result.crit_roll_bp = crit.roll_value_bp
	result.is_crit = crit.result
	result.crit_damage_bp = crit.crit_damage_bp
	if crit.result:
		adjusted = adjusted * crit.crit_damage_bp / 10000
	result.final_damage = adjusted

	var remaining_damage: int = adjusted
	var shield_damage: int = 0
	if shield > 0 and remaining_damage > 0:
		shield_damage = remaining_damage
		if shield_damage > shield:
			shield_damage = shield
		shield -= shield_damage
		remaining_damage -= shield_damage
	result.shield_damage = shield_damage
	result.target_shield_after = shield

	var hp_damage: int = remaining_damage
	if hp_damage > hp:
		hp_damage = hp
	if hp_damage < 0:
		hp_damage = 0
	result.actual_hp_damage = hp_damage
	result.target_hp_after = hp - hp_damage
	return result


func _log_damage(context, packet, result, logger) -> void:
	logger.log(context, {
		"event_type": "DAMAGE_PACKET",
		"source_id": packet.source_id,
		"source_layer": packet.source_layer,
		"target_id": packet.target_id,
		"target_layer": packet.target_layer,
		"damage_kind": packet.damage_kind,
		"damage_type": packet.damage_type,
		"raw_damage": result.raw_damage,
		"pre_crit_damage": result.pre_crit_damage,
		"final_damage": result.final_damage,
		"actual_hp_damage": result.actual_hp_damage,
		"shield_damage": result.shield_damage,
		"can_crit": result.can_crit,
		"crit_rate_bp": result.crit_rate_bp,
		"crit_roll_bp": result.crit_roll_bp,
		"is_crit": result.is_crit,
		"crit_damage_bp": result.crit_damage_bp,
		"hp_before": result.target_hp_before,
		"hp_after": result.target_hp_after,
		"shield_before": result.target_shield_before,
		"shield_after": result.target_shield_after,
		"cause": packet.damage_kind,
	})

