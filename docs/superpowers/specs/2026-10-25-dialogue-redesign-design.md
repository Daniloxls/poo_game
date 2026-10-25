# Dialogue redesign: Dialogue Manager, new dialogue box, emotion and the festival city

Date: 2026-10-25
Status: ready for review by the owner

## Why

Writing dialogue today means writing code. Every line lives inside an NPC's GDScript
(`Textbox.queue_text([...])`). A choice is a separate call (`Textbox.display_choice`) whose answer
comes back through a global signal that every NPC listens to, so each NPC needs flags like
`triggered`, `scene` and `finished` to know whether an answer is meant for it. Text and game logic
(battles, tickets, cutscenes) are tangled in the same functions. The Excalibur NPC needs three
functions, two signals and three flags for one short conversation.

The dialogue box itself is crude: a plain panel with Consolas text, an optional portrait, and no way
to show emotion. Characters with portraits look a bit better, but most speakers have none, and the
box does nothing for them. Speaker names are not shown at all.

The owner wants:

- to write conversations as text, with easy branching;
- important player choices whose consequences can reach later parts of the game;
- a dialogue box with more life, matching the battle redesign;
- text and portraits that carry emotion through small animations;
- as much customization as possible;
- a proper rewrite of the city's text: spelling fixed and better writing.

## Goals

1. **Dialogue written in `.dialogue` files** using the Dialogue Manager plugin. Lines, branches,
   conditions, game effects and emotion all go in the file. NPC scripts shrink to starting a
   conversation.
2. **New dialogue box, option B ("portrait breaking out")**, in the battle redesign's visual style.
3. **Emotion toolkit:** text effects and portrait animations used through tags inside a line.
4. **A shared story-state store** where choices are recorded, so any later conversation or scene can
   react to them.
5. **The festival city fully converted** to the new system, with its text rewritten and two new
   player choices (Tritomos and Grande Montanha).
6. **Mouse, keyboard and gamepad** all work in the dialogue box, as they do in battle.
7. **Player dialogue settings**, because they are cheap to add now (see "Player settings").

"As much customization as possible" means flexibility for the person writing dialogue first: tags,
character definitions, theme resources, game effects called from the file. Player settings are a
small extra.

## Non-goals (this round)

- Converting any scene outside the festival city. The old `Textbox` keeps running those scenes
  (chapter one house, south overworld, deep code; chapter two; `cutscene.gd`) until a later round.
- Deleting the old `Textbox`.
- A save system. Story state lives in memory and resets when the game closes. Saving is a separate,
  later project.
- Voice lines, typing sounds or per-character text blips.
- Translation/localization.
- Changing what happens in the city's story (the sword is still stolen, tickets are still earned at
  the same three attractions).

## Anti-goals (would be a failure even if everything works)

- **A "talking bob"** on the portrait while text types. The owner explicitly rejected it as too much.
  Portraits stay still unless a tag moves them.
- **Writing a normal conversation or branch requires editing GDScript.** Code is only for genuine
  game effects (start a battle, give tickets, play a cutscene).
- **Mean or purely good-vs-evil choices.** The owner rejected a "mock the Grande Montanha" option.
  Choices are about honesty and relationships, not cruelty.
- **A generic or childish look** (bubbly fonts, glossy gradients). Same rule as the battle redesign.
- **Breaking the scenes that still use the old `Textbox`.**
- **Modifying the plugin's own files** under `addons/dialogue_manager/`. Customize it through its
  settings and our own scenes and scripts, so the plugin can be updated.

## Constraints

