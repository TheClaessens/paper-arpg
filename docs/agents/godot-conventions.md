# Godot conventions

How code in this project is shaped. Follow these when writing or reviewing any GDScript, scene, or resource.

## Composition

A **component** is a child node with one job and its own `class_name` (e.g. `Standee` draws a character; a future `HealthComponent` tracks health and nothing else). Characters are assembled from components, and the same component serves the player and Enemies alike. Reach for a new component before an inheritance chain.

The one base script is `Character` (`characters/character.gd`), the glossary's Character in code. `Player` and `Enemy` extend it and nothing extends them: an Enemy kind is a scene, not a script. It holds what makes something a Character (its Faction, its Modifiers, its Skills) and wires its components; behaviour stays in the components and in `Player` and `Enemy`. A script that extends another and has its own `_ready()` calls `super()` first: a subclass's `_ready()` replaces its parent's. A Character's Skills sit under its `Skills` node, a `Node3D` without a transform of its own, ahead of whatever activates them.

Components and anything outside them carry `GLOSSARY.md` names. A component's private child nodes may use plain engine words (Standee's `Card` and `Sprite`), since the glossary names domain concepts, not a component's inner parts.

## Call down, signal up

A parent calls methods on its children (`standee.play(&"walk")`). A child reports upward by emitting a signal and lets whoever cares connect to it. A child reaches its parent through signals, never through `get_parent()` or absolute node paths.

## Scenes live in the editor

Build scenes as `.tscn` files and expose tuning values with `@export`, so they can be inspected and tweaked in the editor. Code builds nodes at runtime only when the content is genuinely dynamic.

## Saved content

A scene or resource file holds only the values written in it, an enum as its number; every other value is the script's default. Both the saved numbers and the script's defaults are content, as much as the code:

- **An exported enum is only added to at the end.** `fireball.tscn` saves `aim = 2` and `spell_cooldown.tres` saves `kind = 1`; inserting, reordering or removing an entry changes what every such file says. Exported today: `Skill.Aim`, `NumberChange.Kind`, `TagChange.Kind`, `Faction.Id`.
- **A default is part of every file that doesn't set it.** Attack auto-aims only because `Skill.aim` defaults to `AUTO`; `pierce.tres` adds Pierce only because `TagChange.kind` defaults to `ADD`. Before changing a default, find the `.tscn` and `.tres` files that attach the script, or a script extending it, without a line for the property, and the scenes that instance those without overriding it. Write the old value into each one that should keep it, in the same commit as the new default.
- **Renaming or removing an export** leaves every file that sets it with a line the script no longer has. Change those files in the same commit.
- **A Skill tag is declared in `skills/skill_tag.gd`** before a scene or Modifier file writes it, and game code names it by its `SkillTag` constant, never as text.
- **A number's name means one thing on every Skill that has it**, because a Modifier file names a number without knowing which Skill has it. Name a number for what it is: how fast Fireball's ball flies is `Projectile speed`, so a Modifier on it can't change another Skill's unrelated speed.

`tests/test_content.gd` reads every Skill in every scene and every Modifier file, and fails on, among other faults, a tag that isn't declared, a number no Skill has, an empty effect and a Cooldown of 0 or less. It can't see enums, defaults or a renamed export: keep those by hand. A renamed number or tag it does catch, in a Modifier file that still names the old one.

## Static typing

Enforced: `project.godot` treats untyped declarations and unsafe (unchecked) property access, method calls and call arguments as errors, so `tools/check.sh` fails on them. To type an autoload, give its script a `class_name` that differs from the autoload's name (`GameSettings` for `Settings`, `DevConsole` for `Console`). Test files may opt out of `unsafe_call_argument` with `@warning_ignore_start`, because their assertions compare Variant values.

`Array.filter()` and `map()` return an untyped `Array`, even on a typed array. Assigning the result to a typed array, or passing it to a typed array's `append_array()`, fails the check. Loop instead, or use `assign()`.

## Autoloads

Autoloads are reserved for global services: `Settings` (runtime settings) and `Console` (developer console). Game state and gameplay logic belong in scenes and components.

Besides `help` and the Settings commands (`settings`, `get`, `set`), the Console holds only engine debug toggles (`collisions`, `nav`). A game system registers its own commands with `Console.register()` in `_enter_tree`, as `Aggro` does with `aggro` and `Player` with `tp`. The Console drops a command when the node that owns its callback leaves the tree, so registering in `_enter_tree` (not `_ready`) brings it back after a re-entry. A static callback has no node and stays until the game quits.

## Tests and checks

