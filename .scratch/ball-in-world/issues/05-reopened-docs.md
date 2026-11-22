# 05: The docs this step reopens

**What to build:** The wording from the spec's "Docs this reopens", apart from `GLOSSARY.md` (ticket 01): in the conventions, a bullet in "Levels and navigation" after step 5's and a sentence at the end of step 7's paragraph in "Tests and checks"; the combat spec's decision that starts "**Fireball's ball is a `Projectile`**"; the end of factions-health requirement 4's bullet that starts "`Projectile.hit_enemy(enemy)`"; a new dated comment under `## Comments` in factions-health issue 03, the old one kept; the game-scene spec's last bullet of "Things in flight" and its Out of scope bullet on a node in `World`. Find each passage by its text: earlier steps move line numbers. No code changes. See `.scratch/ball-in-world/spec.md` ("Docs this reopens").

**Files:** `docs/agents/godot-conventions.md`; `.scratch/combat/spec.md`; `.scratch/factions-health/spec.md`; `.scratch/factions-health/issues/03-enemy-death.md`; `.scratch/game-scene/spec.md`.

**Tests:** none.

**Blocked by:** 04.

**Status:** ready-for-agent

- [ ] Each passage reads as the spec gives it, and the paragraphs around it are not reflowed.
- [ ] The specs the spec lists as not reopened (the hit spec among them), `docs/adr/` and the two reports are unchanged.
- [ ] `tools/check.sh` passes.
