# Remove Use time

Status: ready-for-agent

Skills are limited only by their own **Cooldown** (see GLOSSARY.md). The shared Use time, which blocked the whole Skill bar after any use, goes, and so does its press buffer. The throwaway test Skills Nova and Mark go too. This step comes before Skill tags (`.scratch/skill-tags/spec.md`), which builds on cooldowns alone. Agreed in a grilling session on 2026-11-21.

## Requirements

1. **No shared pause.** Using a Skill no longer blocks the other Skill slots.
   - `Skill.use_time` and the Skill bar's busy clock are removed.
   - Moving was never blocked, and stays that way.
2. **Every Skill has a Cooldown above 0.**
   - A Skill with a Cooldown of 0 is a configuration warning in the editor.
   - Attack gets a Cooldown of 0.4 s, its current rhythm. Fireball keeps 4 s.
3. **Presses are queued in press order.**
   - A press joins the queue only if its Skill is ready (off Cooldown). A press on a Skill still on Cooldown is ignored.
   - The queue is worked through in the physics step, in the order the presses arrived, so two presses in one frame both go, one after the other.
   - The same Skill pressed twice before it is used is used once: the second press finds it on Cooldown.
4. **No press buffer.** The 0.15 s buffer and its `buffer` export are removed.
5. **Repeating while held follows the Cooldown.** A held slot whose Skill repeats while held is used again the moment its Cooldown ends, aimed where the hold steers it.
6. **Nova and Mark are removed**: `skills/nova/`, `skills/mark/`, `Enemy.mark()` and its tint, and anything that names them (console `bar` choices, the Player scene, tests).
   - The aim modes stay: used around the player, landing on a spot, and the targeted-Enemy ring (`Aim.AROUND`, `aims_at_spot`, `target_for()`). README step 3's targeted curse Skill will need the spot aim.
   - Their tests use a small test-only Skill instead of Nova or Mark.
7. **Docs**: `GLOSSARY.md` (already updated: Use time removed, Cooldown and Skill bar reworded), the Skill bar's doc comment, and any spec or convention text that still describes Use time.

## Out of scope

- Attack speed and cast speed. They arrive later as Modifiers on Cooldown (see Skill tags).
- A shared pause coming back as a tuning value. Only if play shows Skills feel spammy.

## Tests

- Two different Skills pressed in the same frame are both used, in press order.
- A press on a Skill on Cooldown is ignored, even just before it is ready.
- A held repeating Skill is used again each time its Cooldown ends.
- A Skill with a Cooldown of 0 reports a configuration warning.
- The aim modes still work through a test-only Skill.
