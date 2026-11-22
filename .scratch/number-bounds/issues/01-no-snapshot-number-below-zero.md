# 01: No Snapshot number below 0

**What to build:** `Snapshot._stack` stops a number at 0 once its flat changes are summed, so no number `Snapshot.of` makes is below 0, a Skill's own numbers included. Increased and More keep stopping at −100% as now. `_stack`'s doc, the `numbers` doc and `test_snapshot.gd`'s header say so. Two `ponytail:` comments mark known ceilings: every Snapshot writes its why lines, even one made only to aim (in `Snapshot.of`), and the tag pass finds Modifiers with `in` scans (in `TagPass._init`). Nothing changes in play: no shipped Modifier has a negative flat change. See `.scratch/number-bounds/spec.md` (rule 1; Where each number goes; The change, file by file › `skills/snapshot.gd` ticket 01 and `skills/tag_pass.gd`; open rules 1 to 4).

**Blocked by:** the developer's answers to open rules 1 to 4 in the spec.

**Status:** ready-for-agent

**Files:** `skills/snapshot.gd` (`:10`, `:36`, `:46-48`, `:62`), `skills/tag_pass.gd` (a comment above `:33`), `tests/test_snapshot.gd` (the header at `:4-5`, and a new test after `:61`).

**Tests:** new `test_a_flat_cut_stops_at_zero`, written first. On `master` it gets −5, −7.5 and −1 where it wants 0.

- [x] Range 10 with a flat −15 gives 0; with 50% increased on top, 0; with a flat −15 and a flat +10, 5.
- [x] `Snapshot.of` with a Skill's own Knockback of −1 and no Modifier gives 0.
- [x] `_stack` returns `maxf(0.0, value) * maxf(0.0, 1.0 + increased / 100.0) * more`, and its doc says no number comes out below 0.
- [x] Both `ponytail:` comments are in place, worded as in the spec.
- [x] Every other test passes unchanged; `tools/check.sh` passes.
