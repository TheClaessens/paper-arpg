# Tag changes apply in waves, and the tag pass never starts over

The tag pass works out a Skill's final tags before any number is touched. We decided it runs in waves:

- Each wave is every Modifier with tag changes whose filter matches the tags as they stand. They all apply together, and implied tags are worked out again before the next wave.
- Each Modifier applies at most once. Once it has applied, it stays applied, with all its effects, even if a later wave removes a tag its filter needs.
- A tag removed in the pass can't be added back.
- The pass ends when a wave is empty. Every other Modifier is judged on the final tags.

We chose this because it is simple, it always ends, and the order the Modifiers were gained in doesn't change the result.

## Example

Fireball (Spell, Projectile, Fire, so Elemental) with "Fire Skills are blessed" (needs Fire, adds Holy) and "Blessed Skills lose Fire" (needs Holy, removes Fire):

1. Wave 1: "Fire Skills are blessed" matches, and Holy is added.
2. Wave 2: "Blessed Skills lose Fire" matches now, and Fire is removed. Elemental goes with it.
3. Wave 3 is empty, so the pass ends.

Fireball ends up Spell, Projectile, Holy, and both Modifiers apply. "Fire Skills are blessed" no longer matches the final tags, but it stays applied. Its own number changes count too.

## Considered Options

- **Drop out and start over.** A Modifier whose tag was removed by another Modifier drops out, and the pass runs again from the Skill's own tags without it. Rejected: it raises questions with no clear answer. Does a tag removed in the first run stay gone? Which Modifiers drop out when several lose a tag at once? A Modifier can also drop out only because of another one that later drops out itself. The page that walked through it: https://claude.ai/artifact/Kmd7cdV57Ea7Ddb1FNpamG
- **One pass in list order.** Each Modifier is checked once, in the order they were gained. Rejected: two Modifiers that remove each other's tags would give a different result depending on which came first (see ADR 0002).

## Consequences

- A Modifier with tag changes can apply although its filter misses the final tags. Its line in the Snapshot's why list says "applied", with what it did to the tags.
- A Modifier that replaces a tag only added in the same wave does nothing, because that tag arrives at the end of the wave. Deferred until a real build hits it (see `.scratch/skill-tags/spec.md`).
