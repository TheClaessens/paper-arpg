# Coding standards

Judgement calls for the reviewer. Mechanical rules live in `tools/check.sh` and `project.godot`; Godot conventions in `docs/agents/godot-conventions.md`.

## Tests

- **A test can fail.** A test of a mode or branch sets up a case where the other modes would give a different result, so it goes red when its mode breaks. Example: a Skill used around the player needs an Enemy within auto-aim's reach, since with no Enemy auto-aim also points along Facing.
