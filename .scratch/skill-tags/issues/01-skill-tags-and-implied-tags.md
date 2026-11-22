# 01: Skill tags and implied tags

**What to build:** Skills say what kind of Skill they are. Fireball carries the Skill tags Spell, Projectile and Fire; Attack carries Attack and Melee (the sword's tags, until Weapons bring them through Modifiers). Tags are set in each Skill's scene. Implied tags come from one table (for now Fire → Elemental), so asking Fireball for its tags includes Elemental, and replacing Fire with a tag that implies nothing would drop it. See `.scratch/skill-tags/spec.md` (requirements 1–2) and GLOSSARY.md (Skill tag).

**Blocked by:** The Remove Use time step (`.scratch/remove-use-time/spec.md`), merged.

**Status:** ready-for-agent

- [x] Fireball's scene sets Spell, Projectile and Fire; Attack's sets Attack and Melee.
- [x] One table of implied tags exists, holding Fire → Elemental.
- [x] A Skill's tags, with implied ones worked out, include Elemental for Fireball and not for Attack.
- [x] Implied tags are worked out from whatever tags are given, so a set without Fire has no Elemental.
- [x] GUT tests cover the above; `tools/check.sh` passes.
