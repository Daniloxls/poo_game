# Battle redesign: interface, call stack, console and game feel

Date: 2026-10-24
Status: ready for review by the owner

## Why

The game is a turn-based RPG whose core idea is the double meaning of "class": an RPG class and an
OOP class. A character's class decides its methods, and the battle is where the player uses them.
Today the battle works but feels crude: a fixed bottom menu, plain text panels, a hit is a flying
number plus a blink, and a defeat turns red and vanishes. Nothing in the battle teaches programming
beyond the method names.

The redesign should make battles feel important and satisfying, teach something every round, and
look like a modern take on the Final Fantasy classics, matching the game's hand-drawn cartoon art.
The audience is high school and college students, not kids.

## Goals

1. **Layout "B" (modern):** enemies on the left, party on the right. The action menu pops up next to
   the character whose turn it is, not in a fixed window.
2. **Turn order shown as a real call stack** that the battle actually runs on (see "Call stack").
3. **Two ways to act:** buttons for every method of the active character's class, and a console
   where the player types `Personagem.metodo(argumentos)` with autocomplete.
4. **Clean code combo meter** that rewards using the console, without ever punishing the buttons.
5. **Hits and defeats that feel good:** a 5-beat hit sequence scaled by impact, damage types with
   effect and sound slots, a better enemy HP bar, and a defeat sequence themed as an object being
   destroyed.
6. **A visual style that matches the art** (style "B", described below) and avoids a generic look.
7. **Mouse, keyboard and gamepad** all fully supported.

## Non-goals (this round)

- Class customization / class overhaul. The battle only shows the methods the class already gives
  (`RPG_CLASS.SKILLS`).
- Adding Kath (or anyone) to the party, or fixing `battle_kath.gd`.
- Enemies or effects that manipulate the call stack. The stack must make them possible later, but
  none are built now.
- Final sprites, effect sprite sheets and sounds. The owner will source them; this round ships
  slots with simple placeholders.
- New enemy AI, balance changes or new skills beyond what is needed to demo damage types.

## Anti-goals (would be a failure even if everything works)

- **Clunky or slow.** The player must never feel the battle is wasting their time. Inputs respond
  immediately; animations are short and can be fast-forwarded (see "Pacing").
- **Generic "AI dashboard" look:** dark translucent rounded panels, thin borders, soft glows,
  purple gradients. The UI must look made for this game.
- **Childish.** The art is cartoonish, but the UI must read as grown-up (no bubbly fonts).
- **Punishing mistakes.** Typing is where players learn the most; errors must teach, not cost.
- **Losing feels bad.** A defeat should feel like "try again", not a punishment.

## Constraints

- Godot 4.7 (the project was upgraded in commit `cafc311`). Viewport 1152×648, stretch mode
  `canvas_items`, default texture filter nearest.
- `Battle` is an autoload (`scenes/battle/Battle.tscn`). Its public API is used by the game and must
  keep working:
  - `Battle.start_battle(enemy_group_path)` (called by `tatame_npc.gd`, `scenes/chapter_one/tutorial/dummy.gd`)
  - signals `battle_won` and `battle_lost` (listened to by `scenes/chapter_one/festival_city/scripts/city.gd`)
  - `Battle.set_background(texture)`
- **The party is Turin alone this round** (class `rpg_classes/comumzera.tres`, methods `Atacar` and
  `UsarItem`). Kath joins in a later round. Everything must work for any party size; the
  multi-member cases (party-interrupts-party, "pausado" ally in the console, ally targeting, a
  multi-member status panel) are exercised in the dev-only test battle scene, which uses its own
  test party. *(Decided by the owner.)*
- The party is the `Party` autoload (`globals/party.tscn`); party members use
  `scenes/party/scripts/character.gd` (stats `hp, max_hp, pp, max_pp, atk, def, vel`, `rpg_class`).
- Enemy groups are scenes whose root is `Enemies` with children using `entities/encounters/enemy.gd`
  and a `logic(character_list, menu)` method. `scenes/encounters/muscle_guy.gd` computes its damage
  by running the player-editable Java code of the Lutador (`lutador.calcular_dano(...)`); that must
  keep working, including its error case (`dano < 0` shows the error label).
- Skills are `SKILL` resources (`rpg_classes/skills/skill.gd`) listed in `RPG_CLASS.SKILLS`, with a
  `TARGET` array (`NONE, SELF, ALLY, ENEMY, ITE, ALL_ALLY, ALL_ENEMY, EVERYONE`) and a `SKILL_SCRIPT`.
  Using an item (`usarItem`) goes through the battle inventory (`ui/inventory`).
- In-game text is in Portuguese. Code shown to the player uses Portuguese identifiers
  (`atacar`, `turno`, `alvo`).
- The existing battle code (`scenes/battle/battle.gd`, `scenes/battle/ui/*`) is crude and may be
  rewritten freely, as long as the API above keeps working.

## Visual style (decided)

