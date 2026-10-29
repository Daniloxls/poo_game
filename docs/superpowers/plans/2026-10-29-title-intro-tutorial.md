# Title screen, opening and tutorial Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the overlay title + bare tutorial with a real title screen, a boot-log opening, a
checklist-driven tutorial with a scripted heal fight, and an automatic crack-and-fall into Deep Code.

**Architecture:** The title becomes the main scene and hands off to a new opening scene, which
warps to `Tutorial.tscn`. The tutorial gets a checklist HUD (`ChecklistHud`) that each room ticks.
The heal lesson lives in a new encounter (`tutorial_dummy.tscn`) that drives two small new hooks in
`Battle` (locked skills, a hint panel) plus an optional "no console" flag. The ending replaces
`PortalShow` with a crack cutscene and a separate fall scene that warps to `DeepCode.tscn`.

**Tech Stack:** Godot 4.7.2, GDScript. Headless tests extend `res://tests/battle/battle_test.gd`
(`check`/`eq`/`finish`), run with
`C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/<dir>/<file>.gd`.

**Spec:** `docs/superpowers/specs/2026-10-29-title-intro-tutorial-design.md`

## Global Constraints

- Player-facing text is Portuguese; copy below is draft, the owner edits it later.
- No programming in the tutorial: the battle console is off in the tutorial fight; nothing is editable.
- No save system. Continuar and Créditos are shown but disabled (greyed, skipped by the cursor).
- Title art `assets/screens/menu_background.png` stays static (no breathing/zoom animation).
- Do not touch `scenes/encounters/testdummy.tscn` / `test_dummy.gd` behaviour: `tests/battle/test_battle_flow.gd` fights it by attacking until won.
- Work on a branch, not `main`. Do not use a git worktree inside the project (it leaks `.dialogue` paths into `project.godot`).
- `main` has unrelated uncommitted changes (`City.tscn`, `tileset.tres`, `assets/open-source/`). Never stage them: always `git add` explicit paths.
- Running the tests lets the dialogue plugin rewrite `project.godot`: after each test run, `git diff project.godot` and revert any change you did not make on purpose.
- A new `class_name` needs `Godot --headless --path . --import` once before headless tests can see it.
- New tests go in `tests/tutorial/`; add that folder to `tests/run_all_tests.gd` (same loop as `tests/inventario`).

## Findings the spec did not know

- **Running does not exist.** The `run` action is bound (Shift), but `entities/player/player_script.gd`
  never reads it: speed is a constant `velocity * 3600`. Task 5 adds it.
- **Interact is Space**, but the wall drawing `DesenhosParede/Activate` shows a Z (`assets/props/z.png`).
  Use a placeholder "ESPAÇO" drawing; the owner redraws it.
- The level is rebuilt on `TileMapLayer`s (spec §4, 5-room snake) with a generated sketch-style
  placeholder tileset at 500×500 (same as `scenes/chapter_one/festival_city/tileset.tres`).
  `Tutorial.tscn` keeps its path/uid; its painted `TextureRect` and `MapBorder` polygon go away.

## Review Focus

1. **Player reaches the fight with no Poção** (used it from the inventory menu, which `Progresso` unlocks by default, or a debug path): Atacar locks until one is used. Expected: no softlock. `tutorial_dummy` gives one Poção at battle start if the backpack has none (Task 4 test `sem_pocao`).
2. **Player cancels the item picker (Esc) while Atacar is locked**: expected the menu reopens with Atacar still locked and the Poção still there (Task 4 test `cancelar_item`).
3. **Player is standing in the timed gate when the timer runs out**: expected the gate waits until the player is clear instead of closing on them (Task 5 test `fecha_ocupado`).
4. **Interact spam**: opening the chest twice or pulling the gate lever while open. Expected one Poção ever, and no timer restart that strands the player mid-gate (Task 5 tests `bau_uma_vez`, `alavanca_aberta`).
5. **Confirm held/spammed on the title screen and during the opening**: expected exactly one scene change (Task 2 test `novo_jogo_uma_vez`; Task 3 ignores input).

