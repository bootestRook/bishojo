// 角色 1 伙伴卡效果适配器。
//
// 本模块只读取 data/cards/partners/*.v1.json，把主动/被动效果规范化成
// 可验证的逻辑条目。它不是 Godot 运行时，也不写回卡牌 JSON；当前职责
// 是在没有战斗运行时代码时，为后续系统提供确定性的数据承接面。

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

export const ROLE1_CARD_FILES = [
  "butterfly_guard.v1.json",
  "kobold.v1.json",
  "brick_mouse.v1.json",
  "blood_wolf.v1.json",
];

export const RARITY_ORDER = ["green", "blue", "purple", "yellow"];

const SUPPORTED_EFFECT_TYPES = new Set([
  "damage",
  "apply_dot_to_enemy",
  "lifesteal_from_damage",
  "buff",
]);

const SUPPORTED_TRIGGERS = new Set([
  null,
  "cooldown_ready",
  "self_gain_haste",
  "other_ally_crit",
  "while_deployed",
]);

const SUPPORTED_TARGET_RULES = new Set([
  "enemy_single",
  "player_core",
  "self",
  "right_adjacent_damage_ally",
  "single_deployed_damage_ally",
]);

const SUPPORTED_STATS = new Set([
  "damage_flat",
  "poison_stack_bonus",
  "cooldown_time_cap_bp",
]);

const PENDING_NULL_FIELDS = [
  "damage_type",
  "can_crit",
  "can_trigger_lifesteal",
];

export function repositoryRoot() {
  const currentFile = fileURLToPath(import.meta.url);
  return path.resolve(path.dirname(currentFile), "..", "..");
}

export function role1CardPaths(root = repositoryRoot()) {
  return ROLE1_CARD_FILES.map((filename) =>
    path.join(root, "data", "cards", "partners", filename),
  );
}

export function loadCard(filePath) {
  return JSON.parse(fs.readFileSync(filePath, "utf8"));
}

export function loadRole1Cards(root = repositoryRoot()) {
  return role1CardPaths(root).map((filePath) => {
    if (!fs.existsSync(filePath)) {
      throw new Error(`Missing card JSON: ${filePath}`);
    }
    return loadCard(filePath);
  });
}

export function normalizeCards(cards) {
  const effects = [];
  const warnings = [];
  const errors = [];
  const seenWarnings = new Set();

  for (const card of cards) {
    const rarityOrder = Array.isArray(card.rarity_order) ? card.rarity_order : RARITY_ORDER;
    for (const rarity of rarityOrder) {
      effects.push(
        ...normalizeCardRarity(card, rarity, warnings, errors, seenWarnings),
      );
    }
  }

  return { cards, effects, warnings, errors };
}

export function indexCards(cards) {
  return Object.fromEntries(cards.map((card) => [card.card_id, card]));
}

export function makeDeployed(cardsById, cardId, rarity, slot, instanceId = null) {
  const card = cardsById[cardId];
  if (!card) {
    throw new Error(`Unknown card_id: ${cardId}`);
  }
  return {
    instance_id: instanceId ?? `${cardId}_${slot}`,
    card_id: cardId,
    rarity,
    slot,
    is_damage_card: Boolean(card.is_damage_card),
  };
}

export function effectsFor(result, cardId, rarity, effectType = null) {
  return result.effects.filter((effect) =>
    effect.card_id === cardId &&
    effect.rarity === rarity &&
    (effectType === null || effect.effect_type === effectType),
  );
}

export function collectWhileDeployedModifiers(result, deployed) {
  // 当前只实现角色 1 卡组需要的 aura_no_stack：同一来源同一效果对同一
  // 目标只应用一次。不同来源是否叠加属于后续规则问题，这里保持可叠加。
  const modifiers = Object.fromEntries(
    deployed.map((partner) => [partner.instance_id, {}]),
  );
  const appliedAuraKeys = new Set();

  for (const source of deployed) {
    for (const effect of effectsFor(result, source.card_id, source.rarity, "buff")) {
      if (effect.trigger_rule !== "while_deployed") {
        continue;
      }
      if (!conditionMatches(effect.metadata.condition, deployed)) {
        continue;
      }

      for (const targetId of resolveTargets(effect.target_rule, source, deployed)) {
        if (!effect.stat || effect.value === null || effect.value === undefined) {
          continue;
        }
        const auraKey = `${source.instance_id}|${effect.effect_id}|${targetId}|${effect.stat}`;
        if (effect.metadata.stack_rule === "aura_no_stack" && appliedAuraKeys.has(auraKey)) {
          continue;
        }
        appliedAuraKeys.add(auraKey);
        modifiers[targetId] ??= {};
        modifiers[targetId][effect.stat] = (modifiers[targetId][effect.stat] ?? 0) + Number(effect.value);
      }
    }
  }

  return modifiers;
}

