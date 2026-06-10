---
name: partner-card-screenshot-ingest
description: Extract partner card data from user-provided game screenshots into this repository's per-card Markdown and JSON templates. Use when the user sends card screenshots and asks to录入/整理/新增卡牌信息, especially for 角色1卡组 partner cards, rarity data, cooldown effects, passive effects, keyword tooltips, and damage-card tagging.
---

# Partner Card Screenshot Ingest

Use this skill to convert card screenshots into the project-standard single-card files.

## Fixed Paths

- Read template: `策划文档/02_战斗系统/03_卡牌数据/模板_伙伴卡牌阅读文件_v1.md`
- JSON template: `data/cards/templates/partner_card.template.v1.json`
- Default deck folder: `策划文档/02_战斗系统/03_卡牌数据/01_角色1卡组/`
- Development data folder: `data/cards/partners/`
- Single-card MD name: `内容_[卡牌名]卡牌_v1.md`
- Single-card JSON name: `[card_id].v1.json`

## Extraction Rules

Extract only what is visible or explicitly supplied by the user:

- Card name.
- Size label: 小型 / 中型 / 大型.
- Initial cooldown in seconds and milliseconds.
- Per-rarity sell price.
- Per-rarity portrait top value.
- Per-rarity cooldown-trigger description.
- Per-rarity passive-trigger description.
- Keyword tooltip text, such as 吸血.
- Source screenshot file names by rarity.

Use rarity keys exactly:

- `green` = 绿色
- `blue` = 蓝色
- `purple` = 紫色
- `yellow` = 金色

If a rarity screenshot or field is missing, write `待确认` in Markdown and `null` in JSON. Never infer missing values from a pattern.

## Tagging And Defaults

- Mark `damage_card` only when the card's own active/passive effect directly deals enemy damage, such as `对敌人造成 X 点伤害`. Do not mark it just because text references `伤害伙伴` or grants another card `+X 点伤害`.
- If a keyword appears as a skill bullet and has a tooltip, add it to `keyword_definitions`.
- If there is no passive effect, write `无` in Markdown and use `"trigger": null, "effects": []` in JSON.
- If a passive says an event grants or increases a value, default to stacking once per trigger.
- If no duration is specified, default passive duration to `until_battle_end`.
- Keep unconfirmed implementation choices in `implementation_notes.pending_rules`, for example damage type or whether the active damage can crit.

## Update Workflow

1. Read the current MD and JSON templates before editing.
2. If the new card needs a field not in the templates, update:
   - both templates;
   - every existing single-card MD;
   - every existing single-card JSON.
3. Create or update the card MD under the deck folder.
4. Create or update the card JSON under `data/cards/partners/`.
5. Preserve screenshot source file names in JSON `source.files`.
6. Use `apply_patch` for text edits.

## Validation

After edits:

```powershell
$files = Get-ChildItem -LiteralPath 'G:\bishojo\data\cards' -Recurse -Filter '*.json'
foreach ($file in $files) {
  Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8 | ConvertFrom-Json | Out-Null
}
powershell -NoProfile -ExecutionPolicy Bypass -File tools\verify_text_encoding.ps1
```

Report the created/updated MD and JSON paths, plus any fields left in `pending_rules`.
