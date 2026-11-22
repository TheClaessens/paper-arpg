# 04: The shortest Cooldown

**What to build:** No Cooldown runs shorter than 0.1 s, however short Modifiers make it: a held Attack activates at most 10 times a second. A constant `Skill.SHORTEST_COOLDOWN := 0.1`, and `start_cooldown` starts `maxf(seconds, SHORTEST_COOLDOWN)`. The Snapshot keeps the Cooldown its Modifiers made. `test_it_runs_its_own_cooldown` moves to a 0.2 s Cooldown, since its 0.05 s now runs 0.1 s. The glossary's Cooldown, two lines of the skill-tags spec and the `cooldown` export's doc say so. Last on purpose: dropping or retuning it touches nothing of tickets 01 to 03. See `.scratch/number-bounds/spec.md` (rule 4; The change, file by file › `skills/skill.gd`; Docs this reopens; open rules 7 and 8; Deferred).

**Blocked by:** the developer's answers to open rules 7 and 8 in the spec (the value, or dropping the ticket).

**Status:** ready-for-agent

**Files:** `skills/skill.gd` (a constant after `:22`; the doc at `:39`; `start_cooldown` at `:68-71`), `tests/test_skill.gd` (a new test after `:83`; `:98-102`), `GLOSSARY.md:112`, `.scratch/skill-tags/spec.md:34` and `:60`.

**Tests:** new `test_no_cooldown_runs_shorter_than_the_shortest`, written first: on `master` the Cooldown starts at 0 and the Skill activates again at once. Changed `test_it_runs_its_own_cooldown`: 0.05 s and 6 physics frames become 0.2 s and 15.

- [ ] A Skill whose Modifiers took its Cooldown to 0 starts a Cooldown of `Skill.SHORTEST_COOLDOWN`, can't be activated again at once, and its Snapshot still says 0.
- [ ] `test_it_runs_its_own_cooldown` passes with 0.2 s and 15 frames; every other test passes unchanged.
- [ ] `GLOSSARY.md`'s Cooldown and the skill-tags spec's lines 34 and 60 read as the spec gives them.
- [ ] `tools/check.sh` passes; checked once in game as the spec's "Checking by hand" says.
