extends RefCounted
class_name BranchOption

# 文件职责：
# - 表示一轮分支选择中的单个选项。
# - V1 当前固定生成 shop / supply / gold，后续可替换为权重随机。

var branch_id: String = ""
var branch_type: String = ""
var title: String = ""
var description: String = ""
var weight: int = 1
var payload: Dictionary = {}


func setup(new_branch_id: String, new_branch_type: String, new_title: String, new_description: String, new_weight: int = 1, new_payload: Dictionary = {}) -> void:
	branch_id = new_branch_id
	branch_type = new_branch_type
	title = new_title
	description = new_description
	weight = new_weight
	payload = new_payload.duplicate(true)
