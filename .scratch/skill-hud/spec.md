# Skill HUD

Status: needs-triage

The **Skill bar** (see GLOSSARY.md): five Skill slots on screen, a pause menu, and a Skill bar view for changing what's in each slot. It follows the Skill HUD design (https://claude.ai/artifact/EVbnRWbdTyzc8k8w3FULp8, the UI Pack Adventure look; sketches at https://claude.ai/artifact/YTSamv7cey2tfkxsGPdGSp). Only the two Skills we have, Attack and Fireball. Mobile leads. Agreed in a grilling session on 2026-11-16.

## Requirements

1. **Skill bar**: five Skill slots.
   - The **main slot** is 84 pt, in the bottom right.
   - Four small slots, 54 pt each, fan around it: 118 pt from its centre, spread over 110°, from 10° below straight left to 10° past straight up.
   - All five work the same way. These sizes are exported on the scene.
   - Everything sits inside the phone's safe area, using the larger side inset in landscape, as the Console does.
   - It shows on every device, in play and in the Skill bar view.
2. **What a slot holds**: one Skill, or nothing.
   - The same Skill may sit in several slots.
   - An empty slot shows the round button at half opacity with no icon, and does nothing when used.
   - At launch: Attack in the main slot, the rest empty. Nothing is saved.
3. **Use time is shared.** Using any slot makes the player busy for that Skill's Use time, and no slot can be used until it has passed.
   - The 0.15 s press buffer belongs to the whole Skill bar: the latest press from any slot is kept.
   - The timing moves off the individual slots.
4. **Input**, one action per slot, in fan order from the lowest small slot up:

   | Slot | Mouse / keyboard | Controller |
   |---|---|---|
   | Main | left click | bottom (A) |
   | Small 1 | right click | X |
   | Small 2 | Q | Y |
   | Small 3 | E | B |
   | Small 4 | R | RB |

   - Touch taps the slot itself. Taps go through `TouchScreenButton`s, so a second finger works while the thumb holds the Touch stick.
   - A touch's emulated mouse click still doesn't count.
5. **Pause menu**:
   - The pause button is top left, inside the safe area, and moves there from the bottom right. Esc and Start also pause.
   - Pausing dims the game and shows a small adventure panel under a "Paused" banner, with **Skill bar** and **Resume**.
   - Controller focus starts on Skill bar. Esc, Start or B resumes.
   - It replaces today's pause screen and Skill menu.
6. **Skill bar view**, opened from "Skill bar":
   - The game stays dimmed, and the Skill bar shows in place.
   - The top-left button becomes **Back**, which returns to the pause menu. A hint sits beside it.
   - Choosing a slot rings it in amber (Kenney Highlights A) and opens the **Skill drawer** on the left.
   - The drawer has an **Empty** tile first, then every Skill the player has. The slot's current Skill is outlined.
   - Choosing a tile puts that Skill in the slot, or empties the slot, and closes the drawer. Choosing the ringed slot again also closes it.
   - Back, Esc, Start or B steps back one level: the drawer first, then the pause menu.
   - Controller: focus starts on the main slot. The D-pad moves between slots. A opens the drawer, with focus on the current Skill's tile. The D-pad moves between tiles, A chooses, and B closes.
7. **Look**: UI Pack Adventure (`assets/kenney/kenney_ui-pack-adventure`).
   - Slots and the pause/Back button: `round_brown_dark`, with the white Mobile Controls icons.
   - The drawer and the pause menu: the `panel_brown_dark` nine-patch, with `banner_hanging` as their title.
   - Drawer tiles: `hexagon_brown_dark`.
   - The Touch stick stays as it is.

## Out of scope

Showing Use time on the buttons (a cooldown sweep), button prompts, unlocking Skills, a settings screen, saving the Skill bar, new Skills.

## Open

- A cooldown separate from Use time, for when a Skill should stay unavailable after its use ends.

## Decisions made during the build

- **Sizes are in viewport units.** The design's points are scaled by 1.6, because on an iPhone 17 Pro 1 pt is about 1.6 units of the 648-unit-tall viewport. Main slot 136, small slots 88, fan radius 190, edge margins 26 × 22, pause button 72. They are exports on `SkillBarHud` and `PauseMenu`.
- **`SkillBar` replaces `SkillSlot`.** One node on the Player holds the five slots, the shared Use time and the buffer. Slot 0 is the main slot. The input actions are `use_skill_slot_1` (main) to `_5`.
- **Each slot button has two inputs.** A `TouchScreenButton` uses the slot in play, because it takes a second finger while the thumb holds the stick. A focusable `Button` chooses the slot while the Skill bar is being changed. Only one of the two is shown at a time.
- **`SafeArea`** (`ui/safe_area.gd`) holds the safe-area maths, now shared by the Console and the HUD.
- **The pause button sits 56 units in from the safe area's left edge,** clear of the debug Console's button in the same corner.
- **The Skill bar is drawn above the dimmed screen.** It's darkened behind the pause menu and at full brightness in the Skill bar view.
- **The current Skill's tile is tinted amber** instead of outlined. The adventure pack has no outline piece for its hexagons.
- **The Kenney UI Pack Adventure is added** to `assets/kenney/`.