export function applySelfGainHaste(result, owner, times) {
  const modifiers = {};
  for (const effect of effectsFor(result, owner.card_id, owner.rarity, "buff")) {
    if (effect.trigger_rule !== "self_gain_haste" || effect.target_rule !== "self") {
      continue;
    }
    if (!effect.stat || effect.value === null || effect.value === undefined) {
      continue;
    }
    modifiers[effect.stat] = (modifiers[effect.stat] ?? 0) + Number(effect.value) * times;
  }
  return modifiers;
}

export function applyOtherAllyCrit(result, owner, critActorIds) {
  const modifiers = {};
  const otherCritCount = critActorIds.filter((actorId) => actorId !== owner.instance_id).length;
  if (otherCritCount <= 0) {
    return modifiers;
  }

  for (const effect of effectsFor(result, owner.card_id, owner.rarity, "buff")) {
    if (effect.trigger_rule !== "other_ally_crit" || effect.target_rule !== "self") {
      continue;
    }
    if (!effect.stat || effect.value === null || effect.value === undefined) {
      continue;
    }
    modifiers[effect.stat] = (modifiers[effect.stat] ?? 0) + Number(effect.value) * otherCritCount;
  }
  return modifiers;
}

export function resolveTargets(targetRule, source, deployed) {
  if (targetRule === "self") {
    return [source.instance_id];
  }
  if (targetRule === "enemy_single") {
    return ["enemy_single"];
  }
  if (targetRule === "player_core") {
    return ["player_core"];
  }
  if (targetRule === "right_adjacent_damage_ally") {
    return deployed
      .filter((partner) => partner.slot === source.slot + 1 && partner.is_damage_card)
      .map((partner) => partner.instance_id);
  }
  if (targetRule === "single_deployed_damage_ally") {
    const damageAllies = deployed.filter((partner) => partner.is_damage_card);
    return damageAllies.length === 1 ? [damageAllies[0].instance_id] : [];
  }
  throw new Error(`Unsupported target_rule: ${targetRule}`);
}

export function computeDirectDamage(result, cardId, rarity, statModifiers = {}) {
  const damageEffect = effectsFor(result, cardId, rarity, "damage")[0];
  if (!damageEffect) {
    return 0;
  }
  return Number(damageEffect.value) + Number(statModifiers.damage_flat ?? 0);
}

export function computePoisonStacks(result, cardId, rarity, statModifiers = {}) {
  const dotEffect = effectsFor(result, cardId, rarity, "apply_dot_to_enemy")[0];
  if (!dotEffect) {
    return 0;
  }
  return Number(dotEffect.value) + Number(statModifiers.poison_stack_bonus ?? 0);
}

export function settleDamage(requestedDamage, enemyHp, enemyShield) {
  const shieldDamage = Math.min(Math.max(enemyShield, 0), Math.max(requestedDamage, 0));
  const damageAfterShield = Math.max(requestedDamage, 0) - shieldDamage;
  const actualHpDamage = Math.min(Math.max(enemyHp, 0), damageAfterShield);
  const overkillDamage = Math.max(0, damageAfterShield - actualHpDamage);
  return {
    requested_damage: requestedDamage,
    shield_damage: shieldDamage,
    actual_hp_damage: actualHpDamage,
    overkill_damage: overkillDamage,
    remaining_hp: Math.max(enemyHp, 0) - actualHpDamage,
    remaining_shield: Math.max(enemyShield, 0) - shieldDamage,
  };
}

