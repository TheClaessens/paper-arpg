# 03: Hit feedback owns the impact rule

**What to build:** `HitFeedback.play_impact` doesn't start an impact (hitstop or shake) while a hitstop is still running. Skills land each hit as it happens: `_land_hits(hits, snapshot)` becomes `_land_hit(enemy, push, snapshot)`, and Attack and Fireball stop gathering hits into a list first. The Hit feedback entry in `GLOSSARY.md` says when an impact is skipped. See `.scratch/deepen-skills/spec.md`, item 3.

**Status:** needs-info

**Open:** with this rule, a ball with Pierce still plays two impacts, because it moves only after the first hitstop ends. Is that right, since two Enemies are hit at two separate moments? Or should a Pierce ball's second hit not freeze the world?

- [ ] An impact that comes during a hitstop does nothing; one that comes after it plays.
- [ ] Attack hitting three Enemies plays one impact.
- [ ] A ball with Pierce hitting two Enemies plays the number of impacts settled above, tested through `Fireball.try_activate`.
- [ ] Flash and squash still play on every Enemy hit.
- [ ] `tools/check.sh` passes; checked once in game.
