# Title screen, opening and tutorial redesign

Date: 2026-10-29
Status: approved by the owner

## Why

After the battle, dialogue, inventory and city redesigns, the start of the game is the weakest part:

- The title screen (`ui/title_screen/`, autoload `TitleScreen`) is a `CanvasLayer` drawn over the
  tutorial, which is already the main scene (`run/main_scene` = `Tutorial.tscn`). It is the
  background art, a title split over three hand-placed `Label`s, one blue "Jogar" button, a hidden
  "Créditos" button and "v0.1". No music (commented out), no keyboard focus styling, no polish.
- Pressing "Jogar" hides the overlay and the player is standing in the tutorial. No introduction.
- The tutorial (`scenes/chapter_one/tutorial/`) is a Cuphead-inspired sketch-paper corridor with
  wall drawings: WASD (arrows light up on key press), lever room, dummy fight room. It is short and
  gives a first-time player no sense of progress.
- The ending is abrupt: walking into `PortalShow` fades a static image out in 1 second and shows a
  portal and spikes, with no text or hint. Players don't know they must walk to the portal and
  interact with it, and some get stuck.

The game's audience includes people who have **never played a top-down RPG**. The start has to
teach the controls clearly, give time and small challenges, and set up the story.

### Story concept (owner's)

Turin is an NPC. Sometimes, in his dreams, he goes to a **test chamber** where his functions are
tested: walking, interacting, fighting. The villain (Anti-POO, imprisoned in the Deep Code) cracks
this level on purpose and Turin falls into the Deep Code, where he starts to see the code behind
things. This matches the existing Deep Code scenes: the silhouette guiding Turin is Anti-POO in
disguise, who needs someone to switch on sudo at the terminal to free him
(`anti_poo_room.gd`), and the chapter then continues at `TurinHouse` (reads as Turin waking up).

## Goals

1. A nicer title screen (direction chosen: "living poster").
2. A short opening that takes Turin into the test chamber, told with running code.
3. A longer, clearer tutorial: one function per room, a visible checklist, small challenges.
4. Teach item use, inside a battle.
5. Replace the abrupt static flash with a built-up crack and an automatic fall into Deep Code.

## Non-goals

- **No programming in the tutorial.** It only teaches the basic controls. Code shows up as flavor
  (boot log, checklist written as method calls), never as something the player edits. Sudo, the
  code panel and puzzles start in Deep Code, as today.
- No save system; "Continuar" is a disabled placeholder until saves exist. Créditos too.
- No title art animation now. The owner will split the art into 3 layers later and it gets animated
  then. The title art stays static for now.
- No inventory menu in the tutorial: the player gets the inventory at the end of Deep Code (see the
  inventory spec). The tutorial only puts an item in the backpack (`Inventory.mochila`) for battle use.
- No changes to Deep Code beyond its first line (see 5).

## Anti-goals (failure even if it works)

- A new player finishing a room and not knowing what to do next.
- Losing the tutorial fight.
- The crack feeling like a bug or a sudden cut instead of a story beat.
- A title screen that looks worse than the redesigned menus (battle/inventory).

## Design

Player-facing text is Portuguese, like the rest of the game. All wording below is a draft the owner
will edit.

### 1. Title screen

Direction A ("living poster"), without the breathing/zoom animation.

- Background: `assets/screens/menu_background.png` (Turin, green-haired character, castle), static.
  A soft dark gradient at the bottom so the menu reads.
- Logo: "Protetores da / Ordem dos Objetos" as one tight block at the top, same font and colors as
  now (BreatheFire, orange with brown outline and dark shadow), "PROTETORES DA" smaller above.
- Menu at the bottom center, keyboard/controller driven: **Novo Jogo, Continuar, Opções, Créditos**.
  **Continuar and Créditos are shown but disabled** (greyed, skipped by the cursor) so they can be
  wired up later (owner). Selected
  item is yellow with a `▶` arrow, like the new inventory (cursor arrow, yellow = selected). Mouse
  also works. Use the UI sounds the inventory already uses (Kenney: confirm, back, move).
- Opções reuses the options already in the inventory (`ui/inventory/scripts/opcoes_tab.gd`,
  `globals/opcoes.gd`).
- Music: "Dream" by Eliot Corley (`assets/bgm/Dream Eliot Corley.mp3`, the line already commented
  out in `title_screen.gd`), through `MusicPlayer`.
