// 角色 1 伙伴卡效果适配器最小验证入口。
//
// 运行方式：
//   node tools/card_effect_adapter/validate_role1_cards.mjs
//
// 验证范围仅限只读 JSON 加载、规范化效果生成、目标解析和四张卡的关键
// 机制用例；不会写回卡牌数据，也不依赖 Godot 运行时。

import {
  ROLE1_CARD_FILES,
  applyOtherAllyCrit,
  applySelfGainHaste,
  collectWhileDeployedModifiers,
  computeDirectDamage,
  computePoisonStacks,
  effectsFor,
  indexCards,
  loadRole1Cards,
  makeDeployed,
  normalizeCards,
  repositoryRoot,
  settleDamage,
  settleLifesteal,
} from "./adapter.mjs";

const EXPECTED_PENDING_FIELDS = new Set([
  "blood_wolf|blood_wolf_active_damage|damage_type",
  "blood_wolf|blood_wolf_active_damage|can_crit",
  "kobold|kobold_active_damage|damage_type",
  "kobold|kobold_active_damage|can_crit",
  "kobold|kobold_active_damage|can_trigger_lifesteal",
]);

function main() {
  const args = parseArgs(process.argv.slice(2));
  const summary = runValidation(args.repoRoot);
  if (args.json) {
    console.log(JSON.stringify(summary, null, 2));
  } else {
    printTextSummary(summary);
  }
  process.exitCode = summary.ok ? 0 : 1;
}

export function runValidation(repoRoot = repositoryRoot()) {
  const cards = loadRole1Cards(repoRoot);
  const result = normalizeCards(cards);
  const cardsById = indexCards(cards);
  const failures = [];

  expect(cards.length === 4, `expected 4 role1 cards, got ${cards.length}`, failures);
  expect(
    sameSet(new Set(cards.map((card) => card.card_id)), new Set([
      "butterfly_guard",
      "kobold",
      "brick_mouse",
      "blood_wolf",
    ])),
    "loaded card_id set does not match role1 target cards",
    failures,
  );
  expect(result.errors.length === 0, `normalization errors: ${JSON.stringify(result.errors)}`, failures);
  expect(result.effects.length === 32, `expected 32 normalized effects, got ${result.effects.length}`, failures);

  validatePendingWarnings(result, failures);
  validateAllRaritiesEmitEffects(result, failures);
  validateButterflyGuard(result, cardsById, failures);
  validateKobold(result, cardsById, failures);
  validateBrickMouse(result, cardsById, failures);
  validateBloodWolf(result, failures);

  return {
    ok: failures.length === 0,
    loaded_files: ROLE1_CARD_FILES,
    card_count: cards.length,
    normalized_effect_count: result.effects.length,
    warning_count: result.warnings.length,
    warnings: result.warnings,
    error_count: result.errors.length,
    errors: result.errors,
    failures,
    null_field_policy: "保留待确认警告；规范化效果继续生成，验证仅因未支持机制或结构错误失败。",
  };
}

function validateAllRaritiesEmitEffects(result, failures) {
  const expectedCounts = {
    butterfly_guard: 2,
    kobold: 2,
    brick_mouse: 2,
    blood_wolf: 2,
  };
  for (const [cardId, countPerRarity] of Object.entries(expectedCounts)) {
    for (const rarity of ["green", "blue", "purple", "yellow"]) {
      const actual = effectsFor(result, cardId, rarity).length;
      expect(
        actual === countPerRarity,
        `${cardId}.${rarity} expected ${countPerRarity} effects, got ${actual}`,
        failures,
      );
    }
  }
}

function validatePendingWarnings(result, failures) {
  const actual = new Set(
    result.warnings
      .filter((warning) => warning.code === "pending_null_rule")
      .map((warning) => `${warning.card_id}|${warning.effect_id}|${warning.field}`),
  );
  expect(
    sameSet(actual, EXPECTED_PENDING_FIELDS),
    `pending null warnings mismatch: expected ${JSON.stringify([...EXPECTED_PENDING_FIELDS])}, got ${JSON.stringify([...actual])}`,
    failures,
  );
}

function validateButterflyGuard(result, cardsById, failures) {
  const greenDot = effectsFor(result, "butterfly_guard", "green", "apply_dot_to_enemy")[0];
  expect(greenDot.value === 3, "butterfly_guard green poison stacks should be 3", failures);
  expect(greenDot.status_id === "poison", "butterfly_guard DOT status should be poison", failures);
  expect(greenDot.metadata.tick_interval_ms === 1000, "poison tick interval should be 1000ms", failures);
  expect(greenDot.metadata.ignores_shield === true, "poison should ignore shield", failures);
  expect(greenDot.can_crit === false, "poison should not crit", failures);
  expect(greenDot.can_trigger_lifesteal === false, "poison should not trigger lifesteal", failures);

  const owner = makeDeployed(cardsById, "butterfly_guard", "yellow", 1, "butterfly_yellow");
  const hasteModifiers = applySelfGainHaste(result, owner, 2);
  expect(
    hasteModifiers.poison_stack_bonus === 16,
    "butterfly_guard yellow should gain 16 poison_stack_bonus after two haste events",
    failures,
  );
  expect(
    computePoisonStacks(result, "butterfly_guard", "yellow", hasteModifiers) === 19,
    "butterfly_guard yellow active poison should be 3 + 16 = 19 stacks",
    failures,
  );
}

