extends RefCounted
class_name DamagePacket

# 文件职责：
# - 统一描述一次待结算伤害。
# - 直接伤害、敌人攻击、DOT、剧毒和燃烧都必须进入等价结构后再结算。

var packet_id: String = ""
var source_id: String = ""
var source_layer: String = ""
var target_id: String = ""
var target_layer: String = ""
var damage_kind: String = "direct"
var damage_type: String = "physical"
var raw_damage: int = 0
var can_crit: bool = true
var crit_rate_bp: int = 0
var crit_damage_bp: int = 15000
var damage_bonus_bp: int = 0
var damage_taken_bonus_bp: int = 0
var damage_reduce_flat: int = 0
var can_trigger_lifesteal: bool = false
var can_trigger_on_damage_hooks: bool = false
var status_instance_id: String = ""
var tags: Array = []


func setup(data: Dictionary) -> void:
	packet_id = data.get("packet_id", packet_id)
	source_id = data.get("source_id", source_id)
	source_layer = data.get("source_layer", source_layer)
	target_id = data.get("target_id", target_id)
	target_layer = data.get("target_layer", target_layer)
	damage_kind = data.get("damage_kind", damage_kind)
	damage_type = data.get("damage_type", damage_type)
	raw_damage = data.get("raw_damage", raw_damage)
	can_crit = data.get("can_crit", can_crit)
	crit_rate_bp = data.get("crit_rate_bp", crit_rate_bp)
	crit_damage_bp = data.get("crit_damage_bp", crit_damage_bp)
	damage_bonus_bp = data.get("damage_bonus_bp", damage_bonus_bp)
	damage_taken_bonus_bp = data.get("damage_taken_bonus_bp", damage_taken_bonus_bp)
	damage_reduce_flat = data.get("damage_reduce_flat", damage_reduce_flat)
	can_trigger_lifesteal = data.get("can_trigger_lifesteal", can_trigger_lifesteal)
	can_trigger_on_damage_hooks = data.get("can_trigger_on_damage_hooks", can_trigger_on_damage_hooks)
	status_instance_id = data.get("status_instance_id", status_instance_id)
	tags = data.get("tags", []).duplicate()

