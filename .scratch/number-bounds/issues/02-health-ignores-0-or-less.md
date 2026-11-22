# 02: Health ignores amounts of 0 or less

**What to build:** `Health.damage()` and `heal()` return at once on an amount of 0 or less. Damage never raises Health and healing never lowers it, so Health reaches 0 only through Damage, and `died` comes with it. Health's doc comments say so, and so does factions-health rule 4. Nothing changes in play: after ticket 01 no Skill sends a negative amount, and the Console refuses one. See `.scratch/number-bounds/spec.md` (rule 2; The change, file by file › `characters/health/health.gd`; Docs this reopens; open rule 5).

**Blocked by:** the developer's answer to open rule 5 in the spec.

**Status:** ready-for-agent

**Files:** `characters/health/health.gd` (`:3-5`, `:24-27`, `:33-35`), `tests/test_health.gd` (`:2-3`, and two new tests at the end), `.scratch/factions-health/spec.md:12`.

**Tests:** new `test_negative_damage_does_not_heal` and `test_negative_healing_does_not_hurt`, written first. On `master` Health goes up to 45, and down to 0 without `died`.

- [ ] From 40 of 50, `damage(-5)` leaves 40, and `changed` fired only for the first hit.
- [ ] From 40 of 50, `heal(-50)` leaves 40, and Health isn't dead.
- [ ] 0 Damage, and healing at full, still change nothing (`test_nothing_changes_nothing_is_reported`, unchanged).
- [ ] Factions-health rule 4 reads as the spec gives it.
- [ ] `tools/check.sh` passes.
