extends RefCounted
class_name V1ShopConfig

# 文件职责：
# - 集中维护 V1 商店占位参数。
# - 数值平衡尚未定稿，后续只改配置，不把费用写散在 ShopManager 里。

var stock_count: int = 5
var refresh_cost: int = 2
var sell_refund_ratio_bp: int = 5000
var lock_cost: int = 0
