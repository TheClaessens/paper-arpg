# 02: Snapshot on every use, with the cooldown Modifier

**What to build:** The tracer bullet through the framework. Each use of a Skill builds a **Snapshot** from the Skill and the Character's list of **Modifiers**, and the Skill runs from it. A Modifier is a filter on Skill tags (or none) plus effects; this ticket brings the "change a number" effect, stacking flat additions, then the sum of every **Increased** percentage, then each **More** percentage on its own. `use()` receives the Snapshot; Fireball and Attack read their numbers from it, Fireball hands it to its projectile, and the cooldown that starts is the Snapshot's. The Snapshot records why each Modifier applied or missed. In game, the console command `modifier spell-cooldown on` switches on "Spells have 50% reduced cooldown": Fireball's cooldown becomes 2 s while Attack's stays as made; `modifier` with no arguments lists the proof Modifiers and whether each is on. See `.scratch/skill-tags/spec.md` (rules 2 and 6, requirements 3–7) and GLOSSARY.md (Modifier, Snapshot, Increased, More).

**Blocked by:** 01: Skill tags and implied tags.

**Status:** ready-for-agent

- [ ] The Character keeps one list of Modifiers (where they come from later is a deferred decision in the spec).
- [ ] Building a Snapshot from a Skill and a list of Modifiers is one function, testable without a scene.
- [ ] A Modifier with a Spell filter applies to Fireball and not to Attack; one with no filter applies to both; a number the Skill doesn't have is ignored.
- [ ] Numbers stack flat, then Increased summed, then More each alone: Range 10, +2, +20% and +10% Increased, 50% More gives 23.4.
- [ ] `use()` takes the Snapshot; Fireball, its projectile and Attack read Range and the other numbers from it.
- [ ] The cooldown started on a use comes from the Snapshot: with `spell-cooldown` on, Fireball is ready again after 2 s.
- [ ] The Snapshot lists, per Modifier, whether it applied and why not when it missed.
- [ ] `modifier <name> on|off` switches a proof Modifier; `modifier` lists them with their state. Covered by a GUT test.
- [ ] `tools/check.sh` passes.
