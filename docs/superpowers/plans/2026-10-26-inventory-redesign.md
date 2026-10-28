# Inventory Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the old dark-console inventory with a cream JRPG menu (summary, flip-card Status, Classe, Itens, Equipamento, Documentação, Opções) that shows real Java for every action and unlocks OOP concepts from the story.

**Architecture:** Pure logic first, UI last. New autoload `Progresso` holds unlocks. `Mochila` (a RefCounted owned by `Inventory`) holds items. `CodigoJava` (static, pure) turns game state and the current code stage into Java lines. Each screen is its own scene under `ui/inventory/telas/`. `inventory.gd` only opens/closes the menu and keeps a stack of screens.

**Tech Stack:** Godot 4.7.2, GDScript, headless SceneTree tests (`checar()` style), the battle UI's `HardShadowStyleBox` and fonts.

**Spec:** `docs/superpowers/specs/2026-10-26-inventory-redesign-design.md`

## Global Constraints

- Godot binary: `C:/Godot/Godot_v4.7.2-stable_win64_console.exe`. One test file: `"C:/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path C:/Godot/poo_game --script res://tests/inventario/<file>.gd`. Success line: `N testes passaram, 0 falharam`, exit 0.
- Full suite: `"C:/Godot/Godot_v4.7.2-stable_win64_console.exe" --headless --path C:/Godot/poo_game res://tests/run_all_tests.tscn`. Success line: `RESULT TOTAL <n> arquivos, 0 falharam`.
- Code, node names, comments and UI text in Portuguese, like the rest of the repo. Comments are short `##`/`#` lines in the existing style.
- Colours: cream `#FFF8E7`, ink `#1b1b1b`, yellow `#FFD23F`, code panel `#1e2230`. Fonts: `BattleFonts.display()` (ChakraPetch-Bold) for UI, `BattleFonts.mono()` (JetBrains Mono) for code.
- Every Java line shown is valid Java or a `//` comment.
- Locked concept names never appear in UI text. Show `???`.
- `Inventory` stays the autoload name. `Inventory.full_heal()` keeps working (`tatame_npc.gd`).
- The `%Velocidade` and `%AvancoAutomatico` unique names stay under `Inventory` (`test_opcoes_tab.gd`).
- Typing "e" in a `LineEdit`/`TextEdit` never opens the menu. The menu never opens during dialogue (`PlayerState.is_on_dialogue()`).
- Changing class never removes `atacar`/`usarItem` from battle.
- Currency name lives only in `Inventory.MOEDA := "bits"`.
- Commit after each task with the repo's message style (`Inventário: ...`) ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Stage only the task's files: the working tree has unrelated uncommitted changes.

## Review Focus

1. **Party of one.** Only Turin is in `Party` today. Every screen must render with one member (no empty second row, one Equipamento tab). Covered in Task 7 and Task 11 tests.
2. **Last unit used.** Using or discarding the last potion removes it from the grid and clears the selection. It must not leave a dead button or crash the next keypress. Covered in Task 10.
3. **Healing at full HP.** `pocao.usar(turin)` at full HP still spends the potion (as in RPG Maker), heals 0, and doesn't push HP over max. Covered in Task 2.
4. **Class change lowering max HP.** Switching to a class with a lower `HP_BONUS` clamps `hp` to the new max. HP must never stay above max. Covered in Task 3.
5. **Opening during a battle or a cutscene.** E and the corner icon must do nothing while `Battle` has the inventory disabled or `PlayerState.is_on_scene()`. Covered in Task 6.

---

### Task 1: `Progresso` autoload (unlocks)

**Files:**
- Create: `globals/progresso.gd`
- Modify: `project.godot` (`[autoload]`: add `Progresso="*res://globals/progresso.gd"` on the line **before** `Inventory=`)
- Modify: `tests/run_all_tests.gd` (also scan `res://tests/inventario`)
- Test: `tests/inventario/test_progresso.gd`

**Interfaces:**
- Produces:
  - `signal desbloqueado(id: String)`
  - `const CONCEITOS := ["classe", "objeto", "metodos", "encapsulamento", "abstracao", "polimorfismo", "heranca"]`
  - `const NOMES := {"classe": "Classe", "objeto": "Objeto", "metodos": "Métodos", "encapsulamento": "Encapsulamento", "abstracao": "Abstração", "polimorfismo": "Polimorfismo", "heranca": "Herança"}`
  - Other ids: `"inventario"`, `"basico"`, `"classes"`
  - `enum Estagio { OBJETO, METODOS, ENCAPSULAMENTO }`
  - `func tem(id: String) -> bool`
  - `func desbloquear(id: String) -> void` (no-op if already unlocked; otherwise marks it new and emits)
  - `func novo(id: String) -> bool` (unlocked and not seen yet)
  - `func marcar_visto(id: String) -> void`
  - `func algum_novo() -> bool`
  - `func estagio() -> Estagio` (ENCAPSULAMENTO if `encapsulamento`, else METODOS if `metodos`, else OBJETO)
  - `func desbloquear_tudo() -> void` (all ids)
  - `func resetar() -> void` (back to defaults)
- Defaults (spec, "Claude's calls"): `inventario`, `basico`, `classe` and `objeto` are unlocked and already seen. Everything else is locked.

