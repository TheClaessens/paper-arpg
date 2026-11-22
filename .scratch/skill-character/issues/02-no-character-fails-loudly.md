# 02: A Skill activated without a Character fails loudly

**What to build:** `try_activate()` starts with `assert(character != null, "%s has no Character: give it to one with Character.add_skill()." % name)`, and its doc gains "A Skill without a Character fails an assertion." Tests whose Skill never reaches its Character give it a stand-in kept out of the tree. Nothing changes in play. See `.scratch/skill-character/spec.md` (rule 3; open rule 5; "The change, file by file" › `try_activate`; "Tests" › the last two rows of the table, "Why a stand-in", "Added by earlier steps").

**Files:** `skills/skill.gd` (`:104-108`); `tests/test_skill.gd` (`_recording()`, `:63-68`, and a new test at the end); `tests/test_skill_bar.gd` (the header and `before_each`, `:1-27`); any other test file that activates a bare Skill (below).

**Tests:** `_recording()` sets `recording.character = autofree(Character.new())` before adding the Skill; `test_skill_bar.gd`'s `before_each` gives `sword` and `fire` one such stand-in, and its header says the stand-in owns them. Then `grep -n try_activate tests/`: every Skill activated without a Character, which earlier steps may have added (step 1's shortest Cooldown is a likely one), gets one the same way, or the player's own Skill if it hits something. New: `test_a_skill_without_a_character_fails_loudly` in `test_skill.gd` (spec, New tests).

**Blocked by:** 01; open rule 5 (recommended: an assertion, as written).

**Status:** ready-for-agent

- [x] The assertion is the first line of `try_activate()`, with the message above.
- [x] Every test that activates a Skill gives it a Character; `test_skill.gd`'s `before_each` Skill and `test_skill_slot_button.gd`, which never activate one, are unchanged.
- [x] The new test takes the error with `assert_engine_error("has no Character")` and finds no Snapshot and no Cooldown.
- [x] `tools/check.sh` passes.
