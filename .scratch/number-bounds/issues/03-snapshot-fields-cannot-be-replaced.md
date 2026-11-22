# 03: A Snapshot's fields can't be replaced

**What to build:** Snapshot's `tags`, `numbers` and `why` become properties over private fields (`_tags`, `_numbers`, `_why`). Each getter returns its private field; each setter writes nothing and fails `assert(false, "A Snapshot never changes")`. `_init` writes the private fields and makes them read-only, as now. Readers don't change, and `Snapshot.new` keeps its signature. The class doc says the fields can't be replaced. See `.scratch/number-bounds/spec.md` (rule 3; The change, file by file › `skills/snapshot.gd` ticket 03, with why this shape holds in Godot 4.7; open rules 5 and 6).

**Blocked by:** 01 (both change `skills/snapshot.gd`, and 01 writes the `numbers` doc this ticket moves); the developer's answer to open rule 6, which may drop this ticket.

**Status:** ready-for-agent

**Files:** `skills/snapshot.gd` (`:6`; `:8-13`, plus the three private fields after them; `:16-22`), `tests/test_snapshot.gd` (a new test after `:97`).

**Tests:** new `test_a_snapshots_fields_cannot_be_replaced`, written first. It claims each assert's error with GUT's `assert_engine_error("A Snapshot never changes")`, once per assignment, as `test_console.gd:81` does. On `master` no error comes and each field takes the new value.

- [x] Assigning a new value to each of `tags`, `numbers` and `why` reports "A Snapshot never changes" and leaves the field the same object as before (`assert_same`).
- [x] `test_a_snapshot_never_changes` (the read-only lists) and every reader of `snapshot.tags`, `.numbers` and `.why` pass unchanged.
- [x] No other test reports "A Snapshot never changes": a setter called while a Snapshot is made would show there. If one does, stop and say so in the PR instead of working around it.
- [x] `tools/check.sh` passes.
