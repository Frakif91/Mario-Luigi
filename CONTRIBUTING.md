# Contributing to Mario & Luigi: Hotel Mania

A short guide for people who want to help. Read this first; then skim `.\ENGINE_OVERVIEW.md` (the beginner tour) and `.\ENGINE_WIKI.md` (the file-by-file deep dive) before opening a PR.

The maintainer roster and project story are in `.\README.md`. Most coordination happens on the Discord linked there — come join before you sink a weekend into a feature someone else is already building.

---

## 1. Toolchain

- **Godot 4.7.1** exactly. Older 4.x builds will reject the project, newer builds may have rendering regressions.
- The project uses the **GL Compatibility** renderer (see `project.godot[application].config/features`). Sticking with this renderer matters because of the 3D-to-2D sprite trick used everywhere (see `.\ENGINE_OVERVIEW.md` §6).
- A C#-capable `.NET` build is configured (`project.godot[dotnet].project/assembly_name`), but the codebase is **purely GDScript today**. Don't introduce a mixed C#/GDScript dependency unless you're prepared to maintain both toolchains for everyone.

### First run

1. Clone the repo.
2. Open Godot → *Import* → pick `project.godot`.
3. Press F5. Main scene is `res://Godot/Scene/title.tscn` (set in `project.godot`).
4. To get into a battle quickly, open `battle_scene.tscn` and press F6.

### Local multiplayer

The project is set up to launch two windows (one host, one client) — see `project.godot[debug].multirun`. `multiplayer_node_logic.gd` listens on port **9999** by default; the second window lets you hit it with `join`. That is the only multiplayer test path today.

---

## 2. Codebase orientation

| I want to…                                  | Open                                                                                                   |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| See the high-level tour                     | `.\ENGINE_OVERVIEW.md`                                                                                 |
| Understand a particular file                | `.\ENGINE_WIKI.md`                                                                                     |
| Add an enemy / boss                         | `.\Godot\Scripts\Enemy.gd`, `EnemyUnit.gd`, `Enemy_Behavior.gd`, `Scripts/Enemies/goomba_behavior.gd`   |
| Add a bros attack                           | `.\Godot\Scripts\manual_animations.gd` (`Actions`), then wire it from `game.gd._input_*`               |
| Add an item                                 | `.\Godot\Scripts\Utility\UniqueItem.gd`, `ItemQuantity.gd`, `item_list.gd`, `item_template.gd`         |
| Add an overworld area                       | Mirror `.\Godot\Scene\overworld_test.tscn`; place Mario/Luigi prefabs from `Godot/Nodes/Brother/`      |
| Tweak camera / transitions                  | `.\Godot\Scripts\BattleCamera.gd`, `Scripts\Utility/transitions.gd`, `CameraTransform.gd`             |
| Touch combat flow                           | `.\Godot\Scripts\TurnManager.gd`, `game.gd` — `_on_turn_started` is the canonical entry point          |

Folder colors in the editor match color codes set in `project.godot[file_customization]`. Purple = art, red = 3D-only, blue = audio/reusable-scene, green = top-level scenes, yellow = scripts. Keep new files in the right colored bucket so the editor stays scannable.

---

## 3. Style

- **GDScript only** unless you have a strong reason to introduce something else.
- **Naming**:
  - `PascalCase` for files (`MarioOverworld_Movement.gd`), `class_name`, autoload names.
  - `snake_case` for variables and functions.
  - Constants `SCREAMING_SNAKE`.
  - Enums `PascalCase` keys (`HAMMER`, `PLAYER_ACTION`).
  - Resources destined to be a `class_name` get `class_name X` at the top. If a script has both a class_name and is autoloaded, the autoload name wins for `Globals.foo`-style access from other scripts (`Globals.wait` not `globals.wait`).
- **Indentation**: match the file you're touching. This repo has historical mix between **tabs** and **spaces** — most modern files are tabs, but `.\Godot\Scripts\Utility\Brother.gd` and `CharacterInfo.gd` are spaces. Don't reformat wholesale; respect the file you're editing.
- **Static typing**: prefer typed vars (`var foo : int = 5`), typed function signatures, `: Array[EnemyUnit]` instead of plain `Array`. The codebase is moving toward stricter typing; new code should be strict from day one.
- **Comments**: code comments are mixed **English/French**. New comments in English are fine; French comments are fine if that's your working language. Don't machine-translate existing ones.
- **No silent field mutation**: prefer clamping through the setter (`hp` clamps to `[0, max_hp]` via its setter for both `Brother` and `Enemy`). If you add a new scalar with bounds, do the same.
- **Don't add emojis** to code, comments, scene nodes, or commit messages. The repo convention is intentionally clean.
- **No new autoload** unless you talk to the maintainer first. Autoloads are global; they're hard to take back.
- **No new dependency** on an unlisted `.gd` script or third-party addon without it being added to `addons/` and documented.

### Things the codebase deliberately trades off

- **Procedural animations win over AnimationPlayer curves** for bros actions — see `manual_animations.gd`. The original 3DS games did it procedurally and it's easier to tune mid-fight. Add new actions through `Actions`, not by recording AnimationPlayer tracks.
- **Event-driven combat flow** — the legacy per-frame polls have been replaced with `TurnManager` signals and `game.gd::_on_*` hooks. Add new hooks as new signals/slots, not as new `_process` code that re-polls state.
- **Real-velocity, real-collision movement** for both brothers (no tweening into position). This is intentional: Luigi must be able to physically get stuck so the leash in `MarioOverworld_Movement` is meaningful.

