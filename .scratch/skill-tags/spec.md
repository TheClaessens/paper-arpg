# Skill tags

Status: ready-for-agent

A framework that later game systems use to change Skills: **Skill tags** say what a Skill is, **Modifiers** change Skills by their tags, and each activation builds a **Snapshot** (see GLOSSARY.md). The framework is the point; the Modifiers and tags here are examples that prove it and may not ship. Comes after `.scratch/remove-use-time/spec.md`. Worked out on the Skill Tags whiteboard (https://claude.ai/artifact/KWxxh9kBRFQeMnqhwE7Kr4) and the Skill Tag Rules page with its sandbox (https://claude.ai/artifact/CPo9u5o4VqzvxPbCE7CVQH), then grilled on 2026-11-21. Why the rules are shaped this way: `docs/adr/0002-skill-modifiers-resolve-in-pools.md`.

## The rules

1. **Skill tags say what a Skill is; Damage types say what it deals.** Neither changes the other on its own. A Fire Skill can deal frost damage, and removing a tag never removes damage.
2. **A Modifier is an optional filter plus one or more effects.** The filter checks Skill tags; with none, the Modifier applies to every Skill. Effects change a number, or add, replace or remove a tag. Some tags are also a behaviour the Skill reads from its Snapshot, such as Pierce, so adding one adds the behaviour. (Adding and converting damage come with damage.)
3. **A tag changes only when an effect adds, replaces or removes it.** Prefer replacing a damage-type tag over removing it.
4. **Tag changes apply in rounds, and removal wins.**
   - Modifiers that change tags apply in rounds: each round is every one whose filter matches the tags as they stand. Once applied, a Modifier stays applied, with all its effects, even if a later round removes a tag its filter needs. The pass never starts over (decided 2026-11-21; see `docs/adr/0003-tag-changes-apply-in-rounds.md`).
   - Every other Modifier applies only if its filter matches the Skill's tags after every tag change.
   - A removed tag can't come back in the same activation. Example: with "Projectiles pierce an Enemy" and "Skills that chain can no longer pierce", a Fireball that chains doesn't pierce, and anything that needs Pierce doesn't apply.
   - Each Modifier applies at most once per activation, so the tag pass always ends.
5. **Conversion and tag replacement only move forward along one ordered list of Damage types.** The list is data in one place, so types can be renamed or added and nothing can loop. (Needed once damage exists; nothing to build now.)
6. **Modifiers apply in pools, one pool at a time**: tag changes (with all their effects), added damage, conversion, scaling, other numbers. Inside a pool, a number takes flat additions first, then the sum of every **Increased** percentage, then each **More** percentage on its own. Conversions from one type cap at 100% in total and are shared proportionally above that.

## Requirements

1. **Skill tags on every Skill**, set in its scene.
   - Fireball: Spell, Projectile, Fire.
   - Attack: Attack, Melee. These are the sword's tags until Weapons bring them through Modifiers.
2. **Implied tags** come from one table (for now: Fire → Elemental) and are worked out again whenever tags change, including during the tag pass, so a filter on Elemental can match. A Modifier can't add or remove an implied tag directly; it changes the tag that implies it.
3. **Modifiers** as data: a filter (Skill tags, or none) and a list of effects. Effects for this step:
   - change a number: flat, Increased or More, on a named Skill number (Cooldown, Range, …); a number the Skill doesn't have is ignored.
   - add a tag, replace a tag, remove a tag.
   - a behaviour is a tag the Skill reads from its Snapshot (Pierce), not an effect of its own: it comes with the tag and goes with it, so a removed Pierce tag means no piercing, though the Modifier that added it stays applied. A behaviour has no number (decided 2026-11-21); a count, such as "pierce 1 more Enemy", would be a number change for a later step.
4. **The Character keeps one list of Modifiers.** How it gathers Modifiers from several sources (gear, talents, buffs) is a decision for later; see Deferred decisions.
5. **Each activation builds a Snapshot** from the Skill and the Character's Modifiers, following the rules: tag pass, then the pools for the numbers that exist today.
   - The Skill's own activation receives the Snapshot. Fireball hands it to its projectile; Attack reads it for its swing.
   - The Snapshot never changes after it is made. A projectile in flight keeps its Snapshot when Modifiers change.
   - The Cooldown that starts on an activation is the Snapshot's.
6. **Proof Modifiers**, switched with a console command `modifier <name> on|off` (and listed without arguments):
   - **"Spells have 50% reduced cooldown"**: filter Spell, Increased −50% on Cooldown. Fireball's goes from 4 s to 2 s; Attack's is unchanged.
   - **"Projectiles pierce an Enemy"**: filter Projectile, adds the Pierce tag. Fireball's projectile passes through the first Enemy it hits, landing the hit as usual, and stops at the second. It never pierces a wall, and its Range still ends it. A ball hits each Enemy at most once, so touching one it already hit again (after knocking it ahead) does nothing.
7. **Why a Modifier applied or not** is available on the Snapshot (a list like the sandbox's), for tests and the console. No player-facing display yet.

## Where the code lives

Settled 2026-11-21 after a call map of the old flow (https://claude.ai/artifact/Pi6Ms2MDqTB7FcLh8ppzwY) and `research-skill-systems.md`. The Character owns its Skills and its Modifiers; the Skill bar only binds slots to Skills; a Skill runs its own activation and Cooldown.

- **Skill** (`skills/skill.gd`): `try_activate(aim, modifiers) -> bool` is the one path for an activation: not ready → false; otherwise build the Snapshot from `modifiers`, start the Snapshot's Cooldown, run the Skill's `_activate(snapshot, aim)` (Fireball's and Attack's override it), true. The Skill ticks its own Cooldown each physics frame and emits `ready_again`. It keeps no list of Modifiers.
- **SkillBar** (`skills/skill_bar.gd`): the five slots, the press queue and holds, nothing else. Each physics frame it emits `activation_requested(slot, aim)` for each press and each held repeat whose Skill is ready. No Snapshot, no Cooldown clocks.
- **Player** (`characters/player/player.gd`): keeps `modifiers` and answers `activation_requested`: works out the aim when the press had none, calls `skill.try_activate(aim, modifiers)`, and on success turns to the aim, squashes, and emits `skill_activated(slot)`.
- **SkillBarHud**: presses a button in on the Player's `skill_activated`, and flashes it on its Skill's `ready_again`.
- **Aiming is not an activation.** The aim (auto-aim, a drag, the aim marker's Range ring) reads the Skill's numbers as they stand now with the Character's Modifiers (`Skill.number()`), so a Range Modifier that comes or goes while aiming shows at once. Only the activation makes a Snapshot.
- **Number names** are constants: `Skill.COOLDOWN`, `RANGE`, `KNOCKBACK`, `STAGGER`, `Fireball.SPEED`, `Attack.SWEEP`. A Modifier's `.tres` names them as text.
- **Words**: "activate" replaces "use" everywhere (GLOSSARY.md › Activate), including the console command `activate <slot> [<x> <z>]` and the input actions `activate_skill_slot_1` to `_5`.

## Out of scope

- Damage, Damage types, adding and converting damage, scaling damage. Next step, with health and mana.
- Gear, talents, buffs, supports and Weapons as sources of Modifiers.
- Showing players where a number came from.

## Deferred decisions

- **A minimum Cooldown.** Stacking stops Increased and each More at -100%, so a number never goes below 0, but a Cooldown of 0 would break "every Skill has one". Decide with attack speed, the first Modifier likely to push a Cooldown that low.

- **Where Modifiers come from.** Decide when a second real source exists (say gear next to talents): whether the Character asks each source on every activation, or keeps a combined list. The framework only needs "a list of Modifiers" either way.
- **A replace of a tag added in the same round.** If one Modifier adds Chain and another replaces Chain with Fork, and both apply in the same round of the tag pass, the replace does nothing, because Chain only arrives at the end of that round. Decide if a real build ever hits this.
- Whether converted damage is also scaled by its old type's Modifiers (with damage).
- What the Damage types are, how many, and their order (with damage).

## Tests

- Implied tags: Fireball has Elemental; replacing Fire with a non-elemental tag drops it.
- Filters: a Modifier with a Spell filter applies to Fireball and not to Attack; one with no filter applies to both.
- Tag pass: an added tag lets another Modifier match; a removed tag can't be added back; a Modifier that needs a removed tag misses; a Modifier that changes tags stays applied when a later round removes its tag; two Modifiers that switch each other off and on still end.
- Numbers: flat, then Increased summed, then More each on its own: Range 10, +2, +20% and +10% Increased, 50% More gives 23.4.
- Snapshot: changing Modifiers after an activation doesn't change that activation's projectile.
- Proof: with the cooldown Modifier on, Fireball's Cooldown is 2 s; with Pierce on, its projectile passes through one Enemy and stops at the second, and a wall stops it; with both off, Fireball is as made.
- The console command switches each proof Modifier on and off.
