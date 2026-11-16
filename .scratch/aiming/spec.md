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
   - **Every input**: after a use, the player turns to face what the Skill was aimed at.
3. **Drag to aim (touch, aimed Skills)**:
   - Pressing the slot and dragging past a small deadzone shows an aim marker on the ground. Releasing uses the Skill there.
   - Dragging back onto the slot and lifting there cancels it.
   - **Direction Skills** (Fireball) show a line from the player along the drag, as long as their Range.
   - **Spot Skills** (Mark) show a target that goes as far as the drag, up to the Range. It reaches full Range at 110 pt of drag. The Enemy it would mark is ringed before release.
   - A ring shows the Range while aiming. The deadzone is 8 units (about 5 pt), only enough to tell a tap from a drag. The marker turns grey over the cancel zone.
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

## Known limits

- A tapped spot Skill (Mark) auto-aims like any other: only at Enemies within 60° of Facing. With zombies beside or behind you, a tap marks nothing; dragging reaches them. Accepted for now (2026-11-16).

## Decisions made during the build

- **A use is aimed at an offset on the ground** (`Skill.use(aim)`): its direction for every Skill, plus how far for a spot Skill. The Player picks it: exactly at the cursor, along a pushed right stick, otherwise auto-aimed. A drag carries its own aim through `SkillBar.press(slot, aim)`.
- **The slot buttons follow their own touches**, like the Touch stick, instead of a `TouchScreenButton`, so a drag can be followed. A non-aimed Skill is used the moment the finger lands. An aimed one waits for the lift.
- **A drag that has aimed can't turn back into a tap.** With "cancel slot", lifting on the slot after aiming cancels it, even inside the deadzone. Found in the sandbox check.
- **Sizes in viewport units:** deadzone 22 (8 after the device test, below), full Range at 177 drag units, and the cancel button, since removed.
- **The Range ring is the Skill's whole Range**, so Fireball's (10 units) mostly falls off screen. Mark's shorter Range shows it.
- **The slot only cancels after the thumb has left it.** A short aim that stays on the slot still counts, so near spots can be aimed. Coming back onto the slot after leaving it cancels. Found in the sandbox check with Mark.
- **Nova and Mark values:** Nova has Range 3, knockback 0.8, Stagger 0.15, cooldown 6 s, and reuses the swing shader as a full disc. Mark has Range 6, reach 1.5 around the spot, a 3 s amber tint, and Use time 0.3 s.
- **Deadzone 8 instead of 22, from the device test (2026-11-16).** Mark couldn't be dragged onto zombies hugging the player: the spot only appeared 0.75 units out, past where they stand. Now the deadzone only tells a tap from a drag.
- **The mouse highlights the Enemy under the cursor** (the developer's ask, 2026-11-16): a ring on the Enemy nearest the cursor's spot, within 1 unit. It uses the same rule as Mark's target (`Skill.nearest_to`), so on PC the ring shows who a Mark click marks.
- **Holding repeats the Attack** (device test, 2026-11-16). A Skill marked `repeats_while_held` (only Attack for now) is used again each time the Use time ends while its slot is held, on every input. On touch, dragging while holding steers the following swings and shows the aim line. Inside the deadzone they auto-aim again. Lifting just stops: no extra use, no cancel zone. A pause lets go of every slot, because a release during a pause may never arrive.
- **Cancel by dragging back onto the slot** (the developer's pick, 2026-11-16). The cancel button and the `aim cancel` console command that switched between the two are removed.
- **Drags are measured from where the thumb landed, not from the button's centre** (code review, 2026-11-16). With the deadzone at 8, a thumb that landed off-centre turned almost every tap into a hand-aim. The aim also starts at the player and follows the thumb's movement, wherever on the button it pressed.
- **The player faces the aim for 0.35 s after a use** (code review). Before, the next frame's movement took Facing straight back, so the turn never showed while walking.
- **The pause button takes no focus** (code review). After a mouse click on it, a controller's A would have pressed it again instead of attacking.