---

## 4. Bug reports and feature issues

Use GitHub Issues. Each issue should have:

1. **Reproduction**: the scene, the inputs, the expected vs. actual behavior.
2. **Where**: which file/function you suspect (cite it — even a guess helps). Cross-link the wiki section from `.\ENGINE_WIKI.md`.
3. **`is_debug = true` output** if debug bindings are involved (`game.gd::_input_debug`).
4. **Save/screenshot/video** if visual.

A minimum repro PR is worth more than a long prose issue.

---

## 5. Pull request workflow

There is no formal gating process today, so please be conservative:

1. **Open an issue first** for non-trivial changes (anything bigger than a typo, fix, or single-function tweak). Confirm the approach on Discord if it's a new feature.
2. **Branch off `main`** with a descriptive name: `fix/turn-queue-on-ko`, `feat/enemy-pattern-goomba`, etc.
3. **One concern per PR.** Mix unrelated changes in a single PR and reviewers won't be able to land anything.
4. **Touch as few files as possible.** If you're adding a feature, the loader mentions `TurnManager`, an `EnemyBehavior`, and possibly a new item def — that's already a lot. Resist scope creep.
5. **Do not reformat** files you didn't otherwise change. A whitespace-only diff makes reverts ugly.
6. **Self-review before requesting review**: open your own diff on GitHub and read top-to-bottom once. Catch the obvious things.
7. **No force-pushes** after a reviewer has started a thread; add commits instead.

### Commit messages

- Imperative mood ("Add Hammer B-rank animation", not "Added").
- 50-char subject, 72-char body wrap.
- Reference an issue number when relevant: `Add turn-start hook (#14)`.

---

## 6. Where help is most needed right now

The maintainer-flagged TODOs, in roughly priority order:

1. **Enemy pattern selection** — implement `game.gd::_enemy_take_turn` properly. Each enemy needs a `EnemyBehavior` subclass that:
   - Picks a target meaningfully (not random — high/low HP, threat, etc.).
   - Plays its own telegraph animation (mirror `manual_animations.gd::_hammer_manual_animation`'s phases).
   - Exposes a counterable hit window so the player can defend.
   - The TODO comment in `game.gd::_enemy_take_turn` explicitly calls out reusing `jump_check_hit`'s timing-window pattern.
2. **Player defending window** — wire up the `ENEMY_TELEGRAPH` / `PLAYER_DEFENDING` combat states already declared in `Utility/globals.gd`.
3. **KO rewards / XP / coins** — populate the empty body in `game.gd::_on_actor_defeated` for the enemy case.
4. **Status effects** — tick them at `game.gd::_on_round_started`.
5. **Save integration** — `PlayerSaveData.gd` is written and `_save_game` exists but no gameplay code calls it yet.
6. **Custom UI / fonts** — the bulletin's `MarioLuigi2.ttf` is the only one plumbed in. Multi-font customizability is 0% per `.\README.md`.
7. **Steam** — replace the placeholder AppID `480` in `.\Godot\Scripts\SteamCheck.gd` with the real one (or guard it for development builds).

Where things are polished enough that low-risk contributions still help:

- New `Enemy.gd` stats resources — `Enemy_Goomba.tres` is 288 B; mirror it for the 4–5 enemies listed in the README.
- `DialogField` arrays under `Textbox.tscn` — story is the long pole; any NPC dialogue you can write is welcome.
- Asset polish — sprite cleanup, audio normalization.

---

## 7. Asset rules

- Sprite-sheets ripped from official *Mario & Luigi* titles exist under `.\Assets\` (e.g. `Luigi Sprites.png`, `MarioOverworld.png`). They remain **for study/resemblance only** — don't redistribute them outside the repo and don't pretend they're yours.
- New assets: please add them under the right colored folder (`Assets/Sprites/`, `Assets/Music/`, `Assets/SFX/`, `Assets/Sound/`). Use the existing import presets (look at `.import` siblings for hints).
- Large files (GB-scale textures, music libraries) belong outside `Assets/` if possible — see `.\README.md` for the team's stance on disk size.

---

## 8. License and credits

- Repo license: see `.\LICENSE`.
- Team credits live at the bottom of `.\README.md`. Add yourself there if your contribution is non-trivial.
- The project is part of the **Dreambound Team** collective (see `.\README.md`); if your work would be relevant to other Dreambound fan projects, mention it in the PR.

---

## 9. Quick "first contribution" checklist

- [ ] Forked the repo, cloned locally.
- [ ] Opened `project.godot` in Godot 4.7.1 cleanly (no errors in console).
- [ ] Pressed F5 → reached title screen.
- [ ] Opened `battle_scene.tscn` → fought a Goomba end to end.
- [ ] Read `.\ENGINE_OVERVIEW.md` and skimmed `.\ENGINE_WIKI.md`.
- [ ] Picked something from §6 ("Where help is most needed").
- [ ] Opened an issue or Discord thread describing the change.
- [ ] Made the change on a feature branch.
- [ ] Self-reviewed the diff.
- [ ] PR description references the issue and explains how to test.

Welcome aboard.
