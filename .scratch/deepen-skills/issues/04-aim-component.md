# 04: Aim gets one home

**What to build:** An `Aim` component on the Player. It takes over `_aim_for`, `aim_from_drag`, `ground_aim`, `_range_of`, `show_aim` and `hide_aim` from `Player`, and `auto_aim` and `aim_toward` from `Skill`. The HUD aims through it instead of through Player. See `.scratch/deepen-skills/spec.md`, item 4. Behaviour stays the same.

**Status:** needs-info

**Open:**
- `Skill` already has an inner `enum Aim`. A global `class_name Aim` would be shadowed inside `Skill`, and the check may treat that as an error. Either the enum gets a new name, or the component does. Settle the name with the developer, as a glossary entry if it's a new word.
- How the HUD reaches the component: through a property on Player, or with its own export.

- [ ] `Player` keeps Facing, movement and the squash; it asks `Aim` for an aim.
- [ ] `Skill` has no auto-aim code.
- [ ] The mouse cursor, right stick and Auto-aim cases each have a test through `Aim`.
- [ ] `tools/check.sh` passes; checked once in game on PC and touch.
