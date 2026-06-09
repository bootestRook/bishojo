extends RefCounted
class_name ShopManager

const SHOP_ITEM = preload("res://scripts/systems/shop/shop_item.gd")
const SHOP_CONFIG = preload("res://scripts/systems/shop/v1_shop_config.gd")

# 文件职责：
# - 管理 V1 商店纯逻辑库存、购买、刷新、锁定和出售。
# - 不创建商店 UI，不处理拖拽，不执行战斗效果。

var config = SHOP_CONFIG.new()
var current_stock: Array = []
var is_locked: bool = false
var stock_generation_index: int = 0


func prepare_stock(treasure_catalog, current_locked_stock: Array) -> Array:
	if is_locked and not current_locked_stock.is_empty():
		current_stock = current_locked_stock
	else:
		current_stock = generate_stock(treasure_catalog)

	return current_stock.duplicate()


func generate_stock(treasure_catalog) -> Array:
	var result: Array = []
	var ids: Array = treasure_catalog.get_all_treasure_ids()
	if ids.is_empty():
		return result

	var index: int = 0
	while index < config.stock_count:
		var catalog_index: int = (stock_generation_index + index) % ids.size()
		var treasure_id: String = ids[catalog_index]
		var item = SHOP_ITEM.new()
		item.setup("shop_item_%d" % (stock_generation_index + index + 1), treasure_id, "green", treasure_catalog.get_price(treasure_id, "green"))
		result.append(item)
		index += 1

	stock_generation_index += config.stock_count
	return result


func buy_item(shop_item_id: String, run_manager, inventory_model) -> Dictionary:
	var item = _get_item(shop_item_id)
	if item == null:
		return {"ok": false, "reason": "item_not_found"}
	if item.is_sold:
		return {"ok": false, "reason": "item_sold"}
	if run_manager.gold < item.price:
		return {"ok": false, "reason": "not_enough_gold"}

	run_manager.gold -= item.price
	var instance = inventory_model.add_treasure(item.treasure_id, item.rarity, "shop")
	item.is_sold = true
	return {"ok": true, "reason": "ok", "instance_id": instance.instance_id, "spent_gold": item.price}


func refresh_shop(run_manager, treasure_catalog) -> Dictionary:
	if run_manager.gold < config.refresh_cost:
		return {"ok": false, "reason": "not_enough_gold"}

	run_manager.gold -= config.refresh_cost
	current_stock = generate_stock(treasure_catalog)
	is_locked = false
	return {"ok": true, "reason": "ok", "spent_gold": config.refresh_cost, "stock": current_stock.duplicate()}


func toggle_lock() -> bool:
	is_locked = not is_locked
	return is_locked


func sell_instance(instance_id: String, run_manager, inventory_model, formation_model, treasure_catalog) -> Dictionary:
	var instance = inventory_model.get_instance(instance_id)
	if instance == null:
		return {"ok": false, "reason": "instance_not_found"}

	if instance.is_in_formation:
		formation_model.remove_instance(instance_id)

	var price: int = treasure_catalog.get_price(instance.treasure_id, instance.rarity)
	var refund: int = price * config.sell_refund_ratio_bp / 10000
	inventory_model.remove_instance(instance_id)
	run_manager.gold += refund
	return {"ok": true, "reason": "ok", "refund": refund}


func leave_shop() -> void:
	pass


func _get_item(shop_item_id: String):
	var index: int = 0
	while index < current_stock.size():
		if current_stock[index].shop_item_id == shop_item_id:
			return current_stock[index]
		index += 1

	return null
