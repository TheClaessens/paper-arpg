# Paper ARPG

An action RPG for handheld play, where 2D characters stand as paper cut-outs in a 3D world.

## Language

**Standee**:
A character drawn as a flat 2D cut-out with a white border, standing upright in the 3D world and facing the camera.
_Avoid_: Card, sprite, billboard, paper doll

**Character**:
Anything that moves through the world as a Standee: the player's hero and the enemies.
_Avoid_: Actor, entity, unit

**Blob shadow**:
The soft dark ellipse on the ground beneath a Standee that grounds it in the world.
_Avoid_: Drop shadow, shadow decal

**Enemy**:
A Character hostile to the player. Later Enemies come in kinds (such as elites and bosses) and rarities.
_Avoid_: Monster, mob, creep

**Aggro**:
The state of an Enemy that has noticed the player and chases them. Once an Enemy is aggroed, it stays aggroed.
_Avoid_: Alert, agitated, hostile

**Aggro radius**:
The distance from an Enemy within which the player draws its Aggro.
_Avoid_: Detection range, sight radius
