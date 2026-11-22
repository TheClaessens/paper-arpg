# A Hit lands itself, and the Character hit writes nothing back

One activation of a Skill makes one Hit, fixed once made: the activation's Snapshot, the Character that dealt it, and whether its impact freezes the world. The Hit lands itself on every Hurtbox the activation reaches and decides the impact in one place, so whatever carries it can land it: the Skill now, a projectile in flight after its Skill and Character are gone. Each Character hit works out what the Hit does to it and writes nothing back, because the same Hit goes on to the next Hurtbox.

## Considered Options

- **A hit as two loose arguments, landed by the Skill** (`take_hit(direction, snapshot)` and `Skill._land_hits()`, until `.scratch/hit/spec.md`). Rejected: a projectile can't land a hit once its Skill is gone, and each new fact on a hit, such as who dealt it, would change every receiver's signature.
- **Per-target results on the Hit**: Damage after resistances written back by the Character hit, or a Hit per Hurtbox to hold them. Rejected: a result written on the one Hit would reach the next Hurtbox it lands on, and a Hit per Hurtbox splits what is one activation's.

## Consequences

- A fact a later system needs, such as the parts of a Hit's Damage by Damage type, is a new field on the Hit, filled where the Skill makes it (`Skill._hit()`). No receiver changes.
- The Character that dealt a Hit can be gone when it lands; the Hit then names no dealer, and every reader of the dealer handles that.
- Which landings freeze and shake the world is decided in `Hit.land()` from what each Hurtbox was when the Hit reached it: only a Hit on an Enemy (`.scratch/future-proofing-review/plan.md`, decision 7).
