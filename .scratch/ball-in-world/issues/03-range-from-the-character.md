# 03: A ball's front reaches exactly its Range from the Character

**What to build:** The ball's front stops at its Range from the centre of the Character that threw it, and the physics step looks there before the ball ends. `launch()` sets `_flight` to the Hit's Range less `LAUNCH_OFFSET` less the ball's radius, read from its own `SphereShape3D` (9.35 for Fireball's Range of 10). `_physics_process` checks its end first, then moves, its last step shortened to end exactly at `_flight` (`minf`). A Range under 0.65 gives a flight below 0, which the first check ends before any move. Docs: `launch()`'s "flies until its front is its Hit's Range from `centre` (see GLOSSARY.md, Range). With a Range that ends inside it, it ends where it starts." (ticket 04 adds the Projectile speed), and the class doc's "until its front reaches its Hit's Range from the centre of the Character that threw it". See `.scratch/ball-in-world/spec.md` (rule 5; "The distances"; "The change, file by file" › `projectile.gd`, and why the end check comes first; open rules 1 and 3).

**Files:** `skills/fireball/projectile.gd` (`launch()`, `_physics_process`, the class doc); `tests/test_projectile.gd` (two new tests).

**Tests:** new `test_a_fireballs_front_reaches_its_range` (a zombie centred at 10.15: hit) and `test_a_fireball_never_touches_a_zombie_wholly_beyond_its_range` (centred at 10.35: untouched, and the ball gone), both with the player's own Fireball. Write them first: the second fails before the change; the first passes before and after, and fails if the end check comes after the move (try it once).

**Blocked by:** 02 (the same file). Open rule 1 takes its recommended answer, a, unless the developer says otherwise.

**Status:** ready-for-agent

- [ ] `_physics_process` reads as the spec's sketch: the end check, then one shortened step.
- [ ] `test_flies_along_its_direction_then_disappears_after_its_range` and the `_fire()` tests still pass with the shorter flight.
- [ ] The two new tests pass; the far one failed before the change; `tools/check.sh` passes.
