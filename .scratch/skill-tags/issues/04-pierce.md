# 04: Pierce

**What to build:** A Modifier can add a behaviour by adding the tag that is one. The proof Modifier "Projectiles pierce an Enemy" (filter Projectile) adds the Pierce tag; `modifier pierce on` switches it on. Fireball's projectile then passes through the first Enemy it hits, landing the hit as usual, and stops at the second, at a wall, or at its Range. It hits each Enemy at most once. A projectile reads Pierce from the Snapshot it was fired with, so switching Modifiers while it flies doesn't change it. See `.scratch/skill-tags/spec.md` (requirements 3, 5 and 6).

**Blocked by:** 03: Tag changes and the tag pass.

**Status:** ready-for-agent

- [x] The Skill reads the Pierce behaviour from its Snapshot's tags.
- [x] `modifier pierce on`: Fireball's Snapshot has the Pierce tag; Attack's doesn't.
- [x] With Pierce on, Fireball's projectile hits the first Enemy, passing through it, and stops on the second. It hits an Enemy it already hit only once.
- [x] Walls and Range still stop it.
- [x] Switching Pierce off while a projectile flies leaves that projectile piercing.
- [x] With every proof Modifier off, Fireball behaves as made.
- [x] GUT tests cover the above; `tools/check.sh` passes; checked once in game.
