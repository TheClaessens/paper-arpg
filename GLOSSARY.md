# Paper ARPG

An action RPG for handheld play, where 2D characters stand as paper cut-outs in a 3D world.

## Language

**Standee**:
A character drawn as a flat 2D cut-out with a white border, standing upright in the 3D world and facing the camera.
_Avoid_: Card, sprite, billboard, paper doll

**Character**:
Anything that moves through the world as a Standee and has a Faction: the player's hero and the Enemies. It has its Skills, and the Modifiers that change them.
_Avoid_: Actor, entity, unit

**Blob shadow**:
The soft dark ellipse on the ground beneath a Standee that grounds it in the world.
_Avoid_: Drop shadow, shadow decal

**Enemy**:
A Character of the Enemies' Faction, hostile to the player and their allies. Later Enemies come in kinds (such as elites and bosses) and rarities.
_Avoid_: Monster, mob, creep

**Faction**:
The side a Character fights on: the player's or the Enemies'. Characters of different Factions are hostile, so their Skills hit each other. A pet the player summons would be of the player's Faction.
_Avoid_: Team, allegiance, alignment, side

**Aggro**:
The state of an Enemy that has noticed the player and chases them. Once an Enemy is aggroed, it stays aggroed.
_Avoid_: Alert, agitated, hostile

**Aggro radius**:
The distance from an Enemy within which the player draws its Aggro.
_Avoid_: Detection range, sight radius

**Level**:
One place the player plays through, with its own ground, walls, props, light and Enemies. The player's Character, the camera and the HUD are not part of a Level: they carry over from one Level to the next.
_Avoid_: Map, stage, zone, scene

**Controls**:
How the player tells their Character what to do: where to walk, where to aim and which Skill slot to activate, by keys and mouse, a controller or touch.
_Avoid_: Input, player input, input handler

**Touch stick**:
The on-screen stick a thumb drags to move the player. It appears where the thumb lands on the left half of the screen and acts like the controller's left stick.
_Avoid_: Virtual joystick, thumbstick, d-pad

**Facing**:
The direction on the ground a Character points, at any angle. The player's Facing follows the mouse cursor once the mouse moves, and otherwise the stick, keeping its last direction when the stick is let go.
_Avoid_: Heading, orientation

**Skill**:
Something a Character activates, such as Fireball or Attack; the player activates theirs from Skill slots. The Character has its Skills; the Skill bar is only where the player's are slotted.
_Avoid_: Ability, spell, action, power

**Activate**:
To set a Skill off: it checks its Cooldown, makes a Snapshot, starts the Snapshot's Cooldown and does what it does. One such time is an activation.
_Avoid_: Use, cast, invoke, trigger (kept for a Skill set off by another event)

**Skill tag**:
A word on a Skill that says what kind of Skill it is, such as Spell, Projectile or Fire. Some Skill tags imply others: a Fire Skill is also Elemental.
_Avoid_: Keyword, category, skill type

**Pierce**:
A Skill tag that is also a behaviour: a Pierce projectile passes through the first Enemy it hits and stops at the next. It never passes through a wall.
_Avoid_: Penetrate, pass-through

**Modifier**:
A change that a game system, such as gear or a talent, makes to Skills. It picks the Skills it applies to by their Skill tags, or applies to every Skill.
_Avoid_: Mod, affix, stat

**Tag pass**:
The first step of making a Snapshot: Modifiers that add, replace or remove Skill tags apply round after round, each once, so every other Modifier is judged on the final tags. A removed tag can't come back in the same activation.
_Avoid_: Tag resolution, tag phase

**Damage**:
How much Health a Skill's hit takes away. A number of the Skill that Modifiers change, separate from its Damage type.
_Avoid_: Power, attack value

**Damage type**:
What kind of damage a hit deals, such as fire. It is separate from the Skill's Skill tags: a Fire Skill can deal frost damage, and a tag never sets the damage.
_Avoid_: Element, damage tag

