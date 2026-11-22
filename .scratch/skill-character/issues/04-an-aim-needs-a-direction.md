# 04: An Aim needs a direction; what a Skill does happens now

**What to build:** `try_activate()` refuses an Aim with no direction on the ground: after the Cooldown check, an Aim whose x and z are both zero (`Vector3(aim.x, 0.0, aim.z).is_zero_approx()`) prints `"%s: an Aim needs a direction on the ground." % name` with `push_error` and returns false, before any Snapshot or Cooldown. `try_activate()`'s doc gains "and nor does one aimed with no direction on the ground, which also prints an error". `_activate()`'s doc gains the sentence on the moment of activation and "with a direction". The Console's `activate 1 0 0` no longer swings. See `.scratch/skill-character/spec.md` (rules 5 and 6; open rules 1 to 4; "The change, file by file" › `try_activate`, `_activate`'s doc).

**Files:** `skills/skill.gd` (`:104-113`, `:128-133`); `tests/test_skill.gd` (a new test at the end).

**Tests:** new `test_an_aim_with_no_direction_on_the_ground_is_refused` (spec, New tests): an Aim of zero and one straight up, each refused with an error taken by `assert_push_error("direction on the ground")`.

**Blocked by:** 02; open rules 1 to 4 (their recommended answers unless the developer says otherwise; without open rule 1's confirmation, `_activate`'s new sentence is left out).

**Status:** ready-for-agent

- [ ] `try_activate()` reads: the assertion, the Cooldown check, the Aim check, then today's three lines.
- [ ] `_activate()`'s doc says what the Skill does happens in that call, at the moment it is activated.
- [ ] The new test passes; `tools/check.sh` passes.