Logic with branches (parsing, validation, rules) gets a [GUT](https://gut.readthedocs.io) test in `tests/`, named `test_<subject>.gd`.

One test file: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`. (`-gtest` adds to the `.gutconfig.json` dirs and runs the whole suite.)

`tools/check.sh` loads every script, scene and `.tres` resource (outside `addons/` and `assets/`), then runs all tests; it exits non-zero on any failure. The pre-commit hook runs it once enabled per clone with `git config core.hooksPath .githooks`.

To check a change visually, `tools/screenshot.gd` opens a scene, runs console commands, and saves a screenshot after each one (usage in its header). To check behaviour without playing, `tools/simulate.gd` runs a scene headless after console commands and prints every Character's position once per second. To compare two runs, add Godot's `--fixed-fps 60`; positions still differ by up to 0.01 between runs. Give both the game scene, `res://scenes/game.tscn`: a Level's scene on its own has no player's Character and no HUD, so the commands below don't exist there. Commands that set the scene up:

- `tp <x> <z>` puts the player where the test needs them.
- `bar <slot> <skill|empty>` fills or empties a Skill slot.
- `activate <slot> [<x> <z>]` presses one, auto-aimed or aimed.
- `touch <slot> [<dx> <dy>]` taps or drags it like a finger.

Reach for these before writing a one-off check script.

A test that keeps a node's `_physics_process` from running calls `set_physics_process(false)` after `add_child`: a node whose script has `_physics_process` turns it back on when it becomes ready.

A test that simulates a screen touch sends it with `get_viewport().push_input(event, true)`. Without `true` the position is read as window coordinates and lands somewhere else. Pushed that way, a touch reaches a `SkillSlotButton` too; emitting its `touch_started`/`touch_moved`/`touch_ended`/`touch_lost` signals tests the HUD without one. The system reports a touch it took away as a release at a negative position; a test pushes one with `push_input(event, true)`, in viewport units.

To try a change on the iPhone, `tools/deploy_ios.sh` exports, installs and launches the debug build. Its header lists the known failures and their fixes.

## The open editor

The developer keeps the Godot editor open, and it writes files behind your back:

- **Pressing Play saves every open scene first** ("Save Before Running", Editor Settings › Run › Auto Save). A scene changed on disk while it was open gets overwritten by the editor's stale copy. Keep that setting off.
- **It doesn't pick up changes made outside it** until **Project › Reload Current Project**. Ask for a reload after changing scenes or scripts, and after switching branches.
- **It rewrites `.uid` files** when its uid cache disagrees with them, and reorders `project.godot` when it saves project settings.
- **It resaves files written outside it in its own format**, even while nobody touches it: it adds a `uid` to a hand-written `.tres` or `.tscn` and to its `ext_resource` lines, a `unique_id` to each node, and puts properties in its own order. Left uncommitted, this comes back after every checkout.

Before committing, read `git diff` for scenes the editor reverted. Stage files by name. When the editor's resave touches a file the branch changed, commit the resave once, on its own, so the file stops churning. Leave churn in files the branch didn't change out of the commit.

## Input and UI

- Godot's built-in `ui_accept` and `ui_cancel` come with keys only. This project's input map adds the controller's A and B, so menus work with a controller.
- HUD sizes are in viewport units, the base viewport being 648 tall. On an iPhone 17 Pro, 1 pt is about 1.6 units. Keep HUD elements inside `SafeArea.of(viewport)`.
- `Basis.scaled()` scales along the world's axes. To stretch a node along its own axis (a line's length), multiply by `Basis.from_scale()` instead.
- A touch control that follows a finger by its index (the Touch stick, a Skill slot's button) handles a lost finger. It lets go of the finger on `NOTIFICATION_APPLICATION_FOCUS_OUT`, and a release that is `canceled`, or at a negative x or y, is a lost finger: it only lets go, and never does what a lift would trigger (activate a Skill). Godot 4.7 on iOS reports a touch the system takes away as a release at a negative position with `canceled` false, before the focus loss or after it. The Touch stick's lift only lets go, so it needs no check; a Skill slot's lift activates, so its button checks (`SkillSlotButton._is_lift`). A control that stops with the game (the Touch stick) lets go on a pause; one that runs while paused (`process_mode` ALWAYS, its own or inherited, as the Skill slot buttons do) never gets `NOTIFICATION_PAUSED`, keeps following its finger, and the HUD decides what a lift does. Copy `test_a_touch_the_system_cancels_is_not_a_lift`, `test_a_release_marked_canceled_is_not_a_lift` and `test_losing_focus_lets_go_of_the_finger` from `test_skill_slot_button.gd`. The next touch control is the third, so it extracts the shared piece instead of making a third copy.

## Assets

Art comes from Kenney packs in `assets/kenney/<pack>/`. kenney.nl refuses scripted downloads, so ask the developer to download a new pack into that folder.

## Levels and navigation

- Each Level (see GLOSSARY.md) has a scene of its own, with a `Node3D` root holding its ground, walls, props, navmesh, light and Enemies. `scenes/sandbox.tscn` is the first.
- The game scene, `scenes/game.tscn`, is the main scene: the pixelated view, `World` with the player's Character and its camera, and the HUD. It instances the Level under `World`, after the player's Character, so the Characters take their physics steps in tree order and the player's Character steps before the Enemies, as it did before the split. The player's Character, the camera and the HUD belong to the game scene, never to a Level.
- No node path crosses between the two. Nothing in a Level holds a path or a reference to the game scene's nodes: what it needs from them it gets from physics (an Enemy learns where the player is through Aggro) or from its viewport (a Standee reads the camera with `get_viewport().get_camera_3d()`). No HUD element points into a Level.
- A GridMap cell (x, z) covers [x, x+1] × [z, z+1]; its centre is (x + 0.5, z + 0.5). Place props and Characters by that, not by the cell index.
- After editing a Level, re-bake its navmesh with `tools/bake_navmesh.gd` (usage in its header). It needs a window: a `--headless` bake reads no floor meshes and bakes no floor.
- Navigation cell size and height are 0.1, in each NavigationMesh and in project settings, which must match. At 0.25 an agent radius of 0.3 rounds up to 0.5 and closes one-tile corridors.
- The floor bakes at y 0.2 (heights round up to the cell height), so each NavigationAgent3D has `path_height_offset` 0.2. Change one, change the other.

## API reference

The Godot 4.7 class reference is at docs.godotengine.org/en/4.7. `godot --doctool` output has no descriptions.
