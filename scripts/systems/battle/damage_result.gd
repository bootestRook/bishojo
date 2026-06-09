extends RefCounted
class_name DamageResult

# 文件职责：
# - 保存一次 DamagePacket 的结算结果。
# - actual_hp_damage 明确排除护盾吸收与溢出伤害，是吸血的唯一依据。

var packet_id: String = ""
var raw_damage: int = 0
var pre_crit_damage: int = 0
var final_damage: int = 0
var shield_damage: int = 0
var actual_hp_damage: int = 0
var target_hp_before: int = 0
var target_hp_after: int = 0
var target_shield_before: int = 0
var target_shield_after: int = 0
var can_crit: bool = false
var crit_rate_bp: int = 0
var crit_roll_bp: int = -1
var is_crit: bool = false
var crit_damage_bp: int = 0
var damage_kind: String = ""
var damage_type: String = ""

