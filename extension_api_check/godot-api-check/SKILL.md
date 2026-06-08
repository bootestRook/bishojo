---
name: godot-api-check
description: Export, inspect, and query Godot Engine GDExtension API dumps. Use when Codex needs the complete Godot API surface from extension_api.json, needs to regenerate Godot API JSON from a local Godot executable, or needs to answer precise questions about Godot classes, builtin types, utility functions, singletons, enums, methods, properties, signals, constants, or native structures.
---

# Godot API Check

## Quick Start

Use `scripts/query_godot_api.py` against the bundled API dump. By default the script reads the first existing `extension_api.json` from the skill-adjacent dump path, the current working directory, or the repository `extension_api_check/extension_api.json` path.

```powershell
python scripts/query_godot_api.py summary
python scripts/query_godot_api.py search add_child
python scripts/query_godot_api.py class Node
python scripts/query_godot_api.py method Node add_child
python scripts/query_godot_api.py list classes --filter Input
```

If `python` is not available in PATH, use the active Codex runtime Python or any Python 3.9+ interpreter.

## Export Workflow

Regenerate the API dump from a local Godot executable when the project version changes, when the user asks for a fresh export, or when `extension_api.json` is missing.

```powershell
python scripts/query_godot_api.py export --godot "C:\path\to\Godot_v4.x-stable_win64_console.exe" --output ..\extension_api.json --force
```

Use `--with-docs` only when the user needs embedded documentation text. The default `--dump-extension-api` output contains the full binding API surface without documentation.

The export command also tries to find Godot automatically from:

- `GODOT_BIN`
- `godot`, `godot4`, or `godot.exe` in PATH
- Windows `%LOCALAPPDATA%\CodexGodot` and `%LOCALAPPDATA%\Godot`

## Query Guidance

Prefer script queries over loading the whole JSON into context. The dump is large, and targeted queries keep answers accurate and compact.

Use:

- `summary` for version and section counts.
- `search <term>` for broad lookup across classes, builtin classes, utility functions, methods, properties, signals, constants, enums, and enum values.
- `class <ClassName>` for a compact class or builtin type overview.
- `method <ClassName> <method>` for exact overload/signature details.
- `list <section>` for inventory-style tasks.

When answering user questions, cite the API dump version from `summary` if version precision matters.

## Validation

After editing this skill, run:

```powershell
python scripts/query_godot_api.py summary
python scripts/query_godot_api.py method Node add_child
python C:\Users\Arche\.codex\skills\.system\skill-creator\scripts\quick_validate.py .
```
