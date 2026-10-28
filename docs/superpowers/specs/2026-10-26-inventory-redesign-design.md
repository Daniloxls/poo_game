# Inventory redesign: a JRPG menu that teaches OOP

Date: 2026-10-26
Status: ready for review by the owner

## Why

The inventory (`ui/inventory/`, autoload `Inventory`) is the last big screen still in the old look:
one dark-grey `TabContainer` at a fixed 1141×643, Consolas text, and every screen spelled out as Java
built from dozens of separate `Label`s (`public class Mochila { List<Item> mochila = [ ... ] }`).
Invisible disabled tabs (`a`, `b`, `c`, `d`) are used as spacers. It no longer matches the battle and
dialogue redesigns (cream panels, thick offset black outline, ChakraPetch).

It is also crude to use: it pops in with no animation, potions are the only usable item, item
descriptions only show on mouse hover, there is no keyboard or controller navigation, equipment is a
hardcoded list kept in two places, and `equipamento_tab.gd` loads a path that does not exist
(`res://scenes/inventory/ItemButton.tscn`).

The owner wants the code idea to stay, but as **teaching**: the inventory should help the player
understand OOP. The menu becomes the place where the player keeps seeing OOP in action, using real
Java that is correct for what they have learned so far.

### Where the inventory sits in the game

- The player gets the inventory after the tutorial at the end of deep_code, once they have seen
  programming basics (`bool`, `int`, `String`, ...).
- From then on OOP concepts are introduced in the usual university order: **Classe, Objeto,
  Métodos, Encapsulamento, Abstração, Polimorfismo, Herança**.
- Inventory content appears only as each concept is unlocked.
- The game is a Final Fantasy-style JRPG. The first ability the player gains is **changing classes**
  (Final Fantasy V / Bravely Default jobs). A job class and a Java class are deliberately the same
  idea here.

## Goals

1. **Summary screen** opened by **E** (and the controller menu button, and a corner icon), in the
   classic Final Fantasy / RPG Maker layout.
2. **Status** card per character that literally **flips** to show its live Java code.
3. **Classe**: change a character's class, with a new look, new stats and new methods.
4. **Itens**: use and discard items, with the code for each action shown. Key items get their own tab.
5. **Equipamento**: one tab per character, with stat changes previewed as numbers with ▲▼.
6. **Documentação**: general pages about each concept the player has unlocked.
7. **Unlock flow**: concepts and classes unlock from the story. A badge on the corner icon and in the
   menu tells the player.
8. **Code that grows with the player**: the same action is written differently as concepts unlock
   (see "Code stages").
9. **Mouse, keyboard and controller** all work, as in battle and dialogue.
10. The visual style of the battle/dialogue redesigns.

## Non-goals (this round)

- The battle item picker (`scenes/battle/ui/item_picker.gd`). It is already in the new style. It must
  keep getting its items from the inventory (see Constraints). Changing the battle console's
  `usarItem` command to match `pocao.usar(turin)` is a **later** project the owner has agreed to.
- A save system. Unlock state lives in memory, like `Historia`.
- An economy (shops, earning money). Only *displaying* money is in scope.
- Puzzle hints. Documentação only has general pages. Hints come from CMDzinho and other helpers in
  the world.
- Final per-class character sprites (see "Assets").
- Classes beyond the four listed. The owner plans to add and upgrade classes as the game grows, so
  adding one must stay easy (see Constraints).

## Anti-goals (would be a failure even if everything works)

- **Java that is wrong for what the player knows.** The game teaches real Java. A line on screen must
  be valid Java, or clearly marked as a comment. Specific cases are below.
- **Intimidating walls of numbers and code.** The owner rejected a full-sum code panel on the
  equipment screen as "a bit much". The front of every screen is a friendly JRPG menu. Code is one
  short line, or sits behind the **{ }** flip.
- **Stat bars on the equipment screen.** Tried and rejected: "the bars don't look good". Numbers only.
- **Code always visible beside the card.** Option A (card and code always side by side) was not
  chosen, and neither was a card with a sliding code panel. The code lives on the **back** of the
  card.
- **Locked concept names leaking.** Locked concepts show as `???`. The owner chose this over
  scrambled glyphs and `/* ? */`.

## Visual style

