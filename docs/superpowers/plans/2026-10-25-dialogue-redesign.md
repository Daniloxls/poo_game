# Dialogue Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the festival city's dialogue with Dialogue Manager `.dialogue` files shown in a new "portrait breaking out" dialogue box with text effects, portrait animations, a shared story state, player dialogue settings, rewritten text and two new choices.

**Architecture:** Dialogue Manager 4.1.0 (already in `addons/dialogue_manager/`, enabled, autoload `DialogueManager`) parses and runs the `.dialogue` files. We add our own balloon scene (`ui/dialogue/Balao.tscn`), a label subclass with custom BBCode effects, a portrait node that animates, and four small autoloads: `Historia` (story decisions), `Opcoes` (player settings), `Elenco` (character definitions) and `Dialogo` (starts a conversation, blocks the player, can be awaited). City NPCs pass themselves as extra game state, so a dialogue file reads and sets the NPC's own variables; the NPC's GDScript acts on them after `await Dialogo.iniciar(...)` returns.

**Tech Stack:** Godot 4.7.2 (GDScript, GL Compatibility), Dialogue Manager 4.1.0, headless `SceneTree` test scripts.

**Spec:** `docs/superpowers/specs/2026-10-25-dialogue-redesign-design.md`

## Global Constraints

- Never edit files under `addons/dialogue_manager/`.
- All dialogue text in Brazilian Portuguese. Code identifiers follow the project: Portuguese names (`dialogo`, `balao`, `retrato`).
- Panel style: fill `#fff8e7`, outline 4px `#1b1b1b`, corner radius ~10px, hard shadow offset ~5px `#1b1b1b` (no blur). Selected choice `#ffd23f`. Kath `#2ec4d6`, Grande Montanha `#e8463a`.
- Fonts: Chakra Petch Bold (`assets/fonts/ChakraPetch-Bold.ttf`) for text and names, JetBrains Mono (`BattleFonts.mono()`) for code. Never `CONSOLA.TTF`.
- Styling lives in `ui/dialogue/tema_dialogo.tres` (theme + styleboxes), not per-node overrides.
- No talking bob: the portrait never moves while text types unless a tag asks.
- The old `Textbox` keeps working for every scene outside the city; do not delete or change it.
- City starts with **0** tickets; every other city behavior stays as today (+10 per attraction, `>= 30` check for the sword, `res://scenes/encounters/muscleguy.tscn` battle, full heal on loss).
- Tests: headless `extends SceneTree` scripts using the project's `checar(titulo, ok, detalhe)` helper and printing `"%d testes passaram, %d falharam"`; exit code 1 on failure. New tests live in `tests/dialogo/`.
- Full suite: `C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --import` (once, after adding `.dialogue`/`.tres` files), then `... --headless --path . res://tests/run_all_tests.tscn` must end with `RESULT TOTAL N arquivos, 0 falharam`.
- Single test: `C:/Godot/Godot_v4.7.2-stable_win64_console.exe --headless --path . --script res://tests/dialogo/<arquivo>.gd`.
- Commit messages in Portuguese, prefixed `Diálogo: `, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **Interact pressed on the frame a conversation ends** must not restart the same NPC's conversation (the old box defers `set_on_dialogue(false)` for this reason). Pinned in Task 6.
2. **Opening the inventory (`e`) during a conversation** must do nothing; today `inventory.gd` opens on `e` regardless of state. Pinned in Task 6.
3. **Unknown speaker or missing expression** (`Fulano:` not in `Elenco`, `[#bravo]` with no such portrait) must fall back silently: neutral color, stripe, default portrait. Pinned in Tasks 2 and 5.
4. **Switching settings mid-game** (instant text, auto-advance on) must apply to the very next line, and auto-advance must never skip a choice. Pinned in Task 5.
5. **A long line** must wrap inside the box without overflowing the screen or hiding the ▼. Pinned in Task 5.

---

### Task 1: Story state, player settings and test wiring

**Files:**
- Create: `globals/historia.gd`, `globals/opcoes.gd`
- Modify: `project.godot` (`[autoload]`), `tests/run_all_tests.gd`
- Test: `tests/dialogo/test_estado.gd`

