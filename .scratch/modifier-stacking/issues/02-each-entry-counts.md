# 02: Each entry counts

**What to build:** Each entry in the Character's list of Modifiers applies at most once, so the same Modifier listed twice applies twice, whether both entries are one saved file or two copies. `Snapshot.of` drops `counted`. Two rings that give "+2 Range" give Fireball Range 14, where today it is 12 when both point at one Modifier file. The tag pass doesn't change: both entries of one Modifier already apply in the same round, and their tag changes leave the tags as one entry's would. The why list keeps one line per entry, which now agrees with the numbers. Skill-tags rule 4 and ADR 0003 say so. Nothing changes in play: the Console never lists a Modifier twice. See `.scratch/modifier-stacking/spec.md` (rules 3 to 5; The change, file by file › `skills/tag_pass.gd` and The why lines; Docs this reopens; open rules 1 to 3).

**Blocked by:** 01 (both change `of()`); the developer's answers to open rules 1 to 3 in the spec.

**Status:** ready-for-agent

**Files:** `skills/snapshot.gd` (`of()` and its doc only: `:28`, `:33`, `:37-38` as numbered on `master`), `tests/test_snapshot.gd` (`:230-232`, and a new test after it, at the end of the file), `.scratch/skill-tags/spec.md:16`, `docs/adr/0003-tag-changes-apply-in-rounds.md` (`:6`, and a third consequence).

**Tests:** `test_a_modifier_listed_twice_applies_once` becomes `test_a_modifier_listed_twice_applies_twice`, 12 → 14, with a second assertion for two copies; new `test_a_tag_changer_listed_twice_changes_the_tags_once_and_its_numbers_twice`. Change or write each first: on `master` both get Range 12 where they want 14 (two copies already give 14).

- [ ] Range 10 with one "+2 Range" Modifier listed twice: 14. With two separate "+2 Range" Modifiers: 14.
- [ ] "Fire spells are now Holy" (filter Fire, replaces Fire with Holy) with a flat +2 Range, listed twice on a fire projectile spell: tags Spell, Projectile, Holy; Range 14; two why lines, both "Fire spells are now Holy: applied, replaces Fire with Holy".
- [ ] `of()` has no `counted`, and its doc's last sentence reads as the spec gives it. `skills/tag_pass.gd` is untouched.
- [ ] `test_modifier_switches_a_proof_modifier_on_and_off` ("switching on twice adds it once") and every other test pass unchanged.
- [ ] Skill-tags rule 4 and ADR 0003 read as the spec gives them; `GLOSSARY.md` is unchanged.
- [ ] The two searches in the spec's Done when print nothing.
- [ ] `tools/check.sh` passes, and `/code-review` has run on the branch before its PR.