**Increased**:
A Modifier's percentage that is added to every other increased or reduced percentage on the same number, before they change it together.
_Avoid_: Additive, bonus

**More**:
A Modifier's percentage that changes a number on its own, after every Increased percentage. Less is its negative.
_Avoid_: Multiplicative, compound

**Weapon**:
The item a Character fights with, such as a sword or a bow. Using it is the Attack.
_Avoid_: Gear, equipment

**Attack**:
The Skill that uses the equipped Weapon: a sword swings, a bow shoots. The player always has it and can always slot it.
_Avoid_: Basic attack, auto-attack, default attack

**Skill slot**:
A place on the Skill bar that holds one Skill or is empty, with its own button. Pressing the slot activates the Skill in it; an empty slot does nothing. The same Skill may sit in several slots.
_Avoid_: Hotbar, action slot, button

**Skill bar**:
The player's five Skill slots: the main slot, and four smaller ones fanned around it.
_Avoid_: Hotbar, action bar, loadout

**Main slot**:
The large Skill slot of the Skill bar, under the right thumb. It works the same as the others.
_Avoid_: Primary slot, attack button

**Skill drawer**:
The list of the player's Skills that opens when they choose a Skill slot to change, to pick what goes in it.
_Avoid_: Skill picker, spellbook, inventory

**Cooldown**:
How long after an activation starts before a Skill can be activated again, from any slot it sits in. Every Skill has one, and it is the only thing that limits how often a Skill is activated. Modifiers such as attack speed change it, down to a shortest Cooldown that is the same for every Skill.
_Avoid_: Recharge, refresh, timer, global cooldown, use time

**Snapshot**:
A Skill with every Modifier that applied when it was activated, fixed from that moment for everything the activation causes, such as a projectile in flight or a burn left on an Enemy.
_Avoid_: Activation, cast, invocation, instance

**Range**:
How far a Skill reaches from the Character that has it: the length of a swing, or how far a projectile flies.
_Avoid_: Reach, distance, radius

**Projectile speed**:
How fast a Skill's projectile flies, such as Fireball's ball. A number of the Skill that Modifiers change, named the same on every Skill that has a projectile, so one Modifier can speed them all.
_Avoid_: Speed, ball speed, velocity

**Sweep**:
The angle a melee swing covers, centred on Facing.
_Avoid_: Arc, cone, angle

**Hit feedback**:
How the game shows the moment a Skill hits an Enemy so the hit feels solid: the world freezes for an instant, the Enemy flashes and squashes, and the screen shakes. A projectile's hit doesn't freeze the world, so a ball flying on through Enemies doesn't stutter. Otherwise it is the same for every Skill, and no game system changes it. How far the Enemy is knocked back, and its Stagger, belong to the Skill.
_Avoid_: Juice, game feel, impact effects

**Stagger**:
The short time after a hit when a Character slides with the knockback and doesn't walk. Another hit restarts it, but a hit whose Stagger is 0 doesn't stagger at all. The player, for now, isn't staggered.
_Avoid_: Stun, hitstun, flinch

**Health**:
How much more Damage a Character can take before it dies. Damage lowers it, and healing raises it up to its maximum. At 0 an Enemy dies; the player, for now, stays at 0.
_Avoid_: HP, hit points, life

**Health bar**:
The flat strip over a Character's Standee that shows its Health. It shows only while Health is below its maximum.
_Avoid_: Life bar, HP bar

**Hurtbox**:
The part of a Character that Skills hit. A Character without one can't be hit.
_Avoid_: Hitbox, collider, hit area

**Aim**:
Where an activation of a Skill is sent: a direction on the ground, and for a Skill that lands on a spot, also how far. The mouse cursor, the right stick or a drag off the Skill slot sets it; otherwise Auto-aim does. A Skill activated around the player has none.
_Avoid_: Target, heading, direction

**Auto-aim**:
Aim chosen for the player: the nearest hostile Hurtbox within the Skill's Range and near Facing, or straight along Facing when there is none.
_Avoid_: Aim assist, lock-on, soft target
