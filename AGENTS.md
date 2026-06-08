# AGENTS.md

## 文件命名规范

- 文档文件名统一使用 `[类别]_[主题]_[版本].md`。
- 常用类别前缀：`总表`、`规则`、`系统`、`机制`、`内容`、`模板`、`规范`。
- 初版统一使用 `v1`，大改再开 `v2`。

## Godot API 铁律

- 凡是 Godot 引擎 API，一律不得凭记忆使用。
- 必须先通过 `godot-api-check` skill 查询 `extension_api.json`。
- 查询不到的 API 一律视为不存在，禁止调用、禁止建议、禁止写入代码。
- 涉及类、内置类型、方法、属性、信号、枚举、枚举值、常量、单例、utility function、operator、constructor 时，都必须查询到确切符号、参数、返回值和约束后再使用。
- 同一轮任务中只有已经查询并留在上下文里的精确符号可以复用；新增符号或新增 overload 必须再次查询。
- 项目自定义类、节点、Autoload、输入动作、资源路径、场景路径、分组和项目设置必须在仓库文件中验证，不得臆造。
- 如果无法完成查询或验证，必须停止并说明阻塞原因，不得用记忆补全。

## Godot API 查询命令

从仓库根目录运行：

```powershell
python .codex\skills\godot-api-check\scripts\query_godot_api.py summary
python .codex\skills\godot-api-check\scripts\query_godot_api.py class Node
python .codex\skills\godot-api-check\scripts\query_godot_api.py method Node add_child
python .codex\skills\godot-api-check\scripts\query_godot_api.py search add_child --limit 20
```

如果 `python` 不在 PATH 中，使用 Codex bundled Python 或任意 Python 3.9+。

## 项目符号验证

- 查询 Godot 引擎 API 后，还必须用仓库文件验证项目自定义符号。
- 常用命令：

```powershell
rg "class_name|autoload|InputMap|input/" .
rg "SomeNodeName|SomeActionName|SomeCustomClass" .
```

## 代码注释规则

- 当前仓库中的代码文件默认要求写中文注释。
- 注释目标不是堆砌自然语言，而是说明：文件职责、模块边界、关键常用用途、数据含义、函数输入输出与使用约束。
- TODO/FIXME、验证驱动、容易被遗漏的状态分支、跨系统对接、关键映射、关键规则和非直观设计取舍必须写详细中文注释，保证后续 AI 与人类都能直接读懂。
- 不允许只写空泛注释，例如“定义变量”“获取值”；注释必须解释这段结构为什么存在、给谁用、和哪些系统对接。
- 如果代码本身已经足够直白，允许减少逐行注释；但文件头说明、分区说明、关键映射与关键规则/状态说明仍必须保留。
