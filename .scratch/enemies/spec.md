# Enemies

Status: ready-for-agent

README step 2, movement behaviour of basic Enemies only. Agreed in a grilling session on 2026-11-16. Step 1's open items (controller pass, tuning, shimmer) stay open: controller testing happens after this step.

## Requirements

1. **Larger sandbox level.** `sandbox.tscn` grows (no separate test level). The GridMap and props are laid out by the agent and must contain:
   - an open hall, for a pack chasing in the open;
   - a one-tile-wide corridor, for Enemies queueing;
   - a room reached by a detour: close in a straight line, far by path (it also shows Aggro ignores walls);
   - a cluster of props to route around;
   - a gap exactly one body wide (the case that wedged the player in step 1).
2. **Physics layers.** Named layers `world`, `player`, `enemy`.
   - The player collides with `world` and `enemy`: Enemies body-block the player.
   - Enemies collide with `world`, `player` and `enemy`.
3. **Navmesh.** One `NavigationRegion3D` baked **in the editor** from the static collision, agent radius matching the Character capsule plus a small margin. Re-bake after editing the level: nothing catches a stale bake.
4. **`Aggro` component** (`Area3D`, `class_name Aggro`).
   - A sphere of the exported Aggro radius, masking only the `player` layer.
   - Emits `aggroed(target: Node3D)` the first time the player enters, then stops monitoring. Aggro never ends.
   - Trigger is distance only, no line of sight.
   - Owns a debug ring: a flat circle on the ground at the Aggro radius, hidden by default.
   - GUT test `tests/test_aggro.gd`: emits once on the player, never again, and ignores other bodies.
5. **`Enemy` script** (`characters/enemy/enemy.gd`, `class_name Enemy`, a `CharacterBody3D`, floating motion mode, `safe_margin` 0.02 as for the player).
   - Before Aggro: stands still on `idle`. No wandering.
   - On `aggroed`: chases the target. Each physics frame it sets the agent's target to the player, takes the direction to the agent's next path point, runs it through `Movement.next_velocity()`, and sends the result through the agent's avoidance (`velocity_computed`) before `move_and_slide()`. The same code works with avoidance on or off.
   - **Reach:** stops at `reach` 1.0 from the player and chases again only past `resume` 1.3 (both `@export`). While stopped it plays `idle` and faces the player.
   - Plays `walk` and faces its velocity while moving.
   - The reach/resume rule is a small pure function with a GUT test in `tests/test_enemy.gd`.
6. **Zombie** `characters/enemy/zombie.tscn`: an `Enemy` root with a capsule, the Standee (zombie frames), `Movement` (speed 2.5), `NavigationAgent3D` and `Aggro`.
7. **Placement.** Hand-placed in `sandbox.tscn`: a pack of 5 in the hall, single zombies in the corridor and the detour room. The old bare-`Node3D` zombies are replaced.
8. **Console commands.**
   - `aggro` toggles every Enemy's Aggro ring.
   - `nav` toggles navmesh drawing and every agent's current path.

## Commits

1. Larger sandbox level, named physics layers, navmesh bake.
2. `Aggro` component with its test, `aggro` console command.
3. `Enemy` script and `zombie.tscn` with the reach test, `nav` console command, zombies placed in the sandbox.

## Decisions

- **Navmesh over flow field.** Packs of 3–10, maybe 20–40 on screen; horde scale is not ruled out. A flow field would replace only the "where next" step; `Movement` stays.
- **Movement abilities for Enemies deferred,** like the player's Blink and Leap.
- **Hand-placed Enemies, no spawner.** Spawning waits for session and level structure.
- **`Aggro` is an `Area3D` component.** The physics engine reports the player, so the Enemy never looks it up, and every Enemy type reuses it.
- **No inherited enemy base scene.** One Enemy type; extract a base when the second one shows what they share.
- **Editor-baked navmesh.** No code. Upgrade path: runtime baking, chunked per room on a background thread, once levels are generated. Only the level changes; Enemies don't.
- **Crowding is decided by eye.** Ship with collision and avoidance (RVO) both on, then compare both / collision only (layer mask) / avoidance only (`avoidance_enabled`) in the hall and corridor. Record the outcome here.

## Decisions made during the build

- **The level layout is generated from floor rectangles.** Walls fill every cell next to a floor. A wall is half height when it stands between a floor and the camera (which looks from +x +z), so it never hides what is behind it. This rule reproduces the old room exactly.
- **The navmesh lives in `scenes/sandbox_navmesh.tres`.** A separate file keeps baked data out of `sandbox.tscn`'s diff. The editor's Bake button writes to it.
- **The navmesh parses meshes and collision shapes both.** Floor tiles have no collision, so meshes give the walkable floor; collision boxes make sure every prop and wall blocks, whatever its mesh looks like. Baking meshes needs the GPU: bake in the editor or a windowed run, never `--headless`, which bakes no floor.
- **Navigation cell size 0.1, cell height 0.1** (navmesh and project setting, which must match). At the default 0.25, an agent radius of 0.3 rounds up to 0.5 and closes one-tile corridors.
- **The floor bakes at y 0.2,** not 0: heights round up to the cell height. Enemies only use the path's direction on the ground, so it doesn't matter.
- **Wall and prop tops bake as islands.** Nothing can reach them; they show up in the `nav` drawing only.
- **The chest moved** out of the start room's new north doorway.
- **`Aggro` is a scene,** `characters/aggro/aggro.tscn`: the `Area3D` with its `Sphere` and `Ring`. Both resources are local to the scene, so each Enemy's radius is its own.
- **The ring is a thin `TorusMesh`,** unshaded, lying flat 0.02 above the floor.
- **One static `Aggro.rings_visible`** drives every ring. The `aggro` command flips it, and Enemies placed later pick it up too.
- **The Aggro test uses real physics:** bodies on the `player` and `enemy` layers step into the sphere. It checks the layer mask and the radius, not just the signal code.

## Later

- Pack Aggro: one Enemy noticing the player wakes its neighbours.
- Line of sight and leashing, if aggro through walls feels wrong.
- Wandering before Aggro.
- Enemy kinds (elites, bosses) and rarities.

## Open

- Crowding comparison (see Decisions).
