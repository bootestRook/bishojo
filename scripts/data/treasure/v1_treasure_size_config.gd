extends RefCounted
class_name V1TreasureSizeConfig

# 文件职责：
# - 集中维护 V1 秘宝少女体型和占格尺寸。
# - V1 只支持横向固定摆放，不支持旋转，不支持跨行形状。

const SMALL: String = "small"
const MEDIUM: String = "medium"
const LARGE: String = "large"


func get_footprint(size_type: String) -> Dictionary:
	match size_type:
		SMALL:
			return {"width": 1, "height": 1}
		MEDIUM:
			return {"width": 2, "height": 1}
		LARGE:
			return {"width": 3, "height": 1}
		_:
			return {"width": 0, "height": 0}


func is_valid_size_type(size_type: String) -> bool:
	return size_type == SMALL or size_type == MEDIUM or size_type == LARGE


func can_rotate(size_type: String) -> bool:
	if not is_valid_size_type(size_type):
		return false

	return false