- Version label stays (small, corner).
- The title screen becomes the **main scene** (its own scene, not an overlay on the tutorial), so
  the opening can play between Novo Jogo and the tutorial. Remove the `TitleScreen` autoload, or
  keep it only if something else depends on it; builder checks.

### 2. Opening: boot log (direction A)

After Novo Jogo, a black screen with monospace text typing out line by line (~8 s total), e.g.:

```
> SalaDeTestes v0.1 — iniciando sonho...
> carregando NPC "Turin" ........ OK
> new Teste(turin) {
    [ ] turin.andar()
    [ ] turin.interagir()
    [ ] turin.correr()
    [ ] turin.lutar()
    [ ] turin.usarItem()
  }
> aviso: acesso desconhecido em 0x00DEEP   (ignorado)
> transportando para a sala de testes...
```

- The red warning line is the first hint of Anti-POO. It is shown and "ignored", no comment.
- Transition into the tutorial: the sketch room opens from the center (circle wipe or similar).
- Colors match the battle console / code panel style (keywords purple, methods blue, OK green,
  warning red).
- Not skippable for now: there are no saves and nothing writes to disk, so "seen once" can't be
  remembered across launches. Add a skip when a save system exists. (my call)

### 3. Checklist HUD

The list from the boot log stays on screen during the whole tutorial, in a top corner, small,
same terminal style:

`[✓] andar()  [✓] interagir()  [ ] correr()  [ ] lutar()  [ ] usarItem()`

- Each item ticks with a small sound/flash when its room is done.
- At the crack (see 5), a red line is appended that was not in the list: `[!] turin.cair()`.
- Hidden during battle (the battle has its own UI) except where the battle prompts need it.

### 4. Tutorial rooms

**New tile-based level** (owner approved a new scenario; the owner will draw a new sketch-style
tileset). The single painted background (`tutorial_ground.png`) is replaced by `TileMapLayer`s.
Until the owner's tileset exists, use a generated **sketch-style placeholder tileset** (paper
floor, black ink walls, hatched blocks, door slot), not the project's pixel-art placeholders, which
clash with the look. Tile size **500×500**, like the city tileset, so the real one drops in by
swapping the image. (tile size: my call)

Five rooms, snake-shaped (room 1 bottom-left, 2 above it, 3 a long hallway to the right, 4 top-right,
5 below 4). Each room's exit wall slides open when its checklist item ticks:

1. `andar()`: a few blocks placed so the player must use all four directions. WASD drawing.
2. `interagir()`: lever + chest. Exit opens only when **both** are done. Interact-key drawing.
3. `correr()`: long hallway, timed gate. Run-key drawing.
4. `lutar()` + `usarItem()`: dummy arena. Exit opens on win.
5. **Exit room** (new): a drawn "SAÍDA" door. Walking toward it starts the crack (section 5). The
   player chooses to go; from there it is automatic.

Wall drawings (Cuphead style) stay as sprites on the walls; the arrows still light up on key press.
Existing pieces are reused where they exist.

| # | Ticks | Room | Exists / new |
|---|-------|------|--------------|
| 1 | `andar()` | Turin is sketched into place. WASD wall drawing; arrows light up on press. Ticks once the player has moved in all 4 directions. | Drawing + arrow feedback exist (`tutorial.gd`). Tick logic new. |
| 2 | `interagir()` | Lever opens the wall. A drawn **chest** gives a **Poção** (`scenes/items/repo/potion.tres`, "Recupera 40 HP") into `Inventory.mochila`. Ticks when both are done. | Lever exists (`lever.gd`). Chest new (art + interact). |
| 3 | `correr()` | A lever opens a gate for a few seconds; walking is too slow, running makes it. Run drawing on the wall. Retry is free (pull the lever again). | Run drawings exist. Timed gate new. |
| 4 | `lutar()` + `usarItem()` | The dummy fight teaches both (see below). | Dummy + battle exist. Prompts, glitch hit, damage floor new. |
| 5 | — | Exit room + the crack (section 5). | New; replaces `PortalShow`/`glitch_effect.gd` and `sourcecode_portal.gd`. |

The interact key drawing (`DesenhosParede/Activate`) and run drawings are kept; add or move
drawings so each room has its own key drawing before the challenge.