---

### Task 1: Battle hooks: locked skills, hint panel, console off

**Files:**
- Modify: `scenes/battle/ui/action_menu.gd` (`open_for`)
- Modify: `scenes/battle/battle.gd` (`start_battle`, `_open_menu`, `run_command`, `_end`)
- Modify: `scenes/battle/Battle.tscn` (add `UI/Root/Hint`)
- Test: `tests/battle/test_action_menu.gd`, `tests/battle/test_battle_hooks.gd` (new)

**Interfaces:**
- Produces:
  - `ActionMenu.open_for(actor, skills: Array, anchor: Vector2, locked: Array = []) -> void`. A skill in `locked` gets a button with `disabled = true`, `modulate.a = 0.35`, `focus_mode = FOCUS_NONE`; initial focus goes to the first unlocked button.
  - `Battle.locked_skills: Array` (of `SKILL`). `_open_menu` passes it to `open_for`. `run_command` refuses a locked skill with `fx.play_error(actor, "<metodo>() está bloqueado")` and reopens the menu. Reset to `[]` in `_end`.
  - `Battle.show_hint(text: String) -> void` / `Battle.hide_hint() -> void`. `Hint` is a `PanelContainer` (`theme_type_variation = &"BattlePanel"`) with a `Label`, top-center of `UI/Root`, hidden by default. `_end` hides it.
  - `Battle.start_battle(enemy_group_path: String, console_on := true) -> void`. When false, the console stays `PROCESS_MODE_DISABLED` for the whole battle and `UI/Root/ConsoleButton` is hidden. Restored by `_end` (button visible again).

- [ ] **Step 0: Branch** — `git checkout -b tutorial-redesign`
- [ ] **Step 1: Failing tests**
  - In `test_action_menu.gd`, after the existing menu checks: `menu.open_for(turin, [attack, use_item], Vector2(600,300), [attack])`, then `check("travado: disabled", btns[0].disabled)`, `check("foco no destravado", btns[1].has_focus())`, `await press("ui_up")`, `check("ui_up não foca travado", btns[1].has_focus())`.
  - New `test_battle_hooks.gd` (pattern of `test_battle_flow.gd`, real autoloads, `battle.pacing.instant = true`, `testdummy.tscn`):
    - `start_battle(path, false)`, wait for Turin's turn: `eq("console desligado", battle.console.process_mode, Node.PROCESS_MODE_DISABLED)`, `eq("botão escondido", battle.get_node("UI/Root/ConsoleButton").visible, false)`.
    - `battle.locked_skills = [attack]` then reopen (`battle._open_menu()`): `check("atacar travado", battle.action_menu.buttons()[0].disabled)`; `await battle.run_command(cmd("Turin.atacar(Boneco_de_Teste)"), false)` → `eq("comando travado não age", battle._acting, turin)` and dummy HP unchanged.
    - `battle.show_hint("x")` → `eq("dica visível", hint.visible, true)`.
    - Clear `locked_skills`, fight until won, then: `eq("trava zerada", battle.locked_skills, [])`, `eq("dica some", hint.visible, false)`, `eq("botão volta", ConsoleButton.visible, true)`.
    - Next `start_battle(path)` (default): `eq("console volta", battle.console.process_mode, Node.PROCESS_MODE_INHERIT)`.
- [ ] **Step 2: Run both, verify they fail** (unknown `locked`/`show_hint`, extra arg).
- [ ] **Step 3: Implement** the interfaces above.
- [ ] **Step 4: Run** `test_action_menu.gd`, `test_battle_hooks.gd`, `test_battle_flow.gd`. Expected: `N ok, 0 falharam` each.
- [ ] **Step 5: Commit** `git add scenes/battle/ui/action_menu.gd scenes/battle/battle.gd scenes/battle/Battle.tscn tests/battle/test_action_menu.gd tests/battle/test_battle_hooks.gd` → `feat(batalha): habilidades travadas, dica e console desligável`

