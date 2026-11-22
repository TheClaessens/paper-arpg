# 05: A thumb held through a Cooldown repeats like a held key

**What to build:** Only if the developer answers yes to open rule 1 in `.scratch/touch-interruptions/spec.md`; otherwise mark this ticket `wontfix`. Nothing else depends on it.

Today `SkillBarHud._on_touch_started` returns early when the slot's Skill isn't ready (`skill_bar_hud.gd:98`). So a thumb that lands on the Attack's slot during its Cooldown does nothing until it lifts and lands again, while a held key or controller button holds the slot and the Skill bar activates the Attack the moment its Cooldown ends. Move the readiness check into the aimed branch only:

- A Skill aimed by drag (Fireball) is aimed only when it is ready now, as today. A thumb that lands during its Cooldown shows no aim marker, and its lift activates nothing.
- Any other Skill's press and hold are always passed to the Skill bar, which ignores a press during the Cooldown and activates a held repeating Skill the moment the Cooldown ends.

```gdscript
func _on_touch_started(at: Vector2, slot: int) -> void:
	_landed[slot] = at
	var skill := player.skill_bar.skill_in(slot)
	if skill == null:
		return
	if skill.aim == Skill.Aim.AIMED:
		if skill.is_ready(): # an aim only for a Skill that can be activated now
			_aiming_slot = slot # activated when the thumb lifts
			_aimed = false
			_left_slot = false
	else:
		player.skill_bar.press(slot) # ignored while the Cooldown runs
		if skill.repeats_while_held:
			_held_slot = slot
			player.skill_bar.set_held(slot, true) # activated the moment the Cooldown ends
```

Also: the HUD's class doc comment says that holding a Skill that repeats while held keeps activating it "even when the thumb lands during its Cooldown"; `.scratch/aiming/spec.md:64` gets the sentence the spec gives ("Docs this reopens" 1); and the spec's open rule 1 gets the developer's answer under "Decisions". Then the developer tries it on the phone.

**Blocked by:** 02: A lost finger on a Skill slot activates nothing (same file, next to its changes); the developer's answer to the spec's open rule 1.

**Status:** ready-for-human

Built in `.scratch/aim-modes/` (ticket 04), as the last commit of that branch so it reverts alone; waiting for the developer's try on the phone.

**Files:** `ui/skill_bar_hud.gd` (`_on_touch_started`, the class doc comment), `tests/test_skill_bar_hud.gd` (appended), `.scratch/aiming/spec.md` (line 64), `.scratch/touch-interruptions/spec.md` (Decisions).

**Tests:** the spec's tests 9 and 10. Test 9 fails on `master`: the held thumb is ignored. Test 10 passes on `master` and guards the aimed check.

**Done when:**

- [ ] A thumb that lands on the main slot during the Attack's Cooldown and stays activates it the moment the Cooldown ends, then repeats; a tap during the Cooldown activates nothing.
- [ ] A thumb that lands on Fireball during its Cooldown shows no aim marker, and its lift activates nothing, even after the Cooldown has ended.
- [ ] Every existing test in `test_skill_bar_hud.gd` passes unchanged; `tools/check.sh` passes.
- [ ] On the iPhone, the developer taps the main slot, lands again at once and keeps holding: the Attack repeats as soon as its Cooldown ends, as holding A on a controller does. The developer keeps it, or reverts this ticket and marks it `wontfix`.