Mockups: `.superpowers/brainstorm/22848-1792874746/content/visual-style-v2.html` (style B, font 2),
`layout.html` (option B), `call-stack-v2.html`, `console.html`, `hit-feel.html`.

- Panels: cream fill `#fff8e7`, 4px outline `#1b1b1b`, rounded ~10px, **hard** drop shadow offset
  ~5px in `#1b1b1b` (no blur, no transparency, no glow).
- Flat saturated colors taken from the art. Action buttons are colored per method with the same
  outline and hard shadow, and slightly rotated (±1–2°); the selected one scales up a little.
- Display font: **Chakra Petch** (bold), SIL OFL. Code font (method names in frames, console):
  **JetBrains Mono** (bold), SIL OFL. Neither is in the project yet: download both (with their OFL
  license files) into `assets/fonts/`. Do not use `CONSOLA.TTF` (Consolas is not freely
  redistributable).
- Enemy HP panel top-left: portrait, name, class tag (e.g. "Lutador"), HP bar with outline.
- Party status bottom-right: name, HP and PP bars per member.
- Hand-drawn panel frames may replace the styleboxes later; the layout must not depend on the flat
  style (keep the styling in theme/stylebox resources, not hardcoded per node).

## Call stack (decided)

The turn order **is** a stack the battle runs on. It is drawn top-right as one dark container
(outline + hard shadow, a "base" line at the bottom, title "PILHA" and a frame count) holding cream
frames `Entidade.turno()`.

- **Round:** every living entity (party and enemies) acts once. A round starts with an empty stack.
- **Push (speed as interruption):** frames are pushed from slowest to fastest `vel` (ties: enemies
  are pushed before party members, so the party acts first; within a side, keep list order).
  *(Tie rule decided by Claude.)* Each frame flies
  from its entity's sprite into the stack. When a faster entity's frame lands on top, it shows an
  "INTERROMPE!" flash and the frame below dims to "⏸ pausado". Result: the fastest is on top and
  acts first. This is the teaching moment: a call made inside another pauses it until it returns.
- **Top frame = whose turn it is:** yellow, slightly tilted, `▶` marker. The matching sprite gets a
  turn indicator, and (for party) the action menu pops up next to it.
- **Pop:** when the action finishes, the frame pops ("returns") and the next frame visibly resumes
  ("▶ retoma"). When the stack is empty, the next round starts with a new push.
- Enemy frames are pink-tinted; party frames cream.
- **Destroyed enemy:** its frame is struck through, marked "destruído" and slides out of the stack.
- **Knocked-out party member:** its frame stays and shows "⏸ HP 0"; when it reaches the top it pops
  immediately without acting.
- Built as a real data structure (push/pop/peek, ordered frames with an entity reference) so future
  effects can push extra frames, reorder or remove them.

## Acting: buttons (decided)

- The action menu pops up next to the active party member, listing every skill of its class as a
  button labelled in code style (`atacar()`, `defender()`, `usarItem()`), with an icon for the
  skill's damage type and the skill description shown on hover/focus.
- Picking a skill that needs targets enters target selection: valid targets are highlighted on the
  battlefield (and invalid ones dimmed). Click, arrow keys/d-pad and confirm select; cancel goes back
  to the menu.
- Acting through a button resets the combo meter (neutral, not a penalty).
- `usarItem()` opens the battle item picker (`ui/inventory` battle tab). It is restyled in the new
  visual style as part of this round (same behaviour, new look), since it appears mid-battle.
  *(Decided by Claude.)*

## Acting: console (decided)

A console line at the bottom, opened by a button and a hotkey (and a gamepad button).

- **Syntax:** `Personagem.metodo(arg1, arg2)`. Character and target names as shown in the battle.
  Method names are the skill name in lowerCamelCase (`Atacar` → `atacar`, `UsarItem` → `usarItem`).
  Items are written as bare identifiers with underscores for spaces (`Poção_Pequena`); matching
  ignores case and accents (`pocao_pequena` works) and autocomplete inserts the canonical name.
  An item the player doesn't have is a rejected command ("Você não tem nenhuma Poção_Pequena"),
  so it costs nothing. *(Builder-check answers, decided by Claude.)*
- **Autocomplete narrows at each step:**
  1. Object: all battle entities listed; only the active one (top of the stack) is selectable,
     the others are greyed with "⏸ pausado".
  2. Method: only the methods of that character's class, with their short description.
  3. Arguments: the parameter name shows as a ghost hint (`alvo`); valid targets are listed with
     side and HP, and the same targets light up on the battlefield.
  Tab (or confirm on gamepad) accepts the highlighted suggestion.
- **Enter runs only a valid command.** An invalid command never runs and never costs the turn.
- **Errors look like an IDE:** red wavy underline under the wrong part, and one short Portuguese
  message using the real OOP term, plus a hint toward the fix. Cases to cover at least:
  - unknown name ("Não existe ninguém chamado 'Turim' nesta batalha")
  - not this entity's turn ("Kath está pausada; é o turno de Turin")
  - method not in the class ("A classe Protector não tem o método 'curar'. Métodos de Turin: atacar, proteger, usarItem")
  - wrong argument count ("atacar espera 1 argumento (alvo), recebeu 0")
  - wrong target kind (an ally where an enemy is expected)
  - destroyed target ("Montanha é null: já foi destruído")
  - syntax errors (missing `.`, `(`, `)`)
  The tone matches the existing Java interpreter's errors (`addons/java_interpreter`).
