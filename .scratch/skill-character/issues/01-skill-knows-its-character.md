# 01: A Skill knows its Character

**What to build:** The branch's first commit is `.scratch/skill-character/` with the Skill entry of `GLOSSARY.md` from the spec's "Docs this reopens", as the working agreement asks. Then `Skill.character` replaces `Skill.faction`; `hostile_mask()` reads `character.faction`; `Character._ready()` and `Character.add_skill()` set `skill.character = self` where they handed down the Faction. The Attack and Fireball tests give their Skill a Character by using the player's own. Nothing changes in play. See `.scratch/skill-character/spec.md` (rules 1 and 2; "The change, file by file" › `skill.gd`'s class doc, `:53-55` and `hostile_mask()`, and `character.gd`; "Tests").

**Files:** `GLOSSARY.md` (`:47-49`); `skills/skill.gd` (`:4-8`, `:53-55`, `:141-143`); `characters/character.gd` (`_ready()`, `add_skill()` and its doc); `tests/test_attack.gd`; `tests/test_projectile.gd`; `tests/test_enemy_death.gd`; `tests/test_health_bar.gd`; `tests/test_character.gd`.

**Tests:** the first four rows of the spec's table "Every test that activates a Skill": `_players_attack()` in `test_attack.gd` and `_players_fireball()` in `test_projectile.gd` (seven tests), the player's own Attack in the `before_each` of `test_enemy_death.gd` and `test_health_bar.gd`, whose two player tests (`:31`, `:47`) then use that player. The two `test_character.gd` tests changed as "Changed assertions" says. New: `test_an_enemys_swing_hits_the_players_faction_not_the_enemies` in `test_attack.gd`.

**Blocked by:** None. The branch starts from step 6's (`character`).

**Status:** ready-for-agent

- [x] The spec folder and the Skill glossary entry are the branch's first commit.
- [x] `skill.gd` has `character` with the spec's doc and no `faction`; its class doc is the spec's, except the clause "and no Skill script can stop it" (ticket 03); `hostile_mask()` reads `character.faction`.
- [x] `character.gd` sets `skill.character = self` in `_ready()` and `add_skill()`; a search for `.faction` under `skills/` finds only `character.faction`.
- [x] No test adds a second Player; the changed tests and the new one pass; `tools/check.sh` passes.
