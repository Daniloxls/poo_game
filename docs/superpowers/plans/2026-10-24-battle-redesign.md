# Battle Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the crude battle with layout "B": a real call stack that drives turns, an action menu next to the active character, a typed console with autocomplete and teaching errors, a clean code combo meter, and juicy hit/defeat feedback in a cartoon style that matches the art.

**Architecture:** Pure logic first, as `RefCounted` classes with headless tests: call stack, console parser/resolver/completer, combo meter, hit impact math, skill outcomes. Then UI components as small scenes, each fed by that logic, and finally a rewritten `battle.gd` that orchestrates rounds, turns, FX and the existing public API (`start_battle`, `battle_won`, `battle_lost`, `set_background`).

**Tech Stack:** Godot 4.7, GDScript, headless SceneTree test scripts (same style as `tests/run_tests_java.gd`).

**Spec:** `docs/superpowers/specs/2026-10-24-battle-redesign-design.md`. Read it first; this plan only adds the decisions the spec leaves open. Mockups: `.superpowers/brainstorm/22848-1792874746/content/*.html` (local only, gitignored).

## Global Constraints

- Engine: Godot 4.7. Run tests with `GODOT=/c/Godot/Godot_v4.7.2-stable_win64_console.exe` and `$GODOT --headless --path . --script res://tests/battle/<file>.gd`. Exit code 0 means pass.
- Viewport 1152×648, stretch `canvas_items`. Enemies left, party right.
- Public API kept: `Battle.start_battle(enemy_group_path: String)`, `Battle.set_background(texture)`, signals `battle_won`, `battle_lost`. Callers: `scenes/chapter_one/festival_city/scripts/tatame_npc.gd`, `scenes/chapter_one/tutorial/dummy.gd`, `scenes/chapter_one/festival_city/scripts/city.gd`.
- Party this round is Turin alone (`rpg_classes/comumzera.tres`: `Atacar`, `UsarItem`). Everything works for any party size.
- All player-facing text in Portuguese; code shown to the player uses Portuguese identifiers (`turno`, `atacar`, `alvo`).
- Colors: panel `#fff8e7`, outline `#1b1b1b` 4px, radius 10, hard shadow offset (5,5) no blur; stack container `#2b2f3a`; top frame `#ffd23f`; enemy frame `#ffd6d2`; method buttons red `#e8463a`, blue `#3a7be8`, green `#3fae5a`; enemy HP `#e8463a`, party HP `#3fae5a`, PP `#3a7be8`, HP ghost `#fff3b0`; numbers: normal `#ffffff`, crit `#ffb347`, heal `#7ee787`, miss `#9aa3b2`.
- Fonts: Chakra Petch Bold (display), JetBrains Mono Bold (code). Never `CONSOLA.TTF`.
- Battle input uses `_unhandled_input` / GUI signals only, never `Input.is_action_just_pressed` polling (so a focused console swallows keys). Navigation uses the built-in `ui_*` actions (keyboard + gamepad).
- Do not change damage formulas (non-goal: balance). `attack.gd`'s formula, including its integer division `target_def/512`, stays as is.
- Comments in Portuguese, matching the codebase.

## Review Focus