- **On success:** a short "✓ compilado, executando…" confirmation, then the action plays exactly as
  if chosen by button.
- **Focus rules:** while the console has focus, every game keyboard control is disabled; keys only
  type. Clicking outside the console keeps the typed text, removes focus, and that click must **not**
  activate whatever is under it (protects against misclicks).

## Clean code combo meter (decided)

- +1 for each command run from the console, as a streak across turns. Using autocomplete/Tab still
  counts.
- Fixing a mistake before pressing Enter never breaks the streak; rejected commands do nothing.
- The streak resets only when the player acts through a button.
- Each level gives +5% to the next action's damage or healing, up to 5 levels (+25%).
- Shown next to the console, visibly "heating up" per level, with a small pop when it grows.

## Hit feel (decided)

Every action plays 5 beats; their intensity scales with impact = damage ÷ target max HP (criticals
add extra):

1. **Anticipation (~0.2s):** attacker steps toward the target with a slight squash; the method name
   pops above it (`atacar()`).
2. **Impact (1 frame):** effect sprite for the skill's damage type; target flashes white.
3. **Hit-stop (0.03–0.12s):** brief freeze. Bigger hits freeze longer and add screen shake and an
   impact frame.
4. **Reaction (~0.3s):** knockback and return; damage number pops, bounces and fades; type sound.
   Numbers: white normal, orange and larger with "!" for crits, green "+N" for heals, grey "MISS".
5. **HP bar (~0.6s):** the bar drops at once; a pale "ghost" chunk shows what was lost and drains
   after a short delay. The bar has segment ticks so chunks of damage are readable.

**Damage types:** at least `corte`, `soco`, `fogo`, `magia`, `cura`, extensible. Each type has a slot
for an effect sprite sheet and a sound; until assets exist, a simple placeholder plays. Skills declare
their type (new field on `SKILL`). Existing actions map as: `Atacar` → `corte`, healing items →
`cura`, enemy attacks declare their own type (the Montanha → `soco`). No new player skills are added
for the other types; they are exercised in a dev-only test battle scene. *(Decided by Claude.)*

**UI motion:** panels and the action menu animate in (slide/scale with a small overshoot, staggered
buttons); hover/focus scales buttons slightly; the stack animates pushes and pops.

## Defeat and victory (decided)

- **Killing blow:** maximum hit-stop, short slow motion (~0.4s) and a slight camera push.
- **Enemy destroyed:** white flash, sprite breaks into code glyphs (`0 1 { } ;`) that drift up and
  fade; a short line `Montanha = null` appears where it stood; its stack frame is struck through and
  slides out.
- **Party member knocked out:** kneels and turns grey (not destroyed); its frame shows "⏸ HP 0".
- **Last enemy:** the longest slow motion, then a victory panel slides in with the rewards.
- **Party defeated:** a neutral, short defeat panel (no harsh red screen); `battle_lost` is emitted as
  today and the caller decides what happens next (the tatame NPC heals and offers a rematch).

## Pacing (decided)

- Holding confirm (keyboard/mouse/gamepad) plays animations at double speed; a single press skips to
  the end of the current animation.
- An enemy turn should normally take under ~1.5s.
- No input is ignored while an animation plays without visible feedback.

## Input (decided)

- Mouse: click buttons, sprites and suggestions.
- Keyboard: arrows/WASD to move focus, confirm/cancel keys, hotkey to open the console, Tab to accept
  suggestions.
- Gamepad: d-pad/stick for focus, A/B confirm/cancel, a button to open the console. On gamepad the
  console is driven by picking suggestions (no free typing), and still counts for the combo.
- Every interactive element is reachable without the mouse.

## Left to the builder

- Scene/script architecture of the new battle (rewrite vs. refactor), how the stack is modelled, how
  enemies hook into it, how the console parser is built (reusing `addons/java_interpreter`'s lexer is
  allowed but not required).
- Exact timings, easing curves, shake amounts, colors per method, icon designs, placeholder effects.
- Hotkey choices (must not clash with existing actions in `project.godot`).
- Where reward data for the victory panel comes from (today battles give none; tickets are given by
  the tatame NPC after `battle_won`).

## How we'll know it works

- Headless tests: stack ordering by speed (including ties), pop/resume, destroyed/KO frames; console
  parsing, autocomplete candidates and every error case; combo rules.
- Existing tests keep passing (`tests/run_tests_java.gd`, `tests/test_integracao_java.gd`).
- Manual playtest in the window: the Montanha fight (win and lose) and the tutorial dummy fight with
  mouse, keyboard and gamepad.