### Task 2: Title screen as main scene

**Files:**
- Rewrite: `ui/title_screen/TitleScreen.tscn`, `ui/title_screen/title_screen.gd`
- Create: `ui/options/Opcoes.tscn` (moved out of `Inventory.tscn`)
- Modify: `ui/inventory/Inventory.tscn` (instance `Opcoes.tscn` at `Menu/Telas/Opcoes`, same node name)
- Modify: `project.godot` (remove `TitleScreen` autoload; `run/main_scene="res://ui/title_screen/TitleScreen.tscn"`)
- Modify: `tests/janela_menu_depurar.gd:38` (drop the `TitleScreen` `queue_free`)
- Test: `tests/tutorial/test_title_screen.gd` (new), plus existing `tests/inventario/test_controle.gd`, `test_resumo.gd`

**Interfaces:**
- Consumes: `LevelWarp.change_level(scene)`; `MusicPlayer` (AudioStreamPlayer autoload).
- Produces: `TitleScreen.tscn` root `Control` (full rect), script `title_screen.gd`:
  - `const ABERTURA := "res://scenes/chapter_one/opening/Abertura.tscn"`
  - `func botoes() -> Array[Button]` in order Novo Jogo, Continuar, Opções, Créditos.
  - `func novo_jogo() -> void`: guarded by `var _saindo := false`, plays `confirmar`, calls `LevelWarp.change_level(ABERTURA)` once.
  - `ui/options/Opcoes.tscn`: root `PanelContainer` named `Opcoes` with `opcoes_tab.gd` and its children unchanged (`%Velocidade`, `%AvancoAutomatico`).

Layout per spec §1: static background, bottom gradient, one logo block (BreatheFire `assets/fonts/BreatheFireIii-PKLOB.ttf`, color `#ef801c`, outline `#773b03`, shadow `#161616c9`; "PROTETORES DA" smaller above "Ordem dos Objetos"), menu bottom-center, selected = yellow `#ffd23f` with `▶ ` prefix, disabled = grey with `focus_mode = FOCUS_NONE`. Version label `v0.1` bottom-left. Kenney sounds `assets/sounds/interface/kenney/{clique,confirmar,voltar}.ogg` on move/confirm/back. Music `assets/bgm/Dream Eliot Corley.mp3` via `MusicPlayer`. Opções shows an `Opcoes.tscn` instance over the menu, `abrir_tela(null)` on open, Esc/`ui_cancel` closes it and refocuses Opções. `PlayerState.set_on_interface(true)` in `_ready`.

- [ ] **Step 1: Failing test** `test_title_screen.gd`: instantiate `TitleScreen.tscn` into root. `eq("4 botões", t.botoes().size(), 4)`; `eq("textos", t.botoes().map(func(b): return b.text.trim_prefix("▶ ")), ["Novo Jogo","Continuar","Opções","Créditos"])`; `check("continuar desabilitado", t.botoes()[1].disabled)`; `check("créditos desabilitado", t.botoes()[3].disabled)`; `check("foco em Novo Jogo", t.botoes()[0].has_focus())`; press `ui_down` → `check("pula desabilitado", t.botoes()[2].has_focus())`. `novo_jogo_uma_vez`: `t.trocar = func(_p): chamadas += 1`, call `t.novo_jogo()` twice → `eq("troca uma vez", chamadas, 1)`.
  (So `title_screen.gd` has `var trocar: Callable` defaulting to `LevelWarp.change_level`, and `novo_jogo` calls `trocar.call(ABERTURA)`.)
