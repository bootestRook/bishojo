extends RefCounted
class_name EffectResolver

const DAMAGE_PACKET = preload("res://scripts/systems/battle/damage_packet.gd")
const TARGET_RESOLVER = preload("res://scripts/systems/battle/target_resolver.gd")
const CHARGE_RESOLVER = preload("res://scripts/systems/battle/charge_resolver.gd")
const CARD_STATUS_RESOLVER = preload("res://scripts/systems/battle/card_status_resolver.gd")
const PLAYER_STATUS_RESOLVER = preload("res://scripts/systems/battle/player_status_resolver.gd")
const LIFESTEAL_RESOLVER = preload("res://scripts/systems/battle/lifesteal_resolver.gd")
const GENERIC_DOT_RESOLVER = preload("res://scripts/systems/battle/generic_dot_resolver.gd")

# 文件职责：
# - 按 effect_list 顺序执行秘宝少女技能效果。
# - 每个 effect 先解析目标，再执行伤害、护盾、治疗、充能、状态或 DOT。

var target_resolver = TARGET_RESOLVER.new()
var charge_resolver = CHARGE_RESOLVER.new()
var card_status_resolver = CARD_STATUS_RESOLVER.new()
var player_status_resolver = PLAYER_STATUS_RESOLVER.new()
var lifesteal_resolver = LIFESTEAL_RESOLVER.new()
var generic_dot_resolver = GENERIC_DOT_RESOLVER.new()


func resolve_effect(context, source_unit, effect, config, cooldown_scheduler, damage_resolver, logger, chain_depth: int = 0) -> void:
	var targets: Array = target_resolver.resolve_targets(context, source_unit, effect.target_rule, logger)
	var index: int = 0
	while index < targets.size() and not context.is_finished:
		var target = targets[index]
		match effect.effect_type:
			"damage":
				_apply_damage(context, source_unit, target, effect, config, damage_resolver, logger)
			"shield":
				player_status_resolver.add_shield(context, effect.get_value(source_unit.rarity), config, logger, source_unit.instance_id)
			"heal":
				player_status_resolver.heal_player(context, effect.get_value(source_unit.rarity), config, logger, source_unit.instance_id)
			"charge":
				charge_resolver.apply_charge(context, source_unit, target, effect.get_value(source_unit.rarity), cooldown_scheduler, logger, chain_depth)
			"apply_haste":
				card_status_resolver.apply_haste(context, target, effect.duration_ms, cooldown_scheduler, logger)
			"apply_slow":
				card_status_resolver.apply_slow(context, target, effect.duration_ms, cooldown_scheduler, logger)
			"apply_freeze":
				card_status_resolver.apply_freeze(context, target, effect.duration_ms, cooldown_scheduler, logger)
			"apply_lifesteal":
				_apply_lifesteal_status(context, target, effect, logger, source_unit.instance_id)
			"apply_poison_to_player":
				player_status_resolver.apply_poison(context, effect.get_value(source_unit.rarity), effect.duration_ms, logger, source_unit.instance_id)
			"apply_burn_to_player":
				player_status_resolver.apply_burn(context, effect.get_value(source_unit.rarity), logger, source_unit.instance_id)
			"apply_dot_to_enemy":
				generic_dot_resolver.apply_dot(context, source_unit, target, effect, config, logger)
			"buff", "gold":
				# `buff` 和 `gold` 当前是目录里的非战斗型数据承诺；战斗层只识别并记录，真实收益由后续 Run/奖励系统承接。
				logger.log(context, {
					"event_type": "EFFECT_NON_COMBAT_DATA",
					"source_id": source_unit.instance_id,
					"target_id": "non_combat_target",
					"effect_type": effect.effect_type,
					"cause": "recognized_non_battle_effect",
				})
			_:
				logger.log(context, {
					"event_type": "EFFECT_IGNORED",
					"source_id": source_unit.instance_id,
					"effect_type": effect.effect_type,
					"cause": "unsupported_or_non_battle_effect",
				})
		index += 1


func _apply_damage(context, source_unit, target_enemy, effect, config, damage_resolver, logger) -> void:
	var packet = DAMAGE_PACKET.new()
	var raw_damage: int = effect.get_value(source_unit.rarity)
	var crit_rate: int = config.base_crit_rate_bp + source_unit.stats.crit_rate_bp + source_unit.stats.crit_rate_bonus_bp
	var crit_damage: int = config.base_crit_damage_bp
	if source_unit.stats.crit_damage_bp > 0:
		crit_damage = source_unit.stats.crit_damage_bp
	crit_damage += source_unit.stats.crit_damage_bonus_bp
	packet.setup({
		"packet_id": "damage_%d_%s" % [context.time_ms, source_unit.instance_id],
		"source_id": source_unit.instance_id,
		"source_layer": "player_card",
		"target_id": target_enemy.enemy_id,
		"target_layer": "enemy",
		"damage_kind": "direct",
		"damage_type": effect.damage_type,
		"raw_damage": raw_damage,
		"can_crit": effect.can_crit,
		"crit_rate_bp": crit_rate,
		"crit_damage_bp": crit_damage,
		"damage_bonus_bp": source_unit.stats.damage_bonus_bp,
		"damage_taken_bonus_bp": target_enemy.stats.damage_taken_bonus_bp,
		"damage_reduce_flat": target_enemy.stats.damage_reduce_flat,
		"can_trigger_lifesteal": effect.can_trigger_lifesteal,
		"can_trigger_on_damage_hooks": effect.can_trigger_on_damage_hooks,
	})
	var damage_result = damage_resolver.apply_to_enemy(context, packet, target_enemy, config, logger)
	if packet.can_trigger_lifesteal:
		lifesteal_resolver.apply_lifesteal(context, source_unit, damage_result, logger)


func _apply_lifesteal_status(context, target_unit, effect, logger, source_id: String) -> void:
	var before: int = target_unit.lifesteal_bp
	var value: int = effect.get_value(target_unit.rarity)
	if value <= 0:
		value = 10000
	target_unit.lifesteal_bp = value
	logger.log(context, {
		"event_type": "APPLY_LIFESTEAL",
		"source_id": source_id,
		"target_id": target_unit.instance_id,
		"lifesteal_bp": value,
		"stack_before": before,
		"stack_after": target_unit.lifesteal_bp,
		"cause": "effect",
	})
