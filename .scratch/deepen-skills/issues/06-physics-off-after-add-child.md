# 06: Tests turn a Player's physics off after it is in the tree

**What to build:** `before_each` in `test_player.gd`, `test_aim_modes.gd`, `test_pause_menu.gd` and `test_skill_bar_hud.gd` calls `player.set_physics_process(false)` before `add_child`, which does nothing: the Player turns physics back on when it becomes ready. Move each call after `add_child`, and drop the now-redundant second call in `test_player.gd`'s Auto-aim test. See `docs/agents/godot-conventions.md`, Tests and checks.

**Status:** ready-for-agent

- [x] Each of those `before_each` turns physics off after `add_child`.
- [x] Tests that turn physics back on themselves still pass; `tools/check.sh` passes.
