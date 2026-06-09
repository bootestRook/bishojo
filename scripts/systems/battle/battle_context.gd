extends RefCounted
class_name BattleContext

const BATTLE_EVENT_QUEUE = preload("res://scripts/systems/battle/battle_event_queue.gd")

# 文件职责：
# - 持有单场战斗的全部可复盘状态。
# - Runner 只推进该上下文，不访问 UI、动画、场景节点或 Autoload。

var battle_id: String = ""
var battle_type: String = "normal"
var time_ms: int = 0
var battle_seed: int = 0
var rng_roll_index: int = 0
var player_core_hp: int = 0
var player_core_hp_max: int = 0
var player_shield_stack: int = 0
var player_poison_stack: int = 0
var player_poison_end_time_ms: int = 0
var player_burn_stack: int = 0
var next_poison_tick_time_ms: int = 0
var next_burn_tick_time_ms: int = 0
var poison_tick_version: int = 0
var burn_tick_version: int = 0
var player_units: Array = []
var enemies: Array = []
var event_queue = BATTLE_EVENT_QUEUE.new()
var next_event_sequence_id: int = 0
var chain_event_count_this_time: int = 0
var current_chain_time_ms: int = -1
var is_finished: bool = false
var result: String = ""
var timeline_log: Array = []
var debug_notes: Array = []


func get_alive_enemies() -> Array:
	var result_array: Array = []
	var index: int = 0
	while index < enemies.size():
		if enemies[index].is_alive and enemies[index].hp > 0:
			result_array.append(enemies[index])
		index += 1

	return result_array


func get_alive_units() -> Array:
	var result_array: Array = []
	var index: int = 0
	while index < player_units.size():
		if player_units[index].is_alive:
			result_array.append(player_units[index])
		index += 1

	return result_array
