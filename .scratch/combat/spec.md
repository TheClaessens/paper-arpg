# Combat: the first slice

Status: ready-for-human

The first piece of README step 3 (Basic Combat). The player has one **Skill slot** (see GLOSSARY.md) holding either **Attack** (a sword swing) or **Fireball**, and can swap between them from the pause screen. The point is **Hit feedback**: Skills must feel good to use. Agreed in a grilling session on 2026-11-16.

Baseline for the feedback: Seki & Ishikawa, *Quantifying Hit Feedback Preferences in 2D Action Games* (CHI EA '26, https://dl.acm.org/doi/full/10.1145/3772363.3798911). Players tuned visual and timing parameters with sliders. Their preferences fell into three groups, and melee and ranged attacks showed no real difference. So we expose the feedback as tunable values and share one set between Attack and Fireball.

## Requirements

1. **Facing** on the Player: a direction on the ground, at any angle.
   - Stick or WASD: the pushed direction. It keeps the last one when let go.
   - Mouse: from the player to the spot under the cursor on the ground. Once the mouse moves it leads, and WASD only walks. Pushing a gamepad stick or touching the screen takes Facing back.
   - A small arrow on the ground at the player's feet points along Facing.
2. **Skill slot**: exactly one, holding Attack by default. It resets on every launch.
   - Touch: a button on the right of the screen showing the slotted Skill's icon.
   - Input action `use_skill_slot`: the left mouse button and the controller's bottom face button (`JOY_BUTTON_A`).
   - Press only. One press uses the Skill once along Facing. Holding does nothing extra.
   - Each Skill has a use time (Attack 0.4 s, Fireball 0.6 s). A press in the last 0.15 s is remembered and used when the time ends. Earlier presses are dropped.
   - The player can keep moving while using a Skill.
3. **Attack** (sword): a 120° arc reaching 1.6 units along Facing. It hits every Enemy inside the arc once. A white arc flashes flat on the ground, and the Standee card gives a small hop or tilt.
4. **Fireball**: a plain circle moving along Facing at 12 units/s. It disappears after 10 units, or on the first Enemy or wall it touches. A hit on an Enemy gives the same Hit feedback as Attack.
5. **Hit feedback**, one set of values for both Skills:
   - hitstop: the whole game freezes briefly
   - flash: the hit Enemy turns white
   - squash: the hit Standee squashes
   - knockback: the distance the Enemy is pushed
   - screen shake: strength and duration
   - **Stagger**: the Enemy slides with the knockback and doesn't chase, starting at 0.2 s. A hit during a Stagger restarts it.
   - Enemies have no health and don't die yet.
6. **Swapping**: a small button in the bottom right, plus a `pause` action (Esc and controller Start).
   - It pauses the game and shows the pause screen with the Skill slot.
   - Tapping the slot opens a small menu of Skills (Attack, Fireball). Choosing one replaces what's in the slot.
   - Unpausing returns to play. The layout will be refined later.
7. **Tuning**: the console command `hitfeel <name> <value>` changes each Hit feedback value while the game runs, for tuning on the device. It goes away or becomes a setting once the values settle.

## Starting values

These were tuned in the throwaway Combat Feel Lab artifact (https://claude.ai/artifact/6oK7kom3QL7aGN7vTkPR2N). The defaults felt right on the first device test, 2026-11-16.

| Value | Start |
|---|---|
| hitstop | 0.06 s |
| flash | 0.1 s |
| squash | 0.3 (the Standee widens 30% and shortens 30% at the peak, over 0.18 s) |
| knockback | 0.8 units |
| shake strength | 0.12 units |
| shake duration | 0.15 s |
| stagger | 0.2 s (knockback speed falls linearly to zero over it) |
| Attack arc / reach / use time | 120° / 1.6 units / 0.4 s |
| Fireball speed / range / use time | 12 units/s / 10 units / 0.6 s |
| press buffer | 0.15 s |

## Out of scope

Enemies hurting the player, health and death, sound, aiming on touch or controller, holding or channelling, more than one slot, saving the slot, a real loadout screen, Weapons other than the sword.

## Open

- How cursor-style aiming carries over to touch and controller.
- The final layout of the pause screen and Skill menu.

## Decisions made during the build

- **Mouse-to-touch emulation is off.** A left click uses the slot, so it can't also be a screen touch that grabs the Touch stick. The Mac now plays like PC (WASD, mouse aims, click uses the slot). The stick is tried on the phone and covered by its GUT test.
- **The card flips to Facing**, not to velocity, so it looks where the mouse aims even while walking the other way.
- **Facing starts at screen right**, the side the card faces by default.
- **The cursor leads Facing.** Changed after trying it: WASD walking no longer overrides the mouse, since keyboard and mouse are played together. Only a gamepad stick or a touch, each of which aims by itself, takes Facing back.
