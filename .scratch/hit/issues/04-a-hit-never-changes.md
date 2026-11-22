# 04: A Hit never changes, and a freed dealer reads as none

**What to build:** `Hit`'s `snapshot`, `dealer` and `freezes` become properties over private fields (`_snapshot`, `_dealer`, `_freezes`), as Snapshot's are. Each setter writes nothing and fails `assert(false, "A Hit never changes")`. The `snapshot` and `freezes` getters return their private fields; the `dealer` getter returns `_dealer.get_ref() as Character`, `_dealer` being the `WeakRef` that `_init` makes with `weakref(hit_dealer)` (an empty one for null). So a dealer freed since reads as null, never as a freed object: a getter returning the dealer itself would error in a debug build once it is freed ("Trying to return a previously freed instance."). `_init` writes the private fields. The class doc and the `dealer` doc become the spec's. Readers don't change, and `Hit.new()` keeps its signature. Nothing changes in play. See `.scratch/hit/spec.md` (rules 3 and 4; "The change, file by file" › `skills/hit.gd`, ticket 04; open rules 2 and 3; engine facts 4 to 6).

**Files:** `skills/hit.gd` (the class doc, the three fields and three private fields after them, `_init`); `tests/test_hit.gd` (two tests at the end).

**Tests:** new `test_a_hits_fields_cannot_be_replaced` (each of the three assignments taken with `assert_engine_error("A Hit never changes")`, then each field as it was) and `test_a_dealer_that_is_freed_reads_as_none` (a Hit dealt by a `Character.new()` kept out of the tree, then the Character's `free()`, then `assert_same(hit.dealer, null)`), as the spec's table says. Write them first: both fail after ticket 01.

**Blocked by:** 02 (both change `skills/hit.gd`); open rules 2 and 3 (recommended: refusing setters with the dealer held weakly; a Hit may be made with no dealer). Under open rule 2's option b, the fields stay plain: this ticket keeps only the `dealer` doc ("or null; check `is_instance_valid()` before using it, since it can be a freed Character") and the freed-dealer test, which then asserts `is_instance_valid(hit.dealer)` is false.

**Status:** ready-for-agent

- [ ] Assigning `snapshot`, `dealer` or `freezes` reports "A Hit never changes" and leaves the Hit as it was.
- [ ] A Hit's dealer is the Character it was made with while that Character exists, and null after it is freed, with no error on reading it.
- [ ] No other test reports "A Hit never changes": a setter called while a Hit is made would show there. If one does, stop and say so in the PR instead of working around it.
- [ ] `tools/check.sh` passes.
