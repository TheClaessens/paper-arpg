# Retro: enemies step

Status: done

Environment fixes from the retrospective on README step 2, agreed on 2026-11-16.

## Requirements

1. **`tp <x> <z>` console command,** registered by `Player` while it is in the tree. GUT test `tests/test_player.gd`.
2. **`tools/simulate.gd`:** runs a scene headless after console commands, printing every Character's position and distance to the player once per second.
3. **`tools/bake_navmesh.gd`:** bakes every NavigationRegion3D in a scene and saves its navmesh. It refuses to run headless, keeps the file's uid, and prints walkable area by height.
4. **`check.sh` fails on an invalid UID,** which Godot only warns about.
5. **`godot-conventions.md`:** who owns console commands, the two new tools, GridMap cell coordinates, navmesh pitfalls (headless bake, cell size and height, `path_height_offset`), and where the API docs are.
6. **`CLAUDE.md`:** one branch per step, landed by a PR with a merge commit.

## Decisions

- **`tp` registers in `_enter_tree` and unregisters in `_exit_tree`,** so the `collisions` command's scene re-entry and scene reloads keep exactly one `tp`.
- **The bake tool restores the uid with `ResourceSaver.set_uid`:** `ResourceSaver.save` drops it, which made the uid appear and disappear between bakes.
