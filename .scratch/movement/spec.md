# Movement

Status: ready-for-human

README step 1, basic movement only. Built; waiting on the developer's controller pass. Blink, Leap and other movement abilities wait until abilities are designed. Agreed in a grilling session on 2026-11-15.

## Requirements

1. **Collision.**
   - The `wall` and `wall-half` items in the dungeon MeshLibrary get box shapes. Floors get none.
   - Each prop scene gets a `StaticBody3D` with a rough primitive shape (box or cylinder). No trimesh.
2. **`Movement` component** (`Node`, `class_name Movement`). It is shared by every Character: the player now, enemies in step 2.
   - It has exported `speed`, `acceleration` and `deceleration`, tuned in the editor. The starting ramp is about 0.05–0.1 s to full speed and stops slightly faster.
   - `next_velocity(direction, delta)` returns the velocity ramped toward `direction * speed`.
   - GUT test `tests/test_movement.gd`: it accelerates toward the target, caps at speed, and decelerates to zero.
3. **Player scene** `characters/player/player.tscn`.
   - The root is a `CharacterBody3D` with a `Player` script and floating motion mode: no gravity, stays at y = 0.
   - Its children are a capsule `CollisionShape3D`, the `Standee` (adventurer frames) and `Movement`.
   - In `_physics_process` it reads input, calls `movement.next_velocity()`, then `move_and_slide()`.
   - It plays `idle` when still and `walk` when moving, with the existing wobble.
   - It calls `standee.face(velocity)` while moving. When it stops, it keeps the side it last faced.
4. **Input.**
   - InputMap actions `move_left/right/up/down`, each bound to the left stick, WASD and the arrow keys.
   - `Input.get_vector()` with a deadzone of 0.2.
   - **Direction only:** any tilt past the deadzone means full speed (the vector is normalised).
   - Directions are camera-relative: screen-up maps to the ground through the camera's basis, not a hard-coded 45°.
   - No touch joystick yet. It comes in the playtest prep after step 3.
5. **Camera.** It hard-locks to the player: the existing `Camera` becomes a child of the `Player` instance in `sandbox.tscn` and keeps its offset. No code.
6. **Sandbox.**
   - The player instance replaces the bare `Player` node.
   - The zombies stay non-colliding `Node3D` + Standee until step 2.
   - The TEMP `anim` console command is removed.

## Commits

1. Collision shapes on wall tiles and props.
2. Player scene, `Movement` component with its test, input actions, camera follow, removal of `anim`.
3. Optional: pixel-shimmer fix (snap the camera to the texel grid), only if the shimmer bothers the developer on screen.

## Decisions

- **No `PlayerInput` component.** `Player` reads input itself; only one scene needs it.
- **Direction-only stick.** Chosen over proportional speed (Diablo IV's model) and walk/run thresholds. Switching to proportional later means dropping the normalisation.
- **Only `idle` and `walk`.** The run poses wait until speed is tuned.

## Decisions made during the build

- **Props are scenes.** Each prop is `props/<name>.tscn`: a `StaticBody3D` root with the Kenney model and a box shape. Wall tiles use the importer's physics option plus matching shapes in the MeshLibrary, so a re-export from `dungeon_tiles.tscn` keeps them.
- **`next_velocity(velocity, direction, delta)`.** It takes the current velocity instead of storing its own, so speed lost against a wall in `move_and_slide()` stays lost.
- **Physical WASD keys.** Bound by physical key, so they sit in the same place on AZERTY.
- **The deadzone lives in the Input Map.** Each `move_*` action has a 0.2 deadzone, and `get_vector()` uses it.
- **Running into a wall plays `idle`.** Once the velocity is zero, the walk stops.
- **`safe_margin` 0.02 on Character bodies.** The default 0.001 let the capsule wedge into a gap exactly its width (wall to rocks, 0.5) and stay stuck. With 0.02 it stops at the gap instead. Enemies get the same margin in step 2.
- **`sandbox.gd` deleted.** With `anim` gone it had nothing left.
- **`collisions` console command.** Added during the build to inspect the new shapes. It toggles collision shape drawing without reloading the scene. Shapes are drawn opaque pink (`debug/shapes/collision/shape_color`).
- **The console pauses the game while open.** Typing moved the player, because it reads the keyboard directly. Closing restores whatever pause state the game had before.

## Open

- Controller pass: check that up is up the screen, the walk/idle switch and the 0.2 deadzone.
- Tune speed, acceleration and deceleration with the developer.
- Pixel shimmer: not noticed on a keyboard pass. Revisit only if it shows up.
