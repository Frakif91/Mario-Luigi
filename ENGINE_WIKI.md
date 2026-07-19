# Engine Wiki — Mario & Luigi: Hotel Mania

A file-by-file walk-through of the essential code: purpose, key functions, what they call, what calls them. Pairs with the beginner-friendly `.\ENGINE_OVERVIEW.md`.

This file assumes you've read the overview first. Where code comments are in French, the explanation below is in English; both are preserved for fidelity.

---

## 1. Project entry point

### `project.godot`

The Godot project file. Notable sections:

- `[application]` — `name = "Mario & Luigi : Hotel Mania"`, `version = "1.2.5"`, main scene `res://Godot/Scene/title.tscn`. GL Compatibility renderer (`4.7`). Splash = `Assets/load.png`. Icon = `n_icon.png`.
- `[animation]` / `[rendering]` — `compatibility/default_parent_skeleton_in_mesh_instance_3d = true` (3D skeleton compatibility), VRAM compression on, MSAA 2D = on, `snap_2d_transforms_to_pixel = true`.
- `[autoload]` — `Globals`, `Transitions`, `Debugger` (explained below).
- `[debug]` — `multirun` configured: launches two windows, second one auto-launches with `listen join`. This is how multiplayer is iterated on locally.
- `[input]` — Maps for `Jump`, `Back`, `MarioButton`, `LuigiButton`, `MenuUp/Down/Left/Right`, plus debug `Test2`…`Test9` and `TestButton1` (digit-key based).
- `[file_customization]` — Folder colors used in the editor (purple/red/blue/green/yellow); reflects the disk layout described in the overview.

### `SceneProperties.gd`

Empty helper (not currently used by any visible scene). Exists as a project-level scene property stub.

### `.vscode/settings.json`

Hides Godot's auto-generated files (`*.import`, `*.uid`) from VS Code's explorer so the workspace looks clean.

### `.gitignore`

Ignores `.godot/`, `.import/`, `export.cfg`, `Movie.avi`, the `/build/` folder, and mono-specific noise files. Effectively excludes anything generated.

---

## 2. Autoloads (always-on singletons)

### `Godot/Scripts/Utility/globals.gd` (`class_name` not set; autoloaded as `Globals`)

The cross-scene glue. Anything that needs to survive a scene change lives here.

Key members:

- `signal item_have_been_choosed` / `eat_inventory_item(tex, _item)` / `finish_eating` / `heal_mario(hp)` / `hurt_mario(damage)` — emitted from various places, listened by `game.gd`, debug HUD, etc.
- `enum ACTIONS_BLOCKS { NONE = -1, HAMMER, JUMP, ITEM, FLEE, BROS }` — the player's currently selected action. Mirrors `BLOCKS_NAMES` in `choosecubes.gd`. The naming intentionally matches the order in `BLOCKS_NAMES` array; `JUMP` index `0` is the first selectable.
- `cur_action : ACTIONS_BLOCKS` — set whenever a choosecube block is selected (see `game.gd::hitting_block`).
- `Bros : Dictionary` — runtime map of `"Mario"` / `"Luigi"` to a `Brother` resource instance (stats). Populated in `_ready()` from `CharacterDefaultStats.create_character()`.
- `cur_brother : BrotherCB3` — pointer to the 3D character body currently playing their turn.
- `RPG : RPG_System` — inner class holding `combat_state`. Note: in disk there are **two** versions of this file (root `Scripts/globals.gd` was *preceded* by the file under `Scripts/Utility/`). They define slightly different `combat_turn` enums (`ENEMY_ACTION` in one, plus `ENEMY_TELEGRAPH` and `PLAYER_DEFENDING` in the newer `Utility/globals.gd`). The project autoload points to `Utility/globals.gd` (see `project.godot`) — the older root file is residual/legacy.
  - States walk: `PLAYER_CHOOSING → PLAYER_MENU (item) or PLAYER_SELECTING (jump/hammer) → PLAYER_ACTION → ENEMY_ACTION (today) / INTERRUPTION`.
