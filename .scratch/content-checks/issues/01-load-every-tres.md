# 01: The check loads every `.tres` file

**What to build:** `tools/check.sh` fails on a `.tres` resource that doesn't load, even one nothing refers to yet, as gear and talent Modifier files will be. `tools/load_all.gd` loads `.gd`, `.tscn` and `.tres` files, and leaves out dot folders and the two vendored folders, `res://addons` and `res://assets`, by their whole path. Its file walk becomes the static `find_files(dir, extensions)`, so ticket 03's content test walks the same files. No game code changes. See `.scratch/content-checks/spec.md` (rule 6; The change › `tools/load_all.gd`; Docs this reopens, the conventions' line 37).

**Files:** `tools/load_all.gd` (header `:2-4`, the walk at `:12`, `_find` at `:28-36` → `find_files`); `tools/check.sh` (header `:2-3`, step label `:28`); `docs/agents/godot-conventions.md:37`.

**Tests:** no new GUT test; `load_all` is the check. Break L1 from the spec's Tests table, tried by hand.

**Blocked by:** None. The branch starts from step 1's (`number-bounds`), as the plan stacks the steps.

**Status:** ready-for-agent

- [x] `load_all` loads every `.gd`, `.tscn` and `.tres` file outside dot folders, `res://addons` and `res://assets`, and walks no other way than `find_files`.
- [x] `find_files(dir, extensions)` is static, with the doc comment from the spec.
- [x] Break L1 (`skills/modifiers/broken.tres`, nothing refers to it) fails `tools/check.sh` at the load step with `FAILED TO LOAD: res://skills/modifiers/broken.tres`; deleted, the check passes.
- [x] The headers of `load_all.gd` and `check.sh`, `check.sh`'s step label and the conventions' line 37 say "script, scene and resource".
- [x] `tools/check.sh` passes.
