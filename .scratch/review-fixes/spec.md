# Review fixes

Status: done

Fixes from the architecture review of 2026-11-16. No new behaviour beyond what each item says.

## Requirements

1. **A Skill cools down off the Skill bar too.** The Skill bar keeps running the cooldown of a Skill it used after the Skill leaves its slots.
2. **An Enemy's body is its collision shape.** `Skill.body_radius` goes.
   - `Skill.enemies_around()` asks the physics engine with `reach` alone: an Enemy whose body touches the sphere is within reach.
   - `Attack.in_sweep()` only judges the angle (and point blank); the query has already judged the Range.
   - Auto-aim at an Enemy whose body is in Range but whose centre is past it aims as far as the Range.
   - Nova no longer reaches a body's width past its disc.
3. **Each Skill slot's touch has its own landing point**, so a second finger on another slot doesn't move the first one's drag origin.
4. **The pause menu neither pauses nor unpauses while the Console is open**, so closing the Console can't unpause the game under an open menu, and the menu can't unpause it under an open Console.
5. **Small ones:**
   - `HitFeedback.shared()` keeps the resource it loaded.
   - The Skill slot input actions are named once, in a constant.
   - `Player` reads the camera's ground axes in one place, which copes with no camera.
   - An Aggro's ring is shown by the `aggro` command through a group, not polled every frame.

Each of 1 to 4 gets a GUT test.
