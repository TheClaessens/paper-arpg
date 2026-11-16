# Retro: combat, Skill HUD and aiming

Status: done

Tooling and doc fixes from the retrospective on the combat slice, the Skill HUD and aiming. Agreed on 2026-11-16.

## Requirements

1. **The editor overwrites files:** a section in `godot-conventions.md`.
   - Turn off "Save Before Running".
   - Reload the project after changes made outside the editor or after a branch switch.
   - Stage files explicitly, leaving editor churn (`.uid`, a reordered `project.godot`) out.
2. **Code review before each PR**, in `CLAUDE.md`'s working agreement.
3. **Console commands that drive Skills**, so `tools/screenshot.gd` and `tools/simulate.gd` can check them without throwaway scripts:
   - `bar <slot> <skill|empty>` (Player): puts a Skill in a slot, 1 being the main slot, or empties it.
   - `use <slot> [<x> <z>]` (Player): uses a slot, auto-aimed, or aimed at an offset on the ground.
   - `touch <slot> [<dx> <dy>]` (Skill bar HUD): a finger that lands on the slot, moves by the offset in viewport units, and lifts. Without an offset it's a tap.
   - Each is covered by a GUT test.
4. **Gotchas in `godot-conventions.md`:**
   - Touch on HUD buttons is tested by emitting the slot button's touch signals; pushed events don't reach it in GUT.
   - Godot's built-in `ui_accept`/`ui_cancel` have no controller buttons; this project adds A and B.
   - UI sizes are in viewport units, where 1 pt on an iPhone 17 Pro is about 1.6 units.
   - `Basis.scaled()` scales along the world's axes; to stretch a node along its own axis, multiply by `Basis.from_scale()`.
5. **Design before the spec for UI work**, in `CLAUDE.md`: a design pass in an artifact (sketch, design canvas, clickable prototype) comes first.
