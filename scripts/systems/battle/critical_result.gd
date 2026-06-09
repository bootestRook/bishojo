extends RefCounted
class_name CriticalResult

# 文件职责：
# - 保存一次暴击判定的完整复盘数据。

var battle_seed: int = 0
var rng_roll_index: int = -1
var roll_type: String = "crit"
var roll_value_bp: int = -1
var threshold_bp: int = 0
var result: bool = false
var crit_damage_bp: int = 15000


func setup(data: Dictionary) -> void:
	battle_seed = data.get("battle_seed", battle_seed)
	rng_roll_index = data.get("rng_roll_index", rng_roll_index)
	roll_type = data.get("roll_type", roll_type)
	roll_value_bp = data.get("roll_value_bp", roll_value_bp)
	threshold_bp = data.get("threshold_bp", threshold_bp)
	result = data.get("result", result)
	crit_damage_bp = data.get("crit_damage_bp", crit_damage_bp)

