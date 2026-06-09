extends RefCounted
class_name EnemyActionScheduler

const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")
const DAMAGE_PACKET = preload("res://scripts/systems/battle/damage_packet.gd")

# 文件职责：
# - 调度敌人按 attack_interval_ms 攻击玩家核心。
# - 敌人攻击统一走 DamagePacket，V1 默认不可暴击。


func schedule_enemy_action(context, enemy) -> void:
	if enemy.attack_interval_ms <= 0 or not enemy.is_alive:
		return
	context.next_event_sequence_id += 1
	var event = BATTLE_EVENT.new()
	event.setup({
		"event_id": "event_%d" % context.next_event_sequence_id,
		"event_type": "ENEMY_ACTION",
		"trigger_time_ms": enemy.next_action_time_ms,
		"priority": 40,
		"sequence_id": context.next_event_sequence_id,
		"source_id": enemy.enemy_id,
		"target_id": "player_core",
	})
	context.event_queue.push(event)


func handle_action(context, event, config, damage_resolver, player_status_resolver, logger) -> void:
	var enemy = _find_enemy(context, event.source_id)
	if enemy == null or not enemy.is_alive:
		return

	logger.log(context, {
		"event_type": "ENEMY_ACTION",
		"source_id": enemy.enemy_id,
		"target_id": "player_core",
		"raw_damage": enemy.attack_damage,
		"cause": "attack_interval",
	})
	var packet = DAMAGE_PACKET.new()
	packet.setup({
		"packet_id": "enemy_attack_%d" % context.time_ms,
		"source_id": enemy.enemy_id,
		"source_layer": "enemy",
		"target_id": "player_core",
		"target_layer": "player_core",
		"damage_kind": "enemy_attack",
		"damage_type": "physical",
		"raw_damage": enemy.attack_damage,
		"can_crit": false,
		"can_trigger_lifesteal": false,
		"can_trigger_on_damage_hooks": false,
		"damage_taken_bonus_bp": enemy.stats.damage_bonus_bp,
	})
	damage_resolver.apply_to_player_core(context, packet, config, logger)
	_apply_enemy_effects(context, enemy, player_status_resolver, logger)
	if context.player_core_hp > 0 and enemy.is_alive:
		enemy.next_action_time_ms = context.time_ms + enemy.attack_interval_ms
		schedule_enemy_action(context, enemy)


func _apply_enemy_effects(context, enemy, player_status_resolver, logger) -> void:
	var index: int = 0
	while index < enemy.effect_list.size():
		var effect: Dictionary = enemy.effect_list[index]
		match effect.get("effect_type", ""):
			"apply_poison_to_player":
				player_status_resolver.apply_poison(context, effect.get("value", effect.get("stack", 1)), effect.get("duration_ms", 0), logger, enemy.enemy_id)
			"apply_burn_to_player":
				player_status_resolver.apply_burn(context, effect.get("value", effect.get("stack", 1)), logger, enemy.enemy_id)
			_:
				pass
		index += 1


func _find_enemy(context, enemy_id: String):
	var index: int = 0
	while index < context.enemies.size():
		if context.enemies[index].enemy_id == enemy_id:
			return context.enemies[index]
		index += 1

	return null

