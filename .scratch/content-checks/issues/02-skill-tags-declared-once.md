# 02: Skill tags declared once

**What to build:** Every Skill tag is declared once, in a new `skills/skill_tag.gd`: `class_name SkillTag` with no `extends` (as `characters/faction.gd`), one constant per tag the game has today (Spell, Attack, Melee, Projectile, Fire, Elemental, Pierce) and `SkillTag.ALL` holding all seven. Game code names a tag by its constant: `TagPass.IMPLIED_TAGS` becomes `{SkillTag.FIRE: [SkillTag.ELEMENTAL]}` and the projectile reads `SkillTag.PIERCE`. Scenes and Modifier files keep writing tags as text, and so do tests. Nothing changes in play. See `.scratch/content-checks/spec.md` (rule 1; Where tags and number names are written today; The change › `skills/skill_tag.gd`).

**Files:** `skills/skill_tag.gd` (new); `skills/tag_pass.gd:13-15`; `skills/fireball/projectile.gd:48`.

**Tests:** none new; `SkillTag` holds constants only, and ticket 03 checks content against `ALL`. `test_skill_tags.gd`, `test_snapshot.gd` and `test_projectile.gd` pass unchanged.

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] `SkillTag` declares the seven tags, and `ALL` holds exactly them.
- [ ] `grep -rnE '&"(Spell|Attack|Melee|Projectile|Fire|Elemental|Pierce)"' autoloads characters skills ui scenes props rendering --include='*.gd'` prints only `skills/skill_tag.gd`.
- [ ] The console names `"pierce"` and `"spell-cooldown"` (`player.gd:21-23`) and every test are left as they are.
- [ ] `tools/check.sh` passes.