export function settleLifesteal(
  damageResult,
  lifestealBp,
  coreCurrentHp,
  coreMaxHp,
  shieldAbsorbedDamageCounts = false,
) {
  // 角色 1 卡组当前规则采用 actual_hp_damage 作为基数；只有数据显式
  // 允许时才把护盾吸收计入。
  const healBaseDamage = damageResult.actual_hp_damage +
    (shieldAbsorbedDamageCounts ? damageResult.shield_damage : 0);
  const rawHeal = Math.floor(healBaseDamage * lifestealBp / 10000);
  const appliedHeal = Math.min(Math.max(coreMaxHp - coreCurrentHp, 0), rawHeal);
  return {
    heal_base_damage: healBaseDamage,
    raw_heal: rawHeal,
    applied_heal: appliedHeal,
    core_hp_after: coreCurrentHp + appliedHeal,
  };
}

function normalizeCardRarity(card, rarity, warnings, errors, seenWarnings) {
  const normalized = [];
  for (const skillKind of ["active_skill", "passive_skill"]) {
    const skill = card[skillKind] ?? {};
    const skillTrigger = skill.trigger ?? null;
    if (!SUPPORTED_TRIGGERS.has(skillTrigger)) {
      errors.push(adapterMessage(
        "unsupported_trigger",
        card.card_id,
        null,
        "trigger",
        `Unsupported trigger: ${skillTrigger}`,
        rarity,
      ));
    }

    for (const effect of skill.effects ?? []) {
      validateEffect(card.card_id, rarity, skillTrigger, effect, warnings, errors, seenWarnings);
      const normalizedEffect = normalizeEffect(card, rarity, skillKind, skillTrigger, effect, errors);
      if (normalizedEffect) {
        normalized.push(normalizedEffect);
      }
    }
  }
  return normalized;
}

function validateEffect(cardId, rarity, skillTrigger, effect, warnings, errors, seenWarnings) {
  const effectId = effect.effect_id ?? "";
  if (!SUPPORTED_EFFECT_TYPES.has(effect.effect_type)) {
    errors.push(adapterMessage(
      "unsupported_effect_type",
      cardId,
      effectId,
      "effect_type",
      `Unsupported effect_type: ${effect.effect_type}`,
      rarity,
    ));
  }

  const triggerRule = effect.trigger_rule ?? skillTrigger;
  if (!SUPPORTED_TRIGGERS.has(triggerRule)) {
    errors.push(adapterMessage(
      "unsupported_trigger_rule",
      cardId,
      effectId,
      "trigger_rule",
      `Unsupported trigger_rule: ${triggerRule}`,
      rarity,
    ));
  }

  const targetRule = effect.target_rule ?? effect.heal_target;
  if (!SUPPORTED_TARGET_RULES.has(targetRule)) {
    errors.push(adapterMessage(
      "unsupported_target_rule",
      cardId,
      effectId,
      "target_rule",
      `Unsupported target_rule: ${targetRule}`,
      rarity,
    ));
  }

  const stat = effect.stat_modifier?.stat;
  if (stat !== undefined && !SUPPORTED_STATS.has(stat)) {
    errors.push(adapterMessage(
      "unsupported_stat",
      cardId,
      effectId,
      "stat_modifier.stat",
      `Unsupported stat: ${stat}`,
      rarity,
    ));
  }

  for (const fieldName of PENDING_NULL_FIELDS) {
    if (Object.hasOwn(effect, fieldName) && effect[fieldName] === null) {
      const key = `pending_null_rule|${cardId}|${effectId}|${fieldName}`;
      if (seenWarnings.has(key)) {
        continue;
      }
      seenWarnings.add(key);
      warnings.push(adapterMessage(
        "pending_null_rule",
        cardId,
        effectId,
        fieldName,
        `${cardId}.${effectId}.${fieldName} is null; normalized effect is emitted with a pending-rule warning.`,
        null,
      ));
    }
  }
}

