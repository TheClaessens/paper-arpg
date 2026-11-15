# Art style slice

Status: ready-for-human

Turns the art style spike (`.scratch/art-style-spike/`) into real project code, following ADR 0001. Agreed in a grilling session on 2026-11-15. Ready for the developer's review and first commit.

## Requirements

1. `docs/agents/godot-conventions.md`, pointed to from `CLAUDE.md`. Rules: composition with single-job components shared between scenes (e.g. a future HealthComponent); call down, signal up; scenes built in the editor and tuned with `@export`; static typing everywhere; autoloads only for real global services.
2. GUT as the test framework, in a version that supports Godot 4.7.
3. `Settings` autoload.
   - Each setting is declared once with its type, default and description, so a Settings HUD can be generated from the list later.
   - Changes are announced with a `changed(key, value)` signal.
   - `pixelated` is the only setting. Pixel height and similar values are not settings.
   - `pixelated` defaults to on and resets every launch (not saved).
4. `Console` autoload, debug builds only.
   - Opens with backtick, or both sticks pressed in on a controller.
   - Systems add commands with `Console.register(...)`.
   - Built-in commands: `help`, `set`, `get`, `settings` (e.g. `set pixelated 1`).
   - GUT tests cover parsing and setting validation.
5. `PixelatedView`.
   - Renders the 3D view at an internal height set by an `@export` (`pixel_height`, starting at 240) and tuned in the editor.
   - Follows the `pixelated` setting, so pixelation can be turned off.
   - UI and HUD are not pixelated.
6. `Standee` component.
   - Outline shader with a white cut-out border, SpriteFrames animations, flip, walk wobble and Blob shadow.
   - Characters control it with `play(anim)` and `face(direction)`.
7. `scenes/sandbox.tscn` is the main scene: a room, a player Standee and two zombies.
   - A temporary `anim <name>` console command previews animations. It is marked for removal in the movement step.
   - `spikes/` is deleted.

## Decisions made during the build

- **Whole-number scaling.** The pixelated view scales by a whole number so every world pixel is the same size. The real height is therefore close to `pixel_height` rather than equal to it (1080p with 240 gives 216). The developer accepted this.
- **Console in release builds.** The Console autoload stays loaded as an empty shell: no panel, no input, and `register()` does nothing. Game code can call it without checking the build type.
- **Accepted values for `set`.** It accepts `1/0`, `true/false` and `on/off`.
- **`Card` and `Sprite` names kept.** These are Standee's internal node names (see the glossary note in the conventions doc).
- **Outline filtering.** The outline shader samples with nearest filtering (`filter_nearest_mipmap`). The Blob shadow is a soft radial gradient.
- **Checks.** Static typing is enforced through `project.godot`, and `tools/check.sh` runs from a pre-commit hook.

## Open

- Tune `pixel_height` together with the developer on real screens.
