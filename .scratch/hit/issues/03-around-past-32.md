# 03: `Hurtbox.around()` finds past 32, and warns when it is full

**What to build:** `Hurtbox.MOST_FOUND := 128`, with its doc and the spec's `ponytail:` comment naming the ceiling and the upgrade (rings, or a list of Hurtboxes). `around()` asks `intersect_shape()` for `MOST_FOUND` results instead of 32, and when the result holds exactly that many, prints `push_warning("Hurtbox.around() found its most, %d Hurtboxes: any more were left out." % MOST_FOUND)`. `around()`'s doc says "up to MOST_FOUND of them, in no particular order" and that a warning says when that many were found. No registry, no spatial index, no sorting. Nothing changes in play: the Level has seven zombies. See `.scratch/hit/spec.md` (rule 8; "The change, file by file" › `characters/hurtbox/hurtbox.gd`, ticket 03; open rule 6; engine facts 1 and 2).

**Files:** `characters/hurtbox/hurtbox.gd` (a constant after the signal; `around()`, `:46-62`); `tests/test_hurtbox.gd` (its header, a helper beside `_player_hurtbox_at()`, two tests at the end).

**Tests:** new `test_around_finds_more_than_32` (33 Hurtboxes on the Enemies' layer at (0.5, 0, 0), all found; fails before the change) and `test_around_warns_when_it_finds_its_most` (`MOST_FOUND + 1` of them: `MOST_FOUND` found, and `assert_push_warning("found its most")`), written first. Both wait two physics frames before asking, as the file's other reach tests do. The helper adds `count` `hurtbox.tscn` instances with `collision_layer = ENEMIES` at a spot, each with `add_child_autofree`. The header gains "up to Hurtbox.MOST_FOUND at once, with a warning when that many are found".

**Blocked by:** 01 (both change `hurtbox.gd`); open rule 6 (recommended: 128 and a warning; under option b, `push_error` and `assert_push_error`).

**Status:** ready-for-agent

- [x] `MOST_FOUND` is 128, with its doc and `ponytail:` comment; `around()` asks for that many and warns when it gets that many.
- [x] `nearest()` and `nearest_to()` are unchanged.
- [x] The two new tests pass; `tools/check.sh` passes.
