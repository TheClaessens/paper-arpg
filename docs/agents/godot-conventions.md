# Godot conventions

How code in this project is shaped. Follow these when writing or reviewing any GDScript, scene, or resource.

## Composition

A **component** is a child node with one job and its own `class_name` (e.g. `Standee` draws a character; a future `HealthComponent` tracks health and nothing else). Characters are assembled from components, and the same component serves the player and Enemies alike. Reach for a new component before an inheritance chain. A scene inherits another in one case only: an Enemy kind inherits `characters/enemy/enemy.tscn`, so that a change for every Enemy is one edit (see "Enemy kinds"). The chain this section warns against would be a scene between the base and the Enemy kinds, a script per Enemy kind, or anything in the base that only some Enemy kinds want.

The base scripts are `Character` (`characters/character.gd`, the glossary's Character in code) and `Skill` (`Attack` and `Fireball` extend it). A base script is right when it is one level deep, stands for a glossary term that covers what extends it (Character for the player's hero and Enemies, Skill for Attack and Fireball), and holds identity and wiring, while behaviour stays in components and in the scripts that extend it. Anything else is a component. `Player` and `Enemy` extend `Character` and nothing extends them: an Enemy kind is a scene, not a script. A script that extends a base script and defines a function the base script also defines calls `super()` in it, unless it means to replace what the base does: in Godot 4 the subclass's function replaces the base's. `_ready()` is the example: `Player._ready()` and `Enemy._ready()` start with `super()`. The exception is `_notification`: the engine calls it on every script in the inheritance chain, base first, so never call `super()` in it, or the base's runs twice. `Skill` runs its Cooldown from `_notification`, so a Skill script may define `_physics_process()` freely: the Cooldown doesn't run there. A Character's Skills sit under its `Skills` node, a `Node3D` without a transform of its own, ahead of `SkillBar` in the scene so that a Skill's Cooldown runs before the Skill bar asks whether it is ready.

Components and anything outside them carry `GLOSSARY.md` names. A component's private child nodes may use plain engine words (Standee's `Card` and `Sprite`), since the glossary names domain concepts, not a component's inner parts.

## Call down, signal up

A parent calls methods on its children (`standee.play(&"walk")`). A child reports upward by emitting a signal and lets whoever cares connect to it. A child reaches its parent through signals, never through `get_parent()` or absolute node paths. A parent may hand a child a reference to what the child needs, as a Character hands itself to each of its Skills (`Skill.character`), and the child may use what it was handed. What stays ruled out is a child finding its parent by itself, with `get_parent()` or a path. A Skill uses its Character in three ways: it reads the Character's Faction to know what is hostile, its Hits name the Character as their dealer, and it puts what it leaves in the world beside the Character. A Skill puts a node in the world only through `Skill._add_to_world()`, never by adding it to another node itself.

## Scenes live in the editor

Build scenes as `.tscn` files and expose tuning values with `@export`, so they can be inspected and tweaked in the editor. Code builds nodes at runtime only when the content is genuinely dynamic.

## Saved content

A scene or resource file holds only the values written in it, an enum as its number; every other value is the script's default. Both the saved numbers and the script's defaults are content, as much as the code:

- **An exported enum is only added to at the end.** `fireball.tscn` saves `aim = 2` and `spell_cooldown.tres` saves `kind = 1`; inserting, reordering or removing an entry changes what every such file says. Exported today: `Skill.Aim`, `NumberChange.Kind`, `TagChange.Kind`, `Faction.Id`.
- **A default is part of every file that doesn't set it.** Attack auto-aims only because `Skill.aim` defaults to `AUTO`; `pierce.tres` adds Pierce only because `TagChange.kind` defaults to `ADD`. Before changing a default, find the `.tscn` and `.tres` files that attach the script, or a script extending it, without a line for the property, and the scenes that instance or inherit those without overriding it. Write the old value into each one that should keep it, in the same commit as the new default.
- **Renaming or removing an export** leaves every file that sets it with a line the script no longer has. Change those files in the same commit.
- **A Skill tag is declared in `skills/skill_tag.gd`** before a scene or Modifier file writes it, and game code names it by its `SkillTag` constant, never as text.
- **A number's name means one thing on every Skill that has it**, because a Modifier file names a number without knowing which Skill has it. Name a number for what it is: how fast Fireball's ball flies is `Projectile speed`, so a Modifier on it can't change another Skill's unrelated speed.

