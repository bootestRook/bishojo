extends RefCounted
class_name GenericDotResolver

const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")
const DAMAGE_PACKET = preload("res://scripts/systems/battle/damage_packet.gd")
const GENERIC_DOT_STATUS = preload("res://scripts/systems/battle/generic_dot_status.gd")

# 文件职责：
# - 处理对敌通用 DOT 的施加、刷新、叠层和 tick。
# - DOT 伤害统一走 DamagePacket，默认不暴击、不吸血、不触发连锁。


func apply_dot(context, source_unit, enemy, effect, config, logger) -> void:
	if effect.tick_interval_ms <= 0 or effect.duration_ms <= 0:
		logger.log(context, {
			"event_type": "DOT_REJECTED",
			"source_id": source_unit.instance_id,
			"target_id": enemy.enemy_id,
			"effect_type": "apply_dot_to_enemy",
			"cause": "invalid_duration_or_interval",
		})
		return
	if effect.duration_ms % effect.tick_interval_ms != 0:
		logger.log(context, {
			"event_type": "DOT_REJECTED",
			"source_id": source_unit.instance_id,
			"target_id": enemy.enemy_id,
			"effect_type": "apply_dot_to_enemy",
			"cause": "duration_not_divisible_by_tick_interval",
		})
		return

	var status_key: String = source_unit.instance_id + "_" + effect.status_id
	var status = enemy.status_map.get(status_key, null)
	if status == null:
		status = GENERIC_DOT_STATUS.new()
		status.setup({
			"status_instance_id": status_key,
			"status_id": effect.status_id,
			"source_id": source_unit.instance_id,
			"target_enemy_id": enemy.enemy_id,
			"damage_type": effect.damage_type,
			"damage_per_tick": effect.get_value(source_unit.rarity),
			"stack_count": 1,
			"max_stacks": effect.max_stacks,
			"stack_rule": effect.stack_rule,
			"tick_interval_ms": effect.tick_interval_ms,
			"end_time_ms": context.time_ms + effect.duration_ms,
			"next_tick_time_ms": context.time_ms + effect.tick_interval_ms,
			"version": 1,
		})
		enemy.status_map[status_key] = status
	else:
		status.version += 1
		status.end_time_ms = context.time_ms + effect.duration_ms
		if effect.stack_rule == "stack_intensity":
			status.stack_count += 1
			if status.stack_count > status.max_stacks:
				status.stack_count = status.max_stacks

	logger.log(context, {
		"event_type": "APPLY_DOT",
		"source_id": source_unit.instance_id,
		"target_id": enemy.enemy_id,
		"effect_type": "apply_dot_to_enemy",
		"damage_kind": "dot_tick",
		"raw_damage": status.damage_per_tick * status.stack_count,
		"cause": status.stack_rule,
	})
	_enqueue_dot_tick(context, status)


func handle_tick(context, event, config, damage_resolver, logger) -> void:
	var enemy = _find_enemy(context, event.target_id)
	if enemy == null or not enemy.is_alive:
		return
	var status = enemy.status_map.get(event.payload.get("status_instance_id", ""), null)
	if status == null:
		return
	if event.version != status.version:
		logger.log(context, {
			"event_type": "DOT_OLD_TICK_IGNORED",
			"source_id": event.source_id,
			"target_id": event.target_id,
			"cause": "version_mismatch",
		})
		return
	if context.time_ms > status.end_time_ms:
		enemy.status_map.erase(status.status_instance_id)
		return

	var packet = DAMAGE_PACKET.new()
	packet.setup({
		"packet_id": "dot_%d" % context.time_ms,
		"source_id": status.source_id,
		"source_layer": "player_card",
		"target_id": enemy.enemy_id,
		"target_layer": "enemy",
		"damage_kind": "dot_tick",
		"damage_type": status.damage_type,
		"raw_damage": status.damage_per_tick * status.stack_count,
		"can_crit": false,
		"can_trigger_lifesteal": false,
		"can_trigger_on_damage_hooks": false,
		"status_instance_id": status.status_instance_id,
	})
	damage_resolver.apply_to_enemy(context, packet, enemy, config, logger)
	logger.log(context, {
		"event_type": "GENERIC_DOT_TICK",
		"source_id": status.source_id,
		"target_id": enemy.enemy_id,
		"effect_type": "apply_dot_to_enemy",
		"raw_damage": packet.raw_damage,
		"cause": "dot_no_crit_no_lifesteal_no_chain",
	})
	status.next_tick_time_ms = context.time_ms + status.tick_interval_ms
	if enemy.is_alive and status.next_tick_time_ms <= status.end_time_ms:
		_enqueue_dot_tick(context, status)


func _enqueue_dot_tick(context, status) -> void:
	context.next_event_sequence_id += 1
	var event = BATTLE_EVENT.new()
	event.setup({
		"event_id": "event_%d" % context.next_event_sequence_id,
		"event_type": "GENERIC_DOT_TICK",
		"trigger_time_ms": status.next_tick_time_ms,
		"priority": 27,
		"sequence_id": context.next_event_sequence_id,
		"source_id": status.source_id,
		"target_id": status.target_enemy_id,
		"version": status.version,
		"payload": {"status_instance_id": status.status_instance_id},
	})
	context.event_queue.push(event)


func _find_enemy(context, enemy_id: String):
	var index: int = 0
	while index < context.enemies.size():
		if context.enemies[index].enemy_id == enemy_id:
			return context.enemies[index]
		index += 1

	return null

