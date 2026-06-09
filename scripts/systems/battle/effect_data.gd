extends RefCounted
class_name EffectData

# 文件职责：
# - 统一承接秘宝少女和敌人配置中的 effect_list 项。
# - 兼容当前 catalog 里已有的 value / value_ms / value_bp 字段，避免战斗层反向要求重写配置。

var effect_id: String = ""
var effect_type: String = ""
var target_rule: String = ""
var value: int = 0
var value_by_rarity: Dictionary = {}
var duration_ms: int = 0
var tick_interval_ms: int = 0
var max_stacks: int = 1
var stack_rule: String = "refresh"
var can_crit: bool = true
var can_trigger_lifesteal: bool = false
var can_trigger_on_damage_hooks: bool = false
var tags: Array = []
var status_id: String = ""
var damage_type: String = "physical"


func setup(data: Dictionary) -> void:
	effect_id = data.get("effect_id", "")
	effect_type = data.get("effect_type", "")
	target_rule = data.get("target_rule", "")
	value = data.get("value", data.get("value_ms", data.get("value_bp", data.get("stack", 0))))
	value_by_rarity = data.get("value_by_rarity", {}).duplicate(true)
	duration_ms = data.get("duration_ms", 0)
	tick_interval_ms = data.get("tick_interval_ms", 0)
	max_stacks = data.get("max_stacks", 1)
	stack_rule = data.get("stack_rule", "refresh")
	can_crit = data.get("can_crit", true)
	can_trigger_lifesteal = data.get("can_trigger_lifesteal", false)
	can_trigger_on_damage_hooks = data.get("can_trigger_on_damage_hooks", false)
	tags = data.get("tags", []).duplicate()
	status_id = data.get("status_id", effect_type)
	damage_type = data.get("damage_type", _default_damage_type(effect_type))


func get_value(rarity: String) -> int:
	if value_by_rarity.has(rarity):
		return value_by_rarity.get(rarity, value)

	return value


func _default_damage_type(type: String) -> String:
	match type:
		"apply_burn_to_player":
			return "burn"
		"apply_poison_to_player":
			return "poison"
		"apply_dot_to_enemy":
			return "dot"
		_:
			return "physical"

