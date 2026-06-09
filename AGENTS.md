# AGENTS.md

## 文件命名规范

- 文档文件名统一使用 `[类别]_[主题]_[版本].md`。
- 常用类别前缀：`总表`、`规则`、`系统`、`机制`、`内容`、`模板`、`规范`。
- 初版统一使用 `v1`，大改再开 `v2`。

## 资源与工作区整洁规则

- 所有美术资源不得用代码生成，必须使用 Codex 的 `gpt-image-2` 生图功能产出；代码只负责接入、切片、压缩、格式转换、透明通道清理、资源登记和运行时加载等工程处理。
- 不得在仓库根目录直接保存截图、临时测试脚本、一次性验证脚本、导出残留文件或其他过程性产物；确需生成时必须放入已有的合适子目录，或使用明确命名的临时/工具目录，并在任务结
束前清理不需要保留的文件，保持根目录整洁。

## 处理UI相关的规范

- 处理UI相关的需求前必须先阅读…\策划文档\99_模板与规范\01_UI规范\规范_Codex_Godot_UI组件化与RenderedState实现协议.md
- 所有 UI 相关实现、重构、验收和评审均以该 UI 协议为最高优先级；任何旧策划文档、旧原型代码或临时实现规则与协议冲突时，必须先同步更新对应规则说明，再修改实现。
- UI 核心界面不得继续沿用 `HBoxContainer` / `VBoxContainer` / `GridContainer` 自动排版原型；必须使用 Rendered State 显式坐标驱动的组件化 Godot Control 拼接。

## PowerShell 与 UTF-8 铁律

- 本仓库所有中文文本、策划文档、脚本、配置和 Markdown 文件一律按 UTF-8 处理。
- 在 PowerShell 中读取文本文件时，禁止使用不带编码参数的 `Get-Content`。必须显式使用 `Get-Content -LiteralPath '路径' -Raw -Encoding UTF8`，避免 Windows PowerShell 使用系统默认代码页把中文读成乱码。
- 批量检索文本优先使用 `rg`。确需 PowerShell 管道输出中文前，先设置当前会话编码：

```powershell
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [System.Text.UTF8Encoding]::new()
```

- 写入或修改文本优先使用 `apply_patch`。确需 PowerShell 写文件时，必须使用无 BOM UTF-8，例如 `[System.IO.File]::WriteAllText($path, $text, [System.Text.UTF8Encoding]::new($false))`。
- 需要兼容 Windows PowerShell 5.1 执行的 `.ps1` 自动化脚本必须保持 ASCII-only；Windows PowerShell 5.1 会把无 BOM `.ps1` 按系统代码页解析，脚本内中文字符串或中文注释会直接造成语法错误。中文说明写入 Markdown 文档，不写入这类 `.ps1` 脚本。
- 任何读取结果只要出现 Unicode replacement character、常见 mojibake 标记或明显乱码，不得继续基于该输出分析或改写文件；必须立刻按 UTF-8 重新读取并说明前一次输出无效。
- 提交前必须运行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify_text_encoding.ps1 -Staged`。本仓库已提供 `.githooks/pre-commit` 自动执行该检查，若 hook 未启用，运行 `powershell -NoProfile -ExecutionPolicy Bypass -File tools/install_git_hooks.ps1`。

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
