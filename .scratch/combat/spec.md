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
3. **Attack** (sword): a 120° Sweep with a Range of 1.6 units along Facing. It hits every Enemy inside the arc once. A white arc flashes flat on the ground, and the Standee card gives a small hop or tilt.
4. **Fireball**: a plain circle moving along Facing at 12 units/s. It disappears after 10 units, or on the first Enemy or wall it touches. A hit on an Enemy gives the same Hit feedback as Attack.
5. **What a hit does.**
   - **Hit feedback**, game-wide and shared by every Skill:
     - hitstop: the whole game freezes briefly
     - flash: the hit Enemy turns white
     - squash: the hit Standee squashes
     - screen shake: strength and duration
   - **Set by each Skill**, a default per Skill:
     - knockback: the distance the Enemy is pushed
     - **Stagger**: the Enemy slides with the knockback and doesn't chase. A hit during a Stagger restarts it.
   - The ground rule: if a game system could change a value (gear, passives, Skill levels, Enemy resistances), it belongs to the Skill. If it's how the game presents every hit, it's game-wide.
   - Enemies have no health and don't die yet.
6. **Swapping**: a small button in the bottom right, plus a `pause` action (Esc and controller Start).
   - It pauses the game and shows the pause screen with the Skill slot.
   - Tapping the slot opens a small menu of Skills (Attack, Fireball). Choosing one replaces what's in the slot.
   - Unpausing returns to play. The layout will be refined later.
7. **Tuning**: ~~a `hitfeel` pane of sliders~~. Built and used to settle the values, then removed once they settled (see the decisions below).

## Starting values

These were tuned in the throwaway Combat Feel Lab artifact (https://claude.ai/artifact/6oK7kom3QL7aGN7vTkPR2N). The defaults felt right on the first device test, 2026-11-16.

Game-wide:

| Value | Start |
|---|---|
| hitstop | 0.06 s |
| flash | 0.1 s |
| squash | 0.3 (the Standee widens 30% and shortens 30% at the peak, over 0.18 s) |
| shake strength | 0.12 units |
| shake duration | 0.15 s |
| press buffer | 0.15 s |

Per Skill:

| Skill | Use time | Range | Knockback | Stagger | Own |
|---|---|---|---|---|---|
| Attack | 0.4 s | 1.6 units | 0.35 units | 0.05 s | Sweep 120° |
| Fireball | 0.6 s | 10 units | 0.35 units | 0.05 s | speed 12 units/s |

The knockback speed falls linearly to zero over the Stagger.

## Out of scope

Enemies hurting the player, health and death, sound, aiming on touch or controller, holding or channelling, more than one slot, saving the slot, a real loadout screen, Weapons other than the sword.

## Open

- Once there is more than one slot, should a Skill's Use time block the other slots too, since the Character is busy, as in most ARPGs? Today it blocks only its own slot.

- How cursor-style aiming carries over to touch and controller.
- The final layout of the pause screen and Skill menu.

## Decisions made during the build

- **Mouse-to-touch emulation is off.** A left click uses the slot, so it can't also be a screen touch that grabs the Touch stick. The Mac now plays like PC (WASD, mouse aims, click uses the slot). The stick is tried on the phone and covered by its GUT test.
- **The card flips to Facing**, not to velocity, so it looks where the mouse aims even while walking the other way.
- **Facing starts at screen right**, the side the card faces by default.
- **The cursor leads Facing.** Changed after trying it: WASD walking no longer overrides the mouse, since keyboard and mouse are played together. Only a gamepad stick or a touch, each of which aims by itself, takes Facing back.
- **One impact per use.** Hitstop and screen shake play once per swing, however many Enemies it hits; flash, squash and knockback play on each Enemy.
- **Hitstop sets `Engine.time_scale` to 0.** The shake and the hitstop's own timer ignore the time scale, so the screen shakes through the freeze.
- **Using a Skill stretches the player's card** (a squash of -0.15). It reuses the hit squash and reads as a small hop.
- **Hit feedback values live in `skills/hit_feedback.tres`**, one resource shared by the Attack and every Enemy, so `hitfeel` can tune them live later.
- **The slot button is a `TouchScreenButton`** that presses `use_skill_slot`. It hides when there's no touch screen.
- **The tuning pane came early**, before Fireball: on trying the Attack, knockback and hitstop felt too strong. Its sliders don't take keyboard focus, so arrow keys keep walking the player.
- **Knockback 0.35 and Stagger 0.05 after tuning in game** (2026-11-16). The lab's 0.8 and 0.2 felt excessive on the real Attack: a short, sharp shove instead of a slide.
- **Skill values and game-wide values are split.** Use time, Range, knockback and Stagger are on every Skill, and Sweep on the Attack. `HitFeedback` keeps only what's game-wide. The press buffer stays on the Skill slot. The tuning pane shows "Game" and "Attack" sections, and the Attack's values are named `attack_*`.
- **Fireball's ball is a `Projectile`** (an Area3D) and a child of the Fireball Skill, with `top_level` on so it flies free of the player. Nothing else has to own it. It looks for the `world` and `enemy` layers, reports an Enemy it touches to Fireball, and Fireball decides the hit, as the Attack does. It flies 0.5 units above the ground, so the floor doesn't stop it.
- **Fireball has a tuning section too** (`fireball_*`), including its speed.
- **Each Skill has a `title` and an `icon`** (Kenney's sword and fire icons). The slot button and the pause screen show what's in the slot, and follow it through the slot's `skill_changed` signal.
- **The pause screen** (`ui/pause_menu.tscn`) runs while paused. Esc and Start, plus the controller's B button (`ui_cancel`), step back: from the Skill menu to the pause screen, from there to the game. Focus lands on the slot, then on the slotted Skill, so the D-pad works right away.
- **The Skill menu's buttons are built each time it opens**, from the `skills` list the sandbox gives it, so it always matches the slot.
- **The tuning pane is removed** after the review. The values have settled, and the pane broke "scenes live in the editor". Tuning now happens in the editor: the Hit feedback in `skills/hit_feedback.tres`, and each Skill's values in its own scene.
- **From the review (2026-11-16):**
  - **Point blank:** an Enemy closer than 0.6 units, pressed against the player, is hit by the Attack from any side, even behind. Otherwise a crowded player would miss the Enemies touching them.
  - **The Range counts the Enemy's body:** the swing hits any part of an Enemy within 1.6 units. Its centre can be up to 1.85 units away (body radius 0.25).
  - **Knockback direction:** the Attack pushes an Enemy straight away from the player; Fireball pushes it along the throw.
  - **A touch's emulated mouse click doesn't use the slot**, so a thumb landing on the Touch stick doesn't swing. Only the gamepad's left stick takes Facing back from the mouse, not the right stick or the triggers.
- **From the architecture review:**
  - **Skill lands its own hits.** `Skill._land_hits()` pushes each hit Enemy with the Skill's knockback and Stagger, then plays the impact once per use. Attack and Fireball both use it.
  - **The Hit feedback is reached with `HitFeedback.shared()`**, so no scene links the `.tres` any more.
  - **The knockback slide is now exact.** It used each frame's starting speed and overshot: a 0.35 knockback over a 3-frame Stagger slid 0.47. Each frame now moves exactly its share of the distance, and a hitstop frame doesn't move.
