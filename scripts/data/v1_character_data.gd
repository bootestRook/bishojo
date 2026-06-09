extends RefCounted
class_name V1CharacterData

# 文件职责：
# - 定义 V1 阶段唯一可选角色的最小数据结构。
# - 角色能力字段只作为后续扩展入口，当前不影响战斗、商店、初始营地或任何数值。

const DEFAULT_CHARACTER_ID: String = "v1_default_character"

var character_id: String = DEFAULT_CHARACTER_ID
var character_name: String = "V1 默认角色"
var character_description: String = "V1 阶段用于跑通开局流程的唯一角色。"
var character_ability_id: String = ""
var character_ability_enabled: bool = false


func to_data() -> Dictionary:
	return {
		"character_id": character_id,
		"character_name": character_name,
		"character_description": character_description,
		"character_ability_id": character_ability_id,
		"character_ability_enabled": character_ability_enabled,
	}
