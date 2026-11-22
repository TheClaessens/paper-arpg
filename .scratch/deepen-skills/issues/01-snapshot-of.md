# 01: Making a Snapshot lives in Snapshot

**What to build:** Move making a Snapshot out of `Skill` and into a static `Snapshot.of(own_tags, numbers, modifiers)`. Implied tags move to `TagPass`. See `.scratch/deepen-skills/spec.md`, item 1. Behaviour stays the same.

**Status:** ready-for-agent

- [x] `Snapshot.of` runs the tag pass, puts the changes in the pools in order, stacks them and writes the "why" lines. `Skill.snapshot` and `Skill.number` call it.
- [x] `IMPLIED_TAGS` and `with_implied` are on `TagPass`; nothing on `Skill` refers to them.
- [x] `Skill` no longer has `_numbers_with` or `stack`.
- [x] Tests that only check the rules build Snapshots from plain data, without instancing a Skill scene.
- [x] A search for the old names comes back clean in code, tests and docs; `tools/check.sh` passes.