1. **Second battle in the same session**: state from the first (stack, combo, panels, time scale, signal connections) must not leak; the second must start, run and end normally. Test in Task 13.
2. **Keys while typing**: with the console focused, `z`/Enter/arrows/letters must not skip animations, move menus or trigger the textbox. Test in Task 11.
3. **Click outside the console**: the click must not press the button under it; typed text stays. Test in Task 11.
4. **Entity dies while its frame is paused in the stack** (enemy killed before its turn; party KO'd mid-round): the enemy frame is removed, the KO frame pops without acting, and if all enemies die mid-round the battle ends at once. Tests in Tasks 1 and 13.
5. **Time scale left changed**: hit-stop/slow motion/skip must always restore `Engine.time_scale = 1.0`, including when the battle ends during slow motion. Test in Task 12.

---

### Task 1: Test helper and call stack

**Files:**
- Create: `tests/battle/battle_test.gd`, `tests/battle/fake_combatant.gd`, `tests/battle/test_call_stack.gd`
- Create: `scenes/battle/logic/turn_frame.gd`, `scenes/battle/logic/call_stack.gd`

**Interfaces:**
- Produces: `BattleTest` (extends SceneTree): `check(name: String, ok: bool, detail = "")`, `eq(name: String, got, expected)`, `finish()` (prints "N ok, M falharam", quits 1 on failure).
- Produces: `FakeCombatant` (RefCounted, test-only): vars `nome, vel, alive := true, party := false, hp, max_hp, classe := "", skills := []`; methods `get_nome()`, `get_vel()`, `is_alive()`, `is_party_member()`, `get_hp()`, `get_max_hp()`, `get_class_name()`, `get_skills()`. This duck type is **the combatant contract** every battle entity implements.
- Produces: `TurnFrame` (RefCounted): `enum State { ACTIVE, PAUSED, KO }`, `var entity`, `var state: State`, `func label() -> String` → `"%s.turno()" % entity.get_nome()`.
- Produces: `CallStack` (RefCounted):
  - `signal pushed(frame: TurnFrame, interrupted: TurnFrame)` (`interrupted` = previous top or null)
  - `signal popped(frame: TurnFrame, resumed: TurnFrame)` (`resumed` = new top or null)
  - `signal frame_removed(frame: TurnFrame)`
  - `static func push_order(combatants: Array) -> Array`
  - `func push(entity) -> TurnFrame`, `func pop() -> TurnFrame`, `func peek() -> TurnFrame`, `func size() -> int`, `func is_empty() -> bool`, `func frames() -> Array` (bottom → top), `func remove(entity) -> void`, `func mark_knocked_out(entity) -> void`, `func clear() -> void`

- [ ] **Step 1: Write the failing tests** in `tests/battle/test_call_stack.gd`:

```gdscript
extends "res://tests/battle/battle_test.gd"
const Fake = preload("res://tests/battle/fake_combatant.gd")

func _initialize() -> void:
	var kath := Fake.new("Kath", 9, true)
	var turin := Fake.new("Turin", 6, true)
	var montanha := Fake.new("Montanha", 3, false)
	var boneco := Fake.new("Boneco", 6, false)   # empata com Turin
	var morto := Fake.new("Morto", 1, false); morto.alive = false

	# ordem de push: mais lento primeiro; empate: inimigo antes do grupo; mortos ficam de fora
	var ordem := CallStack.push_order([turin, kath, montanha, boneco, morto])
	eq("push_order", ordem.map(func(c): return c.get_nome()), ["Montanha", "Boneco", "Turin", "Kath"])

	var s := CallStack.new()
	var interrompidos := []
	s.pushed.connect(func(f, i): interrompidos.append(i.entity.get_nome() if i else ""))
	for c in ordem: s.push(c)
	eq("topo é o mais rápido", s.peek().entity, kath)
	eq("quem foi interrompido", interrompidos, ["", "Montanha", "Boneco", "Turin"])
	eq("topo ativo", s.peek().state, TurnFrame.State.ACTIVE)
	eq("abaixo pausado", s.frames()[2].state, TurnFrame.State.PAUSED)
	eq("label", s.peek().label(), "Kath.turno()")

	var retomado = [null]
	s.popped.connect(func(f, r): retomado[0] = r)
	s.pop()
	eq("pop retoma Turin", retomado[0].entity, turin)
	eq("Turin ativo de novo", s.peek().state, TurnFrame.State.ACTIVE)

	s.remove(boneco)                       # inimigo destruído com o frame pausado
	eq("remove tira do meio", s.frames().map(func(f): return f.entity.get_nome()), ["Montanha", "Turin"])
	s.mark_knocked_out(turin)
	eq("KO marcado", s.peek().state, TurnFrame.State.KO)
	s.pop(); s.pop()
	check("vazia", s.is_empty())
	eq("pop vazio devolve null", s.pop(), null)
	finish()
```

- [ ] **Step 2: Run to verify it fails**

Run: `$GODOT --headless --path . --script res://tests/battle/test_call_stack.gd`
Expected: parse error / non-zero exit (`CallStack` not defined).

- [ ] **Step 3: Implement** `BattleTest`, `FakeCombatant` (`_init(nome, vel, party)`), `TurnFrame`, `CallStack` with the interfaces above. `push_order` filters `is_alive()`, then stable-sorts by `get_vel()` ascending; equal speed puts enemies (`not is_party_member()`) before party; otherwise input order. Pushing pauses the old top; popping activates the new top unless it is KO.

- [ ] **Step 4: Run to verify it passes** (same command). Expected: `… ok, 0 falharam`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add tests/battle scenes/battle/logic
git commit -m "Batalha: pilha de chamadas (push por velocidade, pop, remove, KO)"
```

---

### Task 2: Command parser

**Files:**
- Create: `scenes/battle/console/console_error.gd`, `scenes/battle/console/parsed_command.gd`, `scenes/battle/console/command_parser.gd`
- Test: `tests/battle/test_command_parser.gd`

**Interfaces:**
- Produces: `ConsoleError` (RefCounted): `var message: String`, `var hint: String`, `var span: Vector2i` (start column, end column exclusive) for the underline.
- Produces: `ParsedCommand` (RefCounted): `enum Stage { OBJECT, METHOD, ARGS, DONE }`, `var stage`, `var object_name: String`, `var object_span: Vector2i`, `var method_name: String`, `var method_span: Vector2i`, `var args: PackedStringArray`, `var arg_spans: Array[Vector2i]`, `var error: ConsoleError` (null when the text is a syntactically complete command or a valid prefix of one).
- Produces: `CommandParser.parse(text: String) -> ParsedCommand` (static). Whitespace around tokens is allowed. Identifiers: letters (accents included), digits, `_`. `stage` reflects where the text ends (used by autocomplete): `"Tur"` → OBJECT, `"Turin."`/`"Turin.at"` → METHOD, `"Turin.atacar("`/`"Turin.atacar(Mon"`/`"x(a, "` → ARGS, after `)` → DONE.

Syntax errors (exact messages), each with `span` on the offending text:
- `"Esperava '.' depois de %s"` (e.g. `"Turin atacar"`)
- `"Esperava o nome de um método depois de '.'"` (e.g. `"Turin.("`)
- `"Esperava '(' depois de %s"` (e.g. `"Turin.atacar Montanha"`)
- `"Argumento vazio"` (e.g. `"Turin.atacar(,)"`)
- `"Texto sobrando depois de ')'"` (e.g. `"Turin.atacar() x"`)
- Missing `)` is **not** an error from the parser (it is a prefix); the resolver reports it on Enter.

- [ ] **Step 1: Write the failing tests**: one `eq` per row: `parse("Turin.atacar(Montanha)")` → stage DONE, object `"Turin"`, method `"atacar"`, args `["Montanha"]`, `object_span == Vector2i(0,5)`, `method_span == Vector2i(6,12)`, `arg_spans[0] == Vector2i(13,21)`; `parse(" Turin . usarItem ( Poção_Pequena , Turin ) ")` → args `["Poção_Pequena","Turin"]`; the five stage examples above; each syntax error example → its exact message and span; `parse("")` → stage OBJECT, no error.
- [ ] **Step 2: Run to verify it fails.** Run: `$GODOT --headless --path . --script res://tests/battle/test_command_parser.gd`. Expected: non-zero exit.
- [ ] **Step 3: Implement** a single left-to-right scanner in `command_parser.gd` (no regex), recording spans as it goes.
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Console da batalha: parser de comandos"`

---

### Task 3: Skill outcomes, damage types and the combatant contract on real entities

Moves skill logic off `Button` scripts into pure resolvers, and makes characters and enemies implement the combatant contract. Old animation-playing methods are left in place until Task 14 deletes their callers.

**Files:**
- Create: `rpg_classes/skills/damage_type.gd`, `scenes/battle/logic/action_outcome.gd`, `scenes/battle/logic/enemy_action.gd`
- Modify: `rpg_classes/skills/skill.gd`, `rpg_classes/skills/attack.gd`, `rpg_classes/skills/use_item.gd`, `rpg_classes/skills/attack.tres`, `rpg_classes/skills/use_item.tres`
- Modify: `scenes/party/scripts/character.gd`, `entities/encounters/enemy.gd`, `scenes/encounters/test_dummy.gd`, `scenes/encounters/muscle_guy.gd`
- Test: `tests/battle/test_outcomes.gd`

