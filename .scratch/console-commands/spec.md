# Console commands live and die with their owner

Status: ready-for-human

A system registers a console command once, and the Console drops it when the system's node leaves the tree. Today every caller handles that lifecycle itself: Player and TouchStick pair `_enter_tree` with `_exit_tree`, and Aggro guards with a static flag. Picked from an architecture review and settled in a grilling session on 2026-11-16. It sits between README steps and is shipped like one.

## Requirements

1. **Auto-unregister.** `Console.register(command, callback, help)` keeps its call shape. When `callback.get_object()` is a Node, the Console connects that node's `tree_exiting` with `CONNECT_ONE_SHOT`. On exit it erases the command only if the entry still holds that same callback, so an old owner never removes a newer registration of the same name.
2. **Duplicates.** Registering a name that already holds an equal Callable does nothing. Registering a name with a different callback still asserts.
3. **Unbound callbacks stay.** A static callback, or one bound to an object that isn't a Node, stays registered until the game quits. A lambda written inside a node method is bound to that node and behaves like a method. The `register()` doc comment states both rules.
4. **No public `unregister()`.** The erase becomes private. Add a public one back only when a node needs to drop a command while it stays in the tree.
5. **Callers.**
   - `Player` and `TouchStick` lose their `_exit_tree`.
   - `Aggro` loses `_command_registered` and registers `Aggro._toggle_rings` plainly in `_enter_tree`.
   - Every caller registers in `_enter_tree`, not `_ready`, so a node that re-enters the tree gets its command back.
6. **`nav` stays in Console.** It is an engine debug toggle, like `collisions`.
7. **Release builds are unchanged.** `register()` still does nothing there and connects nothing.
8. **Tests** in `tests/test_console.gd`:
   - A node's command disappears when the node leaves the tree. This replaces `test_unregister_removes_command`.
   - Registering the same callback twice is a no-op: `help` lists the command once and it still runs.
   - An old owner leaving the tree does not erase a newer registration of the same name.
   - `test_tp_leaves_with_the_player` in `tests/test_player.gd` stays as the end-to-end check.
9. **Docs.** The Autoloads paragraph in `docs/agents/godot-conventions.md` says: register in `_enter_tree`, the Console drops the command when the node leaves the tree, and static callbacks stay registered. `GLOSSARY.md` doesn't change, because a console command isn't a domain term.

## Decisions

- **The trigger is leaving the tree, not being freed.** `Callable.is_valid()` turns false only once the object is freed. `test_tp_leaves_with_the_player` removes the Player without freeing it and expects `tp` to go.
- **No owner parameter.** The Callable already carries its object, so callers learn nothing new.
- **Same callback is a no-op, a different one asserts.** This lets every Aggro register the same static callback, and two live Players still fail loudly. "Last one wins" was rejected because it hides name clashes.
- **The different-callback assert is not tested.** A failed assert halts the debug run instead of failing a GUT test.
- **Movement deepening (candidate B) is deferred.** Godot's scene-organization guide keeps children unaware of their parent and siblings, and Enemy's avoidance follows Godot's documented `velocity_computed` pattern. The shared idle/walk/face logic may move into Standee once combat adds poses (step 3).