- [ ] **Step 1: Write the failing test** `tests/inventario/test_progresso.gd`, using the same skeleton as `tests/dialogo/test_opcoes_tab.gd` (`checar`, two `process_frame` waits, `_fim`). Get `var p := root.get_node("Progresso")`. Checks:
  - `p.tem("inventario") and p.tem("basico") and p.tem("classe") and p.tem("objeto")`
  - `not p.tem("metodos") and not p.tem("classes")`
  - `not p.algum_novo()`
  - `p.estagio() == p.Estagio.OBJETO`
  - connect `desbloqueado` and count; `p.desbloquear("metodos")` twice, then the count is `1`, `p.novo("metodos")`, `p.algum_novo()`, `p.estagio() == p.Estagio.METODOS`
  - `p.marcar_visto("metodos")`, then `not p.novo("metodos")`
  - `p.desbloquear("encapsulamento")`, then `p.estagio() == p.Estagio.ENCAPSULAMENTO`
  - `p.desbloquear_tudo()`, then every id in `CONCEITOS` plus `"classes"` is `tem`
  - `p.resetar()`, then the defaults again and `not p.tem("metodos")`
- [ ] **Step 2: Run it.** Expected: fails (`Progresso` node is null).
- [ ] **Step 3: Implement** `globals/progresso.gd` (`extends Node`, `##` header line like `historia.gd`) using two Dictionaries `_tem` and `_visto`. Register the autoload and add the `tests/inventario` loop to `run_all_tests.gd` (copy the `tests/dialogo` loop).
- [ ] **Step 4: Run it.** Expected: `... 0 falharam`.
- [ ] **Step 5: Commit** `Inventário: Progresso guarda os conceitos desbloqueados`.

---

### Task 2: Items: `usar(alvo)`, key items, and `Mochila`

**Files:**
- Modify: `scenes/items/classes/item_class.gd`, `scenes/items/classes/health_item.gd`
- Modify: `scenes/items/repo/potion.tres` (becomes a `HEALTH_ITEM`, `HEALTH_RESTORE = 40`, `PRICE = 30`, placeholders), `scenes/items/repo/small_potion.tres` (script path → `res://scenes/items/classes/health_item.gd`, `ITEM_NAME = "Poção Pequena"`, `PRICE = 12`), `armadura_ferro.tres` / `armadura_couro.tres` (`PRICE = 120` / `60`)
- Create: `ui/inventory/mochila.gd`
- Modify: `scenes/battle/battle.gd` (drop `BACKPACK`; `context()` uses `Inventory.mochila.itens`; `run_command` uses `Inventory.mochila.gastar(t)`)
- Test: `tests/inventario/test_mochila.gd`

**Interfaces:**
- Produces on `ITEM`:
  - `@export var CHAVE: bool` (key item)
  - `func pode_usar() -> bool` (base `false`)
  - `func usar(alvo) -> int` (base: does nothing, returns `0`)
- Produces on `HEALTH_ITEM`:
  - `pode_usar()` → `true`
  - `usar(alvo)` → `alvo.apply_heal(HEALTH_RESTORE)`, returns the amount actually healed
- Produces `class_name Mochila extends RefCounted` in `ui/inventory/mochila.gd`:
  - `signal mudou`
  - `var itens: Array[ITEM]`
  - `func adicionar(item: ITEM, qtd: int = 1) -> void` (merges by `resource_path` when not empty, else by `ITEM_NAME`; when new, appends `item.duplicate()` with `QUANTITY = qtd`)
  - `func gastar(item: ITEM) -> void` (−1; removes at 0; emits `mudou`)
  - `func descartar(item: ITEM) -> bool` (`false` and no change if `item.CHAVE`; else `gastar`)
  - `func comuns() -> Array[ITEM]`, `func chave() -> Array[ITEM]`
  - `func de_slot(slots: Array) -> Array[EQUIP_ITEM]` (equipment whose `SLOT` is in `slots`)
- `battle.gd` consumes `Inventory.mochila` (the property is created in Task 6). Until then, add a temporary `var mochila := Mochila.new()` to the current `ui/inventory/scripts/inventory.gd` so battle keeps working. Delete `backpack.gd`'s use from battle only.

