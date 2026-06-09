extends RefCounted
class_name PlayerStatusResolver

const DAMAGE_PACKET = preload("res://scripts/systems/battle/damage_packet.gd")

# 文件职责：
# - 处理玩家核心的护盾、治疗、普通回血、剧毒和燃烧。
# - 治疗会清异常；restore_player_hp 给吸血使用，不清除中毒和燃烧。


func add_shield(context, amount: int, config, logger, source_id: String = "") -> void:
	var before: int = context.player_shield_stack
	context.player_shield_stack += amount
	var shield_cap: int = context.player_core_hp_max * config.shield_cap_ratio_bp / 10000
	if context.player_shield_stack > shield_cap:
		context.player_shield_stack = shield_cap
	logger.log(context, {
		"event_type": "APPLY_SHIELD",
		"source_id": source_id,
		"target_id": "player_core",
		"effect_type": "shield",
		"shield_before": before,
		"shield_after": context.player_shield_stack,
		"cause": "effect",
	})


func heal_player(context, heal_amount: int, config, logger, source_id: String = "") -> Dictionary:
	var hp_before: int = context.player_core_hp
	context.player_core_hp += heal_amount
	if context.player_core_hp > context.player_core_hp_max:
		context.player_core_hp = context.player_core_hp_max
	var actual_restored: int = context.player_core_hp - hp_before
	var poison_before: int = context.player_poison_stack
	var burn_before: int = context.player_burn_stack
	var cleanse_amount: int = heal_amount * config.heal_cleanse_bp / 10000
	context.player_poison_stack -= cleanse_amount
	context.player_burn_stack -= cleanse_amount
	if context.player_poison_stack < 0:
		context.player_poison_stack = 0
	if context.player_burn_stack < 0:
		context.player_burn_stack = 0
	logger.log(context, {
		"event_type": "HEAL",
		"source_id": source_id,
		"target_id": "player_core",
		"effect_type": "heal",
		"heal_amount": heal_amount,
		"actual_restored_hp": actual_restored,
		"cleanse_amount": cleanse_amount,
		"hp_before": hp_before,
		"hp_after": context.player_core_hp,
		"poison_before": poison_before,
		"poison_after": context.player_poison_stack,
		"burn_before": burn_before,
		"burn_after": context.player_burn_stack,
		"cause": "heal_cleanses_status",
	})
	return {"actual_restored_hp": actual_restored, "cleanse_amount": cleanse_amount}


func restore_player_hp(context, restore_amount: int, logger, source_id: String = "", cause: String = "restore") -> int:
	var hp_before: int = context.player_core_hp
	context.player_core_hp += restore_amount
	if context.player_core_hp > context.player_core_hp_max:
		context.player_core_hp = context.player_core_hp_max
	var actual_restored: int = context.player_core_hp - hp_before
	logger.log(context, {
		"event_type": "RESTORE_PLAYER_HP",
		"source_id": source_id,
		"target_id": "player_core",
		"heal_amount": restore_amount,
		"actual_restored_hp": actual_restored,
		"hp_before": hp_before,
		"hp_after": context.player_core_hp,
		"poison_before": context.player_poison_stack,
		"poison_after": context.player_poison_stack,
		"burn_before": context.player_burn_stack,
		"burn_after": context.player_burn_stack,
		"cause": cause,
	})
	return actual_restored


func apply_poison(context, stack: int, duration_ms: int, logger, source_id: String = "") -> void:
	var before: int = context.player_poison_stack
	context.player_poison_stack += stack
	if duration_ms > 0:
		context.player_poison_end_time_ms = context.time_ms + duration_ms
	logger.log(context, {
		"event_type": "APPLY_POISON",
		"source_id": source_id,
		"target_id": "player_core",
		"effect_type": "apply_poison_to_player",
		"poison_before": before,
		"poison_after": context.player_poison_stack,
		"cause": "effect",
	})


func apply_burn(context, stack: int, logger, source_id: String = "") -> void:
	var before: int = context.player_burn_stack
	context.player_burn_stack += stack
	logger.log(context, {
		"event_type": "APPLY_BURN",
		"source_id": source_id,
		"target_id": "player_core",
		"effect_type": "apply_burn_to_player",
		"burn_before": before,
		"burn_after": context.player_burn_stack,
		"cause": "effect",
	})


func tick_poison(context, config, damage_resolver, logger):
	if context.player_poison_stack <= 0:
		return null
	if context.player_poison_end_time_ms > 0 and context.time_ms > context.player_poison_end_time_ms:
		context.player_poison_stack = 0
		return null

	var packet = DAMAGE_PACKET.new()
	packet.setup({
		"packet_id": "poison_%d" % context.time_ms,
		"source_id": "player_poison",
		"source_layer": "system",
		"target_id": "player_core",
		"target_layer": "player_core",
		"damage_kind": "poison",
		"damage_type": "poison",
		"raw_damage": context.player_poison_stack * config.poison_damage_per_stack,
		"can_crit": false,
		"can_trigger_lifesteal": false,
		"can_trigger_on_damage_hooks": false,
	})
	var result = damage_resolver.apply_to_player_core(context, packet, config, logger)
	logger.log(context, {
		"event_type": "PLAYER_POISON_TICK",
		"source_id": "player_poison",
		"target_id": "player_core",
		"effect_type": "poison",
		"raw_damage": packet.raw_damage,
		"actual_hp_damage": result.actual_hp_damage,
		"poison_before": context.player_poison_stack,
		"poison_after": context.player_poison_stack,
		"cause": "poison_ignores_shield",
	})
	return result


func tick_burn(context, config, damage_resolver, logger):
	if context.player_burn_stack <= 0:
		return null

	var burn_before: int = context.player_burn_stack
	var raw_damage: int = context.player_burn_stack * config.burn_damage_per_stack
	if context.player_shield_stack > 0:
		raw_damage = raw_damage / 2
	if raw_damage < 1 and context.player_burn_stack > 0:
		raw_damage = 1

	var packet = DAMAGE_PACKET.new()
	packet.setup({
		"packet_id": "burn_%d" % context.time_ms,
		"source_id": "player_burn",
		"source_layer": "system",
		"target_id": "player_core",
		"target_layer": "player_core",
		"damage_kind": "burn",
		"damage_type": "burn",
		"raw_damage": raw_damage,
		"can_crit": false,
		"can_trigger_lifesteal": false,
		"can_trigger_on_damage_hooks": false,
	})
	var result = damage_resolver.apply_to_player_core(context, packet, config, logger)
	context.player_burn_stack -= 1
	if context.player_burn_stack < 0:
		context.player_burn_stack = 0
	logger.log(context, {
		"event_type": "PLAYER_BURN_TICK",
		"source_id": "player_burn",
		"target_id": "player_core",
		"effect_type": "burn",
		"raw_damage": packet.raw_damage,
		"actual_hp_damage": result.actual_hp_damage,
		"shield_damage": result.shield_damage,
		"burn_before": burn_before,
		"burn_after": context.player_burn_stack,
		"cause": "burn_halved_by_shield_then_decay",
	})
	return result

