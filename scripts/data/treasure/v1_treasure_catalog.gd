extends RefCounted
class_name V1TreasureCatalog

const TREASURE_DATA = preload("res://scripts/data/treasure/v1_treasure_data.gd")
const SIZE_CONFIG = preload("res://scripts/data/treasure/v1_treasure_size_config.gd")

# 文件职责：
# - 保存 V1 秘宝少女基础目录，供商店、初始营地、背包和回路查询。
# - effect_list 只作为未来战斗系统消费的数据，不在本文件内执行。

var size_config = SIZE_CONFIG.new()
var catalog: Dictionary = {}


func _init() -> void:
	_setup_catalog()


func has_treasure_id(treasure_id: String) -> bool:
	return catalog.has(treasure_id)


func get_treasure_data(treasure_id: String, rarity: String = "green"):
	if not catalog.has(treasure_id):
		return null

	var data: Dictionary = catalog.get(treasure_id).duplicate(true)
	var footprint: Dictionary = size_config.get_footprint(data.get("size_type", "small"))
	data["rarity"] = rarity
	data["footprint_width"] = footprint.get("width", 1)
	data["footprint_height"] = footprint.get("height", 1)

	var treasure = TREASURE_DATA.new()
	treasure.setup(data)
	return treasure


func get_all_treasure_ids() -> Array:
	return catalog.keys()


func get_all_treasure_data() -> Array:
	var result: Array = []
	var ids: Array = get_all_treasure_ids()
	var index: int = 0
	while index < ids.size():
		result.append(get_treasure_data(ids[index]))
		index += 1

	return result


func get_price(treasure_id: String, rarity: String = "green") -> int:
	var treasure = get_treasure_data(treasure_id, rarity)
	if treasure == null:
		return 0

	return treasure.price


func _add(data: Dictionary) -> void:
	catalog[data.get("treasure_id", "")] = data


func _setup_catalog() -> void:
	_add({
		"treasure_id": "flame_blade",
		"treasure_name": "焰刃少女",
		"size_type": "small",
		"price": 3,
		"tags": ["damage", "starter"],
		"base_cooldown_ms": 4000,
		"effect_list": [{"effect_type": "damage", "target_rule": "enemy_single", "value": 20}],
		"position_rule": "none",
		"description": "初始输出型秘宝少女，提供直接伤害方向。",
	})
	_add({
		"treasure_id": "thunder_bell",
		"treasure_name": "雷铃少女",
		"size_type": "small",
		"price": 3,
		"tags": ["charge", "starter"],
		"base_cooldown_ms": 3000,
		"effect_list": [{"effect_type": "charge", "target_rule": "adjacent", "value_ms": 1000}],
		"position_rule": "adjacent",
		"description": "初始充能型秘宝少女，后续由战斗系统消费充能数据。",
	})
	_add({
		"treasure_id": "ice_mirror",
		"treasure_name": "冰镜少女",
		"size_type": "small",
		"price": 3,
		"tags": ["shield", "starter"],
		"base_cooldown_ms": 5000,
		"effect_list": [{"effect_type": "shield", "target_rule": "player_core", "value": 12}],
		"position_rule": "none",
		"description": "初始防御型秘宝少女，提供护盾构筑方向。",
	})
	_add({
		"treasure_id": "moon_dagger",
		"treasure_name": "月匕少女",
		"size_type": "small",
		"price": 4,
		"tags": ["damage", "crit"],
		"base_cooldown_ms": 3500,
		"effect_list": [{"effect_type": "damage", "target_rule": "enemy_single", "value": 16, "can_crit": true}],
		"position_rule": "none",
		"description": "低冷却暴击输出。",
	})
	_add({
		"treasure_id": "star_lance",
		"treasure_name": "星枪少女",
		"size_type": "medium",
		"price": 5,
		"tags": ["damage"],
		"base_cooldown_ms": 5500,
		"effect_list": [{"effect_type": "damage", "target_rule": "enemy_single", "value": 34}],
		"position_rule": "same_row",
		"description": "中型输出，占用连续 2 格。",
	})
	_add({
		"treasure_id": "solar_cannon",
		"treasure_name": "日冕炮少女",
		"size_type": "large",
		"price": 7,
		"tags": ["damage", "burst"],
		"base_cooldown_ms": 8000,
		"effect_list": [{"effect_type": "damage", "target_rule": "enemy_all", "value": 50}],
		"position_rule": "same_row",
		"description": "大型爆发输出，占用连续 3 格。",
	})
	_add({
		"treasure_id": "wind_chime",
		"treasure_name": "风铃少女",
		"size_type": "medium",
		"price": 5,
		"tags": ["charge", "haste"],
		"base_cooldown_ms": 4500,
		"effect_list": [{"effect_type": "charge", "target_rule": "same_row", "value_ms": 700}],
		"position_rule": "same_row",
		"description": "中型同排充能组件。",
	})
	_add({
		"treasure_id": "clockwork_key",
		"treasure_name": "发条钥少女",
		"size_type": "small",
		"price": 4,
		"tags": ["charge"],
		"base_cooldown_ms": 5000,
		"effect_list": [{"effect_type": "charge", "target_rule": "longest_cooldown_ally", "value_ms": 1300}],
		"position_rule": "none",
		"description": "给最长冷却友方充能的组件。",
	})
	_add({
		"treasure_id": "crystal_shield",
		"treasure_name": "晶盾少女",
		"size_type": "medium",
		"price": 5,
		"tags": ["shield", "defense"],
		"base_cooldown_ms": 6000,
		"effect_list": [{"effect_type": "shield", "target_rule": "player_core", "value": 20}],
		"position_rule": "same_col",
		"description": "中型护盾组件。",
	})
	_add({
		"treasure_id": "twin_orbit",
		"treasure_name": "双轨少女",
		"size_type": "small",
		"price": 4,
		"tags": ["position", "charge"],
		"base_cooldown_ms": 4200,
		"effect_list": [{"effect_type": "charge", "target_rule": "front_back_overlap", "value_ms": 900}],
		"position_rule": "front_back_overlap",
		"description": "关注前后对应关系的站位组件。",
	})
	_add({
		"treasure_id": "compass_lily",
		"treasure_name": "罗盘百合少女",
		"size_type": "medium",
		"price": 5,
		"tags": ["position", "buff"],
		"base_cooldown_ms": 5200,
		"effect_list": [{"effect_type": "buff", "target_rule": "center_column", "value_bp": 1000}],
		"position_rule": "center_column",
		"description": "鼓励占据中列的站位组件。",
	})
	_add({
		"treasure_id": "golden_purse",
		"treasure_name": "金袋少女",
		"size_type": "small",
		"price": 3,
		"tags": ["economy"],
		"base_cooldown_ms": 7000,
		"effect_list": [{"effect_type": "gold", "target_rule": "run", "value": 1}],
		"position_rule": "none",
		"description": "经济型组件，战斗实现前只保留收益数据。",
	})