- `trans_ready_time = 1.0` — small grace period battle waits after `Transitions` finishes before starting the queue.
- `wait(seconds)` / `next_frame()` — convenience timers; everyone uses these instead of `await get_tree().create_timer(...)`.
- `DIRECTION : Dictionary` — string helpers for 8 directions (`UP = N`, etc.).

### `Godot/Nodes/transitions.tscn` (autoloaded as `Transitions`)

The wipe screen. Backed by `Scripts/Utility/transitions.gd`.

- Loaded as the autoload, it adds a `child_entered_tree` hook so it always moves to the end of the draw order (stays on top).
- `start_loading(path, transition_type, scene_tree)` — plays a fill wipe, then uses `ResourceLoader.load_threaded_request` to async-load the target, then `change_scene_to_packed` to swap. While loading, a label updates with `Loading... N%`.
- `start_fake_loading()` — fake progress for testing the UI without a real scene load.
- `TransitionType` enum: `CIRCULAR` / `FILL` / `TOP_DOWN`.
- Called from many places, e.g. `SteamCheck.gd::_on_button_exit_pressed()` returns to `title.tscn` via this.

### `Godot/Scripts/Utility/Debugging.gd` (autoloaded as `Debugger`)

In-game debug HUD.

- `add_text(tag, placeholder)` — registers a new line.
- `modify_text(tag, text)` — updates an existing line.
- `delete_text(tag)` — removes a line.
- `debug_text : Dictionary` — the underlying store.
- Auto-instantiates `Godot/Nodes/Utility/debugging_scene.tscn` on enter-tree, which contains the `RichTextLabel` that renders everything.

This HUD is the recommended way to peek at runtime state — `print` doesn't go through this and may not surface in your window.

---

## 3. Utility scripts

### `Godot/Scripts/Utility/Brother.gd`

Defines `class_name Brother extends Resource`. The **stats resource** attached to each brother.

Exports:

- `character_name`, `hp`, `bp`, `max_hp`, `max_bp`, `attack`, `defense`, `speed`, `level`, `xp`, `xp_to_next_level`.
- `hp` is **clamped** on set/get to `[0, max_hp]` — so any damage code can just do `hp -= damage` without checking bounds.
- Animation override flags: `overrite_animation`, `can_jump`.
- `chooseblock_offset : Vector2`, `camera_position : Vector3`, `og_position : Vector3` — placement helpers used in battle.
- `action_button : StringName` — input map name. `&"MarioButton"` by default for Mario (overridden in `CharacterInfo.gd`).
- `enum states { IDLE, TIRED, KO }` + `update_state()` — derives a state from HP percentage (≤30% = TIRED, ≤0 = KO).
- `_init(name, _max_hp, _max_bp)` — initializer; the actual stats are filled by `CharacterInfo.create_character`.

### `Godot/Scripts/CharacterInfo.gd`

`class_name CharacterDefaultStats`. Factory for `Brother` instances.

- `enum available { MARIO, LUIGI, WARIO, WALUIGI, PEACH }` — only MARIO/LUIGI are fully initialized today; the rest are placeholders for future candidates.
- `create_character(chosed_character)` returns a configured `Brother` resource. The hardcoded stats roughly match Dream Team's starting Mario/Luigi.
- Called from `Globals._ready()` to populate `Globals.Bros`.

### `Godot/Scripts/Utility/CameraTransform.gd`

`class_name CameraTransform extends Resource`. A reusable preset (pos / rot / fov) for the battle camera.

- Constructor accepts `_pos`, `_rot`, `_fov`.
- Stored in `brother_camera_transforms` keyed by character or scene (`"OG"`, `"Mario"`, `"Luigi"`, `"T_ENEMY"` — see `battle_scene.tscn` exports) and applied to `BattleCamera.cur_transform`.

### `Godot/Scripts/BattleCamera.gd`

`@tool class_name BattleCamera extends Camera3D`.

- `@export var cur_transform : CameraTransform` — drives `position`/`rotation`/`fov` via `lerp` each frame.
- `camera_speed` — lerp speed.
- `@tool`-only editor override: when `on_editor_custom_transform` is true and in editor, uses `debugging_transform` so you can preview without running the game.
- `shake_camera(power, sec)` — short pseudo-random offset wiggle using a Timer + `Globals.wait(0.001)` loop. Used for hit feedback.