function normalizeEffect(card, rarity, skillKind, skillTrigger, effect, errors) {
  if (!SUPPORTED_EFFECT_TYPES.has(effect.effect_type)) {
    return null;
  }

  const triggerRule = effect.trigger_rule ?? skillTrigger;
  const targetRule = effect.target_rule ?? effect.heal_target;
  const base = {
    card_id: card.card_id,
    card_name: card.name,
    rarity,
    skill_kind: skillKind,
    trigger_rule: triggerRule,
    effect_id: effect.effect_id,
    effect_type: effect.effect_type,
    target_rule: targetRule,
  };

  if (effect.effect_type === "damage") {
    return {
      ...base,
      operation: "deal_direct_damage",
      value: valueByRarity(effect, "value_by_rarity", rarity, card.card_id, effect.effect_id, errors),
      value_unit: "hp_damage",
      status_id: null,
      stat: null,
      modifier_operation: null,
      source_effect_id: null,
      damage_type: effect.damage_type,
      can_crit: effect.can_crit,
      can_trigger_lifesteal: effect.can_trigger_lifesteal,
      metadata: { damage_kind: effect.damage_kind },
    };
  }

  if (effect.effect_type === "apply_dot_to_enemy") {
    return {
      ...base,
      operation: "apply_enemy_dot",
      value: valueByRarity(effect, "stack_by_rarity", rarity, card.card_id, effect.effect_id, errors),
      value_unit: "dot_stacks",
      status_id: effect.status_id,
      stat: null,
      modifier_operation: null,
      source_effect_id: null,
      damage_type: effect.damage_type,
      can_crit: effect.can_crit,
      can_trigger_lifesteal: effect.can_trigger_lifesteal,
      metadata: {
        keyword_id: effect.keyword_id,
        tick_interval_ms: effect.tick_interval_ms,
        duration_rule: effect.duration_rule,
        ignores_shield: effect.ignores_shield,
      },
    };
  }

  if (effect.effect_type === "lifesteal_from_damage") {
    return {
      ...base,
      operation: "heal_from_damage_result",
      value: effect.lifesteal_bp,
      value_unit: "basis_points",
      status_id: null,
      stat: null,
      modifier_operation: null,
      source_effect_id: effect.source_effect_id,
      damage_type: null,
      can_crit: null,
      can_trigger_lifesteal: null,
      metadata: {
        keyword_id: effect.keyword_id,
        heal_target: effect.heal_target,
        shield_absorbed_damage_counts: effect.shield_absorbed_damage_counts,
      },
    };
  }

  const statModifier = effect.stat_modifier ?? {};
  return {
    ...base,
    operation: "modify_stat",
    value: valueByRarity(statModifier, "value_by_rarity", rarity, card.card_id, effect.effect_id, errors),
    value_unit: "stat_value",
    status_id: null,
    stat: statModifier.stat,
    modifier_operation: statModifier.operation,
    source_effect_id: null,
    damage_type: null,
    can_crit: null,
    can_trigger_lifesteal: null,
    metadata: {
      condition: effect.condition ?? null,
      stack_rule: effect.stack_rule ?? null,
      duration_rule: effect.duration_rule ?? null,
    },
  };
}

function valueByRarity(source, fieldName, rarity, cardId, effectId, errors) {
  const values = source[fieldName] ?? {};
  if (!Object.hasOwn(values, rarity)) {
    errors.push(adapterMessage(
      "missing_rarity_value",
      cardId,
      effectId,
      fieldName,
      `Missing ${fieldName}.${rarity}`,
      rarity,
    ));
    return null;
  }
  const value = values[rarity];
  if (typeof value !== "number") {
    errors.push(adapterMessage(
      "invalid_rarity_value",
      cardId,
      effectId,
      fieldName,
      `Expected numeric value for ${fieldName}.${rarity}: ${JSON.stringify(value)}`,
      rarity,
    ));
    return null;
  }
  return value;
}

function conditionMatches(condition, deployed) {
  if (!condition) {
    return true;
  }
  if (Object.hasOwn(condition, "deployed_damage_ally_count")) {
    const actual = deployed.filter((partner) => partner.is_damage_card).length;
    return actual === Number(condition.deployed_damage_ally_count);
  }
  return false;
}

function adapterMessage(code, cardId, effectId, field, message, rarity = null) {
  return {
    code,
    card_id: cardId,
    effect_id: effectId,
    field,
    message,
    rarity,
  };
}

