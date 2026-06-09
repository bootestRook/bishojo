extends RefCounted
class_name V1ShopConfig

const V1_BALANCE_CONFIG = preload("res://scripts/data/balance/v1_balance_config.gd")

# 文件职责：
# - 集中维护 V1 商店占位参数。
# - 费用和返还比例从 V1BalanceConfig 读取，避免同一类待定数值散落在多个系统。

var balance_config = V1_BALANCE_CONFIG.new()

var stock_count: int = 5
var refresh_cost: int = 0
var sell_refund_ratio_bp: int = 0
var lock_cost: int = 0


func _init() -> void:
	refresh_cost = balance_config.shop_refresh_cost
	sell_refund_ratio_bp = balance_config.sell_refund_ratio_bp