### `Godot/Scripts/Utility/PlayerSaveData.gd`

`class_name PlayerSaveData extends Resource`.

- `save_sys_version : int = 1024` (`1.0.0`).
- Tracks `online_username`, `money`, `playtime`, `playable_character[]`, `inventory_items[]`, `story_var`, `cur_world`, `cur_coordinate`.
- `_save_game(_args)` writes a `user://save1.dat` using `FileAccess.store_var` (one var per field).
- `_load_game()` reads it back and **asserts** the version before reading.
- Currently the save callsites are not yet wired into the gameplay loop — purely the data model.

### `Godot/Scripts/Utility/transitions.gd`

(Already covered above.) Worth restating: it is the **`Transitions` autoload's script**, which is a `Control` that draws over everything.

### `Godot/Scripts/Utility/loading_screen.gd`

A separate, simpler version of the loading screen as a `Control` with progress signals. Most of the actual scene-change work goes through `transitions.gd`; this file is the lighter alternative for inside-scene loading overlays.

### `Godot/Scripts/Utility/UniqueItem.gd`, `ItemQuantity.gd`

Resource types for inventory data.

- `UniqueItem` — a single item identity (texture, name, description).
- `ItemQuantity` — `UniqueItem` + quantity stack. Used by `item_list.gd`, `item_template.gd`, etc.

### `Godot/Scripts/Utility/Teleporter.gd`

Portable area-based teleport trigger (818 B). Connect any Area3D with this script and configure the target scene + coordinates.

### `Godot/Scripts/Utility/CamSlowFlo.gd` and `Utility/S2D_on_3D.gd`, `3D_to_2D.tscn`, `CharacterBody3D.gd`

Small helpers around camera/3D-to-2D projection used during prototyping.

### `Godot/Scripts/3DSpriteto2D.gd` (`ASprite3D_to_2D`)

A node script that holds both an `AnimatedSprite2D` and `AnimatedSprite3D` and lets you `play_both(...)` / `call_both(...)` so the same animation plays flat *and* in 3D simultaneously. Also flips its 2D sprite off-screen when the camera is behind it (so the 3D one shows).

Used as the rendering glue for characters that need to be visible from both perspectives (cutscenes, mini-maps, etc.).

---

## 4. Overworld movement

### `Godot/Scripts/OWCharacterMovement.gd`

Base class for overworld characters. `class_name OWCharacterMovement extends CharacterBody3D`.

- Owns: `SPEED = 5.0`, `JUMP_VELOCITY = 4.5`, `center_fall_anim_rspeed = 0.3`, current `state_direction`, `state_action`. Pulls gravity from ProjectSettings.
- `ACTIONS` dictionary: `JUMP = &"jump"`, `IDLE = &"idle"`, `WALK = &"walk"`. **Animation names are built as `action-direction-altsuffix`** — see `play_animation`.
- `ALTERNATIVE` enum: how the falling animation should switch frames based on vertical velocity.
- `_physics_process` applies gravity, then `_process_floor_transition` (sets `touched_floor`, `just_touched_floor`), then `_process_fall_animation_alt` (picks `jump_alt`).
- `update_action_and_direction(cur_direction, is_walking)` — given a 2D direction vector, computes the octant using `roundi(8 * angle / TAU + 4) % 8` then maps via `sorted_direction`. Mario and Luigi define different `sorted_direction` arrays because their sprite-sheets have different facing conventions.
- `play_animation(action, direction, alt)` — composes `action-direction-alt` strings and switches the `AnimatedSprite3D`'s frame, while preserving current frame/progress on `walk`→`walk` switches (to avoid "snapping" when direction changes mid-step).
- `try_jump()` — only fires if `is_on_floor()`.

Critical detail baked in by comments: the octant formula shifts BEFORE rounding, which prevents negative indices around 180° west — an old bug in `MarioOverworld_Movement`.

### `Godot/Scripts/MarioOverworld_Movement.gd` (`MarioOW_Movement` extends `OWCharacterMovement`)

Mario's overworld controller. **Plus** the "leash" logic for Luigi-follow.