- [ ] **Step 2: Run, verify fail.**
- [ ] **Step 3: Implement**; move the Opções panel; edit `project.godot` and `janela_menu_depurar.gd`.
- [ ] **Step 4: Run** `test_title_screen.gd`, `tests/inventario/test_controle.gd`, `tests/inventario/test_resumo.gd`, and `tests/janela_menu_depurar.gd` if it is runnable headless. Expected all pass. Revert stray `project.godot` changes from the dialogue plugin (keep yours).
- [ ] **Step 5: Commit** title files, `ui/options/`, `Inventory.tscn`, `project.godot`, `tests/janela_menu_depurar.gd`, `tests/tutorial/test_title_screen.gd`, `tests/run_all_tests.gd` (add `tests/tutorial`) → `feat(título): tela de título como cena principal`

### Task 3: Opening boot log

**Files:**
- Create: `scenes/chapter_one/opening/Abertura.tscn`, `scenes/chapter_one/opening/abertura.gd`

**Interfaces:**
- Produces: `const LINHAS: Array` of `[bbcode: String, pausa_depois: float]`, copy from spec §2 (8 lines, the 5-item `new Teste(turin) {...}` block, the red `aviso: acesso desconhecido em 0x00DEEP` with grey `(ignorado)`). Colors: keywords `#c084fc`, methods `#60a5fa`, OK `#4ade80`, warning `#f87171`, default `#9ca3af`; font `assets/fonts/JetBrainsMono.ttf`; background `#05070d`.
- Each line types out with `visible_characters` (~0.02 s/char), total ≈ 8 s. Then a 0.6 s wipe to paper color `#f4f1ea` (circle shader or fade; builder's choice) and `LevelWarp.change_level("res://scenes/chapter_one/tutorial/Tutorial.tscn")`.
- Not skippable; all input ignored (`PlayerState.set_on_scene(true)` during, `false` before warping).
- The 5 test names are inlined here for now; Task 4 moves them to `ChecklistHud.ITENS_TESTE` and switches the opening to build its 5 lines from it, so the two lists can't drift.

No unit test (pure timed visuals). Verification is Task 8's play-through.

- [ ] **Step 1: Implement.**
- [ ] **Step 2: Run the game from the title, press Novo Jogo**: the log types, the wipe plays, the tutorial loads. No errors in the output.
- [ ] **Step 3: Commit** `scenes/chapter_one/opening/` → `feat(abertura): log de inicialização do sonho`

### Task 4: Checklist HUD and the tutorial fight

Two deliverables, one reviewer gate: the HUD and the fight that ticks it.

**Files:**
- Create: `scenes/chapter_one/tutorial/checklist_hud.gd` (`class_name ChecklistHud extends CanvasLayer`, builds its UI in code like `ActionMenu`)
- Create: `scenes/encounters/tutorial_dummy.tscn`, `scenes/encounters/tutorial_dummy.gd` (`extends "res://scenes/encounters/test_dummy.gd"`)
- Modify: `scenes/chapter_one/tutorial/dummy.gd` (`interaction` → `Battle.start_battle("res://scenes/encounters/tutorial_dummy.tscn", false)`)
- Modify: `scenes/chapter_one/opening/abertura.gd` (use `ChecklistHud.ITENS_TESTE`)
- Test: `tests/tutorial/test_checklist.gd`, `tests/tutorial/test_tutorial_fight.gd`

**Interfaces:**
- Produces `ChecklistHud`:
  - `const ITENS_TESTE := ["andar", "interagir", "correr", "lutar", "usarItem"]`
  - `signal marcou(id: String)`, `signal completou`
  - `func marcar(id: String) -> void`: unknown or already-marked ids are ignored (no signal). Emits `completou` once, when the 5th is marked.
  - `func marcado(id: String) -> bool`, `func completo() -> bool`
  - `func texto() -> String`: plain text of the line, e.g. `"[✓] andar()  [ ] interagir()  [ ] correr()  [ ] lutar()  [ ] usarItem()"`, plus `"  [!] turin.cair()"` after `mostrar_erro()`.
  - `func mostrar_erro() -> void` (red `[!] turin.cair()`), `func piscar_aviso() -> void` (briefly shows red `aviso: acesso desconhecido em 0x00DEEP`), `func mensagem(texto: String) -> void` (terminal-style line under the list, used for "Teste concluído. Acordando...").
  - Top-left, small, JetBrainsMono, same colors as Task 3. Ticking plays a short flash and `confirmar.ogg`.
- Produces `tutorial_dummy.gd`:
  - `const LIMIAR := 13` (dummy HP floor until the Poção is used), `const VIDA_APOS_GLITCH := 3`
  - `const POCAO := preload("res://scenes/items/repo/potion.tres")`
  - `static func dano_limitado(hp: int, dano: int, piso: int) -> int`: returns `clampi(dano, 0, maxi(hp - piso, 0))`
  - `var pocao_usada := false`, `var glitch_feito := false`
  - `apply_damage(amount)` override: while `not pocao_usada`, damage goes through `dano_limitado(hp, amount, LIMIAR)`.
  - In `_ready`: if `Inventory.mochila` has no item named `POCAO.ITEM_NAME` with quantity > 0, add one. Connect `Inventory.mochila.mudou` (set `pocao_usada = true`, since only item use changes the backpack mid-battle) and `Battle.turn_started`. Disconnect both in `_exit_tree`.
  - `turn_started(who)` for a party member: `Battle.locked_skills = [ATTACK] if glitch_feito and not pocao_usada else []`. Hint: before any attack `"Escolha atacar()"`; while locked `"Atacar está fora do ar! Use usarItem() → Poção"`; otherwise `hide_hint()`. `ATTACK = preload("res://rpg_classes/skills/attack.tres")`.
  - `choose_action`: if `hp <= LIMIAR and not glitch_feito and not pocao_usada` → `glitch_feito = true`, glitch flicker on its sprite (modulate/offset jitter ~0.4 s), one hit with `amount = maxi(turin.hp - VIDA_APOS_GLITCH, 0)`. Otherwise the usual 2–5 punch through `dano_limitado(target.hp, dmg, 1)`. Turin never drops below 1.
  - Turin starts the fight at full HP: `dummy.gd::interaction` sets `Party.get_node("Turin").hp = max_hp` before `start_battle`.
- `tutorial.gd` (Task 6) ticks `lutar` and `usarItem` on `Battle.battle_won` (the HUD is hidden in battle, so ticking at the end looks the same).

- [ ] **Step 1: Failing test** `test_checklist.gd`: new `ChecklistHud` in root; `marcar("andar")` → `check(marcado("andar"))`, signal count 1; `marcar("andar")` again → still 1; `marcar("voar")` → ignored; mark the other 4 → `check(completo())`, `completou` count 1; `eq` on `texto()` full line with all `[✓]`; `mostrar_erro()` → `check(texto().ends_with("[!] turin.cair()"))`.
- [ ] **Step 2: Failing test** `test_tutorial_fight.gd` (real autoloads, `pacing.instant = true`, `Inventory.mochila` cleared first):
  - `dano_limitado(27, 16, 13) == 14`, `(13, 16, 13) == 0`, `(3, 5, 1) == 2`, `(1, 4, 1) == 0`.
  - `sem_pocao`: empty backpack, `start_battle(tutorial_dummy, false)` → backpack has 1 Poção.
  - Turin's turn: `eq("dica atacar", hint label text, "Escolha atacar()")`; attack via `run_command(cmd("Turin.atacar(Boneco_de_Teste)"), false)` → `eq("boneco no limiar", dummy.hp, 13)`.
  - After the dummy's turn: `eq("glitch deixa Turin em 3", turin.hp, 3)`; `check("atacar travado", battle.action_menu.buttons()[0].disabled)`.
  - `cancelar_item`: `battle._on_skill_chosen(use_item)` then `battle.item_picker` cancel (`ui_cancel`) → menu reopens, `buttons()[0].disabled` still true, Poção count still 1.
  - Use the Poção (`cmd("Turin.usarItem(Poção)")`) → `check("pocao_usada")`; next Turin turn `eq("destravado", battle.locked_skills, [])`.
  - Fight until won (≤ 20 turns): `check("venceu")`, and across the whole fight `turin.hp >= 1` (sample after each enemy turn).
- [ ] **Step 3: Run both, verify fail.** Run `--import` first (new `class_name`).
- [ ] **Step 4: Implement** `checklist_hud.gd`, `tutorial_dummy.gd/.tscn` (copy `testdummy.tscn`, swap the script), the `dummy.gd` change, and switch `abertura.gd` to build its 5 lines from `ChecklistHud.ITENS_TESTE`.
- [ ] **Step 5: Run** both new tests + `test_battle_flow.gd`. Expected all pass.
- [ ] **Step 6: Commit** the files above → `feat(tutorial): checklist e luta com cura obrigatória`

### Task 5: Running, chest and timed gate

**Files:**
- Modify: `entities/player/player_script.gd` (speed)
- Create: `scenes/chapter_one/tutorial/bau.gd`, `scenes/chapter_one/tutorial/Bau.tscn` (instance of `scenes/main/Interact.tscn` + `AnimatedSprite2D` closed/open)
- Create: `scenes/chapter_one/tutorial/portao_temporizado.gd`, `scenes/chapter_one/tutorial/PortaoTemporizado.tscn` (Interact + lever sprite + `Portao` StaticBody2D with sprite/shape + `Passagem` Area2D just past the gate + `Ocupado` Area2D covering the gate opening)
- Test: `tests/tutorial/test_sala.gd`

**Interfaces:**
- Produces player speed: `const VELOCIDADE := 3600.0`, `const FATOR_CORRIDA := 1.75`; speed = `VELOCIDADE * (FATOR_CORRIDA if Input.is_action_pressed("run") else 1.0)`; walk animation `speed_scale` = the same factor. Fix the stale "shift" comment.
- Produces `bau.gd` (`extends "res://scenes/main/scripts/interact.gd"`): `signal aberto`, `var foi_aberto := false`, `func interaction()`: first time only → `Inventory.mochila.adicionar(POCAO, 1)`, open frame, `Textbox.queue_text(["Você encontrou uma Poção!"])`, emit `aberto`. Later → `Textbox.queue_text(["O baú está vazio."])`.
- Produces `portao_temporizado.gd`: `signal atravessou`, `@export var tempo_aberto := 0.8` (seconds; tune per the rule below), `func interaction()`: if closed and not passed → open (collision disabled, open frame, lever down), start timer; if already open → no-op. On timeout: close, unless a body in group `Player` overlaps `Ocupado`, in which case close as soon as it leaves. `Passagem` entered by the player → `atravessou` once, gate stays open for good.
- Tuning rule: lever-to-gate distance `d` ≈ 4000 px; walk time `d/3600` ≈ 1.1 s; `tempo_aberto` must be < walk time and ≥ 1.25 × run time (`d/6300` ≈ 0.63 s → ≥ 0.8 s). Start at 0.9 s and adjust after the play-through.

- [ ] **Step 1: Failing test** `test_sala.gd`:
  - `bau_uma_vez`: instance `Bau.tscn`, `interaction()` twice → backpack Poção quantity `1`, `aberto` emitted once. (Close the textbox between calls or stub `Textbox` calls by checking state only.)
  - `alavanca_aberta`: instance `PortaoTemporizado.tscn` with `tempo_aberto = 0.2`; `interaction()` → `check("aberto", shape.disabled)`; `interaction()` again at 0.1 s → timer not restarted (`timer.time_left < 0.15`); after 0.3 s → `check("fechou", not shape.disabled)`.
  - `fecha_ocupado`: put a `CharacterBody2D` in group `Player` inside `Ocupado`, open, wait 0.3 s → still open; move it out, wait 2 physics frames → closed.
- [ ] **Step 2: Run, verify fail.**
- [ ] **Step 3: Implement.** Placeholder art is fine (chest: any box sprite or a `ColorRect`; gate: reuse `ParedeRetratiuUp/Down.png` frames like the existing walls).
- [ ] **Step 4: Run** `test_sala.gd`. Expected pass.
- [ ] **Step 5: Commit** → `feat(tutorial): correr, baú e portão temporizado`

### Task 6: New tile-based test chamber and wiring

**Files:**
- Create: `assets/tileset/tutorial/sala_testes_placeholder.png` (generated, see below), `scenes/chapter_one/tutorial/tileset_sala.tres`
- Create: `scenes/chapter_one/tutorial/ParedeSala.tscn` + `parede_sala.gd` (room exit wall)
- Modify: `scenes/chapter_one/tutorial/Tutorial.tscn`, `scenes/chapter_one/tutorial/tutorial.gd`, `scenes/chapter_one/tutorial/lever.gd`
- Delete: `scenes/chapter_one/tutorial/glitch_effect.gd`, `sourcecode_portal.gd` (+ `.uid`), the `PortalShow`, `TextureRect` (painted background) and `MapBorder` nodes

**Interfaces:**
- Consumes: `ChecklistHud`, `Bau.tscn`/`aberto`, `PortaoTemporizado.tscn`/`atravessou`, `Battle.battle_won`, lever.
- Placeholder tileset: one PNG atlas of 500×500 tiles drawn by a throwaway Godot script (`Image` API) in the scratchpad: **paper floor** (`#f4f1ea` with faint pencil grain), **wall** (thick black ink border on paper, slightly wobbly), **hatched block** (diagonal black hatching inside an ink square), **wall face** (grey sketch shading, for the top wall row). Physics layer 0 collision on wall, wall face and block tiles. The owner replaces the PNG later with the same layout.
- `parede_sala.gd`: `extends StaticBody2D`, `func abrir() -> void` (slide/fade the sprite over 0.4 s, then disable the collision shape; idempotent). Sprite: reuse `assets/props/placeholder/ParedeRetratiuUp/Down.png`.
- Layout (spec §4, snake): Room 1 bottom-left (start; 3 hatched blocks forcing up/down/left/right), Room 2 above it, Room 3 a long hallway going right from Room 2's top (gate lever at its left end, gate at its right end; distance ≈ 4000 px per the Task 5 tuning rule), Room 4 top-right (dummy arena), Room 5 below Room 4 (exit room, "SAÍDA" door placeholder on its far wall). Exit walls: 1→2, 2→3, 4→5 are `ParedeSala`; 3→4 is the `PortaoTemporizado` gate. Player spawn in Room 1. Set the player's `Camera2D` limits to the level bounds.
- Wall drawings as sprites on the walls of their room: WASD arrows (existing `DesenhosParede` arrows, keep the light-up code) in Room 1; interact drawing in Room 2 (placeholder `Label` "ESPAÇO" until the owner's art); `Run`/`Run2` in Room 3 (+ a "SHIFT" placeholder label).
- `tutorial.gd`:
  - `_ready`: `PlayerState.set_on_interface(false)`, Turin HP to max, Player fades in over 0.8 s (sketched into place), add a `ChecklistHud`. Hide the HUD while `Battle.visible`.
  - `andar` = all four of up/down/left/right pressed at least once (tracked in the existing `_process` arrow code) → open wall 1→2.
  - `interagir` = lever pulled **and** chest opened, either order → open wall 2→3. `lever.gd` gets `signal puxada` and no longer opens a door itself.
  - `correr` on `atravessou`.
  - On `Battle.battle_won` → tick `lutar`, `usarItem`; open wall 4→5; start the glitch build-up (Task 7 step 1).
  - Room 5 `Area2D` in front of the "SAÍDA" door → `Rachadura.iniciar(hud, player)` (Task 7), once.

- [ ] **Step 1: Generate the placeholder atlas**, build `tileset_sala.tres` (tile size 500×500, physics layer with collision on wall/face/block tiles).
- [ ] **Step 2: Build the level** in `Tutorial.tscn` with `TileMapLayer`s (floor layer + walls/blocks layer) and place the nodes listed above; implement `parede_sala.gd` and the `tutorial.gd`/`lever.gd` wiring.
- [ ] **Step 3: Render check**: screenshot the whole level with a SubViewport render script (camera on the level center, zoom to fit) and confirm the 5 rooms, exits and props match the layout.
- [ ] **Step 4: Run the full suite** (`tests/run_all_tests.tscn` or each file). Expected 0 failures. Revert stray `project.godot` changes.
- [ ] **Step 5: Commit** → `feat(tutorial): sala de testes em tiles ligada ao checklist`

### Task 7: The crack and the fall

**Files:**
- Create: `scenes/chapter_one/tutorial/rachadura.gd` (`class_name Rachadura`, Node2D in Room 5, started by `tutorial.gd`)
- Create: `scenes/chapter_one/tutorial/Queda.tscn`, `scenes/chapter_one/tutorial/queda.gd`
- Modify: `scenes/chapter_one/deep_code/deep_code.gd` (first line)

**Interfaces:**
- Produces `rachadura.gd`: `func iniciar(hud: ChecklistHud, player) -> void` (async), the sequence from spec §5:
  1. Build-up (called by `tutorial.gd` on the win, separate `func agitar(hud) -> void`): every few seconds while the player walks to Room 5, `hud.piscar_aviso()` and a `DesenhosParede` flicker (modulate/offset jitter).
  2. `iniciar` (player reached the "SAÍDA" door): `PlayerState.set_on_scene(true)`. `hud.mensagem("Teste concluído. Acordando...")` typed, cut off at "Acord".
  3. Camera shake ~1 s; crack grows from the door to the player's feet (placeholder: jagged black `Line2D` whose points extend over 1.2 s); `hud.mostrar_erro()`.
  4. Player drops: tween scale to 0.6 + modulate to black + 300 px down over 0.6 s.
  5. `LevelWarp.change_level("res://scenes/chapter_one/tutorial/Queda.tscn")`.
- Produces `queda.gd`: black background, Turin sprite centered drifting slightly, ~30 `Label`s of code snippets (JetBrainsMono, the Task 3 colors at 40–70% alpha, lines like `public void andar(Direcao d) {`, `turin.cair();`, `0x00DEEP`) spawned below and scrolling up fast, 3 s total, then `PlayerState.set_on_scene(false)` and `LevelWarp.change_level("res://scenes/chapter_one/deep_code/DeepCode.tscn")`.
- `deep_code.gd` first `Textbox` line becomes `"Vejo que você caiu por aquela rachadura."`

- [ ] **Step 1: Implement.**
- [ ] **Step 2: Play from Room 4** (temporarily spawn the player there and win the fight, then walk to the door): the sequence plays without input, the fall scene shows, Deep Code loads and shows the new first line. No errors in the output.
- [ ] **Step 3: Commit** → `feat(tutorial): rachadura e queda para o Deep Code`

### Task 8: Full play-through

- [ ] **Step 1:** Run the project from the title screen. Check against the spec, in order: menu focus and disabled items, Opções opens and closes, music; boot log and wipe; each room ticks its item and opens its exit; Room 2 stays shut until both lever and chest are done; timed gate fails walking and passes running; the fight locks Atacar after the glitch hit and unlocks after the Poção; F2 does nothing in the fight; crack plays without input; fall; Deep Code opens.
- [ ] **Step 2:** Full test suite, 0 failures; `git status` shows only intended files; `project.godot` has only the main-scene and autoload change.
- [ ] **Step 3:** Commit any tuning (gate time, positions) → `chore(tutorial): ajustes do play-through`
