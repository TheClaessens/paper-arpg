# 04: Aim lives in Player

**What to build:** Move Auto-aim (`auto_aim`, `aim_toward`, `AUTO_AIM_ANGLE`) from `Skill` to `Player`, where the rest of the aim code is. `aim_toward` becomes Player's private `_auto_aim(reach)`, aiming along the player's Facing. See `.scratch/deepen-skills/spec.md`, item 4. Behaviour stays the same.

**Status:** ready-for-agent

- [x] `Skill` has no Auto-aim code; `Skill.Aim` keeps its name.
- [x] The Auto-aim tests call `Player.auto_aim`, and the test for a body inside the Range goes through `Player._aim_for`.
- [x] A search for `Skill.auto_aim`, `aim_toward` and `Skill.AUTO_AIM_ANGLE` comes back clean; `tools/check.sh` passes.
