# 01: One stack per number

**What to build:** A Modifier that changes Skill tags stops stacking its number changes on their own. The tag pass still runs first and settles the tags and which Modifiers apply; then `Snapshot.of` puts the number changes of every Modifier that applies into one list and stacks each number once: flat additions, then the sum of every Increased percentage, then each More. Fireball's Range 10 with "Projectiles pierce an Enemy and have 50% increased Range" and "+2 Range" becomes 18, where today it is 17. `counted` stays until ticket 02. Skill-tags rule 6, a new deferred decision in the skill-tags spec and a new consequence in ADR 0002 say so. Nothing changes in play: no shipped Modifier changes both tags and numbers. See `.scratch/modifier-stacking/spec.md` (rules 1 and 2; The change, file by file › `skills/snapshot.gd`; Docs this reopens; Seams).

**Blocked by:** step 1, `number-bounds` (`.scratch/number-bounds/`): this branch is built on it (plan.md, decision 8), and both change `skills/snapshot.gd`.

**Status:** ready-for-agent

**Files:** `skills/snapshot.gd` (`of()` and its doc only: `:25-28`, `:31-32`, `:39`, `:42` as numbered on `master`), `tests/test_snapshot.gd` (`:186-194`, and a new test after it), `.scratch/skill-tags/spec.md` (`:18`, and a new line after `:64`), `docs/adr/0002-skill-modifiers-resolve-in-pools.md` (a third consequence).

**Tests:** `test_a_tag_changers_number_changes_are_a_pool_of_their_own` becomes `test_a_tag_changers_number_changes_stack_with_everyone_elses`, 17 → 18; new `test_numbers_stack_the_same_whichever_modifier_changes_tags`, 23.4. Change or write each first: on `master`, and on step 1's branch, they get 17 and 22.

- [ ] Range 10, a tag-changing Modifier with 50% increased Range and a plain "+2 Range": 18.
- [ ] Range 10, a tag-changing Modifier with 20% increased and 50% more Range, a plain "+2 Range" and a plain "10% increased Range": 23.4, as in `test_flat_then_increased_summed_then_each_more`, where no Modifier changes tags.
- [ ] `of()` gathers the number changes of every Modifier that applies in one list and calls `_stack` once per number; `counted` is still there. `_stack`, `skills/tag_pass.gd` and step 1's `ponytail:` comment above `why.append(...)` are untouched.
- [ ] `of()`'s doc reads as the spec gives it after ticket 01.
- [ ] Every other test passes unchanged, step 1's `test_a_flat_cut_stops_at_zero` included.
- [ ] Skill-tags rule 6, its new deferred decision and ADR 0002's third consequence read as the spec gives them.
- [ ] `grep -rn -E "tag_pool|number_pool|pool.of.their.own|two pools" autoloads characters skills ui scenes props rendering tests tools` prints nothing, nor does `grep -rn -i "with all their effects" GLOSSARY.md docs .scratch --exclude-dir=future-proofing-review --exclude-dir=modifier-stacking --exclude-dir=issues`.
- [ ] `tools/check.sh` passes.
