# Deepen Skills

Status: ready-for-agent

Five changes from the architecture review on 2026-11-21. Each gives one concept one home. Behaviour doesn't change, except that a projectile's hit no longer freezes the world (item 3). The branch starts from `skill-tags`, because that branch's code isn't on `master` yet. Rebase it onto `master` once `skill-tags` merges.

## What moves where

1. **Making a Snapshot lives in Snapshot.** `Snapshot.of(own_tags, numbers, modifiers)` runs the tag pass, puts the number changes in the pools in ADR 0002's order, stacks them (flat, then Increased, then More), and writes the "why" lines. It is pure: it takes data and returns data, and needs no nodes. `Skill` keeps its own tags, its numbers, its Cooldown and what it does: `Skill.snapshot(modifiers)` becomes a one-line call to `Snapshot.of`. Implied tags (`IMPLIED_TAGS`, `with_implied`) move to `TagPass`, their only user.
2. **The questions that find Enemies live on Enemy.** `enemies_around`, `enemy_nearest` and `nearest_to` move from `Skill` to statics on `Enemy`. Player's hover ring no longer goes through `Skill` to find an Enemy.
3. **A projectile's hit doesn't freeze the world** (decided 2026-11-21). Today `_land_hits` says the impact plays "once per activation", but Fireball calls it once per Enemy, so a ball with Pierce froze the world twice, and the ball stuttered on through. Now a projectile's hit shakes the screen, flashes and squashes, but has no hitstop; the Attack's hit still freezes. Whether a hit freezes depends on what landed it (the projectile), not on Skill tags, so no Modifier can change Hit feedback. `_land_hits` says what it really does: one impact per call. (A rule in `HitFeedback` merging impacts that come during a hitstop was considered and dropped: during a hitstop nothing moves, so it would only have merged hits that already land in one call.)
4. **Aim lives in Player** (decided 2026-11-21). Auto-aim (`auto_aim`, `aim_toward`, `AUTO_AIM_ANGLE`) moves from `Skill` to `Player`, next to the rest of the aim code (`_aim_for`, `aim_from_drag`, `ground_aim`, `_range_of`). `Skill` keeps only *how* it aims (`aim`, `aims_at_spot`). The Skill bar doesn't change: it only holds Skill slots and asks for activations. A separate `Aim` component was considered and dropped: everything aiming needs (Facing, where the Character stands, its Modifiers, Controls, the aim marker) belongs to the Player, so the component's interface would be as wide as its code, and deleting it would just move the code back.
5. **A Skill slot's button flashes its own Skill when it is ready again.** Today the HUD connects `ready_again` only for the Skills the player had at `_ready`, so a Skill gained later never flashes.

## Out of scope

- Turning Skills into settings on shared pieces (a swing, a projectile, an area) instead of one script each. Do it when the third or fourth Skill shows which pieces repeat.
- The pools ADR 0002 adds with damage (added damage, conversion, scaling). They go into `Snapshot.of` once damage exists.
