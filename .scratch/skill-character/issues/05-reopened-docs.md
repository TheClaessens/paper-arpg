# 05: The docs this step reopens

**What to build:** The wording from the spec's "Docs this reopens", apart from `GLOSSARY.md` (ticket 01): in the conventions' "Tests and checks", a sentence at the end of the `set_physics_process(false)` paragraph and a new paragraph after it; factions-health requirement 2; the Skill bullet of `skill-tags/spec.md:44`, keeping what step 1 wrote there about the shortest Cooldown. Find each passage by its text: earlier steps move line numbers. No code changes. See `.scratch/skill-character/spec.md` ("Docs this reopens").

**Files:** `docs/agents/godot-conventions.md`; `.scratch/factions-health/spec.md`; `.scratch/skill-tags/spec.md`.

**Tests:** none.

**Blocked by:** 04.

**Status:** ready-for-agent

- [x] Each passage reads as the spec gives it, and the paragraphs around it are not reflowed.
- [x] `tools/check.sh` passes.
