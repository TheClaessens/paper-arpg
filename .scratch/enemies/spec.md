# Enemies

Status: ready-for-human

README step 2, movement behaviour of basic Enemies only. Agreed in a grilling session on 2026-11-16. Built; functional test passed 2026-11-16. Crowding setup still to pick. Step 1's open items (controller pass, tuning, shimmer) stay open: controller testing happens after this step.

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
   - **Reach:** stops at `reach_distance` 1.0 from the player and chases again only past `resume_distance` 1.3 (both `@export`). While stopped it plays `idle` and faces the player.
   - Plays `walk` and faces its velocity while moving.
   - The reach/resume rule is a small pure function with a GUT test in `tests/test_enemy.gd`.
6. **Zombie** `characters/enemy/zombie.tscn`: an `Enemy` root with a capsule, the Standee (zombie frames), `Movement` (speed 2.5), `NavigationAgent3D` and `Aggro`.
7. **Placement.** Hand-placed in `sandbox.tscn`: a pack of 5 in the hall, single zombies in the dead-end corridor and the detour room. The old bare-`Node3D` zombies are replaced.
8. **Console commands.**
   - `aggro` toggles every Enemy's Aggro ring. `Aggro` registers it.
   - `nav` toggles every agent's current path.

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
- **`Aggro` registers the `aggro` command,** not the Console: systems add their own commands. The first Aggro to arrive registers it, with a static callback, so `help` lists it only once an Enemy exists.
- **The Aggro test uses real physics:** bodies on the `player` and `enemy` layers step into the sphere. It checks the layer mask and the radius, not just the signal code.
- **Grid cells span `[x, x+1]`,** not `x ± 0.5`. Commit 1 placed the wall rocks flush with the wall; commit 3 moves them (and the wall barrels) half a tile out, so the 0.5 gap exists.
- **Without avoidance the Enemy moves itself.** With `avoidance_enabled` off the agent never emits `velocity_computed`, so the Enemy calls its own handler (the pattern from Godot's docs).
- **`path_desired_distance` 0.1.** At 0.5 an Enemy counted a corridor corner as reached 0.3 early, aimed past it and pushed into the wall.
- **`path_height_offset` 0.2.** Path points sit on the baked floor at y 0.2 (see above). Without the offset an Enemy at y 0 is never within 0.1 of a point and stops. It must match the floor's baked height if the navmesh settings change.
- **The agent's `max_speed` follows `Movement.speed`,** set in `_ready`, so the speed is tuned in one place.
- **A standing Enemy skips `move_and_slide()`.** Run with zero velocity it still pushes the Enemy out of everything pressing into it, and a pack arriving behind shoved the first arrivals onto the player (0.5 instead of reach 1.0).
- **`avoidance_priority` 1.0 while within reach, 0.5 while chasing.** Avoidance is reciprocal: a standing Enemy stepped aside for arrivals and drifted onto the player. An agent ignores agents of lower priority, so chasers now walk around the ones standing.
- **The target is set only while chasing,** not every frame: a standing Enemy has no path to follow.
- **`nav` reaches only the agents present when it runs.** Enemies added later don't show paths until it's toggled again. Fine while Enemies are hand-placed.
- **The one-tile corridor is a dead end off the hall,** at x 18. It first doubled as the detour route, so its idle zombie blocked the detour zombie for good (see Findings).
- **Crowding is two settings,** `enemy_avoidance` and `enemy_collision` (both on), so the setups can be compared live: `set enemy_avoidance off`. Each Enemy applies them on `_ready` and when `Settings.changed` fires; the zombie scene no longer sets avoidance itself.
- **`nav` draws paths only.** The navmesh draws only when navigation debugging is on from launch (Debug > Visible Navigation in the editor, or `--debug-navigation`); scripts can't switch it.

## Findings

Measured in headless runs with the player standing still. Positions after 6 s, distances to the player.

- **Pack of 5 in the hall, crowding compared:**
  - *Both on (shipped):* the first three stop at reach (0.95–0.97). The other two queue behind them at 1.43 and do not walk round to the player's free sides.
  - *Collision only:* the same, with the back two grinding at 1.3–1.8.
  - *Avoidance only:* the same as both on; with collision off they could overlap but don't here.
  - *Neither:* all five stand on almost the same spot at reach.
- **An idle Enemy blocks a one-tile corridor in every setup.** Two bodies can't pass in a one-tile corridor, and avoidance won't push them through. Seen when the corridor was also the detour route; the corridor is now a dead end of its own. Level design should keep idle Enemies out of corridors others path through, until pack Aggro (the blocker would chase too).
- **The detour works:** the detour zombie notices the player through the wall, walks 27.8 for a 5.4 straight line and stops at 0.97.
- **The corridor zombie** walks out of its dead end to a player at the corridor mouth and stops at 0.97.

## Later

- Pack Aggro: one Enemy noticing the player wakes its neighbours. Also unblocks corridors (see Findings).
- Surrounding: Enemies queueing behind the front row could walk round to free sides of the player.
- Line of sight and leashing, if aggro through walls feels wrong.
- Wandering before Aggro.
- Enemy kinds (elites, bosses) and rarities.

## Open

- Crowding: watch the pack with each setup (`set enemy_avoidance on|off`, `set enemy_collision on|off`) and pick one.
