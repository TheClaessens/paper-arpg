# Skill Modifiers resolve in pools, along one order of Damage types

Each activation of a Skill builds a Snapshot from the Skill and every Modifier that applies, and we settled three rules for how that resolves. Skill tags and Damage types never change each other on their own: a tag says what a Skill is, a Damage type what it deals, so removing a tag can't take damage with it and a Fire Skill can deal frost damage. Modifiers apply in fixed pools, one at a time (tag changes, added damage, conversion, scaling, other numbers), so a Modifier's effect never depends on the order it was picked up in. Conversion, and replacing one damage-type tag with another, only move forward along one ordered list of Damage types kept as data, so no build can loop (fire to frost to fire) and every result can be worked out by the player.

## Considered Options

- **Tags follow damage** (a Skill is Fire because it deals fire damage). Rejected: "Fire spells deal frost instead" should leave Fireball a Fire Skill, and modifiers that speak of "fire spells" and "fire damage" mean different things.
- **Repeat until nothing changes, in any direction.** Rejected: fire-to-frost plus frost-to-fire never settles, and the result would depend on which Modifier went first.
- **One pass in the order Modifiers were gained.** Rejected: "Fire spells are now frost spells" plus "Convert 50% of fire to frost" must give 50 frost whichever was gained first.

## Consequences

- A Modifier that should change both what a Skill is and what it deals lists both effects; the code never infers one from the other.
- A conversion "backwards" along the order does nothing. Which types exist and in what order is a design choice made with damage.
- A pool holds one kind of effect, whichever Modifier it comes from. A Modifier that changes tags has its tag changes in the first pool, and its number changes stack with every other Modifier's: Fireball's Range 10 with "Projectiles pierce an Enemy and have 50% increased Range" and "+2 Range" is (10 + 2) × 1.5 = 18 (decided 2026-11-22, `.scratch/modifier-stacking/spec.md`). Whether a Modifier that replaces a damage-type tag also converts its damage as it replaces the tag is decided with damage.
