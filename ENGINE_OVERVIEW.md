# Engine Overview — Mario & Luigi: Hotel Mania

A short, beginner-friendly tour of the codebase. Read this first if you have just cloned the project or want to know "where do I touch this?". The deeper, function-by-function **wiki** lives in `.\ENGINE_WIKI.md`.

---

## 1. What this project is

- A fan game in the style of *Mario & Luigi: Dream Team* / the Alphadream RPGs.
- Built with **Godot 4.7.1** (GL Compatibility renderer, see `project.godot`).
- Mixed GDScript + visual scripting: most logic lives in `.gd` files inside `.\Godot\Scripts\`.
- Some experimental multiplayer / Steam hooks exist, but the core playable surface today is **single-player overworld → command-driven battle**.

The full original README (story, team credits, Dreambound context) lives at `.\README.md`. The GitHub security policy is at `.\SECURITY.md`.

---

## 2. Folder layout — look at the colors

In `project.godot` (`[file_customization]`), the Godot editor paints folders by category. The disk layout matches that:

| Color in editor | Physical path             | Role                                                                    |
| --------------- | ------------------------- | ----------------------------------------------------------------------- |
| (none)          | `.\`                      | Godot project file `project.godot`, icon, license, settings             |
| purple          | `.\Assets\`               | Imported art/audio assets. Sub-folders broken down further below.       |
| red             | `.\Assets\3D\`, `.\Godot\Assets\` | 3D meshes specifically.                                          |
| blue            | `.\Assets\Music\`, `.\Assets\SFX\`, `.\Assets\Sound\`, `.\Godot\Nodes\` | Audio + node scenes (reusable scenes). |
| green           | `.\Godot\Scene\`          | The actual "worlds" / maps / main playable scenes.                      |
| yellow          | `.\Godot\Scripts\`        | All GDScript code.                                                      |

Per-group breakdown:

- `.\Assets\` — images, fonts, music, sound effects. Big chunks come from ripped sprite-sheets from *Dream Team* / *Superstar Saga* (kept for study/resemblance only).
- `.\Fonts\` — TTF files for UI text (MarioLuigi2, Daydream, 04B_30, etc.)
- `.\Godot\Scripts\` — all code. Sub-divided into:
  - `.\Godot\Scripts\` (root) — **battle** scripts (the heart of the project).
  - `.\Godot\Scripts\OverWorld\` — overworld movement.
  - `.\Godot\Scripts\Enemies\` — enemy behavior scripts + stats resources.
  - `.\Godot\Scripts\Multiplayer\` — multiplayer (ENet) scripts (very early stage).
  - `.\Godot\Scripts\Utility\` — globals, transitions, save data, camera, debugging.
- `.\Godot\Scene\` — playable scenes: title (`title.tscn`), cafe (`cafe.tscn`), battle scene (`battle_scene.tscn`), overworld (`overworld_test.tscn`), shop (`shop_ui.tscn`), loading (`loading_screen.tscn`).
- `.\Godot\Nodes\` — reusable/prefab scenes (HP bar, damage popup, items, transitions, Mario/Luigi brothers, furniture, etc.)
- `.\Godot\Shaders\` — `see_through` transparency and screen-mask shaders used by the battle arena.
- `.\addons\` — third-party Godot plugins (`anthonyec.camera_preview`, `debug_draw`).
- `.\godotsteam\` — GodotSteam GDExtension binaries (multi-OS precompiled).
- `.\android\build\` — Android export boilerplate.

---

## 3. Game loop at a glance

```
title.tscn  ──▶  overworld_test.tscn (Mario leads, Luigi follows)
                       │
                       ▼
              trigger → battle_scene.tscn (turn-based RPG)
                       │
                  win / lose / flee
                       │
                       ▼
                back to overworld, or shop_ui.tscn / cafe.tscn
```

The main scene set in `project.godot` is `res://Godot/Scene/title.tscn`. Transitions between scenes normally go through the **`Transitions`** autoload (`.\Godot\Nodes\transitions.tscn`), which plays a 3DS-style iris / fill wipe.