function validateKobold(result, cardsById, failures) {
  const expectedDamage = {
    green: 20,
    blue: 30,
    purple: 40,
    yellow: 50,
  };
  for (const [rarity, expected] of Object.entries(expectedDamage)) {
    expect(
      computeDirectDamage(result, "kobold", rarity) === expected,
      `kobold ${rarity} direct damage should be ${expected}`,
      failures,
    );
  }

  const owner = makeDeployed(cardsById, "kobold", "blue", 1, "kobold_blue");
  const critModifiers = applyOtherAllyCrit(
    result,
    owner,
    ["ally_a", "kobold_blue", "ally_b", "ally_c"],
  );
  expect(
    critModifiers.damage_flat === 30,
    "kobold blue should gain 30 damage_flat from three other-ally crits; self crit ignored",
    failures,
  );
  expect(
    computeDirectDamage(result, "kobold", "blue", critModifiers) === 60,
    "kobold blue damage after passive should be 30 + 30 = 60",
    failures,
  );
}

function validateBrickMouse(result, cardsById, failures) {
  const brick = makeDeployed(cardsById, "brick_mouse", "purple", 0, "brick_purple");
  const kobold = makeDeployed(cardsById, "kobold", "purple", 1, "kobold_purple");
  const butterfly = makeDeployed(cardsById, "butterfly_guard", "purple", 2, "butterfly_purple");

  const oneDamageModifiers = collectWhileDeployedModifiers(result, [brick, kobold, butterfly]);
  expect(
    oneDamageModifiers.kobold_purple.damage_flat === 30,
    "brick_mouse purple should add 30 damage_flat to right adjacent damage ally",
    failures,
  );
  expect(
    oneDamageModifiers.kobold_purple.cooldown_time_cap_bp === -1500,
    "brick_mouse purple should add -1500 cooldown_time_cap_bp when only one damage ally is deployed",
    failures,
  );
  expect(
    !Object.hasOwn(oneDamageModifiers.butterfly_purple, "damage_flat"),
    "brick_mouse should not apply damage_flat to non-damage partner",
    failures,
  );

  const bloodWolf = makeDeployed(cardsById, "blood_wolf", "purple", 3, "blood_wolf_purple");
  const twoDamageModifiers = collectWhileDeployedModifiers(result, [brick, kobold, butterfly, bloodWolf]);
  expect(
    !Object.hasOwn(twoDamageModifiers.kobold_purple, "cooldown_time_cap_bp"),
    "brick_mouse cooldown cap aura should not apply when two damage allies are deployed",
    failures,
  );

  const nonDamageRight = collectWhileDeployedModifiers(result, [brick, butterfly, kobold]);
  expect(
    !Object.hasOwn(nonDamageRight.butterfly_purple, "damage_flat"),
    "brick_mouse right-adjacent aura should ignore a right-side non-damage partner",
    failures,
  );
}

function validateBloodWolf(result, failures) {
  const damage = computeDirectDamage(result, "blood_wolf", "yellow");
  expect(damage === 20, "blood_wolf yellow direct damage should be 20", failures);

  const lifestealEffect = effectsFor(result, "blood_wolf", "yellow", "lifesteal_from_damage")[0];
  const noShieldDamage = settleDamage(damage, 80, 0);
  const noShieldHeal = settleLifesteal(
    noShieldDamage,
    Number(lifestealEffect.value),
    40,
    100,
    Boolean(lifestealEffect.metadata.shield_absorbed_damage_counts),
  );
  expect(noShieldDamage.actual_hp_damage === 20, "blood_wolf should deal 20 actual hp damage without shield", failures);
  expect(noShieldHeal.applied_heal === 20, "blood_wolf lifesteal should heal 20 from 20 actual hp damage", failures);

  const shieldedDamage = settleDamage(damage, 80, 15);
  const shieldedHeal = settleLifesteal(
    shieldedDamage,
    Number(lifestealEffect.value),
    40,
    100,
    Boolean(lifestealEffect.metadata.shield_absorbed_damage_counts),
  );
  expect(shieldedDamage.shield_damage === 15, "blood_wolf shield test should absorb 15", failures);
  expect(shieldedDamage.actual_hp_damage === 5, "blood_wolf shield test should leave 5 actual hp damage", failures);
  expect(shieldedHeal.applied_heal === 5, "blood_wolf lifesteal should ignore shield-absorbed damage", failures);
}

function parseArgs(argv) {
  const args = {
    repoRoot: repositoryRoot(),
    json: false,
  };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--json") {
      args.json = true;
    } else if (arg === "--repo-root") {
      index += 1;
      if (!argv[index]) {
        throw new Error("--repo-root requires a value");
      }
      args.repoRoot = argv[index];
    } else {
      throw new Error(`Unknown argument: ${arg}`);
    }
  }
  return args;
}

function expect(condition, message, failures) {
  if (!condition) {
    failures.push(message);
  }
}

function sameSet(left, right) {
  if (left.size !== right.size) {
    return false;
  }
  for (const value of left) {
    if (!right.has(value)) {
      return false;
    }
  }
  return true;
}

function printTextSummary(summary) {
  printUtf8("card_effect_adapter validation");
  printUtf8(`ok=${summary.ok}`);
  printUtf8(`cards=${summary.card_count}`);
  printUtf8(`normalized_effects=${summary.normalized_effect_count}`);
  printUtf8(`warnings=${summary.warning_count}`);
  printUtf8(`errors=${summary.error_count}`);
  printUtf8(`null_field_policy=${summary.null_field_policy}`);
  if (summary.warnings.length > 0) {
    printUtf8("pending_warnings:");
    for (const warning of summary.warnings) {
      printUtf8(`- ${warning.card_id} ${warning.effect_id} ${warning.field}`);
    }
  }
  if (summary.failures.length > 0) {
    printUtf8("failures:");
    for (const failure of summary.failures) {
      printUtf8(`- ${failure}`);
    }
  }
}

function printUtf8(text) {
  process.stdout.write(`${text}\n`);
}

main();