Match the battle and dialogue redesigns:
- cream panels `#FFF8E7`
- thick outline `#1b1b1b`, with a heavier offset on the right and bottom
- yellow highlight `#FFD23F`
- ChakraPetch-Bold for the interface, JetBrains Mono for code
- dark code panels (`#1e2230`-ish) inside the cream frames

Reuse `HardShadowStyleBox` (`scenes/battle/ui/hard_shadow_style_box.gd`) and `battle_theme.tres` /
`ui/tema_depurar.tres` rather than making new styles.

**Tabs join their panel.** Where tabs are used (Itens / Itens-chave, one tab per character in
Equipamento), the selected tab has the panel's colour, covers the panel's top border under it, and
the panel's corner under the first tab is square. The owner pointed out that a rounded panel with a
tab "hovering on top" looks wrong.

Locked concept chips: a dashed grey pill with `???`. Unlocked: a yellow pill with the name.

## Screens

### Summary (what E opens)

Approved mock: `.superpowers/brainstorm/89864-1793058774/content/resumo.html` (local only,
`.superpowers/` is gitignored).

- **Left, large panel:** one row per party member with portrait, name, class tag, level, and HP and
  PP bars with numbers. The concept chip trail sits under the rows.
- **Right, command list:** Itens, Status, Equipamento, Classe, Documentação, Opções. Status,
  Equipamento and Classe ask for a character after the command (FF-style). A command for something
  not yet unlocked is hidden. Classe appears once classes unlock.
- **Bottom right:** money, current location, play time. Play time and location were Claude's
  additions; the owner approved the screen.
- No Salvar command (there is no save system).

### Status: the flip card

Approved mock: `flip-class.html` (same folder).

- **Front:** the JRPG card with sprite/portrait, name, class tag, level, HP/PP, Ataque / Defesa /
  Velocidade, and the class's abilities listed as **Habilidades**.
- **One { } button** in the card's corner, the same button on both faces. (The mock wrongly showed
  two buttons on the back; that was a mistake.) Pressing it **flips the card in 3D** to the back.
- **Back:** the character's Java code. It is **always live**: if HP changes, the class changes or
  equipment changes, the back updates, whether or not it is showing.
- What the back shows depends on the code stage (below). Sections for concepts not yet unlocked show
  as `// ??? 🔒` (for example the methods section before Métodos).
- The back starts with `Personagem kath;` with `Personagem` greyed out. When **Herança** unlocks it
  lights up: all four classes were `Personagem` the whole time. This is also why
  `kath = new BlackHat(kath);` is valid Java before inheritance is taught. The owner approved this
  payoff. (The existing `rpg_classes/commoner.tres` is already named "Personagem".)

### Classe

- Four classes unlock **all at once**:
  - **Black Hat:** a thief-type hacker
  - **White Hat:** support
  - **Protector:** protects other characters' variables (tank)
  - **Functioneer:** a method user, basically a mage
- Choosing a class changes, at once, the character's **sprite set** (each character has one per
  class), stats and methods/abilities. The old class's methods go away. The lesson: what an object can
  do depends on its class.
- The code line for the change is the copy constructor, with the old object passed as the argument:
  `kath = new BlackHat(kath);`. The owner asked for this ("pass her as an argument") and rejected
  `kath.classe = new BlackHat();` because it "would lose the point of the class object meaning". The
  new object keeps her name, level, XP and equipment from the old one.
- Classes are `RPG_CLASS` resources (`rpg_classes/*.tres`: `CLASS_NAME`, bonuses, `SKILLS`).
  Adding a class must mean adding data (a `.tres` plus sprites), not editing menu code.

### Itens (Mochila)

Approved mock: `mochila.html`.

- Two tabs: **Itens** and **Itens-chave**.
- An item grid with icon, name and quantity. Selecting an item shows its name, description and value
  in money.
- **Usar** → choose a character → the action's code line types itself out while the character's HP
  goes up.
- **Descartar** removes one, shown as `mochila.remove(pocao);`. **Key items cannot be discarded.**
  The button is disabled and the item says so.
- Items whose type has no use effect yet have no Usar button. Only healing is implemented today. The
  design must let new item types bring their own `usar` behaviour later, because that is the
  polymorphism lesson.
- Money: each item shows its value and the total is on the summary screen. The game has no currency
  yet. "bits" in the mocks is a placeholder name. Keep the name in one place so it is easy to change.

### Equipamento

Approved mock: `equipamento-v2.html` **without the bars**.

