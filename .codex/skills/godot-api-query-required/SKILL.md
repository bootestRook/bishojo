---
name: godot-api-query-required
description: Mandatory Godot API verification workflow. Use whenever Codex writes, edits, reviews, explains, or recommends Godot Engine API usage in this repository, including GDScript, C# Godot code, scenes, resources, project settings, signals, properties, methods, classes, singletons, enums, constants, utility functions, builtin types, and GDExtension bindings. This skill requires querying the local Godot extension_api.json through godot-api-check before using any Godot API symbol.
---

# Godot API Query Required

## Hard Rule

Never use Godot Engine API from memory in this repository.

Before writing, editing, reviewing, explaining, or recommending any Godot API symbol, query the local API dump through `$godot-api-check` or its script.

If a Godot API symbol cannot be found in the dump, treat it as nonexistent. Do not call it, suggest it, or write it into code. If lookup is unavailable, stop and report the blocker instead of filling gaps from memory.

## Required Query Flow

1. Query `extension_api.json` through `$godot-api-check` or `.codex/skills/godot-api-check/scripts/query_godot_api.py`.
2. Query every Godot API symbol that will actually be used: classes, builtin types, methods, properties, signals, enums, enum values, constants, singletons, utility functions, operators, and constructors.
3. Confirm arguments, return values, default values, and flags such as const, static, vararg, and virtual before writing code.
4. Reuse only exact symbols already queried in the current context. Query again for new symbols or additional overloads.
5. Briefly mention the key queried Godot APIs in the final response unless the user asked for a very short answer.

## Commands

From the repository root:

```powershell
python .codex\skills\godot-api-check\scripts\query_godot_api.py summary
python .codex\skills\godot-api-check\scripts\query_godot_api.py class Node
python .codex\skills\godot-api-check\scripts\query_godot_api.py method Node add_child
python .codex\skills\godot-api-check\scripts\query_godot_api.py search input_event --limit 20
```

If `python` is unavailable in PATH, use the bundled Codex Python or any Python 3.9+ interpreter.

## Project Symbols

Godot engine API verification is not enough for project-specific names. Verify custom classes, scene nodes, Autoloads, groups, resources, input actions, and project settings from repository files before use.

Use repository search for project symbols:

```powershell
rg "class_name|autoload|InputMap|input/" .
rg "SomeNodeName|SomeActionName|SomeCustomClass" .
```

Do not invent project node paths, input actions, Autoload names, custom classes, resource paths, signal connections, or group names.

## Comment Rules

Repository code comments should be written in Chinese by default.

Comments should explain file responsibility, module boundaries, common usage, data meaning, function inputs and outputs, and usage constraints. Pay special attention to TODO/FIXME items, validation-driven logic, easy-to-miss state branches, cross-system integration, key mappings, critical rules, and non-obvious design choices.

Avoid empty comments such as "define variable" or "get value". If code is self-explanatory, reduce line-by-line comments, but keep file headers, section notes, key mappings, and critical state or rule comments.
