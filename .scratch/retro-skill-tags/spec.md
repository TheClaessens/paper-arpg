# Retro: Skill tags (tickets 01 to 03)

Status: done

Doc fixes from the retrospective on Skill tags, activation and the tag pass. Agreed on 2026-11-21.

## What happened

- The spec left the edge cases of rule 4 open. The agent filled them itself (drop-outs, a restart) and built them before asking, which took a review, an explainer page and a rewrite to undo.
- Words the agent made up ("wave", "restart") weren't in the glossary and were misread: a wave as a group of similar Modifiers, a restart as restarting the game.
- A GDScript typing trap cost failed runs: `filter()` returns an untyped Array.
- The rename of "use" to "activate" left the old word in a test name, ADR 0002 and the tickets, which only a later review found.

## Requirements

1. **Settle open rules before coding**, in `CLAUDE.md`'s working agreement. When the spec leaves a rule's edge cases open, list them and settle them with the developer, with an artifact if it helps, before writing the code.
2. **Explain in the glossary's words**, in `CLAUDE.md`'s working agreement. A new term is proposed as a glossary entry first, or replaced with plain words.
3. **Finish a rename with a grep**, in `CLAUDE.md`'s working agreement: search code, tests and docs for the old word.
4. **A typing gotcha** in `godot-conventions.md` › Static typing: `Array.filter()` (and `map()`) return an untyped `Array`. Assigning the result to a typed array or passing it to `append_array()` on one fails the check, so loop, or use `assign()`.
