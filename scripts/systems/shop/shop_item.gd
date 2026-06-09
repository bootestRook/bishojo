extends RefCounted
class_name ShopItem

# 文件职责：
# - 表示商店中的一个可购买商品。
# - 商品只记录售卖状态和对应秘宝 ID，不创建 UI 卡牌。

var shop_item_id: String = ""
var treasure_id: String = ""
var rarity: String = "green"
var price: int = 0
var is_sold: bool = false


func setup(new_shop_item_id: String, new_treasure_id: String, new_rarity: String, new_price: int) -> void:
	shop_item_id = new_shop_item_id
	treasure_id = new_treasure_id
	rarity = new_rarity
	price = new_price
