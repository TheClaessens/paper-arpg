# 03: Tag changes and the tag pass

**What to build:** Modifiers can change what a Skill is. Effects add, replace or remove a Skill tag, and building a Snapshot first runs the tag pass: Modifiers that change tags apply (with all their effects) before any other pool, in rounds, and every other filter is judged on the final tags. Removal wins: a removed tag can't come back in the same use. Each Modifier applies at most once and, once applied, stays applied (no restart), so the pass always ends. Implied tags are worked out again whenever tags change, so a filter on Elemental can match during the pass. The Snapshot's "why" list says which tags changed and which Modifiers missed because a tag was removed. No proof Modifier changes tags yet (Pierce does, in 04), so this ticket is verified at the Snapshot seam with test-only Modifiers. See `.scratch/skill-tags/spec.md` (rules 3, 4 and 6) and ADR 0002.

**Blocked by:** 02: Snapshot on every use, with the cooldown Modifier.

**Status:** ready-for-agent

- [x] Effects that add, replace and remove a tag.
- [x] An added tag lets another Modifier's filter match.
- [x] A removed tag can't be added back in the same use, whichever Modifier comes first.
- [x] A Modifier whose filter needs a tag that was removed doesn't apply ("Skills that chain can no longer pierce": a chaining Fireball doesn't pierce, and anything needing Pierce misses).
- [x] Two Modifiers that would switch each other off and on still end the pass.
- [x] Replacing Fire with a non-elemental tag drops Elemental; a Modifier filtering on Elemental then misses.
- [x] Tag changes happen before number changes, so a number Modifier filtering on a granted tag applies.
- [x] The Snapshot's "why" list records tag changes and Modifiers that missed because a tag was removed.
- [x] GUT tests at the Snapshot seam cover the above; `tools/check.sh` passes.
