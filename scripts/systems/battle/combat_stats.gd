extends RefCounted
class_name CombatStats

# 文件职责：
# - 保存战斗参与者的可叠加数值属性。
# - V1 只让伤害、暴击、承伤、减伤和吸血消费这些字段，避免技能里散写临时公式。

var damage_bonus_bp: int = 0
var dot_damage_bonus_bp: int = 0
var crit_rate_bp: int = 0
var crit_damage_bp: int = 15000
var crit_rate_bonus_bp: int = 0
var crit_damage_bonus_bp: int = 0
var damage_taken_bonus_bp: int = 0
var dot_damage_taken_bonus_bp: int = 0
var crit_resist_bp: int = 0
var damage_reduce_flat: int = 0
var lifesteal_bp: int = 0


func setup(data: Dictionary) -> void:
	damage_bonus_bp = data.get("damage_bonus_bp", damage_bonus_bp)
	dot_damage_bonus_bp = data.get("dot_damage_bonus_bp", dot_damage_bonus_bp)
	crit_rate_bp = data.get("crit_rate_bp", crit_rate_bp)
	crit_damage_bp = data.get("crit_damage_bp", crit_damage_bp)
	crit_rate_bonus_bp = data.get("crit_rate_bonus_bp", crit_rate_bonus_bp)
	crit_damage_bonus_bp = data.get("crit_damage_bonus_bp", crit_damage_bonus_bp)
	damage_taken_bonus_bp = data.get("damage_taken_bonus_bp", damage_taken_bonus_bp)
	dot_damage_taken_bonus_bp = data.get("dot_damage_taken_bonus_bp", dot_damage_taken_bonus_bp)
	crit_resist_bp = data.get("crit_resist_bp", crit_resist_bp)
	damage_reduce_flat = data.get("damage_reduce_flat", damage_reduce_flat)
	lifesteal_bp = data.get("lifesteal_bp", lifesteal_bp)

