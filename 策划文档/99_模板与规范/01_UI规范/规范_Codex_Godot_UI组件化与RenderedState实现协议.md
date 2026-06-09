# 规范：Codex 在 Godot 中生成参考 UI、UI 组件与界面拼接的 Rendered State 实现协议 V1

文件名：`规范_Codex_Godot_UI组件化与RenderedState实现协议_v1.md`  
项目阶段：V1 核心玩法原型  
目标环境：Godot + Codex  
目标平台：手机竖屏  
主设计尺寸：1080 × 2340  
文档状态：执行规范定稿版  
最后更新：2026-06-09

---

## 0. 核心结论

Codex 在 Godot 中实现 UI 时，必须采用：

```text
参考 UI 图解析
+
UI 组件资产拆分
+
Rendered State 显式布局描述
+
Godot Control 节点拼接
+
运行时数据绑定
```

禁止采用：

```text
生成一张完整 UI 整图作为界面
+
运行时 computed state 自动计算布局
+
根据数据数组动态推导 UI 坐标
+
使用 Godot Container 自动流式排版核心界面
```

最终 UI 必须是由独立组件拼接出的 Godot 可交互界面，而不是一张不可交互的整图。

---

## 1. 本文档目的

本文档用于约束 Codex 在 Godot 项目中处理以下任务：

```text
参考 UI 图解析
UI 组件切分与生成
UI 组件命名
UI 组件导入 Godot
页面场景拼接
Rendered State 描述
事件绑定
验收与回归检查
```

本文档不负责定义游戏状态机、不负责战斗底层逻辑、不负责数值系统。  
本文档只定义 UI 生产与实现方式。

---

## 2. 最高优先级硬规则

### 2.1 禁止整图 UI

任何实际游戏界面不得直接使用一张完整 UI 图作为最终界面。

禁止：

```text
MainMenuPage.png 作为整个主菜单
CharacterSelectPage.png 作为整个角色选择界面
RunBoardPage.png 作为整个局内界面
ShopPage.png 作为整个商店界面
CombatPage.png 作为整个战斗界面
```

允许：

```text
背景图
装饰图
按钮底图
面板底图
卡牌框
图标
分割线
标题牌
弹窗框
槽位框
角色立绘
```

### 2.2 必须组件化拼接

每个页面必须由多个 UI 组件组合而成。

组件例子：

```text
背景层
标题 Logo
主按钮
次按钮
资源栏
角色立绘
角色卡框
商店商品卡槽
背包入口按钮
战斗回路槽位
弹窗底板
关闭按钮
```

### 2.3 必须采用 Rendered State

所有界面布局必须通过 Rendered State 显式描述。

Rendered State 是“最终屏幕上已经排好的 UI 状态描述”，包括：

```text
组件 ID
组件类型
使用哪个组件 prefab
使用哪个贴图
x / y / width / height
anchor
pivot
z_index
visible
variant
text
binding
interaction
```

### 2.4 禁止 computed state 布局

UI 不得在运行时根据规则自动计算核心布局。

禁止：

```text
根据数组长度自动横排商店卡
根据屏幕高度实时计算按钮 y 坐标
根据 children 数量自动分配间距
根据卡牌数量自动生成回路槽位位置
通过 GridContainer / VBoxContainer / HBoxContainer 承担核心布局
通过代码遍历配置并推导所有 UI 坐标
```

允许：

```text
从 Rendered State 读取固定位置
把金币数绑定到固定文本组件
把商品数据绑定到固定 shop_slot_01 ~ shop_slot_05
把背包数据绑定到固定 bag_slot_01 ~ bag_slot_N
按 visible 字段显示 / 隐藏组件
按 variant 字段切换组件皮肤状态
按 Godot 全局 Stretch 做等比缩放
```

---

## 3. Rendered State 与 Computed State 的边界

### 3.1 Rendered State 定义

Rendered State 是一份可以直接还原当前 UI 画面的显式状态表。

它回答的问题是：

```text
这个组件是谁？
它放在哪里？
它多大？
它在第几层？
它当前显示哪种视觉状态？
它绑定哪个运行时数据？
它点击后发什么事件？
```

### 3.2 Computed State 定义

Computed State 是运行时根据规则推导 UI 的方式。

它的典型表现是：

