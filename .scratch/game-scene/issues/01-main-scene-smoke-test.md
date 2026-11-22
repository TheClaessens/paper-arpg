# 01: A smoke test of the main scene

**What to build:** First, the branch's first commit: `.scratch/game-scene/` (the spec and its tickets) with the Level entry in `GLOSSARY.md`, worded as in the spec's "Docs this reopens", item 1 (CLAUDE.md, working agreement). Then `tests/test_game.gd`, exactly as the spec's "Tests" gives it. It loads the main scene that `project.godot` names, puts it in the tree, runs one physics step, and checks three things: there is one player's Character, it is the game scene's own, and the Skill bar HUD and the pause menu reach it, and the pause menu the Skill bar HUD, through their node-path exports. Today nothing checks those exports: a path that leads nowhere loads as null without an error. The test is written against today's main scene, `scenes/sandbox.tscn`, before the split, so it guards the split in ticket 02. See `.scratch/game-scene/spec.md` (rules 1, 3 and 5; Tests; Engine facts 1, 7 and 10).

**Blocked by:** None. The open rules shape ticket 02.

**Status:** ready-for-agent

**Files:** `GLOSSARY.md` (a new entry after Aggro radius, `:31-33`), `tests/test_game.gd` (new). Nothing else.

**Tests:** `tests/test_game.gd`, alone: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gselect=test_game.gd -gexit`. It passes on today's main scene. To see it fail, break `scenes/sandbox.tscn:155` (the Skill bar HUD's `player`), then `:152` (the pause menu's `hud`), one at a time, as the spec says, and revert each with `git checkout -- scenes/sandbox.tscn`. Never commit a break.

- [ ] The branch's first commit holds `.scratch/game-scene/` and the Level entry, worded as in the spec.
- [ ] `tests/test_game.gd` is the spec's, line for line, and passes on today's main scene.
- [ ] With the Skill bar HUD's path broken, it fails on "the Skill bar HUD's player" and on GUT's unexpected error from `SkillBarHud._ready`; with the pause menu's `hud` broken, on "the pause menu's Skill bar HUD". The PR says so.
- [ ] If it fails on an engine error or warning that has nothing to do with the wiring, the message is reported, not hidden, and GUT's error tracking stays on (spec, Tests, "Needs a run").
- [ ] No other test changes; `tools/check.sh` passes.
