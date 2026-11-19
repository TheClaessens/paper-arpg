# Split the player's Controls out of Player

Status: done

`player.gd` does five jobs in 265 lines. This step moves out the one job no other Character will ever share: reading the devices. No behaviour changes: every existing test keeps passing, moved where its subject moves.

## Why this line, and not an "Aim" component

The first draft moved everything about Aim into a `PlayerAim` component. Checked against how Enemies and bosses would aim later, that welds two things together:

- **Device-specific:** which of mouse, right stick or touch is aiming, where the cursor is on the ground, which key uses which Skill slot. Only the player has devices.
- **Device-free:** turning an Aim into a use (`skill.use(aim)`), facing it for a moment, showing it with the `AimMarker`. An Enemy that aims does all of this too, with its target standing in for the devices.

Splitting on devices leaves the device-free part in `Player`, in the same shape `Enemy` already has: a body that is told where to go and where to aim. When an Enemy first aims, what the two share can be lifted out then, with two users to shape it. Nothing is built for that now.

What actually stands between an Enemy and a Skill today is in `Skill`, not `Player`: it finds and hits Enemies only (`enemies_around()` masks the `enemy` layer, `_land_hits()` takes Enemies). That is a later step and out of scope here.

## What moves

A new component, `Controls` (`characters/player/controls.gd`), a plain `Node` child of the Player. It has no visuals and knows nothing about Skills.

| It answers | From today's `Player` |
|---|---|
| `move_direction() -> Vector3` | `_stick_direction(move_*)` |
| `aim_direction() -> Vector3`, zero while the right stick rests | `_stick_direction(aim_*)`, `_aim_with_stick` |
| `leads_with_mouse() -> bool` | `_input`, `_aim_with_mouse` |
| `cursor_on_ground(height) -> Variant` | `_cursor`, `_cursor_on_ground` |
| `ground_axes() -> Array[Vector3]` | `_ground_axes` |
| signals `slot_pressed(slot)`, `slot_released(slot)` | `_unhandled_input`, `pressed_slot`, `released_slot`, `SLOT_ACTIONS` |

Call down, signal up: the Player asks `Controls` for directions each physics frame, and connects its two signals to the Skill bar's `press()` and `set_held()`.

## What stays on Player

- Walking with `Movement`, and choosing Facing: right stick, then the last use's aim for a moment, then the mouse, then the walk.
- Using a Skill and choosing its Aim (`_on_skill_used`, `_aim_for`), `aim_from_drag()` and the static `ground_aim()`, `facing_toward()`.
- The `AimMarker` and the hover ring, where they are in `player.tscn`.
- The `tp`, `bar` and `use` commands.

After this, `player.gd` has no `Input.` or `InputEvent` in it. Expected sizes: `Player` about 200 lines, `Controls` about 90.

## Riding along

- `pressed_slot()` and `released_slot()` become one `slot_for(event, pressed)` on `Controls`.
- Lifecycle functions (`_enter_tree`, `_ready`, `_physics_process`) go to the top of `player.gd`, in that order.
- `GLOSSARY.md` gains **Controls**: how the player tells their Character what to do, by keys and mouse, a controller or touch.

## Tests

- The slot-binding tests move from `test_player.gd` to `test_controls.gd`.
- The Facing tests stay in `test_player.gd`: they press real actions and push real mouse motion, so they cover the two nodes together.
- A sandbox check with `tools/simulate.gd` and `tools/screenshot.gd`: walk, a drag-aimed Fireball, and the hover ring.

## Settled

1. **The name** is `Controls`, with a glossary entry.
2. **The scene edit** was made in `player.tscn` directly: one `Controls` node after `Movement`.

## Checked

- `tools/check.sh`: 126 tests pass.
- Sandbox, by console commands and a script pressing real actions: walking, a Fireball used with `use`, and slot 3 used with its key all behave as on `master`. A screenshot shows the Fireball in flight with the Facing arrow along its aim.
- Not checked: the hover ring (no console command moves the mouse) and a drag-aimed Fireball on a device.
