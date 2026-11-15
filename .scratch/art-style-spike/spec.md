# Spike: art style

Status: resolved

Pick the prototype art style. Per the README, this is a design decision: the developer chooses, the code only makes the options comparable.

## How to compare

The spike scene has been removed; its look lives on in `characters/standee/` and `rendering/pixelated_view.gd`. Same Kenney Mini Dungeon room and isometric orthographic camera for every option.

- Tab / (Y): **A. Paper standee** (Kenney Toon Characters on upright cards, walk cycle, wobble) <-> **B. 3D as 2D** (Kenney Mini Dungeon animated models)
- P / (X): pixelation on/off (renders at 1/3 resolution, nearest-neighbour upscale)
- Move: WASD, arrows, left stick or d-pad

## Things to judge

- Readability at phone size (character ~1/12 of screen height at camera size 6)
- How a standee reads when walking up/down: Toon poses are side-view only, so it flips left/right but has no front/back walk
- Whether pixelation helps the two packs (Toon is clean vector art; Mini Dungeon is low-poly) sit together

## Known gaps

- Cast shadows don't render (Mobile renderer + SubViewport?); blob shadows used instead
- No collision; the player is clamped to the room

## Answer

Paper standee + pixelated, standees get a white cut-out outline (now `characters/standee/`). Decided by the developer, 2026-11-15.