- Godot 4.7.2, GL Compatibility renderer, `window/stretch/mode="canvas_items"`, no viewport size set
  in `project.godot` (Godot's default).
- **Dialogue Manager 4.1.0** is in `addons/dialogue_manager/`. The owner enables it in the editor
  (Project Settings → Plugins), which registers its `DialogueManager` autoload. Syntax verified in
  this version: `~ title`, `Character: line`, `- choice`, `if/elif/else`, `match/when`, `=> title`,
  `=> END`, `do`, `set`, `[#tags]`, `[wait=N]`, `[speed=N]`, `[next=auto]`.
- All dialogue is Brazilian Portuguese.
- `tests/run_all_tests.tscn` (15 suites today) must keep passing; new logic gets its own tests in the
  same style (`tests/`).
- The battle visual language is defined in `docs/superpowers/specs/2026-10-24-battle-redesign-design.md`
  ("Visual style"). Reuse its resources: `scenes/battle/ui/battle_theme.tres`,
  `scenes/battle/ui/battle_fonts.gd` (`BattleFonts.display()`, `BattleFonts.mono()`), and the fonts in
  `assets/fonts/` (Chakra Petch Bold, JetBrains Mono). Do not use `CONSOLA.TTF`.
- Keep styling in theme/stylebox resources, not hard-coded per node, so hand-drawn frames can replace
  the flat style later (same rule as battle).
- The project's default texture filter is nearest (`default_texture_filter=0`). Portraits are large
  hand-drawn PNGs (500×500 to 560×754) shown much smaller, so they must look clean when scaled.
- Old and new systems run side by side. Today `entities/player/player_script.gd` only lets the
  player interact when `Textbox.get_state() == "Ready"`, and the old box sets
  `PlayerState.on_dialogue`. The new system must also block movement and interaction while a
  conversation is open, and the player must not be able to start a second conversation on top of one.

## The dialogue box (decided)

Mockup: `.superpowers/brainstorm/54353-1792934633/content/textbox-look.html`, option **B**.

- A wide cream box along the bottom of the screen: fill `#fff8e7`, thick `#1b1b1b` outline, rounded
  corners, hard drop shadow (no blur). Text in Chakra Petch.
- **Speaker with a portrait:** the bust stands large at the bottom-left, in front of the box,
  overlapping its top edge, with a black outline around the figure. The text starts to the right of
  the bust.
- **Name tag:** each character has a color. The name sits on a slanted tag in that color, on the box's
  top edge (right of the bust when there is one, at the left otherwise). White text with a dark
  outline.
- **Speaker without a portrait:** text uses the full width, and the character's color becomes a thick
  stripe down the box's left edge. Every speaker has an identity even with no art.
- **Line finished:** a small ▼ bobs in the bottom-right corner.
- **Choices:** stacked buttons above the box on the right, in the same panel style. The selected one
  turns yellow (`#ffd23f`), tilts slightly, scales up a little and gets a ▶.
- **Inline highlights:** words can be colored; code terms use JetBrains Mono on a dark chip with yellow
  text (`[code]...[/code]`-style).

## Behavior (decided)

- Text types out letter by letter. Pressing interact once completes the line; pressing it again moves
  to the next line.
- **Enter/exit:** when a speaker with a portrait starts talking, the bust slides in from the left;
  when the conversation ends or the speaker changes, it slides out. Automatic, no tag needed.
- Choices are navigated with up/down (keyboard and gamepad) and confirmed with interact; the mouse can
  hover and click them.

## Player settings (decided: add them; details are Claude's call)

- **Text speed:** slow, normal, fast, instant. Speed changes written in a line (`[speed=N]`) scale
  with it; `[wait=N]` pauses still happen except at "instant", where the line appears at once.
- **Auto-advance:** off by default. When on, a finished line moves on by itself after a short delay
  that grows with the line's length. Choices always wait for the player.
- They live in the inventory's **Opções** tab (`ui/inventory/Inventory.tscn`), which exists today
  and is empty.
- Not saved to disk this round (no save system yet); they reset when the game closes.
- The old `Textbox` does not need to honor them.

## Emotion toolkit (decided)

Mockup: `.superpowers/brainstorm/54353-1792934633/content/emotion.html`. The owner picked all of these.

**Text effects** (tags wrapped around words in a line):

| Effect | Use | Look |
|---|---|---|
| shake | anger, fear, shouting | letters jitter in place |
| wave | playful, dreamy, sing-song | letters ride a sine wave |
| pauses and speed | hesitation, dramatic beats, rushing | Dialogue Manager's `[wait=N]` and `[speed=N]` |
| pop | a word that slams in | appears bigger and colored, overshoots and settles |
| whisper | secrets, asides | smaller, grey, types slower |
| glitch | corrupted things in the code world | brief chromatic red/cyan jitter on letters |

**Portrait animations** (tags on a line, applied when the line starts):

| Animation | Use | Look |
|---|---|---|
| expression swap | any change of feeling | the bust swaps to another expression image with a squash-and-stretch "punch" and a short white flash; can also happen mid-line |
| hop | joy, excitement | a quick jump with squash on landing |
| shake | shock, anger, fear | horizontal shake with a slight rotation |
| slump | sadness | sinks a little, tilts, loses saturation, then holds |

Tag names are the builder's call, but they must be short and readable in a line. Suggested:
`[shake]…[/shake]`, `[wave]…[/wave]`, `[pop]…[/pop]`, `[whisper]…[/whisper]`, `[glitch]…[/glitch]`,
`[code]…[/code]` for text, and Dialogue Manager tags for the portrait, like `[#feliz]` (expression)
and `[#hop]`, `[#shake]`, `[#slump]`. Expression names come from the portrait file names
(`feliz`, `neutro`, `surpreso`, ...).

## Characters (decided in principle)

Characters are defined once, so a line only says `Kath:`. Each definition holds the display name,
the color, and the portraits per expression (with a default). Speakers not defined anywhere still
work, with a neutral color and no portrait.

Known portraits in `assets/portraits/`:

- Kath: `kath_neutra.png`
- CMD (Cmdzinho): `cmd_alegre`, `cmd_duvida`, `cmd_feliz`, `cmd_neutro`, `cmd_surpreso`, `cmd_vazio`
- Anti-POO: `anti_poo_neutro`, `anti_poo_serio`
- Hidden speaker: `silhueta.png` (used today for Anti-POO before he is revealed)

Colors used in the mockups: Kath `#2ec4d6`, Grande Montanha `#e8463a`. Other colors are the builder's
call, taken from each character's art.

## Story state (decided)

One shared store for the whole game (called `Historia` in the examples) that dialogue files read with
`if` and write with `set`, and game code can read too. It is the place where choices are recorded so
later chapters can react. It is not saved to disk in this round.

## The festival city (decided)

Scene: `scenes/chapter_one/festival_city/City.tscn`. Everything spoken in the city moves to
`.dialogue` files and the new box:

- Scripted NPCs in `scenes/chapter_one/festival_city/scripts/`: `cmdzinho.gd`, `excalibur_npc.gd`,
  `medium_tent.gd` (Tritomos), `strenght_test_npc.gd`, `tatame_npc.gd`, `ticket_trader.gd`,
  `sword_cutscene.gd`.
- NPCs whose lines are set in the inspector (`texto` on `NPC.tscn` instances in `City.tscn`):
  `TendaNPC`, `LutadorNPC` (Grande Montanha), `NPC1`, `Kath`, `NPC2`, `NPC3`.

**One deliberate behavior change:** the city starts with **0 tickets**, not 30 (`tickets.gd`; 30 was
a demo shortcut, and the on-screen label already says "x 0"). This makes the "not enough tickets"
branch of the sword event reachable.

**Everything else must stay the same:** +10 tickets each for the strength test, the
tatame fight and Tritomos, the 30-ticket check before the sword event, the tatame battle
(`res://scenes/encounters/muscleguy.tscn`) and full heal on a loss, the strength-test sequence, the
Tritomos code puzzle and its interface, and the order and timing of the sword cutscene. Dialogue
inside the sword cutscene must still be driven by the cutscene, which has to be able to wait for a
conversation to end before continuing.

**Bugs found while reading, to fix in passing:**

- `NPC1`'s `texto` is one string containing a literal `", "` instead of two lines.
- `strenght_test_npc.gd` calls `cmdzinho.textbox.queue_char_text(...)`, but the CMD follower has no
  `textbox`, so CMD's hint after a failed strength test cannot work.
- `ticket_trader.gd` uses `get_node("../Textbox")`, which does not exist.
- `sword_cutscene.gd` never connects its `_on_textbox_text_finish`, so the cutscene stops after its
  first conversation. Take the order and timing from the script as written, not from what the game
  does today.

### New choice 1: Tritomos (decided)

Tritomos really can read thoughts through code. Turin beats him by editing his code so his `return`
gives back a word Turin chose instead of what he truly read. After losing, Tritomos is shaken (his
crystal ball never fails). The player chooses:

- **Tell the truth:** Turin admits he changed the code. Tritomos is unsettled that someone can do that,
  and becomes an ally who knows about code reading. This can pay off later, since Anti-POO also
  tampers with code.
- **Let him believe his power failed:** Tritomos loses confidence.

In both branches Tritomos still leaves the tent afterwards, exactly as today (`vidente_left.png`,
`LeftLabel`). The choice changes only his lines in that conversation and the value recorded in the
story state; the "ally" payoff happens in later chapters, not in the city. Turin gets his 10 tickets
in both branches, since he won the game either way (Claude's call).

### New choice 2: Grande Montanha (decided)

After the player wins the tatame fight, Turin says one of:

- **"Foi uma luta incrível!"** (respect: he becomes a friend), or
- **"Me ensina a lutar assim?"** (he becomes a mentor).

Either way he likes Turin. The answer is recorded in the story state and decides how he appears
later. There is no mean option.

### Rewrite (decided)

- Fix spelling and grammar. Found so far: "dá pedra" → "da pedra", "premios" → "prêmios",
  "vitoria" → "vitória", "bem vindo" → "bem-vindo", "advinhar" → "adivinhar", "trás lembranças" →
  "traz lembranças", "Enquanto a você" → "Quanto a você", and no space before "?".
- Make the lines livelier while keeping the same story beats. The owner approved this sample as the
  target voice:

  ```
  ~ desafio
  Organizador: Ei, você aí, garoto! Tem coragem de encarar o [pop]GRANDE MONTANHA[/pop]?
  Organizador: Três rounds no tatame. Se você ganhar, os tickets são seus!
  - Pode vir!
  	Organizador: [wave]Senhoras e senhores...[/wave][wait=0.4] que comece a luta!
  	do Batalha.iniciar("montanha")
  - Hoje não.
  	Organizador: Sem problema. O Montanha não vai a lugar nenhum.

  ~ vitoria
  Organizador: Eu...[wait=0.3] eu não acredito!
  Organizador: [shake]Montanha![/shake] Você deixou esse garotinho te vencer?!
  Grande Montanha: [whisper]Ele é mais forte do que parece...[/whisper]
  Organizador: Bom, regra é regra. Aqui estão seus tickets. Aproveite o festival!
  ```

  (`Batalha.iniciar` is a placeholder for whatever starts the battle.)
- Use the emotion tags where they serve the moment, not on every line.
- Give every speaker a name (today names are never shown). Exception: in the sword cutscene,
  Anti-POO speaks as "???" (with `silhueta.png` while hidden), because Turin doesn't know who he is
  yet and his name would spoil the reveal (Claude's call).

## Left to the builder

- How the dialogue box is built on top of Dialogue Manager (it ships an example "balloon" to start
  from), and how it is registered.
- How the text effects and portrait animations are implemented, and exact timings, easing and sizes.
- The character definition format and where it lives; the story-state store's exact shape and keys.
- How the `.dialogue` files are organized (one per NPC, one per area, ...).
- How NPC scripts start conversations, and how the sword cutscene waits for them.
- How the new system and the old `Textbox` coexist (player interaction gate, `PlayerState`).
- Colors for characters other than Kath and Grande Montanha; names for currently unnamed NPCs.

## How we'll know it works

- In the city, every conversation runs in the new box: names, colors, busts or stripes, choices,
  effects and portrait animations all behave as described.
- Both new choices work and are recorded in the story state.
- Every city flow still works end to end: earning tickets at all three attractions, losing and
  winning the tatame fight, failing and passing the strength test, solving and failing Tritomos's
  puzzle, being turned away from and then playing the sword event, and the full sword cutscene.
- The city starts at 0 tickets, and the sword event turns Turin away until he has 30.
- Changing text speed and auto-advance in Opções changes how the next line plays.
- Scenes outside the city still use the old `Textbox` and work as before.
- The game starts with no new errors, and all test suites pass.
- The owner playtests the city and reads the rewritten text.
