# 01: An Aim mode replaces the three settings on a Skill

**What to build:** Everything in `../spec.md` under "The change, file by file" and "Docs", plus tests 1 to 4. `AimMode` and its four files; `Skill` loses `Aim`, `aim`, `aims_at_spot` and `repeats_while_held` and gains `aim_mode`; Attack names `steer.tres`, Fireball `line.tres`; `SkillBar`, `Player`, `AimMarker` and `SkillBarHud` ask the mode. One commit: the old settings and their readers can't leave separately.

**Status:** done

**Done when:**

- [x] No `Skill.Aim`, `AIMED`, `aims_at_spot`, `ground_aim` or `skill.repeats_while_held` is left in code, tests or living docs.
- [x] Tests 1 to 4 pass; every other test passes, changed only as the spec says.
- [x] The swing and the ball print `master`'s checksums.
- [x] `tools/check.sh` passes.
