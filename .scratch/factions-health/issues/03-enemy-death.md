# 03: Enemy death: sinking through the floor

**What to build:** A zombie at 0 Health dies. It stops chasing, leaves every collision layer (so it can't be hit, aimed at or ringed, and blocks no one) and sinks through the floor where it stood: the Standee drops through the ground line with a small wobble in 0.45 s, ease-in, while its Blob shadow shrinks and fades. The sink is a tween, so the hitstop holds it still first and the killing hit's flash and squash stay visible. When the sink ends the zombie is removed. The agreed look is the Prototype artboard on the Health Bars & Death canvas (https://claude.ai/artifact/UaRp1inUAJSG34dUsLbrta). See `.scratch/factions-health/spec.md` (rules 5–6, requirements 8–9; edge cases 2, 4, 5).

**Blocked by:** 02: Damage and Health.

**Status:** ready-for-agent

- [x] Five Attacks kill a zombie; it sinks in place in 0.45 s after the hitstop and is then freed.
- [x] The killing hit doesn't knock it back.
- [x] While sinking it can't be hit, auto-aimed or ringed, and doesn't block other Characters.
- [x] A second hit on it in the same frame misses: no flash, no Hit feedback of its own, no second `died`. Hit feedback plays only when at least one hit landed.
- [x] A Pierce projectile passes through the zombie it kills and stops at the next Hurtbox.
- [ ] GUT tests cover the above; `tools/check.sh` passes; checked once in game.
