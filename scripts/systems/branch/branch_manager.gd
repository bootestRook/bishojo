extends RefCounted
class_name BranchManager

const BRANCH_OPTION = preload("res://scripts/systems/branch/branch_option.gd")

# 文件职责：
# - 生成和解析 V1 分支选项。
# - 当前使用固定 3 选 1 占位，后续如接入权重随机，只替换本 manager 内部实现。

var current_options: Array = []


func generate_branch_options(run_manager) -> Array:
	current_options = []
	current_options.append(_make_option("branch_shop", "shop", "进入商店", "购买、刷新、锁定或出售秘宝少女。"))
	current_options.append(_make_option("branch_supply", "supply", "获得补给", "恢复局内耐久或获得少量资源。"))
	current_options.append(_make_option("branch_gold", "gold", "获得金币", "直接获得经济资源。"))
	return current_options.duplicate()


func resolve_branch(branch_option) -> String:
	if branch_option == null:
		return ""

	return branch_option.branch_type


func get_option(branch_id: String):
	var index: int = 0
	while index < current_options.size():
		if current_options[index].branch_id == branch_id:
			return current_options[index]
		index += 1

	return null


func _make_option(branch_id: String, branch_type: String, title: String, description: String):
	var option = BRANCH_OPTION.new()
	option.setup(branch_id, branch_type, title, description)
	return option