- One tab per character.
- Left: the six slots in plain words (Cabeça, Corpo, Pés, Mão dir., Mão esq., Acessório), each
  showing the equipped item name or "vazio". The slots are the character's variables.
- Middle: the items in the backpack that fit the selected slot, plus **Tirar** to empty it.
- Right: Ataque / Defesa / Velocidade (and HP/PP if equipment affects them) as **numbers**. Hovering
  or focusing an item previews it: `Defesa 15 → 18 ▲3` in green, or ▼ in red.
- **One code line**: the assignment about to run, e.g. `kath.corpo = armaduraFerro;` or
  `kath.corpo = null;` for Tirar.
- The full sum (`def = defBase + corpo.def + maoD.def`) is shown only on the back of the Status card.
  Before Métodos it is written as a sum expression. After Métodos it can become
  `int getDef() { return defBase + corpo.def + ...; }`. (A field initialised once with `int def = a + b;`
  would not update in real Java. Showing it as a getter later is a small lesson about why methods
  exist.)
- Equipment comes from the same backpack as other items. No hardcoded lists. Two-hand weapons
  (`EQUIP_ITEM.Slot.TWO_HAND`) still take both hands.

### Documentação

- Left: a list of unlocked topics, including the basics from deep_code (`bool`, `int`, `String`, ...)
  and each OOP concept once unlocked. Locked concepts show as `???`.
- Right: a readable page with a short explanation and a small code example.
- General pages only, no puzzle-specific hints.
- Content: **Claude's call**. Claude drafts the pages for the basics and the concepts unlocked in
  chapter one, and the owner reviews them. Pages for later concepts are short placeholders until the
  story reaches them. Pages must be data (one file per page or one resource), so the owner can edit
  text without touching code.

### Opções

Keep the existing text speed and auto-advance settings (`opcoes_tab.gd`, `%Velocidade`,
`%AvancoAutomatico`), restyled. Tests rely on those unique names.

## Code stages

The same action is written differently as concepts unlock. Only the stages the owner decided are
listed. Later stages are left to the builder, as long as they are valid Java and teach that concept.

| Action | Objeto (start) | Métodos | Encapsulamento |
|---|---|---|---|
| Use potion | `turin.hp = turin.hp + pocao.cura;` | `pocao.usar(turin);` | the direct `hp` line appears crossed out with a note that `hp` is `private`; `pocao.usar(turin);` still works |
| Change class | `kath = new BlackHat(kath);` | same | same |
| Equip | `kath.corpo = armaduraFerro;` | same | builder's call (e.g. a setter) |

The owner chose `pocao.usar(turin)` over `turin.curar(pocao)`: "there would be other items, and they
might not be cure ones". Every item has `usar(alvo)`, and Polimorfismo later shows each item type
overriding it.

## Unlocking

- One call that story code (dialogue files, cutscenes) can make to unlock a concept or the classes,
  e.g. `Progresso.desbloquear("metodos")`. The name and whether it extends `Historia` are the
  builder's call. The menu reads the unlock state; nothing about unlocks is hardcoded in the menu.
- The inventory itself can be locked through the same API: while it is locked, E and the corner icon
  do nothing. In the final game it unlocks at the end of the deep_code tutorial. This round it starts
  unlocked (see "Claude's calls").
- **Corner icon:** a small cream/outlined button on screen that also opens the menu. It appears once
  the inventory is unlocked and hides during dialogue and cutscenes, the same as the E key today
  (`PlayerState.is_on_dialogue()`).
- When something unlocks:
  - a yellow badge appears on the corner icon
  - the command it belongs to (Documentação, Classe) gets the same badge in the menu
  - on first viewing, the chip changes from `???` to its name
  - the badges clear once seen
- For development, a way to unlock everything quickly (like the F9 sword-cutscene shortcut) is
  welcome. Builder's call.

## Controls

- Keyboard and mouse first, with controller supported, like battle and dialogue.
- Use Godot focus navigation with the existing `ui_accept` / `ui_cancel` (already bound to gamepad
  buttons) and arrows/d-pad. E and the controller menu button open the menu. Esc / `ui_cancel` goes
  back one level, then closes.
- Typing "e" in a text field must not open the menu (existing behaviour, covered by tests).
- Item descriptions show on **focus** as well as hover.

## Feel

- Opening and closing animate (a short slide or pop). The exact motion is the builder's call; it must
  be quick.