---

## 4. Autoloads — the "always-on" singletons

In `project.godot` → `[autoload]`:

| Name         | Path                                              | What it does                                                                 |
| ------------ | ------------------------------------------------- | ---------------------------------------------------------------------------- |
| `Globals`    | `.\Godot\Scripts\Utility\globals.gd`              | Cross-scene state: action enum, current brother, RPG combat state, helpers (`wait`, `next_frame`). Signals: item eaten, heal/hurt Mario. |
| `Transitions`| `.\Godot\Nodes\transitions.tscn`                  | The wipe/iris screen + threaded scene loader. Stays in front of every scene. |
| `Debugger`   | `.\Godot\Scripts\Utility\Debugging.gd`             | In-game debug HUD (`add_text`, `modify_text` push strings onto a `RichTextLabel`). Use it instead of `print` for live feedback. |

Any script can do `Globals.wait(0.5)` to `await` a non-blocking timer, or push a label to `Debugger.add_text("tag","placeholder")` and update it with `Debugger.modify_text("tag","new")`.

---

## 5. Input map (what the player can press)

From `project.godot` → `[input]`:

- **Gameplay** — `Jump` (Space / A button), `Back` (Esc / shoulder), `MarioButton` (Q / A), `LuigiButton` (W / X). Mario & Luigi brothers each have their own "action button" so actions can be split per brother (think Dream Team's two-screen controls).
- **Menu navigation** — `MenuUp`, `MenuDown`, `MenuLeft`, `MenuRight` (arrows + gamepad stick + mouse wheel).
- **Test bindings** — `Test2`…`Test9` plus `TestButton1` mapped to digits. These are debug bindings wired in `game.gd` (`_input_debug`).

If you add a new action, add it here so that scripts using `Input.is_action_just_pressed("MyAction")` can resolve it.

---

## 6. Rendering trick to know about

Many of the visuals (battle, choosecube, enemies) are **2D sprites placed in 3D space**.

- Sprite-sheets are imported as `Texture2D`s and rendered by `AnimatedSprite3D` nodes with a `Sprite3D` material.
- The justification: in the original 3DS games, sprites have arbitrary 2D-ish positioning (perspective-correct but drawn flat). Cheaper than full 3D characters and matches the look.
- Helpers: `.\Godot\Scripts\3DSpriteto2D.gd` (conversion logic), `.\Godot\Scripts\Utility\S2D_on_3D.gd` (placement helper).
- Shaders under `.\Godot\Shaders\` give the soft transparency on the battle arena corners.

---

## 7. Where to start when you want to add something

| You want to…                              | Touch these files                                                                                                                                                                                       |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Add a new character to battle             | Add a `CharacterDefaultStats` entry / a new `BrotherCB3` scene under `.\Godot\Nodes\Brother\`. Add the path to `brothers_path` in `battle_scene.tscn`.                                                |
| Add an enemy                               | Drop a `.tres` `Enemy` resource stats file (template at `.\Godot\Scripts\Enemies\Enemy_Goomba.tres`). Add an `EnemyUnit` scene in `battle_scene.tscn` (point `stats` to the resource).                 |
| Make that enemy act differently           | Subclass / write a new script with the same interface as `.\Godot\Scripts\Enemies\goomba_behavior.gd`. Assign it to `EnemyUnit.enemy_behavior` in the inspector.                                        |
| Add a new attack (hammer variant, etc.)   | `.\Godot\Scripts\manual_animations.gd` (`_hammer_manual_animation`, `_hammer_excellent`, `_hammer_good`, `_hammer_bad`, `_jump_manual_animation`). Update `jump_process` wiring in `game.gd`.           |
| Add an item                                | Texture under `.\Godot\Assets\UniqueItem\`. Stats resource (sample at `.\Godot\Assets\mushroom.tres`). Entry in `.\Godot\Scripts\item_list.gd`.                                                          |
| Add a new map / overworld area            | Create a `.tscn` mirroring `.\Godot\Scene\overworld_test.tscn`. Place your `MarioOverworld` + `LuigiOverworld` and link `luigi_np` / `mario_np` at the inspector. Save in `.\Godot\Scene\`.              |
| Add story dialogue                        | `.\Godot\Nodes\Textbox.tscn` (uses `Textbox.gd`). Connect to your scene's trigger area.                                                                                                                 |
| Save / load                                | `.\Godot\Scripts\Utility\PlayerSaveData.gd` (writes to `user://save1.dat`).                                                                                                                             |
| Connect multiplayer                       | `.\Godot\Scripts\Multiplayer\Multiplayer_node_logic.gd` + `multiplayer_ui.gd`. Port `9999`, default IP `127.0.0.1`.                                                                                     |
| Hook Steam                                 | `.\Godot\Scripts\SteamCheck.gd` (uses the GDExtension under `.\godotsteam\`).                                                                                                                            |

---

## 8. Debugging cheatsheet

- Add a live value to the debug HUD:
  ```gdscript
  Debugger.add_text("my_thing", "My Thing")
  Debugger.modify_text("my_thing", str(get_global_position()))
  ```
  open the `Debugger` autoload's panel while playing (top-left, by default).
- In `game.gd`, **`is_debug = true`** enables test inputs (`Test2`–`Test9`) wired in `_input_debug`.
- For physics / movement iteration, fiddle with `SPEED` / `JUMP_VELOCITY` on the `OWCharacterMovement` resource. The base class is shared by Mario & Luigi.
- The `addons/debug_draw` plugin is enabled — `DebugDraw3D` lets you `draw_sphere` / `draw_line` while prototyping.

---

## 9. Known TODOs and design intent (the "near-future")

The codebase carries **explicit TODOs** for the things the team is building toward next:

### Battle system milestones (see `.\Godot\Scripts\game.gd`)

- After a Brother finishes their action, the enemy should attack **using a chosen pattern** that makes sense given the situation (low HP → healer, has BP → special, etc.). Hook: `game.gd::_enemy_take_turn(enemy)`. Today this is a stub.
- Player defending window: between enemy telegraph and enemy hit, the player should be able to time a counter / shield (`manual_animations.gd::jump_check_hit` is the existing timing-window helper — reuse the same pattern).
- KO rewards and XP/coin distribution on `actor_defeated` (`_on_actor_defeated` in `game.gd`).
- Status effect ticks at round start (`_on_round_started` in `game.gd`).

### Overworld milestones

- Cosmetics + room decoration economy (coins, *Mushroom Tokens*). Data resource model lives under `.\Godot\Scripts\Utility\UniqueItem.gd`.
- NPCs as characters (Discord team NPCs are planned). Triggers will likely be `Area3D`-based, similar to overworld blocks (`ow_block.gd` / `overworld_block.gd`).

### Multiplayer / Steam milestones

- ENet host/join works in `Multiplayer_node_logic.gd`, but `add_player_character` lacks the proper per-player biography pieces.
- Steam friends list is shown in `SteamCheck.gd`, but credentials / `steamInit` are stubbed with the placeholder AppID `480` (Spacewar). Replace with real AppID before shipping.
- Cosmetics unlockable via Steam inventory is a future target.

### Asset milestones (per `.\README.md`)

- Custom Mario/Luigi sprites: 0.1% complete (3/??? sprites).
- Maps: 0.1% complete (1/???).
- Font customizability: 0% complete.

---

## 10. Quick "I just want to run it" recap

1. Open the project in Godot **4.7.1** (`.\project.godot` is the entry point).
2. Set `is_debug = true` in `battle_scene.tscn` (or any battle root) if you want to use test buttons.
3. Press F5 → the main scene is `res://Godot/Scene/title.tscn` (set in `project.godot`[application] → `run/main_scene`).
4. To get into battle quickly, run `battle_scene.tscn` directly (F6 on the scene).
5. Add `Debugger.add_text(...)` calls in your script to keep tab on what your code is doing.

---

For deeper, file-by-file explanations, see the companion wiki at `.\ENGINE_WIKI.md`.