`tests/test_content.gd` reads every Skill in every scene and every Modifier file, and fails on, among other faults, a tag that isn't declared, a number no Skill has, an empty effect and a Cooldown of 0 or less. It can't see enums, defaults or a renamed export: keep those by hand. A renamed number or tag it does catch, in a Modifier file that still names the old one.

## Enemy kinds

Every Enemy kind (see GLOSSARY.md) is a scene that inherits `characters/enemy/enemy.tscn`, the base. The base holds what every Enemy needs: the nodes `character.gd` and `enemy.gd` look up by name (`Standee`, `Movement`, `NavigationAgent3D`, `Aggro`, `Hurtbox`, `Health`, `HealthBar`, `Skills`) and the body's `CollisionShape3D`, with the values every Enemy shares. Those names are a contract: renaming or removing one changes the scripts too. An Enemy kind can't delete, rename or move a node it inherits, so a node some Enemy kind might do without, such as a `Stagger`, is each Enemy kind's own. `character.gd` looks `Stagger` up by name too, so an Enemy kind that names its Stagger anything else is silently never staggered. An Enemy kind's own behaviour node and Skills will be added to that Enemy kind, not the base, when they exist. An Enemy kind sets any value the base leaves at its default: the zombie sets its Standee's frames (the base has none), its Movement's speed and its Health's maximum, and another could set the Aggro radius or the Health bar's height.

Enemy kinds are the one place a scene inherits, and it stays one level: an Enemy kind inherits the base itself, never another Enemy kind, and the base carries no script but `enemy.gd`. `tests/test_enemy_kinds.gd` fails on any scene but the base whose root is an Enemy and that doesn't inherit the base directly, or whose Standee has no frames.

To add an Enemy kind, in the editor:

1. Scene › New Inherited Scene…, and pick `characters/enemy/enemy.tscn`.
2. Double-click the root and name it after the Enemy kind.
3. Set `Standee`'s Frames, `Movement`'s Speed and `Health`'s Max Health. Each changed value shows a revert arrow back to the base's.
4. Unless the Enemy kind is never staggered, select the root and Add Child Node › `Stagger`. Its Skills go under `Skills`.
5. Scene › Save Scene As… `characters/enemy/<kind>.tscn`, then place it in a Level.

For Enemy kinds, a value set in the base is part of every one that doesn't override it, as a script's default is part of every file that doesn't set it (Saved content). Change the base after a reload if the files changed on disk ("The open editor"): an editor holding an old copy of the base writes it back, and every Enemy kind then inherits the old one. An Enemy kind's file lists only the base nodes it changes, each with its `index` and the base node's `unique_id`, and its own nodes in full. The base and an Enemy kind can be written as text in a working tree no editor has open; the editor then resaves them in its own format the first time it saves them, and that resave is committed once on its own ("The open editor").

## Static typing

Enforced: `project.godot` treats untyped declarations and unsafe (unchecked) property access, method calls and call arguments as errors, so `tools/check.sh` fails on them. To type an autoload, give its script a `class_name` that differs from the autoload's name (`GameSettings` for `Settings`, `DevConsole` for `Console`). Test files may opt out of `unsafe_call_argument` with `@warning_ignore_start`, because their assertions compare Variant values.

`Array.filter()` and `map()` return an untyped `Array`, even on a typed array. Assigning the result to a typed array, or passing it to a typed array's `append_array()`, fails the check. Loop instead, or use `assign()`.

## Autoloads

Autoloads are reserved for global services: `Settings` (runtime settings) and `Console` (developer console). Game state and gameplay logic belong in scenes and components.

