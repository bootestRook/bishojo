extends RefCounted
class_name BattleRunner

const BATTLE_CONFIG = preload("res://scripts/systems/battle/battle_config.gd")
const BATTLE_EVENT = preload("res://scripts/systems/battle/battle_event.gd")
const BATTLE_TIMELINE_LOGGER = preload("res://scripts/systems/battle/battle_timeline_logger.gd")
const COOLDOWN_SCHEDULER = preload("res://scripts/systems/battle/cooldown_scheduler.gd")
const EFFECT_RESOLVER = preload("res://scripts/systems/battle/effect_resolver.gd")
const DAMAGE_RESOLVER = preload("res://scripts/systems/battle/damage_resolver.gd")
const PLAYER_STATUS_RESOLVER = preload("res://scripts/systems/battle/player_status_resolver.gd")
const CARD_STATUS_RESOLVER = preload("res://scripts/systems/battle/card_status_resolver.gd")
const GENERIC_DOT_RESOLVER = preload("res://scripts/systems/battle/generic_dot_resolver.gd")
const ENEMY_ACTION_SCHEDULER = preload("res://scripts/systems/battle/enemy_action_scheduler.gd")
const CHAIN_GUARD = preload("res://scripts/systems/battle/chain_guard.gd")

# 文件职责：
# - 推进单场战斗的事件循环。
# - 负责冷却初始化、敌人行动、超时、胜负检查和 BattleResult 输出。

var config = BATTLE_CONFIG.new()
var logger = BATTLE_TIMELINE_LOGGER.new()
var cooldown_scheduler = COOLDOWN_SCHEDULER.new()
var effect_resolver = EFFECT_RESOLVER.new()
var damage_resolver = DAMAGE_RESOLVER.new()
var player_status_resolver = PLAYER_STATUS_RESOLVER.new()
var card_status_resolver = CARD_STATUS_RESOLVER.new()
var generic_dot_resolver = GENERIC_DOT_RESOLVER.new()
var enemy_action_scheduler = ENEMY_ACTION_SCHEDULER.new()
var chain_guard = CHAIN_GUARD.new()


func run(context) -> Dictionary:
	_initialize_events(context)
	while not context.is_finished and not context.event_queue.is_empty():
		var event = context.event_queue.pop()
		context.time_ms = event.trigger_time_ms
		if chain_guard.should_delay_event(context, event, config, logger):
			context.event_queue.push(event)
			continue
		_process_event(context, event)
		_check_finish(context)

	if not context.is_finished:
		_finish(context, "timeout", "event_queue_empty")

	return _make_result(context)


func _initialize_events(context) -> void:
	logger.log(context, {
		"event_type": "BATTLE_START",
		"source_id": "battle_runner",
		"cause": context.battle_type,
	})
	var unit_index: int = 0
	while unit_index < context.player_units.size():
		cooldown_scheduler.initialize_unit_cooldown(context, context.player_units[unit_index], config, logger)
		unit_index += 1

	var enemy_index: int = 0
	while enemy_index < context.enemies.size():
		enemy_action_scheduler.schedule_enemy_action(context, context.enemies[enemy_index])
		enemy_index += 1

	_schedule_timeout(context)


func _process_event(context, event) -> void:
	match event.event_type:
		"PLAYER_COOLDOWN_CHECK":
			_handle_cooldown_check(context, event)
		"PLAYER_TRIGGER_SKILL":
			_handle_player_trigger(context, event)
		"CARD_STATUS_EXPIRE":
			_handle_card_status_expire(context, event)
		"PLAYER_POISON_TICK":
			_handle_poison_tick(context, event)
		"PLAYER_BURN_TICK":
			_handle_burn_tick(context, event)
		"GENERIC_DOT_TICK":
			generic_dot_resolver.handle_tick(context, event, config, damage_resolver, logger)
		"ENEMY_ACTION":
			enemy_action_scheduler.handle_action(context, event, config, damage_resolver, player_status_resolver, logger)
		"BATTLE_TIMEOUT":
			_finish(context, "timeout", "battle_timeout")
		_:
			logger.log(context, {
				"event_type": "UNKNOWN_EVENT_IGNORED",
				"source_id": event.source_id,
				"target_id": event.target_id,
				"cause": event.event_type,
			})
	_ensure_player_status_ticks(context)


func _handle_cooldown_check(context, event) -> void:
	var unit = _find_unit(context, event.source_id)
	if unit == null or not unit.is_alive:
		return
	if event.version != unit.cooldown_version:
		logger.log(context, {
			"event_type": "COOLDOWN_OLD_EVENT_IGNORED",
			"source_id": unit.instance_id,
			"cause": "version_mismatch",
		})
		return
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, "natural_cooldown_check")
	if unit.remaining_cooldown_ms > 0:
		cooldown_scheduler.schedule_next_cooldown_check(context, unit)
		return
	if unit.freeze_stack > 0:
		unit.is_ready_blocked_by_freeze = true
		logger.log(context, {
			"event_type": "PLAYER_TRIGGER_BLOCKED_BY_FREEZE",
			"source_id": unit.instance_id,
			"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
			"was_blocked_by_freeze": true,
			"cause": "natural_cooldown",
		})
		return
	cooldown_scheduler.enqueue_player_trigger(context, unit, 10, "natural_cooldown", event.chain_depth)


