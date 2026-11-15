# Paper standees in a pixelated 3D world

Characters are Standees: flat 2D sprites on upright cut-outs with a white border, standing in a 3D world built from Kenney's 3D kits. A fixed isometric orthographic camera views the world. The 3D view is rendered at reduced resolution and upscaled with nearest-neighbour filtering; pixelation is on by default and can be switched off. We chose this over fully 3D characters ("3D as 2D") after a side-by-side spike (since removed; see `.scratch/art-style-spike/`). The developer is not a 2D or 3D artist: Standees are easy to animate (a spin mechanic is just spinning the Standee), and they let us reuse 2D assets from shared asset libraries.

## Consequences

- Camera rotation is not supported. Standees face the camera's fixed yaw instead of billboarding.
- Character art is side-view poses: Standees flip left/right and have no front/back facing.
- Characters are grounded by Blob shadows rather than cast shadows.