Besides `help` and the Settings commands (`settings`, `get`, `set`), the Console holds only engine debug toggles (`collisions`, `nav`). A game system registers its own commands with `Console.register()` in `_enter_tree`, as `Aggro` does with `aggro` and `Player` with `tp`. The Console drops a command when the node that owns its callback leaves the tree, so registering in `_enter_tree` (not `_ready`) brings it back after a re-entry. A static callback has no node and stays until the game quits.

## Frozen frames

`HitFeedback` is the only game code that sets `Engine.time_scale`: a hitstop sets it to 0, and the last hitstop to end sets it back to 1. While it is 0, every `delta` is 0, so a component that divides by `delta` returns early on 0, as `Stagger.next_velocity()` does.

## Tests and checks

Logic with branches (parsing, validation, rules) gets a [GUT](https://gut.readthedocs.io) test in `tests/`, named `test_<subject>.gd`.

One test file: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_<subject>.gd -gexit`. (`-gtest` adds to the `.gutconfig.json` dirs and runs the whole suite.)

`tools/check.sh` loads every script, scene and `.tres` resource (outside `addons/` and `assets/`), then runs all tests; it exits non-zero on any failure. The pre-commit hook runs it once enabled per clone with `git config core.hooksPath .githooks`.

To check a change visually, `tools/screenshot.gd` opens a scene, runs console commands, and saves a screenshot after each one (usage in its header). To check behaviour without playing, `tools/simulate.gd` runs a scene headless after console commands and prints every Character's position once per second. To compare two runs, add Godot's `--fixed-fps 60` and turn off multi-threaded avoidance for the run (the `override.cfg` in `tools/simulate.gd`'s header); without it positions still differ by up to 0.01 between runs. Give both the game scene, `res://scenes/game.tscn`: a Level's scene on its own has no player's Character and no HUD, so the commands below don't exist there. Commands that set the scene up:

- `tp <x> <z>` puts the player where the test needs them.
- `bar <slot> <skill|empty>` fills or empties a Skill slot.
- `activate <slot> [<x> <z>]` presses one, auto-aimed or aimed.
- `touch <slot> [<dx> <dy>]` taps or drags it like a finger.

Reach for these before writing a one-off check script.

A test that keeps a node's `_physics_process` from running calls `set_physics_process(false)` after `add_child`: a node whose script has `_physics_process` turns it back on when it becomes ready.

A test that activates a Skill gives it a Character, as the game does: one of the player's own Skills (`player.get_node("Skills/Attack")`), or `add_skill()` on a Character in the tree. A Skill that never reaches its Character, such as one that only records its activations, may take a stand-in kept out of the tree: `skill.character = autofree(Character.new())`. One Player per test: a second registers the Player's Console commands again, and the Console's assertion fails the test. A ball a Skill throws lives beside its Character, not under it, so freeing the Character doesn't free the ball: a test file whose tests throw balls frees every `Projectile` left in its node in `after_each`, as `tests/test_projectile.gd` does, or they fly on into the next test.

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
- What a Skill leaves in the world, such as a ball in flight, goes beside its Character, by the rule in "Call down, signal up": the player's into `World`, where a Level change doesn't free it, and an Enemy's into its Level, which frees it with itself. Whatever changes Levels, at the second Level, must free the player's too.
- A GridMap cell (x, z) covers [x, x+1] × [z, z+1]; its centre is (x + 0.5, z + 0.5). Place props and Characters by that, not by the cell index.
- After editing a Level, re-bake its navmesh with `tools/bake_navmesh.gd` (usage in its header). It needs a window: a `--headless` bake reads no floor meshes and bakes no floor.
- Navigation cell size and height are 0.1, in each NavigationMesh and in project settings, which must match. At 0.25 an agent radius of 0.3 rounds up to 0.5 and closes one-tile corridors.
- The floor bakes at y 0.2 (heights round up to the cell height), so each NavigationAgent3D has `path_height_offset` 0.2. Change one, change the other.

## API reference

The Godot 4.7 class reference is at docs.godotengine.org/en/4.7. `godot --doctool` output has no descriptions.