**Interfaces:**
- Produces: `DamageType` (class_name on `damage_type.gd`): `enum Kind { CORTE, SOCO, FOGO, MAGIA, CURA }`, `static func color(kind) -> Color`, `static func label(kind) -> String` (`"corte"`, …).
- Produces: `SKILL.DAMAGE_TYPE: DamageType.Kind` (`@export`, default `CORTE`). `attack.tres` → `CORTE`, `use_item.tres` → `CURA`.
- Produces: `ActionOutcome` (RefCounted): `enum Kind { DAMAGE, HEAL, MISS }`, `var target`, `var kind`, `var amount: int`, `var crit: bool`, `var damage_type: DamageType.Kind`.
- Produces: skill scripts become `extends RefCounted` with `func resolve(user, targets: Array, multiplier: float) -> Array[ActionOutcome]`. `attack.gd`: same formula as today, `amount = int(damage * multiplier)`, crit flag when the `*2` branch hits, MISS outcome instead of `target.miss()`. `use_item.gd`: `targets = [item: ITEM, alvo]`, HEAL outcome of `int(item.HEALTH_RESTORE * multiplier)` for `Item_type.HEALTH`.
- Produces: `EnemyAction` (RefCounted): `var method_name: String` (shown as `atacar()`), `var outcomes: Array[ActionOutcome]`, `var error_text: String` (non-empty = the enemy's code failed: show it, no outcomes).
- Produces on **both** `character.gd` and `enemy.gd` (combatant contract from Task 1, plus): `func apply_damage(amount: int) -> int` and `func apply_heal(amount: int) -> int` (stat change only, clamped, return the amount actually applied, no animation, no signals), `func is_party_member() -> bool`, `func is_alive() -> bool` (enemy), `func get_skills() -> Array` (enemy returns `[]`), `func get_class_name() -> String` (enemy returns new `@export var classe := ""`), enemy `@export var portrait: Texture2D`.
- Produces: `enemy.gd` `func choose_action(party: Array, enemies: Array) -> EnemyAction` (base: empty action). `test_dummy.gd`: 2–5 `SOCO` damage on a random living party member, `classe = "Boneco"`. `muscle_guy.gd`: `classe = "Lutador"`, targets `party[0]`, `dano = lutador.calcular_dano(alvo)`; `dano < 0` → `error_text = "atacar() falhou: o código do Lutador tem erro"` and no outcome; otherwise one `SOCO` DAMAGE outcome of `dano`.

- [ ] **Step 1: Write the failing tests** in `test_outcomes.gd` using `FakeCombatant` with `get_atk/get_def/get_vel` added as needed: `seed(1)` then attack vs. a target with `vel = -1000` (never misses) → one DAMAGE outcome, `amount > 0`, `damage_type == CORTE`; same seed with `multiplier = 1.25` → amount equals `int(base_damage * 1.25)` computed in the test with the same RNG sequence (re-seed between runs); target `vel = 100000` → MISS with amount 0; potion (`ITEM` with `HEALTH_RESTORE = 10`, type HEALTH) with `multiplier = 1.1` → HEAL 11; `apply_damage(999)` on a fresh `test_dummy` instance → returns 27, `hp == 0`, `is_alive() == false`; `apply_heal` clamps at max HP.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement** the interfaces above. Keep `use_item.gd`'s unreachable damage code out (delete it).
- [ ] **Step 4: Run to verify it passes**, and run the Java suites (`tests/run_tests_java.gd`, `tests/test_integracao_java.gd`): still pass.
- [ ] **Step 5: Commit** `git commit -m "Batalha: resultados de habilidades, tipos de dano e contrato de combatente"`

---

### Task 4: Battle context and command resolver

**Files:**
- Create: `scenes/battle/console/battle_context.gd`, `scenes/battle/console/resolved_command.gd`, `scenes/battle/console/command_resolver.gd`
- Test: `tests/battle/test_command_resolver.gd`

**Interfaces:**
- Consumes: `ParsedCommand`, `ConsoleError` (Task 2); combatant contract (Tasks 1, 3); `SKILL`, `ITEM`.
- Produces: `BattleContext` (RefCounted): `var combatants: Array`, `var active` (top-of-stack entity), `var items: Array` (ITEM with `QUANTITY > 0`);
  `static func normalize(s: String) -> String` (lowercase, strip accents: á à â ã ä é ê í ó ô õ ú ü ç → plain);
  `static func method_name(skill: SKILL) -> String` (`"Atacar"` → `"atacar"`, `"UsarItem"` → `"usarItem"`, `"Usar Item"` → `"usarItem"`);
  `static func params_of(skill: SKILL) -> PackedStringArray` (one entry per `TARGET` value: `ITE` → `"item"`; `ALLY`, `ENEMY`, `EVERYONE` → `"alvo"`; `NONE`, `SELF`, `ALL_ALLY`, `ALL_ENEMY` → no parameter);
  `func find_combatant(name: String)`, `func find_skill(combatant, method: String) -> SKILL`, `func find_item(name: String) -> ITEM` (all by `normalize`).
- Produces: `ResolvedCommand` (RefCounted): `var ok: bool`, `var error: ConsoleError`, `var actor`, `var skill: SKILL`, `var targets: Array` (in parameter order: `ITEM` objects and combatants).
- Produces: `CommandResolver.resolve(parsed: ParsedCommand, ctx: BattleContext) -> ResolvedCommand` (static). A parsed `error` passes through. Semantic errors, exact text, spans on the offending token:
  - unknown object: `"Não existe ninguém chamado '%s' nesta batalha"`
  - not active: `"%s.turno() está pausado: é o turno de %s"` (neutral wording, decided here)
  - enemy as object: `"%s é um inimigo: você só controla o seu grupo"`
  - unknown method: message `"A classe %s não tem o método '%s'"`, hint `"Métodos de %s: %s"` (comma-separated `method_name`s)
  - incomplete (stage below DONE, e.g. missing `)`): `"Comando incompleto: falta ')'"`
  - arg count: `"%s espera %d %s (%s), recebeu %d"` with `"argumento"`/`"argumentos"` (e.g. `"atacar espera 1 argumento (alvo), recebeu 0"`)
  - ENEMY param given an ally: `"%s espera um inimigo, mas %s é do seu grupo"`; ALLY param given an enemy: `"%s espera alguém do seu grupo, mas %s é inimigo"`
  - destroyed enemy: `"%s é null: já foi destruído"`; KO ally: `"%s está fora de combate (HP 0)"`
  - unknown or used-up item: `"Você não tem %s na mochila"`
  - unknown target name: same message as unknown object

- [ ] **Step 1: Write the failing tests** with fakes (Turin party, `skills = [attack.tres, use_item.tres]`, classe `"Nada"`; Kath party paused; Montanha enemy; Boneco enemy not alive; one `ITEM` named `"Poção_Pequena"` qty 2): `Turin.atacar(Montanha)` → ok, `targets == [montanha]`; `turin.ATACAR(montanha)` → ok (normalization); `Turin.usarItem(pocao_pequena, Turin)` → ok, `targets[0]` is the item; and one test per error above with its exact message (e.g. `Turin.curar(Kath)` → message `"A classe Nada não tem o método 'curar'"`, hint `"Métodos de Turin: atacar, usarItem"`, `span == Vector2i(6,11)`).
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Console da batalha: contexto e validação com erros que ensinam"`

---

### Task 5: Autocomplete

**Files:**
- Create: `scenes/battle/console/console_suggestion.gd`, `scenes/battle/console/command_completer.gd`
- Test: `tests/battle/test_command_completer.gd`

**Interfaces:**
- Consumes: `CommandParser`, `BattleContext` (Tasks 2, 4).
- Produces: `ConsoleSuggestion` (RefCounted): `var label: String`, `var detail: String`, `var enabled: bool`, `var result_text: String` (the whole console line after accepting it).
- Produces: `CommandCompleter.suggest(text: String, ctx: BattleContext) -> Array[ConsoleSuggestion]` (static; caret is at the end of `text`). Filter by `normalize` prefix of the token being typed. Per stage:
  - OBJECT: every living combatant; `enabled` only for `ctx.active`; detail `"<classe> · turno atual"` for the active one, `"⏸ pausado"` for other party members, `"inimigo"` for enemies; accepting appends `"."`.
  - METHOD: `method_name` of each skill of the object (empty if the object is not `ctx.active`); detail = skill `DESCRIPTION`; accepting appends `"("`.
  - ARGS: for the current parameter: `item` → items with detail `"x%d" % QUANTITY`; `alvo` for ENEMY → living enemies, detail `"inimigo · HP %d/%d"`; ALLY → living party, detail `"aliado · HP %d/%d"`; EVERYONE → all living. Accepting appends `", "` if more parameters follow, else `")"`.
  - Ordering: enabled first, then list order.

- [ ] **Step 1: Write the failing tests** with the Task 4 fakes: `suggest("", ctx)` labels `["Turin","Kath","Montanha"]` (dead Boneco absent), Kath `enabled == false`; `suggest("Tu", ctx)[0].result_text == "Turin."`; `suggest("Turin.", ctx)` labels `["atacar","usarItem"]`; `suggest("Turin.atacar(", ctx)` labels `["Montanha"]`, detail `"inimigo · HP 32/32"`, `result_text == "Turin.atacar(Montanha)"`; `suggest("Turin.usarItem(", ctx)[0].result_text == "Turin.usarItem(Poção_Pequena, "`; `suggest("Kath.", ctx)` is empty.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Console da batalha: autocompletar por etapa"`

---

### Task 6: Combo meter and hit impact math

**Files:**
- Create: `scenes/battle/logic/combo_meter.gd`, `scenes/battle/fx/hit_impact.gd`
- Test: `tests/battle/test_combo_and_impact.gd`

**Interfaces:**
- Produces: `ComboMeter` (RefCounted): `const MAX_LEVEL := 5`, `const BONUS_PER_LEVEL := 0.05`, `signal changed(level: int)`, `var level := 0`, `func on_console_action() -> float` (returns the multiplier for this action, `1.0 + level * 0.05`, then `level = mini(level + 1, MAX_LEVEL)`), `func on_button_action() -> float` (returns `1.0`, resets level to 0), `func reset()`.
- Produces: `HitImpact` (static funcs): `impact(damage: int, max_hp: int) -> float` (= `clampf(damage / float(max_hp), 0, 1)`), `hitstop_seconds(impact: float, crit: bool) -> float` (= `lerpf(0.03, 0.12, impact)`, crit adds 0.03, capped at 0.12), `shake_pixels(impact: float, crit: bool) -> float` (= `lerpf(0, 14, impact)`, crit adds 6), `impact_frame(impact: float, crit: bool) -> bool` (`impact >= 0.25 or crit`). Constants `KILL_SLOWMO_SECONDS := 0.4`, `KILL_SLOWMO_SCALE := 0.3`, `LAST_KILL_SLOWMO_SECONDS := 0.8`.

- [ ] **Step 1: Write the failing tests**: console multipliers for 7 actions in a row `[1.0, 1.05, 1.10, 1.15, 1.20, 1.25, 1.25]` (compare with `is_equal_approx`); then `on_button_action() == 1.0` and `level == 0`; `changed` emitted with each new level; `impact(16, 32) == 0.5`; `impact(100, 32) == 1.0`; `hitstop_seconds(0, false) ≈ 0.03`; `hitstop_seconds(1, true) ≈ 0.12`; `shake_pixels(0.5, true) ≈ 13`; `impact_frame(0.1, false) == false`, `impact_frame(0.1, true) == true`.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: medidor de combo e intensidade do impacto"`

---

### Task 7: Fonts, hard-shadow style box and battle theme

**Files:**
- Create: `assets/fonts/ChakraPetch-Bold.ttf`, `assets/fonts/JetBrainsMono.ttf`, `assets/fonts/OFL-ChakraPetch.txt`, `assets/fonts/OFL-JetBrainsMono.txt`
- Create: `scenes/battle/ui/hard_shadow_style_box.gd`, `tools/build_battle_theme.gd`, `scenes/battle/ui/battle_theme.tres` (generated), `scenes/battle/ui/battle_fonts.gd`
- Test: `tests/battle/test_theme.gd`

**Interfaces:**
- Produces: `HardShadowStyleBox` (extends `StyleBox`): `@export var bg_color`, `border_color`, `border_width := 4`, `corner_radius := 10`, `shadow_offset := Vector2(5, 5)`, `shadow_color`; `_draw` draws the shadow rect then the panel (two internal `StyleBoxFlat`, no blur). Content margins 10/6.
- Produces: `battle_theme.tres` with type variations (base type in parentheses): `BattlePanel` (PanelContainer, cream), `StackContainer` (PanelContainer, `#2b2f3a`), `StackFrame`, `StackFrameTop`, `StackFrameEnemy` (PanelContainer), `MethodButton` (Button; normal/hover/pressed/focus/disabled boxes; per-button color set at runtime with `add_theme_stylebox_override` from a duplicated box), `ClassTag` (Label). Default font Chakra Petch Bold; `MonoLabel` (Label) uses JetBrains Mono at weight 700 through a `FontVariation`.
- Produces: `BattleFonts` (static): `display() -> Font`, `mono() -> Font`.
- The `.tres` is produced by running `tools/build_battle_theme.gd` (a SceneTree script that builds the Theme in code and `ResourceSaver.save`s it). Hand-drawn frames later replace boxes in this file only.

- [ ] **Step 1: Download fonts.**

```bash
curl -L -o assets/fonts/ChakraPetch-Bold.ttf "https://github.com/google/fonts/raw/main/ofl/chakrapetch/ChakraPetch-Bold.ttf"
curl -L -o assets/fonts/OFL-ChakraPetch.txt "https://github.com/google/fonts/raw/main/ofl/chakrapetch/OFL.txt"
curl -L -o assets/fonts/JetBrainsMono.ttf "https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/JetBrainsMono%5Bwght%5D.ttf"
curl -L -o assets/fonts/OFL-JetBrainsMono.txt "https://github.com/google/fonts/raw/main/ofl/jetbrainsmono/OFL.txt"
```
Expected: four files, the `.ttf` ones > 50 KB. Then `$GODOT --headless --path . --import`.

- [ ] **Step 2: Write the failing test** `test_theme.gd`: loads `battle_theme.tres`; `has_stylebox("panel", "BattlePanel")`; that box `is HardShadowStyleBox` with `bg_color == Color("#fff8e7")`, `border_width == 4`, `shadow_offset == Vector2(5,5)`; `StackFrameTop` bg `#ffd23f`; `StackFrameEnemy` bg `#ffd6d2`; default font resource path ends with `ChakraPetch-Bold.ttf`.
- [ ] **Step 3: Run to verify it fails.**
- [ ] **Step 4: Implement** the style box, `BattleFonts`, the generator; run `$GODOT --headless --path . --script res://tools/build_battle_theme.gd` to write the `.tres`.
- [ ] **Step 5: Run the test to verify it passes.**
- [ ] **Step 6: Commit** `git commit -m "Batalha: fontes, caixa com sombra dura e tema"`

---

### Task 8: Call stack panel

**Files:**
- Create: `scenes/battle/ui/stack_panel.tscn`, `scenes/battle/ui/stack_panel.gd`, `scenes/battle/ui/stack_frame_view.tscn`, `scenes/battle/ui/stack_frame_view.gd`
- Test: `tests/battle/test_stack_panel.gd`

**Interfaces:**
- Consumes: `CallStack`, `TurnFrame` (Task 1), theme (Task 7).
- Produces: `StackPanel` (Control, top-right, theme `StackContainer`, title `"PILHA"` + frame count, a base line at the bottom): `func bind(stack: CallStack, world_pos_of: Callable) -> void` (`world_pos_of(entity) -> Vector2` screen position of the entity's sprite, used as the fly-from point); `func view_for(frame: TurnFrame) -> StackFrameView`; `signal animation_finished`.
  Animations (all awaitable, durations ≤ 0.35 s each): push = card flies from `world_pos_of(entity)` into place; if `interrupted != null`, an `"INTERROMPE!"` tag flashes (yellow box, black text, −6°) and the interrupted view dims to 0.6 alpha with `"⏸ pausado"`; pop = view lifts, fades, slides out; resumed view shows `"▶ retoma"` for 0.6 s; `frame_removed` = strike-through + `"destruído"` + slide out to the right; KO = `"⏸ HP 0"` tag.
- Produces: `StackFrameView` (PanelContainer): shows `frame.label()` in `MonoLabel`; theme variation follows state: top → `StackFrameTop` + rotation −2° + `▶` prefix, enemy → `StackFrameEnemy`, others `StackFrame`.

- [ ] **Step 1: Write the failing test** (instantiates the panel under `root`, binds a `CallStack` with fakes, pushes 3, awaits `animation_finished`): child view count 3; top view `theme_type_variation == "StackFrameTop"`; the enemy view uses `"StackFrameEnemy"`; after `remove(enemy)` and await → 2 views; count label text `"2"`.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.** Use `create_tween()` per animation; queue animations so rapid pushes play in order.
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: painel da pilha com interrupção, pausa e retomada"`

---

### Task 9: Status panels and damage numbers

**Files:**
- Create: `scenes/battle/ui/enemy_status.tscn/.gd`, `scenes/battle/ui/party_status.tscn/.gd`, `scenes/battle/ui/hp_bar.gd`, `scenes/battle/ui/damage_number.tscn/.gd`
- Test: `tests/battle/test_status_panels.gd`

**Interfaces:**
- Produces: `HpBar` (Control, draws itself): `func setup(max_value: int, value: int, fill: Color)`, `func set_value(new_value: int) -> void` (fill jumps at once; ghost `#fff3b0` keeps the old width, waits 0.25 s, drains over 0.35 s), tick every `max_value / 8` HP (min 1), skew −12°, 3px outline. `var ghost_value: float` (readable by tests).
- Produces: `EnemyStatus` (top-left list, one `BattlePanel` row per enemy: portrait 38×38, name, `ClassTag` with `get_class_name()`, `HpBar` red): `func add_enemy(enemy)`, `func refresh(enemy)`, `func remove_enemy(enemy)` (row fades out).
- Produces: `PartyStatus` (bottom-right `BattlePanel`, one row per member: name, HP bar green, PP bar blue, active member name in `#ffd23f`-highlighted chip): `func set_party(members: Array)`, `func refresh(member)`, `func set_active(member)`.
- Produces: `DamageNumber` (Node2D): `static func spawn(parent: Node, at: Vector2, outcome: ActionOutcome) -> void`: text `str(amount)`, `"%d!"` crit, `"+%d"` heal, `"MISS"`; colors from Global Constraints; size 28 / crit 40 / miss 22; pops up 40 px with an overshoot, bounces once, fades by 0.8 s, frees itself.

- [ ] **Step 1: Write the failing test**: `HpBar.setup(32, 32, red)`, `set_value(16)` → right after, `ghost_value == 32`; after awaiting 0.7 s, `ghost_value == 16`; `EnemyStatus.add_enemy(fake montanha)` creates a row whose class tag text is `"Lutador"`; `DamageNumber.spawn` with a crit outcome of 27 creates a label with text `"27!"` and it is freed after 1 s.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: painéis de status com barra fantasma e números de dano"`

---

### Task 10: Action menu, target selection and item picker

**Files:**
- Create: `scenes/battle/ui/action_menu.tscn/.gd`, `scenes/battle/ui/target_selector.gd`, `scenes/battle/ui/item_picker.tscn/.gd`
- Test: `tests/battle/test_action_menu.gd`

**Interfaces:**
- Consumes: `BattleContext` (Task 4), `DamageType` (Task 3), theme (Task 7).
- Produces: `ActionMenu` (Control): `func open_for(actor, skills: Array, anchor: Vector2) -> void` (pops up left of the actor's sprite: buttons stagger in 0.05 s apart with scale overshoot; label `method_name(skill) + "()"`; icon/color by `DAMAGE_TYPE`; description in a small `BattlePanel` tooltip on hover/focus; first button focused; rotations alternate −2°, 1.5°, −1°; focused button scales 1.1), `func close()`, `signal skill_chosen(skill: SKILL)`. Navigation: mouse, `ui_up/ui_down`, `ui_accept`.
- Produces: `TargetSelector` (Node): `func choose(candidates: Array, sprite_of: Callable) -> Array` (awaitable; highlights candidates with a pulsing outline + bobbing `▼` marker, dims non-candidates to 0.5 alpha; mouse click on sprite, `ui_left/ui_right`, `ui_accept`; `ui_cancel` returns `[]`).
- Produces: `ItemPicker` (Control, `BattlePanel` list of items with icon, name, `x%d`): `func choose(items: Array) -> ITEM` (awaitable; null on cancel).
- Candidate rules reuse the resolver's: ENEMY → living enemies, ALLY → living party, EVERYONE → all living.

- [ ] **Step 1: Write the failing test**: `open_for(turin, [attack.tres, use_item.tres], Vector2(600,300))` → two buttons with texts `"atacar()"` and `"usarItem()"`, first has focus; emitting `pressed` on the first emits `skill_chosen` with `attack.tres`; sending an `InputEventAction` `ui_cancel` to an active `TargetSelector.choose([...])` resolves to `[]`.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: menu de ações, seleção de alvo e mochila"`

---

### Task 11: Console UI

**Files:**
- Create: `scenes/battle/ui/battle_console.tscn/.gd`, `scenes/battle/ui/console_highlighter.gd`, `scenes/battle/ui/combo_view.tscn/.gd`
- Modify: `project.godot` (new input action `battle_console`: a keyboard key and a joypad button of the builder's choice, not clashing with existing actions)
- Test: `tests/battle/test_battle_console.gd`

**Interfaces:**
- Consumes: `CommandParser`, `CommandResolver`, `CommandCompleter`, `BattleContext` (Tasks 2, 4, 5), `ComboMeter` (Task 6).
- Produces: `BattleConsole` (Control, bottom strip, opened by a button, `battle_console` action): `func set_context(ctx: BattleContext)`, `func open()`, `func close()`, `var text: String` (kept between turns until a command runs), `signal command_ready(cmd: ResolvedCommand)`, `func is_typing() -> bool`.
  - Single-line `CodeEdit`/`TextEdit` in `MonoLabel` font; `console_highlighter.gd` colors object `#7cb3ff`, method `#ffd54a`, punctuation `#9aa3b2` using the parser's spans.
  - Suggestion list (`BattlePanel`) above the line, updated on every change from `CommandCompleter.suggest`; disabled ones greyed; `Tab` / `ui_accept` on a highlighted suggestion replaces the line with `result_text`; `ui_up/ui_down` move the highlight.
  - Enter: `CommandResolver.resolve`; error → wavy red underline under `error.span` (drawn in `_draw`), message + hint panel under the line, nothing runs; ok → green `"✓ compilado, executando…"` for 0.4 s, `command_ready` emitted, line cleared.
  - **Focus rule**: while focused, the console marks every key event handled (`accept_event()` in `_gui_input`), so nothing reaches `_unhandled_input`.
  - **Click-outside rule**: in `_input`, a mouse press outside the console rect while it has focus → `release_focus()`, keep `text`, and `get_viewport().set_input_as_handled()` so the click does not reach the button under it.
  - Gamepad: when opened by a joypad event, the line is read-only and the suggestion list is the input (d-pad + A accept, B deletes the last token).
- Produces: `ComboView` (next to the console): `func bind(meter: ComboMeter)`; shows `"COMBO x%d"` with a heat bar (5 steps, colors from blue to `#ffb347`), pops (scale 1.25 → 1) on increase, shakes slightly and greys on reset.

- [ ] **Step 1: Write the failing test**: build a console with the Task 4 fakes; type `"Turin.curar(Kath)"` and send Enter → no `command_ready`, error label text `"A classe Nada não tem o método 'curar'"`; replace text with `"Turin.atacar(Montanha)"`, Enter → `command_ready` once with `targets == [montanha]`; **Review Focus 2**: with focus in the console, parse an `InputEventKey` for `Z` and an `InputEventAction` `ui_accept` → a probe node's `_unhandled_input` received nothing; **Review Focus 3**: focus the console, type `"Tur"`, send a left-click `InputEventMouseButton` at the center of a `Button` placed outside the console → the button's `pressed` was not emitted, `console.text == "Tur"`, console no longer has focus.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: console com autocompletar, erros sublinhados e combo"`

---

### Task 12: Battle FX and pacing

**Files:**
- Create: `scenes/battle/fx/battle_pacing.gd`, `scenes/battle/fx/battle_fx.gd`, `scenes/battle/fx/damage_fx_library.gd`, `scenes/battle/fx/damage_fx.tres`, `scenes/battle/fx/glyph_burst.tscn/.gd`, `scenes/battle/ui/victory_panel.tscn/.gd`, `scenes/battle/ui/defeat_panel.tscn/.gd`
- Test: `tests/battle/test_battle_fx.gd`

**Interfaces:**
- Consumes: `ActionOutcome`, `DamageType` (Task 3), `HitImpact` (Task 6), `DamageNumber`, `HpBar`/status panels (Task 9).
- Produces: `BattlePacing` (Node, `process_mode = ALWAYS`): `var speed := 1.0` (2.0 while `ui_accept` is held, via `_unhandled_input`), `var instant := false` (tests), `func wait(seconds: float) -> void` (awaitable; ends early when skip is pressed — a single `ui_accept` press; ignores `Engine.time_scale`), `func hitstop(seconds: float)`, `func slow_motion(seconds: float, scale: float)`, `func restore() -> void` (`Engine.time_scale = 1.0`, `speed = 1.0`). Every change to `Engine.time_scale` goes through this node.
- Produces: `DamageFxLibrary` (Resource): `@export var effects: Dictionary` (DamageType.Kind → SpriteFrames), `@export var sounds: Dictionary` (Kind → AudioStream); `func effect_for(kind) -> SpriteFrames`, `func sound_for(kind) -> AudioStream` (null → placeholder). `damage_fx.tres` starts empty.
- Produces: `BattleFx` (Node): `func play_action(actor_sprite: Node2D, method_label: String, outcomes: Array, sprite_of: Callable, max_hp_of: Callable) -> void` (awaitable). The 5 beats from the spec, with `HitImpact` values: (1) anticipation 0.2 s: actor moves 40 px toward the target, squash, method name pops above; (2) impact: effect for `damage_type` (placeholder = expanding ring + 6 short lines in `DamageType.color`), target `modulate` white flash; (3) `hitstop`, screen shake (camera-less: offset the battle layers' `offset` / `transform`) of `shake_pixels`, impact frame = one frame of black/white silhouette when `impact_frame`; (4) knockback 16 px and return, `DamageNumber.spawn`, sound or none; (5) HP bar update. MISS skips 2–3 and shows `"MISS"`.
  `func play_enemy_destroyed(enemy_sprite: Node2D, name: String, last: bool) -> void`: `slow_motion(KILL_SLOWMO_SECONDS or LAST_KILL_SLOWMO_SECONDS, KILL_SLOWMO_SCALE)`, field zooms 1.05 toward the enemy and back (camera push), white flash, `GlyphBurst` of `0 1 { } ;` drifting up 60 px and fading, label `"%s = null" % name` for 1 s, sprite hidden.
  `func play_party_knocked_out(sprite: Node2D) -> void`: kneel (scale y 0.8, rotate 8°), grey `modulate`.
  `func play_error(actor_sprite: Node2D, text: String) -> void` (enemy code failed: red `BattlePanel` bubble above the actor for 1.2 s).
- Produces: `VictoryPanel.show_result(lines: Array[String]) -> void` (awaitable, slides in, closes on `ui_accept`/click); `DefeatPanel.show_result(tip: String) -> void` (neutral colors, same closing).

- [ ] **Step 1: Write the failing test** (**Review Focus 5**): with `instant = false`, start `slow_motion(0.4, 0.3)`, assert `Engine.time_scale ≈ 0.3` next frame, call `restore()` → `1.0`; start `slow_motion` and send a `ui_accept` skip → after the wait returns, `Engine.time_scale == 1.0`; `play_action` with `instant = true` on dummy sprites and a DAMAGE outcome returns and leaves `time_scale == 1.0`; `effect_for(DamageType.Kind.FOGO)` on an empty library is null.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run to verify it passes.**
- [ ] **Step 5: Commit** `git commit -m "Batalha: efeitos de golpe, derrota, ritmo e painéis de fim"`

---

### Task 13: Battle orchestrator

**Files:**
- Modify (rewrite): `scenes/battle/battle.gd`, `scenes/battle/Battle.tscn`
- Test: `tests/battle/test_battle_flow.gd`

**Interfaces:**
- Consumes: everything above.
- Keeps: `start_battle(enemy_group_path: String)`, `set_background(bg)`, `signal battle_won`, `signal battle_lost`.
- Produces (for tests and future stack-manipulating enemies): `var stack: CallStack`, `var combo: ComboMeter`, `var pacing: BattlePacing`, `func context() -> BattleContext`, `func run_command(cmd: ResolvedCommand, from_console: bool) -> void` (awaitable), `signal turn_started(entity)`.

Flow (one coroutine, no `_process` state machine). Budget: an enemy turn normally under 1.5 s at speed 1; panels slide in when the battle opens.
1. `start_battle`: instance enemies under `Enemies`, place party right / enemies left with the slide-in, fill status panels, `PlayerState.set_on_interface(true)`, show.
2. Round: `CallStack.push_order(living)` → push each (await `StackPanel` animation).
3. Turn: `frame = stack.peek()`; `turn_started.emit(entity)`; a yellow `▼` marker bobs above the active sprite and its status chip highlights; KO frame → pop, continue; party → `ActionMenu.open_for` and `BattleConsole` ready (`context()` refreshed); first of `skill_chosen` (→ items via `ItemPicker`, targets via `TargetSelector`, cancel returns to the menu) or `command_ready`; then `run_command`. Enemy → `choose_action`; `error_text` → `BattleFx.play_error`; else apply outcomes with the FX.
4. `run_command`: multiplier = `combo.on_console_action()` or `combo.on_button_action()`; `outcomes = skill.SKILL_SCRIPT.new().resolve(actor, targets, multiplier)`; for `usarItem` spend the item through the Inventory backpack (`Inventory.get_node("TabContainer/Mochila").spend_item(item)`); apply each outcome with `apply_damage`/`apply_heal` and `BattleFx.play_action`.
5. After each action: dead enemies → `stack.remove`, `play_enemy_destroyed`, status row removed; party at 0 HP → `stack.mark_knocked_out`, `play_party_knocked_out`. All enemies dead → victory immediately (even with frames left); all party KO → defeat.
6. Pop the frame; empty stack → next round.
7. End: victory → `VictoryPanel.show_result(["%s derrotado" % name for each enemy, "Maior combo: x%d"])`, `battle_won.emit()`; defeat → `DefeatPanel.show_result("Dica: comandos digitados no console enchem o combo.")`, `battle_lost.emit()`; then `pacing.restore()`, `combo.reset()`, `stack.clear()`, free `Enemies`, reset party positions/modulate/scale, clear panels, `PlayerState.set_on_interface(false)`, hide. Signals connect once in `_ready` and are never disconnected.

- [ ] **Step 1: Write the failing test** `test_battle_flow.gd` (uses the real autoloads; `Battle.pacing.instant = true`):
  - start `testdummy.tscn`; after the push, `stack.frames()` labels top-down `["Turin.turno()", "Boneco_de_Teste.turno()"]` (Turin vel 13 > dummy 2);
  - resolve `"Turin.atacar(Boneco_de_Teste)"` against `Battle.context()` and `run_command(cmd, true)` in a loop until `battle_won` fires (max 20 turns) → `battle_won` emitted once, `Battle.visible == false`, `Engine.time_scale == 1.0`, `PlayerState.is_on_interface() == false`, `combo.level == 0`;
  - **Review Focus 1**: start `testdummy.tscn` again → the stack is pushed again and a command runs normally;
  - **Review Focus 4**: in a test battle with two dummies, kill the slower one with a command while its frame is paused → its frame is gone; kill the last one → victory fires before the remaining frames are popped;
  - Montanha (load `City.tscn` as the current scene first: `muscle_guy` finds the Lutador in the current scene): with Turin HP 10, an enemy turn deals 10 → `battle_lost` once and `Battle.visible == false`.
- [ ] **Step 2: Run to verify it fails.**
- [ ] **Step 3: Implement** the flow above; build `Battle.tscn` with: Background, Field (party/enemy anchors), `EnemyStatus`, `PartyStatus`, `StackPanel`, `ActionMenu`, `ItemPicker`, `BattleConsole` + `ComboView`, `BattleFx`, `BattlePacing`, `VictoryPanel`, `DefeatPanel`, theme `battle_theme.tres` on the root Control.
- [ ] **Step 4: Run to verify it passes**, plus every earlier battle test and both Java suites.
- [ ] **Step 5: Commit** `git commit -m "Batalha: novo fluxo de rodadas guiado pela pilha"`

---

### Task 14: Dev test battle, cleanup and playtest

**Files:**
- Create: `scenes/battle/dev/test_battle.tscn/.gd`, `scenes/encounters/dev_test_enemies.tscn`
- Delete (after `grep` shows no remaining references): `scenes/battle/ui/BattleBox.tscn`, `scenes/battle/ui/battle_menu.gd`, `char_container.gd`, `method_container.gd`, `tooltip.gd`, `EnemyButton.tscn`, `scenes/battle/ui/scripts/battle_options.gd`, `scenes/battle/ui/scripts/battle_char_container.gd`, `scenes/party/scripts/skill_button.gd`, the `BattleOptions` node in `BattleTurin.tscn`/`BattleKath.tscn`, per-enemy `Healthbar`/`DamageText` nodes and `entities/encounters/healthbar.gd`/`damage_text.gd` if unused, and old animation-playing methods (`take_damage`, `gain_health`, `miss`, `logic`) once nothing calls them.
- Modify: `.gitignore` only if new generated files appear.

**Interfaces:**
- Produces: `test_battle.tscn` (run with F6): builds a temporary 2-member party (a second `BattleTurin.tscn` instance renamed `"Turin2"`, vel 5, with a test class whose skills cover CORTE, SOCO, FOGO, MAGIA, CURA via duplicated `attack.tres` with different `DAMAGE_TYPE`) and two enemies, then starts the battle. Not reachable from the game.

- [ ] **Step 1: Build the dev test battle** and check by running it headless for 5 s: `$GODOT --headless --path . res://scenes/battle/dev/test_battle.tscn --quit-after 300`; expected: no `SCRIPT ERROR` lines.
- [ ] **Step 2: Delete old files** with `git rm` after `grep -rn "<name>" --include=*.gd --include=*.tscn .` returns nothing for each.
- [ ] **Step 3: Run all tests**: every `tests/battle/test_*.gd`, `tests/run_tests_java.gd`, `tests/test_integracao_java.gd`. Expected: all exit 0.
- [ ] **Step 4: Manual playtest** (owner, in the window), checklist:
  - Tutorial dummy fight, Montanha win, Montanha lose → rematch; each with mouse, keyboard and a gamepad.
  - Stack push shows "INTERROMPE!" in the dev test battle; pop/resume visible; destroyed frame slides out.
  - Console: autocomplete at each stage, each error message, click outside keeps text and presses nothing, combo grows and resets on a button action.
  - Holding confirm speeds up, a press skips; no animation feels long.
  - The UI reads as the cartoon style B with Chakra Petch, not the generic look.
- [ ] **Step 5: Commit** `git commit -m "Batalha: batalha de teste, limpeza do código antigo"`
