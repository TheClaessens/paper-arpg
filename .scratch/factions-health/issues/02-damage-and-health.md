# 02: Damage and Health

**What to build:** Skills deal Damage and Characters have Health. Damage is a number of the Skill, so the Snapshot holds it after Modifiers: Attack 10, Fireball 20. Health is a component with a maximum, its current value, damage and heal (clamped to 0 and the maximum, a 0 Damage hit changes nothing) and `changed` and `died` signals; `died` fires once, after which damage and heal do nothing. The player has 100, the zombie 50. A hit on the zombie's Hurtbox lowers its Health by the Snapshot's Damage. The Console's `damage <amount>` and `heal <amount>` change the player's Health and print it rounded. Death itself has no effect yet. See `.scratch/factions-health/spec.md` (rules 3–5, requirements 5–7, 11; edge case 3).

**Blocked by:** 01: Faction and Hurtbox.

**Status:** ready-for-agent

- [x] Attack's and Fireball's Snapshots carry Damage 10 and 20; a Modifier on Damage changes it.
- [x] Health clamps, ignores 0 Damage, reports each change, and dies exactly once; after death it ignores damage and heal.
- [x] Hitting a zombie lowers its Health by the Skill's Damage.
- [x] `damage` and `heal` change the player's Health, stop at 0 and 100, and healing at 0 leaves it at 0.
- [x] GUT tests cover the above; `tools/check.sh` passes; checked once in game with the Console.
