extends RefCounted
class_name GenericDotStatus

# 文件职责：
# - 保存作用于敌人的通用 DOT 状态。
# - V1 默认 DOT 不暴击、不吸血、不触发连锁，但可以击杀敌人。

var status_instance_id: String = ""
var status_id: String = ""
var source_id: String = ""
var target_enemy_id: String = ""
var damage_type: String = "dot"
var damage_per_tick: int = 0
var stack_count: int = 1
var max_stacks: int = 1
var stack_rule: String = "refresh"
var tick_interval_ms: int = 1000
var end_time_ms: int = 0
var next_tick_time_ms: int = 0
var version: int = 0


func setup(data: Dictionary) -> void:
	status_instance_id = data.get("status_instance_id", status_instance_id)
	status_id = data.get("status_id", status_id)
	source_id = data.get("source_id", source_id)
	target_enemy_id = data.get("target_enemy_id", target_enemy_id)
	damage_type = data.get("damage_type", damage_type)
	damage_per_tick = data.get("damage_per_tick", damage_per_tick)
	stack_count = data.get("stack_count", stack_count)
	max_stacks = data.get("max_stacks", max_stacks)
	stack_rule = data.get("stack_rule", stack_rule)
	tick_interval_ms = data.get("tick_interval_ms", tick_interval_ms)
	end_time_ms = data.get("end_time_ms", end_time_ms)
	next_tick_time_ms = data.get("next_tick_time_ms", next_tick_time_ms)
	version = data.get("version", version)

