# Aiming and cooldowns

Status: ready-for-human

On touch and controller, Facing follows movement, so a Skill can only go where the player walks. This step separates aiming from moving, adds per-Skill cooldowns with feedback on the Skill bar, and adds a few throwaway test Skills to try every combination. Agreed in chat on 2026-11-16; the drag-to-aim gesture gets a design pass first.

## Requirements

1. **How a Skill aims**: each Skill declares one of three kinds.
   - **Around the player**: no aim, used where the player stands (a nova).
   - **Auto**: used toward the nearest Enemy within its Range and within ±60° of Facing, or along Facing when there is none.
   - **Aimed**: a tap auto-aims as above. On touch, dragging off its slot aims it by hand (requirement 3).
2. **Per input**:
   - **Mouse**: Skills go exactly toward the cursor, never auto-aimed. On PC precision Skills can be pinpointed; on touch they can't, and that's fine.
   - **Controller**: the right stick sets Facing while it is pushed past 0.2, apart from movement. When it is idle, auto-aim applies as on touch. Binding slots to the shoulder buttons waits for rebinding.
   - **Touch**: a tap uses the Skill at once, auto-aimed. Aimed Skills can also be dragged.
3. **Drag to aim (touch, aimed Skills)**:
   - Pressing the slot and dragging past a small deadzone shows an aim marker on the ground. Releasing uses the Skill there.
   - Dragging into a cancel zone cancels it.
   - **Direction Skills** (Fireball) show a line from the player along the drag, as long as their Range.
   - **Spot Skills** (Mark) show a target that goes as far as the drag, up to the Range. It reaches full Range at 110 pt of drag. The Enemy it would mark is ringed before release.
   - A dashed ring shows the Range while aiming. The deadzone is 14 pt. The marker turns grey over the cancel zone.
4. **Cooldowns**: a Skill may have a cooldown, a separate clock that starts when a use starts.
   - While it runs, that Skill can't be used from any slot it sits in. A press is ignored, not buffered.
   - Use time still blocks every slot, as today.
5. **Feedback on the Skill bar**:
   - A used slot presses in briefly.
   - A Skill on cooldown shows a radial sweep on each of its slots that empties as it comes back, with a short flash when it's ready.
6. **Test Skills**: throwaway, to be wiped when the real Skill system comes. They cover every combination:

   | Skill | Aims | Cooldown | What it does |
   |---|---|---|---|
   | Attack | auto | none | as today |
   | Fireball | aimed | 4 s | as today |
   | Nova | around the player | 6 s | knocks back every Enemy within 3 units |
   | Mark | aimed | none | marks the Enemy nearest where it lands (tinted for 3 s); no damage |

   Working names, placeholder icons from Kenney.

## Design pass

The clickable prototype is the "Drag to aim (touch)" artboard on https://claude.ai/artifact/EVbnRWbdTyzc8k8w3FULp8 (2026-11-16). The developer found it good enough to playtest.

## Out of scope

Rebinding, targeting a specific Enemy by tapping it, aim assist on the mouse, damage and health.

## Open

- **How to cancel:** dragging back onto the slot, or onto a × button that appears in the top right while aiming. Both get built, switched with an `aim cancel slot|button` console command, until the device playtest picks one.

## Decisions made during the build

- **A use is aimed at an offset on the ground** (`Skill.use(aim)`): its direction for every Skill, plus how far for a spot Skill. The Player picks it: exactly at the cursor, along a pushed right stick, otherwise auto-aimed. A drag carries its own aim through `SkillBar.press(slot, aim)`.
- **The slot buttons follow their own touches**, like the Touch stick, instead of a `TouchScreenButton`, so a drag can be followed. A non-aimed Skill is used the moment the finger lands. An aimed one waits for the lift.
- **A drag that has aimed can't turn back into a tap.** With "cancel slot", lifting on the slot after aiming cancels it, even inside the deadzone. Found in the sandbox check.
- **Sizes in viewport units:** deadzone 22, full Range at 177 drag units, cancel button 88 in the top right of the safe area.
- **The Range ring is the Skill's whole Range**, so Fireball's (10 units) mostly falls off screen. Mark's shorter Range shows it.
