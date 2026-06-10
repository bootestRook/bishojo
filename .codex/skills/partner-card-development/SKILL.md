---
name: partner-card-development
description: Coordinate partner card development in the bishojo Godot repository through real A/B/C sub-agents. Use when Codex needs to develop, implement, audit, or archive partner cards from 策划文档/02_战斗系统/03_卡牌数据, especially 角色1卡组 cards, while maintaining card status and mechanism matrix documents.
---

# Partner Card Development

## Core Rule

Use real sub-agents. The controller must call `multi_agent_v1.spawn_agent` for A, B, and C. If that tool is unavailable, stop and report the blocker instead of simulating the process in prose.

The controller only coordinates, waits, routes feedback, and reports progress. Do not perform mechanism decomposition, implementation, or review locally in the controller conversation.

## Required Inputs

Before spawning agents, identify the target card Markdown files and card JSON files. For 角色1卡组, use:

- `策划文档/02_战斗系统/03_卡牌数据/01_角色1卡组/`
- `data/cards/partners/`

Read only enough repository context to produce scoped prompts. For Godot API usage, every worker that writes, edits, reviews, explains, or recommends Godot Engine API usage must use `$godot-api-query-required` and query `$godot-api-check` first.

## Required Project Documents

Maintain these docs under `策划文档/02_战斗系统/03_卡牌数据/04_开发记录/`:

- `总表_角色1卡组卡牌开发状态_v1.md`: status index only. Keep one row per card with links, owner agent, verification, archive state, and undeveloped items.
- `机制_角色1卡组卡牌机制拆解与实现矩阵_v1.md`: mechanism index only. Keep shared rules, supported mechanism inventory, and links to per-card mechanism files.
- `01_单卡机制矩阵/机制_[卡牌名]卡牌实现矩阵_v1.md`: required per-card mechanism file. Put active/passive breakdown, existing support, missing support, implementation decision, and verification evidence here.
- `规范_角色1卡组卡牌开发审核记录_v1.md`: batch audit record. Keep reviewer findings, pass/fail decision, required B rework, and final archive notes.

Create the directory and docs when missing. Keep filenames compliant with the repository naming rule `[类别]_[主题]_[版本].md`.

Do not put all card mechanisms into one Markdown document. For scale, the total and mechanism docs are indexes; every card gets its own file. When developing 1000 cards, add 1000 small per-card files and one-line index entries, not one giant matrix.

## Agent Sequence

1. Spawn Agent A as a `worker`.
   - Task: read card docs, battle rules, existing JSON/code, create or update the status index, mechanism index, and one per-card mechanism file for each target card.
   - Output: list each card, its per-card mechanism file, existing vs missing support, files that B should own, risks, and verification plan.
   - A may edit only the required project documents unless explicitly asked to fix source data inconsistencies.

2. Wait for Agent A before spawning B.
   - The controller uses A's final result as B's authoritative input.
   - If A reports a blocker, report it to the user instead of guessing.

3. Spawn Agent B as a `worker`.
   - Task: implement the card logic according to A's matrix.
   - Ownership: assign concrete files or directories from A's output.
   - B must not revert user or other-agent edits.
   - B must update the status index and the affected per-card mechanism files with implementation evidence. Do not expand the mechanism index into a long per-card detail document.
   - B must run focused validation and report changed files.

4. Spawn Agent C as an `explorer` for review unless C must update audit/archive docs, then use `worker`.
   - Task: review B's changes against card docs, battle rules, Godot API verification rules, project symbol verification, and encoding rules.
   - Output: `PASS` or `FAIL`, findings with file paths, required fixes, and verification gaps.
   - If C can edit, C updates the audit doc, status index, and affected per-card mechanism files only as needed. Mark cards archived only on pass.

5. If C returns `FAIL`, send the findings back to B with `multi_agent_v1.send_input`.
   - Wait for B's rework.
   - Run C again on the revised state.
   - Repeat until C returns `PASS` or reports a hard blocker.

6. On `PASS`, close no-longer-needed agents and report:
   - developed cards,
   - cards still undeveloped,
   - documents updated,
   - changed implementation files,
   - validation commands and results,
   - any residual risks.

## Prompt Templates

Use `references/agent-prompts.md` for compact A/B/C prompt templates. Fill in actual card paths, doc paths, and A or B outputs. Do not paste hidden conclusions into C's prompt beyond B's changed files and the source requirements needed for review.

## Verification Rules

The final workflow must include:

- `powershell -NoProfile -ExecutionPolicy Bypass -File tools/verify_text_encoding.ps1 -Staged` when files are staged or before a commit request.
- Focused JSON/schema or tool validation when card JSON or helper scripts change.
- Godot API query evidence when any `.gd`, `.tscn`, `.tres`, project setting, or Godot API symbol is changed or reviewed.

If no runtime implementation exists, B must explicitly choose the narrowest useful implementation surface, such as data normalization, validation tooling, or a deterministic card-effect adapter, and document why full runtime integration is blocked.
