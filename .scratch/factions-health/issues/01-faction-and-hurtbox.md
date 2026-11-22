# 01: Faction and Hurtbox: Skills hit what is hostile

**What to build:** A prefactor with no visible change in play. Every Character has a Faction (the player's or the Enemies'), set in its scene, and calls it down to its Hurtbox and its Skills. The zombie gets a Hurtbox, the part of it that Skills hit. Attack's swing, Fireball's projectile (Pierce included), Auto-aim and the player's cursor ring all find their targets as Hurtboxes on layers hostile to their Character's Faction, instead of by the `Enemy` class. A hit on a Hurtbox reports its direction and the activation's Snapshot; the zombie answers it with the knockback, Stagger, flash and squash it has today. The player has no Hurtbox in this step. See `.scratch/factions-health/spec.md` (rules 1–3, requirements 1–4, 12).

**Blocked by:** None (can start immediately).

**Status:** ready-for-agent

- [ ] Faction is a class with the two sides and their layer and hostile mask, not a node; the player is on the player's Faction and the zombie on the Enemies'.
- [ ] The zombie's Hurtbox sits on the Enemies' layer and emits `hit_taken(direction, snapshot)` when hit.
- [ ] Attack, Fireball (with and without Pierce), Auto-aim and the cursor ring behave as before against zombies.
- [ ] A Hurtbox on the player's layer is never hit, aimed at or ringed by the player's Skills.
- [ ] A search finds no leftover `enemies_around`, `enemy_nearest` or `hit_enemy` in code, tests or docs.
- [ ] GUT tests cover the above; `tools/check.sh` passes; checked once in game.
