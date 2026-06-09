extends RefCounted
class_name V1InitialRunConfig

# 文件职责：
# - 保存新局初始化需要写入 RunManager 的最小配置。
# - `initial_gold` 在总案中仍为“待定”，当前使用 0 作为明确占位，后续数值表确认后只改配置层。

var initial_gold: int = 0
var run_durability: int = 5
var run_durability_max: int = 5
var normal_win_count: int = 0
var normal_win_target: int = 10


func to_data() -> Dictionary:
	return {
		"initial_gold": initial_gold,
		"run_durability": run_durability,
		"run_durability_max": run_durability_max,
		"normal_win_count": normal_win_count,
		"normal_win_target": normal_win_target,
	}
