# 01: The ball lives in the world and lands its own Hit

**What to build:** The branch's first commit is `.scratch/ball-in-world/` with the `GLOSSARY.md` entries from the spec's "Docs this reopens" (Range, Pierce, Snapshot, Projectile speed, and Hit's new last sentence), as the working agreement asks. Then `Skill._add_to_world()` puts what a Skill leaves in the world beside its Character, and Fireball's ball carries its Hit, lands it itself and lives there: `Projectile.launch()` and `Projectile.hit` replace the properties Fireball set one by one and the `hit` signal; `LAUNCH_OFFSET` and `FLIGHT_HEIGHT` move from `fireball.gd` into the ball; Fireball's `_activate` becomes three lines and sets no `top_level`; the ball's movement gets the spec's `ponytail:` comment. The tests follow the ball and free the balls they throw. See `.scratch/ball-in-world/spec.md` (rules 1 to 4 and 9; "Where things in flight go"; "The change, file by file"; "Tests").

This ticket changes where the ball lives and who lands its Hit, nothing about how it flies. Until tickets 02 to 04:

- `launch()` sets `_flight` to its Hit's Range, so its centre flies the whole Range from where it starts, as after step 9. Its doc says "and flies until its centre has flown its Hit's Range." where the spec says "and flies until its front is its Hit's Range from `centre` (see GLOSSARY.md, Range).", and leaves out the spec's last sentence.
- `_physics_process` moves first, then frees the ball once `_flown` reaches `_flight`, as after step 9 (with `hit.snapshot` and `_direction` for `snapshot` and `direction`). The `ponytail:` comment goes above it now.
- `_on_area_entered` adds the Hurtbox to `_hurtboxes_hit` and then calls `hit.land({hurtbox: _direction})` without reading its answer, as after step 9 it emitted `hit`.
- The class doc is the spec's without "a Hurtbox its Hit misses doesn't count", and says "until it has flown its Hit's Range" where the spec says "until its front reaches its Hit's Range from the centre of the Character that threw it".

**Files:** `GLOSSARY.md` (Range, Pierce, Snapshot, Projectile speed, Hit); `skills/skill.gd` (`_add_to_world()` after step 9's `_hit()`); `skills/fireball/fireball.gd` (the class doc, `LAUNCH_OFFSET` and `FLIGHT_HEIGHT`, `_activate`); `skills/fireball/projectile.gd`; `tests/test_projectile.gd`; `tests/test_player.gd` and `tests/test_skill_bar_hud.gd` (an `after_each` each); any other test file whose tests throw a ball (`grep -n "Fireball\|press(1\|touch 2" tests/`).

**Tests:** `tests/test_projectile.gd`'s helpers and its thirteen tests (step 9's `test_a_piercing_ball_lands_its_throws_one_hit_on_both` among them) as the spec's table says, including the rewritten `test_a_fireball_hit_knocks_back_without_freezing_the_world`. New: `test_a_ball_whose_character_is_freed_mid_flight_still_lands_its_hit` and `test_an_enemys_ball_goes_into_its_level_and_goes_with_it`, written first: both fail on the base. The `after_each` that frees balls in `test_player.gd` and `test_skill_bar_hud.gd`.

**Blocked by:** None. The branch starts from step 9's (`hit`). Open rule 2 takes its recommended answer unless the developer says otherwise.

**Status:** ready-for-agent

No scene changes: `projectile.tscn` and `fireball.tscn` stay as they are.

- [ ] The spec folder and the glossary entries are the branch's first commit.
- [ ] `skill.gd` gains `_add_to_world()` with the spec's doc and `ponytail:` comment, and nothing else.
- [ ] `fireball.gd`: the spec's class doc and three-line `_activate`; no `LAUNCH_OFFSET`, `FLIGHT_HEIGHT`, `top_level`, `add_child` or `connect`.
- [ ] `projectile.gd`: no signal; `hit`, `_direction`, `_flight`, the two constants, `launch()` and the `ponytail:` comment; flight, end check and Pierce counting as above.
- [ ] The two new tests failed on the base and pass. The time-scale test failed once with Fireball's `FREEZES` set to true, then was reverted; the commit message or PR says so.
- [ ] Every test file whose tests throw a ball frees them in `after_each`.
- [ ] A search for `LAUNCH_OFFSET` and `FLIGHT_HEIGHT` outside `projectile.gd`, `.hit.connect`, `ball.snapshot`, `ball.direction`, and `get_child(0)` in `test_projectile.gd`, comes back clean in code and tests.
- [ ] `tools/check.sh` passes, and the game runs: a Fireball thrown in `scenes/game.tscn` hits a zombie as on the base.
