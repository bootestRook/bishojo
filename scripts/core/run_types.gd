extends RefCounted
class_name RunTypes

# 文件职责：
# - 集中声明整局流程、独立页面、RunBoardPage 内部模式的第一阶段枚举。
# - 只承载策划文档中已经定稿的流程名称，不绑定任何场景路径、节点路径或 Autoload 名称。
# - 后续新增页面或局内模式时，先确认策划口径，再扩展对应枚举，避免临时页面反向污染 RunState。

# 整局真实流程状态。页面只负责发事件，最终由 RunManager 判定能否切换到这些状态。
enum RunState {
	BOOT,
	MAIN_MENU,

	START_NEW_RUN,
	CHARACTER_SELECT,
	RUN_INIT,

	START_CAMP,
	STARTER_TREASURE_SELECT,

	BRANCH_SELECT,
	BRANCH_RESOLVE,
	SHOP_NODE,
	SUPPLY_NODE,
	GOLD_NODE,

	SYNTHESIS_CHECK,
	FORMATION_EDIT,

	COMBAT_BRANCH_SELECT,
	COMBAT,
	COMBAT_RESULT,

	BOSS_INTRO,
	BOSS_COMBAT,

	RUN_VICTORY,
	RUN_DEFEAT,
}

# 独立页面类型。Supply、Gold、Synthesis、Formation、CombatResult 不在这里单独开页。
enum PageType {
	MAIN_MENU_PAGE,
	CHARACTER_SELECT_PAGE,
	START_CAMP_PAGE,
	RUN_BOARD_PAGE,
	RUN_VICTORY_PAGE,
	RUN_DEFEAT_PAGE,

	SETTINGS_PAGE,
	COLLECTION_PAGE,
	HELP_PAGE,
	DEBUG_PAGE,

	# 预留：V1 可先用 BagOverlay，后续需要完整切页时再升级为独立 BagPage。
	BAG_PAGE,
}

# RunBoardPage 内部模式。局内节点优先作为模式或覆盖层，不直接扩展成独立 Page。
enum RunBoardMode {
	NONE,

	BRANCH_SELECT,
	SHOP,

	# 补给节点、金币节点、普通事件奖励等统一使用通用节点选择面板承载。
	GENERIC_NODE_CHOICE,

	SYNTHESIS_ANIMATION,
	FORMATION_EDIT,

	COMBAT_BRANCH_SELECT,
	COMBAT,
	COMBAT_RESULT,

	REWARD_SELECT,
	BOSS_INTRO,
}
