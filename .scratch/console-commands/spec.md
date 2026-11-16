# Console commands live and die with their owner

Status: ready-for-human

A system registers a console command once, and the Console drops it when the system's node leaves the tree. Today every caller handles that lifecycle itself: Player and TouchStick pair `_enter_tree` with `_exit_tree`, and Aggro guards with a static flag. Picked from an architecture review and settled in a grilling session on 2026-11-16. It sits between README steps and is shipped like one.

## Requirements

1. **Auto-unregister.** `Console.register(command, callback, help)` keeps its call shape. When `callback.get_object()` is a Node, the Console connects that node's `tree_exiting` with `CONNECT_ONE_SHOT`, once per node however many commands it owns. On exit it erases every command whose callback belongs to that node, and only those.
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
   - A node leaving drops only its own commands; another node's command keeps working.
   - A static callback's command outlives the node that registered it.
   - Registering the same callback twice is a no-op: `help` lists the command once and it still runs.
   - Another callback under a taken name asserts (checked with GUT's `assert_engine_error`), and the first registration stays.
   - `test_tp_leaves_and_returns_with_the_player` in `tests/test_player.gd` is the end-to-end check: `tp` goes with the Player and comes back when it re-enters.
9. **Docs.** The Autoloads paragraph in `docs/agents/godot-conventions.md` says: register in `_enter_tree`, the Console drops the command when the node leaves the tree, and static callbacks stay registered. `GLOSSARY.md` doesn't change, because a console command isn't a domain term.

## Decisions

- **The trigger is leaving the tree, not being freed.** `Callable.is_valid()` turns false only once the object is freed. `test_tp_leaves_and_returns_with_the_player` removes the Player without freeing it and expects `tp` to go.
- **No owner parameter.** The Callable already carries its object, so callers learn nothing new.
- **Same callback is a no-op, a different one asserts.** This lets every Aggro register the same static callback, and two live Players still fail loudly. "Last one wins" was rejected because it hides name clashes.
- **Drop by owner, not by callback.** Found during the build: Godot treats `bind()`s of one method as the same connection, so one connection per command fails for a node with several commands. One connection per node replaces it. An old owner can no longer erase a newer registration of the same name, since a second owner asserts while the first still holds the name.
- **The different-callback assert is tested.** A failed assert in a headless run logs an engine error and carries on, and GUT's `assert_engine_error` checks it.
- **Movement deepening (candidate B) is deferred.** Godot's scene-organization guide keeps children unaware of their parent and siblings, and Enemy's avoidance follows Godot's documented `velocity_computed` pattern. The shared idle/walk/face logic may move into Standee once combat adds poses (step 3).
