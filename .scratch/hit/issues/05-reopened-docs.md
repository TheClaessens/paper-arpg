# 05: The docs this step reopens

**What to build:** The wording from the spec's "Docs this reopens", apart from `GLOSSARY.md` (ticket 01): a new paragraph at the end of the conventions' "Composition"; factions-health rule 3, requirements 3, 4 (its second bullet) and 7, and edge case 4; the parenthesis after deepen-skills item 3's "one impact per call."; `combat/spec.md:101`; "hit" capitalised where it names the thing in three doc comments in code; and the ADR `docs/adr/0004-a-hit-lands-itself.md`, as drafted in the spec. Find each passage by its text: earlier steps move line numbers. See `.scratch/hit/spec.md` ("Docs this reopens").

**Files:** `docs/agents/godot-conventions.md`; `.scratch/factions-health/spec.md`; `.scratch/deepen-skills/spec.md`; `.scratch/combat/spec.md`; `characters/enemy/enemy.gd` (`:5`, `:109`, doc comments only); `characters/standee/standee.gd` (`:94`, doc comment only); new `docs/adr/0004-a-hit-lands-itself.md`.

**Tests:** none.

**Blocked by:** 04. The ADR goes in unless the developer says otherwise when reading the spec; it states open rules 2 and 4 as recommended, so a different answer changes its Consequences to match.

**Status:** ready-for-agent

- [x] Each passage reads as the spec gives it, and the paragraphs around it are not reflowed.
- [x] The conventions paragraph names `Stagger.next_velocity()`, which exists since step 6.
- [x] `enemy.gd` and `standee.gd` change in doc comments only.
- [x] The specs of steps 6 and 7, resolved tickets and ADRs 0001 to 0003 are unchanged.
- [x] A search for `_land_hits`, `take_hit(direction` and `hit_taken(direction` in code, tests and `docs/` comes back clean.
- [x] `tools/check.sh` passes.
