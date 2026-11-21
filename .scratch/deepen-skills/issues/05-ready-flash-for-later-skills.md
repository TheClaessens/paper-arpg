# 05: A Skill gained later flashes when ready

**What to build:** `SkillSlotButton.show_skill` connects to its Skill's `ready_again` (and disconnects the one it showed before), so the button flashes itself. The HUD's own `ready_again` wiring and `_on_ready_again` go. See `.scratch/deepen-skills/spec.md`, item 5.

**Status:** ready-for-agent

- [ ] A Skill added to the player after `_ready` and slotted flashes its button when its Cooldown ends.
- [ ] A button whose Skill was swapped out no longer flashes for the old Skill.
- [ ] A Skill sitting in two slots flashes both.
- [ ] `tools/check.sh` passes.
