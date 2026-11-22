# 03: A test over every Skill and Modifier file

**What to build:** `tests/test_content.gd` reads every Skill in every scene and every Modifier file, and fails when one names a Skill tag or a number that doesn't exist. It walks the check's own files (`LoadAll.find_files("res://", ["tscn", "tres"])` through a `preload` of `tools/load_all.gd`). A file that doesn't load is a problem, never skipped. Each Skill is checked as the scene it sits in sets it, so a Character scene's overrides count. Modifier files are checked once every scene has given its Skills' numbers. The table of implied tags is checked last. One test collects every problem on one line and also fails when it finds no Skill or no Modifier file. Self-tests feed hand-made broken Skills, Modifiers and a table to the problem functions. The conventions gain "Saved content" (all its bullets but the last, which ticket 04 adds). See `.scratch/content-checks/spec.md` (rules 1–5; The change › `tests/test_content.gd`; Saved content today; Tests; Docs this reopens).

**Files:** `tests/test_content.gd` (new); `docs/agents/godot-conventions.md` (new "Saved content" section after "Scenes live in the editor").

**Tests:** the content test and its three self-tests, as the spec's Tests section describes. Breaks C1–C14 tried by hand, one at a time and reverted; L1 again, with the content test run alone (`-gselect=test_content.gd`).

**Blocked by:** 01 (`find_files`); 02 (`SkillTag`).

**Status:** ready-for-agent

- [x] The content test passes on today's content and finds Attack and Fireball in `attack.tscn`, `fireball.tscn`, `player.tscn` and `sandbox.tscn`, and both Modifier files.
- [x] Each of C1–C14 fails it with a problem naming the file, the place and the word; C2 fails for `player.tscn` and `sandbox.tscn` and not for `attack.tscn`.
- [x] L1 fails it too: "doesn't load", not skipped.
- [x] The self-tests give three problems for the broken Skill, nine for the broken Modifier, one for the broken table, and none for the well-made ones.
- [x] Every problem shows in `tools/check.sh`'s output (one `[Failed]` line, joined with `"; "`).
- [x] "Saved content" in the conventions reads as the spec gives it, without the number-name bullet.
- [x] No `@warning_ignore` is needed; if instancing a scene logs a warning that fails the test (spec, Needs a run 1), stop and report it.
- [x] `tools/check.sh` passes.