```text
给我一个 shop_items 数组，我自动计算每张卡的位置
给我一个 panel_type，我自动生成内部所有节点
给我一个 screen_size，我按公式重新排列所有 UI
给我一个 children 列表，我自动分布间距
```

V1 禁止核心 UI 走这种方式。

### 3.3 允许的最小运行时计算

以下计算允许存在：

| 类型 | 是否允许 | 说明 |
|---|---:|---|
| Godot 全局 Viewport 缩放 | 允许 | 只做整体适配，不改变布局关系 |
| 文本数值替换 | 允许 | 例如金币、耐久、胜利数 |
| visible 切换 | 允许 | 由 Rendered State 定义组件是否显示 |
| variant 切换 | 允许 | normal / pressed / disabled / selected |
| 九宫格拉伸 | 允许 | 组件贴图本身的 9-slice，不是布局计算 |
| 简单 tween 动画 | 允许 | 入场、淡入、按钮点击反馈 |
| 语言文本替换 | 允许 | 只替换文本内容，不改变组件位置 |

以下计算禁止存在：

| 类型 | 是否允许 | 说明 |
|---|---:|---|
| 根据数组长度动态布局 | 禁止 | 商店卡、奖励卡、背包格都必须有固定槽位 |
| 根据内容长短自动改变核心面板尺寸 | 禁止 | 文本可以截断 / 缩放，面板不跟着乱变 |
| 使用 Container 决定核心控件位置 | 禁止 | Container 只能用于非核心调试列表 |
| 运行时重新排布页面结构 | 禁止 | 页面结构由 Rendered State 固定 |
| 按公式生成 2×5 回路坐标 | 禁止 | 10 个槽位必须显式写入 |

---

## 4. 参考 UI 图使用规范

### 4.1 参考图用途

参考 UI 图只用于：

```text
确定风格方向
确定布局比例
确定组件类型
确定层级关系
确定间距感
确定按钮、面板、卡牌的视觉语言
```

参考图不得直接作为最终 UI。

### 4.2 参考图解析流程

Codex 处理参考图时必须先输出一份 UI 分析清单：

```text
页面名称
参考图路径
主视觉风格
画布比例
主要区域划分
组件列表
每个组件的功能
每个组件是否需要独立生成
每个组件是否可复用
不可交互装饰组件
可交互控件组件
```

### 4.3 参考图到组件的拆分标准

拆分原则：

```text
会被点击的，必须拆成独立组件
会改变状态的，必须拆成独立组件
会复用的，必须拆成独立组件
会替换文本 / 数值的，必须拆成独立组件
只作为背景装饰且不交互的，可以做成背景组件
```

示例：

| 参考图元素 | 拆分方式 |
|---|---|
| 整体背景 | `bg_main_menu.png` |
| 标题 Logo | `logo_game_title.png` |
| 开始按钮 | `button_primary_normal.png` / `button_primary_pressed.png` / `button_primary_disabled.png` |
| 角色立绘 | `character_xxx_full.png` |
| 角色选择卡框 | `frame_character_card.png` |
| 金币图标 | `icon_gold.png` |
| 胜利数图标 | `icon_win_count.png` |
| 商店商品卡 | `card_shop_item_frame.png` + 商品头像 + 文本 |
| 回路槽位 | `slot_formation_empty.png` / `slot_formation_locked.png` / `slot_formation_valid.png` / `slot_formation_invalid.png` |

---

## 5. UI 组件资产规范

### 5.1 组件分类

```text
Background       背景
Panel            面板
Button           按钮
Icon             图标
Frame            框体
Card             卡牌框
Slot             槽位
Popup            弹窗
Decoration       装饰
CharacterArt     角色立绘
TextPlate        文本底牌
```

### 5.2 文件命名

统一使用小写蛇形命名。

```text
ui_<page_or_scope>_<component_type>_<name>_<variant>.png
```

示例：

```text
ui_common_button_primary_normal.png
ui_common_button_primary_pressed.png
ui_common_button_primary_disabled.png
ui_runboard_panel_top_status.png
ui_runboard_slot_formation_empty.png
ui_runboard_slot_formation_locked.png
ui_shop_card_item_frame_normal.png
ui_shop_card_item_frame_selected.png
ui_popup_frame_default.png
```

### 5.3 组件状态

按钮必须至少支持：

```text
normal
pressed
disabled
selected，可选
hover，可选；移动端可不做
```

槽位必须至少支持：

