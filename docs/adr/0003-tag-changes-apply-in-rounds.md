# Tag changes apply in rounds, and the tag pass never starts over

The tag pass works out a Skill's final tags before any number is touched. We decided it runs in rounds:

- Each round is every Modifier with tag changes whose filter matches the tags as they stand. They all apply together, and implied tags are worked out again before the next round.
- Each Modifier applies at most once. Once it has applied, it stays applied, with all its effects, even if a later round removes a tag its filter needs.
- A tag removed in the pass can't be added back.
- The pass ends when a round is empty. Every other Modifier is judged on the final tags.

We chose this because it is simple, it always ends, and the order the Modifiers were gained in doesn't change the result.

## Rounds are not pools

The pools (ADR 0002) are the fixed order every activation follows: tag changes, added damage, conversion, scaling, other numbers. Rounds happen only inside the first pool, the tag pass. A round is not a group of similar Modifiers. It is every tag-changing Modifier that matches at that moment, of whatever kind, and which round a Modifier lands in depends on the other Modifiers the player has. Once the rounds are done, the tags are fixed, and the later pools judge every other filter on them.

## Example

Fireball (Spell, Projectile, Fire, so Elemental) with "Fire Skills are blessed" (needs Fire, adds Holy) and "Blessed Skills lose Fire" (needs Holy, removes Fire):

1. Round 1: "Fire Skills are blessed" matches, and Holy is added.
2. Round 2: "Blessed Skills lose Fire" matches now, and Fire is removed. Elemental goes with it.
3. Round 3 is empty, so the pass ends.

Fireball ends up Spell, Projectile, Holy, and both Modifiers apply. "Fire Skills are blessed" no longer matches the final tags, but it stays applied. Its own number changes count too.

## Considered Options

- **Drop out and start over.** A Modifier whose tag was removed by another Modifier drops out, and the pass runs again from the Skill's own tags without it. Rejected: it raises questions with no clear answer. Does a tag removed in the first run stay gone? Which Modifiers drop out when several lose a tag at once? A Modifier can also drop out only because of another one that later drops out itself. The page that walked through it: https://claude.ai/artifact/Kmd7cdV57Ea7Ddb1FNpamG
- **One pass in list order.** Each Modifier is checked once, in the order they were gained. Rejected: two Modifiers that remove each other's tags would give a different result depending on which came first (see ADR 0002).

## Consequences

- A Modifier with tag changes can apply although its filter misses the final tags. Its line in the Snapshot's why list says "applied", with what it did to the tags.
- A Modifier that replaces a tag only added in the same round does nothing, because that tag arrives at the end of the round. Deferred until a real build hits it (see `.scratch/skill-tags/spec.md`).
