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
_Avoid_: Heading, orientation

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
A place on the Skill bar that holds one Skill or is empty, with its own button. Using the slot uses the Skill in it; an empty slot does nothing. The same Skill may sit in several slots.
_Avoid_: Hotbar, action slot, button

**Skill bar**:
The player's five Skill slots: the main slot, and four smaller ones fanned around it. Using any of them makes the player busy for that Skill's Use time, so no slot can be used until it has passed.
_Avoid_: Hotbar, action bar, loadout

**Main slot**:
The large Skill slot of the Skill bar, under the right thumb. It works the same as the others.
_Avoid_: Primary slot, attack button

**Skill drawer**:
The list of the player's Skills that opens when they choose a Skill slot to change, to pick what goes in it.
_Avoid_: Skill picker, spellbook, inventory

**Use time**:
How long one use of a Skill takes. The Skill bar takes no new use, from any slot, until it has passed. Each Skill has its own, and game systems such as attack speed may change it.
_Avoid_: Global cooldown, cast time, attack time

**Cooldown**:
How long after a use starts before a Skill can be used again, from any slot it sits in. It is the Skill's own clock, separate from Use time; many Skills have none.
_Avoid_: Recharge, refresh, timer

**Range**:
How far a Skill reaches from the Character using it: the length of a swing, or how far a projectile flies.
_Avoid_: Reach, distance, radius

**Sweep**:
The angle a melee swing covers, centred on Facing.
_Avoid_: Arc, cone, angle

**Hit feedback**:
How the game shows the moment a Skill hits an Enemy so the hit feels solid: the world freezes for an instant, the Enemy flashes and squashes, and the screen shakes. It is the same for every Skill, and no game system changes it. How far the Enemy is knocked back, and its Stagger, belong to the Skill.
_Avoid_: Juice, game feel, impact effects

**Stagger**:
The short time after a hit when an Enemy slides with the knockback and does not chase. Another hit restarts it.
_Avoid_: Stun, hitstun, flinch

**Aim**:
Where a use of a Skill is sent: a direction on the ground, and for a Skill that lands on a spot, also how far. The mouse cursor, the right stick or a drag off the Skill slot sets it; otherwise Auto-aim does. A Skill used around the player has none.
_Avoid_: Target, heading, direction

**Auto-aim**:
Aim chosen for the player: the nearest Enemy within the Skill's Range and near Facing, or straight along Facing when there is none.
_Avoid_: Aim assist, lock-on, soft target
