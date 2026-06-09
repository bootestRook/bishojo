extends RefCounted
class_name NodeChoiceOption

# 文件职责：
# - 表示补给、金币等通用节点中的一个选择项。
# - payload 用于携带纯数据效果，不直接绑定 UI。

var option_id: String = ""
var node_type: String = ""
var option_type: String = ""
var title: String = ""
var description: String = ""
var payload: Dictionary = {}
var weight: int = 1
var can_skip: bool = false


func setup(new_option_id: String, new_node_type: String, new_option_type: String, new_title: String, new_description: String, new_payload: Dictionary = {}, new_weight: int = 1, new_can_skip: bool = false) -> void:
	option_id = new_option_id
	node_type = new_node_type
	option_type = new_option_type
	title = new_title
	description = new_description
	payload = new_payload.duplicate(true)
	weight = new_weight
	can_skip = new_can_skip
