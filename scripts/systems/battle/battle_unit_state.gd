extends RefCounted
class_name BattleUnitState

const COMBAT_STATS = preload("res://scripts/systems/battle/combat_stats.gd")

# 文件职责：
# - 表示一场战斗中被锁定站位后的秘宝少女战斗快照。
# - 冷却必须由 remaining_cooldown_ms + cooldown_rate_bp + last_cooldown_update_time_ms 表达，禁止退化成单一 next_ready_time。

var instance_id: String = ""
var treasure_id: String = ""
var treasure_name: String = ""
var rarity: String = "green"
var slot_ids: Array = []
var row: int = 0
var col_start: int = 0
var col_end: int = 0
var size_type: String = "small"
var base_cooldown_ms: int = 0
var remaining_cooldown_ms: int = 0
var last_cooldown_update_time_ms: int = 0
var cooldown_rate_bp: int = 10000
var cooldown_version: int = 0
var last_trigger_time_ms: int = -999999
var haste_stack: int = 0
var slow_stack: int = 0
var freeze_stack: int = 0
var haste_end_time_ms: int = 0
var slow_end_time_ms: int = 0
var freeze_end_time_ms: int = 0
var lifesteal_bp: int = 0
var is_ready_blocked_by_freeze: bool = false
var stats = COMBAT_STATS.new()
var effect_list: Array = []
var tags: Array = []
var is_alive: bool = true


func has_tag(tag: String) -> bool:
	return tags.has(tag)

