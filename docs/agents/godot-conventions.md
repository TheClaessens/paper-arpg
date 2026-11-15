# Godot conventions

How code in this project is shaped. Follow these when writing or reviewing any GDScript, scene, or resource.

## Composition

A **component** is a child node with one job and its own `class_name` (e.g. `Standee` draws a character; a future `HealthComponent` tracks health and nothing else). Characters are assembled from components, and the same component serves players and monsters alike. Reach for a new component before an inheritance chain.

## Call down, signal up

A parent calls methods on its children (`standee.play(&"walk")`). A child reports upward by emitting a signal and lets whoever cares connect to it. A child reaches its parent through signals, never through `get_parent()` or absolute node paths.

## Scenes live in the editor

Build scenes as `.tscn` files and expose tuning values with `@export`, so they can be inspected and tweaked in the editor. Code builds nodes at runtime only when the content is genuinely dynamic.

## Static typing

Type every variable, parameter, and return value (`var speed: float`, `func play(name: StringName) -> void`). Use `:=` only where the type is obvious from the right-hand side.

## Autoloads

Autoloads are reserved for global services: `Settings` (runtime settings) and `Console` (developer console). Game state and gameplay logic belong in scenes and components.

## Tests

Logic with branches (parsing, validation, rules) gets a [GUT](https://gut.readthedocs.io) test in `tests/`, named `test_<subject>.gd`. Run headless:

```sh
godot --headless -s addons/gut/gut_cmdln.gd
```
