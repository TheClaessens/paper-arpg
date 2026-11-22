# Factions and Health

Status: ready-for-agent

Two things Characters get: a **Faction**, the side they fight on, and **Health**, which a Skill's **Damage** lowers until an Enemy dies (see GLOSSARY.md). Skills stop looking for the `Enemy` class and hit whatever **Hurtbox** is hostile to their Character's Faction, so a later pet of the player's Faction is safe from the player's Skills. Grilled on 2026-11-22; the look was picked on the Health Bars & Death canvas (https://claude.ai/artifact/UaRp1inUAJSG34dUsLbrta, the Prototype artboard is the agreed result). Comes after `.scratch/skill-tags/spec.md`.

## The rules

1. **Two Factions for now**: the player's and the Enemies'. Characters of different Factions are hostile; a Skill hits only Hurtboxes hostile to its Character's Faction.
2. **Only a Hurtbox can be hit.** A Character without one can't be hit, aimed at by Auto-aim or ringed by the cursor.
3. **A hit is a Hit** (`skills/hit.gd`): the activation's Snapshot, the Character that dealt it, and whether its impact freezes the world. Where it pushes goes with it to each Hurtbox (`take_hit(hit, direction)`). The Character that was hit reads Damage, Knockback and Stagger from the Snapshot and writes nothing back. Later effects (a burn, a curse) read their own numbers from the same Snapshot, and a fact a later hit needs is a new field on the Hit, so `take_hit` and `hit_taken` never change shape. (Reopened by `.scratch/hit/spec.md`: the dealer and the freeze joined the Hit; the Snapshot holds neither.)
4. **Health lies between 0 and its maximum.** Damage lowers it, healing raises it, both clamped. Damage or healing of 0 or less leaves it alone, so Damage never raises it and healing never lowers it (`.scratch/number-bounds/spec.md`, 2026-11-22).
5. **At 0 Health a Character dies, once.** After that its Health ignores Damage and healing.
6. **A dead Enemy is gone**: it stops chasing, can't be hit, aimed at or ringed, doesn't block anyone, and sinks through the floor. The player at 0 Health plays on and stays at 0.
7. **One Health bar for everyone**: the flat strip over the Standee, shown only while Health is below its maximum.

## Requirements

1. **Faction** (`characters/faction.gd`): a class holding the `Id` enum (`PLAYER`, `ENEMIES`), `layer(faction)` (the collision layer bit of that Faction's Hurtboxes) and `hostile_mask(faction)` (the layers of every other Faction). Not a node. The Hurtbox layers are their own (4 `player_hurtbox`, 5 `enemy_hurtbox`), apart from the body layers, so a projectile never takes a Character's body for a wall. Each Character has `@export var faction: Faction.Id`, one export on `Character` (`characters/character.gd`, since `.scratch/character/spec.md`), defaulting to the Enemies' (`ENEMIES`); `player.tscn` sets the player's (`faction = 0`), and otherwise a scene changes it only to put a Character on another Faction. Named `Id`, not `Side`: "side" is an avoided word for Faction, and it reads as two sides only.
2. **The Character calls down its Faction**: on `_ready` it puts its Hurtbox on `Faction.layer(faction)`, and each of its Skills knows it as its Character (`Skill.character`, set in `_ready` and by `add_skill()`), so the Skill queries `Faction.hostile_mask(character.faction)`. (Reopened by `.scratch/skill-character/spec.md`: a Skill knows its Character, not just its Faction.)
3. **Hurtbox** (`characters/hurtbox/`): an `Area3D` component with the same capsule as the Character's body, monitorable and not monitoring. `take_hit(hit: Hit, direction: Vector3)` emits `hit_taken(hit, direction)` (call down, signal up) and returns whether the Hit landed (since `.scratch/hit/spec.md`). The zombie has one; the player does not in this step.
4. **Skills target Hurtboxes**:
   - `Skill.enemies_around` → `hurtboxes_around(world, centre, reach, mask)`, querying areas only; `enemy_nearest` → `hurtbox_nearest(…, mask)`.
   - A Skill makes one Hit per activation (`Skill._hit()`), and `Hit.land()` takes `Dictionary[Hurtbox, Vector3]`, calls `take_hit` on each, then plays the impact once if it landed on an Enemy (since `.scratch/hit/spec.md`; it was `Skill._land_hits()`).
   - Attack's swing, Fireball's Auto-aim and the player's cursor ring use these with the Skill's (or player's) hostile mask.
   - `Projectile.hit_enemy(enemy)` → `hit(hurtbox)`. Its mask is the `world` layer plus its Skill's hostile mask; a Hurtbox arrives through `area_entered`, a wall or prop through `body_entered`. Pierce counts Hurtboxes.
5. **Damage**: `@export var damage` on Skill next to Range, named `Skill.DAMAGE` among its numbers, so the Snapshot holds it after Modifiers. Attack 10, Fireball 20. No Damage types.
6. **Health** (`characters/health/`): a `Node` component with `@export var max_health: float`, `current` (starts at the maximum), `damage(amount)`, `heal(amount)`, and signals `changed(current, max_health)` and `died`. Floats throughout. Player 100, zombie 50.
7. **The Character wires its components** in `_ready` (`characters/character.gd`, since `.scratch/character/spec.md`): Hurtbox `hit_taken` → `health.damage(hit.snapshot.number(Skill.DAMAGE))`, then its Stagger, if it has one, started with the Snapshot's Knockback and Stagger, then flash and squash as now. The Enemy connects `died` → the death below.
8. **Enemy death**: on `died` the Enemy stops chasing, takes its body and Hurtbox off every collision layer, hides its Health bar, and its Standee plays `sink()`. When the sink ends, the Enemy frees itself.
9. **Standee `sink()`**: the card drops through the ground line with a small side-to-side wobble (±3°) in **0.45 s**, ease-in, while the Blob shadow shrinks and fades. A tween, so the hitstop (`Engine.time_scale = 0`) holds it still first, keeping the killing hit's flash and squash visible.
10. **HealthBar** (`characters/health_bar/`): a component over the Standee, a dark strip with a red fill (as on the canvas: about 100×9 at the viewport's 648 height, fill `#d8473a`, frame `#1b1512`). It shows `current / max_health` and only while Health is below its maximum. The Character connects Health's `changed` to it. The player and the zombie both have one.
11. **Console**: `damage <amount>` and `heal <amount>` act on the player's Health and print the result rounded to a whole number. Registered by the Player in `_enter_tree`.
12. **Words**: GLOSSARY.md gains Faction, Damage, Health, Health bar and Hurtbox; Character and Enemy now speak of Factions. Search for `enemies_around`, `enemy_nearest` and `hit_enemy` after the rename.

## Out of scope

- An Enemy Skill that hits the player, the player's Hurtbox, and what a hit does to the player (knockback, Stagger). **The next step**: the player's Hurtbox is added in the same step that first lets an Enemy deal Damage.
- A neutral Faction (destructible pots and the like), pets, charm.
- Damage types, resistances, damage over time, healing Skills.
- Death of the player, respawning, game over.
- A Health bar on the HUD, or a number on any bar.

## Edge cases (settled 2026-11-22)

1. **The Health bar lives in the world**, a 3D strip on the Character inside the pixelated SubViewport, so it pixelates with the Standees. Not a sharp HUD overlay.
2. **The killing hit doesn't knock back.** A dying Enemy sinks where it stood.
3. **Healing doesn't bring the player back from 0.** Rule 5 holds for the player too, until respawning exists.
4. **A second hit on a Character that just died misses**: no flash, no Hit feedback of its own, no second `died`. One Attack and one Fireball landing in the same frame can find a Hurtbox in their queries after the first hit killed it; `Hurtbox.take_hit` returns whether the hit landed (false once its layers are cleared by death), and `Hit.land()` plays the impact only when the Hit landed on at least one Enemy (since `.scratch/hit/spec.md`; it was `_land_hits`).
5. **A Pierce projectile passes through the Enemy it kills.** The kill counts as its pierced hit; it stops at the next Hurtbox.

## Tests

- Health: damage and heal clamp to 0 and the maximum; 0 Damage changes nothing; `died` fires once, at the hit that reaches 0; after death damage and heal do nothing; `changed` reports each change.
- Faction: `hostile_mask(PLAYER)` holds the Enemies' layer and not the player's, and the reverse.
- Attack hits a zombie's Hurtbox in its Sweep and lowers its Health by 10; a Hurtbox on the player's layer in the same spot is not hit.
- Fireball's projectile lowers a zombie's Health by 20; with Pierce it passes through one Hurtbox and stops at the second.
- Five Attacks kill a zombie: it can't be hit or auto-aimed during its sink and is freed after it.
- The Health bar is hidden at full Health, shows after a hit, and hides when healed back to full.
- The console's `damage` and `heal` change the player's Health and stop at 0 and 100.
