# 03: No Skill script can stop its Cooldown

**What to build:** The Cooldown runs on internal physics processing. `skill.gd`'s `_physics_process` (`:83-85`) goes, and in its place a `_notification()` switches internal physics processing on when the Skill is ready (outside the editor) and runs `cool_down(get_physics_process_delta_time())` on each internal physics frame, with the spec's comment above it. The class doc gains its clause "and no Skill script can stop it". Nothing changes in play. See `.scratch/skill-character/spec.md` (rule 4; "The change, file by file" › `:83-85`; "Process order"; engine facts 1 to 5).

**Files:** `skills/skill.gd` (`:4-8`, `:83-85`); `tests/test_skill.gd` (two new tests at the end, and a test-only Skill class beside `RecordingSkill`).

**Tests:** new `test_a_skill_with_its_own_physics_process_still_cools_down` and `test_a_cooldown_waits_while_the_game_is_paused` (spec, New tests). The pause test waits with `wait_physics_frames()`, not `wait_seconds()`, and unpauses before any assertion. Existing tests that check the Cooldown runs: `test_skill.gd`'s `test_it_runs_its_own_cooldown`, `test_player.gd`'s activation tests.

**Blocked by:** 02 (the new tests' Skills need a Character to activate).

**Status:** ready-for-agent

- [x] `skill.gd` has no `_physics_process`; its `_notification()` is the spec's.
- [x] The two new tests pass; `tools/check.sh` passes.
- [ ] In the game, a held Attack swings every 0.4 s and Fireball's slot sweep runs and flashes as before (or this is left to ticket 06).