- [ ] **Step 1: Write the failing test** `test_mochila.gd`:
  - `var m := Mochila.new(); var pocao: ITEM = load("res://scenes/items/repo/potion.tres")`
  - `m.adicionar(pocao, 2); m.adicionar(pocao)`, then `m.itens.size() == 1 and m.itens[0].QUANTITY == 3`
  - `m.itens[0] != pocao` (the stored copy is a duplicate, so the `.tres` isn't mutated)
  - `pocao.pode_usar()` and `not load("res://scenes/items/repo/armadura_ferro.tres").pode_usar()`
  - heal on a stub: `var alvo = root.get_node("Party/Turin"); alvo.hp = alvo.get_max_hp() - 10`, then `m.itens[0].usar(alvo) == 10` and `alvo.hp == alvo.get_max_hp()`
  - full HP: `m.itens[0].usar(alvo) == 0` and `alvo.hp == alvo.get_max_hp()` (Review Focus 3)
  - `m.gastar(m.itens[0])` three times, then `m.itens.is_empty()`
  - key item: `var k := ITEM.new(); k.ITEM_NAME = "Chave"; k.CHAVE = true; m.adicionar(k)`, then `not m.descartar(m.itens[0])`, `m.chave().size() == 1`, `m.comuns().is_empty()`
  - `mudou` fires on `gastar` (count with a lambda)
- [ ] **Step 2: Run it.** Expected: fails (`Mochila` not found).
- [ ] **Step 3: Implement** the item methods, `mochila.gd`, the `.tres` edits and the `battle.gd` change.
- [ ] **Step 4: Run** `test_mochila.gd` and `tests/battle/test_battle_flow.gd` and `tests/battle/test_action_menu.gd`. Expected: all `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: itens com usar(alvo), itens-chave e Mochila`.

---

### Task 3: Classes: bonuses, `mudar_classe`, four job classes

**Files:**
- Modify: `rpg_classes/rpg_class.gd`, `scenes/party/scripts/character.gd`
- Modify: `rpg_classes/protector.tres` (move the `Proteger` skill from `SKILLS` to `HABILIDADES`, `JOGAVEL = true`, `HP_BONUS = 10`, `PP_BONUS = 0`, `COR = #c9a227`)
- Create: `rpg_classes/black_hat.tres`, `white_hat.tres`, `functioneer.tres`. Each has `SKILLS = [attack.tres, use_item.tres]`, `JOGAVEL = true`, and two display-only `HABILIDADES` (`SKILL` sub-resources without `SKILL_SCRIPT`). Placeholder data from the mock:

  | file | CLASS_NAME | HP/PP/ATK/DEF/VEL bonus | COR | HABILIDADES (SKLL_NAME, TARGET, DESCRIPTION) |
  |---|---|---|---|---|
  | black_hat | BlackHat | -4 / 0 / 4 / -2 / 6 | #3a3a3a | Invadir (ENEMY) "Entra no código do inimigo", Roubar (ENEMY) "Pega um item do inimigo" |
  | white_hat | WhiteHat | 0 / 8 / -3 / 0 / 0 | #f4f4f4 | Curar (ALLY) "Restaura o HP de um aliado", Depurar (ALLY) "Remove um erro de um aliado" |
  | protector | Protector | 10 / 0 / 4 / 6 / -2 | #c9a227 | Proteger (ALLY) "Protege as variáveis de um aliado", Provocar (ENEMY) "Atrai os ataques para si" |
  | functioneer | Functioneer | -6 / 12 / -4 / -4 / 2 | #6c4bd8 | Chamar Fogo (ENEMY) "Retorna fogo no inimigo", Retornar Raio (ENEMY) "Retorna um raio no inimigo" |
- Modify: `rpg_classes/commoner.tres` (`HABILIDADES = []`, `JOGAVEL = false`). This is the base class "Personagem".
- Modify: `scenes/party/scripts/battle_turin.gd` (`rpg_class = load("res://rpg_classes/commoner.tres")`; delete the `guigo` line and the `print`), `battle_kath.gd` (path → `res://rpg_classes/commoner.tres`)
- Test: `tests/inventario/test_classes.gd`

**Interfaces:**
- Produces on `RPG_CLASS`:
  - `@export var HP_BONUS: int`, `@export var PP_BONUS: int`
  - `@export var HABILIDADES: Array[SKILL]` (menu only, never read by battle)
  - `@export var JOGAVEL: bool`
  - `@export var COR: Color = Color.WHITE`
  - `static func jogaveis() -> Array[RPG_CLASS]`: every `.tres` in `res://rpg_classes/` from `ResourceLoader.list_directory` where `JOGAVEL`, sorted by `CLASS_NAME`
- Produces on character (`character.gd`):
  - `get_max_hp/get_max_pp/get_atk/get_def/get_vel` add the matching class bonus (rewrite `get_health_percentage` and `gain_health` to call `get_max_hp()` instead of repeating the loop)
  - `func mudar_classe(nova: RPG_CLASS) -> void` (sets `rpg_class` and clamps `hp`/`pp` to the new max; name, level, xp and equipment are untouched)
  - `func get_habilidades() -> Array[SKILL]` (`rpg_class.HABILIDADES`)
  - `@export var sprites_classe: Dictionary = {}` (CLASS_NAME → Texture2D)
  - `func get_retrato() -> Texture2D` (`sprites_classe.get(CLASS_NAME)` if present, else `get_pic()`)
  - `func get_cor_classe() -> Color` (white if a class sprite exists, else `rpg_class.COR`). Menus use it as the placeholder `modulate`.

- [ ] **Step 1: Write the failing test** `test_classes.gd` (`var t = root.get_node("Party/Turin")`):
  - `RPG_CLASS.jogaveis().map(func(c): return c.CLASS_NAME) == ["BlackHat", "Functioneer", "Protector", "WhiteHat"]`
  - `t.get_class_name() == "Personagem"`
  - `var atk0 = t.get_atk(); t.mudar_classe(load("res://rpg_classes/black_hat.tres"))`, then `t.get_atk() == atk0 + 4`, `t.get_nome() == "Turin"`, and the level is unchanged
  - every `jogaveis()` class's `SKILLS` mapped through `BattleContext.method_name` contains `"atacar"` and `"usarItem"` and nothing else
  - Protector: `get_habilidades()` names are `["Proteger", "Provocar"]`
  - Review Focus 4: `t.mudar_classe(protector); t.hp = t.get_max_hp(); t.mudar_classe(functioneer)`, then `t.hp == t.get_max_hp()`
  - equipment survives: `t.set_equip("body_slot", ferro)` before a change, `t.get_equip("body_slot") == ferro` after
  - end with `t.mudar_classe(load("res://rpg_classes/commoner.tres"))` and `t.set_equip("body_slot", null)` so other tests see the default
- [ ] **Step 2: Run it.** Expected: fails (`jogaveis` not found).
- [ ] **Step 3: Implement.** Create the `.tres` files in the editor format matching `protector.tres` (ext_resource for `skill.gd`, `attack.tres`, `use_item.tres`; sub_resources for the HABILIDADES).
- [ ] **Step 4: Run** `test_classes.gd` and all of `tests/battle/` (they call `get_skills()`). Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: quatro classes jogáveis e bônus de classe nos atributos`.

---

### Task 4: `CodigoJava`: every line the menu shows

**Files:**
- Create: `ui/inventory/codigo_java.gd`
- Test: `tests/inventario/test_codigo_java.gd`

**Interfaces:**
- Consumes: `Progresso.Estagio` (Task 1). Pass it as an `int` so the class stays pure.
- Produces `class_name CodigoJava extends RefCounted`, all `static`, all returning plain text (no BBCode) except `colorir`:
  - `nome_variavel(texto: String) -> String`: strips accents (á→a, ç→c, ã→a, ...), splits on spaces and `_`, then camelCase: `"Poção Pequena"` → `"pocaoPequena"`, `"Turin"` → `"turin"`, `"Armadura de Ferro"` → `"armaduraDeFerro"`.
  - `const SLOTS := {"head_slot": "cabeca", "body_slot": "corpo", "feet_slot": "pes", "lhand_slot": "maoE", "rhand_slot": "maoD", "acessory_slot": "acessorio"}`
  - `linha_usar(item: ITEM, alvo, estagio: int) -> Array[String]`
  - `linha_descartar(item: ITEM) -> String` → `"mochila.remove(pocao);"`
  - `linha_equipar(p, slot: String, item) -> String` → `"turin.corpo = armaduraDeFerro;"`, or `"turin.corpo = null;"` when `item == null`
  - `linha_classe(p, classe: RPG_CLASS) -> String` → `"turin = new BlackHat(turin);"`
  - `verso(p, estagio: int, metodos: bool) -> Array[String]`: the back of the card (see Step 1)
  - `colorir(linha: String) -> String`: BBCode with keywords (`new int void return null private`) `#ff9a4d`, types (a capitalised identifier) `#56c7e8`, strings `#9bd36a`, numbers `#ffd23f`, `//` comments `#7d8597`. A line starting with `"✗ "` renders as `[s]` grey without the `✗ ` prefix.

- [ ] **Step 1: Write the failing test** with exact strings (`Party/Turin` at the default class with `hp` set to 18, `pocao` = `potion.tres`):
  - `nome_variavel` cases above
  - `linha_usar(pocao, turin, OBJETO) == ["turin.hp = turin.hp + pocao.cura;"]`
  - `linha_usar(pocao, turin, METODOS) == ["pocao.usar(turin);"]`
  - `linha_usar(pocao, turin, ENCAPSULAMENTO) == ["✗ turin.hp = turin.hp + pocao.cura;  // hp é private", "pocao.usar(turin);"]`
  - `linha_descartar`, `linha_equipar` (both cases) and `linha_classe` as above
  - `verso(turin, OBJETO, false)` starts with `["Personagem turin = new Personagem(\"Turin\");", "turin.nome = \"Turin\";", "turin.hp = 18;"]`. It contains a line `"turin.atk = atkBase + classe.atk;  // " + str(turin.get_atk())`, which grows to `"... + classe.atk + corpo.atk;  // N"` when a body item with `ATTACK != 0` is equipped (terms only for slots whose item changes that stat). It ends with `"// ??? 🔒"` (locked names never shown). After a class change the second line is `"turin = new BlackHat(turin);"`; at ENCAPSULAMENTO hp/pp lines become `turin.setHp(N);` / `turin.setPp(N);`.
  - after `mudar_classe(black_hat)`: the second line is `"turin = new BlackHat(turin);"`
  - `verso(turin, METODOS, true)`: the atk line becomes `"int getAtk() { return atkBase + classe.atk; }  // N"`, and the last lines are one `"void invadir(Inimigo alvo) {}"` per HABILIDADE (method name via `BattleContext.method_name`, params via `SKILL.get_target_argument()` joined `", "` with ` alvo`)
  - `colorir("// x")` contains `#7d8597`; `colorir("✗ a;")` contains `[s]` and not `✗`
  - reset Turin's class and hp at the end
- [ ] **Step 2: Run it.** Expected: fails.
- [ ] **Step 3: Implement.** `colorir` is one `RegEx` pass over tokens. Order: comment, string, number, word.
- [ ] **Step 4: Run it.** Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: CodigoJava escreve o Java de cada ação`.

---

### Task 5: Inventory theme

**Files:**
- Modify: `scenes/battle/ui/hard_shadow_style_box.gd` (add `@export var square_top_left := false`; when true, top-left radius 0 on both the shadow and the panel)
- Create: `ui/inventory/tema_inventario.tres`
- Test: `tests/inventario/test_tema.gd`

**Interfaces:**
- Produces the theme `res://ui/inventory/tema_inventario.tres` (default font ChakraPetch-Bold, size 18, font colour ink) with these type variations:
  - `InvPainel` (PanelContainer: HardShadowStyleBox cream, border 4, shadow (5,5), radius 12)
  - `InvPainelAba` (the same with `square_top_left = true`)
  - `TabContainer` styles: `tab_selected` cream with no bottom border and the same border width as the panel; `tab_unselected` `#d9cfb8`; `panel` = the InvPainelAba box
  - `InvComando` (Button: transparent normal, yellow `hover`/`focus`, radius 7)
  - `InvChip` (Label in a PanelContainer: yellow, border 2, radius 20)
  - `InvChipBloqueado` (`#e9e1cf`, font colour `#6b6457`)
  - `InvCodigo` (PanelContainer `#1e2230`, radius 8) and `InvCodigoTexto` (RichTextLabel using the mono font, size 13, default colour `#e6e6e6`)
  - `InvBadge` (Panel: yellow circle, border 2)

- [ ] **Step 1: Write the failing test.** Load the theme. For each name above, `has_stylebox`/`get_type_variation_base` returns something. The `TabContainer` `panel` stylebox is a `HardShadowStyleBox` with `square_top_left`.
- [ ] **Step 2: Run it.** Expected: fails (file missing).
- [ ] **Step 3: Implement** the theme (`.tres` text or built in code with `ResourceSaver` once; commit the `.tres`) and the style box flag.
- [ ] **Step 4: Run** `test_tema.gd` and `tests/battle/test_theme.gd`. Expected: both `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: tema creme do menu`.

---

### Task 6: Menu shell: open/close, screen stack, corner icon, cleanup

**Files:**
- Rewrite: `ui/inventory/Inventory.tscn`, `ui/inventory/scripts/inventory.gd`
- Create: `ui/inventory/IconeMenu.tscn` and `ui/inventory/scripts/icone_menu.gd`
- Move: Opções into `ui/inventory/telas/Opcoes.tscn` (reusing `opcoes_tab.gd` and the existing nodes `%Velocidade` and `%AvancoAutomatico`; restyle with the theme). It is instanced inside `Inventory.tscn`, so the unique names still resolve from the `Inventory` owner. Set the instance's `editable children`, or make sure `get_node("%Velocidade")` works from the root, and confirm with the test.
- Modify: `project.godot` (new input action `menu` = joypad button 6 / Start)
- Modify: `scenes/chapter_one/deep_code/deep_code.gd:12` (remove the `set_player` call)
- Modify tests that read `inv.visible`: `tests/dialogo/test_iniciar.gd`, `tests/battle/test_battle_flow.gd`, `tests/test_integracao_java.gd` → `inv.esta_aberto()`
- Delete: `ui/inventory/scripts/{backpack,battle_inventory,char_info_tab,character_info,equipamento_tab,held_item_panel,item_button}.gd` (+ `.uid`), `ui/inventory/{item_container,info_box_container}.gd` (+ `.uid`), `ui/inventory/{CharacterInfoTab,CharContainer,ItemButton,ItemContainer}.tscn`, `ui/inventory/*.tmp`, the orphan `.uid`s (`battle_options`, `CharInfoTab`, `EquipamentoTab`, `held_item_panel`, `ItemButton`, `mochila`, `newinventory`, `PersonagemInfo` in `ui/inventory/`), `scenes/battle/ui/battle_inventory.gd` and `battle_inventory_close_button.gd` (+ `.uid`). Before deleting, `grep` for each file's name and `class_name`. Anything still referenced outside these files is kept and reported.
- Test: `tests/inventario/test_menu.gd`

**Interfaces:**
- Consumes: `Progresso` (Task 1), `Mochila` (Task 2), the theme (Task 5).
- Produces on `Inventory` (the root stays a `CanvasLayer`, `layer = 2`, always visible; the menu is the child `Menu` (Control, full rect, theme `tema_inventario.tres`), hidden when closed):
  - `const MOEDA := "bits"`
  - `var mochila := Mochila.new()`, `var dinheiro: int = 0`, `var tempo_jogo: float` (seconds, counts while the game isn't paused)
  - `signal mudou` (emit after any action that changes party or backpack state; also relay `mochila.mudou`)
  - `func esta_aberto() -> bool`
  - `func abrir() -> void` (no-op unless `pode_abrir()`; shows `Menu` with a 0.15 s tween, scale 0.96→1 and alpha 0→1; pushes the screen `"resumo"`; sets `PlayerState.set_on_interface(true)`)
  - `func fechar() -> void` (reverse tween, clears the stack, `set_on_interface(false)`)
  - `func pode_abrir() -> bool` (`Progresso.tem("inventario")`, not in dialogue, not `is_on_scene()`, `process_mode != PROCESS_MODE_DISABLED`)
  - `func ir(tela: String, personagem = null) -> void` (pushes a screen; screen names: `"resumo"`, `"status"`, `"classe"`, `"itens"`, `"equipamento"`, `"documentacao"`, `"opcoes"`)
  - `func voltar() -> void` (pops; closes when popping the last one)
  - `func tela_atual() -> Control`
  - Every screen scene's root script implements `func abrir_tela(personagem) -> void` (fills itself and grabs focus on its first control). `ir()` calls it. Until Tasks 7–12 exist, `ir()` uses a placeholder Control for missing scenes. Keep a `const TELAS := {name: path}` so later tasks only add entries.
  - `get_items()` → `mochila.itens` and `full_heal()` stay (callers exist)
  - `func clique() -> void` plays the kept `Audio_Click` node (`click7.mp3`). Every screen calls it on button presses.
  - Input stays polled in `_process` as today: `e` (keeping the existing focus check) or `menu` toggles (`abrir()` / `fechar()`). `Escape` or `ui_cancel` → `voltar()` while open. When `OS.is_debug_build()` and F10 is just pressed → `Progresso.desbloquear_tudo()`, plus `mochila.adicionar` of `potion.tres` ×6, `small_potion.tres` ×3, `armadura_ferro.tres`, `armadura_couro.tres`, plus `dinheiro += 1250`.
- Produces `IconeMenu` (a child of `Inventory`, outside `Menu`): a 56×56 `Button` in the top-right corner (16 px margin), cream HardShadowStyleBox, the existing icon `res://assets/gui/icons/classes.png`, and a child `Badge` (InvBadge). It is visible when `Progresso.tem("inventario")`, not in dialogue, not `is_on_scene()`, and the menu is closed. `Badge.visible = Progresso.algum_novo()`. Pressing it calls `Inventory.abrir()`.

- [ ] **Step 1: Write the failing test** `test_menu.gd`:
  - `inv.Menu` hidden and `not inv.esta_aberto()` at start
  - press `e` (`Input.action_press("e")`, two frames, release), then `esta_aberto()` and `inv.tela_atual().name` starts with `"Resumo"` (or is the placeholder named `"resumo"`)
  - `inv.ir("itens")` then `inv.voltar()`, then still open on resumo; `voltar()` again, then closed
  - `Progresso.resetar()` with `inventario` locked through a test hook (`Progresso._tem.erase("inventario")`), then `e` does nothing and `IconeMenu` is hidden; then `Progresso.resetar()`
  - `PlayerState.set_on_scene(true)`, then `e` does nothing and the icon is hidden; then `set_on_scene(false)` (Review Focus 5)
  - `inv.process_mode = PROCESS_MODE_DISABLED`, then `pode_abrir()` is false; restore
  - `Progresso.desbloquear("metodos")`, then `IconeMenu/Badge` is visible; `Progresso.marcar_visto("metodos")`, then it is hidden
  - pressing the icon (`icone.pressed.emit()`) opens the menu
  - `inv.get_node("%Velocidade") != null`
- [ ] **Step 2: Run it.** Expected: fails.
- [ ] **Step 3: Implement** the shell, the icon, the input action, the deletions and the three test updates.
- [ ] **Step 4: Run** `test_menu.gd`, then the full suite. Expected: `RESULT TOTAL ... 0 falharam`.
- [ ] **Step 5: Commit** `Inventário: novo menu, ícone no canto e limpeza do inventário antigo`.

---

### Task 7: Resumo (summary screen)

**Files:**
- Create: `ui/inventory/telas/Resumo.tscn`, `ui/inventory/telas/resumo.gd`, `ui/inventory/telas/trilha_conceitos.gd` (a reusable chip row, also used by Task 12)
- Modify: `inventory.gd` `TELAS`
- Test: `tests/inventario/test_resumo.gd`

**Interfaces:**
- Consumes: `Inventory.ir/mudou/dinheiro/tempo_jogo/MOEDA`, `Progresso`, character getters, `get_retrato()`/`get_cor_classe()` (Task 3).
- Produces:
  - `class_name TrilhaConceitos extends HFlowContainer` with `func atualizar() -> void`. It shows one chip per `Progresso.CONCEITOS`: unlocked → `InvChip` with `Progresso.NOMES[id]`; locked → `InvChipBloqueado` with `"???"`. Each chip's node name = the id.
  - Layout (spec "Summary"): left `InvPainel` with one row per `Party` child, then the trilha. Right `InvPainel` with `InvComando` buttons named `Itens`, `Status`, `Equipamento`, `Classe`, `Documentacao`, `Opcoes` (text "Documentação", "Opções"). Bottom right: `"%s %s" % [dinheiro, MOEDA]`, location, play time `"%02d:%02d" % [h, m]`.
  - A row shows `get_retrato()` modulated by `get_cor_classe()`, the name, a class tag, `"Nv %d"`, and HP and PP bars with `"%d/%d"`.
  - `Classe` is visible only when `Progresso.tem("classes")`. A `Badge` on `Classe` appears when `novo("classes")`. A `Badge` on `Documentacao` appears when any of `CONCEITOS` or `"basico"` is `novo`.
  - Status, Equipamento and Classe go into "choose a character" mode: focus moves to the first row, and pressing a row calls `Inventory.ir(<tela>, personagem)`. `ui_cancel` in that mode returns focus to the command instead of popping the screen. With one party member, skip the choice and go straight there.
  - Location: `get_tree().current_scene.get("nome_local")` if it's a String, else `current_scene.name`.
  - Refreshes on `abrir_tela` and on `Inventory.mudou`.

- [ ] **Step 1: Write the failing test:**
  - open → `Resumo` rows count `== Party.get_child_count()` (1 today, Review Focus 1)
  - a 2-member render: add a duplicate of `Party/Turin` named `Kath2` to `Party`, call `abrir_tela(null)`, check 2 rows, then remove and free it
  - the trilha with defaults: chip `classe` text `"Classe"`, chip `metodos` text `"???"`, and no chip text contains `"Métodos"`
  - `Classe` hidden; `Progresso.desbloquear("classes")` + `abrir_tela` → visible with its badge
  - money label contains `"bits"`
  - pressing `Itens` → `tela_atual()` is the itens screen (or its placeholder)
  - one member: pressing `Status` → the status screen for Turin
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `test_resumo.gd` and `test_menu.gd`. Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: tela de resumo no estilo JRPG`.

---

### Task 8: Status: the flip card

**Files:**
- Create: `ui/inventory/telas/Status.tscn`, `ui/inventory/telas/status.gd`
- Test: `tests/inventario/test_status.gd`

**Interfaces:**
- Consumes: `CodigoJava.verso/colorir` (Task 4), `Progresso.estagio()/tem("metodos")/tem("heranca")`, `Inventory.mudou`.
- Produces:
  - `%Carta` (Control, pivot centre) holds `%Frente` (InvPainel) and `%Verso` (InvCodigo with `%Codigo` RichTextLabel). Exactly **one** button `%Virar` ("{ }") sits outside both faces, anchored to the card's top-right corner.
  - `func virar() -> void`: tween `Carta.scale.x` 1→0 (0.25 s), swap which face is visible, then 0→1 (0.25 s). `var virada: bool`.
  - Front: portrait (`get_retrato()` × `get_cor_classe()`), name, class tag, `"Nível %d"`, HP/PP with numbers, Ataque/Defesa/Velocidade, "Habilidades" chips from `get_habilidades()`.
  - Back: `%Codigo.text` = `"\n".join(CodigoJava.verso(p, Progresso.estagio(), Progresso.tem("metodos")).map(CodigoJava.colorir))`. While `not Progresso.tem("heranca")`, the word `Personagem` on the first line is wrapped grey (`#7d8597`).
  - Both faces refresh on `Inventory.mudou` even while hidden (the back is "always live").
  - `ui_accept` on `%Virar` flips. The Y/triangle face button is not mapped (YAGNI).

- [ ] **Step 1: Write the failing test:**
  - `inv.ir("status", turin)`, then `%Frente.visible and not %Verso.visible`
  - only one Button in the screen whose text is `"{ }"`
  - `virar()`, wait 0.6 s (`await create_timer(0.6).timeout`), then `%Verso.visible and not %Frente.visible`
  - the back's text (`%Codigo.get_parsed_text()`) contains `"turin.hp = %d;" % turin.hp`
  - unflip; `turin.hp -= 1; inv.mudou.emit()`, then the hidden back's parsed text has the new hp (live while hidden)
  - `turin.mudar_classe(black_hat); inv.mudou.emit()`, then the parsed text contains `"turin = new BlackHat(turin);"`; restore the class
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: carta de status que vira para o código`.

---

### Task 9: Classe screen

**Files:**
- Create: `ui/inventory/telas/Classe.tscn`, `ui/inventory/telas/classe.gd`
- Test: `tests/inventario/test_classe_tela.gd`

**Interfaces:**
- Consumes: `RPG_CLASS.jogaveis()`, `character.mudar_classe`, `CodigoJava.linha_classe/colorir`, `Progresso.marcar_visto("classes")`, `Inventory.mudou`.
- Produces:
  - Left: the character's front card (reuse the Status screen's `%Frente` building code as a static helper `status.gd: static func preencher_frente(frente: Control, p) -> void`; refactor Task 8 to use it).
  - Right: one `InvComando` per class, named by `CLASS_NAME`, with the description = the first HABILIDADE's text. The current class is highlighted.
  - `%Linha` (InvCodigo) shows the last change line.
  - `func escolher(c: RPG_CLASS) -> void`: `p.mudar_classe(c)`, `%Linha` = `colorir(linha_classe(p, c))`, `Inventory.mudou.emit()`, click sound.
  - `abrir_tela` calls `Progresso.marcar_visto("classes")`.

- [ ] **Step 1: Write the failing test:** `Progresso.desbloquear("classes")`, `inv.ir("classe", turin)`, then 4 class buttons and `not Progresso.novo("classes")`. Pressing `BlackHat`, then `turin.get_class_name() == "BlackHat"` and `%Linha.get_parsed_text() == "turin = new BlackHat(turin);"`. Restore the class.
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** this test and `test_status.gd`. Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: troca de classe`.

---

### Task 10: Itens screen

**Files:**
- Create: `ui/inventory/telas/Itens.tscn`, `ui/inventory/telas/itens.gd`
- Test: `tests/inventario/test_itens.gd`

**Interfaces:**
- Consumes: `Inventory.mochila/MOEDA/mudou`, `ITEM.pode_usar/usar/CHAVE/PRICE`, `CodigoJava.linha_usar/linha_descartar/colorir`, `Progresso.estagio()`.
- Produces:
  - A `TabContainer` `%Abas` with tabs `Itens` and `Itens-chave` (theme from Task 5, so the selected tab joins the panel).
  - The grid `%Grade` holds one `Button` per item (icon, name, `"x%d"`), named `ITEM_NAME`.
  - On focus or hover: `%Nome`, `%Descricao`, and `%Valor` = `"Vale %d %s" % [PRICE, MOEDA]`, or `"Item-chave: não pode ser descartado."` for a key item.
  - `%Usar` is visible only if `pode_usar()`. `%Descartar` is disabled when `CHAVE`.
  - `%Alvos` holds one button per party member with `"%d/%d"` HP and a bar.
  - `func usar_em(item: ITEM, alvo) -> void`: `item.usar(alvo)`, `mochila.gastar(item)`, `%Linha` types `"\n".join(linha_usar(item, alvo, Progresso.estagio()))`. Typing is a tween of `visible_ratio` over 0.02 s × chars. The target's bar tweens to the new value. Then `Inventory.mudou.emit()`.
  - `func descartar(item: ITEM) -> void`: `if mochila.descartar(item)`, `%Linha` = `colorir(linha_descartar(item))`.
  - After any change, rebuild the grid. If the selected item is gone, clear the selection and focus the first grid button, or the tab bar if empty (Review Focus 2).

- [ ] **Step 1: Write the failing test** (`inv.mochila.adicionar(potion, 1)`; `turin.hp = turin.get_max_hp() - 30`):
  - `inv.ir("itens")` → `%Grade` has a `Poção` button
  - `usar_em(item, turin)`, then `turin.hp == turin.get_max_hp() - 30 + 40` clamped (use `mini`), the grid is empty, no error, and `%Linha.get_parsed_text() == "turin.hp = turin.hp + pocao.cura;"` once typing ends (await 1 s)
  - with `Progresso.desbloquear("metodos")`, use another potion → `"pocao.usar(turin);"`
  - a key item: `%Descartar.disabled` and `%Valor.text` begins `"Item-chave"`
  - armor: `%Usar` hidden; `descartar(armor)` removes it and `%Linha` == `"mochila.remove(armaduraDeFerro);"`
  - `Progresso.resetar()` at the end
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: mochila com usar, descartar e itens-chave`.

---

### Task 11: Equipamento screen

**Files:**
- Create: `ui/inventory/telas/Equipamento.tscn`, `ui/inventory/telas/equipamento.gd`
- Test: `tests/inventario/test_equipamento.gd`

**Interfaces:**
- Consumes: `character.get_equip/set_equip` and the stat getters, `Mochila.de_slot/adicionar/gastar`, `EQUIP_ITEM.Slot`, `CodigoJava.linha_equipar/colorir`.
- Produces:
  - `%Abas` (TabContainer) with one tab per `Party` child, named by `get_nome()`. `abrir_tela(p)` selects `p`'s tab.
  - Slots column: `InvComando` buttons for `head_slot, body_slot, feet_slot, rhand_slot, lhand_slot, acessory_slot` with labels "Cabeça", "Corpo", "Pés", "Mão dir.", "Mão esq.", "Acessório", and a second line with the item name or `"vazio"`.
  - Allowed `EQUIP_ITEM.Slot`s per slot: head → [HEAD], body → [BODY], feet → [FEET], rhand → [HAND, TWO_HAND], lhand → [HAND], acessory → [ACESSORY].
  - Items column: `Mochila.de_slot(...)`, plus `Tirar` when the slot is filled.
  - Stats column: one Label per stat (`Ataque`, `Defesa`, `Velocidade`, and `HP máx.`/`PP máx.` only if the previewed or equipped item has a non-zero HP/PP bonus) showing `"%d"`. With a preview: `"%d → %d ▲%d"` (green `#2f9e4f`) or `▼` (red `#c9372c`).
  - `func previsao(p, slot: String, item) -> Dictionary` (`{"atk": [antes, depois], ...}`). Compute it by temporarily `set_equip` and reading the getters, then restoring.
  - `%Linha` shows `colorir(linha_equipar(p, CodigoJava.SLOTS[slot], item))` while previewing.
  - `func equipar(p, slot: String, item) -> void`: the old item (if any) goes to `mochila.adicionar(old)`; the new item `mochila.gastar(item)`, then `set_equip`. TWO_HAND in `rhand_slot` also empties `lhand_slot` back to the backpack. `item == null` means Tirar. Then `Inventory.mudou.emit()`.
  - No numbers bars, no full sum here (spec anti-goals).

- [ ] **Step 1: Write the failing test** (`inv.mochila.adicionar(ferro); inv.mochila.adicionar(couro)`):
  - one tab with one party member (Review Focus 1)
  - `previsao(turin, "body_slot", ferro)["def"] == [turin.get_def(), turin.get_def() + 5]`
  - `equipar(turin, "body_slot", couro)`, then the backpack no longer has couro; `equipar(turin, "body_slot", ferro)`, then couro is back in the backpack and `turin.get_equip("body_slot") == ferro` (or its duplicate: compare `ITEM_NAME`)
  - with ferro equipped (DEF 5), previewing couro (DEF 3): the Defesa label contains `"▼2"`
  - `%Linha` text while previewing `null` == `"turin.corpo = null;"`
  - clean up: `equipar(turin, "body_slot", null)` and empty the backpack
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: equipamento por personagem com prévia ▲▼`.

---

### Task 12: Documentação screen and pages

**Files:**
- Create: `ui/inventory/documentacao/pagina_doc.gd` (`class_name PaginaDoc extends Resource`)
- Create: pages `ui/inventory/documentacao/{bool,int,string,classe,objeto,metodos,encapsulamento,abstracao,polimorfismo,heranca}.tres`
- Create: `ui/inventory/telas/Documentacao.tscn`, `ui/inventory/telas/documentacao.gd`
- Test: `tests/inventario/test_documentacao.gd`

**Interfaces:**
- Produces `PaginaDoc`: `@export var REQUER: String` (a Progresso id: `"basico"` for bool/int/string, else the concept id), `@export var ORDEM: int`, `@export var TITULO: String`, `@export_multiline var TEXTO: String` (BBCode allowed), `@export_multiline var EXEMPLO: String` (Java).
- Page content (Claude drafts, the owner reviews):
  - `bool`, `int`, `string`, `classe` and `objeto` are full pages in Brazilian Portuguese, ≤ 120 words each, friendly tone, one short valid Java example using the game's world (Turin, poção, porta), no puzzle hints.
  - `metodos` through `heranca` are placeholders: TITULO = the concept name, TEXTO = `"Em breve."`, EXEMPLO = `""`.
- Screen: the left list has one button per page sorted by `ORDEM`. Locked pages (`not Progresso.tem(REQUER)`) show `"???"` and are disabled. The right side shows `%Titulo`, `%Texto` (RichTextLabel) and `%Exemplo` (InvCodigo, `colorir` per line). A `TrilhaConceitos` (Task 7) sits on top.
- First view of a new unlock: the chip for a concept where `Progresso.novo(id)` starts as `"???"` and changes to the name with a 0.3 s scale pop (1→1.15→1). Then `marcar_visto(id)`, and the same for `"basico"`.

- [ ] **Step 1: Write the failing test:**
  - 10 pages load from the folder
  - the defaults: `bool` and `classe` buttons are enabled; the `metodos` button text is `"???"` and disabled
  - `Progresso.desbloquear("metodos")`, `inv.ir("documentacao")`, then after 0.5 s the trilha's `metodos` chip text is `"Métodos"` and `not Progresso.novo("metodos")`
  - choosing `objeto` → `%Exemplo.get_parsed_text()` contains `"new"`
  - every `EXEMPLO` line is non-empty Java or a comment (`not line.strip_edges().is_empty()` for full pages)
  - `Progresso.resetar()`
- [ ] **Step 2: Run.** Expected: fails.
- [ ] **Step 3: Implement** the screen and write the pages.
- [ ] **Step 4: Run.** Expected: `0 falharam`.
- [ ] **Step 5: Commit** `Inventário: documentação dos conceitos`.

---

### Task 13: Controller pass and final verification

**Files:**
- Modify: whichever screen scripts need it
- Test: `tests/inventario/test_controle.gd`

**Interfaces:**
- Consumes: everything above.
- Produces: every screen is usable with `ui_up/ui_down/ui_left/ui_right/ui_accept/ui_cancel` alone. Each `abrir_tela` grabs focus on a control. Descriptions in Itens update on `focus_entered` as well as `mouse_entered`.

- [ ] **Step 1: Write the failing test:** open the menu with `e` and send `InputEventAction` for `ui_down`/`ui_accept`/`ui_cancel` (parse with `Input.parse_input_event`, as `test_battle_flow.gd` `key()` does). Check:
  - focus is never `null` after opening each screen
  - `ui_accept` on `Itens` opens the itens screen
  - `ui_cancel` returns to resumo
  - `ui_cancel` again closes the menu
  - in Itens, moving focus to an item updates `%Nome`
- [ ] **Step 2: Run.** Expected: fails where focus is missing.
- [ ] **Step 3: Fix the focus gaps.**
- [ ] **Step 4: Run the full suite.** Expected: `RESULT TOTAL <n> arquivos, 0 falharam`. Then launch the game (`mcp__godot__run_project` or the editor), press F10, and screenshot each screen to confirm the look matches the approved mocks (`.superpowers/brainstorm/89864-1793058774/content/`: `resumo.html`, `flip-class.html`, `mochila.html`, `equipamento-v2.html` without bars).
- [ ] **Step 5: Commit** `Inventário: navegação por controle em todas as telas`.
