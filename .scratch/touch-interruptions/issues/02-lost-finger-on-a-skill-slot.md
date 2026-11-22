# 02: A lost finger on a Skill slot activates nothing

**What to build:** A Skill slot's button reports a finger taken away without lifting with a new signal, `touch_lost`. It emits it on a release of its finger that is `canceled` or at a negative x or y (Godot 4.7 on iOS reports a touch the system cancels as a release at (-1, -1)), and on `NOTIFICATION_APPLICATION_FOCUS_OUT` while it has a finger. A lift still emits `touch_ended`. One finger never emits both, nor `touch_lost` twice, and after it is lost its moves and release are ignored.

The HUD connects `touch_lost` to a new `_let_go(slot)`, which ends the slot's hold and its aim and hides the aim marker, activating nothing. `_on_touch_ended` lets go through the same function before it activates an aim, so a real lift behaves exactly as before. A pause still loses no finger: the button doesn't handle `NOTIFICATION_PAUSED`, which it never gets.

The conventions gain the rule for the next touch control, and two specs get their new wording. See `.scratch/touch-interruptions/spec.md`: rules 1, 2, 3 and 5; "The change, file by file" › `ui/skill_slot_button.gd` and `ui/skill_bar_hud.gd`; "Tests" 2 to 7; "Docs this reopens" 1 to 4.

**Blocked by:** 01: The Skill bar lets go when the app loses focus (the aiming spec's new wording describes both).

**Status:** ready-for-agent

**Files:** `ui/skill_slot_button.gd`, `ui/skill_bar_hud.gd`, `tests/test_skill_slot_button.gd`, `tests/test_skill_bar_hud.gd`, `docs/agents/godot-conventions.md`, `.scratch/aiming/spec.md`, `.scratch/touch-controls/spec.md`. No scenes.

**Tests:** the spec's tests 2 to 7, appended at the end of each file. Tests 2 to 6 fail on `master`; test 7 guards today's pause behaviour through the reshaped `_on_touch_ended`. Simulate touches with `get_viewport().push_input(event, true)` (a new event each time), the iOS cancel as a release at `Vector2(-1, -1)`, and focus loss with `notification()` on the button or `propagate_notification()` on the HUD. In `test_skill_bar_hud.gd`, don't use `player.get_node("Fireball")` (the spec's Seams).

**Done when:**

- [ ] A release that is `canceled` or at a negative position emits `touch_lost`, not `touch_ended`; a release at a real point still emits `touch_ended`.
- [ ] Focus loss emits `touch_lost` once for a button that has a finger and nothing for one that hasn't; that finger's later drag and release emit nothing.
- [ ] Through the real buttons: Fireball dragged and then cancelled at (-1, -1) is not activated and the aim marker hides; a held Attack stops repeating after the HUD's focus loss, even when the thumb moves again.
- [ ] A lift during a pause still activates nothing, and every existing test in `test_skill_bar_hud.gd` passes unchanged.
- [ ] The button's and the HUD's class doc comments, the conventions (the "Tests and checks" paragraph on screen touches, and the new last bullet of "Input and UI"; find both by their text, since `content-checks` moves their lines), `.scratch/aiming/spec.md:64` and `.scratch/touch-controls/spec.md:23` carry the spec's wording.
- [ ] `tools/check.sh` passes.
