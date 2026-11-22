# Touch controls

Status: ready-for-human

Movement on touch: the left thumb drags a **Touch stick** (see GLOSSARY.md). This was pulled forward from the playtest prep after step 3. Touch aiming for skills waits until combat exists. Agreed in a grilling session on 2026-11-16.

## Requirements

1. **iOS deploy.**
   - An iOS export preset that uses Godot's one-click deploy: with a device connected, Remote Debug builds, signs, installs and launches the game, and output reaches the editor debugger.
   - Bundle id `com.thomasclaessens.paperarpg`. `export_presets.cfg` is committed. Sensitive fields stay in `.godot/export_credentials.cfg`.
   - Fallback if signing fights us: Legendary's route, exporting an Xcode project to `~/Documents/godot-exports/paper-arpg` and building from Xcode.
2. **Console button.**
   - A button in `console.tscn`, so it exists in debug builds only. It sits top-left, inset by `DisplayServer.get_display_safe_area()`.
   - Tapping it toggles the Console, the same as the backtick key.
   - Typing uses the iOS on-screen keyboard that appears when the `LineEdit` takes focus. Shortcut buttons only if that turns out to be painful.
3. **Touch stick** `ui/touch_stick.tscn`, a `Control` under a `CanvasLayer`, instanced in `sandbox.tscn`.
   - **Start:** a touch that begins on the left half of the screen. It reads `_unhandled_input`, so GUI such as the console button handles its own touches first.
   - **One finger owns it:** the stick belongs to the touch index that started it. Other fingers are ignored. It ends when that finger lifts.
   - **Origin:** fixed where the thumb lands. The knob clamps at the rim. Exported `radius`, starting at 80 px in the base viewport.
   - **Output:** it presses the `move_*` actions with `Input.action_press(action, strength)`. `Player` stays unchanged, and the 0.2 Input Map deadzone, direction-only movement and camera-relative mapping all apply to touch as they do to the controller.
   - **Visuals:** a base ring and a knob drawn at the touch, from Kenney art, shown only while the thumb is down.
   - **Lost finger:** on pause (the Console opening) or `NOTIFICATION_APPLICATION_FOCUS_OUT`, it releases the actions and hides. A touch the system takes away arrives as a release (at (-1, -1) on iOS) and lets go the same way. The Skill slots' buttons follow the same rule, but keep a finger through a pause: `.scratch/touch-interruptions/spec.md`.
   - **Follow toggle (temporary):** the console command `touchstick follow on|off` switches to a following origin, where the base is dragged along so it stays within one radius of the thumb. Default off. Removed once the device test settles the choice.
   - GUT test `tests/test_touch_stick.gd`: thumb offset → stick vector, clamped to length 1 at the rim, and the origin dragged along in follow mode.
4. **Mac testing.** `input_devices/pointing/emulate_touch_from_mouse` is on, so a mouse drag drives the stick.

## Commits

1. iOS preset and deploy, proven on the phone with the current build.
2. Console button.
3. Touch stick with its test, mouse emulation and the follow toggle.

## Decisions

- **Direction-only, like the controller.** Thumb distance only decides inside or outside the deadzone. If proportional speed ever comes, it changes for both sticks together.
- **Fixed origin first.** Chosen for now. The follow toggle is there to pivot during the device test.
- **Through the `move_*` actions.** `Player` doesn't know where its input comes from.
- **Sandbox, not an autoload.** We're building systems, not the game. Only one scene needs the stick.
- **One-click deploy over an exported Xcode project.** One tool per iteration, plus the editor debugger.

## Decisions made during the build

- **Free developer profile: 3 sideloaded apps.** The first install failed because the iPhone already held three. One was removed to make room.
- **ETC2/ASTC texture import is on.** iOS export with the Mobile renderer refuses to run without it.
- **Landscape only** (`window/handheld/orientation` sensor landscape), and iPhone + iPad as targets.
- **Style C from Kenney's Mobile Controls** (white outlines): `joystick_circle_pad_a` and `joystick_circle_nub_a`, scaled so the ring sits on `radius`.
- **The GUI already claims touches on the console button.** A Control with the default mouse filter consumes a screen touch over it, so the button needs no extra code. `test_touch_stick.gd` guards it. The full-screen `PixelatedView` doesn't block the stick.
- **The stick sets raw action strengths.** `Input.get_vector()` applies the 0.2 deadzone and rescales past it, the same as for the controller.

- **The preset's other choices.** It has an opaque 1024 px icon made from `icon.svg` (the export requires one) and a minimum of iOS 15, as in Legendary. GUT and `tests/` are left out of the export. The team ID is committed; it isn't a secret.
- **Notch inset.** It's skipped on desktop, where the safe area belongs to the display and not the window. On a phone the larger of the left and right insets is used, because in landscape the notch changes sides when the phone turns.
- **The stick releases only what it pressed.** A held W/A/S/D key survives a touch, a pause or a focus loss.
- **A thumb held through a pause is dropped.** After unpausing, it does nothing until it lifts and touches again.

- **Device test (2026-11-16): the stick feels right.** It keeps a fixed origin and the 80 px radius. The follow mode stays, off by default, and becomes a player setting later. The `touchstick` console command switches it until then.
- **Console fixes from the device test.**
  - The command word is lower-cased, because iOS capitalises the first letter typed.
  - The panel sits inside the safe area, to the right of the button.
  - The input sits at the top of the panel, and the panel is 280 px tall, so the on-screen keyboard doesn't cover it.

## Open

- Follow mode as a player setting, once there is a settings screen.
