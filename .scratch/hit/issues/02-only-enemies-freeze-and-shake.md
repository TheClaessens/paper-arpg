# 02: Only a Hit on an Enemy freezes and shakes the world

**What to build:** Plan.md decision 7, in `Hit.land()`. For each Hurtbox, before it takes the Hit, `land()` asks whether it is on the Enemies' layer (`hurtbox.collision_layer & Faction.layer(Faction.Id.ENEMIES) != 0`); the impact plays once, through the viewport of such a Hurtbox, only if the Hit landed on at least one of them. Asked before, because the killing Hit's death takes the Hurtbox off every layer inside `take_hit()`. `land()`'s doc becomes the spec's, and `hit_feedback.gd`'s class doc, `flash` doc and `play_impact()` doc say who plays what. Write the two tests first. Nothing changes in play today: only Enemies can be hit. See `.scratch/hit/spec.md` (rules 6 and 7; "How the impact is decided"; "The change, file by file" › `skills/hit.gd`'s `land()`, `skills/hit_feedback.gd`; open rules 4 and 5).

**Files:** `skills/hit.gd` (`land()` and its doc); `skills/hit_feedback.gd` (`:3-8`, `:12`, `:35`, docs only); `tests/test_hit.gd` (two tests at the end, `PlayerScene` and `HurtboxScene` preloaded).

**Tests:** new `test_a_hit_on_the_player_neither_freezes_nor_shakes_the_world` (a Player instance given a `hurtbox.tscn` instance before it enters the tree, physics off, a current `Camera3D` in the test) and `test_the_killing_hit_on_an_enemy_still_freezes_the_world` (its zombie added with `add_child_autoqfree`), as the spec's table says. The first fails before the change, the second passes before it and guards the order. Existing guards: `test_attack.gd`'s `test_a_swing_that_hits_two_enemies_freezes_the_world` (a Hit on Enemies still freezes), `test_projectile.gd`'s `test_a_fireball_hit_knocks_back_without_freezing_the_world`, `test_enemy_death.gd`'s `test_hit_feedback_plays_only_when_a_hit_landed`.

**Blocked by:** 01; open rules 4 and 5 (recommended: the killing Hit plays like any other; a pet's Hits are left to pets). Under open rule 4's option b, the layer is asked after `take_hit()` and the killing-Hit test asserts the time scale stays 1 instead.

**Status:** ready-for-agent

- [ ] `land()` reads each Hurtbox's layer before calling its `take_hit()`, and plays the impact once, only for a landing on the Enemies' layer.
- [ ] A Hit landed on the player's Faction leaves the time scale at 1 and the camera still; the killing Hit on a zombie freezes the world.
- [ ] `HitFeedback`'s code is unchanged; its docs read as the spec gives them.
- [ ] `tools/check.sh` passes.
