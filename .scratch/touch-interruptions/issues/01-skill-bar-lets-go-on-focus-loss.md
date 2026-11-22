# 01: The Skill bar lets go when the app loses focus

**What to build:** When the app loses focus, the Skill bar lets go of every slot it holds, as it already does on a pause. A key or mouse button held while the app loses focus is released by the engine without an event, so `Controls` never reports it and, on `master`, the Attack keeps repeating after a Cmd-Tab on the Mac. One more condition in `SkillBar._notification`, its comment, and the class doc comment. See `.scratch/touch-interruptions/spec.md` (rule 4; "The change, file by file" › `skills/skill_bar.gd`).

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

**Files:** `skills/skill_bar.gd`, line 11 and lines 72-75 only (the spec's Seams); `tests/test_skill_bar.gd`.

**Tests:** `test_losing_focus_lets_go`, appended after `test_pausing_lets_go` and shaped like it, with `bar.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)` in place of the pause. It fails on `master`: two activations instead of one.

**Done when:**

- [ ] After `NOTIFICATION_APPLICATION_FOCUS_OUT` a held repeating Skill isn't activated again; `test_pausing_lets_go` still passes.
- [ ] The class doc comment reads "Pausing, or the app losing focus, lets go of every slot.", and the `_notification` comment says why both let go.
- [ ] `tools/check.sh` passes.
