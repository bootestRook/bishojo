extends RefCounted
class_name BattleConfig

# 文件职责：
# - 集中维护 V1 战斗底层的技术与数值占位参数。
# - 这些值服务于纯逻辑模拟，不绑定 UI、动画、节点或项目设置。

var normal_timeout_ms: int = 90000
var boss_timeout_ms: int = 180000
var initial_cooldown_ratio_bp: int = 10000
var min_trigger_interval_ms: int = 100
var max_chain_events_per_same_time: int = 30
var base_crit_rate_bp: int = 500
var base_crit_damage_bp: int = 15000
var crit_rate_cap_bp: int = 10000
var shield_cap_ratio_bp: int = 10000
var poison_tick_interval_ms: int = 1000
var burn_tick_interval_ms: int = 500
var poison_damage_per_stack: int = 1
var burn_damage_per_stack: int = 1
var heal_cleanse_bp: int = 500

# V1 战斗原型占位值。后续若拆奖励表或玩家核心配置，应从这里迁出而不是散写在 Runner 内。
var player_core_hp_max: int = 60
var normal_win_reward_gold: int = 2

