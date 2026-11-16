# Godot conventions

How code in this project is shaped. Follow these when writing or reviewing any GDScript, scene, or resource.

## Composition

A **component** is a child node with one job and its own `class_name` (e.g. `Standee` draws a character; a future `HealthComponent` tracks health and nothing else). Characters are assembled from components, and the same component serves the player and Enemies alike. Reach for a new component before an inheritance chain.

Components and anything outside them carry `GLOSSARY.md` names. A component's private child nodes may use plain engine words (Standee's `Card` and `Sprite`), since the glossary names domain concepts, not a component's inner parts.

## Call down, signal up

A parent calls methods on its children (`standee.play(&"walk")`). A child reports upward by emitting a signal and lets whoever cares connect to it. A child reaches its parent through signals, never through `get_parent()` or absolute node paths.

## Scenes live in the editor

Build scenes as `.tscn` files and expose tuning values with `@export`, so they can be inspected and tweaked in the editor. Code builds nodes at runtime only when the content is genuinely dynamic.

## Static typing

Enforced: `project.godot` treats untyped declarations and unsafe (unchecked) property access, method calls and call arguments as errors, so `tools/check.sh` fails on them. To type an autoload, give its script a `class_name` that differs from the autoload's name (`GameSettings` for `Settings`, `DevConsole` for `Console`). Test files may opt out of `unsafe_call_argument` with `@warning_ignore_start`, because their assertions compare Variant values.

## Autoloads

Autoloads are reserved for global services: `Settings` (runtime settings) and `Console` (developer console). Game state and gameplay logic belong in scenes and components.

Besides `help` and the Settings commands (`settings`, `get`, `set`), the Console holds only engine debug toggles (`collisions`, `nav`). A game system registers its own commands with `Console.register()` in `_enter_tree`, as `Aggro` does with `aggro` and `Player` with `tp`. The Console drops a command when the node that owns its callback leaves the tree, so registering in `_enter_tree` (not `_ready`) brings it back after a re-entry. A static callback has no node and stays until the game quits.

## Tests and checks

Logic with branches (parsing, validation, rules) gets a [GUT](https://gut.readthedocs.io) test in `tests/`, named `test_<subject>.gd`.

`tools/check.sh` loads every script and scene, then runs all tests; it exits non-zero on any failure. The pre-commit hook runs it once enabled per clone with `git config core.hooksPath .githooks`.

To check a change visually, `tools/screenshot.gd` opens a scene, runs console commands, and saves a screenshot after each one (usage in its header). To check behaviour without playing, `tools/simulate.gd` runs a scene headless after console commands and prints every Character's position once per second; `tp <x> <z>` puts the player where the test needs them.

A test that simulates a screen touch sends it with `get_viewport().push_input(event, true)`. Without `true` the position is read as window coordinates and lands somewhere else.

To try a change on the iPhone, `tools/deploy_ios.sh` exports, installs and launches the debug build. Its header lists the known failures and their fixes.

## Assets

Art comes from Kenney packs in `assets/kenney/<pack>/`. kenney.nl refuses scripted downloads, so ask the developer to download a new pack into that folder.

## Levels and navigation

- A GridMap cell (x, z) covers [x, x+1] × [z, z+1]; its centre is (x + 0.5, z + 0.5). Place props and Characters by that, not by the cell index.
- After editing a level, re-bake its navmesh with `tools/bake_navmesh.gd` (usage in its header). It needs a window: a `--headless` bake reads no floor meshes and bakes no floor.
- Navigation cell size and height are 0.1, in each NavigationMesh and in project settings, which must match. At 0.25 an agent radius of 0.3 rounds up to 0.5 and closes one-tile corridors.
- The floor bakes at y 0.2 (heights round up to the cell height), so each NavigationAgent3D has `path_height_offset` 0.2. Change one, change the other.

## API reference

The Godot 4.7 class reference is at docs.godotengine.org/en/4.7. `godot --doctool` output has no descriptions.