func _handle_player_trigger(context, event) -> void:
	var unit = _find_unit(context, event.source_id)
	if unit == null or not unit.is_alive:
		return
	cooldown_scheduler.update_cooldown_to_now(context, unit, logger, "skill_trigger_check")
	if unit.freeze_stack > 0:
		unit.is_ready_blocked_by_freeze = true
		logger.log(context, {
			"event_type": "PLAYER_TRIGGER_BLOCKED_BY_FREEZE",
			"source_id": unit.instance_id,
			"remaining_cooldown_after_ms": unit.remaining_cooldown_ms,
			"was_blocked_by_freeze": true,
			"cause": event.payload.get("cause", "trigger"),
		})
		return
	if not chain_guard.can_unit_trigger_now(context, unit, config):
		event.trigger_time_ms = chain_guard.next_allowed_trigger_time(unit, config)
		context.event_queue.push(event)
		logger.log(context, {
			"event_type": "PLAYER_TRIGGER_DELAYED",
			"source_id": unit.instance_id,
			"cause": "min_trigger_interval_ms",
		})
		return

	logger.log(context, {
		"event_type": "PLAYER_TRIGGER_SKILL",
		"source_id": unit.instance_id,
		"remaining_cooldown_before_ms": unit.remaining_cooldown_ms,
		"cause": event.payload.get("cause", "trigger"),
		"chain_depth": event.chain_depth,
	})
	unit.last_trigger_time_ms = context.time_ms
	cooldown_scheduler.reset_unit_cooldown(context, unit, logger)
	var index: int = 0
	while index < unit.effect_list.size() and not context.is_finished:
		effect_resolver.resolve_effect(context, unit, unit.effect_list[index], config, cooldown_scheduler, damage_resolver, logger, event.chain_depth)
		_check_finish(context)
		index += 1


func _handle_card_status_expire(context, event) -> void:
	var unit = _find_unit(context, event.source_id)
	if unit == null:
		return
	card_status_resolver.expire_status(context, unit, event.payload.get("status_id", ""), cooldown_scheduler, logger)


func _handle_poison_tick(context, event) -> void:
	if event.version != context.poison_tick_version:
		return
	context.next_poison_tick_time_ms = 0
	player_status_resolver.tick_poison(context, config, damage_resolver, logger)


func _handle_burn_tick(context, event) -> void:
	if event.version != context.burn_tick_version:
		return
	context.next_burn_tick_time_ms = 0
	player_status_resolver.tick_burn(context, config, damage_resolver, logger)


func _ensure_player_status_ticks(context) -> void:
	if context.player_poison_stack > 0 and context.next_poison_tick_time_ms <= context.time_ms:
		context.poison_tick_version += 1
		context.next_poison_tick_time_ms = context.time_ms + config.poison_tick_interval_ms
		_enqueue_simple_event(context, "PLAYER_POISON_TICK", context.next_poison_tick_time_ms, 50, "player_poison", "player_core", context.poison_tick_version)
	elif context.player_poison_stack <= 0:
		context.next_poison_tick_time_ms = 0

	if context.player_burn_stack > 0 and context.next_burn_tick_time_ms <= context.time_ms:
		context.burn_tick_version += 1
		context.next_burn_tick_time_ms = context.time_ms + config.burn_tick_interval_ms
		_enqueue_simple_event(context, "PLAYER_BURN_TICK", context.next_burn_tick_time_ms, 55, "player_burn", "player_core", context.burn_tick_version)
	elif context.player_burn_stack <= 0:
		context.next_burn_tick_time_ms = 0


func _schedule_timeout(context) -> void:
	var timeout_ms: int = config.normal_timeout_ms
	if context.battle_type == "boss":
		timeout_ms = config.boss_timeout_ms
	_enqueue_simple_event(context, "BATTLE_TIMEOUT", timeout_ms, 90, "battle_runner", "battle", 0)


func _enqueue_simple_event(context, event_type: String, trigger_time_ms: int, priority: int, source_id: String, target_id: String, version: int) -> void:
	context.next_event_sequence_id += 1
	var event = BATTLE_EVENT.new()
	event.setup({
		"event_id": "event_%d" % context.next_event_sequence_id,
		"event_type": event_type,
		"trigger_time_ms": trigger_time_ms,
		"priority": priority,
		"sequence_id": context.next_event_sequence_id,
		"source_id": source_id,
		"target_id": target_id,
		"version": version,
	})
	context.event_queue.push(event)


func _check_finish(context) -> void:
	if context.is_finished:
		return
	if context.player_core_hp <= 0:
		_finish(context, "lose", "player_core_hp_zero")
		return
	if context.get_alive_enemies().is_empty():
		_finish(context, "win", "all_enemies_defeated")


func _finish(context, result: String, cause: String) -> void:
	if context.is_finished:
		return
	context.is_finished = true
	context.result = result
	logger.log(context, {
		"event_type": "BATTLE_FINISH",
		"source_id": "battle_runner",
		"target_id": "battle",
		"cause": cause,
	})


func _make_result(context) -> Dictionary:
	return {
		"result": context.result,
		"battle_type": context.battle_type,
		"time_ms": context.time_ms,
		"enemy_ids": _enemy_ids(context),
		"player_core_hp_after": context.player_core_hp,
		"timeline_log": context.timeline_log,
		"summary": {
			"timeline_count": context.timeline_log.size(),
			"remaining_enemy_count": context.get_alive_enemies().size(),
			"battle_seed": context.battle_seed,
		},
	}


func _enemy_ids(context) -> Array:
	var result: Array = []
	var index: int = 0
	while index < context.enemies.size():
		result.append(context.enemies[index].enemy_id)
		index += 1
	return result


func _find_unit(context, instance_id: String):
	var index: int = 0
	while index < context.player_units.size():
		if context.player_units[index].instance_id == instance_id:
			return context.player_units[index]
		index += 1
	return null