```text
empty
locked
occupied
valid_preview
invalid_preview
highlight
```

卡牌必须至少支持：

```text
normal
selected
disabled
owned
locked，可选
```

### 5.4 切图要求

```text
不要把文字烘焙进按钮底图，除非该文字永远不会变化
不要把数值烘焙进图标或面板
不要把多个可交互元素合成一张图
不要把卡牌头像、边框、稀有度、文字合成一张不可拆图
可缩放面板必须提供 9-slice 参数
纯装饰可以合并，但不得覆盖可交互区域
```

---

## 6. Godot 目录规范

建议目录：

```text
res://assets/ui/
  references/
    main_menu/
    character_select/
    start_camp/
    run_board/
  components/
    common/
    main_menu/
    character_select/
    start_camp/
    run_board/
    shop/
    popup/
  icons/
  characters/
  generated/

res://scenes/ui/
  pages/
    MainMenuPage.tscn
    CharacterSelectPage.tscn
    StartCampPage.tscn
    RunBoardPage.tscn
    RunVictoryPage.tscn
    RunDefeatPage.tscn
  panels/
    BranchSelectPanel.tscn
    ShopPanel.tscn
    GenericNodeChoicePanel.tscn
    FormationPanel.tscn
    CombatPanel.tscn
  overlays/
    CardDetailOverlay.tscn
    BagOverlay.tscn
    SynthesisResultPopup.tscn
    CombatResultOverlay.tscn
    ConfirmPopup.tscn
  components/
    UiImageComponent.tscn
    UiButtonComponent.tscn
    UiTextComponent.tscn
    UiCardSlotComponent.tscn
    UiFormationSlotComponent.tscn

res://data/ui/rendered_states/
  main_menu.rendered_state.json
  character_select.rendered_state.json
  start_camp.rendered_state.json
  run_board_branch_select.rendered_state.json
  run_board_shop.rendered_state.json
  run_board_formation_edit.rendered_state.json
  run_board_combat.rendered_state.json
  run_board_combat_result.rendered_state.json
```

---

## 7. Rendered State 数据结构

### 7.1 文件级结构

```json
{
  "state_id": "run_board_shop",
  "page_type": "RUN_BOARD_PAGE",
  "run_board_mode": "SHOP",
  "design_width": 1080,
  "design_height": 2340,
  "safe_area": {
    "x": 0,
    "y": 120,
    "width": 1080,
    "height": 2160
  },
  "components": []
}
```

### 7.2 组件结构

```json
{
  "component_id": "shop_slot_01",
  "component_role": "shop_item_slot",
  "prefab": "res://scenes/ui/components/UiCardSlotComponent.tscn",
  "asset": "res://assets/ui/components/shop/ui_shop_card_item_frame_normal.png",
  "rect": {
    "x": 72,
    "y": 520,
    "w": 180,
    "h": 300
  },
  "anchor": "top_left",
  "pivot": "center",
  "z_index": 120,
  "visible": true,
  "variant": "normal",
  "data_binding": {
    "source": "shop_items",
    "index": 0
  },
  "text_bindings": [
    {
      "target_node": "NameLabel",
      "source_key": "treasure_name"
    },
    {
      "target_node": "PriceLabel",
      "source_key": "price"
    }
  ],
  "interactions": [
    {
      "event": "pressed",
      "emit": "shop_buy_requested",
      "payload_from_binding": true
    },
    {
      "event": "long_press",
      "emit": "card_detail_requested",
      "payload_from_binding": true
    }
  ]
}
```

### 7.3 固定槽位原则

所有重复槽位都必须在 Rendered State 中显式列出。

商店 5 个商品槽：

```text
shop_slot_01
shop_slot_02
shop_slot_03
shop_slot_04
shop_slot_05
```

战斗回路 2×5 槽位：

```text
formation_slot_front_01
formation_slot_front_02
formation_slot_front_03
formation_slot_front_04
formation_slot_front_05
formation_slot_back_01
formation_slot_back_02
formation_slot_back_03
formation_slot_back_04
formation_slot_back_05
```

奖励 3 选 1 槽位：

```text
reward_option_01
reward_option_02
reward_option_03
```

禁止通过代码循环临时计算这些槽位的坐标。

---

## 8. Godot 实现规则

### 8.1 节点类型

核心 UI 使用 Godot `Control` 系列节点。

允许：

