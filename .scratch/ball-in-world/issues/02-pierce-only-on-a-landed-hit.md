# 02: Pierce is spent only on a Hit that landed

**What to build:** The ball counts a Hurtbox toward Pierce only when its Hit landed on it. In `_on_area_entered`, `hit.land({hurtbox: _direction})` comes before the count, and its answer decides (step 9's `land()` says whether it landed on any): when nothing landed (the Hurtbox's Character died earlier in the same physics step), the ball returns without remembering the Hurtbox, and flies on. The class doc gains "a Hurtbox its Hit misses doesn't count". See `.scratch/ball-in-world/spec.md` (rule 6; "The change, file by file" › `projectile.gd`; "The ball's life", item 5).

**Files:** `skills/fireball/projectile.gd` (`_on_area_entered`, the class doc); `tests/test_projectile.gd` (one new test).

**Tests:** new `test_a_ball_flies_on_past_a_zombie_its_hit_missed` (spec, New tests): two balls thrown side by side at a zombie with 10 Health left, a second zombie behind it. Write it first: before the change it fails, `hits` being `[first]`.

**Blocked by:** 01.

**Status:** ready-for-agent

- [ ] `_on_area_entered` reads as the spec's sketch: the deletion check, the Hurtbox check, the landing, then the count.
- [ ] The new test failed before the change and passes after; every other test still passes; `tools/check.sh` passes.
