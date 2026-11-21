# 04: Pierce

**What to build:** A Modifier can add a behaviour. The proof Modifier "Projectiles pierce 2 Enemies" (filter Projectile) adds the Pierce tag and the behaviour; `modifier pierce on` switches it on. Fireball's projectile then passes through the first two Enemies it hits, landing each hit as usual, and stops at the third, at a wall, or at its Range. A projectile reads Pierce from the Snapshot it was fired with, so switching Modifiers while it flies doesn't change it. See `.scratch/skill-tags/spec.md` (requirements 3, 5 and 6).

**Blocked by:** 03: Tag changes and the tag pass.

**Status:** ready-for-agent

- [ ] A behaviour effect that the Skill reads from its Snapshot.
- [ ] `modifier pierce on`: Fireball's Snapshot has the Pierce tag and Pierce 2; Attack's has neither.
- [ ] With Pierce on, Fireball's projectile hits two Enemies, passing through each, and stops on the third.
- [ ] Walls and Range still stop it.
- [ ] Switching Pierce off while a projectile flies leaves that projectile piercing.
- [ ] With every proof Modifier off, Fireball behaves as made.
- [ ] GUT tests cover the above; `tools/check.sh` passes; checked once in game.