```text
Control
TextureRect
TextureButton
Button
Label
RichTextLabel
NinePatchRect
Panel
ColorRect
```

谨慎使用：

```text
HBoxContainer
VBoxContainer
GridContainer
MarginContainer
```

Container 只允许用于：

```text
调试列表
非核心滚动文本
开发期日志
不会影响最终视觉布局的内部文本组
```

### 8.2 页面根节点

每个 Page 根节点：

```text
Control
custom_minimum_size = 1080 × 2340
anchor = full_rect
```

运行时只做整体适配，不重新计算内部组件布局。

### 8.3 组件实例化

UI 页面加载 Rendered State 后，只能做：

```text
读取 components
按 component_id 创建或找到节点
设置 rect
设置 z_index
设置 visible
设置 texture
设置 variant
绑定文本
绑定点击事件
```

不能做：

```text
重新规划布局
重新排序组件
根据数据数量移动组件
动态改变核心区域结构
```

### 8.4 数据绑定方式

运行时数据只填充已有槽位。

示例：

```text
shop_items[0] → shop_slot_01
shop_items[1] → shop_slot_02
shop_items[2] → shop_slot_03
shop_items[3] → shop_slot_04
shop_items[4] → shop_slot_05
```

如果某个槽位没有数据：

```text
保持槽位显示为空
或显示 empty variant
不得删除槽位
不得重排其他槽位
```

---

## 9. 页面状态文件要求

V1 至少需要以下 Rendered State：

```text
main_menu.rendered_state.json
character_select.rendered_state.json
start_camp.rendered_state.json
run_board_branch_select.rendered_state.json
run_board_shop.rendered_state.json
run_board_generic_node_choice.rendered_state.json
run_board_formation_edit.rendered_state.json
run_board_combat_branch_select.rendered_state.json
run_board_combat.rendered_state.json
run_board_combat_result.rendered_state.json
run_victory.rendered_state.json
run_defeat.rendered_state.json
```

Overlay 也必须有独立 Rendered State：

```text
overlay_card_detail.rendered_state.json
overlay_bag.rendered_state.json
overlay_synthesis_result.rendered_state.json
overlay_invalid_formation.rendered_state.json
overlay_confirm.rendered_state.json
```

---

## 10. RunBoardPage 特殊规范

RunBoardPage 是局内核心页面。它必须保留同一个页面骨架，只切换 RunBoardMode。

### 10.1 常驻组件

这些组件应在多个 mode 中保持位置一致：

```text
top_status_bar
gold_display
normal_win_count_display
menu_button
run_durability_display
bag_button
formation_area
formation_slot_front_01 ~ 05
formation_slot_back_01 ~ 05
```

### 10.2 Mode 差异

不同 mode 通过 Rendered State 切换上半区内容：

| RunBoardMode | 上半区内容 |
|---|---|
| BRANCH_SELECT | 2～3 个分支选项卡 |
| SHOP | 商店 NPC、5 个商品槽、刷新 / 锁定 / 离开按钮 |
| GENERIC_NODE_CHOICE | 2～3 个节点选项卡 |
| FORMATION_EDIT | 弱化上半区，强化回路编辑与背包入口 |
| COMBAT_BRANCH_SELECT | 1～3 个战斗选项 |
| COMBAT | 敌人、技能反馈、伤害数字、充能线索 |
| COMBAT_RESULT | 战斗结果覆盖层 |

### 10.3 回路槽位

2×5 战斗回路槽位必须永远显式存在。

```text
锁定槽：显示 locked variant
空槽：显示 empty variant
可放置：显示 valid_preview variant
不可放置：显示 invalid_preview variant
已占用：显示 occupied variant + 卡牌头像 / 多格框
```

多格单位占用时：

```text
不要生成一张整排图
不要把 2～3 个槽位合并成不可识别整图
必须保留每个槽位的逻辑组件
额外叠加一个 multi_cell_frame 作为视觉整体框
```

---

## 11. Codex 执行流程

Codex 每次处理 UI 任务必须按以下顺序执行：

```text
01 读取当前页面规范与对应 Rendered State
02 读取参考 UI 图，仅做风格 / 布局分析
03 输出组件拆分清单
04 检查是否存在整图 UI 风险
05 生成或补齐独立组件资产
06 编写 / 更新 Rendered State JSON
07 创建或更新 Godot Page / Panel / Overlay 场景
08 绑定运行时数据到固定组件槽位
09 绑定事件，不让页面直接改 RunState
10 运行 UI smoke test
11 输出组件清单、文件清单、验收结果
```

