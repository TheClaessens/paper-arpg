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

**Touch stick**:
The on-screen stick a thumb drags to move the player. It appears where the thumb lands on the left half of the screen and acts like the controller's left stick.
_Avoid_: Virtual joystick, thumbstick, d-pad

**Facing**:
The direction on the ground a Character points, at any angle. The player's Facing follows the mouse cursor once the mouse moves, and otherwise the stick, keeping its last direction when the stick is let go.
_Avoid_: Heading, aim, orientation

**Skill**:
Something the player uses from a Skill slot, such as Fireball or Attack.
_Avoid_: Ability, spell, action, power

**Weapon**:
The item a Character fights with, such as a sword or a bow. Using it is the Attack.
_Avoid_: Gear, equipment

**Attack**:
The Skill that uses the equipped Weapon: a sword swings, a bow shoots. The player always has it and can always slot it.
_Avoid_: Basic attack, auto-attack, default attack

**Skill slot**:
A place that holds one Skill, with its own button. Using the slot uses the Skill in it.
_Avoid_: Hotbar, action slot, button

**Hit feedback**:
What the game does the moment a Skill hits an Enemy so the hit feels solid: the world freezes for an instant, the Enemy flashes and squashes, gets knocked back, and the screen shakes.
_Avoid_: Juice, game feel, impact effects

**Stagger**:
The short time after a hit when an Enemy slides with the knockback and does not chase. Another hit restarts it.
_Avoid_: Stun, hitstun, flinch