**Interfaces:**
- Produces:
  - Autoload `Historia` (`globals/historia.gd`, `extends Node`): `var tritomos: String = ""` (`"verdade"` | `"acreditou"`), `var montanha: String = ""` (`"respeito"` | `"mentor"`), `func resetar() -> void`.
  - Autoload `Opcoes` (`globals/opcoes.gd`, `extends Node`): `enum Velocidade { LENTA, NORMAL, RAPIDA, INSTANTANEA }`, `var velocidade_texto: Velocidade = Velocidade.NORMAL`, `var avanco_automatico: bool = false`, `func segundos_por_letra() -> float`, `func atraso_avanco(letras: int) -> float`.
  - `run_all_tests.gd` also runs every `res://tests/dialogo/test_*.gd`.

- [ ] **Step 1: Write the failing test** `tests/dialogo/test_estado.gd` (copy the `checar`/summary skeleton from `tests/test_integracao_java.gd`), checking via `root.get_node(...)`:
  - `Historia.tritomos == ""` and `Historia.montanha == ""`; after setting both and `resetar()`, both are `""` again.
  - `segundos_por_letra()` is `0.05`, `0.03`, `0.015`, `0.0` for LENTA, NORMAL, RAPIDA, INSTANTANEA.
  - `atraso_avanco(0) == 1.2` and `atraso_avanco(100)` is approx `4.7` (`1.2 + 0.035 * letras`).
  - `avanco_automatico` defaults to `false`.
- [ ] **Step 2: Run it.** Expected: FAIL (no `Historia` node).
- [ ] **Step 3: Implement** both scripts with the values above, register `Historia="*res://globals/historia.gd"` and `Opcoes="*res://globals/opcoes.gd"` after `DialogueManager` in `[autoload]`, and add the `tests/dialogo` loop to `run_all_tests.gd` next to the `tests/battle` loop.
- [ ] **Step 4: Run the test** (PASS) **and the full suite** (16 files, 0 failed).
- [ ] **Step 5: Commit** `Diálogo: estado da história e opções do jogador`.

### Task 2: Characters (`Personagem`, `Elenco`)

**Files:**
- Create: `ui/dialogue/personagem.gd`, `globals/elenco.gd`, `ui/dialogue/personagens/kath.tres`, `cmdzinho.tres`, `anti_poo.tres`, `misterioso.tres`, `grande_montanha.tres`
- Modify: `project.godot` (`[autoload]`)
- Test: `tests/dialogo/test_elenco.gd`

**Interfaces:**
- Produces:
  - `class_name Personagem extends Resource`: `@export var nome: String`, `@export var cor: Color`, `@export var retratos: Dictionary[String, Texture2D]`, `@export var expressao_padrao: String`, `func tem_retrato() -> bool`, `func retrato(expressao: String = "") -> Texture2D` (exact expression, else `expressao_padrao`, else `null`).
  - Autoload `Elenco` (`globals/elenco.gd`): `const PASTA := "res://ui/dialogue/personagens/"`, `const COR_PADRAO := Color("#8a8f98")`, `func buscar(nome: String) -> Personagem` — never `null`; unknown names get a fresh `Personagem` with that `nome`, `COR_PADRAO`, no portraits. Load the folder with `ResourceLoader.list_directory` (works in exported builds), keyed by `nome`.
  - Character `nome` values used by dialogue files: `Kath`, `Cmdzinho`, `Anti-POO`, `???`, `Grande Montanha`. Portraits: Kath `{"neutra": kath_neutra}` (default `neutra`); Cmdzinho `alegre, duvida, feliz, neutro, surpreso, vazio` (default `neutro`); Anti-POO `neutro, serio` (default `neutro`); `???` `{"neutro": silhueta}`; Grande Montanha none. Colors: Kath `#2ec4d6`, Grande Montanha `#e8463a`, others taken from their art.

- [ ] **Step 1: Write the failing test** `test_elenco.gd`:
  - `Elenco.buscar("Kath").cor == Color("#2ec4d6")` and `.tem_retrato()`.
  - `Elenco.buscar("Cmdzinho").retrato("surpreso").resource_path.ends_with("cmd_surpreso.png")`.
  - `Elenco.buscar("Cmdzinho").retrato("bravo")` returns the `neutro` texture (missing expression falls back).
  - `Elenco.buscar("Grande Montanha").tem_retrato() == false` and `.cor == Color("#e8463a")`.
  - `Elenco.buscar("Fulano")` is not null, `.nome == "Fulano"`, `.cor == Elenco.COR_PADRAO`, no portrait.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** the script, the autoload (`Elenco="*res://globals/elenco.gd"`) and the five `.tres` files.
