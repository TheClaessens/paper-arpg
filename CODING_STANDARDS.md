# Coding standards

Judgement calls for the reviewer. Mechanical rules live in `tools/check.sh` and `project.godot`; Godot conventions in `docs/agents/godot-conventions.md`.

## Tests

- **A test can fail.** A test of a mode or branch sets up a case where the other modes would give a different result, so it goes red when its mode breaks. Example: a Skill used around the player needs an Enemy within auto-aim's reach, since with no Enemy auto-aim also points along Facing.
- **A test's name and message promise only what its assertions show.** A test named for "the dragged Aim" checks the Aim, not only that there is one.

## Comments

- **A comment still says what the code does.** After an edit, reread the doc comment of what changed, and of what points at it.

## Renames

- **A rename also searches the prose.** A removed setting leaves words in comments and test names that no search for the identifier finds: `AIMED` left "an aimed Skill".
