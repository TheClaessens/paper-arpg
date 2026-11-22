# 04: A ball that can't fly ends

**What to build:** A ball whose Projectile speed is 0 ends where it starts. `launch()` gives it a flight of 0 when its Hit's Projectile speed is 0 (`can_fly` in the spec's sketch), so the first check in its first `_physics_process` ends it. The end is decided by the Projectile speed at launch, never by the step: a hitstop makes every step 0, and a ball frozen by one must fly on afterwards. `launch()`'s doc becomes the spec's: "With a Projectile speed of 0, or a Range that ends inside it, it ends where it starts." See `.scratch/ball-in-world/spec.md` (rules 7 and 8; "The change, file by file" › `projectile.gd`; open rule 3).

**Files:** `skills/fireball/projectile.gd` (`launch()` and its doc); `tests/test_projectile.gd` (two new tests).

**Tests:** new `test_a_ball_with_no_projectile_speed_ends` (written first: it fails before the change, the ball never moving and never ending) and `test_a_ball_frozen_by_a_hitstop_flies_on_after_it` (a guard: it passes before and after, and fails if the end is tested on the step).

**Blocked by:** 03 (the same lines). Open rule 3 takes its recommended answer, a, unless the developer says otherwise.

**Status:** ready-for-agent

- [x] `launch()` reads as the spec's sketch; `_physics_process` is unchanged from ticket 03.
- [x] The two new tests pass; the first failed before the change; `tools/check.sh` passes.
