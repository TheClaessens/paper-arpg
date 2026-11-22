# 04: The Health bar

**What to build:** The flat strip over every Standee: a dark frame with a red fill showing current over maximum Health, about 100×9 at the viewport's 648 height (fill `#d8473a`, frame `#1b1512`, as on the Prototype artboard at https://claude.ai/artifact/UaRp1inUAJSG34dUsLbrta). It lives in the world, inside the pixelated view, so it pixelates with the Standees. It shows only while Health is below its maximum, and hides when its Enemy dies. The Character connects its Health to its bar. The player and the zombie both have one; the HUD has none. See `.scratch/factions-health/spec.md` (rule 7, requirement 10; edge case 1).

**Blocked by:** 02: Damage and Health; 03: Enemy death.

**Status:** ready-for-agent

- [ ] At full Health no bar shows, for the player or a zombie.
- [ ] Hitting a zombie shows its bar and drops it by the hit's share.
- [ ] `damage 10` shows the player's bar; healing back to full hides it.
- [ ] A dying zombie's bar hides as the sink starts.
- [ ] GUT tests cover the above; `tools/check.sh` passes; checked once in game and on a screenshot.