**The dummy fight** (`scenes/encounters/testdummy.tscn`, `test_dummy.gd`). Note: the dummy already
attacks (2–5 punch damage).

1. Battle opens. A prompt (drawing or short text next to the action menu) points to **Atacar**.
   The dummy hits back weakly. `lutar()` ticks after the first successful attack.
2. **First glitch:** once the dummy's HP drops below a threshold (about half, builder tunes so it
   happens before the dummy can die), the dummy flickers (glitch visual) and on its next turn lands
   one hit much harder than it should, leaving Turin low. This is Anti-POO's interference, not
   explained.
3. **Atacar fades out** (greyed, not selectable) and the only selectable option is **Usar Item**.
   A prompt points to it. Using the Poção ticks `usarItem()` and Atacar comes back. (owner's call)
4. The player finishes the dummy.

- Because Atacar is locked from the threshold until the potion is used, the dummy can't be killed
  before the item lesson. Damage that would take the dummy from above the threshold to 0 in one hit
  must also stop at the threshold (builder checks Turin's damage range against the dummy's 27 HP).
- **The dummy can never knock Turin out**: its damage is clamped so Turin stays at 1 HP minimum.
- Turin starts the tutorial at full HP (his test HP is 10/26 today) and the chest gives exactly
  **one** Poção (`potion.tres` defaults to quantity 6). (my call)
- **The battle console is hidden in this fight** (F2 and `ConsoleButton` disabled): Turin can't call
  functions yet because he isn't in sudo mode (owner). Needs a per-battle switch in `battle.gd`; the
  console's first appearance is left to a later battle.
- Locking a single action (Atacar) also needs a per-battle hook in the action menu.
- If the player uses the potion before the threshold, `usarItem()` still ticks; the glitch hit
  still happens but Atacar is not locked and the prompt is not repeated. (my call)
- Battle prompts hang off the existing `Battle.turn_started` signal; the builder picks the
  mechanism (dialogue line, overlay drawing, highlight on the menu entry).
- After winning, the dummy disappears and the last wall opens, as today
  (`dummy.gd::_on_tutorial_battle_tutorial_end`).

### 5. The crack and the fall

Glitches build from the fight on: after the battle, drawings occasionally flicker and the red
`0x00DEEP` warning flashes on the HUD. Then, walking toward the "SAÍDA" door in the exit room:

1. All five items are ticked. Terminal-style text: "Teste concluído. Acordando..." and it gets cut
   off mid-word.
2. Screen shake, rumble. A crack runs across the floor from the door toward Turin. HUD appends
   `[!] turin.cair()`.
3. The floor opens under Turin and he falls. **This is an automatic cutscene**: player input is off
   (`PlayerState.set_on_scene(true)`); there is no portal to find.
4. The fall: the sketch room falls away and Turin drops through dark space with lines of code
   rushing past, then the screen cuts to Deep Code.
5. Deep Code's first line (`deep_code.gd`) changes from "Vejo que você estava explorando e acabou
   caindo aqui por aquela rachadura" to something that doesn't assume exploring, e.g. "Vejo que você
   caiu por aquela rachadura." (my call; owner edits)

Who talks in the test chamber: nobody. The test system only speaks through terminal text (boot log,
HUD, "Teste concluído..."). (my call; the owner didn't choose)

## New art needed

The owner draws the art. Placeholders are fine while building.

- Sketch-style tileset, 500×500 tiles (floor, walls, blocks, sliding door/wall).
- "SAÍDA" door.
- Interact-key drawing showing **Space** (the bound key; the current drawing shows Z) and a Shift
  drawing for running.

- Chest (closed/open), sketch style.
- Timed gate (open/closed), sketch style; can reuse the retractable wall art.
- Crack on the floor (growing frames or a few stages), sketch style.
- Fall background: dark space with code lines (can be done procedurally with text instead).
- Key drawings for any room missing one.

## Left to the builder

- Scene structure and how the opening is built (own scene vs. part of the title scene).
- Room sizes and exact positions within the 5-room snake layout.
- Gate timer length (tune so walking fails and running passes comfortably).
- Glitch visuals (shader vs. sprite swaps), shake, sounds.
- How battle prompts are shown.
- Whether the old `glitch_effect.gd`, `sourcecode_portal.gd` and `PortalShow` nodes are deleted
  (expected: yes, once the crack replaces them).
- Tests for new logic (checklist ticking, damage floor), following `tests/`.
