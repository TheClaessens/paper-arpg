# 02: The questions that find Enemies live on Enemy

**What to build:** Move `enemies_around`, `enemy_nearest` and `nearest_to` from `Skill` to statics on `Enemy`. See `.scratch/deepen-skills/spec.md`, item 2. Behaviour stays the same.

**Status:** ready-for-agent

- [ ] They are statics on `Enemy`; `Skill`, `Attack`, `Player` and the tests call them there.
- [ ] A search for `Skill.enemies_around`, `Skill.enemy_nearest` and `Skill.nearest_to` comes back clean; `tools/check.sh` passes.