- [ ] **Step 4: Run** `--import`, then the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: personagens e elenco`.

### Task 3: Text effects and the dialogue label

**Files:**
- Create: `ui/dialogue/bbcode.gd`, `ui/dialogue/rotulo_dialogo.gd`, `ui/dialogue/efeitos/efeito_pop.gd`, `efeito_sussurro.gd`, `efeito_glitch.gd`
- Test: `tests/dialogo/test_texto.gd`

**Interfaces:**
- Produces:
  - `class_name DialogoBBCode`: `static func intervalos(texto: String, tag: String) -> Array[Vector2i]` — `[inicio, fim)` ranges of *visible-character* indices inside `[tag]...[/tag]` (every BBCode tag counts as zero characters, tags with arguments like `[shake rate=20]` included); `static func expandir_code(texto: String) -> String` — turns `[code]x[/code]` into `[bgcolor=#1b1b1b][color=#ffd23f][code]x[/code][/color][/bgcolor]`.
  - `class_name RotuloDialogo extends DialogueLabel`: `const LENTIDAO_SUSSURRO := 0.5`; installs one instance each of `EfeitoPop`, `EfeitoSussurro`, `EfeitoGlitch` in `custom_effects`; overrides `_update_text()` (sets `text` to `DialogoBBCode.expandir_code(dialogue_line.text)` and caches the `whisper` ranges) and `_get_speed(at_index)` (multiplies by `LENTIDAO_SUSSURRO` inside a whisper range); records each revealed character's time (from `spoke`, and all at once on `skip_typing`) for the pop effect.
  - Tags available to writers: built-in `[shake]`, `[wave]`, plus `[pop]`, `[whisper]`, `[glitch]`, `[code]`.
  - `EfeitoPop` (`bbcode = "pop"`): colored `#e8463a`, scale 1.25; on reveal scales from ~1.6 down with an overshoot to 1.25 over ~0.25s. `EfeitoSussurro` (`"whisper"`): color `#8a8a8a`, scale 0.85, baseline kept. `EfeitoGlitch` (`"glitch"`): every ~2.4s, staggered per letter, ~0.1s of ±2px offset alternating `#e8463a` / `#2ec4d6`.

- [ ] **Step 1: Write the failing test** `test_texto.gd`:
  - `intervalos("ab[whisper]cd[/whisper]e", "whisper") == [Vector2i(2, 4)]`.
  - `intervalos("[b]x[/b][whisper]yz[/whisper][whisper]w[/whisper]", "whisper") == [Vector2i(1, 3), Vector2i(3, 4)]`.
  - `intervalos("[shake rate=20]a[/shake]b", "whisper") == []`.
  - `expandir_code("tem [code]métodos[/code]")` equals the exact expansion above.
  - A `RotuloDialogo` added to `root`, given a line from `DialogueManager.create_resource_from_text("~ a\nX: ab[whisper]cd[/whisper]\n=> END")`: `_get_speed(1) == 1.0`, `_get_speed(3) == 0.5`; its `custom_effects` contain the three effects; after `skip_typing()`, `visible_characters == get_total_character_count()`.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** the five scripts.
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: efeitos de texto e rótulo do diálogo`.

### Task 4: Animated portrait

**Files:**
- Create: `ui/dialogue/retrato.gd`, `ui/dialogue/Retrato.tscn`, `ui/dialogue/contorno.gdshader`
- Test: `tests/dialogo/test_retrato.gd`

**Interfaces:**
- Consumes: `Personagem` (Task 2).
- Produces: `class_name RetratoDialogo extends Control` (scene root of `Retrato.tscn`, children `%Imagem: TextureRect` with the outline shader and `TEXTURE_FILTER_LINEAR`, `%Flash: ColorRect` white, alpha 0):
  - `var personagem: Personagem` (current, or `null`), `var expressao: String`.
  - `func mostrar(p: Personagem, exp: String) -> void` — same character: behaves like `trocar_expressao(exp)`; different or none: slides the old one out (if any) and the new one in from the left (~0.25s).
  - `func esconder() -> void` — slides out (~0.2s), then `personagem = null`.
  - `func trocar_expressao(exp: String) -> void` — swaps `%Imagem.texture` to `personagem.retrato(exp)`; when the texture actually changes, plays a squash-and-stretch punch (~0.3s) and the flash (alpha 0.7 → 0 in ~0.25s).
  - `func animar(nome: String) -> void` — `"hop"` (jump ~0.45s with landing squash), `"shake"` (horizontal shake with slight rotation ~0.4s), `"slump"` (sinks, tilts, desaturates over ~0.5s and holds); any other name: `push_warning` and nothing else.
  - `func resetar_pose() -> void` — undoes a held slump (called at each new line).
  - `var em_animacao: bool` — true while any tween runs.
  - The rest position is wherever the parent places the node; animations always return to it.

- [ ] **Step 1: Write the failing test** `test_retrato.gd` (instantiate `Retrato.tscn` under a `Control` in `root`, record `position` as rest):
  - `mostrar(kath, "neutra")`, wait 0.4s: visible, `%Imagem.texture == kath.retrato("neutra")`, `position` equals rest.
  - with Cmdzinho: `trocar_expressao("surpreso")` changes the texture and sets `em_animacao`; after 0.5s `em_animacao == false` and `scale == Vector2.ONE`.
  - `animar("hop")` and `animar("shake")`: after 1s, `position` equals rest and `rotation == 0`.
  - `animar("slump")`: after 1s, `position.y > rest.y`; after `resetar_pose()` and 0.6s, back to rest.
  - `animar("inexistente")` leaves `position` and `scale` unchanged.
  - `esconder()`, wait 0.4s: `personagem == null`.
  - With no calls for 1s after `mostrar`, `position` never changes (no talking bob).
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** the scene, script and shader (alpha-based 4px `#1b1b1b` outline).
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: retrato animado`.

### Task 5: The dialogue box (balloon)

**Files:**
- Create: `ui/dialogue/Balao.tscn`, `ui/dialogue/balao.gd`, `ui/dialogue/tema_dialogo.tres`
- Test: `tests/dialogo/test_balao.gd`

**Interfaces:**
- Consumes: `Opcoes` (Task 1), `Elenco`/`Personagem` (Task 2), `RotuloDialogo` (Task 3), `RetratoDialogo` (Task 4), Dialogue Manager (`DialogueResource.get_next_dialogue_line(cue, states)`, `DialogueLine.character/.text/.responses/.next_id/.has_tag()/.tags`, `DialogueResponsesMenu`).
- Produces: `class_name BalaoDialogo extends CanvasLayer` (layer above the game and the old Textbox):
  - `func start(recurso: DialogueResource, cue: String = "", estados_extras: Array = []) -> void` — Dialogue Manager calls this; game states are `[self] + estados_extras`.
  - `func avancar() -> void` — typing: complete the line; finished line without choices: next line; with choices: nothing.
  - `func escolher(indice: int) -> void` — pick a visible choice.
  - `func expressao(nome: String) -> void` and `func animar(nome: String) -> void` — callable from inside a line as `[do expressao("surpreso")]` / `[do animar("hop")]` (mid-line changes).
  - Unique nodes for tests: `%Caixa` (Panel), `%NomeTag` (Label in a skewed colored panel), `%Faixa` (ColorRect stripe on the box's left edge), `%Retrato` (RetratoDialogo), `%Texto` (RotuloDialogo, autowrap), `%Indicador` (▼ label), `%Escolhas` (DialogueResponsesMenu with one button template).
  - Per line: `p := Elenco.buscar(line.character)`. Name tag shows `p.nome` on `p.cor`. If `p.tem_retrato()`: `%Retrato.mostrar(p, <first line tag that is a key of p.retratos, else p.expressao_padrao>)`, `%Faixa` hidden, text starts right of the bust. Else: `%Retrato.esconder()`, `%Faixa` visible with `p.cor`, text uses the full width. Call `%Retrato.resetar_pose()`, then `animar()` for each of `hop`, `shake`, `slump` present as a tag.
  - Typing uses `%Texto.seconds_per_step = Opcoes.segundos_por_letra()`, read at the start of every line.
  - After typing: choices → show `%Escolhas`, focus the first; else if `Opcoes.avanco_automatico` → wait `Opcoes.atraso_avanco(<parsed text length>)` then go on (an earlier `avancar()` wins); else show `%Indicador`.
  - Input (in `_unhandled_input`, marking all input handled while visible): `interact` or `ui_accept` → `avancar()` (or confirm the focused choice); left click on `%Caixa` → `avancar()`; `up`/`down` move focus between choices in addition to `ui_up`/`ui_down`.
  - End of conversation (`null` line): `%Retrato.esconder()`, then `queue_free()`.
  - Layout at the default 1152×648 viewport: box anchored bottom, 16px side and bottom margins, ~190px tall; bust ~430px tall, bottom-left, overlapping the box's top edge and drawn in front; name tag on the box's top edge; choices stacked above the box on the right. Selected choice: `#ffd23f`, rotated ~-1.5°, scale ~1.06, prefixed `▶ `. Uses `tema_dialogo.tres`.

- [ ] **Step 1: Write the failing test** `test_balao.gd`. Start balloons with `DialogueManager.show_dialogue_balloon_scene("res://ui/dialogue/Balao.tscn", DialogueManager.create_resource_from_text(<texto>), "", [ctx])`, where `ctx` is a test `Node` with `var escolha := ""`. Check:
  - `Kath: Oi!` → `%NomeTag.text == "Kath"`, tag color `#2ec4d6`, `%Retrato.personagem.nome == "Kath"`, `%Faixa` hidden.
  - `Grande Montanha: Hah!` → `%Faixa` visible with `#e8463a`, no portrait.
  - `Fulano: oi` → no crash, `%Faixa` visible with `Elenco.COR_PADRAO`.
  - `Cmdzinho: [#surpreso] Uau` → portrait texture is `cmd_surpreso`; `Cmdzinho: [#bravo] hm` → default `neutro`.
  - Two lines: the first `avancar()` completes typing (`%Texto.visible_characters == total`) and shows `%Indicador`; the second loads line two.
  - A line followed by `- A\n\tset escolha = "a"\n- B\n\tset escolha = "b"`: after typing, `%Escolhas` visible; `escolher(1)` ends with `ctx.escolha == "b"`; `avancar()` while choices are shown does nothing.
  - `Opcoes.velocidade_texto = INSTANTANEA` → one frame after the line starts, the text is fully visible.
  - `Opcoes.avanco_automatico = true` with a two-line conversation → line two appears with no `avancar()` after `atraso_avanco` + 0.2s; with a choice line, the choices stay open after 3s.
  - A 400-character line: `%Texto` stays inside `%Caixa`'s rect, and `%Indicador` is inside the viewport.
  - `Kath: Oi [do animar("hop")]tudo bem?` → `%Retrato.em_animacao` becomes true during typing.
  - After the last line + `avancar()`, the balloon is freed and `DialogueManager.dialogue_ended` fired.
  Reset `Opcoes` between cases.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** the theme (cream box stylebox with 4px outline, radius 10, hard 5px shadow; choice normal/focus styleboxes; Chakra Petch default font ~22px; JetBrains Mono as `mono_font`), the scene and the script.
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: nova caixa de diálogo`.

### Task 6: Starting conversations and blocking the player

**Files:**
- Create: `globals/dialogo.gd`
- Modify: `project.godot` (`[autoload]`), `entities/player/player_script.gd:108-112`, `entities/npc/npc_script.gd`, `ui/inventory/scripts/inventory.gd` (`process_input`)
- Test: `tests/dialogo/test_iniciar.gd`

**Interfaces:**
- Consumes: `BalaoDialogo` (Task 5).
- Produces:
  - Autoload `Dialogo` (`globals/dialogo.gd`): `const BALAO := "res://ui/dialogue/Balao.tscn"`, `var ativo: bool`, `func pode_iniciar() -> bool` (not `ativo`, not `PlayerState.is_on_dialogue()`, `Textbox.get_state() == "Ready"`), `func iniciar(recurso: DialogueResource, cue: String = "", contexto: Array = []) -> void` — returns immediately if `not pode_iniciar()`; otherwise sets `ativo` and `PlayerState.set_on_dialogue(true)`, shows `BALAO` via `DialogueManager.show_dialogue_balloon_scene`, awaits `DialogueManager.dialogue_ended` for that resource, waits one more `process_frame`, then clears both. Callers `await` it.
  - `npc_script.gd`: `@export var dialogo: DialogueResource` and `@export var cue_dialogo: String = ""`; `interaction()` runs `Dialogo.iniciar(dialogo, cue_dialogo, [self])` when `dialogo` is set, else the old `Textbox.queue_text(texto)`.
  - Convention for every city dialogue: the NPC passes itself as context; the dialogue file reads/sets the NPC's variables and calls its small helper methods; the NPC's GDScript acts on them after the `await`.
  - Player interaction also requires `not Dialogo.ativo`; inventory `process_input` returns early while `PlayerState.is_on_dialogue()`.

- [ ] **Step 1: Write the failing test** `test_iniciar.gd`:
  - During `Dialogo.iniciar(<2-line resource>)`: `Dialogo.ativo` and `PlayerState.is_on_dialogue()` are true; a second `iniciar` call creates no second balloon.
  - After finishing the lines, the awaited call returns, and `ativo` and `on_dialogue` are false only after the extra frame (check they are still true in the same frame `dialogue_ended` fires).
  - An `npc_script` node with `dialogo` set: `interaction()` opens the new balloon; with `dialogo` unset, it queues on the old `Textbox` (its state leaves `"Ready"`).
  - With a conversation open, `Input.action_press("e")` + one frame does not show the inventory.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** `globals/dialogo.gd`, the autoload `Dialogo="*res://globals/dialogo.gd"`, and the three modifications.
- [ ] **Step 4: Run** the test (PASS) and the full suite (`test_integracao_java.gd` instantiates `City.tscn` and must still pass).
- [ ] **Step 5: Commit** `Diálogo: iniciar conversas e travar o jogador`.

### Task 7: Dialogue settings in the inventory's Opções tab

**Files:**
- Create: `ui/inventory/scripts/opcoes_tab.gd`
- Modify: `ui/inventory/Inventory.tscn` (node `TabContainer/Opções`)
- Test: `tests/dialogo/test_opcoes_tab.gd`

**Interfaces:**
- Consumes: `Opcoes` (Task 1).
- Produces: `Opções` gets a `VBoxContainer` with a `Label` "Velocidade do texto" + `%Velocidade: OptionButton` (items, in order: "Lenta", "Normal", "Rápida", "Instantânea", ids matching `Opcoes.Velocidade`) and `%AvancoAutomatico: CheckButton` "Avançar automaticamente". `opcoes_tab.gd` (on the `Opções` node) syncs from `Opcoes` in `_ready` and writes `Opcoes` on `item_selected` / `toggled`.

- [ ] **Step 1: Write the failing test** `test_opcoes_tab.gd` (use the `Inventory` autoload): `%Velocidade.selected == Opcoes.Velocidade.NORMAL` at start; selecting index 3 and emitting `item_selected(3)` sets `Opcoes.velocidade_texto == INSTANTANEA`; toggling `%AvancoAutomatico` sets `Opcoes.avanco_automatico == true`.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement** the nodes and script.
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: opções de texto no inventário`.

### Task 8: The city's rewritten dialogue files

**Files:**
- Create in `scenes/chapter_one/festival_city/dialogos/`: `excalibur.dialogue`, `tatame.dialogue`, `teste_forca.dialogue`, `tritomos.dialogue`, `espada.dialogue`, `cidade.dialogue`; plus one `ui/dialogue/personagens/*.tres` per newly named city speaker (name and color only)
- Test: `tests/dialogo/test_textos_cidade.gd`

**Interfaces:**
- Consumes: the tags from Task 3 and 5, `Historia` (Task 1), the context convention (Task 6).
- Produces — cues, and the context members each file uses (the NPC scripts in Tasks 9–12 must provide exactly these):
  - `excalibur.dialogue`: `~ conversa` (reads `tickets_atuais() -> int`; sets `var vai_seguir: bool`; after the sword: reads `var espada_tirada: bool`).
  - `tatame.dialogue`: `~ desafio` (sets `var quer_lutar: bool`), `~ vitoria` (ends with Turin's choice: `"Foi uma luta incrível!"` → `set Historia.montanha = "respeito"`, `"Me ensina a lutar assim?"` → `set Historia.montanha = "mentor"`, then the Montanha replies), `~ derrota`, `~ descansando`, `~ montanha` (the Grande Montanha's own lines: before the fight / after, branching on `Historia.montanha`).
  - `teste_forca.dialogue`: `~ convite` (sets `var quer_tentar: bool`), `~ ganhou`, `~ perdeu`, `~ dica` (Cmdzinho with portrait expressions; branches on `var erros: int` 1–3 for the three hints), `~ ja_ganhou`.
  - `tritomos.dialogue`: `~ boas_vindas`, `~ acertou` and `~ errou` (use `{{palavra}}` from `var palavra: String`), and `~ errou` ends with Turin's choice: tell the truth → `set Historia.tritomos = "verdade"`, let him believe → `set Historia.tritomos = "acreditou"`, each with its own Tritomos reply.
  - `espada.dialogue`: `~ cena_1` … `~ cena_7`, one per old `dialogue[i]` block in `sword_cutscene.gd`, same order; Anti-POO speaks as `???` until the cutscene's script reveals him; Kath speaks with her portrait.
  - `cidade.dialogue`: `~ cmdzinho`, `~ kath`, `~ tenda`, `~ npc1`, `~ npc2`, `~ npc3`, `~ trocador`.
  - Every speaker named; spelling fixed (spec list); voice per the spec's approved sample; emotion tags only where they serve the moment; same story beats.

- [ ] **Step 1: Write the failing test** `test_textos_cidade.gd`: for each of the six files, `DMCompiler.compile_string(FileAccess.get_file_as_string(path), path).errors.is_empty()`, and the file has every cue listed above (`result.cues.has(...)`). Then run a few branches with `DialogueManager.get_next_dialogue_line(recurso, cue, [stub])` (a stub `Node` with the members above), following `next_id` and, for responses, the chosen response's `next_id`:
  - `excalibur` with `tickets_atuais() == 0` → `vai_seguir == false`; with `30` and "yes" chosen → `vai_seguir == true`.
  - `tatame/vitoria` choosing the second response → `Historia.montanha == "mentor"`.
  - `tritomos/errou` choosing the first response → `Historia.tritomos == "verdade"`.
  - No line in any file contains `" ?"`, `"advinh"`, `"trás lembr"`, `"Enquanto a você"`, `"premios"`.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Write the six files** (rewrite from the strings in today's scripts and `City.tscn` `texto` properties) and the new character `.tres` files.
- [ ] **Step 4: Run** `--import`, the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: falas reescritas da cidade`.
- [ ] **Step 6: Stop for the owner to read the six files.** Apply their changes and re-run the test before Task 9.

### Task 9: Simple city NPCs, ticket trader and starting tickets

**Files:**
- Modify: `scenes/chapter_one/festival_city/City.tscn` (`TendaNPC`, `LutadorNPC`, `NPC1`, `Kath`, `NPC2`, `NPC3`, `Cmdzinho`: set `dialogo`/`cue_dialogo`, clear `texto`), `scripts/cmdzinho.gd` (delete its `interaction()` override), `scripts/ticket_trader.gd`, `scripts/tickets.gd`
- Test: `tests/dialogo/test_cidade.gd`

**Interfaces:**
- Consumes: `npc_script.gd` exports (Task 6), `cidade.dialogue` and `tatame.dialogue` cues (Task 8).
- Produces: `tickets.gd` starts at `var tickets: int = 0`; `ticket_trader.gd` drops `textbox`/`codebox` lookups and calls `Dialogo.iniciar(<cidade.dialogue>, "trocador", [self])`; `LutadorNPC` uses `tatame.dialogue` `~ montanha`.

- [ ] **Step 1: Write the failing test** `test_cidade.gd` (instantiate `City.tscn` as in `test_integracao_java.gd`): the city's `Tickets` node (`cidade.find_child("Tickets")`) has `get_tickets() == 0`; for each of `NPC1`, `NPC2`, `NPC3`, `Kath`, `TendaNPC`, `Cmdzinho`, `LutadorNPC` and the ticket trader, `interaction()` opens a balloon (`Dialogo.ativo`), whose first `%NomeTag.text` is not empty; then advance it to the end (`avancar()` until freed) before the next.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: NPCs simples da cidade no novo sistema`.

### Task 10: Excalibur NPC and the tatame (Grande Montanha choice)

**Files:**
- Modify: `scenes/chapter_one/festival_city/scripts/excalibur_npc.gd`, `scripts/tatame_npc.gd`
- Test: `tests/dialogo/test_cidade.gd` (extend)

**Interfaces:**
- Consumes: `excalibur.dialogue`, `tatame.dialogue` members (Task 8), `Dialogo.iniciar` (Task 6).
- Produces: both scripts lose every `Textbox.connect`, `triggered`/`scene`/`start_battle` flag and `_on_textbox_*` handler. `excalibur_npc.gd`: `func tickets_atuais() -> int`, `var vai_seguir`, `var espada_tirada`; `interaction()` awaits `conversa`, and if `vai_seguir` hides the ticket counter and plays the sword cutscene (`sword_scene.play()`), then sets `espada_tirada = true`. `tatame_npc.gd`: `var quer_lutar`; `interaction()` awaits `desafio` (or `descansando` after a win) and starts `res://scenes/encounters/muscleguy.tscn` if `quer_lutar`; `_on_city_battle_won` gives 10 tickets and awaits `vitoria`; `_on_city_battle_lost` full-heals and awaits `derrota`.

- [ ] **Step 1: Extend the test:** Excalibur with 0 tickets and "yes" → cutscene not started; with 30 → `sword_scene.play` called (stub `sword_scene` with a counter); tatame "yes" → `Battle.start_battle` called with the muscleguy path (stub `battle`); `_on_city_battle_won()` then choosing "Me ensina a lutar assim?" → `Historia.montanha == "mentor"` and tickets +10; `_on_city_battle_lost()` → party fully healed.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: Excalibur e tatame no novo sistema`.

### Task 11: Strength test (with Cmdzinho's hints) and Tritomos

**Files:**
- Modify: `scenes/chapter_one/festival_city/scripts/strenght_test_npc.gd`, `scripts/medium_tent.gd`
- Test: `tests/dialogo/test_cidade.gd` (extend)

**Interfaces:**
- Consumes: `teste_forca.dialogue`, `tritomos.dialogue` members (Task 8).
- Produces: `strenght_test_npc.gd` keeps its walk/hammer tween sequence and `teste.testar(4)` but replaces `triggered`/`scene`/`animation_end` and the Textbox handlers with awaits: `convite` → (if `quer_tentar`) the sequence → `ganhou` (+10 tickets) or `perdeu` then `dica` with `erros` 1, 2, 3 (capped at 3; replaces the broken `cmdzinho.textbox` call) → walk back; `ja_ganhou` after a win. `medium_tent.gd` keeps the code puzzle and interface; intro text → `boas_vindas`; result → `acertou`/`errou` with `palavra` set; after `errou` (Turin's choice inside it), +10 tickets and Tritomos leaves (`vidente_left.png`, `LeftLabel`) as today in both branches.

- [ ] **Step 1: Extend the test:** strength test "yes" with the original code → `perdeu` then a Cmdzinho line with a portrait; three more failures cap `erros` at 3; with the passing code (`testar` returns true, as in `test_integracao_java.gd`) → +10 tickets and `ja_ganhou` on the next interaction. Tritomos: beaten with `correct_answer` → after choosing the truth, `Historia.tritomos == "verdade"`, tickets +10, `LeftLabel` visible.
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: teste de força e Tritomos no novo sistema`.

### Task 12: Sword cutscene

**Files:**
- Modify: `scenes/chapter_one/festival_city/scripts/sword_cutscene.gd`
- Test: `tests/dialogo/test_cidade.gd` (extend)

**Interfaces:**
- Consumes: `espada.dialogue` cues `cena_1`…`cena_7` (Task 8).
- Produces: `play()` becomes one coroutine running the existing steps in the same order and timings (fade, teleport, NPC kick, Anti-POO walk, grab, flash, magic, Kath run/jump, white-out, black screen, "continua" label), with `await Dialogo.iniciar(espada, "cena_N")` where the old code called `Textbox.queue_char_text(dialogue[N-1], ...)`, and `await tween.finished` between tween steps. Delete `dialogue`, `portraits`, `event_seq`, `set_seq` and `_on_textbox_text_finish` (the never-connected handler that stopped the cutscene after its first conversation).

- [ ] **Step 1: Extend the test:** call `play()` and auto-advance every balloon (`avancar()` each frame while `Dialogo.ativo`); within 40s the `continua` label is visible, and seven conversations ran (count `DialogueManager.dialogue_ended` emissions).
- [ ] **Step 2: Run it.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** the test (PASS) and the full suite.
- [ ] **Step 5: Commit** `Diálogo: cutscene da espada no novo sistema`.

### Task 13: Final check in the running game

**Files:** none new (fixes only).

- [ ] **Step 1:** `grep -n "Textbox" scenes/chapter_one/festival_city/scripts/*.gd` returns nothing.
- [ ] **Step 2:** Run the full suite: `RESULT TOTAL N arquivos, 0 falharam`.
- [ ] **Step 3:** Run the game with the Godot MCP (`run_project`, then `get_debug_output`): no new errors or warnings from `ui/dialogue/`, `globals/` or the city scripts.
- [ ] **Step 4:** Run a scene outside the city that uses the old `Textbox` (`scenes/chapter_one/turin_house/`) with the MCP: its dialogue still shows and finishes.
- [ ] **Step 5:** Hand over to the owner for a playtest of the city (looks, effects, settings, both choices, the full sword cutscene).
- [ ] **Step 6: Commit** any fixes: `Diálogo: ajustes finais`.
