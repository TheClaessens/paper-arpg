# 03: A projectile's hit doesn't freeze the world

**What to build:** A projectile's hit plays the impact without the hitstop: `HitFeedback.play_impact` and `Skill._land_hits` take whether it freezes, and Fireball's hits pass false. The Attack's hit still freezes. `_land_hits` says it plays one impact per call. The Hit feedback entry in `GLOSSARY.md` says a projectile's hit doesn't freeze the world. See `.scratch/deepen-skills/spec.md`, item 3.

**Status:** ready-for-agent

- [x] A Fireball hit knocks the Enemy back, flashes and squashes it, and shakes the screen, without freezing the world; tested through `Fireball.try_activate`.
- [x] An Attack hit still freezes the world, once per swing however many Enemies it hits.
- [x] An impact that doesn't freeze leaves the time scale alone.
- [ ] `tools/check.sh` passes; checked once in game.
