# 02: The questions that find Hurtboxes live on Hurtbox

**What to build:** Move the queries that find what a Skill hits off `Skill`, onto the thing they find. Written as `enemies_around`, `enemy_nearest` and `nearest_to` statics on `Enemy`; the merge with `factions-health` (2026-11-22) turned them into Hurtbox queries, so they are `Hurtbox.around`, `Hurtbox.nearest` and `Hurtbox.nearest_to`. See `.scratch/deepen-skills/spec.md`, item 2. Behaviour stays the same.

**Status:** ready-for-agent

- [x] They are statics on `Hurtbox`; `Attack`, `Player` and the tests call them there.
- [x] A search for `Skill.hurtboxes_around`, `Skill.hurtbox_nearest`, `Skill.nearest_to` and `Enemy.enemies_around` comes back clean; `tools/check.sh` passes.