- `signal did_move(position)`, `start_move`, `stop_move` — used by Luigi + footstep timer.
- `walk_sound_waittime = 12/20/2 ≈ 0.3` and `cur_right_foot` flag alternate between two `AudioStreamPlayer`s for left/right foot.
- The **`trail`** (`Array[Vector3]`) is recorded every `trail_sample_distance = 0.35` units of traveled distance. Cap is `trail_max_length = 20` points.
- When the trail is full, `_enforce_leash()` clamps Mario's `global_position` to within `trail_sample_distance` of `trail[-1]` using `Vector3.limit_length`. So Mario can wiggle but can't escape.
- Input is `ui_left/right/up/down` plus `Jump` action.
- `_handle_block_bumps()` emits `block_hit` on every `OW_Block` he bonks with his head while jumping.

**Why a leash?** In Dream Team Luigi was a co-op partner that could get physically stuck. Here: if Luigi is slow to consume the trail (because he's bigger, falls behind, or is blocked by terrain), Mario is held back. It's not a teleport — real velocity based follow keeps it readable.

### `Godot/Scripts/LuigiOverworld_Movement.gd` (`LuigiOW_Movement` extends `OWCharacterMovement`)

Reads `mario.trail[0]`, moves toward it (clamped to `SPEED`), pops the point on close-enough arrival (`arrival_threshold = 0.15`). Uses real `move_and_slide()` so collision matters. If Luigi can't fit through where Mario walked (colliders, gaps), he physically gets stuck — and that is exactly what makes the leash meaningful. Draws a `DebugDraw3D` sphere on each consumed trail point for visual debugging.

### `Godot/Scripts/OverWorld/ow_enemy.gd`

Defines an overworld enemy node with an `EnemyInfo` resource (a small preset that says "this enemy is stompable"). Place-in-world entity; no AI yet.

### `Godot/Scripts/overworld_block.gd` / `Enemies/Enemy_Group.gd` / `Enemy_Info.gd`

Tiny files: block-bumping interactions, enemy group holder, and overworld enemy info resource respectively.

### `Godot/Scripts/OWCharacterMovement.gd` (already above)

Note there are also **single-character** (`MarioOW_Movement`) and **multiplayer** (`MarioMOWM`, `LuigiMOWM`) variants in `Scripts/Multiplayer/`. Those import / extend the same base but add multiplayer-awareness. Use them for online sessions.

---

## 5. Battle scripts

This is where the bulk of the engine work lives.

### `Godot/Scripts/game.gd` — battle root controller

`extends Node3D`, is the script attached to the root of `battle_scene.tscn`. Even though its filename (just `game.gd`) is generic, it is battle-specific.

Responsibilities:

1. **Wiring** — `_ready()` resolves `brothers_path` and `enemies_path` (both exported dictionaries / arrays of `NodePath`s) into `brothers : Dictionary[String, BrotherCB3]` and `enemies : Array[EnemyUnit]`.
2. **State store** — sets `Globals.cur_action`, `Globals.cur_brother`, listens to `Globals.eat_inventory_item`.
3. **Subsystem composition** — instantiates `Actions` (`manual_animations.gd`) and `TurnManager`, adds them as children, connects their signals.
4. **Camera transforms** — exports a `camera_transforms : Dictionary[String, CameraTransform]` keyed by `"Mario"`, `"Luigi"`, `"T_ENEMY"`, `"OG"` (default).
5. **Animation offsets** — `animation_offsets : Dictionary[String, Vector2]` for things like `"idle"`, `"hammer"`, `"hammer_taking_out"`. Sprites get nudged in 2D to align Mario's hand with the choosecube.
6. **Chooseblock placement** — `chooseblock_global_of : Dictionary[String, Vector3]` controls where the choosecube sits relative to each brother.
7. **Damage popup** — `show_damage(damage, pos_in_3d, damage_type)` instantiates `damage_display.tscn` and adds it to the UI.
8. **Item eating** — `brother_play_eat_anim(texture, uniqueitem)` listens to `eat_inventory_item` and plays the eat animation via `jump_process.eat_animation(...)` (which is in `manual_animations.gd`).
9. **Turn hooks** — `_on_turn_started(actor)`, `_on_round_started()`, `_on_actor_defeated(actor)` (these are explicitly the **only** entry points to logic flow now — older per-frame combat code was migrated to be event-driven).
10. **Enemy turn stub** — `_enemy_take_turn(enemy)` is a documented stub: today it picks a random brother and applies `enemy.stats.attack` flat. The team is expected to plug in pattern selection + a player-defending window here.
11. **Targeting / pointer** — tracks `cur_enemy` / `cur_enemy_index`, moves a `Pointer` node in 3D. Switches with `MenuUp` / `MenuDown`.
12. **Debug inputs** — `_input_debug` listens for `Test3`/`Test4`/`Test5` to test hammer, enemy camera, victory anim etc. without going through `TurnManager`.

Combat state transitions written directly by this file (mostly inside `_input_*` and `hitting_block`):

```
PLAYER_CHOOSING             (default — choosecube visible)
   └── hitting_block("JUMP"|"HAMMER")   → PLAYER_SELECTING, hides choosecube, shows Pointer
   └── hitting_block("ITEM")            → PLAYER_MENU, shows item list
   └── hitting_block(other)             → InvalidSound + push_error
then:
   _input_jump_selecting / _input_hammer_selecting / _end_player_action
   → turn_manager.advance() → next turn (player or enemy)
```

Key entry-points summary:

- `func _ready`
- `func _process` — debug HUD updates
- `func _input`
- `func _on_turn_started`, `_on_round_started`, `_on_actor_defeated`
- `_input_jump_selecting`, `_input_hammer_selecting`, `_target_switch`
- `_end_player_action` — common reset for both jump & hammer
- `change_character(brother)`
- `set_visible_choosecube`, `hide_cubes`, `show_cubes`
- `hitting_block`, `changed_block`
- `brother_play_eat_anim`
- `show_damage`

### `Godot/Scripts/TurnManager.gd` — turn queue

A clean state machine wrapper, no scene dependency.

- `signal round_started`, `turn_started(actor)`, `actor_defeated(actor)`.
- `setup(brothers, enemies)` — call once in `_ready()`.
- `_start_new_round()` — composes `_brothers_ref + _enemies_ref`, calls `_remove_dead`, sorts by `_by_speed_desc`, emits `round_started` then `turn_started(first)`.
- `advance()` — `index += 1`; if past the end, starts a new round; emits `turn_started` on the new actor.
- `_remove_dead()` — iterates the queue, drops actors with `hp <= 0` (or `stats.is_dead()`) and emits `actor_defeated` for any it drops. Re-aligns the index.
- `_get_speed(actor)` — `BrotherCB3.bro.speed` (the resource field) or `actor.stats.speed`.
- `_is_alive(actor)` — `hp > 0` for players, `not stats.is_dead()` for enemies.

This is what replaced older per-frame polling. Any new combat flow hooks should be added as new signals/slots on this **or** new `_on_*` methods on `game.gd`.

### `Godot/Scripts/manual_animations.gd` — `Actions` node

A large procedural-anim helper. Currently the bulk of `game.gd`'s work is delegated here. Sub-regions (visible via `#region X` comments):

- **Shake** — `shake_object(node, power, sec)` for impact.
- **Jump manual** — `_jump_manual_animation(enemy_pos, enemy_sprite)`. Player walks (plays "walking"), then "jump-up-right", then ramps into the timing window. The runtime polls `animation_timer.time_left` to decide what step to do. Returns an `Actions.results` enum (`SUCESS`, `FAIL`, `GOOD`).
- **Hammer manual** — `_hammer_manual_animation(...)` plus `_hammer_excellent`, `_hammer_good`, `_hammer_bad` post-fx based on result.
- **Eat animation** — `eat_animation(sprite, sound, specialnode, power_application, item)` — used by item-based heals. Bound to `Globals.eat_inventory_item`.
- **Damage announce** — `result_todo(result)` triggers damage popup.

The timing-window helpers (`jump_minimal_window` etc.) are the **template for the future enemy-defend window** — the TODO in `game.gd::_enemy_take_turn` explicitly says to reuse this pattern.

### `Godot/Scripts/choosecubes.gd` — the iridescent action wheel

The spinning ring of choice blocks (JUMP / HAMMER / BROS. / FLEE / ITEM). Sits in 3D space and gets bumped by character bodies.

- Auto-discovers its `StaticBody3D` children in `_ready` and builds `original_positions`.
- `index_angle = 360 / blocks_nb` distributes blocks around the ring.
- `pos_offset` is animated toward `index_angle * cur_index` over `offset_speed` = 250 units/sec — this is the rotation animation.
- Selected block also bobs (`sin(deg_to_rad(int(choosen_floating_one_delta * 360)) % 360) * 0.02`).
- Inputs: `ui_left` / `ui_right` (block switch), and `Area3D.body_entered` triggers `hit_block` when the player bumps it.
- Signals: `change_block(index, direction)`, `hit_block`.
- `selected_block_name` / `selected_block_index` — exposed to `game.gd` via `@export`.
- `BLOCKS_NAMES` / `INT_EEE` arrays are explicitly commented as confusing. `INT_EEE = [1,2,3,4,0]` exists because block 0 (JUMP) sits at offset 4 of the visual ring (so when "JUMP" is selected, the floating block is at position index 1 in the visual ring). `INT_NAME = [0,1,2,3,4]` is the linear order. If you add new blocks, update both arrays **and** `BLOCKS_NAMES`.
- `set_global_transparence(transparence)` — applies a transparency value to each block's `MeshInstance3D`. Driven by `game.gd::event_caller` setter when `0 < id < 24`.

### `Godot/Scripts/HP.gd` / `damage_display.gd` / `Damage_Anouncer.gd` / `DamageAnouncerTexture.gd`

The HP number (canvas-style digits using `ImageNumber.gd`) and the floating damage popup (the "25!" style from the originals). All four call into the same coordinate: `game.gd::show_damage(damage, pos_in_3d, damage_type)` instantiates `damage_display.tscn`.

### `Godot/Scripts/Enemy.gd` and `EnemyUnit.gd` / `Enemy_Info.gd` / `Enemy_Group.gd`

- `Enemy.gd` (`class_name Enemy extends Resource`) — the stats resource used by an `EnemyUnit`. Fields: `enemy_name`, `hp` (clamped like `Brother`), `max_hp`, `attack`, `defense`, `speed`, `can_defend`, `xp_reward`, `coin_reward`, `is_dead()`.
- `EnemyUnit.gd` (`class_name EnemyUnit extends CharacterBody3D`) — the in-scene body that *holds* an `Enemy` resource (`@export stats : Enemy`) and is movable. Has `take_damage(amount)` and `is_dead()`. Also holds `enemy_behavior : Script` to plug a behavior script.
- `Enemy_Behavior.gd` (`@abstract class_name EnemyBehavior extends Resource`) — interface with `player_choosing_behavior()` and `attack(enemy)` to override.
- Subclass example: `Scripts/Enemies/goomba_behavior.gd` (`class_name GoombaBehavior extends EnemyBehavior`). Today it just picks a random alive player and has an empty `attack`. The `_jump_manual_animation` helper exists to mirror what the player has.
- Enemy stats resource template: `Scripts/Enemies/Enemy_Goomba.tres` (288 B, just references).

### `Godot/Scripts/Utility/DialogField.gd` + `Textbox.gd` + `Nodes/Textbox.tscn`

The 3DS-style dialog box.

- `DialogField` — a struct holding `text`, `text_size`, `text_delay`, `textbox_size`, `sfx`, `each_n_letters` (sound chirp every N chars).
- `Textbox.gd` shows fields one after another; per-character reveal uses `Label.visible_characters = letter`, with the SFX chopping every N letters. Waits for `ui_accept` between lines. `dialog_nextline.emit()` and `finished_dialog.emit()`.
- The script gracefully falls back: if the loaded scene IS the textbox, it auto-starts (debug mode), otherwise waits for the `show_dialog` signal.

### `Godot/Scripts/item_template.gd` / `item_list.gd`

UI for inventories:

- `item_template.gd` — single item slot.
- `item_list.gd` — inventory panel; can emit `Globals.eat_inventory_item` when used in battle, which triggers `game.gd::brother_play_eat_anim`.

### `Godot/Scripts/Shop.gd`

Marquee-style shop category buttons. Pure UI tween animations on hover (size_flags, modulate, custom_minimum_size). Wired into `Scene/shop_ui.tscn`.

### `Godot/Scripts/NPC.gd`

Tiny NPC node wrapper to drop into scenes for character dialogue triggers.

### `Godot/Scripts/CharacterBody3D.gd`

Project-local helper (`extends CharacterBody3D`) for general-purpose 3D bodies. (Note: the existing class `OWCharacterMovement` already inherits from the engine's `CharacterBody3D`, and `EnemyUnit` does too — so this project's file is mostly supplementary convenience.)

### `Godot/Scripts/Utility/CamSlowFlo.gd`, `S2D_on_3D.gd`, `dialog_field.gd`, etc.

Smaller helpers — see comments inline.

### `Godot/Scripts/SteamCheck.gd`

Steam integration via the GDExtension at `.\godotsteam\`.

- On startup calls `Steam.steamInit(true, 480)` (placeholder AppID 480 = Spacewar; **swap for your real ID before shipping**).
- Pulls the user persona name, fetches avatar via `Steam.getPlayerAvatar(...)` + `Steam.avatar_loaded` signal.
- Lists friends and colors them by `PERSONA_STATE_*` (uses the `persona_status_colors` dictionary).
- Has a button that exits to `title.tscn` via `Transitions.start_loading`.

### `Godot/Scripts/Multiplayer/*` — early ENet multiplayer

- `Multiplayer_node_logic.gd` (`class_name MultiplayerManager`) — owns an `ENetMultiplayerPeer`, exposed `PORT = 9999`, `ADDRESS = "127.0.0.1"`.
  - `_on_host_launch(port, username)` — `create_server`, registers a `peer_connected` callback that uses `rpc()` and `rpc_id()` to sync newly-joined players.
  - `_on_player_joining(ip, port, username)` — `create_client`.
  - `display_message(message)` is `@rpc("any_peer", "call_local", "reliable", 1)` so every peer renders incoming chat.
- `multiplayer_ui.gd` — input form for host/join + status panel that polls `multiplayer.multiplayer_peer.get_connection_status()` every frame.
- `multiplayer_entity.gd` / `multiplayer_info.gd` — server-spawned per-peer entity placeholder.
- `MarioMOWM.gd`, `LuigiMOWM.gd` — multiplayer-aware variants of the overworld controllers.

Iteration-friendly with the project's `multirun` config: launching two windows (one `listen`, one `join`) is the dev workflow.

---

## 6. Shaders

### `Godot/Shaders/object_transparency-see_through.gdshader`

Used by the edges of the battle arena so the choosecube behind a brother isn't clipped.

### `Godot/Shaders/screen_mask.gdshader`

Used by `entry_ui_*.tscn` for the curtained "walk into the battle" effect (the iridescent reveal).

### `Godot/Shaders/choose_enemy.gdshader`, `shop_ui.gdshader`, `screen_mask.gdshader`, `test.gdshader`

Currently 0-byte placeholders that exist as `.uid` files (Godot 4.7 generates UIDs even for empty shader slots). They will be filled in as features land.

---

## 7. Scenes (top-level layouts)

### `Godot/Scene/title.tscn`

Main menu / new game / continue. Set as `run/main_scene`.

### `Godot/Scene/battle_scene.tscn`

The big one (~1 MB). Root script is `game.gd`. Contains all the choosecube wiring, brothers' 3D bodies, enemy units, ratings animation player, item list, pointer — i.e. everything described above.

### `Godot/Scene/overworld_test.tscn`

The overworld test scene. Mario (`MarioOverworld.tscn`) + Luigi (`LuigiOverworld.tscn`) + various blocks. Their `luigi_np` and `mario_np` paths are set on each brother root.

### `Godot/Scene/cafe.tscn` (~4 MB)

The hotel-cafe prototype. UI + NPC slots.

### `Godot/Scene/shop_ui.tscn`

Shop system UI driven by `Shop.gd`.

### `Godot/Scene/loading_screen.tscn`

Standalone loading screen (slim version).

### `Godot/Scene/fake_loading_text_settings.tres`, `progress_bar_theme.tres`, etc.

Various cosmetic `.tres` resources.

---

## 8. Reusable node scenes

In `Godot/Nodes/`:

- `damage_display.tscn` — the pop-up `25!` damage number.
- `Textbox.tscn` — the 3DS-style dialogue box.
- `HP.tscn` + `HP.gd` — HP number label using `ImageNumber.gd`.
- `item_list.tscn`, `item_template.tscn` — inventory UI.
- `choosecubes.tscn` — the action wheel prefab.
- `controller_connected.tscn` — gamepad disconnect UI.
- `furniture.tscn` — placed in cafe/hotel scenes.
- `Brother/MarioOverworld.tscn` and `Brother/LuigiOverworld.tscn` — the overworld prefabs.
- `Transitions/transitions_circles.tres` and `transitions_fill.tres` — animation presets.
- `Entry_ui_in.tscn` / `entry_ui_out.tscn` — battle screen transitions.
- `fake_shadow.tscn` — the round shadow under battle characters.
- `loss_hammer.tscn` — ? (legacy?)
- `multiplayer_entity.tscn`, `multiplayer_ui.tscn` — multiplayer prefabs.
- `OW_Enemy.tscn`, `Ennemy Pointer.tscn`, `Ennemy Pointer.tscn` — battle helpers.

---

## 9. Addons

- `addons/anthonyec.camera_preview` — viewport preview for cameras (enabled editor plugin; see `project.godot[editor_plugins]`).
- `addons/debug_draw` — `DebugDraw3D` runtime API used by `LuigiOverworld_Movement` and `manual_animations.gd`.

---

## 10. Steam GDExtension

`godotsteam/` ships precompiled GDExtension binaries (`win32`, `win64`, `linux32`, `linux64`, `osx`) consumed via `godotsteam.gdextension`. Scripts that need Steam APIs (`Steam.isSteamRunning`, `Steam.steamInit`, etc.) call into this.

---

## 11. How the pieces connect (one-paragraph mental model)

On boot, `Globals._ready()` builds the Bros dictionary. `title.tscn` is the entry; pressing through loads `overworld_test.tscn` (or any future map). On encounter, `battle_scene.tscn` instantiates and its `game.gd::_ready` creates a `TurnManager` and an `Actions` node, wires their signals, and calls `turn_manager.setup(brothers, enemies)`. The `TurnManager` emits `turn_started(currentActor)`. For a player, `game.gd::_on_turn_started` calls `change_character(actor)` then `set_visible_choosecube()`. The player taps `Jump` or `B` against the choosecube (`hit_block` signal), which selects `cur_action` and transitions `Globals.RPG.combat_state` to `PLAYER_SELECTING`. The action button (`MarioButton`/`LuigiButton`) triggers `_input_jump_selecting` or `_input_hammer_selecting`, which delegates the procedural animation to `Actions._jump_manual_animation` / `_hammer_manual_animation`. Those return an `Actions.results`, which feeds `result_todo` and `_end_player_action`. `_end_player_action` resets flags and calls `turn_manager.advance()`, which either rotates to the next actor or starts a new round. For an enemy, `_enemy_take_turn` applies damage and calls `advance()`. Damage pops use `damage_display.tscn`. Outside battle, items are consumed through `Globals.eat_inventory_item ↔ game.gd::brother_play_eat_anim ↔ Actions.eat_animation`. The Debugger HUD shows whatever you choose to log via `Debugger.add_text`/`modify_text`.

The four points where you should **insert new functionality** rather than reinvent:

1. `TurnManager.gd` — when you need new round/timing semantics.
2. `Actions` (manual_animations.gd) — when you need a new procedural attack/bro action.
3. `EnemyBehavior` subclass — when you need a new enemy AI pattern (and you want it counterable, as the TODO comments require).
4. `CharacterDefaultStats` + `Brother` — when you add a new playable character.

See the overview file `.\ENGINE_OVERVIEW.md` for the beginner's summary and folder legend.