---

## 12. Codex 输出格式要求

每次 Codex 完成 UI 相关任务，必须输出：

```text
本次修改页面 / 模式
是否使用参考图
是否生成整图 UI：必须为 false
是否采用 Rendered State：必须为 true
是否存在 computed layout：必须为 false
新增组件资产列表
新增 / 修改 Rendered State 文件
新增 / 修改 Godot 场景文件
事件绑定列表
验收结果
风险点
```

示例：

```text
ui_generation_report:
  page: RunBoardPage
  mode: SHOP
  used_reference_image: true
  full_page_image_used_as_runtime_ui: false
  rendered_state_used: true
  computed_layout_used: false
  components_created:
    - ui_shop_card_item_frame_normal.png
    - ui_common_button_primary_normal.png
  rendered_state_files:
    - res://data/ui/rendered_states/run_board_shop.rendered_state.json
  scenes_changed:
    - res://scenes/ui/pages/RunBoardPage.tscn
    - res://scenes/ui/panels/ShopPanel.tscn
  events_bound:
    - shop_buy_requested
    - shop_refresh_requested
    - shop_lock_toggled
    - shop_leave_requested
  validation:
    passed: true
```

---

## 13. UI 验收标准

### 13.1 必须通过

| 验收项 | 标准 |
|---|---|
| 非整图 UI | 页面不是一张完整 PNG |
| 组件可拆 | 按钮、卡牌、槽位、弹窗、资源栏均为独立组件 |
| Rendered State 存在 | 每个页面 / mode 有对应 JSON |
| 坐标显式 | 核心组件坐标写在 Rendered State 中 |
| 禁止 computed layout | 不根据数据数量动态计算核心布局 |
| 固定槽位 | 商店、奖励、回路槽位全部显式声明 |
| 事件分离 | UI 只发事件，不直接跳状态 |
| 竖屏适配 | 1080×2340 下完整可读 |
| 触控尺寸 | 主按钮 96～128 px，小图标热区 ≥ 80×80 px |
| 资源可复用 | 通用按钮、弹窗、卡框、槽位可跨页面复用 |

### 13.2 一票否决项

出现以下任意一项，本次 UI 实现不通过：

```text
直接把整张参考图放进 TextureRect 当页面
把整页 UI 生成成一张 PNG 并覆盖页面
核心布局依赖 HBoxContainer / VBoxContainer / GridContainer 自动排版
商店卡根据数组长度动态计算坐标
回路槽位通过公式运行时生成坐标
奖励 3 选 1 根据数组动态横排
按钮文字烘焙进不可复用整图
UI 点击后直接修改 RunState
没有 Rendered State 文件
Rendered State 与场景实际节点不一致
```

---

## 14. 给 Codex 的固定指令模板

后续每次让 Codex 做 UI，可以直接附加以下要求：

```text
按照《规范_Codex_Godot_UI组件化与RenderedState实现协议_v1.md》执行。

硬性要求：
1. 不得把参考图或生成图作为整页 UI。
2. 必须把 UI 拆成独立组件资产后在 Godot 中拼接。
3. 必须使用 Rendered State 显式描述每个组件的 rect、z_index、visible、variant、binding、interaction。
4. 不得使用 computed state 方式计算核心布局。
5. 商店卡、奖励卡、战斗回路槽位、背包槽位等重复元素必须使用固定 slot_id，不得根据数组长度动态排布。
6. Godot 页面只读取 Rendered State 并渲染，不允许页面内部自行推导布局。
7. UI 只发事件，不直接修改 RunState。
8. 输出 ui_generation_report，明确 full_page_image_used_as_runtime_ui=false、rendered_state_used=true、computed_layout_used=false。
```

---

## 15. 最终口径

本项目 UI 实现方式定为：

```text
Rendered State 驱动的组件化 Godot UI
```

不是：

```text
整图 UI
Computed State 动态布局 UI
Container 自动排版 UI
运行时公式布局 UI
```

核心判断标准：

```text
把 Rendered State 文件打开后，应该能直接看出当前页面最终长什么样；
把运行时代码打开后，不应该看到核心控件的位置是被公式算出来的。
```
