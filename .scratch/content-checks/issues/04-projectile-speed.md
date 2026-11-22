# 04: Fireball's ball speed is named Projectile speed

**What to build:** A number's name means one thing on every Skill, because a Modifier file names a number without knowing which Skill has it. Fireball's `&"Speed"` is renamed to the name the developer settled in open rule 1 (recommended: `&"Projectile speed"`), with the constant `Fireball.PROJECTILE_SPEED` and the export `projectile_speed` (no scene sets `speed`; `fireball.tscn` keeps relying on the default 12). The projectile and its tests read the new constant. The glossary gains the Projectile speed entry if open rule 1 agrees. The conventions' "Saved content" gains the number-name bullet. The skill-tags spec's line 49 says the rule, and its line 65 keeps `Damage` meaning all of a hit's Damage once Damage types come. Fireball flies as before. See `.scratch/content-checks/spec.md` (rule 7; The change › `skills/fireball/fireball.gd`; Docs this reopens; open rule 1).

**Files:** `skills/fireball/fireball.gd` (`:4`, `:17-21`, `:26`); `skills/fireball/projectile.gd` (`:3`, `:14`, `:28`); `tests/test_projectile.gd` (`:15`, `:55`, as step 1 leaves them); `GLOSSARY.md` (after Range); `docs/agents/godot-conventions.md` ("Saved content", last bullet); `.scratch/skill-tags/spec.md` (`:49`, `:65`).

**Tests:** `test_projectile.gd` passes with the new constant. Break C15 (`spell_cooldown.tres:9` → `&"Speed"`) fails the content test, tried by hand and reverted.

**Blocked by:** 03 (C15 needs the content test, and the bullet goes into its section).

**Status:** ready-for-agent

- [ ] Fireball's number is named as settled, in the constant, the export, `numbers()` and the doc comments.
- [ ] A search for `Fireball.SPEED`, `&"Speed"` and Fireball's `speed` export comes back clean in code, tests and docs; only records of what was remain (`.scratch/combat/spec.md`, the reports, `.scratch/future-proofing-review/`).
- [ ] C15 fails the content test; reverted, it passes.
- [ ] The glossary entry (if agreed), the conventions bullet and the skill-tags spec's lines 49 and 65 read as the spec gives them.
- [ ] `tools/check.sh` passes; checked once in game: Fireball flies as before, and with `modifier pierce on` it passes through one zombie and stops at the next.