- Keep the click sound (`Audio_Click`).
- The card flip is a real 3D-looking flip, about 0.5 s.

## Assets

- Per-class sprites for each character do not exist yet. Use the current sprite with a placeholder
  (for example a class-coloured tint or frame) until the owner provides them. Swapping in real
  sprites must only mean adding files and data.
- Class stats and method names for the four classes are not designed yet. The mocks used
  placeholders. Use placeholders in data that the owner can tune.

## Constraints (existing code that must keep working)

- `Inventory` stays the autoload name.
- `scenes/battle/battle.gd` reads the backpack with
  `Inventory.get_node("TabContainer/Mochila").get_items()` and `.spend_item(item)`. Either keep a
  node at that path with that API, or update `battle.gd` and its tests in the same change.
- `battle.gd` disables `Inventory.process_mode` during battles.
- `tatame_npc.gd` calls `Inventory.full_heal()`.
- `deep_code.gd` calls `Inventory.set_player(player)`, which does not exist in `inventory.gd` today.
  Fix or remove it.
- Tests that touch the inventory: `tests/battle/test_battle_flow.gd`, `tests/dialogo/test_iniciar.gd`,
  `tests/dialogo/test_opcoes_tab.gd`, `tests/test_integracao_java.gd`. The suite runs headless
  (`tests/run_all_tests.gd`) and must stay green.
- Character data comes from the `Party` autoload (`scenes/party/scripts/character.gd`, with its
  `rpg_class` resource).

## Cleanup

- Remove the old `BattleInventory` copy inside `Inventory.tscn` (battle uses `ItemPicker`) if nothing
  else uses it. Also remove `scenes/battle/ui/battle_inventory.gd` and
  `ui/inventory/scripts/battle_inventory.gd` if they are dead.
- Delete the stray `ui/inventory/*.tmp` files and orphaned `.uid` files whose scripts are gone.
- Remove the hardcoded equipment arrays in `inventory.gd` and `equipamento_tab.gd`.

## Party, battle and story timing (owner's answers)

- **The party is Turin only today.** Kath joins only *after* classes unlock, and adding her is later
  story work, not part of this round. Every screen must work with any party size (one row, one
  Equipamento tab, and so on, up to however many join). Two-member layouts are tested with test data.
- **Class abilities do not have to work in battle now.** They show in the menu (Habilidades, and
  methods on the back of the card) as placeholders. In battle, every class keeps `atacar` and
  `usarItem`, and the new class abilities are hidden until a later round implements them. Changing
  class must never take away a character's basic battle actions.
- **Story wiring waits for the tutorial remake.** Chapter one's tutorial has one section on variables
  and one on methods, and the owner will remake it later. This round builds the unlock API and the
  dev shortcut but does not place unlock calls in the story.

## Claude's calls (owner to check)

- **What is unlocked by default this round** (until the remade tutorial calls the unlock API):
  the inventory itself (as today, so the game stays playable), the basics pages (`bool`, `int`,
  `String`), **Classe** and **Objeto**. **Métodos** and later concepts, and the four job classes,
  stay locked until something calls the unlock API (or the dev shortcut).

- **Class stats are bonuses** on each character's own base stats, keeping the existing `RPG_CLASS`
  shape (`ATK_BONUS`, `DEF_BONUS`, `VEL_BONUS`) and adding `HP_BONUS` / `PP_BONUS`. Today
  `get_atk()` / `get_def()` / `get_vel()` ignore the bonuses; they must apply them. The back of the
  card shows the sum, e.g. `atk = atkBase + classe.atk + maoD.atk`. The mock's fixed per-class
  numbers were placeholders.
- **Items:** the backpack starts empty and nothing adds to it today. Add an `adicionar(item)` API.
  The "unlock everything" dev shortcut also fills the backpack with a test set (the existing potions
  and armors). Placing items in the world is not part of this work.
- **Festival tickets stay separate** (the `Tickets` node in festival_city) this round. "Ingresso" in
  the mock was a placeholder. Itens-chave is built and tested with test data.

## Left to the builder

- Scene and script structure, node names (except the constraints above), and how the screens are
  split into scenes.
- The unlock store's name and shape.
- Exact animations, sizes, spacing, icons, and the corner icon's position and art.
- Code stages for Abstração, Polimorfismo and Herança beyond what is listed here.
- How money is stored (a simple counter is enough).
- Order of implementation, as long as the game stays playable between steps.
