# 03: The `Stagger` component, and the hit lands in `Character`

**What to build:** `characters/stagger/stagger.gd`, `class_name Stagger extends Node`, with `start()`, `is_active()`, `next_velocity()` and the static `knockback_left()`: today's slide moved out of `enemy.gd`, except that a Stagger of 0 does nothing (open rule 1). `Character` gains `_stagger` (or null) and `_standee`, connects its Hurtbox's `hit_taken` to `_on_hit_taken()` (moved from `Enemy`), and gains `_slide()`. `Enemy._physics_process` starts with `if _slide(delta): return`. The zombie gets a `Stagger` node. Nothing changes in play. See `.scratch/character/spec.md` (rules 7-10; "The change, file by file" › `character.gd`, `stagger.gd`, `enemy.gd`, `player.gd`, `zombie.tscn` edit 2).

**Files:** new `characters/stagger/stagger.gd` and its `.gd.uid`; `characters/character.gd`; `characters/enemy/enemy.gd` (`:21-23`, `:32`, `:38`, `:51-55`, `:58-69`, `:73-75`, `:123-137`); `characters/player/player.gd:61`; `characters/enemy/zombie.tscn` (an `ext_resource` line after `:10`, a block after `:45`); `tests/test_enemy.gd` (`:31-37` leave); new `tests/test_stagger.gd` and its `.gd.uid`; `tests/test_character.gd`.

**Tests:** `test_enemy.gd:31-37` moves to `test_stagger.gd` as `Stagger.knockback_left`. New, as the spec's Tests table says: `test_a_whole_stagger_slides_exactly_its_knockback`, `test_a_frozen_frame_moves_nothing`, `test_another_hit_restarts_it`, `test_a_stagger_of_0_does_nothing` in `test_stagger.gd`; `test_without_a_stagger_a_hit_doesnt_push` in `test_character.gd`. The existing tests check the move: `test_skill.gd:29-35` (each zombie slides its 0.35), `test_attack.gd:35-49` and `test_projectile.gd:133-145` (knocked back), `test_enemy_death.gd` (the killing hit doesn't knock back).

**Blocked by:** 02; open rule 1 (its working answer, a, unless the developer says otherwise; under c, `start()` keeps today's 0.02 s floor and `test_a_stagger_of_0_does_nothing` says so).

**Status:** ready-for-agent

The scene edit is made in text and checked with the spec's scene check. After the commit the developer reloads the project.

- [x] `Stagger` and `Character` as the spec sketches them, doc comments included.
- [x] `enemy.gd` has no `_stagger_left`, `_stagger_time`, `_knockback`, `knockback_left`, `_on_hit_taken`, `_slide` or `_standee`; `player.gd` has no `_standee`.
- [x] The zombie has a `Stagger` node with its script and no `unique_id`; the scene check shows only its three lines.
- [x] A search for `Enemy.knockback_left`, `_stagger_left` and `_stagger_time` in code and tests comes back clean.
- [x] The new tests pass and `tools/check.sh` passes.
